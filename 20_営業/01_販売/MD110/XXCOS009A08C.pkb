CREATE OR REPLACE PACKAGE BODY APPS.XXCOS009A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCOS009A08C (body)
 * Description      : 汎用エラーリスト
 * MD.050           : 汎用エラーリスト MD050_COS_009_A08
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_data               対象データ取得(A-2)
 *  edit_output_msg        メッセージ編集出力(A-3)
 *  delete_gen_err_list    汎用エラーリスト削除(A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/09/02    1.0   T.Ishiwata       新規作成
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;                 --CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                            --CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                 --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                            --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;         --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;            --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;         --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                            --PROGRAM_UPDATE_DATE
  cn_per_business_group_id  CONSTANT NUMBER      := fnd_global.per_business_group_id;   --PER_BUSINESS_GROUP_ID
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
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000 );
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  --*** ロックエラー例外ハンドラ ***
  global_data_lock_expt     EXCEPTION;
  --*** ログのみ出力例外 ***
  global_api_expt_log       EXCEPTION;
  --*** 対象データ無しエラー例外ハンドラ ***
  global_no_data_expt       EXCEPTION;
  --
  -- ロックエラー
  PRAGMA EXCEPTION_INIT( global_data_lock_expt, -54 );
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                    CONSTANT  VARCHAR2(100) :=  'XXCOS009A08C';        -- パッケージ名
  cv_xxcos_short_name            CONSTANT  VARCHAR2(100) :=  'XXCOS';               -- 販物領域短縮アプリ名
  cv_xxccp_short_name            CONSTANT  VARCHAR2(100) :=  'XXCCP';               -- 共通領域短縮アプリ名
  --メッセージ
  cv_msg_lock_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00001';    -- ロック取得エラーメッセージ
  cv_msg_no_data                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00003';    -- 対象データなしメッセージ
  cv_msg_prof_err                CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00004';    -- プロファイル取得エラーメッセージ
  cv_msg_delete_err              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00012';    -- データ削除エラーメッセージ
  cv_msg_proc_date_err           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00014';    -- 業務日付取得エラーメッセージ
  cv_msg_parameter               CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15019';    -- パラメータ出力メッセージ
  cv_msg_out_rec                 CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15020';    -- 件数メッセージ
  --メッセージ用文字列
  cv_str_purge_term              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15021';    -- XXCOS:汎用エラーリスト削除日数
  --エラーリスト用メッセージ
  cv_gmsg_process_date           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00215';    -- 処理日付出力メッセージ
  cv_gmsg_prog_name              CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15003';    -- 処理名
  cv_gmsg_line1                  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15001';    -- 区切り線１
  cv_gmsg_line2                  CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-15002';    -- 区切り線１
--
  --トークン名
  cv_tkn_nm_table_name           CONSTANT  VARCHAR2(100) :=  'TABLE_NAME';          -- テーブル名称
  cv_tkn_nm_table_lock           CONSTANT  VARCHAR2(100) :=  'TABLE';               -- テーブル名称(ロックエラー時用)
  cv_tkn_nm_key_data             CONSTANT  VARCHAR2(100) :=  'KEY_DATA';            -- キーデータ
  cv_tkn_nm_profile1             CONSTANT  VARCHAR2(100) :=  'PROFILE';             -- プロファイル名(販売領域) 
  cv_tkn_nm_param1               CONSTANT  VARCHAR2(100) :=  'PARAM1';              -- 入力パラメータ１
  cv_tkn_nm_param2               CONSTANT  VARCHAR2(100) :=  'PARAM2';              -- 入力パラメータ２
  cv_tkn_nm_param3               CONSTANT  VARCHAR2(100) :=  'PARAM3';              -- 入力パラメータ３
  cv_tkn_nm_conc_name            CONSTANT  VARCHAR2(100) :=  'CONC_NAME';           -- コンカレント名
  cv_tkn_nm_fdate                CONSTANT  VARCHAR2(100) :=  'FDATE';               -- 処理日付
  cv_tkn_nm_msg_count            CONSTANT  VARCHAR2(100) :=  'MSG_COUNT';           -- エラーメッセージ件数
  cv_tkn_nm_del_count            CONSTANT  VARCHAR2(100) :=  'DEL_COUNT';           -- 汎用エラーリスト削除件数
  --トークン値
  cv_msg_vl_table_xgel           CONSTANT  VARCHAR2(100) :=  'APP-XXCOS1-00213';    -- 汎用エラーリストテーブル
--
  --クイックコード参照用
  --参照タイプ名
  cv_type_xgel_prgm              CONSTANT  VARCHAR2(100) :=  'XXCOS1_GEN_ERR_LIST_PRGM';      --汎用エラーリスト対象プログラム
  cv_type_xgel_errmsg            CONSTANT  VARCHAR2(100) :=  'XXCOS1_GEN_ERR_LIST_ERRMSG';    --汎用エラーリスト対象エラーメッセージ
  --使用可能フラグ定数
  ct_enabled_flg_y               CONSTANT  fnd_lookup_values.enabled_flag%TYPE 
                                                         :=  'Y';       --使用可能
  cv_lang                        CONSTANT  VARCHAR2(100) :=  USERENV( 'LANG' );               --言語
--
  -- プロファイル
  ct_prof_errlist_purge_term     CONSTANT  fnd_profile_options.profile_option_name%TYPE 
                                                         := 'XXCOS1_GEN_ERRLIST_PURGE_TERM';  -- XXCOS:汎用エラーリスト削除日数
--
  --日付フォーマット
  cv_yyyy_mm_dd                  CONSTANT  VARCHAR2(100) :=  'YYYY/MM/DD';            --YYYY/MM/DD型
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_proc_date                DATE;                                              --業務日付
  gn_purge_term               NUMBER;                                            --汎用エラーリスト削除日数
  gn_delete_cnt               NUMBER;                                            --削除件数
--
  -- ===============================
  -- ユーザー定義グローバル・カーソル
  -- ===============================
  -- 汎用エラーリストテーブル抽出カーソル
  CURSOR gen_err_list_cur(
            iv_base_code     VARCHAR2
           ,id_process_date  DATE
           ,iv_conc_name     VARCHAR2
           )
  IS
    SELECT
       xgel.gen_err_list_id                  AS gen_err_list_id                          -- 汎用エラーリストID
      ,xgel.base_code                        AS base_code                                -- 拠点コード
      ,xgel.concurrent_program_name          AS concurrent_program_name                  -- コンカレント名
      ,flv1.description                      AS concurrent_program_desc                  -- コンカレント名称
      ,xgel.business_date                    AS business_date                            -- 処理日付
      ,xgel.message_name                     AS message_name                             -- メッセージ名
      ,xgel.message_text                     AS message_text                             -- メッセージ
      ,flv1.attribute1                       AS func_message_name                        -- 機能メッセージ名
      ,flv2.attribute1                       AS message_title_name                       -- メッセージタイトル名
    FROM
       xxcos_gen_err_list        xgel                                                    -- 汎用エラーリスト
      ,fnd_lookup_values         flv1                                                    -- クイックコード：汎用エラーリスト対象プログラム
      ,fnd_lookup_values         flv2                                                    -- クイックコード：汎用エラーリスト対象エラーメッセージ
    WHERE
        xgel.base_code                    = iv_base_code                                 -- 入力パラメータ「拠点コード」
    AND xgel.business_date                = id_process_date                              -- 入力パラメータ「処理日付」
    AND (
          ( iv_conc_name IS NULL )
         OR
          ( iv_conc_name IS NOT NULL
            AND
            xgel.concurrent_program_name  = iv_conc_name                                 -- 入力パラメータ「機能名」
          )
        )
    --
    -- 対象機能の絞込み
    AND xgel.concurrent_program_name      = flv1.meaning
    AND flv1.lookup_type                  = cv_type_xgel_prgm                            -- クイックコード：汎用エラーリスト対象プログラム
    AND gd_proc_date                     >= NVL( flv1.start_date_active, gd_proc_date )
    AND gd_proc_date                     <= NVL( flv1.end_date_active,   gd_proc_date )
    AND flv1.enabled_flag                 = ct_enabled_flg_y
    AND flv1.language                     = cv_lang
    --
    -- 対象メッセージの絞込み
    AND flv2.meaning                      = xgel.concurrent_program_name || '_' || xgel.message_name
    AND flv2.lookup_type                  = cv_type_xgel_errmsg                          -- クイックコード：汎用エラーリスト対象エラーメッセージ
    AND gd_proc_date                     >= NVL( flv2.start_date_active, gd_proc_date )
    AND gd_proc_date                     <= NVL( flv2.end_date_active,   gd_proc_date )
    AND flv2.enabled_flag                 = ct_enabled_flg_y
    AND flv2.language                     = cv_lang
    ORDER BY
       xgel.concurrent_program_name
      ,xgel.message_name
      ,xgel.gen_err_list_id
  ;
--
  --取得データ格納変数定義
  TYPE g_gen_err_list_ttype IS TABLE OF gen_err_list_cur%ROWTYPE INDEX BY BINARY_INTEGER;
  gt_gen_err_list_tab       g_gen_err_list_ttype;
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    iv_base_code                    IN     VARCHAR2,  -- 拠点コード
    iv_process_date                 IN     VARCHAR2,  -- 処理日付
    iv_conc_name                    IN     VARCHAR2,  -- 機能名
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'init';                 -- プログラム名
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
    lv_para_msg            VARCHAR2(5000);                         -- パラメータ出力メッセージ
    lv_purge_term          NUMBER;                                 -- 汎用エラーリスト削除日数
    lv_profile_name        fnd_new_messages.message_text%TYPE;     -- プロファイル名
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
    --========================================
    -- パラメータ出力処理
    --========================================
    lv_para_msg             :=  xxccp_common_pkg.get_msg(
      iv_application        =>  cv_xxcos_short_name,
      iv_name               =>  cv_msg_parameter,
      iv_token_name1        =>  cv_tkn_nm_param1,
      iv_token_value1       =>  iv_base_code,
      iv_token_name2        =>  cv_tkn_nm_param2,
      iv_token_value2       =>  iv_process_date,
      iv_token_name3        =>  cv_tkn_nm_param3,
      iv_token_value3       =>  iv_conc_name
    );
--
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  lv_para_msg
    );
--
    --1行空白
    FND_FILE.PUT_LINE(
       which  =>  FND_FILE.OUTPUT
      ,buff   =>  NULL
    );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_para_msg
    );
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
--
    --==================================
    -- XXCOS:汎用エラーリスト削除日数
    --==================================
    lv_purge_term := FND_PROFILE.VALUE( ct_prof_errlist_purge_term );
    -- プロファイルが取得できない場合はエラー
    IF ( lv_purge_term IS NULL ) THEN
      --プロファイル名文字列取得
      lv_profile_name := xxccp_common_pkg.get_msg(
        iv_application => cv_xxcos_short_name,
        iv_name        => cv_str_purge_term
      );
      --プロファイル名文字列取得
      lv_errmsg               := xxccp_common_pkg.get_msg(
        iv_application        => cv_xxcos_short_name,
        iv_name               => cv_msg_prof_err,
        iv_token_name1        => cv_tkn_nm_profile1,
        iv_token_value1       => lv_profile_name
      );
      lv_errbuf    := lv_errmsg;
      RAISE global_api_expt_log;
    ELSE
      gn_purge_term := TO_NUMBER(lv_purge_term);
    END IF;
    --
--
    --========================================
    -- 業務日付取得処理
    --========================================
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    IF ( gd_proc_date IS NULL ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_proc_date_err
      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt_log;
    END IF;
--
  EXCEPTION
    -- *** ログ限定出力用例外ハンドラ ***
    WHEN global_api_expt_log THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
   * Procedure Name   : get_data
   * Description      : 処理対象データ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_data(
    iv_base_code                    IN     VARCHAR2,  -- 拠点コード
    id_process_date                 IN     DATE,      -- 処理日付
    iv_conc_name                    IN     VARCHAR2,  -- 機能名
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_data'; -- プログラム名
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
    --対象データ取得
    OPEN  gen_err_list_cur(
             iv_base_code                                     -- 拠点コード
            ,id_process_date                                  -- 処理日付
            ,iv_conc_name                                     -- 機能名
            );
    FETCH gen_err_list_cur BULK COLLECT INTO gt_gen_err_list_tab;
    CLOSE gen_err_list_cur;
--
    --処理件数カウント
    gn_target_cnt := gt_gen_err_list_tab.COUNT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( gen_err_list_cur%ISOPEN ) THEN
        CLOSE gen_err_list_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_data;
--
  /**********************************************************************************
   * Procedure Name   : edit_output_msg
   * Description      : メッセージ編集出力(A-3)
   ***********************************************************************************/
  PROCEDURE edit_output_msg(
    iv_base_code                    IN     VARCHAR2,  -- 拠点コード
    id_process_date                 IN     DATE,      -- 処理日付
    iv_conc_name                    IN     VARCHAR2,  -- 機能名
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'edit_output_msg'; -- プログラム名
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
    lv_past_conc_name  xxcos_gen_err_list.concurrent_program_name%TYPE;
    lv_past_msg_title  xxcos_gen_err_list.message_name%TYPE;
    lv_gen_msg         VARCHAR2(5000);
    lv_gmsg_line1      fnd_new_messages.message_text%TYPE;
    lv_gmsg_line2      fnd_new_messages.message_text%TYPE;
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
    --========================================
    -- 変数の初期化
    --========================================
    lv_past_conc_name := NULL;
    lv_past_msg_title := NULL;
    --
    --========================================
    -- 区切り線の取得
    --========================================
    -- 区切り線１
    lv_gmsg_line1 :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  cv_gmsg_line1
                      );
    -- 区切り線２
    lv_gmsg_line2 :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  cv_gmsg_line2
                      );
    --
    --
    --========================================
    -- エラーメッセージの編集と出力
    --========================================
    --汎用エラーリストテーブルの内容を編集して「出力」へ出力
    <<edit_output_msg>>
    FOR i IN 1..gt_gen_err_list_tab.COUNT LOOP
      -- 機能メッセージの出力：1回目or機能が変わった場合
      IF ( i = 1 OR lv_past_conc_name != gt_gen_err_list_tab(i).concurrent_program_name ) THEN
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        -- 処理名の出力
        lv_gen_msg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  cv_gmsg_prog_name
                       ,iv_token_name1  =>  cv_tkn_nm_conc_name
                       ,iv_token_value1 =>  gt_gen_err_list_tab(i).concurrent_program_desc
                       );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gen_msg
        );
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        -- 区切り線１の出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gmsg_line1
        );
        --
        -- 機能メッセージの出力
        lv_gen_msg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  gt_gen_err_list_tab(i).func_message_name
                       );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gen_msg
        );
        -- 区切り線１の出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gmsg_line1
        );
        --
        --
      END IF;
      --
      -- メッセージタイトルの出力
      -- ループの1回目、またはA-2で取得したエラー情報の「コンカレント名」が前回と変わった場合、
      -- またはA-2で取得したエラー情報の「メッセージタイトル」が前回と変わった場合、
      IF(i = 1 OR lv_past_conc_name != gt_gen_err_list_tab(i).concurrent_program_name 
               OR lv_past_msg_title != gt_gen_err_list_tab(i).message_title_name      ) THEN      
        --空行挿入
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => ''
        );
        --
        -- メッセージタイトルの出力
        lv_gen_msg :=  xxccp_common_pkg.get_msg(
                        iv_application  =>  cv_xxcos_short_name
                       ,iv_name         =>  gt_gen_err_list_tab(i).message_title_name
                       );
        --
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gen_msg
        );
        -- 区切り線２の出力
        FND_FILE.PUT_LINE(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_gmsg_line2
        );
        --      
      END IF;
      --
      -- メッセージの出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => gt_gen_err_list_tab(i).message_text
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --
      -- コンカレントプログラム名の退避
      lv_past_conc_name := gt_gen_err_list_tab(i).concurrent_program_name;
      -- メッセージタイトルの退避
      lv_past_msg_title := gt_gen_err_list_tab(i).message_title_name;
    END LOOP edit_output_msg;
  --
  --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
  END edit_output_msg;
--
  /**********************************************************************************
   * Procedure Name   : delete_gen_err_list
   * Description      : 汎用エラーリスト削除(A-4)
   ***********************************************************************************/
  PROCEDURE delete_gen_err_list(
    iv_base_code                    IN     VARCHAR2,  -- 拠点コード
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_gen_err_list'; -- プログラム名
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
    lv_table_name fnd_new_messages.message_text%TYPE;
--
    -- *** ローカル・カーソル ***
    CURSOR gen_err_list_del_cur
      IS
        SELECT xgel.ROWID
        FROM   xxcos_gen_err_list xgel
        WHERE  xgel.base_code      =   iv_base_code
          AND  xgel.business_date <= (gd_proc_date - gn_purge_term)
        FOR UPDATE NOWAIT;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
--  変数の初期化
    gn_delete_cnt := 0;
--
--
    -- ===============================
    -- ロックの取得
    -- ===============================
    BEGIN
      OPEN  gen_err_list_del_cur;
      CLOSE gen_err_list_del_cur;
    EXCEPTION
      -- *** ロックエラーハンドラ ***
      WHEN global_data_lock_expt THEN
        IF ( gen_err_list_del_cur%ISOPEN ) THEN
          CLOSE gen_err_list_del_cur;
        END IF;
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_name  -- アプリケーション短縮名
                           ,iv_name        => cv_msg_vl_table_xgel -- メッセージコード
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_lock_err         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_nm_table_lock    -- トークンコード1
                       ,iv_token_value1 => lv_table_name           -- トークン値1
                     );
        --
        RAISE global_api_expt;
    END;
--
    -- ===============================
    -- 汎用エラーリストの削除
    -- ===============================
    BEGIN
      DELETE 
      FROM   xxcos_gen_err_list xgel
      WHERE  xgel.base_code      =   iv_base_code
        AND  xgel.business_date <= (gd_proc_date - gn_purge_term)
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_table_name := xxccp_common_pkg.get_msg(
                            iv_application => cv_xxcos_short_name  -- アプリケーション短縮名
                           ,iv_name        => cv_msg_vl_table_xgel -- メッセージコード
                         );
        --
        lv_errbuf := xxccp_common_pkg.get_msg(
                        iv_application  => cv_xxcos_short_name     -- アプリケーション短縮名
                       ,iv_name         => cv_msg_delete_err       -- メッセージコード
                       ,iv_token_name1  => cv_tkn_nm_table_name    -- トークンコード1
                       ,iv_token_value1 => lv_table_name           -- トークン値1
                       ,iv_token_name2  => cv_tkn_nm_key_data      -- トークンコード1
                       ,iv_token_value2 => SQLERRM                 -- トークン値1
                     );
        --
        RAISE global_api_expt;
    END;
    -- 件数の格納
    gn_delete_cnt := SQL%ROWCOUNT;
    --
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      IF ( gen_err_list_del_cur%ISOPEN ) THEN
        CLOSE gen_err_list_del_cur;
      END IF;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END delete_gen_err_list;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_base_code                    IN     VARCHAR2,  -- 拠点コード
    iv_process_date                 IN     VARCHAR2,  -- 処理日付
    iv_conc_name                    IN     VARCHAR2,  -- 機能名
    ov_errbuf                       OUT    VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                      OUT    VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                       OUT    VARCHAR2   -- ユーザー・エラー・メッセージ --# 固定 #
  )
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
    ld_process_date                   DATE;            -- 処理日付
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
    gn_delete_cnt := 0;
--
    -- ===============================
    -- A-1  初期処理
    -- ===============================
    init(
       iv_base_code                    -- 拠点コード
      ,iv_process_date                 -- 処理日付
      ,iv_conc_name                    -- 機能名
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- 入力パラメータ「処理日付」をDATE型に変換
    ld_process_date := TO_DATE( iv_process_date, cv_yyyy_mm_dd );
--
    -- ===============================
    -- A-2  対象データ取得
    -- ===============================
    get_data(
       iv_base_code                    -- 拠点コード
      ,ld_process_date                 -- 処理日付
      ,iv_conc_name                    -- 機能名
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- A-3  メッセージ編集出力
    -- ===============================
    -- エラーメッセージ件数が1件以上のときのみ
    IF( gn_target_cnt  > 0 ) THEN
      edit_output_msg(
         iv_base_code                    -- 拠点コード
        ,ld_process_date                 -- 処理日付
        ,iv_conc_name                    -- 機能名
        ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
        ,lv_retcode                      -- リターン・コード             --# 固定 #
        ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
      );
      IF ( lv_retcode = cv_status_normal ) THEN
        NULL;
      ELSE
        RAISE global_process_expt;
      END IF;
    END IF;
--
    -- ===============================
    -- A-4  汎用エラーリスト削除
    -- ===============================
    delete_gen_err_list(
       iv_base_code                    -- 拠点コード
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    IF ( lv_retcode = cv_status_normal ) THEN
      NULL;
    ELSE
      RAISE global_process_expt;
    END IF;
--
    -- エラーメッセージ件数が0件
    IF ( gn_target_cnt = 0 ) THEN
      lv_errmsg               :=  xxccp_common_pkg.get_msg(
        iv_application        =>  cv_xxcos_short_name,
        iv_name               =>  cv_msg_no_data
      );
      RAISE global_no_data_expt;
    END IF;
--
  EXCEPTION
    -- *** 対象0件例外ハンドラ ***
    WHEN global_no_data_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errmsg, 1, 5000 );
      -- リターンコードを一時的に警告にする
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf, 1, 5000 );
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
    errbuf                          OUT    VARCHAR2,         -- エラー・メッセージ  --# 固定 #
    retcode                         OUT    VARCHAR2,         -- リターン・コード    --# 固定 #
    iv_base_code                    IN     VARCHAR2,         --   拠点コード
    iv_process_date                 IN     VARCHAR2,         --   処理日付
    iv_conc_name                    IN     VARCHAR2          --   機能名
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
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_log_header_out  CONSTANT VARCHAR2(6)   := 'OUTPUT';           -- コンカレントヘッダメッセージ出力先：出力
    cv_log_header_log  CONSTANT VARCHAR2(6)   := 'LOG';              -- コンカレントヘッダメッセージ出力先：ログ
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
       iv_base_code                    -- 拠点コード
      ,iv_process_date                 -- 処理日付
      ,iv_conc_name                    -- 機能名
      ,lv_errbuf                       -- エラー・メッセージ           --# 固定 #
      ,lv_retcode                      -- リターン・コード             --# 固定 #
      ,lv_errmsg                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF ( lv_retcode <> cv_status_normal ) THEN
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --
    -- ===============================================
    -- ステータスの更新
    -- ===============================================
    IF (lv_retcode <> cv_status_error ) THEN
      IF   ( gn_target_cnt > 0 ) THEN
        -- エラーメッセージが１件以上ある場合はステータスを警告
        lv_retcode := cv_status_warn;
      ELSIF( gn_target_cnt = 0 ) THEN
        -- エラーメッセージが０件の場合はステータスを正常
        lv_retcode := cv_status_normal;
      END IF;
    ELSE
      -- エラー件数設定
      gn_error_cnt := gn_error_cnt + 1;
    END IF;
    --
    --
    -- ===============================================
    -- 件数出力
    -- ===============================================
    -- エラーメッセージ件数と削除件数の出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxcos_short_name
                    ,iv_name         => cv_msg_out_rec
                    ,iv_token_name1  => cv_tkn_nm_msg_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                    ,iv_token_name2  => cv_tkn_nm_del_count
                    ,iv_token_value2 => TO_CHAR( gn_delete_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
   --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
        --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- 終了メッセージ出力
    -- ===============================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_xxccp_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
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
END XXCOS009A08C;
/
