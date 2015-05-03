use Mojo::Base -strict;

BEGIN {
    $ENV{MOJO_MODE}    = 'testing';
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use FindBin;
use lib "$FindBin::Bin/lib";

use My::Model;
use Test::More;
use Test::Mojo;

plan skip_all => 'set TEST_ONLINE to enable this test'
  unless $ENV{TEST_ONLINE};

my $orm = My::Model->new($ENV{TEST_ONLINE});
$orm->pg->db->query('drop table if exists postings');
$orm->pg->db->query('create table postings (id serial primary key, title text, content text, foo text, created timestamp)');

$orm->initialize;  # table created

my $postings = $orm->model('Posting');
is ref($postings) => 'Mojo::Pg::ORM::Schema';

# Create
ok $postings->add({title => 'First'});
ok my $created = $postings->add({title => 'Mojo', content => 'I ♥ Mojolicious!'});
is ref($created) => 'My::Model::Posting';
is $created->hello => 'Hello, Mojo';

# Find
my $posting = $postings->find($created->id);
is ref($posting) => 'My::Model::Posting';
is $posting->id        => $created->id;
is $posting->{content} => 'I ♥ Mojolicious!';
is $posting->{title}   => 'Mojo';

# Search
$postings = $orm->model('Posting')->all;
is $postings->size => 2;
$postings = $orm->model('Posting')->search({content => {-like => '%♥%'}});
is $postings->size => 1;

# Update
$postings->first->update({title => 'new'});
$postings->first->{title} = 'new';
is $orm->model('Posting')->search({title => 'new'})->size, 1;
$orm->model('Posting')->update({title => 'updated'});
is $orm->model('Posting')->search({title => 'updated'})->size, 2;

# Remove
$postings->first->remove;
is $orm->model('Posting')->all->size => 1;
$orm->model('Posting')->remove();
is $orm->model('Posting')->all->size => 0;

done_testing;
