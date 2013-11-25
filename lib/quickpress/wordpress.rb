
require 'rubypress'

module Quickpress

  # Handles calls to the Wordpress API
  class Wordpress
    attr_reader :title, :tagline, :url, :categories

    def initialize(url, user, pass)

      # Sanitizing url:
      # If provided with something like "mysite.com/blog"
      # * host must be "mysite.com"
      # * path must be "/blog/xmlrpc.php"
      #
      host  = url
      path  = "/xmlrpc.php"
      paths = url.split '/'

      if paths.size > 1
        host = paths[0]

        path = '/' + paths[1..-1].join('/') + "/xmlrpc.php"
      end

      @client = Rubypress::Client.new(:host => host,
                                      :path => path,
                                      :username => user,
                                      :password => pass)

      # Actually connecting
      options = @client.getOptions

      @title   = options["blog_title"]["value"]
      @tagline = options["blog_tagline"]["value"]
      @url     = options["blog_url"]["value"]

      @categories = []
      terms = @client.getTerms(:taxonomy => 'category')
      terms.each do |term|
        @categories << term["name"]
      end

    end

    # Posts something on the site.
    #
    # Options allowed:
    # * title
    # * keywords
    # * categories
    # * description
    # * created_at
    # * id
    # * user_id
    # * published
    #
    def post options
      id = @client.newPost options

      link = @client.getPost(:post_id => id, :fields => [:link])["link"]
      return id, link
    end

    def post_edit(id, config)
      post = @client.posts.find id
    end

  end
end

