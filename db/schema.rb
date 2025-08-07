# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_07_140750) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "options", force: :cascade do |t|
    t.string "text", null: false
    t.bigint "poll_id", null: false
    t.integer "votes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id"], name: "index_options_on_poll_id"
  end

  create_table "polls", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "user_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_polls_on_active"
    t.index ["expires_at"], name: "index_polls_on_expires_at"
    t.index ["user_id"], name: "index_polls_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "option_id", null: false
    t.bigint "poll_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_id"], name: "index_votes_on_option_id"
    t.index ["poll_id"], name: "index_votes_on_poll_id"
    t.index ["user_id", "poll_id"], name: "index_votes_on_user_and_poll", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "options", "polls"
  add_foreign_key "polls", "users"
  add_foreign_key "votes", "options"
  add_foreign_key "votes", "polls"
  add_foreign_key "votes", "users"
end
