package Randomizer::Helpers::Splitter;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        # name => $name,

        splitter => sub {
            my ($self, $param) = @_;

            #my $string;

            my $name = $param->{name};
            my $dir = $param->{dir};
            my $dn = "$dir/$name";
            my $part = 1;

            open IN, '<', $dn;
            open OUT, '+>>', "$dir/$part\_$name";
            while (<FILE>) {
            $part++ if ( $. % 1000000 ) == 0;
            print OUT $_;
            }
            close IN;
            close OUT;
            return 1;
        }
    );
}

1;
