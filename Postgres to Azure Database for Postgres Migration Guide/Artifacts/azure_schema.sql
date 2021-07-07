--
-- PostgreSQL database dump
--

-- Dumped from database version 10.16
-- Dumped by pg_dump version 13.3

-- Started on 2021-06-17 01:39:39

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP EVENT TRIGGER IF EXISTS log_ddl_info;
DROP EVENT TRIGGER IF EXISTS log_ddl_drop_info;

DROP TYPE IF EXISTS public.address;
DROP DOMAIN IF EXISTS public.color;
DROP SERVER IF EXISTS app_database_server;

--
-- TOC entry 12 (class 2615 OID 16487)
-- Name: fdw_reg_app; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA IF NOT EXISTS fdw_reg_app;


ALTER SCHEMA fdw_reg_app OWNER TO s2admin;

--
-- TOC entry 11 (class 2615 OID 16394)
-- Name: reg_app; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA IF NOT EXISTS reg_app;


ALTER SCHEMA reg_app OWNER TO s2admin;

--
-- TOC entry 2406 (class 3456 OID 16460)
-- Name: C; Type: COLLATION; Schema: reg_app; Owner: postgres
--

CREATE COLLATION IF NOT EXISTS reg_app."C" (provider = libc, locale = 'C');


ALTER COLLATION reg_app."C" OWNER TO s2admin;

--
-- TOC entry 4 (class 3079 OID 16477)
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- TOC entry 2929 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- TOC entry 658 (class 1247 OID 16465)
-- Name: address; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.address AS (
	city character varying(90),
	street character varying(90),
	state character varying(90),
	zip character varying(90),
	country character varying(90)
);


ALTER TYPE public.address OWNER TO s2admin;

--
-- TOC entry 656 (class 1247 OID 16461)
-- Name: color; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.color AS character varying(10)
	CONSTRAINT color_check CHECK (((VALUE)::text = ANY ((ARRAY['red'::character varying, 'green'::character varying, 'blue'::character varying])::text[])));


ALTER DOMAIN public.color OWNER TO s2admin;

--
-- TOC entry 238 (class 1255 OID 16469)
-- Name: attendee_insert_trigger_fnc(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE OR REPLACE FUNCTION public.attendee_insert_trigger_fnc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Reg_App.Attendees_Audit ( "Id", "LastName", "FirstName","EmailAddress", "AuditDate")
         VALUES(NEW."Id",NEW."LastName",NEW."FirstName",NEW.EmailAddress, current_user,current_date);

RETURN NEW;
END;
$$;


ALTER FUNCTION public.attendee_insert_trigger_fnc() OWNER TO s2admin;

--
-- TOC entry 239 (class 1255 OID 16496)
-- Name: log_ddl(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE OR REPLACE  FUNCTION public.log_ddl() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  audit_query TEXT;
  r RECORD;
BEGIN
  IF tg_tag <> 'DROP TABLE'
  THEN
   FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() 
    LOOP
      INSERT INTO Reg_App.ddl_history (ddl_date, ddl_tag, object_name) VALUES (statement_timestamp(), tg_tag, r.object_identity);
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION public.log_ddl() OWNER TO s2admin;

--
-- TOC entry 240 (class 1255 OID 16497)
-- Name: log_ddl_drop(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE OR REPLACE  FUNCTION public.log_ddl_drop() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  audit_query TEXT;
  r RECORD;
BEGIN
  IF tg_tag = 'DROP TABLE'
  THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() 
    LOOP
      INSERT INTO Reg_App.ddl_history (ddl_date, ddl_tag, object_name) VALUES (statement_timestamp(), tg_tag, r.object_identity);
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION public.log_ddl_drop() OWNER TO s2admin;

--
-- TOC entry 241 (class 1255 OID 16696)
-- Name: migration_performinventory(character); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE OR REPLACE  FUNCTION public.migration_performinventory(schema_name character) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
	row_table record;
	cur_tables cursor for select table_name, table_schema from information_schema.tables where table_type = 'BASE TABLE' and table_schema = schema_name order by table_name;
	count int;

begin

CREATE TABLE IF NOT EXISTS IF NOT EXISTS MIG_INVENTORY
(	
	REPORT_TYPE VARCHAR(1000), 
	OBJECT_NAME VARCHAR(1000), 
	PARENT_OBJECT_NAME VARCHAR (1000),
	OBJECT_TYPE VARCHAR(1000), 
	COUNT INT
);

ALTER TABLE MIG_INVENTORY REPLICA IDENTITY FULL;

	--clear it out...
	delete from mig_inventory;

	--count of tables
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'TABLES', 'TABLES', COUNT(*)
    FROM 
		information_schema.tables 
    where 
		TABLE_SCHEMA = schema_Name
		and table_type = 'BASE TABLE';
		
		--count of stats
		INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'STATISTICS', 'STATISTICS', COUNT(*)
    FROM
		PG_INDEXES pg
	WHERE
		pg.schemaname = schema_Name;
		
		--count of table constraints
		INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'TABLE_CONSTRAINTS', 'TABLE_CONSTRAINTS', COUNT(*)
    FROM
		information_schema.table_constraints
	WHERE
		TABLE_SCHEMA = schema_Name;
		
		INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'VIEWS', 'VIEWS', COUNT(*)
	FROM
		information_schema.VIEWS
	WHERE
		TABLE_SCHEMA = schema_Name;
		
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'FUNCTIONS', 'FUNCTIONS', COUNT(*)
	FROM
		information_schema.ROUTINES
	WHERE
		ROUTINE_TYPE = 'FUNCTION' and
		ROUTINE_SCHEMA = schema_Name;
		
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'PROCEDURES', 'PROCEDURES', COUNT(*)
	FROM
		information_schema.ROUTINES
	WHERE
		ROUTINE_TYPE = 'PROCEDURE' and
		ROUTINE_SCHEMA = schema_Name;
		
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'USER DEFINED FUNCTIONS', 'USER DEFINED FUNCTIONS', COUNT(*)
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	left join pg_language l on p.prolang = l.oid
	left join pg_type t on t.oid = p.prorettype 
	where n.nspname not in ('pg_catalog', 'information_schema')	;
	
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'TRIGGERS', 'TRIGGERS', COUNT(*)
	from information_schema.triggers;
		
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'USERS', 'USERS', COUNT(*)
    FROM
		pg_catalog.pg_user;
		
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT
		'OBJECTCOUNT', 'EXTENSIONS', 'EXTENSIONS', COUNT(*)
	FROM pg_extension;
	
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT 
		'OBJECTCOUNT', 'FDW', 'FDW', COUNT(*)
	FROM pg_catalog.pg_foreign_data_wrapper fdw;
	
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	SELECT      
		'OBJECTCOUNT', 'USER DEFINED TYPES', 'USER DEFINED TYPES', COUNT(*)
	FROM        pg_type t 
	LEFT JOIN   pg_catalog.pg_namespace n ON n.oid = t.typnamespace 
	WHERE       (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid)) 
	AND     NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
	AND     n.nspname NOT IN ('pg_catalog', 'information_schema');
	
	INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, COUNT)
	select 
		'OBJECTCOUNT', 'LANGUAGES', 'LANGUAGES', COUNT(*)
	from pg_language;
	
	for row_table in cur_tables loop
	
	 EXECUTE format('select count(*) from %I.%I', schema_name, row_table.table_name) into count;
	 
	 INSERT INTO MIG_INVENTORY (REPORT_TYPE,OBJECT_NAME, OBJECT_TYPE, PARENT_OBJECT_NAME, COUNT)
		SELECT
			'TABLECOUNT', row_table.table_name, 'TABLECOUNT', schema_name, count;
	
	end loop;
	
end;
$$;


ALTER FUNCTION public.migration_performinventory(schema_name character) OWNER TO s2admin;

--
-- TOC entry 235 (class 1255 OID 16454)
-- Name: get_random_attendee(); Type: FUNCTION; Schema: reg_app; Owner: postgres
--

CREATE OR REPLACE  FUNCTION reg_app.get_random_attendee(OUT p_attendeeid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    SELECT
        id into p_attendeeid
    FROM
        (
            SELECT
                id
            FROM
                REG_APP.attendees
            ORDER BY
                RANDOM()
			LIMIT 1
        ) AS attendees_subquery;  
END
$$;


ALTER FUNCTION reg_app.get_random_attendee(OUT p_attendeeid integer) OWNER TO s2admin;

--
-- TOC entry 236 (class 1255 OID 16471)
-- Name: hello_world(); Type: FUNCTION; Schema: reg_app; Owner: postgres
--

CREATE OR REPLACE  FUNCTION reg_app.hello_world() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN 'Hello World';
END
$$;


ALTER FUNCTION reg_app.hello_world() OWNER TO s2admin;

--
-- TOC entry 237 (class 1255 OID 16455)
-- Name: register_attendee_session(integer, integer); Type: FUNCTION; Schema: reg_app; Owner: postgres
--

CREATE OR REPLACE  FUNCTION reg_app.register_attendee_session(p_session_id integer, p_attendee_id integer, OUT status integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO REG_APP.registrations (registration_date, session_id, attendee_id) 
    VALUES (CURRENT_DATE, P_SESSION_ID, P_ATTENDEE_ID);
	
	SELECT 1 INTO STATUS;
END
$$;


ALTER FUNCTION reg_app.register_attendee_session(p_session_id integer, p_attendee_id integer, OUT status integer) OWNER TO s2admin;

--
-- TOC entry 1755 (class 1417 OID 16485)
-- Name: app_database_server; Type: SERVER; Schema: -; Owner: postgres
--

CREATE SERVER app_database_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'reg_app',
    host 'localhost'
);


ALTER SERVER app_database_server OWNER TO s2admin;

--
-- TOC entry 2942 (class 0 OID 0)
-- Name: USER MAPPING postgres SERVER app_database_server; Type: USER MAPPING; Schema: -; Owner: postgres
--

CREATE USER MAPPING FOR postgres SERVER app_database_server OPTIONS (
    password 'Seattle123',
    "user" 'postgres'
);


SET default_tablespace = '';

--
-- TOC entry 216 (class 1259 OID 16697)
-- Name: mig_inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE IF NOT EXISTS public.mig_inventory (
    report_type character varying(1000),
    object_name character varying(1000),
    parent_object_name character varying(1000),
    object_type character varying(1000),
    count integer
);

ALTER TABLE ONLY public.mig_inventory REPLICA IDENTITY FULL;


ALTER TABLE public.mig_inventory OWNER TO s2admin;

--
-- TOC entry 214 (class 1259 OID 16467)
-- Name: mysequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE IF NOT EXISTS public.mysequence
    START WITH 10
    INCREMENT BY 5
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mysequence OWNER TO s2admin;

--
-- TOC entry 203 (class 1259 OID 16406)
-- Name: attendees; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE IF NOT EXISTS reg_app.attendees (
    id integer NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    email_address character varying(200)
);


ALTER TABLE reg_app.attendees OWNER TO s2admin;

--
-- TOC entry 204 (class 1259 OID 16409)
-- Name: attendees_audit; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE IF NOT EXISTS reg_app.attendees_audit (
    id integer NOT NULL,
    lastname character varying(20) NOT NULL,
    firstname character varying(20) NOT NULL,
    emailaddress character varying(20) NOT NULL,
    username character varying(20) NOT NULL,
    audittime character varying(20) NOT NULL
);


ALTER TABLE reg_app.attendees_audit OWNER TO s2admin;

--
-- TOC entry 202 (class 1259 OID 16397)
-- Name: ddl_history; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE IF NOT EXISTS reg_app.ddl_history (
    id integer NOT NULL,
    ddl_date timestamp with time zone,
    ddl_tag text,
    object_name text
);


ALTER TABLE reg_app.ddl_history OWNER TO s2admin;

--
-- TOC entry 201 (class 1259 OID 16395)
-- Name: ddl_history_id_seq; Type: SEQUENCE; Schema: reg_app; Owner: postgres
--

CREATE SEQUENCE IF NOT EXISTS reg_app.ddl_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE reg_app.ddl_history_id_seq OWNER TO s2admin;

--
-- TOC entry 2947 (class 0 OID 0)
-- Dependencies: 201
-- Name: ddl_history_id_seq; Type: SEQUENCE OWNED BY; Schema: reg_app; Owner: postgres
--

ALTER SEQUENCE reg_app.ddl_history_id_seq OWNED BY reg_app.ddl_history.id;


--
-- TOC entry 205 (class 1259 OID 16412)
-- Name: events; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE reg_app.events (
    id integer NOT NULL,
    event_name character varying(300) NOT NULL,
    event_description character varying(2000),
    event_start_date timestamp without time zone NOT NULL,
    event_price numeric,
    event_end_date timestamp without time zone,
    event_pic bytea
);


ALTER TABLE reg_app.events OWNER TO s2admin;

--
-- TOC entry 209 (class 1259 OID 16433)
-- Name: jobs; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE reg_app.jobs (
    id integer,
    name character varying(50),
    last_run character varying(50),
    count integer
);


ALTER TABLE reg_app.jobs OWNER TO s2admin;

--
-- TOC entry 215 (class 1259 OID 16502)
-- Name: reg_app_seq; Type: SEQUENCE; Schema: reg_app; Owner: postgres
--

CREATE SEQUENCE reg_app.reg_app_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE reg_app.reg_app_seq OWNER TO s2admin;

--
-- TOC entry 206 (class 1259 OID 16418)
-- Name: registrations; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE reg_app.registrations (
    id integer DEFAULT nextval('reg_app.reg_app_seq'::regclass) NOT NULL,
    registration_date timestamp without time zone NOT NULL,
    session_id integer NOT NULL,
    attendee_id integer NOT NULL
);


ALTER TABLE reg_app.registrations OWNER TO s2admin;

--
-- TOC entry 207 (class 1259 OID 16421)
-- Name: sessions; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE reg_app.sessions (
    id integer NOT NULL,
    name character varying(300) NOT NULL,
    description character varying(2000),
    session_date timestamp without time zone,
    speaker_id integer NOT NULL,
    event_id integer NOT NULL,
    duration numeric
);


ALTER TABLE reg_app.sessions OWNER TO s2admin;

--
-- TOC entry 211 (class 1259 OID 16440)
-- Name: mv_attendee_sessions; Type: MATERIALIZED VIEW; Schema: reg_app; Owner: postgres
--

CREATE MATERIALIZED VIEW reg_app.mv_attendee_sessions AS
 SELECT att.id AS attendee_id,
    att.first_name,
    att.last_name,
    ses.name AS session_name,
    ses.session_date AS session_start,
    ses.duration,
    reg.registration_date
   FROM ((reg_app.attendees att
     JOIN reg_app.registrations reg ON ((att.id = reg.attendee_id)))
     JOIN reg_app.sessions ses ON ((ses.id = reg.session_id)))
  WITH NO DATA;


ALTER TABLE reg_app.mv_attendee_sessions OWNER TO s2admin;

--
-- TOC entry 208 (class 1259 OID 16427)
-- Name: speakers; Type: TABLE; Schema: reg_app; Owner: postgres
--

CREATE TABLE reg_app.speakers (
    id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    speaker_pic bytea,
    speaker_bio text
);


ALTER TABLE reg_app.speakers OWNER TO s2admin;

--
-- TOC entry 210 (class 1259 OID 16436)
-- Name: v_attendee_sessions; Type: VIEW; Schema: reg_app; Owner: postgres
--

CREATE VIEW reg_app.v_attendee_sessions AS
 SELECT att.id AS attendee_id,
    att.first_name,
    att.last_name,
    ses.name AS session_name,
    ses.session_date AS session_start,
    ses.duration,
    reg.registration_date
   FROM ((reg_app.attendees att
     JOIN reg_app.registrations reg ON ((att.id = reg.attendee_id)))
     JOIN reg_app.sessions ses ON ((ses.id = reg.session_id)));


ALTER TABLE reg_app.v_attendee_sessions OWNER TO s2admin;

--
-- TOC entry 212 (class 1259 OID 16447)
-- Name: v_spk_session; Type: VIEW; Schema: reg_app; Owner: postgres
--

CREATE VIEW reg_app.v_spk_session AS
 SELECT spk.id AS speaker_id,
    spk.first_name,
    spk.last_name,
    ses.id AS session_id,
    ses.name AS session_name,
    ses.description AS session_description,
    ses.session_date,
    ses.duration,
    ses.event_id
   FROM (reg_app.speakers spk
     JOIN reg_app.sessions ses ON ((ses.speaker_id = spk.id)));


ALTER TABLE reg_app.v_spk_session OWNER TO s2admin;

--
-- TOC entry 2761 (class 2604 OID 16400)
-- Name: ddl_history id; Type: DEFAULT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.ddl_history ALTER COLUMN id SET DEFAULT nextval('reg_app.ddl_history_id_seq'::regclass);


--
-- TOC entry 2921 (class 0 OID 16697)
-- Dependencies: 216
-- Data for Name: mig_inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mig_inventory (report_type, object_name, parent_object_name, object_type, count) FROM stdin;
OBJECTCOUNT	TABLES	\N	TABLES	8
OBJECTCOUNT	STATISTICS	\N	STATISTICS	9
OBJECTCOUNT	TABLE_CONSTRAINTS	\N	TABLE_CONSTRAINTS	32
OBJECTCOUNT	VIEWS	\N	VIEWS	2
OBJECTCOUNT	FUNCTIONS	\N	FUNCTIONS	3
OBJECTCOUNT	PROCEDURES	\N	PROCEDURES	0
OBJECTCOUNT	USER DEFINED FUNCTIONS	\N	USER DEFINED FUNCTIONS	13
OBJECTCOUNT	TRIGGERS	\N	TRIGGERS	1
OBJECTCOUNT	USERS	\N	USERS	2
OBJECTCOUNT	EXTENSIONS	\N	EXTENSIONS	4
OBJECTCOUNT	FDW	\N	FDW	2
OBJECTCOUNT	USER DEFINED TYPES	\N	USER DEFINED TYPES	2
OBJECTCOUNT	LANGUAGES	\N	LANGUAGES	6
TABLECOUNT	attendees	reg_app	TABLECOUNT	100
TABLECOUNT	attendees_audit	reg_app	TABLECOUNT	0
TABLECOUNT	ddl_history	reg_app	TABLECOUNT	66
TABLECOUNT	events	reg_app	TABLECOUNT	1
TABLECOUNT	jobs	reg_app	TABLECOUNT	0
TABLECOUNT	registrations	reg_app	TABLECOUNT	15
TABLECOUNT	sessions	reg_app	TABLECOUNT	4
TABLECOUNT	speakers	reg_app	TABLECOUNT	4
\.


--
-- TOC entry 2911 (class 0 OID 16406)
-- Dependencies: 203
-- Data for Name: attendees; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.attendees (id, first_name, last_name, email_address) FROM stdin;
1	Orlando	Gee	orlando0@adventure-works.com
2	Keith	Harris	keith0@adventure-works.com
3	Donna	Carreras	donna0@adventure-works.com
4	Janet	Gates	janet1@adventure-works.com
5	Lucy	Harrington	lucy0@adventure-works.com
6	Rosmarie	Carroll	rosmarie0@adventure-works.com
7	Dominic	Gash	dominic0@adventure-works.com
10	Kathleen	Garza	kathleen0@adventure-works.com
11	Katherine	Harding	katherine0@adventure-works.com
12	Johnny	Caprio	johnny0@adventure-works.com
16	Christopher	Beck	christopher1@adventure-works.com
18	David	Liu	david20@adventure-works.com
19	John	Beaver	john8@adventure-works.com
20	Jean	Handley	jean1@adventure-works.com
21	Jinghao	Liu	jinghao1@adventure-works.com
22	Linda	Burnett	linda4@adventure-works.com
23	Kerim	Hanif	kerim0@adventure-works.com
24	Kevin	Liu	kevin5@adventure-works.com
25	Donald	Blanton	donald0@adventure-works.com
28	Jackie	Blackwell	jackie0@adventure-works.com
29	Bryan	Hamilton	bryan2@adventure-works.com
30	Todd	Logan	todd0@adventure-works.com
34	Barbara	German	barbara4@adventure-works.com
37	Jim	Geist	jim1@adventure-works.com
38	Betty	Haines	betty0@adventure-works.com
39	Sharon	Looney	sharon2@adventure-works.com
40	Darren	Gehring	darren0@adventure-works.com
41	Erin	Hagens	erin1@adventure-works.com
42	Jeremy	Los	jeremy0@adventure-works.com
43	Elsa	Leavitt	elsa0@adventure-works.com
46	David	Lawrence	david19@adventure-works.com
47	Hattie	Haemon	hattie0@adventure-works.com
48	Anita	Lucerne	anita0@adventure-works.com
52	Rebecca	Laszlo	rebecca2@adventure-works.com
55	Eric	Lang	eric6@adventure-works.com
56	Brian	Groth	brian5@adventure-works.com
57	Judy	Lundahl	judy1@adventure-works.com
58	Peter	Kurniawan	peter4@adventure-works.com
59	Douglas	Groncki	douglas2@adventure-works.com
60	Sean	Lunt	sean4@adventure-works.com
61	Jeffrey	Kurtz	jeffrey3@adventure-works.com
64	Vamsi	Kuppa	vamsi1@adventure-works.com
65	Jane	Greer	jane2@adventure-works.com
66	Alexander	Deborde	alexander1@adventure-works.com
70	Deepak	Kumar	deepak0@adventure-works.com
73	Margaret	Krupka	margaret1@adventure-works.com
74	Christopher	Bright	christopher2@adventure-works.com
75	Aidan	Delaney	aidan0@adventure-works.com
76	James	Krow	james11@adventure-works.com
77	Michael	Brundage	michael13@adventure-works.com
78	Stefan	Delmarco	stefan0@adventure-works.com
79	Mitch	Kennedy	mitch0@adventure-works.com
82	James	Kramer	james10@adventure-works.com
83	Eric	Brumfield	eric3@adventure-works.com
84	Della	Demott Jr	della0@adventure-works.com
88	Pamala	Kotc	pamala0@adventure-works.com
91	Joy	Koski	joy0@adventure-works.com
92	Jovita	Carmody	jovita0@adventure-works.com
93	Prashanth	Desai	prashanth0@adventure-works.com
94	Scott	Konersmann	scott6@adventure-works.com
95	Jane	Carmichael	jane0@adventure-works.com
96	Bonnie	Lepro	bonnie2@adventure-works.com
97	Eugene	Kogan	eugene2@adventure-works.com
100	Kirk	King	kirk2@adventure-works.com
101	William	Conner	william1@adventure-works.com
102	Linda	Leste	linda7@adventure-works.com
106	Andrea	Thomsen	andrea1@adventure-works.com
109	Daniel	Thompson	daniel2@adventure-works.com
110	Kendra	Thompson	kendra0@adventure-works.com
111	Scott	Colvin	scott1@adventure-works.com
112	Elsie	Lewin	elsie0@adventure-works.com
113	Donald	Thompson	donald1@adventure-works.com
114	John	Colon	john14@adventure-works.com
115	George	Li	george3@adventure-works.com
118	Yale	Li	yale0@adventure-works.com
119	Phyllis	Thomas	phyllis2@adventure-works.com
120	Pat	Coleman	pat2@adventure-works.com
124	Yuhong	Li	yuhong1@adventure-works.com
127	Joseph	Lique	joseph2@adventure-works.com
128	Judy	Thames	judy3@adventure-works.com
129	Connie	Coffman	connie0@adventure-works.com
130	Paulo	Lisboa	paulo0@adventure-works.com
131	Vanessa	Tench	vanessa0@adventure-works.com
132	Teanna	Cobb	teanna0@adventure-works.com
133	Michael	Graff	michael16@adventure-works.com
136	Derek	Graham	derek0@adventure-works.com
137	Gytis	Barzdukas	gytis0@adventure-works.com
138	Jane	Clayton	jane1@adventure-works.com
142	Jon	Grande	jon1@adventure-works.com
145	Ted	Bremer	ted0@adventure-works.com
146	Richard	Bready	richard1@adventure-works.com
147	Alice	Clark	alice1@adventure-works.com
148	Alan	Brewer	alan1@adventure-works.com
149	Cornelius	Brandon	cornelius0@adventure-works.com
150	Jill	Christie	jill1@adventure-works.com
151	Walter	Brian	walter0@adventure-works.com
154	Carlton	Carlisle	carlton0@adventure-works.com
155	Joseph	Castellucio	joseph1@adventure-works.com
156	Lester	Bowman	lester0@adventure-works.com
160	Brigid	Cavendish	brigid0@adventure-works.com
\.


--
-- TOC entry 2912 (class 0 OID 16409)
-- Dependencies: 204
-- Data for Name: attendees_audit; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.attendees_audit (id, lastname, firstname, emailaddress, username, audittime) FROM stdin;
\.


--
-- TOC entry 2910 (class 0 OID 16397)
-- Dependencies: 202
-- Data for Name: ddl_history; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.ddl_history (id, ddl_date, ddl_tag, object_name) FROM stdin;
1	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
2	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
3	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
4	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
5	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
6	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
7	2021-06-16 20:23:16.793071+00	CREATE SEQUENCE	reg_app.reg_app_seq
8	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
9	2021-06-16 20:23:16.793071+00	ALTER SEQUENCE	reg_app.reg_app_seq
10	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
11	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
12	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
13	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
14	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
15	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.events
16	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.events
17	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.events
18	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.events
19	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.attendees
20	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.attendees
21	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.speakers
22	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.speakers
23	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.speakers
24	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.speakers
25	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
26	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.registrations
27	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
28	2021-06-16 20:23:16.793071+00	ALTER TABLE	reg_app.sessions
29	2021-06-16 20:25:09.253769+00	GRANT	\N
30	2021-06-16 20:25:09.253769+00	GRANT	\N
31	2021-06-16 20:25:09.253769+00	GRANT	\N
32	2021-06-16 20:25:09.253769+00	GRANT	\N
33	2021-06-16 20:25:09.253769+00	GRANT	\N
34	2021-06-16 20:25:09.253769+00	GRANT	\N
35	2021-06-16 20:25:09.253769+00	GRANT	\N
36	2021-06-16 20:25:09.253769+00	GRANT	\N
37	2021-06-16 20:25:09.253769+00	GRANT	\N
38	2021-06-16 20:25:09.253769+00	GRANT	\N
39	2021-06-16 20:25:09.253769+00	GRANT	\N
40	2021-06-16 20:25:09.253769+00	GRANT	\N
41	2021-06-16 20:25:09.253769+00	GRANT	\N
42	2021-06-16 20:25:09.253769+00	GRANT	\N
43	2021-06-16 20:25:09.253769+00	GRANT	\N
44	2021-06-16 20:25:09.253769+00	GRANT	\N
45	2021-06-16 20:25:09.253769+00	GRANT	\N
46	2021-06-16 20:25:09.253769+00	GRANT	\N
47	2021-06-16 20:25:09.253769+00	GRANT	\N
48	2021-06-16 20:25:09.253769+00	GRANT	\N
49	2021-06-16 20:25:09.253769+00	GRANT	\N
50	2021-06-16 20:25:09.253769+00	GRANT	\N
51	2021-06-16 20:25:09.253769+00	GRANT	\N
52	2021-06-16 20:25:09.253769+00	GRANT	\N
53	2021-06-16 20:25:09.253769+00	GRANT	\N
54	2021-06-16 20:25:09.253769+00	GRANT	\N
55	2021-06-16 20:25:09.253769+00	GRANT	\N
56	2021-06-16 20:25:09.253769+00	GRANT	\N
57	2021-06-16 20:25:09.253769+00	GRANT	\N
58	2021-06-16 20:25:09.253769+00	GRANT	\N
59	2021-06-16 20:25:09.253769+00	GRANT	\N
60	2021-06-16 20:25:09.253769+00	GRANT	\N
61	2021-06-16 20:25:09.253769+00	GRANT	\N
62	2021-06-16 20:25:09.253769+00	GRANT	\N
63	2021-06-16 20:25:09.253769+00	GRANT	\N
64	2021-06-17 00:37:22.16475+00	CREATE FUNCTION	public.migration_performinventory(character)
65	2021-06-17 00:37:22.16475+00	CREATE TABLE	public.mig_inventory
66	2021-06-17 00:37:22.16475+00	ALTER TABLE	public.mig_inventory
\.


--
-- TOC entry 2913 (class 0 OID 16412)
-- Dependencies: 205
-- Data for Name: events; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.events (id, event_name, event_description, event_start_date, event_price, event_end_date, event_pic) FROM stdin;
1	World Wide Trade	Contoso WWT is the best trade conference in the world. WWT allows import and exporters to connect with your community, and explore the latest technology.	2020-01-01 00:00:00	1200	2020-01-01 00:00:00	\\xffd8ffe000104a46494600010200006400640000ffec00114475636b7900010004000000640000ffee000e41646f62650064c000000001ffdb008400010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202020202020202020202030303030303030303030101010101010102010102020201020203030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303ffc0001108009000ec03011100021101031101ffc400b8000100030002030101000000000000000000090a0b0708040506030201010001050101010000000000000000000005030406070908010210000006020102030209060b0705000000010203040506000708110912130a21143122b415357597d71a41165658b8395161713274d5d6b7981959422324177738788152337627110002020102030505050704030000000000010203041105211206314151220761718113143242522308f0a1b1c1d162159172432463b327ffda000c03010002110311003f00bfc600c0180300600c0180300600c0180300600c0180300600c0180300600c0180300600c0180300600c0180300600c0180300600c01805037bfc7a93b9e1c3bee07b13879c3e5f5eeafa7e8988a333b5db2cb4183d836ad8170bad2207603c7299ad00fe160aaf0d156a66c9b3641995d9dd3670baae4e9ac920801df3f4caf7d0e56f73abff2078f7cbb6d49b35c759506276cd2b67536acca92e9f412f686b55b0d62d70510a9201caed5e4e47ad1ce59b5686048ae08e01537967002dff80300600c018071e6ddd86c7516a8d9db62518ba948cd61af6e9b0a463191d34dec8b1a5d6e4ac8ed8b43ac20891d3b6f1a64d3137c503983afb300cb2aebeaeeef1162bb4dd8ead78d29afeacfa5d57b0daf62b4a546761e0a2417f13585f9f6d084b5ae53a372811770abd05553898c404404a4201a207676e76d9bb91f6f0e3ff2daf55387a55fef6c2d5037e83ad99d7e6c1ae3afae53d459b99ac22fdd3e906103647101f383766e1770b312b9f7632ee052f3d4024e300600c0180300600c0180300600c0180300600c0180300601d60d93cdce18e9ab1af4edbdcb6e33eacb6b52f8dd55f62ef5d5f4ab0b62898c4eae21ac9688d9147e31043e3261f0601f55a6f945c67e452f3ed78fdc86d1fbc9cd5128f5ed0df506d7a26ca5eb884b9dda714b4ea54d9e995221293523d72b733804c1614540275f01ba019317a9b7f7dff387eb8d31fb3aea3c0257bd12dff7e1cb3ffc490fef8b5d601a10ed9e667107425a93a2ef2e5471cb4d5d9688676046a1b57766b5d7d68560645c3d68c26d381b65962654f12f9d46b849172090a2a288285298448600038cbfccdbb6f7fa8070a7fc52e8ff00edc600ff00336edbdfea01c29ff14ba3ff00b71803fccdbb6f7fa8070a7fc52e8ffedc600ff336edbdfea01c29ff0014ba3ffb71807b7e505f68db4380bc99bfeb5b955761512d3c56def2759ba522c1136aa9d8a34dac2dc896420ec504edf444b3232a91ca0aa0b284131443af501c030d0c035c7f4a68807649e3308880005c79042223ec0000de57cea223f9003009543f731edc4928a22a73f385a9ac928745544fca2d22555359338a6a2474cd770395422851289443a80874c03b5340d93aef6bd6d9dcb575f299b22a321ed6169a1d9e12df5d7bf14a7106b355f7d211cb8810e022055044004300fb4c0180300600c0180300600c0180300600c0180300ac0faa87b9bed7edf5c24a3d038f9667f44ddfcb7b858a8317b1219ca8c6c942d674d866127b367a9b22975562ae0f95b143c4b57a9f85c30424dc3a6ca22f116cb100ca464646425e41f4b4b3e79292b28f1d48c9c9c8ba5dec848c83d5cee5e3e7cf1c9d572ede3b72a99455550c63a873098c222223805f07d0e650fcfdee307f0fb7f3438d251374fc9f3cee910289ba7f2f40fe5c02063d4dbfbeff009c3f5c698fd9d751e012bde896ff00bf0e59ff00e2487f7c5aeb00e02f595874eed54ef67c3c36d3a3fcbffe87ba83aff1fc18054e300600c01806ba7db5c003d337ac3d9d03fcbb7770fc1d3e1aa6cf111ffd447aff001e01916601ae17a557f72171b3ff00b6721bfbefbee0192e5ac00b69b214a0052967e600a5000000009172000001ec0000c0254bb33773ddd3db2f995aa6fb52ba5813d1771bd566b1c8cd52320f17a75eb5c4e4935869d985ebbe79587e7cd3235d9e460e48854dd20edb150328666e1d375c0da113508aa6455330193508550860f80c43940c5307f1080e01fde00c0180300600c0180300600c0180300600c02833eb96fa0bb667d6dcbff91f19700cfb700b6efa42bb806a8e26735f6b71f373d821e955ae6554a9157a45d275e7b8c534dc9af272697a354241eae29c7c6b7bec5dde59ab770b9ca0796458b52fc6741d00b28f785f4b6d1fb98f2b257977acb92cb71e2fd7e83aec66dcafcdeb65b65572d9355183615681b7422adeef507b5b91355a219b278d7a396ce05a1172794a996f380ed0f64eec35abfb2ba7bc76f5af9003b9f68ecaabb2af4fdf242b2d357d0b5eeb0acbf71657ec58c6bcb358d532b2afd06ef25649f3f04934e3d02228a052aea38033d9f503f3ae89dc1fba0ef1dd1a9650b3da72a4c6aba5b5459532a8446d755d6b1ea3391b63105143f8a16cf7690977d187f0a465631c3739d322a639400856c0180300601aa77a5fb9a9a3f9b7dab21784d6f938975b578e750b7e90dabac9f3d1672969d2f6d7d3e5a7dc61db11c15e3bad3faa580609e2c81fcc6b251ea8a85448bb432a04595dfd0f293abbceb8d71dc206175d3998596ad45dcb8fc362b94440aab78916133350db4eb70d3d28c501f00b9458c7a4e4c5f1f92878bc2502c4db0e738abe9d3ecf4a54195c1c3b83d2baf2df5dd54ded7248257adf1c82be2f3f626ac98b169e62a57569bf4eacf1d119a6a3780844d454dd1b3331f00c779c2cab95d670b9c5459c2ca2cb283f09d554e63a871fe331cc23807b1aff00d3d09f5bc6fcb11c037d38cfa363ff00a0b4f93a78079d80300600c0180300600c0180300600c0180300a0cfae5be82ed99f5b72ff00e47c65c033edc01804cde85f508f789e3752e275eeb6e6ddfddd4205a030848cd955ad71b91d45b12fb1164d27f6c532e5642326840022088bc145ba60044ca52001700e2be5af7a7ee83ce1a73dd71c91e5f6c5b76b894300ccebdadb3a9eaea5d8532f41235b4577565769b1d6a8f4d402a856d24476dc8a90aa0100e5298008b8c0180300600c0393b4f6e9dbbc7cd8301b63466cbbbea4d95575c5c40de35ed9256ab648e13f42b8412938872d5c28c5ea41e5b96ca09dbb9444c9aa43a66314409a78cf53e77c08b862c2a5cd572ed12a22815fc9e8ee3a494cf844804f19a59dea555f1d6000ea0731c4fd7dbd7ae01159ca9e6b72bf9bd776bb0f961be7626f2b4c6a2e5bc22f749a32d0f586af7dd45f33a85563d26154a8337e664899c2318c9a26b9d229940318a0380757700f6f5ffa7a13eb78df9623806fa719f46c7ff4169f274f00f3b00600c0180300600c0180300600c0180300601419f5cb7d05db33eb6e5ffc8f8cb8051b38bfc5cdebccdddb50e3a71ae88b6cadc97c4ec0b5529a84e56ab8acaa555adcb5be7d42cc5be660201a84757609db91f39d26270444a4032862944096cfc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef600fc319df07f52093fb6de38fdef601c2fc87ec23dd8f8a7a62f9c84df5c4e90a26a1d6518d262f16e536b68e9e241463e968f836ce8f0f59d97333cf8a7949541212b66ab1cbe67884a04298c00449d7fe9e84fade37e588e01be9c67d1b1ffd05a7c9d3c03cec0180300600c0180300600c0180300600c01805067d72df4176ccfadb97ff0023e32e015fdf4b37efc7e1cfd5bc8afd98f70e01af4601e86d169ac522bb336fb9d8a0ea554aec7b896b059acd2cc20a020e2da105475232f3126bb58f8e62d930ea75565084287c2218045cd5fbeb7685b96c54755d7f9ffc7b736f74fdbc5b2f7bb33b87ab4848bb702d1ab38ebfccc647d0a41670e00084f2648e071317c223e22f502579bb86ef1ba0eda2e8ba6ae9149c3672dd522eddc375c855515d059231935915933018a628894c510101e9807ed80469f223bc5f6c2e28dfd7d57bef9a7a528db1d8bc4984cd2d29c7b6cb0569e2c21e16d6d8fa4c6d8d5a92e52980c72497ba98841031800a20380773746f20747f2675f45ed6e3ded9a06e6d713075516172d73678ab541a8e9b8815d47aeee29cb806328ccc2055daae09b940dec50851f6601cbf80757b943cd6e26f0aaaf1d72e55f2035968b829a70ab48152f964691d2963748140ee5bd6abc90b9b0d8956a430196064d57144a2027f080f5c038db89fdcd780dce47efa178a9ca8d4fb86cd1accd22fa990936ac4de9b4713af99247a359da41db4f1a8f4e877056664483ec3180700ef560109dea33fdca7cfaffa6552fef735de018e7d7fe9e84fade37e588e01be9c67d1b1ff00d05a7c9d3c03cec0180300600c0180300600c0180300600c01805067d72df4176ccfadb97ff23e32e015fdf4b37efc7e1cfd5bc8afd98f70e01af46019d6facfb9ebb45d6ebd37dbc2a3609aae6a183d6d0bbd76e44c73b55931d9b72b458e65850e2ac69a4043cac1ebd6152348356c7399a2925260ba8999764d54440a2ce01a5c7a34f9d1b537c71877ff0011368cecbdb58712a675e4a6a09e9a74a3f7d0dac369a16d40bad88f16319c9e129560a4385e308a98e2d9acafba24246ad5ba290130bea1ee6bec8e07f6afdefb6f4d49baaf6dab8c85434ad06dccba95dd2a4b664b7cdd376d60b1544d469370b4d6926a45b82f885bca8b657c2602086018e6bf7efa55f3d93937aee4a4a49db87f2322fdc2cf1f3f7cf163b876f5ebb70751c3a76e9c2863a8a1cc639ce6131844444700b117a61b9cdb538a3dd1b46ea883b24a9b4bf2d6d0d74a6d9a08aeedc41cb49cfb190435bdc1bc582e566d6d153ba9da14921e59962453a7cdfa811c18400d705f3c423993c90746123662d5c3c706294c731506c91d754c0428098c209907d81ed1c030f7ee3fcddda9dc2798dbab937b52c32f2ca5bee132d35fc048b950f1faef554549bc6d40d7f5e8ff0030cce26360207cbf38a81480f241472f56f1b972baa703ac5a7b70ecfe3f6d0a36e9d2f779ed71b4f5ad858da69176acbbf7398809b8f3899270818c455bba6ae1239d074d5c26b347ad5551bb8495415513301b81f05790923cb1e18f16393333108404def6d09ab768cec234130b28b9eb8d3e2a666d94789cea2831a84ab9581b09844e28783c5f1bae011f5ea33fdca7cfaffa6552fef735de018e7d7fe9e84fade37e588e01be9c67d1b1ff00d05a7c9d3c03cec0180300600c0180300600c0180300600c01805067d72df4176ccfadb97ff23e32e015fdf4b37efc7e1cfd5bc8afd98f70e01af46014f1f54c7645dc9cfb88d67cc6e21d502f9c80d375573ae7646a862ab56b65d9fa9cb28fac35d94a52af5cb567216ed7b372d22268b3082f2cc248deec7170cd16af00cf1eadc0be6edd361b6d4d58e21f252576539906b1614b2694d8ade75a3b78e859a2328cde579b0c33405ca6051c3b141ba25218ca1ca5298c006a2be9b8ed0974ed5fc4db848ef8462db728b92f3d016fda70510fdb4bb2d7155aab07ed35e6b052658aee2326a760fe7e937f2ae999ced01f4999aa2a3849a26e970248bbaa702603b96705b78711e5a69bd566ef5131b35aeae4e5b0ba6f51d9f4b966767a44c3d493228e0d0abcbc7158ca151007078a78e489081cc5100320de4c76bde7e711f67cb6a6dd7c55dcf0f60612c78a8b98afd0acb70a45c80ce956cc2468d75adc648d7ad31f2be578d0f765857001f02a926a8193281697f4c3f61ae4d31e52ebeee15cb9d6368d23ac34b232b62d2543d8512ad76fdb3b634b43bf8087b2bea64bb64e76b948a733945e45170f9264e5ec9a6c8cd8aab62ac7c034693140c02530018a601298043a808087410101f8404300c98fbdf7a7fb969c27e4e6d4d93a1b4adef73f0ef65dd672ebad2dbaaeaf2f7477ac595a5fba9a5f58ec4aed75a48ccd64f4c76e1462c24d548d1b271c9b6541c11d9dc346e0745fb79764ce7cf711db958a450b486c0d6fac1c4c4693616ffd9b4c9daaeb7d7f585ce65246611773c8431eef3a9b248fee70d1275ddba70648aa0b66e651d2406c59a174c52b8e5a4751680d6ed566541d2bada97aba9cddd28559e16bb46af47d6e2947eb94898399070d238aa3857c202aac631843a8e01f05cc3e29eb1e6ff1af6af15b732f686dacb714347415b57a5cb3782b3a6ca2ec30f666c3132aee3a59b34546460d10389dbaa5324262f4f8dd400ad15bbd187db324bca7346dcdcbfa0ca365d172d5c7e7c6b0b53122a81814279cc6635326bac4f30a03d01c93f83ae016ed6e88366e8372984c5411491031ba75302442900c3d3d9d440b807ed80300600c0180300600c0180300600c0180300a0cfae5be82ed99f5b72ffe47c65c02bfbe966fdf8fc39fab7915fb31ee1c035e8c0180300600c0180300601e3a2edab855ca2838456599aa445da49aa43a8d963a29b8224b90a22648e741529c00dd044a601cb5a3370f2aebb1f1adaecbf1e6a16c6324e55c9c633519a4f58b70946493d1b8c93ec655b31efaa10b6d84a35d91728369a5249b8b717de94934daef4d1fd2ee1bb444ebb95916cdd20015165d42228a651102809d450c521004c201ed1f8472e8a470a5d63af4daf3016446d919114e8b6f24abe55eb7220ca350311b8386d24928f53095564800a089fc498a46208801443a9fcdbea26d1ea6627a93b5f57e36f98781d01855644ae95d050a71e0d56acaf2232ba3f532c8e0aa9f341d4e0dc545a4ecda3d3399d2b774be5ecb6edf7e4751df3ad41424e53b25acb9655b507f2957c5cd692e74d26da7a47946bd6aaedada19ed765da4ab74ce29aa2dce605515007f9abb754a9b8404c1ed2f8c85f107b43a87b7375f4af5a74af5be03dcfa533a8cdc38c9c64eb6f9a125dd384946707de94e2b55a496a9a6609bc6c5bc6c190b1778c7b28b9ad5292e0d78c64b58cbc1e8de8f83e27b65deb56e47475562f46487bcba22606596451f0a862a866e8828b881ca91bc20051137847a75e993f97934e162d99992dac7aa129c9a8ca4d462b56d4629ca5a25d914dbee4d91b4d53bed8d1568ed9c9249b4b8b7a2e2da4bdeda47a4a9dae2ae70e9ce430b8166a2ee5b7474dd46cb1556aa992380914000314c0006012888743741e860100c5fa1bae364f50ba7e1d49d3eedfa09db657a590957252ae4e2f849714f84938b6b47a3d24a5152dd41b067f4dee32daf71e4fa9508cbcb2525a496ab8af0e29a7a766ab54d37f4b99810a300600c0180300600c0180300600c0180300a0cfae5be82ed99f5b72ffe47c65c02bfbe966fdf8fc39fab7915fb31ee1c035e8c02acfea50efa373ed7545a071fb8c89c2a9cb2df35c98b3a3729c66ca6e3b486b266f4f0285cd3ae3ef319cddced73893b6f049bc4978e6ff363b5dd24af810417028075befadddeeafb27fe6ab0ee05c8d7b673be07cbc7582e8a59684e4de679866aaeaf9d6d21ae0b1c6f6941ba716448851e84297d9d00d30bb06777a4fbb8712a56e7788487a97243484f465077cd76be0646bb2ef64e30f2353d975462b3976ee2ebb7b66cdd94592ca18eca4e3de22431d02a0aa8077f7b88f36b5ff6ece1beefe5eec78f713b0fa9eb6dd785a9b371ee6f6ed79b1cab0ab50a9ad9e037782c0b62b6ccb46ee1df92b158b432ae4c4311130601941f26fd425ddbb93bb224afd23cc4da9a7228f2abbfadeb6e3ed8e4f50d0ea0c8e6016b10c9ad51d339bb122cc850007138fa51e282222654407a00167ff4d9fa8c3911c8ae43577807cf2b6a7b566f66b09b1d01be1f46308cbb05bebb10f6c2eb5aec43c2306111618d9caec53b562a5d4491914641b03572a3df7d44ed00be9601181ca4ee0dc54e12bcb6326aebfe616e89937bd39d654c9249dba60f0ad8a66df9e336a19789a4471d5382a722de74898ab19445aaa4e805c5fa4fd34e9ce9addf71def61c67466eeb746cbe4e52926d24b4845be1172e69b4befce5c547962a437deb0dc771c3c6dbf71b7e6d587071ae2924d26f5d64d77e9a475fc315c1bd5b87eb6a5cdcee42f5aceef9b3ada438f8bb8424a0f59c020ed82128c4142b98f76956dcb8f7eb0bdf2fc074e567d4f2487ff7acda10a3e1cd41eaa7ea9fa07d3776ecdd30a1be757c1b8c9572d31689ae0d5d7c75e7945f6d54733d572cecad995748fa49d51d60e199bb6bb7ec8f8ae65f9b35dbe4adf627dd3b34edd6309224ceb6de4ebb49aad054b65ced1094f8f246c438bad9646d13264886318157f2922a1d77ae03c7e1298dec49202a698153294a1cddf507d54eb9f53b3feb7ab73656d11973578f5a556355e1f2e98f97992e1f327cf6b5c1cda3d5fd31d1db0748e2ac7d9e951b34d256cdf3db3ff74df1d3fb63cb1d7b228fa3879c99af3d2c8c149bc897c52193072c96148e243808188a1440c92c9fb7af84e5317afb7a6635d35d53d45d1dbac37be97ccbb0b73870e7adfda5dbcb641a70b20fbe1646507dba6a4b6ebb46d9bde1cb0375a617e2cbba4bb1f8c5ad25197f745a7ed22bb66688e5be8edad37c96e2d6ebd876db64a3833eb4c1d9e794b05be65a945438c5c8253665e0b64c03721c4add8bc448e9a17a7baf550a4397a1fe927eb13a7f7d855d3feaad556ddb9708c73aa8bfa4b1f66b7416b2c693ef9c79a9ef7f291e5aeb5f44376daa73dd7a42c9e562f6ca89bfce8afec93e16a5f865a4fb1273648270efbc76aad90bb1d5fc96878fe3e6d341d1a20659649cc6ead9a962a824708aee24c7dff5ccb28f3c607692c633529fa003e3a870483d878db7e0d7855dbb1fc896d538f3d7f2793e5b8cf59f341d7e49464db973475e66dbefd4d34f72ba77cabdcfe643353e597cce64f55c3497379a2d25a692ece089b241741d228b96cb24e1bb8488b20e10508aa2ba2a940e92a8aa98988a24a10c025314440407a86532ecfd700600c0180300600c0180300600c0180300a0cfae5be82ed99f5b72ff00e47c65c02bfbe966fdf8fc39fab7915fb31ee1c035e8c0336af5a5712366573963a179a8dd84a4be9cd9fa8a2b47bf9a49b3c731b4bd97aee72d7616b0128f00a665144ba55ed02ee3123188674ac64918a03e498700a4e601a3b7a29b8a3b3f5de83e5872cae317210342e43d9f5cd07542120cdcb335ae3b4d0de94b65d63856f024fabc361bc7cd2d9c10a6299ec63e4c0c0290808131fea5fe2a6d0e5b768edf351d390b276abe6b29ca36f4674d856aabe98b6c16b69651d5ca2e258b72a8ea4655953a45fc8b668811470f176246e890caaa428818fd6013dbe9abe2aecfe4bf770e304ed26165cf4be3a5bd0df7b66e0d1259389a9d6a94d9e3982672520500448eeeb6d06712d9af8bce70470b28528a282e6201a66772fa7f3c2d7ae7cbe23dad8b0ad271eb16f557aa11785dcd3641f79f386ab6a59e0b618d16a6201d9b10612a73947ca59703f925bcc4963465f9eb8f73eef8a2cb32395287fd77e5ef4bb7e0ff006653067e2e66164a662ec71f29133ec1d3d4a723e71abb6330ca4486399f125db481127adde955f10ade714140375137b7ae643534e716bb3546336a6a324f83d1964bd7d7798afc140249aa1211a30d106164e1431c805347b61f1b371f18edc443da1d3a907f297f2e700f7cae33de731f63fabbff00f6ccecb47a770375d9f16c92f9797f4d579e2bb7c91fb4bb25efedf69d9080b543d8d3ff00815fc0e8a5f12d1ee3c247697f08949d44aba61ffbc8221fc3d3e0c849d72876f6181ee9b2e7ed33ff00b31d686f84e3c62fe3f75fb1e9ecd4f1ee579a9ebf883cddc26da42b10030200b98547afd52875f768c60901ddc8381f83c29907a7c26100f6e5c616065ee377c8c3839d9dfa762f6c9f625eff00815361e9cdefaa3396ddb0e3d99193dfa708c17e2b26f48c23ed935af726f811d5b639756ab67bcc2ebf4dcd36bca78d152544e4fcea93447a94441c2463a3048285ff00610132fd07daa87c19b1f68e8fc4c4d2fdc1abb23f0ffc71f87de7efe1ec3d55d13e86ecbb2726e1d50e19fbaad1aaf47f4d5bff006bd1dcd78cd287841f690c3b196152ef6e5dc286584f34f0cb2ca9ccb1d53fc4f30ca287131d550c6fe77511308fc3edcebffa390ffe59d3f5c124bfc6d7a25c3be4719ff52dc90f5ffac2314a35c77bb9249249251824925c12496892f71627ed3b41ee3f4a94611cfde3388e2f3623255d40eda78bce240ddf316efcadf50a0c1e1ec100f9b26e8a55d239d184456154a744ee4a6e92db5f52f4df566d6b79e9fbe393872b6ead590e09ce8b674d89ebda9595c927f7a3a4937168d733dab7ad9b2de0ee35baa6a10938cb8f96c84671d34ec7cb25aaee7ac5f14cb1b6562e4600c0180300600c0180300600c0180300a0cfae5be82ed99f5b72ff00e47c65c02b81e9aad954fd57debb84561bc4cb180869ab2eccd7ad24a45ca4d1a7e746ced2bb1f5fd2a34cbae62a60e27adf6362c1b97af551cb94c81ed30601b12e01c63b8f4bea6e42eb7b469fde3aeaa3b5b57dd188475a28d79846560aecc3622a9b86e2e183e4954c8e993b448bb6709f8176ae1322a91c8a10a60020ceafe966eca956d82defe8f17a726c19482128ca9168dcbb667f5f22e9bb8339211c575f5b4e7988f39840a766fd776cd44ca04324251300813f554a9d5e895980a5d26bb0951a855625840566af5a8b65095fafc1c5b74d9c6c4434446a2d9846c6b06a9153451453226990a0050000c03e8300829e4b7a6e3b41729f684b6e1bdf1882a378b24a2d336d71a7ef571d57056c9576e947b23253152aa4b33ab23272ee9651478ed93368edd2aa19455532a613e01247c3ce0c713f80dacbfe51f12b4ad4b4ed39cb945fce7cc88ba7d65b7cb37445b233377b9cdb992b65ca5916e614d25e45e393a090f9697813002801f872a39bda038830657bb56d02ada1fb151f5735cd6d34a56f1624ca2aa492cd62c574108d8d55c2264fdf5f2ad9a78ca628286397c395e9c7b6f7e45c3c7b8b7bf26ac75e77e6f0ef2983dcc7914e3b914c3a566a9f0da6221ab774c20ded00a44ef928c542908d53d976e049b1ef4d1b9520f2d81d2419b60318a9809845534de3e34688a8b949f1d7d9f04637b859f5e9c5ae45a68b4edf8beff71231a137febad8d015eac47c97ccd6d88838a8a5ab534649abd7868a8f6ec8ee6196038b696415f23c7e148de71007e3a65e9d738f9eb17a0bd7de9a6e191bbe7d1f5bd2d6df39c7371d4a55454e4e4a37c74e7c7971d3cebe5b7f66c91d4ff49bd68e89ebcdbf1f68c3bbe93a8aaa631962ded46c972c526e996bcb747bfc8f9d2e32844ecca2a288ac92a928a22aa6a14c9a899cc9aa99c07d8621ca2062183f887341bd1af61bb6c84675ca16252835c535aa7ef4c8fad893f3764ba585fcfcb3f98768cbc9324179072a3933766d9eac920d5b01c7c0d9b2499000089814bf97a75ea39b936aa29c7dba985118c22eb8b7a2d356e29b6fc5bf167a73a5b6cdbb69d83171b6ca2aa289515cda845479a52826e52d38ca4dbed936fe07174fd9612b2d3dee69f26d48601f2100ff0078f1d183fd86ad49fef561ebf97a0103f2886677d23d13d51d73b87f8ee98c49e4589ae79fd9a6a4fbedb5f920bd9ab93fbb16cc73d48f55ba07d25d9bfcdf5e6e3561d324fe555f6f2721afbb8f8f1fccb1f73924ab8fdf9c5713a8540b938d69b9e6f714445c35ad691b13a9c6f52bd44b599aca49aaa2474fa47a8638349a2020029bf44e555038f52f50ebd7a331f4da3b87a5789e9aeef9d978d2ab061459918174e89f324f57197073a9b9692aec8f2d896924b869c1beb8f51e8ea0f58378f53b67c483c4dc374b726aa32e10b1c6136b954d45b8c6cd23aa9424dc1be127a6aedcfc03e70f1836dbd71508ad8d2959da72264c51a0de1c8d7e2a78ee193478ba94933954919689466703b75ca06248ff00c39cc46feebe0594d53e847a1fb97a4db35b6eef97936eeb916ddcf4c2e6f0e108dae14d91a17915b6530ae73b1eb38f3fcad7cac98ebdf5130bad33615e1535578b5421cb39412ba52704e71763e3c919ca51505a27cbcfa7125cf37d9810c0180300600c0180300600c0180300601436f5c756a69d6bdedc7704182ea5760ae5c9dad4a4a15338b567376b84d1b2900c16540a2991792614c92513288818c56871001028f4033d76ae9cb172ddeb270bb378cd745d3476d5651bb96ae5ba8555070dd748c45505d05480621ca2062980040404300b25682f560f782d154288d7efb63ea8dead2058b78d8bb36f8d6aad9ef0462d08445b25256ba9d968f2564749a29814cf2505ebe5c7a9d65945044e20738fe328eedbfa2bc3bfb1cbefdf2600fc651ddb7f457877f6397dfbe4c01f8ca3bb6fe8af0efec72fbf7c9803f194776dfd15e1dfd8e5f7ef93007e328eedbfa2bc3bfb1cbefdf26012d9d8f7d493dc2bb89771fd31c53df711c6d8bd617b80dab293ab50359db602d8ab8a6eb3b45ae1dbc5cbca6cd9f64cbc52d12899613b45bcc6e539000a6301c805d1390fc58d1bca5aa1ea7b9290c2c09a49a810d616c058eb7d6575007fe2abb646e4f7f606f1f431911151aac2000b24a143a655aaeb2997356f4fe052b68aaf8f2d8b5fe2be25447b8b7005ff0003a6ea12e6d85156fd61b3a7652068cfe4c9f34dc18cbc6b234aad0963649a5f3439108d0f124fdb2a991c1ca6299ba03e00526f172964eb1d349a5abf02032f0de2e92d75adbd178ebda47490ca24a26aa67511591391545548e7496455208193552548255125086f694c510101f680e5cce30b212aac5195538b8ca3249c6517c1c649ea9a6b834d34fbcb484a75ce3656dc6c8b4e2d369a6bb1a6b8a6bb9a7aa3b9dab39c739ad98950dc2e8961a3c62641736b7cedb33b0c0332087555dbf78aa0ce71ba45f80ab9c8e87e0054e3d0b9e39f56bf487d2dd52addefd3c955b37504b593c769fd0dd2f645272c5937df5a955aff00c51ed3d4fe9a7ea8fa8fa6630da7ae54f74d8e29455faafabaa3e2e4da8e445784dc6cff00c92e08e279be5551f64ab3b3da5a6e3ed30efa664d40b1f84e5169ef2f175534c611d1117ed1d090e021ef69a603f094860e83919e997e97327e45199ea45aabaeb8c57d1e3cd4a5271497e75f1e118bd3ecd5ac9aed9c1f03d27ea7febef131366aba7bd14c7f9d9cb16b859b965d6d42a97225258d892f35938bd57ccc851ad35e5a6c5a48e127cfdf4a3a55f48bb70f9e2c3d5472e5432aa9bf80a0261e84217f214a0050fc819ecada768dab61dbebdab64c7a7136da9796baa2a315ede1c6527df293727ded9cdeea3ea5ea1eafde6eea1eaacdc9dc37cbdeb3bef9bb26fc229be1182fbb0828c22b846291cd1c5bd0f3dcb3dfb0fc74d7d67a7c45f642b92b74904ac926aa410d4c817516d66275c318f6ef64173a2a4c2056edc08433939fd86290a75097775f0a23cd2edf02268ade45ca9835cfa6bf02df1c42ed81c73e29231f61f99d2da9b6d0226a2fb2aed1ed5c2918efc02553f32eba733a8ba92002630155279d20251129dd1cbd0a10b7e65b770fb30f05fcfc4c831f0a9a38fdab3c5ff2f024872d0bc180300600c0180300600c0180300600c03a1bdc8bb7a68eee73c57b9716f7a22ed8c54cba6366a3dea1906ab5a757ec6834dda75dbd567df0a281de3345fb968edb9c4a9be8c78e5a9cc52ac272819e16d6f4717752a7dce5a1f5958b8e1b82968b957e61ba21b19f511e48c7f98606ca4bd52d101ef1092864800556e8bb9041330f42395403c58071b7e10bef23fa1dc7dfb7586fea8c01f842fbc8fe8771f7edd61bfaa3007e10bef23fa1dc7dfb7586fea8c01f842fbc8fe8771f7edd61bfaa3007e10bef23fa1dc7dfb7586fea8c01f842fbc8fe8771f7edd61bfaa300942ecc5e9d3eea3c04ee57c64e546d8aa69c4356eba9cba34d827ac6e386999b2d6aebad2e5465d6651411699e40ccde58905cc910c539c890814407a601a1b6015a5f53056ec729c7ce3ad8232bf37275eaa6d9b238b54e47c53d7b11594256a231d14e2c320dd055ac336929038374147264d3557104c0c271294657699455f24dad5c787b78aec227785278f1693694f8fb168fb7c0a8ed6365cf575306aa89662388412a2d5f2a7051b0f41f07bbbc003aa54407e12180c5e9fcdf0e4e38297bcc7a336b8771c1fbaa12777215155f591f3159878863a14145bf35414111129968b21ba95d8f5e9ef5d545403d82021ecca56e32b1795b52fdc50beb772ede3fb8e9340d9ae3ac2d0e1fd6671dc04fc4bb5d83a711cb81db3a168b99259abc40e5334946073907a9164cc4e83ec001c8dd6509707c511c9cea9be57a491d96b3f36b674e55dac2c447c3d5270e89d29ab4c5f9ae1dbaebf14a78562f0aa2104a284f69cde270729bff0088530e995259136b45a265d4b32d9479568a5deffa781341e95e87b44f772abb5d558db14cc5c5f1cf63b6b1db946729231cca6e76cfafcf18ce76c0649668da565d166e0edd270b1555ca82829818086e96392ff2f8f6ea48ec0a52ce73e2d283d5fc5779a27e4799a0c0180300600c0180300600c0180300600c0180300600c0180300600c0180300f02522a327235f434d47309888946abb1938a9466de4236458b94cc93966f98bb4d66aedab848c253a6a14c4394440404300ae0f3cbd3e7abf687cf3b27864fa2b4cdf95f39f3bd452a2b9750595d1ceaaca96b8ba2474ff59be5854e8449ba6e61be294846ad404eb64ae36e7657e5bf59c3c7ef2febf1e3ed22b276aaadf3d1a427e1f75ff4f870f6779527dd1a1f7171cef8f75aef0d7765d6d738f1f18c458990a29c833053cb24a40ca2065e22c50cb1c3a26f182ee1b283ec03f501009caaeaee8f3d4d4a3fb76aed5f1202ea6da27c9745c65fc7dcfb1af7767bc8adfcd3b5ec0da0ee9b46acd82e570b35be5232bd55ab43bf9fb14e492f22e7c961130b14ddd4848bb53c22209a499cdd0047a7401c88b5a53937d9abfe24338ca7738c5373727a25c7f77f22d7ddb7fd2df7fbf840ed6ee173afb58541506f22cb8f148926e7d93368099259343625c9a0ba8da333709752aac230cee544a7e8772c1520946cacc94b857c5f8990616c13b34b335f2c3f0a7c7e2fbbe1c7dc5d6345f1fb4a719b5dc3ea7d05acaa1aa35ec1147dc6b34d886f16ccee0e01ef12526ba6533d9a9a7a60f1397cf155de393fc655439bdb96729393d64f56651553551055d315182ee4730e7c2a8c0180300600c0180300600c0180300600c0180300600c0180300600c0180300600c0381b90dc63d15caaa2b9d75be75cc0dfeb8a798ab0348a276f375e7ea24744b2f56b1313b69bae4b24538f45da2e918c1f14fe22098a352bb6ca67cf536a5fb7fa9f8b2aaee87cbb62a507dcff6e0fdab89d78e14f6c5e1c7015a4b2fa03583742ef625df2f64db374590b5ed39b4dfb959cab1ea5a9766d7e6885279de10631883166702819448ea7538acb676bd64cb7c6c1c6c46e54c7cedf16f8bff005f0240329976300600c0180300600c0180300fffd9
\.


--
-- TOC entry 2917 (class 0 OID 16433)
-- Dependencies: 209
-- Data for Name: jobs; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.jobs (id, name, last_run, count) FROM stdin;
\.


--
-- TOC entry 2914 (class 0 OID 16418)
-- Dependencies: 206
-- Data for Name: registrations; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.registrations (id, registration_date, session_id, attendee_id) FROM stdin;
1	2020-01-01 00:00:00	1	1
2	2020-01-01 00:00:00	1	2
5	2020-01-01 00:00:00	2	3
6	2020-01-01 00:00:00	2	6
24	2020-01-01 00:00:00	2	52
26	2020-01-01 00:00:00	2	41
27	2020-01-01 00:00:00	1	25
43	2020-01-01 00:00:00	2	114
63	2020-01-01 00:00:00	2	148
83	2020-01-01 00:00:00	2	56
85	2020-01-01 00:00:00	1	56
86	2020-01-01 00:00:00	2	136
87	2020-01-01 00:00:00	1	5
89	2020-01-01 00:00:00	2	5
92	2020-01-01 00:00:00	1	95
\.


--
-- TOC entry 2915 (class 0 OID 16421)
-- Dependencies: 207
-- Data for Name: sessions; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.sessions (id, name, description, session_date, speaker_id, event_id, duration) FROM stdin;
1	What is the Future of Trade? Multilateral or Bilateral?	This panel will cover the “big picture” of global trade concerning the benefits and limits of multilateral trade negotiations, impact of plurilateral and bilateral agreements on the multilateral system, where we are now and prospects for global trade post COVID-19.	2020-01-01 00:00:00	1	1	60
2	New to Trade Compliance?	You will also learn how transition can be made from Trade Compliance to Global Trade Compliance and the specific challenges involved	2020-01-01 00:00:00	2	1	60
3	Supply Chain Logistics, Trade and Tech Talk	Are you at the forefront of technology when it comes to managing your customs and logistics data or are you worried about being left behind?	2019-01-01 00:00:00	3	1	60
4	U.S. Trade Policies and Countries of Production in a Global Supply Chain	Trade policies and actions such as Section 232 and Section 301, even before COVID-19, have affected US importers, global manufacturers, and US resellers decisions about global sourcing and countries of production.	2019-01-01 00:00:00	4	1	60
\.


--
-- TOC entry 2916 (class 0 OID 16427)
-- Dependencies: 208
-- Data for Name: speakers; Type: TABLE DATA; Schema: reg_app; Owner: postgres
--

COPY reg_app.speakers (id, first_name, last_name, speaker_pic, speaker_bio) FROM stdin;
1	Anthony	Smith	\\x89504e470d0a1a0a0000000d4948445200000200000002000803000000c3a624c8000000017352474200aece1ce90000000467414d410000b18f0bfc610500000300504c544500188d081c91102495182c9920349d283ca13044a53848aa4050aa4859ae5061b25969b6616dba6975be717dc27985c67d89c68591ca8d99ce95a1d29daad6a5aedaaeb6deb6bedebec6e2c6cee6ced6ead6daeedee2f2e6eaf6eef2faf6fafaffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3c3adbf0000002174524e53ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff009fc1d021000000097048597300005c4600005c4601149443410000160649444154785eed9dd776e2301040633a0924b42474fbffbf72d93014575c34d2b4fbb6e7b004a48b2c8d46a3b7c4508d09009cb6dbf562b198dc985ffeb158fc6cb75b7881504c80fd76319ff4de2ae85f6cd8eee1e5d2502dc061331f4127d76038f95aede07fca41ad00bbc524829e6d42345dc91a0b540a107fcffad0a16de87dac0ff04efcd127c0713d858eec427fb639c21bf2469900bbaf21f4a00346eb33bc2d633409b0eb34f017f2f10defcd163d026cc6d0696ee9cf794f0a950870fa72fee37f305c9de0cf30448500bb0fe82a34a66c1f05f20588370d823ded196ce0ef3143ba00a8637f1a9e0ac816205e5606f95d3358c7f087f9205a809f01f48c37fa2b6e0a08166087b3ee7b013705c40a70429ff997d15fc14760815001ce8b365b7dae18324a229129c0dadbd4bf84199bd09044010e411efe697a6bf830d41128c026e4e8ff60cc237b489c00e76093bf1c9f1c768ba509b0f3bef4afa0cf60874098000b687a2a4cc8a70d8912e04460f697a1f7039f8d2a9204f8f11af8afcb27edc8a01c01e239b43835c6a41f036204387bd9f56f05e9c78014018e0eb37ddd43f8312044807de8d8ef0be83e066408b02539fd7b86ec634084003f3482bfd5107d0c481060034d4c9c2949030408402dfa57ca88e2de007f0166d0bc0c18109c0a7217207e87c665419fde3132ee02b0eaffcb62805cb2187301a8867f4b89a8ed10f31680cdfcef0962b962ac0558439bf2e20b3e3d0d380bf0032dca8d197c7e12301660cb21fe57082503f80ab0271fff2f670edf81006c053852cafe6ccc02be4578b80a7066ddff6f6f4bf81ec1612a404c37ffa72654aa49301580d1064019441204780af00d8dc899e817be4c58580a7064bc00781091383cc8518098def98f56f428ec0d721480e30e40217d02f9010c05d842f30960103e47889f0027e219e08d78872f150e7e02304b017941f080103b0156d07252089d22c44d803ddb2dc012fa81cb49311320267d04b01513f86a816026809815e0139ff0ddc2c04b80a3b407c01f4177057809206b0570a317321ec44a00ae4980af18073c35c8490081334020609220270196d05c0209971ec2488093c819e09570d1004602c89c01021ff025bdc347805f682aa184ca0f622380dc19e0957ea095001b0104cf00af040a08721140f20c10089322c84500f103c0dbdb28c843808900b1a434a032829c17632280b4349042a2037c5b9ff01040c5001026358087003c4b81342740f9181e02b03f0a5a939eff88300b01a46e03e7f11f0c6021809601e0320ff43e04701040cf00106008e020c0141a4703de87000602eca16d74e0fbb018030144e701e4f17c669cbe0067f9db40293c0f01f405d01204bae37708a02fc004da450d7e8700f2029ca05914e17508202f808244802c5e8700f202e889023ef039045017e0006da20a9f43007501bea04d74e17108a02e00f39ad02df1b823405c801db488327afef243890bc0ee563047f84b0da22d80925cc03c2368007c680b20fc3c6005dea681b405f884e6d087b79211b405d01805ba12f9aa224c5a8033b4864656d006d8901660038da19121b40136a405107033507b3c1511262d80ce3020e0694380b20047680a9d78ca0fa62c80e629c0053f57095016e0035a42296368065c280b20e272b80e787906101640d7819002bc940f252c808aaa2055785907101640d989a03c918fac00c202689f02f8a91e4a5700850702b2cca12930a12b80de5c803b03680a4ce80aa0ee4c60011ed242e80aa03719e48187d2917405d05417a40c0fc140ba0268cd074d811f0c242b80e66ca007f8c140b202283d1292013f184856806f6802ddf4a035f0202b80ce53a139d00b88931540fd4ec0956f680e34c80a20fc8ea8baa09f13a62a400c0da01df42b04a80aa03b21f401fa2c90aa005b6800f560cf02a90a607b8100f62c90aa00ca53c21f60cf02a90aa03e21f006f62c90aa000bf8feea89a041b0a02a80d6e24079909342a80aa0fa60700ae40d41aa02a8ab115e0af22c90aa007a8bc36441ce0aa22a80ead20029906381540550764f4c15b8e783a80a005fde787b3b4293e0405400db0b7a805b2cc804200fee3ad004200f6ea91813803cb847444d00f2e0a6869b00e4c18d049900e4e9439be04054003b18f604b4090e4405b040d013a8912013803ea8912013803ea879a126007d50ef8e3001e8835a2886aa005624f0814a012c21e48109a01cd42be44c00faa814c0b2821fa81440f96d2129540a6075421fa814c00e873e50298055897b807a4098aa005627f2814a012c23e4814a016c33e0814e01ac58f81d9d028ce1db1b4a05b052b177740a6091a03ba80703c80ab0846f6fe80c0459a1c0075fd024289015c0224177542684d8d19007a8e7c3c90a601706dcf981164181ae0096117043e5c110db107e805a319eae007663c00d956703edd29807d02038d015c08a8502b8f5c2090b60f5a2af0ca03d70202c80cd02af8ca03d70202c80c502af4ca13d70202c80cd02afe0d68b272c80cd02afaca13970a02c80cd02ffd84173e04059009b05fe7186e6c081b200360bfc0f6e9940d202589990ff28bd32e60f9b045cc0ad154d5b003b207801b546187101ce7673d0dbdb2f340612a405b03a21174ed01648d016c016826aef0ebe62678491b782a80b6099a16f1fd012581017e00b9a412fc88b00ea02586220f2edf1d405501f0c44be3998be00da4f07e05e197681ba00dacf88624f01c80ba0fd8820eecdd117a80ba03c18889b11fc1ff202e8de1042ad0df107790162d5e5c2706f0eff0f790174170b429f023010e0006da19121b40122f405d03c0dc43d12f0070301144f03516b835c612080e269206e46f81f0c04d03b0d442d110a701040ed34107f11c84300add3c0c8c3138087004aa781d8c9407fb01040e93410f5daf81b2c04d0390decc5f0ed51e121c049e30911fc8da0fff01040e510805a20f40e1301140e01c8c7c26f301140e110807a4bc0032e02e81b02702bc3dce12280ba21c0c34ef01f6c04d03604a05e13f2041b01940d0111f2a9f03b7c04d03504784805b9c247005d4300f691c03b8c04d03404a09f08bbc348004d4380b7018095007a86007f03002b01f4948b40ae0cf60c2b01e201349070b0eb023dc34a80e4175a48381eb2c1eff0124047bd089f030037014e1a4ac6e0de1091819900c91a1a49307d2fa96037b809a020451cbd2a4c0a76021ca40703bcce00180a902ca0a1a4e22911e4063f0162d9e563fde4023fe02780eceaa1def2006e30142099436349c4ef0cf0024701ce724f8a8dbc2e01ffc35100c10f013f87419e612980d89b44bc9c074ec35380e41d5a4c16de678017980a7016b931ec7d067881a900c94e6040d0ff0cf0025701044e0322cf31c02b6c0590971ab0842fe617be02480b09fba80957005f0184ed0bf603ac00fec3580059d7c9784c044ec1590049d7cb7b3b0b9885b500f1149a8f3de3102bc03f580b90c4636840e64407f842fee12d40721e4113f2c64751e012980b901c25c4847d67013dc35d80e4c8ffa4c0c04751e832d80b90ecb91bd0c3bf19aa02fe0224bfbc03423d7fb5008a102000ef23a351a80810204100d621412f35e12b102140b284d6e487d783a045c81080ad01beca4196234400a64f81900100408a002cd7021e6b419522468064c72e1e300db603f4841c01923db3a8f0286400f08e20019223ab9da12989fe1725407266b43bfc4161fcbf204a00461922c13280b2c812804d96589814f022a409c0a3824cc004902ce20448b6e4ab0784deff49214f80e444bc925c2fc811b032040a40fc31300897005a844801283f06c641f37ff2c8142039535d0f7e1159fedf112a00d10de23ea5e9df15b102243b7a8f8169a003a055c8152039132b2414d189fe3c21588024f9a55442601836fbb70cd10224f1924c9ac88cdaec0f902d40929c683c077aa1937f4b912e008de7c03bc1d91f205f80245e047e0e8cfc1780ad8f020192e418322cd4273bfaffa14280cb732054b658b4203af9bba144808b0241f60867741ffe801a019264eb5d8109cda57f0a450224c9ceeb9a70e0f306d8d6a8122049f6de1498d2dbf7294499004972f09136da9b13dbf52f479d009745e102f908d1604de3cc472d140a70613bc33b48f8ce64ec07740a9024f137ca6ca0f7c966ec07b40a70e1b476bc4bd09fff108ffa14a058800b874f67d381d182c1a2bf00dd025c386e669d2588ded7e4237e65a817e03f9d246039f03f30018056128c3fbf691df3688e09f0c479bb59bcd7db31184cbe56a48e78b5c504c853eec16032992c168b5f115d7fc504a8e6b4bd21a8d39f310194434880a3d85f19650808b05d2f269998dc64325b2cb75b467b2a6c092cc0765139e9ee4d3ed75bceab6cfa0414e0bca9b91f33986dd806dac8134a80b86eef03c3f98f3d10300823c0f1abcd7efcfbb73d0d9c134280dfd65bf1d18739e018ff02fc743ba3c12fe58236be05e8d8fd7f304bbaa28d5f01b68e4e680d0995da648e4f014e1fd07f0ee071ea8201fe04705dad634cf9d0351fbc098050a761ca330b8f169e0438e39cc799d98aa02b7e04f8c5aad9177d5a7cb01b3e0440faf95fe951afc0401c0f02ec908fe20d2585058e9bc562b1fa9f81e469ff0b5f000f457be9d7e1a8c7f12bf55b19ce37f8731c6c014e5eea33f52404868e456192d112d9016401d0667f59c6dcf3f3cb8bd9bda3063c7005f078754744ae127f230e556112cc42839802c40e43bf35e03c195cbf8892bea30d7088029cbcd7e6e33a19acf34bf982d7ba064f807d800b1b784e06ebdd798c34cb4113e03b4c815e8a9772bca0eebdf738766309b0814fed1d9af77254f053ff97324798e7220910f2e63e5e2bc246bf9489fb9d0f1c01e6f081c3102df9ac081bfe52dcdf3a8921401cfc0aef219743868d5baae73a070241001297f8cf396c13b76929d706b8178044ffbfbdf5e9270d9e5b952f776c80730188f4ff05ea2bc273cb40995b035c0b40a7ffa94f06eb857f8a706a80630128f5ff05c2db03c70e69323d876b01b70210ebff0b542f6cdb774a931ab8fb566e05f0761d437d683e07f61dab958f9c2d729c0a107cfd5f08c1e7c06fe78d92a92bad5d0a1032fe5bc9945870d8c546c90cdeab2b0e05f090fdd91a52c707dcfc5056f06e1d712740b0fdbf5af4d7f031c3e368a3247213ee7626c02f7c2eb210b9c137763651ee3b590ab812a0ebb4d607788975f5398de1c3386002efd90947029c904fff3822f861d2add33c391779826e04881d7a8d4af4193430b4828fe10a071b5e6e04f09bffdd8968116c4170761e27eb75d7d989005ff07978d00b141bdcbb2f91e1601ae042806ff8346ce8af0228b0414993ee1c0d7020c0214c027827bc2b7040babb3eeaba35dc5d80338f054096fed2e35ce08cf7901c7634b9bb00047700ebd1f3361dfcc63c2435873fd292ce0290dd01aa811f05b046ff1bdd363bbb0a403e025c0d7ee5e123fa1e79bf93c51d0538328800bfe003f30cc1de4784a4d343a0a3005c2280958cbfe1dbb866eb2943aecb36573701384f009e415912fc78fb75745909741260071f4000d1dcf156e10621ee574a875da12e02308d0094315a3b1b06e2b5dfa6e9100eea2200cd1cd02e7c38c91f3d2fbd174719c39f6e4e070168e780b5a4ffd5f551d0ee42acaeb4de13682f8080156031a3557b07e24da0a33151db8de1f602903b04e490c1bcd5b360370ff7a3f880cfd094d602887c003c11bdaf9bfda84e2b9ff3fe3c2de3596d0538052802e79de16c5df369b05f061f1047f0511ad25600464960dde84d972faeafdeae3e48fc1adacd035b0ac07c0fa829d164b6f8c98db1f176bb98792f875a4abb7302ed0488353c008a184deed0e9f91b9fd03b8d682740d8327046096de281ad0410b407208a36f1c03602c4f4463fe38f16fbda6d0490b2092c8f7ef37de11602704c03d742f3a5600b0144640109a5f952b0b9006bf85b06451a2f051b0b70b20700651aef0a361680ed39102534dd156c2ac01efe8e419586d1a0a60248ce0290c13bf4544d1a0af0037fc5a04bb3b2210d05b018207d9a25063413c006000e340a08371240ed2e302f1a05841b09e0bac895814393807013016c0060429321a08900b60bc8850667051b08604160363408083710e013dedda04ffd3da1fa021c6d00e043fd21a0be00b60bc489da01e1da02d82e102feaee09d516c006005ed4dd16ae2b800d00cca83b0ba82b800d00dca8b910a829c011ded56043cd70604d012c06c08f7a3b02f504385b0c801f43e8bc6aea0960db801ca9951a544b00db066449adfb646a096089403ca9130caa25806502f2a4ce05d37504b072004c896ad4bead23800581b852e3c6ec1a025810882d354a86d410c082407c795de6f0b500160462ccebe4c0d702581088317de8c4725e0a604120d6bc2c7afd52000b02b1e6655ec84b012c08c49a97a18057021ce08d0ca6bc0a05bc1200efd663c30baf76845e09605340eebcc80d7c2180b2b2f01279f10c782180bc9be1d43185ae2ca15a80d8a280ec79b10ea81640facd502ad8406716532d8015851340752ca8528013bc85c199a8f28040a5004b780b833595d9c1950284bd09d17044656a609500762054063de8cf42aa04b05420216ca1438ba810c03201a4b0801e2da242000b034ba16a43a8420035d703cba72218582e802583caa16221582e808581e530873e2da05c8009fc67833f03e8d3024a05b08d40491ca157f3940a60d9c09228cf0a2915c0a24092282f1c5a2ac000feab2181f26870990076245816a5c542ca04b01381b228ad1957268015859045e924a044005b040aa374125022c016fe9f2185b24940890076224c1a6591801201ec4cb034caf2c28a05b045a038cab6038a05b09d4079946c07140b60b920f2283920542c400ffe932187929c804201ac36ac4046d0b9190a05b04b8225527c42ac508031fc1743123be8dd3445029ce17f18a228de0f2a12c0928144527c4cbc48008b038ba4f812a92201ac2c844c0a8f87140960510099149e112d10c0360284b2840e4e5120c037bcde1046615650810096102e94c20dc10201ec4c98548a66810502d81c502a45b747e405b0ca4062298a05e605b06410b114a585e505b039a0588a7684f302d856a0588a6a86e604b023218229381c9013c0e68082f9864e7e2227c01a5e6b08e4133af9899c007378ad219082db437202d89920c114dc249b152086971a22c90783b3025846b868f289a15901ac328868f26784b302d83d71a2c92f03b202581c5034f965405600bb234034f9654046003b13229cdc32202380058285935b066404b08450e1e496011901eca640e17c4147dfc90860ab40e1e452c33302d82a5038b9a4a08c00b60a144e041d7d272d80ad02c57382aebe9116c05681e2c99e104d0b6077458a27bb0e4c0b606702c4935d07a605b0f260e2c9ae03d3025818403cd975605a002b0e239eeccd1169012c23543e99fdc0b40076325c3e99fdc094009612ac80cce9a09400561e4a019952512901ecaa280564cac6a704b03890023279a12901ec60a802321563530258205001990de19400561d4603e90de194001609d6403a109012c022c11a4807025202588d500da40301290106f0124332e903a229012c255403e98c809400f00a4334e98c8067012c275805e98c8067016c2f4807a97aa126803e0ed0df7f3c0b60a7027490ba36e05900db0dd641ea227913401fa9a30126803e5277c83e0b60e541743086fefee359004b08d241aa549809a090e7408009a0902374f87f9e05b00a514a780e043c0b6029814a78be3ff05900431d49f20f39904a2f4d6be67a0000000049454e44ae426082	When Anthony is not evaligizing Azure technologies, he is watching baseball and cheering for his favorite team. Go Mets!
2	Julia	Whitehall	\\x89504e470d0a1a0a0000000d4948445200000200000002000803000000c3a624c8000000017352474200aece1ce90000000467414d410000b18f0bfc610500000300504c544500188d081c91102495182c9920349d283ca13044a53848aa4050aa4859ae5061b25969b6616dba6975be717dc27985c67d89c68591ca8d99ce95a1d29daad6a5aedaaeb6deb6bedebec6e2c6cee6ced6ead6daeedee2f2e6eaf6eef2faf6fafaffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3c3adbf0000002174524e53ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff009fc1d021000000097048597300005c4600005c4601149443410000160649444154785eed9dd776e2301040633a0924b42474fbffbf72d93014575c34d2b4fbb6e7b004a48b2c8d46a3b7c4508d09009cb6dbf562b198dc985ffeb158fc6cb75b7881504c80fd76319ff4de2ae85f6cd8eee1e5d2502dc061331f4127d76038f95aede07fca41ad00bbc524829e6d42345dc91a0b540a107fcffad0a16de87dac0ff04efcd127c0713d858eec427fb639c21bf2469900bbaf21f4a00346eb33bc2d633409b0eb34f017f2f10defcd163d026cc6d0696ee9cf794f0a950870fa72fee37f305c9de0cf30448500bb0fe82a34a66c1f05f20588370d823ded196ce0ef3143ba00a8637f1a9e0ac816205e5606f95d3358c7f087f9205a809f01f48c37fa2b6e0a08166087b3ee7b013705c40a70429ff997d15fc14760815001ce8b365b7dae18324a229129c0dadbd4bf84199bd09044010e411efe697a6bf830d41128c026e4e8ff60cc237b489c00e76093bf1c9f1c768ba509b0f3bef4afa0cf60874098000b687a2a4cc8a70d8912e04460f697a1f7039f8d2a9204f8f11af8afcb27edc8a01c01e239b43835c6a41f036204387bd9f56f05e9c78014018e0eb37ddd43f8312044807de8d8ef0be83e066408b02539fd7b86ec634084003f3482bfd5107d0c481060034d4c9c2949030408402dfa57ca88e2de007f0166d0bc0c18109c0a7217207e87c665419fde3132ee02b0eaffcb62805cb2187301a8867f4b89a8ed10f31680cdfcef0962b962ac0558439bf2e20b3e3d0d380bf0032dca8d197c7e12301660cb21fe57082503f80ab0271fff2f670edf81006c053852cafe6ccc02be4578b80a7066ddff6f6f4bf81ec1612a404c37ffa72654aa49301580d1064019441204780af00d8dc899e817be4c58580a7064bc00781091383cc8518098def98f56f428ec0d721480e30e40217d02f9010c05d842f30960103e47889f0027e219e08d78872f150e7e02304b017941f080103b0156d07252089d22c44d803ddb2dc012fa81cb49311320267d04b01513f86a816026809815e0139ff0ddc2c04b80a3b407c01f4177057809206b0570a317321ec44a00ae4980af18073c35c8490081334020609220270196d05c0209971ec2488093c819e09570d1004602c89c01021ff025bdc347805f682aa184ca0f622380dc19e0957ea095001b0104cf00af040a08721140f20c10089322c84500f103c0dbdb28c843808900b1a434a032829c17632280b4349042a2037c5b9ff01040c5001026358087003c4b81342740f9181e02b03f0a5a939eff88300b01a46e03e7f11f0c6021809601e0320ff43e04701040cf00106008e020c0141a4703de87000602eca16d74e0fbb018030144e701e4f17c669cbe0067f9db40293c0f01f405d01204bae37708a02fc004da450d7e8700f2029ca05914e17508202f808244802c5e8700f202e889023ef039045017e0006da20a9f43007501bea04d74e17108a02e00f39ad02df1b823405c801db488327afef243890bc0ee563047f84b0da22d80925cc03c2368007c680b20fc3c6005dea681b405f884e6d087b79211b405d01805ba12f9aa224c5a8033b4864656d006d8901660038da19121b40136a405107033507b3c1511262d80ce3020e0694380b20047680a9d78ca0fa62c80e629c0053f57095016e0035a42296368065c280b20e272b80e787906101640d7819002bc940f252c808aaa2055785907101640d989a03c918fac00c202689f02f8a91e4a5700850702b2cca12930a12b80de5c803b03680a4ce80aa0ee4c60011ed242e80aa03719e48187d2917405d05417a40c0fc140ba0268cd074d811f0c242b80e66ca007f8c140b202283d1292013f184856806f6802ddf4a035f0202b80ce53a139d00b88931540fd4ec0956f680e34c80a20fc8ea8baa09f13a62a400c0da01df42b04a80aa03b21f401fa2c90aa005b6800f560cf02a90a607b8100f62c90aa00ca53c21f60cf02a90aa03e21f006f62c90aa000bf8feea89a041b0a02a80d6e24079909342a80aa0fa60700ae40d41aa02a8ab115e0af22c90aa007a8bc36441ce0aa22a80ead20029906381540550764f4c15b8e783a80a005fde787b3b4293e0405400db0b7a805b2cc804200fee3ad004200f6ea91813803cb847444d00f2e0a6869b00e4c18d049900e4e9439be04054003b18f604b4090e4405b040d013a8912013803ea8912013803ea879a126007d50ef8e3001e8835a2886aa005624f0814a012c21e48109a01cd42be44c00faa814c0b2821fa81440f96d2129540a6075421fa814c00e873e50298055897b807a4098aa005627f2814a012c23e4814a016c33e0814e01ac58f81d9d028ce1db1b4a05b052b177740a6091a03ba80703c80ab0846f6fe80c0459a1c0075fd024289015c0224177542684d8d19007a8e7c3c90a601706dcf981164181ae0096117043e5c110db107e805a319eae007663c00d956703edd29807d02038d015c08a8502b8f5c2090b60f5a2af0ca03d70202c80cd02af8ca03d70202c80c502af4ca13d70202c80cd02afe0d68b272c80cd02afaca13970a02c80cd02ffd84173e04059009b05fe7186e6c081b200360bfc0f6e9940d202589990ff28bd32e60f9b045cc0ad154d5b003b207801b546187101ce7673d0dbdb2f340612a405b03a21174ed01648d016c016826aef0ebe62678491b782a80b6099a16f1fd012581017e00b9a412fc88b00ea02586220f2edf1d405501f0c44be3998be00da4f07e05e197681ba00dacf88624f01c80ba0fd8820eecdd117a80ba03c18889b11fc1ff202e8de1042ad0df107790162d5e5c2706f0eff0f790174170b429f023010e0006da19121b40122f405d03c0dc43d12f0070301144f03516b835c612080e269206e46f81f0c04d03b0d442d110a701040ed34107f11c84300add3c0c8c3138087004aa781d8c9407fb01040e93410f5daf81b2c04d0390decc5f0ed51e121c049e30911fc8da0fff01040e510805a20f40e1301140e01c8c7c26f301140e110807a4bc0032e02e81b02702bc3dce12280ba21c0c34ef01f6c04d03604a05e13f2041b01940d0111f2a9f03b7c04d03504784805b9c247005d4300f691c03b8c04d03404a09f08bbc348004d4380b7018095007a86007f03002b01f4948b40ae0cf60c2b01e201349070b0eb023dc34a80e4175a48381eb2c1eff0124047bd089f030037014e1a4ac6e0de1091819900c91a1a49307d2fa96037b809a020451cbd2a4c0a76021ca40703bcce00180a902ca0a1a4e22911e4063f0162d9e563fde4023fe02780eceaa1def2006e30142099436349c4ef0cf0024701ce724f8a8dbc2e01ffc35100c10f013f87419e612980d89b44bc9c074ec35380e41d5a4c16de678017980a7016b931ec7d067881a900c94e6040d0ff0cf0025701044e0322cf31c02b6c0590971ab0842fe617be02480b09fba80957005f0184ed0bf603ac00fec3580059d7c9784c044ec1590049d7cb7b3b0b9885b500f1149a8f3de3102bc03f580b90c4636840e64407f842fee12d40721e4113f2c64751e012980b901c25c4847d67013dc35d80e4c8ffa4c0c04751e832d80b90ecb91bd0c3bf19aa02fe0224bfbc03423d7fb5008a102000ef23a351a80810204100d621412f35e12b102140b284d6e487d783a045c81080ad01beca4196234400a64f81900100408a002cd7021e6b419522468064c72e1e300db603f4841c01923db3a8f0286400f08e20019223ab9da12989fe1725407266b43bfc4161fcbf204a00461922c13280b2c812804d96589814f022a409c0a3824cc004902ce20448b6e4ab0784deff49214f80e444bc925c2fc811b032040a40fc31300897005a844801283f06c641f37ff2c8142039535d0f7e1159fedf112a00d10de23ea5e9df15b102243b7a8f8169a003a055c8152039132b2414d189fe3c21588024f9a55442601836fbb70cd10224f1924c9ac88cdaec0f902d40929c683c077aa1937f4b912e008de7c03bc1d91f205f80245e047e0e8cfc1780ad8f020192e418322cd4273bfaffa14280cb732054b658b4203af9bba144808b0241f60867741ffe801a019264eb5d8109cda57f0a450224c9ceeb9a70e0f306d8d6a8122049f6de1498d2dbf7294499004972f09136da9b13dbf52f479d009745e102f908d1604de3cc472d140a70613bc33b48f8ce64ec07740a9024f137ca6ca0f7c966ec07b40a70e1b476bc4bd09fff108ffa14a058800b874f67d381d182c1a2bf00dd025c386e669d2588ded7e4237e65a817e03f9d246039f03f30018056128c3fbf691df3688e09f0c479bb59bcd7db31184cbe56a48e78b5c504c853eec16032992c168b5f115d7fc504a8e6b4bd21a8d39f310194434880a3d85f19650808b05d2f269998dc64325b2cb75b467b2a6c092cc0765139e9ee4d3ed75bceab6cfa0414e0bca9b91f33986dd806dac8134a80b86eef03c3f98f3d10300823c0f1abcd7efcfbb73d0d9c134280dfd65bf1d18739e018ff02fc743ba3c12fe58236be05e8d8fd7f304bbaa28d5f01b68e4e680d0995da648e4f014e1fd07f0ee071ea8201fe04705dad634cf9d0351fbc098050a761ca330b8f169e0438e39cc799d98aa02b7e04f8c5aad9177d5a7cb01b3e0440faf95fe951afc0401c0f02ec908fe20d2585058e9bc562b1fa9f81e469ff0b5f000f457be9d7e1a8c7f12bf55b19ce37f8731c6c014e5eea33f52404868e456192d112d9016401d0667f59c6dcf3f3cb8bd9bda3063c7005f078754744ae127f230e556112cc42839802c40e43bf35e03c195cbf8892bea30d7088029cbcd7e6e33a19acf34bf982d7ba064f807d800b1b784e06ebdd798c34cb4113e03b4c815e8a9772bca0eebdf738766309b0814fed1d9af77254f053ff97324798e7220910f2e63e5e2bc246bf9489fb9d0f1c01e6f081c3102df9ac081bfe52dcdf3a8921401cfc0aef219743868d5baae73a070241001297f8cf396c13b76929d706b8178044ffbfbdf5e9270d9e5b952f776c80730188f4ff05ea2bc273cb40995b035c0b40a7ffa94f06eb857f8a706a80630128f5ff05c2db03c70e69323d876b01b70210ebff0b542f6cdb774a931ab8fb566e05f0761d437d683e07f61dab958f9c2d729c0a107cfd5f08c1e7c06fe78d92a92bad5d0a1032fe5bc9945870d8c546c90cdeab2b0e05f090fdd91a52c707dcfc5056f06e1d712740b0fdbf5af4d7f031c3e368a3247213ee7626c02f7c2eb210b9c137763651ee3b590ab812a0ebb4d607788975f5398de1c3386002efd90947029c904fff3822f861d2add33c391779826e04881d7a8d4af4193430b4828fe10a071b5e6e04f09bffdd8968116c4170761e27eb75d7d989005ff07978d00b141bdcbb2f91e1601ae042806ff8346ce8af0228b0414993ee1c0d7020c0214c027827bc2b7040babb3eeaba35dc5d80338f054096fed2e35ce08cf7901c7634b9bb00047700ebd1f3361dfcc63c2435873fd292ce0290dd01aa811f05b046ff1bdd363bbb0a403e025c0d7ee5e123fa1e79bf93c51d0538328800bfe003f30cc1de4784a4d343a0a3005c2280958cbfe1dbb866eb2943aecb36573701384f009e415912fc78fb75745909741260071f4000d1dcf156e10621ee574a875da12e02308d0094315a3b1b06e2b5dfa6e9100eea2200cd1cd02e7c38c91f3d2fbd174719c39f6e4e070168e780b5a4ffd5f551d0ee42acaeb4de13682f8080156031a3557b07e24da0a33151db8de1f602903b04e490c1bcd5b360370ff7a3f880cfd094d602887c003c11bdaf9bfda84e2b9ff3fe3c2de3596d0538052802e79de16c5df369b05f061f1047f0511ad25600464960dde84d972faeafdeae3e48fc1adacd035b0ac07c0fa829d164b6f8c98db1f176bb98792f875a4abb7302ed0488353c008a184deed0e9f91b9fd03b8d682740d8327046096de281ad0410b407208a36f1c03602c4f4463fe38f16fbda6d0490b2092c8f7ef37de11602704c03d742f3a5600b0144640109a5f952b0b9006bf85b06451a2f051b0b70b20700651aef0a361680ed39102534dd156c2ac01efe8e419586d1a0a60248ce0290c13bf4544d1a0af0037fc5a04bb3b2210d05b018207d9a25063413c006000e340a08371240ed2e302f1a05841b09e0bac895814393807013016c0060429321a08900b60bc8850667051b08604160363408083710e013dedda04ffd3da1fa021c6d00e043fd21a0be00b60bc489da01e1da02d82e102feaee09d516c006005ed4dd16ae2b800d00cca83b0ba82b800d00dca8b910a829c011ded56043cd70604d012c06c08f7a3b02f504385b0c801f43e8bc6aea0960db801ca9951a544b00db066449adfb646a096089403ca9130caa25806502f2a4ce05d37504b072004c896ad4bead23800581b852e3c6ec1a025810882d354a86d410c082407c795de6f0b500160462ccebe4c0d702581088317de8c4725e0a604120d6bc2c7afd52000b02b1e6655ec84b012c08c49a97a18057021ce08d0ca6bc0a05bc1200efd663c30baf76845e09605340eebcc80d7c2180b2b2f01279f10c782180bc9be1d43185ae2ca15a80d8a280ec79b10ea81640facd502ad8406716532d8015851340752ca8528013bc85c199a8f28040a5004b780b833595d9c1950284bd09d17044656a609500762054063de8cf42aa04b05420216ca1438ba810c03201a4b0801e2da242000b034ba16a43a8420035d703cba72218582e802583caa16221582e808581e530873e2da05c8009fc67833f03e8d3024a05b08d40491ca157f3940a60d9c09228cf0a2915c0a24092282f1c5a2ac000feab2181f26870990076245816a5c542ca04b01381b228ad1957268015859045e924a044005b040aa374125022c016fe9f2185b24940890076224c1a6591801201ec4cb034caf2c28a05b045a038cab6038a05b09d4079946c07140b60b920f2283920542c400ffe932187929c804201ac36ac4046d0b9190a05b04b8225527c42ac508031fc1743123be8dd3445029ce17f18a228de0f2a12c0928144527c4cbc48008b038ba4f812a92201ac2c844c0a8f87140960510099149e112d10c0360284b2840e4e5120c037bcde1046615650810096102e94c20dc10201ec4c98548a66810502d81c502a45b747e405b0ca4062298a05e605b06410b114a585e505b039a0588a7684f302d856a0588a6a86e604b023218229381c9013c0e68082f9864e7e2227c01a5e6b08e4133af9899c007378ad219082db437202d89920c114dc249b152086971a22c90783b3025846b868f289a15901ac328868f26784b302d83d71a2c92f03b202581c5034f965405600bb234034f9654046003b13229cdc32202380058285935b066404b08450e1e496011901eca640e17c4147dfc90860ab40e1e452c33302d82a5038b9a4a08c00b60a144e041d7d272d80ad02c57382aebe9116c05681e2c99e104d0b6077458a27bb0e4c0b606702c4935d07a605b0f260e2c9ae03d3025818403cd975605a002b0e239eeccd1169012c23543e99fdc0b40076325c3e99fdc094009612ac80cce9a09400561e4a019952512901ecaa280564cac6a704b03890023279a12901ec60a802321563530258205001990de19400561d4603e90de194001609d6403a109012c022c11a4807025202588d500da40301290106f0124332e903a229012c255403e98c809400f00a4334e98c8067012c275805e98c8067016c2f4807a97aa126803e0ed0df7f3c0b60a7027490ba36e05900db0dd641ea227913401fa9a30126803e5277c83e0b60e541743086fefee359004b08d241aa549809a090e7408009a0902374f87f9e05b00a514a780e043c0b6029814a78be3ff05900431d49f20f39904a2f4d6be67a0000000049454e44ae426082	Julia leads the marketing team for Microsoft Azure, and is focused on how Microsoft presents its Applications, Infrastructure, Data and Intelligence capabilities to customers and partners. In addition to the primary focus on Azure, the team are also responsible for Microsoftâ€™s hybrid cloud assets; including SQL Server, Windows Server, Developer tools and management capabilities. Across this portfolio, Julia is responsible for the value proposition, global go to market strategy, and industry engagement. She also works in partnership with engineering leadership to chart the product roadmaps. Julia joined Microsoft in 2001 as a product manager in the Enterprise Server team. In 2005, she moved to Microsoftâ€™s US sales organization to run channel marketing and sales incentives. In 2007, she returned to product leadership, taking on Exchange Server product marketing. Over the course of the next 8 years, she was instrumental in leading the productâ€™s evolution from an on-premises server technology to establishing Office 365 as the leader in cloud productivity services. Julia has a bachelorâ€™s degree from Stanford University and a masterâ€™s in business administration from Harvard Business School.
3	Alice	Brewer	\\x89504e470d0a1a0a0000000d4948445200000200000002000803000000c3a624c8000000017352474200aece1ce90000000467414d410000b18f0bfc610500000300504c544500188d081c91102495182c9920349d283ca13044a53848aa4050aa4859ae5061b25969b6616dba6975be717dc27985c67d89c68591ca8d99ce95a1d29daad6a5aedaaeb6deb6bedebec6e2c6cee6ced6ead6daeedee2f2e6eaf6eef2faf6fafaffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3c3adbf0000002174524e53ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff009fc1d021000000097048597300005c4600005c4601149443410000160649444154785eed9dd776e2301040633a0924b42474fbffbf72d93014575c34d2b4fbb6e7b004a48b2c8d46a3b7c4508d09009cb6dbf562b198dc985ffeb158fc6cb75b7881504c80fd76319ff4de2ae85f6cd8eee1e5d2502dc061331f4127d76038f95aede07fca41ad00bbc524829e6d42345dc91a0b540a107fcffad0a16de87dac0ff04efcd127c0713d858eec427fb639c21bf2469900bbaf21f4a00346eb33bc2d633409b0eb34f017f2f10defcd163d026cc6d0696ee9cf794f0a950870fa72fee37f305c9de0cf30448500bb0fe82a34a66c1f05f20588370d823ded196ce0ef3143ba00a8637f1a9e0ac816205e5606f95d3358c7f087f9205a809f01f48c37fa2b6e0a08166087b3ee7b013705c40a70429ff997d15fc14760815001ce8b365b7dae18324a229129c0dadbd4bf84199bd09044010e411efe697a6bf830d41128c026e4e8ff60cc237b489c00e76093bf1c9f1c768ba509b0f3bef4afa0cf60874098000b687a2a4cc8a70d8912e04460f697a1f7039f8d2a9204f8f11af8afcb27edc8a01c01e239b43835c6a41f036204387bd9f56f05e9c78014018e0eb37ddd43f8312044807de8d8ef0be83e066408b02539fd7b86ec634084003f3482bfd5107d0c481060034d4c9c2949030408402dfa57ca88e2de007f0166d0bc0c18109c0a7217207e87c665419fde3132ee02b0eaffcb62805cb2187301a8867f4b89a8ed10f31680cdfcef0962b962ac0558439bf2e20b3e3d0d380bf0032dca8d197c7e12301660cb21fe57082503f80ab0271fff2f670edf81006c053852cafe6ccc02be4578b80a7066ddff6f6f4bf81ec1612a404c37ffa72654aa49301580d1064019441204780af00d8dc899e817be4c58580a7064bc00781091383cc8518098def98f56f428ec0d721480e30e40217d02f9010c05d842f30960103e47889f0027e219e08d78872f150e7e02304b017941f080103b0156d07252089d22c44d803ddb2dc012fa81cb49311320267d04b01513f86a816026809815e0139ff0ddc2c04b80a3b407c01f4177057809206b0570a317321ec44a00ae4980af18073c35c8490081334020609220270196d05c0209971ec2488093c819e09570d1004602c89c01021ff025bdc347805f682aa184ca0f622380dc19e0957ea095001b0104cf00af040a08721140f20c10089322c84500f103c0dbdb28c843808900b1a434a032829c17632280b4349042a2037c5b9ff01040c5001026358087003c4b81342740f9181e02b03f0a5a939eff88300b01a46e03e7f11f0c6021809601e0320ff43e04701040cf00106008e020c0141a4703de87000602eca16d74e0fbb018030144e701e4f17c669cbe0067f9db40293c0f01f405d01204bae37708a02fc004da450d7e8700f2029ca05914e17508202f808244802c5e8700f202e889023ef039045017e0006da20a9f43007501bea04d74e17108a02e00f39ad02df1b823405c801db488327afef243890bc0ee563047f84b0da22d80925cc03c2368007c680b20fc3c6005dea681b405f884e6d087b79211b405d01805ba12f9aa224c5a8033b4864656d006d8901660038da19121b40136a405107033507b3c1511262d80ce3020e0694380b20047680a9d78ca0fa62c80e629c0053f57095016e0035a42296368065c280b20e272b80e787906101640d7819002bc940f252c808aaa2055785907101640d989a03c918fac00c202689f02f8a91e4a5700850702b2cca12930a12b80de5c803b03680a4ce80aa0ee4c60011ed242e80aa03719e48187d2917405d05417a40c0fc140ba0268cd074d811f0c242b80e66ca007f8c140b202283d1292013f184856806f6802ddf4a035f0202b80ce53a139d00b88931540fd4ec0956f680e34c80a20fc8ea8baa09f13a62a400c0da01df42b04a80aa03b21f401fa2c90aa005b6800f560cf02a90a607b8100f62c90aa00ca53c21f60cf02a90aa03e21f006f62c90aa000bf8feea89a041b0a02a80d6e24079909342a80aa0fa60700ae40d41aa02a8ab115e0af22c90aa007a8bc36441ce0aa22a80ead20029906381540550764f4c15b8e783a80a005fde787b3b4293e0405400db0b7a805b2cc804200fee3ad004200f6ea91813803cb847444d00f2e0a6869b00e4c18d049900e4e9439be04054003b18f604b4090e4405b040d013a8912013803ea8912013803ea879a126007d50ef8e3001e8835a2886aa005624f0814a012c21e48109a01cd42be44c00faa814c0b2821fa81440f96d2129540a6075421fa814c00e873e50298055897b807a4098aa005627f2814a012c23e4814a016c33e0814e01ac58f81d9d028ce1db1b4a05b052b177740a6091a03ba80703c80ab0846f6fe80c0459a1c0075fd024289015c0224177542684d8d19007a8e7c3c90a601706dcf981164181ae0096117043e5c110db107e805a319eae007663c00d956703edd29807d02038d015c08a8502b8f5c2090b60f5a2af0ca03d70202c80cd02af8ca03d70202c80c502af4ca13d70202c80cd02afe0d68b272c80cd02afaca13970a02c80cd02ffd84173e04059009b05fe7186e6c081b200360bfc0f6e9940d202589990ff28bd32e60f9b045cc0ad154d5b003b207801b546187101ce7673d0dbdb2f340612a405b03a21174ed01648d016c016826aef0ebe62678491b782a80b6099a16f1fd012581017e00b9a412fc88b00ea02586220f2edf1d405501f0c44be3998be00da4f07e05e197681ba00dacf88624f01c80ba0fd8820eecdd117a80ba03c18889b11fc1ff202e8de1042ad0df107790162d5e5c2706f0eff0f790174170b429f023010e0006da19121b40122f405d03c0dc43d12f0070301144f03516b835c612080e269206e46f81f0c04d03b0d442d110a701040ed34107f11c84300add3c0c8c3138087004aa781d8c9407fb01040e93410f5daf81b2c04d0390decc5f0ed51e121c049e30911fc8da0fff01040e510805a20f40e1301140e01c8c7c26f301140e110807a4bc0032e02e81b02702bc3dce12280ba21c0c34ef01f6c04d03604a05e13f2041b01940d0111f2a9f03b7c04d03504784805b9c247005d4300f691c03b8c04d03404a09f08bbc348004d4380b7018095007a86007f03002b01f4948b40ae0cf60c2b01e201349070b0eb023dc34a80e4175a48381eb2c1eff0124047bd089f030037014e1a4ac6e0de1091819900c91a1a49307d2fa96037b809a020451cbd2a4c0a76021ca40703bcce00180a902ca0a1a4e22911e4063f0162d9e563fde4023fe02780eceaa1def2006e30142099436349c4ef0cf0024701ce724f8a8dbc2e01ffc35100c10f013f87419e612980d89b44bc9c074ec35380e41d5a4c16de678017980a7016b931ec7d067881a900c94e6040d0ff0cf0025701044e0322cf31c02b6c0590971ab0842fe617be02480b09fba80957005f0184ed0bf603ac00fec3580059d7c9784c044ec1590049d7cb7b3b0b9885b500f1149a8f3de3102bc03f580b90c4636840e64407f842fee12d40721e4113f2c64751e012980b901c25c4847d67013dc35d80e4c8ffa4c0c04751e832d80b90ecb91bd0c3bf19aa02fe0224bfbc03423d7fb5008a102000ef23a351a80810204100d621412f35e12b102140b284d6e487d783a045c81080ad01beca4196234400a64f81900100408a002cd7021e6b419522468064c72e1e300db603f4841c01923db3a8f0286400f08e20019223ab9da12989fe1725407266b43bfc4161fcbf204a00461922c13280b2c812804d96589814f022a409c0a3824cc004902ce20448b6e4ab0784deff49214f80e444bc925c2fc811b032040a40fc31300897005a844801283f06c641f37ff2c8142039535d0f7e1159fedf112a00d10de23ea5e9df15b102243b7a8f8169a003a055c8152039132b2414d189fe3c21588024f9a55442601836fbb70cd10224f1924c9ac88cdaec0f902d40929c683c077aa1937f4b912e008de7c03bc1d91f205f80245e047e0e8cfc1780ad8f020192e418322cd4273bfaffa14280cb732054b658b4203af9bba144808b0241f60867741ffe801a019264eb5d8109cda57f0a450224c9ceeb9a70e0f306d8d6a8122049f6de1498d2dbf7294499004972f09136da9b13dbf52f479d009745e102f908d1604de3cc472d140a70613bc33b48f8ce64ec07740a9024f137ca6ca0f7c966ec07b40a70e1b476bc4bd09fff108ffa14a058800b874f67d381d182c1a2bf00dd025c386e669d2588ded7e4237e65a817e03f9d246039f03f30018056128c3fbf691df3688e09f0c479bb59bcd7db31184cbe56a48e78b5c504c853eec16032992c168b5f115d7fc504a8e6b4bd21a8d39f310194434880a3d85f19650808b05d2f269998dc64325b2cb75b467b2a6c092cc0765139e9ee4d3ed75bceab6cfa0414e0bca9b91f33986dd806dac8134a80b86eef03c3f98f3d10300823c0f1abcd7efcfbb73d0d9c134280dfd65bf1d18739e018ff02fc743ba3c12fe58236be05e8d8fd7f304bbaa28d5f01b68e4e680d0995da648e4f014e1fd07f0ee071ea8201fe04705dad634cf9d0351fbc098050a761ca330b8f169e0438e39cc799d98aa02b7e04f8c5aad9177d5a7cb01b3e0440faf95fe951afc0401c0f02ec908fe20d2585058e9bc562b1fa9f81e469ff0b5f000f457be9d7e1a8c7f12bf55b19ce37f8731c6c014e5eea33f52404868e456192d112d9016401d0667f59c6dcf3f3cb8bd9bda3063c7005f078754744ae127f230e556112cc42839802c40e43bf35e03c195cbf8892bea30d7088029cbcd7e6e33a19acf34bf982d7ba064f807d800b1b784e06ebdd798c34cb4113e03b4c815e8a9772bca0eebdf738766309b0814fed1d9af77254f053ff97324798e7220910f2e63e5e2bc246bf9489fb9d0f1c01e6f081c3102df9ac081bfe52dcdf3a8921401cfc0aef219743868d5baae73a070241001297f8cf396c13b76929d706b8178044ffbfbdf5e9270d9e5b952f776c80730188f4ff05ea2bc273cb40995b035c0b40a7ffa94f06eb857f8a706a80630128f5ff05c2db03c70e69323d876b01b70210ebff0b542f6cdb774a931ab8fb566e05f0761d437d683e07f61dab958f9c2d729c0a107cfd5f08c1e7c06fe78d92a92bad5d0a1032fe5bc9945870d8c546c90cdeab2b0e05f090fdd91a52c707dcfc5056f06e1d712740b0fdbf5af4d7f031c3e368a3247213ee7626c02f7c2eb210b9c137763651ee3b590ab812a0ebb4d607788975f5398de1c3386002efd90947029c904fff3822f861d2add33c391779826e04881d7a8d4af4193430b4828fe10a071b5e6e04f09bffdd8968116c4170761e27eb75d7d989005ff07978d00b141bdcbb2f91e1601ae042806ff8346ce8af0228b0414993ee1c0d7020c0214c027827bc2b7040babb3eeaba35dc5d80338f054096fed2e35ce08cf7901c7634b9bb00047700ebd1f3361dfcc63c2435873fd292ce0290dd01aa811f05b046ff1bdd363bbb0a403e025c0d7ee5e123fa1e79bf93c51d0538328800bfe003f30cc1de4784a4d343a0a3005c2280958cbfe1dbb866eb2943aecb36573701384f009e415912fc78fb75745909741260071f4000d1dcf156e10621ee574a875da12e02308d0094315a3b1b06e2b5dfa6e9100eea2200cd1cd02e7c38c91f3d2fbd174719c39f6e4e070168e780b5a4ffd5f551d0ee42acaeb4de13682f8080156031a3557b07e24da0a33151db8de1f602903b04e490c1bcd5b360370ff7a3f880cfd094d602887c003c11bdaf9bfda84e2b9ff3fe3c2de3596d0538052802e79de16c5df369b05f061f1047f0511ad25600464960dde84d972faeafdeae3e48fc1adacd035b0ac07c0fa829d164b6f8c98db1f176bb98792f875a4abb7302ed0488353c008a184deed0e9f91b9fd03b8d682740d8327046096de281ad0410b407208a36f1c03602c4f4463fe38f16fbda6d0490b2092c8f7ef37de11602704c03d742f3a5600b0144640109a5f952b0b9006bf85b06451a2f051b0b70b20700651aef0a361680ed39102534dd156c2ac01efe8e419586d1a0a60248ce0290c13bf4544d1a0af0037fc5a04bb3b2210d05b018207d9a25063413c006000e340a08371240ed2e302f1a05841b09e0bac895814393807013016c0060429321a08900b60bc8850667051b08604160363408083710e013dedda04ffd3da1fa021c6d00e043fd21a0be00b60bc489da01e1da02d82e102feaee09d516c006005ed4dd16ae2b800d00cca83b0ba82b800d00dca8b910a829c011ded56043cd70604d012c06c08f7a3b02f504385b0c801f43e8bc6aea0960db801ca9951a544b00db066449adfb646a096089403ca9130caa25806502f2a4ce05d37504b072004c896ad4bead23800581b852e3c6ec1a025810882d354a86d410c082407c795de6f0b500160462ccebe4c0d702581088317de8c4725e0a604120d6bc2c7afd52000b02b1e6655ec84b012c08c49a97a18057021ce08d0ca6bc0a05bc1200efd663c30baf76845e09605340eebcc80d7c2180b2b2f01279f10c782180bc9be1d43185ae2ca15a80d8a280ec79b10ea81640facd502ad8406716532d8015851340752ca8528013bc85c199a8f28040a5004b780b833595d9c1950284bd09d17044656a609500762054063de8cf42aa04b05420216ca1438ba810c03201a4b0801e2da242000b034ba16a43a8420035d703cba72218582e802583caa16221582e808581e530873e2da05c8009fc67833f03e8d3024a05b08d40491ca157f3940a60d9c09228cf0a2915c0a24092282f1c5a2ac000feab2181f26870990076245816a5c542ca04b01381b228ad1957268015859045e924a044005b040aa374125022c016fe9f2185b24940890076224c1a6591801201ec4cb034caf2c28a05b045a038cab6038a05b09d4079946c07140b60b920f2283920542c400ffe932187929c804201ac36ac4046d0b9190a05b04b8225527c42ac508031fc1743123be8dd3445029ce17f18a228de0f2a12c0928144527c4cbc48008b038ba4f812a92201ac2c844c0a8f87140960510099149e112d10c0360284b2840e4e5120c037bcde1046615650810096102e94c20dc10201ec4c98548a66810502d81c502a45b747e405b0ca4062298a05e605b06410b114a585e505b039a0588a7684f302d856a0588a6a86e604b023218229381c9013c0e68082f9864e7e2227c01a5e6b08e4133af9899c007378ad219082db437202d89920c114dc249b152086971a22c90783b3025846b868f289a15901ac328868f26784b302d83d71a2c92f03b202581c5034f965405600bb234034f9654046003b13229cdc32202380058285935b066404b08450e1e496011901eca640e17c4147dfc90860ab40e1e452c33302d82a5038b9a4a08c00b60a144e041d7d272d80ad02c57382aebe9116c05681e2c99e104d0b6077458a27bb0e4c0b606702c4935d07a605b0f260e2c9ae03d3025818403cd975605a002b0e239eeccd1169012c23543e99fdc0b40076325c3e99fdc094009612ac80cce9a09400561e4a019952512901ecaa280564cac6a704b03890023279a12901ec60a802321563530258205001990de19400561d4603e90de194001609d6403a109012c022c11a4807025202588d500da40301290106f0124332e903a229012c255403e98c809400f00a4334e98c8067012c275805e98c8067016c2f4807a97aa126803e0ed0df7f3c0b60a7027490ba36e05900db0dd641ea227913401fa9a30126803e5277c83e0b60e541743086fefee359004b08d241aa549809a090e7408009a0902374f87f9e05b00a514a780e043c0b6029814a78be3ff05900431d49f20f39904a2f4d6be67a0000000049454e44ae426082	Alice is a supply chain expert!
4	Michael	Graham	\\x89504e470d0a1a0a0000000d4948445200000200000002000803000000c3a624c8000000017352474200aece1ce90000000467414d410000b18f0bfc610500000300504c544500188d081c91102495182c9920349d283ca13044a53848aa4050aa4859ae5061b25969b6616dba6975be717dc27985c67d89c68591ca8d99ce95a1d29daad6a5aedaaeb6deb6bedebec6e2c6cee6ced6ead6daeedee2f2e6eaf6eef2faf6fafaffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e3c3adbf0000002174524e53ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff009fc1d021000000097048597300005c4600005c4601149443410000160649444154785eed9dd776e2301040633a0924b42474fbffbf72d93014575c34d2b4fbb6e7b004a48b2c8d46a3b7c4508d09009cb6dbf562b198dc985ffeb158fc6cb75b7881504c80fd76319ff4de2ae85f6cd8eee1e5d2502dc061331f4127d76038f95aede07fca41ad00bbc524829e6d42345dc91a0b540a107fcffad0a16de87dac0ff04efcd127c0713d858eec427fb639c21bf2469900bbaf21f4a00346eb33bc2d633409b0eb34f017f2f10defcd163d026cc6d0696ee9cf794f0a950870fa72fee37f305c9de0cf30448500bb0fe82a34a66c1f05f20588370d823ded196ce0ef3143ba00a8637f1a9e0ac816205e5606f95d3358c7f087f9205a809f01f48c37fa2b6e0a08166087b3ee7b013705c40a70429ff997d15fc14760815001ce8b365b7dae18324a229129c0dadbd4bf84199bd09044010e411efe697a6bf830d41128c026e4e8ff60cc237b489c00e76093bf1c9f1c768ba509b0f3bef4afa0cf60874098000b687a2a4cc8a70d8912e04460f697a1f7039f8d2a9204f8f11af8afcb27edc8a01c01e239b43835c6a41f036204387bd9f56f05e9c78014018e0eb37ddd43f8312044807de8d8ef0be83e066408b02539fd7b86ec634084003f3482bfd5107d0c481060034d4c9c2949030408402dfa57ca88e2de007f0166d0bc0c18109c0a7217207e87c665419fde3132ee02b0eaffcb62805cb2187301a8867f4b89a8ed10f31680cdfcef0962b962ac0558439bf2e20b3e3d0d380bf0032dca8d197c7e12301660cb21fe57082503f80ab0271fff2f670edf81006c053852cafe6ccc02be4578b80a7066ddff6f6f4bf81ec1612a404c37ffa72654aa49301580d1064019441204780af00d8dc899e817be4c58580a7064bc00781091383cc8518098def98f56f428ec0d721480e30e40217d02f9010c05d842f30960103e47889f0027e219e08d78872f150e7e02304b017941f080103b0156d07252089d22c44d803ddb2dc012fa81cb49311320267d04b01513f86a816026809815e0139ff0ddc2c04b80a3b407c01f4177057809206b0570a317321ec44a00ae4980af18073c35c8490081334020609220270196d05c0209971ec2488093c819e09570d1004602c89c01021ff025bdc347805f682aa184ca0f622380dc19e0957ea095001b0104cf00af040a08721140f20c10089322c84500f103c0dbdb28c843808900b1a434a032829c17632280b4349042a2037c5b9ff01040c5001026358087003c4b81342740f9181e02b03f0a5a939eff88300b01a46e03e7f11f0c6021809601e0320ff43e04701040cf00106008e020c0141a4703de87000602eca16d74e0fbb018030144e701e4f17c669cbe0067f9db40293c0f01f405d01204bae37708a02fc004da450d7e8700f2029ca05914e17508202f808244802c5e8700f202e889023ef039045017e0006da20a9f43007501bea04d74e17108a02e00f39ad02df1b823405c801db488327afef243890bc0ee563047f84b0da22d80925cc03c2368007c680b20fc3c6005dea681b405f884e6d087b79211b405d01805ba12f9aa224c5a8033b4864656d006d8901660038da19121b40136a405107033507b3c1511262d80ce3020e0694380b20047680a9d78ca0fa62c80e629c0053f57095016e0035a42296368065c280b20e272b80e787906101640d7819002bc940f252c808aaa2055785907101640d989a03c918fac00c202689f02f8a91e4a5700850702b2cca12930a12b80de5c803b03680a4ce80aa0ee4c60011ed242e80aa03719e48187d2917405d05417a40c0fc140ba0268cd074d811f0c242b80e66ca007f8c140b202283d1292013f184856806f6802ddf4a035f0202b80ce53a139d00b88931540fd4ec0956f680e34c80a20fc8ea8baa09f13a62a400c0da01df42b04a80aa03b21f401fa2c90aa005b6800f560cf02a90a607b8100f62c90aa00ca53c21f60cf02a90aa03e21f006f62c90aa000bf8feea89a041b0a02a80d6e24079909342a80aa0fa60700ae40d41aa02a8ab115e0af22c90aa007a8bc36441ce0aa22a80ead20029906381540550764f4c15b8e783a80a005fde787b3b4293e0405400db0b7a805b2cc804200fee3ad004200f6ea91813803cb847444d00f2e0a6869b00e4c18d049900e4e9439be04054003b18f604b4090e4405b040d013a8912013803ea8912013803ea879a126007d50ef8e3001e8835a2886aa005624f0814a012c21e48109a01cd42be44c00faa814c0b2821fa81440f96d2129540a6075421fa814c00e873e50298055897b807a4098aa005627f2814a012c23e4814a016c33e0814e01ac58f81d9d028ce1db1b4a05b052b177740a6091a03ba80703c80ab0846f6fe80c0459a1c0075fd024289015c0224177542684d8d19007a8e7c3c90a601706dcf981164181ae0096117043e5c110db107e805a319eae007663c00d956703edd29807d02038d015c08a8502b8f5c2090b60f5a2af0ca03d70202c80cd02af8ca03d70202c80c502af4ca13d70202c80cd02afe0d68b272c80cd02afaca13970a02c80cd02ffd84173e04059009b05fe7186e6c081b200360bfc0f6e9940d202589990ff28bd32e60f9b045cc0ad154d5b003b207801b546187101ce7673d0dbdb2f340612a405b03a21174ed01648d016c016826aef0ebe62678491b782a80b6099a16f1fd012581017e00b9a412fc88b00ea02586220f2edf1d405501f0c44be3998be00da4f07e05e197681ba00dacf88624f01c80ba0fd8820eecdd117a80ba03c18889b11fc1ff202e8de1042ad0df107790162d5e5c2706f0eff0f790174170b429f023010e0006da19121b40122f405d03c0dc43d12f0070301144f03516b835c612080e269206e46f81f0c04d03b0d442d110a701040ed34107f11c84300add3c0c8c3138087004aa781d8c9407fb01040e93410f5daf81b2c04d0390decc5f0ed51e121c049e30911fc8da0fff01040e510805a20f40e1301140e01c8c7c26f301140e110807a4bc0032e02e81b02702bc3dce12280ba21c0c34ef01f6c04d03604a05e13f2041b01940d0111f2a9f03b7c04d03504784805b9c247005d4300f691c03b8c04d03404a09f08bbc348004d4380b7018095007a86007f03002b01f4948b40ae0cf60c2b01e201349070b0eb023dc34a80e4175a48381eb2c1eff0124047bd089f030037014e1a4ac6e0de1091819900c91a1a49307d2fa96037b809a020451cbd2a4c0a76021ca40703bcce00180a902ca0a1a4e22911e4063f0162d9e563fde4023fe02780eceaa1def2006e30142099436349c4ef0cf0024701ce724f8a8dbc2e01ffc35100c10f013f87419e612980d89b44bc9c074ec35380e41d5a4c16de678017980a7016b931ec7d067881a900c94e6040d0ff0cf0025701044e0322cf31c02b6c0590971ab0842fe617be02480b09fba80957005f0184ed0bf603ac00fec3580059d7c9784c044ec1590049d7cb7b3b0b9885b500f1149a8f3de3102bc03f580b90c4636840e64407f842fee12d40721e4113f2c64751e012980b901c25c4847d67013dc35d80e4c8ffa4c0c04751e832d80b90ecb91bd0c3bf19aa02fe0224bfbc03423d7fb5008a102000ef23a351a80810204100d621412f35e12b102140b284d6e487d783a045c81080ad01beca4196234400a64f81900100408a002cd7021e6b419522468064c72e1e300db603f4841c01923db3a8f0286400f08e20019223ab9da12989fe1725407266b43bfc4161fcbf204a00461922c13280b2c812804d96589814f022a409c0a3824cc004902ce20448b6e4ab0784deff49214f80e444bc925c2fc811b032040a40fc31300897005a844801283f06c641f37ff2c8142039535d0f7e1159fedf112a00d10de23ea5e9df15b102243b7a8f8169a003a055c8152039132b2414d189fe3c21588024f9a55442601836fbb70cd10224f1924c9ac88cdaec0f902d40929c683c077aa1937f4b912e008de7c03bc1d91f205f80245e047e0e8cfc1780ad8f020192e418322cd4273bfaffa14280cb732054b658b4203af9bba144808b0241f60867741ffe801a019264eb5d8109cda57f0a450224c9ceeb9a70e0f306d8d6a8122049f6de1498d2dbf7294499004972f09136da9b13dbf52f479d009745e102f908d1604de3cc472d140a70613bc33b48f8ce64ec07740a9024f137ca6ca0f7c966ec07b40a70e1b476bc4bd09fff108ffa14a058800b874f67d381d182c1a2bf00dd025c386e669d2588ded7e4237e65a817e03f9d246039f03f30018056128c3fbf691df3688e09f0c479bb59bcd7db31184cbe56a48e78b5c504c853eec16032992c168b5f115d7fc504a8e6b4bd21a8d39f310194434880a3d85f19650808b05d2f269998dc64325b2cb75b467b2a6c092cc0765139e9ee4d3ed75bceab6cfa0414e0bca9b91f33986dd806dac8134a80b86eef03c3f98f3d10300823c0f1abcd7efcfbb73d0d9c134280dfd65bf1d18739e018ff02fc743ba3c12fe58236be05e8d8fd7f304bbaa28d5f01b68e4e680d0995da648e4f014e1fd07f0ee071ea8201fe04705dad634cf9d0351fbc098050a761ca330b8f169e0438e39cc799d98aa02b7e04f8c5aad9177d5a7cb01b3e0440faf95fe951afc0401c0f02ec908fe20d2585058e9bc562b1fa9f81e469ff0b5f000f457be9d7e1a8c7f12bf55b19ce37f8731c6c014e5eea33f52404868e456192d112d9016401d0667f59c6dcf3f3cb8bd9bda3063c7005f078754744ae127f230e556112cc42839802c40e43bf35e03c195cbf8892bea30d7088029cbcd7e6e33a19acf34bf982d7ba064f807d800b1b784e06ebdd798c34cb4113e03b4c815e8a9772bca0eebdf738766309b0814fed1d9af77254f053ff97324798e7220910f2e63e5e2bc246bf9489fb9d0f1c01e6f081c3102df9ac081bfe52dcdf3a8921401cfc0aef219743868d5baae73a070241001297f8cf396c13b76929d706b8178044ffbfbdf5e9270d9e5b952f776c80730188f4ff05ea2bc273cb40995b035c0b40a7ffa94f06eb857f8a706a80630128f5ff05c2db03c70e69323d876b01b70210ebff0b542f6cdb774a931ab8fb566e05f0761d437d683e07f61dab958f9c2d729c0a107cfd5f08c1e7c06fe78d92a92bad5d0a1032fe5bc9945870d8c546c90cdeab2b0e05f090fdd91a52c707dcfc5056f06e1d712740b0fdbf5af4d7f031c3e368a3247213ee7626c02f7c2eb210b9c137763651ee3b590ab812a0ebb4d607788975f5398de1c3386002efd90947029c904fff3822f861d2add33c391779826e04881d7a8d4af4193430b4828fe10a071b5e6e04f09bffdd8968116c4170761e27eb75d7d989005ff07978d00b141bdcbb2f91e1601ae042806ff8346ce8af0228b0414993ee1c0d7020c0214c027827bc2b7040babb3eeaba35dc5d80338f054096fed2e35ce08cf7901c7634b9bb00047700ebd1f3361dfcc63c2435873fd292ce0290dd01aa811f05b046ff1bdd363bbb0a403e025c0d7ee5e123fa1e79bf93c51d0538328800bfe003f30cc1de4784a4d343a0a3005c2280958cbfe1dbb866eb2943aecb36573701384f009e415912fc78fb75745909741260071f4000d1dcf156e10621ee574a875da12e02308d0094315a3b1b06e2b5dfa6e9100eea2200cd1cd02e7c38c91f3d2fbd174719c39f6e4e070168e780b5a4ffd5f551d0ee42acaeb4de13682f8080156031a3557b07e24da0a33151db8de1f602903b04e490c1bcd5b360370ff7a3f880cfd094d602887c003c11bdaf9bfda84e2b9ff3fe3c2de3596d0538052802e79de16c5df369b05f061f1047f0511ad25600464960dde84d972faeafdeae3e48fc1adacd035b0ac07c0fa829d164b6f8c98db1f176bb98792f875a4abb7302ed0488353c008a184deed0e9f91b9fd03b8d682740d8327046096de281ad0410b407208a36f1c03602c4f4463fe38f16fbda6d0490b2092c8f7ef37de11602704c03d742f3a5600b0144640109a5f952b0b9006bf85b06451a2f051b0b70b20700651aef0a361680ed39102534dd156c2ac01efe8e419586d1a0a60248ce0290c13bf4544d1a0af0037fc5a04bb3b2210d05b018207d9a25063413c006000e340a08371240ed2e302f1a05841b09e0bac895814393807013016c0060429321a08900b60bc8850667051b08604160363408083710e013dedda04ffd3da1fa021c6d00e043fd21a0be00b60bc489da01e1da02d82e102feaee09d516c006005ed4dd16ae2b800d00cca83b0ba82b800d00dca8b910a829c011ded56043cd70604d012c06c08f7a3b02f504385b0c801f43e8bc6aea0960db801ca9951a544b00db066449adfb646a096089403ca9130caa25806502f2a4ce05d37504b072004c896ad4bead23800581b852e3c6ec1a025810882d354a86d410c082407c795de6f0b500160462ccebe4c0d702581088317de8c4725e0a604120d6bc2c7afd52000b02b1e6655ec84b012c08c49a97a18057021ce08d0ca6bc0a05bc1200efd663c30baf76845e09605340eebcc80d7c2180b2b2f01279f10c782180bc9be1d43185ae2ca15a80d8a280ec79b10ea81640facd502ad8406716532d8015851340752ca8528013bc85c199a8f28040a5004b780b833595d9c1950284bd09d17044656a609500762054063de8cf42aa04b05420216ca1438ba810c03201a4b0801e2da242000b034ba16a43a8420035d703cba72218582e802583caa16221582e808581e530873e2da05c8009fc67833f03e8d3024a05b08d40491ca157f3940a60d9c09228cf0a2915c0a24092282f1c5a2ac000feab2181f26870990076245816a5c542ca04b01381b228ad1957268015859045e924a044005b040aa374125022c016fe9f2185b24940890076224c1a6591801201ec4cb034caf2c28a05b045a038cab6038a05b09d4079946c07140b60b920f2283920542c400ffe932187929c804201ac36ac4046d0b9190a05b04b8225527c42ac508031fc1743123be8dd3445029ce17f18a228de0f2a12c0928144527c4cbc48008b038ba4f812a92201ac2c844c0a8f87140960510099149e112d10c0360284b2840e4e5120c037bcde1046615650810096102e94c20dc10201ec4c98548a66810502d81c502a45b747e405b0ca4062298a05e605b06410b114a585e505b039a0588a7684f302d856a0588a6a86e604b023218229381c9013c0e68082f9864e7e2227c01a5e6b08e4133af9899c007378ad219082db437202d89920c114dc249b152086971a22c90783b3025846b868f289a15901ac328868f26784b302d83d71a2c92f03b202581c5034f965405600bb234034f9654046003b13229cdc32202380058285935b066404b08450e1e496011901eca640e17c4147dfc90860ab40e1e452c33302d82a5038b9a4a08c00b60a144e041d7d272d80ad02c57382aebe9116c05681e2c99e104d0b6077458a27bb0e4c0b606702c4935d07a605b0f260e2c9ae03d3025818403cd975605a002b0e239eeccd1169012c23543e99fdc0b40076325c3e99fdc094009612ac80cce9a09400561e4a019952512901ecaa280564cac6a704b03890023279a12901ec60a802321563530258205001990de19400561d4603e90de194001609d6403a109012c022c11a4807025202588d500da40301290106f0124332e903a229012c255403e98c809400f00a4334e98c8067012c275805e98c8067016c2f4807a97aa126803e0ed0df7f3c0b60a7027490ba36e05900db0dd641ea227913401fa9a30126803e5277c83e0b60e541743086fefee359004b08d241aa549809a090e7408009a0902374f87f9e05b00a514a780e043c0b6029814a78be3ff05900431d49f20f39904a2f4d6be67a0000000049454e44ae426082	Michael works with the US Trade Commission and helps reform trade policies
\.


--
-- TOC entry 2958 (class 0 OID 0)
-- Dependencies: 214
-- Name: mysequence; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mysequence', 10, false);


--
-- TOC entry 2959 (class 0 OID 0)
-- Dependencies: 201
-- Name: ddl_history_id_seq; Type: SEQUENCE SET; Schema: reg_app; Owner: postgres
--

SELECT pg_catalog.setval('reg_app.ddl_history_id_seq', 66, true);


--
-- TOC entry 2960 (class 0 OID 0)
-- Dependencies: 215
-- Name: reg_app_seq; Type: SEQUENCE SET; Schema: reg_app; Owner: postgres
--

SELECT pg_catalog.setval('reg_app.reg_app_seq', 103, false);


--
-- TOC entry 2766 (class 2606 OID 16511)
-- Name: attendees attendees_pkey; Type: CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.attendees
    ADD CONSTRAINT attendees_pkey PRIMARY KEY (id);

--
-- TOC entry 2769 (class 2606 OID 16509)
-- Name: events events_pkey; Type: CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- TOC entry 2773 (class 2606 OID 16501)
-- Name: registrations registrations_pkey; Type: CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.registrations
    ADD CONSTRAINT registrations_pkey PRIMARY KEY (id);


--
-- TOC entry 2775 (class 2606 OID 16507)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 2777 (class 2606 OID 16513)
-- Name: speakers speakers_pkey; Type: CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.speakers
    ADD CONSTRAINT speakers_pkey PRIMARY KEY (id);


--
-- TOC entry 2767 (class 1259 OID 16451)
-- Name: ix_attendees_email; Type: INDEX; Schema: reg_app; Owner: postgres
--

CREATE UNIQUE INDEX ix_attendees_email ON reg_app.attendees USING btree (email_address);


--
-- TOC entry 2770 (class 1259 OID 16452)
-- Name: ix_events_name; Type: INDEX; Schema: reg_app; Owner: postgres
--

CREATE INDEX ix_events_name ON reg_app.events USING btree (event_name);


--
-- TOC entry 2771 (class 1259 OID 16453)
-- Name: ix_reg_sess_attendee; Type: INDEX; Schema: reg_app; Owner: postgres
--

CREATE UNIQUE INDEX ix_reg_sess_attendee ON reg_app.registrations USING btree (session_id, attendee_id);


--
-- TOC entry 2907 (class 2618 OID 16466)
-- Name: registrations protect_data; Type: RULE; Schema: reg_app; Owner: postgres
--

CREATE RULE protect_data AS
    ON UPDATE TO reg_app.registrations
   WHERE (old.attendee_id = 1) DO INSTEAD NOTHING;


--
-- TOC entry 2782 (class 2620 OID 16470)
-- Name: attendees attendee_insert_trigger; Type: TRIGGER; Schema: reg_app; Owner: postgres
--

CREATE TRIGGER attendee_insert_trigger AFTER INSERT ON reg_app.attendees FOR EACH ROW EXECUTE PROCEDURE public.attendee_insert_trigger_fnc();


--
-- TOC entry 2778 (class 2606 OID 16514)
-- Name: registrations registrations_attendee_id_fkey; Type: FK CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.registrations
    ADD CONSTRAINT registrations_attendee_id_fkey FOREIGN KEY (attendee_id) REFERENCES reg_app.attendees(id);


--
-- TOC entry 2779 (class 2606 OID 16519)
-- Name: registrations registrations_session_id_fkey; Type: FK CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.registrations
    ADD CONSTRAINT registrations_session_id_fkey FOREIGN KEY (session_id) REFERENCES reg_app.sessions(id);


--
-- TOC entry 2780 (class 2606 OID 16524)
-- Name: sessions sessions_event_id_fkey; Type: FK CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.sessions
    ADD CONSTRAINT sessions_event_id_fkey FOREIGN KEY (event_id) REFERENCES reg_app.events(id);


--
-- TOC entry 2781 (class 2606 OID 16529)
-- Name: sessions sessions_speaker_id_fkey; Type: FK CONSTRAINT; Schema: reg_app; Owner: postgres
--

ALTER TABLE ONLY reg_app.sessions
    ADD CONSTRAINT sessions_speaker_id_fkey FOREIGN KEY (speaker_id) REFERENCES reg_app.speakers(id);


--
-- TOC entry 2908 (class 6104 OID 16494)
-- Name: app_pub; Type: PUBLICATION; Schema: -; Owner: postgres
--

CREATE PUBLICATION app_pub WITH (publish = 'insert, update, delete');


ALTER PUBLICATION app_pub OWNER TO s2admin;

--
-- TOC entry 2930 (class 0 OID 0)
-- Dependencies: 238
-- Name: FUNCTION attendee_insert_trigger_fnc(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.attendee_insert_trigger_fnc() TO conferenceuser;


--
-- TOC entry 2932 (class 0 OID 0)
-- Dependencies: 230
-- Name: FUNCTION file_fdw_validator(text[], oid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.file_fdw_validator(text[], oid) TO conferenceuser;


--
-- TOC entry 2933 (class 0 OID 0)
-- Dependencies: 239
-- Name: FUNCTION log_ddl(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.log_ddl() TO conferenceuser;


--
-- TOC entry 2934 (class 0 OID 0)
-- Dependencies: 240
-- Name: FUNCTION log_ddl_drop(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.log_ddl_drop() TO conferenceuser;


--
-- TOC entry 2936 (class 0 OID 0)
-- Dependencies: 232
-- Name: FUNCTION postgres_fdw_handler(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.postgres_fdw_handler() TO conferenceuser;


--
-- TOC entry 2939 (class 0 OID 0)
-- Dependencies: 235
-- Name: FUNCTION get_random_attendee(OUT p_attendeeid integer); Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON FUNCTION reg_app.get_random_attendee(OUT p_attendeeid integer) TO conferenceuser;


--
-- TOC entry 2940 (class 0 OID 0)
-- Dependencies: 236
-- Name: FUNCTION hello_world(); Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON FUNCTION reg_app.hello_world() TO conferenceuser;


--
-- TOC entry 2941 (class 0 OID 0)
-- Dependencies: 237
-- Name: FUNCTION register_attendee_session(p_session_id integer, p_attendee_id integer, OUT status integer); Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON FUNCTION reg_app.register_attendee_session(p_session_id integer, p_attendee_id integer, OUT status integer) TO conferenceuser;


--
-- TOC entry 2943 (class 0 OID 0)
-- Dependencies: 214
-- Name: SEQUENCE mysequence; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.mysequence TO conferenceuser;


--
-- TOC entry 2944 (class 0 OID 0)
-- Dependencies: 203
-- Name: TABLE attendees; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.attendees TO conferenceuser;


--
-- TOC entry 2945 (class 0 OID 0)
-- Dependencies: 204
-- Name: TABLE attendees_audit; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.attendees_audit TO conferenceuser;


--
-- TOC entry 2946 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE ddl_history; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.ddl_history TO conferenceuser;


--
-- TOC entry 2948 (class 0 OID 0)
-- Dependencies: 201
-- Name: SEQUENCE ddl_history_id_seq; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON SEQUENCE reg_app.ddl_history_id_seq TO conferenceuser;


--
-- TOC entry 2949 (class 0 OID 0)
-- Dependencies: 205
-- Name: TABLE events; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.events TO conferenceuser;


--
-- TOC entry 2950 (class 0 OID 0)
-- Dependencies: 209
-- Name: TABLE jobs; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.jobs TO conferenceuser;


--
-- TOC entry 2951 (class 0 OID 0)
-- Dependencies: 215
-- Name: SEQUENCE reg_app_seq; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON SEQUENCE reg_app.reg_app_seq TO conferenceuser;


--
-- TOC entry 2952 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE registrations; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.registrations TO conferenceuser;


--
-- TOC entry 2953 (class 0 OID 0)
-- Dependencies: 207
-- Name: TABLE sessions; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.sessions TO conferenceuser;


--
-- TOC entry 2954 (class 0 OID 0)
-- Dependencies: 211
-- Name: TABLE mv_attendee_sessions; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.mv_attendee_sessions TO conferenceuser;


--
-- TOC entry 2955 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE speakers; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.speakers TO conferenceuser;


--
-- TOC entry 2956 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE v_attendee_sessions; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.v_attendee_sessions TO conferenceuser;


--
-- TOC entry 2957 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE v_spk_session; Type: ACL; Schema: reg_app; Owner: postgres
--

GRANT ALL ON TABLE reg_app.v_spk_session TO conferenceuser;


--
-- TOC entry 2760 (class 3466 OID 16499)
-- Name: log_ddl_drop_info; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER log_ddl_drop_info ON sql_drop
   EXECUTE FUNCTION public.log_ddl_drop();


ALTER EVENT TRIGGER log_ddl_drop_info OWNER TO s2admin;

--
-- TOC entry 2759 (class 3466 OID 16498)
-- Name: log_ddl_info; Type: EVENT TRIGGER; Schema: -; Owner: postgres
--

CREATE EVENT TRIGGER log_ddl_info ON ddl_command_end
   EXECUTE FUNCTION public.log_ddl();


ALTER EVENT TRIGGER log_ddl_info OWNER TO s2admin;

--
-- TOC entry 2918 (class 0 OID 16440)
-- Dependencies: 211 2923
-- Name: mv_attendee_sessions; Type: MATERIALIZED VIEW DATA; Schema: reg_app; Owner: postgres
--

REFRESH MATERIALIZED VIEW reg_app.mv_attendee_sessions;


-- Completed on 2021-06-17 01:39:39

--
-- PostgreSQL database dump complete
--

