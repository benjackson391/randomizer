package Randomizer::Helpers::CreateBoxes;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        create_boxes => sub {
            my ($self, $param) = @_;
            $self->app->log->debug("CreateBoxes: $param->{dir}/$param->{name}");
            my @rows;
            open INPUT, '<:utf8', "$param->{dir}/$param->{name}" or $self->app->log->debug("Can't oprn file: $!");

            my ($count_1, $count_2, $line_number, $ln_3,$first_row, $draw) = (1,1,1,1,0,0);
            while (<INPUT>) {
                s/\s+\z//;
                chomp;

                $count_1 = (length($count_1) > 5) ? $count_1 : '0' x (6 - length($count_1)) . $count_1;
                $count_2 = (length($count_2) > 3) ? $count_2 : '0' x (4 - length($count_2)) . $count_2;
                if (!$draw) {
                    #$draw = $_;
                    ($draw = $_) =~ s/$param->{regex_for_draw}/$1/;
                }

                $_ .= "$count_1;$count_2;";

                if ( $line_number eq 1 || !(($line_number-1) % $param->{count_1}))
                {
                    ( my $sn = $_  ) =~ s/$param->{regex_for_sn}/$1/;
                    $self->create_ckeckfile_3({
                        ln           => $ln_3++,
                        sn           => $sn,
                        name         => $param->{name},
                        dir          => $param->{dir},
                        r_count_1    => $count_1,
                        count_1      => $param->{count_1},
                        order_number => $param->{order_number},
                        date         => $param->{date},
                        draw         => $draw,
                    });
                }

                unless ($line_number % $param->{count_1}) {
                    $_ .= "I;";
                }

                $count_1++ unless ($line_number % $param->{count_1});
                $count_2++ unless ($line_number % $param->{count_2});

                push @rows, $_;
                $line_number++;
                #$self->app->log->debug( $_ ) if $line_number < 17;
            }
            close INPUT;
            open OUTPUT, '>', "$param->{dir}/$param->{name}" or $self->app->log->debug("Can't oprn file: $!");
            foreach (@rows) {
                print OUTPUT "$_\n";
            }
            close OUTPUT;

            return 1;
        }
    );
}

1;