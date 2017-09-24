#!/usr/bin/perl

use strict;
use RRDs;
use DBI;
use Unix::Syslog qw(:subs);
use Unix::Syslog qw(:macros);
use Device::SerialPort;
use Getopt::Long;


# Database Details
my $dbs="DBI:SQLite:dbname=data.db";
my $dbh= DBI->connect($dbs);
my $sth = $dbh->prepare("insert into data (ts,device,min,avg,max) values (?,?,?,?,?)");

#
# No User servicanle parts below here.
#
#
# Options
my $foreground = '';
my $serialdev = '/dev/ttyACM0'; #Default Arduino device.

GetOptions('foreground' => \$foreground, 'device=s' => \$serialdev);

print "Using device $serialdev\n";

if($foreground) {
	print "Running in foreground\n";
} else {
	print "Going daemon...\n";
	my $pid = fork;
	exit if $pid;
	die "Nu forky $!" unless defined($pid);
}

my $time2die = 0;
my $rrdsecs;

openlog("GrowBoxd",LOG_PID,LOG_DAEMON);
syslog(LOG_NOTICE,"GrowBoxd Started");

sub signal_handler {
    $time2die = 1;
}
$SIG{INT} = $SIG{TERM} = $SIG{HUP} =\&signal_handler;

#
# tag rrd start time so all db's will be consistent
if(! -e "rrdstart") {
    open(F, ">rrdstart") || die "Opening rrdstart... Bummer $!";
    $rrdsecs = time();
    print F $rrdsecs;
    close(F);
    syslog(LOG_NOTICE,"Creating rrdstart");
} else {
    open(F,"rrdstart") || die "Opening rrdstart for read.. Bummer $!";
    $rrdsecs = <F>;
    close(F);
}

syslog(LOG_NOTICE,"rrdsecs = $rrdsecs");

my $currdir = `pwd`;
my $nextupdate = time() - (time()%300) +300;

#
# Open Database;
my $dbh = DBI->connect($dbs);


#
# This runs until the planet explodes, or the power goes out.
#
# Data format fro arduino;
#
#  Lumens: 72
#  Humidity: 34.00
#  Room (f): 81.14
#  Res: (f): 80.15
#  Plant: (f): 80.15
#

# 
# Placeholders
my %min = ();
my %max = ();
my %avg = ();
my %count = ();
my %accum = ();

open(TTY,"ttylog -f -b 9600 -d $serialdev |") || die "Crap: $!\n";
while(<TTY>) {
    exit if ($time2die);

    if(/^Lum/) {
        my $id="lumens";
        if(! -e "$id.rrd") {
            createrrd($id);
        }
        chomp();
        (my $caca, my $data) = split(":");
        $count{$id} ++;
        $accum{$id} = $accum{$id} + $data;
        $avg{$id} = $accum{$id} / $count{$id};
        if ($min{$id} eq "") { $min{$id} = $data; }
        if ($max{$id} eq "") { $max{$id} = $data; }
        if ($data < $min{$id}) { $min{$id} = $data; }
        if ($data > $max{$id}) { $max{$id} = $data; }
    }

    if(/^Hum/) {
        my $id="humidity";
        if(! -e "$id.rrd") {
            createrrd($id);
        }
        chomp();
        (my $caca, my $data) = split(":");
        $count{$id} ++;
        $accum{$id} = $accum{$id} + $data;
        $avg{$id} = $accum{$id} / $count{$id};
        if ($min{$id} eq "") { $min{$id} = $data; }
        if ($max{$id} eq "") { $max{$id} = $data; }
        if ($data < $min{$id}) { $min{$id} = $data; }
        if ($data > $max{$id}) { $max{$id} = $data; }
    }

    if(/^Res/) {
        my $id="res";
        if(! -e "$id.rrd") {
            createrrd($id);
        }
        chomp();
        (my $caca, my $data) = split(":");
        $count{$id} ++;
        $accum{$id} = $accum{$id} + $data;
        $avg{$id} = $accum{$id} / $count{$id};
        if ($min{$id} eq "") { $min{$id} = $data; }
        if ($max{$id} eq "") { $max{$id} = $data; }
        if ($data < $min{$id}) { $min{$id} = $data; }
        if ($data > $max{$id}) { $max{$id} = $data; }
    }

    if(/^Roo/) {
        my $id="room";
        if(! -e "$id.rrd") {
            createrrd($id);
        }
        chomp();
        (my $caca, my $data) = split(":");
        $count{$id} ++;
        $accum{$id} = $accum{$id} + $data;
        $avg{$id} = $accum{$id} / $count{$id};
        if ($min{$id} eq "") { $min{$id} = $data; }
        if ($max{$id} eq "") { $max{$id} = $data; }
        if ($data < $min{$id}) { $min{$id} = $data; }
        if ($data > $max{$id}) { $max{$id} = $data; }
    }

    if(/^Pla/) {
        my $id="plant";
        if(! -e "$id.rrd") {
            createrrd($id);
        }
        chomp();
        (my $caca, my $data) = split(":");
        $count{$id} ++;
        $accum{$id} = $accum{$id} + $data;
        $avg{$id} = $accum{$id} / $count{$id};
        if ($min{$id} eq "") { $min{$id} = $data; }
        if ($max{$id} eq "") { $max{$id} = $data; }
        if ($data < $min{$id}) { $min{$id} = $data; }
        if ($data > $max{$id}) { $max{$id} = $data; }
    }

    my $rrd;
    my $ltime = time();
    if(time() >= $nextupdate) {
        $nextupdate = time()-(time()%300) +300;
        foreach my $k (sort(keys(%avg))) {
            syslog(LOG_NOTICE,"Device $k data: = $avg{$k}");
            syslog(LOG_NOTICE,"Device $k count: = $count{$k}");
            $rrd = "$k.rrd";
            RRDs::update $rrd, "$ltime:$min{$k}:$avg{$k}:$max{$k}";
            if(my $ERROR = RRDs::error) {
                warn "unable to update $rrd $!";
            }
            $sth->execute($ltime,$k,$min{$k},$avg{$k},$max{$k});
        }

        #
        # Ugly, but has implied knowledge for Thingspeak
        #
        #`./postTS.py $avg{'room'} $avg{'res'} $avg{'plant'} $avg{'humidity'} $avg{'lumens'}`;
        `./postTS.py $avg{'humidity'} $avg{'lumens'} $avg{'room'} $avg{'res'} $avg{'plant'}`;
        syslog(LOG_NOTICE, "./postTS.py $avg{'humidity'} $avg{'lumens'} $avg{'room'} $avg{'res'} $avg{'plant'}");

        %min = ();
        %max = ();
        %avg = ();
        %count = ();
        %accum = ();
    }
}

#
# Subs

sub createrrd()
{
    my $name = shift;
    $name = "$name.rrd";
    #openlog("Temperature Logger",LOG_PID,LOG_DAEMON);
    syslog(LOG_NOTICE,"Creating $name");
    #closelog();
    my @options = ("--start", $rrdsecs,
    "DS:tmplow:GAUGE:600:-10:130",
    "DS:tmpavg:GAUGE:600:-10:130",
    "DS:tmphi:GAUGE:600:-10:130",
    "RRA:MIN:0.5:1:600",
    "RRA:MIN:0.5:6:700",
    "RRA:MIN:0.5:24:775",
    "RRA:MIN:0.5:288:797",
    "RRA:AVERAGE:0.5:1:600",
    "RRA:AVERAGE:0.5:6:700",
    "RRA:AVERAGE:0.5:24:775",
    "RRA:AVERAGE:0.5:288:797",
    "RRA:MAX:0.5:1:600",
    "RRA:MAX:0.5:6:700",
    "RRA:MAX:0.5:24:775",
    "RRA:MAX:0.5:288:797");
    RRDs::create $name, @options;
    my $ERROR = RRDs::error;
    if ($ERROR) {
       die "trying to create $name: $ERROR\n";
    }
}

