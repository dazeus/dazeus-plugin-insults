use strict;
use warnings;
use DaZeus;

my ($socket) = @ARGV;

if (!$socket) {
	warn "Usage: $0 socket\n";
	exit 1;
}

my $dazeus = DaZeus->connect($socket);

#####################################################################
#                       CONTROLLER FUNCTIONS
#####################################################################

# Test!
$dazeus->subscribe_command("test" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("Test back - I think it works.", $network, $sender, $channel);
});

# Hey?
$dazeus->subscribe_command("hey" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("Hey $sender!", $network, $sender, $channel);
});

# Hi?
$dazeus->subscribe_command("hi" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("Hi $sender!", $network, $sender, $channel);
});

# Hello?
$dazeus->subscribe_command("hello" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("Hello $sender!", $network, $sender, $channel);
});

# Ping?
$dazeus->subscribe_command("ping" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("Pong!", $network, $sender, $channel);
});

# Pong?
$dazeus->subscribe_command("pong" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("Ping!", $network, $sender, $channel);
});

# Sarcasm sign?
$dazeus->subscribe_command("sarcasm" => sub {
	my ($self, $network, $sender, $channel, @rest) = @_;
	reply("+-------+\n|Sarcasm|\n+---+---+\n    | (o.o;\n    o=", $network, $sender, $channel);
});

# Ordering something?
$dazeus->subscribe_command("order" => sub {
	my ($self, $network, $sender, $channel, $command, $line) = @_;
	my ($what, $forwhom) = $line =~ /^(.+?)\sfor\s(.+)$/i;

	if (!defined($what)) {
		# Didn't match -- maybe they forgot 'for $somebody'.
		$what = $line;
		$forwhom = $sender;
	}
	if (!defined($what)) {
		# Still didn't match -- they probably just said '}order'.
		reply("Syntax error. Please say }order [something] for [somebody].", $network, $sender, $channel);
	}

	$dazeus->action($network, $channel, "slides $what down the bar to $forwhom.", $network, $sender, $channel);
});

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
