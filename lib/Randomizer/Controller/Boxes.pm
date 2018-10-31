package Randomizer::Controller::Boxes;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(b64_decode b64_encode);
use Archive::Zip qw( :ERROR_CODES );
use Encode::Detect::Detector;
use File::Find::Rule;
use File::Basename;
use File::Copy;
use Mojo::Upload;
#use File::Find;
use FindBin;
use Data::Dumper;
use utf8;
use Encode;


# This action will render a template
sub index {
    my $self = shift;

    $self->render( template => 'default/boxes' );
}

sub create {
    my $self = shift;
    my (%param, $fileuploaded);
    my $log = $self->app->log;

    map { $param{$_} = $self->param($_) } qw/order_number expansion loto_type count_1 count_2 date add_null/;

    $log->debug(Dumper( \%param ));

    $param{ticket_type} = 5;
    my $t_cnf = $self->app->config('ticket')->{$param{ticket_type}};
    my $l_cnf = $t_cnf->{include}->{$param{loto_type}};

    return $self->redirect_to('/tickets')
        unless $self->param('upload_file');
    $fileuploaded = $self->req->upload('upload_file');
    $param{size} = $fileuploaded->size;
    $param{name} = $fileuploaded->filename;

    $log->debug("Ticket type = " . $param{ticket_type} . $param{loto_type});
    my $dir = 'uploaded/' . b64_encode ($self->session('user') . " :: " .  time );
    chomp($dir);
    mkdir $dir, 0755;

    if ( $param{name} =~ /(.*)\.(.*)/) {
        $param{name} = "$1.$param{expansion}";
    } else {
        $param{name} .= ".$param{expansion}";
    }

    $log->debug("File name - " . $param{name});
    $fileuploaded->move_to("$dir/$param{name}");
    copy("$dir/$param{name}", "$dir/$param{name}.dist");

    $self->logger("$dir :: $t_cnf->{name} :: $l_cnf->{name} :: $param{order_number}");

    $log->debug('1111' . $l_cnf->{regex_for_sn} );
    if ($l_cnf->{regex_for_sn}) {
        $log->debug("Start: regex fo sn");
        my $file_check = $self->file_check({
            dir          => $dir,
            name         => $param{name},
            sort         => 1,
            regex_for_sn => $l_cnf->{regex_for_sn},
        });
        $log->debug($file_check->[0]);
        if ($file_check->[0]) {
            $log->debug("Start: regex fo sn - ok");
            if ($l_cnf->{regexp_modify}) {
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
                    name    => $param{name},
                    dir     => $dir,
                    date    => $param{date},
                    columns => $l_cnf->{columns},
                });
                $l_cnf->{columns}++;
                $log->debug("Start: add date simple - ok");
            }
            if ($l_cnf->{add_null_row}) {
                $log->debug("Start: add null row");
                $self->add_null_row({
                    name => "$dir/$param{name}",
                    add_null => $param{add_null},
                });
                $log->debug("Start: add null row - ok");
            }
            if ($l_cnf->{create_boxes}) {
                $log->debug("Start: create_boxes");
                my $fn = $self->create_boxes({
                    name    => $param{name},
                    dir     => $dir,
                    count_1 => $param{count_1},
                    count_2 => $param{count_2},
                    columns => $l_cnf->{columns},
                    regex_for_sn => $l_cnf->{regex_for_sn},
                    order_number => $param{order_number},
                    date => $param{date},
                });
                $log->debug("create_boxes - ok") if $fn;
                # $l_cnf->{columns}++;
                $log->debug("Start: create_ckeckfile_2");
                my $fn = $self->create_ckeckfile_2({
                    name    => $param{name},
                    dir     => $dir,
                    count_1 => $param{count_1},
                    count_2 => $param{count_2},
                    columns => ++$l_cnf->{columns},
                    regex_for_sn => $l_cnf->{regex_for_sn},
                });
                $log->debug("Start: create_ckeckfile_2") if $fn;
            }

            my @files = File::Find::Rule->file()->name( '*.csv', '*.txt' )->in( $dir );
            $log->debug(Dumper \@files);
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
                    return;
                }
            } else {
                $self->render_file(
                    'filepath'            => $files[0],
                    'format'              => 'application/x-download',
                    'content_disposition' => 'inline',
                    'cleanup'             => 0,
                );
                return;
            }
        } else {
            $self->render(text => $file_check->[1] );
        }
    } else {
        $self->render(text => "Error: Can't find regexp for sn" );
    }
    $self->render( template => 'default/boxes' );
}

1;
