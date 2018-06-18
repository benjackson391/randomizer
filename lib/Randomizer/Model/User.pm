package Randomizer::Model::User v0.0.1 {

    use SQL::Abstract::More;
    use Mojo::Base -base;
    use Data::Dumper;

    has 'db';

    sub get_users {
        my $self = shift;

        my $sql = ("select id, first_name, last_name, login, valid_id, created from users");

        my $sth = $self->db->prepare($sql);
        $sth->execute();
#        my %users = $sth->fetchall_hashref('id');
#        my %groups = $self->app->groups->get_groups;
#
#        for my $user (keys %users) {
#            for my $group (keys %groups) {
#                $self->
#            }
#        }

        return $sth->fetchall_hashref('id');
    }

    sub set_user {
        my ($self, $param) = @_;

        my $sql = ("UPDATE users SET");
        for (qw/first_name last_name login password/) {
            $sql .= " $_ = '$param->{$_}'," if $param->{$_};
        }
        $sql .= " valid_id = '$param->{valid_id}' WHERE id = $param->{id}";

        my $sth = $self->db->prepare($sql);
        $sth->execute();

        return $sql;
    }

=head get_user_group()
    my $user_group = $self->get_user_group(
    1, # user_id
    1  # optional - return array;
    )
=cut

    sub get_user_group {
        my ($self, $user_id, $array) = @_;

        my $sql = ("select
                      groups.id
                    from user_group
                      inner join groups on user_group.group_id = groups.id
                    where user_group.user_id = ?");

        my $sth = $self->db->prepare($sql);
        $sth->execute($user_id);

        if ($array) {
            my @groups = map { $_->[0] } @{ $sth->fetchall_arrayref };
            return \@groups;
        } else {
            my %groups = map { $_->[0] => 1 } @{ $sth->fetchall_arrayref };
            return \%groups;
        }
    }


    sub set_user_group {
        my ($self, $param) = @_;

        $self->db->do("DELETE FROM user_group WHERE user_group.user_id = $param->{user_id}");

        for ( keys $param->{groups} ) {
            if ( $param->{groups}->{$_} ) {
                my $sql = ("INSERT INTO user_group(user_id, group_id) VALUES(?, ?)");
                my $sth = $self->db->prepare($sql);
                $sth->execute($param->{user_id}, $param->{groups}->{$_});
            }
        }

        return 1;
    }




    #    has 'sql' => sub { SQL::Abstract::More->new(); };
#    #
#    #
#    # has 'pg';  # Set during object creation with new()
#    # has 'sql' => sub { SQL::Abstract::More->new(); };
#
#    sub _fieldnames {
#        my ($fieldset) = @_;
#        my @fields = qw(username);
#        if (defined $fieldset) {
#            # Do not normally return password
#            push @fields, ['first_name', 'last_name', 'login', 'password'] if ($fieldset eq 'save');
#            push @fields, 'id' if ($fieldset eq 'find');
#        }
#        return @fields;
#    }
#
#    sub add {
#        my ($self, $data) = @_;
#
#        my ($stmt, @bind) = $self->sql->select('users', '*', {login => $data->{login}} );
#        my $sth = $self->db->prepare($stmt);
#        $sth->execute(@bind);
#        my $exist = $sth->fetchall_hashref('login');
#
#        if ( !$exist->{ $data->{login} } ) {
#            my ($stmt, @bind) = $self->sql->insert( 'users', $data );
#            my $sth = $self->db->prepare($stmt);
#            $sth->execute(@bind);
#
#            ($stmt, @bind) = $self->sql->select('users', 'id', {login => $data->{login}});
#            $sth = $self->db->prepare($stmt);
#            $sth->execute(@bind);
#
#            return $sth->fetchall_arrayref->[0]->[0];
#        } else {
#            return 0;
#        }
#    }
#
#    sub list {
#        my ($self, $param) = @_;
#
#        my ($stmt, @bind) = $self->sql->select(
#            -from => 'users',
#            -columns => [ qw(id first_name last_name login valid_id created) ],
#            #-offset => $args->{start},
#            #-limit  => $args->{count},
#            -order_by => {-asc => [qw(first_name)]},
#        );
#
#        my $sth = $self->db->prepare($stmt);
#        $sth->execute();
#
#        return $sth->fetchall_arrayref;
#    }
#
#    sub find {
#        my ($self, $key, $value) = @_;
#
#        my ($stmt, @bind) = $self->sql->select('users', '*', {$key => $value});
#        my $sth = $self->db->prepare($stmt);
#        $sth->execute(@bind);
#        return $sth->fetchall_hashref('id');
#    }
#


    #
    # sub remove {
    #     my ($self, $username) = @_;
    #     return $self->pg->db->query
    #       ( $self->sql->delete( -from => 'users',
    #                             -where => {username => $username})
    #       )->rows;
    # }
    #
    # sub get_password {
    #     my ($self, $username) = @_;
    #
    #     return $self->pg->db->query
    #       ( $self->sql->select( -from => 'users',
    #                             -columns => [qw(password)],
    #                             -where => {username => $username})
    #       )->hash->{password};
    # }
    #
    # sub set_password {
    #     my ($self, $username, $password) = @_;
    #
    #     # crypto is handled in the controller
    #     return $self->pg->db->query
    #       ( $self->sql->update( -table => 'users',
    #                             -set   => {password => $password},
    #                             -where => {username => $username})
    #       )->rows;
    # }

}

1;
