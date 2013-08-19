class CreateHooks
  class Example
    def execute
      encrypted = OpenSSL::Cipher.new('AES-256-CFB').tap do |cipher|
        cipher.encrypt
        cipher.key = ENV['SECRET_TOKEN']
      end.update('cache-bot')

      encoded   = Base64.encode64(encrypted)
      url       = ENV['DEPLOYHOOKS_HTTP_URL'] % encoded

      puts "Example URL: #{url.chomp}"
      puts "Test with: curl -d 'head=23xzh7&git_log=%23bust' #{url.chomp}"
    end
  end

  include Server, Speakable

  def execute 
     # Set up deploy hooks
    # List each app we are a collaborator on
    server.apps.each do |app|
      next if app.addons.include?('deployhooks:http') || app.config.keys.include?('DEPLOYHOOKS_HTTP_URL'

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
      server.post_addon(
        app.name,
        'deployhooks:http',
        url: url
      )

      speak("Set up CacheBot for #{app.name}")
      end
    end
  end
end
