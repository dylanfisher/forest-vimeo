module Forest::Vimeo
  module MediaItemExtension
    extend ActiveSupport::Concern

    included do
      after_save_commit :upload_to_vimeo
      after_destroy_commit :delete_from_vimeo
    end

    def vimeo_video?
      video? && vimeo_video_id.present?
    end

    def vimeo_video_id
      vimeo_metadata['uri']&.match(/^\/videos\/(\d*)/).try(:[], 1)
    end

    def vimeo_user_id
      vimeo_metadata.dig('user', 'uri')&.match(/^\/users\/(\d*)/).try(:[], 1)
    end

    def vimeo_video_link
      vimeo_metadata['link']
    end

    def vimeo_video_width
      vimeo_metadata['width']
    end

    def vimeo_video_height
      vimeo_metadata['height']
    end

    def vimeo_video_upload_status
      vimeo_metadata.dig('upload', 'status')
    end

    def vimeo_video_transcode_status
      vimeo_metadata.dig('transcode', 'status')
    end

    def vimeo_video_default_thumbnail?
      vimeo_metadata.dig('pictures', 'type') == 'default'
    end

    def vimeo_video_thumbnails
      vimeo_metadata.dig('pictures', 'sizes').to_a
    end

    def vimeo_video_thumbnail
      return [] unless vimeo_video_thumbnails.size > 1

      largest_thumbnail = vimeo_video_thumbnails.find do |p|
        p['width'] == vimeo_video_width && p['height'] == vimeo_video_height
      end.presence
      largest_thumbnail = vimeo_video_thumbnails.last if largest_thumbnail.blank?
      largest_thumbnail.try(:[], 'link')
    end

    private

    def upload_to_vimeo
      return unless attachment_changed?

      if saved_changes[:attachment_data].try(:[], 0).blank?
        Forest::Vimeo::VideoUploadJob.perform_later(id)
      else
        Forest::Vimeo::VideoReplaceJob.perform_later(id)
      end
    end

    def delete_from_vimeo
      Forest::Vimeo::VideoDestroyJob.perform_later(vimeo_video_id)
    end
  end
end
