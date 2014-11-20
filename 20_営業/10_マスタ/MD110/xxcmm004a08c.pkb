CREATE OR REPLACE PACKAGE BODY xxcmm004a08c
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A08C(body)
 * Description      : EBS(ファイルアップロードIF)に取込まれた標準原価データを
 *                  : OPM標準原価テーブルに反映します。
 * MD.050           : 標準原価一括改定    MD050_CMM_004_A08
 * Version          : Draft2B
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              初期処理 (A-1)
 *  get_if_data            ファイルアップロードIFデータ取得 (A-2)
 *  loop_main              標準原価一括改定ワークの取得 (A-3)
 *                            ・validate_item
 *                            ・proc_opm_cost_ref
 *  validate_item          データ妥当性チェック (A-4)
 *  proc_opm_cost_ref      OPM標準原価反映
 *                         標準原価改定対象データの抽出 (A-5)
 *                         OPM標準原価反映 (A-6)
 *  proc_comp              終了処理 (A-7)
 *
 *  submain                メイン処理プロシージャ
 *                            ・proc_init  
 *                            ・get_if_data
 *                            ・loop_main
 *                            ・proc_comp
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/17    1.0   H.Yoshikawa      新規作成
 *  2009/01/27    1.0   N.Nishimura      BLOBデータ変換共通関数の戻り値ハンドリング
 *                                       適用日未登録年度のチェック
 *  2009/01/28    1.0   N.Nishimura      メッセージ、トークン追加
 *                                       OPM標準原価マスタへのロック処理
 *                                       親品目チェックのSELECT文に品目ステータス追加
 *                                       ファイルアップロード名称の取得 データ抽出エラー
 *  2009/01/29    1.0   N.Nishimura      IF文の外に出す（データ妥当性チェックのステータスを退避）
 *  2009/02/03    1.0   N.Nishimura      proc_init共通関数の例外処理メッセージ変更
 *  2009/02/03    1.1   N.Nishimura      ファイル内重複チェック修正
 *                                       OPM標準原価 ロック取得エラー修正
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;    -- 正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;      -- 警告:1
  cv_status_error            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;     -- 異常:2
  --WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;                    -- CREATED_BY
  cd_creation_date           CONSTANT DATE          := SYSDATE;                               -- CREATION_DATE
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;                    -- LAST_UPDATED_BY
  cd_last_update_date        CONSTANT DATE          := SYSDATE;                               -- LAST_UPDATE_DATE
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;                   -- LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;            -- REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;               -- PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;            -- PROGRAM_ID
  cd_program_update_date     CONSTANT DATE          := SYSDATE;                               -- PROGRAM_UPDATE_DATE
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                 VARCHAR2(2000);
  gv_sep_msg                 VARCHAR2(2000);
  gv_exec_user               VARCHAR2(100);
  gv_conc_name               VARCHAR2(30);
  gv_conc_status             VARCHAR2(30);
  gn_target_cnt              NUMBER;                -- 対象件数
  gn_normal_cnt              NUMBER;                -- 正常件数
  gn_error_cnt               NUMBER;                -- エラー件数
  gn_warn_cnt                NUMBER;                -- スキップ件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 共通関数例外 ***
  global_api_expt            EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt     EXCEPTION;
  --*** ロックエラー例外 ***
  global_check_lock_expt     EXCEPTION;
  --
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
--################################  固定部 END   ##################################
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_appl_name_xxcmm         CONSTANT VARCHAR2(10)  := 'XXCMM';              -- アドオン：共通・マスタ
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCMM004A08C';       -- パッケージ名
  cv_msg_comma               CONSTANT VARCHAR2(3)   := ',';                  -- カンマ
  --
  cv_yes                     CONSTANT VARCHAR2(1)   := 'Y';                  -- Y
  cv_no                      CONSTANT VARCHAR2(1)   := 'N';                  -- N
  --
  cv_upd_div_upd             CONSTANT VARCHAR2(1)   := 'U';                  -- 更新区分(U)
  --
  -- 標準原価
  cv_whse_code               CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                             -- 倉庫
  cv_cost_mthd_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                             -- 原価方法
  cv_cost_analysis_code      CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                             -- 分析コード
  --2009/02/03追加
  cv_date_fmt_std            CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                             -- 日付書式
  --
  --=========================================================================================================================================
  -- メッセージコード（コンカレント実行時）
  cv_msg_xxcmm_00021         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';   -- ファイルアップロード名称ノート
  cv_msg_xxcmm_00022         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';   -- CSVファイル名ノート
  cv_msg_xxcmm_00023         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';   -- FILE_IDノート
  cv_msg_xxcmm_00024         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';   -- フォーマットパターンノート
  --
  -- トークンコード
  cv_tkn_file_id             CONSTANT VARCHAR2(20)  := 'FILE_ID';            -- ファイルID
  cv_tkn_format              CONSTANT VARCHAR2(20)  := 'FORMAT';             -- フォーマット
  cv_tkn_file_name           CONSTANT VARCHAR2(20)  := 'FILE_NAME';          -- ファイル名
  cv_tkn_up_name             CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';        -- ファイルアップロード名称
  --=========================================================================================================================================
  --
  --エラーメッセージコード
  cv_msg_xxcmm_00002         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00002';   -- プロファイル取得エラー
  cv_msg_xxcmm_00008         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00008';   -- ロック取得エラー
  cv_msg_xxcmm_00028         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';   -- データ項目数エラー
  cv_msg_xxcmm_00440         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00440';   -- パラメータチェックエラー
  cv_msg_xxcmm_00455         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00455';   -- 起動種別エラー
  cv_msg_xxcmm_00456         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00456';   -- ファイル項目チェックエラー
  cv_msg_xxcmm_00457         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00457';   -- 適用日チェックエラー
  cv_msg_xxcmm_00458         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00458';   -- 親品目チェックエラー
  cv_msg_xxcmm_00459         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00459';   -- マスタチェックエラー
  cv_msg_xxcmm_00460         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00460';   -- 標準原価チェックエラー
  cv_msg_xxcmm_00463         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00463';   -- ファイル内重複エラー
  cv_msg_xxcmm_00464         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00464';   -- 重複エラー
  cv_msg_xxcmm_00466         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00466';   -- データ登録エラー
  cv_msg_xxcmm_00467         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00467';   -- データ更新エラー
  cv_msg_xxcmm_00468         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00468';   -- データ削除エラー
  cv_msg_xxcmm_00469         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00469';   -- 標準原価反映エラー
  --2009/01/28追加
  cv_msg_xxcmm_00482         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00482';   -- 適用日未登録年度エラー
  cv_msg_xxcmm_00483         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00483';   -- 品目ステータス対象外エラー
  cv_msg_xxcmm_00409         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00409';   -- データ抽出エラー
  --
  --警告メッセージコード
  cv_msg_xxcmm_00462         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00462';   -- 標準原価比較警告
  --
  --トークンコード
  cv_tkn_table               CONSTANT VARCHAR2(20)  := 'TABLE';              -- テーブル名
  cv_tkn_ng_table            CONSTANT VARCHAR2(20)  := 'NG_TABLE';           -- ロック取得エラーテーブル名
  cv_tkn_count               CONSTANT VARCHAR2(20)  := 'COUNT';              -- 項目数チェック件数
  cv_tkn_profile             CONSTANT VARCHAR2(20)  := 'NG_PROFILE';         -- プロファイル名
  cv_tkn_param_name          CONSTANT VARCHAR2(20)  := 'PARAM_NAME';         -- パラメータ名
  cv_tkn_input_col_name      CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';     -- 項目名称
  cv_tkn_cost_type           CONSTANT VARCHAR2(20)  := 'COST_TYPE ';         -- 原価タイプ
  cv_tkn_input_cost          CONSTANT VARCHAR2(20)  := 'INPUT_COST';         -- 入力原価(標準原価)
  cv_tkn_disc_cost           CONSTANT VARCHAR2(20)  := 'DISC_COST';          -- 営業原価
  cv_tkn_opm_cost            CONSTANT VARCHAR2(20)  := 'OPM_COST';           -- 標準原価
  cv_tkn_input_item          CONSTANT VARCHAR2(20)  := 'INPUT_ITEM';         -- 品目コード
  cv_tkn_input_apply_date    CONSTANT VARCHAR2(20)  := 'INPUT_APPLY_DATE';   -- 適用日
  cv_tkn_err_msg             CONSTANT VARCHAR2(20)  := 'ERR_MSG';            -- エラーメッセージ
  --
  cv_tkn_val_proc_name       CONSTANT VARCHAR2(30)  := '標準原価一括改定';
  cv_tkn_val_fmt_pattern     CONSTANT VARCHAR2(30)  := 'フォーマットパターン';
  cv_tkn_val_opm_cost        CONSTANT VARCHAR2(30)  := '標準原価';
  cv_tkn_val_file_ul_if      CONSTANT VARCHAR2(30)  := 'ファイルアップロードＩ／Ｆ';
  cv_tkn_val_wk_opm_cost     CONSTANT VARCHAR2(30)  := '標準原価一括改定ワーク';
  cv_tkn_val_cmpnt_cost      CONSTANT VARCHAR2(100) := '標準原価（原料、再製費、資材費、包装費、外注管理費、保管費、その他経費）';
  --
  cv_tkn_cm_cmpt_dtl         CONSTANT VARCHAR2(30)  := 'ＯＰＭ標準原価マスタ';
  cv_lookup_cost_cmpt        CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';   -- 標準原価コンポーネント
  --2009/01/28追加
  cv_tkn_errmsg              CONSTANT VARCHAR2(20)  := 'ERRMSG';             -- エラー内容
  cv_tkn_input_line_no       CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';      -- インタフェースの行番号
  cv_tkn_input_item_code     CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';    -- インタフェースの品名コード
  cv_table_flv               CONSTANT VARCHAR2(30)  := 'LOOKUP表';           -- FND_LOOKUP_VALUES_VL
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_def_info_rtype IS RECORD(
    meaning                  VARCHAR2(100)                                   -- 項目名
   ,attribute                VARCHAR2(100)                                   -- 項目属性
   ,essential                VARCHAR2(100)                                   -- 必須フラグ
   ,figures                  NUMBER                                          -- 項目の長さ(整数)
   ,decim                    NUMBER                                          -- 項目の長さ(小数)
  );
  --
  TYPE g_opm_cost_rtype IS RECORD(
    item_id                  ic_item_mst_b.item_id%TYPE                      -- 品目ID
   ,item_no                  ic_item_mst_b.item_no%TYPE                      -- 品目コード
   ,apply_date               xxcmm_system_items_b_hst.apply_date%TYPE        -- 適用日
   ,cmpntcost_01gen          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 原料
   ,cmpntcost_02sai          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 再製費
   ,cmpntcost_03szi          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 資材費
   ,cmpntcost_04hou          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 包装費
   ,cmpntcost_05gai          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 外注管理費
   ,cmpntcost_06hkn          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 保管費
   ,cmpntcost_07kei          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- その他経費
   ,cmpntcost_total          cm_cmpt_dtl.cmpnt_cost%TYPE                     -- 標準原価計
  );
  --
  TYPE g_def_info_ttype   IS TABLE OF g_def_info_rtype INDEX BY BINARY_INTEGER;
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(1000)   INDEX BY BINARY_INTEGER;
  --
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  --テーブル型変数の宣言
  g_def_info_tab             g_def_info_ttype;                               -- テーブル型変数の宣言
  gn_file_id                 NUMBER;                                         -- パラメータ格納用変数
  gn_item_num                NUMBER;                                         -- 年間計画データ項目数格納用
  gv_format                  VARCHAR2(100);                                  -- パラメータ格納用変数
  gd_process_date            DATE;                                           -- 業務日付
--
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : 終了処理 (A-7)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_COMP';          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    --
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    IF ( gn_error_cnt > 0 ) THEN
      --==============================================================
      --A-7.1 チェックエラー存在時(SAVEPOINT まで ROLLBACK)
      --==============================================================
      lv_step := 'A-7.1';
      -- SAVEPOINTまで ROLLBACK
      ROLLBACK TO XXCMM004A08C_savepoint;
      --
    ELSE
      --==============================================================
      --A-7.2 標準原価一括改定データ削除
      --==============================================================
      BEGIN
        lv_step := 'A-7.2';
        DELETE  FROM    xxcmm_wk_opmcost_batch_regist;
        --
      EXCEPTION
        -- *** データ削除例外ハンドラ ***
        WHEN OTHERS THEN
          --
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxcmm_00468          -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_table                -- トークンコード1
                         ,iv_token_value1  =>  cv_tkn_val_wk_opm_cost      -- トークン値1
                         ,iv_token_name2   =>  cv_tkn_err_msg              -- トークンコード2
                         ,iv_token_value2  =>  SQLERRM                     -- トークン値2
                        );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          ov_retcode := cv_status_error;
      END;
      --
    END IF;
    --
    --==============================================================
    --A-7.3 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      lv_step := 'A-7.3';
      DELETE  FROM    xxccp_mrp_file_ul_interface
      WHERE   file_id = gn_file_id;
      --
      COMMIT;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm            -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxcmm_00468            -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  =>  cv_tkn_val_file_ul_if         -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_err_msg                -- トークンコード2
                       ,iv_token_value2  =>  SQLERRM                       -- トークン値2
                      );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
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
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_comp;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_opm_cost_ref
   * Description      : OPM標準原価反映 (A-5、A-6)
   ***********************************************************************************/
  PROCEDURE proc_opm_cost_ref(
    i_opm_cost_rec    IN       g_opm_cost_rtype                                -- 標準原価改定データ
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_OPM_COST_REF';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 品目ステータス
    cn_itm_status_num_tmp      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;
                                                                           -- 仮採番
    cn_itm_status_pre_reg      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_pre_reg;
                                                                           -- 仮登録
    cn_itm_status_regist       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_regist;
                                                                           -- 本登録
    cn_itm_status_no_sch       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_sch;
                                                                           -- 廃
    cn_itm_status_trn_only     CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_trn_only;
                                                                           -- Ｄ’
    cn_itm_status_no_use       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                           -- Ｄ
    --
    -- コンポーネント区分
    cv_cost_cmpnt_01gen        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_01gen;
                                                                           -- 原料
    cv_cost_cmpnt_02sai        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_02sai;
                                                                           -- 再製費
    cv_cost_cmpnt_03szi        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_03szi;
                                                                           -- 資材費
    cv_cost_cmpnt_04hou        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_04hou;
                                                                           -- 包装費
    cv_cost_cmpnt_05gai        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_05gai;
                                                                           -- 外注管理費
    cv_cost_cmpnt_06hkn        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_06hkn;
                                                                           -- 保管費
    cv_cost_cmpnt_07kei        CONSTANT VARCHAR2(5)   := xxcmm_004common_pkg.cv_cost_cmpnt_07kei;
                                                                           -- その他経費
    --
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    --
    ln_cmp_cost_index          NUMBER;
    ln_cmpnt_cost              cm_cmpt_dtl.cmpnt_cost%TYPE;
    --
    -- *** カーソル ***
    -- 標準原価改定対象データ取得カーソル
    CURSOR opmcost_item_cur(
      p_item_id    NUMBER )
    IS
      -- 親品目抽出
      SELECT    xoiv.item_id
      FROM      xxcmm_opmmtl_items_v      xoiv                             -- 品目ビュー
      WHERE     xoiv.item_id            = p_item_id                        -- 品目ID
      AND       xoiv.parent_item_id     = xoiv.item_id                     -- 親品目であること
      AND       xoiv.start_date_active <= TRUNC( SYSDATE )                 -- 適用開始日
      AND       xoiv.end_date_active   >= TRUNC( SYSDATE )                 -- 適用終了日
-- 2009/01/16 Mod
      AND       NVL( xoiv.item_status, cn_itm_status_num_tmp )
                                       != cn_itm_status_no_use             -- Ｄ以外
--      AND       xoiv.item_status       IN ( cn_itm_status_num_tmp          -- 仮採番
--                                           ,cn_itm_status_pre_reg          -- 仮登録
--                                           ,cn_itm_status_regist           -- 本登録
--                                           ,cn_itm_status_no_sch           -- 廃
--                                           ,cn_itm_status_trn_only )       -- Ｄ’
-- End
      UNION ALL
      -- 子品目抽出
      SELECT    xoiv.item_id
      FROM      xxcmm_opmmtl_items_v      xoiv                             -- 品目ビュー
      WHERE     xoiv.parent_item_id     = p_item_id                        -- 親品目ID
      AND       xoiv.item_id           != xoiv.parent_item_id              -- 親品目でないこと
      AND       xoiv.start_date_active <= TRUNC( SYSDATE )                 -- 適用開始日
      AND       xoiv.end_date_active   >= TRUNC( SYSDATE )                 -- 適用終了日
      AND       xoiv.item_status       IN ( cn_itm_status_regist           -- 本登録
                                           ,cn_itm_status_no_sch           -- 廃
                                           ,cn_itm_status_trn_only );      -- Ｄ’
    --
    -- 標準原価コンポーネント取得カーソル
    CURSOR opmcost_cmpnt_cur(
      p_item_id     NUMBER
     ,p_apply_date  DATE )
    IS
      SELECT    ccmd.cmpntcost_id                                          -- 標準原価ID
               ,cmcr.calendar_code                                         -- カレンダコード
               ,cmcr.period_code                                           -- 期間コード
               ,cmcr.cost_cmpntcls_id                                      -- 原価コンポーネントID
               ,cmcr.cost_cmpntcls_code                                    -- 原価コンポーネントコード
      FROM      cm_cmpt_dtl          ccmd,                                 -- OPM標準原価
              ( SELECT    cclr.calendar_code                               -- カレンダコード
                         ,cclr.period_code                                 -- 期間コード
                         ,ccmv.cost_cmpntcls_id                            -- 原価コンポーネントID
                         ,ccmv.cost_cmpntcls_code                          -- 原価コンポーネントコード
                FROM      cm_cldr_dtl          cclr,                       -- OPM原価カレンダ
                          cm_cmpt_mst_vl       ccmv,                       -- 原価コンポーネント
                          fnd_lookup_values_vl flv                         -- 参照コード値
                WHERE     flv.lookup_type          = cv_lookup_cost_cmpt   -- 参照タイプ
                AND       flv.enabled_flag         = cv_yes                -- 使用可能
                AND       ccmv.cost_cmpntcls_code  = flv.meaning           -- 原価コンポーネントコード
                AND       cclr.start_date         <= p_apply_date          -- 開始日
                AND       cclr.end_date           >= p_apply_date )  cmcr  -- 終了日
      WHERE     ccmd.item_id(+)            = p_item_id                     -- 品目
      AND       ccmd.cost_cmpntcls_id(+)   = cmcr.cost_cmpntcls_id         -- 原価コンポーネントID
      AND       ccmd.calendar_code(+)      = cmcr.calendar_code            -- カレンダコード
      AND       ccmd.period_code(+)        = cmcr.period_code              -- 期間コード
      AND       ccmd.whse_code(+)          = cv_whse_code                  -- 倉庫
      AND       ccmd.cost_mthd_code(+)     = cv_cost_mthd_code             -- 原価方法
      AND       ccmd.cost_analysis_code(+) = cv_cost_analysis_code         -- 分析コード
      ORDER BY  cmcr.cost_cmpntcls_code
      FOR UPDATE OF ccmd.cmpntcost_id NOWAIT;                              -- ロック処理追加 2009/01/28
    --
    -- OPM標準原価用
    l_opm_cost_header_rec           xxcmm_004common_pkg.opm_cost_header_rtype;
    l_opm_cost_dist_tab             xxcmm_004common_pkg.opm_cost_dist_ttype;
    --
    --2009/02/04 追加
    proc_opmcost_ref_expt  EXCEPTION;
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
    --A-5 品目変更履歴アドオン登録・更新判定
    --==============================================================
    -- OPM標準原価反映処理LOOP
    <<opmcost_loop>>
    FOR l_opmcost_item_rec IN opmcost_item_cur( i_opm_cost_rec.item_id ) LOOP
    --==============================================================
    --A-6 OPM標準原価反映
    --==============================================================
      --==============================================================
      --A-6.1 標準原価登録対象情報の取得
      --==============================================================
      ln_cmp_cost_index := 0;
      <<cmpnt_loop>>
      FOR l_opmcost_cmpnt_rec IN opmcost_cmpnt_cur( l_opmcost_item_rec.item_id
                                                   ,i_opm_cost_rec.apply_date ) LOOP
        --
        -- 原価の取得
        CASE l_opmcost_cmpnt_rec.cost_cmpntcls_code 
          WHEN cv_cost_cmpnt_01gen THEN    -- '01GEN'
            -- 原料
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_01gen;
          WHEN cv_cost_cmpnt_02sai THEN    -- '02SAI'
            -- 再製費
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_02sai;
          WHEN cv_cost_cmpnt_03szi THEN    -- '03SZI'
            -- 資材費
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_03szi;
          WHEN cv_cost_cmpnt_04hou THEN    -- '04HOU'
            -- 包装費
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_04hou;
          WHEN cv_cost_cmpnt_05gai THEN    -- '05GAI'
            -- 外注管理費
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_05gai;
          WHEN cv_cost_cmpnt_06hkn THEN    -- '06HKN'
            -- 保管費
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_06hkn;
          WHEN cv_cost_cmpnt_07kei THEN    -- '07KEI'
            -- その他経費
            ln_cmpnt_cost := i_opm_cost_rec.cmpntcost_07kei;
        END CASE;
        --
        -- 原価設定判断
        IF ( ln_cmpnt_cost IS NOT NULL ) THEN
          --
          -- OPM標準原価ヘッダパラメータ設定
          IF ( ln_cmp_cost_index = 0 ) THEN
            -- カレンダコード
            l_opm_cost_header_rec.calendar_code     := l_opmcost_cmpnt_rec.calendar_code;
            -- 期間コード
            l_opm_cost_header_rec.period_code       := l_opmcost_cmpnt_rec.period_code;
            -- 品目ID
            l_opm_cost_header_rec.item_id           := l_opmcost_item_rec.item_id;
          END IF;
          --
          -- 原価登録・更新判断
          IF ( l_opmcost_cmpnt_rec.cmpntcost_id IS NULL ) THEN 
            --==============================================================
            --A-6.2 標準原価登録時
            --==============================================================
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            -- 原価明細
            -- 標準原価ID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := NULL;
            -- 原価コンポーネントID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_opmcost_cmpnt_rec.cost_cmpntcls_id;
            -- 原価
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := ln_cmpnt_cost;
            --
          ELSE
            --==============================================================
            --A-6.3 標準原価更新時
            --==============================================================
            ln_cmp_cost_index := ln_cmp_cost_index + 1;
            -- 原価明細
            -- 標準原価ID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpntcost_id     := l_opmcost_cmpnt_rec.cmpntcost_id;
            -- 原価コンポーネントID
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cost_cmpntcls_id := l_opmcost_cmpnt_rec.cost_cmpntcls_id;
            -- 原価
            l_opm_cost_dist_tab( ln_cmp_cost_index ).cmpnt_cost       := ln_cmpnt_cost;
            --
          END IF;
          --
        END IF;
        --
      END LOOP cmpnt_loop;
      --
      --==============================================================
      --A-6.4 標準原価反映API
      --==============================================================
      -- 標準原価登録
      xxcmm_004common_pkg.proc_opmcost_ref(
        i_cost_header_rec  =>  l_opm_cost_header_rec  -- 原価ヘッダレコードタイプ
       ,i_cost_dist_tab    =>  l_opm_cost_dist_tab    -- 原価明細テーブルタイプ
       ,ov_errbuf          =>  lv_errbuf              -- エラー・メッセージ
       ,ov_retcode         =>  lv_retcode             -- リターン・コード
       ,ov_errmsg          =>  lv_errmsg              -- ユーザー・エラー・メッセージ
      );
      --
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_opmcost_ref_expt;
      END IF;
      --
    END LOOP opmcost_loop;
    --
  EXCEPTION
--
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00008    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_ng_table       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_cm_cmpt_dtl    -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      --
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
      --
    -- *** 標準原価反映APIエラー例外ハンドラ *** 2009/02/04追加
    WHEN proc_opmcost_ref_expt THEN
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_00469                        -- メッセージコード
                      ,iv_token_name1   =>  cv_tkn_input_item                         -- トークンコード1
                      ,iv_token_value1  =>  i_opm_cost_rec.item_no                    -- トークン値1
                      ,iv_token_name2   =>  cv_tkn_input_apply_date                   -- トークンコード2
                      ,iv_token_value2  =>  i_opm_cost_rec.apply_date                 -- トークン値2
                      ,iv_token_name3   =>  cv_tkn_err_msg                            -- トークンコード3
                      ,iv_token_value3  =>  lv_errmsg                                 -- トークン値3
                     );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
    --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_opm_cost_ref;
--
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : データ妥当性チェック (A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_opm_cost_rec    IN       xxcmm_wk_opmcost_batch_regist%ROWTYPE           -- 変換前標準原価改定データ
   ,o_opm_cost_rec    OUT      g_opm_cost_rtype                                -- 変換後標準原価改定データ
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'VALIDATE_ITEM';      -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    -- 品目ステータス
    cn_itm_status_no_use       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                           -- Ｄ
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    lv_warnig_flg              VARCHAR2(1);
    ln_column_cnt              NUMBER;
    --
    ln_exists_cnt              NUMBER;
    lv_item_no                 ic_item_mst_b.item_no%TYPE;
    ln_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE;
    ln_disc_cost               NUMBER;
    --2009/01/27追加
    ln_cldr_code_cnt           NUMBER;
    ln_item_status             xxcmm_system_items_b.item_status%TYPE;
    --
    l_validate_disc_cost_tab   g_check_data_ttype;
    l_opm_cost_rec             g_opm_cost_rtype;
    --
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    lv_step := 'A-4.0';
    lv_warnig_flg                  := cv_status_normal;
    --
    -- 品目ID
    l_validate_disc_cost_tab( 1 )  := i_opm_cost_rec.item_id;
    -- 品目コード
    l_validate_disc_cost_tab( 2 )  := i_opm_cost_rec.item_no;
    -- 適用日
    l_validate_disc_cost_tab( 3 )  := i_opm_cost_rec.apply_date;
    -- 原料
    l_validate_disc_cost_tab( 4 )  := i_opm_cost_rec.cmpntcost_01gen;
    -- 再製費
    l_validate_disc_cost_tab( 5 )  := i_opm_cost_rec.cmpntcost_02sai;
    -- 資材費
    l_validate_disc_cost_tab( 6 )  := i_opm_cost_rec.cmpntcost_03szi;
    -- 包装費
    l_validate_disc_cost_tab( 7 )  := i_opm_cost_rec.cmpntcost_04hou;
    -- 外注管理費
    l_validate_disc_cost_tab( 8 )  := i_opm_cost_rec.cmpntcost_05gai;
    -- 保管費
    l_validate_disc_cost_tab( 9 )  := i_opm_cost_rec.cmpntcost_06hkn;
    -- その他経費
    l_validate_disc_cost_tab( 10 ) := i_opm_cost_rec.cmpntcost_07kei;
    --
    --==============================================================
    --A-4.1 必須・型・サイズチェック
    --==============================================================
    <<validate_column_loop>>
    FOR ln_column_cnt IN 1..4 LOOP
      --
      -- 項目チェック
      lv_step := 'A-4.1';
      xxccp_common_pkg2.upload_item_check(
        iv_item_name     =>  g_def_info_tab( ln_column_cnt ).meaning                   -- 項目名称
       ,iv_item_value    =>  l_validate_disc_cost_tab( ln_column_cnt )                 -- 項目の値
       ,in_item_len      =>  g_def_info_tab( ln_column_cnt ).figures                   -- 項目の長さ(整数部分)
       ,in_item_decimal  =>  g_def_info_tab( ln_column_cnt ).decim                     -- 項目の長さ(小数点以下)
       ,iv_item_nullflg  =>  g_def_info_tab( ln_column_cnt ).essential                 -- 必須フラグ
       ,iv_item_attr     =>  g_def_info_tab( ln_column_cnt ).attribute                 -- 項目の属性
       ,ov_errbuf        =>  lv_errbuf 
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg 
      );
      --
      -- 戻り値が異常の場合
      IF ( lv_retcode != cv_status_normal ) THEN    -- cv_status_errorからcv_status_normalに変更 2009/01/27
        -- ファイル項目チェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00456                        -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_col_name                     -- トークンコード1
                        ,iv_token_value1  =>  g_def_info_tab( ln_column_cnt ).meaning   -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_item                         -- トークンコード2
                        ,iv_token_value2  =>  i_opm_cost_rec.item_no                    -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_apply_date                   -- トークンコード3
                        ,iv_token_value3  =>  i_opm_cost_rec.apply_date                 -- トークン値3
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- ステータスをエラーにする。
        lv_warnig_flg := cv_status_error;
      END IF;
    END LOOP validate_column_loop;
    --
    --==============================================================
    --A-4.2 標準原価の必須チェック
    --==============================================================
    lv_step := 'A-4.2';
    IF (  i_opm_cost_rec.cmpntcost_01gen IS NULL
      AND i_opm_cost_rec.cmpntcost_02sai IS NULL
      AND i_opm_cost_rec.cmpntcost_03szi IS NULL
      AND i_opm_cost_rec.cmpntcost_04hou IS NULL
      AND i_opm_cost_rec.cmpntcost_05gai IS NULL
      AND i_opm_cost_rec.cmpntcost_06hkn IS NULL
      AND i_opm_cost_rec.cmpntcost_07kei IS NULL ) THEN
      -- 
      -- ファイル項目チェックエラー
      lv_errmsg  :=  xxccp_common_pkg.get_msg(
                       iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                      ,iv_name          =>  cv_msg_xxcmm_00456                        -- メッセージコード
                      ,iv_token_name1   =>  cv_tkn_input_col_name                     -- トークンコード1
                      ,iv_token_value1  =>  cv_tkn_val_cmpnt_cost                     -- トークン値1
                      ,iv_token_name2   =>  cv_tkn_input_item                         -- トークンコード2
                      ,iv_token_value2  =>  i_opm_cost_rec.item_no                    -- トークン値2
                      ,iv_token_name3   =>  cv_tkn_input_apply_date                   -- トークンコード3
                      ,iv_token_value3  =>  i_opm_cost_rec.apply_date                 -- トークン値3
                     );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      --
      -- ステータスをエラーにする。
      lv_warnig_flg := cv_status_error;
    END IF;
    --
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      -- 各項目に格納
      l_opm_cost_rec.item_id         := TO_NUMBER( i_opm_cost_rec.item_id );
      l_opm_cost_rec.apply_date      := fnd_date.canonical_to_date( i_opm_cost_rec.apply_date );
      l_opm_cost_rec.cmpntcost_01gen := TO_NUMBER( i_opm_cost_rec.cmpntcost_01gen );
      l_opm_cost_rec.cmpntcost_02sai := TO_NUMBER( i_opm_cost_rec.cmpntcost_02sai );
      l_opm_cost_rec.cmpntcost_03szi := TO_NUMBER( i_opm_cost_rec.cmpntcost_03szi );
      l_opm_cost_rec.cmpntcost_04hou := TO_NUMBER( i_opm_cost_rec.cmpntcost_04hou );
      l_opm_cost_rec.cmpntcost_05gai := TO_NUMBER( i_opm_cost_rec.cmpntcost_05gai );
      l_opm_cost_rec.cmpntcost_06hkn := TO_NUMBER( i_opm_cost_rec.cmpntcost_06hkn );
      l_opm_cost_rec.cmpntcost_07kei := TO_NUMBER( i_opm_cost_rec.cmpntcost_07kei );
      l_opm_cost_rec.cmpntcost_total := NVL( l_opm_cost_rec.cmpntcost_01gen, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_02sai, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_03szi, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_04hou, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_05gai, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_06hkn, 0 ) +
                                        NVL( l_opm_cost_rec.cmpntcost_07kei, 0 );
      --
      --==============================================================
      --A-4.3 親品目チェック
      --==============================================================
      -- ※親品目でも、品目ステータスがＤの場合対象外であるべきかも
      lv_step := 'A-4.3';
      --
      BEGIN
        --
        SELECT    xoiv.item_no                                         -- 品目コード
                 ,TO_NUMBER( NVL( xoiv.opt_cost_new, '0' ) )
                                                            disc_cost  -- 営業原価
                 ,xoiv.item_status                                     -- 品目ステータス 2009/01/28追加
        INTO      lv_item_no
                 ,ln_disc_cost
                 ,ln_item_status                                       -- 品目ステータス 2009/01/28追加
        FROM      xxcmm_opmmtl_items_v       xoiv                      -- 品目ビュー
        WHERE     xoiv.item_id             = l_opm_cost_rec.item_id    -- 品目ID
        AND       xoiv.item_id             = xoiv.parent_item_id       -- 親品目
        AND       xoiv.start_date_active  <= TRUNC( SYSDATE )          -- 適用開始日
        AND       xoiv.end_date_active    >= TRUNC( SYSDATE );         -- 適用終了日
        --
        l_opm_cost_rec.item_no       := lv_item_no;
        --
        -- 品目ステータスが'D'のものは更新しない
        IF ( ln_item_status = cn_itm_status_no_use ) THEN
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_00483          -- メッセージコード
                          ,iv_token_name1   =>  cv_tkn_input_item           -- トークンコード1
                          ,iv_token_value1  =>  i_opm_cost_rec.item_no      -- トークン値1
                         );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          -- ステータスをエラーにする。
          lv_warnig_flg := cv_status_error;
          --
        END IF;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- 親品目チェックエラー
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_00458          -- メッセージコード
                          ,iv_token_name1   =>  cv_tkn_input_item           -- トークンコード1
                          ,iv_token_value1  =>  i_opm_cost_rec.item_no      -- トークン値1
                         );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          -- ステータスをエラーにする。
          lv_warnig_flg := cv_status_error;
      END;
      --
      --==============================================================
      --A-4.4 適用日チェック
      --==============================================================
      -- ※カレンダが設定されていない適用日指定時はエラーを追加する必要あり
      -- 原価カレンダに登録されていない年度が適用日に指定されていた場合、エラーとする 2009/01/27追加
      --
      SELECT    COUNT( ccd.calendar_code )
      INTO      ln_cldr_code_cnt
      FROM      cm_cldr_dtl ccd
      WHERE     TRUNC( ccd.start_date ) <= l_opm_cost_rec.apply_date
      AND       TRUNC( ccd.end_date   ) >= l_opm_cost_rec.apply_date
      AND       ROWNUM = 1;
      --
      -- 適用日未登録年度エラー
      IF ( ln_cldr_code_cnt = 0 ) THEN
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00482          -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_item           -- トークンコード1
                        ,iv_token_value1  =>  i_opm_cost_rec.item_no      -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date     -- トークンコード2
                        ,iv_token_value2  =>  i_opm_cost_rec.apply_date   -- トークン値2
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- ステータスをエラーにする。
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      -- 未来日のみ指定可能
      lv_step := 'A-4.4';
      IF ( l_opm_cost_rec.apply_date <= gd_process_date ) THEN
        -- マスタチェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00457            -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_item             -- トークンコード1
                        ,iv_token_value1  =>  i_opm_cost_rec.item_no        -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date       -- トークンコード2
                        ,iv_token_value2  =>  i_opm_cost_rec.apply_date     -- トークン値2
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- ステータスをエラーにする。
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      --==============================================================
      --A-4.5 ファイル内重複チェック
      --==============================================================
      lv_step := 'A-4.5';
      SELECT    COUNT( xwobr.ROWID )
      INTO      ln_exists_cnt
      FROM      xxcmm_wk_opmcost_batch_regist    xwobr               -- 標準原価一括改定ワーク
               ,cm_cldr_dtl                      ccd1                -- OPM原価カレンダ（対象品目）
               ,cm_cldr_dtl                      ccd2                -- OPM原価カレンダ（重複チェック品目）
      WHERE     xwobr.file_id         = gn_file_id                   -- ファイルID
      AND       xwobr.update_div      = cv_upd_div_upd               -- 更新区分
      --空白削除 2009/02/03
      AND       TRIM( xwobr.item_id ) = i_opm_cost_rec.item_id       -- 品目ID
      --日付型変換追加 2009/02/03
      AND       ccd2.start_date      <= TO_DATE( xwobr.apply_date, cv_date_fmt_std)
                                                                     -- 開始日(重複チェック品目)
      AND       ccd2.end_date        >= TO_DATE( xwobr.apply_date, cv_date_fmt_std)
                                                                     -- 終了日(重複チェック品目)
      AND       xwobr.file_seq       != i_opm_cost_rec.file_seq      -- ファイルシーケンス
      AND       ccd1.start_date      <= TO_DATE( i_opm_cost_rec.apply_date, cv_date_fmt_std)
                                                                     -- 開始日(対象品目)
      AND       ccd1.end_date        >= TO_DATE( i_opm_cost_rec.apply_date, cv_date_fmt_std)
                                                                     -- 終了日(対象品目)
      AND       ccd1.calendar_code    = ccd2.calendar_code           -- カレンダコード
      AND       ccd1.period_code      = ccd2.period_code             -- 期間コード
      AND       ROWNUM           = 1;
      
      --
      IF ( ln_exists_cnt >= 1 ) THEN
        -- ファイル内重複エラー  トークン追加 2009/02/03
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00463            -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_cost_type              -- トークンコード1
                        ,iv_token_value1  =>  cv_tkn_val_opm_cost           -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_item             -- トークンコード1
                        ,iv_token_value2  =>  i_opm_cost_rec.item_no        -- トークン値1
                        ,iv_token_name3   =>  cv_tkn_input_apply_date       -- トークンコード2
                        ,iv_token_value3  =>  i_opm_cost_rec.apply_date     -- トークン値2
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- ステータスをエラーにする。
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      --==============================================================
      --A-4.6 標準原価チェック
      -- 項目レベルで小数点以下チェックがあるので不要かも。
      --==============================================================
      lv_step := 'A-4.6';
      IF ( l_opm_cost_rec.cmpntcost_total < 0 )
      OR ( l_opm_cost_rec.cmpntcost_total <> TRUNC( l_opm_cost_rec.cmpntcost_total ) ) THEN
        -- 標準原価チェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00460              -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_cost_type                -- トークンコード1
                        ,iv_token_value1  =>  cv_tkn_val_opm_cost             -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_cost               -- トークンコード2
                        ,iv_token_value2  =>  l_opm_cost_rec.cmpntcost_total  -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- トークンコード3
                        ,iv_token_value3  =>  i_opm_cost_rec.item_no          -- トークン値3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- トークンコード4
                        ,iv_token_value4  =>  i_opm_cost_rec.apply_date       -- トークン値4
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- ステータスをエラーにする。
        lv_warnig_flg := cv_status_error;
      END IF;
      --
      --==============================================================
      --A-4.7 標準原価と営業原価の比較
      --==============================================================
      lv_step := 'A-4.7';
      --
      IF ( l_opm_cost_rec.cmpntcost_total > ln_disc_cost ) THEN
        -- 標準原価比較警告
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00462              -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_opm_cost                 -- トークンコード1
                        ,iv_token_value1  =>  TO_CHAR( l_opm_cost_rec.cmpntcost_total )
                                                                              -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_disc_cost                -- トークンコード2
                        ,iv_token_value2  =>  TO_CHAR( ln_disc_cost )         -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- トークンコード3
                        ,iv_token_value3  =>  i_opm_cost_rec.item_no          -- トークン値3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- トークンコード4
                        ,iv_token_value4  =>  i_opm_cost_rec.apply_date       -- トークン値4
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- 正常時はステータスを警告にする。（異常時は変更しない）
        IF ( lv_warnig_flg = cv_status_normal ) THEN
          lv_warnig_flg := cv_status_warn;
        END IF;
      END IF;
      --
    END IF;
    --
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      -- 型変換実施後OUT変数に格納
      o_opm_cost_rec := l_opm_cost_rec;
    ELSIF ( lv_warnig_flg = cv_status_warn ) THEN
      -- 型変換実施後OUT変数に格納
      o_opm_cost_rec := l_opm_cost_rec;
      -- 終了ステータスに警告を設定
      ov_retcode      := cv_status_warn;
    ELSE
      -- 終了ステータスにエラーを設定
      ov_retcode      := cv_status_error;
    END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_item;
--
--
  /**********************************************************************************
   * Procedure Name   : loop_main
   * Description      : 標準原価一括改定ワークの取得 (A-3)
   ***********************************************************************************/
  PROCEDURE loop_main(
    ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'LOOP_MAIN';          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    lv_warnig_flg              VARCHAR2(1);                                    -- 退避用リターン・コード
    --
    -- *** カーソル ***
    -- 標準原価一括改定データ取得カーソル
    CURSOR get_data_cur
    IS
      SELECT    xwobr.file_id                                   -- ファイルID
               ,xwobr.file_seq                                  -- ファイルシーケンス
               ,TRIM( xwobr.item_id )          item_id          -- 品目ID
               ,TRIM( xwobr.item_no )          item_no          -- 品目コード
               ,TRIM( xwobr.apply_date )       apply_date       -- 適用日
               ,TRIM( xwobr.cmpntcost_01gen )  cmpntcost_01gen  -- 原料
               ,TRIM( xwobr.cmpntcost_02sai )  cmpntcost_02sai  -- 再製費
               ,TRIM( xwobr.cmpntcost_03szi )  cmpntcost_03szi  -- 資材費
               ,TRIM( xwobr.cmpntcost_04hou )  cmpntcost_04hou  -- 包装費
               ,TRIM( xwobr.cmpntcost_05gai )  cmpntcost_05gai  -- 外注管理費
               ,TRIM( xwobr.cmpntcost_06hkn )  cmpntcost_06hkn  -- 保管費
               ,TRIM( xwobr.cmpntcost_07kei )  cmpntcost_07kei  -- その他経費
               ,xwobr.update_div                                -- ★更新区分(使用しない)
               ,xwobr.created_by                                -- ★作成者(使用しない)
               ,xwobr.creation_date                             -- ★作成日(使用しない)
               ,xwobr.last_updated_by                           -- ★最終更新者(使用しない)
               ,xwobr.last_update_date                          -- ★最終更新日(使用しない)
               ,xwobr.last_update_login                         -- ★最終更新ﾛｸﾞｲﾝ(使用しない)
               ,xwobr.request_id                                -- ★要求ID(使用しない)
               ,xwobr.program_application_id                    -- ★ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID(使用しない)
               ,xwobr.program_id                                -- ★ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID(使用しない)
               ,xwobr.program_update_date                       -- ★ﾌﾟﾛｸﾞﾗﾑ更新日(使用しない)
      FROM      xxcmm_wk_opmcost_batch_regist    xwobr          -- 標準原価一括改定ワーク
      WHERE     xwobr.file_id    = gn_file_id                   -- ファイルID
      AND       xwobr.update_div = cv_upd_div_upd               -- 更新区分
      ORDER BY  xwobr.file_seq;                                 -- ファイルシーケンス
    --
    l_opm_cost_rec             g_opm_cost_rtype;
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
    --A-3 標準原価一括改定ワークの取得
    --==============================================================
    lv_step := 'A-3.1';
    -- メイン処理LOOP
    <<main_loop>>
    FOR l_get_data_rec IN get_data_cur LOOP
      --
      --==============================================================
      --A-4 データ妥当性チェック
      --==============================================================
      lv_step := 'A-4';
      validate_item(
        i_opm_cost_rec    =>  l_get_data_rec
       ,o_opm_cost_rec    =>  l_opm_cost_rec
       ,ov_errbuf         =>  lv_errbuf
       ,ov_retcode        =>  lv_retcode
       ,ov_errmsg         =>  lv_errmsg
      );
      --
      -- データ妥当性チェックのステータスを退避
      lv_warnig_flg := lv_retcode;  -- 2009/01/29追加
      --
      -- データ妥当性チェック結果が正常、警告を登録・更新処理へ
      -- (警告データも登録・更新対象)
      IF ( lv_retcode != cv_status_error ) THEN
        --
        -- データ妥当性チェックのステータスを退避
        --lv_warnig_flg := lv_retcode;  2009/01/29 IF文の外に出す
        --
        --==============================================================
        --OPM標準原価反映
        --  A-5 標準原価改定対象データの抽出
        --  A-6 OPM標準原価反映
        --==============================================================
        lv_step := 'A-5';
        proc_opm_cost_ref(
          i_opm_cost_rec   =>  l_opm_cost_rec
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
        -- 異常時は、データ妥当性チェックのステータスを上書き
        IF ( lv_retcode = cv_status_error ) THEN
          lv_warnig_flg := lv_retcode;
          --
        END IF;
      END IF;
      --
      IF ( lv_warnig_flg = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSIF ( lv_warnig_flg = cv_status_warn ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
        gn_warn_cnt   := gn_warn_cnt   + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt  + 1;
      END IF;
    END LOOP main_loop;
    --
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    ELSE
      IF ( gn_warn_cnt > 0 ) THEN
        ov_retcode := cv_status_warn;
      END IF;
    END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END loop_main;
--
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'GET_IF_DATA';        -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--#####################  固定ローカル変数宣言部  END    ########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_cost_div_str            CONSTANT VARCHAR2(20)  := '原価改定種別区分：';
                                                                        -- 原価改定種別
    cv_cost_div_opm            CONSTANT NUMBER(2)     := '1';           -- 原価改定種別区分(標準原価)
    --
    -- CSVファイル内列番号
    cn_csv_item_id             CONSTANT NUMBER(2)     := 17;            -- 品目ID
    cn_csv_item_no             CONSTANT NUMBER(2)     := 2;             -- 品目コード
    cn_csv_apply_date          CONSTANT NUMBER(2)     := 14;            -- 適用日
    cn_csv_opm_cost_01         CONSTANT NUMBER(2)     := 3;             -- 原料
    cn_csv_opm_cost_02         CONSTANT NUMBER(2)     := 4;             -- 再製費
    cn_csv_opm_cost_03         CONSTANT NUMBER(2)     := 5;             -- 資材費
    cn_csv_opm_cost_04         CONSTANT NUMBER(2)     := 6;             -- 包装費
    cn_csv_opm_cost_05         CONSTANT NUMBER(2)     := 7;             -- 外注管理費
    cn_csv_opm_cost_06         CONSTANT NUMBER(2)     := 8;             -- 保管費
    cn_csv_opm_cost_07         CONSTANT NUMBER(2)     := 9;             -- その他経費
    cn_csv_update_div          CONSTANT NUMBER(2)     := 13;            -- 更新区分
    --
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    --
    ln_line_cnt                NUMBER;                                  -- 行カウンタ
    ln_item_num                NUMBER;                                  -- 項目数
    lv_cost_div                VARCHAR2(1);                             -- 原価改定種別区分
    lv_update_div              VARCHAR2(1);                             -- 更新区分
    ln_ins_item_cnt            NUMBER;                                  -- 登録件数カウンタ
    --
    -- 
    l_if_data_tab              xxccp_common_pkg2.g_file_data_tbl;
    -- 
    l_disc_cost_tab            g_check_data_ttype;
    --
    cost_div_expt              EXCEPTION;                               -- 起動種別区分エラー
    get_ifdat_cnt_expt         EXCEPTION;                               -- データ項目数エラー
    ins_data_expt              EXCEPTION;                               -- データ登録エラー
    --
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    lv_step := 'A-2';
    ln_ins_item_cnt := 0;
    --
    -- SAVEPOINT設定
    SAVEPOINT XXCMM004A08C_savepoint;
--    --
    --==============================================================
    --A-2.2 標準原価一括改定対象データの分割(レコード分割)
    --==============================================================
    lv_step := 'A-2.2-L';
    -- BLOBデータ変換共通関数
    xxccp_common_pkg2.blob_to_varchar2(
      in_file_id    =>  gn_file_id        -- INパラメータ
     ,ov_file_data  =>  l_if_data_tab     -- レコード単位
     ,ov_errbuf     =>  lv_errbuf 
     ,ov_retcode    =>  lv_retcode
     ,ov_errmsg     =>  lv_errmsg 
    );
-- 2009/01/27 追加
    -- ステータスがエラーの場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
-- End
    --
    ------------------
    -- レコードLOOP
    ------------------
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 1..l_if_data_tab.COUNT LOOP
      --
      IF ( ln_line_cnt <= 5 ) THEN
        ------------------
        -- ヘッダレコード
        -- 1行目：表名
        -- 2行目：標準原価年度
        -- 3行目：営業原価タイプ
        -- 4行目：原価改定種別区分
        -- 5行目：明細タイトル
        ------------------
        IF ( ln_line_cnt = 4 ) THEN
          --==============================================================
          --A-2.4 原価改定種別区分のチェック
          --==============================================================
          -- 原価改定種別区分の抽出
          lv_step := 'A-2.4';
          lv_cost_div := SUBSTRB( TRIM( REPLACE( l_if_data_tab( ln_line_cnt ), cv_cost_div_str, '' ) ), 1, 1 );
          --
          IF ( lv_cost_div != cv_cost_div_opm ) THEN
            -- 標準原価改定ではないためエラー
            RAISE cost_div_expt;
          END IF;
        END IF;
        --
      ELSIF ( ln_line_cnt > 5 ) THEN
        ------------------
        -- 明細レコード
        ------------------
        --==============================================================
        --A-2.3 項目数のチェック
        --==============================================================
        -- 項目数のチェック
        -- データ項目数を格納( レコードバイト数 - カンマを除いたレコードバイト数 + 1 )
        lv_step := 'A-2.3';
        ln_item_num := ( LENGTHB( l_if_data_tab( ln_line_cnt ) )
                     - ( LENGTHB( REPLACE( l_if_data_tab( ln_line_cnt ), cv_msg_comma, '' ) ) )
                     +   1 );
        --
        -- 項目数が一致しない場合
        IF ( gn_item_num <> ln_item_num ) THEN
          RAISE get_ifdat_cnt_expt;
        END IF;
        --
        --==============================================================
        --A-2.2 標準原価一括改定対象データの分割(項目分割)
        --==============================================================
        -------------------------------
        -- デリミタ文字変換共通関数
        -- 各項目の値を格納
        -------------------------------
        lv_step := 'A-2.2-C';
        -- 品目ID    （１７列目）
        l_disc_cost_tab( 1 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_item_id
                                 );
        -- 品目コード（２列目）
        l_disc_cost_tab( 2 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_item_no
                                 );
        -- 適用日    （１４列目）
        l_disc_cost_tab( 3 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_apply_date
                                 );
        -- 原料      （３列目）
        l_disc_cost_tab( 4 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_01
                                 );
        -- 再製費    （４列目）
        l_disc_cost_tab( 5 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_02
                                 );
        -- 資材費    （５列目）
        l_disc_cost_tab( 6 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_03
                                 );
        -- 包装費    （６列目）
        l_disc_cost_tab( 7 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_04
                                 );
        -- 外注管理費（７列目）
        l_disc_cost_tab( 8 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_05
                                 );
        -- 保管費    （８列目）
        l_disc_cost_tab( 9 )  := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_06
                                 );
        -- その他経費（９列目）
        l_disc_cost_tab( 10 ) := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_opm_cost_07
                                 );
        -- 更新区分  （１３列目）
        l_disc_cost_tab( 11 ) := xxccp_common_pkg.char_delim_partition(
                                   iv_char     =>  l_if_data_tab( ln_line_cnt )
                                  ,iv_delim    =>  cv_msg_comma
                                  ,in_part_num =>  cn_csv_update_div
                                 );
        lv_update_div := SUBSTRB( TRIM( l_disc_cost_tab( 11 ) ), 1, 1 );
        --
        IF ( lv_update_div = cv_upd_div_upd ) THEN
          -- 更新区分が'U'のみ対象
          gn_target_cnt := gn_target_cnt + 1;
          --
          --==============================================================
          --A-2.5 標準原価一括改定ワークへ登録
          --==============================================================
          lv_step := 'A-2.5';
          BEGIN
            ln_ins_item_cnt := ln_ins_item_cnt + 1;
            INSERT INTO  xxcmm_wk_opmcost_batch_regist(
              file_id                        -- ファイルID
             ,file_seq                       -- ファイルシーケンス
             ,item_id                        -- 品目ID
             ,item_no                        -- 品目コード
             ,apply_date                     -- 適用日
             ,cmpntcost_01gen                -- 原料
             ,cmpntcost_02sai                -- 再製費
             ,cmpntcost_03szi                -- 資材費
             ,cmpntcost_04hou                -- 包装費
             ,cmpntcost_05gai                -- 外注管理費
             ,cmpntcost_06hkn                -- 保管費
             ,cmpntcost_07kei                -- その他経費
             ,update_div                     -- 更新区分
             ,created_by                     -- 作成者
             ,creation_date                  -- 作成日
             ,last_updated_by                -- 最終更新者
             ,last_update_date               -- 最終更新日
             ,last_update_login              -- 最終更新ﾛｸﾞｲﾝ
             ,request_id                     -- 要求ID
             ,program_application_id         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             ,program_id                     -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
             ,program_update_date )          -- ﾌﾟﾛｸﾞﾗﾑ更新日
            VALUES(
              gn_file_id                     -- ファイルID
             ,ln_ins_item_cnt                -- ファイルシーケンス
             ,SUBSTRB( l_disc_cost_tab( 1 ),
                       1, 100 )              -- 品目ID
             ,SUBSTRB( l_disc_cost_tab( 2 ),
                       1, 100 )              -- 品目コード
             ,SUBSTRB( l_disc_cost_tab( 3 ),
                       1, 100 )              -- 適用日
             ,SUBSTRB( l_disc_cost_tab( 4 ),
                       1, 100 )              -- 原料
             ,SUBSTRB( l_disc_cost_tab( 5 ),
                       1, 100 )              -- 再製費
             ,SUBSTRB( l_disc_cost_tab( 6 ),
                       1, 100 )              -- 資材費
             ,SUBSTRB( l_disc_cost_tab( 7 ),
                       1, 100 )              -- 包装費
             ,SUBSTRB( l_disc_cost_tab( 8 ),
                       1, 100 )              -- 外注管理費
             ,SUBSTRB( l_disc_cost_tab( 9 ),
                       1, 100 )              -- 保管費
             ,SUBSTRB( l_disc_cost_tab( 10 ),
                       1, 100 )              -- その他経費
             ,lv_update_div                  -- 更新区分
             ,cn_created_by                  -- 作成者
             ,cd_creation_date               -- 作成日
             ,cn_last_updated_by             -- 最終更新者
             ,cd_last_update_date            -- 最終更新日
             ,cn_last_update_login           -- 最終更新ﾛｸﾞｲﾝ
             ,cn_request_id                  -- 要求ID
             ,cn_program_application_id      -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             ,cn_program_id                  -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
             ,cd_program_update_date         -- ﾌﾟﾛｸﾞﾗﾑ更新日
            );
          EXCEPTION
            -- *** データ登録例外ハンドラ ***
            WHEN OTHERS THEN
              lv_errmsg  := xxccp_common_pkg.get_msg(
                              iv_application   =>  cv_appl_name_xxcmm         -- アプリケーション短縮名
                             ,iv_name          =>  cv_msg_xxcmm_00466         -- メッセージコード
                             ,iv_token_name1   =>  cv_tkn_table               -- トークンコード1
                             ,iv_token_value1  =>  cv_tkn_val_wk_opm_cost     -- トークン値1
                             ,iv_token_name2   =>  cv_tkn_input_item          -- トークンコード2
                             ,iv_token_value2  =>  l_disc_cost_tab( 2 )       -- トークン値2
                             ,iv_token_name3   =>  cv_tkn_input_apply_date    -- トークンコード3
                             ,iv_token_value3  =>  l_disc_cost_tab( 3 )       -- トークン値3
                             ,iv_token_name4   =>  cv_tkn_err_msg             -- トークンコード2
                             ,iv_token_value4  =>  SQLERRM                    -- トークン値2
                            );
              -- メッセージ出力
              xxcmm_004common_pkg.put_message(
                iv_message_buff  =>  lv_errmsg
               ,ov_errbuf        =>  lv_errbuf
               ,ov_retcode       =>  lv_retcode
               ,ov_errmsg        =>  lv_errmsg
              );
              --
              gn_error_cnt  := gn_error_cnt  + 1;
            --
          END;
          --
        END IF;
      END IF;
      --
    END LOOP ins_wk_loop;
    --
  EXCEPTION
--
    -- *** 起動種別区分例外ハンドラ ***
    WHEN cost_div_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name          =>  cv_msg_xxcmm_00455    -- メッセージコード
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
    -- *** データ項目数例外ハンドラ ***
    WHEN get_ifdat_cnt_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application   =>  cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name          =>  cv_msg_xxcmm_00028    -- メッセージコード
                     ,iv_token_name1   =>  cv_tkn_table          -- トークンコード1
                     ,iv_token_value1  =>  cv_tkn_val_proc_name  -- トークン値1
                     ,iv_token_name2   =>  cv_tkn_count          -- トークンコード2
                     ,iv_token_value2  =>  ln_item_num           -- トークン値2
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
    --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END  get_if_data;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id        IN       VARCHAR2                                        -- 入力パラメータ.FILE_ID
   ,iv_format         IN       VARCHAR2                                        -- 入力パラメータ.ファイルフォーマット
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_INIT';          -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_lookup_type_upload_obj  CONSTANT VARCHAR2(30) := xxcmm_004common_pkg.cv_lookup_type_upload_obj;
                                                                                                    -- ファイルアップロードオブジェクト
    cv_lookup_opm_cost_item    CONSTANT VARCHAR2(30) := 'XXCMM1_004A08_ITEM_DEF';                   -- 標準原価一括改定データ項目定義
    cv_item_num                CONSTANT VARCHAR2(30) := 'XXCMM1_004A08_ITEM_NUM';                   -- 標準原価一括改定データ項目数
    --
    cv_null_ok                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_null_ok;             -- 任意項目
    cv_null_ng                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_null_ng;             -- 必須項目
    cv_varchar                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_varchar;             -- 文字列
    cv_number                  CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_number;              -- 数値
    cv_date                    CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date;                -- 日付
    cv_varchar_cd              CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_varchar_cd;          -- 文字列項目
    cv_number_cd               CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_number_cd;           -- 数値項目
    cv_date_cd                 CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_date_cd;             -- 日付項目
    cv_not_null                CONSTANT VARCHAR2(10) := xxcmm_004common_pkg.cv_not_null;            -- 必須
    --
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    lv_tkn_value               VARCHAR2(4000);                                                      -- トークン値
    ln_cnt                     NUMBER;                                                              -- カウンタ
    lv_upload_obj              VARCHAR2(100);                                                       -- ファイルアップロード名称
    --
    -- ファイルアップロードIFテーブル項目
    lv_csv_file_name           xxccp_mrp_file_ul_interface.file_name%TYPE;                          -- ファイル名格納用
    ln_created_by              xxccp_mrp_file_ul_interface.created_by%TYPE;                         -- 作成者格納用
    ld_creation_date           xxccp_mrp_file_ul_interface.creation_date%TYPE;                      -- 作成日格納用
    --
    -- 初期出力
    lv_up_name                 VARCHAR2(1000);                                                      -- アップロード名称出力用
    lv_file_name               VARCHAR2(1000);                                                      -- ファイル名出力用
    lv_in_file_id              VARCHAR2(1000);                                                      -- ファイルＩＤ出力用
    lv_in_format               VARCHAR2(1000);                                                      -- フォーマット出力用
    --
    -- *** ローカル・カーソル ***
    CURSOR   get_def_info_cur                                                                       -- データ項目定義取得用カーソル
    IS
      SELECT   flv.meaning                                                   meaning                -- 内容
              ,DECODE( flv.attribute1, cv_varchar, cv_varchar_cd
                                     , cv_number,  cv_number_cd
                                     , cv_date_cd )                          attribute              -- 項目属性
              ,DECODE( flv.attribute2, cv_not_null, cv_null_ng
                                     , cv_null_ok )                          essential              -- 必須フラグ
              ,TO_NUMBER( flv.attribute3 )                                   figures                -- 項目の長さ(整数)
              ,TO_NUMBER( flv.attribute4 )                                   decim                  -- 項目の長さ(小数)
      FROM     fnd_lookup_values_vl  flv                                                            -- LOOKUP表
      WHERE    flv.lookup_type        = cv_lookup_opm_cost_item                                     -- 標準原価一括改定項目定義
      AND      flv.enabled_flag       = cv_yes                                                      -- 使用可能フラグ
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date                     -- 適用開始日
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date                     -- 適用終了日
      ORDER BY flv.lookup_code;
      --
    --
    -- *** ローカルユーザー定義例外 ***
    get_param_expt            EXCEPTION;                              -- パラメータNULLエラー
    get_profile_expt          EXCEPTION;                              -- プロファイル取得例外
    select_expt               EXCEPTION;                              -- データ抽出エラー
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    --==============================================================
    --A-1.1 パラメータチェック
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_tkn_file_id;
      RAISE get_param_expt;
    END IF;
    --
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := cv_tkn_val_fmt_pattern;
      RAISE get_param_expt;
    END IF;
    --
    gn_file_id := TO_NUMBER( iv_file_id );    -- INパラメータを格納
    gv_format  := iv_format;                  -- INパラメータを格納
    --
    --==============================================================
    --A-1.2 業務日付の取得
    --==============================================================
    lv_step := 'A-1.2';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --
    --==============================================================
    --A-1.3 プロファイル値取得
    --==============================================================
    -- 項目数の取得
    lv_step := 'A-1.3';
    gn_item_num     := TO_NUMBER( FND_PROFILE.VALUE( cv_item_num ) );
    --
    IF ( gn_item_num IS NULL ) THEN
      -- 項目数取得失敗の場合
      lv_tkn_value := cv_tkn_profile;
      RAISE get_profile_expt;
    END IF;
    --
    --==============================================================
    --A-1.4 ファイルアップロード名称の取得
    --==============================================================
    lv_step := 'A-1.4';
    --
    BEGIN
      SELECT   flv.meaning  meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv                                             -- LOOKUP表
      WHERE    flv.lookup_type        = cv_lookup_type_upload_obj                   -- ファイルアップロードオブジェクト
      AND      flv.lookup_code        = gv_format                                   -- フォーマットパターン
      AND      flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
    EXCEPTION
      WHEN OTHERS THEN    --データ抽出エラー 2009/01/28追加
        RAISE select_expt;
    END;
    --
    --==============================================================
    --A-1.5 対象データロックの取得
    --==============================================================
    lv_step := 'A-1.5';
    SELECT   fui.file_name         file_name        -- ファイル名
            ,fui.created_by        created_by       -- 作成者
            ,fui.creation_date     creation_date    -- 作成日
    INTO     lv_csv_file_name
            ,ln_created_by
            ,ld_creation_date
    FROM     xxccp_mrp_file_ul_interface  fui       -- ファイルアップロードIFテーブル
    WHERE    fui.file_id = gn_file_id               -- ファイルID
    FOR UPDATE NOWAIT;
    --
    --==============================================================
    --A-1.6 標準原価一括改定テーブル定義情報取得
    --==============================================================
    lv_step := 'A-1.6';
    ln_cnt := 0;                                                           -- 変数の初期化
    <<def_info_loop>>                                                      -- テーブル定義取得LOOP
    FOR l_get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_def_info_tab(ln_cnt).meaning   := l_get_def_info_rec.meaning;      -- 項目名
      g_def_info_tab(ln_cnt).attribute := l_get_def_info_rec.attribute;    -- 項目属性
      g_def_info_tab(ln_cnt).essential := l_get_def_info_rec.essential;    -- 必須フラグ
      g_def_info_tab(ln_cnt).figures   := l_get_def_info_rec.figures;      -- 項目の長さ(整数)
      g_def_info_tab(ln_cnt).decim     := l_get_def_info_rec.decim;        -- 項目の長さ(小数)
    END LOOP def_info_loop;
    --
    --==============================================================
    --A-1.7 INパラメータの出力
    --==============================================================
    lv_step := 'A-1.7';
    --
    lv_up_name    := xxccp_common_pkg.get_msg(                -- アップロード名称の出力
                       iv_application  => cv_appl_name_xxcmm  -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00021  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_up_name      -- トークンコード1
                      ,iv_token_value1 => lv_upload_obj       -- トークン値1
                      );
    lv_file_name  := xxccp_common_pkg.get_msg(                -- CSVファイル名の出力
                       iv_application  => cv_appl_name_xxcmm  -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00022  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_name    -- トークンコード1
                      ,iv_token_value1 => lv_csv_file_name    -- トークン値1
                      );
    lv_in_file_id := xxccp_common_pkg.get_msg(                -- ファイルIDの出力
                       iv_application  => cv_appl_name_xxcmm  -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00023  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_id      -- トークンコード1
                      ,iv_token_value1 => gn_file_id          -- トークン値1
                      );
    lv_in_format  := xxccp_common_pkg.get_msg(                -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcmm  -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00024  -- メッセージコード
                      ,iv_token_name1  => cv_tkn_format       -- トークンコード1
                      ,iv_token_value1 => gv_format           -- トークン値1
                      );
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  ''            || CHR(10) ||
                           lv_up_name    || CHR(10) ||
                           lv_file_name  || CHR(10) ||
                           lv_in_file_id || CHR(10) ||
                           lv_in_format  || CHR(10)
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
  EXCEPTION
--
    -- *** パラメータチェック例外ハンドラ ***
    WHEN get_param_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00440    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_param_name     -- トークンコード1
                     ,iv_token_value1 => lv_tkn_value          -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** プロファイル取得例外ハンドラ ***
    WHEN get_profile_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00002    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_profile        -- トークンコード1
                     ,iv_token_value1 => lv_tkn_value          -- トークン値1
                   );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm    -- アプリケーション短縮名
                     ,iv_name         => cv_msg_xxcmm_00008    -- メッセージコード
                     ,iv_token_name1  => cv_tkn_ng_table       -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_file_ul_if -- トークン値1
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errmsg, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    --*** データ抽出エラー(アップロードファイル名称) ***
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00409            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_table_flv                  -- トークン値1
                    ,iv_token_name2  => cv_tkn_input_line_no          -- トークンコード2
                    ,iv_token_value2 => NULL                          -- トークン値2
                    ,iv_token_name3  => cv_tkn_input_item_code        -- トークンコード3
                    ,iv_token_value3 => NULL                          -- トークン値3
                    ,iv_token_name4  => cv_tkn_errmsg                 -- トークンコード4
                    ,iv_token_value4 => SQLERRM                       -- トークン値4
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
  --
  END proc_init;
--
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_file_id        IN       VARCHAR2                                        -- 入力パラメータ.FILE_ID
   ,iv_format         IN       VARCHAR2                                        -- 入力パラメータ.ファイルフォーマット
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'SUBMAIN';            -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
  --
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    lv_step                    VARCHAR2(10);
    lv_lm_errbuf               VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_lm_retcode              VARCHAR2(1);                                    -- リターン・コード
    lv_lm_errmsg               VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    --
    -- *** ローカル例外 ***
    sub_proc_expt              EXCEPTION;
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
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    gn_warn_cnt   := 0;
    --
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    --A-1.  初期処理
    --==============================================================
    lv_step := 'A-1';
    proc_init(
      iv_file_id  =>  iv_file_id    -- 入力パラメータ.FILE_ID
     ,iv_format   =>  iv_format     -- 入力パラメータ.ファイルフォーマット
     ,ov_errbuf   =>  lv_errbuf     -- エラー・メッセージ
     ,ov_retcode  =>  lv_retcode    -- リターン・コード
     ,ov_errmsg   =>  lv_errmsg     -- ユーザー・エラー・メッセージ
    );
    --
    -- 戻り値が異常の場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-2.  ファイルアップロードIFデータ取得
    --==============================================================
    lv_step := 'A-2';
    get_if_data(
      ov_errbuf   =>  lv_errbuf     -- エラー・メッセージ
     ,ov_retcode  =>  lv_retcode    -- リターン・コード
     ,ov_errmsg   =>  lv_errmsg     -- ユーザー・エラー・メッセージ
    );
    --
    -- 戻り値が異常の場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    --A-3 標準原価一括改定ワークの取得
    --  A-4 データ妥当性チェック
    --  A-5 標準原価改定対象データの抽出
    --  A-6 OPM標準原価反映
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf   =>  lv_lm_errbuf   -- エラー・メッセージ
     ,ov_retcode  =>  lv_lm_retcode  -- リターン・コード
     ,ov_errmsg   =>  lv_lm_errmsg   -- ユーザー・エラー・メッセージ
    );
    --
    --==============================================================
    --A-7.  終了処理
    --==============================================================
    lv_step := 'A-7';
    proc_comp(
      ov_errbuf   =>  lv_errbuf     -- エラー・メッセージ
     ,ov_retcode  =>  lv_retcode    -- リターン・コード
     ,ov_errmsg   =>  lv_errmsg     -- ユーザー・エラー・メッセージ
    );
    --
    -- LOOP_MAINの戻り値が異常の場合
    IF ( lv_lm_retcode = cv_status_error ) THEN
      lv_errbuf := lv_lm_errbuf;
      lv_errmsg := lv_lm_errmsg;
      RAISE sub_proc_expt;
    END IF;
    --
    -- 終了処理の戻り値が異常の場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    ov_retcode := lv_lm_retcode;
    --
  EXCEPTION
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
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
  PROCEDURE main(
    errbuf            OUT      VARCHAR2                                        -- エラー・メッセージ
   ,retcode           OUT      VARCHAR2                                        -- リターン・コード
   ,iv_file_id        IN       VARCHAR2                                        -- ファイルID
   ,iv_format         IN       VARCHAR2                                        -- フォーマットパターン
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
    cv_prg_name                CONSTANT VARCHAR2(100) := 'MAIN';               -- プログラム名
    --
    cv_appl_name_xxccp         CONSTANT VARCHAR2(10)  := 'XXCCP';              -- アドオン：共通・IF領域
    cv_target_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';   -- 対象件数メッセージ
    cv_success_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';   -- 成功件数メッセージ
    cv_error_rec_msg           CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';   -- エラー件数メッセージ
    cv_skip_rec_msg            CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';   -- スキップ件数メッセージ
    cv_cnt_token               CONSTANT VARCHAR2(10)  := 'COUNT';              -- 件数メッセージ用トークン名
    cv_normal_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';   -- 正常終了メッセージ
    cv_warn_msg                CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';   -- 警告終了メッセージ
    cv_error_msg               CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';   -- エラー終了全ロールバック
    --
    cv_log                     CONSTANT VARCHAR2(100) := 'LOG';                -- ログ
    cv_output                  CONSTANT VARCHAR2(100) := 'OUTPUT';             -- アウトプット
    --
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf                  VARCHAR2(5000);                                 -- エラー・メッセージ
    lv_retcode                 VARCHAR2(1);                                    -- リターン・コード
    lv_errmsg                  VARCHAR2(5000);                                 -- ユーザー・エラー・メッセージ
    lv_message_code            VARCHAR2(100);                                  -- 終了メッセージコード
    --
    lv_submain_retcode         VARCHAR2(1);                                    -- リターン・コード
  BEGIN
--
--###########################  固定部 START   #####################################################
    --
    ----------------------------------
    -- ログヘッダ出力
    ----------------------------------
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_log
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
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
      iv_file_id  =>  iv_file_id              -- 入力パラメータ.FILE_ID
     ,iv_format   =>  iv_format               -- 入力パラメータ.ファイルフォーマット
     ,ov_errbuf   =>  lv_errbuf               -- エラー・メッセージ
     ,ov_retcode  =>  lv_retcode              -- リターン・コード
     ,ov_errmsg   =>  lv_errmsg               -- ユーザー・エラー・メッセージ
    );
    --
    -- submainのリターンコードを退避
    lv_submain_retcode := lv_retcode;
    --
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF ( lv_submain_retcode = cv_status_error ) THEN
      -- 出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                -- ユーザー・エラーメッセージ
      );
      -- ログ
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf                -- エラーメッセージ
      );
    END IF;
    --
    ----------------------------------
    -- ログフッタ出力
    ----------------------------------
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                   ,iv_name          =>  cv_target_rec_msg
                   ,iv_token_name1   =>  cv_cnt_token
                   ,iv_token_value1  =>  TO_CHAR( gn_target_cnt )
                  );
    --
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                   ,iv_name          =>  cv_success_rec_msg
                   ,iv_token_name1   =>  cv_cnt_token
                   ,iv_token_value1  =>  TO_CHAR( gn_normal_cnt )
                  );
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application   =>  cv_appl_name_xxccp
                   ,iv_name          =>  cv_error_rec_msg
                   ,iv_token_name1   =>  cv_cnt_token
                   ,iv_token_value1  =>  TO_CHAR( gn_error_cnt )
                  );
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    --
-- 2009/01/16 Del 不要
--    -- スキップ件数出力
--    gv_out_msg := xxccp_common_pkg.get_msg(
--                    iv_application   =>  cv_appl_name_xxccp
--                   ,iv_name          =>  cv_skip_rec_msg
--                   ,iv_token_name1   =>  cv_cnt_token
--                   ,iv_token_value1  =>  TO_CHAR( gn_warn_cnt )
--                  );
--    -- メッセージ出力
--    xxcmm_004common_pkg.put_message(
--      iv_message_buff  =>  gv_out_msg
--     ,ov_errbuf        =>  lv_errbuf
--     ,ov_retcode       =>  lv_retcode
--     ,ov_errmsg        =>  lv_errmsg
--    );
-- End
    --
    -- 終了メッセージ
    IF ( lv_submain_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_submain_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF ( lv_submain_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  =>  cv_appl_name_xxccp
                   ,iv_name         =>  lv_message_code
                  );
    -- メッセージ出力
    xxcmm_004common_pkg.put_message(
      iv_message_buff  =>  gv_out_msg
     ,ov_errbuf        =>  lv_errbuf
     ,ov_retcode       =>  lv_retcode
     ,ov_errmsg        =>  lv_errmsg
    );
    -- ステータスセット
    retcode := lv_submain_retcode;
    -- 終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
    END IF;
    --
  EXCEPTION
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  END main;
--
END xxcmm004a08c;
/
