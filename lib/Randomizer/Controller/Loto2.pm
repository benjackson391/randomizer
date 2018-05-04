package Randomizer::Controller::Loto2;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Mojo::Upload;
use File::Basename;
use File::Find::Rule;
use Archive::Zip qw( :ERROR_CODES );
use utf8;


sub loto2 {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {

        $self->stash( lotos => $self->config->{loto2} );
        $self->render( template => 'default/loto2' );
    }
}

sub generate2 {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {

        my $type =      $self->param("Type");
        my $count =     $self->param("Count");
        my $OrderNumber=$self->param("OrderNumber");
        my $Check1 =    $self->param("Check1");
        my $Check2 =    $self->param("Check2");
        my $Check3 =    $self->param("Check3");
        my $Draw   =    $self->param("Draw");

        return $self->render(text => 'File is too big.', status => 200)
            if $self->req->is_limit_exceeded;
        return $self->redirect_to('/loto2')
            unless my $upload_file = $self->param('upload_file');
        my $fileuploaded = $self->req->upload('upload_file');
        my $size = $fileuploaded->size;
        my $name = $fileuploaded->filename;

        my $dir = 'uploaded/' . b64_encode ($self->session('user') . time );
        chomp($dir);
        $name = 'base.csv';
        mkdir $dir, 0755;
        $fileuploaded->move_to("$dir/$name");

        my $cnf = $self->config->{loto2}->{$type};

        if ($cnf->{add_null_row}) {
            $self->add_null_row({
                name => "$dir/$name",
                add_null => $cnf->{add_null},
                null_row => $cnf->{null_row},
            });
        }

        if ($cnf->{regexp_modify}) {
            $self->regexp_modify({
                name => $name,
                dir => $dir,
                regex => $cnf->{regex},
                substition => $cnf->{substition},
            });
        }

        if ($cnf->{create_ckeckfile}) {
            $self->create_ckeckfile({
                name => $name,
                dir => $dir,
                regex_for_sn => $cnf->{regex_for_sn},
                order_number => $OrderNumber,
                draw => $Draw,
                check1 => $Check1,
                check2 => $Check2,
                check3 => $Check3,
            });
        }
        if ($cnf->{xtoplus}) {
            $self->create_ckeckfile({
                name => $name,
                dir => $dir,
            });
        }

        my @files = File::Find::Rule->file()->name( '*.csv' )->in( $dir );

        my $obj = Archive::Zip->new();
        foreach (@files) {
            $obj->addFile($_, basename($_));
        }
        if ($obj->writeToFileNamed("$OrderNumber.zip") == AZ_OK) {
        $self->render_file(
            'filepath' => "$OrderNumber.zip",
            'format'   => 'application/x-download',
            'content_disposition' => 'inline',
            'cleanup'  => 1,
            );
        }
        #$self->redirect_to('/loto2');
    }
}

1;
