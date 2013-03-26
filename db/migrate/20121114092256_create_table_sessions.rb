class CreateTableSessions < ActiveRecord::Migration
  def change
    create_table "sessions" do |t|
      t.integer   "lock_version", :default => 0
      t.string    "session_id"
      t.text      "data"
      t.datetime  "created_on"
      t.timestamp "updated_on",                  :null => false
    end

    add_index "sessions", ["session_id"], :name => "sessions_session_id_index"
  end
end
