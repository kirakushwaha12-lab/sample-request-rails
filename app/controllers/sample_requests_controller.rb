require "jwt"
require "cgi"

class SampleRequestsController < ApplicationController

  # =========================================================
  # CREATE SAMPLE REQUEST
  # =========================================================
  def create
    begin

      puts "INQUIRY DATE RECEIVED FROM FORM: #{params[:inquiryReceivedDate]}"

      request_id = params[:requestId]
      client_code = params[:clientCode]
      inquiry_received_date = params[:inquiryReceivedDate]
      status = params[:status]
      created_by = params[:createdBy]
      articles = params[:articles]

      unless request_id.present?
        return render json: {
          message: "Request ID is required"
        }, status: :bad_request
      end

      connection = ActiveRecord::Base.connection

      request_result = connection.exec_query(
        <<~SQL
          INSERT INTO sample_requests
          (
            request_id,
            client_code,
            inquiry_received_date,
            status,
            created_by
          )
          VALUES
          (
            #{connection.quote(request_id)},
            #{connection.quote(client_code)},
            #{connection.quote(inquiry_received_date)},
            #{connection.quote(status.present? ? status : "SUBMITTED")},
            #{connection.quote(created_by)}
          )
          RETURNING *
        SQL
      )

      sample_request = request_result.first

      if articles.is_a?(Array)

        articles.each do |article|

          leather =
            article["leather"].is_a?(Array) ?
            article["leather"].join(", ") :
            article["leather"]

          lining =
            article["lining"].is_a?(Array) ?
            article["lining"].join(", ") :
            article["lining"]

          hardware =
            article["hardware"].is_a?(Array) ?
            article["hardware"].join(", ") :
            article["hardware"]

          thread =
            article["thread"].is_a?(Array) ?
            article["thread"].join(", ") :
            article["thread"]

          zipper =
            article["zipper"].is_a?(Array) ?
            article["zipper"].join(", ") :
            article["zipper"]

          webbing =
            article["webbing"].is_a?(Array) ?
            article["webbing"].join(", ") :
            article["webbing"]

          branding_images =
            (article["brandingImages"] || []).to_json

          reference_images =
            (article["referenceImages"] || []).to_json

          sample_dispatch_date =
            article["sampleDispatchDate"].present? ?
            article["sampleDispatchDate"] :
            nil
  

          connection.execute(
            <<~SQL
              INSERT INTO sample_request_articles
              (
                sample_request_id,
                article_no,
                article_type,
                leather,
                lining,
                hardware,
                thread,
                fabric_canvas,
                hardware_finish,
                zipper,
                raw_edge_folded_edge,
                edge_color,
                puller_tab,
                webbing,
                branding_images,
                changes,
                sample_dispatch_date,
                reference_images
              )
              VALUES
              (
                #{connection.quote(sample_request["id"])},
                #{connection.quote(article["articleNo"])},
                #{connection.quote(article["articleType"])},
                #{connection.quote(leather)},
                #{connection.quote(lining)},
                #{connection.quote(hardware)},
                #{connection.quote(thread)},
                #{connection.quote(article["fabricCanvas"])},
                #{connection.quote(article["hardwareFinish"])},
                #{connection.quote(zipper)},
                #{connection.quote(article["rawEdgeFoldedEdge"])},
                #{connection.quote(article["edgeColor"])},
                #{connection.quote(article["pullerTab"])},
                #{connection.quote(webbing)},
                #{connection.quote(branding_images)},
                #{connection.quote(article["changes"])},
                #{connection.quote(sample_dispatch_date)},
                #{connection.quote(reference_images)}
              )
            SQL
          )

        end
      end

      article_count =
        articles.is_a?(Array) ? articles.length : 0

      view_link =
        "https://sample-request-rails.sample.blitz.cloud/sample%20requests1.html?view=#{CGI.escape(request_id)}"
      
      login_link =
       "https://sample-request-rails.sample.blitz.cloud/"

      merchant_user = User.find_by(id: created_by)

      merchant_email =
        merchant_user ? merchant_user.email : nil
 
      SampleRequestMailer.new_sample_request(
        request_id,
        client_code,
        inquiry_received_date,
        article_count,
        view_link,
        login_link,
        merchant_email
      ).deliver_now

      render json: {
        message: "Sample request created successfully",
        request: sample_request
      }, status: :created

    rescue => error

      Rails.logger.error "Create sample request error: #{error}"

      render json: {
        message: "Failed to create sample request"
      }, status: :internal_server_error

    end
  end


  # =========================================================
  # GET ALL SAMPLE REQUESTS
  # =========================================================
  def index

    puts "GET ALL SAMPLE REQUESTS HIT"

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

      puts "LOGGED IN USER: #{decoded_user}"

      connection = ActiveRecord::Base.connection

      query = <<~SQL
        SELECT
          sr.id,
          sr.request_id,
          sr.client_code,
          TO_CHAR(
            sr.inquiry_received_date,
            'YYYY-MM-DD'
          ) AS inquiry_received_date,
          sr.status,
          sr.created_by,
          sr.created_at,
          u.user_id,
          u.name,
          u.department
        FROM sample_requests sr
        LEFT JOIN users u
          ON sr.created_by = u.id
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

      Rails.logger.error "Get sample requests JWT error: #{error}"

      render json: {
        message: "Invalid or expired token"
      }, status: :unauthorized

    rescue => error

      Rails.logger.error "Get sample requests error: #{error}"

      render json: {
        message: error.message,
        error: error.to_s
      }, status: :internal_server_error

    end
  end


  # =========================================================
  # GET ONE SAMPLE REQUEST
  # =========================================================
  def show

    begin

      request_id = params[:requestId]

      connection = ActiveRecord::Base.connection

      request_result = connection.exec_query(
        <<~SQL
          SELECT
            sr.id,
            sr.request_id,
            sr.client_code,
            TO_CHAR(
              sr.inquiry_received_date,
              'YYYY-MM-DD'
            ) AS inquiry_received_date,
            sr.status,
            sr.created_by,
            sr.created_at,
            u.user_id,
            u.name,
            u.department
          FROM sample_requests sr
          LEFT JOIN users u
            ON sr.created_by = u.id
          WHERE sr.request_id =
            #{connection.quote(request_id)}
        SQL
      )

      if request_result.rows.empty?
        return render json: {
          message: "Sample request not found"
        }, status: :not_found
      end

      sample_request = request_result.first

      articles_result = connection.exec_query(
        <<~SQL
          SELECT *
          FROM sample_request_articles
          WHERE sample_request_id =
            #{connection.quote(sample_request["id"])}
          ORDER BY id ASC
        SQL
      )

      sample_request["articles"] =
  articles_result.to_a.map do |article|

    if article["branding_images"].present?
      begin
        article["branding_images"] =
          JSON.parse(article["branding_images"])
      rescue
        article["branding_images"] = []
      end
    else
      article["branding_images"] = []
    end

    if article["reference_images"].present?
      begin
        article["reference_images"] =
          JSON.parse(article["reference_images"])
      rescue
        article["reference_images"] = []
      end
    else
      article["reference_images"] = []
    end

    article
  end

      render json: sample_request

    rescue => error

      Rails.logger.error "Get sample request error: #{error}"

      render json: {
        message: "Failed to fetch sample request"
      }, status: :internal_server_error

    end
  end


  # =========================================================
  # UPDATE SAMPLE REQUEST
  # =========================================================
  def update

    puts "🔥 PUT ROUTE HIT: #{params[:requestId]}"

    connection = ActiveRecord::Base.connection

    begin

      request_id = params[:requestId]
      client_code = params[:clientCode]
      inquiry_received_date = params[:inquiryReceivedDate]
      status = params[:status]
      articles = params[:articles]

      sample_request = nil

      connection.transaction do

        request_result = connection.exec_query(
          <<~SQL
            UPDATE sample_requests
            SET
              client_code =
                #{connection.quote(client_code)},
              inquiry_received_date =
                #{connection.quote(inquiry_received_date)},
              status =
                #{connection.quote(status.present? ? status : "UPDATED")}
            WHERE request_id =
              #{connection.quote(request_id)}
            RETURNING *
          SQL
        )

        if request_result.rows.empty?
          raise ActiveRecord::Rollback
        end

        sample_request = request_result.first

        connection.execute(
          <<~SQL
            DELETE FROM sample_request_articles
            WHERE sample_request_id =
              #{connection.quote(sample_request["id"])}
          SQL
        )

        if articles.is_a?(Array)

          articles.each do |article|

            leather =
              article["leather"].is_a?(Array) ?
              article["leather"].join(", ") :
              article["leather"]

            lining =
              article["lining"].is_a?(Array) ?
              article["lining"].join(", ") :
              article["lining"]

            hardware =
              article["hardware"].is_a?(Array) ?
              article["hardware"].join(", ") :
              article["hardware"]

            thread =
              article["thread"].is_a?(Array) ?
              article["thread"].join(", ") :
              article["thread"]

            zipper =
              article["zipper"].is_a?(Array) ?
              article["zipper"].join(", ") :
              article["zipper"]

            webbing =
              article["webbing"].is_a?(Array) ?
              article["webbing"].join(", ") :
              article["webbing"]  

            branding_images =
              (article["brandingImages"] || []).to_json

            reference_images =
              (article["referenceImages"] || []).to_json

            sample_dispatch_date =
              article["sampleDispatchDate"].present? ?
              article["sampleDispatchDate"] :
              nil  

            connection.execute(
              <<~SQL
                INSERT INTO sample_request_articles
                (
                  sample_request_id,
                  article_no,
                  article_type,
                  leather,
                  lining,
                  hardware,
                  thread,
                  fabric_canvas,
                  hardware_finish,
                  zipper,
                  raw_edge_folded_edge,
                  edge_color,
                  puller_tab,
                  webbing,
                  branding_images,
                  changes,
                  sample_dispatch_date,
                  reference_images
                )
                VALUES
                (
                  #{connection.quote(sample_request["id"])},
                  #{connection.quote(article["articleNo"])},
                  #{connection.quote(article["articleType"])},
                  #{connection.quote(leather)},
                  #{connection.quote(lining)},
                  #{connection.quote(hardware)},
                  #{connection.quote(thread)},
                  #{connection.quote(article["fabricCanvas"])},
                  #{connection.quote(article["hardwareFinish"])},
                  #{connection.quote(zipper)},
                  #{connection.quote(article["rawEdgeFoldedEdge"])},
                  #{connection.quote(article["edgeColor"])},
                  #{connection.quote(article["pullerTab"])},
                  #{connection.quote(webbing)},
                  #{connection.quote(branding_images)},
                  #{connection.quote(article["changes"])},
                  #{connection.quote(sample_dispatch_date)},
                  #{connection.quote(reference_images)}
                )
              SQL
            )

          end
        end
      end

      if sample_request.nil?
        return render json: {
          message: "Sample request not found"
        }, status: :not_found
      end

      render json: {
        message: "Sample request updated successfully",
        request: sample_request
      }

    rescue => error

      Rails.logger.error "Update sample request error: #{error}"

      render json: {
        message: error.message,
        error: error.to_s
      }, status: :internal_server_error

    end
  end


  # =========================================================
  # DELETE SAMPLE REQUEST
  # =========================================================
  def destroy

    begin

      request_id = params[:requestId]

      connection = ActiveRecord::Base.connection

      result = connection.exec_query(
        <<~SQL
          DELETE FROM sample_requests
          WHERE request_id =
            #{connection.quote(request_id)}
          RETURNING *
        SQL
      )

      if result.rows.empty?
        return render json: {
          message: "Sample request not found"
        }, status: :not_found
      end

      render json: {
        message: "Sample request deleted successfully"
      }

    rescue => error

      Rails.logger.error "Delete sample request error: #{error}"

      render json: {
        message: "Failed to delete sample request"
      }, status: :internal_server_error

    end
  end

end