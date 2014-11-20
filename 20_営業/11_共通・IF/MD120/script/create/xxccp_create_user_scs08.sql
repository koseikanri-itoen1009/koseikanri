/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_CREATE_USER_SCS08
 * Description     : �Q�ƃ��[�U�[�쐬�X�N���v�g
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          �V�K�쐬
 *  2010/12/28    1.1    S.Niki          E_�{�ғ�_06035 �V�[�P���X��SELECT������t�^
 *
 ****************************************************************************************/
CREATE USER   scs08
IDENTIFIED BY scs08
DEFAULT TABLESPACE XXDATA2
TEMPORARY TABLESPACE TEMP
/
GRANT CREATE SESSION TO        scs08
/
GRANT SELECT ANY TABLE TO      scs08
/
GRANT EXECUTE ANY PROCEDURE TO scs08
/
GRANT SELECT ANY DICTIONARY TO scs08
/
-- 2010/12/28 Ver.1.1 [E_�{�ғ�_06035] SCS S.Niki ADD START
GRANT SELECT ANY SEQUENCE TO   scs08
/
-- 2010/12/28 Ver.1.1 [E_�{�ғ�_06035] SCS S.Niki ADD END
CREATE SYNONYM scs08.FND_GLOBAL FOR APPS.FND_GLOBAL
/
CREATE SYNONYM scs08.FND_APPLICATION FOR APPS.FND_APPLICATION
/
CREATE SYNONYM scs08.FND_CACHE_VERSIONS FOR APPS.FND_CACHE_VERSIONS
/
CREATE SYNONYM scs08.FND_PROFILE_OPTIONS FOR APPS.FND_PROFILE_OPTIONS
/
CREATE SYNONYM scs08.FND_PROFILE_OPTION_VALUES FOR APPS.FND_PROFILE_OPTION_VALUES
/
CREATE SYNONYM scs08.FND_RESPONSIBILITY_VL FOR APPS.FND_RESPONSIBILITY_VL
/
CREATE SYNONYM scs08.FND_USER FOR APPS.FND_USER
/
