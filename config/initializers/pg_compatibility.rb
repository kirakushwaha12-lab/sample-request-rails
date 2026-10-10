require "pg"

unless defined?(PGconn)
  Object.const_set(:PGconn, PG::Connection)
end