require "jwt"
require "securerandom"

class AdminController < ApplicationController
  before_action :admin_only, only: [:create_user, :users]

  def create_user
    user_id = params[:user_id]
    name = params[:name]
    department = params[:department]
    email = params[:email]
    role = params[:role]

    unless user_id.present? && name.present? && department.present? && email.present? && role.present?
      return render json: {
        message: "All fields are required"
      }, status: :bad_request
    end

    valid_mapping = case department
                when "marketing"
                  role == "merchant"
                when "sample"
                  role == "sampler"
                when "administration"
                  ["admin", "super_admin"].include?(role)
                else
                  false
                end

unless valid_mapping
  return render json: {
    message: "Invalid Department and Role combination"
  }, status: :bad_request
end

    existing_user = ActiveRecord::Base.connection.exec_query(
      <<~SQL,
        SELECT id, user_id, password_hash
        FROM users
        WHERE user_id = $1
      SQL
      "CreateUserCheck",
      [[nil, user_id]]
    )

    if existing_user.rows.any?
      return render json: {
        message: "User ID already exists"
      }, status: :conflict
    end

    invitation_token = SecureRandom.hex(32)

    result = ActiveRecord::Base.connection.exec_query(
      <<~SQL,
        INSERT INTO users
        (
          user_id,
          name,
          department,
          email,
          role,
          password_hash,
          invitation_token
        )
        VALUES ($1, $2, $3, $4, $5, NULL, $6)
        RETURNING id, user_id, name, department, email, role
      SQL
      "CreateUser",
      [
        [nil, user_id],
        [nil, name],
        [nil, department],
        [nil, email],
        [nil, role],
        [nil, invitation_token]
      ]
    )

    user = result.first

    invitation_link =
      "http://localhost:3000/accept-invitation.html?token=#{CGI.escape(invitation_token)}"

    mail = ActionMailer::MailHelper

    AdminMailer.invitation_email(
      name,
      email,
      invitation_link
    ).deliver_now

    Rails.logger.info "INVITATION EMAIL SENT"

    render json: {
      message: "Invitation sent successfully",
      user: user
    }, status: :created

  rescue => error
    Rails.logger.error "Admin user creation/invitation error: #{error}"

    render json: {
      message: "Failed to create user or send invitation"
    }, status: :internal_server_error
  end


  def users
    result = ActiveRecord::Base.connection.exec_query(
      <<~SQL
        SELECT
          id,
          user_id,
          name,
          department,
          email,
          role,
          CASE
            WHEN password_hash IS NOT NULL THEN 'Active'
            WHEN invitation_token IS NOT NULL THEN 'Pending'
            ELSE 'Inactive'
          END AS status
        FROM users
        ORDER BY id ASC
      SQL
    )

    render json: result.to_a

  rescue => error
    Rails.logger.error "Get users error: #{error}"

    render json: {
      message: "Failed to load users"
    }, status: :internal_server_error
  end
  
  def delete_user
  user_id = params[:user_id]

  user = ActiveRecord::Base.connection.exec_query(
    <<~SQL,
      SELECT id, user_id
      FROM users
      WHERE id = $1
    SQL
    "DeleteUserCheck",
    [[nil, user_id]]
  )

  if user.rows.empty?
    return render json: {
      message: "User not found"
    }, status: :not_found
  end

  ActiveRecord::Base.connection.exec_query(
    <<~SQL,
      DELETE FROM users
      WHERE id = $1
    SQL
    "DeleteUser",
    [[nil, user_id]]
  )

  render json: {
    message: "User deleted successfully"
  }, status: :ok

rescue => error
  Rails.logger.error "Delete user error: #{error}"

  render json: {
    message: "Failed to delete user"
  }, status: :internal_server_error
end

  private

  def admin_only
    begin
      authorization = request.headers["Authorization"]
      token = authorization&.split(" ")&.[](1)

      unless token
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

      result = ActiveRecord::Base.connection.exec_query(
        <<~SQL,
          SELECT role
          FROM users
          WHERE id = $1
        SQL
        "AdminAuthorization",
        [[nil, user_id]]
      )

      if result.rows.empty?
        return render json: {
          message: "User not found"
        }, status: :unauthorized
      end

      unless result.first["role"] == "admin"
        return render json: {
          message: "Admin access required"
        }, status: :forbidden
      end

    rescue => error
      Rails.logger.error "Admin authorization error: #{error}"

      render json: {
        message: "Invalid or expired session"
      }, status: :unauthorized
    end
  end
end