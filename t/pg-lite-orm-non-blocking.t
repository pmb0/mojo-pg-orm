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

use Mojolicious::Lite;

helper orm => sub { state $orm = My::Model->new($ENV{TEST_ONLINE}) };

app->orm->pg->db->query('drop table if exists postings');
app->orm->pg->db->query('create table postings (id serial primary key, title text, content text, foo text, created timestamp)');

app->orm->initialize;  # table created

# Create
put '/non-blocking' => sub {
    my $c = shift;
    $c->orm->model('Posting')->add({title => 'First'}, sub {
        my ($err, $created) = @_;
        $c->render(text => $created->hello);
    });
};

post '/non-blocking' => sub {
    my $c = shift;
    $c->orm->model('Posting')->update({title => 'Updated'}, sub {
        my ($err, $updated) = @_;
        $c->render(text => $updated->hello);
    });
};

get '/non-blocking' => sub {
    my $c = shift;
    $c->orm->model('Posting')->search(undef, sub {
        my ($err, $rows) = @_;
        my $text = $rows->map(sub { shift->hello })->join(' xxx ');
        $c->render(text => $text);
    });
};

get '/non-blocking/:id' => sub {
    my $c = shift;
    $c->orm->model('Posting')->find($c->param('id'), sub {
        my ($err, $posting) = @_;
        $c->render(text => $posting->{title});
    });
};

del '/non-blocking' => sub {
    my $c = shift;
    $c->orm->model('Posting')->remove(undef, sub {
        my $err = shift;
        $c->render(text => 'deleted');
    });
};

my $t = Test::Mojo->new;
$t->put_ok('/non-blocking')->content_is('Hello, First');
$t->post_ok('/non-blocking')->content_is('Hello, Updated');
$t->put_ok('/non-blocking')->content_is('Hello, First');
is app->orm->model('Posting')->all->size => 2;
$t->get_ok('/non-blocking')->content_is('Hello, Updated xxx Hello, First');
$t->delete_ok('/non-blocking')->content_is('deleted');
is app->orm->model('Posting')->all->size => 0;

done_testing;
