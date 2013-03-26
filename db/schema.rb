# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130214104422) do

  create_table "app_parameters", :force => true do |t|
    t.integer  "code",                                                          :default => 0,     :null => false
    t.integer  "lock_version",                                                  :default => 0
    t.datetime "created_on"
    t.datetime "updated_on",                                                                       :null => false
    t.string   "controller_name"
    t.string   "action_name"
    t.boolean  "is_a_post",                                                     :default => false, :null => false
    t.string   "confirmation_text"
    t.string   "a_string"
    t.boolean  "a_bool",                                                        :default => false, :null => false
    t.integer  "a_integer",         :limit => 8
    t.datetime "a_date"
    t.decimal  "a_decimal",                      :precision => 10, :scale => 2
    t.decimal  "a_decimal_2",                    :precision => 10, :scale => 2
    t.decimal  "a_decimal_3",                    :precision => 10, :scale => 2
    t.decimal  "a_decimal_4",                    :precision => 10, :scale => 2
    t.integer  "range_x",           :limit => 8
    t.integer  "range_y",           :limit => 8
    t.string   "a_name"
    t.string   "a_filename"
    t.string   "tooltip_text"
    t.integer  "view_height",                                                   :default => 0,     :null => false
    t.integer  "code_type_1",       :limit => 8
    t.integer  "code_type_2",       :limit => 8
    t.integer  "code_type_3",       :limit => 8
    t.integer  "code_type_4",       :limit => 8
    t.text     "free_text_1"
    t.text     "free_text_2"
    t.text     "free_text_3"
    t.text     "free_text_4"
    t.boolean  "free_bool_1"
    t.boolean  "free_bool_2"
    t.boolean  "free_bool_3"
    t.boolean  "free_bool_4"
    t.boolean  "free_bool_5"
    t.boolean  "free_bool_6"
    t.text     "description"
  end

  add_index "app_parameters", ["code"], :name => "code", :unique => true

  create_table "appointments", :force => true do |t|
    t.integer   "lock_version",                                                 :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                                                      :null => false
    t.datetime  "date_schedule",                                                                   :null => false
    t.integer   "patient_id",       :limit => 8,                                :default => 0,     :null => false
    t.decimal   "price",                         :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.string    "notes"
    t.boolean   "is_payed",                                                     :default => false, :null => false
    t.string    "additional_notes"
    t.integer   "receipt_id",       :limit => 8,                                :default => 0,     :null => false
  end

  add_index "appointments", ["date_schedule"], :name => "date_schedule"
  add_index "appointments", ["patient_id"], :name => "patient_id"
  add_index "appointments", ["receipt_id"], :name => "receipt_id"

  create_table "articles", :force => true do |t|
    t.integer   "lock_version",               :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                    :null => false
    t.string    "title",        :limit => 80,                    :null => false
    t.text      "entry_text",                                    :null => false
    t.integer   "user_id",      :limit => 8,                     :null => false
    t.boolean   "is_sticky",                  :default => false, :null => false
  end

  add_index "articles", ["title"], :name => "name"
  add_index "articles", ["user_id"], :name => "user_id"

  create_table "le_cities", :force => true do |t|
    t.integer   "lock_version",               :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                :null => false
    t.string    "name",         :limit => 40,                :null => false
    t.string    "zip",          :limit => 6
    t.string    "area",         :limit => 40,                :null => false
    t.string    "country",      :limit => 40,                :null => false
    t.string    "country_code", :limit => 4,                 :null => false
  end

  add_index "le_cities", ["name"], :name => "name"
  add_index "le_cities", ["zip"], :name => "zip"

  create_table "le_titles", :force => true do |t|
    t.integer   "lock_version",               :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                :null => false
    t.string    "name",         :limit => 20
    t.string    "description",  :limit => 80
  end

  add_index "le_titles", ["name"], :name => "name"

  create_table "le_users", :force => true do |t|
    t.integer   "lock_version",                       :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                            :null => false
    t.string    "name",                :limit => 20,  :default => "",    :null => false
    t.string    "description",         :limit => 80
    t.string    "hashed_pwd",          :limit => 128,                    :null => false
    t.string    "salt",                :limit => 128,                    :null => false
    t.boolean   "enable_delete",                      :default => false, :null => false
    t.boolean   "enable_edit",                        :default => false, :null => false
    t.boolean   "enable_setup",                       :default => false, :null => false
    t.boolean   "enable_blog",                        :default => false, :null => false
    t.integer   "authorization_level",                                   :null => false
    t.integer   "firm_id",             :limit => 8
  end

  add_index "le_users", ["name"], :name => "name"

  create_table "patients", :force => true do |t|
    t.integer   "lock_version",                                                             :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                                                                  :null => false
    t.integer   "le_title_id",                :limit => 8
    t.string    "name",                       :limit => 40,                                 :default => "",    :null => false
    t.string    "surname",                    :limit => 80,                                 :default => "",    :null => false
    t.string    "address"
    t.integer   "le_city_id",                 :limit => 8
    t.string    "tax_code",                   :limit => 18
    t.datetime  "date_birth"
    t.string    "phone_home",                 :limit => 40
    t.string    "phone_work",                 :limit => 40
    t.string    "phone_cell",                 :limit => 40
    t.string    "phone_fax",                  :limit => 40
    t.string    "e_mail",                     :limit => 100
    t.string    "notes"
    t.decimal   "default_invoice_price",                     :precision => 10, :scale => 2, :default => 65.0,  :null => false
    t.string    "default_invoice_text",       :limit => 120
    t.boolean   "specify_neurologic_checkup",                                               :default => false, :null => false
    t.integer   "appointment_freq",           :limit => 1,                                  :default => 0,     :null => false
    t.string    "preferred_days",                                                           :default => ""
    t.string    "preferred_times",                                                          :default => ""
    t.boolean   "is_suspended",                                                             :default => false, :null => false
    t.boolean   "is_a_firm",                                                                :default => false, :null => false
    t.boolean   "is_fiscal",                                                                :default => false, :null => false
  end

  add_index "patients", ["le_city_id"], :name => "le_city_id"
  add_index "patients", ["le_title_id"], :name => "le_title_id"
  add_index "patients", ["name", "surname"], :name => "name_surname"
  add_index "patients", ["surname", "name"], :name => "surname_name"

  create_table "receipts", :force => true do |t|
    t.integer  "lock_version",                                                       :default => 0
    t.datetime "created_on"
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "receipt_num",                                                        :default => 0,     :null => false
    t.datetime "date_receipt",                                                                          :null => false
    t.integer  "patient_id",           :limit => 8,                                  :default => 0,     :null => false
    t.decimal  "price",                               :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.string   "receipt_description",  :limit => 120
    t.string   "notes"
    t.boolean  "is_receipt_delivered",                                               :default => false, :null => false
    t.boolean  "is_payed",                                                           :default => false, :null => false
    t.string   "additional_notes"
  end

  add_index "receipts", ["date_receipt"], :name => "date_receipt"
  add_index "receipts", ["patient_id"], :name => "patient_id"
  add_index "receipts", ["receipt_num"], :name => "receipt_seq"

  create_table "schedules", :force => true do |t|
    t.integer   "lock_version",               :default => 0
    t.datetime  "created_on"
    t.timestamp "updated_on",                                    :null => false
    t.datetime  "date_schedule",                                 :null => false
    t.boolean   "must_insert",                :default => false, :null => false
    t.boolean   "must_move",                  :default => false, :null => false
    t.boolean   "must_call",                  :default => false, :null => false
    t.boolean   "is_done",                    :default => false, :null => false
    t.integer   "patient_id",    :limit => 8, :default => 0,     :null => false
    t.string    "notes"
  end

  add_index "schedules", ["date_schedule"], :name => "date_schedule"
  add_index "schedules", ["patient_id"], :name => "patient_id"

  create_table "sessions", :force => true do |t|
    t.integer  "lock_version", :default => 0
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_on"
    t.datetime "updated_on",                  :null => false
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

end
