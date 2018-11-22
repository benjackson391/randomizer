package Randomizer::Helpers::CreateCheckFile2;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;
    $app->helper(
        create_ckeckfile_2 => sub {
            my ($self, $param) = @_;

            my $log = $self->app->log;

            $param->{line_number} = 1;
            tie (my @fn,"Tie::File" ,$param->{dir} . '/'. $param->{name} ) or die $!;
            $param->{size} = @fn;
            $param->{file} = [@fn];
            untie @fn;

            ( my $draw = $param->{file}[0] ) =~ s/$param->{regex_for_draw}/$1/;

                my $count = eval {int($param->{size} / ($param->{count_2}))};
            $count-- unless $param->{size} % ($param->{count_2});

            open(CHECKLIST, ">>", $param->{dir} . '/check_list.csv') or die "Could not open 'check_list' $!\n";

            my @check_3;
            for (0 .. $count) {

                my $ln = (length($param->{line_number}) > 3) ? $param->{line_number} : '0' x (4 - length($param->{line_number})) . $param->{line_number};

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

                my $row = "$ln;$f_sn;$s_sn;$f_bn;$s_bn;$f_pn;$s_pn;$param->{count_1};$draw;";
                print CHECKLIST "$row\n";
                $param->{line_number}++;
                if ($param->{check_3}) {
                    push @check_3, $row;
                }
            }

            close CHECKLIST;

            if ($param->{check_3}) {
                open(CHECKLIST3, ">>", $param->{dir} . '/check_list_3.csv') or die "Could not open 'check_list' $!\n";
                    for (@check_3) {
                        $log->debug($_);
                        $_ =~ s/^(\d*;)(\d*)(\d);(\d*)(\d)(;.*)/$1$2$3;$2;$3;$4$5;$4;$5$6/;
                        $_ =~ s/^(\d*;)(0;0;)(.*)$/$1$2$2$3/ if $_ =~ /^\d*;0;0;.*$/;
                        print CHECKLIST3 "$_\n";
                    }
                close CHECKLIST3;
            }

            return 1;
        }
    );
}


1;
