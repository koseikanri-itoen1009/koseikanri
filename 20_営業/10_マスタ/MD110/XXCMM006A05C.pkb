CREATE OR REPLACE PACKAGE BODY XXCMM006A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM006A05C(body)
 * Description      : 締め情報ファイルIF出力(情報系)
 * MD.050           : 締め情報ファイルIF出力(情報系) MD050_CMM_006_A05
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理プロシージャ(A-1)
 *  get_period_data        会計期間ステータス情報取得プロシージャ(A-2)
 *  output_csv             CSVファイル出力プロシージャ(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/26    1.0   SCS 福間 貴子    初回作成
 *  2009/03/12    1.1   SCS R.Takigawa   抽出SQLを修正(在庫期間(INV)の抽出テーブルの変更)
 *  2009/05/26    1.2   SCS H.Yoshiawa   GLの連携モジュール名を修正（障害：T1_1200）
 *  2009/09/04    1.3   SCS Y.Kuboshima  障害0001130の対応
 *                                       在庫組織をS01 -> Z99 に変更
 *  2018/05/10    1.4   SCSK H.Mori      E_本稼動_15085の対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCMM006A05C';               -- パッケージ名
  -- プロファイル
  cv_filepath               CONSTANT VARCHAR2(30)  := 'XXCMM1_JYOHO_OUT_DIR';       -- 情報系CSVファイル出力先
  cv_filename               CONSTANT VARCHAR2(30)  := 'XXCMM1_006A05_OUT_FILE';     -- 連携用CSVファイル名
-- 2009/09/04 Ver1.3 add start by Y.Kuboshima
  cv_org_code               CONSTANT VARCHAR2(30)  := 'XXCOI1_ORGANIZATION_CODE';   -- 在庫組織コード
-- 2009/09/04 Ver1.3 add end by Y.Kuboshima
-- 2018/05/10 Ver1.4 add start by H.Mori
  cv_prf_bks_id             CONSTANT VARCHAR2(50)  := 'GL_SET_OF_BKS_ID';           --GL会計帳簿ID
-- 2018/05/10 Ver1.4 add end by H.Mori
  -- トークン
  cv_tkn_profile            CONSTANT VARCHAR2(10)  := 'NG_PROFILE';                 -- プロファイル名
  cv_tkn_filepath_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル出力先';
  cv_tkn_filename_nm        CONSTANT VARCHAR2(20)  := 'CSVファイル名';
  cv_tkn_word               CONSTANT VARCHAR2(10)  := 'NG_WORD';                    -- 項目名
  cv_tkn_word1              CONSTANT VARCHAR2(20)  := 'モジュール';
  cv_tkn_word2              CONSTANT VARCHAR2(20)  := '、年月：';
  cv_tkn_data               CONSTANT VARCHAR2(10)  := 'NG_DATA';                    -- データ
  cv_tkn_filename           CONSTANT VARCHAR2(10)  := 'FILE_NAME';                  -- ファイル名
-- 2009/09/04 Ver1.3 add start by Y.Kuboshima
  cv_tkn_org_code           CONSTANT VARCHAR2(30)  := '在庫組織コード';             -- 在庫組織コード
-- 2009/09/04 Ver1.3 add end by Y.Kuboshima
-- 2018/05/10 Ver1.4 add start by H.Mori
  cv_tkn_invalid_id         CONSTANT VARCHAR2(20)  := 'GL会計帳簿ID';               --プロファイル取得失敗（GL会計帳簿ID）
-- 2018/05/10 Ver1.4 add end by H.Mori
  -- メッセージ区分
  cv_msg_kbn_cmm            CONSTANT VARCHAR2(5)   := 'XXCMM';
  cv_msg_kbn_ccp            CONSTANT VARCHAR2(5)   := 'XXCCP';
  -- メッセージ
  cv_msg_90008              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-90008';           -- コンカレント入力パラメータなし
  cv_msg_00002              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';           -- プロファイル取得エラー
  cv_msg_05102              CONSTANT VARCHAR2(20)  := 'APP-XXCCP1-05102';           -- ファイル名出力メッセージ
  cv_msg_00010              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00010';           -- CSVファイル存在チェック
  cv_msg_00003              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00003';           -- ファイルパス不正エラー
  cv_msg_00018              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00018';           -- 業務日付取得エラー
  cv_msg_00013              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00013';           -- 会計カレンダのタイプ取得エラー
  cv_msg_00001              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';           -- 対象データ無し
  cv_msg_00011              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00011';           -- 通常月のデータ無し
  cv_msg_00007              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00007';           -- ファイルアクセス権限エラー
  cv_msg_00009              CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00009';           -- CSVデータ出力エラー
  -- 固定値(設定値、抽出条件)
  cv_company_cd             CONSTANT VARCHAR2(3)   := '001';                        -- 会社コード
  cv_karenda                CONSTANT VARCHAR2(20)  := '会計カレンダ';               -- 抽出対象カレンダ
  cv_SQLGL                  CONSTANT VARCHAR2(5)   := 'SQLGL';                      -- 抽出対象モジュール
-- Ver1.2  2009/05/26  ADD  T1_1200(連携モジュール名称を'SQLGL'から'GL'に修正)
  cv_GL                     CONSTANT VARCHAR2(5)   := 'GL';                         -- 連携モジュール名(GL)
-- End
  cv_AR                     CONSTANT VARCHAR2(5)   := 'AR';                         -- 抽出対象モジュール・連携モジュール名(AR)
  cv_INV                    CONSTANT VARCHAR2(5)   := 'INV';                        -- 抽出対象モジュール・連携モジュール名(INV)
  cv_open_status            CONSTANT VARCHAR2(1)   := 'O';                          -- オープンのステータス
  cv_open_status_nm         CONSTANT VARCHAR2(40)  := 'オープン';                   -- オープンのステータス名
--Ver1.1 2009/03/12 add 在庫期間(INV)の抽出テーブルの変更により定数追加
  cv_unopen_status          CONSTANT VARCHAR2(1)   := 'N';                          -- 未オープンのステータス
  cv_unopen_status_nm       CONSTANT VARCHAR2(10)  := '未オープン';                 -- 未オープンのステータス名
  cv_close_status           CONSTANT VARCHAR2(1)   := 'C';                          -- クローズのステータス
  cv_close_status_nm        CONSTANT VARCHAR2(8)   := 'クローズ';                   -- クローズのステータス名
  cv_unsmr_close_status_nm  CONSTANT VARCHAR2(14)  := 'クローズ未要約';             -- クローズ未要約のステータス名
  cv_future_status_nm       CONSTANT VARCHAR2(4)   := '将来';                       -- 将来のステータス名
  cv_adj_period_flg_n       CONSTANT VARCHAR2(1)   := 'N';                          -- 調整期間：N
-- 2009/09/04 Ver1.3 delete start by Y.Kuboshima
--  cv_organization_code      CONSTANT VARCHAR2(3)   := 'S01';                        -- 組織コード：S01
-- 2009/09/04 Ver1.3 delete end by Y.Kuboshima
--End1.1
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_sysdate                DATE;                 -- 処理開始日時
  gv_filepath               VARCHAR2(255);        -- 連携用CSVファイル出力先
  gv_filename               VARCHAR2(255);        -- 連携用CSVファイル名
  gd_process_date           DATE;                 -- 業務日付
  gn_before_year            NUMBER(4);            -- 前年度
  gn_next_year              NUMBER(4);            -- 次年度
  gv_period_type            VARCHAR2(15);         -- カレンダタイプ
  gv_application_short_name VARCHAR2(5);          -- 期間モジュール
  gv_period_name            VARCHAR2(7);          -- 期間名称
  gv_closing_status         VARCHAR2(1);          -- ステータス
  gv_show_status            VARCHAR2(40);         -- ステータス名
  gd_start_date             DATE;                 -- 期間From
  gd_end_date               DATE;                 -- 期間To
  gn_period_year            NUMBER(4);            -- 年度
  gv_adjustment_period_flag VARCHAR2(1);          -- 調整期間
  gf_file_hand              UTL_FILE.FILE_TYPE;   -- ファイル・ハンドルの宣言
  gn_all_cnt                NUMBER;               -- 取得データ件数
  gc_del_flg                CHAR(1);              -- ファイル削除フラグ(対象データ無しの場合)
-- 2009/09/04 Ver1.3 add start by Y.Kuboshima
  gv_org_code               VARCHAR2(100);        -- 在庫組織コード
-- 2009/09/04 Ver1.3 add end by Y.Kuboshima
-- 2018/05/10 Ver1.4 add start by H.Mori
  gn_bks_id                 NUMBER;
-- 2018/05/10 Ver1.4 add end by H.Mori
--
  -- ===============================
  -- ユーザー定義グローバルカーソル
  -- ===============================
  CURSOR get_period_data_cur
  IS
--Ver1.1 2009/03/12 Mod 在庫期間(INV)の抽出テーブルの変更
--    SELECT   SUBSTRB(g.period_name,1,7) AS period_name,
--             SUBSTRB(f.application_short_name,1,5) AS application_short_name,
--             SUBSTRB(g.closing_status,1,1) AS closing_status,
--             SUBSTRB(g.show_status,1,40) AS show_status,
--             g.start_date AS start_date,
--             g.end_date AS end_date,
--             SUBSTRB(g.period_year,1,4) AS period_year,
--             g.adjustment_period_flag AS adjustment_period_flag
--    FROM     gl_period_statuses_v g,
--             fnd_application f
--    WHERE    g.application_id = f.application_id
--    AND      g.period_year >= gn_before_year
--    AND      g.period_year <= gn_next_year
--    AND      (f.application_short_name = cv_SQLGL
--             OR f.application_short_name = cv_AR
--             OR f.application_short_name = cv_INV)
--    AND      g.period_type = gv_period_type
--    ORDER BY application_short_name,period_name,g.adjustment_period_flag
--期間モジュール【AR】
    SELECT   SUBSTRB(gpsv.period_name,1,7)              AS period_name,              --期間名称
             SUBSTRB(fapp.application_short_name,1,5)   AS application_short_name,   --期間モジュール
             SUBSTRB(gpsv.closing_status,1,1)           AS closing_status,           --ステータス
             SUBSTRB(gpsv.show_status,1,40)             AS show_status,              --ステータス名
             gpsv.start_date                            AS start_date,               --期間From
             gpsv.end_date                              AS end_date,                 --期間To
             SUBSTRB(gpsv.period_year,1,4)              AS period_year,              --年度
             gpsv.adjustment_period_flag                AS adjustment_period_flag    --調整期間
    FROM     gl_period_statuses_v gpsv,
             fnd_application fapp
    WHERE    gpsv.application_id = fapp.application_id
    AND      gpsv.period_year >= gn_before_year
    AND      gpsv.period_year <= gn_next_year
    AND      fapp.application_short_name = cv_AR
    AND      adjustment_period_flag = cv_adj_period_flg_n
    AND      gpsv.period_type = gv_period_type
-- 2018/05/10 Ver1.4 add start by H.Mori
    AND      gpsv.set_of_books_id = gn_bks_id   --帳簿ID
-- 2018/05/10 Ver1.4 add end by H.Mori
    UNION ALL
--期間モジュール【SQLGL】
    SELECT   SUBSTRB(gpsv.period_name,1,7)              AS period_name,              --期間名称
-- Ver1.2  2009/05/26  ADD  T1_1200(連携モジュール名称を'SQLGL'から'GL'に修正)
--             SUBSTRB(fapp.application_short_name,1,5)   AS application_short_name,   --期間モジュール
             cv_GL                                      AS application_short_name,   --期間モジュール
-- End
             SUBSTRB(gpsv.closing_status,1,1)           AS closing_status,           --ステータス
             SUBSTRB(gpsv.show_status,1,40)             AS show_status,              --ステータス名
             gpsv.start_date                            AS start_date,               --期間From
             gpsv.end_date                              AS end_date,                 --期間To
             SUBSTRB(gpsv.period_year,1,4)              AS period_year,              --年度
             gpsv.adjustment_period_flag                AS adjustment_period_flag    --調整期間
    FROM     gl_period_statuses_v gpsv,
             fnd_application fapp
    WHERE    gpsv.application_id = fapp.application_id
    AND      gpsv.period_year >= gn_before_year
    AND      gpsv.period_year <= gn_next_year
    AND      fapp.application_short_name = cv_SQLGL
    AND      gpsv.period_type = gv_period_type
-- 2018/05/10 Ver1.4 add start by H.Mori
    AND      gpsv.set_of_books_id = gn_bks_id   --帳簿ID
-- 2018/05/10 Ver1.4 add end by H.Mori
   UNION ALL
--期間モジュール【INV】
    SELECT   SUBSTRB(oapv.period_name,1,7)              AS period_name,              --期間名称
             cv_INV                                     AS application_short_name,   --期間モジュール
             DECODE(oapv.status,
                      cv_open_status_nm,cv_open_status,                              --オープン      ：O
                      cv_unsmr_close_status_nm,cv_close_status,                      --クローズ未要約：C
                      cv_close_status_nm,cv_close_status,                            --クローズ      ：C
                      cv_future_status_nm,cv_unopen_status,                          --将来          ：N
                      NULL)                             AS closing_status,           --ステータス
             DECODE(SUBSTRB(oapv.status,1,40),
                      cv_open_status_nm,cv_open_status_nm,                           --オープン      ：オープン
                      cv_unsmr_close_status_nm,cv_close_status_nm,                   --クローズ未要約：クローズ
                      cv_close_status_nm,cv_close_status_nm,                         --クローズ      ：クローズ
                      cv_future_status_nm,cv_unopen_status_nm,                       --将来          ：未オープン
                      NULL)                             AS show_status,              --ステータス名
             oapv.start_date                            AS start_date,               --期間From
             oapv.end_date                              AS end_date,                 --期間To
             SUBSTRB(oapv.period_year,1,4)              AS period_year,              --年度
             cv_adj_period_flg_n                        AS adjustment_period_flag    --調整期間
    FROM     org_acct_periods_v oapv,
             mtl_parameters mp
    WHERE    oapv.period_year >= gn_before_year
    AND      oapv.period_year <= gn_next_year
-- 2009/09/04 Ver1.3 modify start by Y.Kuboshima
--    AND      mp.organization_code = cv_organization_code
    AND      mp.organization_code = gv_org_code
-- 2009/09/04 Ver1.3 modify end by Y.Kuboshima
    AND  (
            ( oapv.organization_id = mp.organization_id )
        OR  ( oapv.accounted_period_type = gv_period_type
          AND NOT EXISTS ( SELECT  oap.period_name,
                                   oap.period_year
                           FROM    org_acct_periods oap
                           WHERE   oap.organization_id = mp.organization_id
                           AND     oap.period_name = oapv.period_name )
            )
         )
    ORDER BY application_short_name,period_name,adjustment_period_flag
--End1.1
  ;
  TYPE g_period_data_ttype IS TABLE OF get_period_data_cur%ROWTYPE INDEX BY PLS_INTEGER;
  gt_period_data            g_period_data_ttype;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'init';                  -- プログラム名
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
    -- ファイルオープンモード
    cv_open_mode_w          CONSTANT VARCHAR2(10)  := 'w';           -- 上書き
--
    -- *** ローカル変数 ***
    lb_fexists              BOOLEAN;              -- ファイルが存在するかどうか
    ln_file_size            NUMBER;               -- ファイルの長さ
    ln_block_size           NUMBER;               -- ファイルシステムのブロックサイズ
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
    -- =========================================================
    --  処理開始日時を取得
    -- =========================================================
    gd_sysdate := SYSDATE;
    --
    -- =========================================================
    --  固定出力(入力パラメータ部)
    -- =========================================================
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_90008           -- コンカレント入力パラメータなし
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- =========================================================
    --  プロファイルの取得(CSVファイル出力先、CSVファイル名、在庫組織コード)
    -- =========================================================
    gv_filepath := fnd_profile.value(cv_filepath);
    IF (gv_filepath IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filepath_nm   -- プロファイル名(CSVファイル出力先)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    gv_filename := fnd_profile.value(cv_filename);
    IF (gv_filename IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_filename_nm   -- プロファイル名(CSVファイル名)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/09/04 Ver1.3 add start by Y.Kuboshima
    -- 在庫組織コードの取得
    gv_org_code := fnd_profile.value(cv_org_code);
    IF (gv_org_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_org_code      -- プロファイル名(在庫組織コード)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/09/04 Ver1.3 add end by Y.Kuboshima
-- 2018/05/10 Ver1.4 add start by H.Mori
    -- GL会計帳簿IDの取得
    gn_bks_id := fnd_profile.value(cv_prf_bks_id);
    IF (gn_bks_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00002         -- プロファイル取得エラー
                      ,iv_token_name1  => cv_tkn_profile       -- トークン(NG_PROFILE)
                      ,iv_token_value1 => cv_tkn_invalid_id    -- プロファイル名(GL会計帳簿ID)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2018/05/10 Ver1.4 add end by H.Mori
    --
    -- =========================================================
    --  固定出力(I/Fファイル名部)
    -- =========================================================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_ccp         -- 'XXCCP'
                    ,iv_name         => cv_msg_05102           -- ファイル名出力メッセージ
                    ,iv_token_name1  => cv_tkn_filename        -- トークン(FILE_NAME)
                    ,iv_token_value1 => gv_filename            -- ファイル名
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    -- =========================================================
    --  CSVファイル存在チェック
    -- =========================================================
    UTL_FILE.FGETATTR(gv_filepath,
                      gv_filename,
                      lb_fexists,
                      ln_file_size,
                      ln_block_size);
    IF (lb_fexists = TRUE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00010         -- ファイル作成済みエラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --
    -- =========================================================
    --  ファイルオープン
    -- =========================================================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(gv_filepath
                                    ,gv_filename
                                    ,cv_open_mode_w);
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                        ,iv_name         => cv_msg_00003       -- ファイルパス不正エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
    --
    -- =========================================================
    --  業務日付取得(前年度、次年度取得)
    -- =========================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00018         -- 業務処理日付取得エラー
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    -- 前年度、次年度取得
    IF ((TO_NUMBER(TO_CHAR(gd_process_date,'MM')) >= 1)
      AND (TO_NUMBER(TO_CHAR(gd_process_date,'mm')) <= 4))
    THEN
      -- 業務日付の月が1から4の場合 (前年度:業務日付の年-2、次年度:業務日付の年)
      gn_before_year := TO_CHAR(gd_process_date,'YYYY')-2;
      gn_next_year   := TO_CHAR(gd_process_date,'YYYY');
    ELSE
      -- 業務日付の月が5から12の場合(前年度:業務日付の年-1、次年度:業務日付の年+1)
      gn_before_year := TO_CHAR(gd_process_date,'YYYY')-1;
      gn_next_year   := TO_CHAR(gd_process_date,'YYYY')+1;
    END IF;
    --
    -- =========================================================
    --  会計カレンダのタイプ取得
    -- =========================================================
    BEGIN
      SELECT  t.period_type INTO gv_period_type
      FROM    gl_periods_and_types_v t,gl_period_sets_v k
      WHERE   t.period_set_name = k.period_set_name
      AND     k.description = cv_karenda;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_msg_kbn_cmm     -- 'XXCMM'
                        ,iv_name         => cv_msg_00013       -- 会計カレンダのタイプ取得エラー
                       );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
   * Procedure Name   : get_period_data
   * Description      : 会計期間ステータス情報取得プロシージャ(A-2)
   ***********************************************************************************/
  PROCEDURE get_period_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_period_data';       -- プログラム名
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
   -- カーソルオープン
    OPEN get_period_data_cur;
    --
    -- データの一括取得
    FETCH get_period_data_cur BULK COLLECT INTO gt_period_data;
    --
    -- 取得データ件数をセット
    gn_all_cnt := gt_period_data.COUNT;
    --
    -- カーソルクローズ
    CLOSE get_period_data_cur;
    --
    -- 処理対象となるデータが存在するかをチェック
    IF (gn_all_cnt = 0) THEN
      gc_del_flg := '1';
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_msg_kbn_cmm       -- 'XXCMM'
                      ,iv_name         => cv_msg_00001         -- 対象データ無し
                     );
      lv_errbuf := lv_errmsg;
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
  END get_period_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力プロシージャ(A-4)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv';            -- プログラム名
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
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(2)  := '"';                -- 単語囲み文字
--
    -- *** ローカル変数 ***
    ln_loop_cnt         NUMBER;                   -- ループカウンタ
    ln_target_cnt       NUMBER;                   -- 処理件数(期間モジュール/期間名称毎)
    lv_csv_text         VARCHAR2(32000);          -- 出力１行分文字列変数
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
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
--
    -- 変数の初期化
    ln_target_cnt := 0;
    gv_application_short_name := ' ';
    gv_period_name := ' ';
    -- =========================================================
    --  会計期間ステータス情報抽出(A-3)
    -- =========================================================
    <<out_loop>>
    FOR ln_loop_cnt IN 1..gn_all_cnt LOOP
      -- =========================================================
      --  取得した期間モジュール、期間名称と異なる場合、
      --  期間モジュールと期間名称の取得、データの出力を行う
      -- =========================================================
      IF ((gv_application_short_name <> gt_period_data(ln_loop_cnt).application_short_name)
        OR (gv_period_name <> gt_period_data(ln_loop_cnt).period_name))
      THEN
        -- 期間モジュール、期間名称の取得
        gv_application_short_name := gt_period_data(ln_loop_cnt).application_short_name;
        gv_period_name := gt_period_data(ln_loop_cnt).period_name;
        -- 通常月のレコードが存在しない場合
        IF (gt_period_data(ln_loop_cnt).adjustment_period_flag <> 'N') THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_msg_kbn_cmm                           -- 'XXCMM'
                          ,iv_name         => cv_msg_00011                             -- 通常月のデータ無し
                          ,iv_token_name1  => cv_tkn_word                              -- トークン(NG_WORD)
                          ,iv_token_value1 => cv_tkn_word1                             -- NG_WORD1
                          ,iv_token_name2  => cv_tkn_data                              -- トークン(NG_DATA)
                          ,iv_token_value2 => gv_application_short_name                -- NG_WORD1のDATA
                                                || cv_tkn_word2                        -- NG_WORD2
                                                || gv_period_name                      -- NG_WORD2のDATA
                         );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        END IF;
        -- =========================================================
        --  データの取得
        -- =========================================================
        IF (ln_loop_cnt = gn_all_cnt) THEN
          -- 最終レコードの場合、次レコードのチェックは行わない
          gv_closing_status := gt_period_data(ln_loop_cnt).closing_status;             -- ステータス
          gv_show_status := gt_period_data(ln_loop_cnt).show_status;                   -- ステータス名
          gd_start_date := gt_period_data(ln_loop_cnt).start_date;                     -- 期間FROM
          gd_end_date := gt_period_data(ln_loop_cnt).end_date;                         -- 期間TO
          gn_period_year := gt_period_data(ln_loop_cnt).period_year;                   -- 年度
        ELSE
          -- 最終レコード以外の場合、次レコードの期間モジュール、期間名称をチェック
          IF ((gv_application_short_name <> gt_period_data(ln_loop_cnt+1).application_short_name)
            OR (gv_period_name <> gt_period_data(ln_loop_cnt+1).period_name))
          THEN
            -- 同一の期間モジュール、期間名称のデータなし
            gv_closing_status := gt_period_data(ln_loop_cnt).closing_status;           -- ステータス
            gv_show_status := gt_period_data(ln_loop_cnt).show_status;                 -- ステータス名
            gd_start_date := gt_period_data(ln_loop_cnt).start_date;                   -- 期間FROM
            gd_end_date := gt_period_data(ln_loop_cnt).end_date;                       -- 期間TO
            gn_period_year := gt_period_data(ln_loop_cnt).period_year;                 -- 年度
          ELSE
            -- 同一の期間モジュール、期間名称のデータありの場合、調整期間レコードのステータスをチェック
            IF ((gt_period_data(ln_loop_cnt+1).adjustment_period_flag = 'Y')
              AND (gt_period_data(ln_loop_cnt+1).closing_status = cv_open_status))
            THEN
              -- 調整期間レコードのステータスが「O」の場合、ステータス、ステータス名にオープンをセット
              gv_closing_status := cv_open_status;                                     -- ステータス
              gv_show_status := cv_open_status_nm;                                     -- ステータス名
              gd_start_date := gt_period_data(ln_loop_cnt).start_date;                 -- 期間FROM
              gd_end_date := gt_period_data(ln_loop_cnt).end_date;                     -- 期間TO
              gn_period_year := gt_period_data(ln_loop_cnt).period_year;               -- 年度
            ELSE
              -- 調整期間レコードのステータスが「O」以外
              gv_closing_status := gt_period_data(ln_loop_cnt).closing_status;         -- ステータス
              gv_show_status := gt_period_data(ln_loop_cnt).show_status;               -- ステータス名
              gd_start_date := gt_period_data(ln_loop_cnt).start_date;                 -- 期間FROM
              gd_end_date := gt_period_data(ln_loop_cnt).end_date;                     -- 期間TO
              gn_period_year := gt_period_data(ln_loop_cnt).period_year;               -- 年度
            END IF;
          END IF;
        END IF;
        -- =========================================================
        --  CSVファイル出力
        -- =========================================================
        lv_csv_text := cv_enclosed || cv_company_cd || cv_enclosed || cv_delimiter     -- 会社コード
          || cv_enclosed || gv_period_name || cv_enclosed || cv_delimiter              -- 期間名称
          || cv_enclosed || gv_application_short_name || cv_enclosed || cv_delimiter   -- 期間モジュール
          || cv_enclosed || gv_closing_status || cv_enclosed || cv_delimiter           -- ステータス
          || cv_enclosed || gv_show_status || cv_enclosed || cv_delimiter              -- ステータス名
          || TO_CHAR(gd_start_date,'YYYYMMDD') || cv_delimiter                         -- 期間FROM
          || TO_CHAR(gd_end_date,'YYYYMMDD') || cv_delimiter                           -- 期間TO
          || gn_period_year || cv_delimiter                                            -- 年度
          || TO_CHAR(gd_sysdate,'YYYYMMDDHH24MISS')                                    -- 連携日時
        ;
        BEGIN
          -- ファイル書き込み
          UTL_FILE.PUT_LINE(gf_file_hand,lv_csv_text);
        EXCEPTION
          -- ファイルアクセス権限エラー
          WHEN UTL_FILE.INVALID_OPERATION THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                            ,iv_name         => cv_msg_00007                           -- ファイルアクセス権限エラー
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          --
          -- CSVデータ出力エラー
          WHEN UTL_FILE.WRITE_ERROR THEN
            lv_errmsg := xxcmn_common_pkg.get_msg(
                             iv_application  => cv_msg_kbn_cmm                         -- 'XXCMM'
                            ,iv_name         => cv_msg_00009                           -- CSVデータ出力エラー
                            ,iv_token_name1  => cv_tkn_word                            -- トークン(NG_WORD)
                            ,iv_token_value1 => cv_tkn_word1                           -- NG_WORD1
                            ,iv_token_name2  => cv_tkn_data                            -- トークン(NG_DATA)
                            ,iv_token_value2 => gv_application_short_name              -- NG_WORD1のDATA
                                                  || cv_tkn_word2                      -- NG_WORD2
                                                  || gv_period_name                    -- NG_WORD2のDATA
                           );
            lv_errbuf := lv_errmsg;
            RAISE global_api_expt;
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
        --
        -- 処理件数のカウント
        ln_target_cnt := ln_target_cnt + 1;
      END IF;
    END LOOP out_loop;
    --
    -- 対象件数に処理件数をセット
    gn_target_cnt := ln_target_cnt;
    -- 正常件数に処理件数をセット
    gn_normal_cnt := ln_target_cnt;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
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
  END output_csv;
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';                -- プログラム名
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
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --
    -- =====================================================
    --  初期処理プロシージャ(A-1)
    -- =====================================================
    init(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  会計期間ステータス情報取得プロシージャ(A-2)
    -- =====================================================
    get_period_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  CSVファイル出力プロシージャ(A-4)
    -- =====================================================
    output_csv(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- =====================================================
    --  終了処理プロシージャ(A-5)
    -- =====================================================
    -- CSVファイルをクローズする
    UTL_FILE.FCLOSE(gf_file_hand);
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
   * Description      : コンカレント実行プロシージャ
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
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
    -- ファイル削除フラグをクリア
    gc_del_flg := '0';
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      lv_errbuf   -- エラー・メッセージ            --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      -- 空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- エラー発生時、各件数は以下に統一して出力する
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
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
    -- 空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
    --
    --CSVファイルがクローズされていなかった場合、クローズする
    IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
      UTL_FILE.FCLOSE(gf_file_hand);
    END IF;
    --
    --対象データ無しの場合、CSVファイルを削除
    IF (gc_del_flg = '1') THEN
      UTL_FILE.FREMOVE(gv_filepath,    -- CSVファイル出力先
                       gv_filename);   -- ファイル名
    END IF;
    --
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
END XXCMM006A05C;
/
