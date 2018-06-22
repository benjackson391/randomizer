package Randomizer::Controller::Reprint;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Archive::Zip qw( :ERROR_CODES );
use IO::Compress::Zip qw(:all);
use File::Find::Rule;
use File::Basename;
use Data::Dumper;
use Mojo::Upload;
use Tie::File;
use Encode;
use utf8;

sub index {
    my $self = shift;
    my $param;
    if (!$self->param("dir")) {
#        if ($self->param("file")) {
#            my $file = b64_decode($self->param("file"));
#
#            my @file = File::Find::Rule->file()
#                ->name( $file )
#                ->in( "uploaded/" . $self->param("dir") );
#
#            $self->render_file(
#                'filepath' => $file[0],
#                'format'   => 'application/x-download',
#                'content_disposition' => 'inline',
#                'cleanup'  => 0,
#            );
#        } else {
#            my $d = $self->param("dir");
#
#            opendir(my $dh, "uploaded/$d");
#            my @dirs = readdir($dh);
#            @dirs = grep ! /^[\.]*$/, @dirs;
#
#            my %dirs;
#            foreach (@dirs) {
#                my $size = -s "uploaded/$d/$_";
#                $dirs{b64_encode($_)} = $size;
#            }
#            $self->render( template => 'default/download2', files => \%dirs );
#        }

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
        $self->render( template => 'default/reprint' );
    } else {
        ($param->{dir}, $param->{reprint}) = split /\--/, $self->param("dir");
        for (split ';', $param->{reprint}) {
            if (/^\d+[-]\d+/) {
                my @el = split '-';
                $param->{rows}->{$el[0]} = $el[1];
            } else {
                $param->{rows}->{$_} = $_;
            }
        }

        for (sort {$a <=> $b} keys $param->{rows}) {
            if ($_ == $param->{rows}->{$_}) {
                $param->{output}->{$_} = 1;
            } else {
                for ($_ .. $param->{rows}->{$_}) {
                    $param->{output}->{$_} = 1;
                }
            }
        }


        my @file = File::Find::Rule->file()
            ->name( qr/^((?!((.+\.zip|check_list\.csv|.+\.dist))).+)/ )
            #->name('*.*')
            ->in( "uploaded/" . $param->{dir} );

        my $string;
        tie my @lines, 'Tie::File', $file[0];

        my $temp_file_name =  'reprint_' . time . '.csv';
        open my $temp_file, '>>', $temp_file_name;
        for (sort {$a <=> $b} keys $param->{output}) {
            print $temp_file "$lines[$_]\n";
        }
        close $temp_file;
        untie @lines;

        $self->render_file(
            'filepath' => $temp_file_name,
            'format'   => 'application/x-download',
            'content_disposition' => 'inline',
            'cleanup'  => 1,
        );
        #$self->render( text => "$param->{dir}  --- $param->{reprint} №№№№№№ \n\n\n\n\n". $self->param("dir"));

#        foreach ( sort {$a <=> $b} keys %{ $param->{rows} }) {
#            if ($_ == $temp->{$_}) {
#                $output->{$_} = 1;
#            } else {
#                for ($_ .. $temp->{$_}) {
#                    $output->{$_} = 1;
#                }
#            }
#        }
#
#        for ( sort {$a <=> $b} keys %$output) {
#            print "$_\n";
#        }


    }
}

1;
