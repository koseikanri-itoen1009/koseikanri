create or replace PACKAGE BODY XXCMM005A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM005A05C(body)
 * Description      : 拠点マスタIF出力（ワークフロー）
 * MD.050           : 拠点マスタIF出力（ワークフロー） MD050_CMM_005_A05
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  open_csv_file          ファイルオープン処理(A-2)
 *  chk_count_top_dept     最上位部門件数取得(A-3)
 *  get_base_data          処理対象データ抽出(A-4)
 *  output_csv_data        抽出情報出力(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009/02/06    1.0   Masayuki.Sano    新規作成
 *  2009/02/26    1.1   Masayuki.Sano    結合テスト動作不正対応
 *  2009/02/27    1.2   Masayuki.Sano    結合テスト動作不正対応(出力不正)
 *  2009/03/09    1.3   Yuuki.Nakamura   ファイル出力先プロファイル名称変更
 *  2009/04/20    1.4   Yutaka.Kuboshima 障害T1_0590の対応
 *  2009/05/14    1.5   Yutaka.Kuboshima 障害T1_1000の対応
 *  2009/10/07    1.6   Shigeto.Niki     障害I_E_542、E_T3_00469の対応
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
  cn_created_by             CONSTANT NUMBER      := fnd_global.user_id;         -- CREATED_BY
  cd_creation_date          CONSTANT DATE        := SYSDATE;                    -- CREATION_DATE
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;         -- LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                    -- LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;        -- LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id; -- REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;    -- PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id; -- PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                    -- PROGRAM_UPDATE_DATE
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name         CONSTANT VARCHAR2(100) := 'XXCMM005A05C';               -- パッケージ名
  -- ■ アプリケーション短縮名
  cv_app_name_xxcmm   CONSTANT VARCHAR2(30)  := 'XXCMM';                      -- マスタ
  cv_app_name_xxccp   CONSTANT VARCHAR2(30)  := 'XXCCP';                      -- 共通・IF
  -- ■ カスタム・プロファイル・オプション
--ver.1.3 2009/03/09 mod by Yuuki.Nakamura start
--  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_005A05_OUT_FILE_DIR';  -- 連携用CSVファイル出力先
  cv_pro_out_file_dir CONSTANT VARCHAR2(50) := 'XXCMM1_WORKFLOW_OUT_DIR';     -- 連携用CSVファイル出力先
--ver.1.3 2009/03/09 mod by Yuuki.Nakamura end
  cv_pro_out_file_fil CONSTANT VARCHAR2(50) := 'XXCMM1_005A05_OUT_FILE_FIL';  -- 連携用CSVファイル名
-- 2009/04/20 Ver1.4 add start by Yutaka.Kuboshima
  cv_aff_dept_dummy_cd CONSTANT VARCHAR2(50)  := 'XXCMM1_AFF_DEPT_DUMMY_CD';    -- AFFダミー部門コード
-- 2009/04/20 Ver1.4 add end by Yutaka.Kuboshima
  -- ■ メッセージ・コード(エラー)
  cv_msg_00002        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';            -- プロファイル取得エラー
  cv_msg_00010        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';            -- CSVファイル存在チェック
  cv_msg_00003        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';            -- ファイルパス不正エラー
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--  cv_msg_00500        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00500';            -- 部門階層エラー
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
  cv_msg_00001        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';            -- 対象データ無し
  cv_msg_00009        CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';            -- CSVデータ出力エラー
-- 2009/02/26 ADD by M.Sano Start
  cv_msg_91003        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-91003';            -- システムエラー
-- 2009/02/26 ADD by M.Sano End
  -- ■ メッセージ・コード(出力)
  cv_msg_90008        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';            -- コンカレント入力パラメータなし
  cv_msg_05132        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';            -- ファイル名出力メッセージ
  cv_msg_90000        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90000';            -- 対象件数メッセージ
  cv_msg_90001        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90001';            -- 成功件数メッセージ
  cv_msg_90002        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90002';            -- エラー件数メッセージ
  cv_normal_msg       CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90004';            -- 正常終了メッセージ
  cv_error_msg        CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90006';            -- エラー終了全ロールバック
  -- ■ トークン(キー)
  cv_tok_filename     CONSTANT VARCHAR2(15) := 'FILE_NAME';                   -- ファイル名
  cv_tok_ng_profile   CONSTANT VARCHAR2(15) := 'NG_PROFILE';
  cv_tok_ffv_set_name CONSTANT VARCHAR2(15) := 'FFV_SET_NAME';                -- 値セット名
  cv_tok_ng_word      CONSTANT VARCHAR2(15) := 'NG_WORD';
  cv_tok_ng_data      CONSTANT VARCHAR2(15) := 'NG_DATA';
  cv_tok_count        CONSTANT VARCHAR2(15) := 'COUNT';
  -- ■ トークン(値)
  cv_tvl_out_file_dir CONSTANT VARCHAR2(50) := '拠点マスタ（ワークフロー）連携用CSVファイル出力先';
  cv_tvl_out_file_fil CONSTANT VARCHAR2(50) := '拠点マスタ（ワークフロー）連携用CSVファイル名';
  cv_tvl_base_code    CONSTANT VARCHAR2(20) := '拠点コード';
  cv_tvl_ffv_set_name CONSTANT VARCHAR2(20) := 'XX03_DEPARTMENT';
-- 2009/04/20 Ver1.4 add start by Yutaka.Kuboshima
  cv_tvl_dummy_code   CONSTANT VARCHAR2(50)  := 'AFFダミー部門コード';        -- AFFダミー部門コード
-- 2009/04/20 Ver1.4 add end by Yutaka.Kuboshima
--
-- 2009/04/20 Ver1.4 add start by Yutaka.Kuboshima
  cv_flag_parent      CONSTANT VARCHAR2(1)  := 'P';                           -- フラグ：P(親)
-- 2009/04/20 Ver1.4 add end by Yutaka.Kuboshima
-- 2009/05/14 Ver1.5 add start by Yutaka.Kuboshima
  cv_lookup_area      CONSTANT VARCHAR2(30) := 'XXCMN_AREA';                  -- 参照タイプ(地区名)
  cv_y_flag           CONSTANT VARCHAR2(1)  := 'Y';                           -- 有効フラグ(Y)
  cv_language_ja      CONSTANT VARCHAR2(2)  := 'JA';                          -- 言語(JA)
-- 
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 拠点マスタIF出力(ワークフロー)レイアウト
  TYPE output_data_rtype IS RECORD
  (
     dpt6_cd                 xxcmm_hierarchy_dept_v.dpt6_cd%TYPE                 -- 部門コード
    ,dpt6_name               xxcmm_hierarchy_dept_v.dpt6_name%TYPE               -- 拠点正式名
    ,dpt6_abbreviate         xxcmm_hierarchy_dept_v.dpt6_abbreviate%TYPE         -- 拠点略称
    ,dpt6_old_cd             xxcmm_hierarchy_dept_v.dpt6_old_cd%TYPE             -- 旧本部コード
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
--     ,dpt6_sort_num           xxcmm_hierarchy_dept_v.dpt6_sort_num%TYPE         -- 拠点並び順
    ,dpt6_new_cd             xxcmm_hierarchy_dept_v.dpt6_new_cd%TYPE             -- 新本部コード
    ,dpt6_start_date_active  xxcmm_hierarchy_dept_v.dpt6_start_date_active%TYPE  -- 部門適用開始日
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--    ,attribute4              fnd_flex_values.attribute4%TYPE                    -- 拠点正式名（旧本部コード）
--    ,attribute6              fnd_flex_values.attribute6%TYPE                    -- 拠点並び順（旧本部コード）
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
    ,creation_date           xxcmm_hierarchy_dept_v.creation_date%TYPE           -- 作成日
    ,dpt3_cd                 xxcmm_hierarchy_dept_v.dpt3_cd%TYPE                 -- 部門コード(3階層目)
    ,dpt3_name               xxcmm_hierarchy_dept_v.dpt3_name%TYPE               -- 拠点正式名(3階層目)
    ,customer_name_phonetic  ar_customers_v.customer_name_phonetic%TYPE          -- 顧客カナ名
    ,address_line            VARCHAR2(100)                                       -- 住所
    ,zip                     xxcmn_parties.zip%TYPE                              -- 郵便番号
    ,phone                   xxcmn_parties.phone%TYPE                            -- 電話番号
    ,fax                     xxcmn_parties.fax%TYPE                              -- FAX番号
-- 2009/10/08 Ver1.6 delete start by Shigeto.Niki
-- 2009/05/14 Ver1.5 add start by Yutaka.Kuboshima
--     ,area_name               fnd_lookup_values.meaning%TYPE                      -- 地区名
-- 2009/05/14 Ver1.5 add start by Yutaka.Kuboshima
-- 2009/10/08 Ver1.6 delete end by Shigeto.Niki
  );
--
  -- 拠点マスタIF出力(ワークフロー)レイアウト テーブルタイプ
  TYPE output_data_ttype IS TABLE OF output_data_rtype INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gv_csv_file_dir       fnd_profile_option_values.profile_option_value%TYPE;
                                        -- 拠点マスタIF出力（ワークフロー）連携用CSVファイル出力先
  gv_csv_file_name      fnd_profile_option_values.profile_option_value%TYPE;  
                                        -- 拠点マスタIF出力（ワークフロー）連携用CSVファイル名
-- 2009/04/20 Ver1.3 add start by Yutaka.Kuboshima
  gv_aff_dept_dummy_cd  fnd_profile_option_values.profile_option_value%TYPE;
                                        -- AFFダミー部門コード
-- 2009/04/20 Ver1.3 add end by Yutaka.Kuboshima
  gf_file_handler       UTL_FILE.FILE_TYPE;                                   
                                        -- CSVファイル出力用ハンドラ
  gt_csv_out_tab        output_data_ttype;                                   
                                        -- 拠点マスタIF出力（ワークフロー）データ
-- 2009/10/07 Ver1.6 add start by Shigeto.Niki
  gv_next_proc_date     VARCHAR2(8);
                                        -- 翌業務日付(YYYYMMDD)
-- 2009/10/07 Ver1.6 add end by Shigeto.Niki
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lb_file_exists   BOOLEAN;        -- ファイル存在判断
    ln_file_length   NUMBER(30);     -- ファイルの文字列数
    lbi_block_size   BINARY_INTEGER; -- ブロックサイズ
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
    --１．プロファイルの取得を行います。
    --==============================================================
    -- 拠点マスタIF出力（ワークフロー）連携用CSVファイル出力先を取得
    gv_csv_file_dir    := FND_PROFILE.VALUE(cv_pro_out_file_dir);
    -- 拠点マスタIF出力（ワークフロー）連携用CSVファイル出力先の取得内容チェック
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_dir  -- 値      :CSVファイル出力先
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 拠点マスタIF出力（ワークフロー）連携用CSVファイル名を取得
    gv_csv_file_name    := FND_PROFILE.VALUE(cv_pro_out_file_fil);
    -- 拠点マスタIF出力（ワークフロー）連携用CSVファイル名の取得内容チェック
    IF ( gv_csv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_out_file_fil  -- 値      :CSVファイル名
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2009/04/20 Ver1.4 add start by Yutaka.Kuboshima
    -- XXCMM:AFFダミー部門コードを取得
    gv_aff_dept_dummy_cd := FND_PROFILE.VALUE(cv_aff_dept_dummy_cd);
    -- XXCMM:AFFダミー部門コードの取得内容チェック
    IF ( gv_aff_dept_dummy_cd IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00002         -- エラー  :プロファイル取得エラー
                     ,iv_token_name1  => cv_tok_ng_profile    -- トークン:NG_PROFILE
                     ,iv_token_value1 => cv_tvl_dummy_code    -- 値      :AFFダミー部門コード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
-- 2009/04/20 Ver1.4 add end by Yutaka.Kuboshima
    --==============================================================
    --２．CSVファイル存在チェックを行います。
    --==============================================================
    -- ファイル情報を取得
    UTL_FILE.FGETATTR(
         location     => gv_csv_file_dir
        ,filename     => gv_csv_file_name
        ,fexists      => lb_file_exists
        ,file_length  => ln_file_length
        ,block_size   => lbi_block_size
      );
    -- ファイル重複チェック(ファイル存在の有無)
    IF ( lb_file_exists ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00010         -- エラー:CSVファイル存在チェック
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
-- 2009/10/07 Ver1.6 add start by Shigeto.Niki
    --==============================================================
    --３．翌業務日付をYYYYMMDD形式で取得します。
    --==============================================================
      gv_next_proc_date := TO_CHAR(xxccp_common_pkg2.get_process_date + 1,'YYYYMMDD');
      --
-- 2009/10/07 Ver1.6 add end by Shigeto.Niki
--
  EXCEPTION
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : open_file
   * Description      : ファイルオープン処理(A-2)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file'; -- プログラム名
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
    cv_csv_mode_w CONSTANT VARCHAR2(1) := 'w';  -- ファイルオープンモード(書き込みモード)
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
    -- オープンモード'W'(出力)でオープンします。
    -- ===============================================
    BEGIN
      -- ファイルを開く
      gf_file_handler := UTL_FILE.FOPEN(
                            location   => gv_csv_file_dir     -- 出力先
                           ,filename   => gv_csv_file_name    -- ファイル名
                           ,open_mode  => cv_csv_mode_w       -- ファイルオープンモード
                        );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH THEN
        -- メッセージを取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name_xxcmm  -- マスタ
                       ,iv_name         => cv_msg_00003       -- エラー:ファイルパス不正エラー
                     );
        lv_errbuf := lv_errmsg;
        -- 例外をスロー
        RAISE global_api_expt;
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--  /**********************************************************************************
--   * Procedure Name   : chk_count_top_dept
--   * Description      : 最上位部門件数取得(A-3)
--   ***********************************************************************************/
--  PROCEDURE chk_count_top_dept(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_count_top_dept'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル変数 ***
--    ln_top_dept_cnt NUMBER;
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := cv_status_normal;
----
----###########################  固定部 END   ############################
----
--    --==============================================================
--    -- 1.最上位部門の件数を取得します。
--    --==============================================================
--    BEGIN
--      SELECT COUNT(1)
--      INTO   ln_top_dept_cnt
--      FROM   fnd_flex_value_sets ffvs  -- 値セット定義マスタ
--            ,fnd_flex_values     ffvl  -- 値セット値定義マスタ
--      WHERE  ffvs.flex_value_set_id = ffvl.flex_value_set_id
--      AND    ffvl.enabled_flag = 'Y'
--      AND    ffvl.summary_flag = 'Y'
--      AND    ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
--      AND    xxccp_common_pkg2.get_process_date BETWEEN
--                   NVL(ffvl.start_date_active, TO_DATE('19000101','YYYYMMDD'))
--               AND NVL(ffvl.end_date_active, TO_DATE('99991231','YYYYMMDD'))
---- 2009/04/20 Ver1.4 add start by Yutaka.Kuboshima
--      AND    ffvl.flex_value <> gv_aff_dept_dummy_cd
---- 2009/04/20 Ver1.4 add end by Yutaka.Kuboshima
--      AND    NOT EXISTS (
--               SELECT 'X'
--               FROM   fnd_flex_value_norm_hierarchy ffvh
--               WHERE  ffvh.flex_value_set_id = ffvl.flex_value_set_id
--               AND    ffvl.flex_value BETWEEN ffvh.child_flex_value_low
--                                          AND ffvh.child_flex_value_high
---- 2009/04/20 Ver1.4 add start by Yutaka.Kuboshima
--               AND    ffvh.range_attribute   = cv_flag_parent
--             )
--      AND    EXISTS (
--               SELECT 'X'
--               FROM   fnd_flex_value_norm_hierarchy ffvh2
--               WHERE  ffvh2.flex_value_set_id = ffvl.flex_value_set_id
--               AND    ffvh2.parent_flex_value = ffvl.flex_value
--               AND    ffvh2.range_attribute   = cv_flag_parent
--             )
---- 2009/04/20 Ver1.4 add end by Yutaka.Kuboshima
--      ;
--    EXCEPTION
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
----
--    --==============================================================
--    -- 2．最上位部門件数が1件以外の場合、部門階層エラー
--    --==============================================================
--    IF ( ln_top_dept_cnt <> 1 ) THEN
--      -- 最上位層の部門数でエラーがあった場合、既に開いてるファイルを削除
--      UTL_FILE.FREMOVE( location    => gv_csv_file_dir    -- 削除対象があるディレクトリ
--                       ,filename    => gv_csv_file_name   -- 削除対象ファイル名
--      );
--      -- エラーメッセージを出力後、異常終了
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxcmm        -- マスタ
--                     ,iv_name         => cv_msg_00500             -- エラー:部門階層エラー
--                     ,iv_token_name1  => cv_tok_ffv_set_name      -- トークン  :FFV_SET_NAME
--                     ,iv_token_value1 => cv_tvl_ffv_set_name      -- トークン値:XX03_DEPARTMENT
--                     ,iv_token_name2  => cv_tok_count             -- トークン  :COUNT
--                     ,iv_token_value2 => TO_CHAR(ln_top_dept_cnt) -- トークン値:最上位階層の件数
--                   );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    -- *** 共通関数例外ハンドラ ***
--    WHEN global_api_expt THEN
--      ov_errmsg  := lv_errmsg;
--      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := cv_status_error;
--    -- *** 共通関数OTHERS例外ハンドラ ***
--    WHEN global_api_others_expt THEN
---- 2009/02/26 ADD by M.Sano Start
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxccp    -- マスタ
--                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
--                   );
---- 2009/02/26 ADD by M.Sano End
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
--    -- *** OTHERS例外ハンドラ ***
--    WHEN OTHERS THEN
---- 2009/02/26 ADD by M.Sano Start
--      ov_errmsg  := xxccp_common_pkg.get_msg(
--                      iv_application  => cv_app_name_xxccp    -- マスタ
--                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
--                   );
---- 2009/02/26 ADD by M.Sano End
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
--      ov_retcode := cv_status_error;
----
----#####################################  固定部 END   ##########################################
----
--  END chk_count_top_dept;
--
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
  /**********************************************************************************
   * Procedure Name   : get_base_data
   * Description      : 処理対象データ抽出(A-4)
   ***********************************************************************************/
  PROCEDURE get_base_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_base_data'; -- プログラム名
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
    -- *** ローカルカーソル***
    CURSOR base_mst_cur
    IS
      SELECT xhdv.dpt6_cd                 AS  dpt6_cd                 -- 部門コード
            ,xhdv.dpt6_name               AS  dpt6_name               -- 拠点正式名
            ,xhdv.dpt6_abbreviate         AS  dpt6_abbreviate         -- 拠点略称
            ,xhdv.dpt6_old_cd             AS  dpt6_old_cd             -- 旧本部コード
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
            ,xhdv.dpt6_new_cd             AS  dpt6_new_cd             -- 新本部コード
            ,xhdv.dpt6_start_date_active  AS  dpt6_start_date_active  -- 部門適用開始日(6階層目)
--             ,xhdv.dpt6_sort_num           AS  dpt6_sort_num           -- 拠点並び順
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--            ,ffvl.attribute4              AS  attribute4              -- 拠点正式名（旧本部コード）
--            ,ffvl.attribute6              AS  attribute6              -- 拠点並び順（旧本部コード）
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
            ,xhdv.creation_date           AS  creation_date           -- 作成日
            ,xhdv.dpt3_cd                 AS  dpt3_cd                 -- 部門コード(3階層目)
            ,xhdv.dpt3_name               AS  dpt3_name               -- 拠点正式名(3階層目)
            ,bnad.customer_name_phonetic  AS  customer_name_phonetic  -- 顧客カナ名
            ,bnad.address_line            AS  address_line            -- 住所
            ,bnad.zip                     AS  zip                     -- 郵便番号
            ,bnad.phone                   AS  phone                   -- 電話番号
            ,bnad.fax                     AS  fax                     -- FAX番号
-- 2009/10/08 Ver1.6 delete start by Shigeto.Niki
-- 2009/05/14 Ver1.5 add start by Yutaka.Kuboshima
--             ,flva.meaning                 AS  area_name               -- 地区名
-- 2009/05/14 Ver1.5 add end by Yutaka.Kuboshima
-- 2009/10/08 Ver1.6 delete end by Shigeto.Niki
      FROM   xxcmm_hierarchy_dept_v xhdv          -- (table)部門階層ビュー
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--            ,fnd_flex_values        ffvl          -- (table)値セット値定義マスタ
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
            ,( SELECT arv.customer_number         AS customer_number         -- 顧客コード
                     ,arv.customer_name           AS customer_name           -- 顧客名称
                     ,arv.account_name            AS account_name            -- 顧客略称
                     ,arv.customer_name_phonetic  AS customer_name_phonetic  -- 顧客カナ名
                     ,pta.party_id                AS party_id                -- パーティid
                     ,pta.address_line            AS address_line            -- 住所
                     ,pta.zip                     AS zip                     -- 郵便番号
                     ,pta.phone                   AS phone                   -- 電話番号
                     ,pta.fax                     AS fax                     -- FAX番号
               FROM   ar_customers_v  arv         -- (table)顧客マスタ
                     ,( /*** 現在有効な適用日範囲のもの ***/
                        SELECT xpt.party_id                           AS  party_id
                              ,xpt.address_line1 || xpt.address_line2 AS  address_line
                              ,xpt.zip                                AS  zip
                              ,xpt.phone                              AS  phone
                              ,xpt.fax                                AS  fax
                        FROM   xxcmn_parties xpt  -- (table)パーティアドオン
                        WHERE  xxccp_common_pkg2.get_process_date BETWEEN xpt.start_date_active
                                                                      AND xpt.end_date_active
                      )               pta         -- (table)パーティアドオン
               WHERE  pta.party_id(+)         = arv.party_id
                 AND  arv.customer_class_code = '1'
             )                      bnad          -- (table)拠点名称住所
-- 2009/10/08 Ver1.6 delete start by Shigeto.Niki
-- 2009/05/14 Ver1.5 add start by Yutaka.Kuboshima
--             ,( SELECT flv.lookup_code lookup_code
--                      ,flv.meaning     meaning
--                FROM   fnd_lookup_values flv
--                WHERE  flv.lookup_type  = cv_lookup_area
--                  AND  flv.enabled_flag = cv_y_flag
--                  AND  flv.language     = cv_language_ja
--              )                      flva          -- (table)LOOKUP地区名
-- 2009/05/14 Ver1.5 add end by Yutaka.Kuboshima
-- 2009/10/08 Ver1.6 delete end by Shigeto.Niki
      WHERE  bnad.customer_number(+)   = xhdv.dpt6_cd
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--      AND    ffvl.flex_value_set_id(+) = xhdv.flex_value_set_id
--      AND    ffvl.flex_value(+)        = xhdv.dpt6_old_cd
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
-- 2009/10/08 Ver1.6 delete start by Shigeto.Niki
-- 2009/05/14 Ver1.5 add start by Yutaka.Kuboshima
--       AND    flva.lookup_code(+)       = xhdv.dpt6_old_cd
-- 2009/05/14 Ver1.5 add end by Yutaka.Kuboshima
-- 2009/10/08 Ver1.6 delete end by Shigeto.Niki
      ORDER BY
             xhdv.dpt6_cd ASC
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
    --==============================================================
    -- １．拠点情報を取得します
    --==============================================================
    -- CSV出力データ取得カーソルのオープン
    OPEN base_mst_cur;
    -- CSV出力データ取得の取得
    <<base_mst_loop>>
    LOOP
      FETCH base_mst_cur BULK COLLECT INTO gt_csv_out_tab;
      EXIT WHEN base_mst_cur%NOTFOUND;
    END LOOP base_mst_loop;
    -- CSV出力データ取得カーソルのクローズ
    CLOSE base_mst_cur;
    -- 件数を取得
    gn_target_cnt := gt_csv_out_tab.COUNT;
--
    --==============================================================
    -- ２．拠点情報取得件数が0件の場合、対象データ無し
    --==============================================================
    IF ( gn_target_cnt = 0 ) THEN
      -- 最上位層の部門数でエラーがあった場合、既に開いてるファイルを削除
      UTL_FILE.FREMOVE( location    => gv_csv_file_dir    -- 削除対象があるディレクトリ
                       ,filename    => gv_csv_file_name   -- 削除対象ファイル名
      );
      -- エラーメッセージを出力後、異常終了
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxcmm    -- マスタ
                     ,iv_name         => cv_msg_00001         -- エラー:対象データ無し
                   );
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_base_data;
--
  /**********************************************************************************
   * Procedure Name   : output_csv_data
   * Description      : 抽出情報出力(A-5)
   ***********************************************************************************/
  PROCEDURE output_csv_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv_data'; -- プログラム名
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
    cv_sep                CONSTANT VARCHAR2(1)   := ',';  -- 区切り文字
    cv_dqu                CONSTANT VARCHAR2(1)   := '"';  -- ダブルクォーテーション
    cv_datetime_fmt       CONSTANT VARCHAR2(16)  := 'YYYYMMDDHH24MISS'; -- 日時出力フォーマット①
    -- *** ローカル変数 ***
    ln_idx                NUMBER;          -- Loop時のカウント変数
    lv_out_val            VARCHAR2(255);   -- 出力内容(項目)
    lv_out_line           VARCHAR2(2400);  -- 出力内容(行)
    lv_base_code          hz_cust_accounts.account_number%TYPE;
                                           -- 拠点コード
-- 2009/10/08 Ver1.6 add start by Shigeto.Niki
    lv_head_code          VARCHAR2(6);     -- 最新本部コード
    lv_district_code      VARCHAR2(4);     -- 最新地区本部コード
    lv_district_name      VARCHAR2(16);    -- 最新地区本部名称    
-- 2009/10/08 Ver1.6 add end by Shigeto.Niki
    ld_sys_date           DATE;            -- 1レコード目出力時のシステム日付
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
    -- 取得した拠点マスタIFの情報を、CSVファイルへ出力
    --==============================================================
    <<output_csv_loop>>
    FOR ln_idx IN 1 .. gn_target_cnt LOOP
      BEGIN
        -- ■ 初期設定
        lv_base_code := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_cd, 1, 4);
        lv_out_val   := '';
        lv_out_line  := '';
--
        -- ■ システム日付を取得する。
        IF ln_idx = 1 THEN
          ld_sys_date := SYSDATE;
        END IF;
--
-- 2009/10/08 Ver1.6 add start by Shigeto.Niki
      -- ■ 最新地区本部コードおよび最新本部コードを取得する
      IF (gt_csv_out_tab(ln_idx).dpt6_start_date_active IS NULL) THEN
        lv_head_code     := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 6);
        lv_district_code := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 4);
      ELSIF (gt_csv_out_tab(ln_idx).dpt6_start_date_active <= gv_next_proc_date) THEN
        lv_head_code     := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_new_cd, 1, 6);
        lv_district_code := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_new_cd, 1, 4);
      ELSE
        lv_head_code     := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 6);
        lv_district_code := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 4);
      END IF;

      -- ■ 最新本部名称を取得する
      IF ( lv_head_code IS NOT NULL ) THEN
        BEGIN
        SELECT SUBSTRB(flv.meaning, 1, 16)
        INTO   lv_district_name
        FROM   fnd_lookup_values     flv
        WHERE  flv.lookup_type     = cv_lookup_area
          AND  flv.enabled_flag    = cv_y_flag
          AND  flv.language        = cv_language_ja
          AND  flv.lookup_code(+)  = lv_district_code
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            lv_district_name := '';
          WHEN OTHERS THEN
            RAISE global_api_others_expt;
        END;
      ELSE
        lv_district_name := '';
      END IF;
-- 2009/10/08 Ver1.6 add end by Shigeto.Niki
--
        -- ■ 出力データ作成
        -- 1.拠点（部門）コード
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_cd, 1, 4);
        lv_out_line := cv_dqu || lv_out_val || cv_dqu;
        -- 2.情報系用拠点名称１
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 3.情報系用拠点名称２
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 4.情報系用拠点名称３
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_name, 1, 20);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 5.情報系用拠点略称１
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 6.情報系用拠点略称２
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 7.情報系用拠点略称３
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_abbreviate, 1, 8);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 8.最新大本部コード
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        -- 9.最新大本部名称
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --10.最新本部コード(上位４桁)
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt3_cd, 1, 4);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --11.最新本部名称
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt3_name, 1, 12);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --12.最新地区本部コード
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
--         lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 4);
        lv_out_val  := lv_district_code;
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
        --13.最新地区本部名称
-- 2009/05/14 Ver1.5 modify start by Yutaka.Kuboshima
--        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).attribute4, 1, 16);
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
--        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).area_name, 1, 16);
        lv_out_val  := lv_district_name;
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
-- 2009/05/14 Ver1.5 modify end by Yutaka.Kuboshima
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --14.最新本部コード
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
--        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd ||
        lv_out_val  := lv_head_code;
-- 2009/05/14 Ver1.5 modify start by Yutaka.Kuboshima
--                            SUBSTRB(LPAD(gt_csv_out_tab(ln_idx).attribute6, 3, '0'), 2, 2), 1, 6);
--                         SUBSTRB(LPAD(gt_csv_out_tab(ln_idx).dpt6_sort_num, 3, '0'), 2, 2), 1, 6);
-- 2009/05/14 Ver1.5 modify end by Yutaka.Kuboshima
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
        --15.拠点名（正式名）
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_name, 1, 20);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --16.拠点名（略名）
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_abbreviate, 1, 8);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --17.拠点名（カナ）
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).customer_name_phonetic, 1, 10);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --18.拠点住所
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).address_line, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --19.郵便番号
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).zip, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --20.電話番号
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).phone, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --21.ＦＡＸ番号
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).fax, 1, 60);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
--         --22.旧本部コード(null)
        --22.旧本部コード
--         lv_out_val   := '';
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd, 1, 6);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
        --23.新本部コード
--         lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_old_cd ||
-- 2009/05/14 Ver1.5 modify start by Yutaka.Kuboshima
--                             SUBSTRB(LPAD(gt_csv_out_tab(ln_idx).attribute6, 3, '0'), 2, 2), 1, 6);
--                          SUBSTRB(LPAD(gt_csv_out_tab(ln_idx).dpt6_sort_num, 3, '0'), 2, 2), 1, 6);
-- 2009/05/14 Ver1.5 modify end by Yutaka.Kuboshima
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_new_cd, 1, 6);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
-- 2009/10/07 Ver1.6 modify start by Shigeto.Niki
--         --24.本部コード適用開始日(null)
        --24.本部コード適用開始日
--         lv_out_val   := '';
        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).dpt6_start_date_active, 1, 8);
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
-- 2009/10/07 Ver1.6 modify end by Shigeto.Niki
        --25.拠点実績有無区分(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --26.出庫管理元区分(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --27.地区名（本部コード用）
-- 2009/05/14 Ver1.5 modify start by Yutaka.Kuboshima
--        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).attribute4, 1, 16);
-- 2009/10/08 Ver1.6 modify start by Shigeto.Niki
--        lv_out_val  := SUBSTRB(gt_csv_out_tab(ln_idx).area_name, 1, 16);
        lv_out_val  := lv_district_name;
-- 2009/10/08 Ver1.6 modify end by Shigeto.Niki
-- 2009/05/14 Ver1.5 modify end by Yutaka.Kuboshima
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        --28.作成年月日時分秒日付
        lv_out_val  := TO_CHAR(gt_csv_out_tab(ln_idx).creation_date, cv_datetime_fmt);
-- 2009/02/27 UPD by M.Sano Start
--        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        lv_out_line := lv_out_line || cv_sep || lv_out_val;
-- 2009/02/27 UPD by M.Sano End
        --29.最終更新年月日時分秒
        lv_out_val  := TO_CHAR(ld_sys_date, cv_datetime_fmt);
-- 2009/02/27 UPD by M.Sano Start
--        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
        lv_out_line := lv_out_line || cv_sep || lv_out_val;
-- 2009/02/27 UPD by M.Sano End
        --30.予備(null)
        lv_out_val   := '';
        lv_out_line := lv_out_line || cv_sep || cv_dqu || lv_out_val || cv_dqu;
--
        -- ■ 出力データをcsvファイルに出力する。
        UTL_FILE.PUT_LINE(gf_file_handler, lv_out_line);
--
      EXCEPTION
        WHEN UTL_FILE.WRITE_ERROR THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name_xxcmm    -- マスタ
                         ,iv_name         => cv_msg_00009         -- エラー  :CSVデータ出力エラー
                         ,iv_token_name1  => cv_tok_ng_word       -- トークン:NG_WORD
                         ,iv_token_value1 => cv_tvl_base_code     -- 値      :拠点コード
                         ,iv_token_name2  => cv_tok_ng_data       -- トークン:NG_DATA
                         ,iv_token_value2 => lv_base_code         -- 値      :拠点コード(データ)
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      --成功件数を更新する。
      gn_normal_cnt := gn_normal_cnt + 1;
   END LOOP output_csv_loop;
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
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END output_csv_data;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf             OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode            OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg             OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル変数 ***
    lv_tok_value        VARCHAR2(100);  -- トークンに格納する値
    lv_out_msg          VARCHAR2(5000); -- 出力用
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
    gn_warn_cnt   := 0;
--
    -- ===============================================
    -- A-1.初期処理
    -- ===============================================
    init(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 入力パラメータなし出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90008
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- ファイル名出力
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_05132
                    ,iv_token_name1  => cv_tok_filename
                    ,iv_token_value1 => gv_csv_file_name
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_out_msg
    );
    -- 初期処理の実行結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-2．ファイルオープン処理(書込モード)
    -- ===============================================
    open_csv_file(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-3．最上位部門件数取得
    -- ===============================================
-- 2009/05/14 Ver1.5 delete start by Yutaka.Kuboshima
--    chk_count_top_dept(
--       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
--      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
--      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
--    );
--    -- 処理結果チェック
--    IF ( lv_retcode <> cv_status_normal ) THEN
--      -- ファイルが閉じられていない場合、ファイルを閉じる。
--      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
--        UTL_FILE.FCLOSE(gf_file_handler);
--      END IF;
--      -- 例外をスロー
--      RAISE global_process_expt;
--    END IF;
----
-- 2009/05/14 Ver1.5 delete end by Yutaka.Kuboshima
    -- ===============================================
    -- A-4．処理対象データ抽出
    -- ===============================================
    get_base_data(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ファイルが閉じられていない場合、ファイルを閉じる。
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
      -- 例外をスロー
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-5．抽出情報出力
    -- ===============================================
    output_csv_data(
       ov_errbuf           => lv_errbuf       -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode      -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- エラー件数を更新する。
    gn_error_cnt := gn_target_cnt - gn_normal_cnt;
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      -- ファイルが閉じられていない場合、ファイルを閉じる。
      IF ( UTL_FILE.IS_OPEN(gf_file_handler) ) THEN
        UTL_FILE.FCLOSE(gf_file_handler);
      END IF;
      -- 例外をスロー
      RAISE global_process_expt;
    END IF;
--
    -- ===============================================
    -- A-6．終了処理
    -- ===============================================
    UTL_FILE.FCLOSE(gf_file_handler);
--
  EXCEPTION
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- 2009/02/26 ADD by M.Sano Start
      ov_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name_xxccp    -- マスタ
                     ,iv_name         => cv_msg_91003         -- エラー:システムエラー
                   );
-- 2009/02/26 ADD by M.Sano End
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
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,        --   エラーメッセージ #固定#
    retcode               OUT    VARCHAR2)        --   エラーコード     #固定#
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
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf           VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode          VARCHAR2(1);     -- リターン・コード
    lv_errmsg           VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code     VARCHAR2(100);   -- 終了メッセージコード
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
       ov_errbuf           => lv_errbuf             -- エラー・メッセージ           --# 固定 #
      ,ov_retcode          => lv_retcode            -- リターン・コード             --# 固定 #
      ,ov_errmsg           => lv_errmsg             -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ===============================================
    -- エラーメッセージの出力
    -- ===============================================
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
      -- エラー発生し、かつ、エラー件数:0の場合、各件数は以下に統一して出力する
      if ( gn_error_cnt = 0 ) THEN
        gn_target_cnt := 0;
        gn_normal_cnt := 0;
        gn_error_cnt  := 1;
      END IF;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================================
    -- 件数の出力
    -- ===============================================
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90000
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90001
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name_xxccp
                    ,iv_name         => cv_msg_90002
                    ,iv_token_name1  => cv_tok_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    -- ===============================================
    --終了メッセージ
    -- ===============================================
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
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
END XXCMM005A05C;
/
