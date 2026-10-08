class SampleRequestMailer < ApplicationMailer
  def new_sample_request(
    request_id,
    client_code,
    inquiry_received_date,
    article_count,
    view_link,
    login_link,
    merchant_email
  )
    @request_id = request_id
    @client_code = client_code
    @inquiry_received_date = inquiry_received_date
    @article_count = article_count
    @view_link = view_link
    @login_link = login_link
    @merchant_email = merchant_email


    
    mail(
      to: ENV["SAMPLE_DEPARTMENT_EMAIL"],
      cc: @merchant_email,
      subject: "New Sample Request - #{request_id}"
    )
  end
end