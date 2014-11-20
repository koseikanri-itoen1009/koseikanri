/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS07
 * Description     : 参照ユーザー作成スクリプト
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *  2010/12/28    1.1    S.Niki          E_本稼動_06035 シーケンスのSELECT権限を付与
 *
 ****************************************************************************************/
CREATE USER   scs07
IDENTIFIED BY scs07
DEFAULT TABLESPACE XXDATA2
TEMPORARY TABLESPACE TEMP
/
GRANT CREATE SESSION TO        scs07
/
GRANT SELECT ANY TABLE TO      scs07
/
GRANT EXECUTE ANY PROCEDURE TO scs07
/
GRANT SELECT ANY DICTIONARY TO scs07
/
-- 2010/12/28 Ver.1.1 [E_本稼動_06035] SCS S.Niki ADD START
GRANT SELECT ANY SEQUENCE TO   scs07
/
-- 2010/12/28 Ver.1.1 [E_本稼動_06035] SCS S.Niki ADD END
CREATE SYNONYM scs07.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM scs07.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM scs07.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM scs07.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM scs07.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM scs07.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM scs07.FND_USER FOR APPS.FND_USER
/
