CREATE OR REPLACE PACKAGE BODY XXCMM004A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A07C(body)
 * Description      : EBS(ファイルアップロードIF)に取込まれた営業原価データを
 *                  : Disc品目変更履歴テーブル(アドオン)に取込みます。
 * MD.050           : 営業原価一括改定    MD050_CMM_004_A07
 * Version          : Issue3.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_init              初期処理 (A-1)
 *  get_if_data            ファイルアップロードIFデータ取得 (A-2)
 *  loop_main              営業原価一括改定ワークの取得 (A-3)
 *                            ・validate_item
 *                            ・proc_disc_hst_ref
 *  validate_item          データ妥当性チェック (A-4)
 *  proc_disc_hst_ref      Disc品目変更履歴反映
 *                         品目変更履歴アドオン登録・更新判定 (A-5)
 *                            ・insert_disc_hst
 *                            ・update_disc_hst
 *  insert_disc_hst        Disc品目変更履歴アドオン挿入 (A-6)
 *  update_disc_hst        Disc品目変更履歴アドオン更新 (A-7)
 *  proc_comp              終了処理 (A-8)
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
 *  2009/01/22    1.01  R.Takigawa       BLOBデータ変換共通関数の後にretcodeがエラーかどうか判断するIF文を追記
 *  2009/01/27    1.02  R.Takigawa       ファイル内重複エラーにトークンを追加
 *  2009/01/28    1.03  R.Takigawa       データ抽出エラーを追加
 *  2009/02/02    1.04  R.Takigawa       プロファイル名を追加
 *  2009/02/03    1.05  R.Takigawa       proc_init共通関数の例外処理メッセージ変更
 *  2009/02/03    1.06  R.Takigawa       データ抽出エラーのメッセージ変更
 *  2009/02/04    1.07  R.Takigawa       SQLのデータ型修正
 *  2009/02/09    1.08  R.Takigawa       ロックエラー時のメッセージ変更
 *  2009/05/15    1.1   H.Yoshikawa      障害T1_0569,T1_0588 対応
 *  2009/08/11    1.2   Y.Kuboshima      障害0000894 対応
 *  2010/04/07    1.3   Y.Kuboshima      障害E_本稼動02018 対応 標準原価 > 営業原価の場合、エラー -> 警告とするよう修正
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
  cv_pkg_name                CONSTANT VARCHAR2(100) := 'XXCMM004A07C';       -- パッケージ名
  cv_msg_comma               CONSTANT VARCHAR2(3)   := ',';                  -- カンマ
  --
  cv_yes                     CONSTANT VARCHAR2(1)   := 'Y';                  -- Y
  cv_no                      CONSTANT VARCHAR2(1)   := 'N';                  -- N
  --
  cv_upd_div_upd             CONSTANT VARCHAR2(1)   := 'U';                  -- 更新区分(U)
  cv_date_fmt_std            CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_date_fmt_std;
                                                                             -- 日付書式：YYYY/MM/DD
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
-- Ver1.03
--  cv_msg_xxcmm_00409         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00409';   -- データ抽出エラー
-- End1.03
-- Ver1.1  2009/05/15  Add  T1_0588 対応
  cv_msg_xxcmm_00429         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00429';   -- 品目ステータスエラー
-- End
-- Ver1.06
  cv_msg_xxcmm_00439         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00439';   -- データ抽出エラー
-- End1.03
  cv_msg_xxcmm_00440         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00440';   -- パラメータチェックエラー
-- Ver1.08 Add メッセージ追加 2009/02/09
  cv_msg_xxcmm_00443         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00443';   -- ロック取得エラー
-- End1.08
  cv_msg_xxcmm_00455         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00455';   -- 起動種別エラー
  cv_msg_xxcmm_00456         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00456';   -- ファイル項目チェックエラー
  cv_msg_xxcmm_00457         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00457';   -- 適用日チェックエラー
  cv_msg_xxcmm_00458         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00458';   -- 親品目チェックエラー
  cv_msg_xxcmm_00459         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00459';   -- マスタチェックエラー
  cv_msg_xxcmm_00460         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00460';   -- 営業原価チェックエラー
  cv_msg_xxcmm_00461         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00461';   -- 営業原価比較エラー
  cv_msg_xxcmm_00463         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00463';   -- ファイル内重複エラー
  cv_msg_xxcmm_00464         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00464';   -- 重複エラー
  cv_msg_xxcmm_00466         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00466';   -- データ登録エラー
  cv_msg_xxcmm_00467         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00467';   -- データ更新エラー
  cv_msg_xxcmm_00468         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00468';   -- データ削除エラー
-- 2010/04/07 Ver1.3 E_本稼動_02018 add start by Y.Kuboshima
  cv_msg_xxcmm_00495         CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00495';   -- 営業原価比較エラー
-- 2010/04/07 Ver1.3 E_本稼動_02018 add end by Y.Kuboshima
  --
  --トークンコード
  cv_tkn_table               CONSTANT VARCHAR2(20)  := 'TABLE';              -- テーブル名
-- Ver1.08 Add メッセージ追加 2009/02/09
  cv_tkn_item_code           CONSTANT VARCHAR2(20)  := 'ITEM_CODE';          -- 品目コード
-- End1.08
  cv_tkn_ng_table            CONSTANT VARCHAR2(20)  := 'NG_TABLE';           -- ロック取得エラーテーブル名
  cv_tkn_count               CONSTANT VARCHAR2(20)  := 'COUNT';              -- 項目数チェック件数
  cv_tkn_profile             CONSTANT VARCHAR2(20)  := 'NG_PROFILE';         -- プロファイル名
  cv_tkn_param_name          CONSTANT VARCHAR2(20)  := 'PARAM_NAME';         -- パラメータ名
  cv_tkn_input_col_name      CONSTANT VARCHAR2(20)  := 'INPUT_COL_NAME';     -- 項目名称
  cv_tkn_cost_type           CONSTANT VARCHAR2(20)  := 'COST_TYPE ';         -- 原価タイプ
  cv_tkn_input_cost          CONSTANT VARCHAR2(20)  := 'INPUT_COST';         -- 入力原価(営業原価)
  cv_tkn_disc_cost           CONSTANT VARCHAR2(20)  := 'DISC_COST';          -- 営業原価
  cv_tkn_opm_cost            CONSTANT VARCHAR2(20)  := 'OPM_COST';           -- 標準原価
  cv_tkn_input_item          CONSTANT VARCHAR2(20)  := 'INPUT_ITEM';         -- 品目コード
  cv_tkn_input_apply_date    CONSTANT VARCHAR2(20)  := 'INPUT_APPLY_DATE';   -- 適用日
  cv_tkn_err_msg             CONSTANT VARCHAR2(20)  := 'ERR_MSG';            -- エラーメッセージ
-- Ver1.03
  --cv_tkn_errmsg              CONSTANT VARCHAR2(20)  := 'ERRMSG';             -- エラー内容
  cv_tkn_input_line_no       CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';      -- インタフェースの行番号
  cv_tkn_input_item_code     CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';    -- インタフェースの品名コード
-- Ver1.1  2009/05/15  Add  T1_0588 対応
  cv_tkn_item_status         CONSTANT VARCHAR2(20)  := 'ITEM_STATUS';        -- 品目ステータス名
-- End  --
  cv_table_flv               CONSTANT VARCHAR2(30)  := 'LOOKUP表';           -- FND_LOOKUP_VALUES_VL
-- End1.03
  cv_tkn_val_proc_name       CONSTANT VARCHAR2(30)  := '営業原価一括改定';
  cv_tkn_val_fmt_pattern     CONSTANT VARCHAR2(30)  := 'フォーマットパターン';
  cv_tkn_val_disc_cost       CONSTANT VARCHAR2(30)  := '営業原価';
  cv_tkn_val_file_ul_if      CONSTANT VARCHAR2(30)  := 'ファイルアップロードＩ／Ｆ';
  cv_tkn_val_wk_disc_cost    CONSTANT VARCHAR2(30)  := '営業原価一括改定ワーク';
  cv_tkn_val_disc_hst        CONSTANT VARCHAR2(30)  := 'Disc品目変更履歴アドオン';
  cv_tkn_val_disc_item       CONSTANT VARCHAR2(30)  := 'Disc品目マスタ';
-- Ver1.04
  cv_tkn_val_profile         CONSTANT VARCHAR2(50)  := 'XXCMM:営業原価一括改定データ項目数';
-- End1.04
  --
  cv_lookup_cost_cmpt        CONSTANT VARCHAR2(20)  := 'XXCMM1_COST_CMPT';   -- 標準原価コンポーネント
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
  TYPE g_disc_hst_rtype IS RECORD(
    item_id                  xxcmm_system_items_b_hst.item_id%TYPE           -- 品目ID
   ,item_code                xxcmm_system_items_b_hst.item_code%TYPE         -- 品目コード
   ,apply_date               xxcmm_system_items_b_hst.apply_date%TYPE        -- 適用日
   ,discrete_cost            xxcmm_system_items_b_hst.discrete_cost%TYPE     -- 営業原価
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
   * Description      : 終了処理 (A-8)
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
    --
    --==============================================================
    --A-8.1 チェックエラー存在時(SAVEPOINT まで ROLLBACK)
    --==============================================================
    IF ( gn_error_cnt > 0 ) THEN
      --==============================================================
      --A-8.1 チェックエラー存在時(SAVEPOINT まで ROLLBACK)
      --==============================================================
      lv_step := 'A-8.1';
      -- SAVEPOINTまで ROLLBACK
      ROLLBACK TO xxcmm004a07c_savepoint;
      --
    ELSE
      --==============================================================
      --A-8.2 営業原価一括改定データ削除
      --==============================================================
      BEGIN
        lv_step := 'A-8.2';
        DELETE  FROM    xxcmm_wk_disccost_batch_regist;
        --
      EXCEPTION
        -- *** データ削除例外ハンドラ ***
        WHEN OTHERS THEN
          --
          lv_errmsg  := xxccp_common_pkg.get_msg(
                          iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                         ,iv_name          =>  cv_msg_xxcmm_00468          -- メッセージコード
                         ,iv_token_name1   =>  cv_tkn_table                -- トークンコード1
                         ,iv_token_value1  =>  cv_tkn_val_wk_disc_cost     -- トークン値1
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
    --A-8.3 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      lv_step := 'A-8.3';
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
   * Procedure Name   : update_disc_hst
   * Description      : Disc品目変更履歴アドオン更新 (A-7)
   ***********************************************************************************/
  PROCEDURE update_disc_hst(
    i_disc_hst_rec    IN       g_disc_hst_rtype                                -- 標準原価改定データ
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'UPDATE_DISC_HST';    -- プログラム名
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
    --
    ln_item_hst_id             xxcmm_system_items_b_hst.item_hst_id%TYPE;
    --
    -- Disc品目変更履歴アドオンロックカーソル
    CURSOR lock_disc_hst_cur(
      p_item_id       NUMBER
     ,p_apply_date    DATE )
    IS
      SELECT    xsibh.item_hst_id                       -- 品目変更履歴ID
      FROM      xxcmm_system_items_b_hst    xsibh       -- Disc品目変更履歴アドオン
      WHERE     xsibh.item_id        = p_item_id        -- 品目ID
      AND       xsibh.apply_date     = p_apply_date     -- 適用日
      AND       xsibh.apply_flag     = cv_no            -- 適用フラグ
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
    --==============================================================
    --A-7.1 Disc品目変更履歴アドオンのロック取得
    --==============================================================
    lv_step := 'A-7.1';
    OPEN  lock_disc_hst_cur(
            i_disc_hst_rec.item_id
           ,i_disc_hst_rec.apply_date
          );
    FETCH lock_disc_hst_cur INTO ln_item_hst_id;
    CLOSE lock_disc_hst_cur;
    --
    --==============================================================
    --A-7.2 Disc品目変更履歴アドオンの更新
    --==============================================================
    lv_step := 'A-7.2';
    BEGIN
      UPDATE  xxcmm_system_items_b_hst
      SET     discrete_cost          = i_disc_hst_rec.discrete_cost     -- 営業原価
             ,last_updated_by        = cn_last_updated_by               -- 最終更新者
             ,last_update_date       = cd_last_update_date              -- 最終更新日
             ,last_update_login      = cn_last_update_login             -- 最終更新ﾛｸﾞｲﾝ
             ,request_id             = cn_request_id                    -- 要求ID
             ,program_application_id = cn_program_application_id        -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
             ,program_id             = cn_program_id                    -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
             ,program_update_date    = cd_program_update_date           -- ﾌﾟﾛｸﾞﾗﾑ更新日
      WHERE   item_hst_id            = ln_item_hst_id;
      --
    EXCEPTION
      -- *** データ更新例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxcmm_00467          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_table                -- トークンコード1
                       ,iv_token_value1  =>  cv_tkn_val_disc_hst         -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_item           -- トークンコード2
                       ,iv_token_value2  =>  i_disc_hst_rec.item_code    -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_input_apply_date     -- トークンコード3
                       ,iv_token_value3  =>  TO_CHAR( i_disc_hst_rec.apply_date
                                                    , cv_date_fmt_std )  -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_err_msg              -- トークンコード4
                       ,iv_token_value4  =>  SQLERRM                     -- トークン値4
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
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
-- Ver1.08 Mod ロックエラー時のメッセージ変更 2009/02/09
      lv_errmsg  := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_name_xxcmm        -- アプリケーション短縮名
--                     ,iv_name         => cv_msg_xxcmm_00008      -- メッセージコード
                     ,iv_name         => cv_msg_xxcmm_00443        -- メッセージコード
--                     ,iv_token_name1  => cv_tkn_ng_table           -- トークンコード1
                     ,iv_token_name1  => cv_tkn_table           -- トークンコード1
                     ,iv_token_value1 => cv_tkn_val_disc_hst       -- トークン値1
--                     ,iv_token_name2  => cv_tkn_input_item         -- トークンコード2
                     ,iv_token_name2  => cv_tkn_item_code         -- トークンコード2
                    ,iv_token_value2 => i_disc_hst_rec.item_code  -- トークン値2
-- End1.08
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
      --
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
  END update_disc_hst;
--
--
  /**********************************************************************************
   * Procedure Name   : insert_disc_hst
   * Description      : Disc品目変更履歴アドオン挿入 (A-6)
   ***********************************************************************************/
  PROCEDURE insert_disc_hst(
    i_disc_hst_rec    IN       g_disc_hst_rtype                                -- 標準原価改定データ
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'INSERT_DISC_HST';    -- プログラム名
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
    --==============================================================
    --A-6 Disc品目変更履歴アドオン挿入
    --==============================================================
    lv_step := 'A-6.1';
    BEGIN
      INSERT INTO xxcmm_system_items_b_hst(
        item_hst_id                           -- 品目変更履歴ID
       ,item_id                               -- 品目ID
       ,item_code                             -- 品目コード
       ,apply_date                            -- 適用日（適用開始日）
       ,apply_flag                            -- 適用有無
       ,item_status                           -- 品目ステータス
       ,policy_group                          -- 政策群コード
       ,fixed_price                           -- 定価
       ,discrete_cost                         -- 営業原価
       ,first_apply_flag                      -- 初回適用フラグ
       ,created_by                            -- 作成者
       ,creation_date                         -- 作成日
       ,last_updated_by                       -- 最終更新者
       ,last_update_date                      -- 最終更新日
       ,last_update_login                     -- 最終更新ﾛｸﾞｲﾝ
       ,request_id                            -- 要求ID
       ,program_application_id                -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       ,program_id                            -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       ,program_update_date )                 -- ﾌﾟﾛｸﾞﾗﾑ更新日
      VALUES(
        xxcmm_system_items_b_hst_s.NEXTVAL    -- 品目変更履歴ID
       ,i_disc_hst_rec.item_id                -- 品目ID
       ,i_disc_hst_rec.item_code              -- 品目コード
       ,i_disc_hst_rec.apply_date             -- 適用日（適用開始日）
       ,cv_no                                 -- 適用有無
       ,NULL                                  -- 品目ステータス
       ,NULL                                  -- 政策群コード
       ,NULL                                  -- 定価
       ,i_disc_hst_rec.discrete_cost          -- 営業原価
       ,cv_no                                 -- 初回適用フラグ
       ,cn_created_by                         -- 作成者
       ,cd_creation_date                      -- 作成日
       ,cn_last_updated_by                    -- 最終更新者
       ,cd_last_update_date                   -- 最終更新日
       ,cn_last_update_login                  -- 最終更新ﾛｸﾞｲﾝ
       ,cn_request_id                         -- 要求ID
       ,cn_program_application_id             -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
       ,cn_program_id                         -- ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
       ,cd_program_update_date                -- ﾌﾟﾛｸﾞﾗﾑ更新日
      );
      --
    EXCEPTION
      -- *** データ登録例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg  := xxccp_common_pkg.get_msg(
                        iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                       ,iv_name          =>  cv_msg_xxcmm_00466          -- メッセージコード
                       ,iv_token_name1   =>  cv_tkn_table                -- トークンコード1
                       ,iv_token_value1  =>  cv_tkn_val_disc_hst         -- トークン値1
                       ,iv_token_name2   =>  cv_tkn_input_item           -- トークンコード2
                       ,iv_token_value2  =>  i_disc_hst_rec.item_code    -- トークン値2
                       ,iv_token_name3   =>  cv_tkn_input_apply_date     -- トークンコード3
                       ,iv_token_value3  =>  TO_CHAR( i_disc_hst_rec.apply_date
                                                    , cv_date_fmt_std )  -- トークン値3
                       ,iv_token_name4   =>  cv_tkn_err_msg              -- トークンコード4
                       ,iv_token_value4  =>  SQLERRM                     -- トークン値4
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
  END insert_disc_hst;
--
--
  /**********************************************************************************
   * Procedure Name   : proc_disc_hst_ref
   * Description      : Disc品目変更履歴反映 (A-5、A-6、A-7)
   ***********************************************************************************/
  PROCEDURE proc_disc_hst_ref(
    i_disc_hst_rec    IN       g_disc_hst_rtype                                -- 標準原価改定データ
   ,ov_errbuf         OUT      VARCHAR2                                        -- エラー・メッセージ
   ,ov_retcode        OUT      VARCHAR2                                        -- リターン・コード
   ,ov_errmsg         OUT      VARCHAR2                                        -- ユーザー・エラー・メッセージ
  )
  --
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100) := 'PROC_DISC_HST_REF';  -- プログラム名
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
    ln_exists_cnt              NUMBER;
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
    lv_step := 'A-5.1';
    SELECT    COUNT( xsibh.ROWID )
    INTO      ln_exists_cnt
    FROM      xxcmm_system_items_b_hst    xsibh                     -- Disc品目変更履歴アドオン
    WHERE     xsibh.item_id        = i_disc_hst_rec.item_id         -- 品目ID
    AND       xsibh.apply_date     = i_disc_hst_rec.apply_date      -- 適用日
    AND       xsibh.apply_flag     = cv_no                          -- 適用フラグ
    AND       ROWNUM               = 1;
    --
    IF ( ln_exists_cnt = 0 ) THEN
      --==============================================================
      --A-6 Disc品目変更履歴アドオン挿入
      --==============================================================
      lv_step := 'A-6';
      insert_disc_hst(
        i_disc_hst_rec   =>  i_disc_hst_rec
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      -- 戻り値がエラーの場合
      IF ( lv_retcode = cv_status_error ) THEN
        ov_retcode := cv_status_error;
      END IF;
    ELSE
      --==============================================================
      --A-7 Disc品目変更履歴アドオン更新
      --==============================================================
      lv_step := 'A-7';
      update_disc_hst(
        i_disc_hst_rec   =>  i_disc_hst_rec
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      -- 戻り値がエラーの場合
      IF ( lv_retcode = cv_status_error ) THEN
        ov_retcode := cv_status_error;
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
  END proc_disc_hst_ref;
--
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : データ妥当性チェック (A-4)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_disc_cost_rec   IN       xxcmm_wk_disccost_batch_regist%ROWTYPE          -- 変換前標準原価改定データ
   ,o_disc_hst_rec    OUT      g_disc_hst_rtype                                -- 変換後標準原価改定データ
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
-- Ver1.1  2009/05/15  Add  T1_0588 対応
    -- ルックアップ
    cv_lookup_item_status      CONSTANT VARCHAR2(20)  := 'XXCMM_ITM_STATUS';   -- 品目ステータス
    --
    -- 品目ステータス
    cn_itm_status_num_tmp      CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_num_tmp;
                                                                               -- 仮採番
    cn_itm_status_no_use       CONSTANT NUMBER        := xxcmm_004common_pkg.cn_itm_status_no_use;
                                                                               -- Ｄ
-- End
    -- 標準原価
    cv_whse_code               CONSTANT VARCHAR2(3)   := xxcmm_004common_pkg.cv_whse_code;
                                                                               -- 倉庫
    cv_cost_mthd_code          CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_mthd_code;
                                                                               -- 原価方法
    cv_cost_analysis_code      CONSTANT VARCHAR2(4)   := xxcmm_004common_pkg.cv_cost_analysis_code;
                                                                               -- 分析コード
    --
    -- *** ローカル変数 ***
    lv_step                    VARCHAR2(10);
    lv_warnig_flg              VARCHAR2(1);
    ln_column_cnt              NUMBER;
    --
    ln_exists_cnt              NUMBER;
    lv_item_no                 ic_item_mst_b.item_no%TYPE;
    ln_inventory_item_id       mtl_system_items_b.inventory_item_id%TYPE;
    ln_opm_cost                NUMBER;
    --
-- Ver1.1  2009/05/15  Add  T1_0588 対応
    ln_item_status             xxcmm_system_items_b.item_status%TYPE;
    lv_item_status_name        VARCHAR2(10);
-- End
    l_validate_disc_cost_tab   g_check_data_ttype;
    l_disc_hst_rec             g_disc_hst_rtype;
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
    lv_warnig_flg                 := cv_status_normal;
    --
    -- 品目ID
    l_validate_disc_cost_tab( 1 ) := i_disc_cost_rec.item_id;
    -- 品目コード
    l_validate_disc_cost_tab( 2 ) := i_disc_cost_rec.item_no;
    -- 適用日
    l_validate_disc_cost_tab( 3 ) := i_disc_cost_rec.apply_date;
    -- 営業原価
    l_validate_disc_cost_tab( 4 ) := i_disc_cost_rec.discrete_cost;
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
-- Ver1.01
--      IF ( lv_retcode = cv_status_error ) THEN
      IF ( lv_retcode != cv_status_normal ) THEN
-- End1.01
        -- ファイル項目チェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm                        -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00456                        -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_col_name                     -- トークンコード1
                        ,iv_token_value1  =>  g_def_info_tab( ln_column_cnt ).meaning   -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_item                         -- トークンコード2
                        ,iv_token_value2  =>  i_disc_cost_rec.item_no                   -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_apply_date                   -- トークンコード3
                        ,iv_token_value3  =>  i_disc_cost_rec.apply_date                -- トークン値3
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
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      lv_step := 'A-4.2';
      -- 各項目に格納
      l_disc_hst_rec.item_id       := TO_NUMBER( i_disc_cost_rec.item_id );
      l_disc_hst_rec.apply_date    := fnd_date.canonical_to_date( i_disc_cost_rec.apply_date );
      l_disc_hst_rec.discrete_cost := TO_NUMBER( i_disc_cost_rec.discrete_cost );
      --
      --==============================================================
      --A-4.2 親品目チェック
      --==============================================================
      BEGIN
        --
        SELECT    xoiv.item_no                                            -- 品目コード
-- Ver1.1  2009/05/15  Add  T1_0588 対応
                 ,NVL( xoiv.item_status, cn_itm_status_num_tmp )
                                      AS item_status                      -- 品目ステータス
                 ,flvv.meaning        AS item_status_name                 -- 品目ステータス名
-- End
        INTO      lv_item_no
-- Ver1.1  2009/05/15  Add  T1_0588 対応
                 ,ln_item_status
                 ,lv_item_status_name
-- End
        FROM      xxcmm_opmmtl_items_v       xoiv                         -- 品目ビュー
-- Ver1.1  2009/05/15  Add  T1_0588 対応
                 ,fnd_lookup_values_vl       flvv                         -- LOOKUP表
-- End
        WHERE     xoiv.item_id             = l_disc_hst_rec.item_id       -- 品目ID
        AND       xoiv.item_id             = xoiv.parent_item_id          -- 親品目
-- Ver1.1  2009/05/15  Add  T1_0588 対応
        AND       flvv.lookup_type         = cv_lookup_item_status        -- XXCMM_ITM_STATUS
        AND       flvv.lookup_code         = TO_CHAR( NVL( xoiv.item_status, cn_itm_status_num_tmp ))
                                                                          -- 品目ステータス
-- End
-- 2009/08/11 Ver1.2 modify start by Y.Kuboshima
--        AND       xoiv.start_date_active  <= TRUNC( SYSDATE )             -- 適用開始日
--        AND       xoiv.end_date_active    >= TRUNC( SYSDATE );            -- 適用終了日
        AND       xoiv.start_date_active  <= gd_process_date              -- 適用開始日
        AND       xoiv.end_date_active    >= gd_process_date;             -- 適用終了日
-- 2009/08/11 Ver1.2 modify end by Y.Kuboshima
        --
        l_disc_hst_rec.item_code     := lv_item_no;
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- 親品目チェックエラー
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_00458          -- メッセージコード
                          ,iv_token_name1   =>  cv_tkn_input_item           -- トークンコード1
                          ,iv_token_value1  =>  i_disc_cost_rec.item_no     -- トークン値1
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
-- Ver1.1  2009/05/15  Add  T1_0588 対応
      -- 品目ステータス：仮採番、または、Ｄの場合エラー。
      --   仮採番：営業組織(Z99)に品目割当されていないため
      --   Ｄ    ：品目情報変更不可のため
      IF ( ln_item_status IN ( cn_itm_status_num_tmp, cn_itm_status_no_use ) ) THEN
        -- 営業原価チェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00429              -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_item               -- トークンコード1
                        ,iv_token_value1  =>  i_disc_cost_rec.item_no         -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_item_status              -- トークンコード2
                        ,iv_token_value2  =>  TO_CHAR( ln_item_status ) || cv_msg_part || 
                                              lv_item_status_name             -- トークン値2
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
-- End
      --
      --==============================================================
      --A-4.3 Disc品目存在チェック
      --==============================================================
      lv_step := 'A-4.3';
      BEGIN
        --
        SELECT    xoiv.inventory_item_id          inventory_item_id         -- Disc品目ID
        INTO      ln_inventory_item_id
        FROM      xxcmm_opmmtl_items_v            xoiv                      -- Disc品目マスタ
        WHERE     xoiv.item_no         = lv_item_no                         -- 品目コード
-- 2009/08/11 Ver1.2 modify start by Y.Kuboshima
--        AND       xoiv.start_date_active  <= TRUNC( SYSDATE )               -- 適用開始日
--        AND       xoiv.end_date_active    >= TRUNC( SYSDATE );              -- 適用終了日
        AND       xoiv.start_date_active  <= gd_process_date                -- 適用開始日
        AND       xoiv.end_date_active    >= gd_process_date;               -- 適用終了日
-- 2009/08/11 Ver1.2 modify end by Y.Kuboshima
        --
      EXCEPTION
        WHEN OTHERS THEN
          -- マスタチェックエラー
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm          -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_00459          -- メッセージコード
                          ,iv_token_name1   =>  cv_tkn_input_item           -- トークンコード1
                          ,iv_token_value1  =>  i_disc_cost_rec.item_no     -- トークン値1
                          ,iv_token_name2   =>  cv_tkn_table                -- トークンコード2
                          ,iv_token_value2  =>  cv_tkn_val_disc_item        -- トークン値2
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
      -- 未来日のみ指定可能
      lv_step := 'A-4.4';
      IF ( l_disc_hst_rec.apply_date <= gd_process_date ) THEN
        -- マスタチェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00457            -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_item             -- トークンコード1
                        ,iv_token_value1  =>  i_disc_cost_rec.item_no       -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date       -- トークンコード2
                        ,iv_token_value2  =>  i_disc_cost_rec.apply_date    -- トークン値2
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
      SELECT    COUNT( xwdbr.ROWID )
      INTO      ln_exists_cnt
      FROM      xxcmm_wk_disccost_batch_regist    xwdbr                     -- 営業原価一括改定ワーク
      WHERE     xwdbr.file_id             = gn_file_id                      -- ファイルID
      AND       xwdbr.update_div          = cv_upd_div_upd                  -- 更新区分
-- Ver1.07 Mod TRIMを追加
      AND       TRIM( xwdbr.item_id )     = i_disc_cost_rec.item_id         -- 品目ID
-- End1.07
      AND       TRIM( xwdbr.apply_date )  = i_disc_cost_rec.apply_date      -- 適用日
      AND       xwdbr.file_seq           != i_disc_cost_rec.file_seq        -- ファイルシーケンス
      AND       ROWNUM                    = 1;
      --
      IF ( ln_exists_cnt >= 1 ) THEN
        -- ファイル内重複エラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00463            -- メッセージコード
-- Ver1.02
                        ,iv_token_name1   =>  cv_tkn_cost_type              -- トークンコード1
                        ,iv_token_value1  =>  cv_tkn_val_disc_cost          -- トークン値1
-- End1.02
                        ,iv_token_name2   =>  cv_tkn_input_item             -- トークンコード2
                        ,iv_token_value2  =>  i_disc_cost_rec.item_no       -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_apply_date       -- トークンコード3
                        ,iv_token_value3  =>  i_disc_cost_rec.apply_date    -- トークン値3
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
      --A-4.6 変更予約済みチェック
      --==============================================================
      lv_step := 'A-4.6';
      SELECT    COUNT( xsibh.ROWID )
      INTO      ln_exists_cnt
      FROM      xxcmm_system_items_b_hst    xsibh                     -- Disc品目変更履歴アドオン
-- Ver1.07 Mod 品目IDの型をVARCHAR2からNUMBERに変更
--      WHERE     xsibh.item_id        = i_disc_cost_rec.item_id        -- 品目ID
      WHERE     xsibh.item_id        = l_disc_hst_rec.item_id        -- 品目ID
-- End1.07
      AND       xsibh.apply_date     = l_disc_hst_rec.apply_date      -- 適用日
      AND       xsibh.apply_flag     = cv_no                          -- 適用フラグ
      AND       xsibh.discrete_cost IS NOT NULL                       -- 営業原価
      AND       ROWNUM               = 1;
      --
      IF ( ln_exists_cnt >= 1 ) THEN
        -- 重複エラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm            -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00464            -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_input_item             -- トークンコード1
                        ,iv_token_value1  =>  i_disc_cost_rec.item_no       -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_apply_date       -- トークンコード2
                        ,iv_token_value2  =>  i_disc_cost_rec.apply_date    -- トークン値2
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
      --A-4.7 営業原価チェック
      --==============================================================
      lv_step := 'A-4.7';
      IF ( l_disc_hst_rec.discrete_cost < 0 )
      OR ( l_disc_hst_rec.discrete_cost <> TRUNC( l_disc_hst_rec.discrete_cost ) ) THEN
        -- 営業原価チェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- アプリケーション短縮名
                        ,iv_name          =>  cv_msg_xxcmm_00464              -- メッセージコード
                        ,iv_token_name1   =>  cv_tkn_cost_type                -- トークンコード1
                        ,iv_token_value1  =>  cv_tkn_val_disc_cost            -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_input_cost               -- トークンコード2
                        ,iv_token_value2  =>  i_disc_cost_rec.discrete_cost   -- トークン値2
                        ,iv_token_name3   =>  cv_tkn_input_item               -- トークンコード3
                        ,iv_token_value3  =>  i_disc_cost_rec.item_no         -- トークン値3
                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- トークンコード4
                        ,iv_token_value4  =>  i_disc_cost_rec.apply_date      -- トークン値4
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
      --A-4.8 営業原価と標準原価の比較
      --==============================================================
      lv_step := 'A-4.8';
      SELECT    SUM( NVL( ccmd.cmpnt_cost, 0 ) )    -- 標準原価
      INTO      ln_opm_cost
      FROM      cm_cmpt_dtl          ccmd,          -- OPM標準原価
                cm_cldr_dtl          cclr,          -- OPM原価カレンダ
                cm_cmpt_mst_vl       ccmv,          -- 原価コンポーネント
                fnd_lookup_values_vl flv            -- 参照コード値
      WHERE     ccmd.item_id             = l_disc_hst_rec.item_id     -- 品目ID
      AND       cclr.start_date         <= l_disc_hst_rec.apply_date  -- 開始日
      AND       cclr.end_date           >= l_disc_hst_rec.apply_date  -- 終了日
      AND       flv.lookup_type          = cv_lookup_cost_cmpt        -- 参照タイプ
      AND       flv.enabled_flag         = cv_yes                     -- 使用可能
      AND       ccmv.cost_cmpntcls_code  = flv.meaning                -- 原価コンポーネントコード
      AND       ccmd.cost_cmpntcls_id    = ccmv.cost_cmpntcls_id      -- 原価コンポーネントID
      AND       ccmd.calendar_code       = cclr.calendar_code         -- カレンダコード
      AND       ccmd.period_code         = cclr.period_code           -- 期間コード
      AND       ccmd.whse_code           = cv_whse_code               -- 倉庫
      AND       ccmd.cost_mthd_code      = cv_cost_mthd_code          -- 原価方法
      AND       ccmd.cost_analysis_code  = cv_cost_analysis_code;     -- 分析コード
      --
      IF ( l_disc_hst_rec.discrete_cost < ln_opm_cost ) THEN
        -- 営業原価チェックエラー
        lv_errmsg  :=  xxccp_common_pkg.get_msg(
                         iv_application   =>  cv_appl_name_xxcmm              -- アプリケーション短縮名
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify start by Y.Kuboshima
--                        ,iv_name          =>  cv_msg_xxcmm_00461              -- メッセージコード
                        ,iv_name          =>  cv_msg_xxcmm_00495              -- メッセージコード
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify end by Y.Kuboshima
                        ,iv_token_name1   =>  cv_tkn_disc_cost                -- トークンコード1
                        ,iv_token_value1  =>  i_disc_cost_rec.discrete_cost   -- トークン値1
                        ,iv_token_name2   =>  cv_tkn_opm_cost                 -- トークンコード2
                        ,iv_token_value2  =>  TO_CHAR( ln_opm_cost )          -- トークン値2
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify start by Y.Kuboshima
--                        ,iv_token_name3   =>  cv_tkn_input_item               -- トークンコード3
--                        ,iv_token_value3  =>  i_disc_cost_rec.item_no         -- トークン値3
--                        ,iv_token_name4   =>  cv_tkn_input_apply_date         -- トークンコード4
--                        ,iv_token_value4  =>  i_disc_cost_rec.apply_date      -- トークン値4
                        ,iv_token_name3   =>  cv_tkn_item_code                -- トークンコード3
                        ,iv_token_value3  =>  i_disc_cost_rec.item_no         -- トークン値3
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify end by Y.Kuboshima
                       );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff  =>  lv_errmsg
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify start by Y.Kuboshima
--        -- ステータスをエラーにする。
--        lv_warnig_flg := cv_status_error;
        -- ステータスを警告にする。
        IF ( lv_warnig_flg = cv_status_normal ) THEN
          lv_warnig_flg := cv_status_warn;
        END IF;
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify end by Y.Kuboshima
      END IF;
    END IF;
    --
    IF ( lv_warnig_flg = cv_status_normal ) THEN
      -- 型変換実施後OUT変数に格納
      o_disc_hst_rec := l_disc_hst_rec;
-- 2010/04/07 Ver1.3 E_本稼動_02018 add start by Y.Kuboshima
    ELSIF ( lv_warnig_flg = cv_status_warn ) THEN
      -- 型変換実施後OUT変数に格納
      o_disc_hst_rec  := l_disc_hst_rec;
      ov_retcode      := cv_status_warn;
-- 2010/04/07 Ver1.3 E_本稼動_02018 add end by Y.Kuboshima
    ELSE
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
   * Description      : 営業原価一括改定ワークの取得 (A-3)
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
-- 2010/04/07 Ver1.3 E_本稼動_02018 add start by Y.Kuboshima
    lv_vi_retcode              VARCHAR2(1);                                    -- データ妥当性チェックのリターン・コード
-- 2010/04/07 Ver1.3 E_本稼動_02018 add end by Y.Kuboshima
    --
    -- *** カーソル ***
    -- 営業原価一括改定データ取得カーソル
    CURSOR get_data_cur
    IS
      SELECT    xwdbr.file_id                                 -- ファイルID
               ,xwdbr.file_seq                                -- ファイルシーケンス
               ,TRIM( xwdbr.item_id )        item_id          -- 品目ID
               ,TRIM( xwdbr.item_no )        item_no          -- 品目コード
               ,TRIM( xwdbr.apply_date )     apply_date       -- 適用日
               ,TRIM( xwdbr.discrete_cost )  discrete_cost    -- 営業原価
               ,xwdbr.update_div                              -- ★更新区分(使用しない)
               ,xwdbr.created_by                              -- ★作成者(使用しない)
               ,xwdbr.creation_date                           -- ★作成日(使用しない)
               ,xwdbr.last_updated_by                         -- ★最終更新者(使用しない)
               ,xwdbr.last_update_date                        -- ★最終更新日(使用しない)
               ,xwdbr.last_update_login                       -- ★最終更新ﾛｸﾞｲﾝ(使用しない)
               ,xwdbr.request_id                              -- ★要求ID(使用しない)
               ,xwdbr.program_application_id                  -- ★ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID(使用しない)
               ,xwdbr.program_id                              -- ★ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID(使用しない)
               ,xwdbr.program_update_date                     -- ★ﾌﾟﾛｸﾞﾗﾑ更新日(使用しない)
      FROM      xxcmm_wk_disccost_batch_regist    xwdbr       -- 営業原価一括改定ワーク
      WHERE     xwdbr.file_id    = gn_file_id                 -- ファイルID
      AND       xwdbr.update_div = cv_upd_div_upd             -- 更新区分
      ORDER BY  xwdbr.file_seq;                               -- ファイルシーケンス
    --
    l_disc_hst_rec             g_disc_hst_rtype;
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
    --A-3 営業原価一括改定ワークの取得
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
        i_disc_cost_rec   =>  l_get_data_rec
       ,o_disc_hst_rec    =>  l_disc_hst_rec
       ,ov_errbuf         =>  lv_errbuf
       ,ov_retcode        =>  lv_retcode
       ,ov_errmsg         =>  lv_errmsg
      );
      --
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify start by Y.Kuboshima
--      -- データ妥当性チェック結果が正常のもののみ登録・更新処理へ
--      IF ( lv_retcode = cv_status_normal ) THEN
      -- データ妥当性チェックのリターン・コードを保持
      lv_vi_retcode := lv_retcode;
      --
      -- データ妥当性チェック結果がエラー以外のもののみ登録・更新処理へ
      IF ( lv_retcode <> cv_status_error ) THEN
-- 2010/04/07 Ver1.3 E_本稼動_02018 modify end by Y.Kuboshima
        --==============================================================
        -- Disc品目変更履歴反映
        --  A-5 品目変更履歴アドオン登録・更新判定
        --  A-6 Disc品目変更履歴アドオン挿入
        --  A-7 Disc品目変更履歴アドオン更新
        --==============================================================
        lv_step := 'A-5';
        proc_disc_hst_ref(
          i_disc_hst_rec   =>  l_disc_hst_rec
         ,ov_errbuf        =>  lv_errbuf
         ,ov_retcode       =>  lv_retcode
         ,ov_errmsg        =>  lv_errmsg
        );
        --
      END IF;
      --
      IF ( lv_retcode = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
-- 2010/04/07 Ver1.3 E_本稼動_02018 add start by Y.Kuboshima
        IF ( lv_vi_retcode = cv_status_warn ) THEN
          gn_warn_cnt   := gn_warn_cnt + 1;
        END IF;
-- 2010/04/07 Ver1.3 E_本稼動_02018 add end by Y.Kuboshima
      ELSE
        gn_error_cnt  := gn_error_cnt  + 1;
      END IF;
    END LOOP main_loop;
    --
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
-- 2010/04/07 Ver1.3 E_本稼動_02018 add start by Y.Kuboshima
    ELSIF ( gn_warn_cnt > 0 ) THEN
      ov_retcode := cv_status_warn;
-- 2010/04/07 Ver1.3 E_本稼動_02018 add end by Y.Kuboshima
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
    cv_cost_div_disc           CONSTANT NUMBER(2)     := '2';           -- 原価改定種別区分(営業原価)
    --
    -- CSVファイル内列番号
    cn_csv_item_id             CONSTANT NUMBER(2)     := 17;            -- 品目ID
    cn_csv_item_no             CONSTANT NUMBER(2)     := 2;             -- 品目コード
    cn_csv_apply_date          CONSTANT NUMBER(2)     := 14;            -- 適用日
    cn_csv_disc_cost           CONSTANT NUMBER(2)     := 11;            -- 営業原価
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
    SAVEPOINT xxcmm004a07c_savepoint;
    --
    --==============================================================
    --A-2.2 営業原価一括改定対象データの分割(レコード分割)
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
    --
-- Ver1.01 Add
    -- ステータスがエラーの場合
    IF ( lv_retcode != cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
-- End1.01
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
-- Ver1.1  2009/05/15  Mod  T1_0569対応
--          IF ( lv_cost_div != cv_cost_div_disc ) THEN
          IF ( lv_cost_div != cv_cost_div_disc )
          OR ( lv_cost_div IS NULL ) THEN
-- End
            -- 営業原価改定ではないためエラー
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
        --A-2.2 営業原価一括改定対象データの分割(項目分割)
        --==============================================================
        -------------------------------
        -- デリミタ文字変換共通関数
        -- 各項目の値を格納
        -------------------------------
        lv_step := 'A-2.2-C';
        -- 品目ID    （１７列目）
        l_disc_cost_tab( 1 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_item_id
                                );
        -- 品目コード（２列目）
        l_disc_cost_tab( 2 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_item_no
                                );
        -- 適用日    （１４列目）
        l_disc_cost_tab( 3 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_apply_date
                                );
        -- 営業原価  （１１列目）
        l_disc_cost_tab( 4 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_disc_cost
                                );
        -- 更新区分  （１３列目）
        l_disc_cost_tab( 5 ) := xxccp_common_pkg.char_delim_partition(
                                  iv_char     =>  l_if_data_tab( ln_line_cnt )
                                 ,iv_delim    =>  cv_msg_comma
                                 ,in_part_num =>  cn_csv_update_div
                                );
        lv_update_div := SUBSTRB( TRIM( l_disc_cost_tab( 5 ) ), 1, 1 );
        --
        IF ( lv_update_div = cv_upd_div_upd ) THEN
          -- 更新区分が'U'のみ対象
          gn_target_cnt := gn_target_cnt + 1;
          --
          --==============================================================
          --A-2.5 営業原価一括改定ワークへ登録
          --==============================================================
          lv_step := 'A-2.5';
          BEGIN
            ln_ins_item_cnt := ln_ins_item_cnt + 1;
            INSERT INTO  xxcmm_wk_disccost_batch_regist(
              file_id                        -- ファイルID
             ,file_seq                       -- ファイルシーケンス
             ,item_id                        -- 品目ID
             ,item_no                        -- 品目コード
             ,apply_date                     -- 適用日
             ,discrete_cost                  -- 営業原価
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
                       1, 100 )              -- 営業原価
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
                             ,iv_token_value1  =>  cv_tkn_val_wk_disc_cost    -- トークン値1
                             ,iv_token_name2   =>  cv_tkn_input_item          -- トークンコード2
                             ,iv_token_value2  =>  l_disc_cost_tab( 2 )       -- トークン値2
                             ,iv_token_name3   =>  cv_tkn_input_apply_date    -- トークンコード3
                             ,iv_token_value3  =>  l_disc_cost_tab( 3 )       -- トークン値3
                             ,iv_token_name4   =>  cv_tkn_err_msg             -- トークンコード4
                             ,iv_token_value4  =>  SQLERRM                    -- トークン値4
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
    cv_disc_cost_item          CONSTANT VARCHAR2(30) := 'XXCMM1_004A07_ITEM_DEF';                   -- 営業原価一括改定データ項目定義
    cv_item_num                CONSTANT VARCHAR2(30) := 'XXCMM1_004A07_ITEM_NUM';                   -- 営業原価一括改定データ項目数
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
-- Ver1.06
    lv_sqlerrm                VARCHAR2(5000);                         -- SQLERRMを退避
-- End1.06
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
    CURSOR get_def_info_cur                                                                       -- データ項目定義取得用カーソル
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
      WHERE    flv.lookup_type        = cv_disc_cost_item                                           -- 営業原価一括改定項目定義
      AND      flv.enabled_flag       = cv_yes                                                      -- 使用可能フラグ
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date                     -- 適用開始日
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date                     -- 適用終了日
      ORDER BY flv.lookup_code;
      --
    --
    get_param_expt             EXCEPTION;
    get_profile_expt           EXCEPTION;
-- Ver1.03
    select_expt                EXCEPTION;                              -- データ抽出エラー
-- End1.03
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
      lv_tkn_value := cv_tkn_val_profile;
      RAISE get_profile_expt;
    END IF;
    --
    --==============================================================
    --A-1.4 ファイルアップロード名称の取得
    --==============================================================
    lv_step := 'A-1.4';
    --
-- Ver1.03 Mod
/*
    SELECT   flv.meaning  meaning
    INTO     lv_upload_obj
    FROM     fnd_lookup_values_vl flv                                             -- LOOKUP表
    WHERE    flv.lookup_type        = cv_lookup_type_upload_obj                   -- ファイルアップロードオブジェクト
    AND      flv.lookup_code        = gv_format                                   -- フォーマットパターン
    AND      flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
    AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
    AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了日
*/
    BEGIN
      SELECT   flv.meaning  meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv                                             -- LOOKUP表
      WHERE    flv.lookup_type        = cv_lookup_type_upload_obj                   -- ファイルアップロードオブジェクト
      AND      flv.lookup_code        = gv_format                                   -- フォーマットパターン
      AND      flv.enabled_flag       = cv_yes                                      -- 使用可能フラグ
      AND      NVL( flv.start_date_active, gd_process_date ) <= gd_process_date     -- 適用開始日
      AND      NVL( flv.end_date_active,   gd_process_date ) >= gd_process_date;    -- 適用終了
    EXCEPTION
      WHEN OTHERS THEN
-- Ver1.06 Add
        lv_sqlerrm := SQLERRM;
-- End1.06
        RAISE select_expt;
    END;
-- End1.03
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
    --A-1.6 営業原価一括改定テーブル定義情報取得
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
-- Ver1.03
    IF ( ln_cnt = 0 ) THEN
      RAISE select_expt;
    END IF;
-- End1.03
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
-- Ver1.03 Add データ抽出エラー
-- Ver1.06 Mod データ抽出エラー
/*
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
*/
    WHEN select_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00439            -- メッセージ
                    ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                    ,iv_token_value1 => cv_table_flv                  -- トークン値1
                    ,iv_token_name2  => cv_tkn_err_msg                -- トークンコード2
                    ,iv_token_value2 => lv_sqlerrm                    -- トークン値2
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
-- End1.06
-- End1.03
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
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
-- Ver1.05
      --ov_errmsg  := lv_errmsg;
      ov_errmsg  := SUBSTRB( SQLERRM, 1, 5000 );  --2009/02/03 メッセージ変更
-- End1.05
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_cont || lv_step || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
-- Ver1.05
      ov_errmsg  := lv_errmsg;
--      ov_errmsg  := SUBSTRB( SQLERRM, 1, 5000 );  --2009/02/03 メッセージ変更
-- End1.05
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
    --A-3 営業原価一括改定ワークの取得
    --  A-4 データ妥当性チェック
    --  A-5 品目変更履歴アドオン登録・更新判定
    --  A-6 Disc品目変更履歴アドオン挿入
    --  A-7 Disc品目変更履歴アドオン更新
    --==============================================================
    lv_step := 'A-3';
    loop_main(
      ov_errbuf   =>  lv_lm_errbuf   -- エラー・メッセージ
     ,ov_retcode  =>  lv_lm_retcode  -- リターン・コード
     ,ov_errmsg   =>  lv_lm_errmsg   -- ユーザー・エラー・メッセージ
    );
    --
    --==============================================================
    --A-8.  終了処理
    --==============================================================
    lv_step := 'A-8';
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
    -- 終了lv_submain_retcode
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
    --
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
END XXCMM004A07C;
/
