# NAME

Mojo::Pg::ORM - Mojolicious ♥ PostgreSQL ♥ ORM

# SYNOPSIS

THIS IS EXPERIMENTAL SOFTWARE. USE AT YOUR OWN RISK.

    package My::Model;
    use Mojo::Base 'Mojo::Pg::ORM';
    # That's it

    package My::Model::Posting;
    use Mojo::Base 'Mojo::Pg::ORM::Schema';
    use experimental 'signatures';

    sub hello($self) {
        return 'Hello, ' . $self->{title};
    }

    package main;

    use Mojo::Pg::ORM;
    use Mojolicious::Lite;

    helper orm => sub { state $orm = My::Model->new($connection) };

    # non-blocking
    get '/postings/:id' => sub {
        my $c = shift;
        $c->orm->model('Posting')->find($c->param('id'), sub {
            my ($err, $posting) = @_;
            $c->render(text => $posting->{title});
        });
    };

    # non-blocking
    get '/postings' => sub {
        my $c = shift;
        $c->orm->model('Posting')->search(undef, sub {
            my ($err, $postings) = @_;
            $c->stash(postings => $postings);
            $c->render;
        });
    };

    # blocking
    get '/postings' => sub {
        my $c = shift;
        $c->stash(postings => $c->orm->model('Posting')->all);
        $c->render;
    };

# DESCRIPTION

A simple blocking and non-blocking object relational mapper for Mojolicious
and PostgreSQL.

# ATTRIBUTES

## pg

The [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) object used for low level operations.

## schemas

Key-value-map of [Mojo::Pg::ORM::Model](https://metacpan.org/pod/Mojo::Pg::ORM::Model) class names and [Mojo::Pg::ORM::Schema](https://metacpan.org/pod/Mojo::Pg::ORM::Schema)
objects. These objects hold information about primary keys, columns and so on for
the [Mojo::Pg::ORM::Model](https://metacpan.org/pod/Mojo::Pg::ORM::Model) class.

# METHODS

## initialize

Loads and initializes table schema information classes.

## model

    my $model = $orm->model('Posting');
    my $rows = $model->all;

Returns a [Mojo::Pg::ORM::Model](https://metacpan.org/pod/Mojo::Pg::ORM::Model) object of the given name.

## new

    my $orm = Mojo::Pg::ORM->new($connection, %options?);

Constructs a [Mojo::Pg::ORM](https://metacpan.org/pod/Mojo::Pg::ORM) object.
