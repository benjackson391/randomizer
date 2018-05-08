package Randomizer::Helpers::RegexpModify;
use base 'Mojolicious::Plugin';
use Modern::Perl;
use Data::Dumper;
use Tie::File;

sub register {

    my ($self, $app) = @_;
    $app->helper(
    # name => $name,
    # dir => $dir,
    # regex => $self->config->{loto2}->{$type}->{regex},
    # substition => $self->config->{loto2}->{$type}->{substition},

    regexp_modify => sub {
        my ($self, $param) = @_;
        #my %file;
        #my $line = 1;
        my $find = $param->{regex};
        my $replace = $param->{substition};

        tie (my @ry,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;
        $_=~ s/$find/$replace/ee for @ry;
        #$_ = "--- $_" for @ry;
        untie @ry;
        #open my $fh1, "<", $param->{dir} . '/'. $param->{name};
        #open my $fh2, "+>", $param->{dir} . '/output_'. $param->{name};

        #   or $self->app->log->debug("Cant't open file: " . $param->{name});
        #while (<$fh1>) {
       #     next if $_ =~ /^\s*$/;
        #    chomp($_);
            #   $self->app->log->debug($_) if $line < 4;
         #   $_=~ s/$find/$replace/ee;
        #    print $fh2 "$_\n";
            #$file{$line} = $_;
            #  $self->app->log->debug($_) if $line < 4;
            #$line++;
        #}
       # close $fh1;
        #open my $fh2, "+>", $param->{dir} . '/'. $param->{name};
        #print $fh2 Dumper(\%file);
        #foreach ( sort { $a <=> $b } keys %file ) {
        #    print $fh2 "$file{$_}\n";
        #}
        #close $fh2;

        return 1;
    }
	);
}


1;
