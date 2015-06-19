# encoding: utf-8


namespace :log do

  # Remote Tail log tool.
  desc <<-DESC
    Tails/follows a specified log file in the shared path or the production.log,
    if none is given.
    Press CTRL-C to stop following the file.

    Basic usage:
    > cap logs:tail
    To tail the production.log (choosen by the deployment environment name)

    Or:
    > cap logs:tail[access]
    To tail the access.log file (or anything specified between brackets)

    Remember that if you use zsh you'll need to format it with single quotes as:
    > cap 'logs:tail[logfile]'

  DESC
  task :tail, :file do |t, args|
    base_filename = args[:file] || fetch(:rails_env) || 'production'
    on roles(:app) do
      execute :tail, "-f -n60 #{shared_path}/log/#{base_filename}.log"
    end
  end
  # ---------------------------------------------------------------------------


  desc "Executes remotely a log_rotate backup task + db:session:clear, storing log backups in the <release_num>.docs directory."
  task :rotate do
    on roles(:app) do |host|
      within release_path do
        rake "RAILS_ENV=production build:log_rotate db:sessions:clear"
      end
    end
  end
  # ---------------------------------------------------------------------------

end
