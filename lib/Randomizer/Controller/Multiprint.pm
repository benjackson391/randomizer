package Randomizer::Controller::Multiprint;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Encode::Detect::Detector;
use Data::Dumper;
use File::Copy;
use Encode;
use utf8;

sub main {
    my $self = shift;
    $self->render( template => 'default/multiprint');
}

sub upload {
    my $self = shift;
    my $data;

    my $dir = 'multiprint/' . b64_encode ($self->session('user') . " :: " .  time );
    chomp($dir);
    mkdir $dir, 0755;

    my $t_cnf = $self->app->config('ticket')->{5};
    my $l_cnf = $t_cnf->{include}->{$self->param('loto_type')};

    my $max_rows;

    for (1 .. 5) {
        next unless $self->req->upload('file_'.$_)->size;
        my $file = $self->req->upload('file_'.$_);
        $data->{$_} = {
            name    => $file->filename,
            column  => $self->param('column_' . $_),
            size    => $file->size,
            max_l_2 => 0,
        };

        $file->move_to("$dir/$data->{$_}->{name}");
    }

    for my $k (sort {$a <=> $b} keys %$data) {
        tie (my @ry,"Tie::File", $dir . '/'. $data->{$k}->{name} ) or die $!;
        if ($l_cnf->{regexp_modify}) {
            $self->app->log->debug('regexp_modify');
            my $find = $l_cnf->{regex};
            my $replace = $l_cnf->{substition};
            $_=~ s/$find/$replace/ee for @ry;
        }
        untie @ry;
    }



    for my $k (sort {$a <=> $b} keys %$data) {
        tie (my @ry,"Tie::File", $dir . '/'. $data->{$k}->{name} ) or die $!;
            my $max_l = 0;
            for (@ry) {
                s/\s+\z//;
                chomp;
                $_ .= ';' if /^.*[^;]$/;
                my @row = split ';', $_;
                my $l = scalar @row;
                $max_l = $l if $l > $max_l;
            }
            $data->{$k}->{max_l} = $max_l;
        untie @ry;
    }

    $self->app->log->debug(Dumper $data);

    for my $k (sort {$a <=> $b} keys %$data) {

        tie (my @ry,"Tie::File", $dir . '/'. $data->{$k}->{name} ) or die $!;



        my $i;
        for (@ry) {
            s/\s+\z//;
            chomp;

            my $count = () = $_ =~ /\Q;/g;
            my @split = split ';', $_;
            my $scalar = scalar @split;
            my $diff = $data->{$k}->{max_l} - $count;
            $self->app->log->debug("$diff = $data->{$k}->{max_l} - $count ( $scalar ) $_") if $i++ < 10;
            $_ .= ';'x int($diff) if $diff;
            $_ .= "$data->{$k}->{column};\n";
        }

        pop @ry unless $ry[-1] =~ /[\w\d]/;

        my $diff = $max_rows - scalar(@ry);
        $self->app->log->debug("diff $diff max_rows $max_rows  scalar(\@ry) "  .  scalar(@ry));
        if ($diff) {
            for (1 .. $max_rows - scalar(@ry)) {
                push @ry, '0;' x ($data->{$k}->{max_l_2} + 1) . "\n";
            }
        }

        untie @ry;
    }

    my $output;

    for my $k (sort {$a <=> $b} keys %$data) {
        next if not $data->{$k}->{name};
        my $ln;
        my $path = $dir . '/'. $data->{$k}->{name};
        $self->app->log->debug($path);

        tie (my @ry,"Tie::File", $path) or die $!;
        for (@ry) {
            $output->{int($ln++)} .= $_;
        }
        untie @ry;
    }

    open FILE, '>', "$dir/output.csv" or die;
    for my $k(sort {$a <=> $b} keys %$output) {
        print FILE $output->{$k} . "\n";
    }
    close FILE;

    $self->add_null_row({
        name      => "$dir/output.csv",
        add_null  => $self->param('add_null'),
    });

    $self->render_file(
        'filepath'            => "$dir/output.csv",
        'format'              => 'application/x-download',
        'content_disposition' => 'inline',
        'cleanup'             => 0,
    );
}

1;
