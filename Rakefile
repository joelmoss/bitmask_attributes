# encoding: UTF-8
begin
  require 'bundler/setup'
  require 'appraisal'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
Bundler::GemHelper.install_tasks

require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end


#############################################################################
#
# Helper functions
#
#############################################################################

def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def version
  line = File.read("lib/#{name}/version.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end

def gem_file
  "#{name}-#{version}.gem"
end

require 'rdoc/task'
require 'sdoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = "#{name} #{version}"
  rdoc.options << '-f' << 'sdoc'
  rdoc.options << '-a'
  rdoc.options << '--markup' << 'tomdoc'
  rdoc.options << '-m' << 'README.rdoc'
  rdoc.rdoc_files.include('CHANGELOG*')
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


#############################################################################
#
# Changeling
#
#############################################################################

namespace :changeling do
  # desc "Bumps the version by a minor or patch version, depending on what was passed in."
  task :bump, :part do |t, args|
    unless `git branch` =~ /^\* master$/
      puts "You must be on the master branch to bump the version!"
      exit!
    end
    
    # Thanks, Jeweler!
    if BitmaskAttributes::VERSION  =~ /^(\d+)\.(\d+)\.(\d+)(?:\.(.*?))?$/
      major = $1.to_i
      minor = $2.to_i
      patch = $3.to_i
      
      if $4 =~ /([a-z]+)(\d+)?/i
        pre_name    = $1
        pre_version = ($2 || 0).to_i
      end
    else
      abort
    end
    
    case args[:part]
    when /minor/
      minor += 1
      patch = 0
    when /patch/
      patch += 1
    when /pre/
      pre_version += 1
      pre = "#{pre_name}#{pre_version}"
    else
      abort
    end

    version = [major, minor, patch, pre].compact.join('.')

    File.open(File.join("lib", name, "version.rb"), "w") do |f|
      f.write <<EOF
module BitmaskAttributes
  VERSION = "#{version}".freeze
end
EOF
    end
  end

  # desc "Writes out the new CHANGELOG and prepares the release"
  task :change do
    unless `git branch` =~ /^\* master$/
      puts "You must be on the master branch to update changelog!"
      exit!
    end
    
    load "lib/#{name}/version.rb"
    file    = "CHANGELOG.rdoc"
    old     = File.read(file)
    message = "Bumping to version #{version}"

    File.open(file, "w") do |f|
      f.write <<EOF
=== Version #{version} - #{Time.now}

#{`git log $(git tag | tail -1)..HEAD | git shortlog`.gsub /\s{6}/, "\n*"}
#{old}
EOF
    end

    Rake::Task['build'].invoke
    exec ["#{ENV["EDITOR"]} #{file}",
          "git commit -aqm '#{message}'",
          "git tag -a -m '#{message}' v#{version}",
          "git push origin master",
          "git push origin $(git tag | tail -1)",
          "gem push pkg/#{name}-#{version}.gem",
          "echo '\n\033[32mReleased v#{version} /' `git show-ref -s refs/heads/master` '.\033[0m\n'"].join(' && ')
  end

  desc "Bump by a minor version (1.2.3 => 1.3.0)"
  task :minor do |t|
    Rake::Task['changeling:bump'].invoke(t.name)
    Rake::Task['changeling:change'].invoke
  end

  desc "Bump by a patch version, (1.2.3 => 1.2.4)"
  task :patch do |t|
    Rake::Task['changeling:bump'].invoke(t.name)
    Rake::Task['changeling:change'].invoke
  end
  
  desc "Bump by a pre-release version, (1.0.0.pre1 => 1.0.0.pre2)"
  task :pre do |t|
    Rake::Task['changeling:bump'].invoke(t.name)
    Rake::Task['changeling:change'].invoke
  end
end