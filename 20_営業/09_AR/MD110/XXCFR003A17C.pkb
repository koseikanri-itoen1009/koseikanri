CREATE OR REPLACE PACKAGE BODY XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(body)
 * Description      : イセトー請求書データ作成
 * MD.050           : MD050_CFR_003_A17_イセトー請求書データ作成
 * MD.070           : MD050_CFR_003_A17_イセトー請求書データ作成
 * Version          : 1.10
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  insert_work_table      p ワークテーブルデータ登録                (A-3)
 *  chk_account_data       p 口座情報取得チェック                    (A-4)
 *  chk_line_cnt_limit     p 請求書明細件数チェック                  (A-5)
 *  csv_file_output        p ファイル出力処理                        (A-6)
 *  put_account_warning    p 顧客紐付け警告出力                      (A-7)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-23    1.00 SCS 白砂 幸世     新規作成
 *  2009-09-29    1.10 SCS 安川 智博     共通課題「IE535」対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt                CONSTANT VARCHAR2(3) := ',';
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gv_sep_msg       VARCHAR2(2000);
  gv_exec_user     VARCHAR2(100);
  gv_conc_name     VARCHAR2(30);
  gv_conc_status   VARCHAR2(30);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFR003A17C'; -- パッケージ名
  cv_msg_kbn_cmn      CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp      CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr      CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
--
  cv_msg_xxcfr_00010  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00010';            -- 共通関数エラーメッセージ
  cv_msg_xxcfr_00004  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00004';            -- プロファイル取得エラーメッセージ
  cv_msg_xxcfr_00024  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00024';            -- 取得データなしメッセージ
  cv_msg_xxcfr_00016  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00016';            -- テーブル挿入エラー
  cv_msg_xxcfr_00038  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00038';            -- 振込口座未登録メッセージ
  cv_msg_xxcfr_00051  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00051';            -- 振込口座未登録情報
  cv_msg_xxcfr_00052  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00052';            -- 振込口座未登録件数メッセージ
  cv_msg_xxcfr_00071  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00071';            -- 請求書明細件数制限メッセージ
  cv_msg_xxcfr_00072  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00072';            -- 請求書明細件数制限情報
  cv_msg_xxcfr_00056  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00056';            -- システムエラーメッセージ
-- Modify 2009-09-29 Ver1.10 Start  
  cv_msg_xxcfr_00079  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00079';            -- 請求書用顧客存在なしメッセージ
  cv_msg_xxcfr_00080  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00080';            -- 売掛管理先顧客存在なしメッセージ
  cv_msg_xxcfr_00081  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00081';            -- 顧客コード複数指定メッセージ
  cv_msg_xxcfr_00082  CONSTANT VARCHAR2(20)  := 'APP-XXCFR1-00082';            -- 統括請求書用顧客存在なしメッセージ
-- Modify 2009-09-29 Ver1.10 End
--
-- トークン
  cv_tkn_func         CONSTANT VARCHAR2(15)  := 'FUNC_NAME';                   -- 共通関数名
  cv_tkn_prof         CONSTANT VARCHAR2(15)  := 'PROF_NAME';                   -- プロファイル名
  cv_tkn_table        CONSTANT VARCHAR2(15)  := 'TABLE';                       -- テーブル名
  cv_tkn_ac_code      CONSTANT VARCHAR2(30)  := 'ACCOUNT_CODE';                -- 顧客コード
  cv_tkn_ac_name      CONSTANT VARCHAR2(30)  := 'ACCOUNT_NAME';                -- 顧客名
  cv_tkn_lc_name      CONSTANT VARCHAR2(30)  := 'KYOTEN_NAME';                 -- 拠点名
  cv_tkn_rec_limit    CONSTANT VARCHAR2(30)  := 'LINE_LIMIT';                  -- 制限レコード数
  cv_tkn_count        CONSTANT VARCHAR2(30)  := 'COUNT';                       -- カウント数
--
  -- 日本語辞書
  cv_dict_date_func   CONSTANT VARCHAR2(100) := 'CFR000A00003';                -- 日付パラメータ変換関数
  cv_dict_ymd4        CONSTANT VARCHAR2(100) := 'CFR000A00007';                -- YYYY"年"MM"月"DD"日"
  cv_dict_ymd2        CONSTANT VARCHAR2(100) := 'CFR000A00008';                -- YY"年"MM"月"DD"日"
  cv_dict_year        CONSTANT VARCHAR2(100) := 'CFR000A00009';                -- 年
  cv_dict_month       CONSTANT VARCHAR2(100) := 'CFR000A00010';                -- 月
  cv_dict_bank        CONSTANT VARCHAR2(100) := 'CFR000A00011';                -- 銀行
  cv_dict_central     CONSTANT VARCHAR2(100) := 'CFR000A00015';                -- 本店
  cv_dict_branch      CONSTANT VARCHAR2(100) := 'CFR000A00012';                -- 支店
  cv_dict_account     CONSTANT VARCHAR2(100) := 'CFR000A00013';                -- 普通
  cv_dict_current     CONSTANT VARCHAR2(100) := 'CFR000A00014';                -- 当座
  cv_dict_zip_mark    CONSTANT VARCHAR2(100) := 'CFR000A00016';                -- 〒
  cv_dict_bank_damy   CONSTANT VARCHAR2(100) := 'CFR000A00017';                -- 銀行ダミーコード
  cv_dict_csv_out     CONSTANT VARCHAR2(100) := 'CFR000A00018';                -- OUTファイル出力処理
--
  --プロファイル
  cv_line_cnt_limit   CONSTANT VARCHAR2(30)  := 'XXCFR1_LINE_CNT_LIMIT';       -- 制限明細数
-- Modify 2009-09-29 Ver1.10 Start
  cv_line_cnt_limit2  CONSTANT VARCHAR2(30)  := 'XXCFR1_LINE_CNT_LIMIT2';      -- 制限明細数
-- Modify 2009-09-29 Ver1.10 End
  cv_set_of_bks_id    CONSTANT VARCHAR2(30)  := 'GL_SET_OF_BKS_ID';            -- 会計帳簿ID
  cv_org_id           CONSTANT VARCHAR2(30)  := 'ORG_ID';                      -- 組織ID
--
  cv_tax_div_excluded CONSTANT VARCHAR2(1)   := '1';                           -- 消費税区分：外税
  cv_tax_div_nontax   CONSTANT VARCHAR2(1)   := '4';                           -- 消費税区分：非課税
  cv_out_div_included CONSTANT VARCHAR2(1)   := '1';                           -- 請求書出力区分：税込
  cv_out_div_excluded CONSTANT VARCHAR2(1)   := '2';                           -- 請求書出力区分：税抜
  cv_inv_prt_type     CONSTANT VARCHAR2(1)   := '4';                           -- 請求書出力形式：業者委託
--
  cv_table            CONSTANT VARCHAR2(100) := 'XXCFR_CSV_OUTS_TEMP';         -- ワークテーブル名
  cv_lookup_type_out  CONSTANT VARCHAR2(100) := 'XXCFR1_003A17_BILL_DATA_SET'; -- イセトー請求書データ作成用参照タイプ名
--
  cv_file_type_log    CONSTANT VARCHAR2(10)  := 'LOG';                         -- ログ出力
--
  cv_flag_yes         CONSTANT VARCHAR2(1)   := 'Y';                           -- 有効フラグ（Ｙ）
--
  cv_status_yes       CONSTANT VARCHAR2(1)   := '1';                           -- 有効ステータス（1：有効）
  cv_status_no        CONSTANT VARCHAR2(1)   := '0';                           -- 有効ステータス（0：無効）
--
  cv_format_date_ymd      CONSTANT VARCHAR2(8)   := 'YY/MM/DD';                    -- 日付フォーマット（2桁年月日スラッシュ付）
  cv_format_date_yyyymmdd CONSTANT VARCHAR2(8)   := 'YYYYMMDD';                    -- 日付フォーマット（YYYYMMDD）
--
  cv_max_date_value   CONSTANT VARCHAR2(10)  := '9999/12/31';                  -- 最大日付値
--
-- Modify 2009-09-29 Ver1.10 Start
  -- 顧客区分
  cv_customer_class_code14 CONSTANT VARCHAR2(2) := '14';      -- 顧客区分14(売掛管理先)
  cv_customer_class_code21 CONSTANT VARCHAR2(2) := '21';      -- 顧客区分21(統括請求書用)
  cv_customer_class_code20 CONSTANT VARCHAR2(2) := '20';      -- 顧客区分20(請求書用)
  cv_customer_class_code10 CONSTANT VARCHAR2(2) := '10';      -- 顧客区分10(顧客)
--
  -- 請求書印刷単位
  cv_invoice_printing_unit_a1 CONSTANT VARCHAR2(2) := '9';    -- 請求書印刷単位:'A1'
  cv_invoice_printing_unit_a2 CONSTANT VARCHAR2(2) := '8';    -- 請求書印刷単位:'A2'
  cv_invoice_printing_unit_a3 CONSTANT VARCHAR2(2) := '6';    -- 請求書印刷単位:'A3'
  cv_invoice_printing_unit_a4 CONSTANT VARCHAR2(2) := '7';    -- 請求書印刷単位:'A4'
  cv_invoice_printing_unit_a5 CONSTANT VARCHAR2(2) := '5';    -- 請求書印刷単位:'A5'
  cv_invoice_printing_unit_a6 CONSTANT VARCHAR2(2) := '4';    -- 請求書印刷単位:'A6'
  cv_invoice_printing_unit_n1 CONSTANT VARCHAR2(2) := '2';    -- 請求書印刷単位:'N1'
  cv_invoice_printing_unit_n2 CONSTANT VARCHAR2(2) := '3';    -- 請求書印刷単位:'N2'
  cv_invoice_printing_unit_n3 CONSTANT VARCHAR2(2) := '1';    -- 請求書印刷単位:'N3'
  cv_invoice_printing_unit_n4 CONSTANT VARCHAR2(2) := '0';    -- 請求書印刷単位:'N4'
--
  -- 使用目的
  cv_site_use_code_bill_to CONSTANT VARCHAR(10) := 'BILL_TO';  -- 使用目的：「請求先」
--
  -- 顧客関連処理対象ステータス
  cv_acct_relate_status    CONSTANT VARCHAR2(1) := 'A';
--
  -- 顧客関連
  cv_acct_relate_type_bill CONSTANT VARCHAR2(1) := '1';     -- 請求関連
--
  -- AFF部門値セット名
  cv_ffv_set_name_dept CONSTANT VARCHAR2(100) := 'XX03_DEPARTMENT';
--
  -- ヘッダ/明細区分
  cv_header_kbn   VARCHAR2(1) := '1'; -- ヘッダ
  cv_line_kbn     VARCHAR2(1) := '2'; -- 明細
--
  -- レコード区分
  cv_record_kbn0  VARCHAR2(1) := '0'; -- ヘッダレコード
  cv_record_kbn1  VARCHAR2(1) := '1'; -- 明細レコード
  cv_record_kbn2  VARCHAR2(1) := '2'; -- 店舗計レコード
--
  -- レイアウト区分
  cv_layout_kbn1  VARCHAR2(1) := '1'; -- 店舗別内訳なし
  cv_layout_kbn2  VARCHAR2(1) := '2'; -- 店舗別内訳あり
-- Modify 2009-09-29 Ver1.10 End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gd_target_date        DATE;                                      -- パラメータ．締日（データ型変換用）
  gn_line_cnt_limit     NUMBER;                                    -- 請求書明細件数制限(店舗別内訳なし)
-- Modify 2009-09-29 Ver1.10 Start
  gn_line_cnt_limit2    NUMBER;                                    -- 請求書明細件数制限(店舗別内訳あり)
-- Modify 2009-09-29 Ver1.10 End
  gn_org_id             NUMBER;                                    -- 組織ID
  gn_set_of_bks_id      NUMBER;                                    -- 会計帳簿ID
--
  -- 最大日付
  gd_max_date           DATE DEFAULT TO_DATE(cv_max_date_value, cv_format_date_ymd);
--
-- Modify 2009-09-29 Ver1.10 Start
  -- 顧客紐付け警告存在フラグ
  gv_warning_flag       VARCHAR2(1) := cv_status_no;
-- Modify 2009-09-29 Ver1.10 End
--
  -- 日本語辞書用変数
  gv_format_date_jpymd4  VARCHAR2(25); -- 書式整形用：YYYY"年"MM"月"DD"日"
  gv_format_date_jpymd2  VARCHAR2(25); -- 書式整形用：YY"年"MM"月"DD"日"
  gv_format_zip_mark     VARCHAR2(10); -- 〒
  gv_format_date_year    VARCHAR2(10); -- 年
  gv_format_date_month   VARCHAR2(10); -- 月
  gv_format_bank         VARCHAR2(10); -- 銀行
  gv_format_central      VARCHAR2(10); -- 本店
  gv_format_branch       VARCHAR2(10); -- 支店
  gv_format_account      VARCHAR2(10); -- 普通
  gv_format_current      VARCHAR2(10); -- 当座
  gv_format_bank_dummy   VARCHAR2(10); -- D%
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code14     IN      VARCHAR2,         -- 売掛管理先顧客
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    param_expt EXCEPTION;  -- 顧客コード複数指定例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log   -- ログ出力
                                   ,iv_conc_param1  => iv_target_date     -- コンカレントパラメータ１
                                   ,iv_conc_param2  => iv_customer_code10 -- コンカレントパラメータ２
                                   ,iv_conc_param3  => iv_customer_code20 -- コンカレントパラメータ３
                                   ,iv_conc_param4  => iv_customer_code21 -- コンカレントパラメータ４
                                   ,iv_conc_param5  => iv_customer_code14 -- コンカレントパラメータ５
                                   ,ov_errbuf       => ov_errbuf          -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode         -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);        -- ユーザー・エラー・メッセージ 
--
    -- パラメータ．締日をDATE型に変換する
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfr 
                                                   ,cv_msg_xxcfr_00010 -- 共通関数エラー
                                                   ,cv_tkn_func        -- トークン'機能名'
                                                   ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                      ,cv_dict_date_func))
                                                   -- 日付変換共通関数エラー
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009-09-29 Ver1.10 Start
    -- パラメータ顧客コードの指定数チェック 顧客コードは１つのみ指定していることをチェック
    IF (iv_customer_code14 IS NOT NULL) THEN
      IF (iv_customer_code21 IS NOT NULL)
      OR (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code21 IS NOT NULL) THEN
      IF (iv_customer_code20 IS NOT NULL)
      OR (iv_customer_code10 IS NOT NULL)
      THEN
        RAISE param_expt;
      END IF;
    ELSIF (iv_customer_code20 IS NOT NULL)
    AND   (iv_customer_code10 IS NOT NULL)
    THEN
      RAISE param_expt;
    END IF;
-- Modify 2009-09-29 Ver1.10 End
--
  EXCEPTION
    WHEN param_expt THEN
      ov_errmsg := xxccp_common_pkg.get_msg( iv_application  => cv_msg_kbn_cfr
                                            ,iv_name         => cv_msg_xxcfr_00081);
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_value(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_value'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- プロファイルから制限明細数を取得
    gn_line_cnt_limit := TO_NUMBER(FND_PROFILE.VALUE(cv_line_cnt_limit));
--
    IF (gn_line_cnt_limit IS NULL) THEN
      -- 取得エラー時
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン:プロファイル名
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_line_cnt_limit))
                                                     -- 制限明細数
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- Modify 2009-09-29 Ver1.10 Start
    -- プロファイルから制限明細数を取得
    gn_line_cnt_limit2 := TO_NUMBER(FND_PROFILE.VALUE(cv_line_cnt_limit2));
--
    IF (gn_line_cnt_limit2 IS NULL) THEN
      -- 取得エラー時
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン:プロファイル名
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_line_cnt_limit2))
                                                     -- 制限明細数
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- Modify 2009-09-29 Ver1.10 End
--
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE(cv_set_of_bks_id));
--
    IF (gn_set_of_bks_id IS NULL) THEN
      -- 取得エラー時
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン:プロファイル名
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- 会計帳簿ID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
--
    IF (gn_org_id IS NULL) THEN
      -- 取得エラー時
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr
                                                    ,cv_msg_xxcfr_00004 -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン:プロファイル名
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- 組織ID
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_profile_value;
--
-- Modify 2009-09-29 Ver1.10 Start
  /**********************************************************************************
   * Procedure Name   : put_account_warning(A-7)
   * Description      : 顧客紐付け警告出力 (A-7)
   ***********************************************************************************/
  PROCEDURE put_account_warning(
    iv_customer_class_code  IN   VARCHAR2,            -- 顧客区分
    iv_customer_code        IN   VARCHAR2,            -- 顧客コード
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_account_warning'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_data_msg  VARCHAR2(5000);        -- ログ出力メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
    -- 売掛管理先顧客存在なしメッセージ出力
    IF (iv_customer_class_code = cv_customer_class_code14) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_xxcfr_00080
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- 統括請求書用顧客存在なしメッセージ出力
    ELSIF (iv_customer_class_code = cv_customer_class_code21) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_xxcfr_00082
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    -- 請求書用顧客存在なしメッセージ出力
    ELSIF (iv_customer_class_code = cv_customer_class_code20) THEN
      lv_data_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_xxcfr_00079
                      ,iv_token_name1  => cv_tkn_ac_code
                      ,iv_token_value1 => iv_customer_code);
      fnd_file.put_line(
        which => FND_FILE.LOG
       ,buff  => lv_data_msg);
    END IF;
--
    -- 顧客紐付け警告存在フラグを存在ありに変更する
    gv_warning_flag := cv_status_yes;
--
--###########################  固定部 END   ############################
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
                           ,1
                           ,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_account_warning;
-- Modify 2009-09-29 Ver1.10 End
--
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ワークテーブルデータ登録 (A-3)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- 締日
    iv_customer_code10      IN   VARCHAR2,            -- 顧客
    iv_customer_code20      IN   VARCHAR2,            -- 請求書用顧客
    iv_customer_code21      IN   VARCHAR2,            -- 統括請求書用顧客
    iv_customer_code14      IN   VARCHAR2,            -- 売掛管理先顧客
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'insert_work_table'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
--
    ln_target_cnt   NUMBER := 0;    -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    lv_no_data_msg  VARCHAR2(5000); -- 帳票０件メッセージ
    lv_func_status  VARCHAR2(1);    -- SVF帳票共通関数(0件出力メッセージ)終了ステータス
--
    -- *** ローカル・カーソル ***
-- Modify 2009-09-29 Ver1.10 Start
    -- 顧客取得カーソルタイプ
    TYPE cursor_rec_type IS RECORD(customer_id           xxcmm_cust_accounts.customer_id%TYPE,           -- 顧客区分10顧客ID
                                   customer_code         xxcmm_cust_accounts.customer_code%TYPE,         -- 顧客区分10顧客コード
                                   invoice_printing_unit xxcmm_cust_accounts.invoice_printing_unit%TYPE, -- 顧客区分10請求書印刷単位
                                   bill_base_code        xxcmm_cust_accounts.bill_base_code%TYPE);       -- 顧客区分10請求拠点コード
    TYPE cursor_ref_type IS REF CURSOR;
    get_all_account_cur cursor_ref_type;
    all_account_rec cursor_rec_type;
--
    -- 顧客10取得カーソル文字列
    cv_get_all_account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||            -- 顧客ID
    '       xxca.customer_code         AS customer_code, '||          -- 顧客コード
    '        xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
    '        xxca.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    ' FROM xxcmm_cust_accounts xxca, '||                                     -- 顧客追加情報
    '      hz_cust_accounts    hzca '||                                      -- 顧客マスタ
    ' WHERE hzca.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
    ' AND   xxca.customer_id = hzca.cust_account_id ';
--
    -- 顧客10取得カーソル文字列(売掛管理先顧客指定時)
    cv_get_14account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     hz_cust_accounts    hzca10, '||                                     -- 顧客10顧客マスタ
    '     hz_cust_acct_sites  hasa10, '||                                     -- 顧客10顧客所在地
    '     hz_cust_site_uses   hsua10, '||                                     -- 顧客10顧客使用目的
    '     hz_cust_accounts    hzca14, '||                                     -- 顧客14顧客マスタ
    '     hz_cust_acct_relate hcar14, '||                                     -- 顧客関連マスタ
    '     hz_cust_acct_sites  hasa14, '||                                     -- 顧客14顧客所在地
    '     hz_cust_site_uses   hsua14 '||                                      -- 顧客14顧客使用目的
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a1||''','||
                                           ''''||cv_invoice_printing_unit_a2||''','||
                                           ''''||cv_invoice_printing_unit_a3||''','||
                                           ''''||cv_invoice_printing_unit_a4||''','||
                                           ''''||cv_invoice_printing_unit_a5||''','||
                                           ''''||cv_invoice_printing_unit_a6||''','||
                                           ''''||cv_invoice_printing_unit_n1||''','||
                                           ''''||cv_invoice_printing_unit_n2||''','||
                                           ''''||cv_invoice_printing_unit_n3||''') '|| -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||         -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   hzca14.account_number = :iv_customer_code14 '||
    'AND   hzca14.cust_account_id = hcar14.cust_account_id '||
    'AND   hcar14.related_cust_account_id = hzca10.cust_account_id '||
    'AND   hzca14.customer_class_code = '''||cv_customer_class_code14||''' '||
    'AND   hcar14.status = '''||cv_acct_relate_status||''' '||
    'AND   hcar14.attribute1 = '''||cv_acct_relate_type_bill||''' '||
    'AND   hzca14.cust_account_id = hasa14.cust_account_id '||
    'AND   hasa14.cust_acct_site_id = hsua14.cust_acct_site_id '||
    'AND   hsua14.site_use_code = '''||cv_site_use_code_bill_to||''' '||
    'AND   hzca10.cust_account_id = hasa10.cust_account_id '||
    'AND   hasa10.cust_acct_site_id = hsua10.cust_acct_site_id '||
    'AND   hsua10.bill_to_site_use_id = hsua14.site_use_id ';
--
    -- 顧客10取得カーソル文字列(統括請求書用顧客指定時)
    cv_get_21account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     xxcmm_cust_accounts xxca21, '||                                     -- 顧客21顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a2||''','||
                                           ''''||cv_invoice_printing_unit_a4||''') '|| -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||          -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.enclose_invoice_code = xxca21.customer_code '||
    'AND   xxca21.customer_code = :iv_customer_code21 ';
--
    -- 顧客10取得カーソル文字列(請求書用顧客指定時)
    cv_get_20account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca10.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca10.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca10.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
    '       xxca10.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca10, '||                                     -- 顧客10顧客追加情報
    '     xxcmm_cust_accounts xxca20, '||                                     -- 顧客20顧客追加情報
    '     hz_cust_accounts    hzca10 '||                                      -- 顧客10顧客マスタ
    'WHERE xxca10.invoice_printing_unit IN ('''||cv_invoice_printing_unit_a3||''','||
                                           ''''||cv_invoice_printing_unit_a6||''','||
                                           ''''||cv_invoice_printing_unit_n3||''') '||   -- 請求書印刷単位
    'AND   hzca10.customer_class_code = '''||cv_customer_class_code10||''' '||           -- 顧客区分:10
    'AND   xxca10.customer_id = hzca10.cust_account_id '||
    'AND   xxca10.invoice_code = xxca20.customer_code '||
    'AND   xxca20.customer_code = :iv_customer_code20 ';
--
    -- 顧客10取得カーソル文字列(顧客指定時)
    cv_get_10account_cur   CONSTANT VARCHAR2(3000) := 
    'SELECT xxca.customer_id           AS customer_id, '||           -- 顧客ID
    '       xxca.customer_code         AS customer_code, '||         -- 顧客コード
    '       xxca.invoice_printing_unit AS invoice_printing_unit, '|| -- 請求書印刷単位
    '       xxca.bill_base_code        AS bill_base_code '||         -- 請求拠点コード
    'FROM xxcmm_cust_accounts xxca, '||                                     -- 顧客追加情報
    '     hz_cust_accounts    hzca '||                                      -- 顧客マスタ
    'WHERE xxca.invoice_printing_unit = '''||cv_invoice_printing_unit_n4||''' '||       -- 請求書印刷単位
    'AND   hzca.customer_class_code = '''||cv_customer_class_code10||''' '||            -- 顧客区分:10
    'AND   xxca.customer_id = hzca.cust_account_id '||
    'AND   xxca.customer_code = :iv_customer_code10 ';
--
    -- 顧客14取得カーソル
    CURSOR get_14account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT bill_hzca_1.cust_account_id         AS cash_account_id,         --顧客14ID
            bill_hzca_1.account_number          AS cash_account_number,     --顧客14コード
            bill_hzpa_1.party_name              AS cash_account_name,       --顧客14顧客名
            ship_hzca_1.cust_account_id         AS ship_account_id,         --顧客10顧客ID        
            ship_hzca_1.account_number          AS ship_account_number,     --顧客10顧客コード 
            bill_hzad_1.bill_base_code          AS bill_base_code,          --顧客14請求拠点コード
            bill_hzlo_1.postal_code             AS bill_postal_code,        --顧客14郵便番号            
            bill_hzlo_1.state                   AS bill_state,              --顧客14都道府県            
            bill_hzlo_1.city                    AS bill_city,               --顧客14市・区              
            bill_hzlo_1.address1                AS bill_address1,           --顧客14住所1               
            bill_hzlo_1.address2                AS bill_address2,           --顧客14住所2
            bill_hzlo_1.address_lines_phonetic  AS phone_num,               --顧客14電話番号
            bill_hzad_1.tax_div                 AS bill_tax_div,            --顧客14消費税区分
            bill_hsua_1.attribute7              AS bill_invoice_type,       --顧客14請求書出力形式      
            bill_hsua_1.payment_term_id         AS bill_payment_term_id,    --顧客14支払条件
            bill_hzcp_1.cons_inv_flag           AS cons_inv_flag            --顧客14一括請求書発行フラグ
     FROM hz_cust_accounts          bill_hzca_1,              --顧客14顧客マスタ
          hz_cust_accounts          ship_hzca_1,              --顧客10顧客マスタ
          xxcmm_cust_accounts       bill_hzad_1,              --顧客14顧客追加情報
          hz_cust_acct_sites        bill_hasa_1,              --顧客14顧客所在地
          hz_locations              bill_hzlo_1,              --顧客14顧客事業所
          hz_cust_site_uses         bill_hsua_1,              --顧客14顧客使用目的
          hz_customer_profiles      bill_hzcp_1,              --顧客14プロファイル
          hz_cust_acct_relate       bill_hcar_1,              --顧客関連マスタ(請求関連)
          hz_cust_acct_sites        ship_hasa_1,              --顧客10顧客所在地
          hz_cust_site_uses         ship_hsua_1,              --顧客10顧客使用目的
          hz_party_sites            bill_hzps_1,              --顧客14パーティサイト
          hz_parties                bill_hzpa_1               --顧客14パーティ
     WHERE ship_hzca_1.cust_account_id = iv_customer_id
     AND   bill_hzca_1.cust_account_id = bill_hcar_1.cust_account_id         --顧客14顧客マスタ.顧客ID = 顧客関連マスタ.顧客ID
     AND   bill_hcar_1.related_cust_account_id = ship_hzca_1.cust_account_id --顧客関連マスタ.関連先顧客ID = 顧客10顧客マスタ.顧客ID
     AND   bill_hzca_1.customer_class_code = cv_customer_class_code14        --顧客14顧客マスタ.顧客区分 = '14'(売掛管理先顧客)
     AND   bill_hcar_1.status = cv_acct_relate_status                        --顧客関連マスタ.ステータス = ‘A’
     AND   bill_hcar_1.attribute1 = cv_acct_relate_type_bill                 --顧客関連マスタ.関連分類 = ‘1’ (請求)
     AND   bill_hzca_1.cust_account_id = bill_hzad_1.customer_id             --顧客14顧客マスタ.顧客ID = 顧客14顧客追加情報.顧客ID
     AND   bill_hzca_1.cust_account_id = bill_hasa_1.cust_account_id         --顧客14顧客マスタ.顧客ID = 顧客14顧客所在地.顧客ID
     AND   bill_hasa_1.cust_acct_site_id = bill_hsua_1.cust_acct_site_id     --顧客14顧客所在地.顧客所在地ID = 顧客14顧客使用目的.顧客所在地ID
     AND   bill_hsua_1.site_use_code = cv_site_use_code_bill_to              --顧客14顧客使用目的.使用目的 = 'BILL_TO'(請求先)
     AND   bill_hzcp_1.cust_account_id = bill_hzca_1.cust_account_id         --顧客14プロファイル.顧客ID = 顧客14顧客マスタ.顧客ID
     AND   bill_hzcp_1.site_use_id = bill_hsua_1.site_use_id                 --顧客14プロファイル.使用目的ID = 顧客14顧客使用目的.使用目的ID
     AND   ship_hzca_1.cust_account_id = ship_hasa_1.cust_account_id         --顧客10顧客マスタ.顧客ID = 顧客10顧客所在地.顧客ID
     AND   ship_hasa_1.cust_acct_site_id = ship_hsua_1.cust_acct_site_id     --顧客10顧客所在地.顧客所在地ID = 顧客10顧客使用目的.顧客所在地ID
     AND   ship_hsua_1.bill_to_site_use_id = bill_hsua_1.site_use_id         --顧客10顧客使用目的.請求先事業所ID = 顧客14顧客使用目的.使用目的ID
     AND   bill_hasa_1.party_site_id = bill_hzps_1.party_site_id             --顧客14顧客所在地.パーティサイトID = 顧客14パーティサイト.パーティサイトID  
     AND   bill_hzps_1.location_id = bill_hzlo_1.location_id                 --顧客14パーティサイト.事業所ID = 顧客14顧客事業所.事業所ID                  
     AND   bill_hzca_1.party_id = bill_hzpa_1.party_id;                      --顧客14顧客マスタ.パーティID = 顧客14.パーティID
--
    get_14account_rec get_14account_cur%ROWTYPE;
--
    -- 顧客21取得カーソル
    CURSOR get_21account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT xxca21.customer_id                  AS bill_account_id,         --顧客21ID
            xxca21.customer_code                AS bill_account_number,     --顧客21コード
            hzpa21.party_name                   AS bill_account_name,       --顧客21顧客名
            xxca21.bill_base_code               AS bill_base_code21,        --顧客21請求拠点コード
            hzlo21.postal_code                  AS bill_postal_code,        --顧客21郵便番号
            hzlo21.state                        AS bill_state,              --顧客21都道府県
            hzlo21.city                         AS bill_city,               --顧客21市・区
            hzlo21.address1                     AS bill_address1,           --顧客21住所1
            hzlo21.address2                     AS bill_address2,           --顧客21住所2
            hzlo21.address_lines_phonetic       AS phone_num,               --顧客21電話番号
            xxca20.bill_base_code               AS bill_base_code20         --顧客20請求拠点コード
     FROM xxcmm_cust_accounts       xxca21,                   --顧客21顧客追加情報
          xxcmm_cust_accounts       xxca20,                   --顧客20顧客追加情報
          xxcmm_cust_accounts       xxca10,                   --顧客10顧客追加情報
          hz_cust_accounts          hzca20,                   --顧客20顧客マスタ
          hz_cust_accounts          hzca21,                   --顧客21顧客マスタ
          hz_parties                hzpa21,                   --顧客21パーティ
          hz_cust_acct_sites        hcas21,                   --顧客21顧客所在地
          hz_party_sites            hzps21,                   --顧客21パーティサイト
          hz_locations              hzlo21                    --顧客21顧客事業所
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --顧客10顧客追加情報.請求書用コード = 顧客20顧客追加情報.顧客コード
     AND   xxca20.enclose_invoice_code = xxca21.customer_code                --顧客20顧客追加情報.統括請求書用コード = 顧客21顧客追加情報.顧客コード
     AND   hzca20.customer_class_code = cv_customer_class_code20             --顧客20顧客マスタ.顧客区分 = '20'(請求書用)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --顧客20顧客マスタ.顧客ID = 顧客20顧客追加情報.顧客コード
     AND   hzca21.customer_class_code = cv_customer_class_code21             --顧客21顧客マスタ.顧客区分 = '21'(統括請求書用)
     AND   hzca21.cust_account_id = xxca21.customer_id                       --顧客21顧客マスタ.顧客ID = 顧客21顧客追加情報.顧客コード
     AND   hzca21.party_id = hzpa21.party_id                                 --顧客21顧客マスタ.パーティID = 顧客21パーティ.パーティID
     AND   hzca21.cust_account_id = hcas21.cust_account_id                   --顧客21顧客マスタ.顧客ID = 顧客21所在地.顧客ID
     AND   hcas21.party_site_id = hzps21.party_site_id                       --顧客所在地21.パーティサイト = 顧客21パーティサイト.顧客21パーティサイトID
     AND   hzps21.location_id = hzlo21.location_id;                          --顧客21パーティサイト.事業所ID = 顧客21顧客事業所.事業所ID
--
    get_21account_rec get_21account_cur%ROWTYPE;
--
    -- 顧客20取得カーソル
    CURSOR get_20account_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT xxca20.customer_id                  AS bill_account_id,         --顧客20ID
            xxca20.customer_code                AS bill_account_number,     --顧客20コード
            hzpa20.party_name                   AS bill_account_name,       --顧客20顧客名
            xxca20.bill_base_code               AS bill_base_code,          --顧客20請求拠点コード
            hzlo20.postal_code                  AS bill_postal_code,        --顧客20郵便番号
            hzlo20.state                        AS bill_state,              --顧客20都道府県
            hzlo20.city                         AS bill_city,               --顧客20市・区
            hzlo20.address1                     AS bill_address1,           --顧客20住所1
            hzlo20.address2                     AS bill_address2,           --顧客20住所2
            hzlo20.address_lines_phonetic       AS phone_num                --顧客20電話番号
     FROM xxcmm_cust_accounts       xxca20,                   --顧客20顧客追加情報
          xxcmm_cust_accounts       xxca10,                   --顧客10顧客追加情報
          hz_cust_accounts          hzca20,                   --顧客20顧客マスタ
          hz_parties                hzpa20,                   --顧客20パーティ
          hz_cust_acct_sites        hcas20,                   --顧客20顧客所在地
          hz_party_sites            hzps20,                   --顧客20パーティサイト
          hz_locations              hzlo20                    --顧客20顧客事業所
     WHERE xxca10.customer_id = iv_customer_id
     AND   xxca10.invoice_code = xxca20.customer_code                        --顧客10顧客追加情報.請求書用コード = 顧客20顧客追加情報.顧客コード
     AND   hzca20.customer_class_code = cv_customer_class_code20             --顧客20顧客マスタ.顧客区分 = '20'(請求書用)
     AND   hzca20.cust_account_id = xxca20.customer_id                       --顧客20顧客マスタ.顧客ID = 顧客20顧客追加情報.顧客コード
     AND   hzca20.party_id = hzpa20.party_id                                 --顧客20顧客マスタ.パーティID = 顧客20パーティ.パーティID
     AND   hzca20.cust_account_id = hcas20.cust_account_id                   --顧客20顧客マスタ.顧客ID = 顧客20所在地.顧客ID
     AND   hcas20.party_site_id = hzps20.party_site_id                       --顧客所在地20.パーティサイト = 顧客20パーティサイト.顧客20パーティサイトID
     AND   hzps20.location_id = hzlo20.location_id;                          --顧客20パーティサイト.事業所ID = 顧客20顧客事業所.事業所ID
--
    get_20account_rec get_20account_cur%ROWTYPE;
--
    -- 単独店請求書出力形式取得カーソル
    CURSOR get_10inv_type_cur(
      iv_customer_id IN NUMBER) -- 顧客区分10の顧客ID
    IS
     SELECT hsua.attribute7    AS invoice_type, -- 請求書出力形式
            hcpa.cons_inv_flag AS cons_inv_flag -- 一括請求書発行フラグ
     FROM hz_cust_acct_sites      hasa,      -- 顧客10顧客所在地
          hz_cust_site_uses       hsua,      -- 顧客10使用目的
          hz_customer_profiles    hcpa       -- 顧客10プロファイル
     WHERE hasa.cust_account_id = iv_customer_id
       AND hsua.cust_acct_site_id = hasa.cust_acct_site_id  -- 顧客10使用目的.顧客所在地ID = 顧客10顧客所在地.顧客所在地ID
       AND hsua.site_use_code = cv_site_use_code_bill_to    -- 顧客10顧客使用目的.使用目的 = 'BILL_TO'(請求先)
       AND hsua.attribute7 = cv_inv_prt_type                -- 顧客10顧客使用目的.請求書出力形式 = '4'(業者委託)
       AND hcpa.cons_inv_flag = cv_flag_yes                 -- 顧客10一括請求書発行フラグ = 'Y'
       AND hcpa.cust_account_id = iv_customer_id
       AND hcpa.site_use_id = hsua.site_use_id;             -- 顧客10プロファイル.使用目的ID = 顧客10使用目的.使用目的ID
--
    get_10inv_type_rec get_10inv_type_cur%ROWTYPE;
--
-- Modify 2009-09-29 Ver1.10 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================================
    -- 日本語文字列取得
    -- ====================================================
    gv_format_date_jpymd4  := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_ymd4)      -- YYYY"年"MM"月"DD"日"
                                     ,1
                                     ,5000);
    --
    gv_format_date_jpymd2  := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_ymd2)      -- YY"年"MM"月"DD"日"
                                     ,1
                                     ,5000);
    --
    gv_format_zip_mark     := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_zip_mark)  -- 〒
                                     ,1
                                     ,5000);
    --
    gv_format_date_year    := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_year)      -- 年
                                     ,1
                                     ,5000);
    --
    gv_format_date_month   := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_month)     -- 月
                                     ,1
                                     ,5000);
    --
    gv_format_bank         := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_bank)      -- 銀行
                                     ,1
                                     ,5000);
    --
    gv_format_central      := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_central)   -- 本店
                                     ,1
                                     ,5000);
    --
    gv_format_branch       := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_branch)    -- 支店
                                     ,1
                                     ,5000);
    --
    gv_format_account      := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_account)   -- 普通
                                     ,1
                                     ,5000);
    --
    gv_format_current      := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_current)   -- 当座
                                     ,1
                                     ,5000);
    --
    gv_format_bank_dummy   := SUBSTRB(xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                        ,cv_dict_bank_damy) -- D
                                     ,1
                                     ,5000);
--
    -- ====================================================
    -- ワークテーブルへの登録
    -- ====================================================
    BEGIN
--
-- Modify 2009-09-29 Ver1.10 Start
      -- 売掛管理先顧客指定時
      IF (iv_customer_code14 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_14account_cur USING iv_customer_code14;
      -- 統括請求書用顧客指定時
      ELSIF (iv_customer_code21 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_21account_cur USING iv_customer_code21;
      -- 請求書用顧客指定時
      ELSIF (iv_customer_code20 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_20account_cur USING iv_customer_code20;
      -- 顧客指定時
      ELSIF (iv_customer_code10 IS NOT NULL) THEN
        OPEN get_all_account_cur FOR cv_get_10account_cur USING iv_customer_code10;
      -- パラメータ指定なし時
      ELSE
        OPEN get_all_account_cur FOR cv_get_all_account_cur;
      END IF;
--
      <<get_account10_loop>>
      LOOP
        FETCH get_all_account_cur INTO all_account_rec;
        EXIT WHEN get_all_account_cur%NOTFOUND;
--
        -- 請求書印刷単位が'N4'(単独店)以外の場合、
        -- 顧客区分10の顧客に紐づく、顧客区分14の顧客を取得
        IF (all_account_rec.invoice_printing_unit <> cv_invoice_printing_unit_n4) THEN
          OPEN get_14account_cur(all_account_rec.customer_id);
          FETCH get_14account_cur INTO get_14account_rec;
--
          -- 紐づく顧客区分14の顧客が存在しない場合
          IF (get_14account_cur%NOTFOUND) THEN
            -- 顧客区分14存在なしメッセージ出力
            put_account_warning(iv_customer_class_code => cv_customer_class_code14
                               ,iv_customer_code       => all_account_rec.customer_code
                               ,ov_errbuf              => lv_errbuf
                               ,ov_retcode             => lv_retcode
                               ,ov_errmsg              => lv_errmsg);
            IF (lv_retcode = cv_status_error) THEN
              --(エラー処理)
              RAISE global_process_expt;
            END IF;
          -- 請求書印刷単位 IN ('A1','A5') 売掛管理先顧客でまとめる
          ELSIF (all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a1,cv_invoice_printing_unit_a5))
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 4.業者委託
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- 一括請求書発行フラグ = 'Y'
          THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- 要求ID
             ,seq              -- 出力順
             ,col1             -- ヘッダ/明細区分
             ,col2             -- レコード区分
             ,col3             -- 発行日付
             ,col4             -- 郵便番号
             ,col5             -- 住所１
             ,col6             -- 住所２
             ,col7             -- 住所３
             ,col8             -- 顧客コード
             ,col9             -- 顧客名
             ,col10            -- 担当拠点名
             ,col11            -- 電話番号
             ,col12            -- 対象年月
             ,col13            -- 売掛管理コード連結文字列
             ,col14            -- 請求書出力区分
             ,col15            -- 当月お買い上げ額
             ,col16            -- 消費税等
             ,col17            -- 当月請求額
             ,col18            -- 入金予定日
             ,col19            -- 振込先銀行名
             ,col20            -- 振込先銀行支店名
             ,col21            -- 振込先口座種別
             ,col22            -- 振込先口座番号
             ,col23            -- 振込先口座名義人カナ名
             ,col24            -- 店舗コード
             ,col25            -- 店舗名
             ,col26            -- 伝票日付
             ,col27            -- 伝票No
             ,col28            -- 伝票金額
             ,col29            -- レイアウト区分
             ,col101           -- 伝票税抜額(非出力項目)
             ,col102           -- 伝票税額(非出力項目)
             ,col103           -- 入金先顧客コード(非出力項目)
             ,col104)          -- 入金先顧客名(非出力項目)
            SELECT cn_request_id                                              request_id         -- 要求ID
                  ,TO_NUMBER(NULL)                                            seq                -- 出力順
                  ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                  ,cv_record_kbn1                                             record_kbn         -- レコード区分
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                  ,NULL                                                       zip_code           -- 郵便番号
                  ,NULL                                                       send_address1      -- 住所１
                  ,NULL                                                       send_address2      -- 住所２
                  ,NULL                                                       send_address3      -- 住所３
                  ,get_14account_rec.cash_account_number                      bill_cust_code     -- 顧客コード
                  ,NULL                                                       bill_cust_name     -- 顧客名
                  ,NULL                                                       location_name      -- 拠点名
                  ,NULL                                                       phone_num          -- 電話番号
                  ,xih.object_month                                           object_month       -- 対象年月
                  ,get_14account_rec.cash_account_number||' '||xih.term_name  ar_concat_text     -- 売掛管理コード連結文字列
                  ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                        ,cv_tax_div_nontax,cv_out_div_excluded
                                                                          ,cv_out_div_included)
                                                                              out_put_div        -- 請求書出力区分
                  ,NULL                                                       inv_amount         -- 当月お買い上げ額
                  ,NULL                                                       tax_amount         -- 消費税等
                  ,NULL                                                       total_amount       -- 当月請求額
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                             ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                   END                                                        banc_number        -- 銀行名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,CASE WHEN INSTR(bank.bank_branch_name
                                           ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                   END                                                        bank_branch_number -- 支店名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                   END                                                        bank_account_type  -- 口座種別
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,bank.bank_account_num)
                   END                                                        bank_account_num   -- 口座番号
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,bank.account_holder_name_alt)
                   END                                                        bank_account_name  -- 口座名義人カナ名
                  ,xil.ship_cust_code                                         ship_cust_code     -- 店舗コード
                  ,hzp.party_name                                             ship_cust_name     -- 店舗名
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                 ,xil.delivery_date
                                 ,xil.acceptance_date)
                                 ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                  ,xil.slip_num                                                     slip_num     -- 伝票番号
                  ,SUM(CASE
                       WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                              ,cv_tax_div_excluded)
                       THEN
                            xil.ship_amount
                       ELSE
                            xil.tax_amount + xil.ship_amount
                       END)                                                         slip_sum          -- 伝票金額
                  ,cv_layout_kbn2                                                   layout_kbn        -- レイアウト区分
                  ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- 伝票税抜額
                  ,SUM(xil.tax_amount)                                              slip_tax          -- 伝票税額
                  ,get_14account_rec.cash_account_number                            payment_cust_code -- 入金先顧客コード
                  ,get_14account_rec.cash_account_name                              payment_cust_name -- 入金先顧客名
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                 hz_parties                     hzp  , -- 顧客10パーティマスタ
                 (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                        ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                        ,ap_bank_accounts_all           abaa                 --銀行口座
                        ,ap_bank_branches               abb                  --銀行支店
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  get_14account_rec.cash_account_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND hzca.cust_account_id = all_account_rec.customer_id
              AND hzp.party_id = hzca.party_id
            GROUP BY xih.inv_creation_date,                                               -- 発行日付
                     xih.object_month,                                                    -- 対象年月
                     xih.term_name,                                                       -- 支払条件
                     xih.payment_date,                                                    -- 入金予定日
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END,                                                                 -- 銀行名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END,                                                                 -- 支店名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END,                                                                 -- 口座種別
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END,                                                                 -- 口座番号
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- 口座名義人カナ名
                     xil.ship_cust_code,                                                  -- 店舗コード
                     hzp.party_name,                                                      -- 店舗名
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- 伝票日付
                     xil.slip_num;                                                        -- 伝票番号
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          -- 請求書印刷単位 IN ('A2','A4') 統括請求書用顧客でまとめる
          ELSIF (all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a2,cv_invoice_printing_unit_a4))
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 4.業者委託
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- 一括請求書発行フラグ = 'Y'
          THEN
            OPEN get_21account_cur(all_account_rec.customer_id);
            FETCH get_21account_cur INTO get_21account_rec;
--
            --顧客区分21の顧客が存在しない場合
            IF get_21account_cur%NOTFOUND THEN
              -- 顧客区分21存在なしメッセージ出力
              put_account_warning(iv_customer_class_code => cv_customer_class_code21
                                 ,iv_customer_code       => all_account_rec.customer_code
                                 ,ov_errbuf              => lv_errbuf
                                 ,ov_retcode             => lv_retcode
                                 ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                RAISE global_process_expt;
              END IF;
            ELSE
              INSERT INTO xxcfr_csv_outs_temp(
                request_id       -- 要求ID
               ,seq              -- 出力順
               ,col1             -- ヘッダ/明細区分
               ,col2             -- レコード区分
               ,col3             -- 発行日付
               ,col4             -- 郵便番号
               ,col5             -- 住所１
               ,col6             -- 住所２
               ,col7             -- 住所３
               ,col8             -- 顧客コード
               ,col9             -- 顧客名
               ,col10            -- 担当拠点名
               ,col11            -- 電話番号
               ,col12            -- 対象年月
               ,col13            -- 売掛管理コード連結文字列
               ,col14            -- 請求書出力区分
               ,col15            -- 当月お買い上げ額
               ,col16            -- 消費税等
               ,col17            -- 当月請求額
               ,col18            -- 入金予定日
               ,col19            -- 振込先銀行名
               ,col20            -- 振込先銀行支店名
               ,col21            -- 振込先口座種別
               ,col22            -- 振込先口座番号
               ,col23            -- 振込先口座名義人カナ名
               ,col24            -- 店舗コード
               ,col25            -- 店舗名
               ,col26            -- 伝票日付
               ,col27            -- 伝票No
               ,col28            -- 伝票金額
               ,col29            -- レイアウト区分
               ,col101           -- 伝票税抜額(非出力項目)
               ,col102           -- 伝票税額(非出力項目)
               ,col103           -- 入金先顧客コード(非出力項目)
               ,col104)          -- 入金先顧客名(非出力項目)
              SELECT cn_request_id                                              request_id         -- 要求ID
                    ,TO_NUMBER(NULL)                                            seq                -- 出力順
                    ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                    ,cv_record_kbn1                                             record_kbn         -- レコード区分
                    ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                    ,NULL                                                       zip_code           -- 郵便番号
                    ,NULL                                                       send_address1      -- 住所１
                    ,NULL                                                       send_address2      -- 住所２
                    ,NULL                                                       send_address3      -- 住所３
                    ,get_21account_rec.bill_account_number                      bill_cust_code     -- 顧客コード
                    ,NULL                                                       bill_cust_name     -- 顧客名
                    ,NULL                                                       location_name      -- 拠点名
                    ,NULL                                                       phone_num          -- 電話番号
                    ,xih.object_month                                           object_month       -- 対象年月
                    ,get_21account_rec.bill_account_number||' '||xih.term_name  ar_concat_text     -- 売掛管理コード連結文字列
                    ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                          ,cv_tax_div_nontax,cv_out_div_excluded
                                                                            ,cv_out_div_included)
                                                                                out_put_div        -- 請求書出力区分
                    ,NULL                                                       inv_amount         -- 当月お買い上げ額
                    ,NULL                                                       tax_amount         -- 消費税等
                    ,NULL                                                       total_amount       -- 当月請求額
                    ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END                                                        banc_number        -- 銀行名
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END                                                        bank_branch_number -- 支店名
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END                                                        bank_account_type  -- 口座種別
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END                                                        bank_account_num   -- 口座番号
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END                                                        bank_account_name  -- 口座名義人カナ名
                    ,xxca.invoice_code                                          ship_cust_code     -- 店舗コード
                    ,hzp.party_name                                             ship_cust_name     -- 店舗名
                    ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                    ,xil.slip_num                                                     slip_num     -- 伝票番号
                    ,SUM(CASE
                         WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                                ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                                         slip_sum          -- 伝票金額
                    ,cv_layout_kbn2                                                   layout_kbn        -- レイアウト区分
                    ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- 伝票税抜額
                    ,SUM(xil.tax_amount)                                              slip_tax          -- 伝票税額
                    ,get_14account_rec.cash_account_number                            payment_cust_code -- 入金先顧客コード
                    ,get_14account_rec.cash_account_name                              payment_cust_name -- 入金先顧客名
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   hz_cust_accounts               hzca , -- 顧客20顧客マスタ
                   hz_parties                     hzp  , -- 顧客20パーティマスタ
                   xxcmm_cust_accounts            xxca , -- 顧客10追加情報
                   (SELECT all_account_rec.customer_code ship_cust_code
                          ,rcrm.customer_id             customer_id
                          ,abb.bank_number              bank_number
                          ,abb.bank_name                bank_name
                          ,abb.bank_branch_name         bank_branch_name
                          ,abaa.bank_account_type       bank_account_type
                          ,abaa.bank_account_num        bank_account_num
                          ,abaa.account_holder_name     account_holder_name
                          ,abaa.account_holder_name_alt account_holder_name_alt
                    FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                          ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                          ,ap_bank_accounts_all           abaa                 --銀行口座
                          ,ap_bank_branches               abb                  --銀行支店
                    WHERE  rcrm.primary_flag      = cv_flag_yes
                      AND  get_14account_rec.cash_account_id = rcrm.customer_id
                      AND  gd_target_date   BETWEEN rcrm.start_date
                                                AND NVL(rcrm.end_date, gd_max_date)
                      AND  rcrm.site_use_id      IS NOT NULL
                      AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND  arma.bank_account_id   = abaa.bank_account_id(+)
                      AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                      AND  arma.org_id            = gn_org_id
                      AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
              WHERE xih.invoice_id = xil.invoice_id
                AND xil.cutoff_date = gd_target_date
                AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND xxca.customer_id = all_account_rec.customer_id
                AND hzca.account_number = xxca.invoice_code
                AND hzp.party_id = hzca.party_id
              GROUP BY xih.inv_creation_date,                                               -- 発行日付
                       xih.object_month,                                                    -- 対象年月
                       xih.term_name,                                                       -- 支払条件
                       xih.payment_date,                                                    -- 入金予定日
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name 
                                END)
                       END,                                                                 -- 銀行名
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END)
                       END,                                                                 -- 支店名
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type))
                       END,                                                                 -- 口座種別
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,bank.bank_account_num)
                       END,                                                                 -- 口座番号
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,bank.account_holder_name_alt)
                       END,                                                                 -- 口座名義人カナ名
                       xxca.invoice_code,                                                   -- 店舗コード
                       hzp.party_name,                                                      -- 店舗名
                       TO_CHAR(DECODE(xil.acceptance_date,NULL
                                     ,xil.delivery_date
                                     ,xil.acceptance_date)
                                     ,cv_format_date_yyyymmdd),                             -- 伝票日付
                       xil.slip_num;                                                        -- 伝票番号
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            END IF;
--
            CLOSE get_21account_cur;
--
          -- 請求書印刷単位 IN ('A3','A6') 請求書用顧客でまとめる
          ELSIF (all_account_rec.invoice_printing_unit IN (cv_invoice_printing_unit_a3,cv_invoice_printing_unit_a6))
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 4.業者委託
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- 一括請求書発行フラグ
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --顧客区分20の顧客が存在しない場合
            IF get_20account_cur%NOTFOUND THEN
              -- 顧客区分20存在なしメッセージ出力
              put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                  ,iv_customer_code       => all_account_rec.customer_code
                                  ,ov_errbuf              => lv_errbuf
                                  ,ov_retcode             => lv_retcode
                                  ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                RAISE global_process_expt;
              END IF;
            ELSE
              INSERT INTO xxcfr_csv_outs_temp(
                request_id       -- 要求ID
               ,seq              -- 出力順
               ,col1             -- ヘッダ/明細区分
               ,col2             -- レコード区分
               ,col3             -- 発行日付
               ,col4             -- 郵便番号
               ,col5             -- 住所１
               ,col6             -- 住所２
               ,col7             -- 住所３
               ,col8             -- 顧客コード
               ,col9             -- 顧客名
               ,col10            -- 担当拠点名
               ,col11            -- 電話番号
               ,col12            -- 対象年月
               ,col13            -- 売掛管理コード連結文字列
               ,col14            -- 請求書出力区分
               ,col15            -- 当月お買い上げ額
               ,col16            -- 消費税等
               ,col17            -- 当月請求額
               ,col18            -- 入金予定日
               ,col19            -- 振込先銀行名
               ,col20            -- 振込先銀行支店名
               ,col21            -- 振込先口座種別
               ,col22            -- 振込先口座番号
               ,col23            -- 振込先口座名義人カナ名
               ,col24            -- 店舗コード
               ,col25            -- 店舗名
               ,col26            -- 伝票日付
               ,col27            -- 伝票No
               ,col28            -- 伝票金額
               ,col29            -- レイアウト区分
               ,col101           -- 伝票税抜額(非出力項目)
               ,col102           -- 伝票税額(非出力項目)
               ,col103           -- 入金先顧客コード(非出力項目)
               ,col104)          -- 入金先顧客名(非出力項目)
              SELECT cn_request_id                                              request_id         -- 要求ID
                    ,TO_NUMBER(NULL)                                            seq                -- 出力順
                    ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                    ,cv_record_kbn1                                             record_kbn         -- レコード区分
                    ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                    ,NULL                                                       zip_code           -- 郵便番号
                    ,NULL                                                       send_address1      -- 住所１
                    ,NULL                                                       send_address2      -- 住所２
                    ,NULL                                                       send_address3      -- 住所３
                    ,get_20account_rec.bill_account_number                      bill_cust_code     -- 顧客コード
                    ,NULL                                                       bill_cust_name     -- 顧客名
                    ,NULL                                                       location_name      -- 拠点名
                    ,NULL                                                       phone_num          -- 電話番号
                    ,xih.object_month                                           object_month       -- 対象年月
                    ,get_20account_rec.bill_account_number||' '||xih.term_name  ar_concat_text     -- 売掛管理コード連結文字列
                    ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                          ,cv_tax_div_nontax,cv_out_div_excluded
                                                                            ,cv_out_div_included)
                                                                                out_put_div        -- 請求書出力区分
                    ,NULL                                                       inv_amount         -- 当月お買い上げ額
                    ,NULL                                                       tax_amount         -- 消費税等
                    ,NULL                                                       total_amount       -- 当月請求額
                    ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END                                                        banc_number        -- 銀行名
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END                                                        bank_branch_number -- 支店名
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END                                                        bank_account_type  -- 口座種別
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END                                                        bank_account_num   -- 口座番号
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END                                                        bank_account_name  -- 口座名義人カナ名
                    ,xil.ship_cust_code                                         ship_cust_code     -- 店舗コード
                    ,hzp.party_name                                             ship_cust_name     -- 店舗名
                    ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                    ,xil.slip_num                                                     slip_num     -- 伝票番号
                    ,SUM(CASE
                         WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                                ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                                         slip_sum          -- 伝票金額
                    ,cv_layout_kbn2                                                   layout_kbn        -- レイアウト区分
                    ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- 伝票税抜額
                    ,SUM(xil.tax_amount)                                              slip_tax          -- 伝票税額
                    ,get_14account_rec.cash_account_number                            payment_cust_code -- 入金先顧客コード
                    ,get_14account_rec.cash_account_name                              payment_cust_name -- 入金先顧客名
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   hz_cust_accounts               hzca , -- 顧客10顧客マスタ
                   hz_parties                     hzp  , -- 顧客10パーティマスタ
                   (SELECT all_account_rec.customer_code ship_cust_code
                          ,rcrm.customer_id             customer_id
                          ,abb.bank_number              bank_number
                          ,abb.bank_name                bank_name
                          ,abb.bank_branch_name         bank_branch_name
                          ,abaa.bank_account_type       bank_account_type
                          ,abaa.bank_account_num        bank_account_num
                          ,abaa.account_holder_name     account_holder_name
                          ,abaa.account_holder_name_alt account_holder_name_alt
                    FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                          ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                          ,ap_bank_accounts_all           abaa                 --銀行口座
                          ,ap_bank_branches               abb                  --銀行支店
                    WHERE  rcrm.primary_flag      = cv_flag_yes
                      AND  get_14account_rec.cash_account_id = rcrm.customer_id
                      AND  gd_target_date   BETWEEN rcrm.start_date
                                                AND NVL(rcrm.end_date, gd_max_date)
                      AND  rcrm.site_use_id      IS NOT NULL
                      AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND  arma.bank_account_id   = abaa.bank_account_id(+)
                      AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                      AND  arma.org_id            = gn_org_id
                      AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
              WHERE xih.invoice_id = xil.invoice_id
                AND xil.cutoff_date = gd_target_date
                AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND xil.ship_cust_code = all_account_rec.customer_code
                AND hzca.cust_account_id = all_account_rec.customer_id
                AND hzp.party_id = hzca.party_id
              GROUP BY xih.inv_creation_date,                                               -- 発行日付
                       xih.object_month,                                                    -- 対象年月
                       xih.term_name,                                                       -- 支払条件
                       xih.payment_date,                                                    -- 入金予定日
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name 
                                END)
                       END,                                                                 -- 銀行名
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END)
                       END,                                                                 -- 支店名
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type))
                       END,                                                                 -- 口座種別
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,bank.bank_account_num)
                       END,                                                                 -- 口座番号
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,bank.account_holder_name_alt)
                       END,                                                                 -- 口座名義人カナ名
                       xil.ship_cust_code,                                                  -- 店舗コード
                       hzp.party_name,                                                      -- 店舗名
                       TO_CHAR(DECODE(xil.acceptance_date,NULL
                                     ,xil.delivery_date
                                     ,xil.acceptance_date)
                                     ,cv_format_date_yyyymmdd),                             -- 伝票日付
                       xil.slip_num;                                                        -- 伝票番号
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            END IF;
--
            CLOSE get_20account_cur;
--
          -- 請求書印刷単位 = 'N1' 顧客区分10単位で送付
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n1)
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 4.業者委託
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- 一括請求書発行フラグ = 'Y'
          THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- 要求ID
             ,seq              -- 出力順
             ,col1             -- ヘッダ/明細区分
             ,col2             -- レコード区分
             ,col3             -- 発行日付
             ,col4             -- 郵便番号
             ,col5             -- 住所１
             ,col6             -- 住所２
             ,col7             -- 住所３
             ,col8             -- 顧客コード
             ,col9             -- 顧客名
             ,col10            -- 担当拠点名
             ,col11            -- 電話番号
             ,col12            -- 対象年月
             ,col13            -- 売掛管理コード連結文字列
             ,col14            -- 請求書出力区分
             ,col15            -- 当月お買い上げ額
             ,col16            -- 消費税等
             ,col17            -- 当月請求額
             ,col18            -- 入金予定日
             ,col19            -- 振込先銀行名
             ,col20            -- 振込先銀行支店名
             ,col21            -- 振込先口座種別
             ,col22            -- 振込先口座番号
             ,col23            -- 振込先口座名義人カナ名
             ,col24            -- 店舗コード
             ,col25            -- 店舗名
             ,col26            -- 伝票日付
             ,col27            -- 伝票No
             ,col28            -- 伝票金額
             ,col29            -- レイアウト区分
             ,col101           -- 伝票税抜額(非出力項目)
             ,col102           -- 伝票税額(非出力項目)
             ,col103           -- 入金先顧客コード(非出力項目)
             ,col104)          -- 入金先顧客名(非出力項目)
            SELECT cn_request_id                                              request_id         -- 要求ID
                  ,TO_NUMBER(NULL)                                            seq                -- 出力順
                  ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                  ,cv_record_kbn1                                             record_kbn         -- レコード区分
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                  ,NULL                                                       zip_code           -- 郵便番号
                  ,NULL                                                       send_address1      -- 住所１
                  ,NULL                                                       send_address2      -- 住所２
                  ,NULL                                                       send_address3      -- 住所３
                  ,xil.ship_cust_code                                         bill_cust_code     -- 顧客コード
                  ,NULL                                                       bill_cust_name     -- 顧客名
                  ,NULL                                                       location_name      -- 拠点名
                  ,NULL                                                       phone_num          -- 電話番号
                  ,xih.object_month                                           object_month       -- 対象年月
                  ,xil.ship_cust_code||' '||xih.term_name                     ar_concat_text     -- 売掛管理コード連結文字列
                  ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                        ,cv_tax_div_nontax,cv_out_div_excluded
                                                                          ,cv_out_div_included)
                                                                              out_put_div        -- 請求書出力区分
                  ,NULL                                                       inv_amount         -- 当月お買い上げ額
                  ,NULL                                                       tax_amount         -- 消費税等
                  ,NULL                                                       total_amount       -- 当月請求額
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                             ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                   END                                                        banc_number        -- 銀行名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,CASE WHEN INSTR(bank.bank_branch_name
                                           ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                   END                                                        bank_branch_number -- 支店名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                   END                                                        bank_account_type  -- 口座種別
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,bank.bank_account_num)
                   END                                                        bank_account_num   -- 口座番号
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,bank.account_holder_name_alt)
                   END                                                        bank_account_name  -- 口座名義人カナ名
                  ,NULL                                                       ship_cust_code     -- 店舗コード
                  ,NULL                                                       ship_cust_name     -- 店舗名
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                 ,xil.delivery_date
                                 ,xil.acceptance_date)
                                 ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                  ,xil.slip_num                                                     slip_num     -- 伝票番号
                  ,SUM(CASE
                       WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                              ,cv_tax_div_excluded)
                       THEN
                            xil.ship_amount
                       ELSE
                            xil.tax_amount + xil.ship_amount
                       END)                                                         slip_sum     -- 伝票金額
                  ,cv_layout_kbn1                                                   layout_kbn   -- レイアウト区分
                  ,SUM(xil.ship_amount)                                             slip_sum_ex_tax  -- 伝票税抜額
                  ,SUM(xil.tax_amount)                                              slip_tax         -- 伝票税額
                  ,get_14account_rec.cash_account_number                            payment_cust_code -- 入金先顧客コード
                  ,get_14account_rec.cash_account_name                              payment_cust_name -- 入金先顧客名
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                        ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                        ,ap_bank_accounts_all           abaa                 --銀行口座
                        ,ap_bank_branches               abb                  --銀行支店
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  get_14account_rec.cash_account_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
            GROUP BY xih.inv_creation_date,                                               -- 発行日付
                     xil.ship_cust_code,                                                  -- 顧客コード
                     xih.object_month,                                                    -- 対象年月
                     xih.term_name,                                                       -- 支払条件
                     xih.payment_date,                                                    -- 入金予定日
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END,                                                                 -- 銀行名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END,                                                                 -- 支店名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END,                                                                 -- 口座種別
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END,                                                                 -- 口座番号
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- 口座名義人カナ名
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- 伝票日付
                     xil.slip_num;                                                        -- 伝票番号
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          -- 請求書印刷単位 = 'N2' 売掛管理先顧客に送付
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n2)
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 4.業者委託
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- 一括請求書発行フラグ = 'Y'
          THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- 要求ID
             ,seq              -- 出力順
             ,col1             -- ヘッダ/明細区分
             ,col2             -- レコード区分
             ,col3             -- 発行日付
             ,col4             -- 郵便番号
             ,col5             -- 住所１
             ,col6             -- 住所２
             ,col7             -- 住所３
             ,col8             -- 顧客コード
             ,col9             -- 顧客名
             ,col10            -- 担当拠点名
             ,col11            -- 電話番号
             ,col12            -- 対象年月
             ,col13            -- 売掛管理コード連結文字列
             ,col14            -- 請求書出力区分
             ,col15            -- 当月お買い上げ額
             ,col16            -- 消費税等
             ,col17            -- 当月請求額
             ,col18            -- 入金予定日
             ,col19            -- 振込先銀行名
             ,col20            -- 振込先銀行支店名
             ,col21            -- 振込先口座種別
             ,col22            -- 振込先口座番号
             ,col23            -- 振込先口座名義人カナ名
             ,col24            -- 店舗コード
             ,col25            -- 店舗名
             ,col26            -- 伝票日付
             ,col27            -- 伝票No
             ,col28            -- 伝票金額
             ,col29            -- レイアウト区分
             ,col101           -- 伝票税抜額(非出力項目)
             ,col102           -- 伝票税額(非出力項目)
             ,col103           -- 入金先顧客コード(非出力項目)
             ,col104)          -- 入金先顧客名(非出力項目)
            SELECT cn_request_id                                              request_id         -- 要求ID
                  ,TO_NUMBER(NULL)                                            seq                -- 出力順
                  ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                  ,cv_record_kbn1                                             record_kbn         -- レコード区分
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                  ,NULL                                                       zip_code           -- 郵便番号
                  ,NULL                                                       send_address1      -- 住所１
                  ,NULL                                                       send_address2      -- 住所２
                  ,NULL                                                       send_address3      -- 住所３
                  ,get_14account_rec.cash_account_number                      bill_cust_code     -- 顧客コード
                  ,NULL                                                       bill_cust_name     -- 顧客名
                  ,NULL                                                       location_name      -- 拠点名
                  ,NULL                                                       phone_num          -- 電話番号
                  ,xih.object_month                                           object_month       -- 対象年月
                  ,get_14account_rec.cash_account_number||' '||xih.term_name  ar_concat_text     -- 売掛管理コード連結文字列
                  ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                        ,cv_tax_div_nontax,cv_out_div_excluded
                                                                          ,cv_out_div_included)
                                                                              out_put_div        -- 請求書出力区分
                  ,NULL                                                       inv_amount         -- 当月お買い上げ額
                  ,NULL                                                       tax_amount         -- 消費税等
                  ,NULL                                                       total_amount       -- 当月請求額
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                             ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                   END                                                        banc_number        -- 銀行名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,CASE WHEN INSTR(bank.bank_branch_name
                                           ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                   END                                                        bank_branch_number -- 支店名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                   END                                                        bank_account_type  -- 口座種別
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,bank.bank_account_num)
                   END                                                        bank_account_num   -- 口座番号
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                     NULL
                   ELSE
                     DECODE(SUBSTR(bank.bank_number,1,1)
                           ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                           ,bank.account_holder_name_alt)
                   END                                                        bank_account_name  -- 口座名義人カナ名
                  ,NULL                                                       ship_cust_code     -- 店舗コード
                  ,NULL                                                       ship_cust_name     -- 店舗名
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                 ,xil.delivery_date
                                 ,xil.acceptance_date)
                                 ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                  ,xil.slip_num                                                     slip_num     -- 伝票番号
                  ,SUM(CASE
                       WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                              ,cv_tax_div_excluded)
                       THEN
                            xil.ship_amount
                       ELSE
                            xil.tax_amount + xil.ship_amount
                       END)                                                         slip_sum          -- 伝票金額
                  ,cv_layout_kbn1                                                   layout_kbn        -- レイアウト区分
                  ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- 伝票税抜額
                  ,SUM(xil.tax_amount)                                              slip_tax          -- 伝票税額
                  ,get_14account_rec.cash_account_number                            payment_cust_code -- 入金先顧客コード
                  ,get_14account_rec.cash_account_name                              payment_cust_name -- 入金先顧客名
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                 xxcfr_invoice_lines            xil  , -- 請求明細
                 (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                        ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                        ,ap_bank_accounts_all           abaa                 --銀行口座
                        ,ap_bank_branches               abb                  --銀行支店
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  get_14account_rec.cash_account_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
            GROUP BY xih.inv_creation_date,                                               -- 発行日付
                     xih.object_month,                                                    -- 対象年月
                     xih.term_name,                                                       -- 支払条件
                     xih.payment_date,                                                    -- 入金予定日
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END,                                                                 -- 銀行名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END,                                                                 -- 支店名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END,                                                                 -- 口座種別
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END,                                                                 -- 口座番号
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- 口座名義人カナ名
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- 伝票日付
                     xil.slip_num;                                                        -- 伝票番号
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          -- 請求書印刷単位 = 'N3' 請求書用顧客に送付
          ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n3)
            AND (get_14account_rec.bill_invoice_type = cv_inv_prt_type) -- 請求書出力形式 = 4.業者委託
            AND (get_14account_rec.cons_inv_flag = cv_flag_yes)         -- 一括請求書発行フラグ
          THEN
            OPEN get_20account_cur(all_account_rec.customer_id);
            FETCH get_20account_cur INTO get_20account_rec;
            --顧客区分20の顧客が存在しない場合
            IF get_20account_cur%NOTFOUND THEN
              -- 顧客区分20存在なしメッセージ出力
              put_account_warning(iv_customer_class_code => cv_customer_class_code20
                                  ,iv_customer_code       => all_account_rec.customer_code
                                  ,ov_errbuf              => lv_errbuf
                                  ,ov_retcode             => lv_retcode
                                  ,ov_errmsg              => lv_errmsg);
              IF (lv_retcode = cv_status_error) THEN
                --(エラー処理)
                RAISE global_process_expt;
              END IF;
            ELSE
              INSERT INTO xxcfr_csv_outs_temp(
                request_id       -- 要求ID
               ,seq              -- 出力順
               ,col1             -- ヘッダ/明細区分
               ,col2             -- レコード区分
               ,col3             -- 発行日付
               ,col4             -- 郵便番号
               ,col5             -- 住所１
               ,col6             -- 住所２
               ,col7             -- 住所３
               ,col8             -- 顧客コード
               ,col9             -- 顧客名
               ,col10            -- 担当拠点名
               ,col11            -- 電話番号
               ,col12            -- 対象年月
               ,col13            -- 売掛管理コード連結文字列
               ,col14            -- 請求書出力区分
               ,col15            -- 当月お買い上げ額
               ,col16            -- 消費税等
               ,col17            -- 当月請求額
               ,col18            -- 入金予定日
               ,col19            -- 振込先銀行名
               ,col20            -- 振込先銀行支店名
               ,col21            -- 振込先口座種別
               ,col22            -- 振込先口座番号
               ,col23            -- 振込先口座名義人カナ名
               ,col24            -- 店舗コード
               ,col25            -- 店舗名
               ,col26            -- 伝票日付
               ,col27            -- 伝票No
               ,col28            -- 伝票金額
               ,col29            -- レイアウト区分
               ,col101           -- 伝票税抜額(非出力項目)
               ,col102           -- 伝票税額(非出力項目)
               ,col103           -- 入金先顧客コード(非出力項目)
               ,col104)          -- 入金先顧客名(非出力項目)
              SELECT cn_request_id                                              request_id         -- 要求ID
                    ,TO_NUMBER(NULL)                                            seq                -- 出力順
                    ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                    ,cv_record_kbn1                                             record_kbn         -- レコード区分
                    ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                    ,NULL                                                       zip_code           -- 郵便番号
                    ,NULL                                                       send_address1      -- 住所１
                    ,NULL                                                       send_address2      -- 住所２
                    ,NULL                                                       send_address3      -- 住所３
                    ,get_20account_rec.bill_account_number                      bill_cust_code     -- 顧客コード
                    ,NULL                                                       bill_cust_name     -- 顧客名
                    ,NULL                                                       location_name      -- 拠点名
                    ,NULL                                                       phone_num          -- 電話番号
                    ,xih.object_month                                           object_month       -- 対象年月
                    ,get_20account_rec.bill_account_number||' '||xih.term_name  ar_concat_text     -- 売掛管理コード連結文字列
                    ,DECODE(get_14account_rec.bill_tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                                          ,cv_tax_div_nontax,cv_out_div_excluded
                                                                            ,cv_out_div_included)
                                                                                out_put_div        -- 請求書出力区分
                    ,NULL                                                       inv_amount         -- 当月お買い上げ額
                    ,NULL                                                       tax_amount         -- 消費税等
                    ,NULL                                                       total_amount       -- 当月請求額
                    ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END)
                     END                                                        banc_number        -- 銀行名
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END)
                     END                                                        bank_branch_number -- 支店名
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type))
                     END                                                        bank_account_type  -- 口座種別
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END                                                        bank_account_num   -- 口座番号
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END                                                        bank_account_name  -- 口座名義人カナ名
                    ,NULL                                                       ship_cust_code     -- 店舗コード
                    ,NULL                                                       ship_cust_name     -- 店舗名
                    ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                    ,xil.slip_num                                                     slip_num     -- 伝票番号
                    ,SUM(CASE
                         WHEN get_14account_rec.bill_tax_div IN (cv_tax_div_nontax
                                                                ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                                         slip_sum          -- 伝票金額
                    ,cv_layout_kbn1                                                   layout_kbn        -- レイアウト区分
                    ,SUM(xil.ship_amount)                                             slip_sum_ex_tax   -- 伝票税抜額
                    ,SUM(xil.tax_amount)                                              slip_tax          -- 伝票税額
                    ,get_14account_rec.cash_account_number                            payment_cust_code -- 入金先顧客コード
                    ,get_14account_rec.cash_account_name                              payment_cust_name -- 入金先顧客名
              FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                   xxcfr_invoice_lines            xil  , -- 請求明細
                   (SELECT all_account_rec.customer_code ship_cust_code
                          ,rcrm.customer_id             customer_id
                          ,abb.bank_number              bank_number
                          ,abb.bank_name                bank_name
                          ,abb.bank_branch_name         bank_branch_name
                          ,abaa.bank_account_type       bank_account_type
                          ,abaa.bank_account_num        bank_account_num
                          ,abaa.account_holder_name     account_holder_name
                          ,abaa.account_holder_name_alt account_holder_name_alt
                    FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                          ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                          ,ap_bank_accounts_all           abaa                 --銀行口座
                          ,ap_bank_branches               abb                  --銀行支店
                    WHERE  rcrm.primary_flag      = cv_flag_yes
                      AND  get_14account_rec.cash_account_id = rcrm.customer_id
                      AND  gd_target_date   BETWEEN rcrm.start_date
                                                AND NVL(rcrm.end_date, gd_max_date)
                      AND  rcrm.site_use_id      IS NOT NULL
                      AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                      AND  arma.bank_account_id   = abaa.bank_account_id(+)
                      AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                      AND  arma.org_id            = gn_org_id
                      AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
              WHERE xih.invoice_id = xil.invoice_id
                AND xil.cutoff_date = gd_target_date
                AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
                AND xih.set_of_books_id = gn_set_of_bks_id
                AND xih.org_id = gn_org_id
                AND xil.ship_cust_code = all_account_rec.customer_code
              GROUP BY xih.inv_creation_date,                                               -- 発行日付
                       xih.object_month,                                                    -- 対象年月
                       xih.term_name,                                                       -- 支払条件
                       xih.payment_date,                                                    -- 入金予定日
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name 
                                END)
                       END,                                                                 -- 銀行名
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END)
                       END,                                                                 -- 支店名
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type))
                       END,                                                                 -- 口座種別
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,bank.bank_account_num)
                       END,                                                                 -- 口座番号
                       CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                               ,bank.account_holder_name_alt)
                       END,                                                                 -- 口座名義人カナ名
                       TO_CHAR(DECODE(xil.acceptance_date,NULL
                                     ,xil.delivery_date
                                     ,xil.acceptance_date)
                                     ,cv_format_date_yyyymmdd),                             -- 伝票日付
                       xil.slip_num;                                                        -- 伝票番号
--
              gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
            END IF;
--
            CLOSE get_20account_cur;
--
          END IF;
--
          CLOSE get_14account_cur;
--
        -- 請求書印刷単位が'N4'(単独店)の場合、
        ELSIF (all_account_rec.invoice_printing_unit = cv_invoice_printing_unit_n4) THEN
          -- 請求書出力形式取得
          OPEN get_10inv_type_cur(all_account_rec.customer_id);
          FETCH get_10inv_type_cur INTO get_10inv_type_rec;
          -- 請求書出力形式が'4'かつ、一括請求書発行フラグ = 'Y'の場合
          IF  (get_10inv_type_cur%FOUND) THEN
            INSERT INTO xxcfr_csv_outs_temp(
              request_id       -- 要求ID
             ,seq              -- 出力順
             ,col1             -- ヘッダ/明細区分
             ,col2             -- レコード区分
             ,col3             -- 発行日付
             ,col4             -- 郵便番号
             ,col5             -- 住所１
             ,col6             -- 住所２
             ,col7             -- 住所３
             ,col8             -- 顧客コード
             ,col9             -- 顧客名
             ,col10            -- 担当拠点名
             ,col11            -- 電話番号
             ,col12            -- 対象年月
             ,col13            -- 売掛管理コード連結文字列
             ,col14            -- 請求書出力区分
             ,col15            -- 当月お買い上げ額
             ,col16            -- 消費税等
             ,col17            -- 当月請求額
             ,col18            -- 入金予定日
             ,col19            -- 振込先銀行名
             ,col20            -- 振込先銀行支店名
             ,col21            -- 振込先口座種別
             ,col22            -- 振込先口座番号
             ,col23            -- 振込先口座名義人カナ名
             ,col24            -- 店舗コード
             ,col25            -- 店舗名
             ,col26            -- 伝票日付
             ,col27            -- 伝票No
             ,col28            -- 伝票金額
             ,col29            -- レイアウト区分
             ,col101           -- 伝票税抜額(非出力項目)
             ,col102           -- 伝票税額(非出力項目)
             ,col103           -- 入金先顧客コード(非出力項目)
             ,col104)          -- 入金先顧客名(非出力項目)
            SELECT cn_request_id                                              request_id         -- 要求ID
                  ,TO_NUMBER(NULL)                                            seq                -- 出力順
                  ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
                  ,cv_record_kbn1                                             record_kbn         -- レコード区分
                  ,TO_CHAR(xih.inv_creation_date,cv_format_date_yyyymmdd)     issue_date         -- 発行日付
                  ,NULL                                                       zip_code           -- 郵便番号
                  ,NULL                                                       send_address1      -- 住所１
                  ,NULL                                                       send_address2      -- 住所２
                  ,NULL                                                       send_address3      -- 住所３
                  ,xil.ship_cust_code                                         bill_cust_code     -- 顧客コード
                  ,NULL                                                       bill_cust_name     -- 顧客名
                  ,NULL                                                       location_name      -- 拠点名
                  ,NULL                                                       phone_num          -- 電話番号
                  ,xih.object_month                                           object_month       -- 対象年月
                  ,xil.ship_cust_code||' '||xih.term_name                     ar_concat_text     -- 売掛管理コード連結文字列
                  ,DECODE(xxca.tax_div,cv_tax_div_excluded,cv_out_div_excluded
                                      ,cv_tax_div_nontax,cv_out_div_excluded
                                      ,cv_out_div_included)
                                                                              out_put_div        -- 請求書出力区分
                  ,NULL                                                       inv_amount         -- 当月お買い上げ額
                  ,NULL                                                       tax_amount         -- 消費税等
                  ,NULL                                                       total_amount       -- 当月請求額
                  ,TO_CHAR(xih.payment_date,cv_format_date_yyyymmdd)          payment_date       -- 入金予定日
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                            ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                              CASE WHEN INSTR(bank.bank_name
                                              ,gv_format_bank) > 0
                              THEN
                                bank.bank_name
                              ELSE
                                bank.bank_name || gv_format_bank
                              END
                            ELSE
                              bank.bank_name 
                            END)
                    END                                                        banc_number        -- 銀行名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                            ,CASE WHEN INSTR(bank.bank_branch_name
                                            ,gv_format_central) > 0
                            THEN
                              bank.bank_branch_name
                            ELSE
                              bank.bank_branch_name || gv_format_branch
                            END)
                    END                                                        bank_branch_number -- 支店名
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                            ,DECODE(bank.bank_account_type
                                  ,1, gv_format_account
                                  ,2, gv_format_current
                                  ,bank.bank_account_type))
                    END                                                        bank_account_type  -- 口座種別
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                            ,bank.bank_account_num)
                    END                                                        bank_account_num   -- 口座番号
                  ,CASE WHEN bank.bank_account_num IS NULL THEN
                      NULL
                    ELSE
                      DECODE(SUBSTR(bank.bank_number,1,1)
                            ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                            ,bank.account_holder_name_alt)
                    END                                                        bank_account_name  -- 口座名義人カナ名
                  ,NULL                                                        ship_cust_code     -- 店舗コード
                  ,NULL                                                        ship_cust_name     -- 店舗名
                  ,TO_CHAR(DECODE(xil.acceptance_date,NULL
                                  ,xil.delivery_date
                                  ,xil.acceptance_date)
                                  ,cv_format_date_yyyymmdd)                          slip_date    -- 伝票日付
                  ,xil.slip_num                                                      slip_num     -- 伝票番号
                  ,SUM(CASE
                        WHEN xxca.tax_div IN (cv_tax_div_nontax
                                             ,cv_tax_div_excluded)
                        THEN
                            xil.ship_amount
                        ELSE
                            xil.tax_amount + xil.ship_amount
                        END)                                                         slip_sum          -- 伝票金額
                  ,cv_layout_kbn1                                                    layout_kbn        -- レイアウト区分
                  ,SUM(xil.ship_amount)                                              slip_sum_ex_tax   -- 伝票税抜額
                  ,SUM(xil.tax_amount)                                               slip_tax          -- 伝票税額
                  ,NULL                                                              payment_cust_code -- 入金先顧客コード
                  ,NULL                                                              payment_cust_name -- 入金先顧客名
            FROM xxcfr_invoice_headers          xih  , -- 請求ヘッダ
                  xxcfr_invoice_lines            xil  , -- 請求明細
                  xxcmm_cust_accounts            xxca , -- 顧客10追加情報
                  (SELECT all_account_rec.customer_code ship_cust_code
                        ,rcrm.customer_id             customer_id
                        ,abb.bank_number              bank_number
                        ,abb.bank_name                bank_name
                        ,abb.bank_branch_name         bank_branch_name
                        ,abaa.bank_account_type       bank_account_type
                        ,abaa.bank_account_num        bank_account_num
                        ,abaa.account_holder_name     account_holder_name
                        ,abaa.account_holder_name_alt account_holder_name_alt
                  FROM   ra_cust_receipt_methods        rcrm                 --支払方法情報
                        ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                        ,ap_bank_accounts_all           abaa                 --銀行口座
                        ,ap_bank_branches               abb                  --銀行支店
                  WHERE  rcrm.primary_flag      = cv_flag_yes
                    AND  all_account_rec.customer_id = rcrm.customer_id
                    AND  gd_target_date   BETWEEN rcrm.start_date
                                              AND NVL(rcrm.end_date, gd_max_date)
                    AND  rcrm.site_use_id      IS NOT NULL
                    AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                    AND  arma.bank_account_id   = abaa.bank_account_id(+)
                    AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                    AND  arma.org_id            = gn_org_id
                    AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
            WHERE xih.invoice_id = xil.invoice_id
              AND xil.cutoff_date = gd_target_date
              AND xil.ship_cust_code = bank.ship_cust_code(+)                -- 外部結合のためのダミー結合
              AND xih.set_of_books_id = gn_set_of_bks_id
              AND xih.org_id = gn_org_id
              AND xil.ship_cust_code = all_account_rec.customer_code
              AND xxca.customer_code = all_account_rec.customer_code
            GROUP BY xih.inv_creation_date,                                               -- 発行日付
                     xil.ship_cust_code,                                                  -- 顧客コード
                     xih.object_month,                                                    -- 対象年月
                     xih.term_name,                                                       -- 支払条件
                     xxca.tax_div,                                                        -- 消費税区分
                     xih.payment_date,                                                    -- 入金予定日
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                               CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                               THEN
                                 bank.bank_name
                               ELSE
                                 bank.bank_name || gv_format_bank
                               END
                             ELSE
                               bank.bank_name 
                             END)
                     END,                                                                 -- 銀行名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                             THEN
                               bank.bank_branch_name
                             ELSE
                               bank.bank_branch_name || gv_format_branch
                             END)
                     END,                                                                 -- 支店名
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,DECODE(bank.bank_account_type
                                   ,1, gv_format_account
                                   ,2, gv_format_current
                                   ,bank.bank_account_type))
                     END,                                                                 -- 口座種別
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.bank_account_num)
                     END,                                                                 -- 口座番号
                     CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,bank.account_holder_name_alt)
                     END,                                                                 -- 口座名義人カナ名
                     TO_CHAR(DECODE(xil.acceptance_date,NULL
                                   ,xil.delivery_date
                                   ,xil.acceptance_date)
                                   ,cv_format_date_yyyymmdd),                             -- 伝票日付
                     xil.slip_num;                                                        -- 伝票番号
--
            gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
          END IF;
--
          CLOSE get_10inv_type_cur;
--
        END IF;
      END LOOP get_account10_loop;
--
      -- 店舗別小計レコード作成
      INSERT INTO xxcfr_csv_outs_temp(
        request_id       -- 要求ID
        ,seq              -- 出力順
        ,col1             -- ヘッダ/明細区分
        ,col2             -- レコード区分
        ,col3             -- 発行日付
        ,col4             -- 郵便番号
        ,col5             -- 住所１
        ,col6             -- 住所２
        ,col7             -- 住所３
        ,col8             -- 顧客コード
        ,col9             -- 顧客名
        ,col10            -- 担当拠点名
        ,col11            -- 電話番号
        ,col12            -- 対象年月
        ,col13            -- 売掛管理コード連結文字列
        ,col14            -- 請求書出力区分
        ,col15            -- 当月お買い上げ額
        ,col16            -- 消費税等
        ,col17            -- 当月請求額
        ,col18            -- 入金予定日
        ,col19            -- 振込先銀行名
        ,col20            -- 振込先銀行支店名
        ,col21            -- 振込先口座種別
        ,col22            -- 振込先口座番号
        ,col23            -- 振込先口座名義人カナ名
        ,col24            -- 店舗コード
        ,col25            -- 店舗名
        ,col26            -- 伝票日付
        ,col27            -- 伝票No
        ,col28            -- 伝票金額
        ,col29)           -- レイアウト区分
      SELECT cn_request_id                                              request_id         -- 要求ID
            ,TO_NUMBER(NULL)                                            seq                -- 出力順
            ,cv_line_kbn                                                header_line_kbn    -- ヘッダ/明細区分
            ,cv_record_kbn2                                             record_kbn         -- レコード区分
            ,xxcot.col3                                                 issue_date         -- 発行日付
            ,NULL                                                       zip_code           -- 郵便番号
            ,NULL                                                       send_address1      -- 住所１
            ,NULL                                                       send_address2      -- 住所２
            ,NULL                                                       send_address3      -- 住所３
            ,xxcot.col8                                                 bill_cust_code     -- 顧客コード
            ,NULL                                                       bill_cust_name     -- 顧客名
            ,NULL                                                       location_name      -- 拠点名
            ,NULL                                                       phone_num          -- 電話番号
            ,NULL                                                       object_month       -- 対象年月
            ,NULL                                                       ar_concat_text     -- 売掛管理コード連結文字列
            ,NULL                                                       out_put_div        -- 請求書出力区分
            ,NULL                                                       inv_amount         -- 当月お買い上げ額
            ,NULL                                                       tax_amount         -- 消費税等
            ,NULL                                                       total_amount       -- 当月請求額
            ,NULL                                                       payment_date       -- 入金予定日
            ,NULL                                                       banc_number        -- 銀行名
            ,NULL                                                       bank_branch_number -- 支店名
            ,NULL                                                       bank_account_type  -- 口座種別
            ,NULL                                                       bank_account_num   -- 口座番号
            ,NULL                                                       bank_account_name  -- 口座名義人カナ名
            ,xxcot.col24                                                ship_cust_code     -- 店舗コード
            ,xxcot.col25                                                ship_cust_name     -- 店舗名
            ,NULL                                                       slip_date          -- 伝票日付
            ,NULL                                                       slip_num           -- 伝票番号
            ,SUM(TO_NUMBER(xxcot.col28))                                slip_sum           -- 伝票金額
            ,cv_layout_kbn2                                             layout_kbn         -- レイアウト区分
      FROM xxcfr_csv_outs_temp          xxcot  -- CSV出力ワークテーブル
      WHERE xxcot.request_id = cn_request_id
        AND xxcot.col29 = cv_layout_kbn2       -- レイアウト区分 = '2'(店舗別内訳レイアウト)
        AND xxcot.col2 = cv_record_kbn1        -- レコード区分 = '1'(店舗別明細レコード)
      GROUP BY xxcot.col3,                                                                 -- 発行日付
               xxcot.col8,                                                                 -- 顧客コード
               xxcot.col24,                                                                -- 店舗コード
               xxcot.col25;                                                                -- 店舗名
--
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
      -- ヘッダレコード作成
      INSERT INTO xxcfr_csv_outs_temp(
        request_id       -- 要求ID
        ,seq              -- 出力順
        ,col1             -- ヘッダ/明細区分
        ,col2             -- レコード区分
        ,col3             -- 発行日付
        ,col4             -- 郵便番号
        ,col5             -- 住所１
        ,col6             -- 住所２
        ,col7             -- 住所３
        ,col8             -- 顧客コード
        ,col9             -- 顧客名
        ,col10            -- 担当拠点名
        ,col11            -- 電話番号
        ,col12            -- 対象年月
        ,col13            -- 売掛管理コード連結文字列
        ,col14            -- 請求書出力区分
        ,col15            -- 当月お買い上げ額
        ,col16            -- 消費税等
        ,col17            -- 当月請求額
        ,col18            -- 入金予定日
        ,col19            -- 振込先銀行名
        ,col20            -- 振込先銀行支店名
        ,col21            -- 振込先口座種別
        ,col22            -- 振込先口座番号
        ,col23            -- 振込先口座名義人カナ名
        ,col24            -- 店舗コード
        ,col25            -- 店舗名
        ,col26            -- 伝票日付
        ,col27            -- 伝票No
        ,col28            -- 伝票金額
        ,col29            -- レイアウト区分
        ,col103           -- 入金先顧客コード(非出力項目)
        ,col104)          -- 入金先顧客名(非出力項目)
      SELECT cn_request_id                                              request_id         -- 要求ID
            ,TO_NUMBER(NULL)                                            seq                -- 出力順
            ,cv_header_kbn                                              header_line_kbn    -- ヘッダ/明細区分
            ,cv_record_kbn0                                             record_kbn         -- レコード区分
            ,xxcot.col3                                                 issue_date         -- 発行日付
            ,hzlo.postal_code                                           zip_code           -- 郵便番号
            ,hzlo.state||hzlo.city                                      send_address1      -- 住所１
            ,hzlo.address1                                              send_address2      -- 住所２
            ,hzlo.address2                                              send_address3      -- 住所３
            ,xxcot.col8                                                 bill_cust_code     -- 顧客コード
            ,hzpa.party_name                                            bill_cust_name     -- 顧客名
            ,xffvv.description                                          location_name      -- 拠点名
            ,xxcfr_common_pkg.get_base_target_tel_num(xxcot.col8)       phone_num          -- 電話番号
            ,xxcot.col12                                                object_month       -- 対象年月
            ,xxcot.col13                                                ar_concat_text     -- 売掛管理コード連結文字列
            ,xxcot.col14                                                out_put_div        -- 請求書出力区分
            ,SUM(TO_NUMBER(xxcot.col101))                               inv_amount         -- 当月お買い上げ額
            ,SUM(TO_NUMBER(xxcot.col102))                               tax_amount         -- 消費税等
            ,SUM(TO_NUMBER(xxcot.col101) + TO_NUMBER(xxcot.col102))     total_amount       -- 当月請求額
            ,xxcot.col18                                                payment_date       -- 入金予定日
            ,xxcot.col19                                                banc_number        -- 銀行名
            ,xxcot.col20                                                bank_branch_number -- 支店名
            ,xxcot.col21                                                bank_account_type  -- 口座種別
            ,xxcot.col22                                                bank_account_num   -- 口座番号
            ,xxcot.col23                                                bank_account_name  -- 口座名義人カナ名
            ,NULL                                                       ship_cust_code     -- 店舗コード
            ,NULL                                                       ship_cust_name     -- 店舗名
            ,NULL                                                       slip_date          -- 伝票日付
            ,NULL                                                       slip_num           -- 伝票番号
            ,NULL                                                       slip_sum           -- 伝票金額
            ,xxcot.col29                                                layout_kbn         -- レイアウト区分
            ,NVL(xxcot.col103,xxcot.col8)                               payment_cust_code  -- 入金先顧客ビュー(単独店の場合顧客コードをセット)
            ,NVL(xxcot.col104,hzpa.party_name)                          payment_cust_name  -- 入金先顧客名(単独店の場合顧客名をセット)
      FROM xxcfr_csv_outs_temp          xxcot,  -- CSV出力ワークテーブル
           xxcmm_cust_accounts          xxca,   -- 顧客追加情報
           hz_cust_accounts             hzca,   -- 顧客マスタ
           hz_parties                   hzpa,   -- パーティ
           hz_cust_acct_sites           hcas,   -- 顧客所在地
           hz_party_sites               hzps,   -- パーティサイト
           hz_locations                 hzlo,   -- 顧客事業所
           (SELECT flex_value,
                   description
            FROM   fnd_flex_values_vl ffv
            WHERE  EXISTS
                   (SELECT  'X'
                    FROM    fnd_flex_value_sets
                    WHERE   flex_value_set_name = cv_ffv_set_name_dept
                    AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  -- 部門値セット
      WHERE xxcot.request_id = cn_request_id
        AND xxcot.col2 = cv_record_kbn1                             -- レコード区分 = '1'(明細レコード)
        AND xxca.customer_code = xxcot.col8                         -- 顧客追加情報.顧客コード = CSVワーク.顧客コード
        AND hzca.cust_account_id = xxca.customer_id                 -- 顧客マスタ.顧客ID = 顧客追加情報.顧客ID
        AND hzpa.party_id = hzca.party_id                           -- パーティ.パーティID = 顧客マスタ.パーティID
        AND hcas.cust_account_id = hzca.cust_account_id             -- 顧客所在地.顧客ID = 顧客マスタ.顧客ID
        AND hzps.party_site_id = hcas.party_site_id                 -- パーティサイト.パーティサイトID = 顧客所在地.パーティサイトID
        AND hzlo.location_id = hzps.location_id                     -- 顧客事業所.事業所ID = パーティサイト.事業所ID
        AND xffvv.flex_value = xxca.bill_base_code                  -- 部門値セット.コード = 顧客追加情報.請求拠点コード
      GROUP BY xxcot.col3,                                                                 -- 発行日付
               hzlo.postal_code,                                                           -- 郵便番号
               hzlo.state||hzlo.city,                                                      -- 住所１
               hzlo.address1,                                                              -- 住所２
               hzlo.address2,                                                              -- 住所３
               xxcot.col8,                                                                 -- 顧客コード
               hzpa.party_name,                                                            -- 顧客名
               xffvv.description,                                                          -- 拠点名
               xxcot.col12,                                                                -- 対象年月
               xxcot.col13,                                                                -- 売掛管理コード連結文字列
               xxcot.col14,                                                                -- 請求書出力区分
               xxcot.col18,                                                                -- 入金予定日
               xxcot.col19,                                                                -- 銀行名
               xxcot.col20,                                                                -- 支店名
               xxcot.col21,                                                                -- 口座種別
               xxcot.col22,                                                                -- 口座番号
               xxcot.col23,                                                                -- 口座名義人カナ名
               xxcot.col29,                                                                -- レイアウト区分
               xxcot.col103,                                                               -- 入金先顧客コード
               xxcot.col104;                                                               -- 入金先顧客名
--
      gn_target_cnt := gn_target_cnt + SQL%ROWCOUNT;
--
      -- 明細レコード更新(不要な項目値をクリアする)
      UPDATE xxcfr_csv_outs_temp xxcot
      SET col12 = NULL,                          -- 対象年月
          col13 = NULL,                          -- 売掛管理コード連結文字列
          col14 = NULL,                          -- 請求書出力区分
          col18 = NULL,                          -- 入金予定日
          col19 = NULL,                          -- 振込先銀行名
          col20 = NULL,                          -- 振込先銀行支店名
          col21 = NULL,                          -- 振込先口座種別
          col22 = NULL,                          -- 振込先口座番号
          col23 = NULL                           -- 振込先口座名義人カナ名
      WHERE xxcot.request_id = cn_request_id
        AND xxcot.col2 = cv_record_kbn1;         -- レコード区分 = '1'(明細レコード)
--
/*
      INSERT INTO xxcfr_csv_outs_temp(
        request_id       -- 要求ID
       ,seq              -- 出力順
       ,col1             -- 発行日付
       ,col2             -- 郵便番号
       ,col3             -- 住所1
       ,col4             -- 住所2
       ,col5             -- 住所3
       ,col6             -- 顧客コード
       ,col7             -- 顧客名
       ,col8             -- 担当拠点名
       ,col9             -- 電話番号
       ,col10            -- 対象年月
       ,col11            -- 売掛管理コード連結文字列
       ,col12            -- 請求書出力区分
       ,col13            -- 当月お買上げ額
       ,col14            -- 消費税等
       ,col15            -- 当月請求額
       ,col16            -- 入金予定日
       ,col17            -- 振込口座
       ,col18            -- 伝票日付
       ,col19            -- 伝票No
       ,col20)           -- 伝票金額
      SELECT
             bill.request_id       -- 要求ID
            ,ROWNUM                -- 表示順
            ,bill.issue_date       -- 発行日付
            ,bill.zip_code         -- 郵便番号
            ,bill.send_address1    -- 住所１
            ,bill.send_address2    -- 住所２
            ,bill.send_address3    -- 住所３
            ,bill.bill_cust_code   -- 顧客コード
            ,bill.bill_cust_name   -- 顧客名
            ,bill.location_name    -- 担当拠点名
            ,bill.phone_num        -- 電話番号
            ,bill.target_date      -- 対象年月
            ,bill.ar_concat_text   -- 売掛管理コード連結文字列
            ,bill.out_put_div      -- 請求書出力区分
            ,bill.inv_amount       -- 当月お買上げ額
            ,bill.tax_amount       -- 消費税等
            ,bill.total_amount     -- 当月請求額
            ,bill.payment_due_date -- 入金予定日
            ,bill.account_data     -- 振込口座情報
            ,bill.line_date        -- 伝票日付
            ,bill.line_number      -- 伝票No
            ,bill.line_amount      -- 伝票金額
      FROM
             (SELECT
                     cn_request_id                                        request_id       -- 要求ID
                    ,TO_CHAR(xih.inv_creation_date,gv_format_date_jpymd4) issue_date       -- 発行日付
                    ,DECODE(xih.postal_code,
                            NULL,NULL,
                            gv_format_zip_mark ||
                              SUBSTR(xih.postal_code,1,3) || '-' || 
                              SUBSTR(xih.postal_code,4,4))                zip_code         -- 郵便番号
                    ,xih.send_address1                                    send_address1    -- 住所１
                    ,xih.send_address2                                    send_address2    -- 住所２
                    ,xih.send_address3                                    send_address3    -- 住所３
                    ,xih.bill_cust_code                                   bill_cust_code   -- 顧客コード
                    ,xih.send_to_name                                     bill_cust_name   -- 顧客名
                    ,xih.bill_location_name                               location_name    -- 担当拠点名
                    ,xih.agent_tel_num                                    phone_num        -- 電話番号
                    ,SUBSTR(xih.object_month,1,4)||gv_format_date_year||
                       SUBSTR(xih.object_month,5,2)||gv_format_date_month target_date      -- 対象年月
                    ,xih.payment_cust_code || ' ' ||
                       xih.bill_cust_code  || ' ' ||
                       xih.term_name                                      ar_concat_text   -- 売掛管理コード連結文字列
                    ,CASE
                     WHEN xbcv.tax_div IN (cv_tax_div_nontax
                                          ,cv_tax_div_excluded)
                     THEN
                          cv_out_div_excluded
                     ELSE
                          cv_out_div_included
                     END                                                  out_put_div      -- 請求書出力区分
                    ,xih.inv_amount_no_tax                                inv_amount       -- 当月お買上げ額
                    ,xih.tax_amount_sum                                   tax_amount       -- 消費税等
                    ,xih.inv_amount_includ_tax                            total_amount     -- 当月請求額
                    ,TO_CHAR(xih.payment_date, gv_format_date_jpymd2)     payment_due_date -- 入金予定日
                    ,CASE WHEN bank.bank_account_num IS NULL THEN
                       NULL
                     ELSE
                       DECODE(SUBSTR(bank.bank_number,1,1)
                             ,gv_format_bank_dummy, NULL -- ダミー銀行の場合はNULL
                             ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                CASE WHEN INSTR(bank.bank_name
                                               ,gv_format_bank) > 0
                                THEN
                                  bank.bank_name
                                ELSE
                                  bank.bank_name || gv_format_bank
                                END
                              ELSE
                                bank.bank_name 
                              END || ' ' ||                                    -- 銀行名
                              CASE WHEN INSTR(bank.bank_branch_name
                                             ,gv_format_central) > 0
                              THEN
                                bank.bank_branch_name
                              ELSE
                                bank.bank_branch_name || gv_format_branch
                              END || ' ' ||                                    -- 支店名
                              DECODE(bank.bank_account_type
                                    ,1, gv_format_account
                                    ,2, gv_format_current
                                    ,bank.bank_account_type) || ' ' ||         -- 口座種別
                              bank.bank_account_num || ' ' ||                  -- 口座番号
                              bank.account_holder_name || ' ' ||               -- 口座名義人
                              bank.account_holder_name_alt)                    -- 口座名義人カナ名
                     END                                                  account_data     -- 振込口座情報
                    ,TO_CHAR(DECODE(xil.acceptance_date
                                   ,NULL, xil.delivery_date
                                   ,xil.acceptance_date)
                            ,cv_format_date_ymd)                          line_date        -- 伝票日付
                    ,xil.slip_num                                         line_number      -- 伝票No
                    ,SUM(CASE
                         WHEN xbcv.tax_div IN (cv_tax_div_nontax
                                              ,cv_tax_div_excluded)
                         THEN
                              xil.ship_amount
                         ELSE
                              xil.tax_amount + xil.ship_amount
                         END)                                             line_amount      -- 伝票金額
              FROM
                     xxcfr_invoice_headers          xih                     -- 請求ヘッダ
                    ,xxcfr_invoice_lines            xil                     -- 請求明細
                    ,xxcfr_bill_customers_v         xbcv                    -- 請求先顧客ビュー
                    ,(SELECT
                             rcrm.customer_id             customer_id
                            ,abb.bank_number              bank_number
                            ,abb.bank_name                bank_name
                            ,abb.bank_branch_name         bank_branch_name
                            ,abaa.bank_account_type       bank_account_type
                            ,abaa.bank_account_num        bank_account_num
                            ,abaa.account_holder_name     account_holder_name
                            ,abaa.account_holder_name_alt account_holder_name_alt
                      FROM
                             ra_cust_receipt_methods        rcrm                 --支払方法情報
                            ,ar_receipt_method_accounts_all arma                 --AR支払方法口座
                            ,ap_bank_accounts_all           abaa                 --銀行口座
                            ,ap_bank_branches               abb                  --銀行支店
                      WHERE
                             rcrm.primary_flag      = cv_flag_yes
                        AND  gd_target_date   BETWEEN rcrm.start_date
                                                  AND NVL(rcrm.end_date, gd_max_date)
                        AND  rcrm.site_use_id      IS NOT NULL
                        AND  rcrm.receipt_method_id = arma.receipt_method_id(+)
                        AND  arma.bank_account_id   = abaa.bank_account_id(+)
                        AND  abaa.bank_branch_id    = abb.bank_branch_id(+)
                        AND  arma.org_id            = gn_org_id
                        AND  abaa.org_id            = gn_org_id) bank            -- 銀行口座ビュー
              WHERE
                    xih.invoice_id      = xil.invoice_id                         -- 一括請求書ID
                AND xih.cutoff_date     = gd_target_date                         -- パラメータ．締日
                AND xih.set_of_books_id = gn_set_of_bks_id                       -- 会計帳簿ID
                AND xih.org_id          = gn_org_id                              -- 組織ID
                AND EXISTS (SELECT
                                   1
                            FROM
                                   xxcfr_bill_customers_v xb                     -- 請求先顧客ビュー
                            WHERE
                                   xih.bill_cust_code    = xb.bill_customer_code
                              AND  xb.inv_prt_type       = cv_inv_prt_type       -- 請求書出力形式
                              AND  xb.cons_inv_flag      = cv_flag_yes           -- 一括請求フラグ
                              AND  xb.bill_customer_code = NVL(iv_bill_cust_code, xb.bill_customer_code))
                AND xih.bill_cust_code   = xbcv.bill_customer_code
                AND xbcv.pay_customer_id = bank.customer_id(+)
              GROUP BY cn_request_id
                      ,TO_CHAR(xih.inv_creation_date,gv_format_date_jpymd4)
                      ,DECODE(xih.postal_code,
                              NULL,NULL,
                              gv_format_zip_mark ||
                                SUBSTR(xih.postal_code,1,3) || '-' ||
                                SUBSTR(xih.postal_code,4,4))
                      ,xih.send_address1
                      ,xih.send_address2
                      ,xih.send_address3
                      ,xih.bill_cust_code
                      ,xih.send_to_name
                      ,xih.bill_location_name
                      ,xih.agent_tel_num
                      ,SUBSTR(xih.object_month,1,4)||gv_format_date_year||
                         SUBSTR(xih.object_month,5,2)||gv_format_date_month
                      ,xih.payment_cust_code || ' ' ||
                         xih.bill_cust_code  || ' ' ||
                         xih.term_name
                      ,CASE
                       WHEN xbcv.tax_div IN (cv_tax_div_nontax
                                            ,cv_tax_div_excluded)
                       THEN
                            cv_out_div_excluded
                       ELSE
                            cv_out_div_included
                       END
                      ,xih.inv_amount_no_tax
                      ,xih.tax_amount_sum
                      ,xih.inv_amount_includ_tax
                      ,TO_CHAR(xih.payment_date, gv_format_date_jpymd2)
                      ,CASE WHEN bank.bank_account_num IS NULL THEN
                         NULL
                       ELSE
                         DECODE(SUBSTR(bank.bank_number,1,1)
                               ,gv_format_bank_dummy, NULL
                               ,CASE WHEN TO_NUMBER(bank.bank_number) < 1000  THEN
                                  CASE WHEN INSTR(bank.bank_name
                                                 ,gv_format_bank) > 0
                                  THEN
                                    bank.bank_name
                                  ELSE
                                    bank.bank_name || gv_format_bank
                                  END
                                ELSE
                                  bank.bank_name
                                END || ' ' ||
                                CASE WHEN INSTR(bank.bank_branch_name
                                               ,gv_format_central) > 0
                                THEN
                                  bank.bank_branch_name
                                ELSE
                                  bank.bank_branch_name || gv_format_branch
                                END || ' ' ||
                                DECODE(bank.bank_account_type
                                      ,1, gv_format_account
                                      ,2, gv_format_current
                                      ,bank.bank_account_type) || ' ' ||
                                bank.bank_account_num || ' ' ||
                                bank.account_holder_name || ' ' ||
                                bank.account_holder_name_alt)
                       END
                      ,TO_CHAR(DECODE(xil.acceptance_date
                                     ,NULL, xil.delivery_date
                                     ,xil.acceptance_date)
                              ,cv_format_date_ymd)
                      ,xil.slip_num
              ORDER BY
                       bill_cust_code
                      ,line_date
                      ,line_number) bill;
--
      gn_target_cnt := SQL%ROWCOUNT;
--
*/
-- Modify 2009-09-29 Ver1.10 End
      -- 登録データが１件も存在しない場合、０件メッセージログ出力
      IF (gn_target_cnt = 0) THEN
--
        -- 警告終了
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr
                              ,iv_name         => cv_msg_xxcfr_00024)  -- 対象データ0件警告
                            ,1
                            ,5000);
--
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_errmsg
        );
--
        ov_retcode := cv_status_warn;
--
      END IF;
--
    EXCEPTION
      -- 登録時エラー
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(
                               iv_application  => cv_msg_kbn_cfr
                              ,iv_name         => cv_msg_xxcfr_00016                            -- テーブル挿入エラー
                              ,iv_token_name1  => cv_tkn_table                                  -- トークン：テーブル名
                              ,iv_token_value1 => xxcfr_common_pkg.get_table_comment(cv_table)) -- ワークテーブル
                            ,1
                            ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        raise global_api_expt;
    END;
--
    -- 成功件数の設定
    gn_normal_cnt := gn_target_cnt;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_work_table;
--
  /**********************************************************************************
   * Procedure Name   : chk_account_data
   * Description      : 口座情報取得チェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_account_data(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_account_data'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt    NUMBER DEFAULT 0; -- 対象件数
    lv_warn_msg      VARCHAR2(5000);
    lv_cust_data_msg VARCHAR2(5000);
    lv_warn_bill_num VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- 口座情報なし明細抽出
-- Modify 2009-09-29 Ver1.10 Start
    CURSOR sel_no_account_data_cur
    IS
      SELECT
            -- xcot.col6 bill_cust_code
             xcot.col103 payment_cust_code   -- 入金先顧客コード
            --,xcot.col7 bill_cust_name
            ,xcot.col104 payment_cust_name   -- 入金先顧客名
            --,xcot.col8 bill_location_name
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- 要求ID
        AND  xcot.col1 = cv_header_kbn         -- ヘッダ/明細区分 = '1'(ヘッダー)
        --AND  xcot.col17      IS NULL
        AND  xcot.col19 IS NULL                -- 振込先銀行名 IS NULL
      GROUP BY --xcot.col6,
               xcot.col103,
               --xcot.col7,
               xcot.col104
               --xcot.col8
      ORDER BY --xcot.col6;
               xcot.col103;
-- Modify 2009-09-29 Ver1.10 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 請求書発行対象データが存在する場合以下の処理を実行
    IF (gn_target_cnt > 0) THEN
--      END IF;
      -- 口座情報なし明細抽出
      <<sel_no_account_loop>>
      FOR l_sel_no_account_data_rec IN sel_no_account_data_cur LOOP
--
        -- はじめに振込口座未登録メッセージを出力
        IF (sel_no_account_data_cur%ROWCOUNT = 1) THEN
        --１行改行
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''
        );
--
        -- 振込口座未登録メッセージ出力
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_xxcfr_00038)
                              ,1
                              ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        END IF;
--
        -- 顧客コード・顧客名メッセージ出力
        lv_cust_data_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00051
                                     ,iv_token_name1  => cv_tkn_ac_code
-- Modify 2009-09-29 Ver1.10 Start
                                     --,iv_token_value1 => l_sel_no_account_data_rec.bill_cust_code
                                     ,iv_token_value1 => l_sel_no_account_data_rec.payment_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     --,iv_token_value2 => l_sel_no_account_data_rec.bill_cust_name
-- Modify 2009-09-29 Ver1.10 End
                                     ,iv_token_value2 => l_sel_no_account_data_rec.payment_cust_name)
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_cust_data_msg
        );
--
        ln_target_cnt := sel_no_account_data_cur%ROWCOUNT;
--
      END LOOP sel_no_account_loop;
--
      -- 処理件数が1件以上合った場合
      IF (ln_target_cnt > 0) THEN
        -- 顧客コードの件数をメッセージ出力
        lv_warn_bill_num := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00052
                                     ,iv_token_name1  => cv_tkn_count
                                     ,iv_token_value1 => TO_CHAR(ln_target_cnt))
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_bill_num
        );
--
        --１行改行
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => ''
        );
--
        -- 警告終了
        ov_retcode := cv_status_warn;
--
      END IF;
--
    END IF;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_account_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_line_cnt_limit
   * Description      : 請求書明細件数チェック (A-5)
   ***********************************************************************************/
  PROCEDURE chk_line_cnt_limit(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_line_cnt_limit'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_target_cnt    NUMBER DEFAULT 0; -- 対象件数
    lv_warn_msg      VARCHAR2(5000);
    lv_cust_data_msg VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- 明細件数制限顧客情報抽出(店舗別内訳なし)
-- Modify 2009-09-29 Ver1.10 Start
    CURSOR line_cnt_limit_cur
    IS
      SELECT
            -- xcot.col6        bill_cust_code     -- 請求先顧客コード
             xcot.col8        bill_cust_code     -- 請求先顧客コード
            --,xcot.col7        bill_cust_name     -- 請求先顧客名
            ,xcot.col9        bill_cust_name     -- 請求先顧客名
            --,xcot.col8        bill_location_name -- 担当拠点名
            ,xcot.col10       bill_location_name -- 担当拠点名
            ,COUNT(xcot.col8) line_count         -- 明細件数
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- 要求ID
        AND  xcot.col29 = cv_layout_kbn1       -- レイアウト区分 = '1'(店舗別内訳なし)
      HAVING count(xcot.col8) > gn_line_cnt_limit
      GROUP BY --xcot.col6,
               xcot.col8,
               --xcot.col7,
               xcot.col9,
               --xcot.col8
               xcot.col10
      ORDER BY --xcot.col6;
               xcot.col8;
--
    CURSOR line_cnt_limit2_cur
    IS
      SELECT
             xcot.col8        bill_cust_code     -- 請求先顧客コード
            ,xcot.col9        bill_cust_name     -- 請求先顧客名
            ,xcot.col10       bill_location_name -- 担当拠点名
            ,COUNT(xcot.col8) line_count         -- 明細件数
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- 要求ID
        AND  xcot.col29 = cv_layout_kbn2       -- レイアウト区分 = '2'(店舗別内訳あり)
      HAVING count(xcot.col8) > gn_line_cnt_limit2
      GROUP BY xcot.col8,
               xcot.col9,
               xcot.col10
      ORDER BY xcot.col8;
-- Modify 2009-09-29 Ver1.10 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 請求書発行対象データが存在する場合以下の処理を実行
    IF (gn_target_cnt > 0) THEN
      -- 明細件数制限顧客情報抽出(店舗別内訳なし)
      <<sel_no_account_loop>>
      FOR l_line_cnt_limit_rec IN line_cnt_limit_cur LOOP
--
        -- はじめに請求書明細件数制限メッセージを出力
        IF (line_cnt_limit_cur%ROWCOUNT = 1) THEN
        --１行改行
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''
        );
--
        -- 請求書明細件数制限メッセージ出力
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_xxcfr_00071
                                ,iv_token_name1  => cv_tkn_rec_limit
                                ,iv_token_value1 => TO_CHAR(gn_line_cnt_limit))
                              ,1
                              ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        END IF;
--
        -- 顧客コード・顧客名メッセージ出力
        lv_cust_data_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00072
                                     ,iv_token_name1  => cv_tkn_ac_code
                                     ,iv_token_value1 => l_line_cnt_limit_rec.bill_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     ,iv_token_value2 => l_line_cnt_limit_rec.bill_cust_name
                                     ,iv_token_name3  => cv_tkn_lc_name
                                     ,iv_token_value3 => l_line_cnt_limit_rec.bill_location_name
                                     ,iv_token_name4  => cv_tkn_count
                                     ,iv_token_value4 => l_line_cnt_limit_rec.line_count)
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_cust_data_msg
        );
--
        ln_target_cnt := line_cnt_limit_cur%ROWCOUNT;
--
      END LOOP sel_no_account_loop;
--
-- Modify 2009-09-29 Ver1.10 Start
      -- 明細件数制限顧客情報抽出(店舗別内訳あり)
      <<sel_no_account_loop2>>
      FOR l_line_cnt_limit2_rec IN line_cnt_limit2_cur LOOP
--
        -- はじめに請求書明細件数制限メッセージを出力
        IF (line_cnt_limit2_cur%ROWCOUNT = 1) THEN
        --１行改行
        fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => ''
        );
--
        -- 請求書明細件数制限メッセージ出力
        lv_warn_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                 iv_application  => cv_msg_kbn_cfr
                                ,iv_name         => cv_msg_xxcfr_00071
                                ,iv_token_name1  => cv_tkn_rec_limit
                                ,iv_token_value1 => TO_CHAR(gn_line_cnt_limit2))
                              ,1
                              ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_warn_msg
        );
        END IF;
--
        -- 顧客コード・顧客名メッセージ出力
        lv_cust_data_msg := SUBSTRB(xxccp_common_pkg.get_msg(
                                      iv_application  => cv_msg_kbn_cfr
                                     ,iv_name         => cv_msg_xxcfr_00072
                                     ,iv_token_name1  => cv_tkn_ac_code
                                     ,iv_token_value1 => l_line_cnt_limit2_rec.bill_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     ,iv_token_value2 => l_line_cnt_limit2_rec.bill_cust_name
                                     ,iv_token_name3  => cv_tkn_lc_name
                                     ,iv_token_value3 => l_line_cnt_limit2_rec.bill_location_name
                                     ,iv_token_name4  => cv_tkn_count
                                     ,iv_token_value4 => l_line_cnt_limit2_rec.line_count)
                                   ,1
                                   ,5000);
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => lv_cust_data_msg
        );
--
        ln_target_cnt := ln_target_cnt + line_cnt_limit2_cur%ROWCOUNT;
--
      END LOOP sel_no_account_loop2;
-- Modify 2009-09-29 Ver1.10 End
--
      -- 処理件数が1件以上合った場合
      IF (ln_target_cnt > 0) THEN
        -- 警告終了
        ov_retcode := cv_status_warn;
--
      END IF;
--
    END IF;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END chk_line_cnt_limit;
--
  /**********************************************************************************
   * Procedure Name   : csv_file_output
   * Description      : ファイル出力処理(A-6)
   ***********************************************************************************/
  PROCEDURE csv_file_output(
    ov_errbuf        OUT VARCHAR2,
    ov_retcode       OUT VARCHAR2,
    ov_errmsg        OUT VARCHAR2
  )
  IS
--
--#######################  固定ローカル定数宣言部 START   #######################
--
    cv_prg_name   CONSTANT VARCHAR2(100) := 'csv_file_output';  -- プログラム名
--
--##############################  固定部 END   ##################################
    --===============================================================
    -- ローカル定数
    --===============================================================
    --===============================================================
    -- ローカル変数
    --===============================================================
--
--#######################  固定ローカル変数宣言部 START   #######################
--
    lv_retcode VARCHAR2(1);    -- 共通関数リターンコード
    lv_errbuf  VARCHAR2(5000); -- 共通関数エラーバッファ
    lv_errmsg  VARCHAR2(5000); -- 共通関数エラーメッセージ
--
--##############################  固定部 END   ##################################
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- OUTファイル出力処理実行
    xxcfr_common_pkg.csv_out(in_request_id  => cn_request_id,      -- 要求ID
                             iv_lookup_type => cv_lookup_type_out, -- 項目名用参照タイプ
                             in_rec_cnt     => gn_target_cnt,      -- 処理件数
                             ov_retcode     => lv_retcode,
                             ov_errbuf      => lv_errbuf,
                             ov_errmsg      => lv_errmsg
                            );
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg(cv_msg_kbn_cfr 
                                                   ,cv_msg_xxcfr_00010 -- 共通関数エラー
                                                   ,cv_tkn_func        -- トークン'機能名'
                                                   ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                      ,cv_dict_csv_out))
                                                   -- OUTファイル出力共通関数エラー
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数エラー発生時 ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END csv_file_output;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code14     IN      VARCHAR2,         -- 売掛管理先顧客
    ov_errbuf              OUT     VARCHAR2,         -- エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         -- リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         -- ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_errbuf_svf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode_svf VARCHAR2(1);     -- リターン・コード
    lv_errmsg_svf  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
       iv_target_date         -- 締日
      ,iv_customer_code10     -- 顧客
      ,iv_customer_code20     -- 請求書用顧客
      ,iv_customer_code21     -- 統括請求書用顧客
      ,iv_customer_code14     -- 売掛管理先顧客
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-2)
    -- =====================================================
    get_profile_value(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ワークテーブルデータ登録 (A-3)
    -- =====================================================
    insert_work_table(
       iv_target_date         -- 締日
      ,iv_customer_code10     -- 顧客
      ,iv_customer_code20     -- 請求書用顧客
      ,iv_customer_code21     -- 統括請求書用顧客
      ,iv_customer_code14     -- 売掛管理先顧客
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
-- Modify 2009-09-29 Ver1.10 Start
    ELSIF (gv_warning_flag = cv_status_yes) THEN  -- 顧客紐付け警告存在時
      ov_retcode := cv_status_warn;
-- Modify 2009-09-29 Ver1.10 End
    END IF;
--
    -- =====================================================
    --  口座情報取得チェック (A-4)
    -- =====================================================
    chk_account_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  請求書明細件数チェック (A-5)
    -- =====================================================
    chk_line_cnt_limit(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
    END IF;
--
    -- =====================================================
    --  ファイル出力処理 (A-6)
    -- =====================================================
    csv_file_output(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- エラー・メッセージ  #固定#
    retcode                OUT     VARCHAR2,         -- エラーコード        #固定#
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_customer_code10     IN      VARCHAR2,         -- 顧客
    iv_customer_code20     IN      VARCHAR2,         -- 請求書用顧客
    iv_customer_code21     IN      VARCHAR2,         -- 統括請求書用顧客
    iv_customer_code14     IN      VARCHAR2          -- 売掛管理先顧客
  )
--
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
    lv_errbuf2      VARCHAR2(5000);  -- エラー・メッセージ
--
--###########################  固定部 END   #############################
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_target_date     -- 締日
      ,iv_customer_code10 -- 顧客
      ,iv_customer_code20 -- 請求書用顧客
      ,iv_customer_code21 -- 統括請求書用顧客
      ,iv_customer_code14 -- 売掛管理先顧客
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- =====================================================
    --  終了処理 (A-7)
    -- =====================================================
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
--
      -- ユーザーエラーメッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --エラーメッセージ
      );
--
     --１行改行
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
--
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                      iv_application  => cv_msg_kbn_cfr
                     ,iv_name         => cv_msg_xxcfr_00056
                    );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
--
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000) --エラーメッセージ
      );
    END IF;
--
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_target_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_success_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_error_rec_msg
                   ,iv_token_name1  => cv_cnt_token
                   ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' -- エラーメッセージ
    );
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
--###########################  固定部 START   #####################################################
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCFR003A17C;
/
