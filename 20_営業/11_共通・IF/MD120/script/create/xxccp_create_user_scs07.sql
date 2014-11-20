/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS07
 * Description     : �Q�ƃ��[�U�[�쐬�X�N���v�g
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          �V�K�쐬
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
