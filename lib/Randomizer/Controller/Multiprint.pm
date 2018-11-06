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

    for (1 .. 5) {
        next unless $self->req->upload('file_'.$_)->size;
        my $file = $self->req->upload('file_'.$_);
        $data->{$_} = {
            name    => $file->filename,
            column  => $self->param('column_'.$_),
            size    => $file->size,
            #slurp   => $file->slurp,
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
            # $max_l = $l if $l > $max_l;
        }
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


    # my @fh;
    # for my $k (sort {$a <=> $b} keys %$data) {
    #     open my $fh, '<', $dir . '/' . $data->{$k}->{name} or die "Unable to open '$_' for reading: $!";
    #     push @fh, $fh;
    # }
    #
    # open FILE, '>', "$dir/output.csv" or die;
    #
    # for (1 .. 5) {
    #     my $str = $fh[0][$_] . ';' . $fh[1][$_];
    #     print FILE $str;
    # }

    # my $ln = 1;
    # while (grep { not eof } @fh) {
    #     for my $fh (@fh) {
    #         if (defined(my $line = <$fh>)) {
    #             p $line;
    #             chomp $line;
    #             # print FILE $line;
    #             ($ln % (scalar keys %$data)) ? print FILE "$line\n" : print FILE "$line";
    #         }
    #     }
    #     $ln++;
    # }

    $self->render_file(
        'filepath'            => "$dir/output.csv",
        'format'              => 'application/x-download',
        'content_disposition' => 'inline',
        'cleanup'             => 0,
    );
    # for my $file ( @{$self->req->uploads('files')} ) {
    #     my $size = $file->size;
    #     my $name = $file->filename;
    #     my $row_number = 1;
    #     push @{$data->{names}}, $name;
    #     my $str = $file->slurp;
    #     for ( split "\n", $str ) {
    #         $data->{content}->{$name}->{$row_number++} = $_;
    #     }
    #     $data->{rows} = $row_number if !$data->{rows};
    # }
    # open FILE, '>>', 'trash/all.txt' or {
    #     mkdir 'trash' and `touch all.txt`and open FILE, '>>', 'trash/all.txt'
    # };
    #
    # for my $rn ( 1 .. ($data->{rows} - 1))  {
    #     my $line;
    #     for (@{$data->{names}}) {
    #         $line .= $data->{content}->{$_}->{$rn};
    #     }
    #     $line .= "\n";
    #     print FILE $line;
    # }
    #
    # open FILE2, '<', 'trash/all.txt';
    # my $f;
    # while (<FILE2>) {
    #     $f .= "$_\n";
    # }
    # p $f;
    #
    # $self->render(text => "-\n$f");
}

1;
