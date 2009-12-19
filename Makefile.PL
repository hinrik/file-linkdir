use strict;
use warnings;
use inc::Module::Install;
use 5.006;

name           ('File-LinkDir');
perl_version   ('5.006');
author         ('Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>');
abstract_from  ('lib/File//LinkDir.pm');
version_from   ('lib/File//LinkDir.pm');
install_script ('script/link-files');
license        ('perl');
githubmeta     ();
requires       ('File::Path'   => '2.07');
test_requires  ('Test::More'   => '0');
test_requires  ('Test::Script' => '0');
tests_recursive();
WriteAll();
