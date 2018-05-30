package Randomizer::Controller::Bases;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Upload;
use Archive::Zip qw( :ERROR_CODES );
use File::Basename;
use File::Find;
use Mojo::Util qw(b64_decode b64_encode);
use FindBin;
use Data::Dumper;
use utf8;
use Encode;
use Encode::Detect::Detector;

# This action will render a template
sub main {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {
        opendir(my $dh, "bases");
        my @files = readdir($dh);

        my %files = map { split( " :: ", b64_decode($_), 2 ) } @files;
        %files = map { Mojo::Date->new($_) => $files{$_} } keys %files;

        $self->app->log->debug(Dumper(\%files));
        $self->stash( files => \%files );
        $self->render( template => 'default/bases' );
    }
}

sub upload {
    my $self = shift;
    if ( not $self->user_exists ) {
        }
        else {
            return $self->render(text => 'File is too big.', status => 200)
                if $self->req->is_limit_exceeded;
            return $self->redirect_to('/bases')
                unless my $upload_file = $self->param('upload_file');
            my $fileuploaded = $self->req->upload('upload_file');
            my $name = $fileuploaded->filename;
            my $headers = $fileuploaded->headers;
            my $size = $fileuploaded->size;
            my $slurp = $fileuploaded->slurp;

            $self->app->log->debug('Bases->upload: uploaded file name is ' . $name);

            $fileuploaded->move_to('bases/' . b64_encode ( time . " :: $name" ) );
            $self->redirect_to('/bases');
    }
}

1;
