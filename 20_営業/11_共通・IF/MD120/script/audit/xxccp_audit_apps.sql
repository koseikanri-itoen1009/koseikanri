/****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Script Name     : XXCCP_AUDIT_APPS
 * Description     : APPSユーザー監査設定スクリプト
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/24    1.0    S.Niki          新規作成
 *
 ****************************************************************************************/
AUDIT DIRECTORY BY apps BY ACCESS
/
AUDIT INDEX BY apps BY ACCESS
/
AUDIT MATERIALIZED VIEW BY apps BY ACCESS
/
AUDIT PROCEDURE BY apps BY ACCESS
/
AUDIT PUBLIC SYNONYM BY apps BY ACCESS
/
AUDIT SEQUENCE BY apps BY ACCESS
/
AUDIT SYNONYM BY apps BY ACCESS
/
AUDIT TABLE BY apps BY ACCESS
/
AUDIT TRIGGER BY apps BY ACCESS
/
AUDIT TYPE BY apps BY ACCESS
/
AUDIT VIEW BY apps BY ACCESS
/
AUDIT ALTER SEQUENCE BY apps BY ACCESS
/
AUDIT ALTER TABLE BY apps BY ACCESS
/