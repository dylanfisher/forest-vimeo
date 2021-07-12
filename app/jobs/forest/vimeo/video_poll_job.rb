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
        time_ago_in_hours = (Time.current - media_item.created_at) / 3600

        if transcode_status == 'in_progress'
          Forest::Vimeo::VideoPollJob.set(wait: Forest::Vimeo::Video::POLL_TIME).perform_later(media_item.id)
        else
          media_item.assign_attributes(vimeo_metadata: video_metadata.except(*Forest::Vimeo::Video::VIDEO_DATA_EXCLUDED_KEYS))
          media_item.save! if media_item.changed?

          # If the media item was created less than 24 hours ago, poll the video at a lower rate.
          # Even though the transcode status is complete, some of the larger video sizes take longer.
          if time_ago_in_hours < 0.5
            wait_time = 5.minutes
          elsif time_ago_in_hours < 1
            wait_time = 10.minutes
          elsif time_ago_in_hours < 12
            wait_time = 60.minutes
          elsif time_ago_in_hours < 24
            wait_time = 120.minutes
          end

          if wait_time.present?
            Forest::Vimeo::VideoPollJob.set(wait: wait_time).perform_later(media_item.id)
          end
        end
      rescue Exception => e
        backtrace = e.backtrace.first(10).join("\n")
        Rails.logger.error { "[Forest][Error] Forest::Vimeo::VideoPollJob failed\n#{e.message}\n#{backtrace}" }
      end
    end
  end
end
