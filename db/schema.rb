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

ActiveRecord::Schema[8.1].define(version: 2026_08_05_073407) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"

  create_table "dojo_event_services", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "dojo_id", null: false
    t.string "group_id"
    t.integer "name", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "url"
    t.index ["dojo_id"], name: "index_dojo_event_services_on_dojo_id"
  end

  create_table "dojos", id: :serial, force: :cascade do |t|
    t.integer "counter", default: 1, null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.string "email"
    t.string "global_club_id"
    t.datetime "inactivated_at"
    t.boolean "is_private", default: false, null: false
    t.string "logo", default: "/logo.png"
    t.string "name"
    t.text "note", default: "", null: false
    t.string "order", default: "000000"
    t.integer "prefecture_id"
    t.text "tags"
    t.datetime "updated_at", precision: nil, null: false
    t.string "url", default: "#"
    t.index ["global_club_id"], name: "index_dojos_on_global_club_id", unique: true
    t.index ["inactivated_at"], name: "index_dojos_on_inactivated_at"
  end

  create_table "event_histories", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "dojo_id", null: false
    t.string "dojo_name", null: false
    t.string "event_id", null: false
    t.string "event_url", null: false
    t.datetime "evented_at", precision: nil, null: false
    t.integer "participants", null: false
    t.string "service_group_id"
    t.string "service_name", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["dojo_id"], name: "index_event_histories_on_dojo_id"
    t.index ["evented_at", "dojo_id"], name: "index_event_histories_on_evented_at_and_dojo_id"
    t.index ["service_name", "event_id"], name: "index_event_histories_on_service_name_and_event_id", unique: true
  end

  create_table "news", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["url"], name: "index_news_on_url", unique: true
  end

  create_table "podcasts", force: :cascade do |t|
    t.integer "content_size", null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "description"
    t.string "duration", null: false
    t.string "enclosure_url", null: false
    t.string "permalink", null: false
    t.string "permalink_url", null: false
    t.date "published_date", null: false
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enclosure_url"], name: "index_podcasts_on_enclosure_url", unique: true
  end

  create_table "prefectures", force: :cascade do |t|
    t.string "name"
    t.string "region"
    t.index ["name"], name: "index_prefectures_on_name", unique: true
    t.index ["region"], name: "index_prefectures_on_region"
  end

  create_table "stretch3s", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "dojo_name", null: false
    t.string "email", null: false
    t.string "parent_name", null: false
    t.string "participant_name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "upcoming_events", force: :cascade do |t|
    t.string "address"
    t.integer "dojo_event_service_id", null: false
    t.datetime "event_at", precision: nil, null: false
    t.datetime "event_end_at", precision: nil, null: false
    t.string "event_id", null: false
    t.string "event_title", null: false
    t.datetime "event_update_at", precision: nil
    t.string "event_url", null: false
    t.integer "limit"
    t.integer "participants", null: false
    t.string "place"
    t.string "service_name", null: false
    t.index ["dojo_event_service_id"], name: "index_upcoming_events_on_dojo_event_service_id"
    t.index ["service_name", "event_id"], name: "index_upcoming_events_on_service_name_and_event_id", unique: true
  end

  add_foreign_key "dojo_event_services", "dojos"
  add_foreign_key "event_histories", "dojos"
end
