require 'faraday'

module Forest
  module Vimeo
    class Video
      VIDEO_DATA_EXCLUDED_KEYS = ['user', 'embed', 'stats', 'metadata', 'uploader', 'download']
      POLL_TIME = 1.minute

      def self.get(vimeo_video_id)
        response = Faraday.get("https://api.vimeo.com/videos/#{vimeo_video_id}", nil, Forest::Vimeo::Client::HEADERS)

        unless response.success?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video upload failed\n#{response.status} #{response.reason_phrase}" }

          return response
        end

        JSON.parse(response.body)
      end

      def self.upload(media_item)
        # This upload method uses Vimeo's "pull" approach
        # https://developer.vimeo.com/api/upload/videos#pull-approach

        # TODO: move the file to a dedicated Forest folder after upload
        # https://developer.vimeo.com/api/reference/folders

        body = {
          "upload": {
            "approach": "pull",
            "size": media_item.attachment_data.dig('metadata', 'size'),
            "link": media_item.attachment_url
          },
          "privacy": {
            "view": "disable",
            "comments": "nobody",
            "download": false
          },
          "name": media_item.title,
          "description": media_item.caption.to_s,
          "review_page": {
            "active": false
          }
        }.to_json

        response = Faraday.post("https://api.vimeo.com/me/videos", body, Forest::Vimeo::Client::HEADERS)

        unless response.success?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video upload failed\n#{response.status} #{response.reason_phrase}" }
          return response
        end

        media_item.update(vimeo_metadata: JSON.parse(response.body).except(*VIDEO_DATA_EXCLUDED_KEYS))

        Forest::Vimeo::VideoPollJob.set(wait: POLL_TIME).perform_later(media_item.id)
      end

      def self.replace(media_item)
        # Replace the source file of an existing video using the "pull" approach
        # https://developer.vimeo.com/api/upload/videos#replacing-a-source-file

        body = {
          "file_name": media_item.title,
          "upload": {
            "approach": "pull",
            "status": "in_progress",
            "size": media_item.attachment_data.dig('metadata', 'size'),
            "link": media_item.attachment_url
          },
        }.to_json

        response = Faraday.post("https://api.vimeo.com/videos/#{media_item.vimeo_video_id}/versions", body, Forest::Vimeo::Client::HEADERS)

        unless response.success?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video replace failed\n#{response.status} #{response.reason_phrase}" }
          return response
        end

        media_item.update(vimeo_metadata: JSON.parse(response.body).except(*VIDEO_DATA_EXCLUDED_KEYS))

        Forest::Vimeo::VideoPollJob.set(wait: POLL_TIME).perform_later(media_item.id)
      end

      def self.destroy(vimeo_video_id)
        if vimeo_video_id.blank?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video destroy failed: vimeo_video_id is blank" }
          return
        end

        response = Faraday.delete("https://api.vimeo.com/videos/#{vimeo_video_id}", nil, Forest::Vimeo::Client::HEADERS)

        unless response.success?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video destroy failed\n#{response.status} #{response.reason_phrase}" }
          return response
        end
      end
    end
  end
end
