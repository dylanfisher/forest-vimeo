Rails.application.routes.draw do
  # Admin
  namespace :admin do
    resources :media_items, except: [:show], path: 'media-items' do
      namespace :vimeo do
        resources :videos, only: [:update]
      end
    end
  end
end
