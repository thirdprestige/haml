require 'heroku/client/pgbackups' 

class DemoRebuilder
  include Server, Speakable

  def execute
    server.apps.each do |app|
      next unless app.demo?

      # Two-step process
      # * Restore the latest non-automated backup (one that we captured manually)
      # * Bust the cache by updating the RAILS_CACHE_ID
       
      latest_non_automated_backup = app.backups.get_backups.find do |backup|
        backup['to_url'] =~ /\/b[0-9]+.dump/
      end

      app.backups.create_transfer(
        latest_non_automated_backup['to_url'], 
        'BACKUP', 
        app.config['DATABASE_URL'], 
        'RESTORE'
      )

      app.bust!
    end
  end
end 