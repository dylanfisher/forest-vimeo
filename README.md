# Forest::Vimeo
Enable an application running Forest to sync video uploads to Vimeo.

## Usage
This plugin requires at minimum a Vimeo pro account to enable direct video file access.

In Vimeo, create a new [developer app](https://developer.vimeo.com/apps) named e.g. `Forest Video Integration`.

Generate an authenticated personal acces token with the following scopes:

- Public
- Private
- Create
- Edit
- Upload
- Delete
- Video Files

Add the following key/values to your Rails credentials file, or specify an environment variable to override.

The Vimeo [personal access token](https://developer.vimeo.com/apps/215549#personal_access_tokens)

`forest_vimeo_access_token: abcdef12345` or override with `ENV['FOREST_VIMEO_ACCESS_TOKEN']`

Override `MediaItem` class and include the `Forest::Vimeo::MediaItemExtension` concern in your host app:

```ruby
# app/models/media_item.rb
class MediaItem < Forest::ApplicationRecord
  include BaseMediaItem
  include Forest::Vimeo::MediaItemExtension
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'forest-vimeo'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install forest-vimeo
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
