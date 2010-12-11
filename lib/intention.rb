class Intention
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :email, String, :format => :email_address
  property :token, String

  validates_presence_of :name
  validates_presence_of :email
  
  belongs_to :gift
end
