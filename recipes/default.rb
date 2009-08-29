#
# Cookbook Name:: wordpress
# Recipe:: default
#
# Copyright 2009, Jim Van Fleet
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

include_recipe "apache2"
include_recipe "passenger_apache2::mod_rails"
include_recipe "database"

#sudo gem install rails -v2.3.2

gem_package "rails" do
  action :install
  version "2.3.2"
end

# We'd like to install the rest of the gems that spree
# needs, but not by re-enumerating them in this file.

execute "clone-spree" do
  command "git clone git://github.com/railsdog/spree.git"
  cwd "/tmp"
  not_if { File.exists?("/tmp/spree") }
end

execute "cp database.yml" do
  command "cp config/database.yml.example config/database.yml"
  cwd "/tmp/spree"
  not_if { File.exists?("/tmp/spree/config/database.yml") }
end

execute "gem install" do
  command "rake gems:install"
  cwd "/tmp/spree"
end

application_user = node[:railsapps][:spree][:app][:user]

%w{mysql}.each do |gem_dep|
  gem_package gem_dep
end

database_request node[:railsapps][:spree][:db][:database] do
  username node[:railsapps][:spree][:db][:user]
  password node[:railsapps][:spree][:db][:password]
end

database_nodes = search(:node, "database_location:*")
Chef::Log.info "Inspecting #{database_nodes.size} nodes for database host information"
hashes = database_nodes.collect{ |rslt| rslt[:database][:location] }
results = hashes.uniq.reject{ |r| r.empty? }
Chef::Log.info "Found #{results.inspect}"
db_host = results.first


["#{node[:railsapps][:spree][:app][:log_dir]}",
 "#{node[:railsapps][:spree][:app][:path]}",
 "#{node[:railsapps][:spree][:app][:path]}/shared",
 "#{node[:railsapps][:spree][:app][:path]}/shared/config"].each do |dir_name|
   directory dir_name do
     owner application_user
     group node[:railsapps][:spree][:app][:group]
     mode 0775
   end
end

template "#{node[:railsapps][:spree][:app][:path]}/shared/config/database.yml" do
  source "database.yml.erb"
  owner    application_user
  group    node[:railsapps][:spree][:app][:group]
  variables :database => node[:railsapps][:spree][:db][:database], 
            :user => node[:railsapps][:spree][:db][:user],  
            :passwd => node[:railsapps][:spree][:db][:password],
            :host   => db_host || "localhost"  
  mode "0664"
end


r = gem_package "chef-deploy" do
  source "http://gems.engineyard.com"
  action :nothing
end
 
r.run_action(:install)
 
Gem.clear_paths
require "chef-deploy"

deploy node[:railsapps][:spree][:app][:path] do
  repo "git://github.com/railsdog/spree.git"
  branch "HEAD"
  user application_user
  group node[:railsapps][:spree][:app][:group]
  enable_submodules true
  migrate true
  migration_command "rake db:migrate"
  environment "production"
  shallow_clone true
  restart_command "touch tmp/restart.txt"
  action :deploy # or :rollback
end

web_app "spree" do
  docroot current_path
  server_name node[:railsapps][:spree][:host]
  log_dir node[:railsapps][:spree][:app][:log_dir]
  max_pool_size node[:railsapps][:spree][:app][:pool_size]
  rails_env "production"
  template "http.conf.erb"
end

apache_site "default" do
  enable false
end

