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

    my $loto_type =  $self->param('loto_type');

    my $t_cnf = $self->app->config('ticket')->{5};
    my $l_cnf = $t_cnf->{include}->{$self->param('loto_type')};

    for (1 .. 5) {
        next unless $self->req->upload('file_'.$_)->size;
        my $file = $self->req->upload('file_'.$_);
        $data->{$_} = {
            name    => $file->filename,
            column  => $self->param('column_'.$_),
            size    => $file->size,
        };
        $file->move_to("$dir/$data->{$_}->{name}");
    }

    for my $k (sort {$a <=> $b} keys %$data) {
        my $max_l;
        tie (my @ry,"Tie::File", $dir . '/'. $data->{$k}->{name} ) or die $!;
        for (@ry) {
            my @tmp_arr = split ';', $_;
            my $l = scalar @tmp_arr;
            if (!$max_l || $l > $max_l) {$max_l = $l;}
        }

        if ($l_cnf->{regexp_modify}) {
            my $find = $l_cnf->{regex};
            my $replace = $l_cnf->{substition};
            $_=~ s/$find/$replace/ee for @ry;
        }

        my $add_null_row = $self->add_null_row({
            name     => "$dir/$data->{$k}->{name}",
            add_null => 1000,
        });

        for (@ry) {
            s/\s+\z//;
            chomp;
            $_ .= ';' if /^.*[^;]$/;
            my $count = () = $_ =~ /\Q;/g;
            my $diff = $max_l - $count;
            $_ .= ';'x$diff if $diff;
            $_ .= "$data->{$k}->{column};\n";
        }
        untie @ry;
    }

    my $output;

    for my $k (sort {$a <=> $b} keys %$data) {
        my $ln;
        tie (my @ry,"Tie::File",$dir . '/'. $data->{$k}->{name} ) or die $!;
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

    $self->render_file(
        'filepath'            => "$dir/output.csv",
        'format'              => 'application/x-download',
        'content_disposition' => 'inline',
        'cleanup'             => 0,
    );
}

1;
