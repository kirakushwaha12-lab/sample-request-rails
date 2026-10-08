module AuthenticateToken
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_token
  end

  private

  def authenticate_token
    begin
      auth_header = request.headers["Authorization"]

      unless auth_header.present? && auth_header.start_with?("Bearer ")
        return render json: {
          message: "Authentication required"
        }, status: 401
      end

      token = auth_header.split(" ")[1]

      decoded = JWT.decode(
        token,
        ENV["JWT_SECRET"],
        true,
        algorithm: "HS256"
      ).first

      @current_user = decoded

    rescue => error
      Rails.logger.error("AUTH MIDDLEWARE ERROR: #{error.message}")

      return render json: {
        message: "Invalid or expired token"
      }, status: 401
    end
  end

  def current_user
    @current_user
  end
end