class AuthController < ApplicationController

  def me
  auth_header = request.headers["Authorization"]
  token = auth_header.to_s.split(" ")[1]

  if token.blank?
    return render json: {
      message: "Authentication required"
    }, status: 401
  end

  begin
    decoded = JWT.decode(
      token,
      ENV["JWT_SECRET"],
      true,
      algorithm: "HS256"
    ).first
  rescue JWT::ExpiredSignature, JWT::DecodeError
    return render json: {
      message: "Session expired. Please login again."
    }, status: 401
  end

  user = User.find_by(id: decoded["id"])

  unless user
    return render json: {
      message: "User not found"
    }, status: 404
  end

  render json: {
    user: {
      id: user.id,
      user_id: user.user_id,
      name: user.name,
      department: user.department,
      role: user.role
    }
  }

rescue => error
  Rails.logger.error("ME ERROR: #{error.message}")

  render json: {
    message: "Server error"
  }, status: 500
end

  def login
    user_id = params[:user_id]
    password = params[:password]

    if user_id.blank? || password.blank?
      return render json: {
        message: "Login ID and password are required"
      }, status: 400
    end

    user = User.find_by(user_id: user_id)

    unless user
      return render json: {
        message: "Invalid Login ID or password"
      }, status: 401
    end

    unless BCrypt::Password.new(user.password_hash) == password
      return render json: {
        message: "Invalid Login ID or password"
      }, status: 401
    end

    token = JWT.encode(
      {
        id: user.id,
        user_id: user.user_id,
        name: user.name,
        department: user.department,
        role: user.role,
        exp: 8.hours.from_now.to_i
      },
      ENV["JWT_SECRET"],
      "HS256"
    )

    render json: {
      message: "Login successful",
      token: token,
      user: {
        id: user.id,
        user_id: user.user_id,
        name: user.name,
        department: user.department,
        role: user.role
      }
    }

  rescue => error
    Rails.logger.error("LOGIN ERROR: #{error.message}")

    render json: {
      message: "Server error"
    }, status: 500
  end


  def accept_invitation
    token = params[:token]
    Rails.logger.info("INVITATION TOKEN RECEIVED: #{token}")
    new_password = params[:newPassword]

    if token.blank? || new_password.blank?
      return render json: {
        message: "Invitation token and password are required"
      }, status: 400
    end

    if new_password.length < 6
      return render json: {
        message: "Password must be at least 6 characters"
      }, status: 400
    end

    user = User.find_by(invitation_token: token)

    unless user
      return render json: {
        message: "Invalid or expired invitation link"
      }, status: 400
    end

    if user.password_hash.present?
      return render json: {
        message: "This invitation has already been accepted"
      }, status: 400
    end

    password_hash = BCrypt::Password.create(new_password, cost: 10)

    user.update!(
      password_hash: password_hash.to_s,
      invitation_token: nil
    )

    render json: {
      message: "Invitation accepted and password created successfully"
    }

  rescue => error
    Rails.logger.error("Accept invitation error: #{error.message}")

    render json: {
      message: "Failed to accept invitation"
    }, status: 500
  end


  def reset_password
    auth_header = request.headers["Authorization"]
    token = auth_header.to_s.split(" ")[1]

    if token.blank?
      return render json: {
        message: "Authentication required"
      }, status: 401
    end

    begin
      decoded = JWT.decode(
        token,
        ENV["JWT_SECRET"],
        true,
        algorithm: "HS256"
      ).first
    rescue JWT::ExpiredSignature, JWT::DecodeError
      return render json: {
        message: "Session expired. Please login again."
      }, status: 401
    end

    current_password = params[:currentPassword]
    new_password = params[:newPassword]

    if current_password.blank? || new_password.blank?
      return render json: {
        message: "Current password and new password are required"
      }, status: 400
    end

    if new_password.length < 6
      return render json: {
        message: "New password must be at least 6 characters"
      }, status: 400
    end

    user = User.find_by(id: decoded["id"])

    unless user
      return render json: {
        message: "User not found"
      }, status: 404
    end

    unless BCrypt::Password.new(user.password_hash) == current_password
      return render json: {
        message: "Current password is incorrect"
      }, status: 401
    end

    new_password_hash =
      BCrypt::Password.create(new_password, cost: 10)

    user.update!(
      password_hash: new_password_hash.to_s
    )

    render json: {
      message: "Password changed successfully"
    }

  rescue => error
    Rails.logger.error("Reset password error: #{error.message}")

    render json: {
      message: "Server error"
    }, status: 500
  end

end