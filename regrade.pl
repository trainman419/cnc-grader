#!/usr/bin/perl
#

use strict;
use DBI;
use File::Copy;

if( scalar(@ARGV) != 1 ) {
   print "Usage: ./regrade.pl <num>\n";
   exit(1);
}

my $problem = $ARGV[0];

print "Regrading problem $problem\n";

my $dbh = DBI->connect("DBI:mysql:crashncompile", "crashncompile",
      "crashncompile") or die "Can't connect to database: $DBH::errstr";

my $basedir = "/opt/crashandcompile";
my $grader = "/home/turtlebot/cnc_2012/grader/grade2.py";

chdir("$basedir/tmp");

my $userrows = $dbh->selectall_arrayref('select id, email from users');

my %users;

# build user hash
for my $user (@$userrows) {
   $users{$user->[0]} = $user->[1];
}

# clean up
$userrows = undef;

my $problem_dir = "$basedir/problems/$problem";
opendir DIR, $problem_dir or die "Failed to open problem directory $problem_dir";
my @problem_files = readdir(DIR);
closedir DIR;
my @input;
for my $problem_file (@problem_files) {
   if( $problem_file =~ m/^in/ ) {
      push @input, $problem_file;
   }
}

my $total = scalar(@input);

my $results = "";

for my $user (keys %users) {

   print "Regrading user $user\n";

   my $rows = $dbh->selectall_arrayref('select id, problem, time, filename from submissions where problem = ? and userid = ?',
      undef, ($problem, $user));

   my $output = "";

   for my $row (@$rows) {
      my $time = $row->[2];
      my $file = $row->[3];
      my $archive = "$basedir/archive/$user/$time-$file";
      if( not -f $archive ) {
         print "Missing archive file $archive\n";
      } else {
         print "Regrading archive file $archive\n";
         my $tmpfile = "$basedir/tmp/$file";
         copy($archive, "$tmpfile") or print "Failed to copy out of archive\n";

         my $pass = 0;

         for my $input_file (@input) {
            my $output_file = $input_file;
            $output_file =~ s/^in/out/;
            if( -e "$problem_dir/$output_file" ) {
               my $cmd = "$grader $file $problem_dir/$input_file $problem_dir/$output_file";
               my $out = `$cmd`;
               my $res = $?;
               if( not $res ) {
                  print "Pass $res\n";
                  $pass++;
               } else {
                  print "Fail $res\n";
               }
               print "$out";
            } else {
               print "Missing output for $problem_dir/$input_file\n";
            }
         }

         $output .= "$archive passed $pass out of $total\n";

         unlink($tmpfile);
      }
   }

   # print results; don't send email.
   if( $output ne "" ) {
      $results .= "Results for $users{$user}:\n$output\n";
   }
}

print "\n";
print $results;
