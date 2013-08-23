class CreateCollaborators
  include Server, Speakable

  def execute
    collaborators = Server::App.default.collaborators

    apps.each do |app|
      (collaborators - app.collaborators).each do |collaborator|
        speak "Adding #{collaborator} to #{app.name}"
        app.collaborate(collaborator)
      end
    end
  end
end

class HerokuCollaborator < Struct.new(:email)
  include Server, Speakable

  def execute
    if email.empty?
      speak("Please provide an email: `haml collaborate haml@thirdprestige.com`")
    else
      speak("Adding #{email} to apps:")
      apps.each do |app|
        begin
          app.collaborate(email)
          speak("Added #{email} to #{app.name}")
        rescue => e
          paste("Error adding #{email} to #{app.name}", e)
        end
      end
    end
  end
end
