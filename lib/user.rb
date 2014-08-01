require 'bcrypt'

class User

  attr_reader :password
  attr_accessor :password_confirmation


  include DataMapper::Resource

  property :id, Serial
  property :email, String,  :unique => true, :message => "This email is already taken"
  property :password_digest, Text
  property :password_token, Text
  property :password_token_timestamp, Text

  def password=(password)
  	@password = password
    self.password_digest = BCrypt::Password.create(password)
  end

  def self.authenticate(email, password)
  # that's the user who is trying to sign in
    user = first(:email => email)
    if user && BCrypt::Password.new(user.password_digest) == password
    	user
    else
     	nil
    end
  end

  validates_uniqueness_of :email
  validates_confirmation_of :password

  def update_tokens
    update(password_token: create_new_token,
           password_token_timestamp: create_new_timestamp)
  end



  def create_new_token
    (1..64).map{("A".."Z").to_a.sample}.join
  end

  def create_new_timestamp
    Time.now
  end

end