# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jarbs/version'

Gem::Specification.new do |spec|
  spec.name          = "jarbs"
  spec.version       = Jarbs::VERSION
  spec.authors       = ["Luke van der Hoeven"]
  spec.email         = ["hungerandthirst@gmail.com"]

  spec.summary       = %q{Jarbs: CLI Tooling for Lambda}
  spec.description   = %q{Jarbs: They took em.}
  spec.homepage      = "https://docs.articulate.zone/tools/jarbs.html"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = %w{ jarbs }
  spec.require_paths = ["lib"]

  spec.add_dependency "commander"
  spec.add_dependency "aws-sdk", "~> 2"
  spec.add_dependency "rubyzip"
  spec.add_dependency "babel-transpiler"
  spec.add_dependency "rugged"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
end
