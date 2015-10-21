# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'OpenMatriX/version'

Gem::Specification.new do |spec|
  spec.name          = "OpenMatriX"
  spec.version       = OpenMatriX::VERSION
  spec.authors       = ["Andrew Rohne"]
  spec.email         = ["arohne@oki.org"]
  spec.licenses      = ["Apache-2.0"]
  spec.summary       = %q{Open Matrix support for Ruby}
  spec.description   = %q{Open Matrix Ruby API}
  spec.homepage      = "https://github.com/okiandrew/OpenMatriX"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"

  spec.add_dependency "ffi", "~> 1.9"
  spec.add_dependency "narray", "~> 0.6"
end
