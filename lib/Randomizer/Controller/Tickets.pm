package Randomizer::Controller::Tickets;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_encode b64_decode);
use Archive::Zip qw( :ERROR_CODES );
use Encode::Detect::Detector;
use File::Find::Rule;
use File::Basename;
use Mojo::Upload;
use Data::Dumper;
use File::Copy;
use Tie::File;
use JSON;
use utf8;

sub main {
    my $self = shift;
        my $cnf = $self->app->config('ticket');
        $self->render( template => 'default/ticket', config => $cnf );
}

sub send_config {
    my $self = shift;
    if ( not $self->user_exists ) {
        $self->flash( message => 'You must log in to view this page' );
        $self->redirect_to('/');
        return;
    }
    else {
        my $cnf = $self->app->config('ticket');
        $self->render( json => $cnf );
    }
}

sub create {
    my $self = shift;
    my (%param, $fileuploaded);
    my $log = $self->app->log;

    map { $param{$_} = $self->param($_) } qw/expansion order_number ticket_type loto_type draw t_in_p p_in_b p_n add_null/;

    my $t_cnf = $self->app->config('ticket')->{$param{ticket_type}};
    my $l_cnf = $t_cnf->{include}->{$param{loto_type}};

    foreach ( @{$t_cnf->{add_fields} } ) {
        if ($_ eq 'upload_file') {
            return $self->redirect_to('/tickets')
                unless $self->param('upload_file');
            $fileuploaded = $self->req->upload('upload_file');
            $param{size} = $fileuploaded->size;
            $param{name} = $fileuploaded->filename;
        } else {
            $param{$_} = $self->param($_);
        }
    }

    if ( $param{ticket_type} == 1 ) {
        my $generator = $self->generator({
            LotoType    => $param{loto_type},
            Count       => $param{count},
            OrderNumber => $param{order_number},
            Draw        => $param{draw},
            expansion   => $param{expansion},
        });
        if ($generator) {

            $self->logger("$generator->{dir} :: $t_cnf->{name} :: $l_cnf->{name} :: $param{order_number}");

            my $add_null_row = $self->add_null_row({
                name     => "$generator->{dir}/$generator->{name}",
                add_null => $param{add_null},
            });
            if ($add_null_row) {
                my $check_file = $self->create_ckeckfile({
                    name => $generator->{name},
                    dir => $generator->{dir},
                    regex_for_sn => $l_cnf->{regex_for_sn},
                    order_number => $param{order_number},
                    draw => $param{draw},
                    p_n => $param{p_n},
                    p_in_b => $param{p_in_b},
                    t_in_p => $param{t_in_p},
                });
                if ($check_file) {

                    my @files = File::Find::Rule->file()->name( '*.csv',  '*.txt' )->in( $generator->{dir} );
                    my $obj = Archive::Zip->new();
                    map { $obj->addFile($_, basename($_)) } @files;
                    if ($obj->writeToFileNamed("$generator->{dir}/$param{order_number}.zip") == AZ_OK) {
                        $self->render_file(
                            'filepath' => "$generator->{dir}/$param{order_number}.zip",
                            'format'   => 'application/x-download',
                            'content_disposition' => 'inline',
                            'cleanup'  => 1,
                        );
                    }
                }
            }
        }
    }
    else {
        $log->debug("Ticket type = " . $param{ticket_type});
        my $dir = 'uploaded/' . b64_encode ($self->session('user') . " :: " .  time );
        chomp($dir);
        mkdir $dir, 0755;
        #$param{name} =~ s/(.+)\.\w+$/$1.$param{expansion}/;
        ###
        if ( $param{name} =~ /(.*)\.(.*)/) {
            $param{name} = "$1.$param{expansion}";
        } else {
            $param{name} .= ".$param{expansion}";
        }
        ###
        $log->debug("File name - " . $param{name});
        $fileuploaded->move_to("$dir/$param{name}");
        copy("$dir/$param{name}", "$dir/$param{name}.dist");

        $self->logger("$dir :: $t_cnf->{name} :: $l_cnf->{name} :: $param{order_number}");
        if ($l_cnf->{regex_for_sn}) {
            $log->debug("Start: regex fo sn");
            my $file_check = $self->file_check({
                dir          => $dir,
                name         => $param{name},
                sort         => 1,
                regex_for_sn => $l_cnf->{regex_for_sn},
            });
            if ($file_check->[0]) {
                $log->debug("Start: regex fo sn - ok");
                if ($l_cnf->{regexp_modify}) {
                    $self->app->log->debug("Start: regex modify");
                    $self->regexp_modify({
                        name => $param{name},
                        dir => $dir,
                        regex => $l_cnf->{regex},
                        substition => $l_cnf->{substition},
                    });
                    $log->debug("Start: regex modify - ok");
                }
                if ($l_cnf->{add_date}) {
                    $log->debug("Start: add date");
                    my @rows;
                    open FILE, '<:utf8', "$dir/$param{name}";
                    my $i = 0;
                    while (<FILE>) {
                        my $line1 = $_;
                        my $line2 = <FILE>;
                        foreach (($line1, $line2)) {
                            chop;
                            chop;
                            $_ .= ';' if /^.*[^;]$/;
                        }
                        push @rows, "$line1$line2$param{date}\n";
                        $i++;
                    }
                    open FILE, '>', "$dir/$param{name}";
                    foreach (@rows) {
                        print FILE $_ ;
                    }
                    $log->debug("Start: add date - ok");
                }

                if ($l_cnf->{add_date_simple}) {
                    $log->debug("Start: add date simple");
                    $self->add_data_simple({
                        name => $param{name},
                        dir  => $dir,
                        date => $param{date},
                    });
                    $log->debug("Start: add date simple - ok");
                }

                if ($l_cnf->{create_ckeckfile}) {
                    $log->debug("Start: create checkfile");
                    $self->create_ckeckfile({
                        name => $param{name},
                        dir => $dir,
                        regex_for_sn => $l_cnf->{regex_for_sn},
                        order_number => $param{order_number},
                        draw => $param{draw},
                        p_n => $param{p_n},
                        p_in_b => $param{p_in_b},
                        t_in_p => $param{t_in_p},
                    });
                    $log->debug("Start: create checkfile - ok");
                }

                if ($l_cnf->{add_null_row}) {
                    $log->debug("Start: add null row");
                    $self->add_null_row({
                        name => "$dir/$param{name}",
                        add_null => $param{add_null},
                    });
                    $log->debug("Start: add null row - ok");
                }

                if ($l_cnf->{xtoplus}) {
                    $log->debug("Start: x to plus");
                    $self->x_to_plus({
                        name => $param{name},
                        dir => $dir,
                    });
                    $log->debug("Start: x to plus - okQ");
                }

                my @files = File::Find::Rule->file()->name( '*.csv', '*.txt' )->in( $dir );
                my $obj = Archive::Zip->new();
                foreach (@files) {
                    $obj->addFile($_, basename($_));
                }

                if (@files > 1) {
                    if ($obj->writeToFileNamed("$dir/$param{order_number}.zip") == AZ_OK) {
                        $log->debug('archive created');

                        $self->render_file(
                            'filepath'            => "$dir/$param{order_number}.zip",
                            'format'              => 'application/x-download',
                            'content_disposition' => 'inline',
                            'cleanup'             => 0,
                        );
                    }
                } else {
                    $self->render_file(
                        'filepath'            => $files[0],
                        'format'              => 'application/x-download',
                        'content_disposition' => 'inline',
                        'cleanup'             => 0,
                    );
                }

            } else {
                $self->render(text => $file_check->[1] );
            }
        } else {
            $self->render(text => "Error: Can't find regexp for sn" );
        }



    }
}

1;
