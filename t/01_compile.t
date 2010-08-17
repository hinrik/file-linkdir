use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 2;
use Test::Script;
use_ok('File::LinkDir');
script_compiles_ok(catfile('bin', 'link-files'), 'link-files compiles');
