class Gift
  include DataMapper::Resource

  property :id,          Serial
  property :name,        String
  property :description, Text
  property :status,      String

  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :status

  has 1, :intention
end
