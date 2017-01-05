#!/usr/bin/perl
# Retorts plugin for DaZeus
# Copyright (C) 2017  Aaron van Geffen <aaron@aaronweb.net>
# 'Je moeder' function (C) 2010 Pen-Pen, 2013 Quis

use strict;
use warnings;
use DaZeus;

my ($socket) = @ARGV;

if (!$socket) {
	warn "Usage: $0 socket\n";
	exit 1;
}

my $dazeus = DaZeus->connect($socket);

# Fetch the hilight character(s).
my $sigil = $dazeus->getConfig("core", "highlight");

# Remember messages potentially concerning your mother.
my %lastJeMoederableMessages;

$dazeus->subscribe("PRIVMSG" => sub {
	my ($self, $event) = @_;
	my ($network, $sender, $channel, $msg) = @{$event->{params}};

	# As long as the message isn't a command or factoid request, save it.
	if (substr($msg, 0, length($sigil)) ne $sigil && substr($msg, 0, 1) ne "]" && $channel ne $dazeus->getNick($network)) {
		if ($msg =~ /\b(is|ben|bent|zijn|was|waren|hebben|heeft|hebt|heb)\s+(.*)$/i) {
			$lastJeMoederableMessages{$channel} = $2;
		} else {
			$lastJeMoederableMessages{$channel} = $msg;
		}
	}
});

# Send 'witty' replies concerning your mother.
$dazeus->subscribe_command("m" => sub {
	my ($self, $network, $sender, $channel, $command, $line) = @_;

	# Look up a previously saved message for this channel.
	if ($line eq "" && defined($lastJeMoederableMessages{$channel})) {
		$line = $lastJeMoederableMessages{$channel};
	}

	# Anything interesting to add?
	if ($line eq "") {
		reply("Je moeder is een null-pointer!", $network, $sender, $channel);
	} else {
		reply("Je moeder is $line!", $network, $sender, $channel);
	}
});

# Or, indeed, your father...
$dazeus->subscribe_command("v" => sub {
	my ($self, $network, $sender, $channel, $command, $line) = @_;

	# Look up a previously saved message for this channel.
	if ($line eq "" && defined($lastJeMoederableMessages{$channel})) {
		$line = $lastJeMoederableMessages{$channel};
	}

	# Anything interesting to add?
	if ($line eq "") {
		reply("Je vader is een null-pointer!", $network, $sender, $channel);
	} else {
		reply("Je vader is $line!", $network, $sender, $channel);
	}
});

# Or, finally, their miserable selves...
$dazeus->subscribe_command("z" => sub {
	my ($self, $network, $sender, $channel, $command, $line) = @_;

	# Look up a previously saved message for this channel.
	if ($line eq "" && defined($lastJeMoederableMessages{$channel})) {
		$line = $lastJeMoederableMessages{$channel};
	}

	# Anything interesting to add?
	if ($line eq "") {
		reply("Je bent zelf een null-pointer!", $network, $sender, $channel);
	} else {
		reply("Je bent zelf $line!", $network, $sender, $channel);
	}
});

while($dazeus->handleEvents()) {}

#####################################################################
#                       MODEL FUNCTIONS
#####################################################################

sub reply {
	my ($response, $network, $sender, $channel) = @_;

	if ($channel eq $dazeus->getNick($network)) {
		$dazeus->message($network, $sender, $response);
	} else {
		$dazeus->message($network, $channel, $response);
	}
}
