CREATE OR REPLACE PACKAGE BODY      XXCOK024A38C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A38C(body)
 * Description      : 入金時値引データIF出力（情報系）
 * MD.050           : 入金時値引データIF出力（情報系） MD050_COK_024_A38
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_discount_data_p    入金時値引データ抽出(A-2)
 *  put_discount_data_p    入金時値引データ出力(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/06/22    1.0   Y.Koh            新規作成
 *
 *****************************************************************************************/
--
  -- ==============================
  -- グローバル定数
  -- ==============================
  -- ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1)          := xxccp_common_pkg.set_status_error;   -- 異常:2
  -- パッケージ名
  cv_pkg_name                 CONSTANT VARCHAR2(100)        := 'XXCOK024A38C';                      -- パッケージ名
  -- プロファイル
  cv_discount_data_filepath   CONSTANT VARCHAR2(30)         := 'XXCFR1_SALES_DATA_FILEPATH';        -- 入金時値引データファイルパス(売上実績データと同じパス)
  cv_discount_data_filename   CONSTANT VARCHAR2(30)         := 'XXCOK1_DISCOUNT_DATA_FILE_NAME';    -- 入金時値引データファイル名
  cv_aff1_company_code        CONSTANT VARCHAR2(30)         := 'XXCOK1_AFF1_COMPANY_CODE';          -- 会社コード
  cv_ra_trx_type_general      CONSTANT VARCHAR2(30)         := 'XXCOK1_RA_TRX_TYPE_GENERAL';        -- 取引タイプ_入金値引_一般店
  cv_sd_sold_return_type      CONSTANT VARCHAR2(35)         := 'XXCFR1_SD_SOLD_RETURN_TYPE';        -- 売上実績データ売上返品区分
  cv_sd_sales_class           CONSTANT VARCHAR2(35)         := 'XXCFR1_SD_SALES_CLASS';             -- 売上実績データ売上区分
  cv_sd_delivery_ptn_class    CONSTANT VARCHAR2(35)         := 'XXCFR1_SD_DELIVERY_PTN_CLASS';      -- 売上実績データ納品形態区分
  -- アプリケーション短縮名
  cv_appli_xxccp_name         CONSTANT VARCHAR2(50)         := 'XXCCP';                             -- アプリケーション短縮名(共通)
  cv_appli_xxcok_name         CONSTANT VARCHAR2(15)         := 'XXCOK';                             -- アプリケーション短縮名(個別開発)
  cv_appli_xxcfr_name         CONSTANT VARCHAR2(50)         := 'XXCFR';                             -- アプリケーション短縮名(AR)
  -- メッセージ
  cv_msg_ccp_90000            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90000';                  -- 対象件数メッセージ
  cv_msg_ccp_90001            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90001';                  -- 成功件数メッセージ
  cv_msg_ccp_90003            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90003';                  -- スキップ件数メッセージ
  cv_msg_ccp_90002            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90002';                  -- エラー件数メッセージ
  cv_msg_ccp_90004            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90004';                  -- 正常終了メッセージ
  cv_msg_ccp_90005            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90005';                  -- 警告終了メッセージ
  cv_msg_ccp_90006            CONSTANT VARCHAR2(50)         := 'APP-XXCCP1-90006';                  -- エラー終了全ロールバックメッセージ
  cv_msg_cok_00001            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00001';                  -- 対象なしメッセージ
  cv_msg_cok_00003            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00003';                  -- プロファイル取得エラー
  cv_msg_cok_00009            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00009';                  -- ファイル存在エラー
  cv_msg_cok_00028            CONSTANT VARCHAR2(50)         := 'APP-XXCOK1-00028';                  -- 業務処理日付取得エラー
  cv_msg_cfr_00058            CONSTANT VARCHAR2(50)         := 'APP-XXCFR1-00058';                  -- 商品コード未設定メッセージ
  -- トークン名
  cv_tkn_count                CONSTANT VARCHAR2(15)         := 'COUNT';                             -- 件数のトークン名
  cv_tkn_profile              CONSTANT VARCHAR2(15)         := 'PROFILE';                           -- プロファイル名のトークン名
  cv_tkn_file_name            CONSTANT VARCHAR2(15)         := 'FILE_NAME';                         -- ファイル名のトークン名
  cv_tkn_trx_type             CONSTANT VARCHAR2(15)         := 'TRX_TYPE';                          -- 取引タイプのトークン名
  -- 参照タイプ
  cv_lookup_data_type         CONSTANT VARCHAR2(50)         := 'XXCOK1_DEDUCTION_DATA_TYPE';        -- 控除データ種類
  -- フラグ等
  cv_lang_ja                  CONSTANT VARCHAR2(2)          := 'JA';                                -- 言語 JA
  cv_flag_y                   CONSTANT VARCHAR2(1)          := 'Y';                                 -- 有効 Y
  -- 記号
  cv_msg_cont                 CONSTANT VARCHAR2(1)          := '.';
  cv_msg_part                 CONSTANT VARCHAR2(3)          := ' : ';
--
  cv_trx_number               CONSTANT VARCHAR2(10)         := '9999999999';                                            -- 納品伝票No
  cv_object_code              CONSTANT VARCHAR2(10)         := '0000000000';                                            -- 物件コード
  cv_hc_code                  CONSTANT VARCHAR2(1)          := '1';                                                     -- Ｈ＆Ｃ（コールド）
  cv_score_member_code        CONSTANT VARCHAR2(5)          := '00000';                                                 -- 成績者コード
  cv_sales_card_type          CONSTANT VARCHAR2(1)          := '0';                                                     -- カード売り区分（現金）
  cv_delivery_base_code       CONSTANT VARCHAR2(4)          := '0000';                                                  -- 納品拠点コード
  cv_unit_sales               CONSTANT VARCHAR2(1)          := '0';                                                     -- 売上数量
  cv_column_no                CONSTANT VARCHAR2(2)          := '00';                                                    -- コラムNo
  cn_zero                     CONSTANT NUMBER               := 0;                                                       -- 基準単価（税込）,売上金額（税込）出力固定値
--
  cv_format_date_ymd          CONSTANT VARCHAR2(8)          := 'YYYYMMDD';                                              -- 日付フォーマット（年月日）
  cv_format_date_ymdhns       CONSTANT VARCHAR2(16)         := 'YYYYMMDDHH24MISS';                                      -- 日付フォーマット（年月日時分秒）
--
  -- ==============================
  -- グローバル変数
  -- ==============================
  gn_target_cnt               NUMBER    DEFAULT 0;                                                  -- 対象件数
  gn_normal_cnt               NUMBER    DEFAULT 0;                                                  -- 正常件数
  gn_skip_cnt                 NUMBER    DEFAULT 0;                                                  -- スキップ件数
  gn_error_cnt                NUMBER    DEFAULT 0;                                                  -- エラー件数
--
  gd_process_date             DATE;                                                                 -- 業務処理日付
  gd_process_month            DATE;                                                                 -- 対象年月(日)
--
  gv_discount_data_filepath   VARCHAR2(500);                                                        -- 入金時値引データファイル格納パス
  gv_discount_data_filename   VARCHAR2(100);                                                        -- 入金時値引データファイル名
  gf_file_hand                UTL_FILE.FILE_TYPE;                                                   -- ファイル・ハンドルの宣言
--
  gv_aff1_company_code        VARCHAR2(30);                                                         -- 会社コード
  gv_ra_trx_type_general      VARCHAR2(30);                                                         -- 取引タイプ_入金値引_一般店
  gv_item_code                VARCHAR2(30);                                                         -- 入金時値引の情報系システム連携商品コード
  gv_sd_sold_return_type      VARCHAR2(30);                                                         -- 売上実績データ売上返品区分
  gv_sd_sales_class           VARCHAR2(30);                                                         -- 売上実績データ売上区分
  gv_sd_delivery_ptn_class    VARCHAR2(30);                                                         -- 売上実績データ納品形態区分
--
  -- ==============================
  -- グローバル例外
  -- ==============================
  -- *** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ 
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 業務処理日付の取得
    -- ============================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF  gd_process_date IS  NULL  THEN
      lv_errmsg  := xxccp_common_pkg.get_msg( cv_appli_xxcok_name
                                             ,cv_msg_cok_00028
                                             );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    gd_process_month  :=  trunc(gd_process_date,'MM') - 1;
--
    -- ============================================================
    -- 出力ファイルパス取得
    -- ============================================================
    gv_discount_data_filepath := FND_PROFILE.VALUE(cv_discount_data_filepath);
    -- 取得エラー時
    IF  gv_discount_data_filepath  IS NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_discount_data_filepath
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 出力ファイル名取得
    -- ============================================================
    gv_discount_data_filename := FND_PROFILE.VALUE(cv_discount_data_filename);
    -- 取得エラー時
    IF  gv_discount_data_filename IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_discount_data_filename
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 会社コード取得
    -- ============================================================
    gv_aff1_company_code      := FND_PROFILE.VALUE( cv_aff1_company_code );
    IF  gv_aff1_company_code	IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_aff1_company_code
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 入金時値引の取引タイプ取得
    -- ============================================================
    gv_ra_trx_type_general    := FND_PROFILE.VALUE( cv_ra_trx_type_general );
    IF  gv_ra_trx_type_general  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_ra_trx_type_general
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 入金時値引の情報系システム連携商品コード取得
    -- ============================================================
    select  max(attribute3)
    into    gv_item_code
    from    ra_cust_trx_types_all rctta
    where   rctta.name  = gv_ra_trx_type_general;
--
    IF  gv_item_code  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcfr_name
                     ,cv_msg_cfr_00058
                     ,cv_tkn_trx_type
                     ,gv_ra_trx_type_general
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 売上実績データ売上返品区分取得
    -- ============================================================
    gv_sd_sold_return_type    := FND_PROFILE.VALUE( cv_sd_sold_return_type );
    IF  gv_sd_sold_return_type  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_sd_sold_return_type
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 売上実績データ売上区分取得
    -- ============================================================
    gv_sd_sales_class         := FND_PROFILE.VALUE( cv_sd_sales_class );
    IF  gv_sd_sales_class IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_sd_sales_class
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 売上実績データ納品形態区分取得
    -- ============================================================
    gv_sd_delivery_ptn_class  := FND_PROFILE.VALUE( cv_sd_delivery_ptn_class );
    IF  gv_sd_delivery_ptn_class  IS  NULL  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00003
                     ,cv_tkn_profile
                     ,cv_sd_delivery_ptn_class
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : put_discount_data_p
   * Description      : 入金時値引データ出力(A-3)
   ***********************************************************************************/
  PROCEDURE put_discount_data_p(
    ov_errbuf               OUT VARCHAR2                    -- エラー・メッセージ
  , ov_retcode              OUT VARCHAR2                    -- リターン・コード
  , ov_errmsg               OUT VARCHAR2                    -- ユーザー・エラー・メッセージ
  , iv_base_code_to         IN  VARCHAR2                    -- 振替先拠点
  , iv_customer_code_to     IN  VARCHAR2                    -- 振替先顧客コード
  , iv_tax_code             IN  VARCHAR2                    -- 税コード
  , in_deduction_amount     IN  NUMBER                      -- 控除額
  , in_deduction_tax_amount IN  NUMBER                      -- 控除税額
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'put_discount_data_p'; -- プログラム名
--
    cv_delimiter    CONSTANT VARCHAR2(1)    := ',';                             -- CSV区切り文字
    cv_enclosed     CONSTANT VARCHAR2(2)    := '"';                             -- 単語囲み文字
--
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_base_code              VARCHAR2(4);                            -- 担当拠点
    lv_errbuf                 VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode                VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg                 VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    lb_retcode                BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
    lv_csv_text               VARCHAR2(32000);                        -- CSVデータ
    -- 顧客情報
    lv_bill_to_cust_code      VARCHAR2(30)        DEFAULT NULL;       -- メッセージ出力変数
    lv_sales_staff_code       VARCHAR2(30)        DEFAULT NULL;       -- メッセージ出力変数
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- 担当営業員コード取得
    -- ============================================================
    lv_sales_staff_code   :=  xxcok_common_pkg.get_sales_staff_code_f( iv_customer_code_to, gd_process_month );
--
    -- ============================================================
    -- 請求先顧客コード取得
    -- ============================================================
    lv_bill_to_cust_code  :=  xxcok_common_pkg.get_bill_to_cust_code_f( iv_customer_code_to );
--
    -- ============================================================
    -- 入金時値引データ出力
    -- ============================================================
    lv_csv_text := cv_enclosed || gv_aff1_company_code || cv_enclosed || cv_delimiter               -- 会社コード
                || TO_CHAR ( gd_process_month, cv_format_date_ymd ) || cv_delimiter                 -- 納品日(GL記帳日)
                || cv_enclosed || cv_trx_number || cv_enclosed || cv_delimiter                      -- 納品伝票No
                || '1' || cv_delimiter                                                              -- 納品伝票行No
                || cv_enclosed || iv_customer_code_to || cv_enclosed || cv_delimiter                -- 顧客コード
                || cv_enclosed || gv_item_code || cv_enclosed || cv_delimiter                       -- 商品コード
                || cv_enclosed || cv_object_code || cv_enclosed || cv_delimiter                     -- 物件コード
                || cv_enclosed || cv_hc_code || cv_enclosed || cv_delimiter                         -- Ｈ＆Ｃ
                || cv_enclosed || iv_base_code_to || cv_enclosed || cv_delimiter                    -- 売上拠点コード
                || cv_enclosed || lv_sales_staff_code || cv_enclosed || cv_delimiter                -- 成績者コード
                || cv_enclosed || cv_sales_card_type || cv_enclosed || cv_delimiter                 -- カード売り区分
                || cv_enclosed || cv_delivery_base_code || cv_enclosed || cv_delimiter              -- 納品拠点コード
                || TO_CHAR ( - in_deduction_amount ) || cv_delimiter                                -- 売上金額
                || cv_unit_sales || cv_delimiter                                                    -- 売上数量
                || TO_CHAR ( - in_deduction_tax_amount ) || cv_delimiter                            -- 税額
                || cv_enclosed || gv_sd_sold_return_type || cv_enclosed || cv_delimiter             -- 売上返品区分
                || cv_enclosed || gv_sd_sales_class || cv_enclosed || cv_delimiter                  -- 売上区分
                || cv_enclosed || gv_sd_delivery_ptn_class || cv_enclosed || cv_delimiter           -- 納品形態区分
                || cv_enclosed || cv_column_no || cv_enclosed || cv_delimiter                       -- コラムNo
                || TO_CHAR ( gd_process_month, cv_format_date_ymd ) || cv_delimiter                 -- 検収予定日(取引日)
                || cv_delimiter                                                                     -- 納品単価
                || cv_enclosed || iv_tax_code || cv_enclosed || cv_delimiter                        -- 税コード
                || cv_enclosed || lv_bill_to_cust_code || cv_enclosed || cv_delimiter               -- 請求先顧客コード
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- 注文伝票番号
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- 伝票区分
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- 伝票分類コード
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- つり銭切れ時間100円
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- つり銭切れ時間10円
                || cn_zero                    || cv_delimiter                                       -- 基準単価（税込）
                || cn_zero                    || cv_delimiter                                       -- 売上金額（税込）
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- 売切区分
                || cv_enclosed || cv_enclosed || cv_delimiter                                       -- 売切時間
                || TO_CHAR ( SYSDATE, cv_format_date_ymdhns)                                        -- 連携日時
    ;
--
    -- ============================================================
    -- ファイル書き込み
    -- ============================================================
    UTL_FILE.PUT_LINE( gf_file_hand, lv_csv_text ) ;
    gn_normal_cnt :=  gn_normal_cnt + 1;                    -- 正常件数
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END put_discount_data_p;
--
  /**********************************************************************************
   * Procedure Name   : get_discount_data_p
   * Description      : 入金時値引データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_discount_data_p(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ 
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100)  := 'get_sales_exp_p';               -- プログラム名
--
    cv_open_mode_w  CONSTANT VARCHAR2(10)   := 'w';                             -- ファイルオープンモード（上書き）
--
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ出力変数
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
--
    lb_fexists      BOOLEAN;                                -- ファイルが存在するかどうか
    ln_file_size    NUMBER;                                 -- ファイルの長さ
    ln_block_size   NUMBER;                                 -- ファイルシステムのブロックサイズ
--
    -- ==============================
    -- ローカルカーソル
    -- ==============================
    -- 入金時値引情報
    CURSOR l_discount_data_cur
    IS
      WITH
        flvc1 AS
        ( SELECT  /*+ MATERIALIZED */ lookup_code
          FROM    fnd_lookup_values flvc
          WHERE   flvc.lookup_type  = cv_lookup_data_type
          AND     flvc.language     = cv_lang_ja
          AND     flvc.enabled_flag = cv_flag_y
          AND     flvc.attribute10  = cv_flag_y
        )
      SELECT  xsd.base_code_to            base_code_to        ,                 -- 振替先拠点
              xsd.customer_code_to        customer_code_to    ,                 -- 振替先顧客コード
              xsd.tax_code                tax_code            ,                 -- 税コード
              SUM(deduction_amount)       deduction_amount    ,                 -- 控除額
              SUM(deduction_tax_amount)   deduction_tax_amount                  -- 控除税額
      FROM    xxcok_sales_deduction   xsd ,
              flvc1                   flv
      WHERE   xsd.data_type           =   flv.lookup_code
      AND     xsd.cancel_gl_date      IS  NULL
      AND     xsd.gl_date             =   gd_process_month
      GROUP BY  xsd.base_code_to    ,
                xsd.customer_code_to,
                xsd.tax_code
    UNION ALL
      SELECT  xsd.base_code_to            base_code_to        ,                 -- 振替先拠点
              xsd.customer_code_to        customer_code_to    ,                 -- 振替先顧客コード
              xsd.tax_code                tax_code            ,                 -- 税コード
              -SUM(deduction_amount)      deduction_amount    ,                 -- 控除額
              -SUM(deduction_tax_amount)  deduction_tax_amount                  -- 控除税額
      FROM    xxcok_sales_deduction   xsd ,
              flvc1                   flv
      WHERE   xsd.data_type           =   flv.lookup_code
      AND     xsd.cancel_gl_date      =   gd_process_month
      GROUP BY  xsd.base_code_to    ,
                xsd.customer_code_to,
                xsd.tax_code        ;
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR(gv_discount_data_filepath,
                      gv_discount_data_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
--
    -- 前回ファイルが存在している
    IF  lb_fexists  THEN
      lv_errmsg :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxcok_name
                     ,cv_msg_cok_00009
                     ,cv_tkn_file_name
                     ,gv_discount_data_filename
                    );
      lv_errbuf :=  lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    gf_file_hand := UTL_FILE.FOPEN
                      ( gv_discount_data_filepath
                       ,gv_discount_data_filename
                       ,cv_open_mode_w
                      ) ;
--
    -- ============================================================
    -- 入金時値引情報抽出
    -- ============================================================
    FOR l_discount_data_rec IN  l_discount_data_cur LOOP
--
      gn_target_cnt :=  gn_target_cnt + 1;                  -- 対象件数
      -- ============================================================
      -- 入金時値引情報出力(A-3)の呼び出し
      -- ============================================================
      put_discount_data_p(
        ov_errbuf               =>  lv_errbuf                                 -- エラー・メッセージ
      , ov_retcode              =>  lv_retcode                                -- リターン・コード
      , ov_errmsg               =>  lv_errmsg                                 -- ユーザー・エラー・メッセージ
      , iv_base_code_to         =>  l_discount_data_rec.base_code_to          -- 振替先拠点
      , iv_customer_code_to     =>  l_discount_data_rec.customer_code_to      -- 振替先顧客コード
      , iv_tax_code             =>  l_discount_data_rec.tax_code              -- 税コード
      , in_deduction_amount     =>  l_discount_data_rec.deduction_amount      -- 控除額
      , in_deduction_tax_amount =>  l_discount_data_rec.deduction_tax_amount  -- 控除税額
      );
--
      IF    lv_retcode  = cv_status_warn  THEN
        ov_retcode  :=  cv_status_warn;
      ELSIF lv_retcode  = cv_status_error THEN
        RAISE global_process_expt;
      END IF;
--
    END LOOP;
--
    -- ============================================================
    -- 対象なしの場合
    -- ============================================================
    IF gn_normal_cnt = 0 THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxcok_name
                      , cv_msg_cok_00001
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT   -- 出力区分
                      , lv_out_msg        -- メッセージ
                      , 1                 -- 改行
                      );
      ov_retcode  :=  cv_status_warn;
    END IF;
--
    -- ============================================================
    -- ファイルクローズ
    -- ============================================================
    UTL_FILE.FCLOSE( gf_file_hand ) ;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END get_discount_data_p;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf  OUT VARCHAR2                                 -- エラー・メッセージ
  , ov_retcode OUT VARCHAR2                                 -- リターン・コード
  , ov_errmsg  OUT VARCHAR2                                 -- ユーザー・エラー・メッセージ
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'submain';    -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
--
  BEGIN
--
    ov_retcode  :=  cv_status_normal;
--
    -- ============================================================
    -- グローバル変数の初期化
    -- ============================================================
    gn_target_cnt :=  0;
    gn_normal_cnt :=  0;
    gn_skip_cnt   :=  0;
    gn_error_cnt  :=  0;
--
    -- =============================================================
    -- initの呼び出し
    -- =============================================================
    init(
      ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode                            -- リターン・コード
    , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
    -- ============================================================
    -- 入金時値引データ抽出の呼び出し
    -- ============================================================
    get_discount_data_p(
      ov_errbuf   =>  lv_errbuf                             -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode                            -- リターン・コード
    , ov_errmsg   =>  lv_errmsg                             -- ユーザー・エラー・メッセージ
    );
    IF  lv_retcode  = cv_status_warn  THEN
      ov_retcode  :=  cv_status_warn;
    ELSIF lv_retcode  = cv_status_error THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN  global_process_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode  :=  cv_status_error;
      ov_errmsg   :=  lv_errmsg;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ov_errbuf   :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      ov_retcode  :=  cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf  OUT VARCHAR2                                    -- エラー・メッセージ
  , retcode OUT VARCHAR2                                    -- リターン・コード
  )
  IS
--
    -- ==============================
    -- ローカル定数
    -- ==============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';       -- プログラム名
    -- ==============================
    -- ローカル変数
    -- ==============================
    lv_errbuf       VARCHAR2(5000)      DEFAULT NULL;       -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)         DEFAULT NULL;       -- リターン・コード
    lv_errmsg       VARCHAR2(5000)      DEFAULT NULL;       -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN             DEFAULT NULL;       -- メッセージ出力関数の戻り値
    lv_out_msg      VARCHAR2(1000)      DEFAULT NULL;       -- メッセージ変数
--
  BEGIN
--
    -- ============================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ============================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
--
    lb_retcode := xxcok_common_pkg.put_message_f( 
                    FND_FILE.OUTPUT    -- 出力区分
                  , NULL               -- メッセージ
                  , 1                  -- 改行
                  );
--
    -- ============================================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ============================================================
    submain(
      ov_errbuf  => lv_errbuf                               -- エラー・メッセージ
    , ov_retcode => lv_retcode                              -- リターン・コード
    , ov_errmsg  => lv_errmsg                               -- ユーザー・エラー・メッセージ
    );
--
    -- ============================================================
    -- エラー出力
    -- ============================================================
    IF  lv_retcode  = cv_status_error THEN
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.OUTPUT -- 出力区分
                      , lv_errmsg       -- メッセージ
                      , 1               -- 改行
                      );
      lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                        FND_FILE.LOG    -- 出力区分
                      , lv_errbuf       -- メッセージ
                      , 0               -- 改行
                      );
      gn_target_cnt :=  0;
      gn_normal_cnt :=  0;
      gn_skip_cnt   :=  0;
      gn_error_cnt  :=  1;
    END IF;
--
    -- ============================================================
    -- 対象件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90000
                    , cv_tkn_count
                    , TO_CHAR( gn_target_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- 成功件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90001
                    , cv_tkn_count
                    , TO_CHAR( gn_normal_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- スキップ件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90003
                    , cv_tkn_count
                    , TO_CHAR( gn_skip_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- ============================================================
    -- エラー件数出力
    -- ============================================================
    lv_out_msg  :=  xxccp_common_pkg.get_msg(
                      cv_appli_xxccp_name
                    , cv_msg_ccp_90002
                    , cv_tkn_count
                    , TO_CHAR( gn_error_cnt )
                    );
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 1                 -- 改行
                    );
--
    -- ============================================================
    -- 終了メッセージ
    -- ============================================================
    retcode :=  lv_retcode;
    IF  retcode   = cv_status_normal  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90004
                      );
    ELSIF retcode = cv_status_warn  THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90005
                      );
    ELSIF retcode = cv_status_error THEN
      lv_out_msg  :=  xxccp_common_pkg.get_msg(
                        cv_appli_xxccp_name
                      , cv_msg_ccp_90006
                      );
    END IF;
--
    lb_retcode  :=  xxcok_common_pkg.put_message_f( 
                      FND_FILE.OUTPUT   -- 出力区分
                    , lv_out_msg        -- メッセージ
                    , 0                 -- 改行
                    );
--
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF  retcode = cv_status_error THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN  global_api_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN  global_api_others_expt THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN  OTHERS THEN
      ROLLBACK;
      errbuf  :=  SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM, 1, 5000 );
      retcode :=  cv_status_error;
  END main;
END XXCOK024A38C;
/
