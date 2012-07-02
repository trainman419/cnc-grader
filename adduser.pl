#!/usr/bin/perl
#
# Add a user to the database
#

use strict;
use DBI;
use Term::ReadKey;
use Crypt::PasswdMD5;

# check parameter
if( scalar(@ARGV) != 1 ) {
   print "Usage: adduser.pl <email>\n";
   #print "Got ".scalar(@ARGV)." arguments\n";
   exit(-1);
}

my $email = shift;

my $dbh = DBI->connect("DBI:mysql:crashncompile", "crashncompile", 
      "crashncompile") or die "Could not connect to database: $DBI::errstr";

ReadMode('noecho'); # suppress output echoing for password
print "Password: ";
my $pass = <>;
chomp($pass);
print "\n";

ReadMode('restore');

# TODO: hash password
my $hash = unix_md5_crypt($pass);

$dbh->do("insert into users (email, password) values(?, ?)", undef, 
      ($email, $hash)) or die "Failed to create user: $DBI::errstr";
