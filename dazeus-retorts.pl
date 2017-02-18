#!/usr/bin/perl
# Retorts plugin for DaZeus
# Copyright (C) 2017  Aaron van Geffen <aaron@aaronweb.net>
# 'Je moeder' function (C) 2010 Pen-Pen, 2013 Quis

use strict;
use warnings;
use DaZeus;
use Data::Dumper;

my ($socket) = @ARGV;

if (!$socket) {
	warn "Usage: $0 socket\n";
	exit 1;
}

my $dazeus = DaZeus->connect($socket);

# Fetch the hilight character(s).
my $sigil = $dazeus->getConfig("core", "highlight");

# Remember messages we can potentially use for any 'witty' retorts.
# NB: The name for this map was coined by Quis in the original implementation.
#     It is left in place as a memento.
my %lastJeMoederableMessages;

$dazeus->subscribe("PRIVMSG" => sub {
	my ($self, $event) = @_;
	my ($network, $sender, $channel, $msg) = @{$event->{params}};

	# If the message is a command or a factoid request, skip this one.
	if (substr($msg, 0, length($sigil)) eq $sigil ||
		substr($msg, 0, 1) eq "]" ||
		$channel eq $dazeus->getNick($network)) {
		return;
	}

	# Try matching as best as we can, figuring out what verb to use on the way.
	my $pair;
	if ($msg =~ /(?:^|\b)(is|ben|bent|zijn|was|waren|'s)\s+([^,.!?]*)/i) {
		$pair = ["zijn", $2];
	} elsif ($msg =~ /(?:^|\b)(hebben|heeft|hebt|heb|had|hadden|has|have)\s+([^,.!?]*)/i) {
		$pair = ["hebben", $2];
	} elsif ($msg =~ /(?:^|\b)(doen|doet|deden|deed|does|doe|do)\s+([^,.!?]*)/i) {
		$pair = ["doen", $2];
	} elsif ($msg =~ /(?:^|\b)((een|an?) [^,.!?]*)/i) {
		$pair = ["zijn", $1];
	} else {
		$pair = ["zijn", $msg];
	}

	$lastJeMoederableMessages{$channel} = $pair;
});

sub wittyRetort {
	my ($self, $network, $sender, $channel, $command, $query) = @_;

	# Testing aside, this doesn't make sense in PMs.
	if ($channel eq $dazeus->getNick($network)) {
		return $self->reply("For privacy reasons, I don't do witty retorts in private messages.", $network, $sender, $channel);
	}

	# Look up a previously saved message for this channel.
	my $line;
	if ($query ne "") {
		$line = ["zijn", $query];
	} elsif (defined($lastJeMoederableMessages{$channel})) {
		$line = $lastJeMoederableMessages{$channel};
	} else {
		$line = ["zijn", "een null-pointer"];
	}

	# What kind of retort are we dealing with?
	my $retort;
	if ($command eq "m") {
		$retort = "Je moeder %v %n!";
	} elsif ($command eq "v") {
		$retort = "Je vader %v %n!";
	} elsif ($command eq "z") {
		$retort = "Je %v zelf %n!";
	} else {
		return;
	}

	# What verb conjugation should we be using?
	my $verb;
	if ($command eq "z") {
		if ($line->[0] eq "zijn") {
			$verb = "bent";
		} elsif ($line->[0] eq "doen") {
			$verb = "doet";
		} else {
			$verb = "hebt";
		}
	} else {
		if ($line->[0] eq "zijn") {
			$verb = "is";
		} elsif ($line->[0] eq "doen") {
			$verb = "doet";
		} else {
			$verb = "heeft";
		}
	}

	# Time to get this show on the road...
	$retort =~ s/%v/$verb/;
	$retort =~ s/%n/$line->[1]/;

	$self->reply($retort, $network, $sender, $channel);
}

# Send 'witty' replies concerning your mother.
$dazeus->subscribe_command("m" => \&wittyRetort);

# Or, indeed, your father...
$dazeus->subscribe_command("v" => \&wittyRetort);

# Or, finally, their miserable selves...
$dazeus->subscribe_command("z" => \&wittyRetort);

while($dazeus->handleEvents()) {}
