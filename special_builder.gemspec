# frozen_string_literal: true

require_relative "lib/special_builder/version"

# The gemspec's name is the plugin's key and its table prefix.
Gem::Specification.new do |spec|
  spec.name = "special_builder"
  spec.version = SpecialBuilder::VERSION
  spec.summary = "Special Builder for the CMS: drag specials onto the days of every week, or of one week"
  spec.authors = ["Martin Business Consultants"]
  spec.homepage = "https://github.com/Martin-Business-Consultants/plugin-special-builder"
  spec.license = "FSL-1.1-MIT"
  spec.files = Dir["{app,config,db,lib}/**/*"]
  spec.required_ruby_version = ">= 3.3"
  spec.add_dependency "rails", ">= 8.1"
end
