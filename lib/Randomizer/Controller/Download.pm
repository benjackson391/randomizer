package Randomizer::Controller::Download;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Mojo::Upload;
use File::Basename;
use File::Find::Rule;
use Archive::Zip qw( :ERROR_CODES );
use IO::Compress::Zip qw(:all);
use utf8;
use Data::Dumper;


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
            $l->debug('--- ' . $self->param("dir"));

            if ($self->param("file")) {
                my @file = File::Find::Rule->file()
                    ->name($self->param('file') . '.*' )
                    ->in( 'uploaded/'.$self->param('dir') );

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
                @dirs           = grep ! /^[\.]*$/, @dirs;
                $self->render( template => 'default/download2', files => \@dirs );
            }
        } else {
            my %items;
            open (LOG, '<:utf8', 'log/logger') or die;

            while (<LOG>) {
                chomp($_);
                my @line = split " :: ", $_;
                $self->app->log->debug(Dumper( \@line));
                $line[0] =~ s/^\[.+\]\[.+\]\s(.*)$/${1}/;
                push @line, ( split "/", $line[0] );
                ($items{$.}{name}, $items{$.}{order}, $items{$.}{dir}, $items{$.}{dir64}) = ($line[1], $line[2], $line[3], $line[4] );
                ($items{$.}{login}, $items{$.}{date}) = split ' :: ', b64_decode($line[4]);
                $items{$.}{basefile} = 1 if -r "uploaded/$line[4]/base.csv";
                $items{$.}{checklist} = 1 if -f "uploaded/$line[4]/check_list.csv";
                $items{$.}{archive} = 1 if -f "uploaded/$line[4]/" . $items{$.}{order} . ".zip";
            }
            close LOG;
            #$self->app->log->debug( '---' . Dumper( \%items));
            $self->stash( files => \%items );
            $self->render( template => 'default/download' );
        }

    }
}

1;
