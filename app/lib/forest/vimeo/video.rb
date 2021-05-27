require 'faraday'

module Forest
  module Vimeo
    class Video
      VIDEO_DATA_EXCLUDED_KEYS = ['embed', 'stats', 'metadata', 'uploader', 'download']
      POLL_TIME = 1.minute
      FOLDER_NAME = 'Forest CMS'

      def self.get(vimeo_video_id)
        response = Faraday.get("https://api.vimeo.com/videos/#{vimeo_video_id}", nil, Forest::Vimeo::Client::HEADERS)

        unless response.success?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video upload failed\n#{response.status} #{response.reason_phrase}" }

          return response
        end

        JSON.parse(response.body)
      end

      def self.upload(media_item, folder_name: FOLDER_NAME)
        # This upload method uses Vimeo's "pull" approach
        # https://developer.vimeo.com/api/upload/videos#pull-approach

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

        if folder_name.present?
          folder = get_folder(user_id: media_item.vimeo_user_id, folder_name: folder_name, create_if_not_exist: true)
          add_video_to_folder(user_id: media_item.vimeo_user_id, folder_id: get_folder_id(folder), video_id: media_item.vimeo_video_id)
        end
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
          }
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

        Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video destroy failed\n#{response.status} #{response.reason_phrase}" } unless response.success?

        response
      end

      def self.get_folder(user_id:, folder_name: FOLDER_NAME, page_number: 1, create_if_not_exist: false)
        # https://developer.vimeo.com/api/reference/folders#get_projects

        if class_variable_defined?(folder_class_variable_name(folder_name)) && class_variable_get(folder_class_variable_name(folder_name)).present?
          return class_variable_get(folder_class_variable_name(folder_name))
        end

        body = {
          "direction": "asc",
          "page": page_number,
          "per_page": 100,
          "sort": "name"
        }

        response = Faraday.get("https://api.vimeo.com/users/#{user_id}/projects", body, Forest::Vimeo::Client::HEADERS)

        unless response.success?
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video folder failed\n#{response.status} #{response.reason_phrase}" }
          return response
        end

        response = JSON.parse(response.body)

        folder = response['data'].to_a.find { |f| f['name'] == folder_name }

        if !folder && response.dig('paging', 'next').present?
          page_number += 1
          get_folder(user_id: user_id, folder_name: folder_name, page_number: page_number)
        end

        class_variable_set(folder_class_variable_name(folder_name), folder)

        if folder.blank? && create_if_not_exist
          folder = create_folder(user_id: user_id, folder_name: folder_name)
        end

        folder
      end

      def self.create_folder(user_id:, folder_name: FOLDER_NAME)
        # https://developer.vimeo.com/api/reference/folders#create_project

        body = {
          "name": folder_name
        }.to_json

        response = Faraday.post("https://api.vimeo.com/users/#{user_id}/projects", body, Forest::Vimeo::Client::HEADERS)

        Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video create_folder failed\n#{response.status} #{response.reason_phrase}" } unless response.success?

        folder = JSON.parse(response.body)

        class_variable_set(folder_class_variable_name(folder_name), folder)

        folder
      end

      def self.add_video_to_folder(user_id:, folder_id:, video_id:)
        if [user_id, folder_id, video_id].any?(&:blank?)
          Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video add_video_to_folder failed - a required parameter is missing." }
          return
        end

        response = Faraday.put("https://api.vimeo.com/users/#{user_id}/projects/#{folder_id}/videos/#{video_id}", nil, Forest::Vimeo::Client::HEADERS)

        Rails.logger.error { "[Forest][Error] Forest::Vimeo::Video add_video_to_folder failed\n#{response.status} #{response.reason_phrase}" } unless response.success?

        response
      end

      private

      def self.folder_class_variable_name(folder_name)
        :"@@folder_#{folder_name.parameterize.underscore}"
      end

      def self.get_folder_id(folder)
        folder["uri"]&.match(/^\/users\/\d*\/projects\/(\d*)/).try(:[], 1)
      end
    end
  end
end
