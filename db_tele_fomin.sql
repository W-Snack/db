--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2024-12-24 04:39:31

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16556)
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- TOC entry 4968 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- TOC entry 904 (class 1247 OID 16389)
-- Name: t_child; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.t_child AS (
	cname text,
	cdob date
);


ALTER TYPE public.t_child OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16390)
-- Name: check_salary(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_salary() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.salary < 500 THEN
        NEW.salary = 501;
        RAISE NOTICE 'Correction salary value of % %', NEW.sfn, NEW.sln;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_salary() OWNER TO postgres;

--
-- TOC entry 4969 (class 0 OID 0)
-- Dependencies: 247
-- Name: FUNCTION check_salary(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.check_salary() IS 'Checking salary, if new salary < 500 then establish value as 500';


--
-- TOC entry 248 (class 1255 OID 16391)
-- Name: correct_minutes(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.correct_minutes(calc_minutes bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF calc_minutes < 0 THEN
        RETURN 0;
    ELSE
        RETURN calc_minutes;
    END IF;
END;
$$;


ALTER FUNCTION public.correct_minutes(calc_minutes bigint) OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 16392)
-- Name: cursor_test(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cursor_test(tkt integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    ss NUMERIC;
    curs CURSOR FOR SELECT * FROM s WHERE kt = tkt;
    rr RECORD;
BEGIN
    ss = 0.0;
    OPEN curs;
    LOOP
        FETCH curs INTO rr;
            EXIT WHEN NOT FOUND;
        IF rr.salary < 1000 THEN
            ss = ss + rr.salary;
            UPDATE s SET salary = 1001 WHERE CURRENT OF curs;
        END IF;
    END LOOP;
    CLOSE curs;
    RETURN ss;
END;
$$;


ALTER FUNCTION public.cursor_test(tkt integer) OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16393)
-- Name: dev_sum_subscr(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dev_sum_subscr() RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE 
    ss NUMERIC = 0.0;
    rr RECORD;
BEGIN
    FOR rr IN SELECT * FROM s LOOP
        ss = ss + rr.salary;
    END LOOP;
    RETURN ss;
END;
$$;


ALTER FUNCTION public.dev_sum_subscr() OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 16394)
-- Name: dev_tariff(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.dev_tariff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
-- Structure NEW is input parameter 
BEGIN
    RAISE NOTICE 'Before insert trigger';
    IF NEW.monthfee < 0 OR NEW.monthmins < 0 OR
       NEW.minfee < 0 
    THEN
        RAISE EXCEPTION 'Negative value: (%) OR (%) OR (%)',
                        NEW.monthfee, NEW.monthmins, NEW.minfee;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.dev_tariff() OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 16395)
-- Name: f_bill(integer, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_bill(a_kt integer, a_totalmins bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$DECLARE
    tariff_record RECORD;
    invoice NUMERIC;
BEGIN
    SELECT * INTO tariff_record FROM t WHERE kt = a_kt;
    IF a_totalmins <= tariff_record.monthmins THEN
        invoice = tariff_record.monthfee;
    ELSE
        invoice = tariff_record.monthfee + tariff_record.minfee * (a_totalmins - tariff_record.monthmins);
    END IF;
    RETURN invoice;
END;$$;


ALTER FUNCTION public.f_bill(a_kt integer, a_totalmins bigint) OWNER TO postgres;

--
-- TOC entry 4970 (class 0 OID 0)
-- Dependencies: 254
-- Name: FUNCTION f_bill(a_kt integer, a_totalmins bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.f_bill(a_kt integer, a_totalmins bigint) IS 'This function calculates invoice for the total minutes according to tariff';


--
-- TOC entry 263 (class 1255 OID 16396)
-- Name: f_billing(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_billing(s_kt integer, totalmins integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    tariff_rec RECORD;
    invoice INTEGER;
BEGIN
    SELECT * INTO tariff_rec FROM t WHERE kt = s_kt;
    IF totalmins <= tariff_rec.monthmins THEN
        invoice = tariff_rec.monthfee;
    ELSE
        invoice = tariff_rec.monthfee + 
                  tariff_rec.minfee * (totalmins - tariff_rec.monthmins);
    END IF;
    RETURN invoice;
END;

$$;


ALTER FUNCTION public.f_billing(s_kt integer, totalmins integer) OWNER TO postgres;

--
-- TOC entry 4971 (class 0 OID 0)
-- Dependencies: 263
-- Name: FUNCTION f_billing(s_kt integer, totalmins integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.f_billing(s_kt integer, totalmins integer) IS 'This function performs and calculates invoice for total minutes according by tariff code';


--
-- TOC entry 264 (class 1255 OID 16397)
-- Name: f_billing(integer, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_billing(s_kt integer, totalmins bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    tariff_rec RECORD;
    invoice INTEGER;
BEGIN
    SELECT * INTO tariff_rec FROM t WHERE kt = s_kt;
    IF totalmins <= tariff_rec.monthmins THEN
        invoice = tariff_rec.monthfee;
    ELSE
        invoice = tariff_rec.monthfee + 
                  tariff_rec.minfee * (totalmins - tariff_rec.monthmins);
    END IF;
    RETURN invoice;
END;

$$;


ALTER FUNCTION public.f_billing(s_kt integer, totalmins bigint) OWNER TO postgres;

--
-- TOC entry 265 (class 1255 OID 16398)
-- Name: f_billing2(integer, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_billing2(s_kt integer, totalmins bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    tariff_rec RECORD;
    invoice NUMERIC;
BEGIN
    SELECT * INTO tariff_rec FROM t WHERE kt = s_kt;
    IF totalmins <= tariff_rec.monthmins THEN
        invoice = tariff_rec.monthfee;
    ELSE
        invoice = tariff_rec.monthfee + tariff_rec.minfee * (totalmins - tariff_rec.monthmins);
    END IF;
    RETURN invoice;
END;
$$;


ALTER FUNCTION public.f_billing2(s_kt integer, totalmins bigint) OWNER TO postgres;

--
-- TOC entry 4972 (class 0 OID 0)
-- Dependencies: 265
-- Name: FUNCTION f_billing2(s_kt integer, totalmins bigint); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.f_billing2(s_kt integer, totalmins bigint) IS '<invoice> = monthfee IF (calling <= monthmins)
<invoice> = monthfee + minfee * (calling - monthmins)  IF (calling > monthmins)
monthmins and minfee are according by tariff (kt)';


--
-- TOC entry 266 (class 1255 OID 16399)
-- Name: f_qa_itog(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.f_qa_itog() RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    mrecord RECORD;
    sitog NUMERIC = 0.0;
BEGIN
    RAISE NOTICE 'Privet!';
    FOR mrecord IN SELECT * FROM s LOOP
        sitog = sitog + mrecord.salary;
    END LOOP;
    RAISE NOTICE 'Result = %', sitog;
    RETURN sitog;
END;
$$;


ALTER FUNCTION public.f_qa_itog() OWNER TO postgres;

--
-- TOC entry 267 (class 1255 OID 16400)
-- Name: init_balance(numeric); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.init_balance(IN start_balance numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
   cust_cursor CURSOR FOR SELECT * FROM s;
   cust        RECORD;
   cur_pack    INTEGER;
BEGIN
   -- Очистка таблицы остатков
   DELETE FROM rest_balance;
   
   -- Работа с записями из таблицы абонентов
   OPEN cust_cursor; -- Открытие курсора и выполнение выборки
   LOOP
      FETCH cust_cursor INTO cust; -- Берём текущую запись
      EXIT WHEN NOT FOUND; -- выход, если прошли все записи
      
      -- Ищем пакет минут
      SELECT monthmins INTO cur_pack FROM t WHERE kt = cust.kt;
      
      -- Генерируем новую запись в таблице баланса
      INSERT INTO rest_balance(ks, minutes, balance)
             VALUES (cust.ks, cur_pack, start_balance);
   
   END LOOP;
   CLOSE cust_cursor;
END;
$$;


ALTER PROCEDURE public.init_balance(IN start_balance numeric) OWNER TO postgres;

--
-- TOC entry 4973 (class 0 OID 0)
-- Dependencies: 267
-- Name: PROCEDURE init_balance(IN start_balance numeric); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.init_balance(IN start_balance numeric) IS '1) Создать специальную таблицу <rest_balance> для запоминания данных об остатке минут и текущем балансе:
- создание пустой таблицы (одкратное действие);
- загрузка данных для каждого абонента: пакеты минут (из соответствующего тарифа), на баланс кидаем 10';


--
-- TOC entry 279 (class 1255 OID 16401)
-- Name: init_call(integer, timestamp with time zone, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.init_call(IN who integer, IN ctime timestamp with time zone, IN duration integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
   cur_cust RECORD;
   cur_bal  RECORD;
   cur_tarr RECORD;
   cur_mins INTEGER;  
BEGIN
   -- Вставить новую запись в таблицу фактов
   INSERT INTO f(ks, dt, dur) VALUES (who, ctime, duration);
   
   -- Получаем данные о текущем пользователе
   SELECT * INTO cur_cust FROM s WHERE ks = who;
   SELECT * INTO cur_bal  FROM rest_balance WHERE ks = who;
   SELECT * INTO cur_tarr FROM t WHERE kt = cur_cust.kt;
   
   -- Рассчитываем новые показатели баланса
   IF duration <= cur_bal.minutes THEN 
      cur_bal.minutes = cur_bal.minutes - duration;
   ELSE 
      cur_mins = duration - cur_bal.minutes;
      cur_bal.minutes = 0;
      cur_bal.balance = 
         cur_bal.balance - cur_mins * cur_tarr.minfee;
   END IF;
   
   -- Корректируем таблицу остатков
   UPDATE rest_balance SET minutes = cur_bal.minutes, balance = cur_bal.balance
                       WHERE ks = who;
   
END;$$;


ALTER PROCEDURE public.init_call(IN who integer, IN ctime timestamp with time zone, IN duration integer) OWNER TO postgres;

--
-- TOC entry 4974 (class 0 OID 0)
-- Dependencies: 279
-- Name: PROCEDURE init_call(IN who integer, IN ctime timestamp with time zone, IN duration integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON PROCEDURE public.init_call(IN who integer, IN ctime timestamp with time zone, IN duration integer) IS 'Эта процедура должна выполнить следующие действия:
a) вставить новую запись в таблицу фактов <f>
b) скорректировать данные об остатке пакета минут и скорректировать баланс
';


--
-- TOC entry 280 (class 1255 OID 16402)
-- Name: logging_subscr(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logging_subscr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO tlog(einfo) VALUES (NEW.sfn || ' ' || NEW.sln);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.logging_subscr() OWNER TO postgres;

--
-- TOC entry 281 (class 1255 OID 16403)
-- Name: new_cust(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.new_cust() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.salary < 0 THEN
        RAISE EXCEPTION 'Negative salary: %', NEW.salary;
    ELSEIF NEW.salary < 100 THEN
        RAISE NOTICE 'Too small salary: %', NEW.salary;
        NEW.salary = 100;
    ELSEIF NEW.salary > 10000 THEN
        RAISE NOTICE 'Too big salary: %', NEW.salary;
        NEW.salary = 10000;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.new_cust() OWNER TO postgres;

--
-- TOC entry 4975 (class 0 OID 0)
-- Dependencies: 281
-- Name: FUNCTION new_cust(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.new_cust() IS 'Mistake if salary < 100 and salary > 10000';


--
-- TOC entry 282 (class 1255 OID 16404)
-- Name: salary_correction(numeric); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.salary_correction(IN snew numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    cur CURSOR FOR SELECT * FROM s;
    rr RECORD;
BEGIN
    -- Opening the cursor
    OPEN cur;
    
    -- Cycle of fetching
    LOOP
        FETCH cur INTO rr;
            EXIT WHEN NOT FOUND;
        IF rr.salary > 10000 THEN
            RAISE NOTICE 'Changing salary % of % to %', 
                          rr.salary, 
                          rr.sfn || ' ' || rr.sln, snew;
            UPDATE s SET salary = snew WHERE CURRENT OF cur;
        END IF;
    END LOOP;
END;
$$;


ALTER PROCEDURE public.salary_correction(IN snew numeric) OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 16405)
-- Name: simple_f_1(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.simple_f_1(x1 double precision, x2 double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF x1 < 0 THEN
        x1 = x1 * -1;
    END IF;
    RETURN x1 + x2;
END;
$$;


ALTER FUNCTION public.simple_f_1(x1 double precision, x2 double precision) OWNER TO postgres;

--
-- TOC entry 284 (class 1255 OID 16406)
-- Name: test001(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.test001(xx integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    ss INTEGER;
BEGIN
    IF xx >= 0 THEN
        ss = xx * 2;
    ELSE
        RAISE NOTICE 'Correction value: %', xx;
        ss = -xx;
    END IF;
    RETURN ss;
END;
$$;


ALTER FUNCTION public.test001(xx integer) OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 16407)
-- Name: tr_qa_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.tr_qa_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.salary < 1000 THEN
        RAISE EXCEPTION 'Bad salary value % of %',
                        NEW.salary, NEW.sln;
    END IF;
    RAISE NOTICE 'Insertion: Salary % of %',
                        NEW.salary, NEW.sln;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.tr_qa_insert() OWNER TO postgres;

--
-- TOC entry 286 (class 1255 OID 16408)
-- Name: view_creation(text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.view_creation(IN text)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    CREATE VIEW ss1 AS SELECT * FROM s WHERE sfn = $1;
END;
$_$;


ALTER PROCEDURE public.view_creation(IN text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 219 (class 1259 OID 16409)
-- Name: f; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.f (
    idcall integer NOT NULL,
    ks integer NOT NULL,
    dt timestamp(3) with time zone NOT NULL,
    dur integer
);


ALTER TABLE public.f OWNER TO postgres;

--
-- TOC entry 4976 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE f; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.f IS 'Facts of calling ';


--
-- TOC entry 220 (class 1259 OID 16412)
-- Name: s; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.s (
    ks integer NOT NULL,
    sfn character varying(255),
    sln character varying(255),
    kt integer,
    gender character(1),
    h integer,
    salary numeric(12,2)
);


ALTER TABLE public.s OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16434)
-- Name: t; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.t (
    kt integer NOT NULL,
    nt character varying(20),
    monthfee numeric(12,2),
    monthmins integer,
    minfee numeric(12,2)
);


ALTER TABLE public.t OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16521)
-- Name: call_analytics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.call_analytics AS
 SELECT f.idcall,
    f.dt AS call_date,
    f.dur AS call_duration,
    s.sfn AS first_name,
    s.sln AS last_name,
    t.nt AS tariff_name,
    t.monthfee,
    t.monthmins,
    t.minfee
   FROM ((public.f
     JOIN public.s ON ((f.ks = s.ks)))
     JOIN public.t ON ((s.kt = t.kt)));


ALTER VIEW public.call_analytics OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16538)
-- Name: call_data_cube; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.call_data_cube AS
SELECT
    NULL::integer AS subscriber_id,
    NULL::character varying(255) AS first_name,
    NULL::character varying(255) AS last_name,
    NULL::character(1) AS gender,
    NULL::numeric(12,2) AS salary,
    NULL::integer AS tariff_id,
    NULL::character varying(20) AS tariff_name,
    NULL::numeric(12,2) AS monthfee,
    NULL::integer AS monthmins,
    NULL::numeric(12,2) AS minfee,
    NULL::date AS call_date,
    NULL::bigint AS total_call_duration,
    NULL::bigint AS total_calls,
    NULL::numeric AS avg_call_duration;


ALTER VIEW public.call_data_cube OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16551)
-- Name: subscriber_spending_and_duration; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.subscriber_spending_and_duration AS
SELECT
    NULL::integer AS subscriber_id,
    NULL::character varying(255) AS first_name,
    NULL::character varying(255) AS last_name,
    NULL::integer AS tariff_id,
    NULL::character varying(20) AS tariff_name,
    NULL::numeric(12,2) AS monthfee,
    NULL::integer AS monthmins,
    NULL::numeric(12,2) AS minfee,
    NULL::bigint AS total_call_duration,
    NULL::bigint AS total_calls,
    NULL::numeric AS avg_call_duration,
    NULL::numeric AS total_spending;


ALTER VIEW public.subscriber_spending_and_duration OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16636)
-- Name: corr; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.corr AS
 SELECT corr((avg_call_duration)::double precision, (total_spending)::double precision) AS correlation_coefficient
   FROM public.subscriber_spending_and_duration;


ALTER VIEW public.corr OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 16632)
-- Name: cross_spend_dur; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.cross_spend_dur AS
 SELECT avg_call_duration,
    "Mini",
    "Average",
    "Maxi"
   FROM public.crosstab('SELECT avg_call_duration, tariff_name, total_spending
     FROM subscriber_spending_and_duration
     ORDER BY avg_call_duration, tariff_name'::text, 'SELECT ''Mini'' UNION SELECT ''Average'' UNION SELECT ''Maxi'''::text) ct(avg_call_duration numeric, "Mini" numeric, "Average" numeric, "Maxi" numeric);


ALTER VIEW public.cross_spend_dur OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16602)
-- Name: crosstab_data; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.crosstab_data AS
 SELECT s.ks AS subscriber_id,
    t.nt AS tariff_name,
    avg(f.dur) AS avg_call_duration
   FROM ((public.s
     JOIN public.t ON ((s.kt = t.kt)))
     JOIN public.f ON ((s.ks = f.ks)))
  GROUP BY s.ks, t.nt
  ORDER BY (avg(f.dur));


ALTER VIEW public.crosstab_data OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16616)
-- Name: crosstab_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.crosstab_view AS
 SELECT subscriber_id,
    "Maxi",
    "Average",
    "Mini",
    total_sum
   FROM public.crosstab('
    SELECT 
        COALESCE(t.subscriber_id::text, ''total_sum'') AS subscriber_id,
        COALESCE(t.tariff_name, ''total_sum'') AS tariff_name,
        AVG(t.avg_call_duration) AS avg_call_duration
    FROM public.crosstab_data t
    GROUP BY CUBE(t.subscriber_id, t.tariff_name)
    ORDER BY subscriber_id, tariff_name
    '::text, '
    (SELECT DISTINCT tt.tariff_name
     FROM public.crosstab_data tt
     ORDER BY tt.tariff_name)
     UNION ALL
     SELECT ''total_sum''
    '::text) ct(subscriber_id text, "Maxi" numeric, "Average" numeric, "Mini" numeric, total_sum numeric);


ALTER VIEW public.crosstab_view OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16428)
-- Name: f1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.f1 (
    k1 integer NOT NULL,
    t1 timestamp with time zone DEFAULT now(),
    n1 bigint
);


ALTER TABLE public.f1 OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16432)
-- Name: f1_k1_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.f1_k1_seq
    AS integer
    START WITH 1
    INCREMENT BY 1111
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.f1_k1_seq OWNER TO postgres;

--
-- TOC entry 4977 (class 0 OID 0)
-- Dependencies: 223
-- Name: f1_k1_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.f1_k1_seq OWNED BY public.f1.k1;


--
-- TOC entry 224 (class 1259 OID 16433)
-- Name: f_idcall_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.f_idcall_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.f_idcall_seq OWNER TO postgres;

--
-- TOC entry 4978 (class 0 OID 0)
-- Dependencies: 224
-- Name: f_idcall_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.f_idcall_seq OWNED BY public.f.idcall;


--
-- TOC entry 226 (class 1259 OID 16441)
-- Name: rest_balance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rest_balance (
    ks integer NOT NULL,
    minutes integer NOT NULL,
    balance numeric(12,2) NOT NULL
);


ALTER TABLE public.rest_balance OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16421)
-- Name: s_children; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.s_children (
    ks integer NOT NULL,
    nch integer
);


ALTER TABLE public.s_children OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16525)
-- Name: subscriber_analytics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.subscriber_analytics AS
 SELECT s.ks,
    s.sfn AS first_name,
    s.sln AS last_name,
    s.gender,
    s.h AS height,
    s.salary,
    t.nt AS tariff_name,
    t.monthfee,
    t.monthmins,
    t.minfee
   FROM (public.s
     JOIN public.t ON ((s.kt = t.kt)));


ALTER VIEW public.subscriber_analytics OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16529)
-- Name: sub_anaysis_Maxi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public."sub_anaysis_Maxi" AS
 SELECT ks,
    first_name,
    last_name,
    gender,
    height,
    salary,
    tariff_name,
    monthfee,
    monthmins,
    minfee
   FROM public.subscriber_analytics
  WHERE ((tariff_name)::text = 'Maxi'::text);


ALTER VIEW public."sub_anaysis_Maxi" OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16533)
-- Name: subscriber_analytics_view; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.subscriber_analytics_view AS
SELECT
    NULL::integer AS subscriber_id,
    NULL::character varying(255) AS first_name,
    NULL::character varying(255) AS last_name,
    NULL::character(1) AS gender,
    NULL::integer AS height,
    NULL::numeric(12,2) AS salary,
    NULL::integer AS tariff_id,
    NULL::character varying(20) AS tariff_name,
    NULL::numeric(12,2) AS monthfee,
    NULL::integer AS monthmins,
    NULL::numeric(12,2) AS minfee,
    NULL::integer AS number_of_children,
    NULL::integer AS remaining_minutes,
    NULL::numeric(12,2) AS current_balance,
    NULL::bigint AS total_call_duration,
    NULL::bigint AS total_calls;


ALTER VIEW public.subscriber_analytics_view OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16448)
-- Name: test_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.test_seq
    START WITH 1
    INCREMENT BY 10
    NO MINVALUE
    MAXVALUE 1000
    CACHE 1
    CYCLE;


ALTER SEQUENCE public.test_seq OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16449)
-- Name: tlog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tlog (
    idtlog bigint NOT NULL,
    etstmp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    euser text DEFAULT CURRENT_USER,
    einfo text
);


ALTER TABLE public.tlog OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16456)
-- Name: tlog_idtlog_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tlog_idtlog_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tlog_idtlog_seq OWNER TO postgres;

--
-- TOC entry 4979 (class 0 OID 0)
-- Dependencies: 229
-- Name: tlog_idtlog_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tlog_idtlog_seq OWNED BY public.tlog.idtlog;


--
-- TOC entry 230 (class 1259 OID 16457)
-- Name: ttt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ttt (
    eid character(5) NOT NULL,
    echild public.t_child
);


ALTER TABLE public.ttt OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 16547)
-- Name: variational_series_total_calls; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.variational_series_total_calls AS
 SELECT tariff_id,
    tariff_name,
    sum(total_calls) AS total_calls
   FROM public.call_data_cube
  GROUP BY tariff_id, tariff_name
  ORDER BY (sum(total_calls)) DESC;


ALTER VIEW public.variational_series_total_calls OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16543)
-- Name: variatonal_series_call_duration; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.variatonal_series_call_duration AS
 SELECT subscriber_id,
    first_name,
    last_name,
    sum(total_call_duration) AS total_call_duration
   FROM public.call_data_cube
  GROUP BY subscriber_id, first_name, last_name
  ORDER BY (sum(total_call_duration)) DESC;


ALTER VIEW public.variatonal_series_call_duration OWNER TO postgres;

--
-- TOC entry 4764 (class 2604 OID 16479)
-- Name: f idcall; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.f ALTER COLUMN idcall SET DEFAULT nextval('public.f_idcall_seq'::regclass);


--
-- TOC entry 4765 (class 2604 OID 16480)
-- Name: f1 k1; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.f1 ALTER COLUMN k1 SET DEFAULT nextval('public.f1_k1_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 16481)
-- Name: tlog idtlog; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tlog ALTER COLUMN idtlog SET DEFAULT nextval('public.tlog_idtlog_seq'::regclass);


--
-- TOC entry 4950 (class 0 OID 16409)
-- Dependencies: 219
-- Data for Name: f; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.f (idcall, ks, dt, dur) FROM stdin;
120001	1000	2018-01-08 10:00:00+03	10
120002	1000	2018-01-08 12:00:00+03	20
120004	1000	2018-01-09 10:00:00+03	40
120005	1000	2018-01-10 10:00:00+03	50
120006	1001	2018-01-01 10:00:00+03	20
120007	1001	2018-01-02 10:10:00+03	30
120008	1001	2018-01-03 10:00:00+03	2
120009	1001	2018-01-04 10:00:00+03	5
120011	1003	2018-01-03 10:00:00+03	10
120012	1003	2018-01-04 10:00:00+03	11
120013	1003	2018-01-05 10:00:00+03	15
120014	1004	2018-01-02 10:00:00+03	20
120015	1005	2018-01-08 11:00:00+03	3
120016	1006	2018-01-05 10:00:00+03	10
120017	1006	2018-01-06 10:00:00+03	10
120018	1007	2019-07-15 07:30:26.928+03	21
120022	1000	2021-03-22 18:30:30.218+03	13
120033	1001	2018-01-01 11:00:00+03	4
120003	1000	2018-01-08 14:00:00+03	41
120010	1002	2018-01-07 10:00:00+03	160
120024	1105	2021-10-28 15:39:58.367+03	45
120027	1002	2021-11-12 11:35:35.688+03	100
120028	1002	2021-11-12 11:36:02.278+03	100
120029	1002	2021-11-18 14:26:24.829+03	100
120030	1002	2021-11-18 14:26:58.825+03	100
120031	1005	2021-11-18 15:44:40.388+03	20
120032	1005	2021-11-18 15:45:19.303+03	50
120034	1000	2021-11-18 15:46:40.155+03	70
120035	1005	2021-11-18 15:46:59.869+03	50
120036	1000	2021-11-18 15:47:18.267+03	70
120037	1000	2021-11-18 15:47:33.55+03	20
\.


--
-- TOC entry 4953 (class 0 OID 16428)
-- Dependencies: 222
-- Data for Name: f1; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.f1 (k1, t1, n1) FROM stdin;
1000000	2024-11-23 09:55:16.921071+03	123
1	2024-11-23 09:56:26.951387+03	321
2	2024-11-23 09:56:40.388233+03	333
6	2024-11-23 09:58:17.869546+03	334
1117	2024-11-23 09:59:15.554957+03	335
2228	2024-11-23 09:59:22.878387+03	336
\.


--
-- TOC entry 4957 (class 0 OID 16441)
-- Dependencies: 226
-- Data for Name: rest_balance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rest_balance (ks, minutes, balance) FROM stdin;
1002	150	123.00
1003	150	123.00
1004	150	123.00
1006	0	123.00
1007	0	123.00
1001	300	123.00
1009	0	123.00
1008	150	123.00
1234	0	123.00
2222	0	123.00
1101	300	123.00
1105	300	123.00
1100	300	123.00
1005	0	-477.00
1000	0	93.00
\.


--
-- TOC entry 4951 (class 0 OID 16412)
-- Dependencies: 220
-- Data for Name: s; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.s (ks, sfn, sln, kt, gender, h, salary) FROM stdin;
1002	Ian	Holm	2	m	169	1200.00
1003	Milla	Jovovich	2	f	176	2100.00
1004	Chris	Tucker	2	m	190	900.00
1005	Luke	Perry	3	m	167	950.00
1006	Brion	James	3	m	200	1100.00
1007	Lee	Evans	3	m	178	500.00
1001	Gary	Oldman	1	m	167	2500.00
1000	Bruce	Willis	2	m	183	3000.00
1009	Donald	Trump	3	m	188	501.00
1008	Dmitrii	Nagiev	2	m	160	666.00
1234	Ivan	Ivanov	3	m	199	501.00
2222	Steven	King	3	m	193	9999.00
1101	Joseph	Biden	1	m	170	8899.00
1105	Dmitrii	Shaposhnikov	1	m	175	8899.00
1100	Grette	Tundberg	1	f	149	8899.00
2987	Alex	Linev	1	m	181	2987.77
3333	Petr	Petrov	3	m	170	1200.00
\.


--
-- TOC entry 4952 (class 0 OID 16421)
-- Dependencies: 221
-- Data for Name: s_children; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.s_children (ks, nch) FROM stdin;
1003	2
1000	5
1100	0
1105	1
\.


--
-- TOC entry 4956 (class 0 OID 16434)
-- Dependencies: 225
-- Data for Name: t; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.t (kt, nt, monthfee, monthmins, minfee) FROM stdin;
2	Average	200.00	150	3.00
4	Dummy	800.00	600	1.00
1	Maxi	400.00	300	1.00
3	Mini	0.00	0	5.00
\.


--
-- TOC entry 4959 (class 0 OID 16449)
-- Dependencies: 228
-- Data for Name: tlog; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tlog (idtlog, etstmp, euser, einfo) FROM stdin;
1	2021-07-27 14:06:26.399192+03	postgres	Test of logging!
2	2021-07-27 14:14:47.032163+03	postgres	Dmitrii Nagiev
7	2021-07-29 19:33:21.21365+03	postgres	Ivan Ivanov
\.


--
-- TOC entry 4961 (class 0 OID 16457)
-- Dependencies: 230
-- Data for Name: ttt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ttt (eid, echild) FROM stdin;
00001	('Robert',2010-12-10)
\.


--
-- TOC entry 4980 (class 0 OID 0)
-- Dependencies: 223
-- Name: f1_k1_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.f1_k1_seq', 2228, true);


--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 224
-- Name: f_idcall_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.f_idcall_seq', 120037, true);


--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 227
-- Name: test_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.test_seq', 81, true);


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 229
-- Name: tlog_idtlog_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tlog_idtlog_seq', 12, true);


--
-- TOC entry 4777 (class 2606 OID 16483)
-- Name: f1 f1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.f1
    ADD CONSTRAINT f1_pkey PRIMARY KEY (k1);


--
-- TOC entry 4781 (class 2606 OID 16485)
-- Name: rest_balance pk_balance; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rest_balance
    ADD CONSTRAINT pk_balance PRIMARY KEY (ks);


--
-- TOC entry 4771 (class 2606 OID 16487)
-- Name: f pk_f; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.f
    ADD CONSTRAINT pk_f PRIMARY KEY (idcall);


--
-- TOC entry 4773 (class 2606 OID 16489)
-- Name: s pk_ks; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.s
    ADD CONSTRAINT pk_ks PRIMARY KEY (ks);


--
-- TOC entry 4779 (class 2606 OID 16491)
-- Name: t pk_kt; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.t
    ADD CONSTRAINT pk_kt PRIMARY KEY (kt);


--
-- TOC entry 4775 (class 2606 OID 16493)
-- Name: s_children pks_ch; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.s_children
    ADD CONSTRAINT pks_ch PRIMARY KEY (ks);


--
-- TOC entry 4783 (class 2606 OID 16495)
-- Name: tlog tlog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tlog
    ADD CONSTRAINT tlog_pkey PRIMARY KEY (idtlog);


--
-- TOC entry 4785 (class 2606 OID 16497)
-- Name: ttt ttt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ttt
    ADD CONSTRAINT ttt_pkey PRIMARY KEY (eid);


--
-- TOC entry 4941 (class 2618 OID 16536)
-- Name: subscriber_analytics_view _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.subscriber_analytics_view AS
 SELECT s.ks AS subscriber_id,
    s.sfn AS first_name,
    s.sln AS last_name,
    s.gender,
    s.h AS height,
    s.salary,
    t.kt AS tariff_id,
    t.nt AS tariff_name,
    t.monthfee,
    t.monthmins,
    t.minfee,
    COALESCE(sc.nch, 0) AS number_of_children,
    rb.minutes AS remaining_minutes,
    rb.balance AS current_balance,
    COALESCE(sum(f.dur), (0)::bigint) AS total_call_duration,
    count(f.idcall) AS total_calls
   FROM ((((public.s
     JOIN public.t ON ((s.kt = t.kt)))
     LEFT JOIN public.s_children sc ON ((s.ks = sc.ks)))
     LEFT JOIN public.rest_balance rb ON ((s.ks = rb.ks)))
     LEFT JOIN public.f ON ((s.ks = f.ks)))
  GROUP BY s.ks, t.kt, sc.nch, rb.minutes, rb.balance;


--
-- TOC entry 4942 (class 2618 OID 16541)
-- Name: call_data_cube _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.call_data_cube AS
 SELECT s.ks AS subscriber_id,
    s.sfn AS first_name,
    s.sln AS last_name,
    s.gender,
    s.salary,
    t.kt AS tariff_id,
    t.nt AS tariff_name,
    t.monthfee,
    t.monthmins,
    t.minfee,
    (f.dt)::date AS call_date,
    sum(f.dur) AS total_call_duration,
    count(f.idcall) AS total_calls,
    avg(f.dur) AS avg_call_duration
   FROM ((public.s
     JOIN public.t ON ((s.kt = t.kt)))
     JOIN public.f ON ((s.ks = f.ks)))
  GROUP BY s.ks, t.kt, ((f.dt)::date);


--
-- TOC entry 4945 (class 2618 OID 16554)
-- Name: subscriber_spending_and_duration _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.subscriber_spending_and_duration AS
 SELECT s.ks AS subscriber_id,
    s.sfn AS first_name,
    s.sln AS last_name,
    t.kt AS tariff_id,
    t.nt AS tariff_name,
    t.monthfee,
    t.monthmins,
    t.minfee,
    sum(f.dur) AS total_call_duration,
    count(f.idcall) AS total_calls,
    avg(f.dur) AS avg_call_duration,
    sum(
        CASE
            WHEN (f.dur <= t.monthmins) THEN t.monthfee
            ELSE (t.monthfee + (t.minfee * ((f.dur - t.monthmins))::numeric))
        END) AS total_spending
   FROM ((public.s
     JOIN public.t ON ((s.kt = t.kt)))
     JOIN public.f ON ((s.ks = f.ks)))
  GROUP BY s.ks, t.kt;


--
-- TOC entry 4792 (class 2620 OID 16498)
-- Name: t hfukygkb; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER hfukygkb BEFORE INSERT OR UPDATE ON public.t FOR EACH ROW EXECUTE FUNCTION public.dev_tariff();


--
-- TOC entry 4790 (class 2620 OID 16499)
-- Name: s qwertyu; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER qwertyu BEFORE INSERT OR UPDATE ON public.s FOR EACH ROW EXECUTE FUNCTION public.new_cust();


--
-- TOC entry 4791 (class 2620 OID 16500)
-- Name: s tertergdfhfggs; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tertergdfhfggs BEFORE INSERT OR UPDATE ON public.s FOR EACH ROW EXECUTE FUNCTION public.tr_qa_insert();


--
-- TOC entry 4787 (class 2606 OID 16501)
-- Name: s ewqrewqtr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.s
    ADD CONSTRAINT ewqrewqtr FOREIGN KEY (kt) REFERENCES public.t(kt) ON UPDATE CASCADE ON DELETE RESTRICT NOT VALID;


--
-- TOC entry 4786 (class 2606 OID 16506)
-- Name: f fk_ks; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.f
    ADD CONSTRAINT fk_ks FOREIGN KEY (ks) REFERENCES public.s(ks) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4789 (class 2606 OID 16511)
-- Name: rest_balance fk_ks; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rest_balance
    ADD CONSTRAINT fk_ks FOREIGN KEY (ks) REFERENCES public.s(ks) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4788 (class 2606 OID 16516)
-- Name: s_children fk_s; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.s_children
    ADD CONSTRAINT fk_s FOREIGN KEY (ks) REFERENCES public.s(ks) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4967 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2024-12-24 04:39:31

--
-- PostgreSQL database dump complete
--

