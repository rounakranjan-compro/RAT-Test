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

ActiveRecord::Schema.define(version: 2026_06_02_042859) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artifacts", force: :cascade do |t|
    t.bigint "test_run_id", null: false
    t.string "kind"
    t.jsonb "metadata"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "file_url"
    t.index ["test_run_id"], name: "index_artifacts_on_test_run_id"
  end

  create_table "features", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_features_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "revoked_tokens", force: :cascade do |t|
    t.string "jti"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "exp"
    t.index ["jti"], name: "index_revoked_tokens_on_jti", unique: true
  end

  create_table "scripts", force: :cascade do |t|
    t.string "name"
    t.text "raw_content"
    t.text "normalized_content"
    t.string "language"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "test_runs", force: :cascade do |t|
    t.bigint "test_id", null: false
    t.string "status", default: "not_run"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "script_id"
    t.string "environment", null: false
    t.string "runner_mode", default: "headless", null: false
    t.integer "retries_on_failure", default: 0, null: false
    t.text "tags"
    t.string "vnc_url"
    t.index ["script_id"], name: "index_test_runs_on_script_id"
    t.index ["test_id"], name: "index_test_runs_on_test_id"
  end

  create_table "tests", force: :cascade do |t|
    t.string "title"
    t.bigint "script_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "vnc_url"
    t.bigint "user_id", null: false
    t.bigint "feature_id"
    t.string "tags"
    t.integer "retries_on_failure"
    t.string "runner_mode"
    t.string "environment"
    t.index ["feature_id"], name: "index_tests_on_feature_id"
    t.index ["script_id"], name: "index_tests_on_script_id"
    t.index ["user_id"], name: "index_tests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_id"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "provider"
    t.string "uid"
    t.index ["email_id"], name: "index_users_on_email_id", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "artifacts", "test_runs"
  add_foreign_key "features", "users"
  add_foreign_key "test_runs", "scripts"
  add_foreign_key "test_runs", "tests"
  add_foreign_key "tests", "features"
  add_foreign_key "tests", "scripts"
  add_foreign_key "tests", "users"
end
