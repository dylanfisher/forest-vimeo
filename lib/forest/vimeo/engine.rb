module Forest
  module Vimeo
    class Engine < ::Rails::Engine
      isolate_namespace Forest::Vimeo

      initializer 'forest-vimeo.checking_migrations' do
        Migrations.new(config, engine_name).check
      end
    end
  end
end
