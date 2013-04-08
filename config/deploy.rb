require "rvm/capistrano"
require "bundler/capistrano"
# Application name.

# Application name.
set :application, 'transcoder'

# Web server url.
set :location, 'raved.aws'



# Remote user name. Must be able to log in via SSH.
set :user, 'ec2-user'

# Local user name.
set :local_user, 'justin'

# Site path on web server
set :deploy_to, "/usr/share/nginx/ruby/apps/#{application}"

# - You shouldn't need to change anything below this line. -

# Remove or set the true if all commands should be run through sudo.
set :use_sudo, false

# Copy the files across as an archive rather than using Subversion on the remote machine.
set :deploy_via, :copy
set :copy_remote_dir, deploy_to

# Use local filesystem path as source.
set :repository, './'
set :scm, :none

default_run_options[:pty] = true


set :rvm_ruby_string, "ruby-1.9.3-p286"
set :bundle_cmd, "LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8' bundle"

role :app, location
role :web, location
role :db,  location, :primary => true

# Override default tasks which are not relevant to a non-rails app.

after "deploy", "deploy:setuplinks"







namespace :deploy do

  task :setuplinks do
    run "cd /usr/share/nginx/ruby/apps/transcoder/current; bundle install"
    run "unlink /usr/share/nginx/html/apps/spintally/current/transcoder"
    run "ln -s /usr/share/nginx/ruby/apps/transcoder/current/public /usr/share/nginx/html/apps/spintally/current/transcoder"
  end


  task(:migrate) { true }
  task(:finalize_update) { true }
  task(:start) { true }
  task(:stop) { true }
  task(:restart) { true }
end