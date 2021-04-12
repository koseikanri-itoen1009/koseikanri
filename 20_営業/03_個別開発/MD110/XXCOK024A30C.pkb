CREATE OR REPLACE PACKAGE BODY      XXCOK024A30C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A30C(body)
 * Description      : 控除マスタIF出力（情報系）
 * MD.050           : 控除マスタIF出力（情報系） MD050_COK_024_A30
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            初期処理(A-1)
 *
 *  submain              メイン処理プロシージャ
 *                          ・proc_init
 *                       控除情報の取得(A-2)
 *                       控除マスタ（情報系）出力処理(A-3)
 *
 *  main                 コンカレント実行ファイル登録プロシージャ
 *                          ・submain
 *                       終了処理(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2020/12/18    1.0   R.Oikawa        main新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal               CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;  -- 正常:0
  cv_status_warn                 CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;    -- 警告:1
  cv_status_error                CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;   -- 異常:2
  --WHOカラム
  cn_created_by                  CONSTANT NUMBER      := fnd_global.user_id;            -- CREATED_BY
  cd_creation_date               CONSTANT DATE        := SYSDATE;                       -- CREATION_DATE
  cn_last_updated_by             CONSTANT NUMBER      := fnd_global.user_id;            -- LAST_UPDATED_BY
  cd_last_update_date            CONSTANT DATE        := SYSDATE;                       -- LAST_UPDATE_DATE
  cn_last_update_login           CONSTANT NUMBER      := fnd_global.login_id;           -- LAST_UPDATE_LOGIN
  cn_request_id                  CONSTANT NUMBER      := fnd_global.conc_request_id;    -- REQUEST_ID
  cn_program_application_id      CONSTANT NUMBER      := fnd_global.prog_appl_id;       -- PROGRAM_APPLICATION_ID
  cn_program_id                  CONSTANT NUMBER      := fnd_global.conc_program_id;    -- PROGRAM_ID
  cd_program_update_date         CONSTANT DATE        := SYSDATE;                       -- PROGRAM_UPDATE_DATE
  cv_msg_part                    CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                    CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                     VARCHAR2(2000);
  gv_sep_msg                     VARCHAR2(2000);
  gv_exec_user                   VARCHAR2(100);
  gv_conc_name                   VARCHAR2(30);
  gv_conc_status                 VARCHAR2(30);
  gn_target_cnt                  NUMBER;                    -- 対象件数
  gn_normal_cnt                  NUMBER;                    -- 正常件数
  gn_error_cnt                   NUMBER;                    -- エラー件数
  gn_warn_cnt                    NUMBER;                    -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt            EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt                EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt         EXCEPTION;
  global_check_lock_expt         EXCEPTION;                 -- ロック取得エラー
  --
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCOK024A30C';       -- パッケージ名
--
  cv_appl_name_xxcok             CONSTANT VARCHAR2(5)   := 'XXCOK';              -- アプリケーション短縮名
  -- メッセージ
  cv_msg_xxcok_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00001';   -- 対象データなし
  cv_msg_xxcok_00003             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00003';   -- プロファイル取得エラー
--
  cv_msg_xxcok_00006             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00006';   -- CSVファイル名ノート
--
  cv_msg_xxcok_00009             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-00009';   -- CSVファイル存在エラー
  cv_msg_xxcok_10787             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10787';   -- ファイルオープンエラー
  cv_msg_xxcok_10788             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10788';   -- ファイル書き込みエラー
  cv_msg_xxcok_10789             CONSTANT VARCHAR2(20)  := 'APP-XXCOK1-10789';   -- ファイルクローズエラー
  -- トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'PROFILE';            -- トークン：プロファイル名
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- トークン：SQLエラー
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- トークン：SQLエラー
--                                                                                 -- YYYYMMDD
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
  --
  cv_csv_fl_name                 CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_MASTER_FILE_NAME';
                                                                                 -- XXCOK:控除マスタファイル名
  cv_csv_fl_dir                  CONSTANT VARCHAR2(33)  := 'XXCOK1_DEDUCTION_MASTER_DIRE_PATH';
                                                                                 -- XXCOK:控除マスタディレクトリパス
  cv_dqu                         CONSTANT VARCHAR2(1)   := '"';
  cv_sep                         CONSTANT VARCHAR2(1)   := ',';
--
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- 会社コード
  cv_csv_mode                    CONSTANT VARCHAR2(1)   := 'w';                  -- csvファイルオープン時のモード
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_trans_date                  VARCHAR2(14);                                  -- 連携日付
  gv_csv_file_dir                VARCHAR2(1000);                                -- 控除マスタ（情報系）連携用CSVファイル出力先の取得
  gv_file_name                   VARCHAR2(30);                                  -- 控除マスタ（情報系）連携用CSVファイル名
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'proc_init';          -- プログラム名
--
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(100);                                    -- ステップ
    lv_message_token          VARCHAR2(100);                                    -- 連携日付
    lb_fexists                BOOLEAN;                                          -- ファイル存在判断
    ln_file_length            NUMBER;                                           -- ファイルの文字列数
    lbi_block_size            BINARY_INTEGER;                                   -- ブロックサイズ
    lv_csv_file               VARCHAR2(1000);                                   -- csvファイル名
    --
    -- *** ユーザー定義例外 ***
    profile_expt              EXCEPTION;                                        -- プロファイル取得例外
    csv_file_exst_expt        EXCEPTION;                                        -- CSVファイル存在エラー
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
    -- 連携日時の取得
    lv_step := 'A-1.1';
    lv_message_token := '連携日時の取得';
    gv_trans_date    := TO_CHAR( SYSDATE, cv_date_fmt_dt_ymdhms );
    --
    -- プロファイル取得
    lv_step := 'A-1.2';
    lv_message_token := '連携用CSVファイル名の取得';
    -- 控除マスタ（情報系）連携用CSVファイル名の取得
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- 取得エラー時
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_csv_fl_name;
      RAISE profile_expt;
    END IF;
    --
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- アップロード名称の出力
                    iv_application  => cv_appl_name_xxcok                       -- アプリケーション短縮名
                   ,iv_name         => cv_msg_xxcok_00006                       -- メッセージコード
                   ,iv_token_name1  => cv_tkn_file_name                         -- トークンコード1
                   ,iv_token_value1 => gv_file_name                             -- トークン値1
                  );
    -- ファイル名出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff => lv_csv_file
     ,ov_errbuf       => lv_errbuf
     ,ov_retcode      => lv_retcode
     ,ov_errmsg       => lv_errmsg
    );
    --
    lv_step := 'A-1.2';
    lv_message_token := '連携用CSVファイル出力先の取得';
    -- 控除マスタ（情報系）連携用CSVファイル出力先の取得
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- 取得エラー時
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_csv_fl_dir;
      RAISE profile_expt;
    END IF;
    --
    lv_step := 'A-1.3';
    lv_message_token := 'CSVファイル存在チェック';
    --
    -- CSVファイル存在チェック
    UTL_FILE.FGETATTR(
       location    => gv_csv_file_dir
      ,filename    => gv_file_name
      ,fexists     => lb_fexists
      ,file_length => ln_file_length
      ,block_size  => lbi_block_size
    );
    -- ファイル存在時
    IF ( lb_fexists = TRUE ) THEN
      RAISE csv_file_exst_expt;
    END IF;
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- カーソルのクローズをここに記述する
    --*** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_00003            -- メッセージ：APP-XXCOK1-00003 プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_profile                -- トークン：PROFILE
                     ,iv_token_value1 => lv_message_token              -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** CSVファイル存在エラー ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok            -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_00009            -- メッセージ：APP-XXCOK1-00009 CSVファイル存在エラー
                     ,iv_token_name1  => cv_tkn_file_name              -- トークン：FILE_NAME
                     ,iv_token_value1 => gv_file_name                  -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf      OUT    VARCHAR2         --   エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT    VARCHAR2         --   リターン・コード             --# 固定 #
   ,ov_errmsg      OUT    VARCHAR2         --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';            -- プログラム名
    -- ===============================
    -- 固定ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                  -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザーローカル変数
    -- ===============================
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM退避
    lf_file_hand              UTL_FILE.FILE_TYPE;                             -- ファイル・ハンドルの宣言
    lv_message_token          VARCHAR2(100);                                  -- 連携日付
    lv_out_csv_line           VARCHAR2(1000);                                 -- 出力行
    --
    -- 控除マスタ（情報系）情報カーソル
    --lv_step := 'A-2';
    CURSOR csv_condition_cur
    IS
      SELECT xch.condition_id                   condition_id,                 -- 控除条件ID
             xch.condition_no                   condition_no,                 -- 控除番号
             xch.enabled_flag_h                 enabled_flag_h,               -- 有効フラグ
             xch.corp_code                      corp_code,                    -- 企業コード
             xch.deduction_chain_code           deduction_chain_code,         -- 控除用チェーンコード
             xch.customer_code                  customer_code,                -- 顧客コード
-- 2021/04/02 MOD Start
             ffvv.attribute2 
                || flv2.attribute3 
                || xca.sale_base_code           base_code,                    -- 拠点
-- 2021/04/02 MOD End
             xch.data_type                      data_type,                    -- データ種類
             flv.meaning                        data_type_name,               -- データ種類名
             xch.tax_code                       tax_code,                     -- 税コード
             xch.tax_rate                       tax_rate,                     -- 税率
             TO_CHAR( xch.start_date_active, cv_date_fmt_ymd )
                                                start_date_active,            -- 開始日
             TO_CHAR( xch.end_date_active, cv_date_fmt_ymd )
                                                end_date_active,              -- 終了日
-- 2021/03/03 ADD Start
             xch.content                        content ,                     -- 内容
-- 2021/03/03 ADD End
             xch.decision_no                    decision_no,                  -- 決裁No
             xch.agreement_no                   agreement_no,                 -- 契約番号
             xch.header_recovery_flag           header_recovery_flag,         -- リカバリ対象フラグ
             xcl.condition_line_id              condition_line_id,            -- 控除詳細ID
             xcl.detail_number                  detail_number,                -- 明細番号
             xcl.enabled_flag_l                 enabled_flag_l,               -- 有効フラグ(明細)
             xcl.target_category                target_category,              -- 対象区分
             xcl.product_class                  product_class,                -- 商品区分
             xcl.item_code                      item_code,                    -- 品目コード
             xcl.uom_code                       uom_code,                     -- 単位
             xcl.line_recovery_flag             line_recovery_flag,           -- リカバリ対象フラグ(明細)
             xcl.shop_pay_1                     shop_pay_1,                   -- 店納(％)
             xcl.material_rate_1                material_rate_1,              -- 料率(％)
             xcl.condition_unit_price_en_2      condition_unit_price_en_2,    -- 条件単価２(円)
             xcl.demand_en_3                    demand_en_3,                  -- 請求(円)
             xcl.shop_pay_en_3                  shop_pay_en_3,                -- 店納(円)
             xcl.compensation_en_3              compensation_en_3,            -- 補填(円)
             xcl.wholesale_margin_en_3          wholesale_margin_en_3,        -- 問屋マージン(円)
             xcl.wholesale_margin_per_3         wholesale_margin_per_3,       -- 問屋マージン(％)
             xcl.accrued_en_3                   accrued_en_3,                 -- 未収計３(円)
             xcl.normal_shop_pay_en_4           normal_shop_pay_en_4,         -- 通常店納(円)
             xcl.just_shop_pay_en_4             just_shop_pay_en_4,           -- 今回店納(円)
             xcl.just_condition_en_4            just_condition_en_4,          -- 今回条件(円)
             xcl.wholesale_adj_margin_en_4      wholesale_adj_margin_en_4,    -- 問屋マージン修正(円)
             xcl.wholesale_adj_margin_per_4     wholesale_adj_margin_per_4,   -- 問屋マージン修正(％)
             xcl.accrued_en_4                   accrued_en_4,                 -- 未収計４(円)
             xcl.prediction_qty_5               prediction_qty_5,             -- 予測数量５(本)
             xcl.ratio_per_5                    ratio_per_5,                  -- 比率(％)
             xcl.amount_prorated_en_5           amount_prorated_en_5,         -- 金額按分(円)
             xcl.condition_unit_price_en_5      condition_unit_price_en_5,    -- 条件単価５(円)
             xcl.support_amount_sum_en_5        support_amount_sum_en_5,      -- 協賛金合計(円)
             xcl.prediction_qty_6               prediction_qty_6,             -- 予測数量６(本)
             xcl.condition_unit_price_en_6      condition_unit_price_en_6,    -- 条件単価６(円)
             xcl.target_rate_6                  target_rate_6,                -- 対象率(％)
             xcl.deduction_unit_price_en_6      deduction_unit_price_en_6,    -- 控除単価(円)
-- 2021/03/01 MOD Start
--             xcl.accounting_base                accounting_base,              -- 計上拠点
             xcl.accounting_customer_code       accounting_customer_code,     -- 計上顧客
-- 2021/03/01 MOD End
             xcl.deduction_amount               deduction_amount,             -- 控除額(本体)
             xcl.deduction_tax_amount           deduction_tax_amount,         -- 控除税額
             xcl.dl_wholesale_margin_en         dl_wholesale_margin_en,       -- DL用問屋マージン(円)
             xcl.dl_wholesale_margin_per        dl_wholesale_margin_per,      -- DL用問屋マージン(％)
             xcl.dl_wholesale_adj_margin_en     dl_wholesale_adj_margin_en,   -- DL用問屋マージン修正(円)
             xcl.dl_wholesale_adj_margin_per    dl_wholesale_adj_margin_per,  -- DL用問屋マージン修正(％)
             fu1.user_name                      create_user_name,             -- 作成者
             TO_CHAR( xcl.creation_date, cv_date_fmt_ymd )
                                                creation_date,                -- 作成日
             fu2.user_name                      last_updated_user_name,       -- 最終更新者
             TO_CHAR( xcl.last_update_date, cv_date_fmt_ymd )
                                                last_update_date              -- 最終更新日
      FROM   xxcok_condition_header xch, -- 控除条件テーブル
             xxcok_condition_lines  xcl, -- 控除詳細テーブル
             fnd_user fu1,               -- ユーザーマスタ
             fnd_user fu2,               -- ユーザーマスタ
             fnd_lookup_values      flv, -- データ種類
-- 2021/04/02 MOD Start
             fnd_lookup_values      flv2,-- チェーンコード
             fnd_flex_values_vl     ffvv, -- 企業
             xxcmm_cust_accounts    xca  -- 顧客
-- 2021/04/02 MOD End
      WHERE  xch.condition_id    = xcl.condition_id
      AND    xcl.created_by      = fu1.user_id(+)
      AND    xcl.last_updated_by = fu2.user_id(+)
      AND    flv.lookup_type(+)  = 'XXCOK1_DEDUCTION_DATA_TYPE'
      AND    flv.lookup_code(+)  = xch.data_type
      AND    flv.language(+)     = 'JA'
--      AND    flv.enabled_flag(+) = 'Y'
-- 2021/04/02 MOD Start
      AND    flv2.lookup_type(+)  = 'XXCMM_CHAIN_CODE'
      AND    flv2.lookup_code(+)  = xch.deduction_chain_code
      AND    flv2.language(+)     = 'JA'
      AND    ffvv.flex_value(+)   = xch.corp_code
      AND    ffvv.value_category(+) = 'XX03_BUSINESS_TYPE'
      AND    xca.customer_code(+) = xch.customer_code
-- 2021/04/02 MOD End
      ORDER BY xch.condition_id, xcl.condition_line_id
      ;
--
    TYPE csv_condition_ttype IS TABLE OF csv_condition_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_csv_condition_tab       csv_condition_ttype;               -- 控除条件IF出力データ
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    subproc_expt              EXCEPTION;       -- サブプログラムエラー
    file_open_expt            EXCEPTION;       -- ファイルオープンエラー
    file_output_expt          EXCEPTION;       -- ファイル書き込みエラー
    file_close_expt           EXCEPTION;       -- ファイルクローズエラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    -- ===============================================
    -- proc_initの呼び出し（初期処理はproc_initで行う）
    -- ===============================================
    proc_init(
       ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE subproc_expt;
    END IF;
    --
    -----------------------------------
    -- A-2.控除条件情報の取得
    -----------------------------------
    lv_step := 'A-2';
--
    OPEN  csv_condition_cur;
    FETCH csv_condition_cur BULK COLLECT INTO lt_csv_condition_tab;
    CLOSE csv_condition_cur;
    -- 処理件数カウント
    gn_target_cnt := lt_csv_condition_tab.COUNT;
--
    -----------------------------------------------
    -- A-3.控除マスタ（情報系）出力処理
    -----------------------------------------------
    lv_step := 'A-3.1a';
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象データなし
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok
                     ,iv_name         => cv_msg_xxcok_00001
                     );
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
    ELSE
      -- CSVファイルオープン
      lv_step := 'A-1.5';
      BEGIN
        lf_file_hand := UTL_FILE.FOPEN(  location  => gv_csv_file_dir  -- 出力先
                                        ,filename  => gv_file_name     -- CSVファイル名
                                        ,open_mode => cv_csv_mode      -- モード
                                       );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_open_expt;
      END;
      -- ファイル出力
      lv_step := 'A-3.1b';
      <<out_csv_loop>>
      FOR i IN 1..lt_csv_condition_tab.COUNT LOOP
        --
        lv_out_csv_line := '';
        -- 会社コード
        lv_step := 'A-3.company_code';
        lv_out_csv_line := cv_dqu ||
                           cv_company_code ||
                           cv_dqu;
        -- 控除条件ID
        lv_step := 'A-3.condition_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).condition_id;
        -- 控除番号
        lv_step := 'A-3.condition_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).condition_no ||
                           cv_dqu;
        -- 有効フラグ
        lv_step := 'A-3.enabled_flag_h';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).enabled_flag_h ||
                           cv_dqu;
        -- 企業コード
        lv_step := 'A-3.corp_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).corp_code ||
                           cv_dqu;
        -- 控除用チェーンコード
        lv_step := 'A-3.deduction_chain_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).deduction_chain_code ||
                           cv_dqu;
        -- 顧客コード
        lv_step := 'A-3.customer_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).customer_code ||
                           cv_dqu;
-- 2021/04/02 MOD Start
        lv_step := 'A-3.base_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).base_code ||
                           cv_dqu;
-- 2021/04/02 MOD End
        -- データ種類
        lv_step := 'A-3.data_type_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).data_type_name ||
                           cv_dqu;
        -- 税コード
        lv_step := 'A-3.tax_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).tax_code ||
                           cv_dqu;
        -- 税率
        lv_step := 'A-3.tax_rate';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).tax_rate;
        -- 開始日【YYYYMMDD】
        lv_step := 'A-3.start_date_active';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).start_date_active;
        -- 終了日【YYYYMMDD】
        lv_step := 'A-3.end_date_active';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_condition_tab( i ).end_date_active;
-- 2021/03/03 ADD Start
        -- 内容
        lv_step := 'A-3.content';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).content ||
                           cv_dqu;
-- 2021/03/03 ADD End
        -- 決裁No
        lv_step := 'A-3.decision_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).decision_no ||
                           cv_dqu;
        -- 契約番号
        lv_step := 'A-3.agreement_no';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).agreement_no ||
                           cv_dqu;
        -- リカバリ対象フラグ
        lv_step := 'A-3.header_recovery_flag';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).header_recovery_flag ||
                           cv_dqu;
        -- 控除詳細ID
        lv_step := 'A-3.condition_line_id';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_line_id;
        -- 明細番号
        lv_step := 'A-3.detail_number';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).detail_number;
        -- 有効フラグ(明細)
        lv_step := 'A-3.enabled_flag_l';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).enabled_flag_l ||
                           cv_dqu;
        -- 対象区分
        lv_step := 'A-3.target_category';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).target_category ||
                           cv_dqu;
        -- 商品区分
        lv_step := 'A-3.product_class';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).product_class ||
                           cv_dqu;
        -- 品目コード
        lv_step := 'A-3.item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).item_code ||
                           cv_dqu;
        -- 単位
        lv_step := 'A-3.uom_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).uom_code ||
                           cv_dqu;
        -- リカバリ対象フラグ(明細)
        lv_step := 'A-3.line_recovery_flag';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).line_recovery_flag ||
                           cv_dqu;
        -- 店納(％)
        lv_step := 'A-3.shop_pay_1';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).shop_pay_1;
        -- 料率(％)
        lv_step := 'A-3.material_rate_1';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).material_rate_1;
        -- 条件単価２(円)
        lv_step := 'A-3.condition_unit_price_en_2';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_unit_price_en_2;
        -- 請求(円)
        lv_step := 'A-3.demand_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).demand_en_3;
        -- 店納(円)
        lv_step := 'A-3.shop_pay_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).shop_pay_en_3;
        -- 補填(円)
        lv_step := 'A-3.compensation_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).compensation_en_3;
        -- 問屋マージン(円)
        lv_step := 'A-3.wholesale_margin_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_margin_en_3;
        -- 問屋マージン(％)
        lv_step := 'A-3.wholesale_margin_per_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_margin_per_3;
        -- 未収計３(円)
        lv_step := 'A-3.accrued_en_3';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).accrued_en_3;
        -- 通常店納(円)
        lv_step := 'A-3.normal_shop_pay_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).normal_shop_pay_en_4;
        -- 今回店納(円)
        lv_step := 'A-3.just_shop_pay_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).just_shop_pay_en_4;
        -- 今回条件(円)
        lv_step := 'A-3.just_condition_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).just_condition_en_4;
        -- 問屋マージン修正(円)
        lv_step := 'A-3.wholesale_adj_margin_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_adj_margin_en_4;
        -- 問屋マージン修正(％)
        lv_step := 'A-3.wholesale_adj_margin_per_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).wholesale_adj_margin_per_4;
        -- 未収計４(円)
        lv_step := 'A-3.accrued_en_4';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).accrued_en_4;
        -- 予測数量５(本)
        lv_step := 'A-3.prediction_qty_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).prediction_qty_5;
        -- 比率(％)
        lv_step := 'A-3.ratio_per_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).ratio_per_5;
        -- 金額按分(円)
        lv_step := 'A-3.amount_prorated_en_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).amount_prorated_en_5;
        -- 条件単価５(円)
        lv_step := 'A-3.condition_unit_price_en_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_unit_price_en_5;
        -- 協賛金合計(円)
        lv_step := 'A-3.support_amount_sum_en_5';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).support_amount_sum_en_5;
        -- 予測数量６(本)
        lv_step := 'A-3.prediction_qty_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).prediction_qty_6;
        -- 条件単価６(円)
        lv_step := 'A-3.condition_unit_price_en_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).condition_unit_price_en_6;
        -- 対象率(％)
        lv_step := 'A-3.target_rate_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).target_rate_6;
        -- 控除単価(円)
        lv_step := 'A-3.deduction_unit_price_en_6';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).deduction_unit_price_en_6;
        -- 計上拠点
-- 2021/03/01 MOD Start
--        lv_step := 'A-3.accounting_base';
        lv_step := 'A-3.accounting_customer_code';
-- 2021/03/01 MOD End
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
-- 2021/03/01 MOD Start
--                           lt_csv_condition_tab( i ).accounting_base ||
                           lt_csv_condition_tab( i ).accounting_customer_code ||
-- 2021/03/01 MOD End
                           cv_dqu;
        -- 控除額(本体)
        lv_step := 'A-3.deduction_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).deduction_amount;
        -- 控除税額
        lv_step := 'A-3.deduction_tax_amount';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).deduction_tax_amount;
        -- DL用問屋マージン(円)
        lv_step := 'A-3.dl_wholesale_margin_en';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_margin_en;
        -- DL用問屋マージン(％)
        lv_step := 'A-3.dl_wholesale_margin_per';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_margin_per;
        -- DL用問屋マージン修正(円)
        lv_step := 'A-3.dl_wholesale_adj_margin_en';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_adj_margin_en;
        -- DL用問屋マージン修正(％)
        lv_step := 'A-3.dl_wholesale_adj_margin_per';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).dl_wholesale_adj_margin_per;
        -- 作成者
        lv_step := 'A-3.create_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).create_user_name ||
                           cv_dqu;
        --作成日
        lv_step := 'A-3.creation_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).creation_date;
        -- 最終更新者
        lv_step := 'A-3.last_updated_user_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_condition_tab( i ).last_updated_user_name ||
                           cv_dqu;
        --最終更新日
        lv_step := 'A-3.last_update_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_condition_tab( i ).last_update_date;
        -- 連携日時【YYYYMMDDHH24MISS】
        lv_step := 'A-3.gv_trans_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           gv_trans_date;
        --
        --=================
        -- CSVファイル出力
        --=================
        lv_step := 'A-3.1c';
        BEGIN
          UTL_FILE.PUT_LINE( lf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
            lv_sqlerrm := SQLERRM;
            RAISE file_output_expt;
        END;
        --
        -- 成功件数
        gn_normal_cnt := gn_normal_cnt + 1;
        --
      END LOOP out_csv_loop;
      --
      -----------------------------------------------
      -- A-4.終了処理
      -----------------------------------------------
      -- ファイルクローズ
      lv_step := 'A-4.1';
      --
      --ファイルクローズ失敗
      BEGIN
        UTL_FILE.FCLOSE( lf_file_hand );
      EXCEPTION
        WHEN OTHERS THEN
          lv_sqlerrm := SQLERRM;
          RAISE file_close_expt;
      END;
      --
    END IF;
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    -- *** サブプログラム例外ハンドラ ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    --*** ファイルオープンエラー ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_10787             -- メッセージ：APP-XXCOK1-10787 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** ファイル書き込みエラー ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_10788             -- メッセージ：APP-XXCOK1-10788 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
    --*** ファイルクローズエラー ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcok             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcok_10789             -- メッセージ：APP-XXCOK1-10789 ファイルクローズエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数出力
      gn_error_cnt := gn_target_cnt;
      ov_errbuf    := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode   := cv_status_error;
--
--####################################  固定部 END   ###################s#######################
--
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  --
  PROCEDURE main(
    errbuf         OUT    VARCHAR2         --   エラーメッセージ #固定#
   ,retcode        OUT    VARCHAR2         --   エラーコード     #固定#
  )
  IS
  --
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';               -- プログラム名
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                -- ログ
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';             -- アウトプット
    cv_app_name_xxccp         CONSTANT VARCHAR2(100) := 'XXCCP';              -- アプリケーション短縮名
    cv_target_cnt_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
    cv_success_cnt_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
    cv_error_cnt_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
    cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- 正常終了メッセージ
    cv_warn_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- 警告終了メッセージ
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-10008';   -- エラー終了メッセージ
    cv_token_name1            CONSTANT VARCHAR2(100) := 'COUNT';              -- 処理件数
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(10);                                   -- ステップ
    lv_message_code           VARCHAR2(100);                                  -- メッセージコード
    --
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    IF ( lv_retcode <> cv_status_normal ) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザーエラーメッセージ
      );
      --
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_target_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_success_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_error_cnt_msg
                    ,iv_token_name1  => cv_token_name1
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
  --
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCOK024A30C;
/
