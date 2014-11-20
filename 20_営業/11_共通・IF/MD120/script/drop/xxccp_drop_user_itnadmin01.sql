/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_DROP_USER_ITNADMIN01
 * Description     : パッチ担当用ユーザー削除スクリプト
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *
 ****************************************************************************************/
DROP SYNONYM itnadmin01.FND_GLOBAL
/
DROP SYNONYM itnadmin01.FND_APPLICATION
/
DROP SYNONYM itnadmin01.FND_CACHE_VERSIONS
/
DROP SYNONYM itnadmin01.FND_PROFILE_OPTIONS
/
DROP SYNONYM itnadmin01.FND_PROFILE_OPTION_VALUES
/
DROP SYNONYM itnadmin01.FND_RESPONSIBILITY_VL
/
DROP SYNONYM itnadmin01.FND_USER
/
DROP USER itnadmin01
/
