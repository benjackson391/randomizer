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

        $self->app->log->debug("Start: regex modify");

        my $find = $param->{regex};
        my $replace = $param->{substition};

        tie (my @ry,"Tie::File",$param->{dir} . '/'. $param->{name} ) or die $!;

        $_=~ s/$find/$replace/ee for @ry;

        untie @ry;

        return 1;
    }
	);
}


1;
