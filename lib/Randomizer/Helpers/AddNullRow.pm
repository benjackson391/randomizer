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
            my $log = $self->app->log;
            my $name = $param->{name};

            my @lines;
            tie @lines, 'Tie::File', $name;
            my $lines = $#lines + 1;
            my $last_line = $lines[$#lines];
            untie @lines;

            $log->debug("[Helpers::AddNullRow] lines: $lines in $name");

            my $residue = $lines % $param->{add_null};

            if ($residue) {
                my $to_add = $param->{add_null} - $residue;
                open my $fh, "+>>", $param->{name};
                print "\n" if $last_line =~ /\S+/;
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
