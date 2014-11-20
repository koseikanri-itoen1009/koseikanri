CREATE OR REPLACE PACKAGE BODY XXCSM002A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A15C(body)
 * Description      : 商品計画ヘッダテーブル、及び商品計画明細テーブルより対象予算年度の
 *                  : 商品計画データを抽出し、生産システムに連携するためのIFテーブルにデータを
 *                  : 登録します。
 * MD.050           : MD050_CSM_002_A15_年間商品計画生産システムIF
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  del_forecast_firstif   販売計画/引取計画I/Fテーブル事前削除処理(A-3)
 *  get_compute_count      単位換算処理 (A-4)
 *  insert_forecast_if     年間商品計画データ登録 (A-5)
 *  submain                メイン処理プロシージャ
 *                           年間商品計画データ取得 (A-2)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-08    1.0   T.Tsukino        新規作成
 *  2009-02-24    1.1   M.Ohtsuki        [CT_063]  数量0のレコードの不具合の対応
 *  2009-03-24    1.2   M.Ohtsuki        [T1_0117] バラ数生産連携不具合の対応
 *  2009-03-24    1.2   M.Ohtsuki        [T1_0097] パージ条件不具合の対応
 *  2009-05-11    1.3   M.Ohtsuki        [T1_0942] 新商品を連携対象に含む対応
 *  2009-07-31    1.4   M.Ohtsuki        [0000903] 共通関数INパラメータの不具合の対応
 *  2011-11-08    1.5   Y.Horikawa       [E_本稼動_07458] 値引額、数量0売上あり　を連携対象に追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             -- 正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               -- 警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              -- 異常:2
  --WHOカラム
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                             -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                                        -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        -- PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
  cv_msg_00111              CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00111';                           -- 想定外エラーメッセージ
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gv_sep_msg                VARCHAR2(2000);
  gv_exec_user              VARCHAR2(100);
  gv_conc_name              VARCHAR2(30);
  gv_conc_status            VARCHAR2(30);
  gn_target_cnt             NUMBER;                                                                 -- 対象件数
  gn_normal_cnt             NUMBER;                                                                 -- 正常件数
  gn_error_cnt              NUMBER;                                                                 -- エラー件数
  gn_warn_cnt               NUMBER;                                                                 -- スキップ件数
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name             CONSTANT VARCHAR2(100)  := 'XXCSM002A15C';                                -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)    := 'XXCSM';                                       -- アプリケーション短縮名
  -- メッセージコード
  cv_xxccp_msg_90008      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';                             -- コンカレント入力パラメータなし
  cv_xxcsm_msg_00005      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                             -- プロファイル取得エラーメッセージ
  cv_xxcsm_msg_00006      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00006';                             -- 年間販売計画カレンダー未存在エラーメッセージ
  cv_xxcsm_msg_00004      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00004';                             -- 予算年度チェックエラー
  cv_xxcsm_msg_10001      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10001';                             -- 取得データ0件エラーメッセージ
  cv_xxcsm_msg_10134      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10134';                             -- 販売計画/引取計画I/Fテーブルロックエラーメッセージ
  cv_xxcsm_msg_10137      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10137';                             -- 商品計画数量取得エラーメッセージ
--//+ADD END        2009/03/24   T1_0097 M.Ohtsuki
  cv_xxcsm_msg_10154      CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10154';                             -- 販売計画/引取計画I/Fテーブルロックエラーメッセージ(既存)
--//+ADD END        2009/03/24   T1_0097 M.Ohtsuki
  --プロファイル名
  cv_yearplan_calender    CONSTANT VARCHAR2(100) := 'XXCSM1_YEARPLAN_CALENDER';                     -- XXCSM:年間販売計画カレンダー名
--// Add Start 2011/11/08 Ver.1.5
  cv_sales_discount_item_cd    CONSTANT VARCHAR2(100) := 'XXCOS1_DISCOUNT_ITEM_CODE';              -- XXCOS:売上値引品目
  cv_receipt_discount_item_cd  CONSTANT VARCHAR2(100) := 'XXCSM1_RECEIPT_DISCOUNT_ITEM_CODE';      -- XXCSM:入金値引品目
--// Add End 2011/11/08 Ver.1.5
  -- トークンコード
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';                                     -- プロファイル名セット
  cv_tkn_item             CONSTANT VARCHAR2(20) := 'ITEM';                                          -- 項目名称セット
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';                                         -- 処理件数
  cv_tkn_itemcd           CONSTANT VARCHAR2(20) := 'ITEM_CD';                                       -- 商品コード
  cv_tkn_kyotencd         CONSTANT VARCHAR2(20) := 'KYOTEN_CD';                                     -- 拠点コード
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date         DATE;                                                 -- 業務日付格納用
  gv_prf_calender         VARCHAR2(100);                                        -- プロファイルXXCSM:年間販売計画カレンダー名
  gn_active_year          NUMBER;                                               -- 対象年度
--// Add Start 2011/11/08 Ver.1.5
  gv_prf_sales_discnt_item_cd    VARCHAR2(100);  -- プロファイル XXCOS:売上値引品目
  gv_prf_receipt_discnt_item_cd  VARCHAR2(100);  -- プロファイル XXCSM:入金値引品目
--// Add End 2011/11/08 Ver.1.5
--
  /**********************************************************************************
   * Procedure Name   : init
   * Argument         : なし
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)   := 'init';                                         -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf           VARCHAR2(4000);                                                             -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);                                                                -- リターン・コード
    lv_errmsg           VARCHAR2(4000);                                                             -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name  CONSTANT VARCHAR2(10)  := 'XXCCP';                      -- アプリケーション短縮名
    -- *** ローカル変数 ***
    lv_prm_msg          VARCHAR2(4000);                                         -- コンカレント入力パラメータメッセージ格納用
    ln_carender_cnt     NUMBER;                                                 -- 年間販売計画チェック用
    ln_retcode          NUMBER;                                                 -- 年間販売計画カレンダー取得関数:STATUS
    lv_result           VARCHAR2(1);                                            -- 年間販売計画カレンダー取得関数:処理結果
    lv_msg              VARCHAR2(100);                                          --
    -- *** ローカル例外 ***
    getprofile_err_expt EXCEPTION;                                              -- プロファイル取得エラーメッセージ
    calendar_check_expt EXCEPTION;                                              -- 年間販売計画カレンダー未存在エラーメッセージ
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
-- 業務運用日の取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- =====================================
    -- A-1: ① 入力パラメータメッセージ出力
    -- =====================================
    -- コンカレント入力パラメータメッセージ
    lv_prm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_appl_short_name                   --アプリケーション短縮名
                       ,iv_name         => cv_xxccp_msg_90008                     --メッセージコード
                    );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||                                     -- 空行の挿入
                 lv_prm_msg   || CHR(10) ||
                 ''                                                             -- 空行の挿入
    );
    --ログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => ''           || CHR(10) ||                                     -- 空行の挿入
                 lv_prm_msg   || CHR(10) ||
                 ''                                                             -- 空行の挿入
    );
    -- ===========================
    -- A-1: ② プロファイル値取得
    -- ===========================
    -- XXCSM:年間販売計画カレンダー名
    gv_prf_calender :=  FND_PROFILE.VALUE(cv_yearplan_calender);
    -- プロファイル値取得に失敗した場合
    IF (gv_prf_calender IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_00005                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_prf_name                        --トークンコード1
                     ,iv_token_value1 => cv_yearplan_calender                   --トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE getprofile_err_expt;
    END IF;
--// Add Start 2011/11/08 Ver.1.5
    -- XXCOS:売上値引品目
    gv_prf_sales_discnt_item_cd :=  FND_PROFILE.VALUE(cv_sales_discount_item_cd);
    -- プロファイル値取得に失敗した場合
    IF (gv_prf_sales_discnt_item_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_00005                     --メッセージコード
                     ,iv_token_name1  => cv_tkn_prf_name                        --トークンコード1
                     ,iv_token_value1 => cv_sales_discount_item_cd              --トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE getprofile_err_expt;
    END IF;
    -- XXCSM:入金値引品目
    gv_prf_receipt_discnt_item_cd :=  FND_PROFILE.VALUE(cv_receipt_discount_item_cd);
    -- プロファイル値取得に失敗した場合
    IF (gv_prf_receipt_discnt_item_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_00005                     --メッセージコード
                     ,iv_token_name1  => cv_tkn_prf_name                        --トークンコード1
                     ,iv_token_value1 => cv_receipt_discount_item_cd            --トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE getprofile_err_expt;
    END IF;
--// Add End 2011/11/08 Ver.1.5
    -- ===========================================
    -- A-1: ④ 年間販売計画カレンダー存在チェック
    -- ===========================================
    BEGIN
      SELECT  COUNT(1)
      INTO    ln_carender_cnt
      FROM    fnd_flex_value_sets  ffv                                      -- 値セットヘッダ
      WHERE   ffv.flex_value_set_name = gv_prf_calender;                    -- 年間販売カレンダー名
      IF (ln_carender_cnt = 0) THEN                                         -- カレンダー存在件数が0件の場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                                              iv_application  => cv_app_name
                                             ,iv_name         => cv_xxcsm_msg_00006
                                             ,iv_token_name1  => cv_tkn_item
                                             ,iv_token_value1 => gv_prf_calender
                     );
        lv_errbuf := lv_errmsg;
        RAISE calendar_check_expt;
      END IF;
    END;
    -- ===========================================
    -- A-1: ⑤ 年間販売計画カレンダー有効年度取得
    -- ===========================================
    -- 共通関数:年間販売計画カレンダー取得関数：GET_YEARPLAN_CALENDER
    xxcsm_common_pkg.get_yearplan_calender(
--//+UPD START      2009/07/31   0000903 M.Ohtsuki
--                                           id_comparison_date  => cd_creation_date  -- 日付
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                                           id_comparison_date  => gd_process_date  -- 業務日付
--//+ADD END        2009/07/31   0000903 M.Ohtsuki
                                          ,ov_status           => lv_result         -- 処理結果(0：有効年度が1つの場合(正常)
                                                                                    --          1：有効年度が複数または0個の場合(異常)
                                          ,on_active_year      => gn_active_year    -- 対象年度（処理結果が0の場合のみセット）
                                          ,ov_retcode          => ln_retcode
                                          ,ov_errbuf           => lv_errbuf
                                          ,ov_errmsg           => lv_errmsg
    );
    IF (ln_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                                            iv_application  => cv_app_name
                                           ,iv_name         => cv_xxcsm_msg_00004
                                           ,iv_token_name1  => cv_tkn_item
                                           ,iv_token_value1 => gv_prf_calender
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
    -- *** プロファイル取得例外ハンドラ ***
    WHEN getprofile_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 年間販売計画カレンダー未存在例外ハンドラ ***
    WHEN calendar_check_expt THEN
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
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
--//+ADD START     2009/03/24   T1_0097 M.Ohtsuki
  /**********************************************************************************
   * Procedure Name   : del_existing_data
   * Description      : 既存データ削除処理
   ***********************************************************************************/
  PROCEDURE del_existing_data(
     ov_errbuf           OUT NOCOPY VARCHAR2                                                        -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                                        -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                                        -- ユーザー・エラー・メッセージ
    )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'del_existing_data';                           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_forecast_designator  CONSTANT VARCHAR2(2)   := '05';                                         -- Forecast分類 固定値：'05’ (販売計画)
    cv_item_kbn             CONSTANT VARCHAR2(1)   := '1';                                          -- 商品区分:'1'
--//+ADD START 2009/05/11   T1_0942 M.Ohtsuki
    cv_new_item             CONSTANT VARCHAR2(1)   := '2';                                          -- 商品区分('2'=新商品）
--//+ADD END   2009/05/11   T1_0942 M.Ohtsuki
    -- *** ローカル・カーソル ***
    CURSOR del_existing_data_cur
    IS
--// Mod Start 2011/11/08 Ver.1.5
--      SELECT ROWID
      SELECT /*+ unnest(@a) */
             ROWID
--// Mod End 2011/11/08 Ver.1.5
      FROM   xxinv_mrp_forecast_interface xxmfi
      WHERE  xxmfi.forecast_designator = cv_forecast_designator                                     -- 固定値:'5'（販売計画）
--// Add Start 2011/11/08 Ver.1.5
      AND    xxmfi.program_application_id = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
      AND    xxmfi.program_id             = cn_program_id              -- コンカレント・プログラムID
--// Add End 2011/11/08 Ver.1.5
      AND    NOT EXISTS
--// Mod Start 2011/11/08 Ver.1.5
--              (SELECT 'X'
              (SELECT /*+ qb_name(a) */
                      'X'
--// Mod End 2011/11/08 Ver.1.5
               FROM   xxcsm_item_plan_headers  xxiph
                     ,xxcsm_item_plan_lines    xxipl
               WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id
               AND    xxiph.plan_year           = gn_active_year                                    -- 対象年度
--//+UPD START 2009/05/11   T1_0942 M.Ohtsuki
--               AND    xxipl.item_kbn = cv_item_kbn                                                -- 固定値:'1'（商品単品）
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
               AND    xxipl.item_kbn IN (cv_item_kbn,cv_new_item)                                   --（商品単品,新商品）
--//+UPD END   2009/05/11   T1_0942 M.Ohtsuki
               AND    xxipl.item_no             = xxmfi.item_code                                   -- 商品コード
               AND    xxiph.location_cd         = xxmfi.base_code                                   -- 拠点コード
               AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date      -- 開始日付
               AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date  -- 終了日付
               )
--// Add Start 2011/11/08 Ver.1.5
      AND    NOT EXISTS
              (SELECT 'X'
               FROM   xxcsm_item_plan_headers  xiph
                     ,xxcsm_item_plan_loc_bdgt xiplb
               WHERE  xiplb.item_plan_header_id = xiph.item_plan_header_id
               AND    xiph.plan_year = gn_active_year                                               -- 対象年度
               AND     ((xiplb.sales_discount <> 0                                                  -- 売上値引額
                   AND   xxmfi.item_code = gv_prf_sales_discnt_item_cd)                             -- 売上値引品目コード
                 OR     (xiplb.receipt_discount <> 0                                                -- 入金値引額
                   AND   xxmfi.item_code = gv_prf_receipt_discnt_item_cd))                          -- 入金値引品目コード
               AND    xiph.location_cd = xxmfi.base_code                                            -- 拠点コード
               AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date      -- 開始日付
               AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date  -- 終了日付
              )
--// Add End 2011/11/08 Ver.1.5
      FOR UPDATE NOWAIT
      ;
    -- *** ローカル例外 ***
    rock_err_expt        EXCEPTION;
--
  BEGIN
--
--
    -- ロックの取得
    BEGIN
      OPEN  del_existing_data_cur;
      CLOSE del_existing_data_cur;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE rock_err_expt;
    END;
--
    --対象データ削除処理
    DELETE FROM xxinv_mrp_forecast_interface  xxmfi                                                 -- 販売計画/引取計画I/Fテーブル
    WHERE  xxmfi.forecast_designator    = cv_forecast_designator                                    -- 固定値:'5'（販売計画）
    AND    xxmfi.program_application_id = cn_program_application_id                                 -- コンカレント・プログラム・アプリケーションID
    AND    xxmfi.program_id             = cn_program_id                                             -- コンカレント・プログラムID
    AND    NOT  EXISTS
               (SELECT 'X'
                FROM   xxcsm_item_plan_headers  xxiph                                               -- 商品計画用販売実績ヘッダ
                      ,xxcsm_item_plan_lines    xxipl                                               -- 商品計画用販売実績明細
                WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id                        -- ヘッダID紐付け
                AND    xxiph.plan_year           = gn_active_year                                   -- 対象年度
--//+UPD START 2009/05/11   T1_0942 M.Ohtsuki
--                AND    xxipl.item_kbn = cv_item_kbn                                               -- 固定値:'1'（商品単品）
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                AND    xxipl.item_kbn IN (cv_item_kbn,cv_new_item)                                  --（商品単品,新商品）
--//+UPD END   2009/05/11   T1_0942 M.Ohtsuki
                AND    xxipl.item_no             = xxmfi.item_code                                  -- 商品コード
                AND    xxiph.location_cd         = xxmfi.base_code                                  -- 拠点コード
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date     -- 開始日付
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date -- 終了日付
--// Add Start 2011/11/08 Ver.1.5
               )
    AND    NOT EXISTS
              (SELECT 'X'
               FROM   xxcsm_item_plan_headers  xiph
                     ,xxcsm_item_plan_loc_bdgt xiplb
               WHERE  xiplb.item_plan_header_id = xiph.item_plan_header_id
               AND    xiph.plan_year = gn_active_year                                               -- 対象年度
               AND     ((xiplb.sales_discount <> 0                                                  -- 売上値引額
                   AND   xxmfi.item_code = gv_prf_sales_discnt_item_cd)                             -- 売上値引品目コード
                 OR     (xiplb.receipt_discount <> 0                                                -- 入金値引額
                   AND   xxmfi.item_code = gv_prf_receipt_discnt_item_cd))                          -- 入金値引品目コード
               AND    xiph.location_cd = xxmfi.base_code                                            -- 拠点コード
               AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date      -- 開始日付
               AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date  -- 終了日付
--// Add End 2011/11/08 Ver.1.5
               );
  EXCEPTION
    -- *** 販売計画/引取計画I/Fテーブルロック例外ハンドラ ***
    WHEN rock_err_expt THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                                                -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_10154                                         -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;                                                                -- ステータス:エラー
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_existing_data;
--
--//+ADD END        2009/03/24   T1_0097 M.Ohtsuki
  /**********************************************************************************
   * Procedure Name   : del_forecast_firstif
   * Argument         : iv_kyoten_cd   [拠点コード]
   * Description      : 販売計画/引取計画I/Fテーブル事前削除処理(A-3)
   ***********************************************************************************/
  PROCEDURE del_forecast_firstif(
     iv_kyoten_cd        IN  VARCHAR2                                           -- 拠点コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'del_forecast_firstif';    -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                        -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                           -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                        -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--//+UPD START 2009/02/24   CT063 M.Ohtsuki
--    cv_forecast_designator  CONSTANT VARCHAR2(1)   := '5';                      -- Forecast分類 固定値：’5’ (販売計画)
    cv_forecast_designator  CONSTANT VARCHAR2(2)   := '05';                      -- Forecast分類 固定値：'05’ (販売計画)
--//+UPD END   2009/02/24   CT063 M.Ohtsuki
    cv_item_kbn             CONSTANT VARCHAR2(1)   := '1';                      -- 商品区分:'1'
--//+ADD START 2009/05/11   T1_0942 M.Ohtsuki
    cv_new_item             CONSTANT VARCHAR2(1)   := '2';                                          -- 商品区分('2'=新商品）
--//+ADD END   2009/05/11   T1_0942 M.Ohtsuki
    -- *** ローカル・カーソル ***
    CURSOR del_forecast_firstif_cur
    IS
--// Mod Start 2011/11/08 Ver.1.5
--      SELECT ROWID
      SELECT /*+ push_subq(@a) push_subq(@b) */
             ROWID
--// Mod End 2011/11/08 Ver.1.5
      FROM   xxinv_mrp_forecast_interface xxmfi
      WHERE  xxmfi.forecast_designator = cv_forecast_designator     -- 固定値:'5'（販売計画）
--// Add Start 2011/11/08 Ver.1.5
      AND    xxmfi.program_application_id = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
      AND    xxmfi.program_id             = cn_program_id              -- コンカレント・プログラムID
      AND    xxmfi.base_code              = iv_kyoten_cd               -- 拠点コード
--// Add End 2011/11/08 Ver.1.5
--// Mod Start 2011/11/08 Ver.1.5
--      AND EXISTS (SELECT 'X'
      AND (EXISTS (SELECT /*+ index(xxipl xxcsm_item_plan_lines_n01) qb_name(a) */
                          'X'
--// Mod End 2011/11/08 Ver.1.5
                  FROM   xxcsm_item_plan_headers  xxiph
                        ,xxcsm_item_plan_lines    xxipl
                  WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id
--//+UPD START 2009/05/11   T1_0942 M.Ohtsuki
--                  AND    xxipl.item_kbn = cv_item_kbn                               -- 固定値:'1'（商品単品）
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                  AND    xxipl.item_kbn IN (cv_item_kbn,cv_new_item)                                --（商品単品,新商品）
--//+UPD END   2009/05/11   T1_0942 M.Ohtsuki
                  AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date        --開始日付
                  AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date    --終了日付
                  AND    xxipl.item_no = xxmfi.item_code                            -- 商品コード
                  AND    xxiph.location_cd = iv_kyoten_cd                           -- 拠点コード
                  AND    xxiph.location_cd = xxmfi.base_code                        -- 拠点コード
--// Add Start 2011/11/08 Ver.1.5
                  AND    xxiph.plan_year   = gn_active_year                         -- 年度
--// Add End 2011/11/08 Ver.1.5
                 )
--// Add Start 2011/11/08 Ver.1.5
        OR EXISTS (SELECT /*+ qb_name(b) */
                          'X'
                   FROM   xxcsm_item_plan_headers  xiph
                         ,xxcsm_item_plan_loc_bdgt xiplb
                   WHERE  xiplb.item_plan_header_id = xiph.item_plan_header_id
                   AND     ((xiplb.sales_discount <> 0                                                  -- 売上値引額
                       AND   xxmfi.item_code = gv_prf_sales_discnt_item_cd)                             -- 売上値引品目コード
                     OR     (xiplb.receipt_discount <> 0                                                -- 入金値引額
                       AND   xxmfi.item_code = gv_prf_receipt_discnt_item_cd))                          -- 入金値引品目コード
                   AND    xiph.location_cd = xxmfi.base_code                                            -- 拠点コード
                   AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date      -- 開始日付
                   AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date  -- 終了日付
                   AND    xiph.location_cd = iv_kyoten_cd                                               -- 拠点コード
                   AND    xiph.plan_year = gn_active_year                                               -- 年度
                  )
          )
--// Add End 2011/11/08 Ver.1.5
      FOR UPDATE NOWAIT
      ;
    -- *** ローカル例外 ***
    rock_err_expt        EXCEPTION;
--
    PRAGMA EXCEPTION_INIT(rock_err_expt,-54);
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ロックの取得
    OPEN del_forecast_firstif_cur;
    CLOSE del_forecast_firstif_cur;
    --対象データ削除処理
--// Mod Start 2011/11/08 Ver.1.5
--    DELETE FROM xxinv_mrp_forecast_interface  xxmfi               -- 販売計画/引取計画I/Fテーブル
    DELETE /*+ push_subq(@a) push_subq(@b) */
    FROM xxinv_mrp_forecast_interface  xxmfi               -- 販売計画/引取計画I/Fテーブル
--// Mod End 2011/11/08 Ver.1.5
    WHERE  xxmfi.forecast_designator = cv_forecast_designator     -- 固定値:'5'（販売計画）
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
    AND    xxmfi.program_application_id = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
    AND    xxmfi.program_id             = cn_program_id              -- コンカレント・プログラムID
--//+ADD END   2009/02/24   CT063 M.Ohtsuki
--// Add Start 2011/11/08 Ver.1.5
    AND    xxmfi.base_code              = iv_kyoten_cd               -- 拠点コード
--// Add End 2011/11/08 Ver.1.5
--// Mod Start 2011/11/08 Ver.1.5
--    AND EXISTS (SELECT 'X'
    AND (EXISTS (SELECT /*+ index(xxipl xxcsm_item_plan_lines_n01) qb_name(a) */
                        'X'
--// Mod End 2011/11/08 Ver.1.5
                FROM   xxcsm_item_plan_headers  xxiph
                      ,xxcsm_item_plan_lines    xxipl
                WHERE  xxiph.item_plan_header_id = xxipl.item_plan_header_id
--//+UPD START 2009/05/11   T1_0942 M.Ohtsuki
--                AND    xxipl.item_kbn = cv_item_kbn                               -- 固定値:'1'（商品単品）
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                AND    xxipl.item_kbn IN (cv_item_kbn,cv_new_item)                                  --（商品単品,新商品）
--//+UPD END   2009/05/11   T1_0942 M.Ohtsuki
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date        --開始日付
                AND    TRUNC(TO_DATE(xxipl.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date    --終了日付
                AND    xxipl.item_no = xxmfi.item_code                            -- 商品コード
                AND    xxiph.location_cd = iv_kyoten_cd                           -- 拠点コード
                AND    xxiph.location_cd = xxmfi.base_code                        -- 拠点コード
--// Add Start 2011/11/08 Ver.1.5
                AND    xxiph.plan_year   = gn_active_year                         -- 年度
--// Add End 2011/11/08 Ver.1.5
               )
--// Add Start 2011/11/08 Ver.1.5
    OR   EXISTS (SELECT /*+ qb_name(b) */
                        'X'
                 FROM   xxcsm_item_plan_headers  xiph
                       ,xxcsm_item_plan_loc_bdgt xiplb
                 WHERE  xiplb.item_plan_header_id = xiph.item_plan_header_id
                 AND     ((xiplb.sales_discount <> 0                                                  -- 売上値引額
                     AND   xxmfi.item_code = gv_prf_sales_discnt_item_cd)                             -- 売上値引品目コード
                   OR     (xiplb.receipt_discount <> 0                                                -- 入金値引額
                     AND   xxmfi.item_code = gv_prf_receipt_discnt_item_cd))                          -- 入金値引品目コード
                 AND    xiph.location_cd = xxmfi.base_code                                            -- 拠点コード
                 AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_date      -- 開始日付
                 AND    TRUNC(TO_DATE(xiplb.year_month,'YYYYMM'), 'MONTH') = xxmfi.forecast_end_date  -- 終了日付
                 AND    xiph.location_cd = iv_kyoten_cd                                               -- 拠点コード
                 AND    xiph.plan_year = gn_active_year                                               -- 年度
                )
        )
--// Add End 2011/11/08 Ver.1.5
    ;
  EXCEPTION
    -- *** 販売計画/引取計画I/Fテーブルロック例外ハンドラ ***
    WHEN rock_err_expt THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            -- アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_10134                     -- メッセージコード
                     ,iv_token_name1  => cv_tkn_kyotencd                        -- トークンコード1
                     ,iv_token_value1 => iv_kyoten_cd                           -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_warn;   -- ステータス:警告
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END del_forecast_firstif;
--
  /**********************************************************************************
   * Procedure Name   : get_compute_count
   * Argument         : iv_item_cd   [商品コード]
   *                  : in_amount    [数量]
   * Description      : 単位換算処理（A-4）
   ***********************************************************************************/
--//+DEL START 2009/03/24   T1_0117 M.Ohtsuki
/*
  PROCEDURE get_compute_count(
     iv_item_cd          IN  VARCHAR2                                           -- 商品コード
    ,in_amount           IN  NUMBER                                             -- 数量
    ,on_case_count       OUT NUMBER                                             -- ケース数量
    ,on_bara_count       OUT NUMBER                                             -- バラ数量
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_compute_count';                           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
--
    -- *** ローカル変数 ***
    lv_insert_count      VARCHAR2(100);                                          -- 入数格納用
    -- *** ローカル・カーソル ***
    CURSOR get_compute_cur(
      iv_item_cd       VARCHAR2
    )
    IS
      SELECT iimb.attribute11          insert_count   -- 入数
      FROM   ic_item_mst_b             iimb           -- OPM品目マスタ
            ,mtl_system_items_b        msib           -- 品目マスタ
      WHERE  iimb.item_no = iv_item_cd                -- A-2で取得した商品コード
      AND    iimb.item_no = msib.segment1             -- OPM品目マスタ．品目コード ＝ 品目マスタ．品目コード
      AND    ROWNUM <= 1
      ;
    -- *** ローカル・レコード ***
    get_compute_rec    get_compute_cur%ROWTYPE;
--
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- カーソルオープン
    OPEN get_compute_cur(iv_item_cd);
      FETCH get_compute_cur INTO get_compute_rec;
    -- カーソルクローズ
    CLOSE get_compute_cur;
    -- =============================
    -- A-3: ②出力パラメータ設定
    -- =============================
    -- ①ケース入数が取得できた場合
    IF (in_amount IS NOT NULL) AND
       (get_compute_rec.insert_count IS NOT NULL) AND
       (get_compute_rec.insert_count <> 0)
    THEN
      on_case_count := TRUNC(in_amount/TO_NUMBER(get_compute_rec.insert_count));
      on_bara_count := MOD(in_amount,TO_NUMBER(get_compute_rec.insert_count));
    -- ②ケース入数が取得できなかった場合
    ELSE
      on_case_count := 0;
      on_bara_count := in_amount;   -- 数量を全てバラ数とする
    END IF;
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_compute_count;
*/
--//+DEL END   2009/03/24   T1_0117 M.Ohtsuki
  /**********************************************************************************
   * Procedure Name   : insert_forecast_if
   * Argument         : iv_kyoten_cd    [拠点コード]
   *                  : iv_item_cd      [商品コード]
   *                  : in_year_month   [年月]
   *                  : in_case_count   [ケース数量]
   *                  : in_bara_count   [バラ数量]
   *                  : in_sales_budget [売上金額]
   * Description      : 年間商品計画データ登録（A-5）
   ***********************************************************************************/
  PROCEDURE insert_forecast_if(
     iv_kyoten_cd        IN  VARCHAR2                                           -- 拠点コード
    ,iv_item_cd          IN  VARCHAR2                                           -- 商品コード
    ,in_year_month       IN  NUMBER                                             -- 年月
--//+DEL START 2009/03/24  T1_0117 M.Ohtsuki
--    ,in_case_count       IN  NUMBER                                             -- ケース数量
--//+DEL END   2009/03/24  T1_0117 M.Ohtsuki
    ,in_bara_count       IN  NUMBER                                             -- バラ数量
    ,in_sales_budget     IN  NUMBER                                             -- 売上金額
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_forecast_if';                              -- プログラム名

--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                                            -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                                               -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                                            -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
--    cn_forecast          CONSTANT VARCHAR2(1)     := '5';                       -- 固定値:'5'（販売計画）
      cn_forecast          CONSTANT VARCHAR2(2)     := '05';                       -- 固定値:'5'（販売計画）
--//+ADD START 2009/02/24   CT063 M.Ohtsuki
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  --販売計画/引取計画I/Fテーブル登録処理
    INSERT INTO xxinv_mrp_forecast_interface(
       forecast_if_id
      ,forecast_designator
      ,base_code
      ,item_code
      ,forecast_date
      ,forecast_end_date
      ,case_quantity
      ,indivi_quantity
      ,amount
      ,created_by
      ,creation_date
      ,last_updated_by
      ,last_update_date
      ,last_update_login
      ,request_id
      ,program_application_id
      ,program_id
      ,program_update_date
    )VALUES(
       XXINV_MRP_FRCST_IF_S1.NEXTVAL
      ,cn_forecast
      ,iv_kyoten_cd
      ,iv_item_cd
      ,TRUNC(TO_DATE(in_year_month,'YYYYMM'), 'MONTH')
      ,TRUNC(TO_DATE(in_year_month,'YYYYMM'), 'MONTH')
--//+UPD  START 2009/03/24  T1_0117 M.Ohtsuki
--      ,in_case_count
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ,0
--//+UPD  END   2009/03/24  T1_0117  M.Ohtsuki
      ,in_bara_count
      ,in_sales_budget
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END insert_forecast_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   *                    年間商品計画データ取得 (A-2)
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf         OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                      -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';                      -- プログラム名
    cv_year_bdgt_kbn  CONSTANT VARCHAR2(1)   := '0';                            -- 年間群予算区分‘0’(各月単位予算)
    cv_item_kbn       CONSTANT VARCHAR2(1)   := '1';                            -- 商品区分 ＝ ‘1’(商品単品)
--//+ADD START 2009/05/11   T1_0942 M.Ohtsuki
    cv_new_item       CONSTANT VARCHAR2(1)   := '2';                                                -- 商品区分('2'=新商品）
--//+ADD END   2009/05/11   T1_0942 M.Ohtsuki
    cn_sts_normal     CONSTANT  NUMBER       :=  1;                              -- 無
    cn_sts_error      CONSTANT  NUMBER       :=  2;                              -- 有
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                           -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                              -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                           -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
--//+DEL START 2009/03/24  T1_0117 M.Ohtsuki
--    ln_case_count     NUMBER;
--    ln_bara_count     NUMBER;
--//+DEL END   2009/03/24  T1_0117 M.Ohtsuki
    lt_kyoten_cd      XXCSM_ITEM_PLAN_HEADERS.LOCATION_CD%TYPE;
    ln_sts_flg        NUMBER;
    ln_location_count NUMBER;

    -- *** ローカル・カーソル ***  年間商品計画データ取得
    CURSOR year_item_date_cur
    IS
      SELECT xipl.year_month       nengetsu                                     -- 年月
            ,xiph.location_cd      kyoten_cd                                    -- 拠点コード
            ,xipl.item_no          syouhin_cd                                   -- 商品コード
            ,xipl.amount           suryo                                        -- 数量
            ,xipl.sales_budget     urikin                                       -- 売上金額
      FROM   xxcsm_item_plan_headers xiph                                       -- 商品計画ヘッダテーブル
            ,xxcsm_item_plan_lines xipl                                         -- 商品計画明細テーブル
      WHERE  xiph.item_plan_header_id = xipl.item_plan_header_id                 -- ヘッダIDで関連付け
        AND  xiph.plan_year = gn_active_year                                     -- 商品計画ヘッダテーブル．予算年度 ＝ A-1で取得した年度
        AND  xipl.year_bdgt_kbn = cv_year_bdgt_kbn                               -- 商品計画明細テーブル．年間群予算区分 ＝‘0’(各月単位予算)
--//+UPD START 2009/05/11   T1_0942 M.Ohtsuki
--        AND    xipl.item_kbn = cv_item_kbn                                       -- 固定値:'1'（商品単品）
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
        AND    xipl.item_kbn IN (cv_item_kbn,cv_new_item)                                          --（商品単品,新商品）
--//+UPD END   2009/05/11   T1_0942 M.Ohtsuki
--// Mod Start 2011/11/08 Ver.1.5
----//+ADD START 2009/02/24   CT063 M.Ohtsuki
--        AND  xipl.amount <> 0                                                    -- 商品計画明細テーブル. 数量 <> 0
----//+ADD END   2009/02/24   CT063 M.Ohtsuki
        AND  (xipl.amount <> 0                                                   -- 商品計画明細テーブル. 数量 <> 0
          OR  xipl.sales_budget <> 0)                                            -- 商品計画明細テーブル. 売上金額 <> 0
--// Mod End 2011/11/08 Ver.1.5
        AND  NOT EXISTS (SELECT 'X'
                         FROM   fnd_lookup_values         flv                      --クイックコード値
                               ,mtl_categories_b          mcb                      --品目カテゴリ
                               ,mtl_category_sets_b       mcsb                     --品目カテゴリ
                               ,fnd_id_flex_structures    fifs                     --キーフレックスフィールド
                               ,gmi_item_categories       gic                      --品目カテゴリ割当
                               ,ic_item_mst_b             iimb                     --OPM品目マスタ
                         WHERE  flv.lookup_type = 'XXCSM1_ITEM_KBN'                --コードタイプ:品目区分（"XXCSM1_ITEM_KBN”）
                         AND    flv.language = USERENV('LANG')                     --言語
                         AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                         AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                         AND    NVL(flv.enabled_flag,'Y') = 'Y'
                         AND    flv.lookup_code = mcb.segment1                     --品目区分の値
                         AND    mcsb.structure_id = mcb.structure_id
                         AND    mcb.enabled_flag = 'Y'
                         AND    NVL(mcb.disable_date,gd_process_date) <= gd_process_date
                         AND    fifs.id_flex_structure_code = 'XXCA_ITEM_CLASS'    -- キーフレックスフィールド：品目区分
                         AND    fifs.application_id = 401                          -- Inventory
                         AND    fifs.id_flex_code = 'MCAT'                         -- 品目カテゴリのコード
                         AND    fifs.id_flex_num = mcsb.structure_id
                         AND    iimb.item_id = gic.item_id
                         AND    gic.category_id = mcb.category_id
                         AND    gic.category_set_id = mcsb.category_set_id
                         AND    iimb.item_no = xipl.item_no                        -- 品目マスタと商品計画明細テーブルの商品コードを関連付け
                         )
--// Add Start 2011/11/08 Ver.1.5
      UNION ALL
      SELECT xiplb.year_month             nengetsu    -- 年月
            ,xiph.location_cd             kyoten_cd   -- 拠点コード
            ,gv_prf_sales_discnt_item_cd  syouhin_cd  -- 商品コード
            ,0                            suryo       -- 数量
            ,xiplb.sales_discount         urikin      -- 売上金額（売上値引額）
      FROM   xxcsm_item_plan_headers  xiph                         -- 商品計画ヘッダテーブル
            ,xxcsm_item_plan_loc_bdgt xiplb                        -- 商品計画拠点別予算テーブル
      WHERE  xiplb.item_plan_header_id = xiph.item_plan_header_id  -- ヘッダIDで関連付け
      AND    xiph.plan_year = gn_active_year                       -- 商品計画ヘッダテーブル．予算年度 ＝ A-1で取得した年度
      AND    xiplb.sales_discount <> 0                             -- 商品計画拠点別予算テーブル．売上値引 <> 0
      UNION ALL
      SELECT xiplb.year_month               nengetsu    -- 年月
            ,xiph.location_cd               kyoten_cd   -- 拠点コード
            ,gv_prf_receipt_discnt_item_cd  syouhin_cd  -- 商品コード
            ,0                              suryo       -- 数量
            ,xiplb.receipt_discount         urikin      -- 売上金額（入金値引額）
      FROM   xxcsm_item_plan_headers  xiph                         -- 商品計画ヘッダテーブル
            ,xxcsm_item_plan_loc_bdgt xiplb                        -- 商品計画拠点別予算テーブル
      WHERE  xiplb.item_plan_header_id = xiph.item_plan_header_id  -- ヘッダIDで関連付け
      AND    xiph.plan_year = gn_active_year                       -- 商品計画ヘッダテーブル．予算年度 ＝ A-1で取得した年度
      AND    xiplb.receipt_discount <> 0                           -- 商品計画拠点別予算テーブル．入金値引 <> 0
--// Add End 2011/11/08 Ver.1.5
--// Mod Start 2011/11/08 Ver.1.5
--      ORDER BY xiph.location_cd
--              ,xipl.year_month
--              ,xipl.item_no
      ORDER BY kyoten_cd
              ,nengetsu
              ,syouhin_cd
--// Mod End 2011/11/08 Ver.1.5
      ;
    -- *** ローカル・レコード ***
    year_item_date_rec    year_item_date_cur%ROWTYPE;
    -- *** ローカル例外 ***
    global_skip_expt    EXCEPTION;
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --グローバル変数の初期化
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_error_cnt   := 0;
    gn_warn_cnt    := 0;
    ln_location_count := 0;
--
    -- ======================================
    -- A-1.初期処理
    -- ======================================
    init(
       ov_errbuf       => lv_errbuf                                             -- エラー・メッセージ
      ,ov_retcode      => lv_retcode                                            -- リターン・コード
      ,ov_errmsg       => lv_errmsg                                             -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--//+ADD START  2009/03/24  T1_0097 M.Ohtsuki
    -- ======================================
    -- 既存データ削除処理
    -- ======================================
    del_existing_data(
       ov_errbuf       => lv_errbuf                                             -- エラー・メッセージ
      ,ov_retcode      => lv_retcode                                            -- リターン・コード
      ,ov_errmsg       => lv_errmsg                                             -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--//+ADD END    2009/03/24  T1_0097 M.Ohtsuki
    -- ======================================
    -- ローカル・カーソルオープン
    -- ======================================
    OPEN year_item_date_cur;
    <<year_item_date_loop>>
    LOOP
      FETCH year_item_date_cur INTO year_item_date_rec;
      EXIT WHEN year_item_date_cur%NOTFOUND;
      BEGIN
        -- ==========================
        -- キーブレイク
        -- ==========================
        IF (year_item_date_rec.kyoten_cd = lt_kyoten_cd) THEN
          NULL;
        ELSE
          -- キーブレイク元の拠点件数を纏めてカウントアップする。
          IF (ln_sts_flg = cn_sts_normal) THEN
            gn_normal_cnt := gn_normal_cnt + ln_location_count;
          ELSIF (ln_sts_flg = cn_sts_error) THEN
            --エラー件数のカウント
            gn_error_cnt := gn_error_cnt + ln_location_count;
          ELSE
            NULL;
          END IF;
          --拠点件数のクリア；
          ln_location_count := 0;
          --スキップフラグのクリア
          ln_sts_flg       :=  cn_sts_normal;
          --拠点単位でセーブポイント
          SAVEPOINT item_date_sv;
          -- ==========================================
          -- 販売計画/引取計画I/Fテーブル事前削除処理
          -- ==========================================
          del_forecast_firstif(
             iv_kyoten_cd    =>   year_item_date_rec.kyoten_cd
            ,ov_errbuf       =>   lv_errbuf                                          -- エラー・メッセージ
            ,ov_retcode      =>   lv_retcode                                         -- リターン・コード
            ,ov_errmsg       =>   lv_errmsg                                          -- ユーザー・エラー・メッセージ
          );
          -- Oracleエラーならば、処理を中止する。（ステータスはエラー）
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_api_expt;
          -- 警告(ロック取得エラー)ならば、拠点単位で処理をスキップする。（ステータスは警告）
          ELSIF (lv_retcode = cv_status_warn) THEN
            RAISE global_skip_expt;
          END IF;
        END IF;
--
        --拠点でエラーが発生している場合、その拠点データはスキップさせる。
        IF (ln_sts_flg = cn_sts_error) THEN
          RAISE global_skip_expt;
        END IF;
--
--// Del Start 2011/11/08 Ver.1.5  （2009/03/24 T1_0117 にて換算処理は削除されているためコメント削除）
--        -- 数量がNULLだった場合、又は0の場合、
--        -- 後の単位換算処理のケース数の除算にて、NULL又は0で除算を行うことになる。
--        -- そのエラーを防ぐため、global_skip_exptとして警告を上げる。
--// Del End 2011/11/08 Ver.1.5
--// Add Start 2011/11/08 Ver.1.5
        -- 数量がNULLの場合、global_skip_exptとして警告を上げる。
        -- Ver.1.5 対応により、数量0も連携する必要があるため　数量＝0の場合のエラーチェックを削除
--// Add End 2011/11/08 Ver.1.5
        IF (year_item_date_rec.suryo IS NULL)
--// Del Start 2011/11/08 Ver.1.5
--          OR (year_item_date_rec.suryo = 0)
--// Del End 2011/11/08 Ver.1.5
        THEN
          lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              --アプリケーション短縮名
                       ,iv_name         => cv_xxcsm_msg_10137                       --メッセージコード
                       ,iv_token_name1  => cv_tkn_itemcd                            --トークンコード1
                       ,iv_token_value1 => year_item_date_rec.syouhin_cd            --トークン値1
                       ,iv_token_name2  => cv_tkn_kyotencd                          --トークンコード2
                       ,iv_token_value2 => year_item_date_rec.kyoten_cd             --トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_skip_expt;
        END IF;
        -- ======================================
        -- A-3.単位換算処理
        -- ======================================
--//+DEL START 2009/03/24  T1_0117 M.Ohtsuki
/*
        get_compute_count(
           iv_item_cd      => year_item_date_rec.syouhin_cd                        -- 商品コード
          ,in_amount       => year_item_date_rec.suryo                             -- 数量(数量は小数点第1まで持つ)
          ,on_case_count   => ln_case_count
          ,on_bara_count   => ln_bara_count
          ,ov_errbuf       => lv_errbuf                                            -- エラー・メッセージ
          ,ov_retcode      => lv_retcode                                           -- リターン・コード
          ,ov_errmsg       => lv_errmsg                                            -- ユーザー・エラー・メッセージ
        );
        -- エラーならば、処理をスキップする。
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        END IF;
*/
--//+DEL END     2009/03/24  T1_0117 M.Ohtsuki
        -- ======================================
        -- A-5.年間商品計画データ登録
        -- ======================================
        insert_forecast_if(
           iv_kyoten_cd    => year_item_date_rec.kyoten_cd                        -- 拠点コード
          ,iv_item_cd      => year_item_date_rec.syouhin_cd                       -- 商品コード
          ,in_year_month   => year_item_date_rec.nengetsu                         -- 対象年月
--//+UPD START 2009/03/24   T1_0117 M.Ohtsuki
--          ,in_case_count   => ln_case_count                                       -- ケース数量
--          ,in_bara_count   => ln_bara_count                                       -- バラ数量
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
          ,in_bara_count   => year_item_date_rec.suryo                            -- バラ数量
--//+UPD END   2009/03/24   T1_0117 M.Ohtsuki
          ,in_sales_budget => year_item_date_rec.urikin                           -- 売上金額
          ,ov_errbuf       => lv_errbuf                                           -- エラー・メッセージ
          ,ov_retcode      => lv_retcode                                          -- リターン・コード
          ,ov_errmsg       => lv_errmsg                                           -- ユーザー・エラー・メッセージ
        );
        -- エラーならば、処理をスキップする。
        IF (lv_retcode <> cv_status_normal) THEN
          RAISE global_api_expt;
        END IF;
        -- 拠点コードの格納
        lt_kyoten_cd := year_item_date_rec.kyoten_cd;
      EXCEPTION
        WHEN global_skip_expt THEN
          --拠点単位でエラーが発生した初回のデータのみメッセージ出力
          IF (ln_sts_flg = cn_sts_normal) THEN
            -- 拠点コードの格納
            lt_kyoten_cd := year_item_date_rec.kyoten_cd;
            ln_sts_flg       :=  cn_sts_error;
            -- ロールバック
            ROLLBACK TO item_date_sv;
            lv_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
            --エラー出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_errmsg                                                    -- ユーザー・エラーメッセージ
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => lv_errbuf                                                    -- エラーメッセージ
            );
            ov_retcode := cv_status_warn;
          END IF;
      END;
      ln_location_count := ln_location_count + 1;
    END LOOP year_item_date_loop;
--
    -- 処理対象件数格納
    gn_target_cnt := year_item_date_cur%ROWCOUNT;
--
    -- 最終拠点件数を纏めてカウントアップする。
    IF (ln_sts_flg = cn_sts_normal) THEN
      gn_normal_cnt := gn_normal_cnt +  ln_location_count;
    ELSE
      gn_error_cnt := gn_error_cnt + ln_location_count;
    END IF;
--
    -- カーソルクローズ
    CLOSE year_item_date_cur;
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- 0件メッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                                                 --アプリケーション短縮名
                    ,iv_name         => cv_xxcsm_msg_10001                                            --メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      --メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                    -- ユーザー・エラーメッセージ
      );
    END IF;
  EXCEPTION
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   *                    終了処理 （A-7）
   **********************************************************************************/
--
  PROCEDURE main(
     errbuf           OUT NOCOPY VARCHAR2                                                              -- エラー・メッセージ
    ,retcode          OUT NOCOPY VARCHAR2                                                              -- リターン・コード
    )
    --
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';                                            -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';                                           -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';                                -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';                                -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';                                -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';                                -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';                                           -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';                                -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';                                -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';                                -- エラー終了全ロールバック
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(4000);                                                              -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);                                                                 -- リターン・コード
    lv_errmsg          VARCHAR2(4000);                                                              -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);                                                               -- 終了メッセージコード
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
       ov_errbuf        => lv_errbuf                                            -- エラー・メッセージ
      ,ov_retcode       => lv_retcode                                           -- リターン・コード
      ,ov_errmsg        => lv_errmsg                                            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF (lv_errmsg IS NULL) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_00111                          -- 想定外エラーメッセージ
                     );
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                    -- ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                                                    -- エラーメッセージ
      );
      --件数の振替(エラーの場合、エラー件数を1件のみ表示させる。）
      gn_target_cnt := 0;
      gn_normal_cnt := 0;
      gn_error_cnt  := 1;
      gn_warn_cnt   := 0;
    END IF;
--
    -- =======================
    -- A-6.終了処理
    -- =======================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
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
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
END XXCSM002A15C;
/
