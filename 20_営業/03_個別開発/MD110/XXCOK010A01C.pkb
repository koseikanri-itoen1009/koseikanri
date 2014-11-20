CREATE OR REPLACE PACKAGE BODY XXCOK010A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK010A01C(body)
 * Description      : 売上実績振替情報テーブルのデータから、
                      情報系システムへI/Fする「実績振替」を作成します。
 * MD.050           : 売上実績振替情報のI/Fファイル作成 (MD050_COK_010_A01)
 * Version          : 1.6
 *
 * Program List
 * ------------------------- ----------------------------------------------------------
 *  Name                      Description
 * ------------------------- ----------------------------------------------------------
 *  init                      初期処理                        (A-1)
 *  get_selling_trns_info     売上実績振替情報抽出            (A-2)
 *  output_csvfile            売上実績データ（実績振替）出力  (A-3)
 *  update_selling_trns_info  売上実績振替情報更新            (A-4)
 *  submain                   メイン処理プロシージャ
 *  main                      コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   K.Motohashi      新規作成
 *  2009/02/06    1.1   M.Hiruta         [障害COK_013]ディレクトリパスの出力方法を変更
 *  2009/03/04    1.2   M.Hiruta         [障害COK_072]出力ファイル(CSV)末尾のカンマ削除
 *  2009/03/19    1.3   M.Hiruta         [障害T1_0087]行Noのダブルクォーテーションを削除
 *  2010/01/17    1.4   Y.Kuboshima      [障害E_本稼動_00555,障害E_本稼動_00900]
 *                                       出力項目内容の変更
 *                                       【売上金額】売上金額(税込)                            -> 売上金額(税抜)
 *                                       【消費税額】売上金額(税込) - 売上金額(税抜)           -> 「0」固定
 *                                       【売上数量】数量                                      -> 基準単位数量
 *                                       【納品単価】納品単価÷納品単位１あたりの基準単位数量  -> 基準単位単価
 *  2010/02/18    1.5   K.Yamaguchi      [障害E_本稼動_01600]非在庫品目の場合納品数量を０とする
 *                                                           変動電気料を連携対象外とする
 *  2011/04/19    1.6   Y.Nishino        [障害E_本稼動_04976]情報系への連携項目追加
 *
 *****************************************************************************************/
--
-- ===================================================
-- グローバル定数宣言部
-- ===================================================
  cv_pkg_name                CONSTANT VARCHAR2(100)  := 'XXCOK010A01C';                      -- パッケージ名
--
  --ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)    := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by              CONSTANT NUMBER         := fnd_global.user_id;                  -- CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER         := fnd_global.user_id;                  -- LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER         := fnd_global.login_id;                 -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER         := fnd_global.conc_request_id;          -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER         := fnd_global.prog_appl_id;             -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER         := fnd_global.conc_program_id;          -- PROGRAM_ID
--
  -- *** 定数(セパレータ) ***
  cv_msg_part                CONSTANT VARCHAR2(3)    := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)    := '.';
  cv_msg_wq                  CONSTANT CHAR(1)        := '"';                                 -- ダブルクォーテイション
  cv_msg_c                   CONSTANT CHAR(1)        := ',';                                 -- コンマ
  cv_msg_slash               CONSTANT CHAR(1)        := '/';                                 -- スラッシュ
--
  -- *** 定数(カウント用数値) ***
  cn_count_0                 CONSTANT NUMBER         := 0;                                   -- 0
  cn_count_1                 CONSTANT NUMBER         := 1;                                   -- 1
--
  -- *** 定数(数値) ***
  cn_number_0                CONSTANT NUMBER         := 0;                                   -- 0
  cn_number_1                CONSTANT NUMBER         := 1;                                   -- 1
--
  -- *** 定数(アプリケーション短縮名) ***
  cv_appli_name_xxccp        CONSTANT VARCHAR2(10)   := 'XXCCP';                             -- XXCCP
  cv_appli_name_xxcok        CONSTANT VARCHAR2(10)   := 'XXCOK';                             -- XXCOK
--
  -- *** 定数(トークン) ***
  cv_tkn_output              CONSTANT VARCHAR2(10)   := 'OUTPUT';
  cv_tkn_count               CONSTANT VARCHAR2(10)   := 'COUNT';                             -- 件数出力トークン
  cv_tkn_bill_no             CONSTANT VARCHAR2(30)   := 'BILL_NO';                           -- 伝票番号
  cv_tkn_line_no             CONSTANT VARCHAR2(30)   := 'LINE_NO';                           -- 明細番号
  cv_tkn_location_code       CONSTANT VARCHAR2(30)   := 'LOCATION_CODE';                     -- 拠点コード
  cv_tkn_customer_code       CONSTANT VARCHAR2(30)   := 'CUSTOMER_CODE';                     -- 顧客コード
  cv_tkn_item_code           CONSTANT VARCHAR2(30)   := 'ITEM_CODE';                         -- 品目コード
  cv_tkn_delivery_price      CONSTANT VARCHAR2(30)   := 'DELIVERY_PRICE';                    -- 納品単価
  cv_tkn_profile             CONSTANT VARCHAR2(30)   := 'PROFILE';                           -- プロファイル名
  cv_tkn_directory           CONSTANT VARCHAR2(30)   := 'DIRECTORY';                         -- ディレクトリ
  cv_tkn_file_name           CONSTANT VARCHAR2(30)   := 'FILE_NAME';                         -- ファイル名
--
  -- *** 定数(メッセージ) ***
  cv_msg_ccp1_90000          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90000';                  -- 対象件数出力
  cv_msg_ccp1_90001          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90001';                  -- 成功件数出力
  cv_msg_ccp1_90002          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90002';                  -- エラー件数出力
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  cv_msg_ccp1_90003          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90003';                  -- スキップ件数出力
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
  cv_msg_ccp1_90004          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90004';                  -- 正常終了メッセージ
  cv_msg_ccp1_90005          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90005';                  -- 警告終了メッセージ
  cv_msg_ccp1_90006          CONSTANT VARCHAR2(50)   := 'APP-XXCCP1-90006';                  -- エラー終了メッセージ
  cv_msg_ccp1_90008          CONSTANT VARCHAR2(100)  := 'APP-XXCCP1-90008';                  -- 入力パラメータ無し
--
  cv_msg_cok1_00001          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00001';                  -- 対象データ無エラー
  cv_msg_cok1_00003          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00003';                  -- プロファイル取得エラー
  cv_msg_cok1_00067          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00067';                  -- ディレクトリ出力
  cv_msg_cok1_00006          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00006';                  -- ファイル名出力
  cv_msg_cok1_00009          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00009';                  -- ファイル存在チェックエラー
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  cv_msg_cok1_00028          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-00028';                  -- 業務日付取得エラー
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
  cv_msg_cok1_10070          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10070';                  -- ロック取得エラー
  cv_msg_cok1_10071          CONSTANT VARCHAR2(50)   := 'APP-XXCOK1-10071';                  -- 更新エラー
--
  -- *** 定数(カスタム・プロファイル名) ***
  cv_prof_company_code       CONSTANT VARCHAR2(50)   := 'XXCOK1_AFF1_COMPANY_CODE';          -- 会社コード
  cv_prof_dire_path          CONSTANT VARCHAR2(50)   := 'XXCOK1_SELLING_DIRE_PATH';          -- 売上実績データディレクトリパス
  cv_prof_file_name          CONSTANT VARCHAR2(50)   := 'XXCOK1_SELLING_FILE_NAME';          -- 売上実績データファイル名
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  cv_prof_elec_change        CONSTANT VARCHAR2(50)   := 'XXCOK1_ELEC_CHANGE_ITEM_CODE';      -- 電気料（変動）品目コード
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
  -- *** 定数(CSVファイルオープン) ***
  cv_fopen_open_mode         CONSTANT VARCHAR2(1)    := 'w';
  cn_fopen_max_line          CONSTANT NUMBER         := 32767;
--
  -- *** 定数(情報系I/Fフラグ) ***
  cv_info_if_flag_yet        CONSTANT VARCHAR2(1)    := '0';                                 -- 未済
  cv_info_if_flag_over       CONSTANT VARCHAR2(1)    := '1';                                 -- 済
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  cv_info_if_flag_off        CONSTANT VARCHAR2(1)    := '2';                                 -- 対象外
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  -- *** 定数(参照タイプ) ***
  cv_lookup_type_01          CONSTANT VARCHAR2(30)   := 'XXCOS1_NO_INV_ITEM_CODE';           -- 非在庫品目
  -- *** 定数(参照タイプ・有効フラグ) ***
  cv_enable                  CONSTANT VARCHAR2(1)   := 'Y'; -- 有効
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
-- ==============
-- 共通例外宣言部
-- ==============
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  --==================================================
  -- グローバル例外
  --==================================================
  --*** エラー終了 ***
  error_proc_expt           EXCEPTION;
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
  -- ==============
  -- グローバル変数
  -- ==============
  gn_target_cnt         NUMBER              DEFAULT NULL;   -- 対象件数
  gn_normal_cnt         NUMBER              DEFAULT NULL;   -- 正常件数
  gn_error_cnt          NUMBER              DEFAULT NULL;   -- エラー件数
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  gn_skip_cnt           NUMBER              DEFAULT 0;      -- スキップ件数
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
  gd_sysdate            DATE                DEFAULT NULL;   -- システム日付
  gv_prof_company_code  VARCHAR2(100)       DEFAULT NULL;   -- 会社コード
  gv_prof_dire_path     VARCHAR2(100)       DEFAULT NULL;   -- 売上実績データディレクトリパス
  gv_prof_file_name     VARCHAR2(100)       DEFAULT NULL;   -- 売上実績データファイル名
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  gv_prof_elec_change   VARCHAR2(100)       DEFAULT NULL;   -- 電気料（変動）品目コード
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
  g_file_handle         UTL_FILE.FILE_TYPE  DEFAULT NULL;   -- ファイルハンドル
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
  gd_process_date       DATE                DEFAULT NULL;   -- 業務処理日付
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
  -- =================================
  -- ユーザー定義グローバルカーソル
  -- 売上実績振替情報抽出カーソル(A-2)
  -- =================================
  CURSOR get_sell_trns_info_cur
  IS
    SELECT xsti.selling_trns_info_id  AS xsti_id                   -- 売上実績振替情報ID(内部ID)
         , xsti.slip_no               AS xsti_slip_no              -- 伝票番号
         , xsti.detail_no             AS xsti_detail_no            -- 明細番号
         , xsti.selling_date          AS xsti_selling_date         -- 売上計上日
         , xsti.selling_type          AS xsti_selling_type         -- 売上区分
         , xsti.delivery_slip_type    AS xsti_delivery_slip_type   -- 納品伝票区分
         , xsti.base_code             AS xsti_base_code            -- 拠点コード
         , xsti.cust_code             AS xsti_cust_code            -- 顧客コード
         , xsti.selling_emp_code      AS xsti_selling_emp_code     -- 担当営業コード
         , xsti.delivery_form_type    AS xsti_delivery_form_type   -- 納品形態区分
         , xsti.article_code          AS xsti_article_code         -- 物件コード
         , xsti.card_selling_type     AS xsti_card_selling_type    -- カード売り区分
         , xsti.checking_date         AS xsti_checking_date        -- 検収日
         , xsti.demand_to_cust_code   AS xsti_demand_to_cust_code  -- 請求先顧客コード
         , xsti.h_c                   AS xsti_h_c                  -- H＆C
         , xsti.column_no             AS xsti_column_no            -- コラムNo.
         , xsti.item_code             AS xsti_item_code            -- 品目コード
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR START
--         , xsti.qty                   AS xsti_qty                  -- 数量
         , CASE
             WHEN EXISTS( SELECT 'X'
                          FROM fnd_lookup_values_vl     flvv
                          WHERE flvv.lookup_type        = cv_lookup_type_01 -- 非在庫品目
                            AND flvv.lookup_code        = xsti.item_code
                            AND flvv.enabled_flag       = cv_enable
                            AND gd_process_date   BETWEEN NVL( flvv.start_date_active, gd_process_date )
                                                      AND NVL( flvv.end_date_active  , gd_process_date )
                  )
             THEN
               0
             ELSE
               xsti.qty
           END                        AS xsti_qty                  -- 数量
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR END
         , xsti.delivery_unit_price   AS xsti_delivery_unit_price  -- 納品単価
         , xsti.selling_amt           AS xsti_selling_amt          -- 売上金額
         , xsti.selling_amt_no_tax    AS xsti_selling_amt_notax    -- 売上金額(税抜き)
         , xsti.tax_code              AS xsti_tax_code             -- 消費税コード
         , xsti.delivery_base_code    AS xsti_delivery_base_code   -- 納品拠点コード
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- 単位の追加
         , xsti.unit_type             AS xsit_unit_type            -- 単位
-- End   2010/01/07 Ver1.4 Y.Kuboshima
    FROM xxcok_selling_trns_info      xsti                         -- 売上実績振替情報テーブル
    WHERE xsti.info_interface_flag = cv_info_if_flag_yet;
--
  -- ==============================
  -- ユーザー定義グローバルテーブル
  -- ==============================
  TYPE g_sell_trns_info_ttype IS TABLE OF get_sell_trns_info_cur%ROWTYPE
  INDEX BY BINARY_INTEGER;
  g_xsti_tab g_sell_trns_info_ttype;
--
  -- ================
  -- ユーザー定義例外
  -- ================
  resouce_busy_expt  EXCEPTION;  -- グローバル例外
--
  -- ========
  -- プラグマ
  -- ========
  PRAGMA EXCEPTION_INIT( resouce_busy_expt, -54 );
--
  /**********************************************************************************
   * Procedure Name   : update_selling_trns_info
   * Description      : 売上実績振替情報更新(A-4)
  ***********************************************************************************/
  PROCEDURE update_selling_trns_info(
    ov_errbuf   OUT VARCHAR2          -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2          -- リターン・コード
  , ov_errmsg   OUT VARCHAR2          -- ユーザー・エラー・メッセージ
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR START
--  , in_idx      IN  BINARY_INTEGER )  -- カーソル取得値格納レコード
  , in_idx      IN  BINARY_INTEGER    -- カーソル取得値格納レコード
  , iv_if_flag  IN  VARCHAR2          -- 情報系連携フラグ
  )
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR END
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'update_selling_trns_info';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
  -- =========================
  -- ロック取得用カーソル(A-4)
  -- =========================
  CURSOR lock_table_cur(
    in_sell_trns_info_id IN xxcok_selling_trns_info.selling_trns_info_id%TYPE )
  IS
    SELECT 'X'                      AS dummy
      FROM xxcok_selling_trns_info  xsti                     -- 売上実績振替情報テーブル
     WHERE xsti.selling_trns_info_id = in_sell_trns_info_id
       FOR UPDATE OF xsti.selling_trns_info_id NOWAIT;
--
    -- ============
    -- ローカル例外
    -- ============
    update_err_expt  EXCEPTION;  -- 売上実績振替情報更新エラー
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- =====================================
    --売上実績振替情報テーブルのロックを取得
    -- =====================================
    OPEN  lock_table_cur( g_xsti_tab( in_idx ).xsti_id );
    CLOSE lock_table_cur;
--
      BEGIN
      -- =============================
      --売上実績振替情報テーブルを更新
      -- =============================
      UPDATE xxcok_selling_trns_info xsti                               -- 売上実績振替情報テーブル
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR START
--         SET xsti.info_interface_flag     =  cv_info_if_flag_over       -- 情報系I/Fフラグ='1'(I/F済)
         SET xsti.info_interface_flag     =  iv_if_flag                 -- 情報系I/Fフラグ
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR END
           , xsti.last_updated_by         =  cn_last_updated_by         -- 最終更新者
           , xsti.last_update_date        =  SYSDATE                    -- 最終更新日
           , xsti.last_update_login       =  cn_last_update_login       -- 最終更新ログインID
           , xsti.request_id              =  cn_request_id              -- 要求ID
           , xsti.program_application_id  =  cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
           , xsti.program_id              =   cn_program_id             -- コンカレント・プログラムID
           , xsti.program_update_date     =  SYSDATE                    -- プログラム更新日
       WHERE xsti.selling_trns_info_id    =  g_xsti_tab( in_idx ).xsti_id;
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_out_msg := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appli_name_xxcok
                        , iv_name          =>  cv_msg_cok1_10071
                        , iv_token_name1   =>  cv_tkn_bill_no
                        , iv_token_value1  =>  g_xsti_tab( in_idx ).xsti_slip_no
                        , iv_token_name2   =>  cv_tkn_line_no
                        , iv_token_value2  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_detail_no )
                        , iv_token_name3   =>  cv_tkn_location_code
                        , iv_token_value3  =>  g_xsti_tab( in_idx ).xsti_base_code
                        , iv_token_name4   =>  cv_tkn_customer_code
                        , iv_token_value4  =>  g_xsti_tab( in_idx ).xsti_cust_code
                        , iv_token_name5   =>  cv_tkn_item_code
                        , iv_token_value5  =>  g_xsti_tab( in_idx ).xsti_item_code
                        , iv_token_name6   =>  cv_tkn_delivery_price
                        , iv_token_value6  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_delivery_unit_price )
                        );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which     =>  FND_FILE.OUTPUT
                        , iv_message   =>  lv_out_msg
                        , in_new_line  =>  cn_number_0
                        );
          RAISE update_err_expt;
      END;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    --*** ロック取得エラー ***
    WHEN resouce_busy_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appli_name_xxcok
                    , iv_name          =>  cv_msg_cok1_10070
                    , iv_token_name1   =>  cv_tkn_bill_no
                    , iv_token_value1  =>  g_xsti_tab( in_idx ).xsti_slip_no
                    , iv_token_name2   =>  cv_tkn_line_no
                    , iv_token_value2  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_detail_no )
                    , iv_token_name3   =>  cv_tkn_location_code
                    , iv_token_value3  =>  g_xsti_tab( in_idx ).xsti_base_code
                    , iv_token_name4   =>  cv_tkn_customer_code
                    , iv_token_value4  =>  g_xsti_tab( in_idx ).xsti_cust_code
                    , iv_token_name5   =>  cv_tkn_item_code
                    , iv_token_value5  =>  g_xsti_tab( in_idx ).xsti_item_code
                    , iv_token_name6   =>  cv_tkn_delivery_price
                    , iv_token_value6  =>  TO_CHAR( g_xsti_tab( in_idx ).xsti_delivery_unit_price )
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** 売上実績振替情報更新エラー ***
    WHEN update_err_expt THEN
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR START
--      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR END
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END update_selling_trns_info;
--
--
  /**********************************************************************************
   * Procedure Name   : output_csvfile
   * Description      : 売上実績データ（実績振替）出力(A-3)
   ***********************************************************************************/
  PROCEDURE output_csvfile(
    ov_errbuf   OUT VARCHAR2          -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2          -- リターン・コード
  , ov_errmsg   OUT VARCHAR2          -- ユーザー・エラー・メッセージ
  , in_idx      IN  BINARY_INTEGER )  -- カーソル取得値格納レコード
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'output_csvfile';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)                            DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)                               DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)                            DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lb_retcode  BOOLEAN                                   DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    lv_csvfile  VARCHAR2(3000)                            DEFAULT NULL;  -- CSVファイル
    lt_tax_amt  xxcok_selling_trns_info.selling_amt%TYPE  DEFAULT NULL;  -- 消費税額
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
    ln_sale_qty NUMBER                                    DEFAULT NULL;  -- 売上数量
-- End   2010/01/07 Ver1.4 Y.Kuboshima
-- 2010/01/08 Ver.1.4 [E_本稼動_00555,E_本稼動_00900] SCS K.Yamaguchi ADD START
    ln_item_uom_qty   NUMBER       DEFAULT NULL;
    ln_item_uom_price NUMBER       DEFAULT NULL;
    lv_item_uom_price VARCHAR2(15) DEFAULT NULL;
-- 2010/01/08 Ver.1.4 [E_本稼動_00555,E_本稼動_00900] SCS K.Yamaguchi ADD END
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ==============
    -- 消費税額の算出
    -- ==============
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- 0固定とするよう修正
--    lt_tax_amt := g_xsti_tab( in_idx ).xsti_selling_amt - g_xsti_tab( in_idx ).xsti_selling_amt_notax;
    lt_tax_amt := cn_number_0;
-- End   2010/01/07 Ver1.4 Y.Kuboshima
    --
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
    -- ==============
    -- 売上数量の算出
    -- ==============
    -- 基準単位数量の取得
    ln_sale_qty := TRUNC( xxcok_common_pkg.get_uom_conversion_qty_f(
                            iv_item_code => g_xsti_tab( in_idx ).xsti_item_code -- 品目コード
                          , iv_uom_code  => g_xsti_tab( in_idx ).xsit_unit_type -- 単位
                          , in_quantity  => g_xsti_tab( in_idx ).xsti_qty       -- 数量
                          )
                        , 2
                   )
    ;
-- End   2010/01/07 Ver1.4 Y.Kuboshima
-- 2010/01/08 Ver.1.4 [E_本稼動_00555,E_本稼動_00900] SCS K.Yamaguchi ADD START
    -- 基準単位数量の取得
    ln_item_uom_qty := TRUNC( xxcok_common_pkg.get_uom_conversion_qty_f(
                                iv_item_code => g_xsti_tab( in_idx ).xsti_item_code -- 品目コード
                              , iv_uom_code  => g_xsti_tab( in_idx ).xsit_unit_type -- 単位
                              , in_quantity  => 1                                   -- 数量
                              )
                            , 2
                       )
    ;
    ln_item_uom_price := ROUND(   g_xsti_tab( in_idx ).xsti_delivery_unit_price -- 納品単価
                                / ln_item_uom_qty                               -- 基準単位数量
                              , 2
                         )
    ;
    IF( ln_item_uom_price IS NULL ) THEN
      lv_item_uom_price := NULL;
    ELSIF( ln_item_uom_price = TRUNC( ln_item_uom_price ) ) THEN
      lv_item_uom_price := TO_CHAR( ln_item_uom_price );
    ELSE
      lv_item_uom_price := TO_CHAR( ln_item_uom_price, 'FM999999990.99' );
    END IF;
-- 2010/01/08 Ver.1.4 [E_本稼動_00555,E_本稼動_00900] SCS K.Yamaguchi ADD END
    --
    -- ================
    -- ファイル書き込み
    -- ================
    lv_csvfile := (
         cv_msg_wq || gv_prof_company_code                                           || cv_msg_wq  -- 会社コード
      || cv_msg_c
                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_selling_date, 'YYYYMMDD' )                -- 売上計上
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_slip_no                              || cv_msg_wq  -- 伝票番号
      || cv_msg_c
-- Start 2009/03/19 Ver.1.3 M.Hiruta
--      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_detail_no                            || cv_msg_wq  -- 行No.
                   || g_xsti_tab( in_idx ).xsti_detail_no                                          -- 行No.
-- End   2009/03/19 Ver.1.3 M.Hiruta
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_cust_code                            || cv_msg_wq  -- 顧客コード
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_item_code                            || cv_msg_wq  -- 商品コード
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_article_code                         || cv_msg_wq  -- 物件コード
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_h_c                                  || cv_msg_wq  -- H＆C
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_base_code                            || cv_msg_wq  -- 売上拠点コード
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_selling_emp_code                     || cv_msg_wq  -- 成績者コード
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_card_selling_type                    || cv_msg_wq  -- カード売り区分
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_delivery_base_code                   || cv_msg_wq  -- 納品拠点コード
      || cv_msg_c
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- 売上金額(税抜)を設定するよう修正
--                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_selling_amt )                             -- 売上金額
                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_selling_amt_notax )                       -- 売上金額
-- End   2010/01/07 Ver1.4 Y.Kuboshima
      || cv_msg_c
-- Start 2010/01/07 Ver1.4 Y.Kuboshima
-- 基準単位数量を設定するよう修正
--                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_qty )                                     -- 売上数量
                   || TO_CHAR( ln_sale_qty )                                                       -- 売上数量
-- End   2010/01/07 Ver1.4 Y.Kuboshima
      || cv_msg_c
                   || TO_CHAR( lt_tax_amt )                                                        -- 消費税額
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_delivery_slip_type                   || cv_msg_wq  -- 売上返品区分
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_selling_type                         || cv_msg_wq  -- 売上区分
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_delivery_form_type                   || cv_msg_wq  -- 納品形態区分
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_column_no                            || cv_msg_wq  -- コラムNo.
      || cv_msg_c
                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_checking_date, 'YYYYMMDD' )               -- 検収日
      || cv_msg_c
-- 2010/01/08 Ver.1.4 [E_本稼動_00555,E_本稼動_00900] SCS K.Yamaguchi REPAIR START
--                   || TO_CHAR( g_xsti_tab( in_idx ).xsti_delivery_unit_price )                     -- 納品単価
                   || lv_item_uom_price                                                            -- 納品単価
-- 2010/01/08 Ver.1.4 [E_本稼動_00555,E_本稼動_00900] SCS K.Yamaguchi REPAIR END
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_tax_code                             || cv_msg_wq  -- 消費税コード
      || cv_msg_c
      || cv_msg_wq || g_xsti_tab( in_idx ).xsti_demand_to_cust_code                  || cv_msg_wq  -- 請求顧客コード
      || cv_msg_c
-- 2011/04/19 Ver.1.6 [障害E_本稼動_04976] SCS Y.Nishino ADD START
      || cv_msg_wq                                                                   || cv_msg_wq  -- 注文伝票番号
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- 伝票区分
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- 伝票分類コード
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- つり銭切れ時間100円
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- つり銭切れ時間10円
      || cv_msg_c
                   || cn_number_0                                                                  -- 基準単価（税込）
      || cv_msg_c
                   || cn_number_0                                                                  -- 売上金額（税込）
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- 売切区分
      || cv_msg_c
      || cv_msg_wq                                                                   || cv_msg_wq  -- 売切時間
      || cv_msg_c
-- 2011/04/19 Ver.1.6 [障害E_本稼動_04976] SCS Y.Nishino ADD END
                   || TO_CHAR( gd_sysdate, 'YYYYMMDDHH24MISS' )                                    -- システム日付
    );
--
    -- ============
    -- ファイル出力
    -- ============
    UTL_FILE.PUT_LINE(
      file    =>  g_file_handle
    , buffer  =>  lv_csvfile
    );
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END output_csvfile;
--
--
  /**********************************************************************************
   * Procedure Name   : get_selling_trns_info（ループ部）
   * Description      : 売上実績振替情報抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_selling_trns_info(
    ov_errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    -- リターン・コード
  , ov_errmsg   OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'get_selling_trns_info';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg  VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    -- =============
    -- ローカル例外
    -- =============
    loop_expt     EXCEPTION;  -- ループ内のエラー
    no_data_expt  EXCEPTION;  -- 対象データ無エラー
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    gn_target_cnt := 0;  -- 対象件数
    gn_normal_cnt := 0;  -- 正常件数
    gn_error_cnt  := 0;  -- エラー件数
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
    gn_skip_cnt   := 0;  -- スキップ件数
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
    -- ========================================
    -- 売上実績振替情報テーブルからデータを抽出
    -- ========================================
    OPEN get_sell_trns_info_cur;
    FETCH get_sell_trns_info_cur BULK COLLECT INTO g_xsti_tab;
    CLOSE get_sell_trns_info_cur;
--
    IF( g_xsti_tab.COUNT = cn_count_0 ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  =>  cv_appli_name_xxcok
                    , iv_name         =>  cv_msg_cok1_00001
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      RAISE no_data_expt;
    ELSE
      gn_target_cnt := g_xsti_tab.COUNT;
    END IF;
--
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR START
--    -- ======
--    -- ループ
--    -- ======
--    <<get_selling_trns_info_loop>>
--    FOR ln_idx IN g_xsti_tab.FIRST .. g_xsti_tab.LAST LOOP
----
--      -- ==============================
--      -- 売上実績データ（実績振替）出力
--      -- ==============================
--      output_csvfile(
--        ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
--      , ov_retcode  =>  lv_retcode  -- リターン・コード
--      , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
--      , in_idx      =>  ln_idx      -- カーソル取得値格納レコード
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE loop_expt;
--      END IF;
----
--      -- =====================
--      --成功処理件数のカウント
--      -- =====================
--      gn_normal_cnt := gn_normal_cnt + cn_count_1;
----
--      -- ====================
--      -- 売上実績振替情報更新
--      -- ====================
--      update_selling_trns_info(
--        ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
--      , ov_retcode  =>  lv_retcode  -- リターン・コード
--      , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
--      , in_idx      =>  ln_idx      -- カーソル取得値格納レコード
--      );
--      IF( lv_retcode = cv_status_error ) THEN
--        RAISE loop_expt;
--      END IF;
----
--    END LOOP get_selling_trns_info_loop;
    --==================================================
    -- 実績振替情報ループ
    --==================================================
    <<get_selling_trns_info_loop>>
    FOR i IN 1 .. g_xsti_tab.COUNT LOOP
      --==================================================
      -- 処理対象外（変動電気料）
      --==================================================
      IF( g_xsti_tab( i ).xsti_item_code = gv_prof_elec_change ) THEN
        --==================================================
        -- 売上実績振替情報更新
        --==================================================
        update_selling_trns_info(
          ov_errbuf   =>  lv_errbuf               -- エラー・メッセージ
        , ov_retcode  =>  lv_retcode              -- リターン・コード
        , ov_errmsg   =>  lv_errmsg               -- ユーザー・エラー・メッセージ
        , in_idx      =>  i                       -- カーソル取得値格納レコード
        , iv_if_flag  =>  cv_info_if_flag_off     -- 対象外
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE loop_expt;
        END IF;
        gn_skip_cnt := gn_skip_cnt + 1;
      --==================================================
      -- 処理対象
      --==================================================
      ELSE
        --==================================================
        -- 売上実績データ（実績振替）出力
        --==================================================
        output_csvfile(
          ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
        , ov_retcode  =>  lv_retcode  -- リターン・コード
        , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
        , in_idx      =>  i           -- カーソル取得値格納レコード
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE loop_expt;
        END IF;
        --==================================================
        -- 売上実績振替情報更新
        --==================================================
        update_selling_trns_info(
          ov_errbuf   =>  lv_errbuf               -- エラー・メッセージ
        , ov_retcode  =>  lv_retcode              -- リターン・コード
        , ov_errmsg   =>  lv_errmsg               -- ユーザー・エラー・メッセージ
        , in_idx      =>  i                       -- カーソル取得値格納レコード
        , iv_if_flag  =>  cv_info_if_flag_over    -- 済
        );
        IF( lv_retcode = cv_status_error ) THEN
          RAISE loop_expt;
        END IF;
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    END LOOP get_selling_trns_info_loop;
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi REPAIR END
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
    --*** 対象データ無エラー ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_warn;
    --*** ループ内のエラー ***
    WHEN loop_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END get_selling_trns_info;
--
--
  /***********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    -- リターン・コード
  , ov_errmsg   OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ
  IS
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf       VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg       VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lb_retcode      BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
    lv_out_msg      VARCHAR2(2000)  DEFAULT NULL;  -- メッセージ
    lb_exists       BOOLEAN         DEFAULT TRUE;  -- ブール値
    ln_file_length  NUMBER          DEFAULT NULL;  -- ファイルの長さ
    ln_block_size   BINARY_INTEGER  DEFAULT NULL;  -- ブロックサイズ
    lv_null_prof    VARCHAR2(100)   DEFAULT NULL;  -- 取得失敗したプロフィール名
--
    -- ============
    -- ローカル例外
    -- ============
    prof_err_expt   EXCEPTION;  -- プロファイル取得エラー
    file_exist_expt EXCEPTION;  -- ファイル存在チェックエラー
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ==================================================
    -- 「コンカレント入力パラメータなしメッセージ」を出力
    -- ==================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appli_name_xxccp
                  , iv_name         =>  cv_msg_ccp1_90008
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_1
                  );
--
    -- ====================
    -- 2.システム日付を取得
    -- ====================
    gd_sysdate := SYSDATE;
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
    --==================================================
    -- 業務日付取得
    --==================================================
    gd_process_date := TRUNC( xxccp_common_pkg2.get_process_date );
    IF( gd_process_date IS NULL ) THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application          => cv_appli_name_xxcok
                    , iv_name                 => cv_msg_cok1_00028
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which                => FND_FILE.OUTPUT
                    , iv_message              => lv_out_msg
                    , in_new_line             => 0
                    );
      RAISE error_proc_expt;
    END IF;
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
--
    -- ====================
    -- 3.プロファイルの取得
    -- ====================
    gv_prof_company_code := FND_PROFILE.VALUE( cv_prof_company_code );  -- 会社コード
--
    IF( gv_prof_company_code IS NULL ) THEN
      lv_null_prof := cv_prof_company_code;
      RAISE prof_err_expt;
    END IF;
--
    gv_prof_dire_path := FND_PROFILE.VALUE( cv_prof_dire_path );        -- 売上実績データディレクトリパス
--
    IF( gv_prof_dire_path IS NULL ) THEN
      lv_null_prof := cv_prof_dire_path;
      RAISE prof_err_expt;
    END IF;
--
    gv_prof_file_name := FND_PROFILE.VALUE( cv_prof_file_name );        -- 売上実績データファイル名
--
    IF( gv_prof_file_name IS NULL ) THEN
      lv_null_prof := cv_prof_file_name;
      RAISE prof_err_expt;
    END IF;
--
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
    gv_prof_elec_change := FND_PROFILE.VALUE( cv_prof_elec_change );  -- 電気料（変動）品目コード
    IF( gv_prof_elec_change IS NULL ) THEN
      lv_null_prof := cv_prof_elec_change;
      RAISE prof_err_expt;
    END IF;
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
    -- =============================================================
    --4.プロファイル取得後、ディレクトリとファイル名をメッセージ出力
    --  空行を出力
    -- =============================================================
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appli_name_xxcok
                  , iv_name          =>  cv_msg_cok1_00067
                  , iv_token_name1   =>  cv_tkn_directory
                  , iv_token_value1  =>  xxcok_common_pkg.get_directory_path_f( gv_prof_dire_path )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appli_name_xxcok
                  , iv_name          =>  cv_msg_cok1_00006
                  , iv_token_name1   =>  cv_tkn_file_name
                  , iv_token_value1  =>  gv_prof_file_name
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_1
                  );
--
    -- ========================
    --5．ファイルの存在チェック
    -- ========================
    UTL_FILE.FGETATTR(
      location     =>  gv_prof_dire_path
    , filename     =>  gv_prof_file_name
    , fexists      =>  lb_exists
    , file_length  =>  ln_file_length
    , block_size   =>  ln_block_size
    );
--
    IF( lb_exists = TRUE ) THEN
      RAISE file_exist_expt;
--
    ELSE
    -- ===================
    --6.ファイルのオープン
    -- ===================
      g_file_handle := UTL_FILE.FOPEN(
                         location      =>  gv_prof_dire_path
                       , filename      =>  gv_prof_file_name
                       , open_mode     =>  cv_fopen_open_mode
                       , max_linesize  =>  cn_fopen_max_line
                       );
    END IF;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_retcode := lv_retcode;
--
  EXCEPTION
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
    -- *** エラー終了 ***
    WHEN error_proc_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
    --*** プロファイル取得エラー ***
    WHEN prof_err_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appli_name_xxcok
                    , iv_name         => cv_msg_cok1_00003
                    , iv_token_name1  => cv_tkn_profile
                    , iv_token_value1 => lv_null_prof
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    --*** ファイル存在チェックエラー ***
    WHEN file_exist_expt THEN
      lv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appli_name_xxcok
                    , iv_name          =>  cv_msg_cok1_00009
                    , iv_token_name1   =>  cv_tkn_file_name
                    , iv_token_value1  =>  gv_prof_file_name
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_out_msg
                    , in_new_line  =>  cn_number_0
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_out_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END init;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf   OUT VARCHAR2    -- エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    -- リターン・コード
  , ov_errmsg   OUT VARCHAR2 )  -- ユーザー・エラー・メッセージ
  IS
--
    -- ============
    -- ローカル定数
    -- ============
    cv_prg_name  CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf   VARCHAR2(5000)  DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode  VARCHAR2(1)     DEFAULT NULL;  -- リターン・コード
    lv_errmsg   VARCHAR2(5000)  DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lb_retcode  BOOLEAN         DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_retcode := cv_status_normal;
--
    -- ========
    -- 初期処理
    -- ========
    init(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- 売上実績振替情報抽出
    -- ====================
    get_selling_trns_info(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================
    -- 出力パラメータの設定
    -- ====================
    ov_errbuf  := lv_errbuf;
    ov_retcode := lv_retcode;
    ov_errmsg  := lv_errmsg;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf   OUT VARCHAR2  -- エラー・メッセージ
  , retcode  OUT VARCHAR2  -- リターン・コード
  )
  IS
    -- ================
    -- 固定ローカル定数
    -- ================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
--
    -- ============
    -- ローカル変数
    -- ============
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;  -- エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT NULL;  -- リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;  -- ユーザー・エラー・メッセージ
    lv_out_msg       VARCHAR2(2000) DEFAULT NULL;  -- メッセージ
    lv_message_code  VARCHAR2(5000) DEFAULT NULL;  -- 処理終了メッセージ
    lb_retcode       BOOLEAN        DEFAULT TRUE;  -- メッセージ出力ファンクション戻り値
--
  BEGIN
    -- ============
    -- 変数の初期化
    -- ============
    lv_out_msg := NULL;
--
    -- ==============================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- ==============================================
    xxccp_common_pkg.put_log_header(
      iv_which    =>  cv_tkn_output
    , ov_retcode  =>  lv_retcode
    , ov_errbuf   =>  lv_errbuf
    , ov_errmsg   =>  lv_errmsg
    );
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
--
    -- ==============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ==============================================
    submain(
      ov_errbuf   =>  lv_errbuf   -- エラー・メッセージ
    , ov_retcode  =>  lv_retcode  -- リターン・コード
    , ov_errmsg   =>  lv_errmsg   -- ユーザー・エラー・メッセージ
    );
--
    -- ==========
    -- エラー出力
    -- ==========
    IF( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.OUTPUT
                    , iv_message   =>  lv_errmsg
                    , in_new_line  =>  cn_number_1
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which     =>  FND_FILE.LOG
                    , iv_message   =>  lv_errbuf
                    , in_new_line  =>  cn_number_0
                    );
    END IF;
--
    -- ==================
    -- ファイルのクローズ
    -- ==================
    UTL_FILE.FCLOSE(
      file  =>  g_file_handle
    );
--
    -- ====================================
    -- エラーが発生した場合、処理件数を設定
    -- エラー処理件数：1件
    -- その他処理件数：0件
    -- ====================================
    IF( lv_retcode = cv_status_error ) THEN
      gn_error_cnt  := cn_count_1;
      gn_target_cnt := cn_count_0;
      gn_normal_cnt := cn_count_0;
    ELSIF( lv_retcode = cv_status_normal ) THEN
      gn_error_cnt  := cn_count_0;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      gn_error_cnt  := cn_count_0;
      gn_target_cnt := cn_count_0;
      gn_normal_cnt := cn_count_0;
    END IF;
--
    -- ===============================
    -- 警告処理時空行出力
    -- ===============================
    -- リターンコードが警告である場合は空行を出力する
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                       FND_FILE.OUTPUT
                      ,NULL
                      ,1
                    );
    END IF;
--
    --対象件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appli_name_xxccp
                    ,iv_name          =>  cv_msg_ccp1_90000
                    ,iv_token_name1   =>  cv_tkn_count
                    ,iv_token_value1  =>  TO_CHAR( gn_target_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which         =>  FND_FILE.OUTPUT
                    ,iv_message       =>  lv_out_msg
                    ,in_new_line      =>  cn_number_0
                  );
--
    --成功件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appli_name_xxccp
                    ,iv_name          =>  cv_msg_ccp1_90001
                    ,iv_token_name1   =>  cv_tkn_count
                    ,iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD START
    -- スキップ件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application           => cv_appli_name_xxccp
                  , iv_name                  => cv_msg_ccp1_90003
                  , iv_token_name1           => cv_tkn_count
                  , iv_token_value1          => TO_CHAR( gn_skip_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which                 => FND_FILE.OUTPUT
                  , iv_message               => lv_out_msg
                  , in_new_line              => 0
                  );
-- 2010/02/18 Ver.1.5 [障害E_本稼動_01600] SCS K.Yamaguchi ADD END
    --エラー件数出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application   =>  cv_appli_name_xxccp
                    ,iv_name          =>  cv_msg_ccp1_90002
                    ,iv_token_name1   =>  cv_tkn_count
                    ,iv_token_value1  =>  TO_CHAR( gn_error_cnt )
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
--
    --終了メッセージ
    IF( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_msg_ccp1_90004;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_msg_ccp1_90005;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_msg_ccp1_90006;
    END IF;
--
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appli_name_xxccp
                    ,iv_name         => lv_message_code
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which     =>  FND_FILE.OUTPUT
                  , iv_message   =>  lv_out_msg
                  , in_new_line  =>  cn_number_0
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END XXCOK010A01C;
/
