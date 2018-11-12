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

sub builder_1 {
    my ($self, $row) = @_;
    $row =~ s/\s+\z//;
    chomp $row;
    $row .= ';' if $row =~ /^.*[^;]$/;
    my @row = split ';', $row;
    my $l = scalar @row;
    return [$row, $l];
    #$max_l = $l if $l > $max_l;

}

sub upload {
    my $self = shift;
    my $data;

    my $dir = 'multiprint/' . b64_encode ($self->session('user') . " :: " .  time );
    chomp($dir);
    mkdir $dir, 0755;

    my $l_cnf = $self->app->config('ticket')->{5}->{include}->{$self->param('loto_type')};
    #my $l_cnf = $t_cnf->{include}->{$self->param('loto_type')};

    for (1 .. 5) {
        next unless $self->req->upload('file_'.$_)->size;
        my $file = $self->req->upload('file_'.$_);
        $data->{$_} = {
            name    => $file->filename,
            column  => $self->param('column_' . $_),
            size    => $file->size,
            rows    => [split "\n", $file->slurp],
            max_col => 0,
        };
        $file->move_to("$dir/$data->{$_}->{name}");
    }

    my $max_rows = [sort {$b <=> $a} map {scalar @{$data->{$_}->{rows}}} keys %$data]->[0];

    for my $k (sort {$a <=> $b} keys %$data) {
        if ($l_cnf->{regexp_modify}) {
            my $find = $l_cnf->{regex};
            my $replace = $l_cnf->{substition};
            for (@{$data->{$k}->{rows}}) {
                $_=~ s/$find/$replace/ee;
            }
        }
        for (@{$data->{$k}->{rows}}) {
            s/\s+\z//;
            chomp;
            $_ .= ';' if /^.*[^;]$/;
            my @row = split ';', $_;
            $data->{$k}->{max_col} = scalar @row if scalar @row > $data->{$k}->{max_col};
        }

        my $i;
        for (@{$data->{$k}->{rows}}) {
            my $count = () = $_ =~ /\Q;/g;
            # my $scalar = scalar (split ';', $_);
            my $diff = $data->{$k}->{max_col} - $count;
            $_ .= ';'x int($diff) if $diff;
            $_ .= "$data->{$k}->{column};";
            $self->app->log->debug("$diff = $data->{$k}->{max_col} - $count") if $i++ < 10;
        }

        while (${$data->{$k}->{rows}}[-1] =~ /[s+]/) {
           pop @{$data->{$k}->{rows}};
        }
        while (scalar(@{$data->{$k}->{rows}}) != $max_rows) {
            push @{$data->{$k}->{rows}}, '0;'x ($data->{$k}->{max_col} + 1);
        }
    }

    open FILE, '>', "$dir/output.csv" or die;
    my @keys = sort {$a <=> $b} keys %$data;
    for my $row (0 .. ($max_rows - 1)) {
        my $str;
        for my $k (@keys) {
            my $el = ${$data->{$k}->{rows}}[$row];
            $str .= $el;
        }
        print FILE "$str\n";
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
