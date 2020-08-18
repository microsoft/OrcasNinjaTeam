--------------------------------------------------------
--  File created - Thursday-March-26-2020   
--------------------------------------------------------
DROP SEQUENCE "REG_APP"."DBOBJECTID_SEQUENCE";
DROP SEQUENCE "REG_APP"."REGISTRATION_ID_SEQ";
DROP TABLE "REG_APP"."ATTENDEES";
DROP TABLE "REG_APP"."EVENTS";
DROP TABLE "REG_APP"."REGISTRATIONS";
DROP TABLE "REG_APP"."SESSIONS";
DROP TABLE "REG_APP"."SPEAKERS";
DROP VIEW "REG_APP"."V_ATTENDEE_SESSIONS";
DROP VIEW "REG_APP"."V_SPK_SESSION";
DROP PROCEDURE "REG_APP"."GET_RANDOM_ATTENDEE";
DROP PROCEDURE "REG_APP"."REGISTER_ATTENDEE_SESSION";
DROP PACKAGE "REG_APP"."UTILITY_SCRIPTS";
DROP PACKAGE BODY "REG_APP"."UTILITY_SCRIPTS";
--------------------------------------------------------
--  DDL for Sequence DBOBJECTID_SEQUENCE
--------------------------------------------------------

   CREATE SEQUENCE  "REG_APP"."DBOBJECTID_SEQUENCE"  MINVALUE 1 MAXVALUE 999999999999999999999999 INCREMENT BY 50 START WITH 1 CACHE 50 NOORDER  NOCYCLE ;
--------------------------------------------------------
--  DDL for Sequence REGISTRATION_ID_SEQ
--------------------------------------------------------

   CREATE SEQUENCE  "REG_APP"."REGISTRATION_ID_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 103 CACHE 20 NOORDER  NOCYCLE ;
--------------------------------------------------------
--  DDL for Table ATTENDEES
--------------------------------------------------------

  CREATE TABLE "REG_APP"."ATTENDEES" 
   (	"ID" NUMBER, 
	"FIRST_NAME" VARCHAR2(50 CHAR), 
	"LAST_NAME" VARCHAR2(50 CHAR), 
	"EMAIL_ADDRESS" VARCHAR2(200 CHAR)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Table EVENTS
--------------------------------------------------------

  CREATE TABLE "REG_APP"."EVENTS" 
   (	"ID" NUMBER, 
	"EVENT_NAME" VARCHAR2(300 CHAR), 
	"EVENT_DESCRIPTION" VARCHAR2(2000 CHAR), 
	"EVENT_START_DATE" DATE, 
	"EVENT_PRICE" NUMBER(*,0), 
	"EVENT_END_DATE" DATE, 
	"EVENT_PIC" BLOB
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" 
 LOB ("EVENT_PIC") STORE AS BASICFILE (
  TABLESPACE "SYSTEM" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
--------------------------------------------------------
--  DDL for Table REGISTRATIONS
--------------------------------------------------------

  CREATE TABLE "REG_APP"."REGISTRATIONS" 
   (	"ID" NUMBER, 
	"REGISTRATION_DATE" DATE, 
	"SESSION_ID" NUMBER, 
	"ATTENDEE_ID" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Table SESSIONS
--------------------------------------------------------

  CREATE TABLE "REG_APP"."SESSIONS" 
   (	"ID" NUMBER, 
	"NAME" VARCHAR2(300 CHAR), 
	"DESCRIPTION" VARCHAR2(2000 CHAR), 
	"SESSION_DATE" DATE, 
	"SPEAKER_ID" NUMBER, 
	"EVENT_ID" NUMBER, 
	"DURATION" NUMBER
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Table SPEAKERS
--------------------------------------------------------

  CREATE TABLE "REG_APP"."SPEAKERS" 
   (	"ID" NUMBER, 
	"FIRST_NAME" VARCHAR2(50 CHAR), 
	"LAST_NAME" VARCHAR2(50 CHAR), 
	"SPEAKER_PIC" BLOB, 
	"SPEAKER_BIO" CLOB
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" 
 LOB ("SPEAKER_PIC") STORE AS BASICFILE (
  TABLESPACE "SYSTEM" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) 
 LOB ("SPEAKER_BIO") STORE AS BASICFILE (
  TABLESPACE "SYSTEM" ENABLE STORAGE IN ROW CHUNK 8192 RETENTION 
  NOCACHE LOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)) ;
--------------------------------------------------------
--  DDL for View V_ATTENDEE_SESSIONS
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "REG_APP"."V_ATTENDEE_SESSIONS" ("ATTENDEE_ID", "FIRST_NAME", "LAST_NAME", "SESSION_NAME", "SESSION_START", "DURATION", "REGISTRATION_DATE") AS 
  SELECT
    att.id as attendee_id,
    att.first_name,
    att.last_name,
    ses.name as session_name,
    ses.session_date as session_start,
    ses.duration,
    reg.registration_date
FROM 
    attendees att 
        inner join registrations reg
            on att.id = reg.attendee_id
        inner join sessions ses
            on ses.id = reg.session_id
;
--------------------------------------------------------
--  DDL for View V_SPK_SESSION
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "REG_APP"."V_SPK_SESSION" ("SPEAKER_ID", "FIRST_NAME", "LAST_NAME", "SESSION_ID", "SESSION_NAME", "SESSION_DESCRIPTION", "SESSION_DATE", "DURATION", "EVENT_ID") AS 
  select 
    spk.id as speaker_id, 
    spk.first_name,
    spk.last_name, 
    ses.id as session_id, 
    ses.name as session_name, 
    ses.description as session_description, 
    ses.session_date, 
    ses.duration,
    ses.event_id
from speakers spk
    inner join sessions ses
        on ses.speaker_id = spk.id
;
REM INSERTING into REG_APP.ATTENDEES
SET DEFINE OFF;
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (1,'Orlando','Gee','orlando0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (2,'Keith','Harris','keith0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (3,'Donna','Carreras','donna0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (4,'Janet','Gates','janet1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (5,'Lucy','Harrington','lucy0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (6,'Rosmarie','Carroll','rosmarie0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (7,'Dominic','Gash','dominic0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (10,'Kathleen','Garza','kathleen0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (11,'Katherine','Harding','katherine0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (12,'Johnny','Caprio','johnny0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (16,'Christopher','Beck','christopher1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (18,'David','Liu','david20@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (19,'John','Beaver','john8@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (20,'Jean','Handley','jean1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (21,'Jinghao','Liu','jinghao1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (22,'Linda','Burnett','linda4@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (23,'Kerim','Hanif','kerim0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (24,'Kevin','Liu','kevin5@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (25,'Donald','Blanton','donald0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (28,'Jackie','Blackwell','jackie0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (29,'Bryan','Hamilton','bryan2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (30,'Todd','Logan','todd0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (34,'Barbara','German','barbara4@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (37,'Jim','Geist','jim1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (38,'Betty','Haines','betty0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (39,'Sharon','Looney','sharon2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (40,'Darren','Gehring','darren0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (41,'Erin','Hagens','erin1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (42,'Jeremy','Los','jeremy0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (43,'Elsa','Leavitt','elsa0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (46,'David','Lawrence','david19@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (47,'Hattie','Haemon','hattie0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (48,'Anita','Lucerne','anita0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (52,'Rebecca','Laszlo','rebecca2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (55,'Eric','Lang','eric6@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (56,'Brian','Groth','brian5@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (57,'Judy','Lundahl','judy1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (58,'Peter','Kurniawan','peter4@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (59,'Douglas','Groncki','douglas2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (60,'Sean','Lunt','sean4@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (61,'Jeffrey','Kurtz','jeffrey3@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (64,'Vamsi','Kuppa','vamsi1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (65,'Jane','Greer','jane2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (66,'Alexander','Deborde','alexander1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (70,'Deepak','Kumar','deepak0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (73,'Margaret','Krupka','margaret1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (74,'Christopher','Bright','christopher2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (75,'Aidan','Delaney','aidan0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (76,'James','Krow','james11@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (77,'Michael','Brundage','michael13@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (78,'Stefan','Delmarco','stefan0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (79,'Mitch','Kennedy','mitch0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (82,'James','Kramer','james10@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (83,'Eric','Brumfield','eric3@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (84,'Della','Demott Jr','della0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (88,'Pamala','Kotc','pamala0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (91,'Joy','Koski','joy0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (92,'Jovita','Carmody','jovita0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (93,'Prashanth','Desai','prashanth0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (94,'Scott','Konersmann','scott6@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (95,'Jane','Carmichael','jane0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (96,'Bonnie','Lepro','bonnie2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (97,'Eugene','Kogan','eugene2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (100,'Kirk','King','kirk2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (101,'William','Conner','william1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (102,'Linda','Leste','linda7@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (106,'Andrea','Thomsen','andrea1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (109,'Daniel','Thompson','daniel2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (110,'Kendra','Thompson','kendra0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (111,'Scott','Colvin','scott1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (112,'Elsie','Lewin','elsie0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (113,'Donald','Thompson','donald1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (114,'John','Colon','john14@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (115,'George','Li','george3@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (118,'Yale','Li','yale0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (119,'Phyllis','Thomas','phyllis2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (120,'Pat','Coleman','pat2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (124,'Yuhong','Li','yuhong1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (127,'Joseph','Lique','joseph2@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (128,'Judy','Thames','judy3@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (129,'Connie','Coffman','connie0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (130,'Paulo','Lisboa','paulo0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (131,'Vanessa','Tench','vanessa0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (132,'Teanna','Cobb','teanna0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (133,'Michael','Graff','michael16@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (136,'Derek','Graham','derek0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (137,'Gytis','Barzdukas','gytis0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (138,'Jane','Clayton','jane1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (142,'Jon','Grande','jon1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (145,'Ted','Bremer','ted0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (146,'Richard','Bready','richard1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (147,'Alice','Clark','alice1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (148,'Alan','Brewer','alan1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (149,'Cornelius','Brandon','cornelius0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (150,'Jill','Christie','jill1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (151,'Walter','Brian','walter0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (154,'Carlton','Carlisle','carlton0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (155,'Joseph','Castellucio','joseph1@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (156,'Lester','Bowman','lester0@adventure-works.com');
Insert into REG_APP.ATTENDEES (ID,FIRST_NAME,LAST_NAME,EMAIL_ADDRESS) values (160,'Brigid','Cavendish','brigid0@adventure-works.com');
REM INSERTING into REG_APP.EVENTS
SET DEFINE OFF;
Insert into REG_APP.EVENTS (ID,EVENT_NAME,EVENT_DESCRIPTION,EVENT_START_DATE,EVENT_PRICE,EVENT_END_DATE) values (1,'Ignite','Microsoft Ignite is the place to learn from the experts, connect with your community, and explore the latest technology.',to_date('21-SEP-20','DD-MON-RR'),1200,to_date('25-SEP-20','DD-MON-RR'));
REM INSERTING into REG_APP.REGISTRATIONS
SET DEFINE OFF;
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (1,to_date('02-MAR-20','DD-MON-RR'),1,1);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (2,to_date('03-FEB-20','DD-MON-RR'),1,2);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (5,to_date('04-MAR-20','DD-MON-RR'),2,3);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (6,to_date('18-MAR-20','DD-MON-RR'),2,6);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (24,to_date('16-MAR-20','DD-MON-RR'),2,52);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (26,to_date('16-MAR-20','DD-MON-RR'),2,41);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (27,to_date('16-MAR-20','DD-MON-RR'),1,25);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (43,to_date('24-MAR-20','DD-MON-RR'),2,114);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (63,to_date('24-MAR-20','DD-MON-RR'),2,148);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (83,to_date('25-MAR-20','DD-MON-RR'),2,56);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (85,to_date('25-MAR-20','DD-MON-RR'),1,56);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (86,to_date('25-MAR-20','DD-MON-RR'),2,136);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (87,to_date('26-MAR-20','DD-MON-RR'),1,5);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (89,to_date('26-MAR-20','DD-MON-RR'),2,5);
Insert into REG_APP.REGISTRATIONS (ID,REGISTRATION_DATE,SESSION_ID,ATTENDEE_ID) values (92,to_date('26-MAR-20','DD-MON-RR'),1,95);
REM INSERTING into REG_APP.SESSIONS
SET DEFINE OFF;
Insert into REG_APP.SESSIONS (ID,NAME,DESCRIPTION,SESSION_DATE,SPEAKER_ID,EVENT_ID,DURATION) values (1,'Serverless Signal R','Build real time messaging applications for web and .NET',to_date('21-SEP-20','DD-MON-RR'),1,1,60);
Insert into REG_APP.SESSIONS (ID,NAME,DESCRIPTION,SESSION_DATE,SPEAKER_ID,EVENT_ID,DURATION) values (2,'Hybrid updates in Azure with Julia White','Hybrid updates in Azure with Julia White',to_date('29-MAR-19','DD-MON-RR'),2,1,45);
REM INSERTING into REG_APP.SPEAKERS
SET DEFINE OFF;
Insert into REG_APP.SPEAKERS (ID,FIRST_NAME,LAST_NAME,SPEAKER_BIO) values (1,'Anthony','Smith','When Anthony is not evaligizing Azure technologies, he is watching baseball and cheering for his favorite team. Go Mets!');
Insert into REG_APP.SPEAKERS (ID,FIRST_NAME,LAST_NAME,SPEAKER_BIO) values (2,'Julia','Whitehall',TO_CLOB(q'[Julia leads the marketing team for Microsoft Azure, and is focused on how Microsoft presents its Applications, Infrastructure, Data and Intelligence capabilities to customers and partners. In addition to the primary focus on Azure, the team are also responsible for Microsoftâ€™s hybrid cloud assets; including SQL Server, Windows Server, Developer tools and management capabilities. Across this portfolio, Julia is responsible for the value proposition, global go to market strategy, and industry enga]')
|| TO_CLOB(q'[gement. She also works in partnership with engineering leadership to chart the product roadmaps. Julia joined Microsoft in 2001 as a product manager in the Enterprise Server team. In 2005, she moved to Microsoftâ€™s US sales organization to run channel marketing and sales incentives. In 2007, she returned to product leadership, taking on Exchange Server product marketing. Over the course of the next 8 years, she was instrumental in leading the productâ€™s evolution from an on-premises server technol]')
|| TO_CLOB(q'[ogy to establishing Office 365 as the leader in cloud productivity services. Julia has a bachelorâ€™s degree from Stanford University and a masterâ€™s in business administration from Harvard Business School.]'));
--------------------------------------------------------
--  DDL for Index SESSIONS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."SESSIONS_PK" ON "REG_APP"."SESSIONS" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index REGISTRATIONS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."REGISTRATIONS_PK" ON "REG_APP"."REGISTRATIONS" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index IX_ATTENDEES_EMAIL
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."IX_ATTENDEES_EMAIL" ON "REG_APP"."ATTENDEES" ("EMAIL_ADDRESS") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index IX_EVENTS_NAME
--------------------------------------------------------

  CREATE INDEX "REG_APP"."IX_EVENTS_NAME" ON "REG_APP"."EVENTS" ("EVENT_NAME") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index EVENTS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."EVENTS_PK" ON "REG_APP"."EVENTS" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index ATTENDEES_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."ATTENDEES_PK" ON "REG_APP"."ATTENDEES" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index IX_REG_SESS_ATTENDEE
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."IX_REG_SESS_ATTENDEE" ON "REG_APP"."REGISTRATIONS" ("SESSION_ID", "ATTENDEE_ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Index SPEAKERS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "REG_APP"."SPEAKERS_PK" ON "REG_APP"."SPEAKERS" ("ID") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" ;
--------------------------------------------------------
--  DDL for Trigger TRG_REGISRATION_ID
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "REG_APP"."TRG_REGISRATION_ID" 
  BEFORE INSERT ON REGISTRATIONS
  FOR EACH ROW
BEGIN
  :new.ID := REGISTRATION_ID_SEQ.nextval;
END;
/
ALTER TRIGGER "REG_APP"."TRG_REGISRATION_ID" ENABLE;
--------------------------------------------------------
--  DDL for Procedure GET_RANDOM_ATTENDEE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "REG_APP"."GET_RANDOM_ATTENDEE" (p_attendeeid OUT NUMBER) AS
BEGIN
    SELECT
        id into p_attendeeid
    FROM
        (
            SELECT
                id
            FROM
                attendees
            ORDER BY
                dbms_random.value
        )
    WHERE
        ROWNUM = 1;  
END get_random_attendee;

/
--------------------------------------------------------
--  DDL for Procedure REGISTER_ATTENDEE_SESSION
--------------------------------------------------------
set define off;

  CREATE OR REPLACE PROCEDURE "REG_APP"."REGISTER_ATTENDEE_SESSION" 
(
  P_SESSION_ID IN NUMBER 
, P_ATTENDEE_ID IN NUMBER
) AS 
BEGIN

    INSERT INTO registrations (registration_date, session_id, attendee_id) 
    VALUES (SYSDATE, P_SESSION_ID, P_ATTENDEE_ID);
    
    COMMIT;

END REGISTER_ATTENDEE_SESSION;

/
--------------------------------------------------------
--  DDL for Package UTILITY_SCRIPTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "REG_APP"."UTILITY_SCRIPTS" AS 
    PROCEDURE create_pg_table_script;

END UTILITY_SCRIPTS;

/
--------------------------------------------------------
--  DDL for Package Body UTILITY_SCRIPTS
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "REG_APP"."UTILITY_SCRIPTS" AS
  PROCEDURE create_pg_table_script AS
    
        CURSOR c_tables IS
            SELECT
                table_name
            FROM
                user_tables
            ORDER BY 
                table_name;
            
        r_table c_tables%rowtype;
    BEGIN
            OPEN c_tables;
            LOOP
                FETCH c_tables INTO r_table;
                EXIT WHEN c_tables%notfound;
                -- DBMS_OUTPUT.PUT_LINE( 'if not exist "schema/tables/' || r_table.table_name || '" mkdir "schema/tables/"' || r_table.table_name || '"');
                DBMS_OUTPUT.PUT_LINE( 'ora2pg -t TABLE -a ' || r_table.table_name || ' -o ' || r_table.table_name || '.sql --namespace REG_APP -c config/ora2pg_dist-my-migration-test.conf -b schema/tables/' );
            END LOOP;
            CLOSE c_tables;
    
    
    END create_pg_table_script;
END UTILITY_SCRIPTS;

/
--------------------------------------------------------
--  Constraints for Table REGISTRATIONS
--------------------------------------------------------

  ALTER TABLE "REG_APP"."REGISTRATIONS" ADD CONSTRAINT "REGISTRATIONS_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM"  ENABLE;
  ALTER TABLE "REG_APP"."REGISTRATIONS" MODIFY ("ATTENDEE_ID" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."REGISTRATIONS" MODIFY ("SESSION_ID" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."REGISTRATIONS" MODIFY ("REGISTRATION_DATE" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."REGISTRATIONS" MODIFY ("ID" NOT NULL ENABLE);
--------------------------------------------------------
--  Constraints for Table SESSIONS
--------------------------------------------------------

  ALTER TABLE "REG_APP"."SESSIONS" MODIFY ("SPEAKER_ID" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."SESSIONS" MODIFY ("EVENT_ID" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."SESSIONS" ADD CONSTRAINT "SESSIONS_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM"  ENABLE;
  ALTER TABLE "REG_APP"."SESSIONS" MODIFY ("NAME" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."SESSIONS" MODIFY ("ID" NOT NULL ENABLE);
--------------------------------------------------------
--  Constraints for Table EVENTS
--------------------------------------------------------

  ALTER TABLE "REG_APP"."EVENTS" ADD CONSTRAINT "EVENTS_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM"  ENABLE;
  ALTER TABLE "REG_APP"."EVENTS" MODIFY ("EVENT_START_DATE" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."EVENTS" MODIFY ("EVENT_NAME" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."EVENTS" MODIFY ("ID" NOT NULL ENABLE);
--------------------------------------------------------
--  Constraints for Table ATTENDEES
--------------------------------------------------------

  ALTER TABLE "REG_APP"."ATTENDEES" ADD CONSTRAINT "ATTENDEES_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM"  ENABLE;
--------------------------------------------------------
--  Constraints for Table SPEAKERS
--------------------------------------------------------

  ALTER TABLE "REG_APP"."SPEAKERS" ADD CONSTRAINT "SPEAKERS_PK" PRIMARY KEY ("ID")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM"  ENABLE;
  ALTER TABLE "REG_APP"."SPEAKERS" MODIFY ("LAST_NAME" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."SPEAKERS" MODIFY ("FIRST_NAME" NOT NULL ENABLE);
  ALTER TABLE "REG_APP"."SPEAKERS" MODIFY ("ID" NOT NULL ENABLE);
--------------------------------------------------------
--  Ref Constraints for Table REGISTRATIONS
--------------------------------------------------------

  ALTER TABLE "REG_APP"."REGISTRATIONS" ADD CONSTRAINT "REG_ATTEND_FK" FOREIGN KEY ("ATTENDEE_ID")
	  REFERENCES "REG_APP"."ATTENDEES" ("ID") ENABLE;
  ALTER TABLE "REG_APP"."REGISTRATIONS" ADD CONSTRAINT "REG_SESSION_FK" FOREIGN KEY ("SESSION_ID")
	  REFERENCES "REG_APP"."SESSIONS" ("ID") ENABLE;
--------------------------------------------------------
--  Ref Constraints for Table SESSIONS
--------------------------------------------------------

  ALTER TABLE "REG_APP"."SESSIONS" ADD CONSTRAINT "SESSION_EVENT_FK" FOREIGN KEY ("EVENT_ID")
	  REFERENCES "REG_APP"."EVENTS" ("ID") ENABLE;
  ALTER TABLE "REG_APP"."SESSIONS" ADD CONSTRAINT "SESSION_SPEAKER_FK" FOREIGN KEY ("SPEAKER_ID")
	  REFERENCES "REG_APP"."SPEAKERS" ("ID") ENABLE;
