require_relative "lib/forest/vimeo/version"

Gem::Specification.new do |spec|
  spec.name        = "forest-vimeo"
  spec.version     = Forest::Vimeo::VERSION
  spec.authors     = ["dylanfisher"]
  spec.email       = ["hi@dylanfisher.com"]
  spec.homepage    = "https://github.com/dylanfisher/forest-vimeo"
  spec.summary     = "Sync Forest CMS video uploads to Vimeo"
  spec.description = "A rails engine that syncs video uploads in Forest CMS to Vimeo, allowing for direct Vimeo file playing."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails"
  spec.add_dependency "faraday"
end
