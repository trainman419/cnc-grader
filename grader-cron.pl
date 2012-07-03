#!/usr/bin/perl
#

use strict;
use DBI;

my $dbh = DBI->connect("DBI:mysql:crashncompile", "crashncompile",
      "crashncompile") or die "Can't connect to database: $DBH::errstr";

my $basedir = "/tmp/crashandcompile";
my $grader = "/home/hendrix/crash-n-compile/cnc_2012/grader/grade.py";

chdir("$basedir/tmp");

my $userrows = $dbh->selectall_arrayref('select id, email from users');

my %users;

# build user hash
for my $user (@$userrows) {
   $users{$user->[0]} = $user->[1];
}

# clean up
$userrows = undef;

for my $user (keys %users) {
   opendir DIR, "$basedir/$user";
   my @files = readdir(DIR);
   closedir DIR;
   for my $file (@files) {
      if( not $file =~ m/^\./ ) {
         my $row = $dbh->selectrow_arrayref('select id,problem,time from submissions where filename = ? order by time desc limit 1', undef, $file);

         if( defined $row ) {
            print "Found submission $file from $user for problem $row->[1] at $row->[2]\n";
            my $problem = $row->[1];
            my $id = $row->[0];

            # do grading and update DB

            # find problem and test data
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
            
            for my $input_file (@input) {
               my $output_file = $input_file;
               $output_file =~ s/^in/out/;
               if( -e "$problem_dir/$output_file" ) {
                  my $cmd = "$grader $basedir/$user/$file $problem_dir/$input_file $problem_dir/$output_file";
#                  print "Running $cmd\n";
                  my $output = `$cmd`;
                  my $res = $?;
                  if( $res ) {
                     print "Grading $file failed: $output\n";
                  } else {
                     print "$file passed!\n";
                  }
               } else {
                  print "Missing output for $problem_dir/$input_file\n";
               }
            }


         } else {
            print "Found submission from $user without DB entry: $file\n";
         }
         print "\n";
      }
   }
}
