/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_NOAUDIT_ITNADMIN01
 * Description     : パッチ担当用ユーザー監査解除スクリプト
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *
 ****************************************************************************************/
NOAUDIT TABLE BY itnadmin01
/
NOAUDIT DELETE TABLE BY itnadmin01
/
NOAUDIT INSERT TABLE BY itnadmin01
/
NOAUDIT UPDATE TABLE BY itnadmin01
/
