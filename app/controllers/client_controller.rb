class ClientController < ApplicationController

  def my_clients
  begin
    puts "FULL AUTH USER: #{current_user.inspect}"

    if ["sampler", "admin", "super_admin"].include?(current_user.role.to_s.downcase)
      puts "#{current_user.role.upcase} USER - LOADING ALL ACTIVE CLIENTS"

      clients = Client
        .where(is_active: true)
        .select(
          "clients.id,
           clients.client_code,
           clients.is_active"
        )
        .order(client_code: :asc)

    else
      merchant_id = current_user.id

      puts "MERCHANT USER - MAPPED CLIENTS REQUEST BY USER ID: #{merchant_id}"

      clients = Client
        .joins("INNER JOIN merchant_clients mc ON mc.client_id = clients.id")
        .where(
          "mc.merchant_id = ? AND clients.is_active = ?",
          merchant_id,
          true
        )
        .select(
          "clients.id,
           clients.client_code,
           clients.is_active"
        )
        .order(client_code: :asc)
    end

    render json: {
      success: true,
      clients: clients
    }

  rescue => error
    Rails.logger.error("MY CLIENTS ERROR: #{error.message}")

    render json: {
      success: false,
      message: "Failed to load mapped clients"
    }, status: 500
  end
end


  def test_mapped_clients
    begin
      mappings = MerchantClient
        .joins("INNER JOIN users u ON u.id = merchant_clients.merchant_id")
        .joins("INNER JOIN clients c ON c.id = merchant_clients.client_id")
        .select(
          "u.user_id AS merchant_id,
           c.client_code"
        )
        .order("u.user_id ASC, c.client_code ASC")

      render json: {
        success: true,
        mappings: mappings
      }

    rescue => error
      Rails.logger.error("TEST MAPPING ERROR: #{error.message}")

      render json: {
        success: false,
        message: "Failed to load mappings"
      }, status: 500
    end
  end


 def my_articles
  begin
    puts "FULL AUTH USER FOR ARTICLES: #{current_user.inspect}"

    if ["sampler", "admin", "super_admin"].include?(current_user.role.to_s.downcase)
      puts "#{current_user.role.upcase} USER - LOADING ALL ACTIVE CLIENT ARTICLES"

      articles = Article
        .joins("INNER JOIN clients c ON c.id = articles.client_id")
        .where("c.is_active = ?", true)
        .select(
          "c.id AS client_id,
           c.client_code,

           articles.id AS article_id,
           articles.article_no,

           articles.leather,
           articles.lining,
           articles.hardware,
           articles.thread,
           articles.fabric_canvas,
           articles.hardware_finish,
           articles.zipper,
           articles.raw_edge_folded_edge,
           articles.edge_color,
           articles.puller_tab,
           articles.webbing,
           articles.branding_images,
           articles.reference_images"
        )
        .order(
          "c.client_code ASC,
           articles.article_no ASC"
        )

    else
      merchant_id = current_user.id

      puts "MERCHANT USER - MY ARTICLES REQUEST BY USER ID: #{merchant_id}"

      articles = Article
        .joins("INNER JOIN clients c ON c.id = articles.client_id")
        .joins(
          "INNER JOIN merchant_clients mc ON mc.client_id = c.id"
        )
        .where(
          "mc.merchant_id = ? AND c.is_active = ?",
          merchant_id,
          true
        )
        .select(
          "c.id AS client_id,
           c.client_code,

           articles.id AS article_id,
           articles.article_no,

           articles.leather,
           articles.lining,
           articles.hardware,
           articles.thread,
           articles.fabric_canvas,
           articles.hardware_finish,
           articles.zipper,
           articles.raw_edge_folded_edge,
           articles.edge_color,
           articles.puller_tab,
           articles.webbing,
           articles.branding_images,
           articles.reference_images"
        )
        .order(
          "c.client_code ASC,
           articles.article_no ASC"
        )
    end

    puts "MY ARTICLES ROWS FOUND: #{articles.length}"

    render json: {
      success: true,
      articles: articles
    }

  rescue => error
    Rails.logger.error("MY ARTICLES ERROR: #{error.message}")

    render json: {
      success: false,
      message: "Failed to load clients and articles"
    }, status: 500
  end
  end
end