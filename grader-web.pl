#!/usr/bin/perl
#
# The user and submission website for the grader
#
# Design:
#  NO fancy javascript/CSS/Ajax; just perl+html
#
#  a fairly simple email + password login system
#  upload programs to a user-specific directory
#  store user email and password hash in the DB
#  
#  session: login creates a session ( random ID)
#   session table: ID and last use date
#   sessions are date-checked before use
#   invalid sessions are deleted and a login page presented
#
#  uploads:
#   uploads go to a user-specific directory
#   grader script runs once every 5-10 minutes, processes any incoming
#   submissions
#
#   grader emails results to users based on email in DB
#   uploads only allowed during official time window
#
#  problem:
#   web interface only presents problem during offical submission window
#
#  user management:
#   separate cli tool for initial user creation
#   users can change their password from the web interface
#
# Database schema:
#  users table: id, username, password hash, start time
#  session table: session id, userid, last use
#  submissions table: id, submission time, problem, file, result, notes
#  results table?
#  problems table?
#
# Filesystem layout:
#  /opt/crashandcompile/
#                       <userID>/ - uploads
#                       problems/<problem>/ - problem files
#                       tmp/ - grading temp space
#
# TODO:
#  standings page
#  password change page
#  links on landing page
#

use strict;
use CGI qw/:standard *table/;
use DBI;
use Crypt::PasswdMD5;
use Crypt::Random qw( makerandom makerandom_octet );
use MIME::Base64;
use File::Copy;

# define problem number
my $problem = 1;

my $basedir = "/opt/crashandcompile";
my $timelimit = 60 * 60 * 2; # 2 hours

# create database connection

my $dbh = DBI->connect("DBI:mysql:crashncompile", "crashncompile",
      "crashncompile");

my $session = cookie('sessionID');
my $cookie = undef;
my $user = undef;
my $start = undef;
my $debug = "";

if( not $dbh ) {
   print header(-cookie=>$cookie),
         start_html("Database Error"),
         h1({-align=>'center'}, "Database Error"),
         p($DBI::errstr),
         end_html;
   exit(0);
}

sub check_timeslot() {
   if( defined $start ) {
      return time() < ($timelimit + $start);
   } else {
      return 0;
   }
}

# display the login page
sub login() {
   print header(-cookie=>$cookie),
         start_html("Login"),
         h1({-align=>'center'},"Login"),
         start_form,
         table({-border=>0, -align=>'center'},
               Tr(
                  [
                     td({-align=>'right'}, "Email") . 
                     td({-align=>'left'},  
                        textfield(-name=>'email', -size=>40,
                           -maxlength=>100)
                        ),
                     td({-align=>'right'}, "Password") .
                     td({-align=>'left'},  
                        password_field(-name=>'password', -size=>40,
                           -maxlength=>100)
                        ),
                     td("") .
                     td({-align=>'left'},
                        submit(-name=>'Login', -value=>'Login')
                        )
                  ]
                  )
               ),
         end_form,
         p($debug),
         end_html;
}

# display the landing page
sub landing() {
   my $url = url;
   print header(-cookie=>$cookie),
         start_html("Crash and Compile"),
         h1({-align=>'center'}, "Crash and Compile"),
         CGI::start_ul(),
         li(a({href=>"$url?problem="},"Problem description")),
         li(a({href=>"$url?upload="}, "Upload source")),
         li(a({href=>"$url?results="},"View results")),
         li("View standings"),
         li(a({href=>"$url?passwd="},"Change password")),
         li(
            start_form,
            submit(-name=>'Logout', -value=>'Logout'),
            end_form
           );

   if( defined $start ) {
      my $remain = ($start + $timelimit) - time();
      if( $remain > 0 ) {
         my $hours = int($remain / 3600);
         my $minutes = int(($remain % 3600) / 60);
         my $seconds = int(($remain % 60 ));
         print li(sprintf("%d:%02d:%02d remaining\n",$hours,$minutes,$seconds));
      } else {
         print li("Time limit expired");
      }
   } else {
      print li(
               start_form,
               submit(-name=>'Start', -value=>'Start Qualification'),
               end_form
            );
   }

   print CGI::end_ul(),
         p($debug),
         end_html;
}

sub problem_desc($) {
   my ($p) = @_;
   my $problem_file = "$basedir/problems/$p/problem.html";
   if( -e $problem_file ) {
      open FILE, $problem_file;
      print <FILE>;
      close FILE;
   }
}

# display the upload page
sub upload_page() {
   print header(-cookie=>$cookie),
         start_html("Upload"),
         h1({-align=>'center'},"Upload");

   problem_desc($problem);

   print div({-align=>'center'},
            start_form,
            filefield('file'),
            br,
            submit(-name=>'Upload', -value=>'Upload'),
            end_form
         );
   print p($debug),
         p("User: $user"),
         div({-align=>'center'}, a({href=>url}, "Home")),
         end_html;
}

# display the problem page
sub problem() {
   print header(-cookie=>$cookie),
         start_html("Problem Description"),
         h1({-align=>'center'},"Problem Description");

   problem_desc($problem);

   print p($debug),
         div({-align=>'center'}, a({href=>url}, "Home")),
         end_html;
}

sub results() {
   print header(-cookie=>$cookie),
         start_html("Results"),
         h1({-align=>'center'},"Results");

   # get submissions
   my $rows = $dbh->selectall_arrayref('select userid, time, problem, result from submissions');

   print start_table;
   print Tr(td(["UserID", "Time", "Problem", "Result"]));
   for my $row (@$rows) {
      $row->[1] = localtime($row->[1]);
      if( $row->[3] == 0 ) {
         $row->[3] = "Not graded";
      } elsif( $row->[3] == 1 ) {
         $row->[3] = "Passed";
      } elsif( $row->[3] == 2 ) {
         $row->[3] = "Failed";
      } else {
         $row->[3] = "Unknown State";
      }
      print Tr(td($row));
   }
   print end_table;

   print p($debug),
         div({-align=>'center'}, a({href=>url}, "Home")),
         end_html;
}

sub passwd() {
   print header(-cookie=>$cookie),
         start_html("Change Password"),
         h1({-align=>'center'},"Change Password"),
         div({-align=>'center'},
            start_form,
            table(
               Tr(td(["Old Password", password_field(-name=>'old',
                        -size=>40,-maxlength=>100)])),
               Tr(td(["New Password", password_field(-name=>'new',
                        -size=>40,-maxlength=>100)])),
               Tr(td(["New Password (again)", password_field(-name=>'new_',
                        -size=>40,-maxlength=>100)])),
               Tr(td(["", submit(-name=>'Change', -value=>'Change Password')]))
               ),
            end_form
            ),
         p($debug),
         div({-align=>'center'}, a({href=>url}, "Home")),
         end_html;
}

# if logout, clear the session cookie
if( param('Logout') ) {
   if( $session ) {
      $dbh->do('delete from session where id = ?', undef, $session);
   }
   $session = "";
}

# validate sessionID
if( $session ) {
   my $row = $dbh->selectrow_hashref('select userid,last_used from session where id = ?', undef, $session);
   if( $row ) {
      $user = $row->{'userid'};
      my $last_used = $row->{'last_used'};

      # session timeout
      my $now = time();
      if( $now - $last_used < 60*60 ) {
         $dbh->do('update session set last_used = ? where id = ?', undef,
               ($now, $session));

         $row = $dbh->selectrow_hashref('select start from users where id = ?',
               undef, $user);
         $start = $row->{'start'};
      } else {
         $debug = "Session timed out";
         # clear DB
         $dbh->do('delete from session where id = ?', undef, $session);
         $session = "";
      }
   } else {
      $session = "";
      $debug = "Bad sessionID";
   }
}

if( param('Login') ) {
   $debug = "Login Failed";
   my $email = param('email');
   my $pass = param('password');
   param('password','');

   my $row = $dbh->selectrow_hashref('select id,password,start from users where email = ?',
         undef, $email);
   if( $row ) {
      my $hash = $row->{'password'};
      if( $hash eq unix_md5_crypt($pass, $hash) ) {
         $debug = "Login successful";
         # generate a 128-character sessionID
         $session = encode_base64(makerandom_octet(Length=>(96)));
         $session =~ s/\n//g;
         $user = $row->{'id'};
         $start = $row->{'start'};
         # insert into session table
         $dbh->do('insert into session (id, userid, last_used) values (?,?,?)',
               undef, ($session, $user, time()));
      }
   }
}

if( $session ) {
   # if time is expired, show the sample problem
   if( not check_timeslot() ) {
      $problem = 0;
   }

   # receive uploaded file
   my $upload_fh = upload('file');
   if( defined $upload_fh ) {
      my $infile = param('file');
      $debug = "Got uploaded file $infile";
      my $now = time();
      my $infile_path = tmpFileName($infile);
      my $outpath = "$basedir/$user/$infile";
      my $archive = "$basedir/archive/$user/$now-$infile";

      mkdir "$basedir";
      mkdir "$basedir/$user";
      mkdir "$basedir/archive";
      mkdir "$basedir/archive/$user";
      copy($infile_path, $outpath);
      copy($infile_path, $archive);
      # add to submissions table
      $dbh->do('insert into submissions (userid, time, problem, filename) '.
            'values (?, ?, ?, ?)', undef, ($user, $now, $problem, $infile));
   }

   # handle password change
   if( defined param('Change') ) {
      param('passwd','');
      $debug = "Password not changed";
      my $old = param('old');
      my $new = param('new');
      my $new_ = param('new_');
      # Check old password
      my $row = $dbh->selectrow_arrayref('select password from users where id = ?', undef, $user);
      if( $row->[0] eq unix_md5_crypt($old, $row->[0]) ) {
         if( $new eq $new_ ) {
            if( $new eq '' ) {
               $debug = "Password can't be empty";
            } else {
               # TODO: update DB
               my $hash = unix_md5_crypt($new);
               $dbh->do('update users set password = ? where id = ?',
                     undef, ($hash, $user));
               $debug = "Password Updated";
               Delete('passwd');
            }
         } else {
            $debug = "New passwords don't match";
         }
      } else {
         $debug = "Invalid old password";
      }
   }

   if( defined param('Start') ) {
      if( not defined $start ) {
         $start = time();
         $dbh->do('update users set start = ? where id = ?', undef, 
               ($start, $user));
      }
   }
}

$cookie = cookie(-name=>'sessionID', -value=>$session);

if( not defined $session or $session eq '') {
   login();
} elsif( defined param('problem') ) {
   problem();
} elsif( defined param('upload') ) {
   upload_page();
} elsif( defined param('results') ) {
   results();
} elsif( defined param('passwd') ) {
   passwd();
} else {
   landing();
}
