/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_DROP_USER_SCS10
 * Description     : 参照ユーザー削除スクリプト
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *
 ****************************************************************************************/
DROP SYNONYM scs10.FND_GLOBAL
/
DROP SYNONYM scs10.FND_APPLICATION
/
DROP SYNONYM scs10.FND_CACHE_VERSIONS
/
DROP SYNONYM scs10.FND_PROFILE_OPTIONS
/
DROP SYNONYM scs10.FND_PROFILE_OPTION_VALUES
/
DROP SYNONYM scs10.FND_RESPONSIBILITY_VL
/
DROP SYNONYM scs10.FND_USER
/
DROP USER scs10
/
