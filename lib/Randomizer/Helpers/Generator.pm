package Randomizer::Helpers::Generator;
use base 'Mojolicious::Plugin';
use Mojo::Util qw(b64_encode b64_decode);
use Archive::Zip qw( :ERROR_CODES );
use File::Find::Rule;
use File::Basename;
use Modern::Perl;
use Data::Dumper;

sub register {

    my ($self, $app) = @_;
    $app->helper(
        # name => $name,

        generator => sub {
            my ($self, $param) = @_;

            my $log = $self->app->log;
            my $start_time = time;

            $log->debug( "benchmark 1: " . (time - $start_time));

            my $progress;
            my ($tickets_in_pack, $packs_in_box, $d, $cycle, $residue) = (50, 60, 500_000, 0, 0);

            my $type        = $param->{LotoType};
            my $count       = $param->{Count};
            my $OrderNumber = $param->{OrderNumber};
            my $Draw        = $param->{Draw};

            my $db_table_name = $self->config->{ticket}->{'1'}->{include}->{$type}->{name};
            my $dir = 'uploaded/' . b64_encode ($self->session('user') . " :: " .  time );
            chomp($dir);
            mkdir $dir, 0755;
            my $name = "$OrderNumber-$db_table_name-$count.csv";

            $residue = $count;

            if ( $count > $d ) {
                $residue = $count % $d;
                $cycle = ( $count - $residue ) / $d;
            }

            my $rand = ( $d / $self->config->{ticket}->{'1'}->{include}->{$type}->{count} ) . 5;

            #   # Запрос случайных записей по 500_000 штук
            if ( $cycle ) {
                for (1 .. $cycle) {
                    my $sth = $self->db->prepare("SELECT * FROM (SELECT name FROM $db_table_name WHERE RAND()<=$rand) AS t1 ORDER BY RAND() LIMIT $d");
                    $sth->execute();
                    my $data = $sth->fetchall_arrayref;
                    $sth->finish;
                    open(my $fh, ">>", "$dir/$name") or die "Could not open '$name' $!\n";
                    foreach ( @{$data} ) {chomp($_->[0]); print $fh "$_->[0]\n";}
                    close $fh;
                    $progress += $d;
                }
            }
            #   # Запрос случайных записей остаток
            if ($residue) {
                my $sth = $self->db->prepare("SELECT * FROM (SELECT name FROM $db_table_name WHERE RAND()<=$rand) AS t1 ORDER BY RAND() LIMIT $residue");
                $sth->execute();
                my $data = $sth->fetchall_arrayref;
                $sth->finish;
                open(my $fh, ">>", "$dir/$name") or die "Could not open '$name' $!\n";
                foreach ( @{$data} ) {chomp($_->[0]); print $fh "$_->[0]\n";}
                close $fh;
                $progress += $residue;
            }

            return {dir => $dir, name => $name};
        }
    );
}

1;
