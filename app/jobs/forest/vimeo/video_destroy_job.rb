module Forest::Vimeo
  class VideoDestroyJob < ApplicationJob
    queue_as :default

    def perform(vimeo_video_id)
      begin
        Forest::Vimeo::Video.destroy(vimeo_video_id)
      rescue Exception => e
        backtrace = e.backtrace.first(10).join("\n")
        Rails.logger.error { "[Forest][Error] Forest::Vimeo::VideoDestroyJob failed\n#{e.message}\n#{backtrace}" }
      end
    end
  end
end
