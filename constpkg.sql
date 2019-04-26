CREATE OR REPLACE PACKAGE constpkg
IS
  /* Environment */
  FUNCTION db_production
    RETURN VARCHAR2;

  FUNCTION db_uat
    RETURN VARCHAR2;

  FUNCTION db_development
    RETURN VARCHAR2;

  FUNCTION db_xe
    RETURN VARCHAR2;

  /* Timer Start/Stop */
  FUNCTION timer_start
    RETURN VARCHAR2;

  FUNCTION timer_stop
    RETURN VARCHAR2;
END constpkg;
/

CREATE OR REPLACE PACKAGE BODY constpkg
IS
  /* Environment */
  c_db_production    CONSTANT VARCHAR2 (15) := 'Production';
  c_db_uat           CONSTANT VARCHAR2 (15) := 'UAT';
  c_db_development   CONSTANT VARCHAR2 (15) := 'Development';
  c_db_xe            CONSTANT VARCHAR2 (15) := 'Oracle XE';

  /* Timer Start/Stop */
  c_timer_start      CONSTANT VARCHAR2 (5) := 'START';
  c_timer_stop       CONSTANT VARCHAR2 (5) := 'STOP';

  FUNCTION db_production
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN c_db_production;
  END db_production;

  FUNCTION db_uat
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN c_db_uat;
  END db_uat;

  FUNCTION db_development
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN c_db_development;
  END db_development;

  FUNCTION db_xe
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN c_db_xe;
  END db_xe;

  FUNCTION timer_start
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN c_timer_start;
  END timer_start;

  FUNCTION timer_stop
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN c_timer_stop;
  END timer_stop;
END constpkg;
/