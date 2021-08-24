class AddVimeoVideoThumbnailOverrideToMediaItems < ActiveRecord::Migration[6.0]
  def change
    add_reference :media_items, :vimeo_video_thumbnail_override, foreign_key: { to_table: 'media_items' }
  end
end
