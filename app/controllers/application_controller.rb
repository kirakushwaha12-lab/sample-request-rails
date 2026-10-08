class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  private

  def current_user
    auth_header = request.headers["Authorization"]
    token = auth_header.to_s.split(" ")[1]

    return nil if token.blank?

    begin
      decoded = JWT.decode(
        token,
        ENV["JWT_SECRET"],
        true,
        algorithm: "HS256"
      ).first

      User.find_by(id: decoded["id"])

    rescue JWT::ExpiredSignature, JWT::DecodeError
      nil
    end
  end
end