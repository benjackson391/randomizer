package Randomizer;

use Modern::Perl;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Authentication;
use Mojolicious::Plugin::Bcrypt;
use Mojolicious::Plugin::Database;
use Data::Dumper;
use utf8;
use DBI;

use Randomizer::Model::User;
use Randomizer::Model::Group;

sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->renderer->encoding('utf8');
    $self->plugin('PODRenderer') if $self->config->{perldoc};
    $self->plugin('RenderFile');
    $self->plugin('bcrypt', { cost => 4 });
    $self->secrets($self->config('secrets'));
    $self->max_request_size($self->config('max_request_size'));

    $self->plugin('Randomizer::Helpers::AddNullRow');
    $self->plugin('Randomizer::Helpers::RegexpModify');
    $self->plugin('Randomizer::Helpers::CreateCheckFile');
    $self->plugin('Randomizer::Helpers::XToPlus');
    $self->plugin('Randomizer::Helpers::Logger');
    $self->plugin('Randomizer::Helpers::Generator');
    $self->plugin('Randomizer::Helpers::FileCheck');

    $self->mode('development');
    $self->plugin('database', {
        dsn      => $self->config->{dsn},
        username => $self->config->{user} || q{},
        password => $self->config->{password}  || q{},
        options  => { mysql_enable_utf8 => 1, RaiseError => 1, mysql_auto_reconnect => 1 },
        helper   => 'db',
    });

    $self->app->sessions->cookie_name('randomizer');
    $self->app->sessions->default_expiration(86400);

    $self->plugin('AccessControl');
    $self->plugin('authentication', {
        load_user => sub {
            my ( $self, $uid ) = @_;
            my $sth = $self->db->prepare(' select * from users where id=? and valid_id = 1');
            $sth->execute($uid);
            if ( my $res = $sth->fetchrow_hashref ) {
                return $res;
            }
            else {
                return;
            }
        },
        validate_user => sub {
            my ( $self, $username, $password ) = @_;
            my $sth
                = $self->db->prepare(' select * from users where login=? and valid_id = 1');
            $sth->execute($username);
            return unless $sth;
            if ( my $res = $sth->fetchrow_hashref ) {
                my $salt = substr $password, 0, 2;
                if ( $self->bcrypt_validate( $password, $res->{password} ) ) {
                    $self->session(user => $username);
                    #$self->flash(message => 'Thanks for logging in.');
                    return $res->{id};
                }
                else {
                    return;
                }
            }
            else {
                return;
            }
        },
    });

    $self->helper(users => sub {
        state $user = Randomizer::Model::User->new(db => shift->db);
    });
    $self->helper(groups => sub {
        state $group = Randomizer::Model::Group->new(db => shift->db);
    });

### Routing

    my $r = $self->routes;

    $r->any('/' => sub {
        my $c = shift;

        $c->redirect_to($c->config->{main_page}) if $c->session('user');

        my $method = $c->tx->req->method;

        if ($method eq 'GET') {
            $c->render( template => 'default/login' );
        } else {
            my $user = $c->param('name') || q{};
            my $pass = $c->param('pass') || q{};
            if ( $c->authenticate( $user, $pass ) ) {
                $c->session(user => $user);
                $c->redirect_to($c->config->{main_page});
            }
            else {
                $c->flash( message => 'Invalid credentials! ' );
                $c->redirect_to('/');
            }
        }
    });

    $r->get('/logout' => sub {
        my $c = shift;
        $c->session(expires => 1);
        $c->redirect_to('/');
    });

    my $logged_in = $r->under( sub {
        my $c = shift;

        my $access = {
            1 => 'users', #admin
            2 => 'download', #download
            3 => 'tickets', #create
            4 => 'reprint', #create
        };

        if ( $c->session('user') ) {
            my $path = $c->tx->req->url->path;
            my $groups = $c->app->users->get_user_group(${ $c->current_user }{id}, 1);

            for (@$groups) {
                #$c->app->log->debug( @$groups );
                #$c->app->log->debug( "access OK for user ${ $c->current_user }{login} to $path" ) if $path =~ /$access->{$_}/;
                return 1 if $path =~ /$access->{$_}/;
            }
        }

        $c->redirect_to('/');
        return undef;
    } );

    $logged_in->get('/tickets')->to('tickets#main');
    $logged_in->get('/tickets/config')->to('tickets#send_config');
    $logged_in->post('/tickets/create')->to('tickets#create');
#    #bases
    $logged_in->get('/bases')->to('bases#main');
    $logged_in->post('/bases')->to('bases#upload');
#    #logs
    $logged_in->get('/logs')->to('logs#main');
#    #users
    $logged_in->get('/users')->to('users#index');
    $logged_in->get('/users/<:user_id>')->to('users#index');
    $logged_in->post('/users/')->to('users#update');
#
    $logged_in->get('/download')->to('download#main');
    $logged_in->get('/download/<:dir>')->to('download#main');
    $logged_in->get('/download/<:dir>/<:file>')->to('download#main');

    $logged_in->get('/reprint')->to('reprint#index');
    $logged_in->get('/reprint/<:dir>')->to('reprint#index');

}

1;
