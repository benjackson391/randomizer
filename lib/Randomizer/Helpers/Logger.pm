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
            my ($ssec, $mmin, $hhour, $mmday, $mmon);
            $sec < 9 ? $ssec = "0$sec" : $ssec = $sec;
            $min < 9 ? $mmin = "0$min" : $mmin = $min;
            $hour < 9 ? $hhour = "0$hour" : $hhour = $hour;
            $mday < 9 ? $mmday = "0$mday" : $mmday = $mday;
            $mon < 9 ? $mmon = "0$mon" : $mmon = $mon;
            $year += 1900;

            my $string = "[ $mmday-$mmon-$year $hhour:$mmin:$ssec ][ $module ] $param";

            open my $fh, ">>", "log/logger";
            print $fh "$string\n" ;
            close $fh;

            return 1;
        }
    );
}

1;
