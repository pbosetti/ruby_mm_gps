require "bundler/gem_tasks"
require "rake/extensiontask"

task :build => :compile

Rake::ExtensionTask.new("mm_gps") do |ext|
  ext.lib_dir = "lib/mm_gps"
end

task :default => [:clobber, :compile, :spec]
