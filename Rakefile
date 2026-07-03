require "bundler/gem_tasks" rescue LoadError
require "rspec/core/rake_task" rescue LoadError
require "fileutils"

RsT = RSpec::Core::RakeTask.new(:spec) rescue nil

desc "Validate every dataset under datasets/"
task :validate do
  datasets = Dir["datasets/*"].select { |p| File.directory?(p) }
  abort "No datasets found under datasets/" if datasets.empty?

  datasets.each do |dataset|
    name = File.basename(dataset)
    puts "== Validating #{name} =="
    sh "glossarist validate #{dataset}"
  end
end

desc "Build GCR package for every dataset"
task :package, [:version] do |_t, args|
  version = args[:version] || "0.0.0-dev"
  Dir["datasets/*"].select { |p| File.directory?(p) }.each do |dataset|
    name = File.basename(dataset)
    puts "== Packaging #{name} =="
    sh "glossarist package #{dataset} -o #{name}-#{version}.gcr " \
       "--shortname #{name} --version #{version}"
  end
end

namespace :import do
  desc "Import E2 (ISO 14812:2025) from iso14812 git ref"
  task :e2 do
    sh "ruby scripts/import_iso14812.rb " \
       "--edition config/editions/isotc204-2025.yml " \
       "--previous config/editions/isotc204-2022.yml"
  end

  desc "Import E3 (draft) from iso14812 HEAD"
  task :e3 do
    sh "ruby scripts/import_iso14812.rb " \
       "--edition config/editions/isotc204-ed3.yml " \
       "--previous config/editions/isotc204-2025.yml"
  end
end

task default: %i[spec]
