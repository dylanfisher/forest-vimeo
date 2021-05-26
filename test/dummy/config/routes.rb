Rails.application.routes.draw do
  mount Forest::Vimeo::Engine => "/forest-vimeo"
end
