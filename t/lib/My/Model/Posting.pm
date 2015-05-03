package My::Model::Posting;
use Mojo::Base 'Mojo::Pg::ORM::Model';
use experimental 'signatures';
use Mojo::Pg::ORM::Model;

use Mojo::Date;

hook before_create => sub($self) {
    $self->{created} = Mojo::Date->new;
    $self->{foo} = 'bar';
};

sub hello { 'Hello, ' . shift->{title} }

1;
