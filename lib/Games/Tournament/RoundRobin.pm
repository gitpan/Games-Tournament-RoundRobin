package Games::Tournament::RoundRobin;

# Last Edit: 2006  2月 11, 07時57分02秒
# $Id: /sched/trunk/lib/Games/Tournament/RoundRobin.pm 515 2006-02-10T23:06:55.230562Z dv  $

use warnings;
use strict;

=head1 NAME

Games::Tournament::RoundRobin - Round-Robin Tournament Schedule Pairings 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    $schedule = Games::Tournament::RoundRobin->new;

    $pairings = $schedule->indexesInRound($roundm);
    $round = $schedule->meeting($member1, [$member2, $member3]);
    ...

=head1 DESCRIPTION

Every member of a league of 2n players can be paired with every other member in 2n-1 rounds.

If the league members are (Inf, 1 .. 2n-1), then in round i, i can be paired with Inf, and a can meet b, where a+b = 2i (mod 2n-1).

=head1 REQUIREMENTS

Installing this module requires Module::Build.

=head1 METHODS

=head2 new

 Games::Tournament::RoundRobin->new( v => 5, league => ['Ha', 'Be', 'He'])
 Games::Tournament::RoundRobin->new( league => {A => $a, B => $b, C => $c})

where v (optional) is the number of league members, and league (optional) is a list (or a hash) reference to the individual unique league members. One of v, or league (which takes precedence) is necessary, and if league is not given, the members are identified by the numbers 0 .. n-1.

If the league is a list (or hash) of n objects, they should be instances of a class that overloads both string quoting with a 'name' method and arithmetical operations with an 'index' method. The index method, called on the n objects in order, should return the n numbers, 0 .. n-1, and in that order if they are presented as an array. If they are presented as a hash, the hash is stored internally as an array and the keys are discarded.

If the league is a list of strings or numbers, indexes are constructed for the values on the basis of their positions in the list, and if a hash of strings or numbers, on the basis of the lexicographic order of their keys. Each string is expected to be unique.

If n is odd, an additional n-1, 'Bye' or object (a Games::League::Member object, by default) member, depending on the type of the first member in the league, is added at the end and n is increased by 1.

=cut 

sub new
{
	my $class = shift;
	my %args = @_;
	my $n;
	my $members;
	$members = $args{league};
	if ( ref $members )
	{
		$members = _hash2array( $members ) if ref $members eq 'HASH';
		$n = $#$members + 1;
		my $memberClass;
		if ( $memberClass = ref $members->[0] )
		{
			$members->[$_]->index == $_ or warn 
		"Index of ${_}th member is $members->[$_]->{index}, not $_,"
							foreach ( 0 .. $n-1 );
		$memberClass ||= 'Games::League::Member';
		push @$members, $memberClass->new(
		index => $n++, name => 'Bye' ) if $n%2;
		}
		elsif ($members->[0] =~ m/^\d+$/)
		{
			push @$members, $n++ if $n%2;
		}
		else {
			if ($n%2)
			{	push @$members, 'Bye' ;
				$n++;
			}
		}
	}
	else {
		$n ||= $args{v};
		$n++ if $n%2;
	}
	$members ||= [ 0 .. $n-1 ];
	$args{v} = $n;
	$args{league} = $members;
	bless \%args, $class;
}

# Converts an hash into a array discarding the keys. Used internally to 
# store the league argument if a hash is passed.

sub _hash2array
{
	my $hash = shift;
	my $array;
	my $index;
	my $n = 0;
	# $array->[$n++] = $hash->{$_} foreach ( keys %$hash );
	foreach my $key ( sort keys %$hash ) 
	{
		if ( ref $hash->{$key} )
		{
			$hash->{$key}->{index} = $n 
					unless exists $hash->{$key}->{index};
			my $index = $hash->{$key}->{index};
			$array->[$index] = $hash->{$key};
			$n++;
		}
		else
		{ 
			$array->[$n++] = $hash->{$key};
		}
	}
	return $array;
}

=head2 indexesInRound

	$schedule->indexesInRound($m)

Returns an array reference of the pairings in round $m. This method is useful if you are using numbers to represent your league members. It is not so useful if you are using strings or objects and you don't know their index numbers. Positions in the array represent members. The values represent their partners. Each member is thus represented twice.

=cut

sub indexesInRound
{
	my $self = shift;
	my $n = $self->size;
	my $round = shift;
	my @pairings = ($round);
	for my $i (1 .. $n-1)
	{
		if ($i == $round)
		{
			push @pairings, 0;
		}
		else
		{
			my $modPartner = ((2*$round-$i) % ($n-1));
			my $partner = $modPartner? $modPartner: $n-1;
			push @pairings, $partner;
		}
	 }
	return \@pairings;
}

=head2 roundsInTournament

	$t = $schedule-> roundsInTournament;
	$round1 = $t[0];
	$inRound1FourthWith = $t->[0]->[3];
	$inLastRoundLastWith = $$t[-1][-1];

Returns, as a reference to an array of arrays, the pairings in all rounds of the tournament. This method is useful if you are using the algorithm indexes.

=cut

sub roundsInTournament
{
	my $self = shift;
	my $matrix;
	push @$matrix, $self->indexesInRound($_)
					foreach 1 .. $self->rounds; 
	return $matrix;
}

=head2 partner

	$schedule->partner($member, $m)

Returns the partner of $member in round $m.

=cut

sub partner
{
	my $self = shift;
	my $member = shift;
	my $round = shift;
	my @partners = @{$self->indexesInRound($round)};
	my $index = $self->index($member);
	my $partner = $self->member($partners[$index]);
	return $partner;
}

=head2 membersInRound

	$schedule->membersInRound($m)

Returns an hash reference of the pairings in round $m. This method is useful if you are using strings or objects. Keys in the hash represent league members. If the league members are objects, their names are used as keys. If 2 names are the same, the names are changed to $name.1, $name.2 etc. The values are their partners. Each player is thus represented twice.

=cut

sub membersInRound
{
	my $self = shift;
	my $n = $self->size;
	my $round = shift;
	my %pairings;
	my @indexes = @{$self->indexesInRound($round)};
	for my $i (0 .. $n-1)
	{
		my $member = $self->member($i);
		# my $index = $self->index($member);
		if ( defined $pairings{$member} ) {
			my $clobbered = $member . 1;
			$pairings{$clobbered} = $pairings{$member};
			delete $pairings{$member};
			$member = $member . 2;
		}
		my $partner = $indexes[$i];
		$partner = $self->member($partner);
		$pairings{$member} = $partner;
	 }
	return \%pairings;
}

=head2 memberSchedule

	$schedule->memberSchedule($member)

Returns, as an array reference, the partners who $member is matched with in the order in which they meet, ie round by round.

=cut

sub memberSchedule
{
	my $self = shift;
	my $member = shift;
	my $schedule;
	foreach my $round ( 0 .. $self->rounds-1 ) 
	{
		my $allMembers = $self->indexesInRound($round);
		push @$schedule, $$allMembers[$member];
	}
	return $schedule;
}

=head2 meeting

	$schedule->meeting($member,$partner)

Returns the rounds (TODO and the venue) at which $member meets $partner.

=cut

sub meeting
{
	my $self = shift;
	my $n = $self->size;
	my ($member, $partner) = @_;
	my $a = $self->index($member);
	my $b = $self->index($partner);
	my $round = $a+$b;
	if ($a == 0)
	{
		return 0+$b;
	}
	elsif ($b == 0)
	{
		return 0+$a;
	}
	elsif ( $round % 2) {
		$round = ($round + $n-1)/2 % ($n-1);
		$round ||= $n-1;
		return 0+$round;
	}
	else {
		return 0+($round/2)%($n-1);
	}
}

=head2 meetings

	$schedule->meetings($member1,[$member2,$member3,...])

Returns, as an array reference, the rounds (TODO and the venue) at which $member1 meets $member2, $member3, ...

=cut

sub meetings
{
	my $self = shift;
	my $n = $self->size;
	my ($member, $partners) = @_;
	my @meetings = map {
		$self->meeting($member,$_);
	} @$partners;
	return \@meetings;
}

=head2 index

	$schedule->index($member)

Returns $member's index, the number which is used to pair it with other members. The index is the position, 0..n-1, of the $member in the league argument to the constructor (if an array) or the constructed array (if a hash.)

If $member is not a member of the array, or is itself an index, undef is returned.

=cut

sub index
{
	my $self = shift;
	my $member = shift;
	my $members = $self->{league};
	my $i = 0;
	foreach my $candidate ( @$members )
	{
		if ( $candidate =~ m/^\d+$/)
		{
			return $i if $candidate == $member;
		}
		else {
			return $i if $candidate eq $member;
		}
		$i++;
	}
	return undef;
}

=head2 member

	$schedule->member($index)
	$schedule->member($name)
	$bye = $schedule->member( $schedule->size-1 )

Returns the member represented by $index, a number which ranges from 0..n-1, or by $name, a string. If there is no such member, undef is returned.

=cut

sub member
{
	my $self = shift;
	my $handle = shift;
	my $members = $self->{league};
	if ( $handle =~ /\d+/ ) {
		return $members->[$handle];
	}
	else
	{
		foreach my $member ( @$members )
		{
			return $member if $member eq $handle;
		}
		return undef;
	}
}

=head2 partners

	$schedule->partners($index)
	$schedule->partners($name)

Returns an array reference of all the partners of the $indexed or $named member, in index order, or the order in the league argument.

=cut

sub partners
{
	my $self = shift;
	my $handle = shift;
	my $members = $self->{league};
	my $partneredOne = $self->member($handle);
	my @partners;
	foreach my $member ( @$members )
	{
		if ( $handle =~ /\d+/ )
		{
				push @partners, $member unless 
					$self->index($member) == $handle;
		}
		else
		{
			push @partners, $member unless $member eq $handle;
		}
	}
	return \@partners;
}

=head2 realPartners

	$schedule->realPartners($index)

	Returns an array reference of all the partners of the $indexed member, excluding the 'Bye' member. Don't use this if you have no 'Bye' member, as it just leaves off the last member.

=cut

sub realPartners
{
	my $self = shift;
	my $index = shift;
	my $members = $self->{league};
	my @partners;
	foreach my $member ( @$members )
	{
		push @partners, $member unless ($member == $index or $member == $self->size-1);
	}
	return \@partners;
}

=head2 size

	$schedule->size

Returns the number of members in the round robin. Sometimes this may not be the same as the number of league members specified, because the array of league members takes precedence if supplied, and a bye is added if the number is odd.

=cut

sub size
{
	my $self = shift;
	$self->{v};
}

=head2 rounds

	$schedule->rounds

Returns the number of rounds in the round robin. This equals the number of league members, minus 1.

=cut

sub rounds
{
	my $self = shift;
	$self->size - 1;
}

=head1 AUTHOR

Dr Bean, C<< <drbean@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-tournament-roundrobin@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Tournament-RoundRobin>.
I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::Tournament::RoundRobin

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-Tournament-RoundRobin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Tournament-RoundRobin>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Tournament-RoundRobin>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Tournament-RoundRobin>

=back

=head1 ACKNOWLEDGEMENTS

The algorithm saw perl attention on Mark Jason Dominus's Quiz of the Week in January 2005.  L<http://perl.plover.com/~alias/list.cgi?1:msp:2343>


=head1 COPYRIGHT & LICENSE

Copyright 2006 Dr Bean, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Games::Tournament::RoundRobin
