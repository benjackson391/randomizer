package Randomizer::Helpers::CreateCheckFile;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;

sub register {
    my ($self, $app) = @_;
    $app->helper(
        create_ckeckfile => sub {
            my ($self, $param) = @_;

            my $tickets_in_pack = 50;
            my $packs_in_box = 60;
            my $box_number = 0001;
            my $pack_number = 1;
            my $line_number = 1;
            my %checklist;
            open ( FILE, $param->{dir} . '/'. $param->{name} ) or die;
            while ( my $line1 = <FILE> ) {
                if ( $line_number == 1 ) {
                    chomp($line1);
                    $checklist{$line_number} = $line1;
                }
                if ( !($line_number % ($tickets_in_pack * $packs_in_box))) {
                    chomp($line1);
                    $checklist{$line_number} = $line1;
                    #      last if $line_number == 36000;
                    defined(my $line2 = <FILE>) or last;
                    $line_number++;
                    chomp($line2);
                    $checklist{$line_number} = $line2;
                }
                $line_number++;
            }
            close FILE;
            my $row = '';
            foreach ( sort {$a <=> $b} keys %checklist ) {
                $box_number = int($box_number);
                $box_number < 10 ? $box_number = "000$box_number" :
                $box_number < 100 ? $box_number = "00$box_number" :
                $box_number < 1000 ? $box_number = "0$box_number" : 1;

                my $regexp = $param->{regex_for_sn};

                $checklist{$_} =~ /$regexp/;
                if ($row eq '') {
                    $row = $param->{order_number} . "-$box_number;" . $param->{draw}. ";$1";
                } else {
                    $row .= ";$1;$pack_number;" . ($pack_number + 59) . $param->{check1} . ';'. $param->{check2} . ';'. $param->{check3} . ';';
                    $pack_number += 60;
                    ###
                    #      print "$row\n";
                    open(my $fh, ">>", $param->{dir} . '/check_list.csv') or die "Could not open 'check_list' $!\n";
                    print $fh "$row\n";
                    close $fh;
                    ###
                    $row = '';
                    $box_number++;
                }
            }
            return 1;
        }
    );
}


1;
