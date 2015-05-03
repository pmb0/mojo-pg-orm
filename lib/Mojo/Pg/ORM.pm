package Mojo::Pg::ORM;
use Mojo::Base -base;
use experimental 'signatures';

use Mojo::Loader qw(find_modules load_class);
use Mojo::Pg::ORM::Schema;
use Mojo::Pg;
use Scalar::Util 'weaken';

has 'connection';
has _sql    => sub { SQL::Abstract->new };
has pg      => sub { Mojo::Pg->new(shift->connection) };
has schemas => sub { {} };

sub new {
    my $self = shift->SUPER::new(connection => shift, @_);

    die 'Usage: Mojo::Pg::ORM->new($connection, $options?)'
      unless $self->connection;

    $self->initialize;

    return $self;
}

sub _get_relation_name($self, $module) {
    return substr($module, length(ref($self)) + 2);
}

sub initialize($self) {
    my @modules = find_modules ref($self);

    die 'No models modules found: ' . ref($self) unless @modules;

    weaken $self;

    # Load relation definition
    for my $module (@modules) {
        my $e = load_class $module;
        warn qq{Loading "$module" failed: $e} and next if ref $e;
        $self->schemas->{$module} = Mojo::Pg::ORM::Schema->new(
            class    => $module,
            orm      => $self,
            relation => $self->_get_relation_name($module),
        );
        # $module->initialize($self);
    }
}

sub model($self, $name) {
    $self->schemas->{ref($self) . '::' . $name};
}

1;

=encoding utf8

=head1 NAME

Mojo::Pg::ORM - Mojolicious ♥ PostgreSQL ♥ ORM

=head1 SYNOPSIS

THIS IS EXPERIMENTAL SOFTWARE. USE AT YOUR OWN RISK.

  # Model class for the table "postings"
  package My::Model::Posting;
  use Mojo::Base 'Mojo::Pg::ORM::Model';
  use experimental 'signatures';

  use Mojo::Date;

  hook before_create => sub($self) {
      $self->{created} = Mojo::Date->new;
  }

  sub hello($self) {
      return 'Hello, ' . $self->{title};
  }

  # Base class to be instantiated in main
  package My::Model;
  use Mojo::Base 'Mojo::Pg::ORM';

  # Mojolicious::Lite example app
  package main;
  use Mojolicious::Lite;
  use experimental 'signatures';

  use Mojo::Pg::ORM;
  use My::Model;

  helper orm => sub { state $orm = My::Model->new($connection) };

  # non-blocking
  get '/postings/:id' => sub($c) {
      $c->orm->model('Posting')->find($c->param('id'), sub($err, $posting) {
          $c->render(text => $posting->{title});
      });
  };

  # non-blocking
  get '/postings' => sub($c) {
      $c->orm->model('Posting')->search(undef, sub($err, $posting) {
          $c->stash(postings => $postings);
          $c->render;
      });
  };

  # blocking
  get '/postings' => sub($c) {
      $c->stash(postings => $c->orm->model('Posting')->all);
      $c->render;
  };

=head1 DESCRIPTION

A simple blocking and non-blocking object relational mapper for Mojolicious
and PostgreSQL.

=head1 ATTRIBUTES

=head2 pg

The L<Mojo::Pg> object used for low level operations.

=head2 schemas

Key-value-map of L<Mojo::Pg::ORM::Model> class names and L<Mojo::Pg::ORM::Schema>
objects. These objects hold information about primary keys, columns and so on for
the L<Mojo::Pg::ORM::Model> class.

=head1 METHODS

=head2 initialize

Loads and initializes table schema information classes.

=head2 model

  my $model = $orm->model('Posting');
  my $rows = $model->all;

Returns a L<Mojo::Pg::ORM::Model> object of the given name.

=head2 new

  my $orm = Mojo::Pg::ORM->new($connection, %options?);

Constructs a L<Mojo::Pg::ORM> object.

=cut
