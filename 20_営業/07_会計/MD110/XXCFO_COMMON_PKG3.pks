create or replace PACKAGE XXCFO_COMMON_PKG3
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg3(spec)
 * Description      : 共通関数（会計）
 * MD.070           : MD070_IPO_CFO_001_共通関数定義書
 * Version          : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  init_proc                 P           共通初期処理
 *  chk_period_status         P           仕訳作成用会計期間チェック
 *  chk_gl_if_status          P           仕訳作成用GL連携チェック
 *  chk_ap_period_status      P           AP請求書作成用会計期間チェック
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-19    1.0   K.Kubo           新規作成
 *
 *****************************************************************************************/
--
  -- 共通初期処理
  PROCEDURE init_proc(
      ov_company_code_mfg         OUT VARCHAR2  -- 会社コード（工場）
    , ov_aff5_customer_dummy      OUT VARCHAR2  -- 顧客コード_ダミー値
    , ov_aff6_company_dummy       OUT VARCHAR2  -- 企業コード_ダミー値
    , ov_aff7_preliminary1_dummy  OUT VARCHAR2  -- 予備1_ダミー値
    , ov_aff8_preliminary2_dummy  OUT VARCHAR2  -- 予備2_ダミー値
    , ov_je_invoice_source_mfg    OUT VARCHAR2  -- 仕訳ソース_生産システム
    , on_org_id_mfg               OUT NUMBER    -- 生産ORG_ID
    , on_sales_set_of_bks_id      OUT NUMBER    -- 営業システム会計帳簿ID
    , ov_sales_set_of_bks_name    OUT VARCHAR2  -- 営業システム会計帳簿名
    , ov_currency_code            OUT VARCHAR2  -- 営業システム機能通貨コード
    , od_process_date             OUT DATE      -- 業務日付
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  );
--
  -- 仕訳作成用会計期間チェック
  PROCEDURE chk_period_status(
      iv_period_name              IN  VARCHAR2  -- 会計期間（YYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- 会計帳簿ID
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  );
--
  -- 仕訳作成用GL連携チェック
  PROCEDURE chk_gl_if_status(
      iv_period_name              IN  VARCHAR2  -- 会計期間（YYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- 会計帳簿ID
    , iv_func_name                IN  VARCHAR2  -- 機能名（コンカレント短縮名）
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  );
--
  -- AP請求書作成用会計期間チェック
  PROCEDURE chk_ap_period_status(
      iv_period_name              IN  VARCHAR2  -- 会計期間（YYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- 会計帳簿ID
    , ov_errbuf                   OUT VARCHAR2  -- エラーバッファ
    , ov_retcode                  OUT VARCHAR2  -- リターンコード
    , ov_errmsg                   OUT VARCHAR2  -- ユーザー・エラーメッセージ
  );
--
END XXCFO_COMMON_PKG3;
/
