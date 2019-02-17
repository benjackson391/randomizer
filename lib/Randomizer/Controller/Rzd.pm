package Randomizer::Controller::Rzd;
use Mojo::Base 'Mojolicious::Controller';
# use DDP;
use utf8;

sub index {
    my $self = shift;
    $self->render( template => 'default/rzd');
}

sub gen {
    my $self = shift;
    my $param;
    map { $param->{$_} = $self->param($_) }
        qw/order_number flow_number f_p_n pack_count f_t_n ticket_count add_row_count expansion/;

    my $f_p_n = int $param->{f_p_n};
    my $fpn_l = length $param->{f_p_n};
    my $f_t_n = int $param->{f_t_n};
    my $ftn_l = length $param->{f_t_n};

    my @output;
    my $index = 0;
    for my $pc (1 .. $param->{pack_count}) {
        my $n1 = (length($pc) > $fpn_l - 1) ? $pc : '0' x ($fpn_l - length($pc)) . $pc;
        push(@{$output[$index]}, [$n1, "----"]) for (1 .. 20);

        for my $tc (1 .. $param->{ticket_count}) {
            my $n2 = (length($tc) > $ftn_l - 1) ? $tc : '0' x ($ftn_l - length($tc)) . $tc;
            push(@{$output[$index]}, ["$n1", "$n2"]);
        }
        ++$index;
        $index = 0 if ($pc % $param->{flow_number} == 0);
    }
    my $str;
    my $f_str;
    for my $i (0 .. ( @{$output[0]} - 1 )) {
        $str .= join(';', @{ $output[$_][$i] }) . ";" for (0 .. (@output - 1));
        $f_str = $str if $i == 20;
        $str .= "\n";
    }

    if ($param->{add_row_count}) {
        $f_str =~ s/\d/0/;
        for (1 .. $param->{add_row_count}) {
            $str .= $f_str . "\n";
        }
    }
    # p $str;
    $self->render_file(
        'data'      => $str,
        'format'    => $param->{expansion},
        'filename'  => $param->{order_number} . '.' . $param->{expansion},
    );
    return 1;
}

1;

# - Номер заказа
# - Количество потоков
# - Номер первой пачки
# - Количество пачек
# - Номер первого билета
# - Количество билетов
# - Количество дополнительных строк
