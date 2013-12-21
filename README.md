# quickpress

Manage your Wordpress site on the command-line.

## Features

Quickpress allows you to quickly post on your Wordpress site.
It is also:

* **Powerful**: With quickpress you can create, delete and list
  your posts and pages. More actions are coming on next releases.
* **Easy-to-use**: Two to three commands should be everything you
  need to know when using it.
* **Versatile**: It supports a wide range of templating languages.
  Markdown, Asciidoc, ERB and [much more](#supported-template-engines)!
* **Documented**: [The wiki][wiki]
  has all the guides you'll ever need. Also, reference is only
  a `qp help` away.
* **Safe**: quickpress doesn't store your username/password anywhere.

## Installation

Quickpress is on RubyGems. To install it, do:

    $ gem install quickpress

If you want to install it yourself, [grab the gem][gem]
and there you go!

## Getting started

To use quickpress we call `qp` with some commands.

To start using a site withing quickpress, do:

    $ qp new-site

Now you can do a lot with it. For example, let's list all
existing posts there:

    $ qp list-posts

Want to post? Write it anywhere and point `qp` to it!

    $ qp new-post my-post.md

If you're too lazy, calling `new-post` without no filenames will
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

[tilt]:https://github.com/rtomayko/tilt
[wiki]:https://github.com/alexdantas/quickpress/wiki
[gem]:https://rubygems.org/gem/quickpress/

