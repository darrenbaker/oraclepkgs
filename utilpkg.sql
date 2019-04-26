-- don't forget to grant execute on sys.Utl_Smtp to the USER you want
--GRANT EXECUTE ON sys.Utl_Smtp TO {user};

DROP TABLE log_timer;
/

CREATE TABLE log_timer
(
  timer               VARCHAR2 (50)
 ,starttime           TIMESTAMP
 ,endtime             TIMESTAMP
 ,duration_seconds    VARCHAR2 (100)
 ,log_schema          VARCHAR2 (30)
 ,log_userid          VARCHAR2 (100)
 ,timer_notes         VARCHAR2 (250)
);
/

CREATE OR REPLACE PACKAGE utilpkg
IS
  /* General Functions/Procedures */
  FUNCTION get_userid
    RETURN VARCHAR2;

  FUNCTION get_dbenv
    RETURN VARCHAR2;

  FUNCTION get_schemaname
    RETURN VARCHAR2;

  /* Environment */
  FUNCTION is_db_production
    RETURN BOOLEAN;

  FUNCTION is_db_uat
    RETURN BOOLEAN;

  FUNCTION is_db_development
    RETURN BOOLEAN;

  FUNCTION is_db_xe
    RETURN BOOLEAN;

  PROCEDURE send_mail (i_sender      VARCHAR2
                      ,i_recipient   VARCHAR2
                      ,i_sub         VARCHAR2
                      ,i_message     VARCHAR2);

  /* Timer */
  PROCEDURE logtime (i_timer VARCHAR2
                    ,i_time_type VARCHAR2
                    ,i_notes VARCHAR2 := NULL);
END utilpkg;
/

CREATE OR REPLACE PACKAGE BODY utilpkg
IS
  FUNCTION get_userid
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN Sys_Context ('USERENV', 'OS_USER') || '@' || Sys_Context ('USERENV', 'HOST');
  END get_userid;

  FUNCTION get_dbenv
    RETURN VARCHAR2
  IS
    l_dbenv   VARCHAR2 (100);
  BEGIN
    BEGIN
      l_dbenv   := Sys_Context ('USERENV', 'DB_NAME');

      l_dbenv   :=
        CASE
          -- change these strings to suit your environment
          WHEN l_dbenv = 'PROD' THEN constpkg.db_production ()
          WHEN l_dbenv = 'UAT' THEN constpkg.db_uat ()
          WHEN l_dbenv = 'DEV' THEN constpkg.db_development ()
          WHEN l_dbenv = 'XE' THEN constpkg.db_xe ()
          ELSE 'Unknown Environment'
        END;
    END;

    RETURN l_dbenv;
  END get_dbenv;

  FUNCTION get_schemaname
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN Sys_Context ('USERENV', 'SESSION_USER');
  END get_schemaname;

  FUNCTION is_db_production
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN CASE WHEN get_dbenv () = constpkg.db_production () THEN TRUE ELSE FALSE END;
  END is_db_production;

  FUNCTION is_db_uat
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN CASE WHEN get_dbenv () = constpkg.db_uat () THEN TRUE ELSE FALSE END;
  END is_db_uat;

  FUNCTION is_db_development
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN CASE WHEN get_dbenv () = constpkg.db_development () THEN TRUE ELSE FALSE END;
  END is_db_development;

  FUNCTION is_db_xe
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN CASE WHEN get_dbenv () = constpkg.db_xe () THEN TRUE ELSE FALSE END;
  END is_db_xe;

  PROCEDURE send_mail (i_sender      VARCHAR2
                      ,i_recipient   VARCHAR2
                      ,i_sub         VARCHAR2
                      ,i_message     VARCHAR2)
  AS
    l_mail_body     VARCHAR2 (32767);
    l_mail_conn     Utl_Smtp.connection;
    l_crlf          VARCHAR2 (2) := Chr (13) || Chr (10);
    l_mail_server   VARCHAR2 (30) := 'localhost';
  BEGIN
    l_mail_conn   := Utl_Smtp.open_connection (l_mail_server, 25);
    Utl_Smtp.helo (l_mail_conn, l_mail_server);
    Utl_Smtp.mail (l_mail_conn, i_sender);
    Utl_Smtp.rcpt (l_mail_conn, i_recipient);
    l_mail_body   :=
         'Date: '
      || To_Char (Sysdate, 'dd Mon yy hh24:mi:ss')
      || l_crlf
      || 'From: '
      || i_sender
      || l_crlf
      || 'To: '
      || i_recipient
      || l_crlf
      || 'Subject: '
      || i_sub
      || l_crlf;
    l_mail_body   := l_mail_body || '' || l_crlf || i_message;
    Utl_Smtp.data (l_mail_conn, l_mail_body);
    Utl_Smtp.quit (l_mail_conn);
  EXCEPTION
    WHEN OTHERS THEN
      errpkg.log_db_error ('send_mail', 'Failed to send email to: ' || i_recipient || ' from: ' || i_sender || '. ' || Sqlerrm);
  END send_mail;

  PROCEDURE logtime (i_timer VARCHAR2, i_time_type VARCHAR2, i_notes VARCHAR2:= NULL)
  IS
    l_sysdate   DATE;
  BEGIN
    l_sysdate   := Systimestamp;

    CASE
      WHEN i_time_type = constpkg.timer_start () THEN
        BEGIN
          INSERT INTO log_timer (timer
                                ,starttime
                                ,log_schema
                                ,log_userid
                                ,timer_notes)
               VALUES (Substr (i_timer, 1, 50)
                      ,l_sysdate
                      ,get_schemaname ()
                      ,get_userid ()
                      ,Substr (i_notes, 1, 250));
        EXCEPTION
          WHEN OTHERS THEN
            errpkg.log_db_error ('logtime', 'Update of STARTTIME failed.');
        END;
      WHEN i_time_type = constpkg.timer_stop () THEN
        BEGIN
          UPDATE log_timer
             SET endtime = l_sysdate, duration_seconds = Regexp_Substr (l_sysdate - starttime, '([1-9][0-9:]*|0)\.\d{3}')
           WHERE timer = i_timer AND endtime IS NULL;
        EXCEPTION
          WHEN OTHERS THEN
            errpkg.log_db_error ('logtime', 'Update of ENDTIME failed.');
        END;
    END CASE;
    
    EXCEPTION
      WHEN OTHERS THEN
        errpkg.log_db_error ('logtime', 'Failed to log the time for timer: ' || Substr (i_timer, 1, 50) || '. ' || Sqlerrm);
  END logtime;
END utilpkg;
/