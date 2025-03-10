CREATE OR REPLACE PACKAGE APPS.xxcso_010003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_010003j_pkg(BODY)
 * Description      : 自動販売機設置契約情報登録更新_共通関数
 * MD.050/070       : 
 * Version          : 1.16
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
 *  chk_stop_account          F    V      中止顧客チェック
 *  chk_account_install_code  F    V      顧客物件チェック
 *  chk_bank_branch           F    V      銀行支店マスタチェック
 *  chk_supplier              F    V      仕入先マスタチェック
 *  chk_bank_account          F    V      銀行口座マスタチェック
 *  chk_bank_account_change   F    V      銀行口座マスタ変更チェック
 *  chk_owner_change_use      F    V      オーナ変更物件使用チェック
 *  chk_supp_info_change      F    V      送付先変更チェック
 *  chk_email_address         F    V      メールアドレスチェック（共通関数ラッピング）
 *  chk_pay_start_date        P    -      支払期間開始日チェック
 *  chk_pay_item              P    -      支払項目チェック
 *  decode_bm_info2           F    V      検索基準拠点コード取得関数
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
 *  2011/01/06    1.7   K.Kiriu          E_本稼動_02498対応
 *  2011/06/06    1.8   K.Kiriu          E_本稼動_01963対応
 *  2013/04/01    1.9   K.Kiriu          E_本稼動_10413対応
 *  2015/12/03    1.10  S.Yamashita      E_本稼動_13345対応
 *  2016/01/06    1.11  K.Kiriu          E_本稼動_13456対応
 *  2019/02/19    1.12  Y.Sasaki         E_本稼動_15349対応
 *  2020/10/28    1.13  Y.Sasaki         E_本稼動_16410,E_本稼動_16293対応
 *  2020/12/14    1.14  Y.Sasaki         E_本稼動_16642対応
 *  2022/03/30    1.15  H.Futamura       E_本稼動_18060対応
 *  2023/07/12    1.16  M.Akachi         E_本稼動_19179対応
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
/* 2015.12.03 S.Yamashita E_本稼動_13345対応 START */
  -- 中止顧客チェック
  FUNCTION chk_stop_account(
    in_install_account_id         IN  NUMBER           -- 顧客ID
  ) RETURN VARCHAR2;
--
  -- 顧客物件チェック
  FUNCTION chk_account_install_code(
    in_install_account_id         IN  NUMBER           -- 顧客ID
  ) RETURN VARCHAR2;
--
/* 2015.12.03 S.Yamashita E_本稼動_13345対応 END */
/* 2010.03.01 D.Abe E_本稼動_01868対応 END */
/* 2011/01/06 Ver1.7 K.kiriu E_本稼動_02498対応 START */
  -- 銀行支店マスタチェック
  FUNCTION chk_bank_branch(
    iv_bank_number  IN  VARCHAR2                       -- 銀行番号
   ,iv_bank_num     IN  VARCHAR2                       -- 支店番号
  ) RETURN VARCHAR2;
/* 2011/01/06 Ver1.7 K.kiriu E_本稼動_02498対応 END */
/* 2011/06/06 Ver1.8 K.kiriu E_本稼動_01963対応 START */
  -- 仕入先マスタチェック
  FUNCTION chk_supplier(
    iv_customer_code              IN  VARCHAR2         -- 顧客コード
   ,in_supplier_id                IN  NUMBER           -- 仕入先ID
   ,iv_contract_number            IN  VARCHAR2         -- 契約書番号
   ,iv_delivery_div               IN  VARCHAR2         -- 送付区分
  ) RETURN VARCHAR2;
  -- 銀行口座マスタチェック
  FUNCTION chk_bank_account(
    iv_bank_number                IN  VARCHAR2         -- 銀行番号
   ,iv_bank_num                   IN  VARCHAR2         -- 支店番号
   ,iv_bank_account_num           IN  VARCHAR2         -- 口座番号
  ) RETURN VARCHAR2;
/* 2011/06/06 Ver1.8 K.kiriu E_本稼動_01963対応 END */
/* 2013/04/01 Ver1.9 K.kiriu E_本稼動_10413対応 START */
  -- 銀行口座マスタ変更チェック
  FUNCTION chk_bank_account_change(
    iv_bank_number                IN  VARCHAR2         -- 銀行番号
   ,iv_bank_num                   IN  VARCHAR2         -- 支店番号
   ,iv_bank_account_num           IN  VARCHAR2         -- 口座番号
   ,iv_bank_account_type          IN  VARCHAR2         -- 口座種別(画面入力値)
   ,iv_account_holder_name_alt    IN  VARCHAR2         -- 口座名義カナ(画面入力値)
   ,iv_account_holder_name        IN  VARCHAR2         -- 口座名義漢字(画面入力値)
   ,ov_bank_account_type          OUT VARCHAR2         -- 口座種別(マスタ)
   ,ov_account_holder_name_alt    OUT VARCHAR2         -- 口座名義カナ(マスタ)
   ,ov_account_holder_name        OUT VARCHAR2         -- 口座名義漢字(マスタ)
  ) RETURN VARCHAR2;
/* 2013/04/01 Ver1.9 K.kiriu E_本稼動_10413対応 END */
/* 2016/01/06 Ver1.11 K.kiriu E_本稼動_13456対応 START */
  -- オーナ変更物件使用チェック
  FUNCTION chk_owner_change_use(
    iv_install_code               IN  VARCHAR2         -- 物件コード
   ,in_install_account_id         IN  NUMBER           -- 顧客ID
  ) RETURN VARCHAR2;
/* 2016/01/06 Ver1.11 K.kiriu E_本稼動_13456対応 END */
/* V1.12 Y.Sasaki Added START */
  -- 送付先情報変更チェック
  FUNCTION chk_supp_info_change(
     iv_vendor_code                  IN  VARCHAR2         -- 送付先コード
    ,ov_bm_transfer_commission_type  OUT VARCHAR2         -- 振込手数料負担
    ,ov_bm_payment_type              OUT VARCHAR2         -- 支払方法、明細書
    ,ov_inquiry_base_code            OUT VARCHAR2         -- 問合せ担当拠点
    ,ov_inquiry_base_name            OUT VARCHAR2         -- 問合せ担当拠点名
    ,ov_vendor_name                  OUT VARCHAR2         -- 送付先名
    ,ov_vendor_name_alt              OUT VARCHAR2         -- 送付先名カナ
    ,ov_zip                          OUT VARCHAR2         -- 郵便番号
    ,ov_address_line1                OUT VARCHAR2         -- 住所１
    ,ov_address_line2                OUT VARCHAR2         -- 住所２
    ,ov_phone_number                 OUT VARCHAR2         -- 電話番号
    ,ov_bank_number                  OUT VARCHAR2         -- 金融機関コード
    ,ov_bank_name                    OUT VARCHAR2         -- 金融機関名
    ,ov_bank_branch_number           OUT VARCHAR2         -- 支店コード
    ,ov_bank_branch_name             OUT VARCHAR2         -- 支店名
    ,ov_bank_account_type            OUT VARCHAR2         -- 口座種別
    ,ov_bank_account_num             OUT VARCHAR2         -- 口座番号
    ,ov_bank_account_holder_nm_alt   OUT VARCHAR2         -- 口座名義カナ
    ,ov_bank_account_holder_nm       OUT VARCHAR2         -- 口座名義漢字
  ) RETURN VARCHAR2;
/* V1.12 Y.Sasaki Added END   */
/* E_本稼動_16410 Add START */
  -- BM銀行口座変更チェック
  FUNCTION chk_bm_bank_chg(
      iv_vendor_code                IN  VARCHAR2          -- 送付先コード
    , iv_bank_number                IN  VARCHAR2          -- 銀行コード
    , iv_bank_num                   IN  VARCHAR2          -- 支店コード
    , iv_bank_account_num           IN  VARCHAR2          -- 口座番号
    , iv_bank_account_type          IN  VARCHAR2          -- 口座種別
    , iv_bank_account_holder_nm_alt IN  VARCHAR2          -- 口座名義カナ
    , iv_bank_account_holder_nm     IN  VARCHAR2          -- 口座名義漢字
    , ov_bank_vendor_code           OUT VARCHAR2          -- 口座仕入先コード
  ) RETURN VARCHAR2;
/* E_本稼動_16410 Add End */
/* E_本稼動_16293 Add START */
  -- 仕入先無効日チェック
  FUNCTION chk_vendor_inbalid(
    iv_vendor_code                  IN  VARCHAR2          -- 送付先コード
  ) RETURN VARCHAR2;
/* E_本稼動_16293 Add END   */
/* E_本稼動_16293 Add START */
  -- メールアドレスチェック
  FUNCTION chk_email_address(
    iv_email_address                IN  VARCHAR2          -- Eメールアドレス
  ) RETURN VARCHAR2;
/* E_本稼動_16293 Add END   */
--
-- Ver.1.15 Add Start
  PROCEDURE chk_pay_start_date(
    iv_account_number             IN  VARCHAR2
   ,iv_sp_decision_number         IN  VARCHAR2
   ,ov_ins_contract_number        OUT VARCHAR2
   ,ov_ins_sp_decision_number     OUT VARCHAR2
   ,ov_ad_contract_number         OUT VARCHAR2
   ,ov_ad_sp_decision_number      OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
  );
--
  PROCEDURE chk_pay_item(
    iv_account_number             IN  VARCHAR2
   ,iv_sp_decision_number         IN  VARCHAR2
   ,ov_ins_contract_number        OUT VARCHAR2
   ,ov_ins_sp_decision_number     OUT VARCHAR2
   ,ov_ad_contract_number         OUT VARCHAR2
   ,ov_ad_sp_decision_number      OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
  );
-- Ver.1.15 Add End
-- Ver.1.16 Add Start
  -- BM情報分岐取得
  FUNCTION decode_bm_info2(
    iv_contract_status          VARCHAR2
   ,iv_cooperate_flag           VARCHAR2
   ,iv_batch_proc_status        VARCHAR2
   ,iv_vendor_code              VARCHAR2
   ,iv_transaction_value        VARCHAR2
   ,iv_master_value             VARCHAR2
  ) RETURN VARCHAR2;
-- Ver.1.16 Add End
END xxcso_010003j_pkg;
/
