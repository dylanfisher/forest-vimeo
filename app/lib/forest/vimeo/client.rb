module Forest
  module Vimeo
    class Client
      ACCESS_TOKEN = ENV['FOREST_VIMEO_ACCESS_TOKEN'].presence || Rails.application.credentials[:forest_vimeo_access_token]

      HEADERS = {
        "Authorization": "bearer #{Forest::Vimeo::Client::ACCESS_TOKEN}",
        "Content-Type": "application/json",
        "Accept": "application/vnd.vimeo.*+json;version=3.4"
      }
    end
  end
end
