package Randomizer::Helpers::FileCheck;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use utf8;

sub register {

    my ($self, $app) = @_;
    $app->helper(

        file_check => sub {
            my ($self, $param) = @_;
            my %param = map { $_ => $param->{$_} } qw/dir name sort regex_for_sn/;
            open FILE, '<', "$param{dir}/$param{name}"; # or die "can't open file";

            while (<FILE>) {
                if ($param{sort}) {
                    if ($_ =~ s/$param{regex_for_sn}/$1/) {
                        if (exists $param{last_id}) {
                            push @{$param{sort_error}}, "$param{last_id};$_" if ($param{last_id}+1) != $_;
                        }
                        $param{last_id} = $_ ;
                    } else {
                        return [ 0, 'regex cant match string! Maybe you select wrong loto type or file?'];
                    }
                }
            }
            close FILE;
            return [1, 'Ok'];
        }
    );
}

1;
