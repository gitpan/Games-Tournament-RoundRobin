use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Tournament::RoundRobin',
    license             => 'perl',
    dist_author         => 'Dr Bean <drbean@cpan.org>',
    dist_version_from   => 'lib/Games/Tournament/RoundRobin.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Games-Tournament-RoundRobin-*' ],
    create_makefile_pl	=> 'passthrough',
);

$builder->create_build_script();
