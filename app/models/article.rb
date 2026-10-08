class Article < ActiveRecord::Base
  self.table_name = "articles"

  belongs_to :client,
             foreign_key: "client_id"
end