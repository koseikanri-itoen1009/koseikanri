/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS06
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
CREATE USER   scs06
IDENTIFIED BY scs06
DEFAULT TABLESPACE XXDATA2
TEMPORARY TABLESPACE TEMP
/
GRANT CREATE SESSION TO        scs06
/
GRANT SELECT ANY TABLE TO      scs06
/
GRANT EXECUTE ANY PROCEDURE TO scs06
/
GRANT SELECT ANY DICTIONARY TO scs06
/
-- 2010/12/28 Ver.1.1 [E_本稼動_06035] SCS S.Niki ADD START
GRANT SELECT ANY SEQUENCE TO   scs06
/
-- 2010/12/28 Ver.1.1 [E_本稼動_06035] SCS S.Niki ADD END
CREATE SYNONYM scs06.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM scs06.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM scs06.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM scs06.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM scs06.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM scs06.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM scs06.FND_USER FOR APPS.FND_USER
/
