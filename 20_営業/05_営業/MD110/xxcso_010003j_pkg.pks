CREATE OR REPLACE PACKAGE APPS.xxcso_010003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010003j_pkg(BODY)
 * Description      : 自動販売機設置契約情報登録更新_共通関数
 * MD.050/070       : 
 * Version          : 1.6
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  decode_bm_info            F    V      検索基準拠点コード取得関数
 *  get_base_leader_name      F    V      発行元所属長取得
 *  get_base_leader_pos_name  F    V      発行元所属長職位名取得
 *  chk_double_byte_kana      F    V      全角カナチェック（共通関数ラッピング）
 *  chk_tel_format            F    V      電話番号チェック（共通関数ラッピング）
 *  chk_duplicate_vendor_name F    V      送付先名重複チェック
 *  get_authority             F    V      権限判定関数
 *  chk_bfa_single_byte_kana  F    V      半角カナチェック（BFA関数ラッピング）
 *  decode_cont_manage_info   F    V      契約管理情報分岐取得
 *  get_sales_charge          F    V      販売手数料発生可否判別
 *  chk_double_byte           F    V      全角文字チェック（共通関数ラッピング）
 *  chk_single_byte_kana      F    V      半角カナチェック（共通関数ラッピング）
 *  chk_cooperate_wait        F    V      マスタ連携待ちチェック
 *  reflect_contract_status   P    -      契約書確定情報反映処理
 *  chk_validate_db           P    -      ＤＢ更新判定チェック
 *  chk_cash_payment          F    V      現金支払チェック
 *  chk_install_code          F    V      物件コードチェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/27    1.0   H.Ogawa          新規作成
 *  2009/02/16    1.0   N.Yanagitaira    [UT後修正]chk_bfa_single_byte_kana追加
 *  2009/02/17    1.1   N.Yanagitaira    [CT1-012]decode_cont_manage_info追加
 *  2009/02/23    1.1   N.Yanagitaira    [内部障害-028]全角カナチェック処理不正修正
 *  2009/03/12    1.1   N.Yanagitaira    [CT2-058]get_sales_charge追加
 *  2009/04/08    1.2   N.Yanagitaira    [ST障害T1_0364]chk_duplicate_vendor_name修正
 *  2009/04/27    1.3   N.Yanagitaira    [ST障害T1_0708]入力項目チェック処理統一修正
 *                                                      chk_double_byte
 *                                                      chk_single_byte_kana
 *  2009-05-01    1.4   Tomoko.Mori      T1_0897対応
 *  2010/02/10    1.5   D.Abe            E_本稼動_01538対応
 *  2010/03/01    1.6   D.Abe            E_本稼動_01678,E_本稼動_01868対応
 *****************************************************************************************/
--
  -- BM情報分岐取得
  FUNCTION decode_bm_info(
    in_customer_id              NUMBER
   ,iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 発行元所属長取得
  FUNCTION get_base_leader_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 発行元所属長職位名取得
  FUNCTION get_base_leader_pos_name(
    iv_base_code                VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 全角カナチェック（共通関数ラッピング）
  FUNCTION chk_double_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 電話番号チェック（共通関数ラッピング）
  FUNCTION chk_tel_format(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 送付先名重複チェック
-- 20090408_N.Yanagitaira T1_0364 Mod START
--  FUNCTION chk_duplicate_vendor_name(
--    iv_dm1_vendor_name             IN  VARCHAR2
--   ,iv_dm2_vendor_name             IN  VARCHAR2
--   ,iv_dm3_vendor_name             IN  VARCHAR2
--   ,in_contract_management_id      IN  NUMBER
--   ,in_dm1_supplier_id             IN  NUMBER
--   ,in_dm2_supplier_id             IN  NUMBER
--   ,in_dm3_supplier_id             IN  NUMBER
--  ) RETURN VARCHAR2;
  PROCEDURE chk_duplicate_vendor_name(
    iv_bm1_vendor_name             IN  VARCHAR2
   ,iv_bm2_vendor_name             IN  VARCHAR2
   ,iv_bm3_vendor_name             IN  VARCHAR2
   ,in_bm1_supplier_id             IN  NUMBER
   ,in_bm2_supplier_id             IN  NUMBER
   ,in_bm3_supplier_id             IN  NUMBER
   ,iv_operation_mode              IN  VARCHAR2
   ,on_bm1_dup_count               OUT NUMBER
   ,on_bm2_dup_count               OUT NUMBER
   ,on_bm3_dup_count               OUT NUMBER
   ,ov_bm1_contract_number         OUT VARCHAR2
   ,ov_bm2_contract_number         OUT VARCHAR2
   ,ov_bm3_contract_number         OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
-- 20090408_N.Yanagitaira T1_0364 Mod END
--
   -- 権限判定関数
  FUNCTION get_authority(
    iv_sp_decision_header_id      IN  NUMBER
  )
  RETURN VARCHAR2;
--
  -- 半角カナチェック（BFA関数ラッピング）
  FUNCTION chk_bfa_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 契約管理分岐取得
  FUNCTION decode_cont_manage_info(
    iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 販売手数料発生可否判別
  FUNCTION get_sales_charge(
    in_sp_decision_header_id    NUMBER
  ) RETURN VARCHAR2;
--
-- 20090427_N.Yanagitaira T1_0708 Add START
  -- 全角文字チェック（共通関数ラッピング）
  FUNCTION chk_double_byte(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 半角カナ文字チェック（共通関数ラッピング）
  FUNCTION chk_single_byte_kana(
    iv_value                       IN  VARCHAR2
  ) RETURN VARCHAR2;
-- 20090427_N.Yanagitaira T1_0708 Add END
--
/* 2010.02.10 D.Abe E_本稼動_01538対応 START */
  -- マスタ連携待ちチェック
  FUNCTION chk_cooperate_wait(
    iv_account_number             IN  VARCHAR2         -- 顧客コード
  ) RETURN VARCHAR2;
--
  -- 契約書確定情報反映処理
  PROCEDURE reflect_contract_status(
    iv_contract_management_id     IN  VARCHAR2         -- 契約書ID
   ,iv_account_number             IN  VARCHAR2         -- 顧客コード
   ,iv_status                     IN  VARCHAR2         -- ステータス
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  );
--
  -- ＤＢ更新判定チェック
  PROCEDURE chk_validate_db(
    iv_contract_number            IN  VARCHAR2         -- 契約書番号
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  );
--
/* 2010.02.10 D.Abe E_本稼動_01538対応 END */
/* 2010.03.01 D.Abe E_本稼動_01678対応 START */
  -- 現金支払チェック
  FUNCTION chk_payment_type_cash(
     in_sp_decision_header_id     IN  NUMBER           -- SP専決ヘッダID
    ,in_supplier_id               IN  NUMBER           -- 送付先ID
    ,iv_delivery_div              IN  VARCHAR2         -- 送付区分
  ) RETURN VARCHAR2;
--
/* 2010.03.01 D.Abe E_本稼動_01678対応 END */
/* 2010.03.01 D.Abe E_本稼動_01868対応 START */
  -- 物件コードチェック
  FUNCTION chk_install_code(
     iv_install_code              IN  VARCHAR2         -- 物件コード
  ) RETURN VARCHAR2;
--
/* 2010.03.01 D.Abe E_本稼動_01868対応 END */

--
END xxcso_010003j_pkg;
/
