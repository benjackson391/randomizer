package Randomizer::Helpers::CreateCheckFile3;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;
    $app->helper(
        create_ckeckfile_3 => sub {
            my ($self, $param) = @_;

            open(CHECKLIST, ">>", $param->{dir} . '/check_list_2.csv') or die "Could not open 'check_list' $!\n";

            my $ln = $param->{ln};
            $ln = (length($ln) > 3) ? $ln : '0' x (4 - length($ln)) . $ln;

            my $row = "$ln;";
            $row .= "$param->{order_number};";
            $row .= $param->{sn} . ';';
            $param->{sn} =~ /(\d{16})(\d{1})/;
            $row .= "$1;$2;";
            $row .= ($param->{r_count_1}) . ';';
            $row .= $param->{count_1} . ';';
            $row .= $param->{date} . ';';

            print CHECKLIST "$row\n";
            #$self->app->log->debug( $row ) if $param->{ln} < 17;
            close CHECKLIST;

            return 1;
        }
    );
}


1;
