package Randomizer::Helpers::CreateCheckFile2;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;
    $app->helper(
        create_ckeckfile_2 => sub {
            my ($self, $param) = @_;

            $param->{line_number} = 1;
            tie (my @fn,"Tie::File" ,$param->{dir} . '/'. $param->{name} ) or die $!;
            $param->{size} = @fn;
            $param->{file} = [@fn];
            untie @fn;



            my $count = eval {int($param->{size} / ($param->{count_2}))};
            $count-- unless $param->{size} % ($param->{count_2});

            open(CHECKLIST, ">>", $param->{dir} . '/check_list.csv') or die "Could not open 'check_list' $!\n";
            for (0 .. $count) {

                my $ln = (length($param->{line_number}) > 3) ? $param->{line_number} : '0' x (4 - length($param->{line_number})) . $param->{line_number};
               # ^.*;(\d+);(\d+);?(I)?;$

                my ($f_sn, $s_sn, $f_bn, $s_bn, $f_pn, $s_pn);
                ( $f_sn = $param->{file}[$_] ) =~ s/$param->{regex_for_sn}/$1/;
                ( $f_bn = $param->{file}[$_] ) =~ s/^.*;(\d+);(\d+);?(I)?;$/$1/;
                ( $f_pn = $param->{file}[$_] ) =~ s/^.*;(\d+);(\d+);?(I)?;$/$2/;

                ( $f_sn = $param->{file}[$_ * $param->{count_2}] ) =~ s/$param->{regex_for_sn}/$1/ if $_;
                ( $f_bn = $param->{file}[$_ * $param->{count_2}] ) =~ s/^.*;(\d+);(\d+);?(I)?;$/$1/ if $_;
                ( $f_pn = $param->{file}[$_ * $param->{count_2}] ) =~ s/^.*;(\d+);(\d+);?(I)?;$/$2/ if $_;
                if (defined  $param->{file}[ ($_+1)*$param->{count_2}-1]) {
                    ( $s_sn = $param->{file}[($_+1)*$param->{count_2}-1]) =~ s/$param->{regex_for_sn}/$1/;
                    ( $s_bn = $param->{file}[($_+1)*$param->{count_2}-1]) =~ s/^.*;(\d+);(\d+);?(I)?;$/$1/;
                    ( $s_pn = $param->{file}[($_+1)*$param->{count_2}-1]) =~ s/^.*;(\d+);(\d+);?(I)?;$/$2/;
                } else {
                    ( $s_sn = $param->{file}[ $param->{size} -1 ] ) =~ s/$param->{regex_for_sn}/$1/;
                    ( $s_bn = $param->{file}[ $param->{size} -1 ] ) =~ s/^.*;(\d+);(\d+);?(I)?;$/$1/;
                    ( $s_pn = $param->{file}[ $param->{size} -1 ] ) =~ s/^.*;(\d+);(\d+);?(I)?;$/$2/;
                }

                my $row = "$ln;$f_sn;$s_sn;$f_bn;$s_bn;$f_pn;$s_pn;$param->{count_1};";
                print CHECKLIST "$row\n";
                #$param->{b_n}++;
                #$param->{p_n} += $param->{count_2};
                #$self->app->log->debug( $row );
                $param->{line_number}++;
            }

            close CHECKLIST;

            return 1;
        }
    );
}


1;
