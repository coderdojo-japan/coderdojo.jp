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

ActiveRecord::Schema.define(version: 20190602092528) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "dojo_event_services", id: :serial, force: :cascade do |t|
    t.integer "dojo_id", null: false
    t.integer "name", null: false
    t.string "url"
    t.string "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dojo_id"], name: "index_dojo_event_services_on_dojo_id"
  end

  create_table "dojos", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "order", default: "000000"
    t.string "description"
    t.string "logo", default: "/logo.png"
    t.string "url", default: "#"
    t.text "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prefecture_id"
    t.boolean "is_active", default: true, null: false
    t.boolean "is_private", default: false, null: false
  end

  create_table "event_histories", id: :serial, force: :cascade do |t|
    t.integer "dojo_id", null: false
    t.string "dojo_name", null: false
    t.string "service_name", null: false
    t.string "service_group_id"
    t.string "event_id", null: false
    t.string "event_url", null: false
    t.integer "participants", null: false
    t.datetime "evented_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dojo_id"], name: "index_event_histories_on_dojo_id"
    t.index ["evented_at", "dojo_id"], name: "index_event_histories_on_evented_at_and_dojo_id"
    t.index ["service_name", "event_id"], name: "index_event_histories_on_service_name_and_event_id", unique: true
  end

  create_table "prefectures", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.index ["name"], name: "index_prefectures_on_name", unique: true
    t.index ["region"], name: "index_prefectures_on_region"
  end

  create_table "soundcloud_tracks", force: :cascade do |t|
    t.integer "track_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "original_content_size", null: false
    t.string "duration", null: false
    t.string "tag_list"
    t.string "download_url", null: false
    t.string "permalink", null: false
    t.string "permalink_url", null: false
    t.datetime "uploaded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["track_id"], name: "index_soundcloud_tracks_on_track_id", unique: true
  end

  create_table "upcoming_events", force: :cascade do |t|
    t.integer "dojo_event_service_id", null: false
    t.string "event_id", null: false
    t.string "event_url", null: false
    t.datetime "event_at", null: false
    t.string "service_name", null: false
    t.integer "participants", null: false
    t.string "event_title", null: false
    t.index ["dojo_event_service_id"], name: "index_upcoming_events_on_dojo_event_service_id"
    t.index ["service_name", "event_id"], name: "index_upcoming_events_on_service_name_and_event_id", unique: true
  end

  add_foreign_key "dojo_event_services", "dojos"
  add_foreign_key "event_histories", "dojos"
end
