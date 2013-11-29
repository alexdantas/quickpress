# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quickpress/version'

Gem::Specification.new do |spec|
  spec.name          = 'quickpress'
  spec.version       = Quickpress::VERSION
  spec.authors       = ["Alexandre Dantas"]
  spec.email         = ["eu@alexdantas.net"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "GPL-3.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rubypress'
  spec.add_dependency 'tilt'
  spec.add_dependency 'RedCarpet'

  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'aruba'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'gli', '2.8.1'
end

