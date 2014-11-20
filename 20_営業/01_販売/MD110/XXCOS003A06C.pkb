CREATE OR REPLACE PACKAGE BODY APPS.XXCOS003A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS003A06C (body)
 * Description      : 販売予測情報更新
 * MD.050           : 販売予測情報更新 MD050_COS_003_A06
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_xxcos_vd_deliv     ベンダ納品実績データ抽出(A-2)
 *  update_mst_vd_column   VDコラムマスタ更新(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2011/09/26    1.0   K.Nakamura       新規作成
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
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
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
  gn_normal_cnt    NUMBER;                    -- 更新件数
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
  -- ロック例外
  lock_expt                 EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
  -- 警告時例外
  warn_expt                 EXCEPTION;
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCOS003A06C';    -- パッケージ名
  cv_application            CONSTANT VARCHAR2(10)  := 'XXCOS';           -- アプリケーション名(販売)
  cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';           -- アドオン：共通・IF領域
  -- メッセージ
  cv_msg_no_data_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00003'; -- 対象データ無しエラー
  cv_msg_profile_err        CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00004'; -- プロファイル取得エラ
  cv_msg_org_id_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00091'; -- 在庫組織ID取得エラー
  cv_msg_update_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00011'; -- データ更新エラーメッセージ
  cv_msg_process_date_err   CONSTANT VARCHAR2(20) := 'APP-XXCOS1-00014'; -- 業務処理日取得エラー
  cv_msg_lookup_err         CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14255'; -- 販売予測対象顧客ステータス取得エラーメッセージ
  cv_msg_lock_err           CONSTANT VARCHAR2(20) := 'APP-XXCOS1-14256'; -- VDコラムマスタロック取得エラーメッセージ
  cv_msg_no_param           CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008'; -- コンカレント入力パラメータなし
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(20) := 'PROFILE';          -- プロファイル名
  cv_tkn_org_code_tok       CONSTANT VARCHAR2(20) := 'ORG_CODE_TOK';     -- 在庫組織コード
  cv_tkn_lookup_type        CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE';      -- タイプ名
  cv_tkn_table_name         CONSTANT VARCHAR2(20) := 'TABLE_NAME';       -- テーブル名
  cv_tkn_key_data           CONSTANT VARCHAR2(20) := 'KEY_DATA';         -- キー項目
  -- プロファイル
  cv_organization_code      CONSTANT VARCHAR2(30) := 'XXCOI1_ORGANIZATION_CODE';      -- 在庫組織コード
  -- 参照コード
  cv_lookup_cust_status     CONSTANT VARCHAR2(30) := 'XXCOS1_FORECAST_CUST_STATUS';   -- 販売予測対象顧客ステータス
  cv_lookup_type_gyotai     CONSTANT VARCHAR2(30) := 'XXCOS1_GYOTAI_SHO_MST_003_A03'; -- 業態（小分類）
  -- メッセージ出力文字
  cv_profile_org_code       CONSTANT VARCHAR2(30) := 'XXCOI:在庫組織コード'; -- プロファイル名
  cv_xxcoi_mst_cd_column    CONSTANT VARCHAR2(20) := 'VDコラムマスタ';       -- テーブル名
  cv_customer_code          CONSTANT VARCHAR2(20) := '顧客コード';           -- 項目名
  cv_column_no              CONSTANT VARCHAR2(20) := 'コラムNo';             -- 項目名
  -- フラグ
  cv_flag_on                CONSTANT VARCHAR2(1)  := 'Y'; -- 有効フラグ
  cv_forecast_use_flag      CONSTANT VARCHAR2(1)  := 'Y'; -- 販売予測利用フラグ
  -- 言語
  ct_language               CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG'); -- 言語
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- VDコラムマスタ更新情報格納用
  TYPE g_update_rtype IS RECORD
    (
       rownumber            NUMBER,                                      -- 順序
       customer_number      xxcos_vd_deliv_headers.customer_number%TYPE, -- 顧客コード
       customer_id          xxcoi_mst_vd_column.customer_id%TYPE,        -- 顧客ID
       column_no            xxcoi_mst_vd_column.column_no%TYPE,          -- コラムNo
       dlv_date_1           xxcoi_mst_vd_column.dlv_date_1%TYPE,         -- 納品日1
       quantity_1           xxcoi_mst_vd_column.quantity_1%TYPE,         -- 本数1
       dlv_date_2           xxcoi_mst_vd_column.dlv_date_2%TYPE,         -- 納品日2
       quantity_2           xxcoi_mst_vd_column.quantity_2%TYPE,         -- 本数2
       dlv_date_3           xxcoi_mst_vd_column.dlv_date_3%TYPE,         -- 納品日3
       quantity_3           xxcoi_mst_vd_column.quantity_3%TYPE,         -- 本数3
       dlv_date_4           xxcoi_mst_vd_column.dlv_date_4%TYPE,         -- 納品日4
       quantity_4           xxcoi_mst_vd_column.quantity_4%TYPE,         -- 本数4
       dlv_date_5           xxcoi_mst_vd_column.dlv_date_5%TYPE,         -- 納品日5
       quantity_5           xxcoi_mst_vd_column.quantity_5%TYPE          -- 本数5
    );
  TYPE g_update_ttype IS TABLE OF g_update_rtype INDEX BY PLS_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_organization_code      mtl_parameters.organization_code%TYPE; -- 在庫組織コード
  gv_organization_id        mtl_parameters.organization_id%TYPE;   -- 在庫組織ID
  gv_key_info               fnd_new_messages.message_text%TYPE;    -- メッセージ出力用キー情報
  gd_process_date           DATE         DEFAULT NULL;             -- 業務日付
  gn_init_warn_cnt          NUMBER;                                -- 警告件数
  g_update_tab              g_update_ttype;                        -- VDコラムマスタ更新情報
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    ln_lookup_code_cnt               NUMBER DEFAULT 0; -- 販売予測対象顧客ステータス取得
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
    -- 「コンカレント入力パラメータなし」メッセージを出力
    --==============================================================
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application => cv_appl_short_name
                    ,iv_name        => cv_msg_no_param
                  );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
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
    --==============================================================
    -- 業務処理日を取得
    --==============================================================
    gd_process_date := TRUNC(xxccp_common_pkg2.get_process_date);
    -- 業務処理日取得エラーの場合
    IF ( gd_process_date IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application => cv_application
                     ,iv_name        => cv_msg_process_date_err
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- プロファイルの取得(在庫組織コード)
    --==============================================================
    gv_organization_code := FND_PROFILE.VALUE(cv_organization_code);
    -- プロファイル取得エラーの場合
    IF ( gv_organization_code IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_profile_err
                     ,iv_token_name1  => cv_tkn_profile
                     ,iv_token_value1 => cv_profile_org_code
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- 在庫組織コードより在庫組織IDを導出
    --==============================================================
    gv_organization_id := xxcoi_common_pkg.get_organization_id(gv_organization_code);
    -- 在庫組織ID取得エラーの場合
    IF ( gv_organization_id IS NULL ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_org_id_err
                     ,iv_token_name1  => cv_tkn_org_code_tok
                     ,iv_token_value1 => gv_organization_code
                   );
      RAISE warn_expt;
    END IF;
--
    --==============================================================
    -- 販売予測対象顧客ステータス取得
    --==============================================================
    SELECT COUNT(flv.lookup_code) lookup_code -- 件数
    INTO   ln_lookup_code_cnt
    FROM   fnd_lookup_values      flv
    WHERE  flv.lookup_type  = cv_lookup_cust_status
    AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                               AND NVL(flv.end_date_active, gd_process_date)
    AND    flv.enabled_flag = cv_flag_on
    AND    flv.language     = ct_language
    ;
    -- 販売予測対象顧客ステータスが存在しない場合
    IF ( ln_lookup_code_cnt = 0 ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_lookup_err
                     ,iv_token_name1  => cv_tkn_lookup_type
                     ,iv_token_value1 => cv_lookup_cust_status
                   );
      RAISE warn_expt;
    END IF;
--
  EXCEPTION
    -- *** 初期処理警告時例外ハンドラ ***
    WHEN warn_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||ov_errmsg,1,5000);
      ov_retcode := cv_status_warn;
      -- 警告件数カウントアップ
      gn_init_warn_cnt := 1;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
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
   * Procedure Name   : get_xxcos_vd_deliv
   * Description      : ベンダ納品実績データ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_xxcos_vd_deliv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xxcos_vd_deliv'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    cv_blank_column_code    CONSTANT VARCHAR2(7) := 'BLANK_C'; -- ブランクコラム用ダミー品目（ベンダ納品実績のみで使用される）
    cv_dummy_char           CONSTANT VARCHAR2(1) := 'X';       -- ダミー文字
    cv_rownumber_min        CONSTANT NUMBER      := 1;         -- 取得レコード最小値
    cv_rownumber_max        CONSTANT NUMBER      := 5;         -- 取得レコード最大値
    cv_record_1             CONSTANT NUMBER      := 1;         -- レコード1判定
    cv_record_2             CONSTANT NUMBER      := 2;         -- レコード2判定
    cv_record_3             CONSTANT NUMBER      := 3;         -- レコード3判定
    cv_record_4             CONSTANT NUMBER      := 4;         -- レコード4判定
    cv_record_5             CONSTANT NUMBER      := 5;         -- レコード5判定
--
    -- *** ローカル変数 ***
    lv_segment1                      VARCHAR2(7) DEFAULT NULL;  -- マスタ品目コード用変数
    lv_hot_cold                      VARCHAR2(1) DEFAULT NULL;  -- マスタH/C用変数
    ln_recode_cnt                    NUMBER      DEFAULT 1;     -- 格納（納品日1～5、本数1～5）判定用変数
    ln_vd_column_cnt                 NUMBER      DEFAULT 1;     -- PL/SQL表のレコード用変数
    lb_same_record_flag              BOOLEAN     DEFAULT FALSE; -- 一致レコード判定フラグ
    lb_column_change_flag            BOOLEAN     DEFAULT FALSE; -- コラム変更判定フラグ
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ベンダ納品実績カーソル
    CURSOR xxcos_vd_deliv_cur
    IS
      SELECT xvdhv.customer_number   customer_number    -- 顧客コード
           , xvdhv.customer_id       customer_id        -- 顧客ID
           , xvdhv.dlv_date          dlv_date           -- 納品日
           , xvdl.column_num         column_num         -- コラムNo
           , xvdl.sales_qty          sales_qty          -- 売上数
           , xvdl.item_code          item_code          -- 品目コード(納品実績)
           , xvdl.hot_cold_type      hot_cold_type      -- H/C(納品実績)
           , msib.segment1           segment1           -- 品目コード(マスタ)
           , xmvc.hot_cold           hot_cold           -- H/C(マスタ)
           , xmvc.column_change_date column_change_date -- コラム変更日
           , xvdhv.rownumber         rownumber          -- 順番
      FROM 
             (
               SELECT /*+ LEADING(flv xca xvdh) USE_NL(flv xca xvdh) */
                      xca.customer_id        customer_id                     -- 顧客ID
                    , xvdh.customer_number   customer_number                 -- 顧客コード
                    , xvdh.dlv_date          dlv_date                        -- 納品日
                    , ROW_NUMBER() OVER (PARTITION BY xvdh.customer_number ORDER BY xvdh.dlv_date DESC)
                                             rownumber                       -- 顧客ごとに納品日でソートして順番付け
               FROM   xxcos_vd_deliv_headers xvdh                            -- ベンダ納品実績ヘッダ
                    , hz_parties             hp                              -- パーティマスタ
                    , hz_cust_accounts       hca                             -- 顧客マスタ
                    , xxcmm_cust_accounts    xca                             -- 顧客追加情報
                    , fnd_lookup_values      flv                             -- クイックコード
                    , fnd_lookup_values      flv2                            -- クイックコード
               WHERE  xvdh.customer_number   = xca.customer_code             -- 顧客コード
               AND    xca.customer_id        = hca.cust_account_id           -- 顧客ID
               AND    hca.party_id           = hp.party_id                   -- パーティID
               AND    xca.business_low_type  = flv.meaning                   -- 業態（小分類）
               AND    flv.lookup_type        = cv_lookup_type_gyotai         -- タイプ
               AND    gd_process_date BETWEEN NVL(flv.start_date_active, gd_process_date)
                                          AND NVL(flv.end_date_active, gd_process_date)
                                                                             -- 有効日
               AND    flv.enabled_flag       = cv_flag_on                    -- 有効フラグ
               AND    flv.language           = ct_language                   -- 言語
               AND    flv2.lookup_code       = hp.duns_number_c              -- 顧客ステータス
               AND    flv2.lookup_type       = cv_lookup_cust_status         -- タイプ
               AND    gd_process_date BETWEEN NVL(flv2.start_date_active, gd_process_date)
                                          AND NVL(flv2.end_date_active, gd_process_date)
                                                                             -- 有効日
               AND    flv2.enabled_flag      = cv_flag_on                    -- 有効フラグ
               AND    flv2.language          = ct_language                   -- 言語
               AND EXISTS (
                            SELECT /*+ USE_NL(xvdhv) */
                                   cv_dummy_char           dummy_char
                            FROM   xxcos_vd_deliv_headers  xvdhv                  -- ベンダ納品実績ヘッダ
                            WHERE  xvdhv.customer_number   = xvdh.customer_number -- 顧客コード
                            AND    xvdhv.last_update_date >= gd_process_date      -- 最終更新日
                          )
               AND EXISTS (
                            SELECT cv_dummy_char      dummy_char
                            FROM   bom_calendars      bc                     -- 稼働日カレンダ
                                 , bom_calendar_dates bcd                    -- 稼動日カレンダ日付
                            WHERE  bc.calendar_code   = bcd.calendar_code    -- カレンダコード
                            AND    bc.calendar_code   = xca.calendar_code    -- 稼働日カレンダコード
                            AND    bcd.calendar_date  = xvdh.dlv_date        -- カレンダ日付
                            AND    bc.attribute1      = cv_forecast_use_flag -- 販売予測利用フラグ（販売予測カレンダ）
                            AND    bcd.seq_num   IS NOT NULL                 -- 順番（非稼動日を除外）
                          )
             )                         xvdhv                                 -- ベンダ納品実績ヘッダの対象絞込みサブクエリー
           , xxcos_vd_deliv_lines      xvdl                                  -- ベンダ納品実績明細
           , xxcoi_mst_vd_column       xmvc                                  -- VDコラムマスタ
           , mtl_system_items_b        msib                                  -- 品目マスタ
      WHERE  xvdhv.customer_number     = xvdl.customer_number                -- 顧客コード
      AND    xvdhv.dlv_date            = xvdl.dlv_date                       -- 納品日
      AND    xvdhv.rownumber BETWEEN cv_rownumber_min
                                 AND cv_rownumber_max                        -- ベンダ納品実績の顧客ごとに直近5つを取得
      AND    xvdhv.customer_id         = xmvc.customer_id                    -- 顧客ID
      AND    xvdl.column_num           = xmvc.column_no                      -- コラムNo
      AND    msib.inventory_item_id(+) = xmvc.item_id                        -- 品目ID
      AND    msib.organization_id(+)   = gv_organization_id                  -- 在庫組織ID
      ORDER BY xvdhv.customer_number                                         -- 顧客コード
             , xvdl.column_num                                               -- コラムNo
             , xvdhv.rownumber                                               -- 順番
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
    -- 更新情報格納ループ
    <<xxcos_vd_deliv_loop>>
    FOR l_xxcos_vd_deliv_rec IN xxcos_vd_deliv_cur LOOP
      -- 対象件数カウントアップ
      gn_target_cnt := gn_target_cnt + 1;
      -- 初回の場合
      IF ( gn_target_cnt = cv_record_1 ) THEN
        -- マスタの品目コードとH/Cを変数格納
        lv_segment1 := NVL(l_xxcos_vd_deliv_rec.segment1, cv_blank_column_code);
        lv_hot_cold := NVL(l_xxcos_vd_deliv_rec.hot_cold, cv_dummy_char);
        --
        g_update_tab(ln_vd_column_cnt).rownumber       := l_xxcos_vd_deliv_rec.rownumber;
        g_update_tab(ln_vd_column_cnt).customer_number := l_xxcos_vd_deliv_rec.customer_number;
        g_update_tab(ln_vd_column_cnt).customer_id     := l_xxcos_vd_deliv_rec.customer_id;
        g_update_tab(ln_vd_column_cnt).column_no       := l_xxcos_vd_deliv_rec.column_num;
        -- 以下の場合は、納品日と本数をNULLで格納
        --   VDコラムマスタの品目がNULL（空コラム）の場合
        --   納品日がコラム変更日よりも前の場合
        --   品目が納品実績とVDコラムマスタで相違する場合
        --   H/Cが納品実績とVDコラムマスタで相違する場合
        IF ( ( lv_segment1 = cv_blank_column_code )
          OR ( l_xxcos_vd_deliv_rec.dlv_date < NVL(l_xxcos_vd_deliv_rec.column_change_date, l_xxcos_vd_deliv_rec.dlv_date ) )
          OR ( l_xxcos_vd_deliv_rec.item_code <> lv_segment1 )
          OR ( NVL(l_xxcos_vd_deliv_rec.hot_cold_type, cv_dummy_char) <> lv_hot_cold ) ) THEN
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := NULL;
          g_update_tab(ln_vd_column_cnt).quantity_1 := NULL;
          lb_column_change_flag := TRUE;
        ELSE
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := l_xxcos_vd_deliv_rec.dlv_date;
          g_update_tab(ln_vd_column_cnt).quantity_1 := l_xxcos_vd_deliv_rec.sales_qty;
        END IF;
      -- 前回格納レコードと顧客またはコラムが異なる場合
      ELSIF ( ( g_update_tab(ln_vd_column_cnt).customer_id <> l_xxcos_vd_deliv_rec.customer_id )
        OR ( g_update_tab(ln_vd_column_cnt).column_no <> l_xxcos_vd_deliv_rec.column_num ) ) THEN
        -- コラム変更判定フラグ初期化
        lb_column_change_flag := FALSE;
        -- マスタの品目コードとH/Cを変数格納
        lv_segment1 := NVL(l_xxcos_vd_deliv_rec.segment1, cv_blank_column_code);
        lv_hot_cold := NVL(l_xxcos_vd_deliv_rec.hot_cold, cv_dummy_char);
        -- 次レコードへ格納
        ln_vd_column_cnt := ln_vd_column_cnt + 1;
        ln_recode_cnt    := 1;
        --
        g_update_tab(ln_vd_column_cnt).rownumber       := l_xxcos_vd_deliv_rec.rownumber;
        g_update_tab(ln_vd_column_cnt).customer_number := l_xxcos_vd_deliv_rec.customer_number;
        g_update_tab(ln_vd_column_cnt).customer_id     := l_xxcos_vd_deliv_rec.customer_id;
        g_update_tab(ln_vd_column_cnt).column_no       := l_xxcos_vd_deliv_rec.column_num;
        --
        -- 以下の場合は、納品日と本数をNULLで格納
        --   VDコラムマスタの品目がNULL（空コラム）の場合
        --   納品日がコラム変更日よりも前の場合
        --   品目が納品実績とVDコラムマスタで相違する場合
        --   H/Cが納品実績とVDコラムマスタで相違する場合
        IF ( ( lv_segment1 = cv_blank_column_code )
          OR ( l_xxcos_vd_deliv_rec.dlv_date < NVL(l_xxcos_vd_deliv_rec.column_change_date, l_xxcos_vd_deliv_rec.dlv_date ) )
          OR ( l_xxcos_vd_deliv_rec.item_code <> lv_segment1 )
          OR ( NVL(l_xxcos_vd_deliv_rec.hot_cold_type, cv_dummy_char) <> lv_hot_cold ) ) THEN
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := NULL;
          g_update_tab(ln_vd_column_cnt).quantity_1 := NULL;
          -- コラム変更判定フラグ
          lb_column_change_flag := TRUE;
        ELSE
          g_update_tab(ln_vd_column_cnt).dlv_date_1 := l_xxcos_vd_deliv_rec.dlv_date;
          g_update_tab(ln_vd_column_cnt).quantity_1 := l_xxcos_vd_deliv_rec.sales_qty;
        END IF;
      -- 前回格納レコードと顧客とコラムが同じ場合、同一レコードへ格納（納品日1～5、本数1～5のいずれかへ格納判定）
      ELSE
        -- 以下の条件で判定
        --   ROWNUMBERが一致する場合（顧客、コラム、納品日が一致するレコード）
        --   ROWNUMBERが不一致の場合、次の納品日および本数へ格納する
        IF ( g_update_tab(ln_vd_column_cnt).rownumber = l_xxcos_vd_deliv_rec.rownumber ) THEN
          -- 一致レコード判定用フラグ
          lb_same_record_flag := TRUE;
        ELSE
          -- 一致レコード判定フラグの初期化
          lb_same_record_flag := FALSE;
          --
          ln_recode_cnt := ln_recode_cnt + 1;
          g_update_tab(ln_vd_column_cnt).rownumber := l_xxcos_vd_deliv_rec.rownumber;
        END IF;
        -- 以下の場合は、納品日と本数をNULLで格納
        --   新しい方の履歴で既にコラム変更が行われていると判定した場合
        --   VDコラムマスタの品目がNULL（空コラム）の場合
        --   納品日がコラム変更日よりも前の場合
        --   品目が納品実績とVDコラムマスタで相違する場合
        --   H/Cが納品実績とVDコラムマスタで相違する場合
        IF ( ( lb_column_change_flag = TRUE )
          OR ( lv_segment1 = cv_blank_column_code )
          OR ( l_xxcos_vd_deliv_rec.dlv_date < NVL(l_xxcos_vd_deliv_rec.column_change_date, l_xxcos_vd_deliv_rec.dlv_date ) )
          OR ( l_xxcos_vd_deliv_rec.item_code <> lv_segment1 )
          OR ( NVL(l_xxcos_vd_deliv_rec.hot_cold_type, cv_dummy_char) <> lv_hot_cold ) ) THEN
          -- 以下の条件で格納
          --   ROWNUMBERが一致するレコードの場合、次レコードへスキップ
          --     （既に正しい値が格納されている、または後続レコードが正しい値のため）
          --   ROWNUMBERが一致しないレコードの場合、NULLで格納
          IF ( lb_same_record_flag = FALSE ) THEN
            -- コラム変更判定フラグ
            lb_column_change_flag := TRUE;
            --
            IF ( ln_recode_cnt = cv_record_1 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_1 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_1 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_2 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_2 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_2 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_3 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_3 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_3 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_4 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_4 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_4 := NULL;
            ELSIF ( ln_recode_cnt = cv_record_5 ) THEN
              g_update_tab(ln_vd_column_cnt).dlv_date_5 := NULL;
              g_update_tab(ln_vd_column_cnt).quantity_5 := NULL;
            END IF;
          END IF;
          --
        ELSE
          IF ( ln_recode_cnt = cv_record_1 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_1 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_1 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_2 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_2 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_2 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_3 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_3 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_3 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_4 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_4 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_4 := l_xxcos_vd_deliv_rec.sales_qty;
          ELSIF ( ln_recode_cnt = cv_record_5 ) THEN
            g_update_tab(ln_vd_column_cnt).dlv_date_5 := l_xxcos_vd_deliv_rec.dlv_date;
            g_update_tab(ln_vd_column_cnt).quantity_5 := l_xxcos_vd_deliv_rec.sales_qty;
          END IF;
        END IF;
      END IF;
    END LOOP xxcos_vd_deliv_loop;
    --
    -- 対象件数0件の場合
    IF ( gn_target_cnt = 0 ) THEN
      ov_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_application
                     ,iv_name         => cv_msg_no_data_err
                   );
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ov_errmsg
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END get_xxcos_vd_deliv;
--
  /**********************************************************************************
   * Procedure Name   : update_mst_vd_column
   * Description      : VDコラムマスタ更新(A-3)
   ***********************************************************************************/
  PROCEDURE update_mst_vd_column(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_mst_vd_column'; -- プログラム名
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
    -- *** ローカル変数 ***
    lv_rowid                         ROWID;
    lb_warn_flag                     BOOLEAN DEFAULT FALSE; -- 警告フラグ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- VDコラムマスタ更新ループ
    <<update_mst_vd_column_loop>>
    FOR i IN 1..g_update_tab.COUNT LOOP
      -- 初期化
      lv_errmsg    := NULL;
      lv_errbuf    := NULL;
      lb_warn_flag := FALSE;
      gv_key_info  := NULL;
      -- VDコラムマスタレコードロック
      BEGIN
        SELECT xmvc.ROWID
        INTO   lv_rowid
        FROM   xxcoi_mst_vd_column xmvc                       -- VDコラムマスタ
        WHERE  xmvc.customer_id = g_update_tab(i).customer_id -- 顧客ID
        AND    xmvc.column_no   = g_update_tab(i).column_no   -- コラムNo
        FOR UPDATE NOWAIT
        ;
      EXCEPTION
        WHEN lock_expt THEN
          lb_warn_flag := TRUE;
          xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                          ,ov_retcode     => lv_retcode
                                          ,ov_errmsg      => lv_errmsg
                                          ,ov_key_info    => gv_key_info
                                          ,iv_item_name1  => cv_customer_code
                                          ,iv_data_value1 => g_update_tab(i).customer_number
                                          ,iv_item_name2  => cv_column_no
                                          ,iv_data_value2 => TO_CHAR(g_update_tab(i).column_no));
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_application
                         ,iv_name         => cv_msg_lock_err
                         ,iv_token_name1  => cv_tkn_table_name
                         ,iv_token_value1 => cv_xxcoi_mst_cd_column
                         ,iv_token_name2  => cv_tkn_key_data
                         ,iv_token_value2 => gv_key_info
                       );
          lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
          ov_retcode := cv_status_warn;
          -- スキップ件数カウントアップ
          gn_warn_cnt := gn_warn_cnt + 1;
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg
          );
        WHEN OTHERS THEN
          RAISE;
      END;
      --
--
      -- ロック取得ができた場合
      IF ( lb_warn_flag = FALSE ) THEN
        BEGIN
          -- VDコラムマスタ更新
          UPDATE xxcoi_mst_vd_column xmvc
          SET    xmvc.dlv_date_1             = g_update_tab(i).dlv_date_1  -- 納品日1
               , xmvc.quantity_1             = g_update_tab(i).quantity_1  -- 本数1
               , xmvc.dlv_date_2             = g_update_tab(i).dlv_date_2  -- 納品日2
               , xmvc.quantity_2             = g_update_tab(i).quantity_2  -- 本数2
               , xmvc.dlv_date_3             = g_update_tab(i).dlv_date_3  -- 納品日3
               , xmvc.quantity_3             = g_update_tab(i).quantity_3  -- 本数3
               , xmvc.dlv_date_4             = g_update_tab(i).dlv_date_4  -- 納品日4
               , xmvc.quantity_4             = g_update_tab(i).quantity_4  -- 本数4
               , xmvc.dlv_date_5             = g_update_tab(i).dlv_date_5  -- 納品日5
               , xmvc.quantity_5             = g_update_tab(i).quantity_5  -- 本数5
               , xmvc.last_updated_by        = cn_last_updated_by          -- 最終更新者
               , xmvc.last_update_date       = cd_last_update_date         -- 最終更新日
               , xmvc.last_update_login      = cn_last_update_login        -- 最終更新ﾛｸﾞｲﾝ
               , xmvc.request_id             = cn_request_id               -- 要求ID
               , xmvc.program_application_id = cn_program_application_id   -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               , xmvc.program_id             = cn_program_id               -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               , xmvc.program_update_date    = cd_program_update_date      -- ﾌﾟﾛｸﾞﾗﾑ更新日
          WHERE  xmvc.customer_id            = g_update_tab(i).customer_id -- 顧客ID
          AND    xmvc.column_no              = g_update_tab(i).column_no   -- コラムNo
          ;
        EXCEPTION
          WHEN OTHERS THEN
            lb_warn_flag := TRUE;
            xxcos_common_pkg.makeup_key_info(ov_errbuf      => lv_errbuf
                                            ,ov_retcode     => lv_retcode
                                            ,ov_errmsg      => lv_errmsg
                                            ,ov_key_info    => gv_key_info
                                            ,iv_item_name1  => cv_customer_code
                                            ,iv_data_value1 => g_update_tab(i).customer_number
                                            ,iv_item_name2  => cv_column_no
                                            ,iv_data_value2 => TO_CHAR(g_update_tab(i).column_no));
            lv_errmsg := xxccp_common_pkg.get_msg(
                            iv_application  => cv_application
                           ,iv_name         => cv_msg_update_err
                           ,iv_token_name1  => cv_tkn_table_name
                           ,iv_token_value1 => cv_xxcoi_mst_cd_column
                           ,iv_token_name2  => cv_tkn_key_data
                           ,iv_token_value2 => gv_key_info
                         );
            lv_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
            ov_retcode := cv_status_warn;
            -- スキップ件数カウントアップ
            gn_warn_cnt := gn_warn_cnt + 1;
            FND_FILE.PUT_LINE(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg
            );
        END;
      END IF;
--
      -- 更新できた場合
      IF ( lb_warn_flag = FALSE ) THEN
        -- 更新件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      END IF;
    --
    END LOOP update_mst_vd_column_loop;
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
  END update_mst_vd_column;
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_target_cnt    := 0;
    gn_normal_cnt    := 0;
    gn_error_cnt     := 0;
    gn_warn_cnt      := 0;
    gn_init_warn_cnt := 0;
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ベンダ納品実績データ抽出(A-2)
    -- ===============================
    get_xxcos_vd_deliv(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- VDコラムマスタ更新(A-3)
    -- ===============================
    update_mst_vd_column(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF ( lv_retcode = cv_status_warn ) THEN
      RAISE warn_expt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 警告例外ハンドラ ***
    WHEN warn_expt THEN
      ov_retcode := cv_status_warn;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14251'; -- 対象件数メッセージ
    cv_update_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14252'; -- 更新件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14253'; -- スキップ件数メッセージ
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCOS1-14254'; -- 警告件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
    --
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
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --
      gn_target_cnt    := 0;
      gn_normal_cnt    := 0;
      gn_warn_cnt      := 0;
      gn_init_warn_cnt := 0;
      gn_error_cnt     := 1;
      --
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
    -- ===============================
    -- 終了処理(A-4)
    -- ===============================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --更新件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_update_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_application
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_init_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
END XXCOS003A06C;
/
