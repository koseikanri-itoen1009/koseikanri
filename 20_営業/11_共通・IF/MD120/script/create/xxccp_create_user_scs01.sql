/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS01
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
CREATE USER   scs01
IDENTIFIED BY scs01
DEFAULT TABLESPACE XXDATA2
TEMPORARY TABLESPACE TEMP
/
GRANT CREATE SESSION TO        scs01
/
GRANT SELECT ANY TABLE TO      scs01
/
GRANT EXECUTE ANY PROCEDURE TO scs01
/
GRANT SELECT ANY DICTIONARY TO scs01
/
CREATE SYNONYM scs01.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM scs01.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM scs01.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM scs01.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM scs01.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM scs01.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM scs01.FND_USER FOR APPS.FND_USER
/
