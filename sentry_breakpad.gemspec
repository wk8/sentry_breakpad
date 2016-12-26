# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sentry_breakpad/version'

Gem::Specification.new do |spec|
  spec.name = 'sentry_breakpad'
  spec.version = SentryBreakpad::VERSION
  spec.authors = ['Jean Rouge']
  spec.email = ['jer329@cornell.edu']

  spec.summary = "Converts Google breakpad's reports into Sentry/Raven events"
  spec.homepage = 'https://github.com/wk8/sentry_breakpad'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sentry-raven', '~> 2.2.0'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
end
