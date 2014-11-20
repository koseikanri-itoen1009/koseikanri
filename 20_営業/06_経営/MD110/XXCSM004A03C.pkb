create or replace PACKAGE BODY XXCSM004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A03C(body)
 * Description      : 従業員マスタと資格ポイントマスタから各営業員の資格ポイントを算出し、
 *                  : 新規獲得ポイント顧客別履歴テーブルに登録します。
 * MD.050           : MD050_CSM_004_A03_新規獲得ポイント集計（資格ポイント集計処理）
 * Version          : 1.10
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_dept_data          部署データの抽出 (A-3)
 *  get_point_data         資格ポイント算出処理 (A-4)
 *  del_rireki_tbl_data    処理対象データのレコード削除(A-5)
 *  insert_rireki_tbl_data 当月度資格ポイントデータの登録(A-6)
 *  submain                メイン処理プロシージャ
 *                           営業員データの抽出 (A-2)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理 (A-7)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-12    1.0   T.Tsukino        新規作成
 *  2009-04-15    1.1   M.Ohtsuki       ［T1_0568］新・旧職務コードNULL値の対応
 *  2009-07-01    1.2   M.Ohtsuki       ［SCS障害管理番号0000253］対応
 *  2009/07/07    1.3   M.Ohtsuki       ［SCS障害管理番号0000254］部署コード取得条件の不具合
 *  2009/07/14    1.4   M.Ohtsuki       ［SCS障害管理番号0000663］想定外エラー発生時の不具合
 *  2009/07/27    1.5   T.Tsukino       ［SCS障害管理番号0000786］パフォーマンス障害
 *  2009/08/24    1.6   T.Tsukino       ［SCS障害管理番号0001150］障害№0001150対応(発令日の判定方法の不備）
 *  2009/09/03    1.7   K.Kubo          ［SCS障害管理番号0001286］発令日の判定方法の不備(営業員以外から営業員への異動)
 *  2009/10/22    1.8   T.Tsukino       ［障害管理番号E-T4-00065］抽出対象営業員の資格コード判定の追加対応
 *  2009/10/30    1.9   T.Tsukino       ［障害管理番号E-T4-00064］パフォーマンス障害（部署コード取得処理変更）
 *  2009/11/26    1.10  T.Tsukino       ［障害管理番号E-本稼動-00110］資格カウント対象外コードを持つ従業員データの排除処理
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
  cv_pkg_name             CONSTANT VARCHAR2(100) := 'XXCSM004A03C';                                 -- パッケージ名
  cv_app_name             CONSTANT VARCHAR2(5)   := 'XXCSM';                                        -- アプリケーション短縮名
  -- メッセージコード
  cv_xxcsm_msg_005        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00005';                             -- プロファイル取得エラーメッセージ
  cv_xxcsm_msg_102        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10002';                             -- 年度取得エラーメッセージ
  cv_xxcsm_msg_042        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00042';                             -- 入力パラメータチェックエラーメッセージ（処理年月）
  cv_xxcsm_msg_047        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00047';                             -- 資格ポイント未存在エラーメッセージ
  cv_xxccp_msg_052        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00052';                             -- コンカレント入力パラメータメッセージ（処理年月）
  cv_xxcsm_msg_069        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00069';                             -- 新規獲得ポイント顧客別履歴テーブルロックエラーメッセージ（従業員別）
  cv_xxcsm_msg_070        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-00070';                             -- 部署コード取得エラーメッセージ（従業員別）
  cv_xxcsm_msg_120        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10020';                             -- 営業員データ取得エラーメッセージ
  cv_xxcsm_msg_125        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10125';                             -- 対象従業員コードの発令日取得エラーメッセージ
  cv_xxcsm_msg_126        CONSTANT VARCHAR2(100) := 'APP-XXCSM1-10126';                             -- 対象従業員コードの資格コード・職務コード取得エラーメッセージ
  --プロファイル名
--//+DEL START 2009/07/07 0000254 M.Ohtsuki
--  cv_calc_point           CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_POST_LEVEL';                 --  プロファイル:XXCSM:ポイント算出用部署階層格納用
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
  -- トークンコード
  cv_tkn_prf_name         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_data             CONSTANT VARCHAR2(20) := 'DATA';
  cv_tkn_date             CONSTANT VARCHAR2(20) := 'DATE';
  cv_tkn_yyyy             CONSTANT VARCHAR2(20) := 'YYYY';
  cv_tkn_month            CONSTANT VARCHAR2(20) := 'MONTH';
  cv_tkn_data_kbn         CONSTANT VARCHAR2(20) := 'DATA_KBN';
  cv_tkn_jugyoin_cd       CONSTANT VARCHAR2(20) := 'JUGYOIN_CD';
  cv_tkn_kyoten_cd        CONSTANT VARCHAR2(20) := 'KYOTEN_CD';
  cv_tkn_input_busyo      CONSTANT VARCHAR2(20) := 'INPUT_BUSYO';
  cv_tkn_input_shikaku    CONSTANT VARCHAR2(20) := 'INPUT_SHIKAKU';
  cv_tkn_input_shokumu    CONSTANT VARCHAR2(20) := 'INPUT_SYOKUMU';
  cv_tkn_pgm              CONSTANT VARCHAR2(20) := 'PGM';
  cv_tkn_err_msg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_count            CONSTANT VARCHAR2(20) := 'COUNT';
  cv_tkn_process          CONSTANT VARCHAR2(20) := 'PROCESS_DATE';
--
--//+ADD START  2009/10/20 E-T4-00064 T.Tsukino
  cv_location_level       CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_LEVEL';                      -- ポイント算出用部署階層
  cv_flg_y                CONSTANT VARCHAR2(1)   := 'Y';                                            -- フラグ'Y'
--//+ADD END    2009/10/20 E-T4-00064 T.Tsukino
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  TYPE gt_loc_lv_ttype IS TABLE OF VARCHAR2(10)                                                     -- テーブル型の宣言
    INDEX BY BINARY_INTEGER;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date         DATE;                                                 -- 業務日付格納用
--//DEL START   2009/07/07 0000254 M.Ohtsuki
--  gv_prf_point            VARCHAR2(100);                                        -- プロファイル:XXCSM:ポイント算出用部署階層格納用
--//DEL END     2009/07/07 0000254 M.Ohtsuki
  gv_inprocess_date       VARCHAR2(100);                                        -- 入力パラメータ格納用パラメータ
  gv_year                 VARCHAR2(4);                                          -- 対象年度格納用:年
  gv_month                VARCHAR2(2);                                          -- 対象年度格納用:月
  gv_process_date         VARCHAR2(10);                                         -- 処理対象年度月
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
  gt_loc_lv_tab             gt_loc_lv_ttype;                                                        -- テーブル型変数の宣言
  ln_loc_lv_cnt             NUMBER;                                                                 -- カウンタ
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
  gn_shikaku_exptcount    NUMBER := 0;                                          -- 資格カウント対象外レコード件数
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
--
  /**********************************************************************************
   * Procedure Name   : init
   * Argument         : iv_process_date [コンカレントINパラメータ：処理日付/YYYYMM形式]
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_process_date     IN  VARCHAR2                                           -- 処理日付
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
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
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_appl_short_name  CONSTANT VARCHAR2(10)    := 'XXCCP';                      -- アプリケーション短縮名
    cv_tkn_value        CONSTANT VARCHAR2(100)   := 'XXCSM_COMMON_PKG';         -- 共通関数名
--//+DEL START  2009/10/20 E-T4-00064 T.Tsukino
----//+ADD START   2009/07/07 0000254 M.Ohtsuki
--    cv_location_level   CONSTANT VARCHAR2(100) := 'XXCSM1_CALC_POINT_LEVEL';                        -- ポイント算出用部署階層
--    cv_flg_y            CONSTANT VARCHAR2(1) := 'Y';                                                -- フラグ'Y'
----//+ADD END     2009/07/07 0000254 M.Ohtsuki
--//+DEL END    2009/10/20 E-T4-00064 T.Tsukino
    -- *** ローカル変数 ***
    lv_prm_msg          VARCHAR2(4000);                                         -- コンカレント入力パラメータメッセージ格納用
    lv_msg              VARCHAR2(100);                                          --
    lv_tkn_value        VARCHAR2(100);                                          -- 入力パラメータ出力トークン値
    lv_year             VARCHAR2(4);                                            -- 年度算出関数:GET_YEAR_MONTH/年度
    lv_month            VARCHAR2(2);                                            -- 年度算出関数:GET_YEAR_MONTH/月
    ld_chk_date         DATE;                                                   -- 入力パラメータ日付チェック
    -- *** ローカル例外 ***
    prm_err_expt        EXCEPTION;                                              -- 入力パラメータチェックエラー
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--    getprofile_err_expt EXCEPTION;                                              -- プロファイル取得エラーメッセージ
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
    get_year_expt       EXCEPTION;                                              -- 年度取得エラーメッセージ
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    CURSOR get_loc_lv_cur
    IS
          SELECT   flv.lookup_code        lookup_code
          FROM     fnd_lookup_values      flv                                                       -- クイックコード値
          WHERE    flv.lookup_type        = cv_location_level                                       -- ポイント算出用部署階層
            AND    flv.language           = USERENV('LANG')                                         -- 言語('JA')
            AND    flv.enabled_flag       = cv_flg_y                                                -- 使用可能フラグ
            AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date                    -- 適用開始日
            AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date                    -- 適用終了日
          ORDER BY flv.lookup_code   DESC;                                                          -- ルックアップコード
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--  業務日付の取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --パラメータへの入力値の格納
    gv_inprocess_date := iv_process_date;
    -- =====================================
    -- A-1: ① 入力パラメータメッセージ出力
    -- =====================================
    lv_tkn_value := gv_inprocess_date;
    lv_prm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                          --アプリケーション短縮名
                       ,iv_name         => cv_xxccp_msg_052                     --メッセージコード
                       ,iv_token_name1  => cv_tkn_data                          --トークンコード1
                       ,iv_token_value1 => lv_tkn_value                         --トークン値1
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
    -- =======================================
    -- A-1: ② 入力パラメータの格納/チェック
    -- =======================================
    --NULLチェック
    IF (iv_process_date IS NULL) THEN
      gv_inprocess_date := TO_CHAR(gd_process_date,'YYYYMM');
    END IF;
    IF (LENGTH(gv_inprocess_date) != 6) THEN
      RAISE prm_err_expt;
    END IF;
    --入力パラメータの月のチェック
    BEGIN
      ld_chk_date := TO_DATE(gv_inprocess_date, 'YYYYMM');
    EXCEPTION
      WHEN OTHERS THEN
        RAISE prm_err_expt;
    END;
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
    -- ================================
    -- A-1: ③ プロファイル値取得処理
    -- ================================
--    gv_prf_point := FND_PROFILE.VALUE(cv_calc_point);
--
    -- プロファイル値取得に失敗した場合
--    IF (gv_prf_point IS NULL) THEN
--      RAISE getprofile_err_expt;
--    END IF;
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
    -- =========================
    -- A-1: ③  年度・月の算出
    -- =========================
    -- 共通関数XXCSM_COMMON_PKG(XXCSM:年度算出関数)
    xxcsm_common_pkg.get_year_month(
       iv_process_years => gv_inprocess_date                                    --年月
      ,ov_year          => lv_year                                              --対象年度
      ,ov_month         => lv_month                                             --月
      ,ov_retcode       => lv_retcode                                           --リターンコード（0:正常、1:警告、2:異常）
      ,ov_errbuf        => lv_errbuf                                            --エラーメッセージ(システム管理者が調査に必要な内容)
      ,ov_errmsg        => lv_errmsg                                            --ユーザー・エラーメッセージ(ユーザーに表示するエラーメッセージ)
    );
    --リターンコードが0:正常以外の場合、エラー
    IF (lv_retcode <> 0) THEN
      RAISE get_year_expt;
    END IF;
    gv_year    := lv_year;
    gv_month   := lv_month;
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
--  --==============================================================
    --A-1: ④ 拠点階層の取得
    --==============================================================
    ln_loc_lv_cnt := 0;                                                                             -- 変数の初期化
    <<get_loc_lv_cur_loop>>                                                                         -- 拠点階層取得LOOP
    FOR rec IN get_loc_lv_cur LOOP
      ln_loc_lv_cnt := ln_loc_lv_cnt + 1;
      gt_loc_lv_tab(ln_loc_lv_cnt)   := rec.lookup_code;                                            -- 拠点階層
    END LOOP get_loc_lv_cur_loop;
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--
  EXCEPTION
    WHEN prm_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_042                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_date                            --トークンコード1
                     ,iv_token_value1 => gv_inprocess_date                      --トークン値1
                     );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--//+DEL START   2009/07/07 0000254 M.Ohtsuki
--    WHEN getprofile_err_expt THEN
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name                            --アプリケーション短縮名
--                     ,iv_name         => cv_xxcsm_msg_005                       --メッセージコード
--                     ,iv_token_name1  => cv_tkn_prf_name                        --トークンコード1
--                     ,iv_token_value1 => cv_calc_point                          --トークン値1
--                   );
--      lv_errbuf  := lv_errmsg;
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--      ov_retcode := cv_status_error;
--//+DEL END   2009/07/07 0000254 M.Ohtsuki
    WHEN get_year_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_102                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_pgm                             --トークンコード1
                     ,iv_token_value1 => cv_tkn_value                           --トークン値1
                     ,iv_token_name2  => cv_tkn_err_msg                         --トークンコード2
                     ,iv_token_value2 => lv_errmsg                              --トークン値2
                   );
      lv_errbuf  := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_dept_data
   * Description      : 部署データの抽出（A-3）
   ***********************************************************************************/
  PROCEDURE get_dept_data(
     iv_employee_cd      IN  VARCHAR2                                           -- 従業員コード
    ,iv_kyoten_cd        IN  VARCHAR2                                           -- 拠点コード
    ,ov_busyo_cd         OUT NOCOPY VARCHAR2                                    -- 部署コード
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_dept_data';           -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_busyo_cd          VARCHAR2(15);                                           -- 部署コード
    lv_shikaku_cd        VARCHAR2(100);                                         -- 資格コード
    lv_syokumu_cd        VARCHAR2(100);                                         -- 職務コード
    ln_shikaku_point     NUMBER;                                                -- 資格ポイント
--//+ADD START   2009/07/07 0000254 M.Ohtsuki
    ln_check_cnt         NUMBER;                                                                    -- 部署チェック用カウンタ
--//+ADD END     2009/07/07 0000254 M.Ohtsuki
--//+ADD START  2009/10/20 E-T4-00064 T.Tsukino
    lv_current_level     VARCHAR2(2);                                           -- 拠点の階層
    ln_count             NUMBER;                                                -- ポイント算出部署階層判定用
--//+ADD END    2009/10/20 E-T4-00064 T.Tsukino
    -- *** ローカル例外 ***
    get_busyo_cd_expt    EXCEPTION;                                             -- 部署コード取得エラーメッセージ
--        
--
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  -- 部署コード抽出処理
--//+ADD START  2009/10/20 E-T4-00064 T.Tsukino
    -- 拠点の階層を取得
    SELECT xxlnlv.hierarchy_level
    INTO   lv_current_level
    FROM   xxcsm_loc_name_list_v  xxlnlv
    WHERE  xxlnlv.base_code = iv_kyoten_cd
    ;
--
    -- 拠点の階層が「ポイント算出部署階層」かを判定
    SELECT COUNT(1)
    INTO   ln_count
    FROM   fnd_lookup_values      flv                                           -- クイックコード値
    WHERE  flv.lookup_type        = cv_location_level                           -- ポイント算出用部署階層
    AND    flv.language           = USERENV('LANG')                             -- 言語('JA')
    AND    flv.enabled_flag       = cv_flg_y                                    -- 使用可能フラグ
    AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date        -- 適用開始日
    AND    NVL(flv.end_date_active,gd_process_date)   >= gd_process_date        -- 適用終了日
    AND    flv.lookup_code        = lv_current_level
    ;
--
    -- 拠点の階層が「ポイント算出部署階層」の場合、
    -- 拠点コードを部署コードとして、設定する
    IF (ln_count > 0) THEN
      lv_busyo_cd := iv_kyoten_cd;
    -- 拠点の階層が「ポイント算出部署階層」でない場合、
    -- ポイント算出部署階層の最下層で部署コードを設定する
    ELSE
      -- 最下層の部署コード取得用変数設定
      ln_check_cnt := 1;
      --
      SELECT DECODE(gt_loc_lv_tab(ln_check_cnt), 'L6',xxlllv.cd_level6,
                                                 'L5',xxlllv.cd_level5,
                                                 'L4',xxlllv.cd_level4,
                                                 'L3',xxlllv.cd_level3,
                                                 'L2',xxlllv.cd_level2,
                                                 'L1',xxlllv.cd_level1
                   )
      INTO   lv_busyo_cd
      FROM   xxcsm_loc_level_list_v   xxlllv
      WHERE  iv_kyoten_cd = DECODE(lv_current_level,'L6',xxlllv.cd_level6,
                                                    'L5',xxlllv.cd_level5,
                                                    'L4',xxlllv.cd_level4,
                                                    'L3',xxlllv.cd_level3,
                                                    'L2',xxlllv.cd_level2,
                                                    'L1',xxlllv.cd_level1
                                  )
      AND    ROWNUM = 1
      ;
    END IF;
--//+ADD END    2009/10/20 E-T4-00064 T.Tsukino
--//+DEL END    2009/10/20 E-T4-00064 T.Tsukino
----//+ADD START  2009/07/07 0000254 M.Ohtsuki
--      ln_check_cnt := 0;                                                                            -- 変数の初期化
--      lv_busyo_cd  := NULL;                                                                         -- 変数の初期化
--      LOOP
--        EXIT WHEN ln_check_cnt >= ln_loc_lv_cnt                                                      -- ポイント算出用部署階層の件数分
--              OR  lv_busyo_cd IS NOT NULL;                                                          -- 部署コードが取得できるまで
--        ln_check_cnt := ln_check_cnt + 1;
----//+ADD END    2009/07/07 0000254 M.Ohtsuki
----//+UPD START  2009/07/07 0000254 M.Ohtsuki
----    SELECT DECODE(gv_prf_point, 'L6',xxlllv.cd_level6,
----↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--    SELECT DECODE(gt_loc_lv_tab(ln_check_cnt), 'L6',xxlllv.cd_level6,
----//+UPD END    2009/07/07 0000254 M.Ohtsuki
--                                'L5',xxlllv.cd_level5,
--                                'L4',xxlllv.cd_level4,
--                                'L3',xxlllv.cd_level3,
--                                'L2',xxlllv.cd_level2,
--                                'L1',xxlllv.cd_level1
--                 )
--    INTO   lv_busyo_cd
--    FROM   xxcsm_loc_level_list_v   xxlllv
--    WHERE  iv_kyoten_cd = DECODE(xxlllv.location_level,'L6',xxlllv.cd_level6,
--                                                           'L5',xxlllv.cd_level5,
--                                                           'L4',xxlllv.cd_level4,
--                                                           'L3',xxlllv.cd_level3,
--                                                           'L2',xxlllv.cd_level2,
--                                                           'L1',xxlllv.cd_level1
--                                    )
--    ;
----//+ADD START  2009/07/07 0000254 M.Ohtsuki
--      END LOOP;
----//+ADD END    2009/07/07 0000254 M.Ohtsuki
--//+DEL END    2009/10/20 E-T4-00064 T.Tsukino
--
  -- 取得結果チェック
    IF (lv_busyo_cd IS NULL) THEN
      RAISE get_busyo_cd_expt;
    END IF;
  -- 出力パラメータ入力処理
    ov_busyo_cd         := lv_busyo_cd;
--
  EXCEPTION
    -- *** 部署データ抽出例外ハンドラ ***
    WHEN get_busyo_cd_expt THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_070                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --トークンコード1
                     ,iv_token_value1 => iv_employee_cd                         --トークン値1
                     ,iv_token_name2  => cv_tkn_kyoten_cd                       --トークンコード2
                     ,iv_token_value2 => iv_kyoten_cd                           --トークン値2
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- ステータス:エラー
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ov_retcode := cv_status_warn;   -- ステータス:警告
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
    -- *** 部署データ抽出例外ハンドラ ***
    WHEN NO_DATA_FOUND THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_070                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --トークンコード1
                     ,iv_token_value1 => iv_employee_cd                         --トークン値1
                     ,iv_token_name2  => cv_tkn_kyoten_cd                       --トークンコード2
                     ,iv_token_value2 => iv_kyoten_cd                           --トークン値2
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- ステータス:エラー
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ov_retcode := cv_status_warn;   -- ステータス:警告
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
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
  END get_dept_data;
  /**********************************************************************************
   * Procedure Name   : get_point_data
   * Description      : 資格ポイント算出処理 （A-4）
   **********************************************************************************/
  PROCEDURE get_point_data(
     iv_employee_cd      IN  VARCHAR2                                           -- 従業員コード
    ,iv_busyo_cd         IN  VARCHAR2                                           -- 部署コード
    ,iv_shikaku_cd       IN  VARCHAR2                                           -- 資格コード
    ,iv_syokumu_cd       IN  VARCHAR2                                           -- 職務コード
    ,on_shikaku_point    OUT NUMBER                                             -- 資格ポイント
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'get_point_data';                              -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_employee_cd       VARCHAR2(30);                                          -- 従業員コード
    lv_busyo_cd          VARCHAR2(15);                                          -- 部署コード
    lv_shikaku_cd        VARCHAR2(100);                                         -- 資格コード
    lv_syokumu_cd        VARCHAR2(100);                                         -- 職務コード
    ln_shikaku_point     NUMBER;                                                -- 資格ポイント
    -- *** ローカル例外 ***
    no_data_shikaku_expt    EXCEPTION;                                          -- 資格ポイント未存在エラーメッセージ
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
  -- 資格ポイント算出処理
    SELECT xxmqp.qualificate_point      shikaku_point
    INTO   ln_shikaku_point
    FROM   xxcsm_mst_qualificate_pnt    xxmqp
    WHERE  xxmqp.subject_year    = gv_year
    AND    xxmqp.post_cd         = iv_busyo_cd
    AND    xxmqp.qualificate_cd  = iv_shikaku_cd
    AND    xxmqp.duties_cd       = iv_syokumu_cd
    ;

  -- 取得結果チェック
    IF (ln_shikaku_point IS NULL) THEN
      RAISE no_data_shikaku_expt;
    END IF;
  -- 出力パラメータ入力処理
    on_shikaku_point    := ln_shikaku_point;
--
  EXCEPTION
    -- *** 資格ポイント未存在例外ハンドラ ***
    WHEN no_data_shikaku_expt THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_047                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --トークンコード1
                     ,iv_token_value1 => iv_employee_cd                         --トークン値1
                     ,iv_token_name2  => cv_tkn_input_busyo                     --トークンコード2
                     ,iv_token_value2 => iv_busyo_cd                            --トークン値2
                     ,iv_token_name3  => cv_tkn_input_shikaku                   --トークンコード3
                     ,iv_token_value3 => iv_shikaku_cd                          --トークン値3
                     ,iv_token_name4  => cv_tkn_input_shokumu                   --トークンコード4
                     ,iv_token_value4 => iv_syokumu_cd                          --トークン値4
                   );
      lv_errbuf := lv_errmsg;
--
      on_shikaku_point := NULL;
      ov_errmsg        := lv_errmsg;
      ov_errbuf        := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- ステータス:エラー
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ov_retcode := cv_status_warn;   -- ステータス:警告
--//\UPD  END    2009/07/14 0000663 M.Ohtsuki
    -- *** 資格ポイント未存在例外ハンドラ ***
    WHEN NO_DATA_FOUND THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_047                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --トークンコード1
                     ,iv_token_value1 => iv_employee_cd                         --トークン値1
                     ,iv_token_name2  => cv_tkn_input_busyo                     --トークンコード2
                     ,iv_token_value2 => iv_busyo_cd                            --トークン値2
                     ,iv_token_name3  => cv_tkn_input_shikaku                   --トークンコード3
                     ,iv_token_value3 => iv_shikaku_cd                          --トークン値3
                     ,iv_token_name4  => cv_tkn_input_shokumu                   --トークンコード4
                     ,iv_token_value4 => iv_syokumu_cd                          --トークン値4
                   );
      lv_errbuf := lv_errmsg;
--
      on_shikaku_point := NULL;
      ov_errmsg        := lv_errmsg;
      ov_errbuf        := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- ステータス:エラー
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ov_retcode := cv_status_warn;   -- ステータス:警告
--//\UPD  END    2009/07/14 0000663 M.Ohtsuki
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      on_shikaku_point := NULL;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM,1,4000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_point_data;
  /**********************************************************************************
   * Procedure Name   : del_rireki_tbl_data
   * Description      : 処理対象データのレコード削除（A-5）
   ***********************************************************************************/
  PROCEDURE del_rireki_tbl_data(
     iv_employee_num     IN  VARCHAR2
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'del_rireki_tbl_data';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf            VARCHAR2(4000);                                        -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);                                           -- リターン・コード
    lv_errmsg            VARCHAR2(4000);                                        -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cn_tkn_kbn           CONSTANT NUMBER   := 0;                                -- データ区分固定値
    -- *** ローカル変数 ***
    lv_employee_number  XXCSM_NEW_CUST_POINT_HST.EMPLOYEE_NUMBER%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR del_rireki_tbl_cur(
      lv_employee_number VARCHAR2
      )
    IS
      SELECT ROWID
      FROM   xxcsm_new_cust_point_hst      xxncph
      WHERE  xxncph.subject_year      =    gv_year
      AND    xxncph.month_no          =    gv_month
      AND    xxncph.data_kbn          =    '0'
      AND    xxncph.employee_number   =    lv_employee_number
      FOR UPDATE NOWAIT
      ;
    -- *** ローカル例外 ***
    rock_err_expt        EXCEPTION;                                              -- 新規獲得ポイント顧客別履歴テーブルロックエラーメッセージ
--
    PRAGMA EXCEPTION_INIT(rock_err_expt,-54);
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
    --入力パラメータの変数への代入
    lv_employee_number    :=   iv_employee_num;
    --対象データ削除処理
    << del_rireki_tbl_loop >>
    FOR del_rireki_tbl_rec IN  del_rireki_tbl_cur(lv_employee_number) LOOP
      DELETE
      FROM    xxcsm_new_cust_point_hst    xxncph
      WHERE   ROWID = del_rireki_tbl_rec.rowid
      ;
    END LOOP  del_rireki_tbl_loop;
--
  EXCEPTION
    -- *** 新規獲得ポイント顧客別履歴テーブルロック例外ハンドラ ***
    WHEN rock_err_expt THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_069                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_yyyy                            --トークンコード1
                     ,iv_token_value1 => gv_year                                --トークン値1
                     ,iv_token_name2  => cv_tkn_month                           --トークンコード2
                     ,iv_token_value2 => gv_month                               --トークン値2
                     ,iv_token_name3  => cv_tkn_data_kbn                        --トークンコード3
                     ,iv_token_value3 => cn_tkn_kbn                             --トークン値3
                     ,iv_token_name4  => cv_tkn_jugyoin_cd                      --トークンコード4
                     ,iv_token_value4 => lv_employee_number                     --トークン値4
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- ステータス:エラー
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ov_retcode := cv_status_warn;   -- ステータス:警告
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
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
  END del_rireki_tbl_data;
--
  /**********************************************************************************
   * Procedure Name   : insert_rireki_tbl_data
   * Description      : 当月度資格ポイントデータの登録（A-6）
   ***********************************************************************************/
  PROCEDURE insert_rireki_tbl_data(
     iv_employee_num     IN  VARCHAR2                                           -- 従業員№
    ,in_shikaku_point    IN  NUMBER
    ,iv_busyo_cd         IN  VARCHAR2
    ,iv_syokumu_cd       IN  VARCHAR2
    ,iv_shikaku_cd       IN  VARCHAR2
    ,iv_kyoten_cd        IN  VARCHAR2
    ,ov_errbuf           OUT NOCOPY VARCHAR2                                    -- エラー・メッセージ
    ,ov_retcode          OUT NOCOPY VARCHAR2                                    -- リターン・コード
    ,ov_errmsg           OUT NOCOPY VARCHAR2                                    -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'insert_rireki_tbl_data';                              -- プログラム名

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
    cv_acc_num           CONSTANT VARCHAR2(1)     := '0';                       -- 固定値:'0'（顧客コードなし）
    cv_date_kbn          CONSTANT VARCHAR2(1)     := '0';                       -- 固定値:'0'（資格ポイント）
    -- *** ローカル変数 ***
    lv_employee_num      VARCHAR2(100);                                         -- 従業員№
    ln_shikaku_point     NUMBER;                                                -- 資格ポイント
    lv_busyo_cd          VARCHAR2(15);                                          -- 部署コード
    lv_syokumu_cd        VARCHAR2(100);                                         -- 職務コード
    lv_shikaku_cd        VARCHAR2(100);                                         -- 資格コード
    lv_kyoten_cd         VARCHAR2(100);                                         -- 拠点コード
    -- *** ローカル例外 ***
    no_data_inprm        EXCEPTION;                                             -- 入力パラメータNULLチェック
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
  --入力パラメータNULLチェック
  IF (in_shikaku_point IS NULL OR
      iv_busyo_cd      IS NULL OR
      iv_syokumu_cd    IS NULL OR
      iv_shikaku_cd    IS NULL OR
      iv_kyoten_cd     IS NULL)
  THEN RAISE no_data_inprm;
  END IF;
  --当月度資格ポイントデータ登録処理
    INSERT INTO xxcsm_new_cust_point_hst(
       employee_number
      ,subject_year
      ,month_no
      ,account_number
      ,data_kbn
      ,year_month
      ,point
      ,post_cd
      ,duties_cd
      ,qualificate_cd
      ,location_cd
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
       iv_employee_num
      ,gv_year
      ,gv_month
      ,cv_acc_num
      ,cv_date_kbn
      ,TO_NUMBER(gv_inprocess_date)
      ,in_shikaku_point
      ,iv_busyo_cd
      ,iv_syokumu_cd
      ,iv_shikaku_cd
      ,iv_kyoten_cd
      ,cn_created_by
      ,cd_creation_date
      ,cn_last_updated_by
      ,cd_last_update_date
      ,cn_last_update_login
      ,cn_request_id
      ,cn_program_application_id
      ,cn_program_id
      ,cd_program_update_date
      )
      ;
--
  EXCEPTION
    -- *** 入力パラメータNULLチェック***
    WHEN no_data_inprm THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_126                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_jugyoin_cd                      --トークンコード1
                     ,iv_token_value1 => iv_employee_num                        --トークン値1
                   );
      lv_errbuf := lv_errmsg;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
--//+UPD  START  2009/07/14 0000663 M.Ohtsuki
--      ov_retcode := cv_status_error;   -- ステータス:エラー
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      ov_retcode := cv_status_warn;   -- ステータス:警告
--//+UPD  END    2009/07/14 0000663 M.Ohtsuki
--
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
  END insert_rireki_tbl_data;
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
  /**********************************************************************************
   * Procedure Name   : point_countcd_chk
   * Description      : 資格ポイントカウント対象コードチェック機能 (A-8)
   ***********************************************************************************/
  PROCEDURE point_countcd_chk(
     iv_shikaku_cd     IN  VARCHAR2
    ,on_shikaku_count  OUT NUMBER
    ,ov_errbuf         OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                      -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'point_countcd_chk';                      -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf         VARCHAR2(4000);                                           -- エラー・メッセージ
    lv_retcode        VARCHAR2(1);                                              -- リターン・コード
    lv_errmsg         VARCHAR2(4000);                                           -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_point_countcd           CONSTANT VARCHAR2(20) := 'XXCSM1_POINT_COUNTCD'; --参照タイプ：資格カウント対象コード
    cv_flv_language            CONSTANT VARCHAR2(2)  := 'JA';
--
  BEGIN
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    --参照タイプ：資格カウント対象コードに対象の資格コードが存在するかチェックする
    SELECT count(1)
    INTO   on_shikaku_count
    FROM   fnd_lookup_values  flv                      --クイックコード値
    WHERE  flv.lookup_type = cv_point_countcd          --参照タイプ：資格カウント対象コード
    AND    flv.language    = cv_flv_language           --言語
    AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
    AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
    AND    flv.enabled_flag = 'Y'
    AND    flv.lookup_code = iv_shikaku_cd
    ;
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
  END point_countcd_chk;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   *                    営業員データの抽出 (A-2)
   ***********************************************************************************/
  PROCEDURE submain(
     iv_process_date   IN  VARCHAR2
    ,ov_errbuf         OUT NOCOPY VARCHAR2                                      -- エラー・メッセージ
    ,ov_retcode        OUT NOCOPY VARCHAR2                                      -- リターン・コード
    ,ov_errmsg         OUT NOCOPY VARCHAR2                                      -- ユーザー・エラー・メッセージ
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'submain';                      -- プログラム名
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
    -- *** ローカル定数 ***
    cn_shikaku_point           CONSTANT NUMBER      := 0;                             -- 資格ポイント:ポイント0
--//+ADD START 2009/08/24 0001150 T.Tsukino
    cv_tougetsu_date           CONSTANT VARCHAR2(2) := '01';                          -- 当月比較用一日日付
--//ADD END 2009/08/24 0001150 T.Tsukino
--//+ADD START 2009/10/22 E-T4-00065 T.Tsukino
    cv_point_countcd           CONSTANT VARCHAR2(20) := 'XXCSM1_POINT_COUNTCD';       --参照タイプ：資格カウント対象コード
--//+ADD END 2009/10/22 E-T4-00065 T.Tsukino
--
    -- *** ローカル変数 ***
    lv_kyoten_cd               PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE5%TYPE;              --  拠点コード
    lv_new_kyoten_cd           PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE5%TYPE;              -- （新）拠点コード
    lv_old_kyoten_cd           PER_ALL_ASSIGNMENTS_F.ASS_ATTRIBUTE6%TYPE;              -- （旧）拠点コード
    lv_busyo_cd                XXCSM_MST_QUALIFICATE_PNT.POST_CD%TYPE;                 --  部署コード
    lv_new_busyo_cd            XXCSM_MST_QUALIFICATE_PNT.POST_CD%TYPE;                 -- （新）部署コード
    lv_old_busyo_cd            XXCSM_MST_QUALIFICATE_PNT.POST_CD%TYPE;                 -- （旧）部署コード
    lv_shikaku_cd              PER_PEOPLE_F.ATTRIBUTE7%TYPE;                           --  資格コード
    lv_new_shikaku_cd          PER_PEOPLE_F.ATTRIBUTE7%TYPE;                           -- （新）資格コード
    lv_old_shikaku_cd          PER_PEOPLE_F.ATTRIBUTE9%TYPE;                           -- （旧）資格コード
    lv_syokumu_cd              PER_PEOPLE_F.ATTRIBUTE15%TYPE;                          --  職務コード
    lv_new_syokumu_cd          PER_PEOPLE_F.ATTRIBUTE15%TYPE;                          -- （新）職務コード
    lv_old_syokumu_cd          PER_PEOPLE_F.ATTRIBUTE17%TYPE;                          -- （旧）職務コード
    ln_shikaku_point           NUMBER;                                                --  資格ポイント
    ln_new_shikaku_point       NUMBER;                                                -- （新）資格ポイント
    ln_old_shikaku_point       NUMBER;                                                -- （旧）資格ポイント
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
    ln_shikaku_count           NUMBER;                                                -- 資格カウント対象チェック
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
    -- *** ローカル・カーソル ***
    CURSOR get_eigyo_date_cur(
      gd_process_date  DATE
     )
    IS
      --従業員の職種が旧部署のみで営業員のケース
--//+DEL  START  2009/07/27 0000786 T.Tsukino
--      SELECT
--//+DEL  END  2009/07/27 0000786 T.Tsukino
--//+ADD  START  2009/07/27 0000786 T.Tsukino
        SELECT /*+ LEADING(ippf.ippf.pap) INDEX(ppf.pap PER_PEOPLE_F_PK) */
--//+ADD  END  2009/07/27 0000786 T.Tsukino
               ppf.employee_number                            employee_number     --従業員コード
              ,SUBSTRB(paaf.ass_attribute2,1,6)               hatsureibi          --発令日(YYYYMMDD⇒YYYYMM）
              ,ppf.attribute7                                 new_shikaku_cd      --資格コード（新）
              ,ppf.attribute9                                 old_shikaku_cd      --資格コード（旧）
              ,ppf.attribute15                                new_syokumu_cd      --職務コード（新）
              ,ppf.attribute17                                old_syokumu_cd      --職務コード（旧）
              ,NULL                                           new_syokusyu_cd     --職種コード（新）
              ,ppf.attribute21                                old_syokusyu_cd     --職種コード（旧）
              ,paaf.ass_attribute5                            new_kyoten_cd       --拠点コード（新）
              ,paaf.ass_attribute6                            old_kyoten_cd       --拠点コード（旧）
      FROM
               per_people_f                ppf                                    --従業員マスタ
              ,per_periods_of_service      ppos                                   --従業員サービスマスタ
              ,per_all_assignments_f       paaf                                   --従業員アサイメントマスタ
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
              ,(SELECT   ippf.person_id                  person_id                                  -- 従業員ID
                        ,MAX(ippf.effective_start_date)  effective_start_date                       -- 最新(適用開始日)
                FROM     per_people_f      ippf                                                     -- 従業員マスタ
                WHERE    ippf.current_emp_or_apl_flag = 'Y'                                         -- 有効フラグ
                GROUP BY ippf.person_id)   ippf                                                     -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
--//+UPD START 2009/07/01 0000253 M.Ohtsuki
--      WHERE    ppf.person_id = ppos.person_id                                     -- (紐付け) 従業員マスタ．従業員ID = 従業員サービスマスタ．従業員ID
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      WHERE    ippf.person_id = ppf.person_id                                                       -- 従業員ID紐付↓
      AND      ippf.effective_start_date = ppf.effective_start_date                                 -- 適用開始日紐付け
      AND      paaf.effective_start_date = ppf.effective_start_date                                 -- 適用開始日紐付け
      AND      paaf.period_of_service_id = ppos.period_of_service_id                                -- サービスID紐付け
--//+UPD END   2009/07/01 0000253 M.Ohtsuki
      AND      ppf.person_id = paaf.person_id                                     --（紐付け）従業員マスタ．従業員ID = 従業員アサインメントマスタ．従業員ID
      AND      ppos.date_start <= gd_process_date                                 --（抽出条件）入社年月日が業務日付以下
      AND     (ppos.actual_termination_date > gd_process_date
                  OR ppos.actual_termination_date IS NULL)                         --（抽出条件）退職年月日が業務日付より後ORデータなし
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --クイックコード値
                      WHERE  flv.lookup_type = 'XXCSM1_BUSINESS_INFO'    --コードタイプ:営業員定義を指す文字列（”XXCSM1_BUSINESS_INFO”）
                      AND    flv.language    = 'JA'                      --言語
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                      AND    flv.enabled_flag = 'Y'
                      AND    flv.lookup_code =  ppf.attribute21          --職種コード（旧）が営業員
--//+UPD START 2009/04/15 T1_0568 M.Ohtsuki
--                      AND    flv.lookup_code <> ppf.attribute19          --職種コード（新）が営業員以外
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                      AND    (flv.lookup_code <> ppf.attribute19          --職種コード（新）が営業員以外
                              OR ppf.attribute19 IS NULL)                 --職種コード（新）がNULL
--//+UPD END   2009/04/15 T1_0568 M.Ohtsuki
                      AND    SUBSTRB(paaf.ass_attribute2,1,6) >= TO_CHAR(gd_process_date,'YYYYMM')) --前月以前に営業員でなくなった従業員を除外
--//+ADD START 2009/10/22 E-T4-00065 T.Tsukino
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --クイックコード値
                      WHERE  flv.lookup_type = cv_point_countcd          --参照タイプ：資格カウント対象コード
                      AND    flv.language    = 'JA'                      --言語
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                      AND    flv.enabled_flag = 'Y'
--//+DEL START 2009/11/26 E-本稼動-00110 T.Tsukino
--                      AND    (flv.lookup_code =  ppf.attribute7          --資格コード（新）が資格カウント対象コード
--                              OR flv.lookup_code = ppf.attribute9))        --資格コード（旧）が資格カウント対象コード
--//+DEL END 2009/11/26 E-本稼動-00110 T.Tsukino
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
                      AND    flv.lookup_code = ppf.attribute9)            --資格コード（旧）が資格カウント対象コード
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
--//+ADD END 2009/10/22 E-T4-00065 T.Tsukino
      UNION ALL
      --従業員の職種が新部署のみで営業員のケース
--//+DEL  START  2009/07/27 0000786 T.Tsukino
--      SELECT
--//+DEL  END  2009/07/27 0000786 T.Tsukino
--//+ADD  START  2009/07/27 0000786 T.Tsukino
        SELECT /*+ LEADING(ippf.ippf.pap) INDEX(ppf.pap PER_PEOPLE_F_PK) */
--//+ADD  END  2009/07/27 0000786 T.Tsukino
               ppf.employee_number                            employee_number     --従業員コード
--//+ADD START 2009/09/03 0001286 K.Kubo
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--              ,SUBSTRB(paaf.ass_attribute2,1,6)               hatsureibi          --発令日(YYYYMMDD⇒YYYYMM）
              ,paaf.ass_attribute2                            hatsureibi          --発令日(YYYYMMDD）
--//+ADD END   2009/09/03 0001286 K.Kubo
              ,ppf.attribute7                                 new_shikaku_cd      --資格コード（新）
              ,ppf.attribute9                                 old_shikaku_cd      --資格コード（旧）
              ,ppf.attribute15                                new_syokumu_cd      --職務コード（新）
              ,ppf.attribute17                                old_syokumu_cd      --職務コード（旧）
              ,ppf.attribute19                                new_syokusyu_cd     --職種コード（新）
              ,NULL                                           old_syokusyu_cd     --職種コード（旧）
              ,paaf.ass_attribute5                            new_kyoten_cd       --拠点コード（新）
              ,paaf.ass_attribute6                            old_kyoten_cd       --拠点コード（旧）
      FROM
               per_people_f                ppf                                    --従業員マスタ
              ,per_periods_of_service      ppos                                   --従業員サービスマスタ
              ,per_all_assignments_f       paaf                                   --従業員アサイメントマスタ
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
              ,(SELECT   ippf.person_id                  person_id                                  -- 従業員ID
                        ,MAX(ippf.effective_start_date)  effective_start_date                       -- 最新(適用開始日)
                FROM     per_people_f      ippf                                                     -- 従業員マスタ
                WHERE    ippf.current_emp_or_apl_flag = 'Y'                                         -- 有効フラグ
                GROUP BY ippf.person_id)   ippf                                                     -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
--//+UPD START 2009/07/01 0000253 M.Ohtsuki
--      WHERE    ppf.person_id = ppos.person_id                                     -- (紐付け) 従業員マスタ．従業員ID = 従業員サービスマスタ．従業員ID
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      WHERE    ippf.person_id = ppf.person_id                                                       -- 従業員ID紐付↓
      AND      ippf.effective_start_date = ppf.effective_start_date                                 -- 適用開始日紐付け
      AND      paaf.effective_start_date = ppf.effective_start_date                                 -- 適用開始日紐付け
      AND      paaf.period_of_service_id = ppos.period_of_service_id                                -- サービスID紐付け
--//+UPD END   2009/07/01 0000253 M.Ohtsuki
      AND      ppf.person_id = paaf.person_id                                     --（紐付け）従業員マスタ．従業員ID = 従業員アサインメントマスタ．従業員ID
      AND      ppos.date_start <= gd_process_date                                 --（抽出条件）入社年月日が業務日付以下
      AND     (ppos.actual_termination_date > gd_process_date
                  OR ppos.actual_termination_date IS NULL)                         --（抽出条件）退職年月日が業務日付より後ORデータなし
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --クイックコード値
                      WHERE  flv.lookup_type = 'XXCSM1_BUSINESS_INFO'    --コードタイプ:営業員定義を指す文字列（”XXCSM1_BUSINESS_INFO”）
                      AND    flv.language    = 'JA'                      --言語
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                      AND    flv.enabled_flag = 'Y'
--//+UPD START 2009/04/15 T1_0568 M.Ohtsuki
--                      AND    flv.lookup_code <> ppf.attribute21          --職種コード（旧）が営業員以外
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
                      AND    (flv.lookup_code <> ppf.attribute21          --職種コード（旧）が営業員以外
                             OR ppf.attribute21 IS NULL)                  --職種コード（旧）がNULL
--//+UPD END   2009/04/15 T1_0568 M.Ohtsuki
                      AND    flv.lookup_code =  ppf.attribute19          --職種コード（新）が営業員
                      AND    SUBSTRB(paaf.ass_attribute2,1,6) <= TO_CHAR(gd_process_date,'YYYYMM')) --翌月以降に営業員でとなる従業員を除外
--//+ADD START 2009/10/22 E-T4-00065 T.Tsukino
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --クイックコード値
                      WHERE  flv.lookup_type = cv_point_countcd          --参照タイプ：資格カウント対象コード
                      AND    flv.language    = 'JA'                      --言語
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                      AND    flv.enabled_flag = 'Y'
--//+DEL START 2009/11/26 E-本稼動-00110 T.Tsukino
--                      AND    (flv.lookup_code =  ppf.attribute7          --資格コード（新）が資格カウント対象コード
--                              OR flv.lookup_code = ppf.attribute9))        --資格コード（旧）が資格カウント対象コード
--//+DEL END 2009/11/26 E-本稼動-00110 T.Tsukino
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
                      AND    flv.lookup_code =  ppf.attribute7)          --資格コード（新）が資格カウント対象コード
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
--//+ADD END 2009/10/22 E-T4-00065 T.Tsukino
      UNION ALL
      --従業員の職種が新・旧部署ともに営業員のケース
      SELECT
               ppf.employee_number                            employee_number     --従業員コード
--//+ADD START 2009/08/24 0001150 T.Tsukino
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--              ,SUBSTRB(paaf.ass_attribute2,1,6)               hatsureibi          --発令日(YYYYMMDD⇒YYYYMM）
              ,paaf.ass_attribute2                            hatsureibi          --発令日(YYYYMMDD）
--//+ADD END 2009/08/24 0001150 T.Tsukino
              ,ppf.attribute7                                 new_shikaku_cd      --資格コード（新）
              ,ppf.attribute9                                 old_shikaku_cd      --資格コード（旧）
              ,ppf.attribute15                                new_syokumu_cd      --職務コード（新）
              ,ppf.attribute17                                old_syokumu_cd      --職務コード（旧）
              ,ppf.attribute19                                new_syokusyu_cd     --職種コード（新）
              ,ppf.attribute21                                old_syokusyu_cd     --職種コード（旧）
              ,paaf.ass_attribute5                            new_kyoten_cd       --拠点コード（新）
              ,paaf.ass_attribute6                            old_kyoten_cd       --拠点コード（旧）
      FROM
               per_people_f                ppf                                    --従業員マスタ
              ,per_periods_of_service      ppos                                   --従業員サービスマスタ
              ,per_all_assignments_f       paaf                                   --従業員アサイメントマスタ
--//+ADD START 2009/07/01 0000253 M.Ohtsuki
              ,(SELECT   ippf.person_id                  person_id                                  -- 従業員ID
                        ,MAX(ippf.effective_start_date)  effective_start_date                       -- 最新(適用開始日)
                FROM     per_people_f      ippf                                                     -- 従業員マスタ
                WHERE    ippf.current_emp_or_apl_flag = 'Y'                                         -- 有効フラグ
                GROUP BY ippf.person_id)   ippf                                                     -- 従業員ID
--//+ADD END   2009/07/01 0000253 M.Ohtsuki
--//+UPD START 2009/07/01 0000253 M.Ohtsuki
--      WHERE    ppf.person_id = ppos.person_id                                     -- (紐付け) 従業員マスタ．従業員ID = 従業員サービスマスタ．従業員ID
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
      WHERE    ippf.person_id = ppf.person_id                                                       -- 従業員ID紐付↓
      AND      ippf.effective_start_date = ppf.effective_start_date                                 -- 適用開始日紐付け
      AND      paaf.effective_start_date = ppf.effective_start_date                                 -- 適用開始日紐付け
      AND      paaf.period_of_service_id = ppos.period_of_service_id                                -- サービスID紐付け
--//+UPD END   2009/07/01 0000253 M.Ohtsuki
      AND      ppf.person_id = paaf.person_id                                     --（紐付け）従業員マスタ．従業員ID = 従業員アサインメントマスタ．従業員ID
      AND      ppos.date_start <= gd_process_date                                 --（抽出条件）入社年月日が業務日付以下
      AND     (ppos.actual_termination_date > gd_process_date
                  OR ppos.actual_termination_date IS NULL)                         --（抽出条件）退職年月日が業務日付より後ORデータなし
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --クイックコード値
                      WHERE  flv.lookup_type = 'XXCSM1_BUSINESS_INFO'    --コードタイプ:営業員定義を指す文字列（”XXCSM1_BUSINESS_INFO”）
                      AND    flv.language    = 'JA'                      --言語
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                      AND    flv.enabled_flag = 'Y'
                      AND    flv.lookup_code =  ppf.attribute21          --職種コード（旧）が営業員
                      AND    flv.lookup_code =  ppf.attribute19)         --職種コード（新）が営業員
--//+ADD START 2009/10/22 E-T4-00065 T.Tsukino
      AND     EXISTS (SELECT 'X'
                      FROM   fnd_lookup_values  flv                      --クイックコード値
                      WHERE  flv.lookup_type = cv_point_countcd          --参照タイプ：資格カウント対象コード
                      AND    flv.language    = 'JA'                      --言語
                      AND    NVL(flv.start_date_active,gd_process_date) <= gd_process_date    --有効開始日<=業務日付
                      AND    NVL(flv.end_date_active,gd_process_date) >= gd_process_date      --有効終了日>=業務日付
                      AND    flv.enabled_flag = 'Y'
                      AND    (flv.lookup_code =  ppf.attribute7          --資格コード（新）が資格カウント対象コード
                              OR flv.lookup_code = ppf.attribute9))        --資格コード（旧）が資格カウント対象コード
--//+ADD END 2009/10/22 E-T4-00065 T.Tsukino
    ;
    -- *** ローカル・レコード ***
    get_eigyo_date_rec    get_eigyo_date_cur%ROWTYPE;
    -- *** ローカル例外 ***
    no_data_expt      EXCEPTION;                                                  -- 営業員データ取得エラーメッセージ
    global_skip_expt  EXCEPTION;                                                  -- 例外処理
    no_data_hatsurei  EXCEPTION;                                                  -- 発令日取得エラーメッセージ
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
    shikaku_count_expt  EXCEPTION;                                                -- 資格カウント対象外エラーメッセージ
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
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
--
    -- ======================================
    -- A-1.初期処理
    -- ======================================
    init(
       iv_process_date => iv_process_date
      ,ov_errbuf       => lv_errbuf                                             -- エラー・メッセージ
      ,ov_retcode      => lv_retcode                                            -- リターン・コード
      ,ov_errmsg       => lv_errmsg                                             -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_process_expt;
    END IF;
    -- ======================================
    -- ローカル・カーソルオープン
    -- ======================================
    OPEN get_eigyo_date_cur(gd_process_date);
    <<get_eigyo_date_loop>>
    LOOP
      FETCH get_eigyo_date_cur INTO get_eigyo_date_rec;
    -- 処理対象件数格納
          gn_target_cnt := get_eigyo_date_cur%ROWCOUNT;
--
      EXIT WHEN get_eigyo_date_cur%NOTFOUND
             OR get_eigyo_date_cur%ROWCOUNT = 0;
      BEGIN
        --セーブポイント
        SAVEPOINT eigyo_date_sv;
        IF (get_eigyo_date_rec.hatsureibi IS NULL) THEN
          RAISE no_data_hatsurei;
        END IF;
--//+UPD START 2009/08/24 0001150 T.Tsukino
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--        IF (get_eigyo_date_rec.hatsureibi = gv_inprocess_date) THEN               --発令日=入力日付'YYYYMM
          IF (SUBSTRB(get_eigyo_date_rec.hatsureibi,1,6) = gv_inprocess_date) THEN               --発令日=入力日付'YYYYMM
--//+UPD END 2009/08/24 0001150 T.Tsukino
           IF(get_eigyo_date_rec.new_syokusyu_cd IS NOT NULL
            AND get_eigyo_date_rec.old_syokusyu_cd IS NOT NULL)
          THEN
--//+ADD START 2009/08/24 0001150 T.Tsukino
            IF (SUBSTRB(get_eigyo_date_rec.hatsureibi,7,2) = cv_tougetsu_date) THEN
            --新データでデータを作る処理
        -- ◇================================◇
        --  新の処理にて、
        --  ①部署コード抽出/資格ポイントの算出
        --  ②レコードの削除
        --  ③レコードの新規追加を行う
        -- ◇================================◇
            --新データの代入
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- 資格ポイントカウント対象コードチェック
         -- ================================================
            -- 新の資格コードがカウント対象コードがチェック
              point_countcd_chk(
                 iv_shikaku_cd     =>     get_eigyo_date_rec.new_shikaku_cd
                ,on_shikaku_count  =>     ln_shikaku_count
                ,ov_errbuf         =>     lv_errbuf
                ,ov_retcode        =>     lv_retcode
                ,ov_errmsg         =>     lv_errmsg
                );
                -- カウントが0値を返した場合、従業員コードを処理対象から外す
                IF (ln_shikaku_count = 0) THEN
                  RAISE shikaku_count_expt;
                END IF;
                IF (lv_retcode <> cv_status_normal) THEN
                  RAISE global_process_expt;
                END IF;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- （新データ)部署データの抽出処理
         -- ================================================
              get_dept_data(
                 iv_employee_cd      =>   get_eigyo_date_rec.employee_number
                ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
                ,ov_busyo_cd         =>   lv_busyo_cd
                ,ov_errbuf           =>   lv_errbuf
                ,ov_retcode          =>   lv_retcode
                ,ov_errmsg           =>   lv_errmsg
                );
                -- エラーならば、処理をスキップする。
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
         -- ================================================
         -- (新データ)資格ポイント算出処理
         -- ================================================
              get_point_data(
                 iv_employee_cd      =>   get_eigyo_date_rec.employee_number
                ,iv_busyo_cd         =>   lv_busyo_cd
                ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
                ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
                ,on_shikaku_point    =>   ln_shikaku_point
                ,ov_errbuf           =>   lv_errbuf
                ,ov_retcode          =>   lv_retcode
                ,ov_errmsg           =>   lv_errmsg
                );
                -- エラーならば、処理をスキップする。
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
         -- ======================================
         -- レコード削除処理
         -- ======================================
              del_rireki_tbl_data(
                 iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
                ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
                ,ov_retcode           => lv_retcode                                      -- リターン・コード
                ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
                );
                -- エラーならば、処理をスキップする。
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
         -- ======================================
         -- レコード新規追加処理
         -- ======================================
              insert_rireki_tbl_data (
                 iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
                ,in_shikaku_point     => ln_shikaku_point                                -- 資格ポイント
                ,iv_busyo_cd          => lv_busyo_cd                                     -- 部署コード
                ,iv_syokumu_cd        => get_eigyo_date_rec.new_syokumu_cd               -- 職務コード
                ,iv_shikaku_cd        => get_eigyo_date_rec.new_shikaku_cd               -- 資格コード
                ,iv_kyoten_cd         => get_eigyo_date_rec.new_kyoten_cd                -- 拠点コード
                ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
                ,ov_retcode           => lv_retcode                                      -- リターン・コード
                ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
                );
                -- エラーならば、処理をスキップする。
                IF (lv_retcode = cv_status_error) THEN
                  RAISE global_process_expt;
                END IF;
                IF (lv_retcode = cv_status_warn) THEN
                  RAISE global_skip_expt;
                END IF;
            ELSE
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- 資格ポイントカウント対象コードチェック
         -- ================================================
          -- 新の資格コードがカウント対象コードがチェック
            point_countcd_chk(
               iv_shikaku_cd     =>     get_eigyo_date_rec.new_shikaku_cd
              ,on_shikaku_count  =>     ln_shikaku_count
              ,ov_errbuf         =>     lv_errbuf
              ,ov_retcode        =>     lv_retcode
              ,ov_errmsg         =>     lv_errmsg
              );
              -- カウントが0値を返した場合、従業員コードを処理対象から外す
              IF (ln_shikaku_count = 0) THEN
                RAISE shikaku_count_expt;
              END IF;
              IF (lv_retcode <> cv_status_normal) THEN
                RAISE global_process_expt;
              END IF;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
--//+ADD END 2009/08/24 0001150 T.Tsukino
            -- ================================================
            -- (新データ)部署データの抽出処理
            -- ================================================
            get_dept_data(
              iv_employee_cd      =>   get_eigyo_date_rec.employee_number
             ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
             ,ov_busyo_cd         =>   lv_new_busyo_cd
             ,ov_errbuf           =>   lv_errbuf
             ,ov_retcode          =>   lv_retcode
             ,ov_errmsg           =>   lv_errmsg
             );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ================================================
            -- (新データ)資格ポイント算出処理
            -- ================================================
            get_point_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_busyo_cd         =>   lv_new_busyo_cd
              ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
              ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
              ,on_shikaku_point    =>   ln_new_shikaku_point
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- 資格ポイントカウント対象コードチェック
         -- ================================================
         -- 旧の資格コードがカウント対象コードかチェック
            point_countcd_chk(
               iv_shikaku_cd     =>     get_eigyo_date_rec.old_shikaku_cd
              ,on_shikaku_count  =>     ln_shikaku_count
              ,ov_errbuf         =>     lv_errbuf
              ,ov_retcode        =>     lv_retcode
              ,ov_errmsg         =>     lv_errmsg
              );
              -- カウントが0値を返した場合、従業員コードを処理対象から外す
              IF (ln_shikaku_count = 0) THEN
                RAISE shikaku_count_expt;
              END IF;
              IF (lv_retcode <> cv_status_normal) THEN
                RAISE global_process_expt;
              END IF;
--//+ADD END2009/11/26 E-本稼動-00110 T.Tsukino
            --旧のデータ取得
            -- ================================================
            -- (旧データ)部署データの抽出処理
            -- ================================================
            get_dept_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_kyoten_cd        =>   get_eigyo_date_rec.old_kyoten_cd
              ,ov_busyo_cd         =>   lv_old_busyo_cd
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ================================================
            -- (旧データ)資格ポイント算出処理
            -- ================================================
            get_point_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_busyo_cd         =>   lv_old_busyo_cd
              ,iv_shikaku_cd       =>   get_eigyo_date_rec.old_shikaku_cd
              ,iv_syokumu_cd       =>   get_eigyo_date_rec.old_syokumu_cd
              ,on_shikaku_point    =>   ln_old_shikaku_point
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            --<<新/旧データの資格ポイントの比較>>---------------------------------------------------
            --新データの資格ポイントが旧データの資格ポイント以下の場合、新データの値を代入
            IF (ln_new_shikaku_point <= ln_old_shikaku_point) THEN
                ln_shikaku_point  :=  ln_new_shikaku_point;                     -- 資格ポイント
                lv_busyo_cd       :=  lv_new_busyo_cd;                          -- 部署コード
                lv_syokumu_cd     :=  get_eigyo_date_rec.new_syokumu_cd;        -- 職務コード
                lv_shikaku_cd     :=  get_eigyo_date_rec.new_shikaku_cd;        -- 資格コード
                lv_kyoten_cd      :=  get_eigyo_date_rec.new_kyoten_cd;         -- 拠点コード
            --新データの資格ポイントより旧データの資格ポイントが低い場合、旧データの値を代入
            ELSE
                ln_shikaku_point  :=  ln_old_shikaku_point;                     -- 資格ポイント
                lv_busyo_cd       :=  lv_old_busyo_cd;                          -- 部署コード
                lv_syokumu_cd     :=  get_eigyo_date_rec.old_syokumu_cd;        -- 職務コード
                lv_shikaku_cd     :=  get_eigyo_date_rec.old_shikaku_cd;        -- 資格コード
                lv_kyoten_cd      :=  get_eigyo_date_rec.old_kyoten_cd;         -- 拠点コード
            END IF;
           --<<新/旧データの資格ポイントの比較/終わり>>---------------------------------------------------
            -- ======================================
            -- レコード削除処理
            -- ======================================
            del_rireki_tbl_data(
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
              ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                      -- リターン・コード
              ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- レコード新規追加処理
            -- ======================================
            insert_rireki_tbl_data (
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
              ,in_shikaku_point     => ln_shikaku_point                                -- 資格ポイント
              ,iv_busyo_cd          => lv_busyo_cd                                     -- 部署コード
              ,iv_syokumu_cd        => lv_syokumu_cd                                   -- 職務コード
              ,iv_shikaku_cd        => lv_shikaku_cd                                   -- 資格コード
              ,iv_kyoten_cd         => lv_kyoten_cd                                    -- 拠点コード
              ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                      -- リターン・コード
              ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
--//+ADD START 2009/08/24 0001150 T.Tsukino
            END IF;
--//+ADD END 2009/08/24 0001150 T.Tsukino
          --資格ポイント抽出    処理不要の場合①
          --新データのみ取得
          ELSIF (get_eigyo_date_rec.new_syokusyu_cd IS NOT NULL
            AND get_eigyo_date_rec.old_syokusyu_cd IS NULL) THEN
        -- ◇================================◇
        --  新の処理にて、
        --  ①部署コード抽出
        --  ②レコードの削除
        --  ③レコードの新規追加を行う
        -- ◇================================◇
            --新データの代入
            -- ================================================
            -- (新データ)部署データの抽出処理
            -- ================================================
            get_dept_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
              ,ov_busyo_cd         =>   lv_busyo_cd
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- レコード削除処理
            -- ======================================
            del_rireki_tbl_data(
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
              ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                      -- リターン・コード
              ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
--//+ADD START 2009/09/03 0001286 K.Kubo
            IF (SUBSTRB(get_eigyo_date_rec.hatsureibi,7,2) = cv_tougetsu_date) THEN
              --発令日が当月１日の場合、新データの資格ポイントを取得
              -- ================================================
              -- (新データ)資格ポイント算出処理
              -- ================================================
              get_point_data(
                 iv_employee_cd      =>   get_eigyo_date_rec.employee_number
                ,iv_busyo_cd         =>   lv_busyo_cd
                ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
                ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
                ,on_shikaku_point    =>   ln_shikaku_point
                ,ov_errbuf           =>   lv_errbuf
                ,ov_retcode          =>   lv_retcode
                ,ov_errmsg           =>   lv_errmsg
                );
              -- エラーならば、処理をスキップする。
              IF (lv_retcode = cv_status_error) THEN
                RAISE global_process_expt;
              END IF;
              IF (lv_retcode = cv_status_warn) THEN
                RAISE global_skip_expt;
              END IF;
--
            ELSE
              --それ以外の場合は、資格ポイントは'0'を設定
              ln_shikaku_point := cn_shikaku_point;
            END IF;
--//+ADD END   2009/09/03 0001286 K.Kubo
            -- ======================================
            -- レコード新規追加処理
            -- ======================================
            insert_rireki_tbl_data (
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
--//+UPD START 2009/09/03 0001286 K.Kubo
--              ,in_shikaku_point     => cn_shikaku_point                                -- 資格ポイント
              ,in_shikaku_point     => ln_shikaku_point                                -- 資格ポイント
--//+UPD END   2009/09/03 0001286 K.Kubo
              ,iv_busyo_cd          => lv_busyo_cd                                     -- 部署コード
              ,iv_syokumu_cd        => get_eigyo_date_rec.new_syokumu_cd               -- 職務コード
              ,iv_shikaku_cd        => get_eigyo_date_rec.new_shikaku_cd               -- 資格コード
              ,iv_kyoten_cd         => get_eigyo_date_rec.new_kyoten_cd                -- 拠点コード
              ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                      -- リターン・コード
              ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
          --資格ポイント抽出処理不要の場合②
          --旧データのみ取得
          ELSIF (get_eigyo_date_rec.old_syokusyu_cd IS NOT NULL
            AND get_eigyo_date_rec.new_syokusyu_cd IS NULL) THEN
        -- ◇================================◇
        --  旧の処理にて、
        --  ①部署コード抽出
        --  ②レコードの削除
        --  ③レコードの新規追加を行う
        -- ◇================================◇
        --旧のデータ取得
            -- ================================================
            -- (旧データ)部署データの抽出処理
            -- ================================================
            get_dept_data(
               iv_employee_cd      =>   get_eigyo_date_rec.employee_number
              ,iv_kyoten_cd        =>   get_eigyo_date_rec.old_kyoten_cd
              ,ov_busyo_cd         =>   lv_busyo_cd
              ,ov_errbuf           =>   lv_errbuf
              ,ov_retcode          =>   lv_retcode
              ,ov_errmsg           =>   lv_errmsg
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- レコード削除処理
            -- ======================================
            del_rireki_tbl_data(
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
              ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                      -- リターン・コード
              ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
            -- ======================================
            -- レコード新規追加処理
            -- ======================================
            insert_rireki_tbl_data (
               iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
              ,in_shikaku_point     => cn_shikaku_point                                -- 資格ポイント
              ,iv_busyo_cd          => lv_busyo_cd                                     -- 部署コード
              ,iv_syokumu_cd        => get_eigyo_date_rec.old_syokumu_cd               -- 職務コード
              ,iv_shikaku_cd        => get_eigyo_date_rec.old_shikaku_cd               -- 資格コード
              ,iv_kyoten_cd         => get_eigyo_date_rec.old_kyoten_cd                -- 拠点コード
              ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
              ,ov_retcode           => lv_retcode                                      -- リターン・コード
              ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
              );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
          END IF;
--//+UPD START 2009/08/24 0001150 T.Tsukino
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--        ELSIF (get_eigyo_date_rec.hatsureibi > gv_inprocess_date) THEN            -- 発令日＞入力日付'YYYYMM'
        ELSIF (SUBSTRB(get_eigyo_date_rec.hatsureibi,1,6) > gv_inprocess_date) THEN            -- 発令日＞入力日付'YYYYMM'
--//+UPD END 2009/08/24 0001150 T.Tsukino
        -- ◇================================◇
        --  旧の処理にて、
        --  ①部署コード抽出/資格ポイントの算出
        --  ②レコードの削除
        --  ③レコードの新規追加を行う
        -- ◇================================◇
         --旧データの代入
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- 資格ポイントカウント対象コードチェック
         -- ================================================
        -- 旧の資格コードがカウント対象コードかチェック
          point_countcd_chk(
             iv_shikaku_cd     =>     get_eigyo_date_rec.old_shikaku_cd
            ,on_shikaku_count  =>     ln_shikaku_count
            ,ov_errbuf         =>     lv_errbuf
            ,ov_retcode        =>     lv_retcode
            ,ov_errmsg         =>     lv_errmsg
            );
          -- カウントが0値を返した場合、従業員コードを処理対象から外す
            IF (ln_shikaku_count = 0) THEN
              RAISE shikaku_count_expt;
            END IF;
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- (旧データ)部署データの抽出処理
         -- ================================================
          get_dept_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_kyoten_cd        =>   get_eigyo_date_rec.old_kyoten_cd
            ,ov_busyo_cd         =>   lv_busyo_cd
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
         -- ================================================
         -- (旧データ)資格ポイント算出処理
         -- ================================================
          get_point_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_busyo_cd         =>   lv_busyo_cd
            ,iv_shikaku_cd       =>   get_eigyo_date_rec.old_shikaku_cd
            ,iv_syokumu_cd       =>   get_eigyo_date_rec.old_syokumu_cd
            ,on_shikaku_point    =>   ln_shikaku_point
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- レコード削除処理
        -- ======================================
          del_rireki_tbl_data(
             iv_employee_num      => get_eigyo_date_rec.employee_number                                  -- 従業員№
            ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
            ,ov_retcode           => lv_retcode                                      -- リターン・コード
            ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- レコード新規追加処理
        -- ======================================
          insert_rireki_tbl_data (
             iv_employee_num      => get_eigyo_date_rec.employee_number                                  -- 従業員№
            ,in_shikaku_point     => ln_shikaku_point                                -- 資格ポイント
            ,iv_busyo_cd          => lv_busyo_cd                                     -- 部署コード
            ,iv_syokumu_cd        => get_eigyo_date_rec.old_syokumu_cd               -- 職務コード
            ,iv_shikaku_cd        => get_eigyo_date_rec.old_shikaku_cd               -- 資格コード
            ,iv_kyoten_cd         => get_eigyo_date_rec.old_kyoten_cd                -- 拠点コード
            ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
            ,ov_retcode           => lv_retcode                                      -- リターン・コード
            ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
--//+UPD START 2009/08/24 0001150 T.Tsukino
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
--        ELSIF (get_eigyo_date_rec.hatsureibi < gv_inprocess_date) THEN            -- 発令日＜入力日付'YYYYMM'
        ELSIF (SUBSTRB(get_eigyo_date_rec.hatsureibi,1,6) < gv_inprocess_date) THEN            -- 発令日＜入力日付'YYYYMM'
--//+UPD END 2009/08/24 0001150 T.Tsukino
        -- ◇================================◇
        --  新の処理にて、
        --  ①部署コード抽出/資格ポイントの算出
        --  ②レコードの削除
        --  ③レコードの新規追加を行う
        -- ◇================================◇
            --新データの代入
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- 資格ポイントカウント対象コードチェック
         -- ================================================
       -- 新の資格コードがカウント対象コードかチェック
          point_countcd_chk(
             iv_shikaku_cd     =>     get_eigyo_date_rec.new_shikaku_cd
            ,on_shikaku_count  =>     ln_shikaku_count
            ,ov_errbuf         =>     lv_errbuf
            ,ov_retcode        =>     lv_retcode
            ,ov_errmsg         =>     lv_errmsg
            );
          -- カウントが0値を返した場合、従業員コードを処理対象から外す
            IF (ln_shikaku_count = 0) THEN
              RAISE shikaku_count_expt;
            END IF;
            IF (lv_retcode <> cv_status_normal) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
         -- ================================================
         -- （新データ)部署データの抽出処理
         -- ================================================
          get_dept_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_kyoten_cd        =>   get_eigyo_date_rec.new_kyoten_cd
            ,ov_busyo_cd         =>   lv_busyo_cd
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
         -- ================================================
         -- (新データ)資格ポイント算出処理
         -- ================================================
          get_point_data(
             iv_employee_cd      =>   get_eigyo_date_rec.employee_number
            ,iv_busyo_cd         =>   lv_busyo_cd
            ,iv_shikaku_cd       =>   get_eigyo_date_rec.new_shikaku_cd
            ,iv_syokumu_cd       =>   get_eigyo_date_rec.new_syokumu_cd
            ,on_shikaku_point    =>   ln_shikaku_point
            ,ov_errbuf           =>   lv_errbuf
            ,ov_retcode          =>   lv_retcode
            ,ov_errmsg           =>   lv_errmsg
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- レコード削除処理
        -- ======================================
          del_rireki_tbl_data(
             iv_employee_num      => get_eigyo_date_rec.employee_number                                  -- 従業員№
            ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
            ,ov_retcode           => lv_retcode                                      -- リターン・コード
            ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        -- ======================================
        -- レコード新規追加処理
        -- ======================================
          insert_rireki_tbl_data (
             iv_employee_num      => get_eigyo_date_rec.employee_number              -- 従業員№
            ,in_shikaku_point     => ln_shikaku_point                                -- 資格ポイント
            ,iv_busyo_cd          => lv_busyo_cd                                     -- 部署コード
            ,iv_syokumu_cd        => get_eigyo_date_rec.new_syokumu_cd               -- 職務コード
            ,iv_shikaku_cd        => get_eigyo_date_rec.new_shikaku_cd               -- 資格コード
            ,iv_kyoten_cd         => get_eigyo_date_rec.new_kyoten_cd                -- 拠点コード
            ,ov_errbuf            => lv_errbuf                                       -- エラー・メッセージ
            ,ov_retcode           => lv_retcode                                      -- リターン・コード
            ,ov_errmsg            => lv_errmsg                                       -- ユーザー・エラー・メッセージ
            );
            -- エラーならば、処理をスキップする。
--//+ADD START 2009/07/14 0000663 M.Ohtsuki
            IF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--//+ADD END   2009/07/14 0000663 M.Ohtsuki
--//+UPD START 2009/07/14 0000663 M.Ohtsuki
--            IF (lv_retcode <> cv_status_normal) THEN
--↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
            IF (lv_retcode = cv_status_warn) THEN
--//+UPD END   2009/07/14 0000663 M.Ohtsuki
              RAISE global_skip_expt;
            END IF;
        END IF;
        -- 正常件数カウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
      EXCEPTION
        WHEN global_skip_expt THEN
          ov_retcode := cv_status_warn;
          --エラー出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                                                    -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => lv_errbuf                                                    -- エラーメッセージ
          );
          --エラー件数のカウント
          gn_error_cnt := gn_error_cnt + 1;
          -- ロールバック
          ROLLBACK TO eigyo_date_sv;
        WHEN no_data_hatsurei THEN
          ov_retcode := cv_status_warn;
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name                            --アプリケーション短縮名
                         ,iv_name         => cv_xxcsm_msg_125                       --メッセージコード
                         ,iv_token_name1  => cv_tkn_jugyoin_cd                      --トークンコード1
                         ,iv_token_value1 => get_eigyo_date_rec.employee_number     --トークン値1
                       );
          ov_errmsg  := lv_errmsg;
          ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg,1,4000);
          --エラー出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => ov_errmsg                                                    -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => ov_errbuf                                                    -- エラーメッセージ
          );
          --エラー件数のカウント
          gn_error_cnt := gn_error_cnt + 1;
          -- ロールバック
          ROLLBACK TO eigyo_date_sv;
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
        WHEN shikaku_count_expt THEN
          gn_shikaku_exptcount := gn_shikaku_exptcount + 1;
          -- ロールバック
          ROLLBACK TO eigyo_date_sv;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
      END;
     END LOOP get_eigyo_date_loop;
--//+ADD START 2009/11/26 E-本稼動-00110 T.Tsukino
  --処理対象外となった件数を対象件数から引く
    gn_target_cnt := gn_target_cnt - gn_shikaku_exptcount;
--//+ADD END 2009/11/26 E-本稼動-00110 T.Tsukino
--
    -- カーソルクローズ
    CLOSE get_eigyo_date_cur;
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      RAISE no_data_expt;
    END IF;
  EXCEPTION
    -- *** 処理対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                            --アプリケーション短縮名
                     ,iv_name         => cv_xxcsm_msg_120                       --メッセージコード
                     ,iv_token_name1  => cv_tkn_process                         --トークンコード1
                     ,iv_token_value1 => gv_inprocess_date                      --トークン値1
                   );
      lv_errbuf := lv_errmsg;
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
      -- カーソルがクローズされていない場合
      IF (get_eigyo_date_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_eigyo_date_cur;
      END IF;
      --エラー出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                                    -- ユーザー・エラーメッセージ
      );
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
    ,iv_process_date  IN  VARCHAR2)                                                                   -- 処理日付
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
       iv_process_date  => iv_process_date
      ,ov_errbuf        => lv_errbuf                                            -- エラー・メッセージ
      ,ov_retcode       => lv_retcode                                           -- リターン・コード
      ,ov_errmsg        => lv_errmsg                                            -- ユーザー・エラー・メッセージ
    );
--
    IF (lv_retcode = cv_status_error) THEN
      IF lv_errmsg IS NULL THEN
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
      gn_error_cnt := 1;
      gn_warn_cnt := 0;
    END IF;
--
    -- =======================
    -- A-6.終了処理
    -- =======================
    --空行の出力
    fnd_file.put_line(
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
END XXCSM004A03C;
/