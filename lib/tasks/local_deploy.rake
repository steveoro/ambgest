require 'date'
require 'rubygems'
require 'find'
require 'fileutils'

require 'rails/all'
require File.join( Rails.root.to_s, 'config/environment' )


# ###################################
# ## Local Deployment helper tasks ##
# ###################################
#
# FASAR Software 2007-2014
# ==> TO BE RakeD inside app root <==


# Script revision number
SCRIPT_VERSION = '4.09.20140331'

# Gives current application name
APP_NAME = Rails.root.to_s.split( File::SEPARATOR ).reverse[0]

MAX_BACKUP_KEPT = 30
DB_BACKUP_DIR = File.join( "#{Rails.root}.docs", 'backup.db' )
TAR_BACKUP_DIR = File.join( "#{Rails.root}.docs", 'backup.src' )
LOG_BACKUP_DIR = File.join( "#{Rails.root}.docs", 'backup.log' )

DB_SEED_DIR = File.join( Rails.root, 'db/seed' ) unless defined? DB_SEED_DIR
UPLOADS_DIR = File.join( Rails.root, 'public/uploads' ) unless defined? UPLOADS_DIR
# The following is used only for clearing temp file
ODT_OUTPUT_DIR = File.join( Rails.root, 'public/output' ) unless defined? ODT_OUTPUT_DIR

NEEDED_DIRS = [DB_BACKUP_DIR, DB_SEED_DIR, UPLOADS_DIR, TAR_BACKUP_DIR, LOG_BACKUP_DIR]

SHORT_AGEX_VERSION = AGEX_FRAMEWORK_VERSION.split(' ')[0]

puts "\r\nAdditional local-build/deploy helper tasks loaded."
puts "- Script version  : #{SCRIPT_VERSION}"



# Returns the full path of a directory with respect to current Application root dir, terminated
# with a trailing slash.
# Current working directory will also be set to Rails.root (application root dir) anyways.
#
def get_full_path( sub_path )
  File.join( Rails.root, sub_path )
end
# ---------------------------------------------------------------------------
# ===========================================================================


# Rotate backups inside a specific 'backup_folder' allowing only a maximum number of 'max_backups'
# and deleting in rotation the oldest ones.
#
def rotate_backups( backup_folder, max_backups )
    all_backups = Dir.glob(File.join(backup_folder, '*'), File::FNM_PATHNAME).sort.reverse
    unwanted_backups = all_backups[max_backups..-1] || []
                                                    # Remove the backups in excess:
    for unwanted_backup in unwanted_backups
      puts "Deleting older backup #{unwanted_backup} ..."
      FileUtils.rm( unwanted_backup )
    end
    puts "Removed #{unwanted_backups.length} backups, #{all_backups.length - unwanted_backups.length} backups available."
end
# ---------------------------------------------------------------------------
# ===========================================================================
# ===========================================================================


# [Steve, 20130808] The following will remove the task db:test:prepare
# to avoid having to wait each time a test is run for the db test to reset
# itself:
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
Rake.application.remove_task 'db:reset'
Rake.application.remove_task 'db:test:prepare'


namespace :db do

  namespace :test do 
    task :prepare do |t|
      # rewrite the task to not do anything you don't want
    end
  end
  # ---------------------------------------------------------------------------


  desc <<-DESC
  This is an override of the standard Rake db:reset task.
It actually DROPS the Database, recreates it using a mysql shell command.
  DESC
  task :reset do |t|
    puts "*** Task: Custom DB RESET ***"
    rails_config  = Rails.configuration             # Prepare & check configuration:
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']
                                                    # Display some info:
    puts "DB name:      #{db_name}"
    puts "DB user:      #{db_user}"
    puts "\r\nDropping DB..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pwd} --execute=\"drop database if exists #{db_name}\""
    puts "\r\nRecreating DB..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pwd} --execute=\"create database #{db_name}\""
  end
  # ---------------------------------------------------------------------------


  desc 'Recreates the DB(s) from scratch. Invokes db:reset + db:migrate + sql:exec + db:clone_to_test in one shot.'
  
  task :rebuild_from_scratch do
    puts "*** Task: Compound DB RESET + MIGRATE + SQL:EXEC ***"
    Rake::Task['db:reset'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['sql:exec'].invoke
    puts "Done."
  end
  # ---------------------------------------------------------------------------


  desc <<-DESC
  Clones the development or production database to the test database (according to
  Rails environment; default is obviously 'development').
  Assumes development db name ends in '_development' and production db name doesn't
  have any suffix.

  Options: [Rails.env=#{Rails.env}]

  DESC
  task :clone_to_test => ['utils:script_status', 'utils:chk_needed_dirs'] do
    puts "*** Task: Clone DB on TEST DB ***"
    if (Rails.env == 'test')
      puts "You must specify either 'development' or 'production'!"
      exit
    end
                                                    # Prepare & check configuration:
    rails_config  = Rails.configuration
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']
    output_folder = ENV.include?("output_dir") ? ENV["output_dir"] : DB_BACKUP_DIR
                                                    # Display some info:
    puts "DB name: #{db_name}"
    puts "DB user: #{db_user}"
    file_name = File.join( output_folder, "#{db_name}-clone.sql" )
    puts "\r\nDumping #{db_name} on #{file_name} ...\r\n"
    sh "mysqldump --host=#{db_host} -u #{db_user} -p#{db_pwd} --triggers --routines -i -e --no-autocommit --single-transaction #{db_name} > #{file_name}"
    base_db_name = db_name.split('_development')[0]
    puts "\r\nDropping Test DB '#{base_db_name}_test'..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pwd} --execute=\"drop database if exists #{base_db_name}_test\""
    puts "\r\nRecreating DB..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pwd} --execute=\"create database #{base_db_name}_test\""
    puts "\r\nExecuting '#{file_name}' on #{base_db_name}_test..."
    sh "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pwd} --database=#{base_db_name}_test --execute=\"\\. #{file_name}\""
    puts "Deleting dump file '#{file_name}'..."
    FileUtils.rm( file_name )

    puts "Clone on Test DB done.\r\n\r\n"
  end
  # ---------------------------------------------------------------------------

end
# =============================================================================
# =============================================================================



namespace :sql do

  desc <<-DESC
  Creates a bzipped MySQL dump of the whole DB or just of a few tables, rotating the backups.

Options: [db_version=<db_struct_version>] [bzip2=<1>|0]
         [output_dir=#{DB_BACKUP_DIR}] [max_backup_kept=#{MAX_BACKUP_KEPT}] [Rails.env=#{Rails.env}]
  DESC
  task :dump => ['utils:script_status', 'utils:chk_needed_dirs'] do
    puts "*** Task: SQL DB dump ***"
                                                    # Prepare & check configuration:
    rails_config  = Rails.configuration
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']

# TODO [FUTUREDEV] get current version from app_parameter table
    db_version    = ENV.include?("db_version") ? ENV['db_version'] + '.' + DateTime.now.strftime("%Y%m%d.%H%M") : 'backup' + '.' + DateTime.now.strftime("%Y%m%d.%H%M%S")
    max_backups   = ENV.include?("max_backup_kept") ? ENV["max_backup_kept"].to_i : MAX_BACKUP_KEPT
    backup_folder = ENV.include?("output_dir") ? ENV["output_dir"] : DB_BACKUP_DIR
                                                    # Compress output? (Default = yes)
    unless ( ENV.include?("bzip2") && (ENV["bzip2"].to_i < 1) )
      zip_pipe = ' | bzip2 -c'
      file_ext = '.sql.bz2'
    else
      zip_pipe = ''
      file_ext = '.sql'
    end
                                                    # Display some info:
    puts "DB name:          #{db_name}"
    puts "version code:     #{db_version}"
    puts "DB user:          #{db_user}"
    puts "extracted tables: " + ( ENV.include?("tables") ? tables : "(entire DB)" )
    file_name = File.join( backup_folder, ( ENV.include?("tables") ? "#{db_name}-update-tables#{file_ext}" : "#{db_name}-#{db_version}#{file_ext}" ) )
    puts "Creating #{file_name} ...\r\n"
    sh "mysqldump --host=#{db_host} -u #{db_user} -p#{db_pwd} --add-drop-database --add-drop-table --extended-insert --triggers --routines --comments -c -i --no-autocommit --single-transaction -B #{db_name} #{zip_pipe} > #{file_name}"

                                                    # Rotate the backups leaving only the newest ones:
    rotate_backups( backup_folder, max_backups )
    puts "Dump done.\r\n\r\n"
  end
  # ---------------------------------------------------------------------------


  desc <<-DESC
  Executes all the SQL scripts ('*.sql') found in a special directory (usually for data seed).
Allows also to clear the executed files afterwards.

Options: [exec_dir=#{DB_SEED_DIR}] [delete=1|<0>]

- 'exec_dir' is the path where the files are found
- 'delete' allows to kill the executed file after completion; defaults to '0' (false)

  DESC
  task :exec => ['utils:script_status', 'utils:chk_needed_dirs'] do
    puts "*** Task: SQL script execute ***"
                                                    # Prepare & check configuration:
    rails_config  = Rails.configuration
    db_name       = rails_config.database_configuration[Rails.env]['database']
    db_user       = rails_config.database_configuration[Rails.env]['username']
    db_pwd        = rails_config.database_configuration[Rails.env]['password']
    db_host       = rails_config.database_configuration[Rails.env]['host']
    exec_folder = ENV.include?("exec_dir") ? ENV["exec_dir"] : DB_SEED_DIR
                                                    # Display some info:
    puts "DB name:      #{db_name}"
    puts "DB user:      #{db_user}"

    if File.directory?( exec_folder )               # If directory exists, scan it and execute each SQL file found:
      puts "\r\n- Processing directory: '#{exec_folder}'..."
                                                    # For each file match in pathname recursively do "process file":
      Dir.glob( File.join(exec_folder, '*.sql'), File::FNM_PATHNAME ).sort.each do |subpathname|
        puts "executing '#{subpathname}'..."
        sh "mysql --host=#{db_host} --user=#{db_user} --password=#{db_pwd} --database=#{db_name} --execute=\"\\. #{subpathname}\""
        # TODO Eventually, capture output to a log file somewhere
                                                    # Kill the file if asked to do so:
        if ( ENV.include?("delete") && ENV.include?("delete") == '1' )
          puts "deleting '#{subpathname}'."
          FileUtils.rm( subpathname )
        end
      end
    else
      puts "Can't find directory '#{exec_folder}'! Nothing to do..."
    end

    puts "SQL script execute done.\r\n\r\n"
  end
  # ---------------------------------------------------------------------------
end
# =============================================================================
# =============================================================================



namespace :build do

  task :default => [:help]
  # ---------------------------------------------------------------------------

  desc 'Generic usage for the build tasks defined.'
  task :help => ['utils:script_status'] do
    Rake::Task['stats'].invoke
    puts "Subtasks defined for :build namespace:"
    puts "\t:log_rotate\tlog backup and rotation (uses output_dir)"
    puts "\t:tar\t\tapp tree tar backup (uses output_dir)"
    puts "\t:version\tinternal DB version update"
    puts "\t:news_log\tinternal DB blog entry update"
    puts "\t:local\t\tlocal build creation (uses output_dir)"
    puts ""
  end
  # ---------------------------------------------------------------------------


desc <<-DESC
Creates a new (bzipped) backup of each log file, truncating then the current ones
and clearing also the temp output dir.

    Options: [output_dir=#{LOG_BACKUP_DIR}] [max_backup_kept=#{MAX_BACKUP_KEPT}]
DESC
  task :log_rotate => ['utils:script_status', 'utils:chk_needed_dirs'] do
    puts "Saving backups of the current log files..."
                                                    # Prepare & check configuration:
    time_signature  = DateTime.now.strftime("%Y%m%d.%H%M%S")
    max_backups     = ENV.include?("max_backup_kept") ? ENV["max_backup_kept"].to_i : MAX_BACKUP_KEPT
    backup_folder   = ENV.include?("output_dir") ? ENV["output_dir"] : LOG_BACKUP_DIR
                                                    # Create a backup of each log:
    Dir.chdir( get_full_path('log') ) do |curr_path|
      for log_filename in Dir.glob(File.join("#{curr_path}",'*.log'), File::FNM_PATHNAME)
        puts "Processing #{log_filename}..."
        Dir.chdir( backup_folder )
        sh "tar --bzip2 -cf #{File.basename(log_filename, '.log') + time_signature + '.log.tar.bz2'} #{log_filename}"
      end
    end
    Dir.chdir( Rails.root.to_s )
    puts "Truncating all current log files..."
    Rake::Task['log:clear'].invoke
    Rake::Task['utils:clear_output'].invoke
                                                    # Rotate the backups leaving only the newest ones: (log files are 3-times normal backups)
    rotate_backups( backup_folder, max_backups * 3 )
    puts "Done.\r\n\r\n"
  end
  # ---------------------------------------------------------------------------


desc <<-DESC
Creates a tar(bz2) dump file for the whole subtree of the application.

    Options: [app_version=#{SHORT_AGEX_VERSION}] [output_dir=#{TAR_BACKUP_DIR}]
DESC
  task :tar => ['build:log_rotate'] do
    puts "*** Task: Tar BZip2 Application Backup ***"
                                                    # Prepare & check configuration:
    backup_folder = ENV.include?("output_dir") ? ENV["output_dir"] : TAR_BACKUP_DIR
    app_version   = ENV.include?("app_version") ?
                    ENV['app_version'] + '.' + Date.today.strftime("%Y%m%d") :
                    SHORT_AGEX_VERSION + '.' + DateTime.now.strftime("%Y%m%d.%H%M")
    file_name     = APP_NAME + '-' + app_version + '.tar.bz2'
    FileUtils.makedirs(backup_folder) if ENV.include?("output_dir") # make sure overridden output folder exists, creating the subtree under app's root

# TODO [FUTUREDEV] parametrize sessions cleanup
    Rake::Task['db:sessions:clear'].invoke
# TODO [FUTUREDEV] parametrize temp dir cleanup
    Rake::Task['tmp:clear'].invoke

    puts "Creating #{file_name} under #{backup_folder}."
    Dir.chdir( backup_folder )
    sh "tar --bzip2 -cf #{file_name} #{Rails.root}"
    Dir.chdir( Rails.root.to_s )

    puts "Done.\r\n"
  end
  # ---------------------------------------------------------------------------


desc <<-DESC
Updates the current versioning numbers inside DB table app_parameters.

    Options: [app_version=#{SHORT_AGEX_VERSION}] [db_version=<db_struct_version>]
             [Rails.env=#{Rails.env}]
DESC
  task :version => [:environment, 'utils:script_status'] do
    puts "Updating current version number..."
                                                    # Prepare & check configuration:
    time_signature = Date.today.strftime("%Y%m%d")
    db_version    = ENV.include?("db_version") ? ENV['db_version'] + '.' + time_signature : nil
    app_version   = ENV.include?("app_version") ?
                    ENV['app_version'] + '.' + time_signature : SHORT_AGEX_VERSION
                                                    # Update DB struct versioning number inside table app_parameter:
    ap = AppParameter.find(:first, :conditions => "code=1")
    unless ap.nil? || ap == []
      ap.update_attribute( :a_string, db_version ) unless db_version.nil?
      ap.update_attribute( :a_name, app_version )
    else
      raise "\r\nError: AppParameter row with code==1 is missing from the DB!"
    end
    puts "Base Versioning update: done."
  end
  # ---------------------------------------------------------------------------


desc <<-DESC
Updates the News log table with an entry stating that the application has been updated.

    Options: [app_version=#{SHORT_AGEX_VERSION}] [db_version=<db_struct_version>]
             [Rails.env=#{Rails.env}]
DESC
  task :news_log => ['build:version'] do
                                                    # Prepare & check configuration:
    time_signature = Date.today.strftime("%Y%m%d")
    db_version    = ENV.include?("db_version") ? ENV['db_version'] + '.' + time_signature : nil
    app_version   = ENV.include?("app_version") ? ENV['app_version'] + '.' + time_signature : SHORT_AGEX_VERSION

# TODO [FUTUREDEV] include LeUser default id search
    puts "Logging the update into the news blog..."
    Article.create({
      :title => "Aggiornamento dell'applicazione",
# TODO [FUTUREDEV] Localize this
      :entry_text => "L'applicazione e' stata aggiornata e portata alla versione " + app_version +
                     (db_version.nil? ? "" : ". La struttura del DB e' stata portata alla versione " + db_version) + ".",
      :user_id => 1                                 # default user id (must be not null)
    })
    puts "NewsLog update: done."
  end
  # ----------------------------------------------------------------------------


desc <<-DESC
Creates a local build (with release info, backup and current DB dump).

This complex task updates the internal versioning number for the DB and the
application framework, then saves the log files, updates and dumps the DB (in
case of a new version) and, finally, stores the local build inside a backup
tar file.

    Options: app_version=<application_version> [db_version=<db_struct_version>]
             [Rails.env=#{Rails.env}]
DESC
  task :local => ['build:news_log','build:tar','sql:dump'] do
    puts "BUILD: LOCAL: done."
  end
  # ----------------------------------------------------------------------------
end
# ==============================================================================



namespace :utils do

  desc "Outputs current script version and working status"
  task(:script_status) do
    puts "\r\n===  local_deploy.rake script - vers. #{SCRIPT_VERSION}  ==="
    puts "Written by Stefano Alloro, FASAR Software 2007-2013\r\n\r\n"
    puts 'Application: ' + APP_NAME if defined? APP_NAME
    puts 'Evironment:  ' + Rails.env
    puts 'Working in:  ' + Dir.pwd
    puts "\r\n- Framework app.  : #{AGEX_APP}"
    puts "- Framework vers. : #{SHORT_AGEX_VERSION}"
    puts "- MAX_BACKUP_KEPT : #{MAX_BACKUP_KEPT}"
    puts "- DB_BACKUP_DIR   : #{DB_BACKUP_DIR}"
    puts "- TAR_BACKUP_DIR  : #{TAR_BACKUP_DIR}"
    puts "- LOG_BACKUP_DIR  : #{LOG_BACKUP_DIR}"
    puts "- ODT_OUTPUT_DIR  : #{ODT_OUTPUT_DIR}"
    puts "- UPLOADS_DIR     : #{UPLOADS_DIR}"
    puts "- DB_SEED_DIR     : #{DB_SEED_DIR}"
    
    puts ""
  end
  # ----------------------------------------------------------------------------


  desc "Check and creates missing needed directories"
  task(:chk_needed_dirs) do                         # Check the needed folders & create if missing:
    for folder in NEEDED_DIRS
      puts "Checking existance of #{folder}..."
      FileUtils.mkdir_p(folder)
    end
    puts "\r\n"
  end
  # ----------------------------------------------------------------------------


  desc "Clears the app 'output' directory (if existing) contained inside /public."
  task(:clear_output) do
    if File.directory?(ODT_OUTPUT_DIR)              # Output Directory found existing?
      puts "Clearing temp output directory..."
      FileUtils.rm( Dir.glob("#{ODT_OUTPUT_DIR}/*") )
    else                                            # Processing a file?
      puts "Temp output directory not found, nothing to do."
    end
    puts 'Done.'
  end


  desc "Clears the app 'uploads' directory (if existing) contained inside /public."
  task(:clear_uploads) do
    if File.directory?(UPLOADS_DIR)                 # Uploads Directory found existing?
      puts "Clearing temp uploads directory..."
      FileUtils.rm( Dir.glob("#{UPLOADS_DIR}/*") )
    else                                            # Processing a file?
      puts "Temp uploads directory not found, nothing to do."
    end
    puts 'Done.'
  end
  # ----------------------------------------------------------------------------
end
# ==============================================================================
