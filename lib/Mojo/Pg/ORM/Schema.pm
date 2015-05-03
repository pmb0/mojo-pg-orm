package Mojo::Pg::ORM::Schema;
use Mojo::Base -base;
use experimental 'signatures';

use Lingua::EN::Inflect 'PL';
use Mojo::Loader 'load_class';
use Mojo::Util 'decamelize';
use Scalar::Util 'weaken';
use SQL::Abstract;

has [qw(class orm)];
has columns  => sub { {} };
has debug    => sub { $ENV{MOJO_PG_ORM_DEBUG} // 1 };
has pk       => sub { shift->_get_pk };
has relation => sub { $_[0]->orm->_get_relation_name(ref($_[0])) };
has table    => sub { PL(decamelize shift->relation) };

sub new {
    my $self = shift->SUPER::new(@_);

    # $self->_sql->{debug} = 1;
    $self->retrieve_columns;
    return $self;
}

# Mojo::Eventemitter not working on classes:
# Can't use string ("Mojo::Pg::ORM::Model") as a HASH ref while "strict refs" in use
sub emit($self, $name, @args) {
    $_->(@args) for @{$self->class->events->{$name} // []};
}

sub on($self, $name, $cb) {
    push @{$self->class->events->{$name}}, $cb;
}

sub retrieve_columns($self) {

    # Retrieve table columns
    my $result = $self->_search(
        'information_schema.columns',
        [qw(column_name data_type)],
        {table_name => $self->table}
    );
    while (my $f = $result->array) {
        $self->columns->{$f->[0]} = $f->[1];
    }
}

# Retrieve Primary Key column(s)
# see http://wiki.postgresql.org/wiki/Retrieve_primary_key_columns
sub _get_pk($self) {
    my $sql = q{
      SELECT
        pg_attribute.attname,
        format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
      FROM pg_index, pg_class, pg_attribute, pg_namespace
      WHERE
        pg_class.oid = ?::regclass AND
        indrelid = pg_class.oid AND
        nspname = 'public' AND
        pg_class.relnamespace = pg_namespace.oid AND
        pg_attribute.attrelid = pg_class.oid AND
        pg_attribute.attnum = any(pg_index.indkey)
       AND indisprimary
    };
    return $self->_query($sql, $self->table)
      ->hashes->map(sub { $_->{attname} })->to_array;
}

sub _query($self, @params) {
    return $self->orm->pg->db->query(@params);
}

sub _collapse($self, $data) {
    return $self->class->new(schema => $self, %$data);
}

sub _search($self, $table, $fields, $where, $cb = undef) {
    my @sql = $self->orm->_sql->select($table, $fields, $where);

   # $self->debug && say $sql[0] . ' <<< ' . (join(', ', $sql[1]) || '(none)');

    return $self->orm->pg->db->query(@sql) unless defined $cb;

    $self->orm->pg->db->query(@sql, $cb);
}

sub find($self, $id, $cb = undef) {
    my $where = ref($id) ? $id : {$self->pk->[0] => $id};

    # blocking
    if (not defined $cb) {
        return $self->_collapse(
            $self->_search($self->table, undef, $where)->hash);
    }

    # non-blocking
    $self->_search(
        $self->table,
        undef, $where,
        sub($db, $err, $result) {
            $cb->($err, $self->_collapse($result->hash));
        }
    );
}

sub all { shift->search(undef, @_) }

sub search($self, $where, $cb = undef) {

    # blocking
    if (not defined $cb) {
        return $self->_search($self->table, undef, $where)
          ->hashes->map(sub { $self->_collapse($_) });
    }

    # non-blocking
    $self->_search(
        $self->table,
        undef, $where,
        sub($db, $err, $results) {
            $cb->($err, $results->hashes->map(sub { $self->_collapse($_) }));
        }
    );
}

sub add($self, $row, $cb = undef) {
    my $validator = $self->orm->validator;
    $self->emit('before_create', $row, $validator->validation);

    my @sql = $self->orm->_sql->insert($self->table, $row,
        {returning => [keys %{$self->columns}],});

    # $self->debug && say $sql[0];

    weaken $self;

    return $self->_collapse($self->orm->pg->db->query(@sql)->hash)
      unless defined $cb;

    $self->orm->pg->db->query(
        @sql,
        sub($db, $err, $results) {
            $cb->($err, $self->_collapse($results->hash));
        }
    );
}

# update($data, sub {})
# update($data, $where)
# update($data, $where, sub {})
sub update {
    my ($self, $data) = (shift, shift);
    my $cb = pop @_;
    my $where;
    if (ref($cb) eq 'CODE') {
        $where = shift // {};
    }
    else {
        $where = $cb;
        $cb    = undef;
    }

    my @sql = $self->orm->_sql->update($self->table, $data, $where);
    $sql[0] .= ' returning ' . join(', ', keys %{$self->columns});

    # $self->debug && say $sql[0];

    return $self->orm->pg->db->query(@sql) unless defined $cb;

    $self->orm->pg->db->query(
        @sql,
        sub($db, $err, $results) {
            $cb->($err, $self->_collapse($results->hash));
        }
    );
}

sub remove {
    my $self = shift;
    my $cb   = pop @_;
    my $where;
    if (ref($cb) eq 'CODE') {
        $where = shift // {};
    }
    else {
        $where = $cb;
        $cb    = undef;
    }

    my @sql = $self->orm->_sql->delete($self->table, $where);

    # $self->debug && say $sql[0] . ' ## ' . $sql[1];

    # blocking
    return $self->orm->pg->db->query(@sql) unless defined $cb;

    # non-blocking
    $self->orm->pg->db->query(@sql, $cb);
}

1;

=encoding utf8

=head1 NAME

Mojo::Pg::ORM::Schema - Table level operations

=head1 SYNOPSIS

  my $orm = Mojo::Pg::ORM->new(...);
  my $schema = $orm->model('SomeTable');
  $schema->update({field => 'value'});

=head1 DESCRIPTION

Table level CRUD operations.

=head1 ATTRIBUTES

=head2 columns

A hash containing field names and data types of the current table.

=head1 METHODS

=head2 add

  $schema->add(\%row_data);
  $schema->add(\%row_data, sub($err, $inserted) {...});

Inserts a new row.

=head2 all

  my $collection = $schema->all;
  my $collection = $schema->all(sub($err, $collection) {...}?);

Returns all rows of the table.

=head2 emit

  $schema->emit($name, @args);

Emits an event.

=head2 find

  my $model = $schema->find($id);
  my $model = $schema->find($id, sub($err, $model) {...}?);

Searches for a row using its ID.

=head2 new

Constructs a L<Mojo::Pg::ORM::Schema> object. Retrieves current column list
from the database.

=head2 on

  $schema->on($event => $cb);

Subscribe to event.

=head2 remove

  $schema->remove(\%where?);
  $schema->remove(\%where?, sub($err) {...}?);

Removes rows from the database.

=head2 retrieve_columns

  $schema->retrieve_columns;

Retrieves column information for the curent table from the database and stores
them i the L<columns> attribute.

=head2 search

  my $model = $schema->search(\%where?);
  my $model = $schema->search(\%where?, sub($err, $collection) {...}?);

Searches for rows and returns a L<Mojo::Collection> result.

=head2 update

  my $model = $schema->update(\%data, \%where?);
  my $model = $schema->update(\%data, \%where?, sub($err, $collection) {...}?);

Updates rows in the database.

=cut
