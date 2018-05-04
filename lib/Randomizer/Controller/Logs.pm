package Randomizer::Controller::Logs;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub main {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {
        $self->app->log->debug("log main");
        my %logs;
        my $line = 1;
        open (my $fn, '<', 'log/logger') or $self->app->log->debug("Can't open log file");
        while (<$fn>) {
            $logs{$line} = $_;
            $line++;
        }
        close $fn;

# Manipulate session
#$self->session->{foo} = 'bar';
#my $foo = $self->session->{foo};
#delete $self->session->{foo};
# Set
        #my $foo = $self->session('foo');
       # if (!$foo) {
      #      $self->session(foo => 'bar');
     #   }

      #  my $rand = $self->session('randomizer');
       # my $rand2 = $self->cookie('randomizer');

# Get
#$self->session('foo');

        #my $dump = Dumper($self->session() );
        #$self->flash( message => "--$rand|$rand2--" );
        $self->render( template => 'default/logs', logs => \%logs );
        #$self->render( template => 'default/logs' logs => ( 1 => 'dasgasgdds'));
#        $self->render( template => 'default/logs' logs => \%logs);
        #$self->render( template => 'default/logs' );
    }
}

1;