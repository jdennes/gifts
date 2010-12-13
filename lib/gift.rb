class Gift
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :description, Text
  property :status, String
  property :category, String

  validates_presence_of :name
  validates_presence_of :status
  validates_presence_of :category

  has 1, :intention
end
