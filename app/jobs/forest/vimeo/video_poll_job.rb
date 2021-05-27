module Forest::Vimeo
  class VideoPollJob < ApplicationJob
    queue_as :default

    def perform(media_item_id)
      begin
        media_item = MediaItem.find(media_item_id)
        vimeo_video_id = media_item.vimeo_video_id

        video_metadata = Forest::Vimeo::Video.get(vimeo_video_id)

        if video_metadata.try(:status) == 404
          media_item.update(vimeo_metadata: nil)
          return
        end

        transcode_status = video_metadata.dig('transcode', 'status')

        if transcode_status == 'in_progress'
          Forest::Vimeo::VideoPollJob.set(wait: Forest::Vimeo::Video::POLL_TIME).perform_later(media_item.id)
        else
          media_item.update(vimeo_metadata: video_metadata.except(*Forest::Vimeo::Video::VIDEO_DATA_EXCLUDED_KEYS))
        end
      rescue Exception => e
        backtrace = e.backtrace.first(10).join("\n")
        Rails.logger.error { "[Forest][Error] Forest::Vimeo::VideoPollJob failed\n#{e.message}\n#{backtrace}" }
      end
    end
  end
end
