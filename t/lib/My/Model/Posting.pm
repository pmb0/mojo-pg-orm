package My::Model::Posting;
use Mojo::Base 'Mojo::Pg::ORM::Model';

sub hello { 'Hello, ' . shift->{title} }

1;
