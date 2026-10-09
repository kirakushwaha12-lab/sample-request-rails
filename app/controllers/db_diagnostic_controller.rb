class DbDiagnosticController < ApplicationController
  def show
    expected_token = ENV["DB_DIAGNOSTIC_TOKEN"].to_s
    supplied_token = request.headers["Authorization"].to_s

    unless expected_token.present? &&
           supplied_token == "Bearer #{expected_token}"
      return render json: { message: "Unauthorized" }, status: 401
    end

    connection = ActiveRecord::Base.connection

    tables = connection.tables.sort

    user_count =
      if tables.include?("users")
        User.count
      else
        nil
      end

    render json: {
      database_connected: true,
      database_name: connection.current_database,
      tables: tables,
      users_table_exists: tables.include?("users"),
      user_count: user_count
    }
  rescue => error
    Rails.logger.error(
      "DB DIAGNOSTIC ERROR: #{error.class}: #{error.message}"
    )

    render json: {
      database_connected: false,
      error_type: error.class.name
    }, status: 500
  end
end