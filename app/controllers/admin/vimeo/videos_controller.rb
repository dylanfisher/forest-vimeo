class Admin::Vimeo::VideosController < Admin::ForestController
  before_action :set_media_item

  def update
    authorize @media_item

    video_metadata = Forest::Vimeo::Video.get(params[:id])

    if video_metadata.try(:status) == 404
      @media_item.update(vimeo_metadata: nil)
      notice = 'This video can\'t be found on Vimeo. The metadata saved in this media item has been cleared. Please re-upload your video if you think this is an error.'
    else
      transcode_status = video_metadata.dig('transcode', 'status')

      if transcode_status == 'in_progress'
        notice = 'This video is still being transcoded. The CMS will continue to automatically check the transcoding status every minute until the video is processed and ready to view.'
        Forest::Vimeo::VideoPollJob.set(wait: Forest::Vimeo::Video::POLL_TIME).perform_later(@media_item.id)
      else
        @media_item.update(vimeo_metadata: video_metadata.except(*Forest::Vimeo::Video::VIDEO_DATA_EXCLUDED_KEYS))
        notice = 'The Vimeo metadata for this video has been updated successfully.'
      end
    end

    redirect_to edit_admin_media_item_path(@media_item), notice: notice
  end

  private

  def set_media_item
    @media_item = MediaItem.find(params[:media_item_id])
  end
end
