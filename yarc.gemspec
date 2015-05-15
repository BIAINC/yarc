# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yarc/version'

Gem::Specification.new do |spec|
  spec.name          = "yarc"
  spec.version       = Yarc::VERSION
  spec.authors       = ["BIA"]
  spec.email         = ["dev@biaprotect.com"]
  spec.summary       = "Yet Another Redis Cache"
  spec.description   = "Redis-backed cache with temporary and permanent storage"
  spec.homepage      = ""
  spec.license       = "none"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", "~> 3.0"
  spec.add_dependency "multi_json", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.10"
end
