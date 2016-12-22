CREATE OR REPLACE PACKAGE BODY XXCFO010A04C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 * 
 * Package Name    : XXCFO010A04C(body)
 * Description     : 稟議WF連携
 * MD.050          : MD050_CFO_010_A04_稟議WF連携
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  init              P        初期処理                               (A-1)
 *  del_coop_data     P        稟議WF連携データテーブル削除処理       (A-2)
 *  get_target_data   P        連携対象データの抽出処理               (A-3)
 *  ins_coop_data     P        稟議WF連携データ登録処理               (A-4)
 *  ins_control       P        稟議WF連携管理テーブル登録・更新処理   (A-5)
 *  get_coop_data     P        稟議WF連携データテーブル抽出処理       (A-6)
 *  put_data_file     P        稟議WF連携データファイル出力処理       (A-7)
 *  submain           P        メイン処理プロシージャ
 *  main              P        コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2016-12-09    1.0  SCSK 小路恭弘  初回作成
 ************************************************************************/
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
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
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
  -- ロックエラー
  lock_expt EXCEPTION;
  PRAGMA EXCEPTION_INIT( lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCFO010A04C';               -- パッケージ名
--
  --アプリケーション短縮名
  cv_msg_kbn_cfo      CONSTANT VARCHAR2(5)   := 'XXCFO';                      -- アドオン：会計・アドオン領域のアプリケーション短縮名
  cv_msg_kbn_coi      CONSTANT VARCHAR2(5)   := 'XXCOI';                      -- アドオン：在庫・アドオン領域のアプリケーション短縮名
--
  -- メッセージ番号
  cv_msg_coi_00029    CONSTANT VARCHAR2(20) := 'APP-XXCOI1-00029';            -- ディレクトリフルパス取得エラーメッセージ
  cv_msg_cfo_00001    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00001';            -- プロファイル取得エラーメッセージ
  cv_msg_cfo_00002    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00002';            -- ファイル名出力メッセージ
  cv_msg_cfo_00004    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00004';            -- 対象データが0件メッセージ
  cv_msg_cfo_00015    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00015';            -- 業務日付取得エラーメッセージ
  cv_msg_cfo_00019    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';            -- データロックエラーメッセージ
  cv_msg_cfo_00020    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';            -- 更新エラーメッセージ
  cv_msg_cfo_00024    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00024';            -- 登録エラーメッセージ
  cv_msg_cfo_00025    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00025';            -- データ削除エラーメッセージ
  cv_msg_cfo_00027    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00027';            -- ファイルが存在しているメッセージ
  cv_msg_cfo_00028    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00028';            -- ファイルの場所が無効メッセージ
  cv_msg_cfo_00029    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00029';            -- ファイルをオープンできないメッセージ
  cv_msg_cfo_00030    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00030';            -- ファイルに書込みできないメッセージ
  cv_msg_cfo_00058    CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00058';            -- 対象期間エラー
--
  -- トークン
  cv_tkn_date_from    CONSTANT VARCHAR2(20) := 'DATE_FROM';                   -- 日付FROM
  cv_tkn_dir_tok      CONSTANT VARCHAR2(20) := 'DIR_TOK';                     -- ディレクトリ名
  cv_tkn_table        CONSTANT VARCHAR2(20) := 'TABLE';                       -- テーブル名
  cv_tkn_errmsg       CONSTANT VARCHAR2(20) := 'ERRMSG';                      -- エラー内容
  cv_tkn_prof         CONSTANT VARCHAR2(20) := 'PROF_NAME';                   -- プロファイル名
  cv_tkn_file         CONSTANT VARCHAR2(20) := 'FILE_NAME';                   -- ファイル名
--
  --メッセージ出力用(トークン登録)
  cv_msgtkn_cfo_50001   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-50001';                   -- 稟議WF連携データテーブル
  cv_msgtkn_cfo_50002   CONSTANT VARCHAR2(20) := 'APP-XXCFO1-50002';                   -- 稟議WF連携管理テーブル
--
  -- プロファイル
  cv_set_of_bks_id      CONSTANT VARCHAR2(40) := 'GL_SET_OF_BKS_ID';                   -- 会計帳簿ID
  cv_data_filepath      CONSTANT VARCHAR2(40) := 'XXCFO1_RFD_PAY_DATA_FILEPATH';       -- XXCFO:稟議WF連携支払データファイル格納パス
  cv_data_filename      CONSTANT VARCHAR2(40) := 'XXCFO1_RFD_PAY_DATA_FILENAME';       -- XXCFO:稟議WF連携支払データファイル名
--
  -- 日付型
  cv_format_hh24_mi_ss  CONSTANT VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS';              -- YYYY/MM/DD HH24:MI:SS形式
  cv_format_yyyy_mm_dd  CONSTANT VARCHAR2(10) := 'YYYY/MM/DD';                         -- YYYY/MM/DD形式
--
  -- ファイル出力
  cv_file_type_log      CONSTANT VARCHAR2(3)  := 'LOG';                                -- ログ出力
--
  cv_enabled_flag_n     CONSTANT VARCHAR2(1) := 'N';                                   -- 判定＝N
  cv_enabled_flag_y     CONSTANT VARCHAR2(1) := 'Y';                                   -- 判定＝Y
  cv_user_lang          CONSTANT fnd_lookup_values.language%TYPE := USERENV( 'LANG' ); -- 言語
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 連携対象データ配列
  TYPE g_gl_je_header_id_ttype              IS TABLE OF gl_je_lines.je_header_id%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_je_line_num_ttype               IS TABLE OF gl_je_lines.je_line_num%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_period_year_ttype               IS TABLE OF gl_periods.period_year%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment2_ttype                  IS TABLE OF gl_code_combinations.segment2%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment2_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment6_ttype                  IS TABLE OF gl_code_combinations.segment6%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment6_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment3_ttype                  IS TABLE OF gl_code_combinations.segment3%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment3_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment4_ttype                  IS TABLE OF gl_code_combinations.segment4%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_segment4_name_ttype             IS TABLE OF fnd_flex_values_tl.description%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_decision_num_ttype              IS TABLE OF gl_je_lines.attribute9%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_amount_ttype                    IS TABLE OF gl_je_lines.entered_dr%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_gl_date_ttype                   IS TABLE OF gl_je_lines.effective_date%type
                                                        INDEX BY PLS_INTEGER;
  gt_gl_je_header_id               g_gl_je_header_id_ttype;                   -- 仕訳_仕訳ヘッダID
  gt_gl_je_line_num                g_gl_je_line_num_ttype;                    -- 仕訳_仕訳明細番号
  gt_gl_period_year                g_gl_period_year_ttype;                    -- 仕訳_年度
  gt_gl_segment2                   g_gl_segment2_ttype;                       -- 仕訳_セグメント2(部門・拠点コード)
  gt_gl_segment2_name              g_gl_segment2_name_ttype;                  -- 仕訳_セグメント2(部門・拠点名)
  gt_gl_segment6                   g_gl_segment6_ttype;                       -- 仕訳_セグメント6(企業コード)
  gt_gl_segment6_name              g_gl_segment6_name_ttype;                  -- 仕訳_セグメント6(企業名)
  gt_gl_segment3                   g_gl_segment3_ttype;                       -- 仕訳_セグメント3(勘定科目コード)
  gt_gl_segment3_name              g_gl_segment3_name_ttype;                  -- 仕訳_セグメント3(勘定科目)
  gt_gl_segment4                   g_gl_segment4_ttype;                       -- 仕訳_セグメント4(補助科目コード)
  gt_gl_segment4_name              g_gl_segment4_name_ttype;                  -- 仕訳_セグメント4(補助科目)
  gt_gl_decision_num               g_gl_decision_num_ttype;                   -- 仕訳_稟議決済番号
  gt_gl_amount                     g_gl_amount_ttype;                         -- 仕訳_支払金額
  gt_gl_gl_date                    g_gl_gl_date_ttype;                        -- 仕訳_計上年月日
--
  -- 連携対象データ配列
  TYPE g_period_year_ttype                  IS TABLE OF xxcfo_rfd_wf_coop_data.period_year%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment2_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment2%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment2_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment2_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment6_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment6%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment6_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment6_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment3_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment3%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment3_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment3_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment4_ttype                     IS TABLE OF xxcfo_rfd_wf_coop_data.segment4%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_segment4_name_ttype                IS TABLE OF xxcfo_rfd_wf_coop_data.segment4_name%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_decision_num_ttype                 IS TABLE OF xxcfo_rfd_wf_coop_data.decision_num%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_amount_ttype                       IS TABLE OF xxcfo_rfd_wf_coop_data.amount%type
                                                        INDEX BY PLS_INTEGER;
  TYPE g_gl_date_ttype                      IS TABLE OF xxcfo_rfd_wf_coop_data.gl_date%type
                                                        INDEX BY PLS_INTEGER;
  gt_period_year                   g_period_year_ttype;                       -- 年度
  gt_segment2                      g_segment2_ttype;                          -- セグメント2(部門・拠点コード)
  gt_segment2_name                 g_segment2_name_ttype;                     -- セグメント2(部門・拠点名)
  gt_segment6                      g_segment6_ttype;                          -- セグメント6(企業コード)
  gt_segment6_name                 g_segment6_name_ttype;                     -- セグメント6(企業名)
  gt_segment3                      g_segment3_ttype;                          -- セグメント3(勘定科目コード)
  gt_segment3_name                 g_segment3_name_ttype;                     -- セグメント3(勘定科目)
  gt_segment4                      g_segment4_ttype;                          -- セグメント4(補助科目コード)
  gt_segment4_name                 g_segment4_name_ttype;                     -- セグメント4(補助科目)
  gt_decision_num                  g_decision_num_ttype;                      -- 稟議決済番号
  gt_amount                        g_amount_ttype;                            -- 支払金額
  gt_gl_date                       g_gl_date_ttype;                           -- 計上年月日
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gt_data_filepath        all_directories.directory_name%TYPE DEFAULT NULL;   -- XXCFO:稟議WF連携データファイル格納パス
  gt_coop_date            xxcfo_rfd_wf_control.coop_date%TYPE;                -- 連携日
  gr_rwc_rowid            ROWID;                                              -- 稟議WF連携管理テーブルのROWID
  gv_control_flag         VARCHAR2(1) DEFAULT 'Y';                            -- 管理テーブル存在フラグ
  gv_recovery_flag        VARCHAR2(1) DEFAULT 'N';                            -- リカバリフラグ
  gv_data_filename        VARCHAR2(100);                                      -- XXCFO:稟議WF連携データファイル名
  gd_coop_date_del        DATE;                                               -- 連携データ削除用
  gd_coop_date_max        DATE;                                               -- 最終連携日
  gd_coop_date_from       DATE;                                               -- 連携日付From日付型
  gd_coop_date_to         DATE;                                               -- 連携日付To日付型
  gd_process_date         DATE;                                               -- 業務日付
  gn_set_of_bks_id        NUMBER;                                             -- GL会計帳簿ID
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_coop_date_from  IN  VARCHAR2,     --   1.連携日From
    iv_coop_date_to    IN  VARCHAR2,     --   2.連携日To
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_slash         CONSTANT VARCHAR2(1)   := '/';                    -- スラッシュ
--
    -- *** ローカル変数 ***
    lt_dir_path      all_directories.directory_path%TYPE DEFAULT NULL; --ディレクトリパス
    lv_full_name     VARCHAR2(200) DEFAULT NULL;                       --ディレクトリ名＋ファイル名連結値
    ld_coop_date_to  DATE;                                             -- コンカレントパラメータToチェック用
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
    --==============================================================
    -- コンカレントパラメータ出力
    --==============================================================
--
    -- ログ出力
    xxcfr_common_pkg.put_log_param(
       iv_which        => cv_file_type_log  -- ログ出力
      ,iv_conc_param1  => iv_coop_date_from -- コンカレントパラメータ1
      ,iv_conc_param2  => iv_coop_date_to   -- コンカレントパラメータ2
      ,ov_errbuf       => lv_errbuf         -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode        -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode <> cv_status_normal) THEN
      RAISE global_api_expt;
    END IF;
--
    --==============================================================
    -- プロファイル取得
    --==============================================================
--
    -- GL会計帳簿ID
    gn_set_of_bks_id := TO_NUMBER(FND_PROFILE.VALUE( cv_set_of_bks_id ));
    -- 取得エラー時
    IF ( gn_set_of_bks_id IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00001   -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_set_of_bks_id ))
                                                                        -- GL会計帳簿ID
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: 稟議WF連携支払データファイル格納パス
    gt_data_filepath := FND_PROFILE.VALUE( cv_data_filepath );
    -- 取得エラー時
    IF ( gt_data_filepath IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00001   -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filepath ))
                                                                        -- XXCFO:稟議WF連携支払データファイル格納パス
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- XXCFO: 稟議WF連携支払データファイル名
    gv_data_filename := FND_PROFILE.VALUE( cv_data_filename );
    -- 取得エラー時
    IF ( gv_data_filename IS NULL ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00001   -- プロファイル取得エラー
                                                    ,cv_tkn_prof        -- トークン'PROF_NAME'
                                                    ,xxcfr_common_pkg.get_user_profile_name( cv_data_filename ))
                                                                        -- XXCFO:稟議WF連携支払データファイル名
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 業務日付取得
    --==================================
--
    -- 共通関数から業務日付を取得
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- 取得エラー時
    IF  ( gd_process_date IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- アプリケーション短縮名
                                            ,cv_msg_cfo_00015);    -- メッセージ：APP-XXCFO1-00015
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    --==================================
    -- 最終連携日を取得
    --==================================
    BEGIN
      SELECT rwc.ROWID      row_id
            ,rwc.coop_date  coop_date
      INTO   gr_rwc_rowid
            ,gt_coop_date
      FROM   xxcfo_rfd_wf_control  rwc   -- 稟議WF連携管理テーブル
      FOR UPDATE NOWAIT
      ;
    -- 最終連携日の設定
    gd_coop_date_max := gt_coop_date;
--
    EXCEPTION
      -- ロックエラー
      WHEN lock_expt THEN
        ov_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_00019      -- データロックエラーメッセージ
                                                      ,cv_tkn_table          -- トークン'TABLE'
                                                      ,cv_msgtkn_cfo_50002   -- 稟議WF連携管理テーブル
                                                      )
                             ,1
                             ,5000);
        ov_errbuf := ov_errmsg;
        ov_retcode := cv_status_error;
      WHEN NO_DATA_FOUND THEN
        -- 最終連携日に業務日付-1を設定
        gd_coop_date_max := gd_process_date - 1;
        -- 管理テーブル存在フラグを設定
        gv_control_flag := cv_enabled_flag_n;
    END;
--
    -- コンカレントパラメータFromの入力がない場合
    IF ( iv_coop_date_from IS NULL ) THEN
      -- 連携日付Fromに最終連携日を設定
      gd_coop_date_from := gd_coop_date_max;
    -- コンカレントパラメータFromの入力がある場合
    ELSE
      -- 連携日付Fromにコンカレントパラメータを設定
      gd_coop_date_from := TO_DATE(iv_coop_date_from ,cv_format_hh24_mi_ss);
      -- 連携日付Fromが最終更新日より後の場合
      IF ( gd_coop_date_from > NVL(gt_coop_date, gd_coop_date_from) ) THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                                  -- 'XXCFO'
                                                      ,cv_msg_cfo_00058                                -- 対象期間エラー
                                                      ,cv_tkn_date_from                                -- 'DATE_FROM'
                                                      ,TO_CHAR(gd_coop_date_max, cv_format_hh24_mi_ss) -- 最終連携日
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- コンカレントパラメータToの入力がない場合
    IF ( iv_coop_date_to IS NULL ) THEN
      -- 連携日付ToにSYSDATEを設定
      gd_coop_date_to   := SYSDATE;
    -- コンカレントパラメータToの入力がある場合
    ELSE
      -- コンカレントパラメータToチェック
      ld_coop_date_to := TO_DATE(iv_coop_date_to ,cv_format_hh24_mi_ss);
      -- コンカレントパラメータToが実施日以降の場合
      IF (ld_coop_date_to >= TRUNC(SYSDATE)) THEN
        gd_coop_date_to := SYSDATE;
      ELSE
        -- 連携日付ToにコンカレントパラメータTo + 1を設定
        gd_coop_date_to   := TO_DATE(iv_coop_date_to ,cv_format_hh24_mi_ss) + 1;
      END IF;
--
      -- コンカレントパラメータToが最終更新日付より前の場合
      IF ( ld_coop_date_to < TRUNC(NVL(gt_coop_date, ld_coop_date_to)) ) THEN
        -- リカバリフラグを設定
        gv_recovery_flag := cv_enabled_flag_y;
      END IF;
    END IF;
--
    -- 削除対象の連携日を設定
    gd_coop_date_del  := ADD_MONTHS(gd_process_date ,-12);
--
    --==================================
    -- ディレクトリパス取得
    --==================================
    BEGIN
      SELECT    ad.directory_path
      INTO      lt_dir_path
      FROM      all_directories ad
      WHERE     ad.directory_name = gt_data_filepath;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_coi   -- 'XXCOI'
                                                      ,cv_msg_coi_00029 -- ディレクトリパス取得エラー
                                                      ,cv_tkn_dir_tok   -- 'DIR_TOK'
                                                      ,gt_data_filepath -- ファイル格納パス
                                                     )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --==================================
    -- IFファイル名出力
    --==================================
--
    -- ディレクトリパス + '/' + ファイル名
    lv_full_name :=  lt_dir_path || cv_slash || gv_data_filename;
--
    -- 稟議WF連携データファイル名を設定
    lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                  ,cv_msg_cfo_00002
                                                  ,cv_tkn_file       -- トークン'FILE_NAME'
                                                  ,lv_full_name)     -- 稟議WF連携データファイル名
                                                 ,1
                                                 ,5000);
--
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg --ユーザー・エラーメッセージ
    );
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : del_coop_data
   * Description      : 稟議WF連携データテーブル削除処理(A-2)
   ***********************************************************************************/
  PROCEDURE del_coop_data(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'del_coop_data'; -- プログラム名
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
    CURSOR rfd_wf_coop_data_cur
    IS
      SELECT rwc.ROWID
      FROM   xxcfo_rfd_wf_coop_data rwc  -- 稟議WF連携データテーブル
      WHERE  rwc.coop_date <= gd_coop_date_del
      FOR UPDATE NOWAIT
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
    -- 稟議WF連携データテーブルのロックを取得
    OPEN rfd_wf_coop_data_cur;
    CLOSE rfd_wf_coop_data_cur;
--
    BEGIN
      -- 稟議WF連携データテーブル削除
      DELETE xxcfo_rfd_wf_coop_data rwc
      WHERE  rwc.coop_date <= gd_coop_date_del
      ;
--
    EXCEPTION
      -- エラー処理（データ削除エラー）
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo_00025      -- データ削除エラーメッセージ
                                                      ,cv_tkn_table          -- トークン'TABLE'
                                                      ,cv_msgtkn_cfo_50001   -- 稟議WF連携データテーブル
                                                      )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
  EXCEPTION
    -- ロックエラー
    WHEN lock_expt THEN
      ov_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                    ,cv_msg_cfo_00019      -- データロックエラーメッセージ
                                                    ,cv_tkn_table          -- トークン'TABLE'
                                                    ,cv_msgtkn_cfo_50001   -- 稟議WF連携データテーブル
                                                    )
                           ,1
                           ,5000);
      ov_errbuf := ov_errmsg;
      ov_retcode := cv_status_error;
--
      IF ( rfd_wf_coop_data_cur%ISOPEN ) THEN
        CLOSE rfd_wf_coop_data_cur;
      END IF;
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
  END del_coop_data;
--
  /**********************************************************************************
   * Procedure Name   : get_target_data
   * Description      : 連携対象データの抽出処理(A-3)
   ***********************************************************************************/
  PROCEDURE get_target_data(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_target_data'; -- プログラム名
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
    cv_actual_flag_a              CONSTANT VARCHAR2(30)  := 'A';                 -- 残高タイプ
    -- ソース
    cv_receivables                CONSTANT VARCHAR2(30)  := 'Receivables';       -- 売掛管理
    cv_payables                   CONSTANT VARCHAR2(30)  := 'Payables';          -- 買掛管理
    cv_je_source_1                CONSTANT VARCHAR2(30)  := '1';                 -- GL部門入力
    -- カテゴリ
    cv_credit_memos               CONSTANT VARCHAR2(30)  := 'Credit Memos';      -- クレジットメモ（売掛）
    cv_sales_invoices             CONSTANT VARCHAR2(30)  := 'Sales Invoices';    -- 売上請求書（売掛）
    cv_purchase_invoices          CONSTANT VARCHAR2(30)  := 'Purchase Invoices'; -- 仕入請求書（買掛）
    cv_je_category_1              CONSTANT VARCHAR2(30)  := '1';                 -- 振替伝票（GL部門入力）
--
    -- *** ローカル変数 ***
--
    -- *** ローカル・カーソル ***
    -- 連携対象データ抽出
    CURSOR get_target_data_cur
    IS
      -- 差分データの取得
      SELECT /*+
                LEADING(gjh ,gjl ,gcc)
                USE_NL (gcc ,rwcm)
                INDEX  (gcc GL_CODE_COMBINATIONS_U1)
                INDEX  (rwcm XXCFO_RFD_WF_COOP_MST_N01)
              */
             gjl.je_header_id                                             je_header_id    -- 仕訳ヘッダID
            ,gjl.je_line_num                                              je_line_num     -- 仕訳明細番号
            ,(
              SELECT gp.period_year
              FROM   gl_sets_of_books  glb  -- 会計帳簿マスタ
                    ,gl_periods        gp   -- 会計カレンダ
              WHERE  glb.set_of_books_id       =  gn_set_of_bks_id
              AND    gp.period_set_name        =  glb.period_set_name
              AND    gp.adjustment_period_flag =  cv_enabled_flag_n
              AND    gp.start_date             <= gjl.effective_date
              AND    gp.end_date               >= gjl.effective_date
             )                                                            period_year     -- 年度
            , gcc.segment2                                                segment2        -- 部門・拠点コード
            ,(SELECT REPLACE(xdv.description, '"', '""')  segment2_name
              FROM   xx03_departments_v xdv           -- 部門マスタ
              WHERE  gcc.segment2 = xdv.flex_value
              AND    ROWNUM = 1)                                          segment2_name   -- 部門・拠点名
            ,gcc.segment6                                                 segment6        -- 企業コード
            ,(SELECT REPLACE(xbtv.description, '"', '""') segment6_name
              FROM   xx03_business_types_v xbtv       -- 事業区分マスタ
              WHERE  gcc.segment6 = xbtv.flex_value
              AND    ROWNUM = 1)                                          segment6_name   -- 企業名
            ,gcc.segment3                                                 segment3        -- 勘定科目コード
            ,(SELECT REPLACE(xav.description, '"', '""')  segment3_name
              FROM   xx03_accounts_v xav              -- 勘定科目マスタ
              WHERE  gcc.segment3 = xav.flex_value
              AND    ROWNUM = 1)                                          segment3_name   -- 勘定科目
            ,gcc.segment4                                                 segment4        -- 補助科目コード
            ,(SELECT REPLACE(xsav.description, '"', '""')  segment4_name
              FROM   xx03_sub_accounts_v xsav         -- 補助科目マスタ
              WHERE  gcc.segment4 = xsav.flex_value 
              AND    gcc.segment3 = xsav.parent_flex_value_low
              AND    ROWNUM = 1)                                          segment4_name   -- 補助科目
            ,gjl.attribute9                                               decision_num    -- 稟議決済番号
            ,NVL(gjl.entered_dr,0) - NVL(gjl.entered_cr,0)                amount          -- 支払金額
            ,gjl.effective_date                                           gl_date         -- 計上年月日
      FROM   gl_je_headers          gjh   -- GL仕訳ヘッダ
            ,gl_je_lines            gjl   -- GL仕訳明細
            ,gl_code_combinations   gcc   -- 勘定科目組合せマスタ
            ,xxcfo_rfd_wf_coop_mst  rwcm  -- 稟議WF連携組合せマスタ
      WHERE  gjh.creation_date       >= gd_coop_date_from
      AND    gjh.creation_date       <  gd_coop_date_to
      AND    gjh.set_of_books_id     =  gn_set_of_bks_id
      AND    gjh.actual_flag         =  cv_actual_flag_a
      AND    gjh.je_source           IN (
                                          cv_receivables       -- 売掛管理
                                         ,cv_payables          -- 買掛管理
                                         ,cv_je_source_1       -- GL部門入力
                                        )
      AND    gjh.je_category         IN (
                                          cv_credit_memos      -- クレジットメモ（売掛）
                                         ,cv_sales_invoices    -- 売上請求書（売掛）
                                         ,cv_purchase_invoices -- 仕入請求書（買掛）
                                         ,cv_je_category_1     -- 振替伝票（GL部門入力）
                                        )
      AND    gjh.je_header_id        =  gjl.je_header_id
      AND    gjl.code_combination_id =  gcc.code_combination_id
      AND    gcc.segment3            =  rwcm.segment3                    -- 勘定科目コード
      AND    gcc.segment4            =  rwcm.segment4                    -- 補助科目コード
      AND    gcc.segment6            =  NVL(rwcm.segment6 ,gcc.segment6) -- 企業コード
      AND    gd_coop_date_from       >= NVL(rwcm.start_date_active ,gd_coop_date_from)
      AND    gd_coop_date_to         <= NVL(rwcm.end_date_active ,gd_coop_date_to)
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
    -- カーソルオープン
    OPEN get_target_data_cur;
--
    -- データの一括取得
    FETCH get_target_data_cur BULK COLLECT INTO
          gt_gl_je_header_id,
          gt_gl_je_line_num,
          gt_gl_period_year,
          gt_gl_segment2,
          gt_gl_segment2_name,
          gt_gl_segment6,
          gt_gl_segment6_name,
          gt_gl_segment3,
          gt_gl_segment3_name,
          gt_gl_segment4,
          gt_gl_segment4_name,
          gt_gl_decision_num,
          gt_gl_amount,
          gt_gl_gl_date;
--
    -- 対象件数のセット
    gn_target_cnt := gt_gl_je_header_id.COUNT;
--
    -- 対象件数0件の場合、警告
    IF ( gn_target_cnt = 0 ) THEN
      -- 対象データが0件メッセージ
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo     -- 'XXCFO'
                                                    ,cv_msg_cfo_00004)
                                                   ,1
                                                   ,5000);
--
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
--
    END IF;
    -- カーソルクローズ
    CLOSE get_target_data_cur;
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
  END get_target_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_coop_data
   * Description      : 稟議WF連携データ登録処理(A-4)
   ***********************************************************************************/
  PROCEDURE ins_coop_data(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_coop_data'; -- プログラム名
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
    BEGIN
--
      FORALL i IN 1..gt_gl_je_header_id.COUNT
        -- 稟議WF連携データテーブル一括登録
        INSERT INTO xxcfo_rfd_wf_coop_data          -- 稟議WF連携データテーブル
          (
            je_header_id                        -- 1.仕訳ヘッダID
           ,je_line_num                         -- 2.仕訳明細番号
           ,period_year                         -- 3.年度
           ,segment2                            -- 4.部門・拠点コード
           ,segment2_name                       -- 5.部門・拠点名
           ,segment6                            -- 6.企業コード
           ,segment6_name                       -- 7.企業名
           ,segment3                            -- 8.勘定科目コード
           ,segment3_name                       -- 9.勘定科目
           ,segment4                            -- 10補助科目コード
           ,segment4_name                       -- 11補助科目
           ,decision_num                        -- 12.稟議決裁番号
           ,amount                              -- 13.支払金額
           ,gl_date                             -- 14.計上年月日
           ,coop_date                           -- 15.連携日
           ,created_by                          -- 16.作成者
           ,creation_date                       -- 17.作成日
           ,last_updated_by                     -- 18.最終更新者
           ,last_update_date                    -- 19.最終更新日
           ,last_update_login                   -- 20.最終更新ログイン
           ,request_id                          -- 21.要求ID
           ,program_application_id              -- 22.コンカレント・プログラム・アプリケーションID
           ,program_id                          -- 23.コンカレント・プログラムID
           ,program_update_date                 -- 24.プログラム更新日
          )VALUES(
            gt_gl_je_header_id(i)              -- 1.仕訳ヘッダID
           ,gt_gl_je_line_num(i)               -- 2.仕訳明細番号
           ,gt_gl_period_year(i)               -- 3.年度
           ,gt_gl_segment2(i)                  -- 4.部門・拠点コード
           ,gt_gl_segment2_name(i)             -- 5.部門・拠点名
           ,gt_gl_segment6(i)                  -- 6.企業コード
           ,gt_gl_segment6_name(i)             -- 7.企業名
           ,gt_gl_segment3(i)                  -- 8.勘定科目コード
           ,gt_gl_segment3_name(i)             -- 9.勘定科目
           ,gt_gl_segment4(i)                  -- 10補助科目コード
           ,gt_gl_segment4_name(i)             -- 11補助科目
           ,gt_gl_decision_num(i)              -- 12.稟議決裁番号
           ,gt_gl_amount(i)                    -- 13.支払金額
           ,gt_gl_gl_date(i)                   -- 14.計上年月日
           ,gd_coop_date_to                    -- 15.連携日
           ,cn_created_by                      -- 16.作成者
           ,cd_creation_date                   -- 17.作成日
           ,cn_last_updated_by                 -- 18.最終更新者
           ,cd_last_update_date                -- 19.最終更新日
           ,cn_last_update_login               -- 20.最終更新ログイン
           ,cn_request_id                      -- 21.要求ID
           ,cn_program_application_id          -- 22.コンカレント・プログラム・アプリケーションID
           ,cn_program_id                      -- 23.コンカレント・プログラムID
           ,cd_program_update_date             -- 24.プログラム更新日
          );
    EXCEPTION
      WHEN OTHERS THEN
       lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                      ,cv_msg_cfo_00024           -- データ登録エラー
                                                      ,cv_tkn_table               -- トークン'TABLE'
                                                      ,cv_msgtkn_cfo_50001        -- 稟議WF連携データテーブル
                                                      ,cv_tkn_errmsg              -- トークン'ERRMSG'
                                                      ,SQLERRM                    -- SQLエラーメッセージ
                                                     )
                            ,1
                            ,5000);
       lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
       RAISE global_api_expt;
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
  END ins_coop_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_control
   * Description      : 稟議WF連携管理テーブル登録・更新処理(A-5)
   ***********************************************************************************/
  PROCEDURE ins_control(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_control'; -- プログラム名
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
    -- 管理テーブルが存在しない場合
    IF ( gv_control_flag = cv_enabled_flag_n ) THEN
      BEGIN
        -- 稟議WF連携管理テーブル登録
        INSERT INTO xxcfo_rfd_wf_control   -- 稟議WF連携管理テーブル
          (
            coop_date                  -- 1.連携日
           ,created_by                 -- 2.作成者
           ,creation_date              -- 3.作成日
           ,last_updated_by            -- 4.最終更新者
           ,last_update_date           -- 5.最終更新日
           ,last_update_login          -- 6.最終更新ログイン
           ,request_id                 -- 7.要求ID
           ,program_application_id     -- 8.コンカレント・プログラム・アプリケーションID
           ,program_id                 -- 9.コンカレント・プログラムID
           ,program_update_date        -- 10.プログラム更新日
          )VALUES(
            gd_coop_date_to            -- 1.連携日
           ,cn_created_by              -- 2.作成者
           ,cd_creation_date           -- 3.作成日
           ,cn_last_updated_by         -- 4.最終更新者
           ,cd_last_update_date        -- 5.最終更新日
           ,cn_last_update_login       -- 6.最終更新ログイン
           ,cn_request_id              -- 7.要求ID
           ,cn_program_application_id  -- 8.コンカレント・プログラム・アプリケーションID
           ,cn_program_id              -- 9.コンカレント・プログラムID
           ,cd_program_update_date     -- 10.プログラム更新日
          );
      EXCEPTION
        WHEN OTHERS THEN
         lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo             -- XXCFO
                                                        ,cv_msg_cfo_00024           -- データ登録エラー
                                                        ,cv_tkn_table               -- トークン'TABLE'
                                                        ,cv_msgtkn_cfo_50002        -- 稟議WF連携管理テーブル
                                                        ,cv_tkn_errmsg              -- トークン'ERRMSG'
                                                        ,SQLERRM                    -- SQLエラーメッセージ
                                                       )
                              ,1
                              ,5000);
         lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
         RAISE global_api_expt;
      END;
    -- 管理テーブルが存在する場合
    ELSE
      BEGIN
        UPDATE xxcfo_rfd_wf_control rwc
        SET rwc.coop_date              = gd_coop_date_to           -- 連携日
           ,rwc.last_updated_by        = cn_last_updated_by        -- 最終更新者
           ,rwc.last_update_date       = cd_last_update_date       -- 最終更新日
           ,rwc.last_update_login      = cn_last_update_login      -- 最終更新ログイン
           ,rwc.request_id             = cn_request_id             -- 要求ID
           ,rwc.program_application_id = cn_program_application_id -- プログラムアプリケーションID
           ,rwc.program_id             = cn_program_id             -- プログラムID
           ,rwc.program_update_date    = cd_program_update_date    -- プログラム更新日
        WHERE rwc.ROWID = gr_rwc_rowid
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB( xxccp_common_pkg.get_msg( cv_msg_kbn_cfo           -- XXCFO
                                                         ,cv_msg_cfo_00020         -- データ登録エラー
                                                         ,cv_tkn_table             -- トークン'TABLE'
                                                         ,cv_msgtkn_cfo_50002      -- 稟議WF連携管理テーブル
                                                         ,cv_tkn_errmsg            -- トークン'ERRMSG'
                                                         ,SQLERRM                  -- SQLエラーメッセージ
                                                        )
                               ,1
                               ,5000);
          lv_errbuf  := lv_errmsg ||cv_msg_part|| SQLERRM;
          RAISE global_api_expt;
      END;
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
  END ins_control;
--
  /**********************************************************************************
   * Procedure Name   : get_coop_data
   * Description      : 稟議WF連携データテーブル抽出処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_coop_data(
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_coop_data'; -- プログラム名
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
    -- 連携対象データ抽出
    CURSOR get_coop_data_cur
    IS
      SELECT rwcd.period_year               period_year                -- 年度
            ,rwcd.segment2                  segment2                   -- 部門・拠点コード
            ,rwcd.segment2_name             segment2_name              -- 部門・拠点名
            ,rwcd.segment6                  segment6                   -- 企業コード
            ,rwcd.segment6_name             segment6_name              -- 企業名
            ,rwcd.segment3                  segment3                   -- 勘定科目コード
            ,rwcd.segment3_name             segment3_name              -- 勘定科目
            ,rwcd.segment4                  segment4                   -- 補助科目コード
            ,rwcd.segment4_name             segment4_name              -- 補助科目
            ,rwcd.decision_num              decision_num               -- 稟議決裁番号
            ,rwcd.amount                    amount                     -- 支払金額
            ,rwcd.gl_date                   gl_date                    -- 計上年月日
      FROM   xxcfo_rfd_wf_coop_data  rwcd   -- 稟議WF連携データテーブル
      WHERE  rwcd.request_id = cn_request_id
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
    -- カーソルオープン
    OPEN get_coop_data_cur;
--
    -- データの一括取得
    FETCH get_coop_data_cur BULK COLLECT INTO
          gt_period_year,
          gt_segment2,
          gt_segment2_name,
          gt_segment6,
          gt_segment6_name,
          gt_segment3,
          gt_segment3_name,
          gt_segment4,
          gt_segment4_name,
          gt_decision_num,
          gt_amount,
          gt_gl_date;
--
    -- カーソルクローズ
    CLOSE get_coop_data_cur;
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
  END get_coop_data;
--
  /**********************************************************************************
   * Procedure Name   : put_data_file
   * Description      : 稟議WF連携データファイル出力処理(A-7)
   ***********************************************************************************/
  PROCEDURE put_data_file(
    ov_errbuf           OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode          OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg           OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'put_data_file'; -- プログラム名
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
    cn_max_linesize     CONSTANT NUMBER       := 32767;                     -- ファイルの1行当たりの最大文字数
    cv_open_mode_w      CONSTANT VARCHAR2(1)  := 'w';                       -- ファイルオープンモード（上書き）
    cv_delimiter        CONSTANT VARCHAR2(1)  := ',';                       -- CSV区切り文字
    cv_enclosed         CONSTANT VARCHAR2(1)  := '"';                       -- 単語囲み文字
    cv_csv_output_head  CONSTANT VARCHAR2(22) := 'XXCFO1_CSV_OUTPUT_HEAD';  -- 稟議WF連携支払CSV出力用ヘッダ
--
    -- *** ローカル変数 ***
    ln_normal_cnt   NUMBER;         -- 正常件数
    ln_loop_cnt     NUMBER;         -- ループカウンタ
--
    -- ファイル出力関連
    lf_file_hand        UTL_FILE.FILE_TYPE ;    -- ファイル・ハンドルの宣言
    lv_csv_text_all     VARCHAR2(32767) ;       -- 出力１行分文字数判定用
    lv_csv_text         VARCHAR2(32767) ;       -- 出力１行分文字列変数
    lb_fexists          BOOLEAN;                -- ファイルが存在するかどうか
    ln_file_size        NUMBER;                 -- ファイルの長さ
    ln_block_size       NUMBER;                 -- ファイルシステムのブロックサイズ
--
    -- *** ローカル・カーソル ***
    CURSOR get_csv_output_head_cur
    IS
      SELECT flv.description
      FROM   fnd_lookup_values  flv
      WHERE  flv.lookup_type   =  cv_csv_output_head
      AND    flv.language      =  cv_user_lang
      AND    gd_coop_date_from >= NVL(flv.start_date_active, gd_coop_date_from)
      AND    gd_coop_date_to   <= NVL(flv.end_date_active, gd_coop_date_to)
      AND    flv.enabled_flag  =  cv_enabled_flag_y
      ORDER BY flv.lookup_code
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
    -- ローカル変数の初期化
    ln_normal_cnt := 0;
--
    -- ====================================================
    -- ＵＴＬファイル存在チェック
    -- ====================================================
    UTL_FILE.FGETATTR( gt_data_filepath,
                       gv_data_filename,
                       lb_fexists,
                       ln_file_size,
                       ln_block_size );
--
    -- 前回ファイルが存在している
    IF ( lb_fexists ) THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00027  -- ファイルが存在している
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルオープン
    -- ====================================================
    lf_file_hand := UTL_FILE.FOPEN
                      (
                        gt_data_filepath
                       ,gv_data_filename
                       ,cv_open_mode_w
                       ,cn_max_linesize
                      ) ;
--
    -- 対象件数が存在する場合
    IF ( gn_target_cnt > 0 ) THEN
      -- ====================================================
      -- ヘッダ項目抽出
      -- ====================================================
      FOR csv_output_head_rec  IN  get_csv_output_head_cur
        LOOP
          IF  ( get_csv_output_head_cur%ROWCOUNT = 1 ) THEN
            lv_csv_text :=  csv_output_head_rec.description;
          ELSE
            lv_csv_text :=  lv_csv_text || cv_delimiter || cv_enclosed || csv_output_head_rec.description || cv_enclosed;
          END IF;
      END LOOP;
--
      -- 改行コード付加
      lv_csv_text :=  lv_csv_text || CHR(13) || CHR(10);
--
      -- 最大文字数判定用
      lv_csv_text_all := lv_csv_text;
--
      -- ====================================================
      -- ヘッダ項目ファイル書き込み
      -- ====================================================
      UTL_FILE.PUT( lf_file_hand, lv_csv_text ) ;
--
      -- ====================================================
      -- 出力データ抽出
      -- ====================================================
      <<out_loop>>
      FOR ln_loop_cnt IN gt_period_year.FIRST..gt_period_year.LAST LOOP
--
        -- 出力文字列作成
        lv_csv_text := cv_enclosed || gt_period_year(ln_loop_cnt)                               || cv_enclosed || cv_delimiter       -- 年度
                    || cv_enclosed || gt_segment2(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- 部門・拠点コード
                    || cv_enclosed || gt_segment2_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- 部門・拠点名
                    || cv_enclosed || gt_segment6(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- 企業コード
                    || cv_enclosed || gt_segment6_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- 企業名
                    || cv_enclosed || gt_segment3(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- 勘定科目コード
                    || cv_enclosed || gt_segment3_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- 勘定科目
                    || cv_enclosed || gt_segment4(ln_loop_cnt)                                  || cv_enclosed || cv_delimiter       -- 補助科目コード
                    || cv_enclosed || gt_segment4_name(ln_loop_cnt)                             || cv_enclosed || cv_delimiter       -- 補助科目
                    || cv_enclosed || gt_decision_num(ln_loop_cnt)                              || cv_enclosed || cv_delimiter       -- 稟議決裁番号
                    || cv_enclosed || TO_CHAR(gt_amount(ln_loop_cnt))                           || cv_enclosed || cv_delimiter       -- 支払金額
                    || cv_enclosed || TO_CHAR(gt_gl_date(ln_loop_cnt), cv_format_yyyy_mm_dd)    || cv_enclosed || cv_delimiter       -- 計上年月日
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目1
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目2
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目3
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目4
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目5
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目6
                    || cv_enclosed || ''                                                        || cv_enclosed || cv_delimiter       -- 予備項目7
                    || cv_enclosed || ''                                                        || cv_enclosed || CHR(13) || CHR(10) -- 予備項目8
        ;
--
        -- ====================================================
        -- ファイル書き込み
        -- ====================================================
        UTL_FILE.PUT( lf_file_hand, lv_csv_text ) ;
--
        -- ====================================================
        -- 処理件数カウントアップ
        -- ====================================================
        ln_normal_cnt := ln_normal_cnt + 1 ;
--
        -- 最大文字数判定用
        lv_csv_text_all := lv_csv_text_all || lv_csv_text;
--
        -- 30000byteを超えたら書き込む
        IF ( LENGTHB(lv_csv_text_all) > 30000 ) THEN
          UTL_FILE.FFLUSH( lf_file_hand );
          lv_csv_text_all := NULL;
        END IF;
--
      END LOOP out_loop;
--
    END IF;
--
    -- ====================================================
    -- ＵＴＬファイルクローズ
    -- ====================================================
    UTL_FILE.FCLOSE( lf_file_hand ) ;
--
    gn_normal_cnt := ln_normal_cnt;
--
  EXCEPTION
--
    -- *** ファイルの場所が無効です ***
    WHEN UTL_FILE.INVALID_PATH THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00028  -- ファイルの場所が無効
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 要求どおりにファイルをオープンできないか、または操作できません ***
    WHEN UTL_FILE.INVALID_OPERATION THEN
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00029  -- ファイルをオープンできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 書込み操作中にオペレーティング・システムのエラーが発生しました ***
    WHEN UTL_FILE.WRITE_ERROR THEN
      --↓ファイルクローズ関数を追加
      IF ( UTL_FILE.IS_OPEN ( lf_file_hand )) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      gn_normal_cnt := ln_normal_cnt;
      lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo    -- 'XXCFO'
                                                    ,cv_msg_cfo_00030  -- ファイルに書込みできない
                                                   )
                                                   ,1
                                                   ,5000);
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --↓ファイルクローズ関数を追加
      IF UTL_FILE.IS_OPEN ( lf_file_hand ) THEN
        UTL_FILE.FCLOSE( lf_file_hand );
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END put_data_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_coop_date_from  IN  VARCHAR2,     --   1.連携日From
    iv_coop_date_to    IN  VARCHAR2,     --   2.連携日To
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- グローバル変数の初期化
    gn_target_cnt       := 0;
    gn_normal_cnt       := 0;
    gn_error_cnt        := 0;
    gn_warn_cnt         := 0;
--
    -- PL/SQL表の初期化
    gt_gl_je_header_id.DELETE;              -- 仕訳_仕訳ヘッダID
    gt_gl_je_line_num.DELETE;               -- 仕訳_仕訳明細番号
    gt_gl_period_year.DELETE;               -- 仕訳_年度
    gt_gl_segment2.DELETE;                  -- 仕訳_セグメント2(部門・拠点コード)
    gt_gl_segment2_name.DELETE;             -- 仕訳_セグメント2(部門・拠点名)
    gt_gl_segment6.DELETE;                  -- 仕訳_セグメント6(企業コード)
    gt_gl_segment6_name.DELETE;             -- 仕訳_セグメント6(企業名)
    gt_gl_segment3.DELETE;                  -- 仕訳_セグメント3(勘定科目コード)
    gt_gl_segment3_name.DELETE;             -- 仕訳_セグメント3(勘定科目)
    gt_gl_segment4.DELETE;                  -- 仕訳_セグメント4(補助科目コード)
    gt_gl_segment4_name.DELETE;             -- 仕訳_セグメント4(補助科目)
    gt_gl_decision_num.DELETE;              -- 仕訳_稟議決済番号
    gt_gl_amount.DELETE;                    -- 仕訳_支払金額
    gt_gl_gl_date.DELETE;                   -- 仕訳_計上年月日
--
    gt_period_year.DELETE;                  -- 年度
    gt_segment2.DELETE;                     -- セグメント2(部門・拠点コード)
    gt_segment2_name.DELETE;                -- セグメント2(部門・拠点名)
    gt_segment6.DELETE;                     -- セグメント6(企業コード)
    gt_segment6_name.DELETE;                -- セグメント6(企業名)
    gt_segment3.DELETE;                     -- セグメント3(勘定科目コード)
    gt_segment3_name.DELETE;                -- セグメント3(勘定科目)
    gt_segment4.DELETE;                     -- セグメント4(補助科目コード)
    gt_segment4_name.DELETE;                -- セグメント4(補助科目)
    gt_decision_num.DELETE;                 -- 稟議決済番号
    gt_amount.DELETE;                       -- 支払金額
    gt_gl_date.DELETE;                      -- 計上年月日
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
       iv_coop_date_from     -- 1.連携日From
      ,iv_coop_date_to       -- 2.連携日To
      ,lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  稟議WF連携データテーブル削除処理(A-2)
    -- =====================================================
    del_coop_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  連携対象データの抽出処理(A-3)
    -- =====================================================
    get_target_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- 値が取得できた場合
    IF ( gn_target_cnt > 0 ) THEN
      -- =====================================================
      --  稟議WF連携データ登録処理(A-4)
      -- =====================================================
      ins_coop_data(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- リカバリフラグが'Y'ではない場合
    IF ( gv_recovery_flag <> cv_enabled_flag_y ) THEN
      -- =====================================================
      --  稟議WF連携管理テーブル登録・更新処理(A-5)
      -- =====================================================
      ins_control(
         lv_errbuf             -- エラー・メッセージ           --# 固定 #
        ,lv_retcode            -- リターン・コード             --# 固定 #
        ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = cv_status_error) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- =====================================================
    --  稟議WF連携データテーブル抽出処理(A-6)
    -- =====================================================
    get_coop_data(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =====================================================
    --  稟議WF連携データファイル出力処理(A-7)
    -- =====================================================
    put_data_file(
       lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,lv_retcode            -- リターン・コード             --# 固定 #
      ,lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = cv_status_error) THEN
      --(エラー処理)
      RAISE global_process_expt;
    -- 対象件数が0件の場合
    ELSIF ( gn_target_cnt = 0 ) THEN
      -- 警告終了
      ov_retcode := cv_status_warn;
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
    errbuf             OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode            OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_coop_date_from  IN  VARCHAR2,      --   1.連携日From
    iv_coop_date_to    IN  VARCHAR2       --   2.連携日To
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
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
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
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_coop_date_from  -- 1.連携日From
      ,iv_coop_date_to    -- 2.連携日To
      ,lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,lv_retcode         -- リターン・コード             --# 固定 #
      ,lv_errmsg          -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 会計チーム標準：異常終了時の件数設定
    IF (lv_retcode = cv_status_error) THEN
      gn_target_cnt       := 0;
      gn_normal_cnt       := 0;
      gn_error_cnt        := 1;
    END IF;
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
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
END XXCFO010A04C;
/
