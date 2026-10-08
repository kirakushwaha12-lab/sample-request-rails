class User < ActiveRecord::Base
  self.table_name = "users"

  has_many :sample_requests,
           foreign_key: "created_by"

  has_many :merchant_clients,
           foreign_key: "merchant_id"

  validates :user_id, uniqueness: true
end