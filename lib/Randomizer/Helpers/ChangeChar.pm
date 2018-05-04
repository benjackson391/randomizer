package Randomizer::Helpers::ChangeChar;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
#use utf8;
#use Text::Unidecode;
use Encode;
use Encode::Detect::Detector;


sub register {

    my ($self, $app) = @_;
    $app->helper(
    # name => "uploaded/$name",
    # type => $type,
    # date => $date,
    change_char => sub {
      my ($self, $param) = @_;
      $self->app->log->debug("----------ChangeChar start");
      my %file;
      my $line = 1;
      my $string;
      my $null_row = ';'x60;
      $null_row = ';'x59 if $param->{type} eq 'JL';
      open my $fh1, "<", $param->{name};
      while (<$fh1>) {
        next if $_ =~ /^\s*$/;
        next if $_ eq '';
        if ($param->{type} eq 'JL') {
          $_ =~/^(\d*;\S{7};\d*;\d*;)(\d{16})(\d{1});(.*)$/;
          $_ = "$1$2$3;$2;$4";
        }
        chomp($_);
        $file{$line} = $_;
        $line++;
      }
      close $fh1;

      my $encoding_name = Encode::Detect::Detector::detect($file{1});
      my $date = $param->{date};
      $date =~ tr/-/ /;
      $self->app->log->debug("----------date: $date");
#      $date = unidecode($date);
      #$date = "$date g.";

      #$param->{name} = decode( $encoding_name, $date);
      open my $fh2, "+>", $param->{name};
      for ( my $i = 1; $i < $line; $i+= 2 ) {
        #my $string;
        my $last_symbol_1 = chop($file{$i});
        my $last_symbol_2 = chop($file{$i+1});
        my $first_ticket = $file{$i} . $last_symbol_1;
        $first_ticket .= ';' if $last_symbol_1 ne ';';
        my $second_ticket = $file{$i+1} . $last_symbol_2;
        $second_ticket .= ';' if $last_symbol_2 ne ';';

        # $last_symbol_1 eq ';' ? $string .= $file{$i} . $last_symbol_1 : $string .= $file{$i} . "$last_symbol_1;";
        # $last_symbol_2 eq ';' ? $string .= $file{$i+1} . $last_symbol_2 : $string .= $file{$i+1} . "$last_symbol_2;";
        #my $string = "$file{$i}$file{$i+1}$date;";
        my $d = decode( $encoding_name, "$first_ticket$second_ticket$date;" );
        print $fh2 "$d\n"
      }
      close $fh2;

      return 1;
    })
  }

1;
