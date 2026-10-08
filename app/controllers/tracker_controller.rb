require "jwt"

class TrackerController < ApplicationController

  # =========================================================
  # GET TRACKER DATA
  # =========================================================
  def index

    begin

      auth_header = request.headers["Authorization"]

      unless auth_header.present?
        return render json: {
          message: "Authentication required"
        }, status: :unauthorized
      end

      token = auth_header.split(" ")[1]

      unless token.present?
        return render json: {
          message: "Authentication required"
        }, status: :unauthorized
      end

      decoded = JWT.decode(
        token,
        ENV["JWT_SECRET"],
        true,
        { algorithm: "HS256" }
      )

      decoded_user = decoded[0]

      puts "TRACKER USER: #{decoded_user}"

      connection = ActiveRecord::Base.connection

      query = <<~SQL
  SELECT
    sr.request_id,
    sr.client_code,
    ts.current_stage,
    ts.updated_at
  FROM sample_requests sr
  LEFT JOIN tracker_stages ts
    ON ts.sample_request_id = sr.id
SQL

if decoded_user["role"].present? &&
   decoded_user["role"].to_s.downcase == "merchant"

  query += <<~SQL
    WHERE sr.created_by =
      #{connection.quote(decoded_user["id"])}
  SQL
end

query += <<~SQL
  ORDER BY sr.created_at DESC
SQL

result = connection.exec_query(query)

      render json: result.to_a

    rescue JWT::DecodeError => error

      Rails.logger.error "Tracker JWT error: #{error}"

      render json: {
        message: "Invalid or expired token"
      }, status: :unauthorized

    rescue => error

      Rails.logger.error "Tracker error: #{error}"

      render json: {
        message: error.message,
        error: error.to_s
      }, status: :internal_server_error

    end

  end
  
  def update_stage

  begin

    auth_header = request.headers["Authorization"]

    unless auth_header.present?
      return render json: {
        message: "Authentication required"
      }, status: :unauthorized
    end

    token = auth_header.split(" ")[1]

    unless token.present?
      return render json: {
        message: "Authentication required"
      }, status: :unauthorized
    end

    decoded = JWT.decode(
      token,
      ENV["JWT_SECRET"],
      true,
      { algorithm: "HS256" }
    )

    user_id = decoded[0]["id"]

    user = User.find_by(id: user_id)

    unless user
      return render json: {
        message: "User not found"
      }, status: :not_found
    end

    unless user.role.to_s.downcase == "sampler"
      return render json: {
        message: "Access denied"
      }, status: :forbidden
    end
    
    request_id = params[:requestId]
    new_stage = params[:stage]

    allowed_stages = [
      "Created",
      "Received by Sample Department",
      "Pattern Making",
      "Sample Cutting",
      "Sample Making",
      "Sample Ready"
    ]

    unless allowed_stages.include?(new_stage)
      return render json: {
        message: "Invalid stage"
      }, status: :bad_request
    end

    sample_request =
      ActiveRecord::Base.connection.exec_query(
        "SELECT request_id, client_code FROM sample_requests
         WHERE request_id = #{ActiveRecord::Base.connection.quote(request_id)}
         LIMIT 1"
      ).to_a.first

    unless sample_request
      return render json: {
        message: "Sample request not found"
      }, status: :not_found
    end
    
    connection = ActiveRecord::Base.connection

connection.execute(
  <<~SQL
    UPDATE tracker_stages
    SET
      current_stage = #{connection.quote(new_stage)},
      updated_at = CURRENT_TIMESTAMP
    WHERE sample_request_id = (
      SELECT id
      FROM sample_requests
      WHERE request_id = #{connection.quote(request_id)}
      LIMIT 1
    )
  SQL
)

    render json: {
      message: "Tracker stage updated successfully",
      request_id: request_id,
      client_code: sample_request["client_code"],
      stage: new_stage
    }

  rescue JWT::DecodeError => error

    render json: {
      message: "Invalid or expired token"
    }, status: :unauthorized

  rescue => error

    Rails.logger.error "Tracker update error: #{error}"

    render json: {
      message: error.message,
      error: error.to_s
    }, status: :internal_server_error

  end

end

end

