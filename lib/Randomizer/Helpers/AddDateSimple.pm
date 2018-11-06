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
            for (@ry) {
                my @tmp_arr = split ';', $_;
                my $l = scalar @tmp_arr;
                $max_l = $l if $l > $max_l;
            }
            untie @ry;
            #####


            my @rows;
            open INPUT, '<:utf8', "$param->{dir}/$param->{name}" or $self->app->log->debug("Can't oprn file: $!");
            my $tmblr;
            while (<INPUT>) {
                s/\s+\z//;
                chomp;

                $_ .= ';' if /^.*[^;]$/;

                my $count = () = $_ =~ /\Q;/g;
                my $diff = $max_l - $count;

                #$self->app->log->debug( "diff: $diff max_l: $max_l count: $count" ) if $tmblr < 10;
                $tmblr++;


                $_ .= ';'x$diff if $diff;

                #$_ .= ';' unless $count eq $param->{columns};
                push @rows, $_ . $param->{date} . ';';
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