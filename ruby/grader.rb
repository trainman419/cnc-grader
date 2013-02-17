require 'sinatra'

enable :sessions

get '/' do
  if session['user_id']
    @logged_in = true

    # TODO: pull this user's submissions from DB
    # Submission name format: Problem Name + File Name
    @submissions = []
    @submissions.push({ :name => 'Submission A', :pass => false })
    @submissions.push({ :name => 'Submission B', :pass => true })
  else
    # TODO: pull all user's submissions from a DB
    # Submission name format: Team Name + Problem Name
    @submissions = []
    @submissions.push({ :name => 'Submission A', :pass => false })
    @submissions.push({ :name => 'Submission B', :pass => true })
  end

  # TODO: pull scoreboard data from DB
  @scoreboard = []
  @scoreboard.push({ :name => 'Team A', :score => 5 })

  erb :landing
end

get '/problem' do
  if session['user_id']
    @logged_in = true
  end

  # TODO: pull current problem name from DB
  @problem = "ones"

  erb :problem
end

get '/settings' do
  if not session['user_id']
    # TODO: redirect to landing page
  end

  @username = session['username']
  @teamname = session['teamname']
end

get '/login' do
  erb :login
end

get '/logout' do
  # TODO
end
