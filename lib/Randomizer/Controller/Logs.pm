package Randomizer::Controller::Logs;
use Mojo::Base 'Mojolicious::Controller';
use Encode::Detect::Detector;
use Data::Dumper;
use Encode;
use utf8;

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
        open (my $fn, '<:utf8', 'log/logger') or $self->app->log->debug("Can't open log file");
        while (<$fn>) {
            $logs{$line} = $_;
            $line++;
        }
        close $fn;

        $self->render( template => 'default/logs', logs => \%logs );
    }
}

1;