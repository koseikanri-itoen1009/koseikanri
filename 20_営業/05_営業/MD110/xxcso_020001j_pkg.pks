CREATE OR REPLACE PACKAGE APPS.xxcso_020001j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_020001j_pkg(SPEC)
 * Description      : フルベンダーSP専決
 * MD.050/070       : 
 * Version          : 1.7
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  initialize_transaction    P    -     トランザクション初期化処理
 *  process_request           P    -     通知ワークフロー起動処理
 *  process_lock              P    -     トランザクションロック処理
 *  get_inst_info_parameter   F    V     設置先情報判定
 *  get_cntr_info_parameter   F    V     契約先情報判定
 *  get_bm1_info_parameter    F    V     BM1情報判定
 *  get_bm2_info_parameter    F    V     BM2情報判定
 *  get_bm3_info_parameter    F    V     BM3情報判定
 *  calculate_sc_line         P    -     売価別条件計算（明細行ごと）
 *  calculate_cc_line         P    -     一律条件・容器別条件計算（明細行ごと）
 *  get_gross_profit_rate     F    V     粗利率取得
 *  calculate_est_year_profit P    -     概算年間損益計算
 *  get_appr_auth_level_num_1 F    N     承認権限レベル番号１取得
 *  get_appr_auth_level_num_2 F    N     承認権限レベル番号２取得
 *  get_appr_auth_level_num_3 F    N     承認権限レベル番号３取得
 *  get_appr_auth_level_num_4 F    N     承認権限レベル番号４取得
 *  get_appr_auth_level_num_5 F    N     承認権限レベル番号５取得
 *  get_appr_auth_level_num_0 F    N     承認権限レベル番号（デフォルト）取得
 *  chk_double_byte_kana      F    V     全角カナチェック（共通関数ラッピング）
 *  chk_tel_format            F    V     電話番号チェック（共通関数ラッピング）
 *  conv_number_separate      P    -     数値セパレート変換
 *  conv_line_number_separate P    -     数値セパレート変換（明細）
 *  chk_double_byte           F    V     全角文字チェック（共通関数ラッピング）
 *  chk_single_byte_kana      F    V     半角カナチェック（共通関数ラッピング）
 *  chk_account_many          P    -     アカウント複数チェック
 *  chk_cust_site_uses        P    -     顧客使用目的チェック
 *  chk_validate_db           P    -     ＤＢ更新判定チェック
 *  get_contract_end_period   F    V     契約終了期間取得
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/23    1.0   H.Ogawa          新規作成
 *  2009/04/27    1.1   N.Yanagitaira    [障害T1_0708]入力項目チェック処理統一修正
 *                                                    chk_double_byte
 *                                                    chk_single_byte_kana
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009/11/29    1.3   D.Abe            [E_本稼動_00106]アカウント複数判定
 *  2010/01/12    1.4   D.Abe            [E_本稼動_00823]顧客マスタの整合性チェック対応
 *  2010/01/15    1.5   D.Abe            [E_本稼動_00950]ＤＢ更新判定チェック対応
 *  2010/03/01    1.6   D.Abe            [E_本稼動_01678]現金支払対応
 *  2014/12/15    1.7   K.Kiriu          [E_本稼動_12565]SP・契約書画面改修対応
 *****************************************************************************************/
--
  -- トランザクション初期化処理
  PROCEDURE initialize_transaction(
    iv_sp_decision_header_id       IN  VARCHAR2
   ,iv_app_base_code               IN  VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
--
  -- 通知ワークフロー起動処理
  PROCEDURE process_request(
    ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
--
  -- トランザクションロック処理
  PROCEDURE process_lock(
    in_sp_decision_header_id       IN  NUMBER
   ,iv_sp_decision_number          IN  VARCHAR2
   ,id_last_update_date            IN  DATE
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
--
  -- 設置先情報判定
  FUNCTION get_inst_info_parameter(
    in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 契約先情報判定
  FUNCTION get_cntr_info_parameter(
    in_contract_customer_id        IN  NUMBER
   ,iv_same_install_account_flag   IN  VARCHAR2
   ,in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,iv_sp_cntr_cust_param          IN  VARCHAR2
   ,iv_cntrct_cust_param           IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- BM1情報判定
  FUNCTION get_bm1_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_bm1_send_type               IN  VARCHAR2
   ,in_cust_account_id             IN  NUMBER
   ,iv_customer_status             IN  VARCHAR2
   ,in_contract_customer_id        IN  NUMBER
   ,iv_same_install_account_flag   IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
   ,iv_sp_inst_cust_param          IN  VARCHAR2
   ,iv_cust_acct_param             IN  VARCHAR2
   ,iv_sp_cntr_cust_param          IN  VARCHAR2
   ,iv_cntrct_cust_param           IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- BM2情報判定
  FUNCTION get_bm2_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- BM3情報判定
  FUNCTION get_bm3_info_parameter(
    in_vendor_id                   IN  NUMBER
   ,iv_bm_payment_type             IN  VARCHAR2
   ,iv_sp_vend_cust_param          IN  VARCHAR2
   ,iv_vendor_param                IN  VARCHAR2
  ) RETURN VARCHAR2;
--
  -- 売価別条件計算（明細行ごと）
  PROCEDURE calculate_sc_line(
    iv_fixed_price                 IN  VARCHAR2
   ,iv_sales_price                 IN  VARCHAR2
   ,iv_bm1_bm_rate                 IN  VARCHAR2
   ,iv_bm1_bm_amt                  IN  VARCHAR2
   ,iv_bm2_bm_rate                 IN  VARCHAR2
   ,iv_bm2_bm_amt                  IN  VARCHAR2
   ,iv_bm3_bm_rate                 IN  VARCHAR2
   ,iv_bm3_bm_amt                  IN  VARCHAR2
   ,on_gross_profit                OUT NUMBER
   ,on_sales_price                 OUT NUMBER
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_bm_amount                   OUT VARCHAR2
   ,ov_bm_conv_rate                OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
--
  -- 一律条件・容器別条件計算（明細行ごと）
  PROCEDURE calculate_cc_line(
    iv_container_type              IN  VARCHAR2
   ,iv_discount_amt                IN  VARCHAR2
   ,iv_bm1_bm_rate                 IN  VARCHAR2
   ,iv_bm1_bm_amt                  IN  VARCHAR2
   ,iv_bm2_bm_rate                 IN  VARCHAR2
   ,iv_bm2_bm_amt                  IN  VARCHAR2
   ,iv_bm3_bm_rate                 IN  VARCHAR2
   ,iv_bm3_bm_amt                  IN  VARCHAR2
   ,on_gross_profit                OUT NUMBER
   ,on_sales_price                 OUT NUMBER
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_bm_amount                   OUT VARCHAR2
   ,ov_bm_conv_rate                OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
  -- 粗利率取得
  FUNCTION get_gross_profit_rate(
    in_total_gross_profit          IN  NUMBER
   ,in_total_sales_price           IN  NUMBER
  ) RETURN VARCHAR2;
--
  -- 概算年間損益計算
  PROCEDURE calculate_est_year_profit(
    iv_sales_month                 IN  VARCHAR2
   ,iv_sales_gross_margin_rate     IN  VARCHAR2
   ,iv_bm_rate                     IN  VARCHAR2
   ,iv_lease_charge_month          IN  VARCHAR2
   ,iv_construction_charge         IN  VARCHAR2
   ,iv_contract_year_date          IN  VARCHAR2
   ,iv_install_support_amt         IN  VARCHAR2
   ,iv_electricity_amount          IN  VARCHAR2
   ,iv_electricity_amt_month       IN  VARCHAR2
   ,ov_sales_year                  OUT VARCHAR2
   ,ov_year_gross_margin_amt       OUT VARCHAR2
   ,ov_vd_sales_charge             OUT VARCHAR2
   ,ov_install_support_amt_year    OUT VARCHAR2
   ,ov_vd_lease_charge             OUT VARCHAR2
   ,ov_electricity_amt_month       OUT VARCHAR2
   ,ov_electricity_amt_year        OUT VARCHAR2
   ,ov_transportation_charge       OUT VARCHAR2
   ,ov_labor_cost_other            OUT VARCHAR2
   ,ov_total_cost                  OUT VARCHAR2
   ,ov_operating_profit            OUT VARCHAR2
   ,ov_operating_profit_rate       OUT VARCHAR2
   ,ov_break_even_point            OUT VARCHAR2
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
--
  -- 承認権限レベル番号１取得
  FUNCTION get_appr_auth_level_num_1(
    iv_fixed_price                 IN  VARCHAR2
   ,iv_sales_price                 IN  VARCHAR2
   ,iv_discount_amt                IN  VARCHAR2
   ,iv_bm_conv_rate                IN  VARCHAR2
  ) RETURN NUMBER;
--
  -- 承認権限レベル番号２取得
  FUNCTION get_appr_auth_level_num_2(
    iv_install_support_amt         IN  VARCHAR2
  ) RETURN NUMBER;
--
  -- 承認権限レベル番号３取得
  FUNCTION get_appr_auth_level_num_3(
    iv_electricity_amt             IN  VARCHAR2
  ) RETURN NUMBER;
--
  -- 承認権限レベル番号４取得
  FUNCTION get_appr_auth_level_num_4(
    iv_construction_charge         IN  VARCHAR2
  ) RETURN NUMBER;
--
/* 2010.03.01 D.Abe E_本稼動_01678対応 START */
  -- 承認権限レベル番号５取得
  FUNCTION get_appr_auth_level_num_5(
    iv_bm1_bm_payment_type     IN  VARCHAR2
   ,iv_bm2_bm_payment_type     IN  VARCHAR2
   ,iv_bm3_bm_payment_type     IN  VARCHAR2
  ) RETURN NUMBER;
--
/* 2010.03.01 D.Abe E_本稼動_01678対応 END */
  -- 承認権限レベル番号（デフォルト）取得
  PROCEDURE get_appr_auth_level_num_0(
    on_appr_auth_level_num         OUT NUMBER
   ,ov_errbuf                      OUT VARCHAR2
   ,ov_retcode                     OUT VARCHAR2
   ,ov_errmsg                      OUT VARCHAR2
  );
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
  -- 数値セパレート変換
  PROCEDURE conv_number_separate(
    iv_sele_number                 IN  VARCHAR2
   ,iv_contract_year_date          IN  VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Del Start
--   ,iv_install_support_amt         IN  VARCHAR2
--   ,iv_install_support_amt2        IN  VARCHAR2
--   ,iv_payment_cycle               IN  VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Del End
   ,iv_electricity_amount          IN  VARCHAR2
   ,iv_sales_month                 IN  VARCHAR2
   ,iv_bm_rate                     IN  VARCHAR2
   ,iv_vd_sales_charge             IN  VARCHAR2
   ,iv_lease_charge_month          IN  VARCHAR2
   ,iv_contruction_charge          IN  VARCHAR2
   ,iv_electricity_amt_month       IN  VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Add Start
   ,iv_contract_year_month         IN  VARCHAR2
   ,iv_contract_start_month        IN  VARCHAR2
   ,iv_contract_end_month          IN  VARCHAR2
   ,iv_ad_assets_amt               IN  VARCHAR2
   ,iv_ad_assets_this_time         IN  VARCHAR2
   ,iv_ad_assets_payment_year      IN  VARCHAR2
   ,iv_install_supp_amt            IN  VARCHAR2
   ,iv_install_supp_this_time      IN  VARCHAR2
   ,iv_install_supp_payment_year   IN  VARCHAR2
   ,iv_intro_chg_amt               IN  VARCHAR2
   ,iv_intro_chg_this_time         IN  VARCHAR2
   ,iv_intro_chg_payment_year      IN  VARCHAR2
   ,iv_intro_chg_per_sales_price   IN  VARCHAR2
   ,iv_intro_chg_per_piece         IN  VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Add End
   ,ov_sele_number                 OUT VARCHAR2
   ,ov_contract_year_date          OUT VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Del Start
--   ,ov_install_support_amt         OUT VARCHAR2
--   ,ov_install_support_amt2        OUT VARCHAR2
--   ,ov_payment_cycle               OUT VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Del End
   ,ov_electricity_amount          OUT VARCHAR2
   ,ov_sales_month                 OUT VARCHAR2
   ,ov_bm_rate                     OUT VARCHAR2
   ,ov_vd_sales_charge             OUT VARCHAR2
   ,ov_lease_charge_month          OUT VARCHAR2
   ,ov_contruction_charge          OUT VARCHAR2
   ,ov_electricity_amt_month       OUT VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Add Start
   ,ov_contract_year_month         OUT VARCHAR2
   ,ov_contract_start_month        OUT VARCHAR2
   ,ov_contract_end_month          OUT VARCHAR2
   ,ov_ad_assets_amt               OUT VARCHAR2
   ,ov_ad_assets_this_time         OUT VARCHAR2
   ,ov_ad_assets_payment_year      OUT VARCHAR2
   ,ov_install_supp_amt            OUT VARCHAR2
   ,ov_install_supp_this_time      OUT VARCHAR2
   ,ov_install_supp_payment_year   OUT VARCHAR2
   ,ov_intro_chg_amt               OUT VARCHAR2
   ,ov_intro_chg_this_time         OUT VARCHAR2
   ,ov_intro_chg_payment_year      OUT VARCHAR2
   ,ov_intro_chg_per_sales_price   OUT VARCHAR2
   ,ov_intro_chg_per_piece         OUT VARCHAR2
-- 20141215_K.Kiriu E_本稼動_12565 Add End
  );
--
  -- 数値セパレート変換（明細）
  PROCEDURE conv_line_number_separate(
    iv_sales_price                  IN  VARCHAR2
   ,iv_discount_amt                 IN  VARCHAR2
   ,iv_total_bm_rate                IN  VARCHAR2
   ,iv_total_bm_amount              IN  VARCHAR2
   ,iv_total_bm_conv_rate           IN  VARCHAR2
   ,iv_bm1_bm_rate                  IN  VARCHAR2
   ,iv_bm1_bm_amount                IN  VARCHAR2
   ,iv_bm2_bm_rate                  IN  VARCHAR2
   ,iv_bm2_bm_amount                IN  VARCHAR2
   ,iv_bm3_bm_rate                  IN  VARCHAR2
   ,iv_bm3_bm_amount                IN  VARCHAR2
   ,ov_sales_price                  OUT VARCHAR2
   ,ov_discount_amt                 OUT VARCHAR2
   ,ov_total_bm_rate                OUT VARCHAR2
   ,ov_total_bm_amount              OUT VARCHAR2
   ,ov_total_bm_conv_rate           OUT VARCHAR2
   ,ov_bm1_bm_rate                  OUT VARCHAR2
   ,ov_bm1_bm_amount                OUT VARCHAR2
   ,ov_bm2_bm_rate                  OUT VARCHAR2
   ,ov_bm2_bm_amount                OUT VARCHAR2
   ,ov_bm3_bm_rate                  OUT VARCHAR2
   ,ov_bm3_bm_amount                OUT VARCHAR2
  );
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
-- 20091129_D.Abe E_本稼動_00106 Mod START
  -- アカウント複数チェック
  PROCEDURE chk_account_many(
    iv_account_number           IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  );
--
-- 20091129_D.Abe E_本稼動_00106 Mod END
-- 20100112_D.Abe E_本稼動_00823 Mod START
  -- 顧客使用目的チェック
  PROCEDURE chk_cust_site_uses(
    iv_account_number           IN  VARCHAR2
   ,ov_errbuf                   OUT VARCHAR2
   ,ov_retcode                  OUT VARCHAR2
   ,ov_errmsg                   OUT VARCHAR2
  );
--
-- 20100112_D.Abe E_本稼動_00823 Mod END
-- 20100115_D.Abe E_本稼動_00950 Mod START
  -- ＤＢ更新判定チェック
  PROCEDURE chk_validate_db(
    in_sp_decision_header_id      IN  NUMBER
   ,id_last_update_date           IN  DATE
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  );
--
-- 20100115_D.Abe E_本稼動_00950 Mod END
-- 20141215_K.Kiriu E_本稼動_12565 Add START
  -- 契約終了期間取得
  PROCEDURE get_contract_end_period(
    iv_contract_year_date         IN  VARCHAR2
   ,iv_contract_year_month        IN  VARCHAR2
   ,iv_contract_start_year        IN  VARCHAR2
   ,iv_contract_start_month       IN  VARCHAR2
   ,iv_contract_end_year          IN  VARCHAR2
   ,iv_contract_end_month         IN  VARCHAR2
   ,ov_contract_end               OUT VARCHAR2
   ,ov_errbuf                     OUT VARCHAR2
   ,ov_retcode                    OUT VARCHAR2
   ,ov_errmsg                     OUT VARCHAR2
  );
--
-- 20141215_K.Kiriu E_本稼動_12565 Add END
END xxcso_020001j_pkg;
/
