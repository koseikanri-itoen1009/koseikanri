REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

SET VERIFY OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE JTF_PF_CONV_PKG AS
/* $Header: jtfpfconvpkgs.pls 115.15 2004/12/17 20:09:01 sywong noship $ */
/*===========================================================================+
 |               Copyright (c) 2002 Oracle Corporation                       |
 |                  Redwood Shores, California, USA                          |
 |                       All rights reserved.                                |
 +===========================================================================+
 |   File name                                                               |
 |             jtfpfconvpkgs.pls			                     |
 |                                                                           |
 |   Description                                                             |
 |                                                                           |
 |     This file contains the pakage specifications for the                  |
 |     JTF_PF_CONV_PKG , which is the PLSQL interface for the                |
 |     jsp (activity) logging project                                        |
 |                                                                           |
 |     Modification History:                                                 |
 |    05-Feb-2004     Modified  navkumar                                     |
 |                       split migrate_data to _stats and _raw for           |
 |                       troubleshooting                                     |
 |    14-Apr-2002     Modified  navkumar                                     |
 |                       added a suite of PL/SQL functions and procedures    |
 |    11-Apr-2002     Created   bsanghav                                     |
 |___________________________________________________________________________|*/
  qname         VARCHAR2(2000) := 'JTF_PF_LOGGING_QUEUE';
  qtablename    varchar2(2000) := 'JTF_PF_LOGGING_TABLE'; 

  -- For Concurrent Manager
  PROCEDURE synchronize_pageflow_data(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER);

  PROCEDURE writePFObject(obj JTF_PF_PAGE_OBJECT,write_to_jtf INTEGER,tech_stack VARCHAR2, dbdate out DATE);
  PROCEDURE migrate_data(timezone_offset IN NUMBER);
  PROCEDURE migrate_data_stats(today DATE);
  PROCEDURE migrate_data_raw;
  PROCEDURE clean_data(start_date DATE);
  PROCEDURE purge_data(start_date DATE);
  PROCEDURE purge_data(ERRBUF OUT VARCHAR2, RETCODE OUT NUMBER , start_date IN DATE);
  PROCEDURE multiply_data(days NUMBER);

  -- PROCEDURE uploadAllNewPfObjects(qname VARCHAR2);
  PROCEDURE uploadAllNewPfObjects;

  FUNCTION GetParams (paramNames JTF_VARCHAR2_TABLE_300, paramValues JTF_VARCHAR2_TABLE_4000, paramSz INTEGER)
  RETURN JTF_PF_PARAMS_TABLE;

  FUNCTION GetParamString(params JTF_PF_PARAMS_TABLE)
  return CLOB;
  FUNCTION GetCookieString(params JTF_PF_COOKIES_TABLE)
  return CLOB;

  FUNCTION GetParamNVs(po_id INTEGER)
  RETURN JTF_VARCHAR2_TABLE_4000;

  FUNCTION GetParamNames (params JTF_PF_PARAMS_TABLE, paramSz INTEGER)
  RETURN JTF_VARCHAR2_TABLE_300;

  FUNCTION GetParamValues (params JTF_PF_PARAMS_TABLE, paramSz INTEGER)
  RETURN JTF_VARCHAR2_TABLE_4000;
 
  FUNCTION GetCookies (cookieNames JTF_VARCHAR2_TABLE_300, cookieValues JTF_VARCHAR2_TABLE_4000,
                cookieSizes JTF_NUMBER_TABLE, cookieSz INTEGER)
  RETURN JTF_PF_COOKIES_TABLE;
  
  FUNCTION GROUP_CONCAT(list IN JTF_PF_TABLETYPE, separator VARCHAR2)
  RETURN VARCHAR2;

END JTF_PF_CONV_PKG;
/
COMMIT;
EXIT;
