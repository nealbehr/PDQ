# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160321211202) do

  create_table "addresses", force: :cascade do |t|
    t.text "street"
    t.text "citystatezip"
  end

  create_table "censustracts", force: :cascade do |t|
    t.float  "home"
    t.float  "name"
    t.float  "area"
    t.float  "pop"
    t.float  "hu"
    t.float  "state"
    t.float  "lat"
    t.float  "lon"
    t.text   "stringname"
    t.string "geoid"
    t.float  "county"
    t.string "tractid"
  end

  create_table "neighbors", force: :cascade do |t|
    t.float "home"
    t.text  "neighbor"
  end

  create_table "outputs", force: :cascade do |t|
    t.text   "street"
    t.text   "citystatezip"
    t.float  "time"
    t.text   "zpid"
    t.text   "runid"
    t.string "names",        default: "--- []\n"
    t.string "numbers",      default: "--- []\n"
    t.string "passes",       default: "--- []\n"
    t.string "urls",         default: "--- []\n"
    t.string "reason",       default: "--- []\n"
    t.string "comments",     default: "--- []\n"
    t.string "usage",        default: "--- []\n"
    t.string "product"
    t.text   "date"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "admin",                  default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
