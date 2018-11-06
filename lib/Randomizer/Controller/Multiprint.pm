package Randomizer::Controller::Multiprint;
use Mojo::Base 'Mojolicious::Controller';
use Encode::Detect::Detector;
use Data::Dumper;
use Encode;
use utf8;
use DDP;

sub main {
    my $self = shift;
    $self->render( template => 'default/multiprint');
}

sub upload {
    my $self = shift;
    my $data;

    for my $file ( @{$self->req->uploads('files')} ) {
        my $size = $file->size;
        my $name = $file->filename;
        my $row_number = 1;
        push @{$data->{names}}, $name;
        my $str = $file->slurp;
        for ( split "\n", $str ) {
            $data->{content}->{$name}->{$row_number++} = $_;
        }
        $data->{rows} = $row_number if !$data->{rows};
    }
    open FILE, '>>', 'trash/all.txt' or {
        mkdir 'trash' and `touch all.txt`and open FILE, '>>', 'trash/all.txt'
    };

    for my $rn ( 1 .. ($data->{rows} - 1))  {
        my $line;
        for (@{$data->{names}}) {
            $line .= $data->{content}->{$_}->{$rn};
        }
        $line .= "\n";
        print FILE $line;
    }

    open FILE2, '<', 'trash/all.txt';
    my $f;
    while (<FILE2>) {
        $f .= "$_\n";
    }
    p $f;

    $self->render(text => "-\n$f");
}

1;
