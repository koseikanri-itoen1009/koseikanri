CREATE OR REPLACE PACKAGE BODY XXCFF019A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCFF019A05C(body)
 * Description      : IFRS台帳除売却
 * MD.050           : MD050_CFF_019_A05_IFRS台帳除売却
 * Version          : 1.0
 *
 * Program List
 * ----------------------------- ----------------------------------------------------------
 *  Name                          Description
 * ----------------------------- ----------------------------------------------------------
 *  init                          初期処理                                  (A-1)
 *  get_profile_values            プロファイル値取得                        (A-2)
 *  chk_period                    会計期間チェック                          (A-3)
 *  get_exec_date                 実行日時取得                              (A-4)
 *  get_ifrs_fa_retire_data       IFRS台帳除売却データ抽出                  (A-5)
 *  upd_ifrs_sets                 IFRS台帳連携セット更新                    (A-6)
 *  submain                       メイン処理プロシージャ
 *  main                          コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2017/11/07    1.0   SCSK大塚         新規作成
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
  --*** 会計期間チェックエラー
  chk_period_expt           EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  data_lock_expt            EXCEPTION;        -- レコードロックエラー
  PRAGMA EXCEPTION_INIT(data_lock_expt, -54);
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100):= 'XXCFF019A05C'; -- パッケージ名
--
  -- ***アプリケーション短縮名
  cv_msg_kbn_cff      CONSTANT VARCHAR2(5)  := 'XXCFF';
--
  -- ***メッセージ名(本文)
  cv_msg_019a05_m_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00020'; -- プロファイル取得エラー
  cv_msg_019a05_m_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00037'; -- 会計期間チェックエラー
  cv_msg_019a05_m_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00278'; -- 除売却OIF登録メッセージ
  cv_msg_019a05_m_014 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00280'; -- IFRS台帳除売却エラー
  cv_msg_019a05_m_017 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00165'; -- 取得対象データ無しメッセージ
  cv_msg_019a05_m_019 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-00007'; -- ロックエラー
  -- ***メッセージ名(トークン)
  cv_msg_019a05_t_010 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50228'; -- XXCFF:台帳種類_固定資産台帳
  cv_msg_019a05_t_011 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50314'; -- XXCFF:台帳種類_IFRS台帳
  cv_msg_019a05_t_012 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50315'; -- 固定資産台帳情報
  cv_msg_019a05_t_013 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50316'; -- IFRS台帳連携セット
  cv_msg_019a05_t_015 CONSTANT VARCHAR2(20) := 'APP-XXCFF1-50093'; -- XXCFF:按分方法
--
  -- ***トークン名
  cv_tkn_prof         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_asset_number CONSTANT VARCHAR2(20) := 'ASSET_NUMBER';
  cv_tkn_bk_type      CONSTANT VARCHAR2(20) := 'BOOK_TYPE_CODE';
  cv_tkn_period       CONSTANT VARCHAR2(20) := 'PERIOD_NAME';
  cv_tkn_get_data     CONSTANT VARCHAR2(20) := 'GET_DATA';
  cv_tkn_table_name   CONSTANT VARCHAR2(20) := 'TABLE_NAME';
--
  -- ***プロファイル
  cv_fixed_asset_register   CONSTANT VARCHAR2(30) := 'XXCFF1_FIXED_ASSET_REGISTER';       -- 台帳種類_固定資産台帳
  cv_fixed_ifrs_asset_regi  CONSTANT VARCHAR2(35) := 'XXCFF1_FIXED_IFRS_ASSET_REGISTER';  -- 台帳種類_IFRS台帳
  cv_prt_conv_cd_ed         CONSTANT VARCHAR2(30) := 'XXCFF1_PRT_CONV_CD_ED';             -- 按分方法_月末
--
  -- ***ファイル出力
  cv_file_type_out   CONSTANT VARCHAR2(10) := 'OUTPUT'; -- メッセージ出力
  cv_file_type_log   CONSTANT VARCHAR2(10) := 'LOG';    -- ログ出力
--
  cn_zero_0          CONSTANT NUMBER       := 0;        -- 数値ゼロ
  cv_yes             CONSTANT VARCHAR2(1)  := 'Y';
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳除売却対象データレコード型
  TYPE g_ifrs_fa_retire_rtype IS RECORD(
    asset_id                       fa_additions_b.asset_id%TYPE,                       -- 資産ID
    asset_number                   fa_additions_b.asset_number%TYPE,                   -- 資産番号
    date_retired                   fa_retirements.date_retired%TYPE,                   -- 除売却日
    cost                           fa_books.cost%TYPE,                                 -- 除・売却取得価格
    retirement_type_code           fa_retirements.retirement_type_code%TYPE,           -- 除売却タイプ
    proceeds_of_sale               fa_retirements.proceeds_of_sale%TYPE,               -- 売却価格
    cost_of_removal                fa_retirements.cost_of_removal%TYPE,                -- 撤去費用
    retirement_prorate_convention  fa_retirements.retirement_prorate_convention%TYPE   -- 除･売却年度償却
  );
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ***バルクフェッチ用定義
  -- IFRS台帳除売却対象データレコード配列
  TYPE g_ifrs_fa_retire_ttype IS TABLE OF g_ifrs_fa_retire_rtype
  INDEX BY BINARY_INTEGER;
--
  g_ifrs_fa_retire_tab         g_ifrs_fa_retire_ttype;  -- IFRS台帳除売却対象データ
--
  -- パラメータ会計期間名
  gv_period_name            VARCHAR2(100);
--
  -- 実行日時
  gt_exec_date  xxcff_ifrs_sets.exec_date%TYPE;
--
  -- ***プロファイル値
  gv_fixed_asset_register   VARCHAR2(100);  -- 台帳種類_固定資産台帳
  gv_fixed_ifrs_asset_regi  VARCHAR2(100);  -- 台帳種類_IFRS台帳
  gv_prt_conv_cd_ed         VARCHAR2(100);  -- XXCFF:按分方法
--
  -- ***処理件数
  -- IFRS台帳除売却処理における件数
  gn_ifrs_fa_retire_target_cnt NUMBER;     -- 対象件数
  gn_loop_cnt                  NUMBER;     -- LOOP数
  gn_ifrs_fa_retire_normal_cnt NUMBER;     -- 正常件数
  gn_ifrs_fa_retire_err_cnt    NUMBER;     -- エラー件数
--
  /**********************************************************************************
   * Procedure Name   : upd_ifrs_sets
   * Description      : IFRS台帳連携セット更新 (A-6)
   ***********************************************************************************/
  PROCEDURE upd_ifrs_sets(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_ifrs_sets'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
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
    UPDATE xxcff_ifrs_sets  xis       -- IFRS台帳連携セット
    SET    xis.exec_date              = cd_last_update_date         -- 実行日時
          ,xis.last_updated_by        = cn_last_updated_by          -- 最終更新者
          ,xis.last_update_date       = cd_last_update_date         -- 最終更新日
          ,xis.last_update_login      = cn_last_update_login        -- 最終更新ログインID
          ,xis.request_id             = cn_request_id               -- 要求ID
          ,xis.program_application_id = cn_program_application_id   -- コンカレント・プログラム・アプリケーションID
          ,xis.program_id             = cn_program_id               -- コンカレント・プログラムID
          ,xis.program_update_date    = cd_program_update_date      -- プログラム更新日
    WHERE  xis.exec_id                = cv_pkg_name                 -- 処理ID
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
  END upd_ifrs_sets;
--
  /**********************************************************************************
   * Procedure Name   : get_ifrs_fa_retire_data
   * Description      : IFRS台帳除売却データ抽出(A-5)
   ***********************************************************************************/
  PROCEDURE get_ifrs_fa_retire_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100) := 'get_ifrs_fa_retire_data'; -- プログラム名
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
    cv_tran_type_retire   CONSTANT VARCHAR2(16)   := 'FULL RETIREMENT';      -- 取引タイプコード(除売却)
    cv_status_pending     CONSTANT VARCHAR2(7)   := 'PENDING';              -- ステータス：PENDING
--
    -- *** ローカル変数 ***
    lv_warnmsg            VARCHAR2(5000);                                         -- 警告メッセージ
    lb_ret                BOOLEAN;                                                -- 関数リターンコード
--
    -- *** ローカル・カーソル ***
    -- 固定資産台帳カーソル
    CURSOR ifrs_fa_retire_cur
    IS
      SELECT  
      -- 除売却OIF登録用
        ifrs_fab.asset_id                AS asset_id                       -- 資産ID
       ,ifrs_fab.asset_number            AS asset_number                   -- 資産番号
       ,fr.date_retired                  AS date_retired                   -- 除売却日
       ,ifrs_fb.cost                     AS cost_retired                   -- 除･売却取得価格
       ,fr.retirement_type_code          AS retirement_type_code           -- 除売却タイプ
       ,fr.proceeds_of_sale              AS proceeds_of_sale               -- 売却価格
       ,fr.cost_of_removal               AS cost_of_removal                -- 撤去費用
       ,fr.retirement_prorate_convention AS retirement_prorate_convention  -- 除･売却年度償却
      FROM    fa_books                  fb        -- 資産台帳情報
             ,fa_additions_b            fab       -- 資産詳細情報
             ,fa_retirements            fr        -- 除売却情報
             ,fa_additions_b            ifrs_fab  -- 資産詳細情報（IFRS台帳）
             ,fa_books                  ifrs_fb   -- 資産台帳情報
      WHERE   fb.asset_id                   = fab.asset_id
      AND     fb.book_type_code             = gv_fixed_asset_register   -- 資産台帳名(固定資産)
      AND     fb.transaction_header_id_in   IN (
                                                SELECT  fth.transaction_header_id   AS trans_header_id  -- 有効取引ヘッダID
                                                FROM    fa_transaction_headers fth
                                                WHERE   fth.transaction_type_code = cv_tran_type_retire    -- 取引タイプコード('FULL RETIREMENT')
                                                AND     fth.book_type_code        = fb.book_type_code   -- 資産台帳名
                                                AND     fth.asset_id              = fab.asset_id        -- 資産ID
                                                AND     fth.date_effective        > gt_exec_date
                                               )
      AND fab.asset_id                      = fr.asset_id
      AND fb.book_type_code                 = fr.book_type_code
      AND fb.transaction_header_id_in       = fr.transaction_header_id_in
      AND fab.asset_number                  = ifrs_fab.attribute22
      AND ifrs_fb.asset_id                  = ifrs_fab.asset_id
      AND ifrs_fb.book_type_code            = gv_fixed_ifrs_asset_regi
      AND ifrs_fb.date_ineffective          IS NULL
      AND ifrs_fb.period_counter_fully_retired   IS NULL
      AND NOT EXISTS ( -- 既にOIF内に除売却データが登録されている場合を除外
                      SELECT 1
                       FROM  xx01_retire_oif xro
                      WHERE  xro.book_type_code = gv_fixed_ifrs_asset_regi
                        AND  ifrs_fab.asset_number  = xro.asset_number
                     )
      ;
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
    --==============================================================
    --メインデータ抽出
    --==============================================================
    -- カーソルオープン
    OPEN ifrs_fa_retire_cur;
    -- データの一括取得
    FETCH ifrs_fa_retire_cur BULK COLLECT INTO  g_ifrs_fa_retire_tab;
    -- カーソルクローズ
    CLOSE ifrs_fa_retire_cur;
    -- 対象件数の取得
    gn_ifrs_fa_retire_target_cnt := g_ifrs_fa_retire_tab.COUNT;
--
    -- 新規登録対象件数が0件の場合
    IF ( gn_ifrs_fa_retire_target_cnt = cn_zero_0 ) THEN
      --メッセージの設定
      lv_warnmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                     ,cv_msg_019a05_m_017  -- 取得対象データ無し
                                                     ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                     ,cv_msg_019a05_t_012) -- 固定資産台帳情報
                                                     ,1
                                                     ,5000);
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG  --ログ(システム管理者用メッセージ)出力
        ,buff   => lv_warnmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT  --メッセージ(ユーザ用メッセージ)出力
        ,buff   => lv_warnmsg
      );
    END IF;
--
    -- LOOP数初期化
    gn_loop_cnt := 0;
--
    -- ***************************************
    -- ***        ループ処理の記述         ***
    -- ***       処理部の呼び出し          ***
    -- ***************************************
    --==============================================================
    --メインループ処理
    --==============================================================
    <<ifrs_fa_retire_loop>>
    FOR ln_loop_cnt IN 1 .. gn_ifrs_fa_retire_target_cnt LOOP
--
      -- LOOP数取得
      gn_loop_cnt := ln_loop_cnt;
--
      -- 既にIFRS台帳に除売却データが存在する場合は処理をスキップする
      -- ここにif文で2重登録を回避する
      -- BOOK_TYPE_CODE+ASSET_NUMBERの組み合わせが同一のものがあればスキップ
--
      --==============================================================
      -- 除売却OIF登録 (A-6)
      --==============================================================
          INSERT INTO xx01_retire_oif(
             retire_oif_id                  -- ID
            ,book_type_code                 -- 台帳名
            ,asset_number                   -- 資産番号
            ,date_retired                   -- 除･売却日
            ,posting_flag                   -- 転記ﾁｪｯｸﾌﾗｸﾞ
            ,status                         -- ｽﾃｰﾀｽ
            ,cost_retired                   -- 除･売却取得価格
            ,retirement_type_code           -- 除売却タイプ
            ,proceeds_of_sale               -- 売却価額
            ,cost_of_removal                -- 撤去費用
            ,retirement_prorate_convention  -- 除･売却年度償却
            ,created_by                     -- 作成者
            ,creation_date                  -- 作成日
            ,last_updated_by                -- 最終更新者
            ,last_update_date               -- 最終更新日
            ,last_update_login              -- 最終更新ﾛｸﾞｲﾝ
            ,request_id                     -- ﾘｸｴｽﾄID
            ,program_application_id         -- ｱﾌﾟﾘｹｰｼｮﾝID
            ,program_id                     -- ﾌﾟﾛｸﾞﾗﾑID
            ,program_update_date            -- ﾌﾟﾛｸﾞﾗﾑ最終更新
          ) VALUES (
             xx01_retire_oif_s.NEXTVAL                               -- ID
            ,gv_fixed_ifrs_asset_regi                                -- 台帳名
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).asset_number          -- 資産番号
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).date_retired          -- 除･売却日
            ,cv_yes                                                  -- 転記ﾁｪｯｸﾌﾗｸﾞ
            ,cv_status_pending                                       -- ｽﾃｰﾀｽ(PENDING)
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).cost                  -- 除･売却取得価格
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).retirement_type_code  -- 除売却タイプ
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).proceeds_of_sale      -- 売却価額
            ,g_ifrs_fa_retire_tab(ln_loop_cnt).cost_of_removal       -- 撤去費用
            ,gv_prt_conv_cd_ed                                       -- 除･売却年度償却
            ,cn_created_by                                           -- 作成者
            ,cd_creation_date                                        -- 作成日
            ,cn_last_updated_by                                      -- 最終更新者
            ,cd_last_update_date                                     -- 最終更新日
            ,cn_last_update_login                                    -- 最終更新ログインID
            ,cn_request_id                                           -- リクエストID
            ,cn_program_application_id                               -- アプリケーションID
            ,cn_program_id                                           -- プログラムID
            ,cd_program_update_date                                  -- プログラム最終更新日
          )
          ;
--
      -- IFRS台帳除売却正常件数カウント
      gn_ifrs_fa_retire_normal_cnt := gn_ifrs_fa_retire_normal_cnt + 1;
--
    END LOOP ifrs_fa_retire_loop;
--
  EXCEPTION
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      -- カーソルクローズ
      IF (ifrs_fa_retire_cur%ISOPEN) THEN
        CLOSE ifrs_fa_retire_cur;
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- カーソルクローズ
      IF (ifrs_fa_retire_cur%ISOPEN) THEN
        CLOSE ifrs_fa_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- カーソルクローズ
      IF (ifrs_fa_retire_cur%ISOPEN) THEN
        CLOSE ifrs_fa_retire_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_ifrs_fa_retire_data;
--
  /**********************************************************************************
   * Procedure Name   : get_exec_date
   * Description      : 実行日時取得 (A-4)
   ***********************************************************************************/
  PROCEDURE get_exec_date(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_exec_date'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
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
    BEGIN
      SELECT  xis.exec_date AS exec_date  -- 実行日時
      INTO    gt_exec_date
      FROM    xxcff_ifrs_sets  xis        -- IFRS台帳連携セット
      WHERE   xis.exec_id = cv_pkg_name
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a05_m_017  -- 取得対象データ無し
                                                      ,cv_tkn_get_data      -- トークン'GET_DATA'
                                                      ,cv_msg_019a05_t_013) -- IFRS台帳連携セット
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
      --
      WHEN data_lock_expt THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                      ,cv_msg_019a05_m_019  -- ロックエラー
                                                      ,cv_tkn_table_name    -- トークン'TABLE_NAME'
                                                      ,cv_msg_019a05_t_013) -- IFRS台帳連携セット
                                                      ,1
                                                      ,5000);
        lv_errbuf := lv_errmsg ||cv_msg_part|| SQLERRM;
        --
        ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
        ov_errmsg  := lv_errmsg;
        ov_retcode := cv_status_error;
    END;
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
  END get_exec_date;
--
  /**********************************************************************************
   * Procedure Name   : chk_period
   * Description      : 会計期間チェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_period(
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_period'; -- プログラム名
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
    lt_deprn_run          fa_deprn_periods.deprn_run%TYPE := NULL;  -- 減価償却実行フラグ
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
    BEGIN
      -- 会計期間チェック
      SELECT  fdp.deprn_run        AS deprn_run   -- 減価償却実行フラグ
      INTO    lt_deprn_run
      FROM    fa_deprn_periods  fdp               -- 減価償却期間
      WHERE   fdp.book_type_code    = gv_fixed_ifrs_asset_regi
      AND     fdp.period_name       = gv_period_name
      AND     fdp.period_close_date IS NULL
      ;
    EXCEPTION
      -- 会計期間の取得件数がゼロ件の場合
      WHEN NO_DATA_FOUND THEN
        RAISE chk_period_expt;
    END;
--
    -- 減価償却が実行されている場合
    IF lt_deprn_run = cv_yes THEN
      RAISE chk_period_expt;
    END IF;
--
  EXCEPTION
    -- *** 会計期間チェックエラーハンドラ ***
    WHEN chk_period_expt THEN	
      -- エラーメッセージをセット
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff            -- XXCFF
                                                    ,cv_msg_019a05_m_011       -- 会計期間チェックエラー
                                                    ,cv_tkn_bk_type            -- トークン'BOOK_TYPE_CODE'
                                                    ,gv_fixed_ifrs_asset_regi  -- 資産台帳名
                                                    ,cv_tkn_period             -- トークン'PERIOD_NAME'
                                                    ,gv_period_name)           -- 会計期間名
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      --
      ov_errbuf := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_errmsg := lv_errmsg;
      -- 終了ステータスはエラーとする
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
  END chk_period;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_values
   * Description      : プロファイル取得処理(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_values(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_values'; -- プログラム名
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
    -- XXCFF:台帳種類_固定資産台帳
    gv_fixed_asset_register := FND_PROFILE.VALUE(cv_fixed_asset_register);
    IF (gv_fixed_asset_register IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a05_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a05_t_010) -- XXCFF:台帳種類_固定資産台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:台帳種類_IFRS台帳
    gv_fixed_ifrs_asset_regi := FND_PROFILE.VALUE(cv_fixed_ifrs_asset_regi);
    IF (gv_fixed_ifrs_asset_regi IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a05_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a05_t_011) -- XXCFF:台帳種類_IFRS台帳
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFF:按分方法
    gv_prt_conv_cd_ed := FND_PROFILE.VALUE(cv_prt_conv_cd_ed);
    IF (gv_prt_conv_cd_ed IS NULL) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff       -- XXCFF
                                                    ,cv_msg_019a05_m_010  -- プロファイル取得エラー
                                                    ,cv_tkn_prof          -- トークン'PROF_NAME'
                                                    ,cv_msg_019a05_t_015) -- XXCFF:按分方法
                                                    ,1
                                                    ,5000);
      lv_errbuf := lv_errmsg;
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
  END get_profile_values;
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
    -- コンカレントパラメータ値出力(出力の表示)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_out    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    -- コンカレントパラメータ値出力(ログ)
    xxcff_common1_pkg.put_log_param(
       iv_which         => cv_file_type_log    -- 出力区分
      ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ           --# 固定 #
      ,ov_retcode       => lv_retcode          -- リターン・コード             --# 固定 #
      ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> ov_retcode) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    WHEN global_api_expt THEN                           --*** 共通関数コメント ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_period_name  IN  VARCHAR2,     -- 1.会計期間名
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain';      -- プログラム名
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- INパラメータ(会計期間名)をグローバル変数に設定
    gv_period_name := iv_period_name;
--
    -- ===============================
    -- 初期処理 (A-1)
    -- ===============================
    init(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- プロファイル値取得 (A-2)
    -- ===============================
    get_profile_values(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 会計期間チェック (A-3)
    -- ===============================
    chk_period(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- 実行日時取得 (A-4)
    -- =========================================
    get_exec_date(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS台帳登録データ抽出 (A-5)
    -- =========================================
    get_ifrs_fa_retire_data(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =========================================
    -- IFRS台帳連携セット更新(A-6)
    -- =========================================
    upd_ifrs_sets(
       lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,lv_retcode        -- リターン・コード             --# 固定 #
      ,lv_errmsg         -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
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
    errbuf         OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode        OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_period_name IN  VARCHAR2       --   1.会計期間名
  )
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
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
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
    -- グローバル変数の初期化
    gn_ifrs_fa_retire_target_cnt := 0;
    gn_ifrs_fa_retire_normal_cnt := 0;
    gn_ifrs_fa_retire_err_cnt    := 0;
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_period_name -- 会計期間名
      ,lv_errbuf      -- エラー・メッセージ           --# 固定 #
      ,lv_retcode     -- リターン・コード             --# 固定 #
      ,lv_errmsg      -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
  /**********************************************************************************
   * Description      : 終了処理(A-7)
   ***********************************************************************************/
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      -- 正常件数を0に設定
      gn_ifrs_fa_retire_normal_cnt := cn_zero_0;
      -- エラー件数を+1更新
      gn_ifrs_fa_retire_err_cnt := gn_ifrs_fa_retire_err_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
      -- 対象件数がカウントされている場合
      IF ( gn_ifrs_fa_retire_target_cnt > 0 ) THEN
        -- IFRS台帳除売却エラーの固定資産台帳情報を出力する
        gv_out_msg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cff         -- XXCFF
                                                       ,cv_msg_019a05_m_014    -- IFRS台帳除売却エラー
                                                       ,cv_tkn_asset_number    -- トークン'ASSET_NUMBER'
                                                       ,g_ifrs_fa_retire_tab(gn_loop_cnt).asset_number)
                                                                               -- 資産番号
                                                       ,1
                                                       ,2000);
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => gv_out_msg
        );
      END IF;
    -- 対象件数が0件だった場合
    ELSIF ( gn_ifrs_fa_retire_target_cnt = cn_zero_0 ) THEN
      -- ステータスを警告にする
      lv_retcode := cv_status_warn;
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --===============================================================
    --IFRS台帳除売却処理における件数出力
    --===============================================================
    --IFRS台帳除売却メッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_msg_kbn_cff
                    ,iv_name         => cv_msg_019a05_m_013
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_target_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_retire_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_success_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_retire_normal_cnt)
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
                    ,iv_token_value1 => TO_CHAR(gn_ifrs_fa_retire_err_cnt)
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
END XXCFF019A05C;
/
