#!/usr/bin/perl

use lib qw/t lib/;
use warnings;
use strict;
use Test::More tests => 42;

use Games::Tournament::RoundRobin;

my @test_leagues = (
		[ 0..1 ],
		[ 0..2 ],
		[qw(M�ller Meier)],
		[qw(M�ller Meier Schulze)],
		[qw(M�ller Meier Schulze Lehmann)],
		["Heinrich von Kleist", 
		 "D'Artagnan",
		 "Victor Hugo",
		 "Clemens Winkler",
		 "Leonardo Da Vinci"],
		['bla1',
		 'bla2',
		 'bla3',
		 'bla4',
		 'bla5',
		 'bla6',
		 'bla7',
		 'bla8',
		 'bla9',
		 'bla10'],
		);

my @schedules = (
	[ [ [ 0, 1 ] ] ],
[ [ [ 0, 1 ], [ 2, 3 ] ], [ [ 0, 2 ], [ 1, 3 ] ], [ [ 0, 3 ], [ 1, 2 ] ] ],
	[ [ [ qw/ M�ller Meier / ] ], ],

	[ [ [ qw/M�ller Meier/ ], [ qw/Schulze Bye/ ], ],
	[ [ qw/M�ller Schulze/ ], [ qw/Meier Bye/ ], ],
	[ [ qw/M�ller Bye/ ], [ qw/Meier Schulze/ ], ], ],

	[ [ [ qw/M�ller Meier/ ], [ qw/Schulze Lehmann/ ], ],
	[ [ qw/M�ller Schulze/ ], [ qw/Meier Lehmann/ ], ],
	[ [ qw/M�ller Lehmann/ ], [ qw/Meier Schulze/ ], ], ],

[ [ [ "Heinrich von Kleist", "D'Artagnan" ], [ "Victor Hugo", "Bye", ],
  [ "Clemens Winkler", "Leonardo Da Vinci" ], ],
[ [ "Heinrich von Kleist", "Victor Hugo" ], [ "D'Artagnan", "Clemens Winkler" ],
  [ "Leonardo Da Vinci", "Bye" ], ],
[ [ "Heinrich von Kleist", "Clemens Winkler" ], [ "D'Artagnan", "Bye" ],
  [ "Victor Hugo", "Leonardo Da Vinci" ], ],
[ ["Heinrich von Kleist", "Leonardo Da Vinci" ], ["D'Artagnan", "Victor Hugo" ],
  [ "Clemens Winkler", "Bye" ], ],
[ [ "Heinrich von Kleist", "Bye" ], [ "D'Artagnan", "Leonardo Da Vinci" ],
  [ "Victor Hugo", "Clemens Winkler" ], ], ], 

[ [ [ qw/bla1 bla2/ ], [ qw/bla3 bla10/ ], [ qw/bla4 bla9/ ], [ qw/bla5 bla8/ ],
  [ qw/bla6 bla7/ ], ],
[ [ qw/bla1 bla3/ ], [ qw/bla2 bla4/ ], [ qw/bla5 bla10/ ], [ qw/bla6 bla9/ ],
  [ qw/bla7 bla8/ ], ],
[ [ qw/bla1 bla4/ ], [ qw/bla2 bla6/ ], [ qw/bla3 bla5/ ], [ qw/bla7 bla10/ ],
  [ qw/bla8 bla9/ ], ],
[ [ qw/bla1 bla5/ ], [ qw/bla2 bla8/ ], [ qw/bla3 bla7/ ], [ qw/bla4 bla6/ ],
  [ qw/bla9 bla10/ ], ],
[ [ qw/bla1 bla6/ ], [ qw/bla2 bla10/ ], [ qw/bla3 bla9/ ], [ qw/bla4 bla8/ ],
  [ qw/bla5 bla7/ ], ],
[ [ qw/bla1 bla7/ ], [ qw/bla2 bla3/ ], [ qw/bla4 bla10/ ], [ qw/bla5 bla9/ ],
  [ qw/bla6 bla8/ ], ],
[ [ qw/bla1 bla8/ ], [ qw/bla2 bla5/ ], [ qw/bla3 bla4/ ], [ qw/bla6 bla10/ ],
  [ qw/bla7 bla9/ ], ],
[ [ qw/bla1 bla9/ ], [ qw/bla2 bla7/ ], [ qw/bla3 bla6/ ], [ qw/bla4 bla5/ ],
  [ qw/bla8 bla10/ ], ],
[ [ qw/bla1 bla10/ ], [ qw/bla2 bla9/ ], [ qw/bla3 bla8/ ], [ qw/bla4 bla7/ ],
  [ qw/bla5 bla6/ ], ], ],


);

for ( 0 .. $#test_leagues) {
	&testing( $_ );
}


sub testing {
	my @members = @{$test_leagues[$_]};
	my $members = @members;
	my %pairings;
	my $redcont;

	ok(my $tourn = Games::Tournament::RoundRobin->new(
				league => [ @members ]),
			"Creating new league with $members members.");
	my $rounds = $tourn->rounds();

	ok(my @sched = @{$tourn->wholeSchedule()},
			'Creating the schedule.');

	is(scalar(@sched), $rounds, 'Right number of rounds.');

	my %count_right; # the right number of appearances of the people
	for my $round (@sched) {
		for my $match (@$round) {
			my ( $member, $partner ) = @$match;
			$count_right{$member}++;
			$count_right{$partner}++;
			$pairings{$member . $partner}++; # See if there are
			$pairings{$partner . $member}++; # redundant meetings?
		}
	}

	for (keys %pairings) {
		if ($pairings{$_} > 1) {$redcont++}
	}
	ok(! $redcont, 'No redundant meetings.');

	my $appearance_ok;
	for (@members) {
		if ($count_right{$_} == $rounds) {++$appearance_ok}
	}
	is($appearance_ok, $members, "All appeared $rounds times.");
	is_deeply($schedules[$_], $tourn->wholeSchedule,
					"test_league $_ schedule");
}
