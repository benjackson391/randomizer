package Randomizer::Controller::Logs;
use Mojo::Base 'Mojolicious::Controller';
use Encode::Detect::Detector;
use Data::Dumper;
use Encode;
use utf8;

sub main {
    my $self = shift;
    $self->render( template => 'default/multiprint', text => 'HW!' );
}

1;
