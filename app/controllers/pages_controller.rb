class PagesController < ApplicationController

  def login
    render file: Rails.root.join("..", "Frontend", "login1.html").to_s, layout: false
  end
  def dashboard
    render file: Rails.root.join("..", "Frontend", "dashboard1.html").to_s, layout: false
  end
  def profile
    render file: Rails.root.join("..", "Frontend", "profile1.html").to_s, layout: false
  end
  def sample_request
    render file: Rails.root.join("..", "Frontend", "sample request2.html").to_s, layout: false
  end
  def sample_requests
    render file: Rails.root.join("..", "Frontend", "sample requests1.html").to_s, layout: false
  end
  def sample_request_sheet
    render file: Rails.root.join("..", "Frontend", "sample request sheet2.html").to_s, layout: false
  end
  def client_article_dropdown
    js_file = Rails.root.join("..", "Frontend", "client-article-dropdown.js")
    
    response.headers["Content-Type"] = "application/javascript"
    render text: File.read(js_file)
  end
  def accept_invitation
    render file: Rails.root.join("..", "Frontend", "accept-invitation.html").to_s,
           layout: false
  end

  

  def tracker
    render file: Rails.root.join("..", "Frontend", "tracker.html").to_s,
         layout: false
  end
 
end