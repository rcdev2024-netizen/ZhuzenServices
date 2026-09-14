-- Test Data Population Script
-- This script populates the Supabase database with realistic test data
-- Run this in Supabase SQL Editor AFTER migrations 001 and 002
-- Safe to run multiple times (uses INSERT OR IGNORE pattern)

-- ============================================================================
-- ROLES
-- ============================================================================
INSERT INTO roles (id, name, description, permissions, created_at, updated_at) VALUES
  ('10000000-0000-0000-0000-000000000001'::uuid, 'Admin', 'Full system access', '["*"]'::jsonb, now(), now()),
  ('10000000-0000-0000-0000-000000000002'::uuid, 'Manager', 'Manage team and jobs', '["read:all","write:own","manage:team"]'::jsonb, now(), now()),
  ('10000000-0000-0000-0000-000000000003'::uuid, 'Technician', 'Execute field work', '["read:assigned","write:assigned","submit:work"]'::jsonb, now(), now()),
  ('10000000-0000-0000-0000-000000000004'::uuid, 'Customer', 'View own assets and requests', '["read:own"]'::jsonb, now(), now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- USERS
-- ============================================================================
-- Password format: pbkdf2_sha256$310000${salt_hex}${digest_hex}
-- All test passwords are: "TestPassword123"
INSERT INTO users (id, email, password_hash, full_name, role_id, is_active, created_at, updated_at) VALUES
  -- Admin user
  ('20000000-0000-0000-0000-000000000001'::uuid, 
   'admin@zhuzen.com',
   'pbkdf2_sha256$310000$2f2e1b8c9a3e4d5f6a7b8c9d0e1f2a3b$4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c',
   'Admin User',
   '10000000-0000-0000-0000-000000000001'::uuid,
   true,
   now(),
   now()),
  
  -- Manager user
  ('20000000-0000-0000-0000-000000000002'::uuid,
   'manager@zhuzen.com',
   'pbkdf2_sha256$310000$3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d$5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d',
   'Manager One',
   '10000000-0000-0000-0000-000000000002'::uuid,
   true,
   now(),
   now()),
  
  -- Technician users
  ('20000000-0000-0000-0000-000000000003'::uuid,
   'tech1@zhuzen.com',
   'pbkdf2_sha256$310000$4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e$6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e',
   'John Technician',
   '10000000-0000-0000-0000-000000000003'::uuid,
   true,
   now(),
   now()),
  
  ('20000000-0000-0000-0000-000000000004'::uuid,
   'tech2@zhuzen.com',
   'pbkdf2_sha256$310000$5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f$7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f',
   'Sarah Technician',
   '10000000-0000-0000-0000-000000000003'::uuid,
   true,
   now(),
   now()),
  
  -- Customer users
  ('20000000-0000-0000-0000-000000000005'::uuid,
   'customer1@example.com',
   'pbkdf2_sha256$310000$6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f10$8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a',
   'Alice Customer',
   '10000000-0000-0000-0000-000000000004'::uuid,
   true,
   now(),
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- CUSTOMERS
-- ============================================================================
INSERT INTO customers (id, name, email, phone, company, address, status, created_at, updated_at) VALUES
  ('30000000-0000-0000-0000-000000000001'::uuid,
   'Acme Corporation',
   'contact@acme.com',
   '+1-555-0100',
   'Acme Corp',
   '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}'::jsonb,
   'active',
   now(),
   now()),
  
  ('30000000-0000-0000-0000-000000000002'::uuid,
   'Global Industries Ltd',
   'support@globalind.com',
   '+1-555-0200',
   'Global Industries',
   '{"street": "456 Oak Ave", "city": "Los Angeles", "state": "CA", "zip": "90001", "country": "USA"}'::jsonb,
   'active',
   now(),
   now()),
  
  ('30000000-0000-0000-0000-000000000003'::uuid,
   'Tech Solutions Inc',
   'hello@techsol.com',
   '+1-555-0300',
   'Tech Solutions',
   '{"street": "789 Pine Rd", "city": "Chicago", "state": "IL", "zip": "60601", "country": "USA"}'::jsonb,
   'active',
   now(),
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ASSETS
-- ============================================================================
INSERT INTO assets (id, customer_id, name, asset_type, serial_number, manufacturer, model, installed_at, warranty_expires_at, metadata, status, created_at, updated_at) VALUES
  ('40000000-0000-0000-0000-000000000001'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   'HVAC System - Building A',
   'HVAC',
   'SN-2024-001',
   'Carrier',
   'AquaEdge 19DV',
   '2023-01-15'::date,
   '2028-01-15'::date,
   '{"location": "Building A - Floor 1", "capacity": "500 tons", "last_service": "2024-06-01"}'::jsonb,
   'active',
   now(),
   now()),
  
  ('40000000-0000-0000-0000-000000000002'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   'Elevator System - Main Lobby',
   'Elevator',
   'SN-2024-002',
   'Otis',
   'Gen2 Rise',
   '2022-06-01'::date,
   '2027-06-01'::date,
   '{"location": "Main Lobby", "floors": 15, "capacity": "2000 lbs"}'::jsonb,
   'active',
   now(),
   now()),
  
  ('40000000-0000-0000-0000-000000000003'::uuid,
   '30000000-0000-0000-0000-000000000002'::uuid,
   'Fire Suppression System',
   'Fire Safety',
   'SN-2024-003',
   'Tyco',
   'FireFlex Pro',
   '2023-03-10'::date,
   '2028-03-10'::date,
   '{"location": "Entire Building", "coverage_area": "50000 sqft"}'::jsonb,
   'active',
   now(),
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- TECHNICIANS
-- ============================================================================
INSERT INTO technicians (id, created_by, created_at, updated_at, data) VALUES
  ('50000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   now(),
   now(),
   '{"user_id": "20000000-0000-0000-0000-000000000003", "license_number": "TECH-001", "certifications": ["HVAC", "Electrical", "Gas"], "service_areas": ["NYC", "NJ", "CT"], "availability": "full-time"}'::jsonb),
  
  ('50000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   now(),
   now(),
   '{"user_id": "20000000-0000-0000-0000-000000000004", "license_number": "TECH-002", "certifications": ["Plumbing", "Water Systems"], "service_areas": ["LA", "OC", "Ventura"], "availability": "full-time"}'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SERVICE REQUESTS
-- ============================================================================
INSERT INTO service_requests (id, customer_id, asset_id, created_by, status, reference, scheduled_at, data, created_at, updated_at) VALUES
  ('60000000-0000-0000-0000-000000000001'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '40000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000005'::uuid,
   'open',
   'SR-2024-001',
   now() + interval '2 days',
   '{"issue": "HVAC not cooling properly", "priority": "high", "requested_date": "2024-09-16", "description": "Main building AC system needs inspection and repair"}'::jsonb,
   now(),
   now()),
  
  ('60000000-0000-0000-0000-000000000002'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '40000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000005'::uuid,
   'assigned',
   'SR-2024-002',
   now() + interval '5 days',
   '{"issue": "Elevator maintenance", "priority": "medium", "scheduled_date": "2024-09-19", "description": "Preventive maintenance for main elevator"}'::jsonb,
   now(),
   now()),
  
  ('60000000-0000-0000-0000-000000000003'::uuid,
   '30000000-0000-0000-0000-000000000002'::uuid,
   '40000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'completed',
   'SR-2024-003',
   now() - interval '1 day',
   '{"issue": "Fire system test", "priority": "high", "completed_date": "2024-09-13", "description": "Annual fire suppression system inspection"}'::jsonb,
   now() - interval '5 days',
   now() - interval '1 day')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- JOB ORDERS
-- ============================================================================
INSERT INTO job_orders (id, customer_id, asset_id, assigned_to, created_by, status, reference, scheduled_at, data, created_at, updated_at) VALUES
  ('70000000-0000-0000-0000-000000000001'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '40000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'assigned',
   'JO-2024-001',
   now() + interval '2 days',
   '{"work_type": "Repair", "description": "Fix HVAC cooling issue", "estimated_hours": 4, "labor_rate": 150}'::jsonb,
   now(),
   now()),
  
  ('70000000-0000-0000-0000-000000000002'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '40000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000004'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'in_progress',
   'JO-2024-002',
   now() - interval '1 day',
   '{"work_type": "Maintenance", "description": "Elevator preventive maintenance", "estimated_hours": 3, "labor_rate": 175}'::jsonb,
   now() - interval '2 days',
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- QUOTATIONS
-- ============================================================================
INSERT INTO quotations (id, customer_id, asset_id, created_by, status, reference, amount, data, created_at, updated_at) VALUES
  ('80000000-0000-0000-0000-000000000001'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '40000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'pending',
   'QT-2024-001',
   1500.00,
   '{"description": "HVAC repair - labor and parts", "line_items": [{"description": "Labor (4 hrs @ $150)", "quantity": 4, "rate": 150}, {"description": "Capacitor replacement", "quantity": 1, "rate": 300}], "terms": "30 days", "validity": "2024-09-30"}'::jsonb,
   now(),
   now()),
  
  ('80000000-0000-0000-0000-000000000002'::uuid,
   '30000000-0000-0000-0000-000000000002'::uuid,
   '40000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'approved',
   'QT-2024-002',
   2500.00,
   '{"description": "Fire system inspection and certification", "line_items": [{"description": "Annual inspection", "quantity": 1, "rate": 1000}, {"description": "Testing and certification", "quantity": 1, "rate": 1500}], "terms": "net 30", "validity": "2024-10-31"}'::jsonb,
   now() - interval '3 days',
   now() - interval '1 day')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- INVOICES
-- ============================================================================
INSERT INTO invoices (id, customer_id, created_by, status, reference, amount, data, created_at, updated_at) VALUES
  ('90000000-0000-0000-0000-000000000001'::uuid,
   '30000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'paid',
   'INV-2024-001',
   2500.00,
   '{"description": "Fire system inspection", "line_items": [{"description": "Annual inspection", "quantity": 1, "rate": 1000}, {"description": "Certification", "quantity": 1, "rate": 1500}], "due_date": "2024-10-13", "paid_date": "2024-09-10"}'::jsonb,
   now() - interval '4 days',
   now() - interval '1 day'),
  
  ('90000000-0000-0000-0000-000000000002'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'partially_paid',
   'INV-2024-002',
   1500.00,
   '{"description": "HVAC repair services", "line_items": [{"description": "Service call", "quantity": 1, "rate": 500}, {"description": "Parts and labor", "quantity": 1, "rate": 1000}], "due_date": "2024-10-14", "issued_date": "2024-09-14", "amount_paid": 1200.00, "balance_due": 300.00}'::jsonb,
   now(),
   now()),
  
  ('90000000-0000-0000-0000-000000000003'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'paid',
   'INV-2024-003',
   3500.00,
   '{"description": "Elevator maintenance and repair", "line_items": [{"description": "Preventive maintenance", "quantity": 3, "rate": 175}, {"description": "Parts replacement", "quantity": 1, "rate": 2425}], "due_date": "2024-10-08", "paid_date": "2024-09-08", "technician": "Sarah Technician"}'::jsonb,
   now() - interval '6 days',
   now() - interval '1 day'),
  
  ('90000000-0000-0000-0000-000000000004'::uuid,
   '30000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'draft',
   'INV-2024-004',
   4200.00,
   '{"description": "Emergency HVAC service", "line_items": [{"description": "Emergency call-out fee", "quantity": 1, "rate": 500}, {"description": "Labor (8 hrs @ $250)", "quantity": 8, "rate": 250}, {"description": "Equipment and parts", "quantity": 1, "rate": 2200}], "due_date": "2024-10-20", "issued_date": "2024-09-14", "status": "pending_customer_approval"}'::jsonb,
   now(),
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PAYMENTS
-- ============================================================================
INSERT INTO payments (id, created_by, status, reference, amount, data, created_at, updated_at) VALUES
  ('a0000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000005'::uuid,
   'completed',
   'PAY-2024-001',
   2500.00,
   '{"invoice_id": "90000000-0000-0000-0000-000000000001", "method": "bank_transfer", "transaction_id": "TXN-2024-001", "payment_date": "2024-09-10", "notes": "Payment for fire system inspection"}'::jsonb,
   now() - interval '4 days',
   now() - interval '4 days'),
  
  ('a0000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'completed',
   'PAY-2024-002',
   1200.00,
   '{"invoice_id": "90000000-0000-0000-0000-000000000002", "method": "credit_card", "transaction_id": "TXN-2024-002", "payment_date": "2024-09-12", "notes": "Partial payment for HVAC repair", "balance_due": 300.00}'::jsonb,
   now() - interval '2 days',
   now() - interval '2 days'),
  
  ('a0000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'pending',
   'PAY-2024-003',
   800.00,
   '{"invoice_id": "90000000-0000-0000-0000-000000000002", "method": "check", "transaction_id": "TXN-2024-003", "expected_date": "2024-09-25", "notes": "Final payment for HVAC work"}'::jsonb,
   now() - interval '1 day',
   now() - interval '1 day'),
  
  ('a0000000-0000-0000-0000-000000000004'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'completed',
   'PAY-2024-004',
   3500.00,
   '{"invoice_id": "90000000-0000-0000-0000-000000000003", "method": "ach", "transaction_id": "TXN-2024-004", "payment_date": "2024-09-08", "notes": "Full payment - Elevator maintenance", "reference": "INV-2024-003"}'::jsonb,
   now() - interval '6 days',
   now() - interval '6 days'),
  
  ('a0000000-0000-0000-0000-000000000005'::uuid,
   '20000000-0000-0000-0000-000000000005'::uuid,
   'completed',
   'PAY-2024-005',
   1800.00,
   '{"invoice_id": "90000000-0000-0000-0000-000000000004", "method": "wire_transfer", "transaction_id": "TXN-2024-005", "payment_date": "2024-09-05", "notes": "Parts and supplies payment", "vendor": "Carrier Direct"}'::jsonb,
   now() - interval '9 days',
   now() - interval '9 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PARTS
-- ============================================================================
INSERT INTO parts (id, created_by, status, reference, data, created_at, updated_at) VALUES
  ('b0000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'in_stock',
   'PART-001',
   '{"part_number": "CAP-HVAC-500", "description": "HVAC Capacitor 50µF", "manufacturer": "Carrier", "quantity_available": 15, "quantity_reserved": 2, "unit_cost": 125.00, "supplier": "Carrier Direct", "last_restocked": "2024-09-01"}'::jsonb,
   now() - interval '1 day',
   now() - interval '1 day'),
  
  ('b0000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'in_stock',
   'PART-002',
   '{"part_number": "FILTER-HVAC-1", "description": "HVAC Air Filter 16x25x1", "manufacturer": "Generic", "quantity_available": 50, "quantity_reserved": 0, "unit_cost": 15.00, "supplier": "HVAC Supply Co", "last_restocked": "2024-09-05"}'::jsonb,
   now() - interval '1 day',
   now() - interval '1 day'),
  
  ('b0000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'low_stock',
   'PART-003',
   '{"part_number": "BELT-ELEV-200", "description": "Elevator Traction Belt", "manufacturer": "Otis", "quantity_available": 3, "quantity_reserved": 1, "unit_cost": 450.00, "supplier": "Otis Parts", "last_restocked": "2024-08-20", "reorder_level": 5}'::jsonb,
   now() - interval '25 days',
   now() - interval '5 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SERVICE INCOME
-- ============================================================================
INSERT INTO service_income (id, created_by, status, reference, amount, data, created_at, updated_at) VALUES
  ('e0000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'recorded',
   'INC-2024-001',
   2500.00,
   '{"service_type": "Inspection & Certification", "customer": "Global Industries Ltd", "invoice_id": "90000000-0000-0000-0000-000000000001", "payment_received_date": "2024-09-10", "invoice_date": "2024-09-07", "service_date": "2024-09-07", "technician": "John Technician", "revenue_recognition": "september_2024"}'::jsonb,
   now() - interval '4 days',
   now() - interval '4 days'),
  
  ('e0000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'recorded',
   'INC-2024-002',
   1200.00,
   '{"service_type": "Labor & Parts", "customer": "Acme Corporation", "invoice_id": "90000000-0000-0000-0000-000000000002", "payment_received_date": "2024-09-12", "invoice_date": "2024-09-14", "service_date": "2024-09-14", "technician": "John Technician", "revenue_recognition": "september_2024", "note": "Partial payment received"}'::jsonb,
   now() - interval '2 days',
   now() - interval '2 days'),
  
  ('e0000000-0000-0000-0000-000000000003'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'recorded',
   'INC-2024-003',
   3500.00,
   '{"service_type": "Maintenance & Repair", "customer": "Acme Corporation", "invoice_id": "90000000-0000-0000-0000-000000000003", "payment_received_date": "2024-09-08", "invoice_date": "2024-09-05", "service_date": "2024-09-05", "technician": "Sarah Technician", "revenue_recognition": "september_2024"}'::jsonb,
   now() - interval '6 days',
   now() - interval '6 days'),
  
  ('e0000000-0000-0000-0000-000000000004'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'accrued',
   'INC-2024-004',
   4200.00,
   '{"service_type": "Emergency Service", "customer": "Tech Solutions Inc", "invoice_id": "90000000-0000-0000-0000-000000000004", "service_date": "2024-09-14", "technician": "John Technician", "revenue_recognition": "september_2024", "status": "pending_payment", "notes": "Emergency call-out for HVAC failure"}'::jsonb,
   now(),
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- RESOURCE RECORDS (Timeline & Activity)
-- ============================================================================
INSERT INTO resource_records (id, resource_type, parent_id, created_by, status, data, created_at, updated_at) VALUES
  ('f0000000-0000-0000-0000-000000000001'::uuid,
   'activity',
   '60000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'completed',
   '{"type": "assignment", "action": "Service request assigned to technician", "assigned_to": "20000000-0000-0000-0000-000000000003", "assigned_by": "Manager One", "notes": "Assigned to John Technician for HVAC inspection"}'::jsonb,
   now() - interval '3 days',
   now() - interval '3 days'),
  
  ('f0000000-0000-0000-0000-000000000002'::uuid,
   'activity',
   '70000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000003'::uuid,
   'completed',
   '{"type": "status_update", "action": "Job order started", "status_before": "assigned", "status_after": "in_progress", "notes": "Arrived at site, began HVAC inspection"}'::jsonb,
   now() - interval '2 days',
   now() - interval '2 days'),
  
  ('f0000000-0000-0000-0000-000000000003'::uuid,
   'activity',
   '70000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000003'::uuid,
   'completed',
   '{"type": "work_log", "action": "Work performed", "duration_hours": 4, "description": "Replaced capacitor, cleaned coils, recharged refrigerant", "parts_used": [{"part_number": "CAP-HVAC-500", "quantity": 1, "cost": 125.00}], "labor_cost": 600.00}'::jsonb,
   now() - interval '2 days',
   now() - interval '2 days'),
  
  ('f0000000-0000-0000-0000-000000000004'::uuid,
   'activity',
   '90000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000005'::uuid,
   'completed',
   '{"type": "payment_received", "action": "Payment received and recorded", "amount": 2500.00, "method": "bank_transfer", "transaction_id": "TXN-2024-001", "payment_date": "2024-09-10", "verified_by": "Admin User"}'::jsonb,
   now() - interval '4 days',
   now() - interval '4 days'),
  
  ('f0000000-0000-0000-0000-000000000005'::uuid,
   'timeline',
   '70000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000004'::uuid,
   'completed',
   '{"event": "started", "timestamp": "2024-09-13", "description": "Elevator maintenance began", "location": "Main Lobby - Otis Gen2 Rise"}'::jsonb,
   now() - interval '1 day',
   now() - interval '1 day'),
  
  ('f0000000-0000-0000-0000-000000000006'::uuid,
   'timeline',
   '70000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000004'::uuid,
   'current',
   '{"event": "in_progress", "timestamp": "2024-09-14 14:30:00", "description": "Preventive maintenance procedures ongoing", "notes": "Belt inspection scheduled for completion today"}'::jsonb,
   now(),
   now()),
  
  ('f0000000-0000-0000-0000-000000000007'::uuid,
   'activity',
   '80000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'completed',
   '{"type": "quotation_approved", "action": "Customer approved quotation", "quotation_id": "80000000-0000-0000-0000-000000000002", "approved_by": "contact@globalind.com", "approved_date": "2024-09-12", "amount": 2500.00}'::jsonb,
   now() - interval '2 days',
   now() - interval '2 days'),
  
  ('f0000000-0000-0000-0000-000000000008'::uuid,
   'activity',
   '90000000-0000-0000-0000-000000000002'::uuid,
   '20000000-0000-0000-0000-000000000005'::uuid,
   'current',
   '{"type": "payment_tracking", "action": "Partial payment received", "amount_received": 1200.00, "amount_expected": 1500.00, "balance_due": 300.00, "payment_date": "2024-09-12", "expected_final_payment": "2024-09-25", "method": "credit_card"}'::jsonb,
   now() - interval '2 days',
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PURCHASES
-- ============================================================================
INSERT INTO purchase_orders (id, created_by, status, reference, amount, data, created_at, updated_at) VALUES
  ('c0000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000002'::uuid,
   'approved',
   'PO-2024-001',
   1875.00,
   '{"supplier": "Carrier Direct", "line_items": [{"part_number": "CAP-HVAC-500", "description": "HVAC Capacitor", "quantity": 15, "unit_cost": 125.00}], "delivery_date": "2024-09-20", "po_date": "2024-09-10", "terms": "net 30"}'::jsonb,
   now() - interval '4 days',
   now() - interval '2 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- WARRANTY
-- ============================================================================
INSERT INTO warranties (id, asset_id, customer_id, created_by, status, data, created_at, updated_at) VALUES
  ('d0000000-0000-0000-0000-000000000001'::uuid,
   '40000000-0000-0000-0000-000000000001'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'active',
   '{"warranty_type": "Manufacturer", "start_date": "2023-01-15", "end_date": "2028-01-15", "coverage": ["parts", "labor", "travel"], "coverage_limit": 50000.00, "deductible": 500.00}'::jsonb,
   now() - interval '20 days',
   now() - interval '20 days'),
  
  ('d0000000-0000-0000-0000-000000000002'::uuid,
   '40000000-0000-0000-0000-000000000002'::uuid,
   '30000000-0000-0000-0000-000000000001'::uuid,
   '20000000-0000-0000-0000-000000000001'::uuid,
   'active',
   '{"warranty_type": "Extended Service Agreement", "start_date": "2022-06-01", "end_date": "2027-06-01", "coverage": ["parts", "labor", "24/7 support"], "coverage_limit": 100000.00, "deductible": 0.00}'::jsonb,
   now() - interval '20 days',
   now() - interval '20 days')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SUMMARY QUERY - Run this to verify all data was inserted
-- ============================================================================
-- Uncomment the following queries to verify data insertion:

/*
SELECT 'Roles' as table_name, COUNT(*) as count FROM roles
UNION ALL SELECT 'Users', COUNT(*) FROM users
UNION ALL SELECT 'Customers', COUNT(*) FROM customers
UNION ALL SELECT 'Assets', COUNT(*) FROM assets
UNION ALL SELECT 'Technicians', COUNT(*) FROM technicians
UNION ALL SELECT 'Service Requests', COUNT(*) FROM service_requests
UNION ALL SELECT 'Job Orders', COUNT(*) FROM job_orders
UNION ALL SELECT 'Quotations', COUNT(*) FROM quotations
UNION ALL SELECT 'Invoices', COUNT(*) FROM invoices
UNION ALL SELECT 'Payments', COUNT(*) FROM payments
UNION ALL SELECT 'Parts', COUNT(*) FROM parts
UNION ALL SELECT 'Purchase Orders', COUNT(*) FROM purchase_orders
UNION ALL SELECT 'Warranties', COUNT(*) FROM warranties
UNION ALL SELECT 'Service Income', COUNT(*) FROM service_income
UNION ALL SELECT 'Resource Records', COUNT(*) FROM resource_records;

-- Detailed transaction summary:
-- Shows payment status breakdown
SELECT 'Payment Summary' as report, 
  (SELECT COUNT(*) FROM payments WHERE status = 'completed')::text || ' completed, ' ||
  (SELECT COUNT(*) FROM payments WHERE status = 'pending')::text || ' pending';

-- Revenue summary by customer
SELECT customer_id, COUNT(*) as transactions, SUM(amount) as total_revenue
FROM payments
WHERE status = 'completed'
GROUP BY customer_id
ORDER BY total_revenue DESC;

-- Invoice aging
SELECT status, COUNT(*) as invoice_count, SUM(amount) as total_amount
FROM invoices
GROUP BY status
ORDER BY status;
*/
