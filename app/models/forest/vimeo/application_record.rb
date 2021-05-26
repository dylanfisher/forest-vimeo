module Forest
  module Vimeo
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
