# quickpress

Manage your Wordpress site on the command-line

## Installation

As usual with ruby gems, do

    $ gem install quickpress

## Getting started

To use `quickpress` we call the executable `qp` with some
commands.

When using your first command, `quikpress` will ask to save
your Wordpress site address.

So, for example, let's list all existing posts on your site:

    $ qp list-posts

It will ask for your Wordpress url, username and password. Each
command from now on will require the username and password only.

Suppose you've written a nice markdown-formatted post on a file
`my-post.md`. To post it, simply do:

    $ qp new-post my-post.md

`quickpress` handles different template engines based on their
filename extensions. You can force one of them with the `-m`
switch:

    $ qp new-post -m asciidoc my-file.txt

To post on-the-fly, call:

    $ qp new-post

It will call your default text editor (set by the environment
`EDITOR`) or ask you for it(if it's empty). When you save
and quit it, it will get posted right away.

To delete posts, call the following command with an `id` seen
with `list-posts`:

    $ qp delete-post (id)

To mess with pages, follow the same path:

    $ qp new-page
	$ qp new-page (filename)
	$ qp list-pages
	$ qp delete-page (id)

If you want help with any command, just call:

    $ qp help (command)

To see a list of all commands, call:

    $ qp help

A simple cheatsheet is shown when using:

    $ qp

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

