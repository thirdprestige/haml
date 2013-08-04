require 'base64'
require 'bundler'
require 'openssl'
require './basecamp'

Bundler.require 


##
## BASECAMP INTEGRATIONS
##

namespace :basecamp do
  desc 'Send machine configuration instructions'
  task :instruct do
    # Basecamp.when(/send.+welcome/) do |task|
    #   # who do we send it to? 

    #   Basecamp.client.mark_as_completed(task)
    # end
  end


  desc 'Test basecamp integration'
  task :test do
    Basecamp.client.mark_as_completed(
      Basecamp.client.add_todo('Testing!')
    )
  end
end



## 
## HEROKU INTEGRATIONS
##

namespace :heroku do
  desc 'Copy all production buckets to the development buckets each night'
  task :copy_production_buckets_to_development do
    Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
      heroku.get_apps.body.map do |response|
        response['name']
      end.select do |app|
        vars = heroku.get_config_vars(app).body

        # Does a development bucket for this app's production bucket exist?
        vars.keys.include?('AWS_S3_BUCKET') && AWS.s3.buckets[vars['AWS_S3_BUCKET'] + '-development'].exists?
      end.each do |app|
        Basecamp.client.add_todo("Copy #{app} bucket to development").tap do |task|
          bucket = heroku.get_config_vars(app).body['AWS_S3_BUCKET']

          AWS.s3.buckets[bucket].objects.each do |object|
            puts "Copying #{object.key} from #{bucket} to #{bucket}-development"
            object.copy_to(object.key, :bucket_name => bucket + '-development', :acl => :public_read)
          end

          Basecamp.client.mark_as_completed(task)
        end
      end
    end
  end

  desc 'Add all collaborators on this app as collaborators on our  other apps' 
  task :collaborators do
    Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
      # List each app Haml is a collaborator on
      collaborators = heroku.get_collaborators(ENV['HEROKU_APP_NAME']).body.map do |response|
        response['email']
      end

      heroku.get_apps.body.map do |response|
        response['name']
      end.each do |app|
        existing_collaborators = heroku.get_collaborators(app).body.map do |response|
          response['email']
        end

        (collaborators - existing_collaborators).each do |collaborator|
          puts "Adding #{collaborator} to #{app}"
          heroku.post_collaborator(app, collaborator)
        end
      end

      Basecamp.mark_as_completed(/heroku/i)
    end
  end

  desc 'Ensure these configurations are set up for all apps'
  task :configurations do
    Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
      # List each app we are a collaborator on
      heroku.get_apps.body.map do |response|
        response['name']
      end.each do |app|
        ENV['TEMPLATE_CONFIG_KEYS'].to_s.split(',').reject do |key|
  	ENV[key].blank? || heroku.get_config_vars(app).body.keys.include?(key)
        end.each do |key|
          heroku.put_config_vars(
            app, 
  	  key => ENV[key]
          )
        end
      end
    end
  end

  desc 'Ensure our demos builds are up to date. [Looks for collaborating apps starting with "demo-", e.g. "demo-third-prestige"]'
  task :rebuild_demos_from_backups do
    require 'heroku/client/pgbackups' 

    Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
      heroku.get_apps.body.map do |response|
        response['name']
      end.select do |app|

        # To add an app to this list, 
        # we need to name the app starting with the prefix 'demo-'
        # 
        # For example:
        # * demo-third-prestige
        # * demo-blp
        # * demo-simple-donation
        #
        app.start_with?('demo-') 
      end.each do |app|
        Basecamp.client.add_todo("Rebuild #{app} demo from scratch").tap do |task|
          # Two-step process
          # * Restore the latest non-automated backup (one that we captured manually)
          # * Bust the cache by updating the RAILS_CACHE_ID

          puts "Rebuilding demo for #{app}"
          puts "=> Restoring database from latest non-automated build..."
          configuration_variables = heroku.get_config_vars(app).body

          Heroku::Client::Pgbackups.new(configuration_variables['PGBACKUPS_URL']).tap do |backups|
              latest_non_automated_backup = backups.get_backups().find do |backup|
                backup['to_url'] =~ /\/b[0-9]+.dump/
              end

              backups.create_transfer(
                latest_non_automated_backup['to_url'], 
                'BACKUP', 
                configuration_variables['DATABASE_URL'], 
                'RESTORE'
              )
          end

          puts "=> Busting cache"
          heroku.put_config_vars(app, 'RAILS_CACHE_ID' => Time.now.to_i)

          puts "=> DONE", "\n" * 2

          Basecamp.client.mark_as_completed(task)
        end
      end
    end
  end

  task :dependencies do
    # Fail fast, we don't have a DEPLOYHOOKS_HTTP_URL
    raise 'Please set $DEPLOYHOOKS_HTTP_URL with a %s at the end' unless
      ENV['DEPLOYHOOKS_HTTP_URL'].to_s =~ /\%s\Z/i
  end

  desc 'Calculate an example URL hook for testing'
  task example: :dependencies do
    encrypted = OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
      cipher.encrypt
      cipher.key = ENV['SECRET_TOKEN']
    end.update('cache-bot')

    encoded   = Base64.encode64(encrypted)
    url       = ENV['DEPLOYHOOKS_HTTP_URL'] % encoded

    puts "Example URL: #{url.chomp}"
    puts "Test with: curl -d 'head=23xzh7&git_log=%23bust' #{url.chomp}"
  end

  desc 'Ensure a web hook is set up for all collaborators'
  task hooks: :dependencies do
    # Set up deploy hooks
    Heroku::API.new(api_key: ENV['HEROKU_API_KEY']).tap do |heroku|
      # List each app we are a collaborator on
      heroku.get_apps.body.map do |response|
        response['name']
      end.reject do |app|
        # Already includes a deploy hook?
        # We must have set it up already
        heroku.get_addons(app).body.map do |addons|
          addons['name']
        end.include?('deployhooks:http')
      end.reject do |app|
        heroku.get_config_vars(app).body.any? do |(key, value)|
          #TODO:
          # yell if the variable is set, but doesn't match our hook
          key == 'DEPLOYHOOKS_HTTP_URL'
        end
      end.each do |app|
        # Alright, a new app! Let's install the add-on

        # First, calculate the deploy hook URL
        # based on the app name
        # We'll decrypt this later,
        # then use it to update the correct app
        encrypted = OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
          cipher.encrypt
          cipher.key = ENV['SECRET_TOKEN']
        end.update(app)

        encoded   = Base64.encode64(encrypted)
        url       = ENV['DEPLOYHOOKS_HTTP_URL'] % encoded

        puts "Adding deployhook to #{app}: #{url}"
        heroku.post_addon(
          app,
          'deployhooks:http',
          url: url
        )

        # TODO:
        # notify other collaborators that cache-bot is set up
      end
    end
  end
end

