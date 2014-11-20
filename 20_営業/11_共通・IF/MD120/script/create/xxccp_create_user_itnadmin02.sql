/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_ITNADMIN02
 * Description     : �p�b�`�S���p���[�U�[�쐬�X�N���v�g
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          �V�K�쐬
 *
 ****************************************************************************************/
CREATE USER    itnadmin02
IDENTIFIED BY  itnadmin02
DEFAULT TABLESPACE XXDATA2 
TEMPORARY TABLESPACE TEMP 
/

GRANT CREATE SESSION TO        itnadmin02
/
GRANT SELECT ANY TABLE TO      itnadmin02
/
GRANT EXECUTE ANY PROCEDURE TO itnadmin02
/
GRANT SELECT ANY DICTIONARY TO itnadmin02
/
GRANT UPDATE ANY TABLE TO      itnadmin02
/
GRANT DELETE ANY TABLE TO      itnadmin02
/
GRANT INSERT ANY TABLE TO      itnadmin02
/
GRANT DROP ANY TABLE TO        itnadmin02
/
CREATE SYNONYM itnadmin02.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM itnadmin02.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM itnadmin02.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM itnadmin02.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM itnadmin02.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM itnadmin02.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM itnadmin02.FND_USER FOR APPS.FND_USER
/
