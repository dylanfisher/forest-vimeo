module Forest::Vimeo
  class VideoUploadJob < ApplicationJob
    queue_as :default

    def perform(media_item_id)
      begin
        Forest::Vimeo::Video.upload(MediaItem.find(media_item_id))
      rescue Exception => e
        backtrace = e.backtrace.first(10).join("\n")
        Rails.logger.error { "[Forest][Error] Forest::Vimeo::VideoUploadJob failed\n#{e.message}\n#{backtrace}" }
      end
    end
  end
end
