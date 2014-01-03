require 'fileutils'
require 'yaml'
require 'open-uri'
require 'tilt'
require 'quickpress/version'
require 'quickpress/wordpress'
require 'quickpress/cli'
require 'quickpress/options'
require 'digest/md5'
require 'net/http'

class String
  # Removes starting whitespace.
  def remove_starting
    dup.remove_starting!
  end

  # Removes starting whitespace (destructive).
  def remove_starting!
    self.gsub(/^ +/, "")
  end
end

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
  CONFIG_FILE = "#{ROOT_DIR}/config.yml"

  @@inited = nil     # config
  @@started = false  # overall
  @@ran_first_time = false

  # URL of the default site used to post.
  @@default_site = nil

  # Nice name of the default site.
  @@default_sitename = nil

  @@username   = nil
  @@password   = nil

  # Actual Wordpress connection Object
  @@wp = nil

  # Supported templating languages and their file extensions.
  @@supported_markup = [["markdown"     , '.md'],
                        ["asciidoc"     , '.adoc'],
                        ["erb"          , '.erb'],
                        ["string"       , '.str'],
                        ["erubis"       , '.erubis'],
                        ["haml"         , '.haml'],
                        ["sass"         , '.sass'],
                        ["scss"         , '.scss'],
                        ["less"         , '.less'],
                        ["builder"      , '.builder'],
                        ["liquid"       , '.liquid'],
                        ["markdown"     , '.md'],
                        ["textile"      , '.textile'],
                        ["rdoc"         , '.rdoc'],
                        ["radius"       , '.radius'],
                        ["markaby"      , '.mab'],
                        ["nokogiri"     , '.nokogiri'],
                        ["coffeescript" , '.coffee'],
                        ["creole"       , '.creole'],
                        ["mediawiki"    , '.mw'],
                        ["yajl"         , '.yajl'],
                        ["csv"          , '.rcsv']]

  module_function

  # Loads default site from configuration file
  def config_init

    # Reading config file if exists
    if File.exists? CONFIG_FILE
      CLI::with_status("Initializing...") do

        raw = File.read CONFIG_FILE
        settings = YAML.load raw
        settings = {} if not settings

        @@default_site = settings["default_site"]
        @@default_sitename = @@default_site.gsub(/htt(p|ps):\/\//, "").gsub(/\//, '-')
      end
      @@inited = true
    end

    FileUtils.mkdir_p ROOT_DIR if not File.exists? ROOT_DIR
  end

  # Executes at the first time, when there's no configuration
  # directories.
  #
  # Asks stuff.
  #
  def first_time
    puts <<-END.remove_starting!
      Hello!
      It looks like this is the first time you're
      running quickpress.

      Let's connect to your Wordpress(.com/.org) site.
    END
    puts

    Quickpress::new_site(nil)
    @@ran_first_time = true
  end

  # Adds site with URL `addr` to quickpress.
  # If it's `nil`, will prompt the user for it.
  def new_site(addr=nil)
    return if @@ran_first_time
    address = nil

    # If retrying, go back here.
    begin
      address = addr.dup if not addr.nil? # cannot .dup NilClass
      address ||= CLI::get("Address:")

      address.gsub!(/http:\/\//, "")
      address.gsub!(/www\./, "")
      address.gsub!(/\/$/, "")

      # Checking if site already exists
      if File.exists? CONFIG_FILE
        raw = File.read CONFIG_FILE

        settings = {}
        settings.merge!(YAML.load(raw))

        settings["sites"].each do |s|
          if address == s
            puts
            puts "There's already a site with address '#{address}'"
            puts "Check it with `qp list-sites`."

            if @@default_site == s
              puts
              puts "It's your default site, by the way"
            end
            exit 666
          end
        end
      end

      Quickpress::authenticate

      # Will try to connect here.
      # Might take a while.
      CLI::with_status("Connecting...") do
        @@wp = Wordpress.new(address, @@username, @@password)
      end

      puts <<-END.remove_starting!

        Title:    #{@@wp.title}
        Tagline:  #{@@wp.tagline}
        Url:      #{@@wp.url}
      END

      answer = CLI::ask "Is that right?"
      fail "will retry" if not answer

      # Last site added becomes the default
      @@default_site = address

      # Hey, this is our first site!
      if not File.exists? CONFIG_FILE

        # For a @@default_site like "http://myblog.com/this/dir"
        #
        # The @@default_sitename must be "myblog.com-this-dir"
        @@default_sitename = address.gsub(/htt(p|ps):\/\//, "").gsub(/\//, '-')

        # Saving to config file
        settings = {}

        settings["sites"] ||= []
        settings["sites"] << @@default_site

        settings["default_site"] = @@default_site

        File.write(CONFIG_FILE, YAML.dump(settings))

      # Config file exists
      else

        raw = File.read CONFIG_FILE

        settings = {}
        settings.merge!(YAML.load(raw))

        settings["sites"] ||= []
        settings["sites"] << @@default_site

        settings["default_site"] = @@default_site

        File.write(CONFIG_FILE, YAML.dump(settings))
      end
      puts "Site added"

    rescue StandardError => e
      retry if e.message =~ /will retry/

      raise e
    end
  end

  # Shows all saved sites.
  def list_sites

    # Hey, this is our first site!
    if not File.exists? CONFIG_FILE
      puts "No sites stored yet!"
      puts
      puts "Run `qp new-site` to create your first!"

    else
      raw = File.read CONFIG_FILE

      settings = {}
      settings.merge!(YAML.load(raw))

      puts "Sites currently managed by quickpress:"
      puts

      settings["sites"].each_with_index do |site, i|

        if @@default_site == site
          puts (" %3d. %s <== default site" % [i, site])
        else
          puts (" %3d. %s" % [i, site])
        end
      end
    end

  end

  def forget_site ids

    # Hey, there's no sites added yet!
    if not File.exists? CONFIG_FILE
      puts "No sites managed with quickpress yet!"
      puts "Add them with `qp new-site`"
      exit 666
    end

    # Getting all sites from config file
    raw = File.read CONFIG_FILE

    settings = {}
    settings.merge!(YAML.load(raw))

    max_id = settings["sites"].size - 1
    ids_to_delete = []

    # Here we go!
    ids.split(',').each do |id|

      if not (0..max_id).include? id.to_i
        puts "Invalid id!"
        puts "Must be between 0 and #{max_id}."
        next
      end

      puts "Will delete the following site:"
      puts
      puts settings["sites"][id.to_i]

      if not $options[:force]
        answer = CLI::ask("Is that right?")
        if not answer
          puts "Alright, then!"
          next
        end
      end

      ids_to_delete << id.to_i
    end

    # Forgetting a lot of sites at once
    # Note: Is there a better way to do this?
    #       Once I delete an id, all the others change!
    #       I can't simply `each do delete` them.

    ids_to_delete.each {|i| settings["sites"][i] = "will_delete" }

    settings["sites"].reject! { |s| s == "will_delete" }

    # Just in case we've just deleted the default site,
    # let's grab the first one left
    if not settings["sites"].include? @@default_site
      if not settings["sites"].empty?
        settings["default_site"] = settings["sites"].first
      end
    end

    File.write(CONFIG_FILE, YAML.dump(settings))
    puts "Forgotten"

    # Ooh, boy
    # We've just ran out of sites! Better delete that config file!
    if settings["sites"].empty?
      FileUtils.rm_f CONFIG_FILE
    end
  end

  def use_site id
    Quickpress::first_time if @@default_site.nil?
    return if @@ran_first_time

    # Hey, there's no sites added yet!
    if not File.exists? CONFIG_FILE
      puts "No sites managed with quickpress yet!"
      puts ""
      exit 666
    end

    # Getting all sites from config file
    raw = File.read CONFIG_FILE

    settings = {}
    settings.merge!(YAML.load(raw))

    max_id = settings["sites"].size - 1

    if not (0..max_id).include? id.to_i
      puts "Invalid id!"
      puts "Must be between 0 and #{max_id}."
      exit 666
    end

    site = settings["sites"][id]

    puts "Default site: #{site}"
    settings["default_site"] = site
    File.write(CONFIG_FILE, YAML.dump(settings))
  end

  # Entrance for when we're creating a page or a post
  # (`what` says so).
  #
  def new(what, filename=nil)
    if filename.nil?

      # Get editor to open temporary file
      editor = ENV["EDITOR"]
      if editor.nil?
        editor = get("Which text editor we'll use?")
      end

      extension = nil

      # No markup passed as argument
      if $options[:markup].nil?
        puts "Choose your templating language."
        puts

        @@supported_markup.each_with_index do |m, i|
          puts (" %2d. %s (%s)" % [i, m[0], m[1]])
        end
        puts

        id = CLI::get("Which one?").to_i

        max_id = @@supported_markup.size - 1

        if not (0..max_id).include? id
          puts "Invalid id!"
          puts "Must be between 0 and #{max_id}."
          exit 666
        end

        extension = @@supported_markup[id][1]

      # User specified filename to post
      else
        markup_id = nil
        @@supported_markup.each_with_index do |m, i|

          if m[0].casecmp($options[:markup]).zero?
            markup_id = i
            break
          end
        end

        if markup_id.nil?
          fail "Unknown markup laguage '#{$options[:markup]}'"
        end

        extension = @@supported_markup[markup_id][1]
      end

      # Create draft file
      tempfile = Tempfile.new ['quickpress', extension]
      tempfile.write "# Leave this file empty to cancel"
      tempfile.flush

      # Oh yeah, baby
      `#{editor} #{tempfile.path}`

      if tempfile.size.zero?
        puts "Empty file: did nothing"
        tempfile.close
        exit 666
      end

      puts "File: '#{tempfile.path}'" if $options[:debug]

      new_file(what, tempfile.path)
      tempfile.close

    else
      # Post file and copy it to posted directory.
      new_file(what, filename)
    end
  end

  # Pretty-prints categories list.
  def list_categories
    Quickpress::startup

    # Will show categories in columns of n
    columns = 5
    table = @@wp.categories.each_slice(columns).to_a

    puts
    Thor::Shell::Basic.new.print_table table
  end

  # Pretty-prints all options of the Wordpress site.
  def list_options
    Quickpress::startup
    options = @@wp.get_options

    puts
    Thor::Shell::Basic.new.print_table options
  end

  # Pretty-prints all users currently registered on the site.
  def list_users
    Quickpress::startup
    users = @@wp.get_users

    users.each do |user|
      puts
      Thor::Shell::Basic.new.print_table user
    end
  end

  # Actually sends post/page `filename` to the blog.
  def new_file(what, filename)
    Quickpress::startup
    html = Tilt.new(filename).render

    # If successful, will store page id and link
    id, link = nil, nil

    title = $options[:title]
    if title.nil?
      title = CLI::get "Title:"
    end

    date = Quickpress::date $options[:date]
    status = Quickpress::status $options[:status]

    if what == :post

      categories = $options[:category]
      if categories.nil?
        puts "Existing blog categories:"
        Quickpress::list_categories
        puts
        puts "Use a comma-separated list (eg. 'cat1, cat2, cat3')"
        puts "Tab-completion works."
        puts "(will create non-existing categories automatically)"

        categories = CLI::tab_complete("Post categories:", @@wp.categories)
      end

      cats = []
      categories.split(',').each { |c| cats << c.lstrip.strip }

      CLI::with_status("Posting...") do

        id, link = @@wp.new_post(:post_status  => 'publish',
                                 :post_date    => date,
                                 :post_title   => title,
                                 :post_content => html,
                                 :post_status  => status,
                                 :terms_names  => {
                                   :category => cats
                                 })
      end
      puts "Post successful!"

    elsif what == :page

      CLI::with_status("Creating page...") do

        id, link = @@wp.new_post(:post_status  => 'publish',
                                 :post_date    => [],
                                 :post_title   => title,
                                 :post_content => html,
                                 :post_status  => status,
                                 :post_type    => 'page')
      end
      puts "Page created!"
    end

    puts <<-END.remove_starting!
      id:   #{id}
      link: #{link}
    END
  end

  # Uploads `filename` to the blog.
  #
  def new_media filename

    if not File.exists? filename
      fail "File '#{filename}' doesn't exist"
    end
    if File.directory? filename
      fail "Are you nuts? '#{filename}' is a directory"
    end
    if File.stat(filename).size.zero?
      fail "File '#{filename}' is empty"
    end

    Quickpress::startup

    id, link, name = nil, nil

    CLI::with_status("Uploading '#{filename}'...") do
      id, link, name = @@wp.new_media filename
    end

    puts <<-END.remove_starting!
      File uploaded!
      id:   #{id}
      link: #{link}
      name: #{name}
    END
  end

  # Shows all uploaded items.
  def list_media
    Quickpress::startup
    media = @@wp.get_all_media
    if media.empty?
      puts "No items uploaded 'til now."
      return
    end

    table = [["ID", "Filename", "Link"]] + media
    Thor::Shell::Basic.new.print_table table
  end

  # Returns a Time Object according to String `format`.
  #
  # The acceptable date formats are:
  #
  # * `minute:hour`
  # * `minute:hour day`
  # * `minute:hour day-month`
  # * `minute:hour day-month-year`
  #
  # Whenever there's a non-specified field
  # (like year, for example) we'll get from the current
  # date.
  #
  # So if you only provide `minute:hour`, it'll return
  # a Time Object with the current day, month and year.
  #
  def date(format=nil)

    # When sending [] as `:post_date` it tells Wordpress
    # to post instantly.
    return [] if format.nil?

    # Allowed date formats
    full_fmt  = /(\d{1,2}):(\d{2}) (\d{1,2})-(\d{1,2})-(\d{4})/
    month_fmt = /(\d{1,2}):(\d{2}) (\d{1,2})-(\d{1,2})/
    day_fmt   = /(\d{1,2}):(\d{2}) (\d{1,2})/
    hours_fmt = /(\d{1,2}):(\d{2})/

    time = nil
    case format
    when full_fmt
      year   = format[full_fmt, 5].to_i
      month  = format[full_fmt, 4].to_i
      day    = format[full_fmt, 3].to_i
      minute = format[full_fmt, 2].to_i
      hour   = format[full_fmt, 1].to_i

      time = Time.new(year, month, day, hour, minute)

    when month_fmt then
      month  = format[month_fmt, 4].to_i
      day    = format[month_fmt, 3].to_i
      minute = format[month_fmt, 2].to_i
      hour   = format[month_fmt, 1].to_i

      time = Time.new(Time.now.year,
                      month, day, hour, minute)

    when day_fmt then
      day    = format[day_fmt, 3].to_i
      minute = format[day_fmt, 2].to_i
      hour   = format[day_fmt, 1].to_i

      time = Time.new(Time.now.year, Time.now.month,
                      day, hour, minute)

    when hours_fmt then
      minute = format[hours_fmt, 2].to_i
      hour   = format[hours_fmt, 1].to_i

      time = Time.new(Time.now.year, Time.now.month, Time.now.day,
                      hour, minute)

    else
      fail "* Invalid data format '#{format}'.\n"
            "See `qp help new-post` for details."
    end

    time
  end

  # Checks if `string` is a valid status for a post.
  #
  # @note Falls back to `publish`.
  def status(string=nil)
    case string
    when nil        then return "publish"
    when /draft/i   then return string
    when /publish/i then return string
    when /private/i then return string
    else
      fail "* Invalid status format '#{format}'.\n"
           "See `qp help new-post` for details."
    end
  end

  # Entrance for when we're editing a page or a post
  # with numerical `id` (`what` says so).
  #
  def edit(what, id, filename=nil)
    Quickpress::startup

    # Get previous content
    old_content = nil
    if what == :post
      post = @@wp.get_post id

      old_content = post["post_content"]
    else
      page = @@wp.get_page id

      old_content = page["post_content"]
    end

    if filename.nil?

      # Get editor to open temporary file
      editor = ENV["EDITOR"]
      if editor.nil?
        editor = get("Which text editor we'll use?")
      end

      # Create draft file
      tempfile = Tempfile.new ['quickpress', '.html']
      tempfile.write old_content
      tempfile.flush

      # Oh yeah, baby
      `#{editor} #{tempfile.path}`

      if tempfile.size.zero?
        puts "Empty file: did nothing"
        tempfile.close
        exit 666
      end

      tempfile.close  # Apparently, calling `tempfile.flush`
      tempfile.open   # won't do it. Need to close and reopen.

      md5old = Digest::MD5.hexdigest old_content
      md5new = Digest::MD5.hexdigest tempfile.read

      if (md5old == md5new) and (not $options[:force])
        puts "Contents unchanged: skipping"
        puts "(use --force if you want to do it anyway)"
        return
      end

      puts "File: '#{tempfile.path}'" if $options[:debug]

      edit_file(what, id, tempfile.path)
      tempfile.close

    else

      md5old = Digest::MD5.hexdigest old_content
      md5new = Digest::MD5.hexdigest File.read(filename)

      if (md5old == md5new) and (not $options[:force])
        puts "Contents unchanged: skipping"
        puts "(use --force if you want to do it anyway)"
        return
      end

      edit_file(what, id, filename)
    end
  end

  # Actually edits post/page `filename` to the blog.
  def edit_file(what, id, filename)

    html = Tilt.new(filename).render

    link = nil

    old_title = nil
    case what
    when :post
      post = @@wp.get_post id
      old_title = post["post_title"]

    when :page
      page = @@wp.get_page id
      old_title = page["post_title"]
    end

    title = $options[:title]
    if title.nil?
      title = CLI::get("New Title:", true)
    end

    # Falling back to current title if empty
    title = old_title if title.empty?

    date   = Quickpress::date $options[:date]
    status = Quickpress::status $options[:status]

    case what
    when :post
      # Only thing that makes posts different from pages
      # are categories.

      categories = $options[:category]
      if categories.nil?
        puts "Existing blog categories:"
        Quickpress::list_categories
        puts
        puts "Use a comma-separated list (eg. 'cat1, cat2, cat3')"
        puts "Tab-completion works."
        puts "(will create non-existing categories automatically)"
        puts "(leave empty to keep current categories)"

        categories = CLI::tab_complete("Post categories:", @@wp.categories)
      end

      cats = categories.split(',').map { |c| c.lstrip.strip }

      CLI::with_status("Editing post...") do
        link = @@wp.edit_post(:post_id => id,
                              :content => {
                                :post_content => html,
                                :post_title => title,
                                :post_status => status,
                                :terms_names => {
                                  :category => cats
                                }
                              })
      end

    when :page
      CLI::with_status("Editing Page...") do
        link = @@wp.edit_post(:post_id => id,
                              :filter => {
                                :post_type => 'page'
                              },
                              :content => {
                                :post_content => html,
                                :post_title => title,
                                :post_status => status
                              })
      end
    end

    puts <<-END.remove_starting!
      Edit successful!
      link: #{link}
    END
  end


  # Deletes comma-separated list of posts/pages with `ids`.
  # A single number is ok too.
  def delete(what, ids)
    Quickpress::startup

    ids.split(',').each do |id|

      thing = nil

      CLI::with_status("Hold on a sec...") do

        if what == :post
          thing = @@wp.get_post id.to_i
        elsif what == :page
          thing = @@wp.get_page id.to_i
        end

      end

      puts <<-END.remove_starting!
        Will delete the following #{what}:

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
        case what
        when :post then @@wp.delete_post id.to_i
        when :page then @@wp.delete_page id.to_i
        end
      end
      puts "Deleted!"
    end
  end

  # Show last `ammount` of posts/pages in reverse order of
  # publication.
  #
  def list(what, ammount)
    Quickpress::startup

    elements = nil
    if what == :post
      CLI::with_status("Retrieving posts...") do
        elements = @@wp.get_posts ammount
      end

    elsif what == :page
      CLI::with_status("Retrieving pages...") do
        elements = @@wp.get_pages ammount
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

  def list_markup
    puts "Name (file extension)"
    puts

    @@supported_markup.each do |m|
      puts "* #{m[0]} (#{m[1]})"
    end
  end

  # Shows comment count according to their status.
  def status_comments
    Quickpress::startup
    status = @@wp.get_comment_status

    puts
    Thor::Shell::Basic.new.print_table status
  end

  def status_categories
    Quickpress::startup
    status = @@wp.get_category_status

    if $options[:"non-empty"]
      status.reject! { |s| s[1].zero? }
    end

    puts
    Thor::Shell::Basic.new.print_table status
  end

  private
  module_function

  # Initializes everything based on the config file or
  # simply by asking the user.
  def startup
    return if @started

    Quickpress::first_time if @@default_site.nil?

    puts "Using site '#{@@default_site}'"

    Quickpress::authenticate

    CLI::with_status("Connecting...") do
      @@wp ||= Wordpress.new(@@default_site, @@username, @@password)
    end
    @started = true
  end

  # Gets username and password for the Wordpress site.
  #
  # There's three ways of authenticating,
  # in order of importance:
  #
  # 1. Command-line options.
  #    User can specify user/pass with the `-u` and `-p`
  #    options, overrides everything else.
  # 2. Environment variables.
  #    Whatever's inside `QP_USERNAME` and `QP_PASSWORD`
  #    envvars will be used.
  # 3. Ask the user.
  #    If all else fails, we'll ask the user for
  #    username/password.
  #
  def authenticate
    @@username ||= $options[:user]
    @@password ||= $options[:pass]

    @@username ||= ENV["QP_USERNAME"]
    @@password ||= ENV["QP_PASSWORD"]

    @@username ||= CLI::get("Username:")
    @@password ||= CLI::get_secret("Password:")
  end
end

