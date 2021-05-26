class AddVimeoMetadataToMediaItems < ActiveRecord::Migration[6.0]
  def change
    add_column :media_items, :vimeo_metadata, :jsonb, default: {}
    add_index  :media_items, :vimeo_metadata, using: :gin
  end
end
