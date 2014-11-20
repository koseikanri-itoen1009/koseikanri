/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS10
 * Description     : 参照ユーザー作成スクリプト
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *
 ****************************************************************************************/
CREATE USER   scs10
IDENTIFIED BY scs10
DEFAULT TABLESPACE XXDATA2
TEMPORARY TABLESPACE TEMP
/
GRANT CREATE SESSION TO        scs10
/
GRANT SELECT ANY TABLE TO      scs10
/
GRANT EXECUTE ANY PROCEDURE TO scs10
/
GRANT SELECT ANY DICTIONARY TO scs10
/
CREATE SYNONYM scs10.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM scs10.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM scs10.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM scs10.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM scs10.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM scs10.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM scs10.FND_USER FOR APPS.FND_USER
/
