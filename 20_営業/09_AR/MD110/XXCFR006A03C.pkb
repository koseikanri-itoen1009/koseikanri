CREATE OR REPLACE PACKAGE BODY XXCFR006A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A03C(body)
 * Description      : 入金消込処理（HHT）
 * MD.050           : MD050_CFR_006_A03_入金消込処理（HHT）
 * MD.070           : MD050_CFR_006_A03_入金消込処理（HHT）
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 入力パラメータ値ログ出力処理            (A-1)
 *  get_process_date       p 業務処理日付取得処理                    (A-2)
 *  get_profile_value      p プロファイル取得処理                    (A-3)
 *  get_target_credit      p 対象債権総額処理                        (A-5)
 *  start_apply_api        p 入金消込API起動処理                     (A-7)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/03    1.00 SCS 高岡 健太    初回作成
 *  2009/02/12    1.1  SCS T.KANEDA     [障害COK_003] 入金額取得不具合対応
 *  2009/07/15    1.2  SCS M.HIROSE     [障害0000511] パフォーマンス改善
 *  2010/01/12    1.3  SCS 安川 智博    障害「E_本稼動_01136」対応
 *  2011/05/17    1.4  SCS 渡辺 学      障害「E_本稼動_07434」対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    --PROGRAM_UPDATE_DATE
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
  cv_msg_pnt       CONSTANT VARCHAR2(3) := ',';
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR006A03C'; -- パッケージ名
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR';
--
  -- メッセージ番号
  cv_msg_006a03_009  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00004'; --プロファイル取得エラーメッセージ
  cv_msg_006a03_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付取得エラーメッセージ
  cv_msg_006a03_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00036'; --入金消込APIエラーメッセージ
-- Modify 2010.01.12 Ver1.3 Start
  cv_msg_006a03_086  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00086'; --支払期日猶予日数未定義エラーメッセージ
  cv_msg_006a03_087  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00087'; --支払期日猶予日数数値エラーメッセージ
-- Modify 2010.01.12 Ver1.3 End
--
-- トークン
  cv_tkn_prof        CONSTANT VARCHAR2(15) := 'PROF_NAME';        -- プロファイル名
  cv_tkn_receipt_nm  CONSTANT VARCHAR2(15) := 'RECEIPT_NUMBER';   -- 入金番号
  cv_tkn_account     CONSTANT VARCHAR2(15) := 'ACCOUNT_CODE';     -- 顧客コード
  cv_tkn_meathod     CONSTANT VARCHAR2(15) := 'RECEIPT_MEATHOD';  -- 支払方法
  cv_tkn_receipt_dt  CONSTANT VARCHAR2(15) := 'RECEIPT_DATE';     -- 入金日
  cv_tkn_amount      CONSTANT VARCHAR2(15) := 'AMOUNT';           -- 入金額
  cv_tkn_trx_nm      CONSTANT VARCHAR2(15) := 'TRX_NUMBER';       -- 取引番号
-- Modify 2010.01.12 Ver1.3 Start
  cv_tkn_hht_lookup_type CONSTANT VARCHAR2(15) := 'LOOKUP_TYPE';  -- 参照タイプ
  cv_tkn_hht_lookup_code CONSTANT VARCHAR2(15) := 'LOOKUP_CODE';  -- 参照コード
-- Modify 2010.01.12 Ver1.3 End
--
  --プロファイル
  cv_org_id          CONSTANT VARCHAR2(30) := 'ORG_ID';           -- 組織ID
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';           -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';              -- ログ出力
--
  -- 書式フォーマット
  cv_format_date_ymd    CONSTANT VARCHAR2(10)  := 'YYYY/MM/DD';   -- 日付フォーマット（年月日）
--
  -- リテラル値
  cv_status_op        CONSTANT VARCHAR2(10) := 'OP';              -- ステータス：オープン
  cv_flag_y           CONSTANT VARCHAR2(10) := 'Y';               -- フラグ値：Y
--
--
  -- 参照タイプ
-- Modify 2010.01.12 Ver1.3 Start
  cv_hht_receipt_date CONSTANT fnd_lookup_values.lookup_type%TYPE := 'XXCFR1_HHT_RECEIPT_DATE'; -- 参照タイプ「HHT消込対象猶予期間」
  cv_date_from        CONSTANT fnd_lookup_values.lookup_code%TYPE := 'DATE_FROM';               -- 参照コード「支払期日前猶予日数」
  cv_date_to          CONSTANT fnd_lookup_values.lookup_code%TYPE := 'DATE_TO';                 -- 参照コード「支払期日後猶予日数」
-- Modify 2010.01.12 Ver1.3 End
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id             NUMBER;             -- 組織ID
  gd_process_date       DATE;               -- 業務処理日付
  gd_receipt_date       DATE;               -- 入金日
-- Modify 2010.01.12 Ver1.3 Start
  gn_hht_date_from      NUMBER;             -- 支払期日前猶予日数
  gn_hht_date_to        NUMBER;             -- 支払期日後猶予日数
-- Modify 2010.01.12 Ver1.3 End
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 入力パラメータ値ログ出力処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_receipt_date   IN      VARCHAR2,    -- 入金日
    ov_errbuf         OUT     VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT     VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg         OUT     VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル・例外 ***
-- Modify 2010.01.12 Ver1.3 Start
    hht_date_from_null_expt   EXCEPTION;  -- 参照コード「支払期日前猶予日数」定義なし例外
    hht_date_to_null_expt     EXCEPTION;  -- 参照コード「支払期日後猶予日数」定義なし例外
    hht_date_from_number_expt EXCEPTION;  -- 参照コード「支払期日前猶予日数」数値例外
    hht_date_to_number_expt   EXCEPTION;  -- 参照コード「支払期日後猶予日数」数値例外
-- Modify 2010.01.12 Ver1.3 End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
   ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,iv_conc_param1  => iv_receipt_date    -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- OUTファイル出力
      ,iv_conc_param1  => iv_receipt_date    -- コンカレントパラメータ１
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
-- Modify 2010.01.12 Ver1.3 Start
    -- 参照コード「支払期日前猶予日数」取得処理
    BEGIN
      SELECT NVL(TO_NUMBER(flvv.description),0) description
      INTO gn_hht_date_from
      FROM fnd_lookup_values_vl flvv
      WHERE flvv.lookup_type = cv_hht_receipt_date
        AND flvv.lookup_code = cv_date_from
        AND flvv.enabled_flag = cv_flag_y
        AND SYSDATE BETWEEN NVL(flvv.start_date_active,SYSDATE) AND NVL(flvv.end_date_active,SYSDATE);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE hht_date_from_null_expt;
      WHEN INVALID_NUMBER THEN
        RAISE hht_date_from_number_expt;
    END;
--
    -- 参照コード「支払期日後猶予日数」取得処理
    BEGIN
      SELECT NVL(TO_NUMBER(flvv.description),0) description
      INTO gn_hht_date_to
      FROM fnd_lookup_values_vl flvv
      WHERE flvv.lookup_type = cv_hht_receipt_date
        AND flvv.lookup_code = cv_date_to
        AND flvv.enabled_flag = cv_flag_y
        AND SYSDATE BETWEEN NVL(flvv.start_date_active,SYSDATE) AND NVL(flvv.end_date_active,SYSDATE);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE hht_date_to_null_expt;
      WHEN INVALID_NUMBER THEN
        RAISE hht_date_to_number_expt;
    END;
-- Modify 2010.01.12 Ver1.3 End    
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
-- Modify 2010.01.12 Ver1.3 Start
    -- *** 参照コード「支払期日前猶予日数」定義なし例外ハンドラ ***
    WHEN hht_date_from_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_086,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_from);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 参照コード「支払期日後猶予日数」定義なし例外ハンドラ ***
    WHEN hht_date_to_null_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_086,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_to);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 参照コード「支払期日前猶予日数」数値例外ハンドラ ***
    WHEN hht_date_from_number_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_087,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_from);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 参照コード「支払期日後猶予日数」数値例外ハンドラ ***
    WHEN hht_date_to_number_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(iv_application => cv_msg_kbn_cfr,
                                            iv_name => cv_msg_006a03_087,
                                            iv_token_name1 => cv_tkn_hht_lookup_type,
                                            iv_token_value1 => cv_hht_receipt_date,
                                            iv_token_name2 => cv_tkn_hht_lookup_code,
                                            iv_token_value2 => cv_date_to);
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,5000);
      ov_retcode := cv_status_error;
-- Modify 2010.01.12 Ver1.3 End
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
   * Procedure Name   : get_process_date
   * Description      : 業務処理日付取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_process_date(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_process_date'; -- プログラム名
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 業務処理日付取得処理
    gd_process_date := trunc ( xxccp_common_pkg2.get_process_date );
--
    -- 取得エラー時
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_006a03_010 -- 業務処理日付取得エラー
                                                    )
                                                    ,1
                                                    ,5000);
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
  END get_process_date;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_value
   * Description      : プロファイル取得処理 (A-3)
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- プロファイルから組織ID取得
    gn_org_id      := TO_NUMBER(FND_PROFILE.VALUE(cv_org_id));
    -- 取得エラー時
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfr    -- 'XXCFR'
                                                    ,cv_msg_006a03_009 -- プロファイル取得エラー
                                                    ,cv_tkn_prof       -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name(cv_org_id))
                                                       -- 組織ID
                                                   ,1
                                                   ,5000);
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
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
   * Procedure Name   : get_target_credit
   * Description      : 対象債権総額処理 (A-5)
   ***********************************************************************************/
  PROCEDURE get_target_credit(
    in_pay_from_customer IN  NUMBER,              -- 顧客ID
    id_receipt_date      IN  DATE,                -- 入金日
    on_target_credit     OUT NUMBER,              -- 対象債権総額
    ov_errbuf            OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode           OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg            OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_credit'; -- プログラム名
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 対象債権総額初期化
    on_target_credit := 0;
--
    -- 対象債権総額取得
    SELECT 
-- Delete 2011.05.17 Ver1.4 Start
---- Modify 2009.07.15 Ver1.2 Start
--           /*+ INDEX(rcta RA_CUSTOMER_TRX_N11)
--               INDEX(apsa AR_PAYMENT_SCHEDULES_N2)
--           */
---- Modify 2009.07.15 Ver1.2 End
-- Delete 2011.05.17 Ver1.4 End
-- Add 2011.05.17 Ver1.4 Start
           /*+
               LEADING(XCHVG APSA RCTA RADIST)
               USE_NL (XCHVG APSA RCTA RADIST)
               INDEX  (XCHVG   XXCFR_CUST_HIERARCHY_MV_N01)
               INDEX  (APSA    AR_PAYMENT_SCHEDULES_N6)
               INDEX  (RCTA    RA_CUSTOMER_TRX_U1)
               INDEX  (RADIST  RA_CUST_TRX_LINE_GL_DIST_N6)
           */
-- Add 2011.05.17 Ver1.4 End
           SUM(apsa.amount_due_remaining) sum_amount --未消込残高総額
    INTO on_target_credit
    FROM ra_customer_trx_all rcta,      --AR取引ヘッダテーブル
         ar_payment_schedules_all apsa, --AR支払計画テーブル
         ( SELECT xchv.bill_account_id bill_account_id  --請求先顧客ID
-- Modify 2011.05.17 Ver1.4 Start
--           FROM xxcfr_cust_hierarchy_v xchv             --顧客階層View
           FROM xxcfr_cust_hierarchy_mv xchv             --顧客階層マテリアライズドView
-- Modify 2011.05.17 Ver1.4 End
           WHERE xchv.cash_account_id  = in_pay_from_customer  --パラメータ：顧客ID
-- Delete 2011.05.17 Ver1.4 Start
--           GROUP BY xchv.bill_account_id
-- Delete 2011.05.17 Ver1.4 End
         ) xchvg --請求先顧客インラインビュー
    WHERE rcta.org_id              = gn_org_id
      AND rcta.customer_trx_id     = apsa.customer_trx_id
      AND rcta.complete_flag       = cv_flag_y
      AND apsa.status              = cv_status_op
-- Modify 2011.05.17 Ver1.4 Start
--      AND rcta.bill_to_customer_id = xchvg.bill_account_id
      AND xchvg.bill_account_id    = apsa.customer_id
-- Modify 2011.05.17 Ver1.4 End
-- Modify 2010.01.12 Ver1.3 Start
--      AND apsa.due_date            = id_receipt_date    --パラメータ：入金日
      AND apsa.due_date            >= id_receipt_date - gn_hht_date_from
      AND apsa.due_date            <= id_receipt_date + gn_hht_date_to
      AND rcta.trx_date            <= id_receipt_date
      AND EXISTS (SELECT 'X'
                  FROM ra_cust_trx_line_gl_dist_all radist
                  WHERE radist.customer_trx_id = rcta.customer_trx_id
                    AND radist.account_class = 'REV'
                    AND radist.gl_date <= id_receipt_date)
-- Modify 2010.01.12 Ver1.3 End
    ;
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
  END get_target_credit;
--
  /**********************************************************************************
   * Procedure Name   : start_apply_api
   * Description      : 入金消込API起動処理 (A-7)
   ***********************************************************************************/
  PROCEDURE start_apply_api(
    in_cash_receipt_id IN  NUMBER,   --   入金ID
    iv_receipt_number  IN  VARCHAR2, --   入金番号
    id_receipt_date    IN  DATE,     --   入金日
    in_amount          IN  NUMBER,   --   入金額
    iv_receipt_method  IN  VARCHAR2, --   支払方法
    iv_account_number  IN  VARCHAR2, --   顧客コード
    in_customer_trx_id IN  NUMBER,   --   取引ヘッダID
    iv_trx_number      IN  VARCHAR2, --   取引番号
    ov_errbuf          OUT VARCHAR2, --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2, --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2) --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'start_apply_api'; -- プログラム名
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
    lv_return_status   VARCHAR2(1);
    ln_msg_count       NUMBER;
    lv_msg_data        VARCHAR2(2000);
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- 入金消込API起動
    ar_receipt_api_pub.apply(
       p_api_version     =>  1.0
      ,p_init_msg_list   =>  FND_API.G_TRUE
      ,x_return_status   =>  lv_return_status
      ,x_msg_count       =>  ln_msg_count
      ,x_msg_data        =>  lv_msg_data
      ,p_customer_trx_id =>  in_customer_trx_id --取引ヘッダID
      ,p_cash_receipt_id =>  in_cash_receipt_id --入金ID
      ,p_apply_date      =>  id_receipt_date    --消込日
      ,p_apply_gl_date   =>  id_receipt_date    --GL記帳日
      );
--
    IF (lv_return_status <> 'S') THEN
      --エラー処理
      lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg(
                               cv_msg_kbn_cfr      -- 'XXCFR'
                              ,cv_msg_006a03_011
                              ,cv_tkn_receipt_nm   -- トークン'RECEIPT_NUMBER'
                              ,iv_receipt_number
                                -- 入金番号
                              ,cv_tkn_account      -- トークン'ACCOUNT_CODE'
                              ,iv_account_number
                                -- 顧客コード
                              ,cv_tkn_meathod      -- トークン'RECEIPT_MEATHOD'
                              ,iv_receipt_method
                                -- 支払方法
                              ,cv_tkn_receipt_dt   -- トークン'RECEIPT_DATE'
                              ,TO_CHAR(id_receipt_date, cv_format_date_ymd)
                                -- 入金日
                              ,cv_tkn_amount       -- トークン'AMOUNT'
                              ,in_amount
                                -- 入金額
                              ,cv_tkn_trx_nm       -- トークン'TRX_NUMBER'
                              ,iv_trx_number
                                -- 取引番号
                            )
                           ,1
                           ,5000
                          );
      -- 入金消込APIエラーメッセージ出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
--
      -- API標準エラーメッセージ出力
      IF (ln_msg_count = 1) THEN
        -- API標準エラーメッセージが１件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '・' || lv_msg_data
        );
--
      ELSE
        -- API標準エラーメッセージが複数件の場合
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_FIRST, FND_API.G_FALSE)
                                       ,1
                                       ,5000
                                     )
        );
        ln_msg_count := ln_msg_count - 1;
        
        <<while_loop>>
        WHILE ln_msg_count > 0 LOOP
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => '・' || SUBSTRB( FND_MSG_PUB.GET(FND_MSG_PUB.G_NEXT, FND_API.G_FALSE)
                                         ,1
                                         ,5000
                                       )
          );
          
          ln_msg_count := ln_msg_count - 1;
          
        END LOOP while_loop;
--
      END IF;
      -- 警告セット
      ov_retcode := cv_status_warn;
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
  END start_apply_api;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_receipt_date        IN      VARCHAR2,         --   入金日
    ov_errbuf              OUT     VARCHAR2,         --   エラー・メッセージ           --# 固定 #
    ov_retcode             OUT     VARCHAR2,         --   リターン・コード             --# 固定 #
    ov_errmsg              OUT     VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_status_unapp     CONSTANT VARCHAR2(10) := 'UNAPP';    -- ステータス：入金－消し込み前
--
    -- *** ローカル変数 ***
    ln_target_credit   ar_cash_receipts_all.amount%type;  -- 対象債権総額
    ln_subloop_err_cnt NUMBER;  -- サブループ内エラー件数
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- <カーソル名>
--
    --対象AR入金抽出テーブルデータ取得カーソル
    CURSOR ar_cash_receipts_cur
    IS
      SELECT acra.cash_receipt_id cash_receipt_id,     --入金ID
             acra.receipt_number receipt_number,       --入金番号
             acra.receipt_date receipt_date,           --入金日
             acra.pay_from_customer pay_from_customer, --顧客ID
-- Modify 2009.02.12 Ver1.1 Start
--             acra.amount amount,                       --入金額
             (SELECT SUM(DECODE(araa.status,'UNAPP',NVL(araa.amount_applied,0),0))
                FROM ar_receivable_applications_all araa
               WHERE acra.cash_receipt_id = araa.cash_receipt_id ) amount, --入金額
-- Modify 2009.02.12 Ver1.1 End
             arm.name name,                            --支払方法名称
             hca.account_number account_number         --顧客コード
      FROM ar_cash_receipts_all acra,   --AR入金テーブル
           hz_cust_accounts     hca,    --顧客マスタ
           ar_receipt_methods   arm,    --AR支払方法テーブル
           ar_receipt_classes   arc     --AR入金区分テーブル
      WHERE acra.org_id            = gn_org_id
        AND acra.receipt_date     <= TRUNC(gd_receipt_date)
        AND acra.status            = cv_status_unapp
        AND acra.pay_from_customer = hca.cust_account_id
        AND acra.receipt_method_id = arm.receipt_method_id
        AND arm.receipt_class_id   = arc.receipt_class_id
        AND arc.attribute1         = cv_flag_y              --HHT自動消込フラグ
    ;
--
    l_ar_cash_receipts_rec   ar_cash_receipts_cur%ROWTYPE;
--
    --対象取引データ取得カーソル
    CURSOR ra_customer_trx_cur(
      in_pay_from_customer NUMBER, --A-4顧客ID
      id_receipt_date      DATE)   --A-4入金日
    IS
      SELECT 
-- Delete 2011.05.17 Ver1.4 Start
---- Modify 2009.07.15 Ver1.2 Start
--           /*+ INDEX(rcta RA_CUSTOMER_TRX_N11)
--               INDEX(apsa AR_PAYMENT_SCHEDULES_N2)
--           */
---- Modify 2009.07.15 Ver1.2 End
-- Delete 2011.05.17 Ver1.4 End
-- Add 2011.05.17 Ver1.4 Start
           /*+
               LEADING(XCHVG APSA RCTA RADIST)
               USE_NL (XCHVG APSA RCTA RADIST)
               INDEX  (XCHVG   XXCFR_CUST_HIERARCHY_MV_N01)
               INDEX  (APSA    AR_PAYMENT_SCHEDULES_N6)
               INDEX  (RCTA    RA_CUSTOMER_TRX_U1)
               INDEX  (RADIST  RA_CUST_TRX_LINE_GL_DIST_N6)
           */
-- Add 2011.05.17 Ver1.4 End
             rcta.customer_trx_id customer_trx_id, --取引ヘッダID
             rcta.trx_number trx_number            --取引番号
      FROM ra_customer_trx_all rcta,      --AR取引ヘッダテーブル
           ar_payment_schedules_all apsa, --AR支払計画テーブル
           ( SELECT xchv.bill_account_id bill_account_id  --請求先顧客ID
-- Modify 2011.05.17 Ver1.4 Start
--             FROM xxcfr_cust_hierarchy_v xchv             --顧客階層View
             FROM xxcfr_cust_hierarchy_mv xchv             --顧客階層マテリアライズドView
-- Modify 2011.05.17 Ver1.4 End
             WHERE xchv.cash_account_id  = in_pay_from_customer  --A-4顧客ID
-- Delete 2011.05.17 Ver1.4 Start
--             GROUP BY xchv.bill_account_id
-- Delete 2011.05.17 Ver1.4 End
           ) xchvg --請求先顧客インラインビュー
      WHERE rcta.org_id              = gn_org_id
        AND rcta.customer_trx_id     = apsa.customer_trx_id
        AND rcta.complete_flag       = cv_flag_y
        AND apsa.status              = cv_status_op
-- Modify 2011.05.17 Ver1.4 Start
--        AND rcta.bill_to_customer_id = xchvg.bill_account_id
        AND xchvg.bill_account_id    = apsa.customer_id
-- Modify 2011.05.17 Ver1.4 End
-- Modify 2010.01.12 Ver1.3 Start
--        AND apsa.due_date            = id_receipt_date  --A-4入金日
        AND apsa.due_date            >= id_receipt_date - gn_hht_date_from
        AND apsa.due_date            <= id_receipt_date + gn_hht_date_to
        AND rcta.trx_date            <= id_receipt_date
        AND EXISTS (SELECT 'X'
                    FROM ra_cust_trx_line_gl_dist_all radist
                    WHERE radist.customer_trx_id = rcta.customer_trx_id
                      AND radist.account_class = 'REV'
                      AND radist.gl_date <= id_receipt_date)
-- Modify 2010.01.12 Ver1.3 End
      ORDER BY apsa.amount_due_remaining
    ;
--
    l_ra_customer_trx_rec   ra_customer_trx_cur%ROWTYPE;
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
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- =====================================================
    --  入力パラメータ値ログ出力処理(A-1)
    -- =====================================================
    init(
       iv_receipt_date        -- 入金日
      ,lv_errbuf              -- エラー・メッセージ           --# 固定 #
      ,lv_retcode             -- リターン・コード             --# 固定 #
      ,lv_errmsg);            -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ・入金日がNULLの場合
    IF (iv_receipt_date IS NULL) THEN
      -- =====================================================
      --  業務処理日付取得処理 (A-2)
      -- =====================================================
      get_process_date(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
      
      -- 入金日のグローバル変数に業務処理日付をセットする
      gd_receipt_date := gd_process_date;
      
    -- 入力パラメータ・入金日がNULLでない場合
    ELSE
      -- 入金日のグローバル変数に入力パラメータ・入金日をセットする
      gd_receipt_date := xxcfr_common_pkg.get_date_param_trans ( iv_receipt_date );
    END IF;
--
    -- =====================================================
    --  プロファイル取得処理(A-3)
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
    --  対象AR入金テーブルデータ取得処理 (A-4)
    -- =====================================================
    -- カーソルオープン
    OPEN ar_cash_receipts_cur;
--
    -- メインループ開始
    <<ar_cash_receipts_loop>>
    LOOP
      -- データの取得
      FETCH ar_cash_receipts_cur INTO l_ar_cash_receipts_rec;
      EXIT WHEN ar_cash_receipts_cur%NOTFOUND;
--
      -- 対象件数カウント
      gn_target_cnt := gn_target_cnt + 1;
--
      -- 対象債権総額初期化
      ln_target_credit := 0;
--
      -- =====================================================
      --  対象債権総額処理 (A-5)
      -- =====================================================
      get_target_credit(
         l_ar_cash_receipts_rec.pay_from_customer   -- 顧客ID
        ,l_ar_cash_receipts_rec.receipt_date        -- 入金日
        ,ln_target_credit                           -- 対象債権総額
        ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
--
      -- A-4で取得した入金額とA-5で取得した未消込残高総額が等しい場合
      IF (lv_retcode = cv_status_normal AND
          l_ar_cash_receipts_rec.amount = ln_target_credit) THEN
--
        -- =====================================================
        --  対象取引データ取得処理 (A-6)
        -- =====================================================
        -- カーソルオープン
        OPEN ra_customer_trx_cur(l_ar_cash_receipts_rec.pay_from_customer,
                                 l_ar_cash_receipts_rec.receipt_date);
--
        -- サブループ内エラー件数初期化
        ln_subloop_err_cnt := 0;
--
        -- サブループ開始
        <<ra_customer_trx_loop>>
        LOOP
          -- データの取得
          FETCH ra_customer_trx_cur INTO l_ra_customer_trx_rec;
          EXIT WHEN ra_customer_trx_cur%NOTFOUND;
--
        -- =====================================================
        --  入金消込API起動処理 (A-7)
        -- =====================================================
        start_apply_api(
           l_ar_cash_receipts_rec.cash_receipt_id  -- 入金ID
          ,l_ar_cash_receipts_rec.receipt_number   -- 入金番号
          ,l_ar_cash_receipts_rec.receipt_date     -- 入金日
          ,l_ar_cash_receipts_rec.amount           -- 入金額
          ,l_ar_cash_receipts_rec.name             -- 支払方法
          ,l_ar_cash_receipts_rec.account_number   -- 顧客コード
          ,l_ra_customer_trx_rec.customer_trx_id   -- 取引ヘッダID
          ,l_ra_customer_trx_rec.trx_number        -- 取引番号
          ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
          ,lv_retcode            -- リターン・コード             --# 固定 #
          ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
        
        -- 正常処理チェック
        IF (lv_retcode <> cv_status_normal) THEN
          ln_subloop_err_cnt := ln_subloop_err_cnt + 1;
        END IF;
--
        -- サブループ終了
        END LOOP ra_customer_trx_loop;
--
        -- カーソルクローズ
        CLOSE ra_customer_trx_cur;
        
        IF (ln_subloop_err_cnt > 0) THEN
          -- エラー件数カウント
          gn_error_cnt   := gn_error_cnt + 1;
        ELSE
          -- 正常件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--
      -- 入金消込対象外の場合
      ELSE
        -- スキップ件数カウント
        gn_warn_cnt   := gn_warn_cnt + 1;
      END IF;
--
    -- メインループ終了
    END LOOP ar_cash_receipts_loop;
--
    -- カーソルクローズ
    CLOSE ar_cash_receipts_cur;
--
    --リターン・コードの設定
    IF (gn_error_cnt > 0) THEN
      -- 警告セット
      ov_retcode := cv_status_warn;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
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
    errbuf                 OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode                OUT     VARCHAR2,         --    エラーコード     #固定#
    iv_receipt_date        IN      VARCHAR2          --    入金日
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
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       ov_retcode => lv_retcode
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
       iv_receipt_date  -- 入金日
      ,lv_errbuf        -- エラー・メッセージ           --# 固定 #
      ,lv_retcode       -- リターン・コード             --# 固定 #
      ,lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
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
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
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
END XXCFR006A03C;
/
