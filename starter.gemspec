# frozen_string_literal: true

require_relative "lib/starter/version"

# The gemspec's name is the theme's key (bin/theme new renames it).
Gem::Specification.new do |spec|
  spec.name = "starter"
  spec.version = Starter::VERSION
  spec.summary = "A Libre Publish theme"
  spec.authors = ["You"]
  spec.files = Dir["{app,config,lib}/**/*"]
  spec.required_ruby_version = ">= 3.3"
  spec.add_dependency "rails", ">= 8.1"
end
