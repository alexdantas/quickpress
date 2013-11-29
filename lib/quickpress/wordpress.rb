require 'rubypress'

module Quickpress

  VERY_LARGE_NUMBER = 2**31 - 1

  # Handles calls to the Wordpress API
  #
  class Wordpress
    # Blog title.
    attr_reader :title

    # Blog subtitle.
    attr_reader :tagline

    # Blog address
    attr_reader :url

    # All categories on blog
    attr_reader :categories

    def initialize(url, user, pass)

      # Sanitizing url:
      #
      # If provided with something like "mysite.com/blog"
      # * host will be "mysite.com"
      # * path will be "/blog/xmlrpc.php"

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
      id   = @client.newPost(:content => options)
      link = @client.getPost(:post_id => id, :fields => [:link])["link"]
      return id, link
    end

    def get_post id
      @client.getPost(:post_id => id)
    end

    def get_page id
      @client.getPost(:post_id => id,
                      :filter => {
                        :post_type => 'page'
                      })
    end

    # Returns `ammount` posts.
    # If `ammount` is zero, will return all posts.
    # FIXME when getting by `ammount` it is ordered by the opposite
    def get_posts(ammount=0)
      ammount = VERY_LARGE_NUMBER if ammount.zero?

      @client.getPosts(:filter => { :number => ammount })
    end

    # Returns `ammount` pages.
    # If `ammount` is zero, will return all posts.
    # FIXME when getting by `ammount` it is ordered by the opposite
    def get_pages(ammount=0)
      ammount = VERY_LARGE_NUMBER if ammount.zero?

      @client.getPosts(:filter => {
                         :number => ammount,
                         :post_type => 'page'
                       })
    end

    def delete_post id
      @client.deletePost(:post_id => id)
    end

    def delete_page id
      @client.deletePost(:post_id => id,
                         :filter => {
                           :post_type => 'page'
                         })
    end

    # def post_edit(id, config)
    #   post = @client.posts.find id
    # end

  end
end

