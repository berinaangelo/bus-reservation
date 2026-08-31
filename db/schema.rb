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

ActiveRecord::Schema[8.1].define(version: 2026_08_31_082012) do
  create_table "bookings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "checked_in_at"
    t.string "contact_number", null: false
    t.datetime "created_at", null: false
    t.string "idempotency_key", null: false
    t.string "reference_code", null: false
    t.integer "seat_count"
    t.integer "status", default: 0, null: false
    t.integer "total_amount", null: false
    t.bigint "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_bookings_on_idempotency_key", unique: true
    t.index ["reference_code"], name: "index_bookings_on_reference_code", unique: true
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["trip_id"], name: "index_bookings_on_trip_id"
  end

  create_table "bus_units", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "operator_id", null: false
    t.string "plate_number", null: false
    t.json "seat_layout"
    t.integer "total_seats", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_id"], name: "index_bus_units_on_operator_id"
    t.index ["plate_number"], name: "index_bus_units_on_plate_number", unique: true
    t.index ["type"], name: "index_bus_units_on_type"
  end

  create_table "fare_rules", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "base_fare", null: false
    t.integer "bus_class", null: false
    t.datetime "created_at", null: false
    t.date "effective_date", null: false
    t.bigint "route_id", null: false
    t.datetime "updated_at", null: false
    t.index ["route_id", "bus_class", "effective_date"], name: "index_fare_rules_on_route_class_and_date"
    t.index ["route_id"], name: "index_fare_rules_on_route_id"
  end

  create_table "operator_sessions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "operator_staff_id", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_staff_id"], name: "index_operator_sessions_on_operator_staff_id"
    t.index ["token_digest"], name: "index_operator_sessions_on_token_digest", unique: true
  end

  create_table "operator_staff", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "name", null: false
    t.bigint "operator_id", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_operator_staff_on_email", unique: true
    t.index ["operator_id"], name: "index_operator_staff_on_operator_id"
  end

  create_table "operators", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "contact_info"
    t.datetime "created_at", null: false
    t.string "franchise_number", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["franchise_number"], name: "index_operators_on_franchise_number", unique: true
  end

  create_table "passengers", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.string "full_name", null: false
    t.bigint "trip_seat_id"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_passengers_on_booking_id"
    t.index ["trip_seat_id"], name: "index_passengers_on_trip_seat_id", unique: true
  end

  create_table "password_reset_tokens", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "operator_staff_id", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["operator_staff_id"], name: "index_password_reset_tokens_on_operator_staff_id"
    t.index ["token_digest"], name: "index_password_reset_tokens_on_token_digest", unique: true
  end

  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "booking_id", null: false
    t.datetime "collected_at"
    t.datetime "created_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id", unique: true
  end

  create_table "routes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "destination_terminal_id", null: false
    t.decimal "distance_km", precision: 6, scale: 2
    t.integer "estimated_duration_minutes"
    t.bigint "operator_id", null: false
    t.bigint "origin_terminal_id", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_terminal_id"], name: "index_routes_on_destination_terminal_id"
    t.index ["operator_id", "origin_terminal_id", "destination_terminal_id"], name: "index_routes_on_operator_and_terminal_pair", unique: true
    t.index ["operator_id"], name: "index_routes_on_operator_id"
    t.index ["origin_terminal_id", "destination_terminal_id"], name: "index_routes_on_terminal_pair"
    t.index ["origin_terminal_id"], name: "index_routes_on_origin_terminal_id"
  end

  create_table "seats", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "bus_unit_id", null: false
    t.datetime "created_at", null: false
    t.integer "deck"
    t.string "seat_number", null: false
    t.integer "seat_type", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_unit_id", "seat_number"], name: "index_seats_on_bus_unit_id_and_seat_number", unique: true
    t.index ["bus_unit_id"], name: "index_seats_on_bus_unit_id"
  end

  create_table "system_settings", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["key"], name: "index_system_settings_on_key", unique: true
  end

  create_table "terminals", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "address"
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "province"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_terminals_on_name", unique: true
  end

  create_table "trip_seats", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "booking_id"
    t.datetime "created_at", null: false
    t.datetime "held_until"
    t.bigint "seat_id", null: false
    t.integer "status", default: 0, null: false
    t.bigint "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_trip_seats_on_booking_id"
    t.index ["seat_id"], name: "index_trip_seats_on_seat_id"
    t.index ["status", "held_until"], name: "index_trip_seats_on_status_and_held_until"
    t.index ["trip_id", "seat_id"], name: "index_trip_seats_on_trip_id_and_seat_id", unique: true
    t.index ["trip_id", "status"], name: "index_trip_seats_on_trip_id_and_status"
    t.index ["trip_id"], name: "index_trip_seats_on_trip_id"
  end

  create_table "trips", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "arrival_at", null: false
    t.bigint "bus_unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "departure_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "route_id", null: false
    t.integer "seats_available"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bus_unit_id"], name: "index_trips_on_bus_unit_id"
    t.index ["departure_at", "id"], name: "index_trips_on_departure_at_and_id"
    t.index ["route_id"], name: "index_trips_on_route_id"
    t.index ["status", "departure_at"], name: "index_trips_on_status_and_departure_at"
  end

  add_foreign_key "bookings", "trips"
  add_foreign_key "bus_units", "operators"
  add_foreign_key "fare_rules", "routes", on_delete: :cascade
  add_foreign_key "operator_sessions", "operator_staff", on_delete: :cascade
  add_foreign_key "operator_staff", "operators", on_delete: :cascade
  add_foreign_key "passengers", "bookings", on_delete: :cascade
  add_foreign_key "passengers", "trip_seats"
  add_foreign_key "password_reset_tokens", "operator_staff", on_delete: :cascade
  add_foreign_key "payments", "bookings", on_delete: :cascade
  add_foreign_key "routes", "operators"
  add_foreign_key "routes", "terminals", column: "destination_terminal_id"
  add_foreign_key "routes", "terminals", column: "origin_terminal_id"
  add_foreign_key "seats", "bus_units", on_delete: :cascade
  add_foreign_key "trip_seats", "bookings", on_delete: :nullify
  add_foreign_key "trip_seats", "seats"
  add_foreign_key "trip_seats", "trips", on_delete: :cascade
  add_foreign_key "trips", "bus_units"
  add_foreign_key "trips", "routes"
end
