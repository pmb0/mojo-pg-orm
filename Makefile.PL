use 5.010001;

use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::Pg::ORM',
  VERSION_FROM => 'lib/Mojo/Pg/ORM.pm',
  ABSTRACT     => 'Mojolicious ♥ PostgreSQL ♥ ORM',
  AUTHOR       => 'Philipp Busse <philipp.busse@gmx.net>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    no_index => {directory => ['t']}
  },
  PREREQ_PM => {
    'DBD::Pg'             => 0,
    'Lingua::EN::Inflect' => 0,
    'SQL::Abstract'       => 0,
    Mojolicious           => '6.0',
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);
