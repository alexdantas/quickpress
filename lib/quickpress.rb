require 'fileutils'
require 'yaml'
require 'open-uri'
require 'tilt'
require 'quickpress/version'
require 'quickpress/wordpress'
require 'quickpress/cli'
require 'quickpress/options'

# Controls all operations we can make.
#
# This module's a mess.
#
# The code sucks, things are not splitted well...
# There should be delegation up the ass but I couldn't stop
# coding.
#
# Gotta study ruby guidelines and see other librarys' codes
# to see where I can improve.
#
module Quickpress

  # Main directory where we store everything.
  ROOT_DIR    = File.expand_path "~/.config/quickpress"

  POST_DIR    = "#{ROOT_DIR}/posts"
  DRAFT_DIR   = "#{ROOT_DIR}/drafts"
  CONFIG_FILE = "#{ROOT_DIR}/config.yml"

  @@inited = nil

  # URL of the default site used to post.
  @@default_site = nil

  # Nice name of the default site.
  @@default_sitename = nil

  @@username   = nil
  @@password   = nil
  @@connection = nil

  module_function

  # Loads default site from configuration file
  def config_init
    CLI::with_status("Initializing...") do

      # Assuring default directories
      [ROOT_DIR, POST_DIR, DRAFT_DIR].each do |dir|
        FileUtils.mkdir dir if not File.exists? dir
      end

      # Reading config file if exists
      if File.exists? CONFIG_FILE
        raw = File.read CONFIG_FILE
        settings = YAML.load raw
        settings = {} if not settings

        @@default_site = settings["default_site"]
        @@default_sitename =
          @@default_site.gsub(/htt(p|ps):\/\//, "").gsub(/\//, '-')
      end

      @@inited = true
    end
  end

  # Executes at the first time, when there's no configuration
  # directories.
  #
  # Asks stuff.
  #
  def first_time
    puts <<-END.gsub(/^ +/, "")
      Hello!
      It looks like this is the first time you're running quickpress.
      Let's connect to your Wordpress(.com/.org) site.
    END

    # If retrying, go back here.
    begin
      puts
      address = CLI::get "Address:"

      @@username   = CLI::get("Username:")
      @@password   = CLI::get_secret("Password:")
      @@connection = Wordpress.new(address, @@username, @@password)

      puts <<-END.gsub(/^ +/, "")

        Title:   #{@@connection.title}
        Tagline: #{@@connection.tagline}
        Url:     #{@@connection.url}
      END

      answer = CLI::ask "Is that right?"
      fail "will retry" if not answer

      @@default_site = address

      # For a @@default_site like "http://myblog.com/this/dir"
      #
      # The @@default_sitename must be "myblog.com-this-dir"
      @@default_sitename =
        address.gsub(/htt(p|ps):\/\//, "").gsub(/\//, '-')

      FileUtils.mkdir_p "#{DRAFT_DIR}/#{@@default_sitename}"
      FileUtils.mkdir_p "#{POST_DIR}/#{@@default_sitename}"

      # Saving to config file, taking care not
      # to overwrite already-existing settings.

      settings = {}

      if File.exists? CONFIG_FILE
        raw = File.read CONFIG_FILE

        settings.merge(YAML.load(raw))
      end

      settings["sites"] ||= []
      settings["sites"] << @@default_site

      settings["default_site"] = @@default_site

      File.write(CONFIG_FILE, YAML.dump(settings))

    rescue StandardError => e
      retry if e.message =~ /will retry/

      raise e
    end
  end

  # Entrance for when we're creating a page or a post
  # (`what` says so).
  #
  def new(what, filename=nil)
    startup

    if filename.nil?
      # Get editor to open temporary file
      editor = ENV["EDITOR"]
      if editor.nil?
        editor = get("Which text editor we'll use?")
      end

      extension = ""
      case $options[:markup]
      when "markdown"     then extension = '.md'
      when "asciidoc"     then extension = '.adoc'
      when "erb"          then extension = '.erb'
      when "string"       then extension = '.str'
      when "erubis"       then extension = '.erubis'
      when "haml"         then extension = '.haml'
      when "sass"         then extension = '.sass'
      when "scss"         then extension = '.scss'
      when "less"         then extension = '.less'
      when "builder"      then extension = '.builder'
      when "liquid"       then extension = '.liquid'
      when "markdown"     then extension = '.md'
      when "textile"      then extension = '.textile'
      when "rdoc"         then extension = '.rdoc'
      when "radius"       then extension = '.radius'
      when "markaby"      then extension = '.mab'
      when "nokogiri"     then extension = '.nokogiri'
      when "coffeescript" then extension = '.coffee'
      when "creole"       then extension = '.creole'
      when "mediawiki"    then extension = 'mw'
      when "yajl"         then extension = '.yajl'
      when "csv"          then extension = '.rcsv'
      else fail "Unknown markup laguage '#{$options[:markup]}'"
      end

      # Create sample file
      template = Time.now.strftime "%Y-%m-%d[%H:%M]#{extension}"

      # as in 'page-xxx' or 'post-xxx'
      template = "#{what}-#{template}"

      draft = "#{DRAFT_DIR}/#{@@default_sitename}/#{template}"
      final = "#{POST_DIR}/#{@@default_sitename}/#{template}"

      # Oh yeah, baby
      `#{editor} #{draft}`

      new_file(what, draft)

      FileUtils.mv(draft, final)

    else
      # Post file and copy it to posted directory.
      new_file(what, filename)

      time  = Time.now.strftime "%Y-%m-%d[%H:%M]"
      final = "#{POST_DIR}/#{@@default_sitename}/#{time}-#{File.basename(filename)}"

      FileUtils.cp(filename, final)
    end
  end

  # Actually sends post/page `filename` to the blog.
  def new_file(what, filename)

    html = Tilt.new(filename).render

    title = CLI::get "Title:"

    if what == :post
      puts <<-END.gsub(/^ +/, "")
      Existing blog categories:
      #{@@connection.categories.each { |c| puts "* #{c}" }}
      Use a comma-separated list (example: 'cat1, cat2, cat3')
      Will create non-existing categories automatically.

    END
      categories = CLI::tab_complete("Post categories:", @@connection.categories)

      cats = []
      categories.split(',').each { |c| cats << c.lstrip.strip }

      print "Posting..."
      id, link = @@connection.post(:post_status  => 'publish',
                                   :post_date    => Time.now,
                                   :post_title   => title,
                                   :post_content => html,
                                   :terms_names  => {
                                     :category => cats
                                   })
      CLI::clear_line
      puts "Post successful!"

    elsif what == :page
      print "Creating page..."
      id, link = @@connection.post(:post_status  => 'publish',
                                   :post_date    => Time.now,
                                   :post_title   => title,
                                   :post_content => html,
                                   :post_type    => 'page')
      CLI::clear_line
      puts "Page created!"
    end

    puts <<-END.gsub(/^ +/, "")
      id:   #{id}
      link: #{link}
    END

  rescue => e
    $stderr.puts e.message
    exit 2
  end

  # Deletes comma-separated list of posts/pages with `ids`.
  # A single number is ok too.
  def delete(what, ids)
    startup

    ids.split(',').each do |id|

      print "Hold on a sec..."
      thing = nil
      if what == :post
        thing = @@connection.get_post id.to_i
      elsif what == :page
        thing = @@connection.get_page id.to_i
      end

      CLI::clear_line

      if what == :post
        puts "Will delete the following post:"
      elsif what == :page
        puts "Will delete the following page:"
      end

      puts <<-END.gsub(/^ +/, "")

        ID:      #{thing["post_id"]}
        Title:   #{thing["post_title"]}
        Date:    #{thing["post_date"].to_time}
        Status:  #{thing["post_status"]}
        URL:     #{thing["link"]}

      END

      if not $options[:force]
        answer = CLI::ask("Is that right?")
        if not answer
          puts "Alright, then!"
          next
        end
      end

      CLI::with_status("Deleting...") do
        if what == :post
          @@connection.delete_post id.to_i
        elsif what == :page
          @@connection.delete_page id.to_i
        end
      end
    end
  end

  # Show last `ammount` of posts/pages in reverse order of
  # publication.
  #
  def list(what, ammount)
    startup

    elements = nil
    if what == :post
      CLI::with_status("Retrieving posts...") do
        elements = @@connection.get_posts ammount
      end
    elsif what == :page
      CLI::with_status("Retrieving pages...") do
        elements = @@connection.get_pages ammount
      end
    end

    # Ugly as fuark :(
    puts "+-----+---------------------------------------+-----------------------+--------+"
    puts "|   ID|Title                                  |Date                   |Status  |"
    puts "+-----+---------------------------------------+-----------------------+--------+"
    elements.each do |post|
      puts sprintf("|%5d|%-39s|%s|%-8s|", post["post_id"].to_i,
                   post["post_title"],
                   post["post_date"].to_time,
                   post["post_status"])
    end
    puts "+-----+---------------------------------------+-----------------------+--------+"
  end

  private
  module_function

  # Initializes everything based on the config file or
  # simply by asking the user.
  def startup
    first_time if @@default_site.nil?

    puts "Using '#{@@default_site}'"

    @@username ||= CLI::get("Username:")
    @@password ||= CLI::get_secret("Password:")

    CLI::with_status("Connecting...") do
      @@connection ||= Wordpress.new(@@default_site, @@username, @@password)
    end
  end

end

