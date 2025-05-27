    -- FINAL YEAR PROJECT 
    
    
 --TABLE STRUCTURE
 
 --MASTER TABLE
 
 drop table raw_vechicle_date;
 
 CREATE  TABLE raw_vehicle_data (
    entry_id       NUMBER PRIMARY KEY,
    timestamp_ms   NUMBER,
    speed_pwm      NUMBER,
    speed_limited  CHAR(1),            -- 'Y' or 'N'
    bypass_active  CHAR(1),            -- 'Y' or 'N'
    event_type     VARCHAR2(30),
    description    VARCHAR2(100)
);


CREATE TABLE vehicle_speed_logs (
log_id NUMBER PRIMARY KEY,
timestamp_ms NUMBER NOT NULL,
speed_pwm NUMBER NOT NULL,
speed_limited CHAR(1) CHECK (speed_limited IN ('Y','N')) NOT NULL,
bypass_active CHAR(1) CHECK (bypass_active IN ('Y','N')) NOT NULL
);

CREATE TABLE system_events (
event_id NUMBER PRIMARY KEY,
event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
event_type VARCHAR2(50) NOT NULL,
description VARCHAR2(255)
);

-- SEQUENCE FOR IDS
CREATE SEQUENCE seq_log_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE seq_event_id START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE SEQUENCE raw_data_seq START WITH 1 INCREMENT BY 1;

SELECT * FROM raw_vehicle_data;

alter table raw_vehicle_data drop column entry_type;

INSERT INTO vehicle_speed_logs (
    log_id,
    timestamp_ms,
    speed_pwm,
    speed_limited,
    bypass_active
)
SELECT
    seq_log_id.NEXTVAL,
    timestamp_ms,
    speed_pwm,
    speed_limited,
    bypass_active
FROM raw_vehicle_data
WHERE speed_pwm IS NOT NULL
  AND speed_limited IS NOT NULL
  AND bypass_active IS NOT NULL;


INSERT INTO system_events (
    event_id,
    event_time,
    event_type,
    description
)
SELECT
    seq_event_id.NEXTVAL,
    SYSTIMESTAMP,
    event_type,
    description
FROM raw_vehicle_data
WHERE event_type IS NOT NULL
  AND description IS NOT NULL;

commit;

CREATE OR REPLACE TRIGGER trg_split_raw_vehicle_data
AFTER INSERT ON raw_vehicle_data
FOR EACH ROW
DECLARE
BEGIN
    -- Insert into vehicle_speed_logs if log-related columns are present
    IF :NEW.speed_pwm IS NOT NULL AND :NEW.speed_limited IS NOT NULL AND :NEW.bypass_active IS NOT NULL THEN
        INSERT INTO vehicle_speed_logs (
            log_id,
            timestamp_ms,
            speed_pwm,
            speed_limited,
            bypass_active
        ) VALUES (
            seq_log_id.NEXTVAL,
            :NEW.timestamp_ms,
            :NEW.speed_pwm,
            :NEW.speed_limited,
            :NEW.bypass_active
        );
    END IF;

    -- Insert into system_events if event-related columns are present
    IF :NEW.event_type IS NOT NULL AND :NEW.description IS NOT NULL THEN
        INSERT INTO system_events (
            event_id,
            event_time,
            event_type,
            description
        ) VALUES (
            seq_event_id.NEXTVAL,
            SYSTIMESTAMP,
            :NEW.event_type,
            :NEW.description
        );
    END IF;
END;
/

--procedure to clean the tables every 7 days for storage efficient

CREATE OR REPLACE PROCEDURE cleanup_old_vehicle_data AS
a number;
BEGIN
DELETE FROM raw_vehicle_data
WHERE created_at < SYSTIMESTAMP - INTERVAL '7' DAY;

DELETE FROM vehicle_speed_logs
WHERE created_at < SYSTIMESTAMP - INTERVAL '7' DAY;

DELETE FROM system_events
WHERE created_at < SYSTIMESTAMP - INTERVAL '7' DAY;

    commit ;
END;
/

--scheduler that executes cleanup_old_vechicle_data procedure with certain intervel of time

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'CLEANUP_OLD_VEHICLE_DATA_JOB',
    job_type        => 'STORED_PROCEDURE',
    job_action      => 'cleanup_old_vehicle_data',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;INTERVAL=3',
    enabled         => TRUE,
    comments        => 'Job to run cleanup_old_vehicle_data every 3 days'
  );
END;
/



--------------------------------------------------------------------------WORKSPACE------------------------------------------------------------------------


Select * from raw_vehicle_data;

Select*from vehicle_speed_logs;

select *from system_events;

truncate table raw_vehicle_data;

truncate table vehicle_speed_logs;

truncate table system_events;

ALTER TABLE raw_vehicle_data ADD created_at TIMESTAMP DEFAULT SYSTIMESTAMP;

ALTER TABLE vehicle_speed_logs ADD created_at TIMESTAMP DEFAULT SYSTIMESTAMP;

ALTER TABLE system_events ADD created_at TIMESTAMP DEFAULT SYSTIMESTAMP;

SELECT *
FROM user_scheduler_jobs
WHERE job_name = 'CLEANUP_OLD_VEHICLE_DATA_JOB';