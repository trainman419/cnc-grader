The automated crash-and-compile grader.

Tl;dr: it's still a work in progress. Use at your own risk.


Setup instructions:

Configure apache to execute perl CGI scripts. Put grader-web.pl somewhere on your server.

Set up the database. MySQL is known to work; other database engines may work, but are untested. The default database name is crashncompile; user crashncompile; password crashncompile. Use grader.sql to set up the database schema.

Set up frink. Make sure the paths to frink in ./grade.py and ./frink are correct for your system.

Set up the grader cron job: make sure the path to grade.py in grader-cron.pl is correct, and set up a cron job to run grader-cron.pl at 1-5 minute intervals.

Set up the directory structure: create /opt/crashandcompile , /opt/crashandcompile/tmp , and /opt/crashandcompile/archive .

Set up the problem descriptions and test cases. Each problem should be a directory containing a markdown description of the problem (*.md), a folder full of inputs (inputs/in*), and a folder full of matching outputs (outputs/out*). The problems.sh script takes these directories as arguments and produces /opt/crashandcompile/problems
