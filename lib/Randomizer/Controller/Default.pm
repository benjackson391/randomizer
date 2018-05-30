package Randomizer::Controller::Default;
use Mojo::Base 'Mojolicious::Controller';

sub welcome {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
      $self->render( template => 'default/welcome' );
  }
}

sub auth {
  my $self = shift;
  if ( $self->session('name') ) {
      return $self->redirect_to('/welcome');
  }
  else {
  $self->render( template => 'default/login' );
  }
}

sub login {
    my $self = shift;
    my $user = $self->param('name') || q{};
    my $pass = $self->param('pass') || q{};

    if ( $self->authenticate( $user, $pass ) ) {
        $self->session(user => $user);
        $self->redirect_to('/welcome');
    }
    else {
        $self->flash( message => 'Invalid credentials! ' );
        $self->redirect_to('/');
    }
}

sub logout {
  my $self = shift;
  $self->session( expires => 1 );
  $self->redirect_to('/');
}

sub loto1 {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
      $self->render( template => 'default/loto1' );
  }
}

sub loto2 {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
      $self->render( template => 'default/loto2' );
  }
}

1;
