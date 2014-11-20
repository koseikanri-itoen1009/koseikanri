/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS02
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
CREATE USER   scs02
IDENTIFIED BY scs02
DEFAULT TABLESPACE XXDATA2
TEMPORARY TABLESPACE TEMP
/
GRANT CREATE SESSION TO        scs02
/
GRANT SELECT ANY TABLE TO      scs02
/
GRANT EXECUTE ANY PROCEDURE TO scs02
/
GRANT SELECT ANY DICTIONARY TO scs02
/
CREATE SYNONYM scs02.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM scs02.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM scs02.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM scs02.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM scs02.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM scs02.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM scs02.FND_USER FOR APPS.FND_USER
/
