package Randomizer::Controller::Loto1;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Upload;
use Archive::Zip qw( :ERROR_CODES );
use File::Basename;
use FindBin;
use Data::Dumper;
use utf8;

sub loto1 {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
      $self->stash(tables => $self->config->{tables});
      $self->stash(tables_rows => $self->config->{tables_description});
      $self->render( template => 'default/loto1' );
  }
}

sub generate {
  my $self = shift;
  if ( not $self->user_exists ) {
      $self->flash( message => 'You must log in to view this page' );
      $self->redirect_to('/');
      return;
  }
  else {
    my $progress;
    my $tickets_in_pack = 50;
    my $packs_in_box = 60;
    my $type =      $self->param("Type");
    my $count =     $self->param("Count");
    my $OrderNumber=$self->param("OrderNumber");
    my $Check1 =    $self->param("Check1");
    my $Check2 =    $self->param("Check2");
    my $Check3 =    $self->param("Check3");
    my $Draw   =    $self->param("Draw");

    $self->app->log->debug("param type: $type");
    $self->app->log->debug("param Count: $count");
    $self->app->log->debug("param OrderNumber: $OrderNumber");

    my $output_file = "$OrderNumber-$type-$count.csv";
    my $filepath = "$FindBin::Bin/../output/";

    my $errors;
    while ($_ = glob("$filepath*")) {
       next if -d $_;
       unlink($_) or ++$errors, warn("Can't remove $_: $!");
    }

    my $d = 500_000;
    my $cycle = 0;
    my $residue;
    my $sql;
    if ( $count > $d ) {
      $residue = $count % $d;
      $cycle = ( $count - $residue ) / $d;
      $self->app->log->debug("residue: $residue");
      $self->app->log->debug("cycle: $cycle");
    } else {
      $residue = $count;
      $self->app->log->debug("residue: $residue");
    }
    my $rand = $d / $self->config->{tables_description}->{$type}->{count};
    $rand .= 5;
  #   # Запрос случайных записей по 500_000 штук
    if ( $cycle ) {
      $self->app->log->debug("Cycle starts for $cycle loops...");
      for (1 .. $cycle) {
        my $sth = $self->db->prepare("SELECT * FROM (SELECT name FROM $type WHERE RAND()<=$rand) AS t1 ORDER BY RAND() LIMIT $d");
        $sth->execute();
        my $data = $sth->fetchall_arrayref;
        $self->app->log->debug("cycle #$_: " . scalar @$data );
        $sth->finish;
        open(my $fh, ">>", $filepath . $output_file) or die "Could not open '$output_file' $!\n";
        foreach ( @{$data} ) {chomp($_->[0]); print $fh "$_->[0]\n";}
        close $fh;
        $progress += $d;
      }
      $self->app->log->debug("Cycle ends successfully!");
    }
  #   # Запрос случайных записей остаток
    if ($residue) {
      $self->app->log->debug("Residue starts for $residue rows...");
      my $sth = $self->db->prepare("SELECT * FROM (SELECT name FROM $type WHERE RAND()<=$rand) AS t1 ORDER BY RAND() LIMIT $residue");
      $sth->execute();
      my $data = $sth->fetchall_arrayref;
      $sth->finish;
      open(my $fh, ">>", $filepath . $output_file) or die "Could not open '$output_file' $!\n";
      foreach ( @{$data} ) {chomp($_->[0]); print $fh "$_->[0]\n";}
      close $fh;
      $progress += $residue;
      $self->app->log->debug("Residue ends successfully!");
    }
  #   # Добавление пустых строк
    if ( $count % ($tickets_in_pack * $packs_in_box ) ) {
      $self->app->log->debug("Adding NULL rows...");
      my $i = $count % 3000;
      my $to_add = ($tickets_in_pack * $packs_in_box ) - $i;
      for (1 .. $to_add) {
        open(my $fh, ">>", $filepath . $output_file) or die "Could not open '$output_file' $!\n";
        print $fh $self->config->{tables_description}->{$type}->{null_row} . "\n";
        close $fh;
      }
    }
    $self->app->log->debug("Start of creating checklist...");
    my $box_number = 0001;
    my $pack_number = 1;
    my $line_number = 1;
    my %checklist;
    open FILE, $filepath . $output_file or $self->app->log->debug("Can't open file: $output_file!");
    while ( my $line1 = <FILE> ) {
      if ( $line_number == 1 ) {
        chomp($line1);
        $checklist{$line_number} = $line1;
      }
      if ( !($line_number % ($tickets_in_pack * $packs_in_box))) {
        chomp($line1);
        $checklist{$line_number} = $line1;
    #      last if $line_number == 36000;
        defined(my $line2 = <FILE>) or last;
        $line_number++;
        chomp($line2);
        $checklist{$line_number} = $line2;
      }
      $line_number++;
    }
    $self->app->log->debug("Creating checklist done!");
    close FILE;
    $self->app->log->debug("Start of creating checklist file...");
    my $row = '';
    foreach ( sort {$a <=> $b} keys %checklist ) {
      $box_number = int($box_number);
      $box_number < 10 ? $box_number = "000$box_number" :
      $box_number < 100 ? $box_number = "00$box_number" :
      $box_number < 1000 ? $box_number = "0$box_number" : 1;

      my $regexp = $self->config->{tables_description}->{$type}->{regex_for_sn};

      $checklist{$_} =~ /$regexp/;
      if ($row eq '') {
        $row = "$OrderNumber-$box_number;$Draw;$1";
      } else {
        $row .= ";$1;$pack_number;" . ($pack_number + 59) . ";$Check1;$Check2;$Check3";
        $pack_number += 60;
        ###
    #      print "$row\n";
        open(my $fh, ">>", $filepath . 'check_list.csv') or die "Could not open 'check_list' $!\n";
        print $fh "$row\n";
        close $fh;
        ###
        $row = '';
        $box_number++;
      }
    }
    $self->app->log->debug("Creating checklist file done!");
    $self->app->log->debug("Start of creating archive...");
####################
    my $obj = Archive::Zip->new();
    use File::Find::Rule;
    my @files = File::Find::Rule->file()
                                ->name( '*.csv' )
                                ->in( $filepath );
    foreach my $file (@files) {
      $obj->addFile($file, basename($file));   # add files
    }
    $obj->writeToFileNamed("$OrderNumber-$type.zip");
    $self->render_file(
        'filepath' => "$OrderNumber-$type.zip",
        'format'   => 'application/x-download', # will change Content-Type "application/x-download" to "application/pdf"
        'content_disposition' => 'inline',   # will change Content-Disposition from "attachment" to "inline"
        'cleanup'  => 1,                     # delete file after completed
    );
  }
}

1;
