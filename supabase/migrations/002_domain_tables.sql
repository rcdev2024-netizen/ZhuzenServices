-- Domain tables for every collection in the service operations API.
-- Run after 001_initial_schema.sql.
--
-- Each table has a stable relational envelope plus a JSONB data column. This
-- gives every API resource its own table now, while allowing the individual
-- modules to gain stricter columns without breaking existing records.

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'service_requests',
    'job_orders',
    'warranties',
    'diagnostics',
    'quotations',
    'parts',
    'purchase_orders',
    'suppliers',
    'repairs',
    'qc_checklists',
    'customer_signatures',
    'projects',
    'site_surveys',
    'material_preparations',
    'technicians',
    'assignments',
    'installations',
    'commissioning',
    'punch_lists',
    'service_partners',
    'partner_requests',
    'schedules',
    'calendar_events',
    'service_reports',
    'uploads',
    'attachments',
    'invoices',
    'payments',
    'service_income',
    'incentives',
    'customer_feedback',
    'performance_metrics',
    'dashboard_snapshots',
    'report_runs'
  ] loop
    execute format(
      'create table if not exists %I (
        id uuid primary key default gen_random_uuid(),
        parent_id uuid,
        customer_id uuid,
        asset_id uuid,
        job_order_id uuid,
        assigned_to uuid,
        created_by uuid,
        status text not null default ''draft'',
        reference text,
        amount numeric(14, 2),
        scheduled_at timestamptz,
        completed_at timestamptz,
        data jsonb not null default ''{}''::jsonb,
        created_at timestamptz not null default now(),
        updated_at timestamptz not null default now()
      )',
      table_name
    );

    execute format(
      'create index if not exists %I on %I(status)',
      table_name || '_status_idx',
      table_name
    );
    execute format(
      'create index if not exists %I on %I(customer_id)',
      table_name || '_customer_idx',
      table_name
    );
    execute format(
      'create index if not exists %I on %I(parent_id)',
      table_name || '_parent_idx',
      table_name
    );
    execute format('alter table %I enable row level security', table_name);
    execute format('drop trigger if exists updated_at on %I', table_name);
    execute format(
      'create trigger updated_at before update on %I
       for each row execute function set_updated_at()',
      table_name
    );
  end loop;
end $$;