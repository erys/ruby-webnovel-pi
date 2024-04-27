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

ActiveRecord::Schema[7.0].define(version: 2024_04_27_223053) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authors", force: :cascade do |t|
    t.string "og_name", null: false
    t.string "tl_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "jjwxc_id"
    t.index ["jjwxc_id"], name: "index_authors_on_jjwxc_id", unique: true
    t.index ["og_name"], name: "index_authors_on_og_name", unique: true
  end

  create_table "books", force: :cascade do |t|
    t.string "og_title", null: false
    t.string "phonetic_title"
    t.string "tl_title", null: false
    t.integer "author_id", null: false
    t.string "og_source"
    t.string "og_source_link"
    t.string "tl_source"
    t.string "tl_source_link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "short_name"
    t.integer "jjwxc_id"
    t.string "translation_status", default: "In Progress"
    t.string "original_status", default: "Completed"
    t.integer "last_chapter"
    t.text "og_description"
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["short_name"], name: "index_books_on_short_name", unique: true
  end

  create_table "chapters", force: :cascade do |t|
    t.integer "ch_number"
    t.string "og_title"
    t.string "tl_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "book_id", null: false
    t.string "og_subtitle"
    t.string "tl_subtitle"
    t.index ["book_id", "ch_number"], name: "index_chapters_on_book_id_and_ch_number", unique: true
    t.index ["book_id"], name: "index_chapters_on_book_id"
  end

  create_table "character_occurrences", force: :cascade do |t|
    t.integer "character_id", null: false
    t.integer "book_id", null: false
    t.integer "occurrences"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_character_occurrences_on_book_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "character", limit: 1, null: false
    t.integer "global_occurrences"
    t.integer "master_freq", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "original_chapters", force: :cascade do |t|
    t.integer "ch_number", null: false
    t.bigint "book_id", null: false
    t.string "link"
    t.string "font_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "main_text"
    t.text "footnote"
    t.string "subtitle"
    t.string "substitutions", default: [], array: true
    t.index ["book_id"], name: "index_original_chapters_on_book_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "books", "authors"
  add_foreign_key "chapters", "books"
  add_foreign_key "character_occurrences", "books"
  add_foreign_key "character_occurrences", "characters"
  add_foreign_key "original_chapters", "books"
end
