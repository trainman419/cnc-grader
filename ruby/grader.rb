require 'sinatra'
require 'data_mapper'
require 'bcrypt'

require "./datamap"
require "./config"

enable :sessions

DataMapper.auto_upgrade!

get '/' do
  if session['user_id']
    @logged_in = true

    # Submission name format: Problem Name + File Name
    # TODO: enforce display format
    @submissions = Submission.all(:user => session['user_id'],
                                 :order => [ :time.desc ])
    #@submissions.push({ :name => 'Submission A', :pass => false })
    #@submissions.push({ :name => 'Submission B', :pass => true })
  else
    # Submission name format: Team Name + Problem Name
    # TODO: enforce display format
    @submissions = Submission.all(:order => [ :time.desc ])
    #@submissions.push({ :name => 'Submission A', :pass => false })
    #@submissions.push({ :name => 'Submission B', :pass => true })
  end

  # pull scoreboard data from DB
  @scoreboard = Team.all(:order => [ :score.desc ])
  #@scoreboard.push({ :name => 'Test Team', :score => 5 })

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
  if session['user_id']
    # TODO
    #  - team creation
    #  - request to join a team
    #  - email change
    #  - username change
    #  - password change
    @user = User.get(session['user_id'])
    if @user
      return erb :settings
    end
  end
  redirect to('/login')
end

get '/login' do
  erb :login
end

post '/login' do
  @login = { :name => params['name'], :pass => params['pass'] }
  if params['name'] and params['pass']
    user = User.first(:name => params['name'])
    if user and user.pw_hash == params['pass']
      session['user_id'] = user.id
      redirect to('/')
    else
      @error = "Bad username or password"
    end
  end
  erb :login
end

get '/logout' do
  session.clear
  redirect '/'
end

get '/signup' do
  erb :signup
end

post '/signup' do
  @user = User.new(:name => params['name'],
                  :email => params['email'])

  error = ! @user.valid?

  if ! params['password'] or params['password'].length == 0
    error = true
    @user.errors.add(:password, "Password must not be blank")
  elsif ! params['password_confirm'] or params['password_confirm'].length == 0
    error = true
    @user.errors.add(:password_confirm, "Password must not be blank")
  elsif params['password'] != params['password_confirm']
    error = true
    @user.errors.add(:password_confirm, "Passwords must match")
  end

  if error
    @error = "Please correct the following problems"
    erb :signup
  else
    @user.pw_hash = params['password']
    if @user.save
      session['user_id'] = @user.id
      redirect to('/')
    else
      @error = "Error creating user"
      @user.errors.each do |err|
        @error += "; "
        @error += err.join("; ")
      end
      erb :signup
    end
  end
end

class Form
  def initialize(obj)
    @obj = obj
  end

  def input(field, options={})
    options = { :type => "text", :label => "" }.merge(options)
    type = options[:type]
    label = options[:label]

    val = ""
    if @obj
      val = @obj[field]
    end

    html = <<EOF
<div class="input_row">
<label for="#{field}">#{label}</label>
<input type="#{type}" name="#{field}" value="#{val}"/>
EOF
    if @obj and @obj.respond_to?(:errors) and @obj.errors[field] and
      @obj.errors[field].length > 0
      err = @obj.errors[field].join("; ")
      html += <<EOF
<div class="error">#{err}</div>
EOF
    end
    html += "</div>"
    html
  end

  def submit(options={})
    opts = { :label => "Submit" }.merge(options)
    <<EOF
<div class="input_row">
<input type="submit" value="#{opts[:label]}"/>
</div>
EOF
  end
end

helpers do
  def form_for(obj, &block)
    block.call(Form.new(obj))
  end
end
