# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


task 'doc:setup'
begin # For the Web site, we use the SDoc RDoc generator/theme (http://github.com/voloko/sdoc/)
  require 'sdoc'
rescue LoadError
  puts "Buildr uses the SDoc RDoc generator/theme. You can install it by running rake doc:setup"
  task('doc:setup') { install_gem 'voloko-sdoc', :source=>'http://gems.github.com' }
end


require 'rake/rdoctask'

desc "Creates a symlink to rake's lib directory to support combined rdoc generation"
file "rake/lib" do
  rake_path = $LOAD_PATH.find { |p| File.exist? File.join(p, "rake.rb") }
  mkdir_p "rake"
  File.symlink(rake_path, "rake/lib")
end

desc "Generate RDoc documentation in rdoc/"
Rake::RDocTask.new :rdoc do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = spec.name
  rdoc.options  = spec.rdoc_options.clone
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.include spec.extra_rdoc_files

  # include rake source for better inheritance rdoc
  rdoc.rdoc_files.include('rake/lib/**.rb')
end
task :rdoc => ["rake/lib"]

begin
  require 'jekylltask'
  module TocFilter
    def toc(input)
      output = "<ol class=\"toc\">"
      input.scan(/<(h2)(?:>|\s+(.*?)>)([^<]*)<\/\1\s*>/mi).each do |entry|
        id = (entry[1][/^id=(['"])(.*)\1$/, 2] rescue nil)
        title = entry[2].gsub(/<(\w*).*?>(.*?)<\/\1\s*>/m, '\2').strip
        if id
          output << %{<li><a href="##{id}">#{title}</a></li>}
        else
          output << %{<li>#{title}</li>}
        end
      end
      output << "</ol>"
      output
    end
  end
  Liquid::Template.register_filter(TocFilter)

  desc "Generate Buildr documentation in _site/"
  JekyllTask.new :jekyll do |task|
    task.source = 'doc'
    task.target = '_site'
  end

rescue LoadError
  puts "Buildr uses the jekyll gem to generate the Web site. You can install it by running rake doc:setup"
  task 'doc:setup' do
    install_gem 'jekyll', :version=>'0.6.2'
    install_gem 'jekylltask', :version=>'1.0.2'
    if `pygmentize -V`.empty?
      args = %w{easy_install Pygments}
      args.unshift 'sudo' unless Config::CONFIG['host_os'] =~ /windows/
      sh *args
    end
  end
end


desc "Generate Buildr documentation as buildr.pdf"
file 'buildr.pdf'=>'_site' do |task|
  pages = File.read('_site/preface.html').scan(/<li><a href=['"]([^'"]+)/).flatten.map { |f| "_site/#{f}" }
  sh 'prince', '--input=html', '--no-network', '--log=prince_errors.log', "--output=#{task.name}", '_site/preface.html', *pages
end

desc "Build a copy of the Web site in the ./_site"
task :site=>['_site', :rdoc, '_reports/specs.html', '_reports/coverage', 'buildr.pdf'] do
  cp_r 'rdoc', '_site'
  fail 'No RDocs in site directory' unless File.exist?('_site/rdoc/files/lib/buildr_rb.html')
  cp '_reports/specs.html', '_site'
  cp_r '_reports/coverage', '_site'
  fail 'No coverage report in site directory' unless File.exist?('_site/coverage/index.html')
  cp 'CHANGELOG', '_site'
  open("_site/.htaccess", "w") do |htaccess|
    htaccess << %Q{
<FilesMatch "CHANGELOG">
ForceType 'text/plain; charset=UTF-8'
</FilesMatch>
}
  end
  cp 'buildr.pdf', '_site'
  fail 'No PDF in site directory' unless File.exist?('_site/buildr.pdf')
  puts 'OK'
end

# Publish prerequisites to Web site.
task 'publish'=>:site do
  target = "people.apache.org:/www/#{spec.name}.apache.org/"
  puts "Uploading new site to #{target} ..."
  sh 'rsync', '--progress', '--recursive', '--delete', '_site/', target
  sh 'ssh', 'people.apache.org', 'chmod', '-R', 'g+w', "/www/#{spec.name}.apache.org/*"
  puts "Done"
end

task :clobber do
  rm_rf '_site'
  rm_f 'buildr.pdf'
  rm_f 'prince_errors.log'
end
