
require 'io/console' # ruby 1.9.3 above
require 'abbrev'

module Quickpress

  # Basic input/output functions for the console.
  module CLI
    module_function

    # Shows `prompt` and gets a string from the user.
    #
    # This ensures that the string is not empty
    # and pre/post spaces are removed.
    def get prompt
      print "#{prompt} "

      ret = ""
      ret = $stdin.gets.lstrip.strip while ret.empty?
      ret
    end

    # Shows `prompt` and gets a secret string from the user.
    #
    # Hides things the user is typing.
    def get_secret prompt
      ret = ""

      $stdin.noecho { ret = get(prompt) }

      puts
      ret
    end

    # Asks `prompt` and returns a true/false answer.
    def ask prompt
      print "#{prompt} (Y/n) "

      ans = $stdin.gets.lstrip.strip

      return true if ans.empty?
      ['y', 'Y'].include? ans
    end

    # Erases from the cursor to the beginning of line.
    def clear_line
      print "\r\e[0K"
    end

    # Runs a block of code withing a quick status `prompt`.
    def with_status(prompt)
      print prompt
      yield
      clear_line
    end

    # Shows `prompt` and reads a line from commandline,
    # doing tab-completion according to `completions` Array.
    #
    # `separator` is the character to use when separating
    # words.
    def tab_complete(prompt, completions, separator=" ")

      abbrevs = Abbrev::abbrev completions
      word = ""
      line = ""

      $stdin.raw do
        while (char = $stdin.getch) != "\r"

          if char == "\t"
            if abbrevs.include?(word)
              word = abbrevs[word]
            end

          elsif (char == "\b" || char.ord == 127) # strange...
            if word.empty?
              line.chop!
            else
              word.chop!
            end

          else
            word += char

            if char == separator
              line += word
              word.clear
            end
          end

          clear_line
          print (line + word)
        end
        line += word
      end
      puts

      line
    end

  end
end

