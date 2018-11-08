package Randomizer::Helpers::AddDate;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        add_date => sub {
            my ($self, $param) = @_;
            my @rows;

            #####
            my $max_l;
            tie (my @ry,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;
            for (@ry) {
                my @tmp_arr = split ';', $_;
                my $l = scalar @tmp_arr;
                $max_l = $l if $l > $max_l;
            }
            untie @ry;
            #####

            open FILE, '<:utf8', $param->{dir} . '/'. $param->{name};
            my $i = 0;
            while (<FILE>) {
                my $line1 = $_;
                my $line2 = <FILE>;
                foreach (($line1, $line2)) {
                    chop;
                    chop;
                    $_ .= ';' if /^.*[^;]$/;
                    my $count = () = $_ =~ /\Q;/g;
                    my $diff = $max_l - $count;
                    $_ .= ';'x$diff if $diff;
                }
                push @rows, "$line1$line2$param->{date}\n";
                $i++;
            }
            open FILE, '>', $param->{dir} . '/'. $param->{name};
            foreach (@rows) {
                print FILE $_ ;
            }

            return 1;
        }
    );
}

1;