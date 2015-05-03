# Mojo::Pg::ORM [![Build Status](https://travis-ci.org/pmb0/mojo-pg-orm.svg?branch=master)](https://travis-ci.org/pmb0/mojo-pg-orm)

A simple blocking and non-blocking object relational mapper for Mojolicious
and PostgreSQL.

*THIS IS EXPERIMENTAL SOFTWARE. USE AT YOUR OWN RISK.*

1. Create a `Mojolicious` application

    ```perl
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
    ```

2. Create `My::Model` class

    ```perl
    # Base class to be instantiated in main
    package My::Model;
    use Mojo::Base 'Mojo::Pg::ORM';
    ```

3. Create `Mojo::Pg::ORM::Model` classes

    ```perl
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
    ```




