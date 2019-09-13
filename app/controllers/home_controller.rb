class HomeController < ApplicationController
  require 'nokogiri'
  require 'open-uri'
  require 'openssl'
  skip_before_action :verify_authenticity_token
  def index
  end

  def show
    extract_info(params[:link][:section])
    # @link = params[:anything][:link]
  end

  private

  def extract_info(link)
    @articles = []
    baseUrl = 'https://www.elnorte.com/'
    doc = Nokogiri::HTML(open(link, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE))
    zona = doc.css('#unodostres div') if doc.css('#unodostres div').present?
    zona = doc.css('#zonaprime div') if doc.css('#zonaprime div').present?
    zona.each do |article|
      if article.css('p a').present? && !article.css('p a')[0].attributes["href"].value.in?(@articles.pluck(:id))
        article_link = baseUrl + article.css('p a')[0].attributes["href"].value
        new_doc = MetaInspector.new(article_link)
        article = {
          id: article.css('p a')[0].attributes["href"].value,
          title: new_doc.title,
          link: article_link,
          description: fetch_description(new_doc),
          image: new_doc.images.best,
          reading_time: fetch_text(new_doc)
        }
        @articles << article
      end
    end
    @articles
  end

  def fetch_description(doc)
    return doc.description unless doc.description.blank?
    return doc.parsed.css('#textoPano').text[0...300] unless doc.parsed.css('#textoPano').blank?
  end

  def fetch_text(doc)
    puts doc.parsed.css('#textoPano')
    return (doc.parsed.css('#textoPano').text.scan(/[\w-]+/).size) / 250 if doc.parsed.css('#textoPano').present?
    return (doc.parsed.css('#contenido_principal').text.scan(/[\w-]+/).size) / 250 if doc.parsed.css('#contenido_principal').present?
  end
end