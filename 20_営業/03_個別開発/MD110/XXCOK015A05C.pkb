CREATE OR REPLACE PACKAGE BODY XXCOK015A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK015A05C(body)
 * Description      : 営業システム構築プロジェクト
 * MD.050           : EDIシステムにてインフォマート社へ送信する支払案内書用データファイル作成
 * Version          : 1.3
 *
 * Program List
 * --------------------------- ----------------------------------------------------------
 *  Name                        Description
 * --------------------------- ----------------------------------------------------------
 *  file_close                  ファイルクローズ(A-12)
 *  upd_data                    連携対象データ更新(A-11)
 *  chk_data                    連携データ妥当性チェック(A-9)
 *  get_work_head_line          ワークヘッダー・明細対象データ抽出(A-7)(A-8)(A-10)
 *  file_open                   ファイルオープン(A-6)
 *  ins_work_header             ワークヘッダー情報作成(A-5)
 *  ins_work_custom             ワークカスタム明細情報作成(A-4)
 *  ins_work_line               ワーク明細情報作成(A-3)
 *  del_work                    ワークテーブルデータ削除(A-2)
 *  init                        初期処理(A-1)
 *  submain                     メイン処理プロシージャ
 *  main                        コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/11/25    1.0   N.Abe            新規作成
 *  2020/12/14    1.1   N.Abe            E_本稼動_16841
 *  2021/02/16    1.2   N.Abe            E_本稼動_16843
 *  2021/03/03    1.3   K.Kanada         E_本稼動_16843（本番障害対応）
 *
 *****************************************************************************************/
--
  -- ===============================================
  -- グローバル定数
  -- ===============================================
  -- パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20)    := 'XXCOK015A05C';
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
  cv_msg_xxcok1_00009        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00009';  -- ファイル存在エラー
  cv_msg_xxcok1_00028        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00028';  -- 業務処理日付取得エラー
  cv_msg_xxcok1_00036        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00036';  -- 締め・支払日取得エラー
  cv_msg_xxcok1_00053        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00053';  -- 販手残高テーブルロック取得エラー
  cv_msg_xxcok1_00067        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-00067';  -- ディレクトリ出力
  cv_msg_xxcok1_10434        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10434';  -- 銀行名全角チェック警告
  cv_msg_xxcok1_10435        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10435';  -- 銀行支店名全角チェック警告
  cv_msg_xxcok1_10460        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10460';  -- 銀行コード半角チェック警告
  cv_msg_xxcok1_10461        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10461';  -- 支店コード半角チェック警告
  cv_msg_xxcok1_10462        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10462';  -- 口座名半角チェック警告
  cv_msg_xxcok1_10762        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10762';  -- おもて備考
  cv_msg_xxcok1_10763        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10763';  -- インフォマート用ヘッダー項目名（外税）
  cv_msg_xxcok1_10764        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10764';  -- インフォマート用ヘッダー項目名（内税）
  cv_msg_xxcok1_10765        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10765';  -- インフォマート用カスタム明細タイトル
  cv_msg_xxcok1_10766        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10766';  -- インフォマート用カスタム明細項目名
  cv_msg_xxcok1_10767        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10767';  -- インフォマート用明細合計行名
  cv_msg_xxcok1_10768        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10768';  -- インフォマート用パラメータ出力
  cv_msg_xxcok1_10769        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10769';  -- 全角チェック警告
  cv_msg_xxcok1_10770        CONSTANT VARCHAR2(16)    := 'APP-XXCOK1-10770';  -- 半角数字およびハイフンチェック警告
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
  cv_tkn_directory           CONSTANT VARCHAR2(9)     := 'DIRECTORY';
  cv_tkn_file_name           CONSTANT VARCHAR2(9)     := 'FILE_NAME';
  cv_tkn_conn_loc            CONSTANT VARCHAR2(8)     := 'CONN_LOC';
  cv_tkn_vendor_code         CONSTANT VARCHAR2(11)    := 'VENDOR_CODE';
  cv_tkn_bank_code           CONSTANT VARCHAR2(9)     := 'BANK_CODE';
  cv_tkn_bank_name           CONSTANT VARCHAR2(9)     := 'BANK_NAME';
  cv_tkn_bank_branch_code    CONSTANT VARCHAR2(16)    := 'BANK_BRANCH_CODE';
  cv_tkn_bank_branch_name    CONSTANT VARCHAR2(16)    := 'BANK_BRANCH_NAME';
  cv_tkn_bank_holder_name    CONSTANT VARCHAR2(20)    := 'BANK_HOLDER_NAME_ALT';
  cv_tkn_count               CONSTANT VARCHAR2(5)     := 'COUNT';
  cv_tkn_col                 CONSTANT VARCHAR2(3)     := 'COL';
  cv_tkn_value               CONSTANT VARCHAR2(5)     := 'VALUE';
  cv_tkn_name                CONSTANT VARCHAR2(4)     := 'NAME';
  cv_tkn_tax_div             CONSTANT VARCHAR2(7)     := 'TAX_DIV';
  cv_tkn_proc_div            CONSTANT VARCHAR2(8)     := 'PROC_DIV';
  cv_tkn_target_div          CONSTANT VARCHAR2(10)    := 'TARGET_DIV';
  -- プロファイル
  cv_prof_i_dire_path        CONSTANT VARCHAR2(25)    := 'XXCOK1_INFOMART_DIRE_PATH';        -- インフォマート_ディレクトリパス
  cv_prof_i_file_name        CONSTANT VARCHAR2(25)    := 'XXCOK1_INFOMART_FILE_NAME';        -- インフォマート_ファイル名
  cv_prof_term_name          CONSTANT VARCHAR2(24)    := 'XXCOK1_DEFAULT_TERM_NAME';         -- デフォルト支払条件
  cv_prof_bank_fee_trans     CONSTANT VARCHAR2(41)    := 'XXCOK1_BANK_FEE_TRANS_CRITERION';  -- 銀行手数料_振込額基準
  cv_prof_bank_fee_less      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_LESS_CRITERION';   -- 銀行手数料_基準額未満
  cv_prof_bank_fee_more      CONSTANT VARCHAR2(30)    := 'XXCOK1_BANK_FEE_MORE_CRITERION';   -- 銀行手数料_基準額以上
  cv_prof_bm_tax             CONSTANT VARCHAR2(13)    := 'XXCOK1_BM_TAX';                    -- 販売手数料_消費税率
  cv_prof_org_id             CONSTANT VARCHAR2(6)     := 'ORG_ID';                           -- MO: 営業単位
  cv_prof_elec_change_item   CONSTANT VARCHAR2(30)    := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';     -- 電気料（変動）品目コード
  -- セパレータ
  cv_msg_part                CONSTANT VARCHAR2(3)     := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(1)     := '.';
  cv_msg_canm                CONSTANT VARCHAR2(1)     := ',';
  -- 書式フォーマット
  cv_fmt_ymd                 CONSTANT VARCHAR2(10)    := 'YYYY/MM/DD';
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
  gd_operating_date          DATE   DEFAULT NULL;                               -- 締め支払日導出元日付
  gd_closing_date            DATE   DEFAULT NULL;                               -- 締め日
  gd_schedule_date           DATE   DEFAULT NULL;                               -- 支払予定日
  gd_pay_date                DATE   DEFAULT NULL;                               -- 支払日
  gn_org_id                  NUMBER;                                            -- 営業単位ID
  gv_i_dire_path             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- インフォマート_ディレクトリパス
  gv_i_file_name             fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- インフォマート_ファイル名
  gv_term_name               fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 支払条件
  gv_bank_fee_trans          fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_振込額基準
  gv_bank_fee_less           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_基準額未満
  gv_bank_fee_more           fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 銀行手数料_基準額以上
  gv_elec_change_item_code   fnd_profile_option_values.profile_option_value%TYPE DEFAULT NULL; -- 電気料（変動）品目コード
  gn_bm_tax                  NUMBER;                                            -- 販売手数料_消費税率
  gn_tax_include_less        NUMBER;                                            -- 税込銀行手数料_基準額未満
  gn_tax_include_more        NUMBER;                                            -- 税込銀行手数料_基準額以上
  g_file_handle              UTL_FILE.FILE_TYPE;                                -- ファイルハンドル
--
  gv_remarks                 fnd_new_messages.message_text%TYPE;                -- おもて備考
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
     ,it_target_div IN  VARCHAR2
  )
  IS
    -- 支払あり
-- Ver1.2 N.Abe MOD START
--    SELECT  xiwh.set_code               AS  set_code
    SELECT  /*+ LEADING(xiwh xiwl) USE_HASH(xiwl) */
            xiwh.set_code               AS  set_code
-- Ver1.2 N.Abe MOD END
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
-- Ver1.2 N.Abe MOD START
--           ,NULL                        AS  subject
           ,xiwh.cust_name              AS  subject
-- Ver1.2 N.Abe MOD END
           ,xiwh.payment_date           AS  payment_date
           ,CASE
              WHEN xiwh.notifi_amt < 0 THEN
                0
              ELSE
                xiwh.notifi_amt
            END                         AS  notifi_amt
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
           ,CASE
              WHEN xiwh.payment_amt < 0 THEN
                0
              ELSE
                xiwh.payment_amt
            END                         AS  payment_amt
           ,xiwl.line_item              AS  line_item
           ,xiwl.unit_price             AS  unit_price
           ,xiwl.qty                    AS  qty
           ,xiwl.unit_type              AS  unit_type
           ,xiwl.amt                    AS  amt
           ,xiwl.tax_amt                AS  l_tax_amt
           ,xiwl.total_amt              AS  total_amt
           ,xiwl.inst_dest              AS  inst_dest
           ,xiwh.remarks                AS  remarks
           ,xiwh.bank_code              AS  bank_code
           ,xiwh.bank_name              AS  bank_name
           ,xiwh.branch_code            AS  branch_code
           ,xiwh.branch_name            AS  branch_name
           ,xiwh.bank_holder_name_alt   AS  bank_holder_name_alt
           ,xiwl.cust_code              AS  cust_code
           ,xiwl.order_num              AS  order_num
           ,xiwl.item_code              AS  item_code
      FROM  xxcok_info_work_header   xiwh
           ,xxcok_info_work_line     xiwl
     WHERE xiwh.vendor_code   = xiwl.vendor_code(+)
     AND   xiwh.tax_div       = it_tax_div
     AND   xiwl.tax_div(+)    = it_tax_div          -- 販売明細が存在しない場合も含む（外部結合）
     AND   xiwh.target_div    = it_target_div
     AND   xiwl.target_div(+) = it_target_div       -- 販売明細が存在しない場合も含む（外部結合）
-- Ver1.2 N.Abe ADD START
     AND   xiwl.tax_div(+)    = xiwh.tax_div          -- 販売明細が存在しない場合も含む（外部結合）
     AND   xiwl.target_div(+) = xiwh.target_div       -- 販売明細が存在しない場合も含む（外部結合）
-- Ver1.2 N.Abe ADD END
     AND   xiwh.payment_amt   > 0                   -- 支払あり
    UNION ALL
    -- 支払なし 且つ 販売明細が存在する場合
-- Ver1.2 N.Abe MOD START
--    SELECT
    SELECT  /*+ LEADING(xiwh xiwl) USE_NL(xiwl) INDEX(xiwl XXCOK_INFO_WORK_LINE_N01) */
-- Ver1.2 N.Abe MOD END
            CASE
              WHEN it_tax_div = '1' THEN '0'
              WHEN it_tax_div = '2' THEN '2'
            END                         AS  set_code                -- 通知書書式設定コード
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
-- Ver1.2 N.Abe MOD START
--           ,NULL                        AS  subject
           ,xiwh.cust_name              AS  subject
-- Ver1.2 N.Abe MOD END
           ,xiwh.payment_date           AS  payment_date
           ,0                           AS  notifi_amt
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
           ,0                           AS  total_sales_qty
           ,0                           AS  total_sales_amt
           ,0                           AS  sales_fee
           ,NULL                        AS  electric_amt
           ,0                           AS  h_tax_amt
           ,0                           AS  transfer_fee
           ,0                           AS  payment_amt
           ,xiwl.line_item              AS  line_item
           ,xiwl.unit_price             AS  unit_price
           ,xiwl.qty                    AS  qty
           ,xiwl.unit_type              AS  unit_type
           ,xiwl.amt                    AS  amt
           ,xiwl.tax_amt                AS  l_tax_amt
           ,xiwl.total_amt              AS  total_amt
           ,xiwl.inst_dest              AS  inst_dest
           ,xiwh.remarks                AS  remarks
           ,xiwh.bank_code              AS  bank_code
           ,xiwh.bank_name              AS  bank_name
           ,xiwh.branch_code            AS  branch_code
           ,xiwh.branch_name            AS  branch_name
           ,xiwh.bank_holder_name_alt   AS  bank_holder_name_alt
           ,xiwl.cust_code              AS  cust_code
           ,xiwl.order_num              AS  order_num
           ,xiwl.item_code              AS  item_code
      FROM  xxcok_info_work_header   xiwh
           ,xxcok_info_work_line     xiwl
     WHERE xiwh.vendor_code   = xiwl.vendor_code    -- 販売明細(ﾜｰｸ明細)が存在する場合（等結合）
     AND   xiwh.tax_div       = it_tax_div
-- Ver1.2 N.Abe MOD START
--     AND   xiwl.tax_div       = it_tax_div          -- 販売明細(ﾜｰｸ明細)が存在する場合（等結合）
--     AND   xiwh.target_div    = it_target_div
--     AND   xiwl.target_div    = it_target_div       -- 販売明細(ﾜｰｸ明細)が存在する場合（等結合）
     AND   xiwh.target_div    = it_target_div
     AND   xiwl.tax_div       = xiwh.tax_div          -- 販売明細(ﾜｰｸ明細)が存在する場合（等結合）
     AND   xiwl.target_div    = xiwh.target_div       -- 販売明細(ﾜｰｸ明細)が存在する場合（等結合）
-- Ver1.2 N.Abe MOD END
     AND   xiwh.payment_amt  <= 0                   -- 支払なし
     ORDER BY
           vendor_code
          ,cust_code
          ,inst_dest
          ,order_num
          ,item_code
          ,unit_price
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
-- Ver1.2 N.Abe MOD START
           ,xiwc.calc_sort              AS  calc_sort
-- Ver1.2 N.Abe MOD END
     FROM   xxcok_info_work_custom   xiwc
     WHERE  xiwc.vendor_code    = it_supplier_code
     AND    xiwc.tax_div        = it_tax_div
     AND    exists (
-- Ver1.2 N.Abe MOD START
--              SELECT 1
              SELECT /*+ use_nl(xiwh) */ 1
-- Ver1.2 N.Abe MOD END
              FROM   xxcok_info_work_header   xiwh
              WHERE  xiwh.vendor_code = xiwc.vendor_code
              AND    xiwh.tax_div     = xiwc.tax_div
              AND    xiwh.payment_amt > 0                 -- 支払あり
              )
     ORDER BY xiwc.cust_code
-- Ver1.1 N.Abe MOD START
--             ,xiwc.inst_dest
             ,xiwc.calc_sort
             ,xiwc.bottle_code
             ,xiwc.salling_price
-- Ver1.2 N.Abe MOD START
             ,CASE
                WHEN xiwc.calc_sort = '2.7' THEN
                  TO_NUMBER(xiwc.sell_bottle)
                ELSE
                  NULL
              END
-- Ver1.2 N.Abe MOD END
             ,xiwc.rebate_rate
             ,xiwc.rebate_amt
-- Ver1.1 N.Abe MOD END
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
  --*** 処理部共通例外(ファイルクローズ) ***
  global_process_file_close_expt  EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                 EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt          EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
  PRAGMA EXCEPTION_INIT(global_lock_fail,-54);
--
  /**********************************************************************************
   * Procedure Name   : file_close
   * Description      : ファイルクローズ(A-12)
   ***********************************************************************************/
  PROCEDURE file_close(
    ov_errbuf   OUT VARCHAR2
   ,ov_retcode  OUT VARCHAR2
   ,ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_close';  -- プログラム名
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
    -- ===============================================
    -- ファイルクローズ
    -- ===============================================
    IF( UTL_FILE.IS_OPEN( g_file_handle ) ) THEN
      UTL_FILE.FCLOSE(
        file   =>   g_file_handle
      );
    END IF;
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END file_close;
--
  /**********************************************************************************
   * Procedure Name   : upd_data
   * Description      : 連携対象データ更新(A-11)
   ***********************************************************************************/
  PROCEDURE upd_data(
    ov_errbuf      OUT VARCHAR2
   ,ov_retcode     OUT VARCHAR2
   ,ov_errmsg      OUT VARCHAR2
   ,iv_vendor_code IN  VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'upd_data';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    CURSOR l_lock_cur
    IS
      SELECT  /*+ INDEX(xbb xxcok_backmargin_balance_n06) */
              xbb.bm_balance_id
      FROM    xxcok_backmargin_balance  xbb
      WHERE   xbb.supplier_code         = iv_vendor_code
      AND     xbb.resv_flag             IS NULL
      AND     xbb.edi_interface_status  = '0'
      AND     xbb.fb_interface_status   = '0'
      AND     xbb.gl_interface_status   = '0'
      AND     xbb.closing_date          <= gd_closing_date
      AND     xbb.expect_payment_date   <= gd_schedule_date
      AND     xbb.amt_fix_status        = '1'
      AND     NVL(xbb.payment_amt_tax, 0) = 0
      FOR UPDATE OF xbb.bm_balance_id NOWAIT;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 販手残高テーブルロック取得
    -- ===============================================
    << lock_loop >>
    FOR l_lock_rec IN l_lock_cur LOOP
      -- ===============================================
      -- 販手残高テーブル更新
      -- ===============================================
      UPDATE xxcok_backmargin_balance xbb
         SET xbb.publication_date        = gd_pay_date                          -- 案内書発効日
            ,xbb.edi_interface_date      = gd_process_date                      -- 連携日（EDI支払案内書）
            ,xbb.edi_interface_status    = '1'                                  -- 連携ステータス（EDI支払案内書）
            ,xbb.last_updated_by         = cn_last_updated_by
            ,xbb.last_update_date        = SYSDATE
            ,xbb.last_update_login       = cn_last_update_login
            ,xbb.request_id              = cn_request_id
            ,xbb.program_application_id  = cn_program_application_id
            ,xbb.program_id              = cn_program_id
            ,xbb.program_update_date     = SYSDATE
       WHERE xbb.bm_balance_id           = l_lock_rec.bm_balance_id
      ;
    END LOOP lock_loop;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00053
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_outmsg
                        ,in_new_line     => 0
                       );
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
  END upd_data;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : 連携データ妥当性チェック(A-9)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf      OUT    VARCHAR2
   ,ov_retcode     OUT    VARCHAR2
   ,ov_errmsg      OUT    VARCHAR2
   ,it_head_rec    IN     g_head_cur%ROWTYPE
   ,it_cust_rec    IN     g_custom_cur%ROWTYPE
   ,iv_h_c         IN     VARCHAR2
   ,iv_chk_flg     IN OUT NOCOPY VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'chk_data';                      -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;                                -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;                    -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;                                -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;                                -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;                                -- メッセージ関数戻り値用
    lb_chk_return   BOOLEAN        DEFAULT TRUE;                                -- チェック結果戻り値用
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
--
    -- ===============================================
    -- ヘッダー・明細
    -- ===============================================
    IF (iv_h_c = 'H') THEN  -- ヘッダーの場合
      -- チェックフラグがNの場合チェックする（Yならチェック済み）
      IF (iv_chk_flg = 'N') THEN
        -- ===============================================
        -- 全角チェック
        -- ===============================================
--
        -- 会社名
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.cust_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(2)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.cust_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 住所（送付先）
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.dest_address1
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(5)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dest_address1
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 部署名
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.dept_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(10)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dept_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 住所（送付元）
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.send_address1
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(12)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.send_address1
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
-- Ver1.2 N.Abe DEL START
--        -- おもて備考
--        lb_chk_return := xxccp_common_pkg.chk_double_byte(
--                           iv_chk_char  => it_head_rec.remarks
--                         );
--        IF ( lb_chk_return = FALSE ) THEN
----
--          lv_outmsg       := xxccp_common_pkg.get_msg(
--                               iv_application   => cv_appli_short_name_xxcok
--                              ,iv_name          => cv_msg_xxcok1_10769
--                              ,iv_token_name1   => cv_tkn_col
--                              ,iv_token_value1  => gt_head_item(45)
--                              ,iv_token_name2   => cv_tkn_vendor_code
--                              ,iv_token_value2  => it_head_rec.vendor_code
--                              ,iv_token_name3   => cv_tkn_value
--                              ,iv_token_value3  => it_head_rec.remarks
--                             );
--          lb_msg_return   := xxcok_common_pkg.put_message_f(
--                               in_which         => FND_FILE.LOG
--                              ,iv_message       => lv_outmsg
--                              ,in_new_line      => 0
--                             );
--          ov_retcode := cv_status_warn;
--        END IF;
-- Ver1.2 N.Abe DEL END
--
        -- 銀行名
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.bank_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10434
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_name
                              ,iv_token_value4  => it_head_rec.bank_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 支店名
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.branch_name
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10435
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_branch_code
                              ,iv_token_value4  => it_head_rec.branch_code
                              ,iv_token_name5   => cv_tkn_bank_branch_name
                              ,iv_token_value5  => it_head_rec.branch_name
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
      -- 明細項目
      IF (it_head_rec.line_item IS NOT NULL) THEN
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.line_item
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(37)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.line_item
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
--
      -- 部門名（設置先名）
      IF (it_head_rec.inst_dest IS NOT NULL) THEN
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_head_rec.inst_dest
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(44)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.inst_dest
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
--
    END IF;
--
    -- カスタム明細
    IF (iv_h_c = 'C') THEN
      -- 計算条件が売価別条件、一律条件明細行以外の場合
-- Ver1.2 N.Abe MOD START
--      IF ( NVL( it_cust_rec.calc_type, '0' ) <> '10' ) THEN
      IF    ( ( NVL( it_cust_rec.calc_type, '0' ) <> '10' )
        AND   ( NVL( it_cust_rec.calc_sort, '0' ) <> '2.7' ) ) THEN
-- Ver1.2 N.Abe MOD END
        -- 売価／容器
        lb_chk_return := xxccp_common_pkg.chk_double_byte(
                           iv_chk_char  => it_cust_rec.custom2
                         );
        IF ( lb_chk_return = FALSE ) THEN
  --
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10769
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_custom_item(2)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_cust_rec.custom2
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
      END IF;
    END IF;
    -- ヘッダー・明細
    IF (iv_h_c = 'H') THEN
      -- チェックフラグがNの場合チェックする（Yならチェック済み）
      IF (iv_chk_flg = 'N') THEN
      -- ===============================================
      -- 半角数字およびハイフンチェック
      -- ===============================================
--
        -- 郵便番号（送付先）
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.dest_post_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(4)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dest_post_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 電話番号（送付先）
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.dest_tel
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(7)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.dest_tel
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- FAX番号
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.fax
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(8)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.fax
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 郵便番号（送付元）
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.send_post_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(11)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.send_post_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 電話番号（送付元）
        lb_chk_return := xxccp_common_pkg.chk_tel_format(
                           iv_check_char  => it_head_rec.send_tel
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10770
                              ,iv_token_name1   => cv_tkn_col
                              ,iv_token_value1  => gt_head_item(14)
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_value
                              ,iv_token_value3  => it_head_rec.send_tel
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
    END IF;
--
    -- ヘッダー・明細
    IF (iv_h_c = 'H') THEN
      -- チェックフラグがNの場合チェックする（Yならチェック済み）
      IF (iv_chk_flg = 'N') THEN
        -- ===============================================
        -- 半角チェック
        -- ===============================================
        -- 銀行コード
        lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                           iv_check_char  => it_head_rec.bank_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10460
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- 支店コード
        lb_chk_return := xxccp_common_pkg.chk_alphabet_number(
                           iv_check_char  => it_head_rec.branch_code
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10461
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_branch_code
                              ,iv_token_value4  => it_head_rec.branch_code
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
        -- ===============================================
        -- 半角英数字記号チェック
        -- ===============================================
        -- 口座名
        lb_chk_return := xxccp_common_pkg.chk_single_byte(
                           iv_chk_char  => it_head_rec.bank_holder_name_alt
                         );
        IF ( lb_chk_return = FALSE ) THEN
--
          lv_outmsg       := xxccp_common_pkg.get_msg(
                               iv_application   => cv_appli_short_name_xxcok
                              ,iv_name          => cv_msg_xxcok1_10462
                              ,iv_token_name1   => cv_tkn_conn_loc
                              ,iv_token_value1  => NULL
                              ,iv_token_name2   => cv_tkn_vendor_code
                              ,iv_token_value2  => it_head_rec.vendor_code
                              ,iv_token_name3   => cv_tkn_bank_code
                              ,iv_token_value3  => it_head_rec.bank_code
                              ,iv_token_name4   => cv_tkn_bank_branch_code
                              ,iv_token_value4  => it_head_rec.branch_code
                              ,iv_token_name5   => cv_tkn_bank_holder_name
                              ,iv_token_value5  => it_head_rec.bank_holder_name_alt
                             );
          lb_msg_return   := xxcok_common_pkg.put_message_f(
                               in_which         => FND_FILE.LOG
                              ,iv_message       => lv_outmsg
                              ,in_new_line      => 0
                             );
          ov_retcode := cv_status_warn;
        END IF;
--
      END IF;
--
    END IF;
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
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : get_work_head_line
   * Description      : ワークヘッダー・明細対象データ抽出(A-7)
   ***********************************************************************************/
  PROCEDURE get_work_head_line(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
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
--
    lv_pre_vendor_code    xxcok_info_work_header.vendor_code%TYPE;
    lv_pre_cust_code      xxcok_info_work_custom.cust_code%TYPE;
    ln_l_loop_cnt         NUMBER DEFAULT 0;
    ln_h_loop_cnt         NUMBER DEFAULT 0;
    ln_out_cnt            PLS_INTEGER;
    lv_skip_flg           VARCHAR2(1) DEFAULT 'N';
    lv_chk_flg            VARCHAR2(1) DEFAULT 'N';
    lv_upd_flg            VARCHAR2(1) DEFAULT 'Y';
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
           ,iv_target_div
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
        -- カスタム明細データ取得(A-8)
        -- ===============================================
        OPEN g_custom_cur(
                lv_pre_vendor_code
               ,iv_tax_div
              );
--
        << custom_loop >>
        LOOP
          FETCH g_custom_cur INTO g_custom_rec;
          EXIT WHEN g_custom_cur%NOTFOUND;
--
          -- ===============================================
          -- 連携データ妥当性チェック(カスタム明細)(A-9)
          -- ===============================================
          chk_data(
            ov_errbuf     => lv_errbuf
           ,ov_retcode    => lv_retcode
           ,ov_errmsg     => lv_errmsg
           ,it_head_rec   => g_head_rec
           ,it_cust_rec   => g_custom_rec
           ,iv_h_c        => 'C'
           ,iv_chk_flg    => lv_chk_flg
          );
--
          IF ( lv_retcode <> cv_status_normal ) THEN
            lv_skip_flg := 'Y';
          END IF;
--
          -- ===============================================
          -- 連携データファイル作成(A-10)
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
        END LOOP custom_loop;
        CLOSE g_custom_cur;
--
        -- 警告データなしの場合出力
        IF ( lv_skip_flg <> 'Y' ) THEN
          -- 書き込みループ
          FOR i IN 1..ln_out_cnt - 1 LOOP
            -- ===============================================
            -- ファイル出力
            -- ===============================================
            UTL_FILE.PUT_LINE(
              file      => g_file_handle
             ,buffer    => lt_out_data(i).column
            );
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
        ELSE
          gn_skip_cnt := gn_skip_cnt + 1;
        END IF;
--
        -- 更新対象かチェック
        IF ( lv_upd_flg = 'Y' ) AND ( lv_skip_flg = 'N' ) THEN
          -- ===============================================
          -- 連携対象データ更新(A-11)
          -- ===============================================
          upd_data(
            ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
           ,iv_vendor_code  => lv_pre_vendor_code
          );
        END IF;
--
        IF ( lv_retcode <> cv_status_normal ) THEN
          RAISE global_process_expt;
        END IF;
--
        --カウンタ、フラグ、出力用変数を初期化
        ln_out_cnt  := 1;
        lv_skip_flg := 'N';
        lv_chk_flg  := 'N';
        lv_upd_flg  := 'Y';
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
      --
      -- ===============================================
      -- 連携データファイル作成(A-10)
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
            ;
--
            -- ===============================================
            -- ファイル出力
            -- ===============================================
            UTL_FILE.PUT_LINE(
              file      => g_file_handle
             ,buffer    => lv_head_data
            );
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
          || cv_msg_canm || g_head_rec.line_item                            -- 明細項目
          || cv_msg_canm || g_head_rec.unit_price                           -- 単価
          || cv_msg_canm || g_head_rec.qty                                  -- 数量
          || cv_msg_canm || g_head_rec.unit_type                            -- 単位
          || cv_msg_canm || g_head_rec.amt                                  -- 金額
          || cv_msg_canm || g_head_rec.l_tax_amt                            -- 消費税額
          || cv_msg_canm || g_head_rec.total_amt                            -- 合計金額
          || cv_msg_canm || g_head_rec.inst_dest                            -- 部門名
          || cv_msg_canm || g_head_rec.remarks                              -- 備考
          ;
--
      ln_out_cnt := ln_out_cnt + 1;
--
      -- ===============================================
      -- 連携データ妥当性チェック(ヘッダー・明細)(A-9)
      -- ===============================================
      chk_data(
        ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
       ,it_head_rec   => g_head_rec
       ,it_cust_rec   => NULL
       ,iv_h_c        => 'H'
       ,iv_chk_flg    => lv_chk_flg
      );
--
      lv_chk_flg := 'Y';
--
      IF ( lv_retcode <> cv_status_normal ) THEN
        lv_skip_flg := 'Y';
      END IF;
--
      -- お支払金額をチェック
      IF ( g_head_rec.payment_amt <= 0 ) THEN
        -- 販手残高更新対象外にする。
        lv_upd_flg := 'N';
      END IF;

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
   * Procedure Name   : file_open
   * Description      : ファイルオープン(A-6)
   ***********************************************************************************/
  PROCEDURE file_open(
    ov_errbuf   OUT VARCHAR2
   ,ov_retcode  OUT VARCHAR2
   ,ov_errmsg   OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'file_open';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    lb_msg_return   BOOLEAN        DEFAULT TRUE;              -- メッセージ関数戻り値用
    lb_fexist       BOOLEAN        DEFAULT FALSE;             -- ファイル存在チェック結果
    ln_file_length  NUMBER         DEFAULT NULL;              -- ファイルの長さ
    ln_block_size   NUMBER         DEFAULT NULL;              -- ブロックサイズ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 存在チェックエラー ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ファイル存在チェック
    -- ===============================================
    UTL_FILE.FGETATTR(
      location     => gv_i_dire_path  -- ディレクトリ
     ,filename     => gv_i_file_name  -- ファイル名
     ,fexists      => lb_fexist       -- True:ファイル存在、False:ファイル存在なし
     ,file_length  => ln_file_length  -- ファイルの長さ
     ,block_size   => ln_block_size   -- ブロックサイズ
    );
    IF ( lb_fexist ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00009
                        ,iv_token_name1   => cv_tkn_file_name
                        ,iv_token_value1  => gv_i_file_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which        => FND_FILE.LOG
                        ,iv_message      => lv_outmsg
                        ,in_new_line     => 0
                       );
      RAISE check_file_expt;
    END IF;
    -- ===============================================
    -- ファイルオープン
    -- ===============================================
    g_file_handle := UTL_FILE.FOPEN(
                       gv_i_dire_path   -- ディレクトリ
                      ,gv_i_file_name   -- ファイル名
                      ,cv_open_mode_w   -- ファイルオープン方法
                      ,cn_max_linesize  -- 1行当り最大文字数
                     );
  EXCEPTION
    -- *** 存在チェックエラー ***
    WHEN check_file_expt THEN
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
  END file_open;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_header
   * Description      : ワークヘッダー情報作成(A-5)
   ***********************************************************************************/
  PROCEDURE ins_work_header(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_work_header';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 存在チェックエラー ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ヘッダー情報登録
    -- ===============================================
    INSERT INTO xxcok_info_work_header(
      set_code                -- 通知書書式設定コード
     ,cust_code               -- 顧客コード
     ,cust_name               -- 会社名
     ,dest_post_code          -- 郵便番号
     ,dest_address1           -- 住所
     ,dest_tel                -- 電話番号
     ,fax                     -- FAX番号
     ,dept_name               -- 部署名
     ,send_post_code          -- 郵便番号（送付元）
     ,send_address1           -- 住所（送付元）
     ,send_tel                -- 電話番号（送付元）
     ,num                     -- 番号
     ,vendor_code             -- 送付先コード
     ,payment_date            -- 支払日
     ,closing_date            -- 締め日
     ,notifi_amt              -- おもての通知金額
     ,total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
     ,tax_amt_8               -- 軽減8%消費税額
     ,total_amt_8             -- 軽減8%合計金額（税込）
     ,total_sales_qty         -- 販売本数合計
     ,total_sales_amt         -- 販売金額合計
     ,sales_fee               -- 販売手数料
     ,electric_amt            -- 電気代等合計　税抜
     ,tax_amt                 -- 消費税
     ,transfer_fee            -- 振込手数料　税込
     ,payment_amt             -- お支払金額　税込
     ,remarks                 -- おもて備考
     ,bank_code               -- 銀行コード
     ,bank_name               -- 銀行名
     ,branch_code             -- 支店コード
     ,branch_name             -- 支店名
     ,bank_holder_name_alt    -- 口座名
     ,tax_div                 -- 税区分
     ,target_div              -- 対象区分
     ,created_by              -- 作成者
     ,creation_date           -- 作成日
     ,last_updated_by         -- 最終更新者
     ,last_update_date        -- 最終更新日
     ,last_update_login       -- 最終更新ログイン
     ,request_id              -- 要求ID
     ,program_application_id  -- コンカレント・プログラム・アプリケーションID
     ,program_id              -- コンカレント・プログラムID
     ,program_update_date     -- プログラム更新日
    )
    SELECT  /*+ 
                LEADING(xbb pv pvsa)
                INDEX(xbb xxcok_backmargin_balance_n05)
                USE_NL(pv) USE_NL(pvsa) USE_NL(abau) USE_NL(aba) USE_NL(abb)
                */
            CASE
              WHEN iv_tax_div = '1' AND NVL(sum_e.sales_fee,0) = 0
              THEN '0'
              WHEN iv_tax_div = '1' AND NVL(sum_e.sales_fee,0) <> 0
              THEN '1'
              WHEN iv_tax_div = '2' AND NVL(sum_e.sales_fee,0) = 0
              THEN '2'
              WHEN iv_tax_div = '2' AND NVL(sum_e.sales_fee,0) <> 0
              THEN '3'
            END                                   AS  set_code                -- 通知書書式設定コード
           ,NULL                                  AS  cust_code               -- 顧客コード
           ,SUBSTR( pvsa.attribute1, 1, 30 )      AS  cust_name               -- 会社名
           ,SUBSTR(pvsa.zip, 1, 3) || '-' || SUBSTR(pvsa.zip, 4, 4)
                                                  AS  dest_post_code          -- 郵便番号
           ,SUBSTR( pvsa.address_line1 || pvsa.address_line2, 1, 100 )
                                                  AS  dest_address1           -- 住所
           ,pvsa.phone                            AS  dest_tel                -- 電話番号
           ,pvsa.fax                              AS  fax                     -- FAX番号
           ,SUBSTR( sub1.dept_name, 1, 30 )       AS  dept_name               -- 部署名
           ,SUBSTR(sub1.send_post_code, 1, 3) || '-' || SUBSTR(sub1.send_post_code, 4, 4)
                                                  AS  send_post_code          -- 郵便番号（送付元）
           ,SUBSTR( sub1.send_address1, 1, 100 )  AS  send_address1           -- 住所（送付元）
           ,sub1.send_tel                         AS  send_tel                -- 電話番号（送付元）
           ,xbb.supplier_code                     AS  num                     -- 番号
           ,xbb.supplier_code                     AS  vendor_code             -- 送付先コード
           ,gd_pay_date                           AS  payment_date            -- 支払日
           ,MAX(xbb.closing_date)                 AS  closing_date            -- 締め日
           ,CASE
              -- 外税
              WHEN iv_tax_div = '1'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       + NVL(sum_t.tax_amt,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
              --内税
              WHEN iv_tax_div = '2'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
            END                                   AS  notifi_amt              -- おもての通知金額
           ,NVL(sum_t.sales_amt,0)                AS  total_amt_no_tax_8      -- 軽減8%合計金額（税抜）
           ,NVL(sum_t.sales_tax_amt,0) - NVL(sum_t.sales_amt,0)
                                                  AS  tax_amt_8               -- 軽減8%消費税額
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_amt_8             -- 軽減8%合計金額（税込）
           ,NVL(sum_t.sales_qty,0)                AS  total_sales_qty         -- 販売本数合計
           ,NVL(sum_t.sales_tax_amt,0)            AS  total_sales_amt         -- 販売金額合計
           ,NVL(sum_ne.sales_fee,0)               AS  sales_fee               -- 販売手数料　税抜／販売手数料　税込
           ,NVL(sum_e.sales_fee,0)                AS  electric_amt            -- 電気代等合計　税抜／電気代等合計　税込
           ,NVL(sum_t.tax_amt,0)                  AS  tax_amt                 -- 消費税／内消費税
           ,CASE
              WHEN pvsa.bank_charge_bearer = 'I'
              THEN 0
              -- 外税
              WHEN    iv_tax_div = '1'
                  AND pvsa.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
              THEN gn_tax_include_less
              WHEN    iv_tax_div = '1'
                  AND pvsa.bank_charge_bearer <> 'I' 
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
              THEN gn_tax_include_more
              --内税
              WHEN    iv_tax_div = '2'
                  AND pvsa.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
              THEN gn_tax_include_less
              WHEN    iv_tax_div = '2'
                  AND pvsa.bank_charge_bearer <> 'I'
                  AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
              THEN gn_tax_include_more
            END * -1                              AS  transfer_fee            -- 振込手数料　税込
           ,CASE
              -- 外税
              WHEN iv_tax_div = '1'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       + NVL(sum_t.tax_amt,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) + NVL(sum_t.tax_amt,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
              --内税
              WHEN iv_tax_div = '2'
              THEN NVL(  NVL(sum_ne.sales_fee,0)
                       + NVL(sum_e.sales_fee,0)
                       - CASE
                           WHEN pvsa.bank_charge_bearer = 'I'
                           THEN 0
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) <  gv_bank_fee_trans
                           THEN gn_tax_include_less
                           WHEN    pvsa.bank_charge_bearer <> 'I' 
                               AND ( NVL(sum_ne.sales_fee,0) + NVL(sum_e.sales_fee,0) ) >= gv_bank_fee_trans
                           THEN gn_tax_include_more
                         END
                      , 0)
            END                                   AS  payment_amt             -- お支払金額　税込
-- Ver1.2 N.Abe MOD START
--           ,SUBSTR( gv_remarks, 1, 500 )          AS  remarks                 -- おもて備考
           ,SUBSTR( '"' || gv_remarks || '"', 1, 500 )
                                                  AS  remarks                 -- おもて備考
-- Ver1.2 N.Abe MOD END
           ,abb.bank_number                       AS  bank_code               -- 銀行コード
           ,abb.bank_name                         AS  bank_name               -- 銀行名
           ,abb.bank_num                          AS  branch_code             -- 支店コード
           ,abb.bank_branch_name                  AS  branch_name             -- 支店名
           ,aba.account_holder_name_alt           AS  bank_holder_name_alt    -- 口座名
           ,iv_tax_div                            AS  tax_div                 -- 税区分
           ,SUBSTR( xbb.supplier_code, -1, 1 )    AS  target_div              -- 対象区分
           ,cn_created_by                         AS  created_by              -- 作成者
           ,SYSDATE                               AS  creation_date           -- 作成日
           ,cn_last_updated_by                    AS  last_updated_by         -- 最終更新者
           ,SYSDATE                               AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                  AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                         AS  request_id              -- 要求ID
           ,cn_program_application_id             AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                         AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                               AS  program_update_date     -- プログラム更新日
    FROM    xxcok_backmargin_balance  xbb
           ,po_vendors                pv
           ,po_vendor_sites_all       pvsa
           ,ap_bank_account_uses      abau                              -- 銀行口座使用情報マスタ
           ,ap_bank_accounts          aba                               -- 銀行口座マスタ
           ,ap_bank_branches          abb                               -- 銀行支店マスタ
           --拠点情報
           ,(SELECT hca.account_number        AS  contact_code
                   ,hp.party_name             AS  dept_name
                   ,hl.postal_code            AS  send_post_code
                   ,hl.city     ||
                    hl.address1 ||
                    hl.address2               AS  send_address1
                   ,hl.address_lines_phonetic AS  send_tel
             FROM   hz_cust_accounts    hca   --顧客マスタ
                   ,hz_cust_acct_sites  hcas  --顧客所在地
                   ,hz_parties          hp    --パーティーマスタ
                   ,hz_party_sites      hps   --パーティーサイト
                   ,hz_locations        hl    --顧客事業所
             WHERE  hca.cust_account_id = hcas.cust_account_id
             AND    hca.party_id        = hp.party_id
             AND    hcas.party_site_id  = hps.party_site_id
             AND    hps.location_id     = hl.location_id
             AND    hcas.org_id         = gn_org_id
            ) sub1
            --全件
           ,(SELECT SUM(xiwc.sales_qty)      AS  sales_qty
                   ,SUM(xiwc.sales_tax_amt)  AS  sales_tax_amt
                   ,SUM(xiwc.tax_amt)        AS  tax_amt
                   ,SUM(xiwc.sales_amt)      AS  sales_amt
                   ,xiwc.vendor_code         AS  vendor_code
             FROM   xxcok_info_work_custom  xiwc
             WHERE  xiwc.calc_sort = 6
             AND    xiwc.tax_div   = iv_tax_div
             GROUP BY xiwc.vendor_code
            ) sum_t
            --電気代除く 
           ,(SELECT CASE
                      WHEN iv_tax_div = '1'
                      THEN SUM(xiwc.sales_fee)
                      WHEN iv_tax_div = '2'
                      THEN SUM(xiwc.sales_tax_fee)
                    END                     AS  sales_fee
                   ,xiwc.vendor_code
             FROM   xxcok_info_work_custom  xiwc
--Mod Ver1.3 K.Kanada S
--             WHERE  calc_sort NOT IN (2.5, 5, 6)  -- 小計、電気代、合計 を除く
             WHERE  calc_sort IN (1,2,3,4)          -- 売価別、容器別、一律条件、定額条件
--Mod Ver1.3 K.Kanada E
             AND    xiwc.tax_div   = iv_tax_div
             GROUP BY xiwc.vendor_code
            ) sum_ne
            --電気代のみ
           ,(SELECT CASE
                      WHEN iv_tax_div = '1'
                      THEN SUM(xiwc.sales_fee)
                      WHEN iv_tax_div = '2'
                      THEN SUM(xiwc.sales_tax_fee)
                    END                     AS  sales_fee
                   ,xiwc.vendor_code
             FROM   xxcok_info_work_custom  xiwc
             WHERE  xiwc.calc_sort = 5
             AND    xiwc.tax_div   = iv_tax_div
             GROUP BY xiwc.vendor_code
            ) sum_e
    WHERE   xbb.supplier_code                      = pv.segment1
    AND     pv.vendor_id                           = pvsa.vendor_id
    AND     ( pvsa.inactive_date                   > gd_process_date
      OR    pvsa.inactive_date                     IS NULL )
    AND     pvsa.org_id                            = gn_org_id
    AND     pvsa.attribute4                        = '1'
    AND     pvsa.attribute5                        = sub1.contact_code
    AND     xbb.supplier_code                      = sum_t.vendor_code(+)
    AND     xbb.supplier_code                      = sum_ne.vendor_code(+)
    AND     xbb.supplier_code                      = sum_e.vendor_code(+)
    AND     xbb.edi_interface_status               = '0'
    AND     SUBSTR( xbb.supplier_code, -1, 1)      = iv_target_div
    AND     xbb.closing_date                      <= gd_closing_date
    AND     xbb.expect_payment_date               <= gd_schedule_date
    AND     xbb.fb_interface_status                = '0'
    AND     xbb.gl_interface_status                = '0'
    AND     NVL(xbb.payment_amt_tax,0)             = 0
    AND     xbb.amt_fix_status                     = '1'
    AND     pvsa.vendor_id                         = abau.vendor_id
    AND     pvsa.vendor_site_id                    = abau.vendor_site_id
    AND     abau.primary_flag                      = 'Y'
    AND     gd_pay_date                            BETWEEN NVL( abau.start_date, gd_pay_date )
                                                   AND     NVL( abau.end_date, gd_pay_date )
    AND     aba.bank_account_id                    = abau.external_bank_account_id
    AND     abb.bank_branch_id                     = aba.bank_branch_id
    AND     iv_tax_div                             = CASE
                                                       WHEN pvsa.attribute6 = '1' THEN          -- 税込
                                                         '2'
                                                       WHEN pvsa.attribute6 IN ('2', '3') THEN  -- 税抜、非課税
                                                         '1'
                                                     END
    GROUP BY
            xbb.supplier_code
           ,pvsa.attribute1
           ,pvsa.zip
           ,pvsa.address_line1
           ,pvsa.address_line2
           ,pvsa.phone
           ,pvsa.fax
           ,sub1.dept_name
           ,sub1.send_post_code
           ,sub1.send_address1
           ,sub1.send_tel
           ,xbb.supplier_code
           ,pvsa.bank_charge_bearer
           ,abb.bank_number
           ,abb.bank_name
           ,abb.bank_num
           ,abb.bank_branch_name
           ,aba.account_holder_name_alt
           ,sum_ne.sales_fee
           ,sum_e.sales_fee
           ,sum_t.tax_amt
           ,sum_t.sales_amt
           ,sum_t.sales_tax_amt
           ,sum_t.sales_qty
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
    -- *** 存在チェックエラー ***
    WHEN check_file_expt THEN
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
  END ins_work_header;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_custom
   * Description      : ワークカスタム明細情報作成(A-4)
   ***********************************************************************************/
  PROCEDURE ins_work_custom(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_work_custom';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
-- Ver1.2 N.Abe ADD START
    -- ===============================================
    -- ローカルカーソル
    -- ===============================================
    -- 定額のみデータ取得
    CURSOR l_fixed_amt_cur
    IS
      SELECT xiwc.rowid       AS  row_id
            ,xiwc.vendor_code AS  vendor_code
            ,xiwc.cust_code   AS  cust_code
      FROM   xxcok_info_work_custom xiwc
      WHERE  xiwc.calc_type  = '40'                 -- 40:定額
      AND    xiwc.tax_div    = iv_tax_div
      AND    xiwc.target_div = iv_target_div
      AND NOT EXISTS (SELECT 'X'
                      FROM   xxcok_info_work_custom xiwc2
                      WHERE  xiwc2.vendor_code = xiwc.vendor_code
                      AND    xiwc2.cust_code = xiwc.cust_code
                      AND    xiwc2.calc_type IN ('10','20','30')
                     )
   ;
--
    -- 電気代のみデータ取得
    CURSOR l_electric_cur
    IS
      SELECT xiwc.rowid       AS  row_id
            ,xiwc.vendor_code AS  vendor_code
            ,xiwc.cust_code   AS  cust_code
      FROM   xxcok_info_work_custom xiwc
      WHERE  xiwc.calc_type  = '50'                 -- 50:電気代
      AND    xiwc.tax_div    = iv_tax_div
      AND    xiwc.target_div = iv_target_div
      AND NOT EXISTS (SELECT 'X'
                      FROM   xxcok_info_work_custom xiwc2
                      WHERE  xiwc2.vendor_code = xiwc.vendor_code
                      AND    xiwc2.cust_code = xiwc.cust_code
                      AND    xiwc2.calc_type IN ('10','20','30','40')
                     )
   ;

-- Ver1.2 N.Abe ADD END
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 存在チェックエラー ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- カスタム明細情報登録
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_type                   -- 計算条件
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,contract                    -- ご契約内容
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,bottle_code                 -- 容器区分コード
     ,salling_price               -- 売価金額
     ,rebate_rate                 -- 割戻率
     ,rebate_amt                  -- 割戻額
     ,tax_code                    -- 税コード
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT  /*+ 
                LEADING(xbb pv pvsa)
                INDEX(xbb xxcok_backmargin_balance_n05)
                USE_NL(pv) USE_NL(pvsa) USE_NL(xbb) USE_NL(sub1) USE_NL(flv1) USE_NL(flv2)
                */
            xbb.supplier_code                       AS  vendor_code             -- 送付先コード
           ,xcbs.delivery_cust_code                 AS  cust_code               -- 顧客コード
-- Ver1.1 N.Abe MOD START
--           ,SUBSTR( sub1.cust_name, 1, 18 )         AS  inst_dest               -- 設置場所
           ,SUBSTR( sub1.cust_name, 1, 50 )         AS  inst_dest               -- 設置場所
-- Ver1.1 N.Abe MOD END
           ,xcbs.calc_type                          AS  calc_type               -- 計算条件
           ,flv2.calc_type_sort                     AS  calc_sort               -- 計算条件ソート順
           ,CASE xcbs.calc_type
              WHEN '10'
              THEN TO_CHAR( xcbs.selling_price )
              WHEN '20'
              THEN SUBSTR( flv1.container_type_name, 1, 10 )
              ELSE flv2.disp
            END                                     AS  sell_bottle             -- 売価／容器
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.delivery_qty )
            END                                     AS  sales_qty               -- 販売本数
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.selling_amt_tax )
            END                                     AS  sales_tax_amt           -- 販売金額（税込）
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN NULL
              ELSE SUM( xcbs.selling_amt_no_tax )
            END                                     AS  sales_amt               -- 販売金額（税抜）
           ,CASE 
              WHEN ( xcbs.rebate_rate IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
              THEN xcbs.rebate_rate || '%'
              WHEN ( xcbs.rebate_amt IS NOT NULL ) AND ( xcbs.calc_type IN ( '10', '20', '30' ) )
              THEN xcbs.rebate_amt || '円'
            END                                     AS  contract                -- ご契約内容
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_amt_no_tax )
              ELSE SUM( xcbs.cond_bm_amt_no_tax )
            END                                     AS  sales_fee               -- 販売手数料（税抜）
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_tax_amt )
              ELSE SUM( xcbs.cond_tax_amt )
            END                                     AS  tax_amt                 -- 消費税
           ,CASE xcbs.calc_type
              WHEN '50'
              THEN SUM( xcbs.electric_amt_tax )
              ELSE SUM( xcbs.cond_bm_amt_tax )
            END                                     AS  sales_tax_fee           -- 販売手数料（税込）
           ,flv1.container_type_code                AS  bottle_code             -- 容器区分コード
           ,xcbs.selling_price                      AS  salling_price           -- 売価金額
           ,xcbs.rebate_rate                        AS  rebate_rate             -- 割戻率
           ,xcbs.rebate_amt                         AS  rebate_amt              -- 割戻額
           ,xbb.tax_code                            AS  tax_code                -- 税コード
           ,iv_tax_div                              AS  tax_div                 -- 税区分
           ,SUBSTR( xbb.supplier_code, -1, 1 )      AS  target_div              -- 対象区分
           ,cn_created_by                           AS  created_by              -- 作成者
           ,SYSDATE                                 AS  creation_date           -- 作成日
           ,cn_last_updated_by                      AS  last_updated_by         -- 最終更新者
           ,SYSDATE                                 AS  last_update_date        -- 最終更新日
           ,cn_last_update_login                    AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                           AS  request_id              -- 要求ID
           ,cn_program_application_id               AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                           AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                                 AS  program_update_date     -- プログラム更新日
    FROM    xxcok_cond_bm_support     xcbs  --条件別販手販協テーブル
           ,xxcok_backmargin_balance  xbb   --販手残高テーブル
           ,po_vendors                pv    --仕入先
           ,po_vendor_sites_all       pvsa  --仕入先サイト
           ,(SELECT hca.account_number  AS  cust_code
                   ,hp.party_name       AS  cust_name
             FROM   hz_cust_accounts    hca
                   ,hz_parties          hp
                   ,xxcmm_cust_accounts xca
             WHERE  hca.party_id = hp.party_id
             AND    xca.customer_id = hca.cust_account_id
            )                         sub1  -- 顧客情報
           ,(SELECT flv.attribute1 AS container_type_code
                   ,flv.meaning    AS container_type_name
             FROM fnd_lookup_values flv
             WHERE flv.lookup_type = 'XXCSO1_SP_RULE_BOTTLE'
             AND flv.language      = USERENV( 'LANG' )
            )                         flv1
           ,(SELECT flv.lookup_code AS calc_type
                   ,flv.meaning     AS line_name
                   ,flv.attribute2  AS calc_type_sort
                   ,flv.attribute3  AS disp
             FROM fnd_lookup_values flv
             WHERE flv.lookup_type = 'XXCOK1_BM_CALC_TYPE'
             AND flv.language      = USERENV( 'LANG' )
            ) flv2
    WHERE   xcbs.base_code                         = xbb.base_code
    AND     xcbs.delivery_cust_code                = xbb.cust_code
    AND     xcbs.supplier_code                     = xbb.supplier_code
    AND     xcbs.closing_date                      = xbb.closing_date
    AND     xcbs.expect_payment_date               = xbb.expect_payment_date
    AND     xbb.supplier_code                      = pv.segment1
    AND     pv.vendor_id                           = pvsa.vendor_id
    AND     ( pvsa.inactive_date                   > gd_closing_date
        OR    pvsa.inactive_date                   IS NULL )
    AND     pvsa.org_id                            = gn_org_id
    AND     pvsa.attribute4                        = '1' --本振あり
    AND     xcbs.delivery_cust_code                = sub1.cust_code
    AND     xcbs.container_type_code               = flv1.container_type_code(+)
    AND     xcbs.calc_type                         = flv2.calc_type
    AND     NVL( xbb.resv_flag, 'N' )             != 'Y'
    AND     xbb.edi_interface_status               = '0'
    AND     SUBSTR( xbb.supplier_code, -1, 1)      = iv_target_div
    AND     xbb.closing_date                      <= gd_closing_date
    AND     xbb.expect_payment_date               <= gd_schedule_date
    AND     xbb.fb_interface_status                = '0'
    AND     xbb.gl_interface_status                = '0'
    AND     NVL(xbb.payment_amt_tax,0)             = 0
    AND     xbb.amt_fix_status                     = '1'
    AND     iv_tax_div                             = CASE
                                                       WHEN pvsa.attribute6 = '1' THEN          -- 税込
                                                         '2'
                                                       WHEN pvsa.attribute6 IN ('2', '3') THEN  -- 税抜、非課税
                                                         '1'
                                                     END
    GROUP BY
            xbb.supplier_code
           ,xcbs.delivery_cust_code
           ,sub1.cust_name
           ,xcbs.calc_type
           ,flv2.calc_type_sort
           ,flv1.container_type_code
           ,flv1.container_type_name
           ,xcbs.selling_price
           ,xcbs.rebate_rate
           ,xcbs.rebate_amt
           ,xbb.tax_code
           ,flv2.disp
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- カスタム明細情報登録(小計行)
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT  xiwc.vendor_code                AS  vendor_code             -- 送付先コード
           ,xiwc.cust_code                  AS  cust_code               -- 顧客コード
           ,xiwc.inst_dest                  AS  inst_dest               -- 設置場所
           ,2.5                             AS  calc_sort               -- 計算条件ソート順
           ,'小計'                          AS  sell_bottle             -- 売価／容器
           ,SUM(NVL(xiwc.sales_qty,0))      AS  sales_qty               -- 販売本数
           ,SUM(NVL(xiwc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
           ,SUM(NVL(xiwc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
           ,SUM(NVL(xiwc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
           ,SUM(NVL(xiwc.tax_amt,0))        AS  tax_amt                 -- 消費税
           ,SUM(NVL(xiwc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
           ,xiwc.tax_div                    AS  tax_div                 -- 税区分
           ,xiwc.target_div                 AS  target_div              -- 対象区分
           ,cn_created_by                   AS  created_by              -- 作成者
           ,SYSDATE                         AS  creation_date           -- 作成日
           ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
           ,SYSDATE                         AS  last_update_date        -- 最終更新日
           ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                   AS  request_id              -- 要求ID
           ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                         AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_work_custom  xiwc
    WHERE   xiwc.calc_type  IN  ('10','20')
    AND     xiwc.tax_div    = iv_tax_div
    AND     xiwc.target_div = iv_target_div
    AND     xiwc.request_id = cn_request_id
    GROUP BY
            xiwc.vendor_code
           ,xiwc.cust_code
           ,xiwc.inst_dest
           ,xiwc.tax_div
           ,xiwc.target_div
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
-- Ver1.2 N.Abe ADD START
    -- ===============================================
    -- カスタム明細情報登録（一律条件明細行）
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_type                   -- 計算条件
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,contract                    -- ご契約内容
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,bottle_code                 -- 容器区分コード
     ,salling_price               -- 売価金額
     ,rebate_rate                 -- 割戻率
     ,rebate_amt                  -- 割戻額
     ,tax_code                    -- 税コード
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT  /*+ 
                LEADING(xbb_1 xseh xsel flv)
                USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                */
            xbb_1.supplier_code                 AS vendor_code            -- 01.送付先コード
           ,xseh.ship_to_customer_code          AS cust_code              -- 02.顧客コード
           ,SUBSTR( hp.party_name, 1, 50)       AS inst_dest              -- 03.設置場所
           ,NULL                                AS calc_type              -- 04.計算条件
           ,'2.7'                               AS calc_sort              -- 05.計算条件ソート順
           ,xsel.dlv_unit_price                 AS sell_bottle            -- 06.売価／容器
           ,SUM( xsel.dlv_qty)                  AS sales_qty              -- 07.販売本数
           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                AS sales_tax_amt          -- 08.販売金額（税込）
           ,SUM( xsel.pure_amount )             AS sales_amt              -- 09.販売金額（税抜）
           ,NULL                                AS contract               -- 10.ご契約内容
           ,NULL                                AS sales_fee              -- 11.販売手数料（税抜）
           ,NULL                                AS tax_amt                -- 12.消費税
           ,NULL                                AS sales_tax_fee          -- 13.販売手数料（税込）
           ,NULL                                AS bottle_code            -- 14.容器区分コード
           ,NULL                                AS salling_price          -- 15.売価金額
           ,NULL                                AS rebate_rate            -- 16.割戻率
           ,NULL                                AS rebate_amt             -- 17.割戻額
           ,NULL                                AS tax_code               -- 18.税コード
           ,iv_tax_div                          AS tax_div                -- 19.税区分
           ,SUBSTR( xbb_1.supplier_code, -1, 1) AS target_div             -- 20.対象区分
           ,cn_created_by                       AS created_by             -- 21.作成者
           ,SYSDATE                             AS creation_date          -- 22.作成日
           ,cn_last_updated_by                  AS last_updated_by        -- 23.最終更新者
           ,SYSDATE                             AS last_update_date       -- 24.最終更新日
           ,cn_last_update_login                AS last_update_login      -- 25.最終更新ログイン
           ,cn_request_id                       AS request_id             -- 26.要求id
           ,cn_program_application_id           AS program_application_id -- 27.コンカレント・プログラム・アプリケーションid
           ,cn_program_id                       AS program_id             -- 28.コンカレント・プログラムid
           ,SYSDATE                             AS program_update_date    -- 29.プログラム更新日
    FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
           ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
           ,hz_cust_accounts          hca   -- 顧客マスタ
           ,hz_parties                hp    -- パーティー
           ,fnd_lookup_values         flv   -- 販手計算対象売上区分
           ,(
             SELECT  /*+ 
                        LEADING(xbb pv pvsa xcbs)
                        INDEX(xbb xxcok_backmargin_balance_n05)
                        USE_NL(pv) USE_NL(pvsa) use_nl(xcbs)
                      */
                     xbb.supplier_code
                    ,xbb.cust_code
                    ,xbb.closing_date
             FROM    xxcok_backmargin_balance  xbb       --販手残高テーブル
                    ,xxcok_cond_bm_support     xcbs  --条件別販手販協テーブル
                    ,po_vendors                pv    --仕入先
                    ,po_vendor_sites_all       pvsa  --仕入先サイト
             WHERE   xcbs.base_code                    =  xbb.base_code
             AND     xcbs.delivery_cust_code           =  xbb.cust_code
             AND     xcbs.supplier_code                =  xbb.supplier_code
             AND     xcbs.closing_date                 =  xbb.closing_date
             AND     xcbs.expect_payment_date          =  xbb.expect_payment_date
             AND     xcbs.calc_type                    =  '30'                 -- 30:一律条件
             AND     xbb.supplier_code                 =  pv.segment1
             AND     pv.vendor_id                      =  pvsa.vendor_id
             AND     ( pvsa.inactive_date              >  gd_closing_date     --締め日
                 OR    pvsa.inactive_date              IS NULL )
             AND     pvsa.org_id                       =  gn_org_id
             AND     pvsa.attribute4                   =  '1' --本振あり
             AND     NVL( xbb.resv_flag, 'N' )         != 'Y'
             AND     SUBSTR( xbb.supplier_code, -1, 1) =  iv_target_div
             AND     xbb.closing_date                  <= gd_closing_date    --締め日
             AND     xbb.expect_payment_date           <= gd_schedule_date   --支払予定日
             AND     xbb.edi_interface_status          =  '0'
             AND     xbb.fb_interface_status           =  '0'
             AND     xbb.gl_interface_status           =  '0'
             AND     NVL(xbb.payment_amt_tax,0)        =   0
             AND     xbb.amt_fix_status                =  '1'
             AND     iv_tax_div = CASE
                                    WHEN pvsa.attribute6 = '1'         THEN '2' -- 税込 ⇒ 内税
                                    WHEN pvsa.attribute6 IN ('2', '3') THEN '1' -- 税抜、非課税 ⇒ 外税
                                    END
             GROUP BY xbb.supplier_code, xbb.cust_code, xbb.closing_date
             ) xbb_1
    WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
    AND     hca.account_number          =  xseh.ship_to_customer_code
    AND     hca.party_id                =  hp.party_id
    AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
    AND     xseh.ship_to_customer_code  =  xbb_1.cust_code
    AND     xseh.delivery_date          >= LAST_DAY(ADD_MONTHS(xbb_1.closing_date, -1)) + 1 --月初日
    AND     xseh.delivery_date          <= xbb_1.closing_date                               --月末日
    AND     flv.lookup_code             =  xsel.sales_class
    AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
    AND     flv.language                =  USERENV( 'LANG' )
    AND     flv.enabled_flag            =  'Y'
    AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                              AND NVL( flv.end_date_active  , gd_process_date )
    AND NOT EXISTS ( SELECT 'X'
                     FROM fnd_lookup_values flv -- 非在庫品目
                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                       AND flv.lookup_code         = xsel.item_code
                       AND flv.language            = USERENV( 'LANG' )
                       AND flv.enabled_flag        = 'Y'
                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND NVL( flv.end_date_active  , gd_process_date )
        )
    GROUP BY
            xseh.ship_to_customer_code
           ,SUBSTR( hp.party_name, 1, 50)
           ,xbb_1.supplier_code
           ,SUBSTR( xbb_1.supplier_code, -1, 1)
           ,xsel.dlv_unit_price
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- カスタム明細情報登録(一律条件小計行)
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT  xiwc.vendor_code                AS  vendor_code             -- 送付先コード
           ,xiwc.cust_code                  AS  cust_code               -- 顧客コード
           ,xiwc.inst_dest                  AS  inst_dest               -- 設置場所
           ,3.5                             AS  calc_sort               -- 計算条件ソート順
           ,'小計'                          AS  sell_bottle             -- 売価／容器
           ,SUM(NVL(xiwc.sales_qty,0))      AS  sales_qty               -- 販売本数
           ,SUM(NVL(xiwc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
           ,SUM(NVL(xiwc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
           ,SUM(NVL(xiwc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
           ,SUM(NVL(xiwc.tax_amt,0))        AS  tax_amt                 -- 消費税
           ,SUM(NVL(xiwc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
           ,xiwc.tax_div                    AS  tax_div                 -- 税区分
           ,xiwc.target_div                 AS  target_div              -- 対象区分
           ,cn_created_by                   AS  created_by              -- 作成者
           ,SYSDATE                         AS  creation_date           -- 作成日
           ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
           ,SYSDATE                         AS  last_update_date        -- 最終更新日
           ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                   AS  request_id              -- 要求ID
           ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                         AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_work_custom  xiwc
    WHERE   xiwc.calc_type  = '30'
    AND     xiwc.tax_div    = iv_tax_div
    AND     xiwc.target_div = iv_target_div
    AND     xiwc.request_id = cn_request_id
    GROUP BY
            xiwc.vendor_code
           ,xiwc.cust_code
           ,xiwc.inst_dest
           ,xiwc.tax_div
           ,xiwc.target_div
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- 定額のみデータ取得
    -- ===============================================
    <<fixed_amt_loop>>
    FOR l_fixed_amt_rec IN l_fixed_amt_cur LOOP
      -- ===============================================
      -- 定額のみデータ更新
      -- ===============================================
      UPDATE xxcok_info_work_custom xiwc
      SET    ( sales_qty
--              ,sales_tax_amt
              ,sales_amt
             ) = (SELECT  /*+ 
                              LEADING(xbb pv pvsa xcbs xseh xsel flv)
                              INDEX(xbb XXCOK_BACKMARGIN_BALANCE_N06 )
                              USE_NL(pv) USE_NL(pvsa)
                              USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                          */
                          SUM( xsel.dlv_qty)                                AS sales_qty              -- 販売本数
--                         ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- 販売金額（税込）
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- 販売金額（税抜）
                  FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
                         ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
                         ,hz_cust_accounts          hca   -- 顧客マスタ
                         ,hz_parties                hp    -- パーティー
                         ,fnd_lookup_values         flv   -- 販手計算対象売上区分
                         ,xxcok_backmargin_balance  xbb   -- 販手残高テーブル
                         ,xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
                         ,po_vendors                pv    -- 仕入先
                         ,po_vendor_sites_all       pvsa  -- 仕入先サイト
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     hca.account_number          =  xseh.ship_to_customer_code
                  AND     hca.party_id                =  hp.party_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
                  AND     flv.lookup_code             =  xsel.sales_class
                  AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                  AND     flv.language                =  USERENV( 'LANG' )
                  AND     flv.enabled_flag            =  'Y'
                  AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                  AND NOT EXISTS ( SELECT 'X'
                                   FROM fnd_lookup_values flv -- 非在庫品目
                                   WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                                     AND flv.lookup_code         = xsel.item_code
                                     AND flv.language            = USERENV( 'LANG' )
                                     AND flv.enabled_flag        = 'Y'
                                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                               AND NVL( flv.end_date_active  , gd_process_date )
                      )
                  AND     xseh.ship_to_customer_code        =  xbb.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbb.closing_date, -1)) + 1 --月初日
                  AND     xseh.delivery_date                <= xbb.closing_date                     --月末日
                  AND     xcbs.base_code                    =  xbb.base_code
                  AND     xcbs.delivery_cust_code           =  xbb.cust_code
                  AND     xcbs.supplier_code                =  xbb.supplier_code
                  AND     xcbs.closing_date                 =  xbb.closing_date
                  AND     xcbs.expect_payment_date          =  xbb.expect_payment_date
                  AND     xcbs.calc_type                    =  '40'                 -- 40:定額
                  AND     xbb.supplier_code                 =  pv.segment1
                  AND     pv.vendor_id                      =  pvsa.vendor_id
                  AND     ( pvsa.inactive_date              >  gd_closing_date     --締め日
                      OR    pvsa.inactive_date              IS NULL )
                  AND     pvsa.org_id                       =  gn_org_id
                  AND     pvsa.attribute4                   =  '1' --本振あり
                  AND     NVL( xbb.resv_flag, 'N' )         != 'Y'
                  AND     SUBSTR( xbb.supplier_code, -1, 1) =  iv_target_div
                  AND     xbb.closing_date                  <=  gd_closing_date    --締め日
                  AND     xbb.expect_payment_date           <=  gd_schedule_date   --支払予定日
                  AND     xbb.edi_interface_status          =  '0'
                  AND     xbb.fb_interface_status           =  '0'
                  AND     xbb.gl_interface_status           =  '0'
                  AND     NVL(xbb.payment_amt_tax,0)        =  0
                  AND     xbb.amt_fix_status                =  '1'
                  AND     iv_tax_div                        =  CASE
                                                                 WHEN pvsa.attribute6 = '1'         THEN '2' -- 税込 ⇒ 内税
                                                                 WHEN pvsa.attribute6 IN ('2', '3') THEN '1' -- 税抜、非課税 ⇒ 外税
                                                               END
                  AND     xbb.supplier_code                 = l_fixed_amt_rec.vendor_code
                  AND     xbb.cust_code                     = l_fixed_amt_rec.cust_code
                  GROUP BY
                          xseh.ship_to_customer_code
                         ,SUBSTR( hp.party_name, 1, 50)
                         ,xbb.supplier_code
                         ,SUBSTR( xbb.supplier_code, -1, 1)
              )
      WHERE xiwc.rowid       = l_fixed_amt_rec.row_id
      ;
--
    END LOOP fixed_amt_loop;
--
    -- ===============================================
    -- 電気代のみデータ取得
    -- ===============================================
    <<elctric_loop>>
    FOR l_electric_rec IN l_electric_cur LOOP
      -- ===============================================
      -- 電気代データ更新
      -- ===============================================
      UPDATE xxcok_info_work_custom xiwc
      SET    ( sales_qty
              ,sales_tax_amt
              ,sales_amt
             ) = (SELECT  /*+ 
                              LEADING(xbb pv pvsa xcbs xseh xsel flv)
                              INDEX(xbb XXCOK_BACKMARGIN_BALANCE_N06 )
                              USE_NL(pv) USE_NL(pvsa)
                              USE_NL(xseh) USE_NL(xsel) USE_NL(flv)
                          */
                          SUM( xsel.dlv_qty)                                AS sales_qty              -- 販売本数
                         ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )  AS sales_tax_amt          -- 販売金額（税込）
                         ,SUM( xsel.pure_amount )                           AS sales_amt              -- 販売金額（税抜）
                  FROM    xxcos_sales_exp_headers   xseh  -- 販売実績ヘッダー
                         ,xxcos_sales_exp_lines     xsel  -- 販売実績明細
                         ,hz_cust_accounts          hca   -- 顧客マスタ
                         ,hz_parties                hp    -- パーティー
                         ,fnd_lookup_values         flv   -- 販手計算対象売上区分
                         ,xxcok_backmargin_balance  xbb   -- 販手残高テーブル
                         ,xxcok_cond_bm_support     xcbs  -- 条件別販手販協テーブル
                         ,po_vendors                pv    -- 仕入先
                         ,po_vendor_sites_all       pvsa  -- 仕入先サイト
                  WHERE   xseh.sales_exp_header_id    =  xsel.sales_exp_header_id
                  AND     hca.account_number          =  xseh.ship_to_customer_code
                  AND     hca.party_id                =  hp.party_id
                  AND     xsel.item_code              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
                  AND     flv.lookup_code             =  xsel.sales_class
                  AND     flv.lookup_type             =  'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                  AND     flv.language                =  USERENV( 'LANG' )
                  AND     flv.enabled_flag            =  'Y'
                  AND     gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                AND NVL( flv.end_date_active  , gd_process_date )
                  AND NOT EXISTS ( SELECT 'X'
                                   FROM fnd_lookup_values flv -- 非在庫品目
                                   WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                                     AND flv.lookup_code         = xsel.item_code
                                     AND flv.language            = USERENV( 'LANG' )
                                     AND flv.enabled_flag        = 'Y'
                                     AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                               AND NVL( flv.end_date_active  , gd_process_date )
                      )
                  AND     xseh.ship_to_customer_code        =  xbb.cust_code
                  AND     xseh.delivery_date                >= LAST_DAY(ADD_MONTHS(xbb.closing_date, -1)) + 1 --月初日
                  AND     xseh.delivery_date                <= xbb.closing_date                     --月末日
                  AND     xcbs.base_code                    =  xbb.base_code
                  AND     xcbs.delivery_cust_code           =  xbb.cust_code
                  AND     xcbs.supplier_code                =  xbb.supplier_code
                  AND     xcbs.closing_date                 =  xbb.closing_date
                  AND     xcbs.expect_payment_date          =  xbb.expect_payment_date
                  AND     xcbs.calc_type                    =  '50'                 -- 50:電気代
                  AND     xbb.supplier_code                 =  pv.segment1
                  AND     pv.vendor_id                      =  pvsa.vendor_id
                  AND     ( pvsa.inactive_date              >  gd_closing_date     --締め日
                      OR    pvsa.inactive_date              IS NULL )
                  AND     pvsa.org_id                       =  gn_org_id
                  AND     pvsa.attribute4                   =  '1' --本振あり
                  AND     NVL( xbb.resv_flag, 'N' )         != 'Y'
                  AND     SUBSTR( xbb.supplier_code, -1, 1) =  iv_target_div
                  AND     xbb.closing_date                  <=  gd_closing_date    --締め日
                  AND     xbb.expect_payment_date           <=  gd_schedule_date   --支払予定日
                  AND     xbb.edi_interface_status          =  '0'
                  AND     xbb.fb_interface_status           =  '0'
                  AND     xbb.gl_interface_status           =  '0'
                  AND     NVL(xbb.payment_amt_tax,0)        =  0
                  AND     xbb.amt_fix_status                =  '1'
                  AND     iv_tax_div                        =  CASE
                                                                 WHEN pvsa.attribute6 = '1'         THEN '2' -- 税込 ⇒ 内税
                                                                 WHEN pvsa.attribute6 IN ('2', '3') THEN '1' -- 税抜、非課税 ⇒ 外税
                                                               END
                  AND     xbb.supplier_code                 = l_electric_rec.vendor_code
                  AND     xbb.cust_code                     = l_electric_rec.cust_code
                  GROUP BY
                          xseh.ship_to_customer_code
                         ,SUBSTR( hp.party_name, 1, 50)
                         ,xbb.supplier_code
                         ,SUBSTR( xbb.supplier_code, -1, 1)
              )
      WHERE xiwc.rowid       = l_electric_rec.row_id
      ;
--
    END LOOP elctric_loop;
-- Ver1.2 N.Abe ADD END
    -- ===============================================
    -- カスタム明細情報登録(合計行)
    -- ===============================================
    INSERT INTO xxcok_info_work_custom(
      vendor_code                 -- 送付先コード
     ,cust_code                   -- 顧客コード
     ,inst_dest                   -- 設置場所
     ,calc_sort                   -- 計算条件ソート順
     ,sell_bottle                 -- 売価／容器
     ,sales_qty                   -- 販売本数
     ,sales_tax_amt               -- 販売金額（税込）
     ,sales_amt                   -- 販売金額（税抜）
     ,sales_fee                   -- 販売手数料（税抜）
     ,tax_amt                     -- 消費税
     ,sales_tax_fee               -- 販売手数料（税込）
     ,tax_div                     -- 税区分
     ,target_div                  -- 対象区分
     ,created_by                  -- 作成者
     ,creation_date               -- 作成日
     ,last_updated_by             -- 最終更新者
     ,last_update_date            -- 最終更新日
     ,last_update_login           -- 最終更新ログイン
     ,request_id                  -- 要求ID
     ,program_application_id      -- コンカレント・プログラム・アプリケーションID
     ,program_id                  -- コンカレント・プログラムID
     ,program_update_date         -- プログラム更新日
    )
    SELECT  xiwc.vendor_code                AS  vendor_code             -- 送付先コード
           ,xiwc.cust_code                  AS  cust_code               -- 顧客コード
           ,xiwc.inst_dest                  AS  inst_dest               -- 設置場所
           ,6                               AS  calc_sort               -- 計算条件ソート順
           ,'合計'                          AS  sell_bottle             -- 売価／容器
           ,SUM(NVL(xiwc.sales_qty,0))      AS  sales_qty               -- 販売本数
           ,SUM(NVL(xiwc.sales_tax_amt,0))  AS  sales_tax_amt           -- 販売金額（税込）
           ,SUM(NVL(xiwc.sales_amt,0))      AS  sales_amt               -- 販売金額（税抜）
           ,SUM(NVL(xiwc.sales_fee,0))      AS  sales_fee               -- 販売手数料（税抜）
           ,SUM(NVL(xiwc.tax_amt,0))        AS  tax_amt                 -- 消費税
           ,SUM(NVL(xiwc.sales_tax_fee,0))  AS  sales_tax_fee           -- 販売手数料（税込）
           ,xiwc.tax_div                    AS  tax_div                 -- 税区分
           ,xiwc.target_div                 AS  target_div              -- 対象区分
           ,cn_created_by                   AS  created_by              -- 作成者
           ,SYSDATE                         AS  creation_date           -- 作成日
           ,cn_last_updated_by              AS  last_updated_by         -- 最終更新者
           ,SYSDATE                         AS  last_update_date        -- 最終更新日
           ,cn_last_update_login            AS  last_update_login       -- 最終更新ログイン
           ,cn_request_id                   AS  request_id              -- 要求ID
           ,cn_program_application_id       AS  program_application_id  -- コンカレント・プログラム・ア
           ,cn_program_id                   AS  program_id              -- コンカレント・プログラムID
           ,SYSDATE                         AS  program_update_date     -- プログラム更新日
    FROM    xxcok_info_work_custom  xiwc
-- Ver1.2 N.Abe MOD START
--    WHERE   xiwc.calc_sort  <> 2.5
    WHERE   xiwc.calc_sort  NOT IN ( '2.5', '2.7', '3.5' )
-- Ver1.2 N.Abe MOD END
    AND     xiwc.tax_div    = iv_tax_div
    AND     xiwc.target_div = iv_target_div
    AND     xiwc.request_id = cn_request_id
    GROUP BY
            xiwc.vendor_code
           ,xiwc.cust_code
           ,xiwc.inst_dest
           ,xiwc.tax_div
           ,xiwc.target_div
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
    -- *** 存在チェックエラー ***
    WHEN check_file_expt THEN
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
  END ins_work_custom;
--
  /**********************************************************************************
   * Procedure Name   : ins_work_line
   * Description      : ワーク明細情報作成(A-3)
   ***********************************************************************************/
  PROCEDURE ins_work_line(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'ins_work_line';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 存在チェックエラー ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- 明細情報登録
    -- ===============================================
    INSERT INTO xxcok_info_work_line(
      order_num                   --  1.順序
     ,line_item                   --  2.明細項目
     ,unit_price                  --  3.単価
     ,qty                         --  4.数量
     ,unit_type                   --  5.単位
     ,amt                         --  6.金額
     ,tax_amt                     --  7.消費税額
     ,total_amt                   --  8.合計金額
     ,inst_dest                   --  9.設置先名
     ,cust_code                   -- 10.顧客コード
     ,item_code                   -- 11.品目コード
     ,vendor_code                 -- 12.送付先コード
     ,tax_div                     -- 13.税区分（パラメータ）
     ,target_div                  -- 14.対象区分
     ,created_by                  -- 15.作成者
     ,creation_date               -- 16.作成日
     ,last_updated_by             -- 17.最終更新者
     ,last_update_date            -- 18.最終更新日
     ,last_update_login           -- 19.最終更新ログイン
     ,request_id                  -- 20.要求ID
     ,program_application_id      -- 21.コンカレント・プログラム・アプリケーションID
     ,program_id                  -- 22.コンカレント・プログラムID
     ,program_update_date         -- 23.プログラム更新日
    )
    SELECT  /*+ 
                LEADING(xbb_1)
                USE_NL(xseh) USE_NL(xsel) USE_NL(iimb) USE_NL(ximb) USE_NL(hca) USE_NL(hp)
                */
            '1'                                 AS  order_num               --  1.順序
           ,ximb.item_short_name                AS  line_item               --  2.明細項目
           ,xsel.dlv_unit_price                 AS  unit_price              --  3.単価
           ,SUM( xsel.dlv_qty)                  AS  qty                     --  4.数量
           ,xsel.dlv_uom_code                   AS  unit_type               --  5.単位
           ,SUM( xsel.pure_amount )             AS  amt                     --  6.金額
           ,SUM( xsel.tax_amount )              AS  tax_amt                 --  7.消費税額
-- Ver1.2 N.Abe MOD START
--           ,SUM( xsel.sale_amount )             AS  total_amt               --  8.合計金額
           ,SUM( xsel.pure_amount ) + SUM( xsel.tax_amount )
                                                AS  total_amt               --  8.合計金額
-- Ver1.2 N.Abe MOD END
           ,SUBSTR( hp.party_name, 1, 50)       AS  inst_dest               --  9.設置先名
           ,xseh.ship_to_customer_code          AS  cust_code               -- 10.顧客コード
           ,xsel.item_code                      AS  item_code               -- 11.品目コード
           ,xbb_1.supplier_code                 AS  vendor_code             -- 12.送付先コード
           ,iv_tax_div                          AS  tax_div                 -- 13.税区分（パラメータ）
           ,SUBSTR( xbb_1.supplier_code, -1, 1) AS  target_div              -- 14.対象区分
           ,cn_created_by                       AS  created_by              -- 15.作成者
           ,SYSDATE                             AS  creation_date           -- 16.作成日
           ,cn_last_updated_by                  AS  last_updated_by         -- 17.最終更新者
           ,SYSDATE                             AS  last_update_date        -- 18.最終更新日
           ,cn_last_update_login                AS  last_update_login       -- 19.最終更新ログイン
           ,cn_request_id                       AS  request_id              -- 20.要求ID
           ,cn_program_application_id           AS  program_application_id  -- 21.コンカレント・プログラム・アプリケーションID
           ,cn_program_id                       AS  program_id              -- 22.コンカレント・プログラムID
           ,SYSDATE                             AS  program_update_date     -- 23.プログラム更新日
    FROM    xxcos_sales_exp_headers   xseh      --販売実績ヘッダー
           ,xxcos_sales_exp_lines     xsel      --販売実績明細
           ,xxcmn_item_mst_b          ximb      --OPM品目アドオン
           ,ic_item_mst_b             iimb      --OPM品目
           ,hz_cust_accounts          hca       --顧客マスタ
           ,hz_parties                hp        --パーティー
           ,(
             SELECT  /*+ 
                         LEADING(xbb pv pvsa)
                         INDEX(xbb xxcok_backmargin_balance_n05)
                         USE_NL(pv) USE_NL(pvsa) 
                      */
                     xbb.supplier_code
                    ,xbb.cust_code
             FROM    xxcok_backmargin_balance  xbb       --販手残高テーブル
                    ,po_vendors                pv        --仕入先マスタ
                    ,po_vendor_sites_all       pvsa      --仕入先サイト
             WHERE   1=1
             AND     xbb.edi_interface_status                     = '0'
             AND     SUBSTR( xbb.supplier_code, -1, 1)            = iv_target_div
             AND     xbb.closing_date                            <= gd_closing_date    --締め日
             AND     xbb.expect_payment_date                     <= gd_schedule_date   --支払予定日
             AND     xbb.fb_interface_status                      = '0'
             AND     xbb.gl_interface_status                      = '0'
             AND     NVL(xbb.payment_amt_tax,0)                   = 0
             AND     xbb.amt_fix_status                           = '1'
             AND     xbb.supplier_code                            = pv.segment1
             AND     pv.vendor_id                                 = pvsa.vendor_id
             AND     ( pvsa.inactive_date                         > gd_process_date
               OR    pvsa.inactive_date                          IS NULL )
             AND     pvsa.org_id                                  = gn_org_id
             AND     pvsa.attribute4                              = '1'
             AND     iv_tax_div                                   = CASE
                                                                      WHEN pvsa.attribute6 = '1' THEN          -- 税込
                                                                        '2'
                                                                      WHEN pvsa.attribute6 IN ('2', '3') THEN  -- 税抜、非課税
                                                                        '1'
                                                                    END
             GROUP BY xbb.supplier_code, xbb.cust_code
             ) xbb_1
    WHERE   xseh.sales_exp_header_id                     = xsel.sales_exp_header_id
    AND     xsel.item_code                              <> gv_elec_change_item_code       -- 電気料（変動）品目コード を除く
    AND     iimb.item_no                                 = xsel.item_code
    AND     ximb.item_id                                 = iimb.item_id
    AND     ximb.start_date_active                      <= xseh.delivery_date
    AND     ximb.end_date_active                        >= xseh.delivery_date
    AND     hca.account_number                           = xseh.ship_to_customer_code
    AND     hca.party_id                                 = hp.party_id
    AND     xseh.delivery_date                          >= LAST_DAY(ADD_MONTHS(gd_closing_date, -1)) + 1 --月初日
    AND     xseh.delivery_date                          <= LAST_DAY(gd_closing_date)                     --月末日
    AND     xseh.ship_to_customer_code                   = xbb_1.cust_code
-- Ver1.1 N.Abe ADD START
    AND EXISTS ( SELECT 'X'
                 FROM fnd_lookup_values flv -- 販手計算対象売上区分
                 WHERE flv.lookup_type         = 'XXCOK1_CALC_SALES_CLASS'      -- 参照タイプ：販手計算対象売上区分
                   AND flv.lookup_code         = xsel.sales_class
                   AND flv.language            = USERENV( 'LANG' )
                   AND flv.enabled_flag        = 'Y'
                   AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                             AND NVL( flv.end_date_active  , gd_process_date )
                   AND ROWNUM = 1
        )
    AND NOT EXISTS ( SELECT 'X'
                     FROM fnd_lookup_values flv -- 非在庫品目
                     WHERE flv.lookup_type         = 'XXCOS1_NO_INV_ITEM_CODE'  -- 参照タイプ：非在庫品目
                       AND flv.lookup_code         = xsel.item_code
                       AND flv.language            = USERENV( 'LANG' )
                       AND flv.enabled_flag        = 'Y'
                       AND gd_process_date   BETWEEN NVL( flv.start_date_active, gd_process_date )
                                                 AND NVL( flv.end_date_active  , gd_process_date )
                       AND ROWNUM = 1
        )
-- Ver1.1 N.Abe ADD END
    GROUP BY
            ximb.item_short_name
           ,xsel.dlv_unit_price
           ,xsel.dlv_uom_code
           ,hp.party_name
           ,xseh.ship_to_customer_code
           ,xsel.item_code
           ,xbb_1.supplier_code
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
    -- ===============================================
    -- 明細情報登録(合計行)
    -- ===============================================
    INSERT INTO xxcok_info_work_line(
      order_num                   -- 1.順序
     ,line_item                   -- 2.明細項目
     ,qty                         -- 3.数量
     ,unit_type                   -- 4.単位
     ,amt                         -- 5.金額
     ,tax_amt                     -- 6.消費税額
     ,total_amt                   -- 7.合計金額
     ,inst_dest                   -- 8.設置先名
     ,cust_code                   -- 9.顧客コード
     ,vendor_code                 -- 10.送付先コード
     ,tax_div                     -- 11.税区分（パラメータ）
     ,target_div                  -- 12.対象区分
     ,created_by                  -- 13.作成者
     ,creation_date               -- 14.作成日
     ,last_updated_by             -- 15.最終更新者
     ,last_update_date            -- 16.最終更新日
     ,last_update_login           -- 17.最終更新ログイン
     ,request_id                  -- 18.要求ID
     ,program_application_id      -- 19.コンカレント・プログラム・アプリケーションID
     ,program_id                  -- 20.コンカレント・プログラムID
     ,program_update_date         -- 21.プログラム更新日
    )
    SELECT  '2'                         AS  order_num               -- 1.順序
           ,gv_line_sum                 AS  line_item               -- 2.明細項目
           ,SUM(xiwl.qty)               AS  qty                     -- 3.数量
           ,MAX(xiwl.unit_type)         AS  unit_type               -- 4.単位
           ,SUM(xiwl.amt)               AS  amt                     -- 5.金額
           ,SUM(xiwl.tax_amt)           AS  tax_amt                 -- 6.消費税額
           ,SUM(xiwl.total_amt)         AS  total_amt               -- 7.合計金額
           ,xiwl.inst_dest              AS  inst_dest               -- 8.設置先名
           ,xiwl.cust_code              AS  cust_code               -- 9.顧客コード
           ,xiwl.vendor_code            AS  vendor_code             -- 10.送付先コード
           ,iv_tax_div                  AS  tax_div                 -- 11.税区分(パラメータ)
           ,xiwl.target_div             AS  target_div              -- 12.対象区分
           ,cn_created_by               AS  created_by              -- 13.作成者
           ,SYSDATE                     AS  creation_date           -- 14.作成日
           ,cn_last_updated_by          AS  last_updated_by         -- 15.最終更新者
           ,SYSDATE                     AS  last_update_date        -- 16.最終更新日
           ,cn_last_update_login        AS  last_update_login       -- 17.最終更新ログイン
           ,cn_request_id               AS  request_id              -- 18.要求ID
           ,cn_program_application_id   AS  program_application_id  -- 19.コンカレント・プログラム・アプリケーションID
           ,cn_program_id               AS  program_id              -- 20.コンカレント・プログラムID
           ,SYSDATE                     AS  program_update_date     -- 21.プログラム更新日
    FROM    xxcok_info_work_line      xiwl  --インフォマート用ワーク（明細）
    WHERE   xiwl.tax_div    = iv_tax_div
    AND     xiwl.target_div = iv_target_div
    AND     xiwl.request_id = cn_request_id
    GROUP BY
            xiwl.cust_code
           ,xiwl.inst_dest
           ,xiwl.vendor_code
           ,xiwl.tax_div
           ,xiwl.target_div
    ;
--
    -- 登録件数（成功件数）
    gn_normal_cnt := gn_normal_cnt + SQL%ROWCOUNT;
--
  EXCEPTION
    -- *** 存在チェックエラー ***
    WHEN check_file_expt THEN
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
  END ins_work_line;
--
  /**********************************************************************************
   * Procedure Name   : del_work
   * Description      : ワークテーブルデータ削除(A-2)
   ***********************************************************************************/
  PROCEDURE del_work(
    iv_tax_div    IN  VARCHAR2
   ,iv_target_div IN  VARCHAR2
   ,ov_errbuf     OUT VARCHAR2
   ,ov_retcode    OUT VARCHAR2
   ,ov_errmsg     OUT VARCHAR2
  )
  IS
    -- ===============================================
    -- ローカル定数
    -- ===============================================
    cv_prg_name    CONSTANT VARCHAR2(20) := 'del_work';  -- プログラム名
    -- ===============================================
    -- ローカル変数
    -- ===============================================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;              -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;              -- ユーザー・エラー・メッセージ
    lv_outmsg       VARCHAR2(5000) DEFAULT NULL;              -- 出力用メッセージ
    -- ===============================================
    -- ローカル例外
    -- ===============================================
    --*** 存在チェックエラー ***
    check_file_expt  EXCEPTION;
--
  BEGIN
    -- ===============================================
    -- ステータス初期化
    -- ===============================================
    ov_retcode := cv_status_normal;
    -- ===============================================
    -- ワークテーブル削除処理
    -- ===============================================
    -- インフォマート用ワーク（ヘッダー）
    DELETE xxcok_info_work_header xiwh
    WHERE  xiwh.tax_div    = iv_tax_div
    AND    xiwh.target_div = iv_target_div
    ;
--
    -- インフォマート用ワーク（明細）
    DELETE xxcok_info_work_line xiwl
    WHERE  xiwl.tax_div    = iv_tax_div
    AND    xiwl.target_div = iv_target_div
    ;
--
    -- インフォマート用ワーク（カスタム明細）
    DELETE xxcok_info_work_custom xiwc
    WHERE  xiwc.tax_div    = iv_tax_div
    AND    xiwc.target_div = iv_target_div
    ;
--
    COMMIT ;
--
  EXCEPTION
    -- *** 存在チェックエラー ***
    WHEN check_file_expt THEN
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
  END del_work;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_tax_div    IN  VARCHAR2    --  1.税区分
   ,iv_proc_div   IN  VARCHAR2    --  2.処理区分
   ,iv_target_div IN  VARCHAR2    --  3.対象区分
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
                      ,iv_name         => cv_msg_xxcok1_10768
                      ,iv_token_name1  => cv_tkn_tax_div
                      ,iv_token_value1 => iv_tax_div
                      ,iv_token_name2  => cv_tkn_proc_div
                      ,iv_token_value2 => iv_proc_div
                      ,iv_token_name3  => cv_tkn_target_div
                      ,iv_token_value3 => iv_target_div
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
    -- ファイル出力時のみ取得
    IF ( iv_proc_div = '2' ) THEN
--
      -- ===============================================
      -- 2.プロファイル取得(支払案内書_インフォマート_ディレクトリパス)
      -- ===============================================
      gv_i_dire_path  := FND_PROFILE.VALUE( cv_prof_i_dire_path );
      IF ( gv_i_dire_path IS NULL ) THEN
        lv_outmsg     := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_i_dire_path
                         );
        lb_msg_return := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
        RAISE init_fail_expt;
      END IF;
      -- ===============================================
      -- 2.プロファイル取得(支払案内書_インフォマート_ファイル名)
      -- ===============================================
      gv_i_file_name  := FND_PROFILE.VALUE( cv_prof_i_file_name );
      IF ( gv_i_file_name IS NULL ) THEN
        lv_outmsg     := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_i_file_name
                         );
        lb_msg_return := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
        RAISE init_fail_expt;
      END IF;
--
      -- ファイル名設定（外税・内税）
      gv_i_file_name := gv_i_file_name || iv_tax_div || iv_target_div || '.csv';
--
    END IF;
--
    -- ===============================================
    -- 2.プロファイル取得(FB支払条件)
    -- ===============================================
    gv_term_name  := FND_PROFILE.VALUE( cv_prof_term_name );
    IF ( gv_term_name IS NULL ) THEN
      lv_outmsg     := xxccp_common_pkg.get_msg(
                         iv_application   => cv_appli_short_name_xxcok
                        ,iv_name          => cv_msg_xxcok1_00003
                        ,iv_token_name1   => cv_tkn_profile
                        ,iv_token_value1  => cv_prof_term_name
                       );
      lb_msg_return := xxcok_common_pkg.put_message_f(
                         in_which         => FND_FILE.LOG
                        ,iv_message       => lv_outmsg
                        ,in_new_line      => 0
                       );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.プロファイル取得(銀行手数料_振込額基準)
    -- ===============================================
    gv_bank_fee_trans  := FND_PROFILE.VALUE( cv_prof_bank_fee_trans );
    IF ( gv_bank_fee_trans IS NULL ) THEN
      lv_outmsg        := xxccp_common_pkg.get_msg(
                            iv_application   => cv_appli_short_name_xxcok
                           ,iv_name          => cv_msg_xxcok1_00003
                           ,iv_token_name1   => cv_tkn_profile
                           ,iv_token_value1  => cv_prof_bank_fee_trans
                          );
      lb_msg_return    := xxcok_common_pkg.put_message_f(
                            in_which         => FND_FILE.LOG
                           ,iv_message       => lv_outmsg
                           ,in_new_line      => 0
                          );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.プロファイル取得(銀行手数料_基準額未満)
    -- ===============================================
    gv_bank_fee_less  := FND_PROFILE.VALUE( cv_prof_bank_fee_less );
    IF ( gv_bank_fee_less IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_less
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.プロファイル取得(銀行手数料_基準額以上)
    -- ===============================================
    gv_bank_fee_more  := FND_PROFILE.VALUE( cv_prof_bank_fee_more );
    IF ( gv_bank_fee_more IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bank_fee_more
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 2.プロファイル取得(販売手数料_消費税率)
    -- ===============================================
    gn_bm_tax         := TO_NUMBER( FND_PROFILE.VALUE( cv_prof_bm_tax ) );
    IF ( gn_bm_tax IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00003
                          ,iv_token_name1   => cv_tkn_profile
                          ,iv_token_value1  => cv_prof_bm_tax
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
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
    -- ===============================================
    -- 2.プロファイル取得(電気料（変動）品目コード)
    -- ===============================================
    gv_elec_change_item_code := FND_PROFILE.VALUE( cv_prof_elec_change_item ) ;
    IF ( gv_elec_change_item_code IS NULL ) THEN
      lv_outmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_short_name_xxcok
                     ,iv_name         => cv_msg_xxcok1_00003
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_prof_elec_change_item
                    );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
--
    -- ===============================================
    -- 3.メッセージ取得(おもて備考)
    -- ===============================================
    gv_remarks  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_short_name_xxcok
                    ,iv_name         => cv_msg_xxcok1_10762
                   );
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
    -- 業務日付 -1ヶ月の締め日、支払予定日を取得
    gd_operating_date := ADD_MONTHS( gd_process_date, -1 );
    -- ===============================================
    -- 5.締め日、支払日予定日取得
    -- ===============================================
    xxcok_common_pkg.get_close_date_p(
        ov_errbuf         => lv_errbuf
       ,ov_retcode        => lv_retcode
       ,ov_errmsg         => lv_errmsg
       ,id_proc_date      => gd_operating_date
       ,iv_pay_cond       => gv_term_name
       ,od_close_date     => gd_closing_date   -- 締め日
       ,od_pay_date       => gd_schedule_date  -- 支払予定日
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 支払日取得
    -- ===============================================
    gd_pay_date := xxcok_common_pkg.get_operating_day_f(
                    id_proc_date      => gd_schedule_date
                   ,in_days           => 0
                   ,in_proc_type      => 1
                  );
    IF ( gd_pay_date IS NULL ) THEN
      lv_outmsg       := xxccp_common_pkg.get_msg(
                           iv_application   => cv_appli_short_name_xxcok
                          ,iv_name          => cv_msg_xxcok1_00036
                         );
      lb_msg_return   := xxcok_common_pkg.put_message_f(
                           in_which         => FND_FILE.LOG
                          ,iv_message       => lv_outmsg
                          ,in_new_line      => 0
                         );
      RAISE init_fail_expt;
    END IF;
    -- ===============================================
    -- 6.税込手数料取得
    -- ===============================================
    gn_tax_include_less := TO_NUMBER( gv_bank_fee_less ) * ( 1 + gn_bm_tax / 100 );
    gn_tax_include_more := TO_NUMBER( gv_bank_fee_more ) * ( 1 + gn_bm_tax / 100 );
--
    -- ファイル出力時のみ取得
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- 7.ディレクトリ出力
      -- ===============================================
      lv_outmsg      := xxccp_common_pkg.get_msg(
                          iv_application   => cv_appli_short_name_xxcok
                         ,iv_name          => cv_msg_xxcok1_00067
                         ,iv_token_name1   => cv_tkn_directory
                         ,iv_token_value1  => xxcok_common_pkg.get_directory_path_f( gv_i_dire_path )
                        );
      lb_msg_return  := xxcok_common_pkg.put_message_f(
                          in_which         => FND_FILE.LOG
                         ,iv_message       => lv_outmsg
                         ,in_new_line      => 0
                        );
      -- ===============================================
      -- 8.ファイル名出力
      -- ===============================================
      lv_outmsg      := xxccp_common_pkg.get_msg(
                          iv_application   => cv_appli_short_name_xxcok
                         ,iv_name          => cv_msg_xxcok1_00006
                         ,iv_token_name1   => cv_tkn_file_name
                         ,iv_token_value1  => gv_i_file_name
                        );
      lb_msg_return  := xxcok_common_pkg.put_message_f(
                          in_which         => FND_FILE.LOG
                         ,iv_message       => lv_outmsg
                         ,in_new_line      => 1
                        );
    END IF;
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
   ,iv_proc_div   IN  VARCHAR2    --  2.処理区分
   ,iv_target_div IN  VARCHAR2    --  3.対象区分
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
     ,iv_proc_div   =>  iv_proc_div     --  2.処理区分
     ,iv_target_div =>  iv_target_div   --  3.対象区分
     ,ov_errbuf     =>  lv_errbuf       --  エラー・メッセージ           --# 固定 #
     ,ov_retcode    =>  lv_retcode      --  リターン・コード             --# 固定 #
     ,ov_errmsg     =>  lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 処理区分 = 1：計算処理の場合
    IF ( iv_proc_div = '1' ) THEN
      -- ===============================================
      -- ワークテーブルデータ削除(A-2)
      -- ===============================================
      del_work(
        iv_tax_div    => iv_tax_div      --  1.税区分
       ,iv_target_div => iv_target_div   --  3.対象区分
       ,ov_errbuf     => lv_errbuf       --  エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode      --  リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================================
      -- ワーク明細情報作成(A-3)
      -- ===============================================
      ins_work_line(
        iv_tax_div    => iv_tax_div      --  1.税区分
       ,iv_target_div => iv_target_div   --  3.対象区分
       ,ov_errbuf     => lv_errbuf       --  エラー・メッセージ           --# 固定 #
       ,ov_retcode    => lv_retcode      --  リターン・コード             --# 固定 #
       ,ov_errmsg     => lv_errmsg       --  ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================================
      -- ワークカスタム明細情報作成(A-4)
      -- ===============================================
      ins_work_custom(
        iv_tax_div    => iv_tax_div      --  1.税区分
       ,iv_target_div => iv_target_div   --  3.対象区分
       ,ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_file_close_expt;
      END IF;
      -- ===============================================
      -- ワークヘッダー明細情報作成(A-5)
      -- ===============================================
      ins_work_header(
        iv_tax_div    => iv_tax_div      --  1.税区分
       ,iv_target_div => iv_target_div   --  3.対象区分
       ,ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_file_close_expt;
      END IF;
    END IF;
--
    -- 処理区分 = 2：ファイル出力
    IF ( iv_proc_div = '2' ) THEN
      -- ===============================================
      -- ファイルオープン(A-6)
      -- ===============================================
      file_open(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- ===============================================
      -- ワークヘッダー・明細対象データ抽出(A-7)
      -- ===============================================
      get_work_head_line(
        iv_tax_div    => iv_tax_div
       ,iv_target_div => iv_target_div
       ,ov_errbuf     => lv_errbuf
       ,ov_retcode    => lv_retcode
       ,ov_errmsg     => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_file_close_expt;
      END IF;
      -- ===============================================
      -- ファイルクローズ(A-12)
      -- ===============================================
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
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
    WHEN global_process_file_close_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
      file_close(
        ov_errbuf   => lv_errbuf
       ,ov_retcode  => lv_retcode
       ,ov_errmsg   => lv_errmsg
      );
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
   ,iv_proc_div     IN  VARCHAR2          -- 2.処理区分
   ,iv_target_div   IN  VARCHAR2          -- 3.対象区分
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
     ,iv_proc_div   => iv_proc_div      -- 2.処理区分
     ,iv_target_div => iv_target_div    -- 3.対象区分
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
    -- 対象件数はファイル出力時の出力
    IF ( iv_proc_div = '2' ) THEN
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
    END IF;
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
END XXCOK015A05C;
/
