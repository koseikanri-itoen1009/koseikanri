/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_AUDIT_ITNADMIN01
 * Description     : パッチ担当用ユーザー監査設定スクリプト
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *
 ****************************************************************************************/
AUDIT TABLE BY itnadmin01 BY ACCESS
/
AUDIT DELETE TABLE BY itnadmin01 BY ACCESS
/
AUDIT INSERT TABLE BY itnadmin01 BY ACCESS
/
AUDIT UPDATE TABLE BY itnadmin01 BY ACCESS
/
