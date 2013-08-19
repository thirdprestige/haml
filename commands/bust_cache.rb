class BustCache < Struct.new(:app_name)
  include Speakable
  
  def execute
    Server::App.new(app_name).bust!

    speak("http://th02.deviantart.net/fs70/PRE/i/2012/321/8/0/keep_calm_and_nuke_it_from_orbit_by_matthewwarlick-d5l9r4d.jpg")
  end
end
