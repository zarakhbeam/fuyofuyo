#!/usr/bin/env ruby
#encoding=utf-8
require 'find'
require 'json'
require 'fileutils'
class IndexCreator
    class Loader
        LoaderError = Class.new StandardError
        attr_reader :extnames, :src_dir
        def initialize(*extnames)
            @extnames = extnames
        end
        def transfer(src, dst, rpath, url_root)
            @assert_dir = File.join(File.dirname(dst), 'asserts')
            @assert_rpath = File.join(File.dirname(rpath), 'asserts')
            @url_root = url_root
            @src_dir = File.dirname(src)
            if @loader.nil?
                raise LoaderError.new "Loader is not initialized. @ #{src} -> #{dst}"
            else
                @loader.call(src, dst)
            end
        end
        def as_assert(path)
            begin
                FileUtils.copy path, File.join(@assert_dir, File.basename(path))
                File.join @url_root, @assert_rpath, File.basename(path)
            rescue Errno::ENOENT => e
                ''
            end
        end
        def on_ext(*extnames)
            @extnames.concat(
                extnames
                .map(&:to_s)
                .map{|x|
                    x.start_with?('.') ? x : '.'+x
                })
        end
        def for_each(&block)
            @loader = block
        end
    end
    def initialize(loaders, config={})
        @loader_dict = Hash.new
        @config = config
        loaders.each do |l|
            l.extnames.each do |e|
                raise Loader::LoaderError.new "Loader for #{e} overlapped." if @loader_dict.has_key? e
                @loader_dict[e] = l
            end
        end
    end
    def create_index(src, dst)
        src = File.realdirpath(src) if File.symlink?(src)
        dir_indices = {
            src => {
                :rpath => '',
                :dirs => [],
                :files => [],
            }
        }
        FileUtils.mkpath dst
        FileUtils.mkpath File.join dst, 'asserts'
        Find.find src do |f|
            rpath= f.sub(%r{^#{src}}, '')
            sdst = File.join dst, rpath
            ext  = File.extname f
            next if f == '.' or f == '..' or f == src
            if File.directory? f
                search_dirs << File.realdirpath(f) if File.symlink?(f)
                fn = sdst
                FileUtils.mkpath sdst
                bn = File.basename(sdst)
                if  bn == 'asserts' || bn.start_with?('.')
                    FileUtils.copy_entry f, sdst
                    Find.prune
                else
                    FileUtils.mkpath File.join(sdst, 'asserts')
                    dir_indices[File.dirname f][:dirs].push(
                        :title => File.basename(f),
                        :path => rpath
                    )
                    dir_indices[f] = {:rpath => rpath, :files=>[], :dirs=>[]}
                end
            else
                Find.prune if File.basename(f) == 'index.json'
                fn = File.join File.dirname(sdst), File.basename(sdst, '.*')+'.html'
                begin
                    FileUtils.touch(fn)
                rescue Errno::ENAMETOOLONG => e
                    dd = File.basename(sdst, '.*')
                    fn = File.join File.dirname(fn), dd.slice(0, dd.length/2) + '.html'
                end
                if @loader_dict.has_key?(ext) && !File.basename(sdst).start_with?('.')
                    @loader_dict[ext.downcase].transfer f, fn, fn.sub(%r{^#{dst}}, ''), @config[:url_root]
                else
                    next
                    fn = sdst
                    FileUtils.copy f, fn
                end
                dir_indices[File.dirname f][:files].push(
                    :title => File.basename(f, '.*'),
                    :path  => fn.sub(%r{^#{dst}}, '')
                )
            end
        end
        dir_indices.each_value do |data|
            File.write (File.join dst, data[:rpath], 'index.json'), data.to_json
        end
    end
    class << self
        def from_loaders_at(dir, config={})
            self.new Dir[File.join dir, '*.rb'].map{|f|
                l = Loader.new
                l.instance_eval File.read f
                l
            }, config
        end
    end
end
