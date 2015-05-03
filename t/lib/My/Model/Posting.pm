package My::Model::Posting;
use Mojo::Base 'Mojo::Pg::ORM::Model';
use experimental 'signatures';
use Mojo::Pg::ORM::Model;

use Mojo::Date;

hook before_create => sub($self, $validation) {
    $self->{created} = Mojo::Date->new;
    $self->{foo} = 'bar';

    $validation->required('title')->size(2, 100);
    $validation->optional('foo')->size(3);
    $validation->optional('created');
};

# hook validate => sub($self, $validator) {
# };

sub hello { 'Hello, ' . shift->{title} }

1;
