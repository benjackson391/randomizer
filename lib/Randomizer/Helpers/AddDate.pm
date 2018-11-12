package Randomizer::Helpers::AddDate;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;
use utf8;

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
               # $self->app->log->debug($i . ' ' . $line1.$line2.$param->{date}) if $i > 362970;
            }

            #tie (my @ry2,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;
            #    @ry2 = @rows;
            #untie @ry2;
            close FILE;
            open FILE2, '>', $param->{dir} . '/'. $param->{name} or die;
            my $ii = 1;
            foreach (@rows) {
                $self->app->log->debug($_) if $ii > 362950;
                print FILE2 $_ ;
                $ii++;
            }
            close FILE2;

            return 1;
        }
    );
}

1;