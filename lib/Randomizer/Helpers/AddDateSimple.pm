package Randomizer::Helpers::AddDateSimple;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        add_data_simple => sub {
            my ($self, $param) = @_;
            $self->app->log->debug("ADS: $param->{dir}/$param->{name}");

            #####
            my $max_l;
            tie (my @ry,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;
            my @tmp_arr = split ';', $_;
            my $l = scalar @tmp_arr;
            $max_l = $l if $l > $max_l;
            untie @ry;
            #####


            my @rows;
            open INPUT, '<:utf8', "$param->{dir}/$param->{name}" or $self->app->log->debug("Can't oprn file: $!");
            while (<INPUT>) {
                #my $line = $_;
                #chomp $line;
                #$line =~ s/\s+\z//;
                s/\s+\z//;
                chomp;

                #$_ .= ';' if /^.*[^;]$/;

                my $count = () = $_ =~ /\Q;/g;
                my $diff = $max_l - $count;

                if ($diff) {
                    $_ .= ';' for $diff;
                }
                

                $_ .= ';' unless $count eq $param->{columns};

                #unless ($count == ($param->{columns})) {
                #    my $k = $param->{column} - $count;
                #    $_ .= ';' x $k;
                #}

                #my @col = split ';', $_;
                #my $k = ($param->{columns} - scalar @col) ;



                #$self->app->log->debug(scalar @col . ' ' . $k . ' ' . (scalar @col + $k) . '|');

                push @rows, $_ . $param->{date} . ';';
            }
            #$self->app->log->debug(Dumper(\@rows));
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