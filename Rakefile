require 'base64'
require 'bundler'
require 'openssl'

Bundler.require

require './lib/speakable'
require './lib/server'

include Server, Speakable

require './commands/bust_cache'
require './commands/copy_production_buckets_to_development'
require './commands/create_collaborators'
require './commands/create_configurations'
require './commands/create_ping'
require './commands/dance'
require './commands/github_authorizor'
require './commands/stream'
require './commands/welcome'

desc 'Copy all production buckets to the development buckets each night'
task :copy_production_buckets_to_development do
  CopyProductionBucketsToDevelopment.new.execute
end

desc 'Add all collaborators on this app as collaborators on our other apps'
task :collaborators do
  CreateCollaborators.new.execute
end

desc 'Ensure these configurations are set up for all apps'
task :configurations do
  CreateConfigurations.new.execute
end

desc 'Watch Campfire for commands'
task :stream do
  Stream.new.execute
end

desc 'Ensure our demos builds are up to date. [Looks for collaborating apps starting with "demo-", e.g. "demo-third-prestige"]'
task :rebuild_demos_from_backups do
  DemoRebuilder.new.execute
end

desc 'Calculate an example URL hook for testing'
task example: :dependencies do
  CreateHooks::Example.new.execute
end

desc 'Ensure a web hook is set up for all collaborators'
task hooks: :dependencies do
  CreateHooks.new.execute
end

task :ping do
  CreatePing.new.execute
end
