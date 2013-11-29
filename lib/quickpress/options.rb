
module Quickpress
  class Options
    def initialize
      @options = {}
      @options[:force] = false
      @options[:markup] = 'markdown'
    end

    def [] label
      @options[label]
    end

    def []=(label, val)
      @options[label] = val
    end
  end

  $options = Options.new
end

