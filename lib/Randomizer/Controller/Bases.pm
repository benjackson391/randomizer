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

#sub generate {
#  my $self = shift;
#  if ( not $self->user_exists ) {
#      $self->flash( message => 'You must log in to view this page' );
#      $self->redirect_to('/');
#      return;
#  }
#  else {
#    $ENV{"MOJO_MAX_MESSAGE_SIZE"} = 500 * 2**20;    #500 MB
#    return $self->render(text => 'File is too big.', status => 200)
#      if $self->req->is_limit_exceeded;
#    return $self->redirect_to('/loto3')
#      unless my $upload_file = $self->param('upload_file');
#    my $date = $self->param('Type');
#    my $fileuploaded = $self->req->upload('upload_file');
#    #my $size = $fileuploaded->size;
#    my $name = $fileuploaded->filename;
#
#    my $errors;
#    while ($_ = glob("uploaded/*")) {
#       next if -d $_;
#       unlink($_) or ++$errors, warn("Can't remove $_: $!");
#    }
#
#    $fileuploaded->move_to("uploaded/$name");
#
#
#    open (my $fn, '<:encoding(UTF-8)', "uploaded/$name") or die;
##
#    my $string;
#    my $line = 1;
#    while (<$fn>) {
#        last if $line == 100;
#        chomp($_);
#        $_ .= $date;
#        $string .= "$_\n";
#        $line++;
#    }
#
#    my $encoding_name = Encode::Detect::Detector::detect($string);
#    $self->app->log->debug("encoding_name $encoding_name");
##    $string = decode( $encoding_name, $string );
##    utf8::encode($string);
##    my $encoding_name2 = Encode::Detect::Detector::detect($string);
##    $self->app->log->debug("encoding_name2 $encoding_name2");
##    $self->render_file(
##        'filepath' => 'output/test.txt',
##        'format'   => 'application/x-download', # will change Content-Type "application/x-download" to "application/pdf"
##        'content_disposition' => 'inline',   # will change Content-Disposition from "attachment" to "inline"
##        'cleanup'  => 1,                     # delete file after completed
##    );
#
#    #$self->render( template => 'default/bases' );
#    $self->render( text => $string );
##    $self->render( text => '123 123 123' );
#  }
#}

1;
