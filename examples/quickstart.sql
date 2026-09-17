CREATE NAMESPACE IF NOT EXISTS lake.yigraph;

CREATE OR REPLACE TABLE lake.yigraph.person_events (
  event_id BIGINT,
  person_id STRING,
  person_name STRING,
  event_type STRING,
  event_time TIMESTAMP
)
USING iceberg
PARTITIONED BY (days(event_time));

INSERT INTO lake.yigraph.person_events VALUES
  (1, 'p-1001', 'Alice', 'person_created', TIMESTAMP '2026-09-17 09:00:00'),
  (2, 'p-1002', 'Bob',   'person_created', TIMESTAMP '2026-09-17 09:05:00'),
  (3, 'p-1001', 'Alice', 'profile_updated', TIMESTAMP '2026-09-17 10:00:00');

SELECT *
FROM lake.yigraph.person_events
ORDER BY event_id;

ALTER TABLE lake.yigraph.person_events ADD COLUMN source STRING;

UPDATE lake.yigraph.person_events
SET source = 'bootstrap'
WHERE source IS NULL;

SELECT snapshot_id, committed_at, operation
FROM lake.yigraph.person_events.snapshots
ORDER BY committed_at;

SELECT file_path, record_count
FROM lake.yigraph.person_events.files;
