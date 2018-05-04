package Randomizer;

use Modern::Perl;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Authentication;
use Mojolicious::Plugin::Bcrypt;
use Mojolicious::Plugin::Database;
use DBI;
use utf8;

use Randomizer::Model::User;

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
    $self->plugin('Randomizer::Helpers::ChangeChar');
    $self->plugin('Randomizer::Helpers::CreateCheckFile');
    $self->plugin('Randomizer::Helpers::XToPlus');
    $self->plugin('Randomizer::Helpers::Logger');

    $self->mode('development');
    $self->plugin('database', {
        dsn      => 'dbi:mysql:dbname=loto:host=192.168.10.114',
        username => 'root' || q{},
        password => 'JM47art1' || q{},
        options  => { mysql_enable_utf8 => 1, RaiseError => 1 },
        helper   => 'db',
    });

    $self->app->sessions->cookie_name('randomizer');
    $self->app->sessions->default_expiration(86400);

    $self->plugin('authentication', {
        load_user => sub {
            my ( $self, $uid ) = @_;
            my $sth = $self->db->prepare(' select * from users where id=? ');
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
                = $self->db->prepare(' select * from users where login = ? ');
            $sth->execute($username);
            return unless $sth;
            if ( my $res = $sth->fetchrow_hashref ) {
                my $salt = substr $password, 0, 2;
                if ( $self->bcrypt_validate( $password, $res->{password} ) ) {
                    $self->session(user => $username);
                    $self->flash(message => 'Thanks for logging in.');
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


	my $r = $self->routes;

	$r->add_condition(
			isUser => sub {
				my ($route, $c, $captures, $pattern) = @_;

				return 1 if $c->isAdmin($c->session->{'user_id'});
				return undef;
			}
		);

    $r->any('/logout')->to('default#logout');
    $r->any('/')->to('default#auth');
    #randomizer
    $r->get('/welcome')->to('loto1#loto1');
    $r->get('/loto1')->to('loto1#loto1');
    $r->post('/loto1')->to('loto1#generate');
    #randomizer2
    $r->get('/loto2')->to('loto2#loto2');
    $r->post('/loto2/upload')->to('loto2#generate2');
    #randomizer3
    $r->get('/loto3')->to('loto3#loto3');
    $r->post('/loto3/upload')->to('loto3#generate3');
    #bases
    $r->get('/bases')->to('bases#main');
    $r->post('/bases')->to('bases#upload');
    #logs
    $r->get('/logs')->to('logs#main');
    #users
    $r->get('/users')->to('users#list');
    $r->post('/users')->to('users#add');
    $r->any('/login')->to('default#login');
}

1;
