# Forest::Vimeo
Enable an application running Forest to sync video uploads to Vimeo.

## Usage
This plugin requires at minimum a Vimeo pro account to enable direct video file access.

In Vimeo, create a new [developer app](https://developer.vimeo.com/apps) named e.g. `Forest CMS Integration`.

Generate an authenticated personal acces token with the following scopes:

- Public
- Private
- Create
- Edit
- Delete
- Interact
- Upload
- Video Files

Add the following key/values to your Rails credentials file, or specify an environment variable to override.

The Vimeo [personal access token](https://developer.vimeo.com/apps/215549#personal_access_tokens):

`forest_vimeo_access_token: abcdef12345` or override with `ENV['FOREST_VIMEO_ACCESS_TOKEN']`

Override the `MediaItem` class and include the `Forest::Vimeo::MediaItemExtension` concern in your host app:

```ruby
# app/models/media_item.rb
class MediaItem < Forest::ApplicationRecord
  include BaseMediaItem
  include Forest::Vimeo::MediaItemExtension
end
```

Now, any time a video is uploaded to the CMS via the media library, the video will be uploaded to Vimeo and stored in a folder named `Forest CMS`.

## Image inputs

It may be helpful to limit the media item image input scope to just videos when launching the media item modal chooser.

`<%= f.association :media_item, as: :image, scope: :videos %>`

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'forest-vimeo', git: 'https://github.com/dylanfisher/forest-vimeo.git', branch: 'main'
```

And then execute:
```bash
$ bundle
```

Import the Gem's migration files and migrate the database:
```bash
bundle exec rake railties:install:migrations
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO:

- Prevent accidental deletion of Vimeo videos in development and staging environments.
