CREATE OR REPLACE PACKAGE APPS.xxcso_010001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010001j_pkg(SPEC)
 * Description      : 権限判定関数(XXCSOユーティリティ）
 * MD.050/070       : 
 * Version          : 1.2
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  get_authority               F    V     権限判定関数
 *  chk_latest_contract         F    V     最新契約書チェック関数
 *  chk_cancel_contract         F    V     契約書取消チェック関数
 *  chk_cooperate_wait          F    V     マスタ連携待ちチェック関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/13    1.0   R.Oikawa        新規作成
 *  2009-05-01    1.1   Tomoko.Mori     T1_0897対応
 *  2010/02/10    1.2   D.Abe           E_本稼動_01538対応
 *
 *****************************************************************************************/
--
   -- 権限判定関数
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER           -- SP専決ヘッダID
  )
  RETURN VARCHAR2;
/* 2010.02.10 D.Abe E_本稼動_01538対応 START */
--
   -- 最新契約書チェック関数
  FUNCTION chk_latest_contract(
    iv_contract_number            IN  VARCHAR2         -- 契約書番号
   ,iv_account_number             IN  VARCHAR2         -- 顧客コード
  )
  RETURN VARCHAR2;
--
   -- 契約書取消チェック関数
  FUNCTION chk_cancel_contract(
    iv_contract_number            IN  VARCHAR2         -- 契約書番号
   ,iv_account_number             IN  VARCHAR2         -- 顧客コード
  )
  RETURN VARCHAR2;
--
  -- マスタ連携待ちチェック関数
  FUNCTION chk_cooperate_wait(
    iv_contract_number            IN  VARCHAR2         -- 契約書番号
  ) RETURN VARCHAR2;
/* 2010.02.10 D.Abe E_本稼動_01538対応 END */
--
END xxcso_010001j_pkg;
/
