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
      submission.note = "Skipped"
      submission.save
      next
    else
      teams[submission.user.team.id] = 1
    end
  else
    if users.has_key?(submission.user.id)
      submission.result = 3
      submission.note = "Skipped"
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
  fails = []
  error = ""

  inputs[problem_id].each do |input_file|

    output_file = input_file.clone
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
      break
    when 2
      error = "Execution timed out"
      break
    when 3
      fails.push(File.basename(input_file))
    end

    puts status
    puts output
  end

  if pass == inputs[problem_id].size
    submission.result = 1
    submission.note = "Passed Tests"
    # grant points
    if submission.user.team
       team_count = Submission.count(:result => 1, 
                                     :problem => submission.problem,
                                     Submission.user.team.id => submission.user.team.id)
       puts "Team #{submission.user.team.name} has solved this #{team_count} times"
       # only give the user points if they haven't already solved the problem
       if team_count == 0
         # compute points based on previous correct submissions
         count = Submission.count(:result => 1,
                                  :problem => submission.problem)
         points = 0
         case count
         when 0
            points = 3
         when 1
            points = 2
         when 2
            points = 1
         end
         submission.user.team.score += points
       end
    end
  else
    submission.result = 2
    if error and error.length > 0
       submission.note = error
    else
       submission.note = "Failed tests: " + fails.join(", ")
    end
  end
  puts submission.note
  submission.save

  # TODO: send email?

  puts
end
