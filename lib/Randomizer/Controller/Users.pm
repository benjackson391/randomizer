package Randomizer::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;


sub list {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {
        $self->stash(users => $self->app->users->list() );
        $self->render( template => 'users/view' );
    }
}

sub add {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {
        ;
        $self->param("last_name");
        $self->param("login");
        my $id = $self->app->users->add({
            first_name => $self->param("first_name"),
            last_name => $self->param("last_name"),
            login => $self->param("login"),
            password => $self->bcrypt( $self->param("password") ),
            valid_id => 1,
        });

        $self->flash( message => 'Пользователь уже существует' ) if !$id;

        $self->redirect_to('/users');
    }
}

1;
