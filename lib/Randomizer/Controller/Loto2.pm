package Randomizer::Controller::Loto2;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Mojo::Upload;
use File::Basename;
use File::Find::Rule;
use Archive::Zip qw( :ERROR_CODES );
use IO::Compress::Zip qw(:all);
use Archive::Zip;
use Data::Dumper;
#use File::Slurp;
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

        my $dir = 'uploaded/' . b64_encode ($self->session('user') . " :: " .  time );
        chomp($dir);
        $name = 'base.csv';
        mkdir $dir, 0755;
        $fileuploaded->move_to("$dir/$name");

        my $cnf = $self->config->{loto2}->{$type};
        my $log = $self->app->log;

        $log->debug("name: $name; dir: $dir");
        $log->debug( Dumper($cnf) );

        if ($cnf->{regexp_modify}) {
                $log->debug('regexp modified');
            $self->regexp_modify({
                name => $name,
                dir => $dir,
                regex => $cnf->{regex},
                substition => $cnf->{substition},
            });
            $log->debug('regexp modified');
        }

        $log->debug('base uploaded');
        if ($cnf->{add_null_row}) {
            $self->add_null_row({
                name => "$dir/$name",
                add_null => $cnf->{add_null},
                null_row => $cnf->{null_row},
            });
            $log->debug('added null row');
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
            $log->debug('checkfile created');
        }
        if ($cnf->{xtoplus}) {
            $self->x_to_plus({
                name => $name,
                dir => $dir,
            });
            $log->debug('X to plus changed');
        }

        if ($cnf->{add_null_row} || $cnf->{regexp_modify} || $cnf->{create_ckeckfile} || $cnf->{xtoplus} ) {
            my @files = File::Find::Rule->file()->name( '*.csv' )->in( $dir );
            my $obj = Archive::Zip->new();
            foreach (@files) {
                $obj->addFile($_, basename($_));
            }
            $self->logger($dir . ' :: ' . $cnf->{name} . ' :: ' . $OrderNumber );
            if ($obj->writeToFileNamed("$dir/$OrderNumber.zip") == AZ_OK) {
            $log->debug('archive created');

            $self->render_file(
                'filepath' => "$dir/$OrderNumber.zip",
                'format'   => 'application/x-download',
                'content_disposition' => 'inline',
                'cleanup'  => 0,
                );
            } else {
                $self->flash( message => 'Ошибка ' . $self->tx->local_address . "/download/" . $dir );
                $self->render( template => 'default/loto2' );
            }
        } else {
            $self->flash( message => 'Файл не требует изменений!' );
            $self->render( template => 'default/loto2' );
        }
    }
}

1;
