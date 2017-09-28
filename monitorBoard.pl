#!/usr/bin/perl -w
#
# Can't believe I have to do this. This script runs as root under supervisor
# which makes it too easy since it doesn't have to fork.
#
# If it sees ttyACM1 in the log files, that means the stupid Raspberry droped the connect to the arduino... again
# So it reboots the pi hard.
use strict;

use File::Tail;
use Unix::Syslog qw(:subs);
use Unix::Syslog qw(:macros);

syslog(LOG_NOTICE,"Starting cheesy board monitor");

my $file=File::Tail->new(name=>"/var/log/kern.log", maxinterval=>300);

while(defined(my $line=$file->read)) {
	print "$line";
	if ($line =~ /USB disconnect/) {
		print("Restarting GrowBag.pl because ttyACM1\n");
		syslog(LOG_NOTICE,"Restarting GrowBag.pl because ttyACM1");
		`killall ttylog`;
	}
}
