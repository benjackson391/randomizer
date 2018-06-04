package Randomizer::Helpers::FileCheck;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;
use utf8;

sub register {

    my ($self, $app) = @_;
    $app->helper(

        file_check => sub {
            my ($self, $param) = @_;


            my %param = map { $_ => $param->{$_} } qw/dir name sort regex_for_sn/;

            #$self->app->log->debug( Dumper(\%param) );

            tie (my @fn,"Tie::File" ,$param{dir} . '/'. $param{name} ) or die $!;
            my $i;
            for (@fn) {
                if ($param{sort}) {
                    if ($_ =~ s/$param{regex_for_sn}/$1/) {
                        if (exists $param{last_id}) {
                            push @{$param{sort_error}}, "$param{last_id};$_" if ($param{last_id}+1) != $_;
                        }
                        $param{last_id} = $_ ;
                    } else {
                        return [ 0, "Regex can't match string! Maybe you select wrong loto type or file? $i : $_" ];
                    }
                }
                $i++;
            }
            untie @fn;

            #open FILE, '<', "$param{dir}/$param{name}"; # or die "can't open file";
            #my $i;
#            while (<FILE>) {
#                if ($param{sort}) {
#                    $self->app->log->debug( $param{regex_for_sn} ) if $i < 2;
#                    if ($_ =~ s/$param{regex_for_sn}/$1/) {
#                        $self->app->log->debug( "$_ $1" ) if $i < 2;
#                        if (exists $param{last_id}) {
#                            push @{$param{sort_error}}, "$param{last_id};$_" if ($param{last_id}+1) != $_;
#                        }
#                        $param{last_id} = $_ ;
#                    } else {
#                        return [ 0, 'regex cant match string! Maybe you select wrong loto type or file?' ];
#                    }
#                }
#                $i++
#            }
#            close FILE;
            return [0, Dumper($param{sort_error})] if exists $param{sort_error};
            return [1, 'Ok'];
        }
    );
}

1;
