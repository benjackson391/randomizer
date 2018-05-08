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

            #my $string;

            my $name = $param->{name};
            my $dir = $param->{dir};
            my $dn = "$dir/$name";

            tie (my @ry,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;
            $_=~ tr/X/+/ for @ry;
            untie @ry;
#            $dn = "$dir/output_$name" if ( -f "$dir/output_$name" );

#            open ( my $fh1, "<", $dn )
#                or $self->app->log->debug("Cant't open file: " . $param->{name});
#            while (<$fh1>) {
#                next if $_ =~ /^\s*$/;
#                $string .= $_;
#            }
#            close $fh1;
            #$string =~ tr/X/+/;
#            open my $fh2, "+>", $param->{dir} . '/'. $param->{name};
#            print $fh2 $string;
#            close $fh2;

            return 1;
        }
    );
}

1;
