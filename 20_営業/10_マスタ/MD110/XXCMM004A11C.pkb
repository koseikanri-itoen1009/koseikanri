CREATE OR REPLACE PACKAGE BODY      XXCMM004A11C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A11C(body)
 * Description      : 品目マスタIF出力（情報系）
 * MD.050           : 品目マスタIF出力（情報系） CMM_004_A11
 * Version          : Draft2D
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  proc_init            初期処理(A-1)
 *
 *  submain              メイン処理プロシージャ
 *                          ・proc_init
 *                       品目情報の取得(A-2)
 *                       品目マスタ（情報系）出力処理(A-3)
 *
 *  main                 コンカレント実行ファイル登録プロシージャ
 *                          ・submain
 *                       終了処理(A-4)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/26    1.0   R.Takigawa       main新規作成
 *  2009/01/27          H.Yoshikawa      単体テスト実施前修正
 *  2009/01/29    1.1   H.Yoshikawa      単体テスト不具合修正
 *                                       1.エラーメッセージ出力を修正(ステップNo．1-4)
 *                                       2.日付書式の書式設定方法を修正(ステップNo．1-9)
 *                                       3.対象データ無し時エラー終了するよう修正(ステップNo．1-10)
 *                                       4.エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
 *                                       5.取得するLOOKUP_TYPE名を修正
 *                                       6.本社商品区分が取得できない場合の処理（9を設定）を削除(ステップNo．2-3)
 *                                       7.標準原価の取得処理を修正(ステップNo．2-7)
 *                                       8.営業原価(新)と営業原価(旧)の出力列を修正(ステップNo．3-1)
 *  2009/01/30    1.2   H.Yoshikawa      単体テスト不具合修正
 *                                       Q&A回答対応 親品目が設定されていない品目を抽出対象とするよう修正(ステップNo．3-1)
 *  2009/02/16    1.3   K.Ito            OUTBOUND用CSVファイル作成場所、ファイル名共通化
 *                                       ファイル名を出力するように修正
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
  cv_pkg_name                    CONSTANT VARCHAR2(30)  := 'XXCMM004A11C';       -- パッケージ名
--
-- Ver1.3 Mod 20090216 START
  cv_appl_name_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- アプリケーション短縮名
--  cv_app_name_xxcmm             CONSTANT VARCHAR2(5)   := 'XXCMM';              -- アプリケーション短縮名
-- Ver1.3 Mod 20090216 END
  -- メッセージ
  cv_msg_xxcmm_00001             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00001';   -- 対象データなし
  cv_msg_xxcmm_00002             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';   -- プロファイル取得エラー
--
-- Ver1.3 Add 20090216
  cv_msg_xxcmm_00022             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';   -- CSVファイル名ノート
--
  cv_msg_xxcmm_00484             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00484';   -- CSVファイル存在エラー
  cv_msg_xxcmm_00487             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00487';   -- ファイルオープンエラー
  cv_msg_xxcmm_00488             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00488';   -- ファイル書き込みエラー
  cv_msg_xxcmm_00489             CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00489';   -- ファイルクローズエラー

  -- トークン
  cv_tkn_profile                 CONSTANT VARCHAR2(10)  := 'NG_PROFILE';         -- トークン：プロファイル名
  cv_tkn_sqlerrm                 CONSTANT VARCHAR2(10)  := 'SQLERRM';            -- トークン：SQLエラー
-- Ver1.3 Add 20090216
  cv_tkn_file_name               CONSTANT VARCHAR2(10)  := 'FILE_NAME';          -- トークン：SQLエラー
  --
-- Ver1.1 Mod 2009/01/28 日付書式の書式設定方法を修正(ステップNo．1-9)
--  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_ymd;
--                                                                                 -- YYYYMMDD
  cv_date_fmt_ymd                CONSTANT VARCHAR2(10)  := 'RRRRMMDD';           -- YYYYMMDD
-- End
  cv_date_fmt_dt_ymdhms          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_date_fmt_dt_ymdhms;
                                                                                 -- YYYYMMDDHH24MISS
  --
-- Ver1.3 Mod 20090216
  cv_csv_fl_name                 CONSTANT VARCHAR2(30)  := 'XXCMM1_004A11_OUT_FILE';
--  cv_csv_fl_name                 CONSTANT VARCHAR2(30)  := 'XXCMM1_004A11_CSV_FILE_FIL';
                                                                                 -- 品目マスタ（情報系）連携用CSVファイル名
-- Ver1.3 Mod 20090216
  cv_csv_fl_dir                  CONSTANT VARCHAR2(30)  := 'XXCMM1_JYOHO_OUT_DIR';
--  cv_csv_fl_dir                  CONSTANT VARCHAR2(30)  := 'XXCMM1_004A11_CSV_FILE_DIR';
                                                                                 -- 品目マスタ（情報系）連携用CSVファイル出力先
  cv_user_csv_fl_name            CONSTANT VARCHAR2(100) := '品目マスタ（情報系）連携用CSVファイル名';
                                                                                 -- 品目マスタ（情報系）連携用CSVファイル名
  cv_user_csv_fl_dir             CONSTANT VARCHAR2(100) := '品目マスタ（情報系）連携用CSVファイル出力先';
                                                                                 -- 品目マスタ（情報系）連携用CSVファイル出力先
  cv_dqu                         CONSTANT VARCHAR2(1)   := '"';
  cv_sep                         CONSTANT VARCHAR2(1)   := ',';
-- Ver1.1 Mod 2009/01/28 Start 取得するLOOKUP_TYPE名を修正
--  cv_lookup_cost_cmpt            CONSTANT VARCHAR2(15)  := 'XXCMM_COST_CMPT';    -- 参照タイプ
  cv_lookup_cost_cmpt            CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';    -- 参照タイプ
-- Ver1.1 Mod 2009/01/28 End
  cv_enbld_flag                  CONSTANT VARCHAR2(1)   := 'Y';                  -- 使用可能
--
  cv_co_code                     CONSTANT VARCHAR2(4)   := 'ITOE';               -- 会社
  cv_whse_code                   CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                                 -- 倉庫
  cv_cost_mthd_code              CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                                 -- 原価方法
  cv_cost_analysis_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                                 -- 分析コード
  --
  cv_company_code                CONSTANT VARCHAR2(3)   := '001';                -- 会社コード
  cn_cost_level                  CONSTANT NUMBER(1)     := 0;                    -- コストレベル
  cv_categ_set_hon_prod          CONSTANT VARCHAR2(20)  := xxcmm_004common_pkg.cv_categ_set_hon_prod;
                                                                                 -- 本社商品区分
  cv_csv_mode                    CONSTANT VARCHAR2(1)   := 'w';                  -- csvファイルオープン時のモード
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 品目マスタIF出力（情報系）レイアウト
  TYPE xxcmm004a11c_rtype IS RECORD
  (
    -- 会社コード                        文字型(3)
     company_code               VARCHAR2(3)                                     -- 
    -- 品目コード                        文字型(7)
    ,item_code                  ic_item_mst_b.item_no%TYPE                      -- VARCHAR2(32)
    -- カナ名                            文字型(30)
    ,item_name_alt              xxcmn_item_mst_b.item_name_alt%TYPE             -- VARCHAR2(30)
    -- 正式名                            文字型(60)
    ,item_name                  xxcmn_item_mst_b.item_name%TYPE                 -- VARCHAR2(60)
    -- JANコード                         文字型(13)
    ,jan_code                   VARCHAR2(240)                                   -- VARCHAR2(240)
    -- ケースJANコード                   文字型(13)
    ,case_jan_code              xxcmm_system_items_b.case_jan_code%TYPE         -- VARCHAR2(13)
    -- ITFコード                         文字型(16)
    ,itf_code                   VARCHAR2(240)                                   -- VARCHAR2(240)
    -- 定価（新）                        数値型(7)
    ,price_new                  VARCHAR2(240)                                   -- VARCHAR2(240)
    -- 標準原価                          数値型(7,2)
    ,standard_cost              cm_cmpt_dtl.cmpnt_cost%TYPE                     -- NUMBER
    -- 営業原価（旧）                    数値型(7)
    ,opt_cost_old               VARCHAR2(240)                                   -- VARCHAR2(240)
    -- 営業原価（新）                    数値型(7)
    ,opt_cost_new               VARCHAR2(240)                                   -- VARCHAR2(240)
    -- 営業原価変更適用日【YYYYMMDD】    文字型(8)
    ,opt_cost_apply_date        VARCHAR2(240)                                   -- VARCHAR2(240)
    -- 発売開始日【YYYYMMDD】            文字型(8)
    ,sell_start_date            VARCHAR2(240)                                   -- VARCHAR2(240)
    -- 配数                              数値型(2)
    ,palette_max_cs_qty         xxcmn_item_mst_b.palette_max_cs_qty%TYPE        -- NUMBER(2,0)
    -- パレット当り最大段数              数値型(2)
    ,palette_max_step_qty       xxcmn_item_mst_b.palette_max_step_qty%TYPE      -- NUMBER(2,0)
    -- パレット段                        数値型(2)
    ,palette_step_qty           xxcmn_item_mst_b.palette_step_qty%TYPE          -- NUMBER(2,0)
    -- ケース入数                        数値型(5)
    ,num_of_cases               VARCHAR2(240)                                   -- VARCHAR2(240)
    -- ボール入数                        数値型(5)
    ,bowl_inc_num               xxcmm_system_items_b.bowl_inc_num%TYPE          -- NUMBER(5,0)
    -- 群コード（新）                    文字型(4)
    ,crowd_code_new             VARCHAR2(240)                                   -- VARCHAR2(240)
    -- ドリンク・リーフ区分              文字型(1)
    ,item_div                   mtl_categories.segment1%TYPE                    -- VARCHAR2(40)
    -- 経理群                            文字型(4)
    ,acnt_group                 xxcmm_system_items_b.acnt_group%TYPE            -- VARCHAR2(4)
    -- 容器群                            文字型(4)
    ,vessel_group               xxcmm_system_items_b.vessel_group%TYPE          -- VARCHAR2(4)
    -- 親商品コード                      文字型(7)
    ,parent_item_code           ic_item_mst_b.item_no%TYPE                      -- VARCHAR2(32)
    -- リニューアル元商品コード          文字型(7)
    ,renewal_item_code          xxcmm_system_items_b.renewal_item_code%TYPE     -- VARCHAR2(40)
    -- 略称                              文字型(20)
--    ,item_short_name            xxcmm_opmmtl_items_v.item_short_name%TYPE       --
    ,item_short_name            xxcmn_item_mst_b.item_short_name%TYPE           -- VARCHAR2(20)
    -- 連携日時【YYYYMMDDHH24MISS】      文字型(14)
    ,trans_date                 VARCHAR2(14)                                    -- 
  );
--
  -- 品目マスタIF出力（情報系）レイアウト テーブルタイプ
  TYPE xxcmm004a11c_ttype IS TABLE OF xxcmm004a11c_rtype INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gd_process_date                DATE;                                          -- 業務日付
  gv_trans_date                  VARCHAR2(14);                                  -- 連携日付
  gv_csv_file_dir                VARCHAR2(1000);                                -- 品目マスタ（情報系）連携用CSVファイル出力先の取得
  gv_file_name                   VARCHAR2(30);                                  -- 品目マスタ（情報系）連携用CSVファイル名
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
-- Ver1.3 Add 20090216
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
    -- 業務日付の取得
    lv_step := 'A-1.1';
    lv_message_token := '業務日付の取得';
    gd_process_date  := TRUNC( xxccp_common_pkg2.get_process_date );
    --
    -- 連携日時の取得
    lv_step := 'A-1.1';
    lv_message_token := '連携日時の取得';
    gv_trans_date    := TO_CHAR( SYSDATE, cv_date_fmt_dt_ymdhms );
    --
    -- プロファイル取得
    lv_step := 'A-1.2';
    lv_message_token := '連携用CSVファイル名の取得';
    -- 品目マスタ（情報系）連携用CSVファイル名の取得
    gv_file_name := FND_PROFILE.VALUE( cv_csv_fl_name );
    -- 取得エラー時
    IF ( gv_file_name IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_name;
      RAISE profile_expt;
    END IF;
    --
-- Ver1.3 Mod 20090216 START
    lv_csv_file := xxccp_common_pkg.get_msg(                                    -- アップロード名称の出力
                    iv_application  => cv_appl_name_xxcmm                       -- アプリケーション短縮名
                   ,iv_name         => cv_msg_xxcmm_00022                       -- メッセージコード
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
-- Ver1.3 Mod 20090216 END
    --
    lv_step := 'A-1.2';
    lv_message_token := '連携用CSVファイル出力先の取得';
    -- 品目マスタ（情報系）連携用CSVファイル出力先の取得
    gv_csv_file_dir := FND_PROFILE.VALUE( cv_csv_fl_dir );
    -- 取得エラー時
    IF ( gv_csv_file_dir IS NULL ) THEN
      lv_message_token := cv_user_csv_fl_dir;
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
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00002            -- メッセージ：APP-XXCMM1-00002 プロファイル取得エラー
                     ,iv_token_name1  => cv_tkn_profile                -- トークン：NG_PROFILE
                     ,iv_token_value1 => lv_message_token              -- プロファイル名
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** CSVファイル存在エラー ***
    WHEN csv_file_exst_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00484            -- メッセージ：APP-XXCMM1-00484 CSVファイル存在エラー
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
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
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
    lv_sqlerrm                VARCHAR2(5000);                                 -- SQLERRM退避
-- End
    lf_file_hand              UTL_FILE.FILE_TYPE;                             -- ファイル・ハンドルの宣言
    lv_message_token          VARCHAR2(100);                                  -- 連携日付
    ln_data_index             NUMBER;                                         -- データ用索引
    lv_parent_item_code       ic_item_mst_b.item_no%TYPE;                     -- 親商品コード
    lv_item_div               VARCHAR2(1);                                    -- ドリンク・リーフ区分
-- Ver1.1 Mod 2009/01/28 標準原価の取得処理を修正(ステップNo．2-7)
--    ln_standard_cost          NUMBER(9,2);                                    -- 標準原価
    lv_standard_cost          VARCHAR2(20);                                   -- 標準原価
-- End
    lv_out_csv_line           VARCHAR2(1000);                                 -- 出力行
    --
    -- 品目マスタ（情報系）情報カーソル
    --lv_step := 'A-2.1a';
    CURSOR csv_item_cur
    IS
      SELECT      xoiv.item_id                                                -- OPM品目ID
                 ,xoiv.item_no                                                -- 品目コード
                 ,xoiv.jan_code                                               -- JANコード
                 ,xoiv.itf_code                                               -- ITFコード
                 ,xoiv.num_of_cases                                           -- ケース入数
                 ,xoiv.bowl_inc_num                                           -- ボール入数
                 ,xoiv.price_new                                              -- 定価（新）
                 ,xoiv.opt_cost_old                                           -- 営業原価（旧）
                 ,xoiv.opt_cost_new                                           -- 営業原価（新）
-- Ver1.1 Mod 2009/01/28 日付書式の書式設定方法を修正(ステップNo．1-9)
--                 ,TO_CHAR( fnd_date.canonical_to_date( xoiv.opt_cost_apply_date ), cv_date_fmt_ymd )
--                                      AS opt_cost_apply_date                  -- 営業原価変更適用日
                 ,TO_CHAR( xoiv.opt_cost_apply_date, cv_date_fmt_ymd )
                                      AS opt_cost_apply_date                  -- 営業原価変更適用日
-- End
                 ,xoiv.crowd_code_new                                         -- 群コード（新）
-- Ver1.1 Mod 2009/01/28 日付書式の書式設定方法を修正(ステップNo．1-9)
--                 ,TO_CHAR( fnd_date.canonical_to_date( xoiv.sell_start_date ), cv_date_fmt_ymd )
--                                      AS sell_start_date                      -- 発売開始日
                 ,TO_CHAR( xoiv.sell_start_date, cv_date_fmt_ymd )
                                      AS sell_start_date                      -- 発売開始日
-- End
                 ,xoiv.item_name                                              -- 正式名
                 ,xoiv.item_name_alt                                          -- カナ名
                 ,xoiv.item_short_name                                        -- 略称
                 ,xoiv.parent_item_id                                         -- 親品目ID
                 ,xoiv.palette_max_cs_qty                                     -- 配数
                 ,xoiv.palette_max_step_qty                                   -- パレット当り最大段数
                 ,xoiv.palette_step_qty                                       -- パレット段
                 ,xoiv.case_jan_code                                          -- ケースJANコード
                 ,xoiv.renewal_item_code                                      -- リニューアル元商品コード
                 ,xoiv.acnt_group                                             -- 経理群
                 ,xoiv.vessel_group                                           -- 容器群
                 ,iimb.item_no        AS parent_item_code                     -- 親商品コード
      FROM        xxcmm_opmmtl_items_v    xoiv                                -- 品目ビュー
                 ,ic_item_mst_b           iimb                                -- OPM品目（親商品コード取得用）
-- Ver1.2 Mod 2009/01/30 親品目が設定されていない品目を抽出対象とするよう修正(ステップNo．3-1)
--      WHERE       iimb.item_id            = xoiv.parent_item_id               -- 親商品コード
      WHERE       iimb.item_id(+)         = xoiv.parent_item_id               -- 親商品コード
-- End
      AND         xoiv.start_date_active <= gd_process_date                   -- 適用開始日
      AND         xoiv.end_date_active   >= gd_process_date                   -- 適用終了日
      ORDER BY    xoiv.item_no;
    --
    lt_csv_item_tab                     xxcmm004a11c_ttype;                   -- 商品IF出力データ
    --
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
    chk_param_err_expt        EXCEPTION;       -- パラメータチェックエラー
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
    -- A-2.品目情報の取得
    -----------------------------------
    lv_step := 'A-2.1b';
    ln_data_index := 0;
    --
    <<csv_item_loop>>
    FOR l_csv_item_rec IN csv_item_cur LOOP
      --
      ln_data_index := ln_data_index + 1;
      --
      BEGIN
        lv_step := 'A-2.3';
        lv_message_token := 'ドリンク・リーフ区分の取得';
        -- ドリンク・リーフ区分の取得
        SELECT      mc.segment1  AS item_div                           -- ドリンク・リーフ区分
        INTO        lv_item_div                                        -- ドリンク・リーフ区分
        FROM        gmi_item_categories     gic                        -- ドリンク・リーフ区分
                   ,mtl_categories          mc                         -- ドリンク・リーフ区分
                   ,mtl_category_sets       mcs                        -- ドリンク・リーフ区分
        WHERE       mcs.category_set_name   = cv_categ_set_hon_prod    -- ドリンク・リーフ区分
        AND         gic.item_id             = l_csv_item_rec.item_id   -- 品目
        AND         gic.category_set_id     = mcs.category_set_id      -- カテゴリセットID
        AND         gic.category_id         = mc.category_id;          -- カテゴリID
      EXCEPTION
        WHEN OTHERS THEN
-- Ver1.1 Mod 2009/01/28 本社商品区分が取得できない場合の値設定を削除(ステップNo．2-3)
--          lv_item_div := '9';
          lv_item_div := '';
-- End
      END;
      --
      --
      lv_step := 'A-2.4';
      lv_message_token := '標準原価の取得';
      -- 標準原価の取得
-- Ver1.1 Mod 2009/01/28 標準原価の取得処理を修正(ステップNo．2-7)
--      SELECT      SUM( NVL( ccmd.cmpnt_cost, 0 ) )
--      INTO        ln_standard_cost
      SELECT      TO_CHAR( TRUNC( SUM( NVL( ccmd.cmpnt_cost, 0 )), 2 ))
                                                      -- 標準原価
      INTO        lv_standard_cost
-- End
      FROM        cm_cmpt_dtl          ccmd           -- OPM標準原価
                 ,cm_cldr_dtl          cclr           -- OPM原価カレンダ
                 ,cm_cmpt_mst_vl       ccmv           -- 原価コンポーネント
                 ,fnd_lookup_values_vl flv            -- 参照コード値
      WHERE       ccmd.item_id             = l_csv_item_rec.item_id     -- 品目ID
      AND         cclr.start_date         <= gd_process_date            -- 開始日(翌営業日じゃないの？)
      AND         cclr.end_date           >= gd_process_date            -- 終了日(翌営業日じゃないの？)
      AND         flv.lookup_type          = cv_lookup_cost_cmpt        -- 参照タイプ
      AND         flv.enabled_flag         = cv_enbld_flag              -- 使用可能
      AND         ccmv.cost_cmpntcls_code  = flv.meaning                -- 原価コンポーネントコード
      AND         ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- 原価コンポーネントID
      AND         ccmd.calendar_code       = cclr.calendar_code         -- カレンダコード
      AND         ccmd.period_code         = cclr.period_code           -- 期間コード
      AND         ccmd.whse_code           = cv_whse_code               -- 倉庫
      AND         ccmd.cost_mthd_code      = cv_cost_mthd_code          -- 原価方法
      AND         ccmd.cost_analysis_code  = cv_cost_analysis_code;     -- 分析コード
      --
      -- 配列に設定
      lv_step := 'A-2.company_code';
      lv_message_token := '会社コード';
      lt_csv_item_tab( ln_data_index ).company_code         := cv_company_code;
      lv_step := 'A-2.item_code';
      lv_message_token := '品目コード';
      lt_csv_item_tab( ln_data_index ).item_code            := SUBSTRB( l_csv_item_rec.item_no, 1, 7 );
      lv_step := 'A-2.item_name_alt';
      lv_message_token := 'カナ名';
      lt_csv_item_tab( ln_data_index ).item_name_alt        := l_csv_item_rec.item_name_alt;
      lv_step := 'A-2.item_name';
      lv_message_token := '正式名';
      lt_csv_item_tab( ln_data_index ).item_name            := l_csv_item_rec.item_name;
      lv_step := 'A-2.jan_code';
      lv_message_token := 'JANコード';
      lt_csv_item_tab( ln_data_index ).jan_code             := SUBSTRB( l_csv_item_rec.jan_code, 1, 13 );
      lv_step := 'A-2.case_jan_code';
      lv_message_token := 'ケースJANコード';
      lt_csv_item_tab( ln_data_index ).case_jan_code        := l_csv_item_rec.case_jan_code;
      lv_step := 'A-2.itf_code';
      lv_message_token := 'ITFコード';
      lt_csv_item_tab( ln_data_index ).itf_code             := SUBSTRB( l_csv_item_rec.itf_code, 1, 16 );
      lv_step := 'A-2.price_new';
      lv_message_token := '定価（新）';
      lt_csv_item_tab( ln_data_index ).price_new            := TO_CHAR( l_csv_item_rec.price_new );
      lv_step := 'A-2.standard_cost';
-- Ver1.1 Mod 2009/01/28 標準原価の取得処理を修正(ステップNo．2-7)
      lv_message_token := '標準原価';
--      lt_csv_item_tab( ln_data_index ).standard_cost        := ln_standard_cost;
      lt_csv_item_tab( ln_data_index ).standard_cost        := lv_standard_cost;
-- End
-- Ver1.1 Mod 2009/01/28 営業原価(新)と営業原価(旧)の出力列を修正(ステップNo．3-1)
--      lv_step := 'A-2.opt_cost_old';
--      lv_message_token := '営業原価（旧）';
--      lt_csv_item_tab( ln_data_index ).opt_cost_old         := TO_CHAR( l_csv_item_rec.opt_cost_old );
--      lv_step := 'A-2.opt_cost_new';
--      lv_message_token := '営業原価（新）';
--      lt_csv_item_tab( ln_data_index ).opt_cost_new         := TO_CHAR( l_csv_item_rec.opt_cost_new );
--      lv_step := 'A-2.opt_cost_apply_date';
      lv_step := 'A-2.opt_cost_new';
      lt_csv_item_tab( ln_data_index ).opt_cost_new         := TO_CHAR( l_csv_item_rec.opt_cost_new );
      lv_step := 'A-2.opt_cost_old';
      lv_message_token := '営業原価（旧）';
      lt_csv_item_tab( ln_data_index ).opt_cost_old         := TO_CHAR( l_csv_item_rec.opt_cost_old );
-- End
      lv_message_token := '営業原価変更適用日';
      lt_csv_item_tab( ln_data_index ).opt_cost_apply_date  := l_csv_item_rec.opt_cost_apply_date;
      lv_step := 'A-2.sell_start_date';
      lv_message_token := '発売開始日';
      lt_csv_item_tab( ln_data_index ).sell_start_date      := l_csv_item_rec.sell_start_date;
      lv_step := 'A-2.palette_max_cs_qty';
      lv_message_token := '配数';
      lt_csv_item_tab( ln_data_index ).palette_max_cs_qty   := l_csv_item_rec.palette_max_cs_qty;
      lv_step := 'A-2.palette_max_step_qty';
      lv_message_token := 'パレット当り最大段数';
      lt_csv_item_tab( ln_data_index ).palette_max_step_qty := l_csv_item_rec.palette_max_step_qty;
      lv_step := 'A-2.palette_step_qty';
      lv_message_token := 'パレット段';
      lt_csv_item_tab( ln_data_index ).palette_step_qty     := l_csv_item_rec.palette_step_qty;
      lv_step := 'A-2.num_of_cases';
      lv_message_token := 'ケース入数';
      lt_csv_item_tab( ln_data_index ).num_of_cases         := TO_CHAR( l_csv_item_rec.num_of_cases );
      lv_step := 'A-2.bowl_inc_num';
      lv_message_token := 'ボール入数';
      lt_csv_item_tab( ln_data_index ).bowl_inc_num         := l_csv_item_rec.bowl_inc_num;
      lv_step := 'A-2.crowd_code_new';
      lv_message_token := '群コード（新）';
      lt_csv_item_tab( ln_data_index ).crowd_code_new       := SUBSTRB( l_csv_item_rec.crowd_code_new, 1, 4 );
      lv_step := 'A-2.item_div';
      lv_message_token := 'ドリンク・リーフ区分';
      lt_csv_item_tab( ln_data_index ).item_div             := lv_item_div;
      lv_step := 'A-2.acnt_group';
      lv_message_token := '経理群';
      lt_csv_item_tab( ln_data_index ).acnt_group           := l_csv_item_rec.acnt_group;
      lv_step := 'A-2.vessel_group';
      lv_message_token := '容器群';
      lt_csv_item_tab( ln_data_index ).vessel_group         := l_csv_item_rec.vessel_group;
      lv_step := 'A-2.parent_item_code';
      lv_message_token := '親商品コード';
      lt_csv_item_tab( ln_data_index ).parent_item_code     := SUBSTRB( l_csv_item_rec.parent_item_code, 1, 7 );
      lv_step := 'A-2.renewal_item_code';
      lv_message_token := 'リニューアル元商品コード';
      lt_csv_item_tab( ln_data_index ).renewal_item_code    := SUBSTRB( l_csv_item_rec.renewal_item_code, 1, 7 );
      lv_step := 'A-2.item_short_name';
      lv_message_token := '略称';
      lt_csv_item_tab( ln_data_index ).item_short_name      := l_csv_item_rec.item_short_name;
      lv_step := 'A-2.trans_date';
      lv_message_token := '連携日時';
      lt_csv_item_tab( ln_data_index ).trans_date           := gv_trans_date;
      --
    END LOOP csv_item_loop;
    --
    -----------------------------------------------
    -- A-3.品目マスタ（情報系）出力処理
    -----------------------------------------------
    lv_step := 'A-3.1a';
    IF ( ln_data_index = 0 ) THEN
      -- 対象データなし
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm
                     ,iv_name         => cv_msg_xxcmm_00001
                     );
-- Ver1.1 Mod 2009/01/28 対象データ無し時エラー終了するよう修正(ステップNo．1-10)
--      -- 出力表示
--      lv_step := 'A-3.1a';
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.OUTPUT
--        ,buff   => lv_errmsg
--      );
--      -- ログ出力
--      FND_FILE.PUT_LINE(
--         which  => FND_FILE.LOG
--        ,buff   => lv_errmsg
--      );
      ov_retcode := cv_status_error;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errmsg;
-- End
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
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
          lv_sqlerrm := SQLERRM;
-- End
          RAISE file_open_expt;
      END;
      -- ファイル出力
      lv_step := 'A-3.1b';
      <<out_csv_loop>>
      FOR ln_index IN 1..lt_csv_item_tab.COUNT LOOP
        --
        lv_out_csv_line := '';
        -- 会社コード
        lv_step := 'A-3.company_code';
        lv_out_csv_line := cv_dqu ||
                           lt_csv_item_tab( ln_index ).company_code ||
                           cv_dqu;
        -- 品目コード
        lv_step := 'A-3.item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_code ||
                           cv_dqu;
        -- カナ名
        lv_step := 'A-3.item_name_alt';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_name_alt ||
                           cv_dqu;
        -- 正式名
        lv_step := 'A-3.item_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_name ||
                           cv_dqu;
        -- JANコード
        lv_step := 'A-3.jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).jan_code ||
                           cv_dqu;
        -- ケースJANコード
        lv_step := 'A-3.case_jan_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).case_jan_code ||
                           cv_dqu;
        -- ITFコード
        lv_step := 'A-3.itf_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).itf_code ||
                           cv_dqu;
        -- 定価（新）
        lv_step := 'A-3.price_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).price_new;
-- Ver1.1 Mod 2009/01/28 標準原価の取得処理を修正(ステップNo．2-7)
        -- 標準原価
        lv_step := 'A-3.standard_cost';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           RTRIM( TO_CHAR( TRUNC( lt_csv_item_tab( ln_index ).standard_cost, 2 ), 'FM99990.99'), '.' );
        lv_out_csv_line := lv_out_csv_line || cv_sep || lt_csv_item_tab( ln_index ).standard_cost;
-- End
-- Ver1.1 Mod 2009/01/28 営業原価(新)と営業原価(旧)の出力列を修正(ステップNo．3-1)
--        -- 営業原価（旧）
--        lv_step := 'A-3.opt_cost_old';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           lt_csv_item_tab( ln_index ).opt_cost_old;
--        -- 営業原価（新）
--        lv_step := 'A-3.opt_cost_new';
--        lv_out_csv_line := lv_out_csv_line || cv_sep ||
--                           lt_csv_item_tab( ln_index ).opt_cost_new;
        -- 営業原価（新）
        lv_step := 'A-3.opt_cost_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).opt_cost_new;
        -- 営業原価（旧）
        lv_step := 'A-3.opt_cost_old';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).opt_cost_old;
-- End
        -- 営業原価変更適用日【YYYYMMDD】
        lv_step := 'A-3.opt_cost_apply_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).opt_cost_apply_date;
        -- 発売開始日【YYYYMMDD】
        lv_step := 'A-3.sell_start_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).sell_start_date;
        -- 配数
        lv_step := 'A-3.palette_max_cs_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).palette_max_cs_qty );
        -- パレット当り最大段数
        lv_step := 'A-3.palette_max_step_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).palette_max_step_qty );
        -- パレット段
        lv_step := 'A-3.palette_step_qty';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).palette_step_qty );
        -- ケース入数
        lv_step := 'A-3.num_of_cases';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).num_of_cases;
        -- ボール入数
        lv_step := 'A-3.bowl_inc_num';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           TO_CHAR( lt_csv_item_tab( ln_index ).bowl_inc_num );
        -- 群コード（新）
        lv_step := 'A-3.crowd_code_new';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).crowd_code_new ||
                           cv_dqu;
        -- ドリンク・リーフ区分
        lv_step := 'A-3.item_div';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_div ||
                           cv_dqu;
        -- 経理群
        lv_step := 'A-3.acnt_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).acnt_group ||
                           cv_dqu;
        -- 容器群
        lv_step := 'A-3.vessel_group';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).vessel_group ||
                           cv_dqu;
        -- 親商品コード
        lv_step := 'A-3.parent_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).parent_item_code ||
                           cv_dqu;
        -- リニューアル元商品コード
        lv_step := 'A-3.renewal_item_code';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).renewal_item_code ||
                           cv_dqu;
        -- 略称
        lv_step := 'A-3.item_short_name';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           cv_dqu ||
                           lt_csv_item_tab( ln_index ).item_short_name ||
                           cv_dqu;
        -- 連携日時【YYYYMMDDHH24MISS】
        lv_step := 'A-3.trans_date';
        lv_out_csv_line := lv_out_csv_line || cv_sep ||
                           lt_csv_item_tab( ln_index ).trans_date;
        --
        --=================
        -- CSVファイル出力
        --=================
        lv_step := 'A-3.1c';
        BEGIN
          UTL_FILE.PUT_LINE( lf_file_hand, lv_out_csv_line );
        EXCEPTION
          WHEN OTHERS THEN
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
            lv_sqlerrm := SQLERRM;
-- End
            RAISE file_output_expt;
        END;
        --
        -- 対象件数
        gn_target_cnt := gn_target_cnt + 1;
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
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
          lv_sqlerrm := SQLERRM;
-- End
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
                      iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00487             -- メッセージ：APP-XXCMM1-00487 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** ファイル書き込みエラー ***
    WHEN file_output_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00488             -- メッセージ：APP-XXCMM1-00488 ファイルオープンエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
      ov_retcode := cv_status_error;
    --*** ファイルクローズエラー ***
    WHEN file_close_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm             -- アプリケーション短縮名：XXCMM マスタ
                     ,iv_name         => cv_msg_xxcmm_00489             -- メッセージ：APP-XXCMM1-00489 ファイルクローズエラー
                     ,iv_token_name1  => cv_tkn_sqlerrm                 -- トークン：SQLERRM
-- Ver1.1 Add 2009/01/28 エラーメッセージのトークン値指定無しを修正(ステップNo．1-12)
                     ,iv_token_value1 => lv_sqlerrm                     -- 値：SQLERRM
-- End
                     );
      ov_errmsg  := lv_errmsg;
-- Ver1.1 Mod 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errmsg;
-- End
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
    cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';   -- 警告終了メッセージ
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
-- Ver1.1 Del 2009/01/28 エラーメッセージ出力を修正(ステップNo．1-4)
--    lv_errmsg := lv_errbuf;
-- End
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
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
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
END XXCMM004A11C;
/
