#!/usr/bin/perl -w

use strict;
use Math::Round qw(:all);
use POSIX qw(strftime);
require DBI;

my $dbname = "DBI:SQLite:dbname=data.db";

my $min = 1000;
my $max = 0;
my $rowcount = 0;

my $dbquery = "select avg,ts from data where device =\"plant\" order by ts limit 3000";

my $dbh = DBI->connect($dbname) || die "can't connect to data.db";
my $sth = $dbh->prepare($dbquery);

$sth->execute;

# Get min and max temps for period.
while(my $ref = $sth->fetchrow_hashref()) {
	if($ref->{'avg'} < $min) {
		$min = $ref->{'avg'};
	}
	if($ref->{'avg'} > $max) {
		$max = $ref->{'avg'};
	}
}

$sth->execute;

print("{\n");
print("\t\"graph\" : {\n");
print("\t\t\"title\" : \"Plant Temperature\",\n");
print("\t\t\"yAxis\" : {\n");
print("\t\t\t\"minValue\" : ". (nearest_floor(10,$min)-10) .",\n");
print("\t\t\t\"maxValue\" : ". (nearest_ceil(10,$max)+10) ."\n");
print("\t\t},\n");
print("\t\t\"refreshEveryNSeconds\" : 300,\n");
print("\t\t\"datasequences\" : [\n");
print("\t\t\t{\n");
print("\t\t\t\t\"title\" : \"GrowRoom\",\n");
print("\t\t\t\t\"datapoints\" : [\n");

while (my $ref = $sth->fetchrow_hashref()) {
	$rowcount++;
	if($rowcount % 2) {
        #my $tmpdate = localtime($ref->{'ts'});
        my $tmpdate = strftime("%Y-%m-%d %H:%M",localtime($ref->{'ts'}));
		print("\t\t\t\t\t");
		print("{ \"title\" : \"".$tmpdate."\", \"value\" : ".$ref->{'avg'}." },\n");
	}
}

print("\t\t\t\t]\n");
print("\t\t\t}\n");
print("\t\t]\n");
print("\t}\n");
print("}\n");
