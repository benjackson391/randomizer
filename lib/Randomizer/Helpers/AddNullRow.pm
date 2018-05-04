package Randomizer::Helpers::AddNullRow;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        add_null_row => sub {
            my ($self, $param) = @_;
            #my $log = $self->app->log;
            my $name = $param->{name};
#            $log->debug("[Helpers::AddNullRow] file: " . $name);
#            my $lines = qx("find /c /v \"\" " . $param->{name});
#            my $lines = qx("wc " . $param->{name});
##            $lines=~/^\n-{10}\s.*:\s(\d+)/;
#            $lines =~/^\s*(\d*)\s*\d*\s\d*\s\S*$/;
#            $lines = $1;
            my $lines = `wc -l < $name`;
            chomp($lines);

            #$log->debug("[Helpers::AddNullRow] lines: $lines");

            my $residue = $lines % $param->{add_null};

            if ($residue) {

                my @lines;
                tie @lines, 'Tie::File', $param->{name};
                
                my $to_add = $param->{add_null} - $residue;
                open my $fh, "+>>", $param->{name};
                print "\n" if $#lines =~ /\S+/;
                for (1 .. $to_add) {
                    print $fh $param->{null_row} . "\n";
                }
                close $fh;
            }
            return 1;
        }
    );
}


1;
