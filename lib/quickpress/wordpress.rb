require 'rubypress'
require 'mimemagic'

module Quickpress

  # Represents an instance of a Wordpress connection.
  # Handles direct calls to the Wordpress API.
  #
  class Wordpress

    attr_reader :title      # Blog title.
    attr_reader :tagline    # Blog subtitle.
    attr_reader :url        # Blog address
    attr_reader :categories # All categories on blog

    # Blog's options in a Hash. Need to call `get_options` first.
    attr_reader :options

    # Yes it is
    VERY_LARGE_NUMBER = 2**31 - 1

    # Creates a new connection to `url` with `user`/`pass`.
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

      # Actually connecting, takes a while
      options = @client.getOptions(:options => ["blog_title",
                                                "blog_tagline",
                                                "blog_url"])

      @title   = options["blog_title"]["value"]
      @tagline = options["blog_tagline"]["value"]
      @url     = options["blog_url"]["value"]

      @categories = []
      terms = @client.getTerms(:taxonomy => "category")
      terms.each do |term|
        @categories << term["name"]
      end
    end

    # Sends a post/page to the Wordpress site with `options`.
    #
    # `options` is a Hash with the following fields:
    #
    # * :post_date    => Ruby Time Object (or `[]` for Time.now)
    # * :post_title   => String
    # * :post_content => String
    # * :post_status  => 'publish'/'draft'/'private'
    # * :post_type    => 'post'(default) / 'page'
    #
    # To Wordpress, Posts and Pages are the same thing.
    # The only thing that makes them different is the
    # option `:post_type`.
    #
    def new_post options
      # Sending post
      id = @client.newPost(:content => options)

      # Getting link for it
      info = @client.getPost(:post_id => id,
                             :fields  => [:link])
      link = info["link"]

      return id, link
    end

    # Edits post/page on the Wordpress site with `options`.
    #
    # Format is the same as Wordpress#new_post.
    # Check it out.
    #
    def edit_post options

      @client.editPost(options)
      info = @client.getPost(:post_id => options[:post_id],
                             :fields  => [:link])

      info["link"]
    end

    # Returns post with numerical `id`.
    # It's a Hash with attributes/values.
    #
    def get_post id
      @client.getPost(:post_id => id)
    end

    # Returns `ammount` posts.
    # If `ammount` is zero, will return all posts.
    # FIXME when getting by `ammount` it is ordered by the opposite
    def get_posts(ammount=0)
      ammount = VERY_LARGE_NUMBER if ammount.zero?

      @client.getPosts(:filter => { :number => ammount })
    end

    # Returns page with numerical `id`.
    # It's a Hash with attributes/values.
    #
    def get_page id
      @client.getPost(:post_id => id,
                      :filter => {
                        :post_type => 'page'
                      })
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

    # Deletes post with numerical `id`.
    def delete_post id
      @client.delnetePost(:post_id => id)
    end

    # Deletes page with numerical `id`.
    def delete_page id
      @client.deletePost(:post_id => id,
                         :filter => {
                           :post_type => 'page'
                         })
    end

    # Retrieves as much metadata about the blog as it can.
    #
    # Returns an array of 3-element arrays:
    #
    # 1. Wordpress' internal option name.
    #    You must use it to set options. See `set_options`.
    # 2. Human-readable description of the option.
    # 3. Current value.
    #
    # The values are detailed here:
    # http://codex.wordpress.org/Option_Reference
    #
    def get_options
      options = @client.getOptions

      options.map { |o| [o[0], o[1]["desc"], o[1]["value"]] }
    end

    # Sets the blog's options according to `new_options`
    # hash.
    # It points to an array with two elements:
    #
    # 1. Wordpress' internal option name.
    #    See `get_options`.
    # 2. It's new value.
    #    See link on `get_options` for possible values.
    #
    # Returns the new options, the same way as `get_options`.
    #
    def set_options new_options
      options = @client.setOptions

      options.map { |o| [o[0], o[1]["desc"], o[1]["value"]] }

    end

    # Returns all users currently registered on the blog.
    #
    # It's an Array of two-element Arrays:
    #
    # 1. Wordpress' internal info name
    # 2. It's value
    def get_users
      users = @client.getUsers

      # Replacing XML-RPC's ugly DateTime class
      # with Ruby's Time
      users.each do |u|
        u["registered"] = u["registered"].to_time
      end

      users.map { |u| u.to_a }
    end

    # Returns comment counts according to their status.
    # It's an Array of two elements:
    #
    # 1. Wordpress' internal status name
    # 2. Comment counts on that status
    #
    def get_comment_status
      status = @client.getCommentCount

      status.to_a
    end

    # Returns categories and how many posts they have.
    # It's an Array of two elements:
    #
    # 1. Category name
    # 2. Post count
    #
    def get_category_status
      status = @client.getTerms(:taxonomy => 'category')

      status.map { |s| [s["name"], s["count"]] } # all we need
    end

    # Uploads `filename` to Wordpress, returning
    # it's ID, URL and unique filename inside Wordpress.
    #
    def new_media filename

      content = XMLRPC::Base64.new(File.read(filename))
      if content.encoded.empty?
        fail "File '#{filename}' is empty"
      end

      mime = MimeMagic.by_path filename
      if mime.nil?
        fail "Unknown MIME type for '#{filename}'"
      end

      file = @client.uploadFile(:data => {
                                  :name => File.basename(filename),
                                  :bits => content,
                                  :type => mime.type
                                })

      return file['id'], file['url'], file['file']
    end

    # Returns all media items on the blog
    def get_all_media
      lib = @client.getMediaLibrary
      return [] if lib.empty?

      # Getting only the fields we're interested on
      lib.map do |m|
        [m["attachment_id"], m["title"], m["link"]]
      end
    end

    def get_media id
      @client.getMediaItem(:attachment_id => id)
    end

  end
end

