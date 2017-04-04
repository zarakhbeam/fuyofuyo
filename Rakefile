#!/usr/bin/env ruby
#encoding=utf-8
require './create-index.rb'
task :init do
    File.mkdir '_files'
    puts "Now you can put your files in files/ and run `rake gen'"
end

task :gen do
    FileUtils.remove_dir 'dist/files'
    Dir.mkdir 'dist/files'
    IndexCreator
        .from_loaders_at('loaders', url_root: 'dist/files')
        .create_index('../articles', 'dist/files')
end

task :server do
  system 'jekyll server'
end

task :r_publish => [:rebuild_gh_pages, :clean_generated_files, :gen, :commit_gh_pages] do
  system 'git push origin gh-pages'
  system 'git checkout master'
end

task :publish => [:gen] do
  system ['git add .',
          'git commit',
          'git checkout gh-pages',
          'git merge master',
          'git push origin gh-pages',
          'git checkout master',
        ].join('&&')
end

task :clean_generated_files do
  FileUtils.remove_dir 'dist/files'
end

task :rebuild_gh_pages do
  system 'git push origin --delete gh-pages'
  system 'git checkout -B gh-pages'
end

task :commit_gh_pages do
  system 'git add . && git commit -m "Auto commit"'
end
