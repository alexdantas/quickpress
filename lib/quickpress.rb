require 'quickpress/version'
require 'quickpress/post'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file

require 'quickpress/wordpress'
require 'fileutils'
require 'yaml'
require 'open-uri'
require 'io/console' # ruby 1.9.3 above

module Quickpress

  # Main directory where we store everything.
  ROOT_DIR  = File.expand_path "~/.config/quickpress"

  POST_DIR  = "#{ROOT_DIR}/posts"
  DRAFT_DIR = "#{ROOT_DIR}/drafts"
  CONFIG_FILE = "#{ROOT_DIR}/config.yml"

  @@inited       = nil
  @@default_site = nil
  @@username     = nil
  @@password     = nil
  @@connection   = nil

  module_function

  # Loads default site from configuration file
  def init

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

    else
      File.write(CONFIG_FILE, "---")
    end

    @@inited = true
  end

  def get prompt
    print "#{prompt} "

    ret = ""
    ret = gets.lstrip.strip while ret.empty?
    ret
  end

  def get_secret prompt
    ret = ""

    $stdin.noecho { ret = get(prompt) }
    puts
    ret
  end

  def ask prompt
    print "#{prompt} (Y/n) "

    ans = gets.lstrip.strip
    return true if ans.empty?

    ['y', 'Y'].include? ans
  end

  def ask_for_site
    puts "It looks like the first time you're running quickpress."
    puts "Let's connect to your Wordpress site."

    begin
      puts
      address = get("Address:")

      ask_for_user_pass
      @@connection = Wordpress.new(address, @@username, @@password)
      puts <<END

Title:   #{@@connection.title}
Tagline: #{@@connection.tagline}
Url:     #{@@connection.url}
END
      answer = ask("Is that right?")
      fail "will retry" if not answer

      @@default_site = address

      # Saving to config file
      if File.exists? CONFIG_FILE
        raw = File.read CONFIG_FILE
        settings = YAML.load raw
        settings = {} if not settings

        settings["sites"] = [] if settings["sites"].nil?
        settings["sites"] << @@default_site

        settings["default_site"] = @@default_site

        File.write(CONFIG_FILE, YAML.dump(settings))
      end

    rescue ArgumentError => arg
      if arg.message =~ /Wrong protocol specified/
        $stderr.puts <<END
* Wrong protocol at Wordpress site.
  Please use `http` or `https`.
END
        retry if ask "Wanna retry?"
        exit 2
      end

      #   rescue Wordpressto::Error => err
      #     if err.message =~ /Incorrect username or password/
      #       $stderr.puts <<END
      # * Wrong username or password to '#{address}'
      # END
      #       retry if ask "Wanna retry?"
      #       exit 2
      #     end

    rescue => e
      if e.message =~ /Wrong content-type/
        $stderr.puts <<END
* This doesn't seem to be a Wordpress site.
  Check the address again.
END
        retry if ask "Wanna retry?"
        exit 2

      elsif e.message =~ /will retry/
        retry
      end

      puts e
      puts e.message
      retry if ask "Wanna retry?"
      exit 2
    end
  end

  def ask_for_user_pass
    @@username = get("Username:")
    @@password = get_secret("Password:")
  end

  def post filename
    self.init if @@inited.nil?

    if not internet_connection?
      fail <<END
# * It seems there's an issue with the internet connection.
  Check your settings and try again.
END
    end

    ask_for_site      if @@default_site.nil?
    ask_for_user_pass if @@username.nil? or @@password.nil?

    if @@connection.nil?
      @@connection = Wordpress.new(@@default_site,
                                   @@username,
                                   @@password)
    end

    post = Post.new filename

    title = get("Post title:")

    puts "Blog categories:"
    @@connection.categories.each { |c| puts c }
    puts
    puts "Use a comma-separated list (example: 'cat1, cat2, cat3')"
    categories = get("Post categories:")

    cats = []
    categories.split(',').each { |c| cats << c.lstrip.strip }

    id, link = @@connection.post(:content => {
                                   :post_status => "published",
                                   :post_date => Time.now,
                                   :post_title => title,
                                   :post_content => post.html
                                 },
                                 :terms_names => {
                                   :category => cats
                                 })
    puts <<END
Post successful!
id:   #{id}
link: #{link}
END

  rescue => e
    $stderr.puts <<END
#{e.message}
END
    exit 2
  end

  def post_new

  end

  def post_edit

  end

  def post_list

  end

  # Tells if there's a internet connection available.
  def internet_connection?
    begin
      true if open('http://www.google.com/',
                   "r",
                   :read_timeout => 2)
    rescue
      false
    end
  end

end

