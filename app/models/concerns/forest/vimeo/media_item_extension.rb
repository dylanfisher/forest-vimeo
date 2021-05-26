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

    def vimeo_video_link
      vimeo_metadata['link']
    end

    def vimeo_video_transcode_status
      vimeo_metadata.dig('transcode', 'status')
    end

    private

    def upload_to_vimeo
      return unless attachment_changed?

      Forest::Vimeo::VideoUploadJob.perform_later(id)
    end

    def delete_from_vimeo
      Forest::Vimeo::VideoDestroyJob.perform_later(vimeo_video_id)
    end
  end
end
