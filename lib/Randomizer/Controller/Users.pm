package Randomizer::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Mojo::JSON;

sub index {
    my $self = shift;
        my $groups = $self->app->groups->get_groups;
        my $users = $self->app->users->get_users;

        for my $user_id (keys %$users) {
            my $included_groups = $self->app->users->get_user_group($user_id);

            for my $group (keys %$groups) {
                $users->{$user_id}->{groups}->{$group}->{name} = $groups->{$group}->{name};
                $users->{$user_id}->{groups}->{$group}->{valid} = $included_groups->{$group} || 0;
            }
        }

        if ($self->param('user_id')) {

            $self->render( user => $users->{$self->param('user_id')});
            $self->render( template => 'users/view');
        } else {
            $self->render( users => $users);
            $self->render( template => 'users/list');
        }
}

sub update {
    my $self = shift;
        my %param;
        for (qw/id first_name last_name login /) {
            $param{$_} = $self->param($_);
        }

        if ($self->param('valid_id')) {
            $param{valid_id} = 1;
        } else {
            $param{valid_id} = 0;
        }
        $param{password} = $self->bcrypt( $self->param('password') ) if $self->param('password');

        my $groups = $self->app->groups->get_groups;
        for (keys %$groups) {
            $param{groups}->{$groups->{$_}->{name}} = $self->param($groups->{$_}->{name});
        }

        $self->app->log->debug($self->app->users->set_user(\%param));

        $self->app->users->set_user_group({
            user_id    => $param{id},
            groups     => $param{groups},
        });

        $self->stash( msg => 'Пользователь обновлен!');
        $self->redirect_to('/users');
}



#sub list {
#    my $self = shift;
#    if ( not $self->user_exists ) {
#        $self->flash( message => 'You must log in to view this page' );
#        $self->redirect_to('/');
#        return;
#    }
#    else {
#        $self->stash(users => $self->app->users->list() );
#        $self->stash(users => $self->app->users->list() );
#        $self->render( template => 'users/view' );
#    }
#}

#sub add {
#    my $self = shift;
#    if ( not $self->user_exists ) {
#        $self->flash( message => 'You must log in to view this page' );
#        $self->redirect_to('/');
#        return;
#    }
#    else {
#        ;
#        $self->param("last_name");
#        $self->param("login");
#        my $id = $self->app->users->add({
#            first_name => $self->param("first_name"),
#            last_name => $self->param("last_name"),
#            login => $self->param("login"),
#            password => $self->bcrypt( $self->param("password") ),
#            valid_id => 1,
#        });
#
#        $self->flash( message => 'Пользователь уже существует' ) if !$id;
#
#        $self->redirect_to('/users');
#    }
#}

1;
