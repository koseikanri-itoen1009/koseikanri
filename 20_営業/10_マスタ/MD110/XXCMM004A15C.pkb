CREATE OR REPLACE PACKAGE BODY XXCMM004A15C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A15C(body)
 * Description      : CSV形式のデータファイルから、Disc品目アドオンの更新を行います。
 * MD.050           : 品目一括更新 CMM_004_A15
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  proc_comp              終了処理 (A-5)
 *  ins_data               データ登録 (A-4)
 *  validate_item          データ妥当性チェック (A-3)
 *  get_if_data            ファイルアップロードIFデータ取得 (A-2)
                              ・validate_item
                              ・ins_data
 *  proc_init              初期処理 (A-1)
 *  submain                メイン処理プロシージャ
 *                            ・proc_init
 *                            ・get_if_data
 *                            ・proc_comp
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                            ・submain
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2021/02/19    1.0   H.Futamura       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal;             --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;               --警告:1
  cv_status_error           CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;              --異常:2
  --WHOカラム
  cn_last_updated_by        CONSTANT NUMBER      := fnd_global.user_id;                             --LAST_UPDATED_BY
  cd_last_update_date       CONSTANT DATE        := SYSDATE;                                        --LAST_UPDATE_DATE
  cn_last_update_login      CONSTANT NUMBER      := fnd_global.login_id;                            --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER      := fnd_global.conc_request_id;                     --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER      := fnd_global.prog_appl_id;                        --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER      := fnd_global.conc_program_id;                     --PROGRAM_ID
  cd_program_update_date    CONSTANT DATE        := SYSDATE;                                        --PROGRAM_UPDATE_DATE
--
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
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
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCMM004A15C';                                  -- パッケージ名
--
  -- メッセージ
  cv_msg_xxcmm_00021     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00021';                              -- ファイルアップロード名称ノート
  cv_msg_xxcmm_00022     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00022';                              -- CSVファイル名ノート
  cv_msg_xxcmm_00023     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00023';                              -- FILE_IDノート
  cv_msg_xxcmm_00024     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00024';                              -- フォーマットノート
  cv_msg_xxcmm_00028     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00028';                              -- データ項目数エラー
  cv_msg_xxcmm_00401     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00401';                              -- パラメータNULLエラー
  cv_msg_xxcmm_00403     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00403';                              -- ファイル項目チェックエラー
  cv_msg_xxcmm_00418     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00418';                              -- データ削除エラー
  cv_msg_xxcmm_00435     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00435';                              -- 取得失敗エラー
  cv_msg_xxcmm_00439     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00439';                              -- データ抽出エラー
  cv_msg_xxcmm_00800     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00800';                              -- マスタ存在チェックエラー
  cv_msg_xxcmm_00801     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00801';                              -- データ抽出エラー
  cv_msg_xxcmm_00802     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00802';                              -- データ更新エラー
  cv_msg_xxcmm_00803     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-00803';                              -- ロック取得エラー
  cv_msg_xxcmm_30400     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30400';                              -- フォーマット
  cv_msg_xxcmm_30401     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30401';                              -- 業務日付
  cv_msg_xxcmm_30402     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30402';                              -- LOOKUP表
  cv_msg_xxcmm_30403     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30403';                              -- Disc品目アドオン
  cv_msg_xxcmm_30404     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30404';                              -- ファイルアップロードIF
  cv_msg_xxcmm_30405     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30405';                              -- 品目コード
  cv_msg_xxcmm_30406     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30406';                              -- 品目一括更新
  cv_msg_xxcmm_30407     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30407';                              -- リニューアル元商品コード
  cv_msg_xxcmm_30408     CONSTANT VARCHAR2(20)  := 'APP-XXCMM1-30408';                              -- 品目マスタ
  -- トークン
  cv_tkn_value           CONSTANT VARCHAR2(20)  := 'VALUE';                                         --
  cv_tkn_up_name         CONSTANT VARCHAR2(20)  := 'UPLOAD_NAME';                                   -- ファイルアップロード名称
  cv_tkn_file_id         CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- ファイルID
  cv_tkn_file_format     CONSTANT VARCHAR2(20)  := 'FORMAT';                                        -- フォーマット
  cv_tkn_file_name       CONSTANT VARCHAR2(20)  := 'FILE_NAME';                                     -- ファイル名
  cv_tkn_count           CONSTANT VARCHAR2(20)  := 'COUNT';                                         -- 処理件数
  cv_tkn_table           CONSTANT VARCHAR2(20)  := 'TABLE';                                         -- テーブル名
  cv_tkn_errmsg          CONSTANT VARCHAR2(20)  := 'ERR_MSG';                                       -- エラー内容
  cv_tkn_input_line_no   CONSTANT VARCHAR2(20)  := 'INPUT_LINE_NO';                                 -- インタフェースの行番号
  cv_tkn_input_item_code CONSTANT VARCHAR2(20)  := 'INPUT_ITEM_CODE';                               -- インタフェースの品目コード
  cv_tkn_input           CONSTANT VARCHAR2(20)  := 'INPUT';                                         -- 項目
--
  -- アプリケーション短縮名
  cv_appl_name_xxcmm     CONSTANT VARCHAR2(5)   := 'XXCMM';
  --
  cv_log                 CONSTANT VARCHAR2(5)   := 'LOG';                                           -- ログ
  cv_output              CONSTANT VARCHAR2(6)   := 'OUTPUT';                                        -- アウトプット
  --
  cv_file_id             CONSTANT VARCHAR2(20)  := 'FILE_ID';                                       -- ファイルID
  cv_lookup_type_upload_obj
                         CONSTANT VARCHAR2(30)  := xxcmm_004common_pkg.cv_lookup_type_upload_obj;   -- ファイルアップロードオブジェクト
  cv_lookup_item_def     CONSTANT VARCHAR2(30)  := 'XXCMM1_004A15_ITEM_UPLOAD_DEF';                 -- 品目一括更新データ項目定義
--
  -- LOOKUP
  cv_lookup_itm_dtl_sts  CONSTANT VARCHAR2(30)  := 'XXCMM_ITM_DTL_STATUS';                          -- 品目詳細ステータス
--
  -- ITEM
  cv_yes                 CONSTANT VARCHAR2(1)   := 'Y';
  cv_no                  CONSTANT VARCHAR2(1)   := 'N';
  cv_null_ok             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ok;                  -- 任意項目
  cv_null_ng             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_null_ng;                  -- 必須項目
  cv_varchar             CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_varchar;                  -- 文字列
  cv_number              CONSTANT VARCHAR2(10)  := xxcmm_004common_pkg.cv_number;                   -- 数値
  cv_varchar_cd          CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_varchar_cd;               -- 文字列項目
  cv_number_cd           CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_number_cd;                -- 数値項目
  cv_date_cd             CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_date_cd;                  -- 日付項目
  cv_not_null            CONSTANT VARCHAR2(1)   := xxcmm_004common_pkg.cv_not_null;                 -- 必須
  cv_msg_comma           CONSTANT VARCHAR2(1)   := ',';                                             -- カンマ
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  TYPE g_item_def_rtype    IS RECORD                                                                -- レコード型を宣言
      (item_name       VARCHAR2(100)                                                                -- 項目名
      ,item_attribute  VARCHAR2(100)                                                                -- 項目属性
      ,item_essential  VARCHAR2(100)                                                                -- 必須フラグ
      ,item_length     NUMBER                                                                       -- 項目の長さ
      )
    ;
  --
  TYPE g_item_rtype IS RECORD
      (line_no           VARCHAR2(100)  -- 行番号
      ,item_code         VARCHAR2(100)  -- 品目コード
      ,item_name         VARCHAR2(100)  -- 品目名
      ,renewal_item_code VARCHAR2(100)  -- リニューアル元商品コード
      ,item_dtl_status   VARCHAR2(100)  -- 品目詳細ステータス
      ,remarks           VARCHAR2(100)  -- 備考
      )
    ;
  --
  TYPE g_item_def_ttype   IS TABLE OF g_item_def_rtype      INDEX BY BINARY_INTEGER;                -- テーブル型の宣言
  --
  TYPE g_check_data_ttype IS TABLE OF VARCHAR2(4000)        INDEX BY BINARY_INTEGER;                -- テーブル型の宣言
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_file_id                NUMBER;                                                                 -- パラメータ格納用変数
  gv_format                 VARCHAR2(100);                                                          -- パラメータ格納用変数
  gn_item_num               NUMBER;                                                                 -- 品目一括登録データ項目数格納用
  gd_process_date           DATE;                                                                   -- 業務日付
  g_item_def_tab            g_item_def_ttype;                                                       -- テーブル型変数の宣言
  g_item_rec                g_item_rtype;                                                           -- レコード型変数の宣言
  --
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  --*** ロックエラー例外 ***
  global_check_lock_expt     EXCEPTION;
  PRAGMA EXCEPTION_INIT(global_check_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : proc_comp
   * Description      : 終了処理 (A-5)
   ***********************************************************************************/
  PROCEDURE proc_comp(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_comp'; -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    del_err_expt              EXCEPTION;                              -- データ削除エラー
--
  BEGIN
    --
--##################  固定ステータス初期化部 START   ###################
    --
    ov_retcode := cv_status_normal;
    --
--###########################  固定部 END   ############################
    --
    lv_step := 'A-5.1';
    --==============================================================
    -- A-5.1 ファイルアップロードIFテーブルデータ削除
    --==============================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface
      WHERE  file_id = gn_file_id
      ;
      --
      COMMIT;
      --
    EXCEPTION
      -- *** データ削除例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00418          -- メッセージコード
                      ,iv_token_name1  => cv_tkn_table                -- TABLE
                      ,iv_token_value1 => cv_msg_xxcmm_30404          -- ファイルアップロードIF
                      ,iv_token_name2  => cv_tkn_errmsg               -- ERR_MSG
                      ,iv_token_value2 => SQLERRM                     -- エラーメッセージ
                     );
        RAISE del_err_expt;
    END;
    --
  EXCEPTION
    -- *** データ削除例外ハンドラ ***
    WHEN del_err_expt THEN
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END proc_comp;
--
  /**********************************************************************************
   * Procedure Name   : ins_data
   * Description      : データ登録 (A-4)
   ***********************************************************************************/
  PROCEDURE ins_data(
    i_wk_item_rec  IN  g_item_rtype               -- 品目一括更新ワーク情報
   ,ov_errbuf      OUT VARCHAR2                   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2                   -- リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2                   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_data'; -- プログラム名
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
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_tkn_table              VARCHAR2(60);
    lv_item_code              xxcmm_system_items_b.item_code%TYPE;
    -- *** ローカル・カーソル ***
    --
    -- *** ローカルユーザー定義例外 ***
    ins_err_expt              EXCEPTION;                              -- データ更新エラー
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
    -- A-4 データ登録
    --==============================================================
    lv_step := 'A-4.1';
    -- Disc品目アドオンデータロック取得
    BEGIN
      SELECT xsib.item_code                       -- 品目コード
      INTO   lv_item_code
      FROM   xxcmm_system_items_b xsib
      WHERE  xsib.item_code              = i_wk_item_rec.item_code
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        RAISE global_check_lock_expt;
    END;
--
    lv_step := 'A-4.2';
    -- Disc品目アドオンデータ更新
    BEGIN
      UPDATE xxcmm_system_items_b xsib
      SET    xsib.renewal_item_code      = NVL(i_wk_item_rec.renewal_item_code ,xsib.renewal_item_code ) -- リニューアル元商品コード
            ,xsib.item_dtl_status        = NVL(i_wk_item_rec.item_dtl_status ,xsib.item_dtl_status )     -- 品目詳細ステータス
            ,xsib.remarks                = NVL(i_wk_item_rec.remarks ,xsib.remarks )                     -- 備考
            ,xsib.last_updated_by        = cn_last_updated_by                                            -- 最終更新者
            ,xsib.last_update_date       = cd_last_update_date                                           -- 最終更新日
            ,xsib.last_update_login      = cn_last_update_login                                          -- 最終更新ログイン
            ,xsib.request_id             = cn_request_id                                                 -- 要求ID
            ,xsib.program_application_id = cn_program_application_id                                     -- コンカレント・プログラムのアプリケーションID
            ,xsib.program_id             = cn_program_id                                                 -- コンカレント・プログラムID
            ,xsib.program_update_date    = cd_program_update_date                                        -- プログラムによる更新日
      WHERE xsib.item_code               = i_wk_item_rec.item_code
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errbuf    := SQLERRM;
        lv_tkn_table := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_30403          -- メッセージコード
                     );
        RAISE ins_err_expt;   -- データ更新例外
    END;
  --
  EXCEPTION
    -- *** ロックエラー例外ハンドラ ***
    WHEN global_check_lock_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00803            -- メッセージコード
                   );
      -- メッセージ出力
      xxcmm_004common_pkg.put_message(
        iv_message_buff  =>  lv_errmsg
       ,ov_errbuf        =>  lv_errbuf
       ,ov_retcode       =>  lv_retcode
       ,ov_errmsg        =>  lv_errmsg
      );
      ov_retcode := cv_status_error;
    -- *** データ更新例外ハンドラ ***
    WHEN ins_err_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00802            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- TABLE
                    ,iv_token_value1 => lv_tkn_table                  -- Disc品目アドオン
                    ,iv_token_name2  => cv_tkn_input_line_no          -- INPUT_LINE_NO
                    ,iv_token_value2 => i_wk_item_rec.line_no         -- 行番号
                    ,iv_token_name3  => cv_tkn_input_item_code        -- INPUT_ITEM_CODE
                    ,iv_token_value3 => i_wk_item_rec.item_code       -- 品目コード
                    ,iv_token_name4  => cv_tkn_errmsg                 -- ERR_MSG
                    ,iv_token_value4 => lv_errbuf                     -- エラーメッセージ
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
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END ins_data;
--
  /**********************************************************************************
   * Procedure Name   : validate_item
   * Description      : データ妥当性チェック (A-3)
   ***********************************************************************************/
  PROCEDURE validate_item(
    i_wk_item_rec  IN  g_item_rtype               -- 品目一括更新ワーク情報
   ,ov_errbuf      OUT VARCHAR2                   -- エラー・メッセージ           --# 固定 #
   ,ov_retcode     OUT VARCHAR2                   -- リターン・コード             --# 固定 #
   ,ov_errmsg      OUT VARCHAR2                   -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'validate_item';                    -- プログラム名
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
    lv_step                   VARCHAR2(10);                                     -- ステップ
    ln_cnt                    NUMBER;                                           -- 品目存在チェックカウント用
    lv_check_flag             VARCHAR2(1);                                      -- チェックフラグ
    l_validate_item_tab       g_check_data_ttype;
    lt_lookup_code            fnd_lookup_values_vl.lookup_code%TYPE;
    --
    ln_check_cnt              NUMBER;
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRM変数退避用
    lv_msg_xxcmm_30402        VARCHAR2(10);                                     -- LOOKUP表
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
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
    ln_cnt        := 0;
    lv_check_flag := cv_status_normal;
    --
    --==============================================================
    -- メイン処理LOOP
    --==============================================================
    lv_step := 'A-3.1';
    --
    l_validate_item_tab(1)  := i_wk_item_rec.line_no;                           -- 行番号
    l_validate_item_tab(2)  := i_wk_item_rec.item_code;                         -- 品目コード
    l_validate_item_tab(3)  := i_wk_item_rec.item_name;                         -- 品目名
    l_validate_item_tab(4)  := i_wk_item_rec.renewal_item_code;                 -- リニューアル元商品コード
    l_validate_item_tab(5)  := i_wk_item_rec.item_dtl_status;                   -- 品目詳細ステータス
    l_validate_item_tab(6)  := i_wk_item_rec.remarks;                           -- 備考
    --
    -- カウンタの初期化
    ln_check_cnt := 0;
    --
    <<validate_column_loop>>
    LOOP
      EXIT WHEN ln_check_cnt >= gn_item_num;
      -- カウンタを加算
      ln_check_cnt := ln_check_cnt + 1;
      --
      -- 項目が「品目名」の場合チェックを実施しない
      IF ( ln_check_cnt <> 3 ) THEN
        xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_item_def_tab(ln_check_cnt).item_name             -- 項目名称
         ,iv_item_value   => l_validate_item_tab(ln_check_cnt)                  -- 項目の値
         ,in_item_len     => g_item_def_tab(ln_check_cnt).item_length           -- 項目の長さ(整数部分)
         ,in_item_decimal => NULL                                               -- 項目の長さ（小数点以下）
         ,iv_item_nullflg => g_item_def_tab(ln_check_cnt).item_essential        -- 必須フラグ
         ,iv_item_attr    => g_item_def_tab(ln_check_cnt).item_attribute        -- 項目の属性
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        -- 処理結果チェック
        IF ( lv_retcode <> cv_status_normal ) THEN
          lv_errmsg  :=  xxccp_common_pkg.get_msg(
                           iv_application   =>  cv_appl_name_xxcmm              -- アプリケーション短縮名
                          ,iv_name          =>  cv_msg_xxcmm_00403              -- メッセージコード
                          ,iv_token_name1   =>  cv_tkn_input_line_no            -- INPUT_LINE_NO
                          ,iv_token_value1  =>  i_wk_item_rec.line_no           -- 行番号
                          ,iv_token_name2   =>  cv_tkn_errmsg                   -- ERR_MSG
                          ,iv_token_value2  =>  LTRIM(lv_errmsg)                -- エラーメッセージ
                         );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff  =>  lv_errmsg
           ,ov_errbuf        =>  lv_errbuf
           ,ov_retcode       =>  lv_retcode
           ,ov_errmsg        =>  lv_errmsg
          );
          --
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
    END LOOP validate_column_loop;
    --
--
    IF ( lv_check_flag = cv_status_normal ) THEN
      --==============================================================
      -- A-3.2 品目存在チェック（品目コード）
      --==============================================================
      lv_step := 'A-3.2';
      SELECT  COUNT(1)
      INTO    ln_cnt
      FROM    ic_item_mst_b iimb
      WHERE   iimb.item_no = i_wk_item_rec.item_code
      AND     ROWNUM       = 1
      ;
      -- 処理結果チェック
      IF ( ln_cnt = 0 ) THEN
        -- マスタ存在チェックエラー
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00800                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_input                          -- INPUT
                      ,iv_token_value1 => cv_msg_xxcmm_30405                    -- 品目コード
                      ,iv_token_name2  => cv_tkn_table                          -- TABLE
                      ,iv_token_value2 => cv_msg_xxcmm_30408                    -- 品目マスタ
                      ,iv_token_name3  => cv_tkn_input_line_no                  -- INPUT_LINE_NO
                      ,iv_token_value3 => i_wk_item_rec.line_no                 -- 行番号
                      ,iv_token_name4  => cv_tkn_input_item_code                -- INPUT_ITEM_CODE
                      ,iv_token_value4 => i_wk_item_rec.item_code               -- 品目コード
                     );
        -- メッセージ出力
        xxcmm_004common_pkg.put_message(
          iv_message_buff => lv_errmsg
         ,ov_errbuf       => lv_errbuf
         ,ov_retcode      => lv_retcode
         ,ov_errmsg       => lv_errmsg
        );
        lv_check_flag := cv_status_error;
      END IF;
      --
      --==============================================================
      -- A-3.3 品目存在チェック（リニューアル元商品コード）
      -- NULLの場合はチェックしない
      --==============================================================
      lv_step := 'A-3.3';
      IF ( i_wk_item_rec.renewal_item_code IS NOT NULL ) THEN
        SELECT  COUNT(1)
        INTO    ln_cnt
        FROM    ic_item_mst_b iimb
        WHERE   iimb.item_no = i_wk_item_rec.renewal_item_code
        AND     ROWNUM       = 1
        ;
        -- 処理結果チェック
        IF ( ln_cnt = 0 ) THEN
          -- マスタ存在チェックエラー
          lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_appl_name_xxcmm                  -- アプリケーション短縮名
                        ,iv_name         => cv_msg_xxcmm_00800                  -- メッセージコード
                        ,iv_token_name1  => cv_tkn_input                        -- INPUT
                        ,iv_token_value1 => cv_msg_xxcmm_30407                  -- リニューアル元商品コード
                        ,iv_token_name2  => cv_tkn_table                        -- TABLE
                        ,iv_token_value2 => cv_msg_xxcmm_30408                  -- 品目マスタ
                        ,iv_token_name3  => cv_tkn_input_line_no                -- INPUT_LINE_NO
                        ,iv_token_value3 => i_wk_item_rec.line_no               -- 行番号
                        ,iv_token_name4  => cv_tkn_input_item_code              -- INPUT_ITEM_CODE
                        ,iv_token_value4 => i_wk_item_rec.item_code             -- 品目コード
                       );
          -- メッセージ出力
          xxcmm_004common_pkg.put_message(
            iv_message_buff => lv_errmsg
           ,ov_errbuf       => lv_errbuf
           ,ov_retcode      => lv_retcode
           ,ov_errmsg       => lv_errmsg
          );
          lv_check_flag := cv_status_error;
        END IF;
      END IF;
      --==============================================================
      -- A-3.4 品目詳細ステータスチェック
      -- NULLの場合はチェックしない
      --==============================================================
      lv_step := 'A-3.4';
      IF ( i_wk_item_rec.item_dtl_status IS NOT NULL ) THEN
        BEGIN
          SELECT  flvv.lookup_code
          INTO    lt_lookup_code
          FROM    fnd_lookup_values_vl flvv
          WHERE   flvv.lookup_type   = cv_lookup_itm_dtl_sts
          AND     flvv.lookup_code   = i_wk_item_rec.item_dtl_status
          AND     flvv.enabled_flag  = cv_yes
          AND     NVL( flvv.start_date_active, gd_process_date ) <= gd_process_date
          AND     NVL( flvv.end_date_active,   gd_process_date ) >= gd_process_date
          ;
        EXCEPTION
          --*** データ抽出エラー ***
          WHEN OTHERS THEN
            lv_sqlerrm := SQLERRM;
            lv_msg_xxcmm_30402 := xxccp_common_pkg.get_msg(
                                    iv_application  => cv_appl_name_xxcmm          -- アプリケーション短縮名
                                   ,iv_name         => cv_msg_xxcmm_30402          -- メッセージコード
                                  );
            lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_appl_name_xxcmm                                    -- アプリケーション短縮名
                          ,iv_name         => cv_msg_xxcmm_00801                                    -- メッセージコード
                          ,iv_token_name1  => cv_tkn_table                                          -- TABLE
                          ,iv_token_value1 => lv_msg_xxcmm_30402 || '(' || cv_lookup_itm_dtl_sts || ')'   -- LOOKUP表
                          ,iv_token_name2  => cv_tkn_input_line_no                                  -- INPUT_LINE_NO
                          ,iv_token_value2 => i_wk_item_rec.line_no                                 -- 行番号
                          ,iv_token_name3  => cv_tkn_input_item_code                                -- INPUT_ITEM_CODE
                          ,iv_token_value3 => i_wk_item_rec.item_code                               -- 品目コード
                          ,iv_token_name4  => cv_tkn_errmsg                                         -- ERR_MSG
                          ,iv_token_value4 => lv_sqlerrm                                            -- エラーメッセージ
                         );
            -- メッセージ出力
            xxcmm_004common_pkg.put_message(
              iv_message_buff => lv_errmsg
             ,ov_errbuf       => lv_errbuf
             ,ov_retcode      => lv_retcode
             ,ov_errmsg       => lv_errmsg
            );
            lv_check_flag := cv_status_error;
        END;
      END IF;
      --
    END IF;
    --戻りステータスの設定
    IF ( lv_check_flag = cv_status_normal ) THEN
      ov_retcode := cv_status_normal;
    ELSIF ( lv_check_flag = cv_status_error ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END validate_item;
--
  /**********************************************************************************
   * Procedure Name   : get_if_data
   * Description      : ファイルアップロードIFデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_if_data(
    ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name       CONSTANT VARCHAR2(100) := 'get_if_data';        -- プログラム名
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    --
    ln_line_cnt               NUMBER;                                 -- 行カウンタ
    ln_item_num               NUMBER;                                 -- 項目数
    ln_item_cnt               NUMBER;                                 -- 項目数カウンタ
    lv_check_error            VARCHAR2(1);                            -- エラーステータス退避
--
    l_wk_item_tab             g_check_data_ttype;                     --  テーブル型変数を宣言(項目分割)
    l_if_data_tab             xxccp_common_pkg2.g_file_data_tbl;      --  テーブル型変数を宣言
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_if_data_expt          EXCEPTION;                              -- データ項目数エラー例外
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    ln_item_num     := 0;
    -- データ項目数設定
    gn_item_num     := 6;
    --
    --==============================================================
    -- A-2.1 対象データの分割(レコード分割)/ファイルアップロードIFテーブルロック
    --==============================================================
    lv_step := 'A-2.1';
    xxccp_common_pkg2.blob_to_varchar2(                               -- BLOBデータ変換共通関数
      in_file_id   => gn_file_id                                      -- ファイルＩＤ
     ,ov_file_data => l_if_data_tab                                   -- 変換後VARCHAR2データ
     ,ov_errbuf    => lv_errbuf                                       -- エラー・メッセージ           --# 固定 #
     ,ov_retcode   => lv_retcode                                      -- リターン・コード             --# 固定 #
     ,ov_errmsg    => lv_errmsg                                       -- ユーザー・エラー・メッセージ --# 固定 #
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE global_api_expt;
    END IF;
    --
    -- データチェック/更新LOOP
    -- ヘッダー部を除く
    <<ins_wk_loop>>
    FOR ln_line_cnt IN 2..l_if_data_tab.COUNT LOOP
      --==============================================================
      -- A-2.2 項目数のチェック
      --==============================================================
      lv_step := 'A-2.2';
      -- データ項目数を格納
      ln_item_num := ( LENGTHB(l_if_data_tab(ln_line_cnt))
                   - ( LENGTHB(REPLACE(l_if_data_tab(ln_line_cnt), cv_msg_comma, '')))
                   + 1);
      -- 項目数が一致しない場合
      IF ( gn_item_num <> ln_item_num ) THEN
        RAISE get_if_data_expt;
      END IF;
      --
      --==============================================================
      -- A-2.3 対象データの分割(項目分割)/格納
      --==============================================================
      lv_step := 'A-2.3';
      <<get_column_loop>>
      FOR ln_item_cnt IN 1..gn_item_num LOOP
        l_wk_item_tab(ln_item_cnt) := xxccp_common_pkg.char_delim_partition(  -- デリミタ文字変換共通関数
                                        iv_char     => l_if_data_tab(ln_line_cnt)
                                       ,iv_delim    => cv_msg_comma
                                       ,in_part_num => ln_item_cnt
                                      );
      END LOOP get_column_loop;
      -- 変数に項目の値を格納
      g_item_rec.line_no := TRIM(l_wk_item_tab(1));
      g_item_rec.item_code := TRIM(l_wk_item_tab(2));
      g_item_rec.item_name := TRIM(l_wk_item_tab(3));
      g_item_rec.renewal_item_code := TRIM(l_wk_item_tab(4));
      g_item_rec.item_dtl_status := TRIM(l_wk_item_tab(5));
      g_item_rec.remarks := TRIM(l_wk_item_tab(6));
      --
      --「リニューアル元商品コード」、「品目詳細ステータス」、「備考」がNULLの場合スキップ
      IF ( g_item_rec.renewal_item_code IS NULL AND g_item_rec.item_dtl_status IS NULL AND g_item_rec.remarks IS NULL ) THEN
        CONTINUE;
      END IF;
      --==============================================================
      -- A-3  データ妥当性チェック
      --==============================================================
      lv_step := 'A-3';
      validate_item(
        i_wk_item_rec  => g_item_rec              -- 品目一括更新ワーク情報
       ,ov_errbuf      => lv_errbuf               -- エラー・メッセージ
       ,ov_retcode     => lv_retcode              -- リターン・コード
       ,ov_errmsg      => lv_errmsg               -- ユーザー・エラー・メッセージ
      );
      -- 処理結果チェック
      IF ( lv_retcode <> cv_status_normal AND lv_errbuf IS NOT NULL ) THEN
        FND_FILE.PUT_LINE(
          which => FND_FILE.LOG,
          buff  => lv_errbuf
        );
      END IF;
      IF ( lv_retcode = cv_status_normal ) THEN
        --==============================================================
        -- A-4  データ登録
        --==============================================================
        lv_step := 'A-4';
        ins_data(
          i_wk_item_rec  => g_item_rec              -- 品目一括更新ワーク情報
         ,ov_errbuf      => lv_errbuf               -- エラー・メッセージ
         ,ov_retcode     => lv_retcode              -- リターン・コード
         ,ov_errmsg      => lv_errmsg               -- ユーザー・エラー・メッセージ
        );
        -- 処理結果チェック
        IF ( lv_retcode <> cv_status_normal AND lv_errbuf IS NOT NULL ) THEN
          FND_FILE.PUT_LINE(
            which => FND_FILE.LOG,
            buff  => lv_errbuf
          );
        END IF;
      END IF;
      --
      --==============================================================
      -- 処理件数加算
      --==============================================================
      IF ( lv_retcode = cv_status_normal ) THEN
        gn_normal_cnt := gn_normal_cnt + 1;
      ELSE
        gn_error_cnt  := gn_error_cnt + 1;
      END IF;
      --エラーステータス退避
      IF ( lv_retcode = cv_status_error ) THEN
        lv_check_error := cv_status_error;
      END IF;
--
    END LOOP ins_wk_loop;
    --
    -- 処理対象件数を格納
    gn_target_cnt := gn_normal_cnt + gn_error_cnt;
    --
    -- ステータス退避がエラーならエラーを返す
    IF ( lv_check_error = cv_status_error ) THEN
      ov_retcode := cv_status_error;
    END IF;
  EXCEPTION
    -- *** データ項目数エラー例外ハンドラ ***
    WHEN get_if_data_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm            -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00028            -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                  -- TABLE
                    ,iv_token_value1 => cv_msg_xxcmm_30406            -- 品目一括更新
                    ,iv_token_name2  => cv_tkn_count                  -- COUNT
                    ,iv_token_value2 => ln_item_num                   -- 項目数
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END get_if_data;
--
  /**********************************************************************************
   * Procedure Name   : proc_init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE proc_init(
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ                 --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード                   --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ       --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_init';                        -- プログラム名
--
    lv_errbuf  VARCHAR2(5000);                                                  -- エラー・メッセージ
    lv_errmsg  VARCHAR2(5000);                                                  -- ユーザー・エラー・メッセージ
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    lv_step                   VARCHAR2(10);                                     -- ステップ
    lv_tkn_value              VARCHAR2(100);                                    -- トークン値
    lv_sqlerrm                VARCHAR2(5000);                                   -- SQLERRMを退避
    --
    lv_upload_obj             VARCHAR2(100);                                    -- ファイルアップロード名称
    lv_up_name                VARCHAR2(1000);                                   -- アップロード名称出力用
    lv_file_id                VARCHAR2(1000);                                   -- ファイルID出力用
    lv_file_format            VARCHAR2(1000);                                   -- フォーマット出力用
    lv_file_name              VARCHAR2(1000);                                   -- ファイル名出力用
    lt_csv_file_name          xxccp_mrp_file_ul_interface.file_name%TYPE;       -- CSVファイル名出力用
    ln_cnt                    NUMBER;                                           -- カウンタ
--
    -- *** ローカル・カーソル ***
    -- データ項目定義取得用カーソル
    CURSOR     get_def_info_cur
    IS
      SELECT   flv.meaning                         AS item_name                 -- 内容
              ,DECODE(flv.attribute1, cv_varchar, cv_varchar_cd
                                    , cv_number,  cv_number_cd
                                    , cv_date_cd)  AS item_attribute            -- 項目属性
              ,DECODE(flv.attribute2, cv_not_null, cv_null_ng
                                    , cv_null_ok)  AS item_essential            -- 必須フラグ
              ,TO_NUMBER(flv.attribute3)           AS item_length               -- 項目の長さ(整数部分)
      FROM     fnd_lookup_values_vl  flv                                        -- LOOKUP表
      WHERE    flv.lookup_type        = cv_lookup_item_def                      -- 品目一括更新データ項目定義
      AND      flv.enabled_flag       = cv_yes                                  -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active, gd_process_date)   >= gd_process_date   -- 適用終了日
      ORDER BY flv.lookup_code;
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    get_param_expt            EXCEPTION;                                        -- パラメータNULLエラー
    process_date_expt         EXCEPTION;                                        -- 業務日付取得失敗エラー
    get_profile_expt          EXCEPTION;                                        -- プロファイル取得例外
    select_file_expt          EXCEPTION;                                        -- データ抽出エラー（LOOKUP表）
    select_csvfile_expt       EXCEPTION;                                        -- データ抽出エラー（ファイルアップロードIFテーブル）
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ローカル変数初期化
    ln_cnt           := 0;
    --==============================================================
    -- A-1.1 入力パラメータ（FILE_ID、フォーマット）の「NULL」チェック
    --==============================================================
    lv_step := 'A-1.1';
    IF ( iv_file_id IS NULL ) THEN
      lv_tkn_value := cv_file_id;
      RAISE get_param_expt;
    END IF;
    IF ( iv_format IS NULL ) THEN
      lv_tkn_value := xxccp_common_pkg.get_msg(                                 -- フォーマットの出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_30400                   -- メッセージコード
                      );
      RAISE get_param_expt;
    END IF;
    --
    -- INパラメータを格納
    gn_file_id := TO_NUMBER(iv_file_id);
    gv_format  := iv_format;
    --
    --==============================================================
    -- A-1.2 業務日付の取得
    --==============================================================
    lv_step := 'A-1.2';
    gd_process_date := xxccp_common_pkg2.get_process_date;
    -- NULLチェック
    IF ( gd_process_date IS NULL ) THEN
      lv_tkn_value := xxccp_common_pkg.get_msg(                                 -- フォーマットの出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_30401                   -- メッセージコード
                      );
      RAISE process_date_expt;
    END IF;
    --
    --==============================================================
    -- A-1.3 ファイルアップロード名称取得
    --==============================================================
    lv_step := 'A-1.3';
    BEGIN
      SELECT   flv.meaning
      INTO     lv_upload_obj
      FROM     fnd_lookup_values_vl flv
      WHERE    flv.lookup_type  = cv_lookup_type_upload_obj                     -- ファイルアップロードオブジェクト
      AND      flv.lookup_code  = gv_format                                     -- フォーマット
      AND      flv.enabled_flag = cv_yes                                        -- 使用可能フラグ
      AND      NVL(flv.start_date_active, gd_process_date) <= gd_process_date   -- 適用開始日
      AND      NVL(flv.end_date_active,   gd_process_date) >= gd_process_date   -- 適用終了日
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE select_file_expt;
    END;
    --
    --==============================================================
    -- A-1.4 Disc品目アドオンの更新項目情報取得の取得
    --==============================================================
    lv_step := 'A-1.4';
    -- 変数の初期化
    ln_cnt := 0;
    -- テーブル定義取得LOOP
    <<def_info_loop>>
    FOR get_def_info_rec IN get_def_info_cur LOOP
      ln_cnt := ln_cnt + 1;
      g_item_def_tab(ln_cnt).item_name      := get_def_info_rec.item_name;      -- 項目名
      g_item_def_tab(ln_cnt).item_attribute := get_def_info_rec.item_attribute; -- 項目属性
      g_item_def_tab(ln_cnt).item_essential := get_def_info_rec.item_essential; -- 必須フラグ
      g_item_def_tab(ln_cnt).item_length    := get_def_info_rec.item_length;    -- 項目の長さ(整数部分)
    END LOOP def_info_loop;
    --
    --==============================================================
    -- A-1.5 CSVファイル名称取得
    --==============================================================
    lv_step := 'A-1.5';
    BEGIN
      SELECT   fui.file_name                                                    -- ファイル名
      INTO     lt_csv_file_name
      FROM     xxccp_mrp_file_ul_interface  fui                                 -- ファイルアップロードIFテーブル
      WHERE    fui.file_id = gn_file_id                                         -- ファイルID
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_sqlerrm := SQLERRM;
        RAISE select_csvfile_expt;
    END;
    --
    --==============================================================
    -- A-1.6 INパラメータの出力
    --==============================================================
    lv_step := 'A-1.6';
    lv_up_name     := xxccp_common_pkg.get_msg(                                 -- アップロード名称の出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00021                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_up_name                       -- UPLOAD_NAME
                       ,iv_token_value1 => lv_upload_obj                        -- ファイルアップロード名称
                      );
    lv_file_name   := xxccp_common_pkg.get_msg(                                 -- ファイル名称の出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00022                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_name                     -- FILE_NAME
                       ,iv_token_value1 => lt_csv_file_name                     -- CSVファイル名称
                      );
    lv_file_id     := xxccp_common_pkg.get_msg(                                 -- ファイルIDの出力
                        iv_application  => cv_appl_name_xxcmm                   -- アプリケーション短縮名
                       ,iv_name         => cv_msg_xxcmm_00023                   -- メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id                       -- FILE_ID
                       ,iv_token_value1 => TO_CHAR(gn_file_id)                  -- FILE_ID
                      );
    lv_file_format := xxccp_common_pkg.get_msg(                                 -- フォーマットの出力
                       iv_application  => cv_appl_name_xxcmm                    -- アプリケーション短縮名
                      ,iv_name         => cv_msg_xxcmm_00024                    -- メッセージコード
                      ,iv_token_name1  => cv_tkn_file_format                    -- FORMAT
                      ,iv_token_value1 => gv_format                             -- フォーマットパターン
                      );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.OUTPUT                                 -- 出力に表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
    FND_FILE.PUT_LINE(
                      which  => FND_FILE.LOG                                    -- ログに表示
                     ,buff   => ''             || CHR(10) ||
                                lv_up_name     || CHR(10) ||
                                lv_file_name   || CHR(10) ||
                                lv_file_id     || CHR(10) ||
                                lv_file_format || CHR(10)
                                );
--
  EXCEPTION
    --*** パラメータNULLエラー ***
    WHEN get_param_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00401                      -- メッセージコード
                    ,iv_token_name1  => cv_tkn_value                            -- VALUE
                    ,iv_token_value1 => lv_tkn_value                            -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** 業務日付取得失敗エラー ***
    WHEN process_date_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00435                      -- メッセージコード
                    ,iv_token_name1  => cv_tkn_value                            -- VALUE
                    ,iv_token_value1 => lv_tkn_value                            -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** データ抽出エラー(アップロードファイル名称) ***
    WHEN select_file_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00439                      -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                            -- TABLE
                    ,iv_token_value1 => cv_msg_xxcmm_30402                      -- LOOKUP表
                    ,iv_token_name2  => cv_tkn_errmsg                           -- ERR_MSG
                    ,iv_token_value2 => lv_sqlerrm                              -- エラーメッセージ
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
    --*** データ抽出エラー(CSVファイル名称) ***
    WHEN select_csvfile_expt THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_name_xxcmm                      -- アプリケーション短縮名
                    ,iv_name         => cv_msg_xxcmm_00439                      -- メッセージコード
                    ,iv_token_name1  => cv_tkn_table                            -- TABLE
                    ,iv_token_value1 => cv_msg_xxcmm_30404                      -- ファイルアップロードIF
                    ,iv_token_name2  => cv_tkn_errmsg                           -- ERR_MSG
                    ,iv_token_value2 => lv_sqlerrm                              -- エラーメッセージ
                   );
      lv_errbuf  := lv_errmsg;
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
    --
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM,1,5000);
      ov_retcode := cv_status_error;
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
    iv_file_id    IN  VARCHAR2          -- 1.ファイルID
   ,iv_format     IN  VARCHAR2          -- 2.フォーマット
   ,ov_errbuf     OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
   ,ov_retcode    OUT VARCHAR2          --   リターン・コード             --# 固定 #
   ,ov_errmsg     OUT VARCHAR2          --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_step                   VARCHAR2(10);                           -- ステップ
    lv_errbuf_bk              VARCHAR2(5000);                         -- エラー・メッセージ
    lv_errmsg_bk              VARCHAR2(5000);                         -- ユーザー・エラー・メッセージ
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカルユーザー定義例外 ***
    sub_proc_expt             EXCEPTION;                              -- サブプログラムエラー
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
    -- ローカル変数初期化
    lv_errbuf     := NULL;
    lv_retcode    := cv_status_normal;
    lv_errmsg     := NULL;
    lv_errbuf_bk  := NULL;
    lv_errmsg_bk  := NULL;
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
    --==============================================================
    -- A-1.  初期処理
    --==============================================================
    lv_step := 'A-1';
    proc_init(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
    --==============================================================
    -- A-5.  終了処理
    --==============================================================
      ROLLBACK;
      --A-1のメッセージ退避
      lv_errbuf_bk := lv_errbuf;
      lv_errmsg_bk := lv_errmsg;
      proc_comp(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --A-5が正常終了の場合A-1のエラーを表示
      IF ( lv_retcode = cv_status_normal ) THEN
        lv_errbuf  := lv_errbuf_bk;
        lv_errmsg  := lv_errmsg_bk;
      END IF;
      RAISE sub_proc_expt;
    END IF;
--
    --==============================================================
    -- A-2.  ファイルアップロードIFデータ取得
      -- A-3.  データ妥当性チェック
      -- A-4.  データ登録
    --==============================================================
    lv_step := 'A-2';
    get_if_data(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
    --==============================================================
    -- A-5.  終了処理
    --==============================================================
      ROLLBACK;
      --A-1のメッセージ退避
      lv_errbuf_bk := lv_errbuf;
      lv_errmsg_bk := lv_errmsg;
      proc_comp(
        ov_errbuf  => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode => lv_retcode          -- リターン・コード
       ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      --A-5が正常終了の場合A-2のエラーを表示
      IF ( lv_retcode = cv_status_normal ) THEN
        lv_errbuf  := lv_errbuf_bk;
        lv_errmsg  := lv_errmsg_bk;
      END IF;
      RAISE sub_proc_expt;
    END IF;
    --
    --==============================================================
    -- A-5.  終了処理
    --==============================================================
    lv_step := 'A-5';
    proc_comp(
      ov_errbuf  => lv_errbuf           -- エラー・メッセージ
     ,ov_retcode => lv_retcode          -- リターン・コード
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ
    );
    --
    -- 処理結果チェック
    IF ( lv_retcode <> cv_status_normal ) THEN
      RAISE sub_proc_expt;
    END IF;
    --
    -- エラーがあればリターン・コードをエラーで返す
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
    --
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
    WHEN sub_proc_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_cont||lv_step||cv_msg_part||SQLERRM;
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
    errbuf        OUT    VARCHAR2       --   エラー・メッセージ
   ,retcode       OUT    VARCHAR2       --   エラーコード
   ,iv_file_id    IN     VARCHAR2       --   ファイルID
   ,iv_format     IN     VARCHAR2       --   フォーマット
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';              -- プログラム名
--
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';             -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
    cv_skip_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90003';  -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';             -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005';  -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
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
    -- ローカル変数初期化
    lv_errbuf       := NULL;
    lv_retcode      := cv_status_normal;
    lv_errmsg       := NULL;
    lv_message_code := NULL;
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
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
    -- メッセージ(OUTPUT)出力
    xxccp_common_pkg.put_log_header(
      iv_which   => cv_output
     ,ov_retcode => lv_retcode
     ,ov_errbuf  => lv_errbuf
     ,ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_others_expt;
    END IF;
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_file_id => iv_file_id          -- ファイルID
     ,iv_format  => iv_format           -- フォーマット
     ,ov_errbuf  => lv_errbuf           -- エラー・メッセージ           --# 固定 #
     ,ov_retcode => lv_retcode          -- リターン・コード             --# 固定 #
     ,ov_errmsg  => lv_errmsg           -- ユーザー・エラー・メッセージ --# 固定 #
    );
    --
    --エラー出力
    IF ( lv_retcode = cv_status_error ) THEN
      FND_FILE.PUT_LINE(
        which  => FND_FILE.OUTPUT
       ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
        which  => FND_FILE.LOG
       ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => ''
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => ''
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
                    iv_application  => cv_appl_short_name
                   ,iv_name         => lv_message_code
                  );
    FND_FILE.PUT_LINE(
       which => FND_FILE.OUTPUT
      ,buff  => gv_out_msg
    );
    FND_FILE.PUT_LINE(
       which => FND_FILE.LOG
      ,buff  => gv_out_msg
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
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCMM004A15C;
/
