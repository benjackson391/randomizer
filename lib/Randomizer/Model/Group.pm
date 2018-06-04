package Randomizer::Model::Group v0.0.1 {

    use SQL::Abstract::More;
    use Mojo::Base -base;
    use Data::Dumper;

    has 'db';

    sub get_groups {
        my $self = shift;

        my $sql = ("select * from groups");

        my $sth = $self->db->prepare($sql);
        $sth->execute();

        return $sth->fetchall_hashref('id');
    }
}

1;
