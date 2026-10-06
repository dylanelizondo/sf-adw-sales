-- slv_sales_territory_history
-- ONE row per salesperson + territory + start_date. Grain matches the source composite PK.
--
-- Open SCD2: 13 of the 17 active rows have NULL end_date (current assignment).
-- is_current_assignment flags the open rows without filtering them out, so
-- consumers can retrieve the full history or the snapshot at any point in time.
-- No rows are closed or synthesised here — that belongs in gold snapshots.

select
    -- grain keys ----------------------------------------------------------
    business_entity_id,
    territory_id,
    try_to_date(start_date) as start_date,

    -- SCD2 close date -----------------------------------------------------
    -- NULL means the salesperson is still assigned to this territory.
    -- is_current_assignment is derived here so consumers never re-derive it
    -- with an ambiguous IS NULL check against the raw column.
    try_to_date(end_date) as end_date,
    (end_date is null)    as is_current_assignment,

    -- technical column ----------------------------------------------------
    rowguid,

    -- audit ---------------------------------------------------------------
    try_to_timestamp(modified_date) as sales_territory_history_modified_date

from {{ ref('adw_core', 'brz_adventure_works_sales__sales_territory_history') }}
