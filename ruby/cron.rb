require 'bcrypt'
require 'data_mapper'
require 'fileutils'

require './config'
require './datamap'


# TODO: convert to ruby
tmpdir = File.join($upload_dir, "tmp")
FileUtils.mkdir_p(tmpdir)
Dir.chdir(tmpdir)


# Get all ungraded submissions
pending = Submission.all(:result => 0, :order => :time.desc)

teams = {}
users = {}

inputs = {}

pending.each do |submission|
  # Mark older, ungraded uploads as skipped
  if submission.user.team
    if teams.has_key?(submission.user.team.id)
      submission.result = 3
      submission.save
      next
    else
      teams[submission.user.team.id] = 1
    end
  else
    if users.has_key?(submission.user.id)
      submission.result = 3
      submission.save
      next
    else
      users[submission.user.id] = 1
    end
  end

  problem_id = submission.problem.id

  # grade latest upload from this team/person
  puts submission.time
  puts submission.filename
  puts submission.user.name
  # Get input files
  if not inputs.has_key?(problem_id)
    problempath = File.join($basedir, 'problems', problem_id.to_s(), 'in*')
    inputs[problem_id] = Dir.glob(problempath)
  end

  pass = 0
  inputs[problem_id].each do |input_file|
    error = ""

    output_file = input_file
    output_file["in"] = "out"
    f = File.join($upload_dir, submission.user.id.to_s(), submission.filename)
    cmd = [$grader, f, input_file, output_file].join(" ")
    output = %x( #{cmd} )
    status = $?.exitstatus

    case status
    when 0
      pass += 1
    when 1
      error = "Compilation Failed"
    when 2
      error = "Execution timed out"
    when 3
      error = "Failed test #{input_file}"
    end

    puts status
    puts output
  end

  if pass == inputs[problem_id].size
    puts "Pass"
  else
    puts "Fail"
  end

  puts
end

#for my $user (keys %users) {
#   opendir DIR, "$basedir/$user";
#   my @files = readdir(DIR);
#   closedir DIR;
#
#   my $email = "";
#   my $message = "";
#
#   for my $file (@files) {
#      if( not $file =~ m/^\./ ) {
#         my $row = $dbh->selectrow_arrayref('select id,problem,time from submissions where filename = ? order by time desc limit 1', undef, $file);
#
#         if( defined $row ) {
#            print "Found submission $file from $user for problem $row->[1] at $row->[2]\n";
#            my $problem = $row->[1];
#            my $id = $row->[0];
#
#            # do grading and update DB
#
#            # find problem and test data
#            my $problem_dir = "$basedir/problems/$problem";
#            opendir DIR, $problem_dir or die "Failed to open problem directory $problem_dir";
#            my @problem_files = readdir(DIR);
#            closedir DIR;
#
#            my @input;
#            for my $problem_file (@problem_files) {
#               if( $problem_file =~ m/^in/ ) {
#                  push @input, $problem_file;
#               }
#            }
#
#            my $pass = 0;
#            my $total = scalar(@input);
#            my $error = "";
#            
#            for my $input_file (@input) {
#               my $output_file = $input_file;
#               $output_file =~ s/^in/out/;
#               if( -e "$problem_dir/$output_file" ) {
#                  my $cmd = "$grader $basedir/$user/$file $problem_dir/$input_file $problem_dir/$output_file";
#                  my $output = `$cmd`;
#                  my $res = ($? >> 8);
#                  if( $res ) {
#                     $email .= "Problem $problem: $file failed:\n$output ($res)\n";
#                  } else {
#                     $pass++;
#                  }
#                  if( $res == 1 ) {
#                     $error = "Compilation Failed";
#                     last;
#                  } elsif( $res == 2 ) {
#                     $error = "Execution timed out";
#                     last;
#                  }
#               } else {
#                  print "Missing output for $problem_dir/$input_file\n";
#               }
#            }
#
#            if( $pass == $total ) {
#               $dbh->do('update submissions set result = 1 where id = ?',
#                     undef, $id);
#               $email .= "Problem $problem: $file passed.\n";
#            } else {
#               $dbh->do('update submissions set result = 2 where id = ?',
#                     undef, $id);
#            }
#            $message = "Passed $pass of $total";
#            $error and $message = $error;
#            $dbh->do('update submissions set note = ? where id = ?',
#                     undef, ($message, $id));
#         } else {
#            print "Found submission from $user without DB entry: $file\n";
#         }
#
#         unlink("$basedir/$user/$file");
#
#         if( $email ne "" ) {
#            $email .= "\n";
#         }
#      }
#   }
#
#   # TODO: send email
#   if( $email ne "" ) {
#      print "Sending email to $users{$user}:\n";
#      print $email;
#      if( -w "/dev/ttyACM0" ) {
#         print "Sending email to printer\n";
#         open LP, ">/dev/ttyACM0";
#         print LP "$users{$user}\n";
#         sleep(1);
#         print LP "$message\n";
#         sleep(1);
#         print LP "fire!\n";
#         close LP;
#      }
##      open EMAIL, "|/usr/sbin/sendmail -t -f 'hendrix\@namniart.com'";
##      print EMAIL "To: $users{$user}\n";
##      print EMAIL "From: Crash and Compile Grader <hendrix\@namniart.com>\n";
##      print EMAIL "Subject: Crash and Compile Grader Results\n";
##      print EMAIL "Content-type: text/plain\n\n";
##      print EMAIL $email;
##      close EMAIL;
#   }
#}
