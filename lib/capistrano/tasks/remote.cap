# encoding: utf-8

# == Capistrano helper tasks ==
#
# - author: Steve A.
# - vers. : 4.00.649
#
# This requires Capistrano v. >= 3.1


namespace :remote do
  set :param_prompt, ask("\r\nEnter ALL parameters for the remote invocation (besides the command itself): ", nil)

  desc "Returns webserver uptime."
  task :uptime do
    on roles(:web) do |host|
      uptime = capture('uptime')
      info "Your webserver #{host} has uptime: #{uptime}"
    end
  end
  #-- -------------------------------------------------------------------------
  #++


  # Remote Rake invocation tool.
  desc <<-DESC
    Invokes any rake command inside the remote app server directory (for the current
    release). This will also ask directly on the command line which parameters must
    be passed to the remote rake command.

    Using 'RAILS_ENV=production' is not required anymore, since the production
    environment is enforced by default.
  DESC
  task :rake do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          rake "#{fetch(:param_prompt)}"
        end
      end
    end
  end


  # Remote Bundle invocation tool.
  desc <<-DESC
    Invokes bundler inside the remote app server directory (for the current
    release). This will also ask directly on the command line which parameters must
    be passed to the remote rake command.
    (For instance, something like  'exec rake assets:precompile' or 'install')
  DESC
  task :bundle do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          bundle "#{fetch(:param_prompt)}"
        end
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++


  # Remote Rake tmp:clear invocation.
  desc <<-DESC
    Invokes remotely rake tmp:clear on the production environment.
  DESC
  task :tmp_clear do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          rake "tmp:clear"
        end
      end
    end
  end


  # Remote Rake db:sessions:clear invocation.
  desc <<-DESC
    Invokes remotely rake db:sessions:clear on the production environment.
  DESC
  task :db_sessions_clear do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          rake "db:sessions:clear"
        end
      end
    end
  end


  # Remote Rake db:rebuild_from_dump invocation.
  desc <<-DESC
    Invokes remotely rake db:rebuild_from_dump on the production environment.
    (Rebuild:  from=production to=production)
  DESC
  task :db_rebuild_from_dump do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          rake "db:rebuild_from_dump from=production to=production"
        end
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++


  desc "Invokes rake 'build:maintenance mode=1' into the remote app server."
  task :maintenance_on do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          rake "build:maintenance mode=1"
        end
      end
    end
  end


  desc "Invokes rake 'build:maintenance mode=0' into the remote app server."
  task :maintenance_off do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          rake "build:maintenance mode=0"
        end
      end
    end
  end


  desc "Executes remotely an sql:dump backup, storing DB backups in the <release_num>.docs directory."
  task :sql_backup do
    on roles(:app) do |host|
      within release_path do
        with rails_env: :production do
          rake "sql:dump"
        end
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++


  desc "Invokes bundler+rake inside the remote app server directory to execute assets precompile."
  task :assets_precompile do
    on roles(:app) do
      within release_path do
        with rails_env: :production do
          bundle "exec rake assets:precompile"
        end
      end
    end
  end
  #-- -------------------------------------------------------------------------
  #++
end
