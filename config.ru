require 'sinatra/base'
require 'redcarpet'
class MdRender < Redcarpet::Render::HTML

  def image(src, title, alt_text)
    url = src.start_with?('asserts/') ?
            A___SELF.as_assert(File.join(A___SELF.src_dir, src)) :
            src
    %Q{
    <a href="#{url}" target="_blank" class="center-block">
      <img
        class="img-responsive center-block"
        src=#{url}
        alt=#{alt_text}>
      #{title}</img>
    </a>}
  end
end

$root = '../articles/'

class App < Sinatra::Base
  set :public_folder, File.dirname(__FILE__)

  get '/' do
    send_file 'index.html'
  end

  get %r{/dist/files/?(?<path>.+)} do
    path = params['path']
    path.force_encoding 'utf-8'
    p path
    case path
    when /^(.*)index\.json$/
      rpath = $1
      entries = Dir.entries(File.join($root, rpath)) - %w{. .. asserts}
      files, dirs = entries.partition{|x| p File.file?(File.join($root, rpath, x))}
      files.select!{|x| /\.md$/ === x}
      files.sort!
      dirs.reject!{|x| x.start_with?(".") || x == 'asserts'}
      dirs.sort!
      {
        rpath: rpath,
        files: files.map{|f| 
          name = File.basename(f, '.*')
          {
            title: name,
            path: File.join('/', rpath, name+'.html')
          }
        },
        dirs: dirs.map{|f| 
          name = File.basename(f)
          {
            title: name,
            path: File.join('/', rpath, name)
          }
        },
      }.to_json
    when /^(.*\/asserts\/).+\.(png|jpg|gif|jpeg)$/
      send_file File.join($root, path)
    when /^(.+)\.html/
      render_markdown(File.read(File.join($root, $1+".md")))
    else
      halt 404
    end
  end
  
  def render_markdown(text)
    Redcarpet::Markdown
      .new(MdRender)
      .render(text
      .gsub(/^\s+/,'')
      .gsub(/\n+/m, "\n\n"))
  end
end

run App
