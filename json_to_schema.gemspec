# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = 'json_to_schema'
  spec.version       = JsonToSchema::VERSION
  spec.authors       = ['Ben Trevor']
  spec.email         = ['trevorb@nextcapital.com']
  spec.description   = 'Aggregate JSON objects into a best-guess swagger schema.'
  spec.summary       = 'Aggregate JSON objects into a best-guess swagger schema.'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'

end