CREATE OR REPLACE PACKAGE BODY XXCFR003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A05C(body)
 * Description      : 請求金額一覧表出力
 * MD.050           : MD050_CFR_003_A05_請求金額一覧表出力
 * MD.070           : MD050_CFR_003_A05_請求金額一覧表出力
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 入力パラメータ値ログ出力処理            (A-1)
 *  get_profile_value      p プロファイル取得処理                    (A-2)
 *  get_output_date        p 出力日取得処理                          (A-3)
 *  chk_inv_all_dept       P 全社出力権限チェック処理                (A-4)
 *  insert_work_table      p ワークテーブルデータ登録                (A-5)
 *  start_svf_api          p SVF起動                                 (A-6)
 *  delete_work_table      p ワークテーブルデータ削除                (A-7)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.00 SCS 大川 恵      初回作成
 *  2009/03/05    1.1  SCS 大川 恵      共通関数リリースに伴うSVF起動処理変更対応
 *                                      中間テーブルデータ削除処理コメントアウト削除対応
 *  2009/04/14    1.2  SCS 大川 恵      [障害T1_0533] 出力ファイル名変数文字列オーバーフロー対応
 *  2009/04/28    1.3  SCS 萱原 伸哉    [障害T1_0742] 伝票日付セット値修正対応
 *  2009/10/02    1.4  SCS 安川 智博    共通課題「IE535」対応
 *  2009/12/24    1.5  SCS 廣瀬 真佐人  [障害本稼動_00606] 期間中の顧客階層変更対応
 *  2014/11/05    1.6  SCSK 竹下 昭範   E_本稼動_12310 対応
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
  gn_warn_cnt      NUMBER;                    -- スキップ件数
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
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR003A05C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN';
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP';
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
  cv_msg_003a05_001  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00056'; -- システムエラーメッセージ
--
  cv_msg_003a05_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; -- プロファイル取得エラーメッセージ
  cv_msg_003a05_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; -- ロックエラーメッセージ
  cv_msg_003a05_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00007'; -- データ削除エラーメッセージ
  cv_msg_003a05_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00016'; -- テーブル挿入エラー
  cv_msg_003a05_014  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00023'; -- 帳票０件メッセージ
  cv_msg_003a05_015  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00011'; -- APIエラーメッセージ
  cv_msg_003a05_016  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00024'; -- 帳票０件ログメッセージ
  cv_msg_003a05_017  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; -- 値取得エラーメッセージ
  cv_msg_003a05_018  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00010'; -- 共通関数エラーメッセージ
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_api         CONSTANT VARCHAR2(15) := 'API_NAME';         -- API名
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- コメント
  cv_tkn_get_data    CONSTANT VARCHAR2(30) := 'DATA';             -- 取得対象データ
  cv_tkn_count       CONSTANT VARCHAR2(30) := 'COUNT';            -- カウント数
  cv_tkn_func        CONSTANT VARCHAR2(15) := 'FUNC_NAME';        -- 共通関数名
--
  -- 日本語辞書
  cv_dict_date       CONSTANT VARCHAR2(100) := 'CFR000A00003';    -- 日付パラメータ変換関数
  cv_dict_svf        CONSTANT VARCHAR2(100) := 'CFR000A00004';    -- SVF起動
  cv_dict_date_func  CONSTANT VARCHAR2(100) := 'CFR000A00002';    -- 営業日付取得関数
--
  --プロファイル
  cv_set_of_bks_id   CONSTANT VARCHAR2(30) := 'GL_SET_OF_BKS_ID'; -- 会計帳簿ID
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
--
  -- 使用DB名
  cv_table           CONSTANT VARCHAR2(50) := 'XXCFR_REP_INVOICE_LIST'; -- 請求金額一覧表帳票ワークテーブル
--
  -- 請求書タイプ
  cv_invoice_type    CONSTANT VARCHAR2(1)   := 'A';                     -- ‘A’(請求金額一覧表)
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10)  := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10)  := 'LOG';       -- ログ出力
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)   := 'Y';         -- 有効フラグ（Ｙ）
--
  cv_status_yes      CONSTANT VARCHAR2(1)   := '1';         -- 有効ステータス（1：有効）
  cv_status_no       CONSTANT VARCHAR2(1)   := '0';         -- 有効ステータス（0：無効）
-- ADD Ver1.6 Start
  cv_out_0           CONSTANT VARCHAR2(1)   := '0';         -- 入金基準
  cv_out_1           CONSTANT VARCHAR2(1)   := '1';         -- 請求基準
  cv_cust_kbn_10     CONSTANT VARCHAR2(2)   := '10';        -- 顧客区分：10
  cv_cust_kbn_14     CONSTANT VARCHAR2(2)   := '14';        -- 顧客区分：14
  cv_site_code_ship  CONSTANT VARCHAR2(7)   := 'SHIP_TO';   -- 使用目的：SHIP_TO
  cv_site_code_bill  CONSTANT VARCHAR2(7)   := 'BILL_TO';   -- 使用目的：BILL_TO
  cv_status_a        CONSTANT VARCHAR2(1)   := 'A';         -- ステータス：有効(A)
  cv_relate_bill     CONSTANT VARCHAR2(1)   := '1';         -- 顧客関連：請求関連(1)
  cv_acct_name_f     CONSTANT VARCHAR2(1)   := '0';         -- 顧客名称取得関数パラメータ(全角)
-- ADD Ver1.6 End
--
  cv_format_date_ymd    CONSTANT VARCHAR2(8)  := 'YYYYMMDD';             -- 日付フォーマット（年月日）
  cv_format_date_ymdhns CONSTANT VARCHAR2(25) := 'YYYY/MM/DD HH24:MI:SS';     -- 日付フォーマット（年月日時分秒
  cv_format_date_ymds   CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';           -- 日付フォーマット（年月日スラッシュ付）
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
-- ADD Ver1.6 Start
  gv_output_standard    VARCHAR2(8);                               -- パラメータ. 出力基準名
-- ADD Ver1.6 End
  gn_org_id             NUMBER;                                    -- 組織ID
  gn_set_of_bks_id      NUMBER;                                    -- 会計帳簿ID
  gv_output_date        VARCHAR2(19);                              -- 出力日
  gt_user_dept          per_all_people_f.attribute28%TYPE := NULL; -- ログインユーザ所属部門
  gv_inv_all_flag       VARCHAR2(1) := '0';                        -- 全社出力権限所持部門フラグ
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
-- ADD Ver1.6 Start
    iv_output_kbn          IN      VARCHAR2,         -- 出力基準
-- ADD Ver1.6 End
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_bill_cust_code      IN      VARCHAR2,         -- 売掛コード１(請求書)
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
-- ADD Ver1.6 Start
    cv_lookup_output_kbn  CONSTANT VARCHAR2(30) := 'XXCFR1_INV_OUT_STANDARD'; -- 請求書一覧出力基準
-- ADD Ver1.6 End
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
    -- パラメータ．締日をDATE型に変換する
    gd_target_date := TRUNC(xxcfr_common_pkg.get_date_param_trans(iv_target_date));
--
    IF (gd_target_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a05_018 -- 共通関数エラー
                                                    ,cv_tkn_func       -- トークン'FUNC_NAME'
                                                    ,xxcfr_common_pkg.lookup_dictionary(cv_msg_kbn_cfr
                                                                                       ,cv_dict_date_func))
                                                    -- 営業日付取得関数
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param( iv_which        => cv_file_type_log                            -- ログ出力
-- Modifiy Ver1.6 Start
--                                   ,iv_conc_param1  => TO_CHAR(gd_target_date,cv_format_date_ymds) -- コンカレントパラメータ１
--                                   ,iv_conc_param2  => iv_bill_cust_code                                 -- コンカレントパラメータ２
                                   ,iv_conc_param1  => iv_output_kbn                               -- コンカレントパラメータ１
                                   ,iv_conc_param2  => TO_CHAR(gd_target_date,cv_format_date_ymds) -- コンカレントパラメータ２
                                   ,iv_conc_param3  => iv_bill_cust_code                           -- コンカレントパラメータ３
-- Modifiy Ver1.6 End
                                   ,ov_errbuf       => ov_errbuf                                   -- エラー・メッセージ
                                   ,ov_retcode      => ov_retcode                                  -- リターン・コード
                                   ,ov_errmsg       => ov_errmsg);                                 -- ユーザー・エラー・メッセージ 
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- ADD Ver1.6 Start
    -- パラメータ．出力基準の名称を取得する
    BEGIN
      SELECT flva.description  AS output_standard
        INTO gv_output_standard
        FROM fnd_lookup_values  flva
       WHERE flva.lookup_code   = iv_output_kbn
         AND flva.lookup_type   = cv_lookup_output_kbn  -- 請求書一覧出力基準
         AND flva.language      = USERENV( 'LANG' )
         AND flva.enabled_flag  = cv_enabled_yes
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        gv_output_standard := NULL;
    END;
-- ADD Ver1.6 End
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
    -- プロファイルから会計帳簿ID取得
    gn_set_of_bks_id      := FND_PROFILE.VALUE(cv_set_of_bks_id);
--
    -- 取得エラー時
    IF (gn_set_of_bks_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a05_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_set_of_bks_id))
                                                     -- 会計帳簿ID
                          ,1
                          ,5000);
      RAISE global_api_expt;
    END IF;
--
    -- プロファイルから組織ID取得
    gn_org_id      := FND_PROFILE.VALUE(cv_org_id);
--
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a05_010 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                     -- 組織ID
                          ,1
                          ,5000);
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
   * Procedure Name   : get_output_date
   * Description      : 出力日取得処理 (A-3)
   ***********************************************************************************/
  PROCEDURE get_output_date(
    ov_errbuf   OUT  VARCHAR2,  -- 1.エラー・メッセージ           --# 固定 #
    ov_retcode  OUT  VARCHAR2,  -- 2.リターン・コード             --# 固定 #
    ov_errmsg   OUT  VARCHAR2)  -- 3.ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_output_date'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 帳票出力日として現在日時を取得、YYYY/MM/DD HH24:MI:SS形式で文字列として取得
    gv_output_date := TO_CHAR(SYSDATE,cv_format_date_ymdhns);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(
                            cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf
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
  END get_output_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_inv_all_dept
   * Description      : 全社出力権限チェック処理 (A-4)
   ***********************************************************************************/
  PROCEDURE chk_inv_all_dept(
    ov_errbuf           OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_inv_all_dept'; -- プログラム名
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
    cv_person_dff_name CONSTANT VARCHAR2(10)  := 'PER_PEOPLE';   -- 従業員マスタDFF名
    cv_peson_dff_att28 CONSTANT VARCHAR2(11)  := 'ATTRIBUTE28';  -- 従業員マスタDFF28(所属部署)カラム名
--
    -- *** ローカル変数 ***
    lv_token_value fnd_descr_flex_col_usage_vl.end_user_column_name%TYPE; -- 所属部門取得エラー時のメッセージトークン値
    lv_valid_flag  VARCHAR2(1) := 'N'; -- 有効フラグ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    get_user_dept_expt EXCEPTION;  -- ユーザ所属部門取得例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ログインユーザ所属部門取得処理
    gt_user_dept := xxcfr_common_pkg.get_user_dept(cn_created_by -- ユーザID
                                                  ,SYSDATE);     -- 取得日付
--
    -- 取得エラー時
    IF (gt_user_dept IS NULL) THEN
      RAISE get_user_dept_expt;
    END IF;
--
    -- 全社出力権限所持部門判定処理
      lv_valid_flag := xxcfr_common_pkg.chk_invoice_all_dept(gt_user_dept      -- 所属部門コード
                                                            ,cv_invoice_type); -- 請求書タイプ
      IF lv_valid_flag = cv_enabled_yes THEN
        gv_inv_all_flag := '1';
      END IF;
--
  EXCEPTION
--
    -- *** 所属部門が取得できない場合 ***
    WHEN get_user_dept_expt THEN
      BEGIN
        SELECT ffcu.end_user_column_name
        INTO lv_token_value
        FROM fnd_descr_flex_col_usage_vl ffcu
        WHERE ffcu.descriptive_flexfield_name = cv_person_dff_name
          AND ffcu.application_column_name = cv_peson_dff_att28;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_003a05_017 -- 値取得エラー
                                                    ,cv_tkn_get_data   -- トークン'DATA'
                                                    ,lv_token_value)   -- 'ログインユーザ所属部門'
                          ,1
                          ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END chk_inv_all_dept;
--
  /**********************************************************************************
   * Procedure Name   : insert_work_table
   * Description      : ワークテーブルデータ登録 (A-5)
   ***********************************************************************************/
  PROCEDURE insert_work_table(
-- ADD Ver1.6 Start
    iv_output_kbn           IN   VARCHAR2,            -- 出力基準
-- ADD Ver1.6 End
    iv_target_date          IN   VARCHAR2,            -- 締日
    iv_bill_cust_code       IN   VARCHAR2,            -- 売掛コード１(請求書)
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
    cv_lookup_tax_type  CONSTANT VARCHAR2(30) := 'XXCMM_CSUT_SYOHIZEI_KBN'; -- 消費税区分
    cv_value_set_name   CONSTANT VARCHAR2(30) := 'XX03_DEPARTMENT' ;        -- 所属部門値セット名
--
    -- *** ローカル変数 ***
--
    ln_target_cnt   NUMBER := 0;    -- 対象件数
--
    lv_no_data_msg  VARCHAR2(5000); -- 帳票０件メッセージ
    lv_func_status  VARCHAR2(1);    -- SVF帳票共通関数(0件出力メッセージ)終了ステータス
--
    -- *** ローカル・カーソル ***
-- Add Ver1.6 Start
    -- 合計金額算出用カーソル
    CURSOR upd_rep_inv_cur
    IS
      SELECT xrsi.cutoff_date                         cutoff_date             -- 締日
            ,xrsi.bill_cust_code                      bill_cust_code          -- 請求先顧客
            ,xrsi.bill_location_code                  bill_location_code      -- 拠点
            ,SUM(xrsi.ship_amount + xrsi.tax_amount)  inv_amount_includ_tax   -- 請求額合計
            ,SUM(xrsi.ship_amount)                    inv_amount_no_tax       -- 本体額合計
            ,SUM(xrsi.tax_amount)                     tax_amount_sum          -- 税額合計
      FROM   xxcfr_rep_invoice_list xrsi       -- 請求金額一覧表帳票ワークテーブル
      WHERE  xrsi.request_id = cn_request_id   -- 要求ID
      GROUP BY
             xrsi.cutoff_date
            ,xrsi.bill_cust_code
            ,xrsi.bill_location_code
      ;
--
    lt_upd_rep_inv_rec    upd_rep_inv_cur%ROWTYPE;
-- Add Ver1.6 End
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
    -- 帳票０件メッセージ取得
    -- ====================================================
    lv_no_data_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr      -- 'XXCFR'
                                                       ,cv_msg_003a05_014 ) -- 帳票０件メッセージ
                              ,1
                              ,5000);
--
    -- ====================================================
    -- ワークテーブルへの登録
    -- ====================================================
    BEGIN
--
    INSERT INTO xxcfr_rep_invoice_list(
       report_id              -- 帳票ID
      ,output_date            -- 出力日
      ,cutoff_date            -- 締日
      ,payment_cust_code      -- 売掛コード１(請求先)
      ,bill_location_code     -- 請求拠点コード
      ,bill_location_name     -- 請求拠点名
      ,tax_type               -- 消費税区分
      ,bill_cust_code         -- 請求先顧客コード
      ,bill_cust_name         -- 請求先顧客名
      ,bill_area_code         -- 請求先エリアコード
      ,inv_amount_includ_tax  -- 請求額合計
      ,tax_gap_amount         -- 税差額
      ,ship_shop_code         -- 店舗コード
      ,sold_location_code     -- 売上拠点コード
      ,sold_location_name     -- 売上拠点名
      ,sold_area_code         -- 売上エリアコード
      ,ship_cust_code         -- 納品先顧客コード
      ,ship_cust_name         -- 納品先顧客名
      ,slip_num               -- 伝票No
      ,delivery_date          -- 納品日
      ,ship_amount            -- 金額
      ,tax_amount             -- 税額
      ,data_empty_message     -- 0件メッセージ
      ,created_by             -- 作成者
      ,creation_date          -- 作成日
      ,last_updated_by        -- 最終更新者
      ,last_update_date       -- 最終更新日
      ,last_update_login      -- 最終更新ログイン
      ,request_id             -- 要求ID
      ,program_application_id -- コンカレント・プログラム・アプリケーションID
      ,program_id             -- コンカレント・プログラムID
-- Modify Ver1.6 Start
--      ,program_update_date  ) -- プログラム更新日
      ,program_update_date    -- プログラム更新日
      ,inv_amount_no_tax      -- 税抜請求額合計
      ,tax_amount_sum         -- 税額合計
      ,output_standard        -- 出力基準
    )
-- Modify Ver1.6 End
-- Modify Ver1.6 Start
--    SELECT cv_pkg_name,                                    -- 帳票ID
    SELECT /*+ LEADING(xih)
               USE_NL(xih xil flv ffvs ffvb2 xxca)
               INDEX(xih XXCFR_INVOICE_HEADERS_U01)
           */
           cv_pkg_name,                                    -- 帳票ID
-- Modify Ver1.6 End
           gv_output_date,                                 -- 出力日
           xih.cutoff_date           cutoff_date,           -- 締日
-- Modify Ver1.6 Start
--           xih.payment_cust_code     payment_cust_code,     -- 親請求先顧客コード
---- Modify 2009.10.02 Ver1.4 Start
--           --xih.bill_location_code    bill_location_code,    -- 請求拠点コード
--           xxca.receiv_base_code     bill_location_code,    -- 入金拠点コード
--           --xih.bill_location_name    bill_location_name,    -- 請求拠点名
--           ffvb.description          bill_location_name,    -- 入金拠点名
---- Modify 2009.10.02 Ver1.4 End
           xxca.bill_cred_rec_code1  payment_cust_code,     -- 親請求先顧客コード
           CASE
             -- パラメータ.出力基準='0'(入金拠点)の場合
             WHEN iv_output_kbn = cv_out_0 THEN
               xxca.receiv_base_code                            -- 入金
             -- 上記以外の場合
             ELSE
               xxca.bill_base_code                              -- 請求
           END                       bill_location_code,        -- 拠点コード
           CASE
             -- パラメータ.出力基準='0'(入金拠点)の場合
             WHEN iv_output_kbn = cv_out_0 THEN
               ffvb.description                                 -- 入金
             -- 上記以外の場合
             ELSE
               ffvb2.description                                -- 請求
           END                       bill_location_name ,       -- 拠点名
-- Modify Ver1.6 End
           flv.meaning               tax_type,              -- 消費税区分名
-- Modify Ver1.6 Start
--           xih.bill_cust_code        bill_cust_code,        -- 請求先顧客コード（ソート順４）
--           xih.bill_cust_name        bill_cust_name,        -- 請求先顧客名
           xxca.bill_cust_code       bill_cust_code,        -- 請求先顧客コード（ソート順４）
           -- 顧客名称取得関数から全角文字で顧客名取得
           xxcfr_common_pkg.get_cust_account_name(
                              xxca.bill_cust_code
                             ,cv_acct_name_f)
                                     bill_cust_name,        -- 請求先顧客名
-- Modify Ver1.6 End
-- Modify 2009.10.02 Ver1.4 Start
           --ffvb.attribute9           bill_area_code        ,-- 請求拠点本部コード
-- Modify Ver1.6 Start
--           CASE
--           WHEN NVL(TO_DATE(ffvb.attribute6,'YYYYMMDD'),gd_target_date) <= gd_target_date THEN
--             ffvb.attribute9
--           ELSE
--             ffvb.attribute7
--           END                       bill_area_code        ,-- 入金拠点本部コード
           CASE
             -- パラメータ.出力基準='0'(入金拠点)の場合
             WHEN iv_output_kbn = cv_out_0 THEN
               CASE
                 WHEN NVL(TO_DATE(ffvb.attribute6 ,'YYYYMMDD') ,gd_target_date) <= gd_target_date THEN
                   ffvb.attribute9
                 ELSE
                   ffvb.attribute7
               END
             -- 上記以外の場合
             ELSE
               CASE
                 WHEN NVL(TO_DATE(ffvb2.attribute6 ,'YYYYMMDD') ,gd_target_date) <= gd_target_date THEN
                   ffvb2.attribute9
                 ELSE
                   ffvb2.attribute7
               END
           END                       bill_area_code        ,-- 入金拠点本部コード
-- Modify Ver1.6 End
-- Modify 2009.10.02 Ver1.4 End
           xih.inv_amount_includ_tax inv_amount_includ_tax, -- 請求額合計
           xih.tax_gap_amount        tax_gap_amount ,       -- 税差額
           xil.ship_shop_code        ship_shop_code,        -- 店舗コード（ソート順６）
           xil.sold_location_code    sold_location_code,    -- 売上拠点コード
           xil.sold_location_name    sold_location_name,    -- 売上拠点名
-- Modify 2009.10.02 Ver1.4 Start
           --ffvs.attribute9           sold_area_code,        -- 売上拠点本部コード  
           CASE
           WHEN NVL(TO_DATE(ffvs.attribute6,'YYYYMMDD'),gd_target_date) <= gd_target_date THEN
             ffvs.attribute9
           ELSE
             ffvs.attribute7
           END                       sold_area_code,        -- 売上拠点本部コード
-- Modify 2009.10.02 Ver1.4 End
           xil.ship_cust_code        ship_cust_code,        -- 納品先顧客コード（ソート順７）
           xil.ship_cust_name        ship_cust_name,        -- 納品先顧客名
           xil.slip_num              slip_num,              -- 伝票no（ソート順９）
-- Modify 2009.04.28 Ver1.3 Start
--           xil.delivery_date         delivery_date,         -- 伝票日付（ソート順８）
           NVL(xil.acceptance_date , xil.delivery_date) delivery_date,  -- 伝票日付（ソート順８）
-- Modify 2009.04.28 Ver1.3 End
           SUM(xil.ship_amount)      ship_amount,           -- 金額
           SUM(xil.tax_amount)       tax_amount,            -- 税額
           NULL,                                           -- 0件メッセージ
           cn_created_by,                                  -- 作成者
           cd_creation_date,                               -- 作成日
           cn_last_updated_by,                             -- 最終更新者
           cd_last_update_date,                            -- 最終更新日
           cn_last_update_login,                           -- 最終更新ログイン
           cn_request_id,                                  -- 要求ID
           cn_program_application_id,                      -- コンカレント・プログラム・アプリケーションID
           cn_program_id,                                  -- コンカレント・プログラムID
-- Modify Ver1.6 Start
--           cd_program_update_date                          -- プログラム更新日
           cd_program_update_date,                         -- プログラム更新日
           xih.inv_amount_no_tax       inv_amount_no_tax,  -- 本体額合計
           xih.tax_amount_sum          tax_amount_sum,     -- 税額合計
           gv_output_standard          output_standard     -- 出力基準
-- Modify Ver1.6 End
    FROM xxcfr_invoice_headers          xih,  -- 請求ヘッダ
         xxcfr_invoice_lines            xil,  -- 請求明細
-- Modify Ver1.6 Start
---- Modify 2009.10.02 Ver1.4 Start
--         xxcmm_cust_accounts            xxca, -- 顧客追加情報
---- Modify 2009.10.02 Ver1.4 End
         (SELECT /*+ USE_NL(hca10 hcas10 hcsu10 xca hca14 hcas14 hcsu14 hcp) */
                 hca10.account_number    AS ship_cust_code      -- 出荷先顧客コード
                ,hca14.account_number    AS bill_cust_code      -- 請求先顧客コード
                ,xca.receiv_base_code    AS receiv_base_code    -- 入金拠点コード
                ,xca.bill_base_code      AS bill_base_code      -- 請求拠点コード
                ,hcsu14.attribute4       AS bill_cred_rec_code1 -- 売掛コード１
          FROM   hz_cust_accounts       hca10
                ,hz_cust_acct_sites_all hcas10
                ,hz_cust_site_uses_all  hcsu10
                ,xxcmm_cust_accounts    xca
                ,hz_cust_accounts       hca14
                ,hz_cust_acct_sites_all hcas14
                ,hz_cust_site_uses_all  hcsu14
                ,hz_customer_profiles   hcp
          WHERE  hca10.cust_account_id      = hcas10.cust_account_id
            AND  hca10.customer_class_code  = cv_cust_kbn_10       -- 顧客区分：10
            AND  hcas10.cust_acct_site_id   = hcsu10.cust_acct_site_id
            AND  hcas10.org_id              = gn_org_id
            AND  hcsu10.org_id              = gn_org_id
            AND  hcas14.org_id              = gn_org_id
            AND  hcsu14.org_id              = gn_org_id
            AND  hcsu10.site_use_code       = cv_site_code_ship    -- 使用目的：SHIP_TO
            AND  hcsu10.bill_to_site_use_id = hcsu14.site_use_id
            AND  hcsu14.site_use_code       = cv_site_code_bill    -- 使用目的：BILL_TO
            AND  hcsu14.cust_acct_site_id   = hcas14.cust_acct_site_id
            AND  hcas14.cust_account_id     = hca14.cust_account_id
            AND  hca14.cust_account_id      = xca.customer_id
            AND  hcsu14.site_use_id         = hcp.site_use_id
            AND  hca14.cust_account_id      = hcp.cust_account_id
            AND  hcp.cons_inv_flag          = cv_enabled_yes       -- 一括請求書フラグ「Y」
            AND (hca14.customer_class_code  = cv_cust_kbn_14       -- 顧客区分：14
            AND  EXISTS (
                   SELECT /*+ USE_NL(hcar) */ 'X'
                   FROM  hz_cust_acct_relate_all hcar
                   WHERE hcar.cust_account_id         = hca14.cust_account_id
                     AND hcar.related_cust_account_id = hca10.cust_account_id
                     AND hcar.attribute1              = cv_relate_bill -- 請求関連：1
                     AND hcar.status                  = cv_status_a    -- 有効：A
                ) OR hca14.customer_class_code  = cv_cust_kbn_10)
         )                              xxca,  -- 顧客追加情報ビュー
-- Modify Ver1.6 End
         (SELECT ffvv.flex_value flex_value
-- Modify 2009.10.02 Ver1.4 Start
                ,ffvv.description
                ,ffvv.attribute6
                ,ffvv.attribute7
-- Modify 2009.10.02 Ver1.4 End
                ,ffvv.attribute9 
          FROM fnd_flex_value_sets ffvs,
               fnd_flex_values_vl  ffvv
          WHERE ffvs.flex_value_set_name = cv_value_set_name
            AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         )                               ffvb, -- 入金拠点値セット値ビュー
-- ADD Ver1.6 Start
         (SELECT ffvv.flex_value  AS flex_value   -- 部門
                ,ffvv.description AS description  -- 部門名
                ,ffvv.attribute6  AS attribute6   -- 適用開始日
                ,ffvv.attribute7  AS attribute7   -- 本部コード(旧)
                ,ffvv.attribute9  AS attribute9   -- 本部コード(新)
          FROM   fnd_flex_value_sets  ffvs
                ,fnd_flex_values_vl   ffvv
          WHERE  ffvs.flex_value_set_name = cv_value_set_name
            AND  ffvs.flex_value_set_id   = ffvv.flex_value_set_id
         )                               ffvb2, -- 請求拠点値セット値ビュー
-- ADD Ver1.6 End
         (SELECT ffvv.flex_value flex_value
-- Modify 2009.10.02 Ver1.4 Start
                ,ffvv.attribute6
                ,ffvv.attribute7
-- Modify 2009.10.02 Ver1.4 Start
                ,ffvv.attribute9 
          FROM fnd_flex_value_sets ffvs,
               fnd_flex_values_vl  ffvv
          WHERE ffvs.flex_value_set_name = cv_value_set_name
            AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
         )                               ffvs, -- 売上拠点値セット値ビュー
         (SELECT flva.lookup_code,
                 flva.meaning
          FROM   fnd_lookup_values     flva
          WHERE  flva.lookup_type  = cv_lookup_tax_type
            AND flva.language  = USERENV( 'LANG' )
            AND flva.enabled_flag  = cv_enabled_yes
         )                               flv  -- 参照表（消費税区分）
    WHERE xih.invoice_id = xil.invoice_id  -- 一括請求書ID
      AND xih.cutoff_date = gd_target_date -- パラメータ．締日
-- Delete Ver1.6 Start
--      AND EXISTS (SELECT 'X'
--                    'X'
---- Modify 2009.10.02 Ver1.4 Start
---- Modify 2009.12.24 Ver1.5 Start
----                  FROM xxcfr_bill_customers_v xb,                      -- 請求先顧客ビュー
--                  FROM xxcfr_all_bill_customers_v xb,                     -- 顧客ビュー
---- Modify 2009.12.24 Ver1.5 End
---- Modify 2009.10.02 Ver1.4 Start
--                       xxcmm_cust_accounts    xca                      -- 顧客追加情報
---- Modify 2009.10.02 Ver1.4 End
---- Modify 2009.12.24 Ver1.5 Start
----                  WHERE xih.bill_cust_code = xb.bill_customer_code
------ Modify 2009.10.02 Ver1.4 Start
----                    AND xca.customer_code = xb.bill_customer_code
------ Modify 2009.10.02 Ver1.4 End
--                  WHERE xih.bill_cust_code = xb.customer_code
--                    AND xca.customer_code = xb.customer_code
---- Modify 2009.12.24 Ver1.5 End
--                    AND xb.cons_inv_flag = cv_enabled_yes             -- 一括請求書発行フラグ＝有効
---- Modify 2009.12.24 Ver1.5 Start
----                    AND (xb.bill_customer_code = NVL(iv_bill_cust_code,xb.bill_customer_code ) ) -- 請求先顧客コード
--                    AND (xb.customer_code = NVL(iv_bill_cust_code,xb.customer_code ) ) -- 請求先顧客コード
---- Modify 2009.12.24 Ver1.5 End
--                    AND ( (gv_inv_all_flag = cv_status_yes) OR
--                          (gv_inv_all_flag = cv_status_no AND 
---- Modify 2009.10.02 Ver1.4 Start
--                           --xb.bill_base_code = gt_user_dept) ) )      -- 請求拠点コード
--                           xca.receiv_base_code = gt_user_dept) ) )      -- 売掛管理先顧客の入金拠点コード
-- Delete Ver1.6 End
-- Modify 2009.10.02 Ver1.4 End
      AND xih.tax_type                = flv.lookup_code
-- Modify 2009.10.02 Ver1.4 Start
-- Modify Ver1.6 Start
--      AND xih.bill_cust_code = xxca.customer_code
      AND xil.ship_cust_code = xxca.ship_cust_code  -- 出荷先顧客コード
      AND xxca.bill_cust_code = NVL(iv_bill_cust_code, xxca.bill_cust_code )
      AND ( (gv_inv_all_flag = cv_status_yes) OR
            (gv_inv_all_flag = cv_status_no AND 
             gt_user_dept    = CASE
                                 -- パラメータ.出力基準='0'(入金拠点)の場合
                                 WHEN iv_output_kbn = cv_out_0 THEN
                                   xxca.receiv_base_code
                                 -- 上記以外の場合
                                 ELSE
                                   xxca.bill_base_code
                               END
                            ) )      -- 売掛管理先顧客の入金or請求拠点コード
-- Modify Ver1.6 End
      AND ffvb.flex_value(+) = xxca.receiv_base_code
      --AND ffvb.flex_value(+) = xih.bill_location_code
-- Modify 2009.10.02 Ver1.4 End
      AND ffvs.flex_value(+) = xil.sold_location_code
-- ADD Ver1.6 Start
      AND ffvb2.flex_value(+) = xxca.bill_base_code -- 請求拠点コード
-- ADD Ver1.6 End
      AND xih.set_of_books_id = gn_set_of_bks_id
      AND xih.org_id = gn_org_id
    GROUP BY  cv_pkg_name,
              gv_output_date,
              xih.cutoff_date           , -- 締日
-- Modify Ver1.6 Start
--              xih.payment_cust_code     , -- 親請求先顧客コード
---- Modify 2009.10.02 Ver1.4 Start
--              --xih.bill_location_code    , -- 請求拠点コード
--              xxca.receiv_base_code     , -- 入金拠点コード
--              --xih.bill_location_name    , -- 請求拠点名
--              ffvb.description          , -- 入金拠点名
---- Modify 2009.10.02 Ver1.4 End
              xxca.bill_cred_rec_code1,    -- 親請求先顧客コード
              CASE
                -- パラメータ.出力基準='0'(入金拠点)の場合
                WHEN iv_output_kbn = cv_out_0 THEN
                  xxca.receiv_base_code
                -- 上記以外の場合
                ELSE
                  xxca.bill_base_code
              END                       , -- 拠点コード
              CASE
                -- パラメータ.出力基準='0'(入金拠点)の場合
                WHEN iv_output_kbn = cv_out_0 THEN
                  ffvb.description
                -- 上記以外の場合
                ELSE
                  ffvb2.description
              END                       , -- 拠点名
-- Modify Ver1.6 End
              flv.meaning               , -- 消費税区分名
-- Modify Ver1.6 Start
--              xih.bill_cust_code        , -- 請求先顧客コード
--              xih.bill_cust_name        , -- 請求先顧客名
              xxca.bill_cust_code       , -- 請求先顧客コード
              xxcfr_common_pkg.get_cust_account_name(
                                 xxca.bill_cust_code
                                ,cv_acct_name_f)
                                        , -- 請求先顧客名
-- Modify Ver1.6 End
-- Modify 2009.10.02 Ver1.4 Start
              --ffvb.attribute9           , -- 請求拠点本部コード
-- Modify Ver1.6 Start
--              CASE
--              WHEN NVL(TO_DATE(ffvb.attribute6,'YYYYMMDD'),gd_target_date) <= gd_target_date THEN
--                ffvb.attribute9
--              ELSE
--                ffvb.attribute7
--              END                       , -- 入金拠点本部コード
           CASE
             -- パラメータ.出力基準='0'(入金拠点)の場合
             WHEN iv_output_kbn = cv_out_0 THEN
               CASE
                 WHEN NVL(TO_DATE(ffvb.attribute6 ,'YYYYMMDD') ,gd_target_date) <= gd_target_date THEN
                   ffvb.attribute9
                 ELSE
                   ffvb.attribute7
               END
             -- 上記以外の場合
             ELSE
               CASE
                 WHEN NVL(TO_DATE(ffvb2.attribute6 ,'YYYYMMDD') ,gd_target_date) <= gd_target_date THEN
                   ffvb2.attribute9
                 ELSE
                   ffvb2.attribute7
               END
           END                          , -- 入金拠点本部コード
-- Modify Ver1.6 End
-- Modify 2009.10.02 Ver1.4 End
              xih.inv_amount_includ_tax , -- 請求額合計
              xih.tax_gap_amount        , -- 税差額
              xil.ship_shop_code        , -- 店舗コード
              xil.sold_location_code    , -- 売上拠点コード
              xil.sold_location_name    , -- 売上拠点名
-- Modify 2009.10.02 Ver1.4 Start
              --ffvs.attribute9           , -- 売上拠点本部コード  
              CASE
              WHEN NVL(TO_DATE(ffvs.attribute6,'YYYYMMDD'),gd_target_date) <= gd_target_date THEN
                ffvs.attribute9
              ELSE
                ffvs.attribute7
              END                       , -- 売上拠点本部コード
-- Modify 2009.10.02 Ver1.4 End
              xil.ship_cust_code        , -- 納品先顧客コード
              xil.ship_cust_name        , -- 納品先顧客名
              xil.slip_num              , -- 伝票no
-- Modify 2009.04.28 Ver1.3 Start              
--              xil.delivery_date           -- 伝票日付
-- Modify Ver1.6 Start
--              NVL(xil.acceptance_date , xil.delivery_date)  -- 伝票日付
---- Modify 2009.04.28 Ver1.3 End
              NVL(xil.acceptance_date , xil.delivery_date)
                                        , -- 伝票日付
              xih.inv_amount_no_tax     , -- 本体額合計
              xih.tax_amount_sum        , -- 税額合計
              gv_output_standard          -- 出力基準
-- Modify Ver1.6 End
      ;
--
    -- 対象件数
    gn_target_cnt := SQL%ROWCOUNT;
--
-- Add Ver1.6 Start
      --***************************************************
      -- 合計額更新
      --***************************************************
      OPEN   upd_rep_inv_cur;
      --
      LOOP
        FETCH upd_rep_inv_cur INTO lt_upd_rep_inv_rec;
        EXIT WHEN upd_rep_inv_cur%NOTFOUND;
        -- 
        -- 改ページ条件で更新する
        UPDATE xxcfr_rep_invoice_list xril
        SET    inv_amount_includ_tax  = lt_upd_rep_inv_rec.inv_amount_includ_tax
              ,inv_amount_no_tax      = lt_upd_rep_inv_rec.inv_amount_no_tax
              ,tax_amount_sum         = lt_upd_rep_inv_rec.tax_amount_sum
        WHERE  xril.request_id          =  cn_request_id
          AND  xril.cutoff_date         =  lt_upd_rep_inv_rec.cutoff_date
          AND  xril.bill_cust_code      =  lt_upd_rep_inv_rec.bill_cust_code
          AND  xril.bill_location_code  =  lt_upd_rep_inv_rec.bill_location_code
        ;
        --
      END LOOP;
      --
      CLOSE  upd_rep_inv_cur;
      --
-- Add Ver1.6 End
--
      -- 登録データが１件も存在しない場合、０件メッセージレコード追加
      IF ( gn_target_cnt = 0 ) THEN
--
        INSERT INTO xxcfr_rep_invoice_list (
          output_date                  , -- 出力日
          cutoff_date                  , -- 締日
          bill_cust_code               , -- 請求先顧客コード
-- ADD Ver1.6 Start
          output_standard              , -- 出力基準
-- ADD Ver1.6 End
          data_empty_message           , -- 0件メッセージ
          created_by                   , -- 作成者
          creation_date                , -- 作成日
          last_updated_by              , -- 最終更新者
          last_update_date             , -- 最終更新日
          last_update_login            , -- 最終更新ログイン
          request_id                   , -- 要求ID
          program_application_id       , -- コンカレント・プログラム・アプリケーションID
          program_id                   , -- コンカレント・プログラムID
          program_update_date          ) -- プログラム更新日
        VALUES (
          gv_output_date               , -- 出力日
          gd_target_date               , -- 締日
          iv_bill_cust_code            , -- 請求先顧客コード
-- ADD Ver1.6 Start
          gv_output_standard           , -- 出力基準
-- ADD Ver1.6 End
          lv_no_data_msg               , -- 0件メッセージ
          cn_created_by                , -- 作成者
          cd_creation_date             , -- 作成日
          cn_last_updated_by           , -- 最終更新者
          cd_last_update_date          , -- 最終更新日
          cn_last_update_login         , -- 最終更新ログイン
          cn_request_id                , -- 要求ID
          cn_program_application_id    , -- コンカレント・プログラム・アプリケーションID
          cn_program_id                , -- コンカレント・プログラムID
          cd_program_update_date       );-- プログラム更新日
--
        -- 警告終了
        lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a05_016 )  -- 対象データ0件警告
                             ,1
                             ,5000);
        ov_errmsg  := lv_errmsg;
--
        ov_retcode := cv_status_warn;
--
      END IF;
--
    EXCEPTION
      WHEN OTHERS THEN  -- 登録時エラー
-- Add Ver1.6 Start
        IF ( upd_rep_inv_cur%ISOPEN ) THEN
            CLOSE upd_rep_inv_cur;
        END IF;
        --
 -- Add Ver1.6 End
       lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                       ,cv_msg_003a05_013    -- テーブル登録エラー
                                                       ,cv_tkn_table         -- トークン'TABLE'
                                                       ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                      -- 請求金額一覧表帳票ワークテーブル
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
   * Procedure Name   : start_svf_api
   * Description      : SVF起動 (A-6)
   ***********************************************************************************/
  PROCEDURE start_svf_api(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_svf_api'; -- プログラム名
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
    cv_svf_form_name  CONSTANT  VARCHAR2(20) := 'XXCFR003A05S.xml';  -- フォーム様式ファイル名
    cv_svf_query_name CONSTANT  VARCHAR2(20) := 'XXCFR003A05S.vrq';  -- クエリー様式ファイル名
    cv_output_mode    CONSTANT  VARCHAR2(1)   := '1';                -- 出力区分(=1：PDF出力）
    cv_extension_pdf  CONSTANT  VARCHAR2(4)  := '.pdf';              -- 拡張子（pdf）
--
    -- *** ローカル変数 ***
    lv_no_data_msg     VARCHAR2(5000);                               -- 帳票０件メッセージ
-- Modify 2009.04.14 Ver1.3 Start
--    lv_svf_file_name   VARCHAR2(30);                                 -- 出力ファイル名
    lv_svf_file_name   VARCHAR2(100);
-- Modify 2009.04.14 Ver1.3 END
    lv_file_id         VARCHAR2(30)  := NULL;
    lv_conc_name       VARCHAR2(30)  := NULL;
    lv_user_name       VARCHAR2(240) := NULL;
    lv_resp_name       VARCHAR2(240) := NULL;
    lv_svf_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    --  SVF起動 (A-6)
    -- =====================================================
--
    -- ファイル名の設定
    lv_svf_file_name := cv_pkg_name
                     || TO_CHAR ( cd_creation_date, cv_format_date_ymd )
                     || TO_CHAR ( cn_request_id )
                     || cv_extension_pdf;
--
    -- コンカレント名の設定
      lv_conc_name := cv_pkg_name;
--
    -- ファイル名の設定
      lv_file_id := cv_pkg_name;
--
    xxccp_svfcommon_pkg.submit_svf_request(
       ov_errbuf       => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_svf_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
      ,iv_conc_name    => lv_conc_name          -- コンカレント名
      ,iv_file_name    => lv_svf_file_name      -- 出力ファイル名
      ,iv_file_id      => lv_file_id            -- 帳票ID
      ,iv_output_mode  => cv_output_mode        -- 出力区分(=1：PDF出力）
      ,iv_frm_file     => cv_svf_form_name      -- フォーム様式ファイル名
      ,iv_vrq_file     => cv_svf_query_name     -- クエリー様式ファイル名
      ,iv_org_id       => gn_org_id             -- ORG_ID
      ,iv_user_name    => lv_user_name          -- ログイン・ユーザ名
      ,iv_resp_name    => lv_resp_name          -- ログイン・ユーザの職責名
      ,iv_doc_name     => NULL                  -- 文書名
      ,iv_printer_name => NULL                  -- プリンタ名
      ,iv_request_id   => cn_request_id         -- 要求ID
      ,iv_nodata_msg   => NULL                  -- データなしメッセージ
    );
    -- SVF起動APIの呼び出しはエラーか
    IF (lv_retcode = cv_status_error) THEN
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a05_015    -- APIエラー
                                                     ,cv_tkn_api           -- トークン'API_NAME'
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                        cv_msg_kbn_cfr
                                                       ,cv_dict_svf 
                                                      )  -- SVF起動
                                                    )
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| lv_errbuf ||cv_msg_part|| lv_svf_errmsg;
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
  END start_svf_api;
--
  /**********************************************************************************
   * Procedure Name   : delete_work_table
   * Description      : ワークテーブルデータ削除 (A-7)
   ***********************************************************************************/
  PROCEDURE delete_work_table(
    ov_errbuf               OUT  VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT  VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT  VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_work_table'; -- プログラム名
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
    ln_target_cnt   NUMBER;         -- 対象件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR del_rep_inv_cur
    IS
      SELECT xrsi.rowid        ln_rowid
      FROM xxcfr_rep_invoice_list xrsi -- 請求金額一覧表帳票ワークテーブル
      WHERE xrsi.request_id = cn_request_id  -- 要求ID
      FOR UPDATE NOWAIT;
--
    TYPE g_del_rep_inv_ttype IS TABLE OF ROWID INDEX BY PLS_INTEGER;
    lt_del_rep_inv_tab    g_del_rep_inv_ttype;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN del_rep_inv_cur;
--
    -- データの一括取得
    FETCH del_rep_inv_cur BULK COLLECT INTO lt_del_rep_inv_tab;
--
    -- 処理件数のセット
    ln_target_cnt := lt_del_rep_inv_tab.COUNT;
--
    -- カーソルクローズ
    CLOSE del_rep_inv_cur;
--
    -- 対象データが存在する場合レコードを削除する
    IF (ln_target_cnt > 0) THEN
      BEGIN
        <<data_loop>>
        FORALL ln_loop_cnt IN 1..ln_target_cnt
          DELETE FROM xxcfr_rep_invoice_list
          WHERE ROWID = lt_del_rep_inv_tab(ln_loop_cnt);
--
        -- コミット発行
        COMMIT;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                        ,cv_msg_003a05_012 -- データ削除エラー
                                                        ,cv_tkn_table         -- トークン'TABLE'
                                                        ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                        -- 請求金額一覧表帳票ワークテーブル
                              ,1
                              ,5000);
          lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
--
    END IF;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_003a05_011    -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
                                                     ,xxcfr_common_pkg.get_table_comment(cv_table))
                                                    -- 請求金額一覧表帳票ワークテーブル
                           ,1
                           ,5000);
      lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END delete_work_table;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
-- ADD Ver1.6 Start
   iv_output_kbn           IN      VARCHAR2,         -- 出力基準
-- ADD Ver1.6 End
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
    gn_warn_cnt   := 0;
--
    -- =====================================================
    --  初期処理(A-1)
    -- =====================================================
    init(
-- Modify Ver1.6 Start
--       iv_target_date         -- 締日
       iv_output_kbn          -- 出力基準
      ,iv_target_date         -- 締日
-- Modify Ver1.6 End
      ,iv_bill_cust_code            -- 売掛コード１(請求書)
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
    --  出力日取得処理(A-3)
    -- =====================================================
    get_output_date(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  全社出力権限チェック処理(A-4)
    -- =====================================================
    chk_inv_all_dept(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  ワークテーブルデータ登録 (A-5)
    -- =====================================================
    insert_work_table(
-- Modify Ver1.6 Start
--       iv_target_date         -- 締日
       iv_output_kbn          -- 出力基準
      ,iv_target_date         -- 締日
-- Modify Ver1.6 End
      ,iv_bill_cust_code            -- 売掛コード１(請求書)
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
    --  SVF起動 (A-6)
    -- =====================================================
    start_svf_api(
       lv_errbuf_svf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode_svf            -- リターン・コード             --# 固定 #
      ,lv_errmsg_svf);           -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- =====================================================
    --  ワークテーブルデータ削除 (A-7)
    -- =====================================================
    delete_work_table(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  SVF起動APIエラーチェック (A-8)
    -- =====================================================
    IF (lv_retcode_svf = cv_status_error) THEN
      --(エラー処理)
      lv_errmsg := lv_errmsg_svf;
      lv_errbuf := lv_errbuf_svf;
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
-- ADD Ver1.6 Start
    iv_output_kbn          IN      VARCHAR2,         -- 出力基準
-- ADD Ver1.6 End
    iv_target_date         IN      VARCHAR2,         -- 締日
    iv_bill_cust_code      IN      VARCHAR2          -- 売掛コード１(請求書)
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
-- Modify Ver1.6 Start
--       iv_target_date -- 締日
       iv_output_kbn  -- 出力基準
      ,iv_target_date -- 締日
-- Modify Ver1.6 End
      ,iv_bill_cust_code    -- 売掛コード１(請求書)
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
--###########################  固定部 START   #####################################################
--
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
    END IF;
--
    --エラーの場合、システムエラーメッセージ出力
    IF (lv_retcode = cv_status_error) THEN
      -- システムエラーメッセージ出力
      lv_errbuf2 := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cfr
                      ,iv_name         => cv_msg_003a05_001
                     );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf2 --エラーメッセージ
      );
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --ユーザー・エラーメッセージ
      );
      --１行改行
      fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => '' --ユーザー・エラーメッセージ
      );
    END IF;
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
      ,buff   => '' --ユーザー・エラーメッセージ
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
END XXCFR003A05C;
/
