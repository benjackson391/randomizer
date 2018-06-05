package Randomizer::Helpers::CreateCheckFile;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;
    $app->helper(
        create_ckeckfile => sub {
            my ($self, $param) = @_;

            #my $dir = $param->{dir};
            #my $name = $param->{name};

            my %param = (
                t_in_p => 50, #tickets_in_pack
                p_in_b => 60, #packs_in_box
                b_n    => 1,  #box_number
                p_n    => 1,  #pack_number
                l_n    => 1,  #line_number
            );

            tie (my @fn,"Tie::File" ,$param->{dir} . '/'. $param->{name} ) or die $!;
            $param{size} = @fn;
            $param{file} = [@fn];
            untie @fn;

            my $count = int($param{size} / ($param{t_in_p} * $param{p_in_b}));
            $count-- unless $param{size} % ($param{t_in_p} * $param{p_in_b});

            open(CHECKLIST, ">>", $param->{dir} . '/check_list.csv') or die "Could not open 'check_list' $!\n";
            for (0 .. $count) {
                my ($f_sn, $s_sn);
                ( $f_sn = $param{file}[$_] ) =~ s/$param->{regex_for_sn}/$1/;
                ( $f_sn = $param{file}[$_ * $param{t_in_p} * $param{p_in_b}] ) =~ s/$param->{regex_for_sn}/$1/ if $_;
                if (defined  $param{file}[ ($_+1)*$param{t_in_p}*$param{p_in_b}-1]) {
                    ( $s_sn = $param{file}[($_+1)*$param{t_in_p}*$param{p_in_b}-1]) =~ s/$param->{regex_for_sn}/$1/;
                } else {
                    ( $s_sn = $param{file}[ $param{size} -1 ] ) =~ s/$param->{regex_for_sn}/$1/;
                }

                my $box_number = int($param{b_n});
                $box_number < 10 ? $box_number = "000$box_number" :
                $box_number < 100 ? $box_number = "00$box_number" :
                $box_number < 1000 ? $box_number = "0$box_number" : 1;

                my $row = "$param->{order_number}-$box_number;$param->{draw};$f_sn;$s_sn;$param{p_n};".($param{p_n}+($param{p_in_b}-1));
                print CHECKLIST "$row\n";
                $param{b_n}++;
                $param{p_n} += $param{p_in_b};
            }

            close CHECKLIST;

            return 1;
        }
    );
}


1;
