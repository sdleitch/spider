require 'nokogiri'
require 'open-uri'
require 'net/http'

class Spider
  attr_reader(:domain, :page_limit)
  attr_accessor(:urls, :visited, :pages)

  def initialize(domain, page_limit=100)
    @domain = domain
    @page_limit = page_limit
    @urls = []
    @visited = {}
    @pages = []
  end

  class WebPage
    attr_reader(:title, :head, :body, :url)

    def initialize(title, head, body, url)
      @title = title
      @head = head
      @body = body
      @url = url
    end
  end

  def crawl(regex=nil, url=@domain)
    # Run until you've crawled the page_limit number of pages.
    until @visited.length == @page_limit

      @visited[url] = true
      sleep 1
      puts "Crawling [#{@visited.length}]: #{url}"

      # Rescuse from HTTP Errors, such as 404 and Runtime Errors
      begin
        page = Nokogiri::HTML(open(url))
      rescue OpenURI::HTTPError, RuntimeError => e
        puts "#{e}: #{e.message}"
        puts "--SKIPPING #{url}"
        break
      end

      @pages << WebPage.new(
        page.title,
        page.at_css("head"),
        page.at_css("body"),
        url
      )

      anchors = page.css('a')
      anchors.each do |anchor|
        link = anchor.attr('href')
        unless link == nil
          if link.include?(@domain)
            @urls << link
          elsif link.start_with?("/")
            @urls << @domain + link
          end
        end
      end

      # Recursively crawl next page
      @urls.each do |url|
        if regex
          crawl(regex, url) if (regex =~ url) && (url.include?(@domain) && @visited[url] == nil) 
        else
          crawl(regex, url) if url.include?(@domain) && @visited[url] == nil
        end
      end

    end
  end

end
