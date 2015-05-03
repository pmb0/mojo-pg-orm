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

my $postings = $orm->model('Posting');

# Create
ok my $created = $postings->add({title => 'First'});
ok defined $created->{created};
is $created->{foo} => 'bar';

done_testing;
