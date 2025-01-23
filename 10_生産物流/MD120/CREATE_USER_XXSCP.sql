/****************************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 *
 * Script Name     : CREATE_USER_XXSCP
 * Description     : 生産計画スキーマ作成用
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2024/10/30    1.0   M.Sato           新規作成
 *  2024/11/26    1.1   M.Sato           XXIDXへの権限を追加
 ****************************************************************************************/
CREATE USER XXSCP IDENTIFIED BY XXSCP DEFAULT TABLESPACE XXDATA TEMPORARY TABLESPACE TEMP QUOTA unlimited on XXDATA QUOTA unlimited on XXIDX;
