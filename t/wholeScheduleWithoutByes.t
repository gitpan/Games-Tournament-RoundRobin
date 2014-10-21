#!/usr/bin/perl

use lib qw/t lib/;
use warnings;
use strict;
use Test::More tests => 30;

use Games::Tournament::RoundRobin;

my @test_leagues = (
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

for (@test_leagues) {
	&testing(@{ $_ });
}


sub testing {
	my @members = @_;
	my $members = @members;
	my %pairings;
	my $redcont;
	my $byecont;

	ok(my $tourn = Games::Tournament::RoundRobin->new(
				league => [ @members ]),
			"Creating new league with $members members.");
	my $rounds = $tourn->rounds();

	ok(my @sched = @{$tourn->byelessSchedule()},
			'Creating the schedule.');

	is(scalar(@sched), $rounds, 'Right number of rounds.');

	my %count_right; # the right number of appearances of the people
	for my $round (@sched) {
		for my $match ( @$round ) {
			my ( $member, $partner ) = @$match;
			$byecont++ if $member eq "Bye" or $partner eq "Bye";
			$count_right{$member}++;
			$count_right{$partner}++;
			$pairings{$member . $partner}++; # Any
			$pairings{$partner . $member}++; # redundant meetings?
		}
	}

	for (keys %pairings) {
		if ($pairings{$_} > 1) {$redcont++}
	}
	ok(! $redcont, 'No redundant meetings.');

	ok(! $byecont, 'No silly Bye member.');

	my $appearance_ok;
	for (@members) {
		if ($count_right{$_} == $members - 1) {++$appearance_ok}
	}
	is($appearance_ok, $members, "All appeared $rounds times.");
}
