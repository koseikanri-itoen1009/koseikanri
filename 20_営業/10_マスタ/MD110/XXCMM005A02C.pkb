CREATE OR REPLACE PACKAGE BODY XXCMM005A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A02C(spec)
 * Description      : 組織マスタIF出力（情報系）
 * MD.050           : 組織マスタIF出力（情報系） CMM_005_A02
 * Version          : 1.4
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  init_proc            初期処理(A-1)
 *
 *  create_aff_date_proc 情報取得プロシージャ(A-4)
 *
 *  output_aff_date_proc 情報書き込みプロシージャ(A-5)
 *
 *  fin_proc             終了処理プロシージャ(A-6)
 *
 *  submain              メイン処理プロシージャ(A-1～A-5)
 *                          ・初期処理(A-1)呼び出し
 *                          ・ファイルオープン処理(A-2)実行
 *                          ・最上位部門件数取得判断処理(A-3)実行
 *                          ・情報取得プロシージャ(A-4)呼び出し
 *                          ・情報書き込みプロシージャ(A-5)呼び出し
 *
 *  main                 コンカレント実行ファイル登録プロシージャ
 *                          ・submain(A-1～A-5)呼び出し
 *                          ・終了処理プロシージャ(A-6)呼び出し
 *                          ・ROLLBACKの実行判断＋実行
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/01/28    1.0  T.Matsumoto       main新規作成
 *  2009/03/09    1.1  Takuya Kaihara    プロファイル値共通化
 *  2009/04/20    1.2  Yutaka.Kuboshima  障害T1_0590の対応
 *  2009/05/15    1.3  Yutaka.Kuboshima  障害T1_1026の対応
 *  2009/10/06    1.4  Shigeto.Niki      I_E_542、E_T3_00469対応
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; -- 正常:0
  cv_status_warn              CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   -- 警告:1
  cv_status_error             CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  -- 異常:2
  --WHOカラム
  cn_created_by               CONSTANT NUMBER      := fnd_global.user_id;                 -- CREATED_BY
  cd_creation_date            CONSTANT DATE        := SYSDATE;                            -- CREATION_DATE
  cn_last_updated_by          CONSTANT NUMBER      := fnd_global.user_id;                 -- LAST_UPDATED_BY
  cd_last_update_date         CONSTANT DATE        := SYSDATE;                            -- LAST_UPDATE_DATE
  cn_last_update_login        CONSTANT NUMBER      := fnd_global.login_id;                -- LAST_UPDATE_LOGIN
  cn_request_id               CONSTANT NUMBER      := fnd_global.conc_request_id;         -- REQUEST_ID
  cn_program_application_id   CONSTANT NUMBER      := fnd_global.prog_appl_id;            -- PROGRAM_APPLICATION_ID
  cn_program_id               CONSTANT NUMBER      := fnd_global.conc_program_id;         -- PROGRAM_ID
  cd_program_update_date      CONSTANT DATE        := SYSDATE;                            -- PROGRAM_UPDATE_DATE
  cv_msg_part                 CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont                 CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                  VARCHAR2(2000);
  gv_sep_msg                  VARCHAR2(2000);
  gv_exec_user                VARCHAR2(100);
  gv_conc_name                VARCHAR2(30);
  gv_conc_status              VARCHAR2(30);
  gn_target_cnt               NUMBER;                                                     -- 対象件数
  gn_normal_cnt               NUMBER;                                                     -- 正常件数
  gn_error_cnt                NUMBER;                                                     -- エラー件数
  gn_warn_cnt                 NUMBER;                                                     -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt         EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt             EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt      EXCEPTION;
  global_check_lock_expt      EXCEPTION;                                                  -- ロック取得エラー
--
  PRAGMA EXCEPTION_INIT( global_check_lock_expt, -54);
  PRAGMA EXCEPTION_INIT( global_api_others_expt, -20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                 CONSTANT VARCHAR2(30)  := 'XXCMM005A02C';                   -- パッケージ名
--
  cv_app_name_xxcmm           CONSTANT VARCHAR2(30)  := 'XXCMM';                          -- APPL短縮名：マスタ
  cv_app_name_xxccp           CONSTANT VARCHAR2(30)  := 'XXCCP';                          -- APPL短縮名：共通・IF
  -- メッセージ
  cv_emsg_nodata              CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00001';               -- 対象データ無しエラー
  cv_emsg_plofaile_get        CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00002';               -- プロファイル取得エラー
  cv_emsg_output              CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00009';               -- ファイル書き込みエラー
  cv_emsg_file_exists         CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00010';               -- CSVファイル存在エラー
  cv_emsg_file_open           CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00487';               -- ファイルオープンエラー
  cv_emsg_file_close          CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00489';               -- ファイルクローズエラー
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
--  cv_emsg_uppersec_cnt        CONSTANT VARCHAR2(30)  := 'APP-XXCMM1-00500';               -- 最上位部門複数時エラー
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
  cv_imsg_all_count           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90000';               -- 総件数情報
  cv_imsg_suc_count           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90001';               -- 成功件数情報
  cv_imsg_err_count           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90002';               -- エラー件数情報
  cv_imsg_normal_end          CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90004';               -- 正常終了メッセージ
  cv_imsg_warn_end            CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90005';               -- 警告終了メッセージ
  cv_imsg_error_end           CONSTANT VARCHAR2(30)  := 'APP-XXCCP1-90006';               -- 異常終了メッセージ
  -- トークン
  cv_tkn_sqlerrm              CONSTANT VARCHAR2(20)  := 'SQLERRM';                        -- トークン：SQLエラー
  cv_tkn_ng_profile           CONSTANT VARCHAR2(20)  := 'NG_PROFILE';                     -- トークン：プロファイル名
  cv_tkn_ffvset_name          CONSTANT VARCHAR2(20)  := 'FFV_SET_NAME';                   -- トークン：値セット名
  cv_tkn_ng_word              CONSTANT VARCHAR2(20)  := 'NG_WORD';                        -- トークン：項目名
  cv_tkn_nd_data              CONSTANT VARCHAR2(20)  := 'NG_DATA';                        -- トークン：対象の項目値
  cv_tkn_count                CONSTANT VARCHAR2(20)  := 'COUNT';                          -- トークン：カウント
  -- トークン値
  cv_tknv_csv_fl_dir          CONSTANT VARCHAR2(100) := 'XXCMM:情報系(OUTBOUND)連携用CSVファイル出力先';
  cv_tknv_csv_fl_name         CONSTANT VARCHAR2(100) := '組織マスタ（情報系）連携用CSVファイル名';
  cv_tknv_base_code           CONSTANT VARCHAR2(100) := '拠点コード'; 
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  cv_tknv_dummy_dept_code     CONSTANT VARCHAR2(100) := 'AFFダミー部門コード'; 
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
  -- カスタム・プロファイル名：組織マスタ(情報系)
  cv_csv_fl_dir               CONSTANT VARCHAR2(50)  := 'XXCMM1_JYOHO_OUT_DIR';           -- 連携用CSVファイル出力先
  cv_csv_fl_name              CONSTANT VARCHAR2(50)  := 'XXCMM1_005A02_OUT_FILE_FIL';     -- 連携用CSVファイル名称
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  cv_aff_dept_dummy_cd        CONSTANT VARCHAR2(50)  := 'XXCMM1_AFF_DEPT_DUMMY_CD';       -- AFFダミー部門コード
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
  -- 値セット名
  cv_dept_valset_name         CONSTANT VARCHAR2(50)  := 'XX03_DEPARTMENT';                -- 部門
  -- その他
  cv_flag_yes                 CONSTANT VARCHAR2(1)   := 'Y';                              -- フラグ：Y
  cv_csv_mode_w               CONSTANT VARCHAR2(1)   := 'w';                              -- Fopen：上書きモード
  cv_dqu                      CONSTANT VARCHAR2(1)   := '"';                              -- ダブルクォーテーション
  cv_sep                      CONSTANT VARCHAR2(1)   := ',';                              -- カンマ
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  cv_flag_parent              CONSTANT VARCHAR2(1)   := 'P';                              -- フラグ：P(親)
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 組織マスタIF出力（情報系）レイアウト
  TYPE xxcmm005a02c_rtype IS RECORD
  (
     base_code                fnd_flex_values.flex_value%TYPE                             -- 拠点コード
    ,base_name                fnd_flex_values.attribute4%TYPE                             -- 拠点名称
    ,base_abbrev              fnd_flex_values.attribute5%TYPE                             -- 拠点略称
    ,base_order               fnd_flex_values.attribute6%TYPE                             -- 拠点並び順
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
--    ,dpt6_start_date_active   fnd_flex_values.attribute6%TYPE                             -- ６階層目適用開始日
    ,dpt6_start_date_active   VARCHAR2(8)
    ,dpt6_old_cd              fnd_flex_values.attribute7%TYPE                             -- ６階層目旧本部コード
    ,dpt6_new_cd              fnd_flex_values.attribute9%TYPE                             -- ６階層目新本部コード    
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki    
    ,section_div              fnd_flex_values.attribute8%TYPE                             -- 部門区分
    ,district_code            fnd_flex_values.flex_value%TYPE                             -- 地区コード
    ,district_name            fnd_flex_values.attribute4%TYPE                             -- 地区名
    ,district_abbrev          fnd_flex_values.attribute5%TYPE                             -- 地区略称
    ,district_order           fnd_flex_values.attribute6%TYPE                             -- 地区並び順
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt5_start_date_active   fnd_flex_values.attribute6%TYPE                             -- ５階層目適用開始日
    ,dpt5_old_cd              fnd_flex_values.attribute7%TYPE                             -- ５階層目旧本部コード
    ,dpt5_new_cd              fnd_flex_values.attribute9%TYPE                             -- ５階層目新本部コード    
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,area_code                fnd_flex_values.flex_value%TYPE                             -- エリアコード
    ,area_name                fnd_flex_values.attribute4%TYPE                             -- エリア名
    ,area_abbrev              fnd_flex_values.attribute5%TYPE                             -- エリア略称
    ,area_order               fnd_flex_values.attribute6%TYPE                             -- エリア並び順
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt4_start_date_active   fnd_flex_values.attribute6%TYPE                             -- ４階層目適用開始日
    ,dpt4_old_cd              fnd_flex_values.attribute7%TYPE                             -- ４階層目旧本部コード
    ,dpt4_new_cd              fnd_flex_values.attribute9%TYPE                             -- ４階層目新本部コード
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,head_code                fnd_flex_values.flex_value%TYPE                             -- 本部コード
    ,head_name                fnd_flex_values.attribute4%TYPE                             -- 本部名
    ,head_abbrev              fnd_flex_values.attribute5%TYPE                             -- 本部略称
    ,head_order               fnd_flex_values.attribute6%TYPE                             -- 本部並び順
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt3_start_date_active   fnd_flex_values.attribute6%TYPE                             -- ３階層目適用開始日
    ,dpt3_old_cd              fnd_flex_values.attribute7%TYPE                             -- ３階層目旧本部コード
    ,dpt3_new_cd              fnd_flex_values.attribute9%TYPE                             -- ３階層目新本部コード
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,foundation_code          fnd_flex_values.flex_value%TYPE                             -- 大本部
    ,foundation_name          fnd_flex_values.attribute4%TYPE                             -- 大本部名
    ,foundation_abbrev        fnd_flex_values.attribute5%TYPE                             -- 大本部略称
    ,foundation_order         fnd_flex_values.attribute6%TYPE                             -- 大本部並び順
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt2_start_date_active   fnd_flex_values.attribute6%TYPE                             -- ２階層目適用開始日
    ,dpt2_old_cd              fnd_flex_values.attribute7%TYPE                             -- ２階層目旧本部コード
    ,dpt2_new_cd              fnd_flex_values.attribute9%TYPE                             -- ２階層目新本部コード
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,co_code                  fnd_flex_values.flex_value%TYPE                             -- 本社計
    ,co_name                  fnd_flex_values.attribute4%TYPE                             -- 本社計名
    ,co_abbrev                fnd_flex_values.attribute5%TYPE                             -- 本社計略称
    ,co_order                 fnd_flex_values.attribute6%TYPE                             -- 本社計並び順
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
    ,dpt1_start_date_active   fnd_flex_values.attribute6%TYPE                             -- １階層目適用開始日
    ,dpt1_old_cd              fnd_flex_values.attribute7%TYPE                             -- １階層目旧本部コード
    ,dpt1_new_cd              fnd_flex_values.attribute9%TYPE                             -- １+階層目新本部コード
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
    ,enabled_flag             fnd_flex_values.enabled_flag%TYPE                           -- 使用可能フラグ
    ,start_date_active        fnd_flex_values.start_date_active%TYPE                      -- 有効期間開始日
    ,end_date_active          fnd_flex_values.end_date_active%TYPE                        -- 有効期間終了日
    );
--
  -- 組織マスタIF出力（情報系）レイアウト テーブルタイプ
  TYPE xxcmm005a02c_ttype IS TABLE OF xxcmm005a02c_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- カスタム・プロファイル値：取得用
  gt_out_file_dir             fnd_profile_option_values.profile_option_value%TYPE;        -- 連携用CSVファイル出力先
  gt_out_file_name            fnd_profile_option_values.profile_option_value%TYPE;        -- 連携用CSVファイル名称
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
  gv_aff_dept_dummy_cd        fnd_profile_option_values.profile_option_value%TYPE;        -- AFFダミー部門コード
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
  gv_process_date              VARCHAR2(8);                                               -- 業務日付(YYYYMMDD)
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
--
  gf_file_hand                UTL_FILE.FILE_TYPE;                                         -- CSVファイル出力用ハンドラ
  g_csv_organ_tab             xxcmm005a02c_ttype;                                         -- 組織IF出力データ
--
  /**********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理プロシージャ(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
    ov_errbuf         OUT     VARCHAR2,                                                   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT     VARCHAR2,                                                   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT     VARCHAR2)                                                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'init_proc';                      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                             -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                              -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message_token          VARCHAR2(100);                                              -- 可変メッセージトークン
    lb_file_exists            BOOLEAN;                                                    -- ファイル存在判断
    ln_file_length            NUMBER(30);                                                 -- ファイルの文字列数
    lbi_block_size            BINARY_INTEGER;                                             -- ブロックサイズ
    --
    -- *** ユーザー定義例外 ***
    profile_expt              EXCEPTION;                                                  -- プロファイル取得例外
    csv_file_exst_expt        EXCEPTION;                                                  -- ファイル重複エラー  
--
  BEGIN
    -- 変数初期化
    lv_step := 'A-1.0';
    lv_errbuf           := NULL;
    lv_retcode          := NULL;
    lv_errmsg           := NULL;
    gt_out_file_dir     := NULL;
    gt_out_file_name    := NULL;
    lv_message_token    := NULL;
    g_csv_organ_tab.DELETE;
    --
    -- グローバル変数の初期化
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
--
    -- カスタム・プロファイル値：連携用CSVファイル出力先の取得
    lv_step := 'A-1.1';
    lv_message_token    := cv_tknv_csv_fl_dir;
    gt_out_file_dir     := FND_PROFILE.VALUE(cv_csv_fl_dir);
    -- 連携用CSVファイル出力先の取得内容チェック
    IF ( gt_out_file_dir IS NULL) THEN
      --
      RAISE profile_expt;
    END IF;
--
    -- カスタム・プロファイル値：連携用CSVファイル名称の取得
    lv_step := 'A-1.2';
    lv_message_token    := cv_tknv_csv_fl_name;
    gt_out_file_name    := FND_PROFILE.VALUE(cv_csv_fl_name);
    -- 連携用CSVファイル出力先の取得内容チェック
    IF ( gt_out_file_name IS NULL) THEN
      --
      RAISE profile_expt;
    END IF;
--
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
    -- カスタム・プロファイル値：AFFダミー部門コードの取得
    lv_step := 'A-1.3';
    lv_message_token     := cv_tknv_dummy_dept_code;
    gv_aff_dept_dummy_cd := FND_PROFILE.VALUE(cv_aff_dept_dummy_cd);
    -- 連携用CSVファイル出力先の取得内容チェック
    IF ( gv_aff_dept_dummy_cd IS NULL) THEN
      --
      RAISE profile_expt;
    END IF;
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
    -- CSVファイル存在チェック
    lv_step := 'A-1.3';
    UTL_FILE.FGETATTR(
         location     => gt_out_file_dir
        ,filename     => gt_out_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
      -- ファイル重複チェック(ファイル存在の有無)
      IF ( lb_file_exists = TRUE ) THEN
        RAISE csv_file_exst_expt;
      END IF;

-- 2009/10/06 Ver1.4 add start by Shigeto.Niki
      -- 業務日付をYYYYMMDD形式で取得します
      gv_process_date := TO_CHAR(xxccp_common_pkg2.get_process_date,'YYYYMMDD');
      --
-- 2009/10/06 Ver1.4 add end by Shigeto.Niki
--
  EXCEPTION
    --*** プロファイル取得エラー ***
    WHEN profile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- マスタ
                     ,iv_name         => cv_emsg_plofaile_get                             -- プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_ng_profile                                -- NG_PROFILE
                     ,iv_token_value1 => lv_message_token                                 -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    --*** CSVファイル存在エラー ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- マスタ
                     ,iv_name         => cv_emsg_file_exists                              -- CSVファイル存在エラー
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  END init_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : create_aff_date_proc
   * Description      : AFF部門マスタ情報取得プロシージャ(A-4)
   ***********************************************************************************/
  PROCEDURE create_aff_date_proc(
    ov_errbuf         OUT     VARCHAR2,                                                   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT     VARCHAR2,                                                   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT     VARCHAR2)                                                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'create_aff_date_proc';           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                             -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                              -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_loop_cnt               NUMBER := 0;                                                -- Loop時のカウント変数
    lv_message_token          VARCHAR2(1000);                                             -- メッセージ用変数
    -- 組織マスタ（情報系）情報カーソル
    CURSOR csv_organ_cur
    IS
      SELECT     xhdal.dpt6_cd                 AS base_code                                  -- 拠点コード
                ,xhdal.dpt6_name               AS base_name                                  -- 拠点名称
                ,xhdal.dpt6_abbreviate         AS base_abbrev                                -- 拠点略称
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt6_sort_num           AS base_order                                 -- 拠点並び順
                ,xhdal.dpt6_start_date_active  AS dpt6_start_date_active                     -- ６階層目適用開始日
                ,xhdal.dpt6_old_cd             AS dpt6_old_cd                                -- ６階層目旧本部コード
                ,xhdal.dpt6_new_cd             AS dpt6_new_cd                                -- ６階層目新本部コード
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt6_div                AS section_div                                -- 部門区分
                ,xhdal.dpt5_cd                 AS district_code                              -- 地区コード
                ,xhdal.dpt5_name               AS district_name                              -- 地区名
                ,xhdal.dpt5_abbreviate         AS district_abbrev                            -- 地区略称
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt5_sort_num           AS district_order                             -- 地区並び順
                ,xhdal.dpt5_start_date_active  AS dpt5_start_date_active                     -- ５階層目適用開始日
                ,xhdal.dpt5_old_cd             AS dpt5_old_cd                                -- ５階層目旧本部コード
                ,xhdal.dpt5_new_cd             AS dpt5_new_cd                                -- ５階層目新本部コード
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt4_cd                 AS area_code                                  -- エリアコード
                ,xhdal.dpt4_name               AS area_name                                  -- エリア名
                ,xhdal.dpt4_abbreviate         AS area_abbrev                                -- エリア略称
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt4_sort_num           AS area_order                                 -- エリア並び順
                ,xhdal.dpt4_start_date_active  AS dpt4_start_date_active                     -- ４階層目適用開始日
                ,xhdal.dpt4_old_cd             AS dpt4_old_cd                                -- ４階層目旧本部コード
                ,xhdal.dpt4_new_cd             AS dpt4_new_cd                                -- ４階層目新本部コード
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt3_cd                 AS head_code                                  -- 本部コード
                ,xhdal.dpt3_name               AS head_name                                  -- 本部名
                ,xhdal.dpt3_abbreviate         AS head_abbrev                                -- 本部略称
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt3_sort_num           AS head_order                                 -- 本部並び順
                ,xhdal.dpt3_start_date_active  AS dpt3_start_date_active                     -- ３階層目適用開始日
                ,xhdal.dpt3_old_cd             AS dpt3_old_cd                                -- ３階層目旧本部コード
                ,xhdal.dpt3_new_cd             AS dpt3_new_cd                                -- ３階層目新本部コード
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt2_cd                 AS foundation_code                            -- 大本部
                ,xhdal.dpt2_name               AS foundation_name                            -- 大本部名
                ,xhdal.dpt2_abbreviate         AS foundation_abbrev                          -- 大本部略称
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt2_sort_num           AS foundation_order                           -- 大本部並び順
                ,xhdal.dpt2_start_date_active  AS dpt2_start_date_active                     -- ２階層目適用開始日
                ,xhdal.dpt2_old_cd             AS dpt2_old_cd                                -- ２階層目旧本部コード
                ,xhdal.dpt2_new_cd             AS dpt2_new_cd                                -- ２階層目新本部コード
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,xhdal.dpt1_cd                 AS co_code                                    -- 本社計
                ,xhdal.dpt1_name               AS co_name                                    -- 本社計名
                ,xhdal.dpt1_abbreviate         AS co_abbrev                                  -- 本社計略称
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                 ,xhdal.dpt1_sort_num           AS co_order                                   -- 本社計並び順
                ,xhdal.dpt1_start_date_active  AS dpt1_start_date_active                     -- １階層目適用開始日
                ,xhdal.dpt1_old_cd             AS dpt1_old_cd                                -- １階層目旧本部コード
                ,xhdal.dpt1_new_cd             AS dpt1_new_cd                                -- １階層目新本部コード
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                ,DECODE(xhdal.enabled_flag,'N','0','Y','1',NULL)
                                               AS enabled_flag                               -- 使用可能フラグ
                ,xhdal.start_date_active       AS start_date_active                          -- 有効期間開始日
                ,xhdal.end_date_active         AS end_date_active                            -- 有効期間終了日
      FROM      xxcmm_hierarchy_dept_all_v     xhdal
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--       ORDER BY  xhdal.dpt1_cd ASC
      ORDER BY  xhdal.dpt6_cd ASC
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      ;
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    nodata_expt             EXCEPTION;                                                    -- 対象データ無しエラー
--
  BEGIN
    -- ===============================================
    -- A-4.0ローカル変数初期化
    -- ===============================================
    lv_step :='A-4.0';
    lv_errbuf   := NULL;
    lv_retcode  := NULL;
    lv_errmsg   := NULL;
    lv_message_token := NULL;
    --
    -- ===============================================
    -- A-4.xxxxx構造体への値の入力を開始
    -- ===============================================
    <<csv_organ_loop>>
    FOR l_csv_organ_rec IN csv_organ_cur LOOP
      -- LOOPカウントUP
      lv_step :='A-4.1';
      ln_loop_cnt := ln_loop_cnt + 1 ;
      -- ===============================
      -- 抽出内容の構造体への入力
      -- ===============================
      -- 拠点コード
      lv_step :='A-4.base_code';
      lv_message_token :='拠点コード';
      g_csv_organ_tab(ln_loop_cnt).base_code         := l_csv_organ_rec.base_code;
      -- 拠点名称
      lv_step :='A-4.base_name';
      lv_message_token :='拠点名称';
      g_csv_organ_tab(ln_loop_cnt).base_name         := l_csv_organ_rec.base_name;
      -- 拠点略称
      lv_step :='A-4.base_abbrev';
      lv_message_token :='拠点略称';
      g_csv_organ_tab(ln_loop_cnt).base_abbrev       := l_csv_organ_rec.base_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- 拠点並び順
      lv_step :='A-4.base_order';
      lv_message_token :='拠点並び順';
--       g_csv_organ_tab(ln_loop_cnt).base_order        := l_csv_organ_rec.base_order;
      -- 適用開始日 <= 業務日付の場合は、新本部コードをセット
      IF (l_csv_organ_rec.dpt6_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).base_order  := l_csv_organ_rec.dpt6_old_cd;
      ELSIF (l_csv_organ_rec.dpt6_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).base_order  := l_csv_organ_rec.dpt6_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).base_order  := l_csv_organ_rec.dpt6_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- 部門区分
      lv_step :='A-4.section_div';
      lv_message_token :='部門区分';
      g_csv_organ_tab(ln_loop_cnt).section_div       := l_csv_organ_rec.section_div;
      -- 地区コード
      lv_step :='A-4.district_code';
      lv_message_token :='地区コード';
      g_csv_organ_tab(ln_loop_cnt).district_code     := l_csv_organ_rec.district_code;
      -- 地区名
      lv_step :='A-4.district_name';
      lv_message_token :='地区名';
      g_csv_organ_tab(ln_loop_cnt).district_name     := l_csv_organ_rec.district_name;
      -- 地区略称
      lv_step :='A-4.district_abbrev';
      lv_message_token :='地区略称';
      g_csv_organ_tab(ln_loop_cnt).district_abbrev   := l_csv_organ_rec.district_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- 地区並び順
      lv_step :='A-4.district_order';
      lv_message_token :='地区並び順';
--      g_csv_organ_tab(ln_loop_cnt).district_order    := l_csv_organ_rec.district_order;
      -- 適用開始日 <= 業務日付の場合は、新本部コードをセット
      IF (l_csv_organ_rec.dpt5_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).district_order  := l_csv_organ_rec.dpt5_old_cd;
      ELSIF (l_csv_organ_rec.dpt5_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).district_order  := l_csv_organ_rec.dpt5_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).district_order  := l_csv_organ_rec.dpt5_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- エリアコード
      lv_step :='A-4.area_code';
      lv_message_token :='エリアコード';
      g_csv_organ_tab(ln_loop_cnt).area_code         := l_csv_organ_rec.area_code;
      -- エリア名
      lv_step :='A-4.area_name';
      lv_message_token :='エリア名';
      g_csv_organ_tab(ln_loop_cnt).area_name         := l_csv_organ_rec.area_name;
      -- エリア略称
      lv_step :='A-4.area_abbrev';
      lv_message_token :='エリア略称';
      g_csv_organ_tab(ln_loop_cnt).area_abbrev       := l_csv_organ_rec.area_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- エリア並び順
      lv_step :='A-4.area_order';
      lv_message_token :='エリア並び順';
--       g_csv_organ_tab(ln_loop_cnt).area_order        := l_csv_organ_rec.area_order;
      -- 適用開始日 <= 業務日付の場合は、新本部コードをセット
      IF (l_csv_organ_rec.dpt4_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).area_order      := l_csv_organ_rec.dpt4_old_cd;
      ELSIF (l_csv_organ_rec.dpt4_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).area_order      := l_csv_organ_rec.dpt4_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).area_order      := l_csv_organ_rec.dpt4_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- 本部コード
      lv_step :='A-4.head_code';
      lv_message_token :='本部コード';
      g_csv_organ_tab(ln_loop_cnt).head_code         := l_csv_organ_rec.head_code;
      -- 本部名
      lv_step :='A-4.head_name';
      lv_message_token :='本部名';
      g_csv_organ_tab(ln_loop_cnt).head_name         := l_csv_organ_rec.head_name;
      -- 本部略称
      lv_step :='A-4.head_abbrev';
      lv_message_token :='本部略称';
      g_csv_organ_tab(ln_loop_cnt).head_abbrev       := l_csv_organ_rec.head_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- 本部並び順
      lv_step :='A-4.head_order';
      lv_message_token :='本部並び順';
--       g_csv_organ_tab(ln_loop_cnt).head_order        := l_csv_organ_rec.head_order;
      -- 適用開始日 <= 業務日付の場合は、新本部コードをセット
      IF (l_csv_organ_rec.dpt3_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).head_order      := l_csv_organ_rec.dpt3_old_cd;
      ELSIF (l_csv_organ_rec.dpt3_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).head_order      := l_csv_organ_rec.dpt3_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).head_order      := l_csv_organ_rec.dpt3_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- 大本部
      lv_step :='A-4.foundation_code';
      lv_message_token :='大本部';
      g_csv_organ_tab(ln_loop_cnt).foundation_code   := l_csv_organ_rec.foundation_code;
      -- 大本部名
      lv_step :='A-4.foundation_name';
      lv_message_token :='大本部名';
      g_csv_organ_tab(ln_loop_cnt).foundation_name   := l_csv_organ_rec.foundation_name;
      -- 大本部略称
      lv_step :='A-4.foundation_abbrev';
      lv_message_token :='大本部略称';
      g_csv_organ_tab(ln_loop_cnt).foundation_abbrev := l_csv_organ_rec.foundation_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- 大本部並び順
      lv_step :='A-4.foundation_order';
      lv_message_token :='大本部並び順';
--       g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.foundation_order;
      -- 適用開始日 <= 業務日付の場合は、新本部コードをセット
      IF (l_csv_organ_rec.dpt2_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.dpt2_old_cd;
      ELSIF (l_csv_organ_rec.dpt2_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.dpt2_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).foundation_order  := l_csv_organ_rec.dpt2_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- 本社計
      lv_step :='A-4.co_code';
      lv_message_token :='本社計';
      g_csv_organ_tab(ln_loop_cnt).co_code           := l_csv_organ_rec.co_code;
      -- 本社計名
      lv_step :='A-4.co_name';
      lv_message_token :='本社計名';
      g_csv_organ_tab(ln_loop_cnt).co_name           := l_csv_organ_rec.co_name;
      -- 本社計略称
      lv_step :='A-4.co_abbrev';
      lv_message_token :='本社計略称';
      g_csv_organ_tab(ln_loop_cnt).co_abbrev         := l_csv_organ_rec.co_abbrev;
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
      -- 本社計並び順
      lv_step :='A-4.co_order';
      lv_message_token :='本社計並び順';
--      g_csv_organ_tab(ln_loop_cnt).co_order          := l_csv_organ_rec.co_order;
      IF (l_csv_organ_rec.dpt1_start_date_active IS NULL) THEN
        g_csv_organ_tab(ln_loop_cnt).co_order      := l_csv_organ_rec.dpt1_old_cd;
      ELSIF (l_csv_organ_rec.dpt1_start_date_active <= gv_process_date) THEN
        g_csv_organ_tab(ln_loop_cnt).co_order      := l_csv_organ_rec.dpt1_new_cd;
      ELSE
        g_csv_organ_tab(ln_loop_cnt).co_order      := l_csv_organ_rec.dpt1_old_cd;
      END IF;
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
      -- 使用可能フラグ
      lv_step :='A-4.enabled_flag';
      lv_message_token :='使用可能フラグ';
      g_csv_organ_tab(ln_loop_cnt).enabled_flag      := l_csv_organ_rec.enabled_flag;
      -- 有効期間開始日
      lv_step :='A-4.start_date_active';
      lv_message_token :='有効期間開始日';
      g_csv_organ_tab(ln_loop_cnt).start_date_active := l_csv_organ_rec.start_date_active;
      -- 有効期間終了日
      lv_step :='A-4.end_date_active';
      lv_message_token :='有効期間終了日';
      g_csv_organ_tab(ln_loop_cnt).end_date_active   := l_csv_organ_rec.end_date_active;
    --
      -- 対象件数
      gn_target_cnt := gn_target_cnt + 1;
    --
    END LOOP csv_organ_loop ;
  --
  -- 構造体への出力件数判断
    lv_step :='A-4.2';
    IF (ln_loop_cnt =  0 ) THEN
      -- 構造体の件数 = 0:即ち出力対象が無い場合は、
      -- 既に開いてるファイルを削除してから異常終了処理を行う
      UTL_FILE.FREMOVE( location    => gt_out_file_dir                                    -- 削除対象があるディレクトリ
                       ,filename    => gt_out_file_name                                   -- 削除対象ファイル名
                                       );
      --
      RAISE nodata_expt;
    END IF;
  --
  EXCEPTION
    -- *** 対象データ無しエラーハンドラ ***
    WHEN nodata_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- マスタ
                     ,iv_name         => cv_emsg_nodata                                   -- 対象データ無しエラー
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message_token --ユーザー・エラーメッセージ
      );
      ov_errbuf  := cv_pkg_name ||  cv_msg_cont   ||  cv_prg_name ||  cv_msg_cont ||
                    lv_step     ||  cv_msg_part   ||  SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END create_aff_date_proc;
--



  /**********************************************************************************
   * Procedure Name   : output_aff_date_proc
   * Description      : AFF部門マスタ情報書き込みプロシージャ(A-5)
   ***********************************************************************************/
  PROCEDURE output_aff_date_proc(
    ov_errbuf         OUT     VARCHAR2,                                                   -- エラー・メッセージ           --# 固定 #
    ov_retcode        OUT     VARCHAR2,                                                   -- リターン・コード             --# 固定 #
    ov_errmsg         OUT     VARCHAR2)                                                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'output_aff_date_proc';           -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                             -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                              -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_company_code           CONSTANT VARCHAR2(10) := '001';                             -- 会社コード：固定値"001"

--
    -- *** ローカル変数 ***
    ln_max_cnt                NUMBER := 0;                                                -- カーソルLoop時の最大LOOP数
    ln_index                  NUMBER ;                                                    -- カーソルLoop時のindex
    lv_message_token          VARCHAR2(1000);                                             -- メッセージ用変数
    lv_if_date                VARCHAR2(20);                                               -- 連携日時用(CHAR型)変数
    -- ↓(データ取得元varchar2(240)*30列+アルファで8000確保) --
    lv_out_csv_line           VARCHAR2(8000);                                             -- 出力行用変数
    lt_base_code              fnd_flex_values.flex_value%TYPE;                            -- エラー時メッセージ用変数
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    file_output_expt          EXCEPTION;                                                  -- ファイル出力エラー
  --
  BEGIN
    -- ===============================================
    -- A-5.0ローカル変数初期化
    -- ===============================================
    lv_step :='A-5.0';
    lv_errbuf   := NULL;
    lv_retcode  := NULL;
    lv_errmsg   := NULL;
    lt_base_code     := NULL;
    lv_message_token := NULL;
    ln_max_cnt  := g_csv_organ_tab.count;
    lv_if_date  := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
--
    -- CSV作成LOOP開始
    <<out_csv_loop>>
    FOR ln_index IN 1 .. ln_max_cnt LOOP
      -- ===============================================
      -- A-5.xxxxx 組織情報構造体からOUTPUT用のCSV行を生成する
      -- ===============================================
      -- lv_out_csv_linen編集時の記述パターン
      -- lv_out_csv_linen := <"> or < lv_out_csv_linen ,"> ||
      --                     <表示編集内容>
      --                     || <">
--
      -- 会社コード
      lv_step :='A-5.company_code';
      lv_message_token :='会社コード';
      lv_out_csv_line  := cv_dqu ||
                          cv_company_code
                          || cv_dqu;
      -- 拠点コード
      lv_step :='A-5.base_code';
      lv_message_token :='拠点コード';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).base_code, 1, 4)
                          || cv_dqu;
      -- 拠点名称
      lv_step :='A-5.base_name';
      lv_message_token :='拠点名称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).base_name, 1, 40)
                          || cv_dqu;
      -- 拠点略称
      lv_step :='A-5.base_abbrev';
      lv_message_token :='拠点略称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).base_abbrev, 1, 8)
                          || cv_dqu;
      -- 拠点並び順
      lv_step :='A-5.base_order';
      lv_message_token :='拠点並び順';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).base_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).base_order, 1, 8)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- 部門区分
      lv_step :='A-5.section_div';
      lv_message_token :='部門区分';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).section_div, 1, 2)
                          || cv_dqu;
      -- 地区コード
      lv_step :='A-5.district_code';
      lv_message_token :='地区コード';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).district_code, 1, 4)
                          || cv_dqu;
      -- 地区名
      lv_step :='A-5.district_name';
      lv_message_token :='地区名';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).district_name, 1, 40)
                          || cv_dqu;
      -- 地区略称
      lv_step :='A-5.district_abbrev';
      lv_message_token :='地区略称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).district_abbrev, 1, 8)
                          || cv_dqu;
      -- 地区並び順
      lv_step :='A-5.district_order';
      lv_message_token :='地区並び順';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).district_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).district_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- エリアコード
      lv_step :='A-5.area_code';
      lv_message_token :='エリアコード';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).area_code, 1, 4)
                          || cv_dqu;
      -- エリア名
      lv_step :='A-5.area_name';
      lv_message_token :='エリア名';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).area_name, 1, 40)
                          || cv_dqu;
      -- エリア略称
      lv_step :='A-5.area_abbrev';
      lv_message_token :='エリア略称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).area_abbrev, 1, 8)
                          || cv_dqu;
      -- エリア並び順
      lv_step :='A-5.area_order';
      lv_message_token :='エリア並び順';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).area_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).area_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- 本部コード
      lv_step :='A-5.head_code';
      lv_message_token :='本部コード';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).head_code, 1, 4)
                          || cv_dqu;
      -- 本部名
      lv_step :='A-5.head_name';
      lv_message_token :='本部名';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).head_name, 1, 40)
                          || cv_dqu;
      -- 本部略称
      lv_step :='A-5.head_abbrev';
      lv_message_token :='本部略称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).head_abbrev, 1, 8)
                          || cv_dqu;
      -- 本部並び順
      lv_step :='A-5.head_order';
      lv_message_token :='本部並び順';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).head_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).head_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- 大本部
      lv_step :='A-5.foundation_code';
      lv_message_token :='大本部';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_code, 1, 4)
                          || cv_dqu;
      -- 大本部名
      lv_step :='A-5.foundation_name';
      lv_message_token :='大本部名';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_name, 1, 40)
                          || cv_dqu;
      -- 大本部略称
      lv_step :='A-5.foundation_abbrev';
      lv_message_token :='大本部略称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_abbrev, 1, 8)
                          || cv_dqu;
      -- 大本部並び順
      lv_step :='A-5.foundation_order';
      lv_message_token :='大本部並び順';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).foundation_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).foundation_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- 本社計
      lv_step :='A-5.co_code';
      lv_message_token :='本社計';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).co_code, 1, 4)
                          || cv_dqu;
      -- 本社計名
      lv_step :='A-5.co_name';
      lv_message_token :='本社計名';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).co_name, 1, 40)
                          || cv_dqu;
      -- 本社計略称
      lv_step :='A-5.co_abbrev';
      lv_message_token :='本社計略称';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).co_abbrev, 1, 8)
                          || cv_dqu;
      -- 本社計並び順
      lv_step :='A-5.co_order';
      lv_message_token :='本社計並び順';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
-- 2009/10/06 Ver1.4 mod start by Shigeto.Niki
--                           SUBSTRB(g_csv_organ_tab(ln_index).co_order, 1, 3)
                          SUBSTRB(g_csv_organ_tab(ln_index).co_order, 1, 6)
-- 2009/10/06 Ver1.4 mod end by Shigeto.Niki
                          || cv_dqu;
      -- 使用可能フラグ
      lv_step :='A-5.enabled_flag';
      lv_message_token :='使用可能フラグ';
      lv_out_csv_line  := lv_out_csv_line || cv_sep || cv_dqu ||
                          SUBSTRB(g_csv_organ_tab(ln_index).enabled_flag, 1, 1)
                          || cv_dqu;
      -- 有効期間開始日
      lv_step :='A-5.start_date_active';
      lv_message_token :='有効期間開始日';
      lv_out_csv_line  := lv_out_csv_line || cv_sep ||
                          TO_CHAR(g_csv_organ_tab(ln_index).start_date_active, 'YYYYMMDD' )
                          ;
      -- 有効期間終了日
      lv_step :='A-5.end_date_active';
      lv_message_token :='有効期間終了日';
      lv_out_csv_line  := lv_out_csv_line || cv_sep ||
                          TO_CHAR(g_csv_organ_tab(ln_index).end_date_active, 'YYYYMMDD'   )
                          ;
      -- 連携日時
      lv_step :='A-5.if_date';
      lv_message_token :='連携日時';
      lv_out_csv_line  := lv_out_csv_line || cv_sep ||
                          lv_if_date
                          ;
      --
      -- CSVファイル出力
      lv_step := 'A-5.2';
      BEGIN
        --
        -- エラー時のメッセージ出力用に拠点コードを変数に格納する
        lt_base_code     := SUBSTRB(g_csv_organ_tab(ln_index).base_code, 1, 4);
        -- ファイルの書き込みを行う(改行込み)
        UTL_FILE.PUT_LINE(gf_file_hand, lv_out_csv_line );
      EXCEPTION
        WHEN OTHERS THEN
          --
          RAISE file_output_expt;
      END;
      --
      -- 成功件数
      gn_normal_cnt := gn_normal_cnt + 1;
      --
    END LOOP out_csv_loop;
  --
  EXCEPTION
    -- *** ファイル書き込みエラーハンドラ ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name_xxcmm                                  -- マスタ
                   ,iv_name         => cv_emsg_output                                     -- ファイル書き込みエラー
                   ,iv_token_name1  => cv_tkn_ng_word                                     -- NG_WORD
                   ,iv_token_value1 => cv_tknv_base_code                                  -- 拠点コード
                   ,iv_token_name2  => cv_tkn_nd_data                                     -- NG_DATA
                   ,iv_token_value2 => lt_base_code                                       -- 拠点コード値
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
  --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_message_token --ユーザー・エラーメッセージ
      );
      ov_errbuf  := cv_pkg_name ||  cv_msg_cont   ||  cv_prg_name ||  cv_msg_cont ||
                    lv_step     ||  cv_msg_part   ||  SQLERRM;
      ov_retcode := cv_status_error;
--
  END output_aff_date_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : fin_proc
   * Description      : 終了処理プロシージャ(A-6)
   ***********************************************************************************/
  PROCEDURE fin_proc(
    iov_errbuf        IN OUT  VARCHAR2,                                                   -- エラー・メッセージ           --# 固定 #
    iov_retcode       IN OUT  VARCHAR2,                                                   -- リターン・コード             --# 固定 #
    iov_errmsg        IN OUT  VARCHAR2)                                                   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'fin_proc';                       -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                 VARCHAR2(5000);                                             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                             -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                              -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_message_code           VARCHAR2(30);                                               -- 可変メッセージコード
    --
    -- *** ユーザー定義例外 ***
--
  BEGIN
    -- ===============================================
    -- A-6.0ローカル変数初期化
    -- ===============================================
    lv_step :='A-6.0';
    lv_errbuf   := NULL ;
    lv_retcode  := NULL ;
    lv_errmsg   := NULL ;
    lv_message_code := NULL;
--
    -- ===============================================
    -- A-6.1ファイルのクローズ処理
    -- ===============================================
    lv_step := 'A-6.1';
    --
    BEGIN
      -- ファイルクローズ
      UTL_FILE.FCLOSE( gf_file_hand );
    EXCEPTION
      WHEN OTHERS THEN
      -- *** ファイルクローズ失敗例外ハンドラ ***
        -- 現在までにエラーが出てる場合は先に出力する
        IF ( iov_retcode <> cv_status_normal ) THEN
          -- エラー発生箇所 + エラー内容
          FND_FILE.PUT_LINE(
             which  => FND_FILE.OUTPUT
            ,buff   => iov_errbuf || iov_errmsg
          );
          FND_FILE.PUT_LINE(
             which  => FND_FILE.LOG
            ,buff   => iov_errbuf || iov_errmsg
          );
        END IF;
        -- ファイルクローズ時エラーメッセージを導出する
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm                                -- マスタ
                       ,iv_name         => cv_emsg_file_close                               -- ファイルクローズエラー
                       ,iv_token_name1  => cv_tkn_sqlerrm                                   -- SQLERRM
                       ,iv_token_value1 => SQLERRM                                          -- SQLERRM
                       );
        iov_errmsg  := lv_errmsg;
        iov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                       lv_step     || cv_msg_part || lv_errbuf;
        iov_retcode := cv_status_error;
      --
    END;
    --
    -- ===============================================
    -- A-6.2終了ログの出力処理
    -- ===============================================
    -- エラーログの出力
    lv_step := 'A-6.2.1';
    IF ( iov_retcode  <> cv_status_normal ) THEN
      -- 正常終了時以外はメッセージログを出力する
      -- エラー発生箇所 + エラー内容
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => iov_errbuf || iov_errmsg
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => iov_errbuf || iov_errmsg
      );
    END IF;
    --
    -- エラー件数の取得(全件数 - 成功件数)
    lv_step := 'A-6.2.2';
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
    --対象件数出力
    lv_step := 'A-6.2.3';
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_imsg_all_count
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_target_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
      );
    -- メッセージ用変数初期化
    lv_errmsg := NULL;
    --
    --成功件数出力
    lv_step := 'A-6.2.4';
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_imsg_suc_count
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_normal_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
      );
    -- メッセージ用変数初期化
    lv_errmsg := NULL;
    --
    --異常件数出力
    lv_step := 'A-6.2.5';
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_imsg_err_count
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR( gn_error_cnt )
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
      );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
      );
    -- メッセージ用変数初期化
    lv_errmsg := NULL;
    --
    --終了メッセージ出力
    lv_step := 'A-6.2.6';
    IF ( iov_retcode    = cv_status_normal ) THEN
      -- 正常終了の場合
      lv_message_code := cv_imsg_normal_end;
    --
    ELSIF( iov_retcode  = cv_status_warn ) THEN
      -- 警告終了の場合
      lv_message_code := cv_imsg_warn_end;
    --
    ELSIF( iov_retcode  = cv_status_error ) THEN
      -- 異常終了の場合
      lv_message_code := cv_imsg_error_end;
    END IF;
    -- メッセージの取得
    lv_errmsg  := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => lv_message_code
                   );
    --
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_errmsg
    );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => lv_errmsg
    );
  --
  EXCEPTION
  --#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      iov_errmsg  := lv_errmsg;
      iov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      iov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      iov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      iov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      --エラー出力
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part||SQLERRM,1,5000),TRUE);
--
  END fin_proc;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf        OUT     VARCHAR2                                                    --   エラー・メッセージ           --# 固定 #
    ,ov_retcode       OUT     VARCHAR2                                                    --   リターン・コード             --# 固定 #
    ,ov_errmsg        OUT     VARCHAR2                                                    --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'submain';                        -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                             -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(100);                                              -- ステップ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザーローカル変数
    -- ===============================
    ln_upper_sec_cnt          NUMBER  := 0;                                               -- 最上位部門数のカウント変数
--
    -- ===============================
    -- ユーザーローカルカーソル定義
    -- ===============================
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    subproc_expt              EXCEPTION;                                                  -- サブプログラムエラー
    file_open_expt            EXCEPTION;                                                  -- ファイルオープンエラー
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
--    upper_sec_cnt_expt        EXCEPTION;                                                  -- 最上位部門複数時のエラー
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================================
    -- A-0.ローカル変数初期化
    -- ===============================================
    lv_errbuf   := NULL;
    lv_retcode  := NULL;
    lv_errmsg   := NULL;
    lv_step     := NULL;
--
    -- ===============================================
    -- A-1.初期処理(init_procで行う)
    -- ===============================================
    init_proc(
       ov_errbuf      => lv_errbuf                                                        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode                                                       -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg                                                        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      --
      RAISE subproc_expt;
    END IF;
--
    -- ===============================================
    -- A-2.ファイルオープン処理(UTL_FILE.FOPEN関数)
    -- ===============================================
    --
      lv_step := 'A-2.1';
      BEGIN
        -- ファイルハンドラの生成
        gf_file_hand := UTL_FILE.FOPEN(  location   => gt_out_file_dir                    -- 出力先
                                        ,filename   => gt_out_file_name                   -- ファイル名
                                        ,open_mode  => cv_csv_mode_w                      -- ファイルオープンモード
                                       );
      EXCEPTION
        WHEN OTHERS THEN
          --
          RAISE file_open_expt;
      END;
--
    -- ===============================================
    -- A-3.最上位部門件数取得
    -- ===============================================
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
/*    -- 最上位部門の数をカウントする
    lv_step := 'A-3.1';
    SELECT
          COUNT(1)
    INTO
          ln_upper_sec_cnt
    FROM
          fnd_flex_value_sets   ffvs,
          fnd_flex_values       ffv
    WHERE
          ffvs.flex_value_set_name    = cv_dept_valset_name
    AND   ffv.summary_flag            = cv_flag_yes
    AND   ffvs.flex_value_set_id      = ffv.flex_value_set_id
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
    AND   ffv.flex_value             <> gv_aff_dept_dummy_cd
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
    AND   NOT EXISTS (
                        SELECT
                            'X'
                        FROM
                            fnd_flex_value_norm_hierarchy ffvh
                        WHERE
                            ffvh.flex_value_set_id =  ffv.flex_value_set_id
                        AND (ffv.flex_value BETWEEN ffvh.child_flex_value_low AND ffvh.child_flex_value_high)
-- 2009/04/20 Ver1.2 add start by Yutaka.Kuboshima
                        AND ffvh.range_attribute   = cv_flag_parent
                        )
    AND   EXISTS (
                    SELECT
                        'X'
                    FROM
                        fnd_flex_value_norm_hierarchy ffvh2
                    WHERE
                        ffvh2.flex_value_set_id = ffv.flex_value_set_id
                    AND ffvh2.parent_flex_value = ffv.flex_value
                    AND ffvh2.range_attribute   = cv_flag_parent
                    )
    ;
-- 2009/04/20 Ver1.2 add end by Yutaka.Kuboshima
    -- 最上位部門の数をチェックする
    lv_step := 'A-3.2';
    IF ( ln_upper_sec_cnt <> 1 ) THEN
      -- 最上位層の部門数でエラーがあった場合
      -- 既に開いてるファイルを削除してから異常終了処理を行う
      UTL_FILE.FREMOVE( location    => gt_out_file_dir                                    -- 削除対象があるディレクトリ
                       ,filename    => gt_out_file_name                                   -- 削除対象ファイル名
                                       );
      --
      RAISE upper_sec_cnt_expt ;
    END IF;
--
*/
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
    -- ===============================================
    -- A-4.AFF部門マスタ情報取得(create_aff_date_procを呼び出す)
    -- ===============================================
    create_aff_date_proc(
       ov_errbuf      => lv_errbuf                                                        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode                                                       -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg                                                        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      --
      RAISE subproc_expt;
    END IF;
--
    -- ===============================================
    -- A-5.AFF部門マスタ情報出力処理(output_aff_date_procを呼び出す)
    -- ===============================================
    output_aff_date_proc(
       ov_errbuf      => lv_errbuf                                                        -- エラー・メッセージ           --# 固定 #
      ,ov_retcode     => lv_retcode                                                       -- リターン・コード             --# 固定 #
      ,ov_errmsg      => lv_errmsg                                                        -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      --
      RAISE subproc_expt;
    END IF;
--
  EXCEPTION
    -- *** サブプログラム例外ハンドラ ****
    WHEN subproc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
    --*** ファイルオープンエラー ***
    WHEN file_open_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- マスタ
                     ,iv_name         => cv_emsg_file_open                                -- ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                                   -- SQLERRM
                     ,iv_token_value1 => SQLERRM                                          -- SQLERRM
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
--
-- 2009/05/15 Ver1.3 delete start by Yutaka.Kuboshima
/*    --*** 最上位部門数エラー ***
    WHEN upper_sec_cnt_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm                                -- マスタ
                     ,iv_name         => cv_emsg_uppersec_cnt                             -- 最上位部門数エラー
                     ,iv_token_name1  => cv_tkn_ffvset_name                               -- FFV_SET_NAME
                     ,iv_token_value1 => cv_dept_valset_name                              -- 値セット名
                     ,iv_token_name2  => cv_tkn_count                                     -- COUNT
                     ,iv_token_value2 => TO_CHAR(ln_upper_sec_cnt)                        -- 最上位部門数
                     );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont ||
                    lv_step     || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
*/
-- 2009/05/15 Ver1.3 delete end by Yutaka.Kuboshima
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf;
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part||SQLERRM,1,5000),TRUE);
--
--#####################################  固定部 END   ##########################################
  --
  END submain;
--
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf            OUT     VARCHAR2                                                    --   エラーメッセージ #固定#
   ,retcode           OUT     VARCHAR2                                                    --   エラーコード     #固定#
  )
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'main';                           -- プログラム名
    cv_log                    CONSTANT VARCHAR2(100) := 'LOG';                            -- ログ
    cv_output                 CONSTANT VARCHAR2(100) := 'OUTPUT';                         -- アウトプット
--
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                 VARCHAR2(5000);                                             -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                                -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                             -- ユーザー・エラー・メッセージ
    lv_step                   VARCHAR2(10);                                               -- ステップ
    lv_message_code           VARCHAR2(100);                                              -- メッセージコード
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
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- A-1.～A-5はsubmain内で行う
    -- ===============================================
    submain(
       ov_errbuf      => lv_errbuf                                                        -- エラー・メッセージ          --# 固定 #
      ,ov_retcode     => lv_retcode                                                       -- リターン・コード            --# 固定 #
      ,ov_errmsg      => lv_errmsg                                                        -- ユーザー・エラー・メッセージ--# 固定 #
    );
--
    -- ===============================================
    -- A-6.終了処理(A-6.1.ファイルクローズ/A-6.2.終了ログ出力はfin_procで行う)
    -- ===============================================
    fin_proc(
       iov_errbuf     => lv_errbuf                                                        -- エラー・メッセージ           --# 固定 #
      ,iov_retcode    => lv_retcode                                                       -- リターン・コード             --# 固定 #
      ,iov_errmsg     => lv_errmsg                                                        -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- A-6.3.終了ステータスのセット
    -- ===============================================
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      --
      ROLLBACK;
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
--
END XXCMM005A02C ;
/
