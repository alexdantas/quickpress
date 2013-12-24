# quickpress

[![Gem Version](https://badge.fury.io/rb/quickpress.png)](http://badge.fury.io/rb/quickpress)
[![emacs banner](http://badges.alexdantas.net/emacs.png)](http://badges.alexdantas.net/)
[![free-software banner](http://badges.alexdantas.net/free-software.png)](http://badges.alexdantas.net/)

Manage your Wordpress site from the command line.

## Features

Quickpress allows you to quickly post on your Wordpress site.
It is also:

* **Powerful**: With quickpress you can create, delete and list
  your posts and pages. More actions are expected on next releases.
* **Easy-to-use**: [Two to three commands](#getting-started) should
  be everything you need to know about it.
* **Versatile**: It supports a wide range of templating languages.
  Markdown, Asciidoc, ERB and [much more](#supported-template-engines)!
* **Documented**: [The wiki][wiki]
  has all the guides you'll ever need. Also, reference is only
  a `qp help` away.
* **Unified**: Works on both Wordpress.com and self-hosted Wordpress.org
  websites.
* **Safe**: Quickpress doesn't store your username/password anywhere.
* **Free**: It is licensed under the GPLv3. It means that quickpress
  will always be free
  ([both as in "free beer" and as in "freedom"](http://en.wikipedia.org/wiki/Gratis_versus_libre#.22Free_beer.22_vs_.22free_speech.22_distinction)).

## Installation

Quickpress is on RubyGems. To install it, do:

    $ gem install quickpress

If you want to install it yourself, [grab the gem][gem]
and there you go!

## Getting started

To use quickpress we call `qp` with some commands, just like `git`.

To start using a site withing quickpress, do:

    $ qp new-site

Now you can do a lot with it. For example, let's list all
existing posts there:

    $ qp list-posts

Want to post? Write it anywhere and point `qp` to it!

    $ qp new-post my-post.md

If you're too lazy, calling `new-post` without filenames will
call your default text editor to write it.
Try it!

Oops, you made a mistake and want to delete a post.
First, list them and then delete by id:

    $ qp list-posts      # shows all posts, with their ID
	$ qp delete-post ID

All of the previous commands can be done with pages too.

Now say you want to post on another Worpress site.
By doing `qp new-site` it should become the default.

After doing this, you can switch between them by using:

	$ qp list-sites      # shows them all, with their ID
	$ qp use-site ID     # sets a default site by it's ID

If you want help with any command, just call:

    $ qp help (command)

To see a list of all commands, call:

    $ qp help

Finally, a simple cheatsheet is shown when doing:

    $ qp

For more help and nice guides, check out [the wiki][wiki].

## Supported template engines

Thanks to [Tilt][tilt], you can write on `quickpress` with several templating
engines. Just be sure to have at least one *required gem* of your favorite
*engine*.

| Engine                  | File extensions       | Required gem               |
| ----------------------- | --------------------- | -------------------------- |
| Asciidoc                | .ad, .adoc, .asciidoc | `asciidoctor` (>= 0.1.0)|
| ERB                     | .erb, .rhtml          | none (included on ruby stdlib)|
| Interpolated String     | .str                  | none (included on ruby core)|
| Erubis                  | .erb, .rhtml, .erubis | `erubis`|
| Haml                    | .haml                 | `haml`|
| Sass                    | .sass                 | `haml` (< 3.1) or `sass` (>= 3.1)|
| Scss                    | .scss                 | `haml` (< 3.1) or `sass` (>= 3.1)|
| Less CSS                | .less                 | `less`|
| Builder                 | .builder              | `builder`|
| Liquid                  | .liquid               | `liquid`|
| Markdown                | .markdown, .mkd, .md  | `rdiscount` or `redcarpet` or `bluecloth` or `kramdown` or `maruku`|
| Textile                 | .textile              | `redcloth`|
| RDoc                    | .rdoc                 | `rdoc`|
| Radius                  | .radius               | `radius`|
| Markaby                 | .mab                  | `markaby`|
| Nokogiri                | .nokogiri             | `nokogiri`|
| CoffeeScript            | .coffee               | `coffee-script` (+ javascript)|
| Creole (Wiki markup)    | .wiki, .creole        | `creole`|
| MediaWiki (Wiki markup) | .wiki, .mediawiki, .mw| `wikicloth`|
| Yajl                    | .yajl                 | `yajl-ruby`|
| CSV                     | .rcsv                 | none (Ruby >= 1.9), `fastercsv` (Ruby < 1.9)|

As said before, simply point `qp` to the filename or specify the engine in
lowercase:

    $ qp post my-markdown.md
    $ qp post my-asciidoc.adoc
	$ qp post -m asciidoc my-text-file.txt
	$ qp post -m textile my-text-file.txt

## Development

Quickpress uses [Thor][thor] for it's CLI interface and
[rubypress] for the Wordpress XMLRPC API.
It was highly inspired by the [blogpost] tool - thanks
a lot, Stuart Rackam!

For now the source code is a mess.
Any comments are well-appreciated.

Contributions are *always* welcome, regardless of the size.
Here's how you can do it:

1. Fork me
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Do your magic
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

An easy way is to help on documentation. For that, simply head up
for [the wiki][wiki] and start editing things.

## Contact

Hi, I'm Alexandre Dantas! Thanks for having interest in this project.
Please take the time to visit any of the links below.

* `quickpress` homepage: http://quickpress.alexdantas.net/
* My homepage: http://www.alexdantas.net
* Mail me: `eu at alexdantas.net`

[tilt]:https://github.com/rtomayko/tilt
[thor]:http://whatisthor.com/
[rubypress]:https://github.com/zachfeldman/rubypress
[wiki]:https://github.com/alexdantas/quickpress/wiki
[gem]:https://rubygems.org/gem/quickpress/
[blogpost]:http://srackham.wordpress.com/blogpost-readme/

