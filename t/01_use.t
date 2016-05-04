use strict;
use warnings;
use Test::More;
use Test::Script;

use_ok 'Stacy';
use_ok 'Stacy::Client';

script_compiles 'bin/stacy';
script_compiles 'bin/stacyclient';

done_testing;
