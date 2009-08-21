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

application_user = node[:railsapps][:spree][:user]

%w{mysql}.each do |gem_dep|
  gem_package gem_dep
end

database_request node[:railsapps][:spree][:db][:database] do
  username node[:railsapps][:spree][:db][:user]
  password node[:railsapps][:spree][:db][:password]
end


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
  variables :name => node[:railsapps][:spree][:db][:database], 
            :passwd => node[:railsapps][:spree][:db][:password]
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

