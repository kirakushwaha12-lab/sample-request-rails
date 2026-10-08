class MerchantClient < ActiveRecord::Base
  self.table_name = "merchant_clients"

  belongs_to :merchant,
             class_name: "User",
             foreign_key: "merchant_id"

  belongs_to :client,
             foreign_key: "client_id"
end