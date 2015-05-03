package Mojo::Pg::ORM::Model;
use Mojo::Base '-base';
use experimental 'signatures';

use Mojo::Util 'monkey_patch';

has 'schema';

sub import {
    my $class = shift;
    my $caller = caller;
    monkey_patch $caller, events => sub { state $hooks = {} };
    monkey_patch $caller, hook => sub($hook, $cb) {
        push @{$caller->events->{$hook}}, $cb;
    };
}

sub id($self) {
    my $pk = $self->schema->pk;
    my @ids = map {$self->{$_}} @$pk;
    return $ids[0] if @ids == 1;
    return \@ids;
}

sub columns($self) {
    return keys %{$self->schema->columns};
}

sub _pk_where($self) {
    return {
        map { $_ => $self->{$_} } @{$self->schema->pk}
    };
}

sub update($self, $data) {
    $self->schema->update($data, $self->_pk_where);
}

sub remove($self) {
    $self->schema->remove($self->_pk_where);
}

sub TO_JSON($self) {
    return {
        map {$_ => $self->{$_}} $self->columns
    };
}

1;

=encoding utf8

=head1 NAME

Mojo::Pg::ORM::Model - Entity base class

=head1 SYNOPSIS

  package My::Schema::SomeTable;
  use Mojo::Base 'Mojo::Pg::ORM::Model';

  sub get_title {
      my $self = shift;
      return 'Title: ' . $self->{title};
  }

=head1 DESCRIPTION

Extend you model classes with this base class.

=head1 METHODS

=head2 columns

  my @columns = $self->columns;

Returns a list of current column names.

=head2 id

  my $id = $self->id;

Returns the id value(s) of the current row.

=head2 remove

  $self->remove;

This method removes the current row from the database.

=head2 TO_JSON

   my $hashref = $self->TO_JSON;

Returns a HashRef of current row's key-value-pairs.

=head2 update

  my $updated = $self->update({field => 'value'});

Updates current row in the database.

=cut
