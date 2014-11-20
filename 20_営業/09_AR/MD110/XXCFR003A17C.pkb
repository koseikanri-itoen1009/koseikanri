CREATE OR REPLACE PACKAGE BODY XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(body)
 * Description      : イセトー請求書データ作成
 * MD.050           : MD050_CFR_003_A17_イセトー請求書データ作成
 * MD.070           : MD050_CFR_003_A17_イセトー請求書データ作成
 * Version          : 1.00
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
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-23    1.00 SCS 白砂 幸世     新規作成
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
  cv_format_date_ymd  CONSTANT VARCHAR2(8)   := 'YY/MM/DD';                    -- 日付フォーマット（2桁年月日スラッシュ付）
--
  cv_max_date_value   CONSTANT VARCHAR2(10)  := '9999/12/31';                  -- 最大日付値
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
  gn_line_cnt_limit     NUMBER;                                    -- 請求書明細件数制限
  gn_org_id             NUMBER;                                    -- 組織ID
  gn_set_of_bks_id      NUMBER;                                    -- 会計帳簿ID
--
  -- 最大日付
  gd_max_date           DATE DEFAULT TO_DATE(cv_max_date_value, cv_format_date_ymd);
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
    iv_bill_cust_code      IN      VARCHAR2,         -- 請求先顧客コード
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
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log  -- ログ出力
                                   ,iv_conc_param1  => iv_target_date    -- コンカレントパラメータ１
                                   ,iv_conc_param2  => iv_bill_cust_code -- コンカレントパラメータ２
                                   ,ov_errbuf       => ov_errbuf         -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode        -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);       -- ユーザー・エラー・メッセージ 
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
  EXCEPTION
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
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ワークテーブルデータ登録 (A-3)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
    iv_target_date          IN   VARCHAR2,            -- 締日
    iv_bill_cust_code       IN   VARCHAR2,            -- 請求先顧客コード
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
    CURSOR sel_no_account_data_cur
    IS
      SELECT
             xcot.col6 bill_cust_code
            ,xcot.col7 bill_cust_name
            ,xcot.col8 bill_location_name
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- 要求ID
        AND  xcot.col17      IS NULL
      GROUP BY xcot.col6,
               xcot.col7,
               xcot.col8
      ORDER BY xcot.col6;
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
                                     ,iv_token_value1 => l_sel_no_account_data_rec.bill_cust_code
                                     ,iv_token_name2  => cv_tkn_ac_name
                                     ,iv_token_value2 => l_sel_no_account_data_rec.bill_cust_name
                                     ,iv_token_name3  => cv_tkn_lc_name
                                     ,iv_token_value3 => l_sel_no_account_data_rec.bill_location_name)
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
    -- 明細件数制限顧客情報抽出
    CURSOR line_cnt_limit_cur
    IS
      SELECT
             xcot.col6        bill_cust_code     -- 請求先顧客コード
            ,xcot.col7        bill_cust_name     -- 請求先顧客名
            ,xcot.col8        bill_location_name -- 担当拠点名
            ,COUNT(xcot.col6) line_count         -- 明細件数
      FROM
             xxcfr_csv_outs_temp  xcot
      WHERE
             xcot.request_id  = cn_request_id  -- 要求ID
      HAVING count(xcot.col6) > gn_line_cnt_limit
      GROUP BY xcot.col6,
               xcot.col7,
               xcot.col8
      ORDER BY xcot.col6;
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
      -- 明細件数制限顧客情報抽出
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
    iv_bill_cust_code      IN      VARCHAR2,         -- 請求先顧客コード
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
      ,iv_bill_cust_code      -- 請求先顧客コード
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
      ,iv_bill_cust_code      -- 請求先顧客コード
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF  (lv_retcode = cv_status_warn) THEN
      ov_retcode := cv_status_warn;
      ov_errmsg  := lv_errmsg;
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
    iv_bill_cust_code      IN      VARCHAR2          -- 請求先顧客
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
       iv_target_date    -- 締日
      ,iv_bill_cust_code -- 請求先顧客コード
      ,lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
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
