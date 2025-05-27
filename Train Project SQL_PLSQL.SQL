CREATE TABLE TTS_Customer (
    customer_id INT primary key,
    First_name VARCHAR(50),
    Last_name VARCHAR(50),
    Address VARCHAR(255),
    Phone_no VARCHAR(15),
    Mail_id VARCHAR(100),
    Password VARCHAR(100)
);

create sequence scusid start with 6000;


CREATE TABLE TTS_Train (
    Train_no number primary key,
    Train_name VARCHAR(100),
    From_stn VARCHAR(50),
    To_Stn VARCHAR(50),
    Seats number,
    Fare number
);

CREATE TABLE TTS_History (
    trans_id number primary key,
    customer_id number references tts_customer(customer_id),
    train_no number references tts_train(train_no),
    Booking_date DATE,
    from_stn VARCHAR(50),
    to_stn VARCHAR(50),
    Seats integer,
    Amount number
);

create sequence strnid start with 7000;

CREATE TABLE TTS_Schedule (
    schedule_id number primary key,
    train_no number references TTS_Train(train_no),
    departure_time varchar(20),
    arrival_time varchar(20),
    travel_duration varchar(30),
    available_seats number
);

create sequence sschdid start with 8000;

CREATE TABLE TTS_Payment (
    payment_id number primary key,
    trans_id number references tts_history(trans_id),
    customer_id number references tts_customer(customer_id),
    payment_mode VARCHAR(50),
    payment_status VARCHAR(50),
    payment_date DATE
);

create sequence sqpaymid start with 9000;

CREATE TABLE TTS_Cancellation (
    cancel_id number primary key,
    trans_id number references tts_history(trans_id),
    customer_id number references tts_customer(customer_id),
    cancel_date DATE,
    refund_amount number,
    status VARCHAR(50)
);

create sequence sqcanid start with 4000;

begin
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12623, 'Chennai Central - Madurai SF Express', 'Chennai Central', 'Madurai Junction', 800, 600);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12673, 'Chennai Egmore - Tiruchirappalli Rockfort Express', 'Chennai Egmore', 'Tiruchirappalli', 750, 550);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12681, 'Coimbatore - Chennai Intercity Express', 'Coimbatore Junction', 'Chennai Central', 700, 500);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(16127, 'Chennai Egmore - Guruvayur Express', 'Chennai Egmore', 'Coimbatore Junction', 650, 450);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12633, 'Chennai - Kanyakumari Express', 'Chennai Egmore', 'Kanyakumari', 850, 700);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12636, 'Vaigai Express', 'Chennai Egmore', 'Madurai Junction', 900, 550);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12652, 'Madurai - Chennai Pandian Express', 'Madurai Junction', 'Chennai Egmore', 850, 580);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12642, 'Thirukkural Express', 'Nagercoil Junction', 'Chennai Central', 800, 750);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12661, 'Pothigai Express', 'Chennai Egmore', 'Tenkasi Junction', 700, 650);
INSERT INTO TTS_Train (Train_no, Train_name, From_stn, To_Stn, Seats, Fare) VALUES 
(12688, 'Dehradun - Madurai Express', 'Madurai Junction', 'Chennai Egmore', 650, 700);
end;
/

select*from tts_train;

begin
INSERT INTO TTS_Schedule (schedule_id, train_no, departure_time, arrival_time, travel_duration, available_seats) VALUES
(1, 12623, '06:00 AM', '02:00 PM', '8 Hours', 200);
INSERT INTO TTS_Schedule (schedule_id, train_no, departure_time, arrival_time, travel_duration, available_seats) VALUES
(2, 12673, '09:00 PM', '05:00 AM', '8 Hours', 180);
INSERT INTO TTS_Schedule (schedule_id, train_no, departure_time, arrival_time, travel_duration, available_seats) VALUES
(3, 12681, '07:15 AM', '01:45 PM', '6 Hours 30 Minutes', 220);
INSERT INTO TTS_Schedule (schedule_id, train_no, departure_time, arrival_time, travel_duration, available_seats) VALUES
(4, 16127, '10:30 PM', '07:00 AM', '8 Hours 30 Minutes', 150);
INSERT INTO TTS_Schedule (schedule_id, train_no, departure_time, arrival_time, travel_duration, available_seats) VALUES
(5, 12633, '05:45 PM', '07:15 AM', '13 Hours 30 Minutes', 250);
end;
/

select*from tts_schedule;

CREATE OR REPLACE PROCEDURE SP_CUS_DETAILS (
T_CUSTOMER_ID IN NUMBER,
T_CUSTOMER_FN IN VARCHAR,
T_CUSTOMER_LN IN VARCHAR,
T_ADDRESS IN VARCHAR,
T_PHNO IN NUMBER,
T_MAIL_ID IN VARCHAR,
T_PASSWORD IN VARCHAR,
T_FROM_STN IN VARCHAR,
T_TO_STN IN VARCHAR,
T_BOOKING_DATE DATE,
T_SEATS NUMBER,
T_PAYMENT_MODE  VARCHAR,
FLAG IN NUMBER,
MSSG OUT VARCHAR
) AS
TRAINNO NUMBER;
TOTALFARE NUMBER;
L_TRANS_ID NUMBER;
FLG3TRANSID NUMBER;
PAYMENTID NUMBER;
FLG3TRAINNO NUMBER;
FLG3AVAILSEATS NUMBER;
FLG3HISTRYSEATS NUMBER;
CNTFLG2 NUMBER;
BEGIN
IF FLAG=1 THEN
INSERT INTO TTS_CUSTOMER VALUES(SCUSID.NEXTVAL,T_CUSTOMER_FN,T_CUSTOMER_LN,T_ADDRESS,T_PHNO,T_MAIL_ID,T_PASSWORD);
ELSIF FLAG=2 THEN
SELECT TRAIN_NO INTO TRAINNO FROM TTS_TRAIN WHERE UPPER(FROM_STN)=UPPER(T_FROM_STN) AND UPPER(TO_STN)=UPPER(T_TO_STN);
SELECT T_SEATS*FARE INTO TOTALFARE FROM TTS_TRAIN WHERE upper(FROM_STN)=UPPER(T_FROM_STN) AND UPPER(TO_STN)=UPPER(T_TO_STN);
SELECT COUNT(*) INTO CNTFLG2 FROM TTS_PAYMENT WHERE CUSTOMER_ID=T_CUSTOMER_ID AND PAYMENT_STATUS ='PENDING';
IF CNTFLG2=0  THEN
INSERT INTO TTS_HISTORY VALUES(STRNID.NEXTVAL,T_CUSTOMER_ID,TRAINNO,T_BOOKING_DATE,T_FROM_STN,T_TO_STN,T_SEATS,TOTALFARE) RETURNING TRANS_ID INTO L_TRANS_ID;
INSERT INTO TTS_PAYMENT VALUES(sqpaymid.NEXTVAL,L_TRANS_ID,T_CUSTOMER_ID,NULL,'PENDING',SYSDATE );
ELSE
DBMS_OUTPUT.PUT_LINE('THERE IS PENDING PAYMENT');
END IF;
ELSIF FLAG=3 THEN
SELECT TRANS_ID INTO FLG3TRANSID FROM TTS_HISTORY WHERE CUSTOMER_ID=T_CUSTOMER_ID;
SELECT PAYMENT_ID INTO PAYMENTID FROM TTS_PAYMENT WHERE TRANS_ID=FLG3TRANSID;
UPDATE TTS_PAYMENT SET PAYMENT_MODE=T_PAYMENT_MODE,PAYMENT_STATUS='ACTIVE',PAYMENT_DATE=SYSDATE WHERE PAYMENT_ID=PAYMENTID;
SELECT TRAIN_NO INTO FLG3TRAINNO FROM TTS_HISTORY WHERE TRANS_ID=FLG3TRANSID;
SELECT SEATS INTO FLG3AVAILSEATS FROM TTS_TRAIN WHERE TRAIN_NO=FLG3TRAINNO;
SELECT SEATS INTO FLG3HISTRYSEATS FROM TTS_HISTORY WHERE TRANS_ID=FLG3TRANSID;
UPDATE TTS_SCHEDULE SET AVAILABLE_SEATS=FLG3AVAILSEATS-T_SEATS WHERE TRAIN_NO=FLG3TRAINNO;
END IF;
MSSG:='SUCCESSFULLY PERFORMED WITH NO ERRORS';
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

SELECT*FROM USER_ERRORS WHERE NAME LIKE'SP%';

SELECT*FROM TTS_CUSTOMER;

DECLARE
MESSAGE VARCHAR(30);
BEGIN
SP_CUS_DETAILS (
T_CUSTOMER_ID=>6005,
T_CUSTOMER_FN =>'PRASANNA',
T_CUSTOMER_LN =>'KUMAR',
T_ADDRESS =>'CHENNAI,INDIA',
T_PHNO =>9988776699,
T_MAIL_ID =>'PRASANNA@GMAIL.COM',
T_PASSWORD =>'2312344',
T_FROM_STN =>'Chennai Central',
T_TO_STN =>'MADURAI JUNCTION',
T_BOOKING_DATE =>SYSDATE,
T_SEATS =>4,
T_PAYMENT_MODE=>'GPAY',
FLAG =>2,
MSSG=>MESSAGE
);
DBMS_OUTPUT.PUT_LINE(MESSAGE);
END;
/

--PROECUDURE TO DELETE PENDING STATUS ABOVE 5MIN
CREATE OR REPLACE PROCEDURE SP_DELETE_PENDINGSTS AS
CND NUMBER;
BEGIN
SELECT CASE WHEN PAYMENT_DATE+INTERVAL '5'  MINUTE>=SYSTIMESTAMP THEN '0' ELSE '1' END INTO CND FROM (SELECT PAYMENT_dATE FROM TTS_PAYMENT WHERE PAYMENT_STATUS='PENDING');
IF CND=1 THEN 
DELETE TTS_PAYMENT WHERE PAYMENT_STATUS='PENDING';
END IF;
END;
/

EXEC SP_DELETE_PENDINGSTS;

BEGIN
DBMS_SCHEDULER.CREATE_JOB(
JOB_NAME=>'DELETE_PENDING_STATUS',
JOB_TYPE=>'STORED_PROCEDURE',
JOB_ACTION=>'SP_DELETE_PENDINGSTS',
START_DATE=>'25-FEB-25 12:07:05 PM',
REPEAT_INTERVAL=>'FREQ=SECONDLY;INTERVAL=20',
END_DATE=>'1-JAN-2026 12:00:00 AM',
AUTO_DROP=>TRUE,
COMMENTS=>'DONE.'
);
END;
/

EXEC DBMS_SCHEDULER.ENABLE('DELETE_PENDING_STATUS');

EXEC DBMS_SCHEDULER.DISABLE('DELETE_PENDING_STATUS');