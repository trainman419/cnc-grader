require "./config"

DataMapper::Logger.new($stdout, :debug)

DataMapper::setup(:default, $db_path)

class User
  include DataMapper::Resource
  include BCrypt

  property :id,         Serial
  property :name,       String, :unique => true
  property :email,      String, :unique => true, :format => :email_address
  property :pw_hash,    BCryptHash

  belongs_to :team, :required => false
  has n, :submission

  validates_length_of :name, :min => 1
  validates_length_of :email, :min => 1
end

class Submission
  include DataMapper::Resource

  property :id,         Serial
  property :time,       DateTime
  property :filename,   String
  property :result,     String
  property :note,       Text

  belongs_to :user
end

class Team
  include DataMapper::Resource

  property :id,         Serial
  property :name,       String, :unique => true
  property :score,      Integer

  has n, :user

  validates_length_of :name, :min => 1
end

DataMapper.finalize
