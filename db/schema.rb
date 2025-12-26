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

ActiveRecord::Schema[7.1].define(version: 2025_12_26_200430) do
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

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tenant_id", null: false
    t.string "action", null: false
    t.string "auditable_type"
    t.integer "auditable_id"
    t.text "changed_data"
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["tenant_id", "created_at"], name: "index_audit_logs_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "communications", force: :cascade do |t|
    t.string "communicable_type", null: false
    t.bigint "communicable_id", null: false
    t.bigint "tenant_id", null: false
    t.integer "communication_type", null: false
    t.string "subject"
    t.text "content"
    t.bigint "created_by_user_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["communicable_type", "communicable_id"], name: "index_communications_on_communicable"
    t.index ["created_by_user_id"], name: "index_communications_on_created_by_user_id"
    t.index ["tenant_id", "communicable_type", "communicable_id"], name: "index_communications_on_tenant_and_communicable"
    t.index ["tenant_id", "communication_type"], name: "index_communications_on_tenant_and_type"
    t.index ["tenant_id", "created_at"], name: "index_communications_on_tenant_and_created_at"
    t.index ["tenant_id"], name: "index_communications_on_tenant_id"
  end

  create_table "company_settings", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "company_name"
    t.text "address"
    t.string "email"
    t.string "phone"
    t.string "iban"
    t.string "company_tagline", default: "3K - Soluções Gráficas, uma empresa do grupo ITTECH"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "phones", default: []
    t.jsonb "emails", default: []
    t.jsonb "ibans", default: []
    t.jsonb "bank_accounts", default: []
    t.string "director_general_email"
    t.string "financial_director_email"
    t.decimal "default_profit_margin", precision: 5, scale: 2, default: "65.0", null: false
    t.index ["tenant_id"], name: "index_company_settings_on_tenant_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "contactable_type", null: false
    t.bigint "contactable_id", null: false
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "whatsapp"
    t.string "position"
    t.string "department"
    t.boolean "primary", default: false, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contactable_type", "contactable_id"], name: "index_contacts_on_contactable"
    t.index ["tenant_id", "contactable_type", "contactable_id"], name: "index_contacts_on_tenant_and_contactable"
    t.index ["tenant_id", "primary"], name: "index_contacts_on_tenant_and_primary"
    t.index ["tenant_id"], name: "index_contacts_on_tenant_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.string "customer_type"
    t.string "tax_id"
    t.string "phone"
    t.string "whatsapp"
    t.string "email"
    t.text "address"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["tenant_id", "customer_type"], name: "index_customers_on_tenant_and_type"
    t.index ["tenant_id"], name: "index_customers_on_tenant_id"
  end

  create_table "daily_revenues", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.date "date"
    t.string "description"
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "entry"
    t.decimal "exit"
    t.decimal "total"
    t.integer "payment_type"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_daily_revenues_on_tenant_id"
  end

  create_table "estimate_items", force: :cascade do |t|
    t.bigint "estimate_id", null: false
    t.bigint "product_id", null: false
    t.string "description"
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "subtotal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["estimate_id"], name: "index_estimate_items_on_estimate_id"
    t.index ["product_id"], name: "index_estimate_items_on_product_id"
    t.index ["tenant_id"], name: "index_estimate_items_on_tenant_id"
  end

  create_table "estimates", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "estimate_number"
    t.string "status"
    t.date "valid_until"
    t.decimal "total_value", precision: 10, scale: 2
    t.bigint "created_by_user_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "approved_by"
    t.datetime "approved_at"
    t.bigint "tenant_id"
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.text "discount_justification"
    t.decimal "subtotal_before_discount", precision: 10, scale: 2
    t.boolean "below_margin_warned", default: false
    t.datetime "below_margin_warned_at"
    t.index ["below_margin_warned"], name: "index_estimates_on_below_margin_warned"
    t.index ["created_by_user_id"], name: "index_estimates_on_created_by_user_id"
    t.index ["customer_id"], name: "index_estimates_on_customer_id"
    t.index ["estimate_number"], name: "index_estimates_on_estimate_number", unique: true
    t.index ["status"], name: "index_estimates_on_status"
    t.index ["tenant_id", "below_margin_warned"], name: "index_estimates_on_tenant_id_and_below_margin_warned"
    t.index ["tenant_id", "status"], name: "index_estimates_on_tenant_and_status"
    t.index ["tenant_id"], name: "index_estimates_on_tenant_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "product_name"
    t.string "supplier_phone"
    t.decimal "gross_quantity"
    t.decimal "net_quantity"
    t.decimal "purchase_price"
    t.integer "minimum_stock"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_inventory_items_on_tenant_id"
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "inventory_item_id", null: false
    t.integer "movement_type"
    t.decimal "quantity"
    t.date "date"
    t.text "notes"
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_inventory_movements_on_created_by_user_id"
    t.index ["inventory_item_id"], name: "index_inventory_movements_on_inventory_item_id"
    t.index ["tenant_id"], name: "index_inventory_movements_on_tenant_id"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description"
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "subtotal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id"
    t.bigint "tenant_id"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["tenant_id"], name: "index_invoice_items_on_tenant_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number"
    t.bigint "customer_id", null: false
    t.string "invoice_type"
    t.string "source_type"
    t.integer "source_id"
    t.decimal "total_value", precision: 10, scale: 2
    t.decimal "paid_value", precision: 10, scale: 2, default: "0.0"
    t.string "status", default: "pendente"
    t.date "payment_date"
    t.string "payment_method"
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "invoice_date"
    t.date "due_date"
    t.bigint "tenant_id"
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.text "discount_justification"
    t.decimal "subtotal_before_discount", precision: 10, scale: 2
    t.boolean "below_margin_warned", default: false
    t.datetime "below_margin_warned_at"
    t.index ["below_margin_warned"], name: "index_invoices_on_below_margin_warned"
    t.index ["created_by_user_id"], name: "index_invoices_on_created_by_user_id"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["source_type", "source_id"], name: "index_invoices_on_source_type_and_source_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["tenant_id", "below_margin_warned"], name: "index_invoices_on_tenant_id_and_below_margin_warned"
    t.index ["tenant_id", "status"], name: "index_invoices_on_tenant_and_status"
    t.index ["tenant_id"], name: "index_invoices_on_tenant_id"
  end

  create_table "job_files", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "file_path"
    t.string "file_type"
    t.bigint "uploaded_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["job_id"], name: "index_job_files_on_job_id"
    t.index ["tenant_id"], name: "index_job_files_on_tenant_id"
    t.index ["uploaded_by_user_id"], name: "index_job_files_on_uploaded_by_user_id"
  end

  create_table "job_items", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "subtotal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["job_id"], name: "index_job_items_on_job_id"
    t.index ["product_id"], name: "index_job_items_on_product_id"
    t.index ["tenant_id"], name: "index_job_items_on_tenant_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "job_number"
    t.bigint "customer_id", null: false
    t.bigint "source_estimate_id"
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "novo"
    t.string "priority", default: "normal"
    t.date "delivery_date"
    t.decimal "total_value", precision: 10, scale: 2
    t.decimal "advance_paid", precision: 10, scale: 2, default: "0.0"
    t.decimal "balance", precision: 10, scale: 2
    t.bigint "created_by_user_id"
    t.text "production_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["created_by_user_id"], name: "index_jobs_on_created_by_user_id"
    t.index ["customer_id"], name: "index_jobs_on_customer_id"
    t.index ["delivery_date"], name: "index_jobs_on_delivery_date"
    t.index ["job_number"], name: "index_jobs_on_job_number", unique: true
    t.index ["priority"], name: "index_jobs_on_priority"
    t.index ["source_estimate_id"], name: "index_jobs_on_source_estimate_id"
    t.index ["status"], name: "index_jobs_on_status"
    t.index ["tenant_id", "status"], name: "index_jobs_on_tenant_and_status"
    t.index ["tenant_id"], name: "index_jobs_on_tenant_id"
  end

  create_table "lan_machines", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.decimal "hourly_rate"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["tenant_id"], name: "index_lan_machines_on_tenant_id"
  end

  create_table "lan_sessions", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "lan_machine_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status", default: "aberta"
    t.string "billing_type"
    t.integer "package_minutes"
    t.integer "total_minutes"
    t.decimal "total_value", precision: 10, scale: 2
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["created_by_user_id"], name: "index_lan_sessions_on_created_by_user_id"
    t.index ["customer_id"], name: "index_lan_sessions_on_customer_id"
    t.index ["lan_machine_id"], name: "index_lan_sessions_on_lan_machine_id"
    t.index ["start_time"], name: "index_lan_sessions_on_start_time"
    t.index ["status"], name: "index_lan_sessions_on_status"
    t.index ["tenant_id"], name: "index_lan_sessions_on_tenant_id"
  end

  create_table "leads", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "company"
    t.string "source"
    t.integer "classification", default: 1
    t.bigint "assigned_to_user_id"
    t.bigint "converted_to_customer_id"
    t.datetime "converted_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "contact_source", default: 0
    t.index ["assigned_to_user_id"], name: "index_leads_on_assigned_to_user_id"
    t.index ["classification"], name: "index_leads_on_classification"
    t.index ["contact_source"], name: "index_leads_on_contact_source"
    t.index ["converted_at"], name: "index_leads_on_converted_at"
    t.index ["converted_to_customer_id"], name: "index_leads_on_converted_to_customer_id"
    t.index ["tenant_id", "classification"], name: "index_leads_on_tenant_and_classification"
    t.index ["tenant_id"], name: "index_leads_on_tenant_id"
  end

  create_table "missing_items", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "inventory_item_id"
    t.string "item_name", null: false
    t.text "description"
    t.integer "source", default: 0
    t.integer "urgency_level", default: 1
    t.integer "status", default: 0
    t.datetime "last_notified_at"
    t.boolean "included_in_weekly_report", default: false
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_missing_items_on_created_by_user_id"
    t.index ["inventory_item_id"], name: "index_missing_items_on_inventory_item_id"
    t.index ["tenant_id", "status"], name: "index_missing_items_on_tenant_id_and_status"
    t.index ["tenant_id", "urgency_level"], name: "index_missing_items_on_tenant_id_and_urgency_level"
    t.index ["tenant_id"], name: "index_missing_items_on_tenant_id"
  end

  create_table "opportunities", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "lead_id"
    t.string "title", null: false
    t.text "description"
    t.decimal "value", precision: 10, scale: 2
    t.integer "probability", default: 50
    t.integer "stage", default: 0, null: false
    t.date "expected_close_date"
    t.date "actual_close_date"
    t.text "won_lost_reason"
    t.bigint "assigned_to_user_id"
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "contact_source", default: 0
    t.index ["assigned_to_user_id"], name: "index_opportunities_on_assigned_to_user_id"
    t.index ["contact_source"], name: "index_opportunities_on_contact_source"
    t.index ["created_by_user_id"], name: "index_opportunities_on_created_by_user_id"
    t.index ["customer_id"], name: "index_opportunities_on_customer_id"
    t.index ["expected_close_date"], name: "index_opportunities_on_expected_close_date"
    t.index ["lead_id"], name: "index_opportunities_on_lead_id"
    t.index ["stage"], name: "index_opportunities_on_stage"
    t.index ["tenant_id", "assigned_to_user_id"], name: "index_opportunities_on_tenant_and_assigned_user"
    t.index ["tenant_id", "stage"], name: "index_opportunities_on_tenant_and_stage"
    t.index ["tenant_id"], name: "index_opportunities_on_tenant_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.decimal "amount", precision: 10, scale: 2
    t.string "payment_method"
    t.date "payment_date"
    t.bigint "received_by_user_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["invoice_id", "payment_date"], name: "index_payments_on_invoice_and_date"
    t.index ["invoice_id"], name: "index_payments_on_invoice_id"
    t.index ["payment_date"], name: "index_payments_on_payment_date"
    t.index ["received_by_user_id"], name: "index_payments_on_received_by_user_id"
    t.index ["tenant_id"], name: "index_payments_on_tenant_id"
  end

  create_table "price_rules", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.integer "min_qty"
    t.integer "max_qty"
    t.decimal "unit_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["product_id"], name: "index_price_rules_on_product_id"
    t.index ["tenant_id"], name: "index_price_rules_on_tenant_id"
  end

  create_table "pricing_warnings", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "warnable_type", null: false
    t.bigint "warnable_id", null: false
    t.bigint "created_by_user_id"
    t.string "warning_type", null: false
    t.decimal "expected_margin", precision: 5, scale: 2
    t.decimal "actual_margin", precision: 5, scale: 2
    t.decimal "margin_deficit", precision: 5, scale: 2
    t.decimal "profit_loss", precision: 10, scale: 2
    t.jsonb "item_breakdown", default: {}
    t.text "justification"
    t.boolean "director_notified", default: false
    t.datetime "director_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_pricing_warnings_on_created_by_user_id"
    t.index ["tenant_id", "warning_type"], name: "index_pricing_warnings_on_tenant_id_and_warning_type"
    t.index ["tenant_id"], name: "index_pricing_warnings_on_tenant_id"
    t.index ["warnable_type", "warnable_id"], name: "index_pricing_warnings_on_warnable"
    t.index ["warnable_type", "warnable_id"], name: "index_pricing_warnings_on_warnable_type_and_warnable_id"
    t.index ["warning_type"], name: "index_pricing_warnings_on_warning_type"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.string "unit"
    t.decimal "base_price"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.decimal "labor_cost", precision: 10, scale: 2, default: "0.0"
    t.decimal "material_cost", precision: 10, scale: 2, default: "0.0"
    t.decimal "purchase_price", precision: 10, scale: 2, default: "0.0"
    t.index ["tenant_id"], name: "index_products_on_tenant_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "category", null: false
    t.string "name", null: false
    t.text "description"
    t.string "estimated_time"
    t.string "availability"
    t.boolean "active", default: true, null: false
    t.bigint "tenant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "category"], name: "index_services_on_tenant_id_and_category"
    t.index ["tenant_id"], name: "index_services_on_tenant_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "related_type"
    t.integer "related_id"
    t.string "title", null: false
    t.text "description"
    t.date "due_date"
    t.string "status", default: "pendente"
    t.bigint "assigned_to_user_id"
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.index ["assigned_to_user_id"], name: "index_tasks_on_assigned_to_user_id"
    t.index ["created_by_user_id"], name: "index_tasks_on_created_by_user_id"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["related_type", "related_id"], name: "index_tasks_on_related_type_and_related_id"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["tenant_id"], name: "index_tasks_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.integer "status", default: 0, null: false
    t.date "subscription_start"
    t.date "subscription_end"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subscription_status", default: "trial"
    t.datetime "subscription_expires_at"
    t.string "subscription_plan", default: "monthly"
    t.datetime "last_payment_date"
    t.integer "grace_period_days", default: 7
    t.boolean "is_master"
    t.index ["status"], name: "index_tenants_on_status"
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
    t.index ["subscription_expires_at"], name: "index_tenants_on_subscription_expires_at"
    t.index ["subscription_status"], name: "index_tenants_on_subscription_status"
  end

  create_table "training_courses", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "student_name"
    t.string "module_name"
    t.decimal "total_value"
    t.decimal "amount_paid"
    t.integer "training_days"
    t.date "start_date"
    t.date "end_date"
    t.integer "payment_type"
    t.integer "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_training_courses_on_tenant_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.integer "role", default: 1, null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tenant_id"
    t.boolean "super_admin"
    t.integer "department"
    t.boolean "admin", default: false, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "must_change_password", default: true, null: false
    t.datetime "password_changed_at"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["department"], name: "index_users_on_department"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "tenants"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "communications", "tenants"
  add_foreign_key "communications", "users", column: "created_by_user_id"
  add_foreign_key "company_settings", "tenants"
  add_foreign_key "contacts", "tenants"
  add_foreign_key "customers", "tenants"
  add_foreign_key "daily_revenues", "tenants"
  add_foreign_key "estimate_items", "estimates"
  add_foreign_key "estimate_items", "products"
  add_foreign_key "estimate_items", "tenants"
  add_foreign_key "estimates", "customers"
  add_foreign_key "estimates", "tenants"
  add_foreign_key "estimates", "users", column: "created_by_user_id"
  add_foreign_key "inventory_items", "tenants"
  add_foreign_key "inventory_movements", "inventory_items"
  add_foreign_key "inventory_movements", "tenants"
  add_foreign_key "inventory_movements", "users", column: "created_by_user_id"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "tenants"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "tenants"
  add_foreign_key "invoices", "users", column: "created_by_user_id"
  add_foreign_key "job_files", "jobs"
  add_foreign_key "job_files", "tenants"
  add_foreign_key "job_files", "users", column: "uploaded_by_user_id"
  add_foreign_key "job_items", "jobs"
  add_foreign_key "job_items", "products"
  add_foreign_key "job_items", "tenants"
  add_foreign_key "jobs", "customers"
  add_foreign_key "jobs", "estimates", column: "source_estimate_id"
  add_foreign_key "jobs", "tenants"
  add_foreign_key "jobs", "users", column: "created_by_user_id"
  add_foreign_key "lan_machines", "tenants"
  add_foreign_key "lan_sessions", "customers"
  add_foreign_key "lan_sessions", "lan_machines"
  add_foreign_key "lan_sessions", "tenants"
  add_foreign_key "lan_sessions", "users", column: "created_by_user_id"
  add_foreign_key "leads", "customers", column: "converted_to_customer_id"
  add_foreign_key "leads", "tenants"
  add_foreign_key "leads", "users", column: "assigned_to_user_id"
  add_foreign_key "missing_items", "inventory_items"
  add_foreign_key "missing_items", "tenants"
  add_foreign_key "missing_items", "users", column: "created_by_user_id"
  add_foreign_key "opportunities", "customers"
  add_foreign_key "opportunities", "leads"
  add_foreign_key "opportunities", "tenants"
  add_foreign_key "opportunities", "users", column: "assigned_to_user_id"
  add_foreign_key "opportunities", "users", column: "created_by_user_id"
  add_foreign_key "payments", "invoices"
  add_foreign_key "payments", "tenants"
  add_foreign_key "payments", "users", column: "received_by_user_id"
  add_foreign_key "price_rules", "products"
  add_foreign_key "price_rules", "tenants"
  add_foreign_key "pricing_warnings", "tenants"
  add_foreign_key "pricing_warnings", "users", column: "created_by_user_id"
  add_foreign_key "products", "tenants"
  add_foreign_key "services", "tenants"
  add_foreign_key "tasks", "tenants"
  add_foreign_key "tasks", "users", column: "assigned_to_user_id"
  add_foreign_key "tasks", "users", column: "created_by_user_id"
  add_foreign_key "training_courses", "tenants"
  add_foreign_key "users", "tenants"
end
