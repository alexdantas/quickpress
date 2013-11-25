require 'tilt'

module Quickpress

  class Post
    attr_reader :raw, :html, :markup

    def initialize(filename)
      @raw = File.read filename

      # Deduce markup based on `filename`'s extension
      @template = Tilt.new filename

      # Parsing the post
      # Need to find the title

      # Parsing the rest
      @html = @template.render
    end

  end
end

