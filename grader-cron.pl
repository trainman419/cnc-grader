#!/usr/bin/perl
#

use strict;
use DBI;

my $dbh = DBI->connect("DBI:mysql:crashncompile", "crashncompile",
      "crashncompile") or die "Can't connect to database: $DBH::errstr";

my $basedir = "/opt/crashandcompile";
my $grader = "/home/turtlebot/cnc_2012/grader/grade.py";

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

   my $email = "";

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

            my $pass = 0;
            my $total = scalar(@input);
            my $error = "";
            
            for my $input_file (@input) {
               my $output_file = $input_file;
               $output_file =~ s/^in/out/;
               if( -e "$problem_dir/$output_file" ) {
                  my $cmd = "$grader $basedir/$user/$file $problem_dir/$input_file $problem_dir/$output_file";
                  my $output = `$cmd`;
                  my $res = ($? >> 8);
                  if( $res ) {
                     $email .= "Problem $problem: $file failed:\n$output ($res)\n";
                  } else {
                     $pass++;
                  }
                  if( $res == 1 ) {
                     $error = "Compilation Failed";
                     last;
                  } elsif( $res == 2 ) {
                     $error = "Execution timed out";
                     last;
                  }
               } else {
                  print "Missing output for $problem_dir/$input_file\n";
               }
            }

            if( $pass == $total ) {
               $dbh->do('update submissions set result = 1 where id = ?',
                     undef, $id);
               $email .= "Problem $problem: $file passed.\n";
            } else {
               $dbh->do('update submissions set result = 2 where id = ?',
                     undef, $id);
            }
            my $message = "Passed $pass of $total";
            $error and $message = $error;
            $dbh->do('update submissions set note = ? where id = ?',
                     undef, ($message, $id));
         } else {
            print "Found submission from $user without DB entry: $file\n";
         }

         unlink("$basedir/$user/$file");

         if( $email ne "" ) {
            $email .= "\n";
         }
      }
   }

   # TODO: send email
   if( $email ne "" ) {
      print "Sending email to $users{$user}:\n";
      print $email;
#      open EMAIL, "|/usr/sbin/sendmail -t -f 'hendrix\@namniart.com'";
#      print EMAIL "To: $users{$user}\n";
#      print EMAIL "From: Crash and Compile Grader <hendrix\@namniart.com>\n";
#      print EMAIL "Subject: Crash and Compile Grader Results\n";
#      print EMAIL "Content-type: text/plain\n\n";
#      print EMAIL $email;
#      close EMAIL;
   }
}
