class Client < ActiveRecord::Base
  self.table_name = "clients"

  has_many :articles,
           foreign_key: "client_id"

  has_many :merchant_clients,
           foreign_key: "client_id"
end