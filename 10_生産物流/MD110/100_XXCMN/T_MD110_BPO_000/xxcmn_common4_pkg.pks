CREATE OR REPLACE PACKAGE xxcmn_common4_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2012. All rights reserved.
 *
 * Package Name           : xxcmn_common4_pkg(spec)
 * Description            : 共通関数4
 * MD.070(CMD.050)        : T_MD050_BPO_000_共通関数4.xls
 * Version                : 1.0
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  get_syori_date         F  DATE  処理日付取得
 *  get_purge_period       F  NUM   バックアップ期間/パージ期間取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2012/10/18   1.00  SCSK 宮本直樹    新規作成
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
  -- ===============================
--
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- 処理日付取得
  FUNCTION get_syori_date RETURN DATE;
--

  -- バックアップ期間/パージ期間取得関数
  FUNCTION get_purge_period (
    iv_purge_type IN VARCHAR2,    --PURGE_TYPE(0:パージ処理期間 1:バックアップ処理期間)
    iv_purge_code IN VARCHAR2)    --PURGE_CODE
    RETURN NUMBER;
--
--
END xxcmn_common4_pkg;
/
