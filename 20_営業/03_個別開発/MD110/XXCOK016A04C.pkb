CREATE OR REPLACE PACKAGE BODY XXCOK016A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK016A04C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : EDIシステムにてインフォマート社へ送信する支払案内書用赤黒データファイル作成
 * Version          : 1.0
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  upd_data_h                  連携対象データ更新(ヘッダー)(A-6)
 *  upd_data_c                  連携対象データ更新(カスタム明細)(A-5)
 *  get_work_head_line          ワークヘッダー・明細対象データ抽出(A-2)(A-3)
 *  init                        初期処理(A-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/02/18    1.0   K.Yoshikawa      新規作成  E_本稼動_17680
 *
 *****************************************************************************************/
--
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK016A04C';
  -- アプリケーション短縮名
  cv_appli_short_name_xxcok  CONSTANT VARCHAR2(10)    := 'XXCOK'; -- 個別_アプリケーション短縮名
  cv_appli_short_name_xxccp  CONSTANT VARCHAR2(10)    := 'XXCCP'; -- 共通_アプリケーション短縮名
  -- ステータス
  cv_status_normal           CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)     := xxccp_common_pkg.set_status_error;  -- 異常:2
  -- WHOカラム
  cn_created_by              CONSTANT NUMBER          := fnd_global.user_id;          -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER          := fnd_global.user_id;          -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER          := fnd_global.login_id;         -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER          := fnd_global.conc_request_id;  -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER          := fnd_global.prog_appl_id;     -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER          := fnd_global.conc_program_id;  -- PROGRAM_ID
  -- メッセージ
  cv_msg_xxcok1_00003        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00003';  -- プロファイル取得エラー
  cv_msg_xxcok1_00006        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00006';  -- ファイル名出力
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_xxcok1_10813        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10813';  -- 赤黒作成メッセージ
  cv_msg_xxcok1_10815        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10815';  -- インフォマート差分出力用パラメータ出力
  cv_msg_xxcok1_10763        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10763';  -- インフォマート用ヘッダー項目名（外税）
  cv_msg_xxcok1_10764        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10764';  -- インフォマート用ヘッダー項目名（内税）
  cv_msg_xxcok1_10765        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10765';  -- インフォマート用カスタム明細タイトル
  cv_msg_xxcok1_10766        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10766';  -- インフォマート用カスタム明細項目名
  cv_msg_xxcok1_10767        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10767';  -- インフォマート用明細合計行名
  cv_msg_xxccp1_90000        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90000';  -- 対象件数
  cv_msg_xxccp1_90001        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90001';  -- 成功件数
  cv_msg_xxccp1_90002        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90002';  -- エラー件数
  cv_msg_xxccp1_90003        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90003';  -- 警告件数
  cv_msg_xxccp1_90004        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90004';  -- 正常終了
  cv_msg_xxccp1_90005        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90005';  -- 警告終了
  cv_msg_xxccp1_90006        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
  cv_msg_xxccp1_90008        CONSTANT VARCHAR2(16)    := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  -- トークン
  cv_tkn_profile             CONSTANT VARCHAR2(7)     := 'PROFILE';
  cv_tkn_file_name           CONSTANT VARCHAR2(9)     := 'FILE_NAME';
  cv_tkn_conn_loc            CONSTANT VARCHAR2(8)     := 'CONN_LOC';
  cv_tkn_vendor_code         CONSTANT VARCHAR2(11)    := 'VENDOR_CODE';
  cv_tkn_count               CONSTANT VARCHAR2(5)     := 'COUNT';
  cv_tkn_col                 CONSTANT VARCHAR2(3)     := 'COL';
  cv_tkn_value               CONSTANT VARCHAR2(5)     := 'VALUE';
  cv_tkn_name                CONSTANT VARCHAR2(4)     := 'NAME';
  cv_tkn_tax_div             CONSTANT VARCHAR2(7)     := 'TAX_DIV';
  cv_tkn_rev                 CONSTANT VARCHAR2(3)     := 'REV';
  -- プロファイル
  cv_prof_i_file_name        CONSTANT VARCHAR2(27)    := 'XXCOK1_INFOMART_R_FILE_NAME';        -- インフォマート_ファイル名
  cv_prof_org_id             CONSTANT VARCHAR2(6)     := 'ORG_ID';                           -- MO: 営業単位
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- 書式フォーマット
  cv_fmt_ymd                 CONSTANT VARCHAR2(10)    := 'YYYY/MM/DD';
  cv_fmt_ymd2                CONSTANT VARCHAR2(8)    := 'YYYYMMDD';
  -- ファイルオープンパラメータ
  cv_open_mode_w             CONSTANT VARCHAR2(1)     := 'w';                   -- テキストの書込み
  cn_max_linesize            CONSTANT BINARY_INTEGER  := 32767;                 -- 1行当り最大文字数
  -- ===============================================
  -- グローバル変数
  -- ===============================================
  gn_target_cnt              NUMBER DEFAULT 0;                                  -- 対象件数
  gn_normal_cnt              NUMBER DEFAULT 0;                                  -- 正常件数
  gn_error_cnt               NUMBER DEFAULT 0;                                  -- エラー件数
  gn_skip_cnt                NUMBER DEFAULT 0;                                  -- スキップ件数
  gd_process_date            DATE   DEFAULT NULL;                               -- 業務処理日付
  gn_org_id                  NUMBER;                                            -- 営業単位ID
--
  gv_custom_title            fnd_new_messages.message_text%TYPE;                -- カスタム明細タイトル
  gv_line_sum                fnd_new_messages.message_text%TYPE;                -- 明細合計行名
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  gt_head_item               xxcok_common_pkg.g_split_csv_tbl;
  gt_custom_item             xxcok_common_pkg.g_split_csv_tbl;
--
  -- ===============================================
  -- グローバルカーソル(ヘッダー・明細)
  -- ===============================================
  CURSOR g_head_cur(
      it_tax_div    IN  VARCHAR2
     ,it_rev        IN  VARCHAR2
  )
  IS
    SELECT  xiwh.set_code               AS  set_code
           ,xiwh.cust_name              AS  cust_name
           ,NULL                        AS  office
           ,xiwh.dest_post_code         AS  dest_post_code
           ,xiwh.dest_address1          AS  dest_address1
           ,NULL                        AS  dest_address2
           ,xiwh.dest_tel               AS  dest_tel
           ,xiwh.fax                    AS  fax
           ,NULL                        AS  business
           ,xiwh.dept_name              AS  dept_name
           ,xiwh.send_post_code         AS  send_post_code
           ,xiwh.send_address1          AS  send_address1
           ,NULL                        AS  send_address2
           ,xiwh.send_tel               AS  send_tel
           ,xiwh.num                    AS  num
           ,xiwh.vendor_code            AS  vendor_code
--           ,NULL                        AS  subject
           ,xiwh.cust_name              AS  subject
           ,xiwh.payment_date           AS  payment_date
           ,xiwh.notifi_amt             AS  notifi_amt
           ,xiwh.total_amt_no_tax_10    AS  total_amt_no_tax_10
           ,xiwh.tax_amt_10             AS  tax_amt_10
           ,xiwh.total_amt_10           AS  total_amt_10
           ,xiwh.total_amt_no_tax_8     AS  total_amt_no_tax_8
           ,xiwh.tax_amt_8              AS  tax_amt_8
           ,xiwh.total_amt_8            AS  total_amt_8
           ,xiwh.total_amt_no_tax_0     AS  total_amt_no_tax_0
           ,xiwh.tax_amt_0              AS  tax_amt_0
           ,xiwh.total_amt_0            AS  total_amt_0
           ,xiwh.closing_date           AS  closing_date
           ,xiwh.closing_date_min       AS  closing_date_min
           ,xiwh.total_sales_qty        AS  total_sales_qty
           ,xiwh.total_sales_amt        AS  total_sales_amt
           ,xiwh.sales_fee              AS  sales_fee
           ,CASE
              WHEN xiwh.set_code IN ('0', '2')
              THEN NULL
              ELSE xiwh.electric_amt
            END                         AS  electric_amt
           ,xiwh.tax_amt                AS  h_tax_amt
           ,xiwh.transfer_fee           AS  transfer_fee
           ,xiwh.payment_amt            AS  payment_amt
           ,xiwh.remarks                AS  remarks
           ,xiwh.bank_code              AS  bank_code
           ,xiwh.bank_name              AS  bank_name
           ,xiwh.branch_code            AS  branch_code
           ,xiwh.branch_name            AS  branch_name
           ,xiwh.bank_holder_name_alt   AS  bank_holder_name_alt
           ,xiwh.rowid                  AS  row_id_h
     FROM  xxcok_info_rev_header   xiwh
     WHERE xiwh.tax_div       = it_tax_div
     AND   xiwh.rev           = it_rev
     AND   xiwh.check_result  = '0'
     AND   ((    xiwh.rev           = '2'
             AND xiwh.payment_amt   <  0  )
            OR
            (    xiwh.rev           = '3'
             AND xiwh.payment_amt   >  0  )
            OR
            (    xiwh.rev           = '4'
             AND xiwh.payment_amt   <  0  )
           )
     ORDER BY
           vendor_code
    ;
--
  g_head_rec    g_head_cur%ROWTYPE;
--
  -- ===============================================
  -- グローバルカーソル(カスタム明細)
  -- ===============================================--
  CURSOR g_custom_cur(
      it_supplier_code  IN  xxcok_backmargin_balance.supplier_code%TYPE
     ,it_tax_div        IN  VARCHAR2
     ,it_rev            IN  VARCHAR2
  )
  IS
    SELECT  CASE
              WHEN xiwc.calc_sort = 6
              THEN xiwc.cust_code
              ELSE NULL
            END                         AS  custom1
           ,xiwc.sell_bottle            AS  custom2
           ,SUBSTR(xiwc.sales_qty,1,13) AS  custom3
           ,xiwc.sales_tax_amt          AS  custom4
           ,CASE
              WHEN it_tax_div = '2'
              THEN NULL
              ELSE xiwc.sales_amt
            END                         AS  custom5
           ,xiwc.contract               AS  custom6
           ,xiwc.sales_fee              AS  custom7
           ,xiwc.tax_amt                AS  custom8
           ,xiwc.sales_tax_fee          AS  custom9
           ,xiwc.inst_dest              AS  cust_name
           ,xiwc.calc_type              AS  calc_type
           ,xiwc.cust_code              AS  cust_code
           ,xiwc.calc_sort              AS  calc_sort
           ,xiwc.rowid                  AS  row_id_c
     FROM   xxcok_info_rev_custom   xiwc
     WHERE  xiwc.vendor_code    = it_supplier_code
     AND    xiwc.tax_div        = it_tax_div
     AND    exists (
              SELECT 1
              FROM   xxcok_info_rev_header   xiwh
              WHERE  xiwh.vendor_code   = xiwc.vendor_code
              AND    xiwh.tax_div       = xiwc.tax_div
              AND    xiwh.rev           = xiwc.rev
              AND    xiwh.check_result  = '0'
              AND    ((    xiwh.rev           = '2'
                       AND xiwh.payment_amt   <  0  )
                      OR
                      (    xiwh.rev           = '3'
                       AND xiwh.payment_amt   >  0  )
                      OR
                      (    xiwh.rev           = '4'
                       AND xiwh.payment_amt   <  0  )
                     )
                   )
     AND    xiwc.rev            = it_rev
     AND    xiwc.check_result   = '0'
     ORDER BY xiwc.cust_code
             ,xiwc.calc_sort
             ,xiwc.bottle_code
             ,xiwc.salling_price
             ,CASE
                WHEN xiwc.calc_sort = '2.7' THEN
                  TO_NUMBER(xiwc.sell_bottle)
                ELSE
                  NULL
              END
             ,xiwc.rebate_rate
             ,xiwc.rebate_amt
     ;
--
  g_custom_rec  g_custom_cur%ROWTYPE;
--
  -- ===============================================
  -- 共通例外
  -- ===============================================
  --*** ロックエラー ***
  global_lock_fail                EXCEPTION;
  --*** 処理部共通例外 ***
  global_process_expt             EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
--
  /**********************************************************************************
   * Procedure Name   : upd_data_c
   * Description      : 連携対象データ更新(カスタム明細)(A-5)
   ***********************************************************************************/
  PROCEDURE upd_data_c(
    ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
   ,iv_row_id_c    IN  VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_data_c';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
      -- ===============================================
      -- インフォマート用赤黒（カスタム明細）テーブル更新
      -- ===============================================
    UPDATE xxcok_info_rev_custom xirc
       SET xirc.edi_interface_date      = gd_process_date                      -- 連携日（EDI支払案内書）
          ,xirc.last_updated_by         = cn_last_updated_by
          ,xirc.last_update_date        = SYSDATE
          ,xirc.last_update_login       = cn_last_update_login
          ,xirc.request_id              = cn_request_id
          ,xirc.program_application_id  = cn_program_application_id
          ,xirc.program_id              = cn_program_id
          ,xirc.program_update_date     = SYSDATE
     WHERE xirc.rowid                   = iv_row_id_c
    ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_data_c;
--
  /**********************************************************************************
   * Procedure Name   : upd_data_h
   * Description      : 連携対象データ更新(ヘッダー)(A-6)
   ***********************************************************************************/
  PROCEDURE upd_data_h(
    ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
   ,iv_row_id_h    IN  VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_data_h';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- インフォマート用赤黒（ヘッダー）テーブル更新
    -- ===============================================
    UPDATE xxcok_info_rev_header xirh
       SET xirh.edi_interface_date      = gd_process_date                      -- 連携日（EDI支払案内書）
          ,xirh.last_updated_by         = cn_last_updated_by
          ,xirh.last_update_date        = SYSDATE
          ,xirh.last_update_login       = cn_last_update_login
          ,xirh.request_id              = cn_request_id
          ,xirh.program_application_id  = cn_program_application_id
          ,xirh.program_id              = cn_program_id
          ,xirh.program_update_date     = SYSDATE
     WHERE xirh.rowid                   = iv_row_id_h
    ;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_data_h;
--
  /**********************************************************************************
   * Procedure Name   : get_work_head_line
   * Description      : ワークヘッダー・明細対象データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_work_head_line(
    iv_tax_div    IN  VARCHAR2
   ,iv_rev        IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'get_work_head_line';                      -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ユーザー・エラー・メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- メッセージ関数戻り値用
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- 出力用メッセージ
--
    lv_pre_vendor_code    xxcok_info_rev_header.vendor_code%TYPE;
    lv_pre_h_row_id       ROWID;
    lv_pre_cust_code      xxcok_info_rev_custom.cust_code%TYPE;
    ln_l_loop_cnt         NUMBER DEFAULT 0;
    ln_h_loop_cnt         NUMBER DEFAULT 0;
    ln_out_cnt            PLS_INTEGER;
--
    lv_head_data          VARCHAR2(32767);
--
    TYPE rec_out_data IS RECORD
      (
        column    VARCHAR2(32767)
      );
    TYPE l_tab_out_data IS TABLE OF rec_out_data INDEX BY PLS_INTEGER;
    lt_out_data         l_tab_out_data;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    ln_out_cnt := 1;
    -- ===============================================
    -- ヘッダー・明細データ取得カーソル
    -- ===============================================
    OPEN g_head_cur(
            iv_tax_div
           ,iv_rev
          );
    << head_loop >>
    LOOP 
      FETCH g_head_cur INTO g_head_rec;
      -- ０件目で、データがない場合ループを抜ける
      IF (ln_h_loop_cnt = 0) THEN
        EXIT WHEN g_head_cur%NOTFOUND;
      END IF;
--
      -- ヘッダーのレコードなし（最終行の後）、又は送付先コードが前回ループ時と違う
      IF    ( g_head_cur%NOTFOUND = TRUE )
        OR  ( NVL( lv_pre_vendor_code, g_head_rec.vendor_code )  <> g_head_rec.vendor_code )
      THEN
--
        -- カウンタ初期化
        ln_l_loop_cnt := 0;
--
        -- ===============================================
        -- カスタム明細データ取得(A-3)
        -- ===============================================
        OPEN g_custom_cur(
                lv_pre_vendor_code
               ,iv_tax_div
               ,iv_rev
              );
--
        << custom_loop >>
        LOOP
          FETCH g_custom_cur INTO g_custom_rec;
          EXIT WHEN g_custom_cur%NOTFOUND;
--
          -- ===============================================
          -- 連携データファイル作成(A-4)
          -- ===============================================
          -- カスタム明細1行目かチェック
          IF (ln_l_loop_cnt = 0) THEN
            -- ===============================================
            -- カスタム明細・名称出力
            -- ===============================================
            lt_out_data(ln_out_cnt).column := '<CN>'           -- 通知書書式設定コード
                || cv_msg_canm || '設置先別明細'               -- カスタム明細名称(設置場所)
                ;
            ln_out_cnt := ln_out_cnt + 1;
--
            -- ===============================================
            -- カスタム明細・項目名出力
            -- ===============================================
            lt_out_data(ln_out_cnt).column := '<CH>'           -- 通知書書式設定コード
                || cv_msg_canm || gt_custom_item(1)            -- 設置場所
                || cv_msg_canm || gt_custom_item(2)            -- 売価／容器
                || cv_msg_canm || gt_custom_item(3)            -- 販売本数
                || cv_msg_canm || gt_custom_item(4)            -- 販売金額（税込）
                || cv_msg_canm || gt_custom_item(5)            -- 販売金額（税抜）
                || cv_msg_canm || gt_custom_item(6)            -- ご契約内容
                || cv_msg_canm || gt_custom_item(7)            -- 販売手数料（税抜）
                || cv_msg_canm || gt_custom_item(8)            -- 消費税
                || cv_msg_canm || gt_custom_item(9)            -- 販売手数料（税込）
                ;
--
            ln_out_cnt := ln_out_cnt + 1;
--
          END IF;
--
          -- 前回顧客がNULL又は、前回と値が違う場合
          IF    (lv_pre_cust_code IS NULL)
            OR  (lv_pre_cust_code <> g_custom_rec.cust_code)
          THEN
--
            -- ===============================================
            -- カスタム明細・顧客名出力
            -- ===============================================
            lt_out_data(ln_out_cnt).column := '<CD>'            -- 通知書書式設定コード
                || cv_msg_canm || g_custom_rec.cust_name        -- 設置場所（顧客名）
                || cv_msg_canm || NULL                          -- カスタム明細２
                || cv_msg_canm || NULL                          -- カスタム明細３
                || cv_msg_canm || NULL                          -- カスタム明細４
                || cv_msg_canm || NULL                          -- カスタム明細５
                || cv_msg_canm || NULL                          -- カスタム明細６
                || cv_msg_canm || NULL                          -- カスタム明細７
                || cv_msg_canm || NULL                          -- カスタム明細８
                || cv_msg_canm || NULL                          -- カスタム明細９
                || cv_msg_canm || NULL                          -- カスタム明細１０
                || cv_msg_canm || NULL                          -- カスタム明細１１
                || cv_msg_canm || NULL                          -- カスタム明細１２
                || cv_msg_canm || NULL                          -- カスタム明細１３
                || cv_msg_canm || NULL                          -- カスタム明細１４
                || cv_msg_canm || NULL                          -- カスタム明細１５
                || cv_msg_canm || NULL                          -- カスタム明細１６
                || cv_msg_canm || NULL                          -- カスタム明細１７
                || cv_msg_canm || NULL                          -- カスタム明細１８
                || cv_msg_canm || NULL                          -- カスタム明細１９
                || cv_msg_canm || NULL                          -- カスタム明細２０
                || cv_msg_canm || NULL                          -- カスタム明細２１
                || cv_msg_canm || NULL                          -- カスタム明細２２
                || cv_msg_canm || NULL                          -- カスタム明細２３
                || cv_msg_canm || NULL                          -- カスタム明細２４
                || cv_msg_canm || NULL                          -- カスタム明細２５
                || cv_msg_canm || NULL                          -- カスタム明細２６
                || cv_msg_canm || NULL                          -- カスタム明細２７
                || cv_msg_canm || NULL                          -- カスタム明細２８
                || cv_msg_canm || NULL                          -- カスタム明細２９
                || cv_msg_canm || NULL                          -- カスタム明細３０
                || cv_msg_canm || NULL                          -- カスタム明細３１
                || cv_msg_canm || NULL                          -- カスタム明細３２
                || cv_msg_canm || NULL                          -- カスタム明細３３
                || cv_msg_canm || NULL                          -- カスタム明細３４
                || cv_msg_canm || NULL                          -- カスタム明細３５
                || cv_msg_canm || NULL                          -- カスタム明細３６
                || cv_msg_canm || NULL                          -- カスタム明細３７
                || cv_msg_canm || NULL                          -- カスタム明細３８
                || cv_msg_canm || NULL                          -- カスタム明細３９
                || cv_msg_canm || NULL                          -- カスタム明細４０
                || cv_msg_canm || NULL                          -- カスタム明細４１
                || cv_msg_canm || NULL                          -- カスタム明細４２
                || cv_msg_canm || NULL                          -- カスタム明細４３
                || cv_msg_canm || NULL                          -- カスタム明細４４
                || cv_msg_canm || NULL                          -- カスタム明細４５
                || cv_msg_canm || NULL                          -- カスタム明細４６
                ;
--
            ln_out_cnt := ln_out_cnt + 1;
--
          END IF;
          -- 次回ループ用に顧客を保持
          lv_pre_cust_code := g_custom_rec.cust_code;
--
          -- ===============================================
          -- カスタム明細・項目情報出力
          -- ===============================================
          lt_out_data(ln_out_cnt).column := '<CD>'            -- 通知書書式設定コード
              || cv_msg_canm || g_custom_rec.custom1          -- カスタム明細１（設置場所）
              || cv_msg_canm || g_custom_rec.custom2          -- カスタム明細２（売価／容器）
              || cv_msg_canm || g_custom_rec.custom3          -- カスタム明細３（販売本数）
              || cv_msg_canm || g_custom_rec.custom4          -- カスタム明細４（販売金額（税込））
              || cv_msg_canm || g_custom_rec.custom5          -- カスタム明細５（販売金額（税抜））
              || cv_msg_canm || g_custom_rec.custom6          -- カスタム明細６（ご契約内容）
              || cv_msg_canm || g_custom_rec.custom7          -- カスタム明細７（販売手数料（税抜））
              || cv_msg_canm || g_custom_rec.custom8          -- カスタム明細８（消費税）
              || cv_msg_canm || g_custom_rec.custom9          -- カスタム明細９（販売手数料（税込））
              || cv_msg_canm || NULL                          -- カスタム明細１０
              || cv_msg_canm || NULL                          -- カスタム明細１１
              || cv_msg_canm || NULL                          -- カスタム明細１２
              || cv_msg_canm || NULL                          -- カスタム明細１３
              || cv_msg_canm || NULL                          -- カスタム明細１４
              || cv_msg_canm || NULL                          -- カスタム明細１５
              || cv_msg_canm || NULL                          -- カスタム明細１６
              || cv_msg_canm || NULL                          -- カスタム明細１７
              || cv_msg_canm || NULL                          -- カスタム明細１８
              || cv_msg_canm || NULL                          -- カスタム明細１９
              || cv_msg_canm || NULL                          -- カスタム明細２０
              || cv_msg_canm || NULL                          -- カスタム明細２１
              || cv_msg_canm || NULL                          -- カスタム明細２２
              || cv_msg_canm || NULL                          -- カスタム明細２３
              || cv_msg_canm || NULL                          -- カスタム明細２４
              || cv_msg_canm || NULL                          -- カスタム明細２５
              || cv_msg_canm || NULL                          -- カスタム明細２６
              || cv_msg_canm || NULL                          -- カスタム明細２７
              || cv_msg_canm || NULL                          -- カスタム明細２８
              || cv_msg_canm || NULL                          -- カスタム明細２９
              || cv_msg_canm || NULL                          -- カスタム明細３０
              || cv_msg_canm || NULL                          -- カスタム明細３１
              || cv_msg_canm || NULL                          -- カスタム明細３２
              || cv_msg_canm || NULL                          -- カスタム明細３３
              || cv_msg_canm || NULL                          -- カスタム明細３４
              || cv_msg_canm || NULL                          -- カスタム明細３５
              || cv_msg_canm || NULL                          -- カスタム明細３６
              || cv_msg_canm || NULL                          -- カスタム明細３７
              || cv_msg_canm || NULL                          -- カスタム明細３８
              || cv_msg_canm || NULL                          -- カスタム明細３９
              || cv_msg_canm || NULL                          -- カスタム明細４０
              || cv_msg_canm || NULL                          -- カスタム明細４１
              || cv_msg_canm || NULL                          -- カスタム明細４２
              || cv_msg_canm || NULL                          -- カスタム明細４３
              || cv_msg_canm || NULL                          -- カスタム明細４４
              || cv_msg_canm || NULL                          -- カスタム明細４５
              || cv_msg_canm || NULL                          -- カスタム明細４６
              ;
--
          ln_out_cnt := ln_out_cnt + 1;
--
          -- カスタム明細カウンタ
          ln_l_loop_cnt := ln_l_loop_cnt + 1;
--
          -- ===============================================
          -- 連携対象データ更新(カスタム明細)(A-5)
          -- ===============================================
          upd_data_c(
            ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
           ,iv_row_id_c     => g_custom_rec.row_id_c
          );
--
        END LOOP custom_loop;
        CLOSE g_custom_cur;
--
        -- 書き込みループ
        FOR i IN 1..ln_out_cnt - 1 LOOP
--
          -- ===============================================
          -- 出力の表示へ連係情報出力
          -- ===============================================
          lb_msg_return := xxcok_common_pkg.put_message_f(
                             in_which        => FND_FILE.OUTPUT
                            ,iv_message      => lt_out_data(i).column
                            ,in_new_line     => 0
                           );
--
        END LOOP;
        gn_normal_cnt := gn_normal_cnt + 1;
--
        -- ===============================================
        -- 連携対象データ更新(ヘッダー)(A-6)
        -- ===============================================
        upd_data_h(
          ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
         ,iv_row_id_h     => lv_pre_h_row_id
        );
--
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        lv_outmsg    := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_10813
                          ,iv_token_name1   => cv_tkn_vendor_code
                          ,iv_token_value1  => lv_pre_vendor_code
                         );
        lb_msg_return := xxcok_common_pkg.put_message_f(
                           in_which        => FND_FILE.LOG
                          ,iv_message      => lv_outmsg
                          ,in_new_line     => 0
                         );
--
        --カウンタ、フラグ、出力用変数を初期化
        ln_out_cnt  := 1;
        lt_out_data.DELETE;
        -- カウンタ
        gn_target_cnt := gn_target_cnt + 1;
--
      END IF;
--
      -- ヘッダーがない場合は処理を抜ける
      EXIT WHEN g_head_cur%NOTFOUND;
      -- 次回ループ用に送付先を保持
      lv_pre_vendor_code := g_head_rec.vendor_code;
      lv_pre_h_row_id    := g_head_rec.row_id_h;      
      --
      -- ===============================================
      -- 連携データファイル作成(A-4)
      -- ===============================================
      -- 1行目かチェック
      IF (ln_h_loop_cnt = 0) THEN
        -- ===============================================
        -- ヘッダー・項目名出力
        -- ===============================================
        lv_head_data := gt_head_item(1)                 -- 通知書書式設定コード
            || cv_msg_canm || gt_head_item(2)           -- 会社名
            || cv_msg_canm || gt_head_item(3)           -- 事務所・営業署名
            || cv_msg_canm || gt_head_item(4)           -- 郵便番号
            || cv_msg_canm || gt_head_item(5)           -- 住所
            || cv_msg_canm || gt_head_item(6)           -- 住所（番地、建名物等）
            || cv_msg_canm || gt_head_item(7)           -- 電話番号
            || cv_msg_canm || gt_head_item(8)           -- FAX番号
            || cv_msg_canm || gt_head_item(9)           -- 事業所・営業所名
            || cv_msg_canm || gt_head_item(10)          -- 部署名
            || cv_msg_canm || gt_head_item(11)          -- 郵便番号
            || cv_msg_canm || gt_head_item(12)          -- 住所
            || cv_msg_canm || gt_head_item(13)          -- 住所（番地・建物名）
            || cv_msg_canm || gt_head_item(14)          -- 電話番号
            || cv_msg_canm || gt_head_item(15)          -- 番号
            || cv_msg_canm || gt_head_item(16)          -- 送付先コード
            || cv_msg_canm || gt_head_item(17)          -- 件名
            || cv_msg_canm || gt_head_item(18)          -- 支払日
            || cv_msg_canm || gt_head_item(19)          -- おもての通知金額
            || cv_msg_canm || gt_head_item(20)          -- 10%合計金額（税抜）
            || cv_msg_canm || gt_head_item(21)          -- 10%消費税額
            || cv_msg_canm || gt_head_item(22)          -- 10%合計金額（税込）
            || cv_msg_canm || gt_head_item(23)          -- 軽減8%合計金額（税抜）
            || cv_msg_canm || gt_head_item(24)          -- 軽減8%消費税額
            || cv_msg_canm || gt_head_item(25)          -- 軽減8%合計金額（税込）
            || cv_msg_canm || gt_head_item(26)          -- 非課税合計金額（税抜）
            || cv_msg_canm || gt_head_item(27)          -- 非課税消費税額
            || cv_msg_canm || gt_head_item(28)          -- 非課税合計金額（税込）
            || cv_msg_canm || gt_head_item(29)          -- 締日
            || cv_msg_canm || gt_head_item(30)          -- 販売本数合計
            || cv_msg_canm || gt_head_item(31)          -- 販売金額合計
            || cv_msg_canm || gt_head_item(32)          -- 販売手数料　税抜／販売手数料　税込
            || cv_msg_canm || gt_head_item(33)          -- 電気代等合計　税抜
            || cv_msg_canm || gt_head_item(34)          -- 消費税／内消費税
            || cv_msg_canm || gt_head_item(35)          -- 振込手数料　税込
            || cv_msg_canm || gt_head_item(36)          -- お支払金額　税込
            || cv_msg_canm || gt_head_item(37)          -- 明細項目
            || cv_msg_canm || gt_head_item(38)          -- 単価
            || cv_msg_canm || gt_head_item(39)          -- 数量
            || cv_msg_canm || gt_head_item(40)          -- 単位
            || cv_msg_canm || gt_head_item(41)          -- 金額
            || cv_msg_canm || gt_head_item(42)          -- 消費税額
            || cv_msg_canm || gt_head_item(43)          -- 合計金額
            || cv_msg_canm || gt_head_item(44)          -- 部門名
            || cv_msg_canm || gt_head_item(45)          -- 備考
            || cv_msg_canm || gt_head_item(46)          -- 対象期間開始日
            || cv_msg_canm || gt_head_item(47)          -- 対象期間終了日
            ;
--
            -- ===============================================
            -- 出力の表示へ連係情報出力
            -- ===============================================
            lb_msg_return := xxcok_common_pkg.put_message_f(
                               in_which        => FND_FILE.OUTPUT
                              ,iv_message      => lv_head_data
                              ,in_new_line     => 0
                             );
--
      END IF;
      -- ===============================================
      -- ヘッダー・明細情報出力
      -- ===============================================
      lt_out_data(ln_out_cnt).column := g_head_rec.set_code                 -- 通知書書式設定コード
          || cv_msg_canm || g_head_rec.cust_name                            -- 会社名
          || cv_msg_canm || g_head_rec.office                               -- 事務所・営業署名
          || cv_msg_canm || g_head_rec.dest_post_code                       -- 郵便番号
          || cv_msg_canm || g_head_rec.dest_address1                        -- 住所
          || cv_msg_canm || g_head_rec.dest_address2                        -- 住所（番地、建名物等）
          || cv_msg_canm || g_head_rec.dest_tel                             -- 電話番号
          || cv_msg_canm || g_head_rec.fax                                  -- FAX番号
          || cv_msg_canm || g_head_rec.business                             -- 事業所・営業所名
          || cv_msg_canm || g_head_rec.dept_name                            -- 部署名
          || cv_msg_canm || g_head_rec.send_post_code                       -- 郵便番号
          || cv_msg_canm || g_head_rec.send_address1                        -- 住所
          || cv_msg_canm || g_head_rec.send_address2                        -- 住所（番地・建物名）
          || cv_msg_canm || g_head_rec.send_tel                             -- 電話番号
          || cv_msg_canm || g_head_rec.num                                  -- 番号
          || cv_msg_canm || g_head_rec.vendor_code                          -- 送付先コード
          || cv_msg_canm || g_head_rec.subject                              -- 件名
          || cv_msg_canm || TO_CHAR( g_head_rec.payment_date, cv_fmt_ymd )  -- 支払日
          || cv_msg_canm || g_head_rec.notifi_amt                           -- おもての通知金額
          || cv_msg_canm || g_head_rec.total_amt_no_tax_10                  -- 10%合計金額（税抜）
          || cv_msg_canm || g_head_rec.tax_amt_10                           -- 10%消費税額
          || cv_msg_canm || g_head_rec.total_amt_10                         -- 10%合計金額（税込）
          || cv_msg_canm || g_head_rec.total_amt_no_tax_8                   -- 軽減8%合計金額（税抜）
          || cv_msg_canm || g_head_rec.tax_amt_8                            -- 軽減8%消費税額
          || cv_msg_canm || g_head_rec.total_amt_8                          -- 軽減8%合計金額（税込）
          || cv_msg_canm || g_head_rec.total_amt_no_tax_0                   -- 非課税合計金額（税抜）
          || cv_msg_canm || g_head_rec.tax_amt_0                            -- 非課税消費税額
          || cv_msg_canm || g_head_rec.total_amt_0                          -- 非課税合計金額（税込）
          || cv_msg_canm || TO_CHAR( g_head_rec.closing_date, cv_fmt_ymd )  -- 締日
          || cv_msg_canm || g_head_rec.total_sales_qty                      -- 販売本数合計
          || cv_msg_canm || g_head_rec.total_sales_amt                      -- 販売金額合計
          || cv_msg_canm || g_head_rec.sales_fee                            -- 販売手数料　税抜／販売手数料　税込
          || cv_msg_canm || g_head_rec.electric_amt                         -- 電気代等合計　税抜
          || cv_msg_canm || g_head_rec.h_tax_amt                            -- 消費税／内消費税
          || cv_msg_canm || g_head_rec.transfer_fee                         -- 振込手数料　税込
          || cv_msg_canm || g_head_rec.payment_amt                          -- お支払金額　税込
          || cv_msg_canm || null                                            -- 明細項目
          || cv_msg_canm || null                                            -- 単価
          || cv_msg_canm || null                                            -- 数量
          || cv_msg_canm || null                                            -- 単位
          || cv_msg_canm || null                                            -- 金額
          || cv_msg_canm || null                                            -- 消費税額
          || cv_msg_canm || null                                            -- 合計金額
          || cv_msg_canm || null                                            -- 部門名
          || cv_msg_canm || g_head_rec.remarks                              -- 備考
          || cv_msg_canm || SUBSTR(
                                   TO_CHAR( g_head_rec.closing_date_min, cv_fmt_ymd2 )
                                   ,1
                                   ,6
                                   ) ||'01'                                  -- 対象期間開始日
          || cv_msg_canm || TO_CHAR( g_head_rec.closing_date, cv_fmt_ymd2 )  -- 対象期間終了日
          ;
--
      ln_out_cnt := ln_out_cnt + 1;
--
      -- ===============================================
      -- 対象件数取得
      -- ===============================================
      -- ヘッダカウンタ
      ln_h_loop_cnt := ln_h_loop_cnt + 1;
--
    END LOOP head_loop;
    CLOSE g_head_cur;
--
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_work_head_line;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_tax_div    IN  VARCHAR2    --  1.税区分
   ,iv_rev        IN  VARCHAR2    --  2.REV
   ,ov_errbuf     OUT VARCHAR2    --  エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2    --  リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2    --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'init';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf      VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode     VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg      VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg      VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return  BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
--
    lv_head_item    fnd_new_messages.message_text%TYPE;
    lv_custom_item  fnd_new_messages.message_text%TYPE;
    ln_cnt          NUMBER;
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 初期処理エラー ***
    init_fail_expt  EXCEPTION;
    --*** クイックコードデータ取得エラー ***
    no_data_expt    EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- コンカレント入力パラメータを出力
    -- ===============================================
    lv_outmsg     := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxcok
                      ,iv_name         => cv_msg_xxcok1_10815
                      ,iv_token_name1  => cv_tkn_tax_div
                      ,iv_token_value1 => iv_tax_div
                      ,iv_token_name2  => cv_tkn_rev
                      ,iv_token_value2 => iv_rev
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_outmsg
                      ,in_new_line     => 2
                     );
    -- ===============================================
    -- 1.業務処理日付取得
    -- ===============================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_process_date IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_00028
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_outmsg
                        ,in_new_line     => 0
                       );
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 2.プロファイル取得(組織ID)
    -- ===============================================
    gn_org_id := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_org_id ) );
    IF ( gn_org_id IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_org_id
                    );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
--
    -- パラメータ税区分：外税の場合
    IF ( iv_tax_div = '1' ) THEN
      -- ===============================================
      -- 3.メッセージ取得(インフォマート用ヘッダー項目名（外税）)
      -- ===============================================
      lv_head_item  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10763
                       );
--
    -- パラメータ税区分：内税の場合
    ELSE
      -- ===============================================
      -- 3.メッセージ取得(インフォマート用ヘッダー項目名（内税）)
      -- ===============================================
      lv_head_item  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10764
                       );
--
    END IF;
--
    -- 項目分割(カンマ単位)
    -- ===============================================
    -- CSV文字列分割
    -- ===============================================
    xxcok_common_pkg.split_csv_data_p(
     ov_errbuf        => lv_errbuf
    ,ov_retcode       => lv_retcode
    ,ov_errmsg        => lv_errmsg
    ,iv_csv_data      => lv_head_item
    ,on_csv_col_cnt   => ln_cnt
    ,ov_split_csv_tab => gt_head_item
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 3.メッセージ取得(インフォマート用カスタム明細タイトル)
    -- ===============================================
    gv_custom_title  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_appli_short_name_xxcok
                         ,iv_name         => cv_msg_xxcok1_10765
                        );
--
    -- ===============================================
    -- 3.メッセージ取得(インフォマート用カスタム明細項目名)
    -- ===============================================
    lv_custom_item  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appli_short_name_xxcok
                        ,iv_name         => cv_msg_xxcok1_10766
                       );
--
    -- 項目分割(カンマ単位)
    -- ===============================================
    -- CSV文字列分割
    -- ===============================================
    xxcok_common_pkg.split_csv_data_p(
     ov_errbuf        => lv_errbuf
    ,ov_retcode       => lv_retcode
    ,ov_errmsg        => lv_errmsg
    ,iv_csv_data      => lv_custom_item
    ,on_csv_col_cnt   => ln_cnt
    ,ov_split_csv_tab => gt_custom_item
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 3.メッセージ取得(インフォマート用明細合計行名)
    -- ===============================================
    gv_line_sum  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_10767
                    );
--
  EXCEPTION
    -- *** クイックコードデータ取得エラー***
    WHEN no_data_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 初期処理エラー ***
    WHEN init_fail_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_outmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_tax_div    IN  VARCHAR2    --  1.税区分
   ,iv_rev        IN  VARCHAR2    --  2.REV
   ,ov_errbuf     OUT VARCHAR2    --  エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2    --  リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2    --  ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================================
    -- 固定ローカル定数
    -- ===============================================
    cv_prg_name  CONSTANT VARCHAR2(20) := 'submain';
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;
    lb_msg_return   BOOLEAN        DEFAULT TRUE;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 初期処理(A-1)
    -- ===============================================
    init(
      iv_tax_div    =>  iv_tax_div      --  1.税区分
     ,iv_rev        =>  iv_rev          --  2.REV
     ,ov_errbuf     =>  lv_errbuf       --  エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --  リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- ワークヘッダー・明細対象データ抽出(A-2)
    -- ===============================================
    get_work_head_line(
      iv_tax_div    => iv_tax_div
     ,iv_rev        => iv_rev
     ,ov_errbuf     => lv_errbuf
     ,ov_retcode    => lv_retcode
     ,ov_errmsg     => lv_errmsg
    );
--
    -- ===============================================
    -- スキップ件数が存在する場合、ステータス警告
    -- ===============================================
    IF ( gn_skip_cnt > 0 ) THEN
      ov_retcode  := cv_status_warn;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外 ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 処理部共通例外(ファイルクローズ) ***
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf          OUT VARCHAR2
   ,retcode         OUT VARCHAR2
   ,iv_tax_div      IN  VARCHAR2          -- 1.税区分
   ,iv_rev          IN  VARCHAR2          -- 2.REV
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name      CONSTANT VARCHAR2(20)  := 'main';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;              -- エラーメッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターンコード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;              -- ユーザーエラーメッセージ
    lv_out_msg       VARCHAR2(5000) DEFAULT NULL;              -- メッセージ変数
    lv_message_code  VARCHAR2(100)  DEFAULT NULL;              -- メッセージコード
    lb_msg_return    BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
--
  BEGIN
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_tax_div    => iv_tax_div       -- 1.税区分
     ,iv_rev        => iv_rev           -- 2.REV
     ,ov_errbuf     => lv_errbuf        -- エラー・メッセージ           --# 固定 #
     ,ov_retcode    => lv_retcode       -- リターン・コード             --# 固定 #e
     ,ov_errmsg     => lv_errmsg        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- ===============================================
    -- エラー出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                        ,iv_message    => lv_errmsg
                        ,in_new_line   => 1
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                        ,iv_message    => lv_errbuf
                        ,in_new_line   => 0
                       );
    END IF;
    -- ===============================================
    -- 警告発生時空行出力
    -- ===============================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.LOG
                        ,iv_message    => NULL
                        ,in_new_line   => 1
                       );
    END IF;
--
    -- ===============================================
    -- 対象件数出力
    -- ===============================================
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90000
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
                     );
--
    -- ===============================================
    -- 成功件数出力(エラー発生時0件)
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := 0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90001
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
                     );
    -- ===============================================
    -- エラー件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_error_cnt := 1;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90002
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
                     );
    -- ===============================================
    -- スキップ件数出力
    -- ===============================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_skip_cnt := 0;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => cv_msg_xxccp1_90003
                      ,iv_token_name1  => cv_tkn_count
                      ,iv_token_value1 => TO_CHAR( gn_skip_cnt )
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 1
                     );
    -- ===============================================
    -- 処理終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode    = cv_status_normal ) THEN
      lv_message_code := cv_msg_xxccp1_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_xxccp1_90005;
    ELSE
      lv_message_code := cv_msg_xxccp1_90006;
    END IF;
    lv_out_msg    := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appli_short_name_xxccp
                      ,iv_name         => lv_message_code
                     );
    lb_msg_return := xxcok_common_pkg.put_message_f(
                       in_which        => FND_FILE.LOG
                      ,iv_message      => lv_out_msg
                      ,in_new_line     => 0
                     );
    -- ===============================================
    -- ステータスセット
    -- ===============================================
    retcode := lv_retcode;
    -- ===============================================
    -- 終了ステータスエラー時、ロールバック
    -- ===============================================
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    -- *** 共通関数例外 ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCOK016A04C;
/
