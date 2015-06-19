# encoding: utf-8

require 'pp'


namespace :utils do
  desc "Checks if we can access the deployment directory as the deploy user."
  task :check_write_permissions do
    on roles(:app, :web) do |host|
      as user: fetch(:deploy_user) do
        if test("[ -d #{fetch(:deploy_to)} ]")
          info "The directory #{fetch(:deploy_to)} exists!"
          if test("[ -w #{fetch(:deploy_to)} ]")
            info "#{fetch(:deploy_to)} is writable on #{host}"
          else
            error "#{fetch(:deploy_to)} is not writable on #{host}"
          end
        else
          error "Directory #{fetch(:deploy_to)} does not exist on #{host}. Creating it..."
          as( user: :root ) do
            execute :mkdir, fetch(:deploy_to)
          end
        end
      end
    end
  end
  # ---------------------------------------------------------------------------


  desc "Checks if agent forwarding is working."
  task :forwarding do
    on roles(:all) do |h|
      if test("env | grep SSH_AUTH_SOCK")
        info "Agent forwarding is up to #{h}"
      else
        error "Agent forwarding is NOT up to #{h}"
      end
    end
  end
  # ---------------------------------------------------------------------------



  desc "Dumps the current environment variables."
  task :env_dump do
    puts "\r\n---------------------8<------------------"
    puts "## Capistrano env ##"
    pp env
    puts "---------------------8<------------------"
    puts "## primary(:app) ##"
    pp primary(:app)
    puts "## primary(:web) ##"
    pp primary(:web)
    puts "## primary(:db) ##"
    pp primary(:db)
    puts "---------------------8<------------------"
    puts "- deploy_to:          #{deploy_to}"
    puts "- deploy_path:        #{deploy_path}"
    puts "- deploy_config_path: #{deploy_config_path}"
    puts "- stage_config_path:  #{stage_config_path}"
    puts "- release_path:       #{release_path}"
    puts "- current_path:       #{current_path}"
    puts "- shared_path:        #{shared_path}"
    puts "- repo_path:          #{repo_path}"
    puts "- repo_url:           #{repo_url}"
    puts "---------------------8<------------------\r\n"
  end
  # ---------------------------------------------------------------------------
end