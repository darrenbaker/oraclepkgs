DROP TABLE db_error_log;
/

CREATE TABLE db_error_log
(
  err_function    VARCHAR2 (30)
 ,err_message     VARCHAR2 (4000)
 ,call_stack      VARCHAR2 (4000)
 ,back_trace      VARCHAR2 (4000)
 ,schemaname      VARCHAR2 (30)
 ,date_created    DATE
 ,user_created    VARCHAR2 (100)
);
/

CREATE OR REPLACE PACKAGE errpkg
IS
  -- errpkg raises this exception if the user requests an abort.
  e_abort_failure    EXCEPTION;

  en_abort_failure   PLS_INTEGER := -20999;
  PRAGMA EXCEPTION_INIT (e_abort_failure, -20999);

  PROCEDURE log_db_error (i_err_function   IN db_error_log.err_function%TYPE
                         ,i_err_message    IN db_error_log.err_message%TYPE := NULL
                         ,i_abort          IN BOOLEAN := FALSE);
END errpkg;
/

CREATE OR REPLACE PACKAGE BODY errpkg
IS
  PROCEDURE log_db_error (i_err_function   IN db_error_log.err_function%TYPE
                         ,i_err_message    IN db_error_log.err_message%TYPE := NULL
                         ,i_abort          IN BOOLEAN := FALSE)
  IS
    PROCEDURE insert_row
    IS
      PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
      INSERT INTO db_error_log (err_function
                               ,err_message
                               ,call_stack
                               ,back_trace
                               ,schemaname
                               ,date_created
                               ,user_created)
           VALUES (i_err_function
                  ,Substr (Nvl (i_err_message, Dbms_Utility.format_error_stack), 1, 4000)
                  ,Substr (Dbms_Utility.format_call_stack, 1, 4000)
                  ,Substr (Dbms_Utility.format_error_backtrace, 1, 4000)
                  ,utilpkg.get_schemaname
                  ,Sysdate
                  ,utilpkg.get_userid);

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        -- Must rollback on exit from autonomous transaction.
        -- Display generic message to indicate problem.
        ROLLBACK;
        Dbms_Output.put_line ('Unable to write to error log!');
        Dbms_Output.put_line ('Error:');
        Dbms_Output.put_line (Dbms_Utility.format_error_stack);
    END insert_row;
  BEGIN
    insert_row;

    IF i_abort THEN
      raise_application_error (en_abort_failure, 'Abort exception invoked by developer!');
    END IF;
  END log_db_error;
END errpkg;
/