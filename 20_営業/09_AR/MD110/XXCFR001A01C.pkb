CREATE OR REPLACE PACKAGE BODY XXCFR001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR001A01C(body)
 * Description      : AR部門入力の顧客情報更新
 * MD.050           : MD050_CFR_001_A01_AR部門入力の顧客情報更新
 * MD.070           : MD050_CFR_001_A01_AR部門入力の顧客情報更新
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   p 初期処理                                (A-1)
 *  get_process_date       p 業務処理日付取得処理                    (A-2)
 *  get_ar_interface_lines p 更新対象AR 取引OIFテーブル取得          (A-3)
 *  get_convert_cust_code  p 読替請求先顧客取得                      (A-4)
 *  get_receipt_dept_code  p 入金拠点取得                            (A-5)
 *  update_ar_interface_lines p 対象テーブル更新                     (A-6)
 *  submain                p メイン処理プロシージャ
 *  main                   p コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/05    1.00 SCS 中村 博      初回作成
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
  lock_expt             EXCEPTION;      -- ロック(ビジー)エラー
  dml_expt              EXCEPTION;      -- ＤＭＬエラー
--
  PRAGMA EXCEPTION_INIT(lock_expt, -54);
  PRAGMA EXCEPTION_INIT(dml_expt, -24381);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100) := 'XXCFR001A01C'; -- パッケージ名
  cv_msg_kbn_cmn     CONSTANT VARCHAR2(5)   := 'XXCMN'; -- アプリケーション短縮名(XXCMN)
  cv_msg_kbn_ccp     CONSTANT VARCHAR2(5)   := 'XXCCP'; -- アプリケーション短縮名(XXCCP)
  cv_msg_kbn_cfr     CONSTANT VARCHAR2(5)   := 'XXCFR'; -- アプリケーション短縮名(XXCFR)
--
  -- メッセージ番号
--
  cv_msg_001a01_010  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00015'; --データが取得できない
  cv_msg_001a01_011  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00003'; --データロックエラーメッセージ
  cv_msg_001a01_012  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00055'; --データ更新エラーメッセージ
  cv_msg_001a01_013  CONSTANT VARCHAR2(20) := 'APP-XXCFR1-00006'; --業務処理日付取得エラーメッセージ
--
-- トークン
  cv_tkn_table       CONSTANT VARCHAR2(15) := 'TABLE';            -- テーブル名
  cv_tkn_data        CONSTANT VARCHAR2(15) := 'DATA';             -- データ
  cv_tkn_comment     CONSTANT VARCHAR2(15) := 'COMMENT';          -- コメント
--
  -- 使用DB名
  cv_table_ra_oif    CONSTANT VARCHAR2(100) := 'RA_INTERFACE_LINES_ALL'; -- 取引オープンインターフェーステーブル
  cv_table_type      CONSTANT VARCHAR2(100) := 'RA_CUST_TRX_TYPES_ALL';  -- 取引タイプマスタ
  cv_table_xca       CONSTANT VARCHAR2(100) := 'XXCMM_CUST_ACCOUNTS';    -- 顧客追加情報テーブル
--
  cv_col_rec_b_cd    CONSTANT VARCHAR2(100) := 'RECEIPT_BASE_CODE';      -- 入金拠点
  cv_col_cust_id     CONSTANT VARCHAR2(100) := 'CUSTOMER_ID';            -- 顧客ＩＤ
--
  -- 日本語辞書
  cv_dict_rila       CONSTANT VARCHAR2(100) := 'CFR001A01001';    -- AR取引明細OIF
--
  -- 改行コード
  cv_cr              CONSTANT VARCHAR2(1) := CHR(10);      -- 改行コード
--
  -- ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT';    -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';       -- ログ出力
--
  cv_enabled_yes     CONSTANT VARCHAR2(1)  := 'Y';         -- 有効フラグ（Ｙ）
--
  cv_ship_to                CONSTANT VARCHAR2(100) := 'SHIP_TO'; -- 出荷先
  cv_cust_class_code_ar_mng CONSTANT VARCHAR2(10) := '14';       -- 顧客区分＝「14」（売掛金管理先顧客）
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  TYPE g_rowid_ttype               IS TABLE OF ROWID INDEX BY PLS_INTEGER;
  TYPE g_bill_customer_id_ttype    IS TABLE OF ra_interface_lines_all.orig_system_bill_customer_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_bill_address_id_ttype     IS TABLE OF ra_interface_lines_all.orig_system_bill_address_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_ship_customer_id_ttype    IS TABLE OF ra_interface_lines_all.orig_system_ship_customer_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_ship_address_id_ttype     IS TABLE OF ra_interface_lines_all.orig_system_ship_address_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_cust_trx_type_id_ttype    IS TABLE OF ra_interface_lines_all.cust_trx_type_id%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_header_attribute7_ttype   IS TABLE OF ra_interface_lines_all.header_attribute7%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_header_attribute11_ttype  IS TABLE OF ra_interface_lines_all.header_attribute11%type
                                               INDEX BY PLS_INTEGER;
  TYPE g_customer_class_code_ttype IS TABLE OF hz_cust_accounts.customer_class_code%type
                                               INDEX BY PLS_INTEGER;
  gt_ril_rowid                          g_rowid_ttype;
  gt_ril_bill_customer_id               g_bill_customer_id_ttype;
  gt_ril_bill_address_id                g_bill_address_id_ttype;
  gt_ril_ship_customer_id               g_ship_customer_id_ttype;
  gt_ril_ship_address_id                g_ship_address_id_ttype;
  gt_ril_cust_trx_type_id               g_cust_trx_type_id_ttype;
  gt_ril_header_attribute7              g_header_attribute7_ttype;
  gt_ril_header_attribute11             g_header_attribute11_ttype;
  gt_hca_customer_class_code            g_customer_class_code_ttype;
--
  TYPE c_out_flag_ttype     IS TABLE OF VARCHAR2(1);
  TYPE c_hold_status_ttype  IS TABLE OF VARCHAR2(10);
  gt_out_flag         c_out_flag_ttype := c_out_flag_ttype ( 'Y', 'N' );          -- 請求書発行区分
  gt_hold_status      c_hold_status_ttype := c_hold_status_ttype ( 'OPEN', 'HOLD' ); -- 請求書保留ステータス
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date             DATE;              -- 業務処理日付
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --コンカレントパラメータ出力
    --==============================================================
    -- メッセージ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_out   -- メッセージ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log   -- ログ出力
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_process_date
   * Description      : 業務処理日付取得処理 (A-2)
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
                                                    ,cv_msg_001a01_013 -- 業務処理日付取得エラー
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
   * Procedure Name   : get_ar_interface_lines
   * Description      : 更新対象AR 取引OIFテーブル取得 (A-3)
   ***********************************************************************************/
  PROCEDURE get_ar_interface_lines(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_interface_lines'; -- プログラム名
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
    cv_ar_inv_inp_source_name CONSTANT VARCHAR2(100) := 'XXCFR1_AR_INV_INP_SOURCE_NAME';
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
--
    -- 抽出
    CURSOR get_ar_interface_cur
    IS
      SELECT rila.ROWID,                                                         -- ROWID
             rila.orig_system_bill_customer_id   orig_system_bill_customer_id,   -- 請求先顧客ＩＤ
             rila.orig_system_bill_address_id    orig_system_bill_address_id,    -- 請求先顧客所在地ＩＤ
             rila.orig_system_ship_customer_id   orig_system_ship_customer_id,   -- 出荷先顧客ＩＤ
             rila.orig_system_ship_address_id    orig_system_ship_address_id,    -- 出荷先顧客所在地ＩＤ
             rila.cust_trx_type_id               cust_trx_type_id,               -- 取引タイプＩＤ
             hca.customer_class_code             customer_class_code,            -- 顧客区分
             DECODE ( rctt.attribute1,
                      gt_out_flag(1), gt_hold_status(1),
                      gt_out_flag(2), gt_hold_status(2),
                      gt_hold_status(2) ) output_invoice_hold_sts         -- 請求書保留ステータス
      FROM ra_interface_lines_all         rila,
           hz_cust_accounts               hca,
           ra_cust_trx_types_all          rctt
      WHERE rila.batch_source_name IN (
              SELECT flvv.meaning
              FROM fnd_lookup_values_vl  flvv
              WHERE flvv.lookup_type             = cv_ar_inv_inp_source_name   -- AR部門入力の仕訳ソースタイプ
                AND flvv.enabled_flag            = cv_enabled_yes
-- Modified Start by SCS)H.Nakamura 2008/11/25 業務処理日付参照することに修正
--                AND ( flvv.start_date_active     IS NULL
--                   OR flvv.start_date_active     <= SYSDATE )
--                AND ( flvv.end_date_active       IS NULL
--                   OR flvv.end_date_active       >= SYSDATE )
                AND ( flvv.start_date_active     IS NULL
                   OR flvv.start_date_active     <= gd_process_date )
                AND ( flvv.end_date_active       IS NULL
                   OR flvv.end_date_active       >= gd_process_date )
-- Modified End by SCS)H.Nakamura 2008/11/25 業務処理日付参照することに修正
            )
        AND rila.interface_status   IS NULL
        AND NOT EXISTS ( 
            SELECT 'X'
            FROM ra_interface_errors_all  riea
            WHERE rila.interface_line_id   = riea.interface_line_id
            )
        AND rila.orig_system_bill_customer_id       = hca.cust_account_id
        AND rila.cust_trx_type_id                   = rctt.cust_trx_type_id(+)
      FOR UPDATE OF rila.INTERFACE_LINE_ID NOWAIT
    ;
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
    -- カーソルオープン
    OPEN get_ar_interface_cur;
--
    -- データの一括取得
    FETCH get_ar_interface_cur BULK COLLECT INTO
          gt_ril_rowid,
          gt_ril_bill_customer_id,
          gt_ril_bill_address_id,
          gt_ril_ship_customer_id,
          gt_ril_ship_address_id,
          gt_ril_cust_trx_type_id,
          gt_hca_customer_class_code,
          gt_ril_header_attribute7;
--
    -- 処理件数のセット
    gn_target_cnt := gt_ril_rowid.COUNT;
--
    -- カーソルクローズ
    CLOSE get_ar_interface_cur;
--
  EXCEPTION
    WHEN lock_expt THEN  -- テーブルロックできなかった
      lv_errmsg := SUBSTRB( xxcmn_common_pkg.get_msg(cv_msg_kbn_cfr        -- 'XXCFR'
                                                     ,cv_msg_001a01_011    -- テーブルロックエラー
                                                     ,cv_tkn_table         -- トークン'TABLE'
--                                                     ,xxcfr_common_pkg.get_table_comment(cv_table_ra_oif))
                                                     ,xxcfr_common_pkg.lookup_dictionary(
                                                       cv_msg_kbn_cfr
                                                      ,cv_dict_rila 
                                                     ))
                                                    -- 取引オープンインターフェーステーブル
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
  END get_ar_interface_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_convert_cust_code
   * Description      : 読替請求先顧客取得 (A-4)
   ***********************************************************************************/
  PROCEDURE get_convert_cust_code(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_convert_cust_code'; -- プログラム名
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
    ln_bill_customer_id   hz_cust_accounts.cust_account_id%type;            -- 請求先顧客ＩＤ
    ln_bill_address_id    hz_cust_acct_sites_all.cust_acct_site_id%type;    -- 請求先顧客所在地ＩＤ
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
    -- 対象件数が０でない場合、読替請求先顧客を取得
    IF ( gn_target_cnt > 0 ) THEN
      <<cust_data_loop>>
      FOR ln_loop_cnt IN gt_ril_rowid.FIRST..gt_ril_rowid.LAST LOOP
--
--        -- 初期値の設定
--        gt_ril_ship_customer_id(ln_loop_cnt) := NULL;
--        gt_ril_ship_address_id(ln_loop_cnt)  := NULL;
--
        -- 顧客区分＝「14」（売掛金管理先顧客）でない場合、読み替え処理を行う
        IF ( gt_hca_customer_class_code(ln_loop_cnt) <> cv_cust_class_code_ar_mng ) THEN
--
          -- 出荷先顧客に請求先顧客を設定する
          gt_ril_ship_customer_id(ln_loop_cnt) := gt_ril_bill_customer_id(ln_loop_cnt);
          gt_ril_ship_address_id(ln_loop_cnt)  := gt_ril_bill_address_id(ln_loop_cnt);
--
          -- 顧客コードを読み替える
          BEGIN
            SELECT hca2.cust_account_id,
                   hcasa2.cust_acct_site_id
            INTO ln_bill_customer_id,
                 ln_bill_address_id
            FROM hz_cust_accounts              hca,
                 hz_cust_acct_sites_all        hcasa,
                 hz_cust_site_uses_all         hcsua,
                 hz_cust_site_uses_all         hcsua2,
                 hz_cust_acct_sites_all        hcasa2,
                 hz_cust_accounts              hca2
            WHERE hca.cust_account_id          = hcasa.cust_account_id  
              AND hcasa.cust_acct_site_id      = hcsua.cust_acct_site_id
              AND hcsua.site_use_code          = cv_ship_to
              AND hcsua.bill_to_site_use_id    = hcsua2.site_use_id
              AND hcsua2.cust_acct_site_id     = hcasa2.cust_acct_site_id
              AND hca2.cust_account_id         = hcasa2.cust_account_id  
              AND hca.cust_account_id          = gt_ril_ship_customer_id(ln_loop_cnt)
              AND hcasa.cust_acct_site_id      = gt_ril_ship_address_id(ln_loop_cnt)
            ;
--
            gt_ril_bill_customer_id(ln_loop_cnt) := ln_bill_customer_id;
            gt_ril_bill_address_id(ln_loop_cnt)  := ln_bill_address_id;
--
          EXCEPTION
            WHEN OTHERS THEN
              -- データが取得できない場合、請求先の読替はしない（元のまま）。
              NULL;
          END;
        END IF;
      END LOOP cust_data_loop;
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
  END get_convert_cust_code;
--
  /**********************************************************************************
   * Procedure Name   : get_receipt_dept_code
   * Description      :入金拠点取得 (A-5)
   ***********************************************************************************/
  PROCEDURE get_receipt_dept_code(
    ov_errbuf               OUT VARCHAR2,            -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,            -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)            -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_receipt_dept_code'; -- プログラム名
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
    -- 対象件数が０でない場合、入金拠点を取得
    IF ( gn_target_cnt > 0 ) THEN
      -- 入金拠点を取得
      <<receipt_dept_code_loop>>
      FOR ln_loop_cnt IN gt_ril_rowid.FIRST..gt_ril_rowid.LAST LOOP
--
        -- 初期値の設定
        gt_ril_header_attribute11(ln_loop_cnt) := NULL;
        BEGIN
          SELECT NVL( xca.receiv_base_code, xca.sale_base_code ) receiv_base_code
          INTO gt_ril_header_attribute11(ln_loop_cnt)
          FROM xxcmm_cust_accounts    xca     -- 顧客追加情報テーブル
          WHERE xca.customer_id       = gt_ril_bill_customer_id(ln_loop_cnt)
          ;
--
        EXCEPTION
          WHEN OTHERS THEN
            -- データが取得できない場合、なにもしない
            NULL;
        END;
      END LOOP receipt_dept_code_loop;
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
  END get_receipt_dept_code;
--
  /**********************************************************************************
   * Procedure Name   : update_ar_interface_lines
   * Description      : 対象テーブル更新 (A-6)
   ***********************************************************************************/
  PROCEDURE update_ar_interface_lines(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_ar_interface_lines'; -- プログラム名
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
    ln_loop_cnt     NUMBER;        -- ループカウンタ
    ln_normal_cnt   NUMBER := 0;   -- 正常件数
    ln_error_cnt    NUMBER;        -- エラーカウンタ
--
    lv_errmsg_tmp   VARCHAR2(5000);  -- ユーザー・エラー・メッセージ・テンポラリ
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
    -- =====================================================
    --  対象テーブル更新 (A-5)
    -- =====================================================
    -- 対象件数が０でない場合、対象データ更新
    IF ( gn_target_cnt > 0 ) THEN
      <<update_loop>>
      FORALL ln_loop_cnt IN gt_ril_rowid.FIRST..gt_ril_rowid.LAST SAVE EXCEPTIONS
        UPDATE ra_interface_lines_all
        SET orig_system_bill_customer_id   = gt_ril_bill_customer_id(ln_loop_cnt)       -- 請求先顧客ＩＤ
           ,orig_system_bill_address_id    = gt_ril_bill_address_id(ln_loop_cnt)        -- 請求先顧客所在地ＩＤ
           ,orig_system_ship_customer_id   = gt_ril_ship_customer_id(ln_loop_cnt)       -- 出荷先顧客ＩＤ
           ,orig_system_ship_address_id    = gt_ril_ship_address_id(ln_loop_cnt)        -- 出荷先顧客所在地ＩＤ
           ,header_attribute7              = gt_ril_header_attribute7(ln_loop_cnt)      -- 請求書保留ステータス
           ,header_attribute11             = gt_ril_header_attribute11(ln_loop_cnt)     -- 入金拠点
           ,last_updated_by                = cn_last_updated_by                         -- 最終更新者
           ,last_update_date               = cd_last_update_date                        -- 最終更新日
           ,last_update_login              = cn_last_update_login                       -- 最終更新ログイン
--           ,request_id                     = cn_request_id  -- 更新すると、インターフェースされなくなるため、削除
        WHERE ROWID                        = gt_ril_rowid(ln_loop_cnt)
      ;
    END IF;
--
    gn_normal_cnt := SQL%ROWCOUNT;
--
  EXCEPTION
    -- DML分実行にてエラーが発生
    WHEN dml_expt THEN
      ln_error_cnt := SQL%BULK_EXCEPTIONS.COUNT;
      FOR ln_loop_cnt IN 1..ln_error_cnt LOOP
        lv_errmsg_tmp := SUBSTRB( xxcmn_common_pkg.get_msg(
                                                        cv_msg_kbn_cfr       -- 'XXCFR'
                                                       ,cv_msg_001a01_012    -- テーブルが更新できない
                                                       ,cv_tkn_table         -- トークン'TABLE'
--                                                       ,xxcfr_common_pkg.get_table_comment(cv_table_ra_oif)
                                                       ,xxcfr_common_pkg.lookup_dictionary(
                                                         cv_msg_kbn_cfr
                                                        ,cv_dict_rila 
                                                       )
                                                       ,cv_tkn_comment       -- トークン'COMMENT'
                                                       ,xxcfr_common_pkg.get_col_comment(cv_table_xca, cv_col_cust_id)
                                                       || cv_msg_part
                                                       || gt_ril_bill_customer_id(SQL%BULK_EXCEPTIONS(ln_loop_cnt).ERROR_INDEX)
                                                       ) -- 顧客ＩＤ
                                                       ,1
                                                       ,5000);
        lv_errbuf := lv_errbuf || SQLERRM(-SQL%BULK_EXCEPTIONS(ln_loop_cnt).ERROR_CODE) || cv_cr;
        lv_errmsg := lv_errmsg || lv_errmsg_tmp || cv_cr;
--
        -- エラーカウントを格納
        gn_error_cnt := SQL%BULK_EXCEPTIONS(ln_loop_cnt).ERROR_INDEX;
--
      END LOOP;
--
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
  END update_ar_interface_lines;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    --  初期処理(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
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
--
    -- =====================================================
    --  更新対象AR 取引OIFテーブル取得 (A-3)
    -- =====================================================
    get_ar_interface_lines(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  読替請求先顧客取得 (A-4)
    -- =====================================================
    get_convert_cust_code(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  入金拠点取得 (A-5)
    -- =====================================================
    get_receipt_dept_code(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  対象テーブル更新 (A-6)
    -- =====================================================
    update_ar_interface_lines(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 正常件数の設定
    gn_normal_cnt := gn_target_cnt - gn_error_cnt;
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
    errbuf        OUT     VARCHAR2,         --    エラー・メッセージ  --# 固定 #
    retcode       OUT     VARCHAR2          --    エラーコード     #固定#
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code VARCHAR2(100);   --メッセージコード
--
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_file_type_out
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
       lv_errbuf     -- エラー・メッセージ           --# 固定 #
      ,lv_retcode    -- リターン・コード             --# 固定 #
      ,lv_errmsg     -- ユーザー・エラー・メッセージ --# 固定 #
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
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --正常でない場合、エラー出力
    IF (lv_retcode <> cv_status_normal) THEN
      -- エラーバッファのメッセージ連結
      lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      --１行改行
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => '' --ユーザー・エラーメッセージ
      );
    END IF;
-- Add End   2008/11/18 SCS H.Nakamura テンプレートを修正
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => lv_errbuf --エラーメッセージ
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
-- Add Start 2008/11/18 SCS H.Nakamura テンプレートを修正
    --１行改行
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => '' --ユーザー・エラーメッセージ
    );
-- Add End 2008/11/18 SCS H.Nakamura テンプレートを修正
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
END XXCFR001A01C;
/
