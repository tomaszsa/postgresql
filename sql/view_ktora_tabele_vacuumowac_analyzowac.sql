-- https://www.depesz.com/2020/01/29/which-tables-should-be-auto-vacuumed-or-auto-analyzed/
CREATE VIEW autovacuum_queue AS
WITH s AS (
    SELECT
        current_setting('autovacuum_analyze_scale_factor')::float8  AS  analyze_factor,
        current_setting('autovacuum_analyze_threshold')::float8     AS  analyze_threshold,
        current_setting('autovacuum_vacuum_scale_factor')::float8   AS  vacuum_factor,
        current_setting('autovacuum_vacuum_threshold')::float8      AS  vacuum_threshold
), tt AS (
    SELECT
        n.nspname,
        c.relname,
        c.oid AS relid,
        t.n_dead_tup,
        t.n_mod_since_analyze,
        c.reltuples * s.vacuum_factor + s.vacuum_threshold AS v_threshold,
        c.reltuples * s.analyze_factor + s.analyze_threshold AS a_threshold
    FROM
        s,
        pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_stat_all_tables t ON c.oid = t.relid
    WHERE
        c.relkind = 'r'
)
SELECT
    nspname,
    relname,
    relid,
    CASE WHEN n_dead_tup > v_threshold THEN 'VACUUM' ELSE '' END AS do_vacuum,
    CASE WHEN n_mod_since_analyze > a_threshold THEN 'ANALYZE' ELSE '' END AS do_analyze
FROM
    tt
WHERE
    n_dead_tup > v_threshold OR
    n_mod_since_analyze > a_threshold;
