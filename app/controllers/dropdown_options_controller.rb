class DropdownOptionsController < ApplicationController
  def index
    puts "🔥 DROPDOWN API REQUEST HIT"

    begin
      result = ActiveRecord::Base.connection.exec_query(<<~SQL)
        SELECT field_name, option_value
        FROM public.dropdown_options
        WHERE is_active = TRUE
        ORDER BY field_name, option_value
      SQL

      puts "Dropdown rows found: #{result.rows.length}"

      dropdown_data = {}

      result.each do |row|
        field = row["field_name"]

        dropdown_data[field] ||= []
        dropdown_data[field] << row["option_value"]
      end

      puts "Dropdown fields: #{dropdown_data.keys}"

      render json: dropdown_data, status: :ok

    rescue => error
      Rails.logger.error "Dropdown options error: #{error}"

      render json: {
        error: "Failed to load dropdown options",
        details: error.message
      }, status: :internal_server_error
    end
  end
end