package Randomizer::Helpers::XToPlus;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        # name => $name,

        x_to_plus => sub {
            my ($self, $param) = @_;

            tie (my @ry,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;
            $_=~ tr/X/+/ for @ry;
            untie @ry;

            return 1;
        }
    );
}

1;
