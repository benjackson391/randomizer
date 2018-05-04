package Randomizer::Helpers::Logger;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        # name => $name,

        logger => sub {
            my ($self, $param) = @_;

            my $module = "$self";
            $module =~ /^(\S*)=HASH\(.*\)/;
            $module = $1;

            my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

            $sec = "0$sec" if $sec < 9;
            $min = "0$min" if $min < 9;
            $hour = "0$hour" if $hour < 9;
            $mday = "0$mday" if $mday < 9;
            $mon = "0$mon" if $mon < 9;

            $year += 1900;

            my $string = "[ $mday-$mon-$year $hour:$min:$sec ][ $module ] $param";

            open my $fh, ">>", "log/logger";
            print $fh $string ;
            close $fh;

            return 1;
        }
    );
}

1;
