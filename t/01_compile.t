use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;
use Test::Script;
use_ok('File::LinkDir');
script_compiles_ok(catfile('script', 'link-files'), 'link-files compiles');
