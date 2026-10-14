require "net/http"
require "uri"
require "json"

class ResendDeliveryMethod
  def initialize(settings = {})
    @api_key = ENV["RESEND_API_KEY"]
  end

  def deliver!(mail)
    raise "RESEND_API_KEY is missing" if @api_key.to_s.empty?

    payload = {
      from: Array(mail.from).join(", "),
      to: Array(mail.to),
      subject: mail.subject
    }

    payload[:cc] = Array(mail.cc) if mail.cc && !mail.cc.empty?

    if mail.multipart?
      payload[:html] = mail.html_part.body.decoded if mail.html_part
      payload[:text] = mail.text_part.body.decoded if mail.text_part
    elsif mail.content_type.to_s.include?("text/html")
      payload[:html] = mail.body.decoded
    else
      payload[:text] = mail.body.decoded
    end

    uri = URI("https://api.resend.com/emails")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(payload)

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true,
      open_timeout: 10,
      read_timeout: 20
    ) { |http| http.request(request) }

    unless response.is_a?(Net::HTTPSuccess)
      raise "Resend API error: HTTP #{response.code} - #{response.body}"
    end

    response
  end
end

ActionMailer::Base.add_delivery_method(
  :resend_api,
  ResendDeliveryMethod
)