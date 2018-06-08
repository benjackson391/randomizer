package Randomizer::Controller::Download;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Archive::Zip qw( :ERROR_CODES );
use IO::Compress::Zip qw(:all);
use File::Find::Rule;
use File::Basename;
use Data::Dumper;
use Mojo::Upload;
use Encode;
use utf8;

sub main {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {
        my $l = $self->app->log;
        if ($self->param("dir")) {
            if ($self->param("file")) {
                my $file = b64_decode($self->param("file"));

                my @file = File::Find::Rule->file()
                    ->name( $file )
                    ->in( "uploaded/" . $self->param("dir") );

                $self->render_file(
                    'filepath' => $file[0],
                    'format'   => 'application/x-download',
                    'content_disposition' => 'inline',
                    'cleanup'  => 0,
                    );
            } else {
                my $d = $self->param("dir");

                opendir(my $dh, "uploaded/$d");
                my @dirs = readdir($dh);
                @dirs = grep ! /^[\.]*$/, @dirs;

                my %dirs;
                foreach (@dirs) {
                    my $size = -s "uploaded/$d/$_";
                    $dirs{b64_encode($_)} = $size;
                }
                $self->render( template => 'default/download2', files => \%dirs );
            }
        } else {
            my %items;
            open (LOG, '<:utf8', 'log/logger') or die;

            while (<LOG>) {
                chomp($_);
                my @line = split " :: ", $_;
                $line[0] =~ s/^\[.+\]\[.+\]\s(.*)$/${1}/;
                push @line, ( split "/", $line[0] );
                ($items{$.}{t_name}, $items{$.}{name}, $items{$.}{order}, $items{$.}{dir}, $items{$.}{dir64}) = ($line[1], $line[2], $line[3], $line[4], $line[5]  );
                ($items{$.}{login}, $items{$.}{date}) = split ' :: ', b64_decode($line[5]);
                $items{$.}{basefile} = 1 if -r "uploaded/$line[4]/base.csv";
                $items{$.}{checklist} = 1 if -f "uploaded/$line[4]/check_list.csv";
                $items{$.}{archive} = 1 if -f "uploaded/$line[4]/" . $items{$.}{order} . ".zip";
            }
            close LOG;

            $self->stash( files => \%items );
            $self->render( template => 'default/download' );
        }

    }
}

1;
