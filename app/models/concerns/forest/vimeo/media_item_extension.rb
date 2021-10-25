module Forest::Vimeo
  module MediaItemExtension
    extend ActiveSupport::Concern

    included do
      after_save_commit :upload_to_vimeo
      after_destroy_commit :delete_from_vimeo

      belongs_to :vimeo_video_thumbnail_override, class_name: 'MediaItem', optional: true
    end

    def vimeo_video?
      video? && vimeo_video_id.present?
    end

    def vimeo_video_id
      vimeo_metadata && vimeo_metadata['uri']&.match(/^\/videos\/(\d*)/).try(:[], 1)
    end

    def vimeo_user_id
      vimeo_metadata&.dig('user', 'uri')&.match(/^\/users\/(\d*)/).try(:[], 1)
    end

    def vimeo_video_link
      vimeo_metadata && vimeo_metadata['link']
    end

    def vimeo_video_width
      vimeo_metadata && vimeo_metadata['width']
    end

    def vimeo_video_height
      vimeo_metadata && vimeo_metadata['height']
    end

    def vimeo_video_aspect_ratio(vimeo_video_default_width: 16, vimeo_video_default_height: 9)
      w = vimeo_video_width.to_f > 0 ? vimeo_video_width.to_f : (vimeo_video_default_width.to_f * 100)
      h = vimeo_video_height.to_f > 0 ? vimeo_video_height.to_f : (vimeo_video_default_height.to_f * 100)
      h / w
    end

    def vimeo_video_upload_status
      vimeo_metadata&.dig('upload', 'status')
    end

    def vimeo_video_transcode_status
      vimeo_metadata&.dig('transcode', 'status')
    end

    def vimeo_video_files(quality: %w(sd hd), public_name_prefix: %w(sd hd))
      return [] unless (vimeo_metadata && vimeo_metadata['files'].to_a.size > 1)

      vimeo_metadata['files'].to_a
                             .select { |f| quality.include?(f['quality'].downcase) }
                             .select { |f| f['public_name'].downcase.start_with?(*public_name_prefix) }
                             .sort_by { |f| f['size'] }
    end

    def vimeo_video_file_url
      video_file_link = vimeo_video_files.last.try(:[], 'link')
      video_file_link
    end

    def vimeo_video_file_url_mobile
      video_file_link = vimeo_video_files.select { |f| f['quality'] == 'hd' }.first.presence ||
                          vimeo_video_files.select { |f| f['quality'] == 'sd' }.last
      video_file_link.try(:[], 'link')
    end

    def vimeo_video_default_thumbnail?
      vimeo_metadata&.dig('pictures', 'type') == 'default'
    end

    def vimeo_video_thumbnails
      vimeo_metadata&.dig('pictures', 'sizes').to_a
    end

    def vimeo_video_thumbnail(size = nil)
      return [] unless vimeo_video_thumbnails.size > 1

      if size.to_s == 'thumb'
        # For now we are assuming the thumbnails are ordered by smallest to largest
        image_link = vimeo_video_thumbnails.first.try(:[], 'link')
      else
        largest_thumbnail = vimeo_video_thumbnails.find do |p|
          p['width'] == vimeo_video_width && p['height'] == vimeo_video_height
        end.presence
        largest_thumbnail = vimeo_video_thumbnails.last if largest_thumbnail.blank?
        image_link = largest_thumbnail.try(:[], 'link')
      end

      image_link
    end

    private

    def upload_to_vimeo
      return unless video? && (attachment_changed? || vimeo_metadata.blank?)

      if saved_changes[:attachment_data].try(:[], 0).blank?
        Forest::Vimeo::VideoUploadJob.perform_later(id)
      else
        Forest::Vimeo::VideoReplaceJob.perform_later(id)
      end
    end

    def delete_from_vimeo
      return unless video?

      Forest::Vimeo::VideoDestroyJob.perform_later(vimeo_video_id)
    end
  end
end
