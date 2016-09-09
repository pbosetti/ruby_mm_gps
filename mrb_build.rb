#!/usr/bin/env ruby
if __FILE__ == $PROGRAM_NAME
  require 'fileutils'
  FileUtils.mkdir_p 'tmp'
  unless File.exists?('tmp/mruby')
    system 'git clone --depth 1 https://github.com/mruby/mruby.git tmp/mruby'
  end
  exit system(%Q[cd tmp/mruby; MRUBY_CONFIG=#{File.expand_path __FILE__} ./minirake #{ARGV.join(' ')}])
end

conf = MRuby::Build.new do |conf|
  toolchain :clang
  conf.cc.defines = %w(MRUBY_ENGINE)
  conf.gembox 'default'
  conf.gem :github => 'pbosetti/mruby-emb-require', :branch => "master"
  conf.gem File.dirname(__FILE__)
end

this_gem = conf.gems.find {|n| n.name.match /mruby-mm-gps/}
this_gem.objs_dir = "ext/mm_gps"
this_gem.mrblib_dir = "lib"
