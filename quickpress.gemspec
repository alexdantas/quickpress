# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quickpress/version'

Gem::Specification.new do |spec|
  spec.name          = 'quickpress'
  spec.version       = Quickpress::VERSION
  spec.authors       = ["Alexandre Dantas"]
  spec.email         = ["eu@alexdantas.net"]
  spec.summary       = "Manage your Wordpress site on the command line"
  spec.description   = <<END
Quickpress allows you to create, delete and list your
posts and pages on the command line.

It supports a great deal of template languages allowing you to
write the way you like.
END

  spec.homepage      = "http://quickpress.alexdantas.net/"
  spec.license       = "GPL-3.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rubypress'
  spec.add_dependency 'tilt'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end

