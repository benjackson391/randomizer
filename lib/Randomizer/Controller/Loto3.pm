package Randomizer::Controller::Loto3;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Upload;
use Archive::Zip qw( :ERROR_CODES );
use File::Basename;
use FindBin;
use Data::Dumper;
use utf8;
use Encode 'encode';



sub loto3 {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
#      $self->stash(files => \@files, lotos => $self->config->{loto2});
      $self->render( template => 'default/loto3' );
  }
}

sub generate3 {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
    $ENV{"MOJO_MAX_MESSAGE_SIZE"} = 500 * 2**20;    #500 MB
    return $self->render(text => 'File is too big.', status => 200)
      if $self->req->is_limit_exceeded;
    return $self->redirect_to('/loto3')
      unless my $upload_file = $self->param('upload_file');
      my $fileuploaded = $self->req->upload('upload_file');
      my $date = $self->param('Date');
      $date = encode('UTF-8', $date);
      my $type = $self->param('Type');
      my $size = $fileuploaded->size;
      my $name = $fileuploaded->filename;
      $fileuploaded->move_to("uploaded/$name");

      my $helper = $self->change_char({name => "uploaded/$name", type => $type, date => $date});
      my $add_null = $self->add_null_row({
        name => "uploaded/$name",
        null_row => $type eq 'JL' ? ';'x59 : ';'x60,
        add_null => 1000,
      });

      if ($helper || $add_null) {
        $self->render_file(
            'filepath' => "uploaded/$name",
            'format'   => 'application/x-download', # will change Content-Type "application/x-download" to "application/pdf"
            'content_disposition' => 'inline',   # will change Content-Disposition from "attachment" to "inline"
            'cleanup'  => 1,                     # delete file after completed
        );
      }
  }
}


1;
