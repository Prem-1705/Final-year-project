LOAD DATA
INFILE 'raw_vehicle_data.csv'
INTO TABLE raw_vehicle_data
APPEND
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  entry_id       INTEGER EXTERNAL,
  timestamp_ms   INTEGER EXTERNAL,
  speed_pwm     INTEGER EXTERNAL,
  speed_limited CHAR,
  bypass_active CHAR,
  event_type    CHAR(30),
  description   CHAR(100)
)
