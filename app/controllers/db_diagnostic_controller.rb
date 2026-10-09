
class DbDiagnosticController < ApplicationController
  def show
    return unauthorized unless valid_token?

    connection = ActiveRecord::Base.connection
    tables = connection.tables.sort

    render json: {
      database_connected: true,
      database_name: connection.current_database,
      tables: tables,
      users_table_exists: tables.include?("users"),
      user_count: tables.include?("users") ? User.count : nil
    }
  rescue => error
    Rails.logger.error("DB DIAGNOSTIC ERROR: #{error.class}: #{error.message}\n#{error.backtrace.first(10).join("\n")}")
    render json: { database_connected: false, error_type: error.class.name },
           status: 500
  end

  def import
    return unauthorized unless valid_token?

    connection = ActiveRecord::Base.connection
    tables = connection.tables

    unless tables.empty?
      return render json: {
        message: "Import stopped: cloud database is not empty",
        tables: tables.sort
      }, status: 409
    end

    sql = request.body.read

    if sql.blank? || sql.bytesize > 2_000_000
      return render json: { message: "Invalid SQL file size" }, status: 400
    end

    if sql.match?(/^\\(restrict|unrestrict|connect|copy)\b/i)
      return render json: {
        message: "SQL contains unsupported psql commands"
      }, status: 400
    end

    connection.transaction do
      connection.raw_connection.exec(sql)
    end
    
    tables = connection.tables.sort

    render json: {
      import_completed: true,
      tables: tables,
      users_table_exists: tables.include?("users"),
      user_count: tables.include?("users") ? User.count : nil
    }
  rescue => error
    Rails.logger.error("DB IMPORT ERROR: #{error.class}: #{error.message}")
    render json: {
      import_completed: false,
      error_type: error.class.name,
      message: "Import failed; check application logs"
    }, status: 500
  end

  private

  def valid_token?
    expected = ENV["DB_DIAGNOSTIC_TOKEN"].to_s
    supplied = request.headers["Authorization"].to_s

    expected.present? && supplied == "Bearer #{expected}"
  end

  def unauthorized
    render json: { message: "Unauthorized" }, status: 401
  end
end