CREATE OR REPLACE PACKAGE XXCFO006A01P1
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name    : XXCFO006A01P1(spec)
 * Description     : APWIセキュリティ
 * MD.050          : MD050_CFO_006_A01_APWIセキュリティ
 * MD.070          : MD050_CFO_006_A01_APWIセキュリティ
 * Version         : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_policy_condition      F    VAR    WHERE句（所属部門権限判定によるセキュリティ設定）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-05   1.0    SCS 嵐田 勇人    初回作成
 *
 *****************************************************************************************/
--
  --
  --APWIセキュリティ
  FUNCTION get_policy_condition(
    p1 IN VARCHAR2            -- 1.DammyParameter for Fine-Grain-Access-Control
   ,p2 IN VARCHAR2)           -- 2.DammyParameter for Fine-Grain-Access-Control
  RETURN VARCHAR2;            -- WHERE句（所属部門権限判定によるセキュリティ設定）
  --
--
END XXCFO006A01P1;
/
