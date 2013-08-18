#!/bin/perl -w

use strict;
use warnings;
use Device::SerialPort;

my $port = Device::SerialPort->new("/dev/ttyACM0");

$port->baudrate(9600);
$port->parity('none');
$port->databits(8);
$port->stopbits(1);
$port->handshake('none');

$port->write_settings or die "Crap $!\n";

while(1) {
    (my $count, my $data) = $port->read(255);
    print $data;
}
