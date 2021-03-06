package Randomizer::Controller::Logs;
use Mojo::Base 'Mojolicious::Controller';
use Encode::Detect::Detector;
use Data::Dumper;
use Encode;
use utf8;

sub main {
    my $self = shift;
        $self->app->log->debug("log main");
        my %logs;
        my $line = 1;
        open (my $fn, '<:utf8', 'log/logger') or {mkdir 'log' and `touch logger`};
        while (<$fn>) {
            $logs{$line} = $_;
            $line++;
        }
        close $fn;

        $self->render( template => 'default/logs', logs => \%logs );
}

1;
