CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A04C(body)
 * Description      : EBSに登録された訪問実績データを情報系システムに連携するための
 *                    CSVファイルを作成します。
 * MD.050           :  MD050_CSO_016_A04_情報系-EBSインターフェース：
 *                     (OUT)訪問実績データ
 * Version          : 1.13
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  set_param_default      パラメータデフォルトセット(A-2)
 *  chk_param              パラメータチェック(A-3)
 *  get_profile_info       プロファイル値取得(A-4)
 *  open_csv_file          訪問実績データCSVファイルオープン(A-5)
 *  get_accounts_data      顧客マスタ・顧客アドオンマスタ抽出(A-7)
 *  get_extrnl_rfrnc       インストールベースマスタ抽出(A-8)
 *  get_sl_rslts_data      販売実績ヘッダーテーブル・販売実績明細テーブル抽出(A-9)
 *  create_csv_rec         訪問実績データCSV出力(A-11)
 *  close_csv_file         CSVファイルクローズ処理(A-13)
 *  submain                メイン処理プロシージャ
 *                         訪問実績データ抽出(A-6)
 *                         前回訪問日抽出(A-10)
 *                         タスクデータ更新 (A-15)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理(A-14)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-19    1.0   Kazuyo.Hosoi     新規作成
 *  2009-02-26    1.1   K.Sai            レビュー結果反映 
 *  2009-03-05    1.1   Mio.Maruyama     販売実績テーブル仕様変更による
 *                                       データ抽出条件変更対応
 *  2009-04-22    1.2   Kazuo.Satomura   システムテスト障害対応(T1_0478,T1_0740)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2009-05-21    1.4   Kazuo.Satomura   システムテスト障害対応(T1_1036)
 *  2009-06-05    1.5   Kazuo.Satomura   システムテスト障害対応(T1_0478再修正)
 *  2009-07-21    1.6   Kazuo.Satomura   統合テスト障害対応(0000070)
 *  2009-09-09    1.7   Daisuke.Abe      統合テスト障害対応(0001323)
 *  2009-10-07    1.8   Daisuke.Abe      障害対応(0001454)
 *  2009-10-23    1.9   Daisuke.Abe      障害対応(E_T4_00056)
 *  2009-11-24    1.10  Daisuke.Abe      障害対応(E_本稼動_00026)
 *  2009-12-02    1.11  T.Maruyama       障害対応(E_本稼動_00081)
 *  2009-12-11    1.12  K.Hosoi          障害対応(E_本稼動_00413)
 *  2010-04-08    1.13  Daisuke.Abe      障害対応(E_本稼動_02021)
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
  /* 2009.10.07 D.Abe 0001454対応 START */
  --gn_warn_cnt      NUMBER;                    -- スキップ件数
  gn_skip_cnt      NUMBER;                    -- スキップ件数
  /* 2009.10.07 D.Abe 0001454対応 END */
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A04C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00145';  -- パラメータ更新日 FROM
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00146';  -- パラメータ更新日 TO
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00150';  -- パラメータデフォルトセット
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00384';  -- 日付書式エラー
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00013';  -- パラメータ整合性エラー
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インターフェースファイル名
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラーメッセージ
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラー
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00016';  -- データ抽出エラー
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラー
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00127';  -- データ抽出警告メッセージ
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00022';  -- CSVファイル出力エラーメッセージ(訪問実績)
  /* 2009.10.23 D.Abe E_T4_00056対応 START */
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00386';  -- タスクテーブルロックエラー
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00332';  -- タスクAPI更新エラー
  /* 2009.10.23 D.Abe E_T4_00056対応 END */
  -- トークンコード
  cv_tkn_frm_val         CONSTANT VARCHAR2(20) := 'FROM_VALUE';
  cv_tkn_to_val          CONSTANT VARCHAR2(20) := 'TO_VALUE';
  cv_tkn_val             CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_csv_fnm         CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc         CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage      CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prcss_nm        CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_vst_dt          CONSTANT VARCHAR2(20) := 'VISIT_DATE';
  cv_tkn_tsk_id          CONSTANT VARCHAR2(20) := 'TASK_ID';
  cv_tkn_cstm_cd         CONSTANT VARCHAR2(20) := 'CUSTOMER_CD';
  /* 2009.10.23 D.Abe E_T4_00056対応 START */
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_errmsg1         CONSTANT VARCHAR2(20) := 'ERRMSG';
  cv_tkn_api_name        CONSTANT VARCHAR2(20) := 'API_NAME';
  cv_tkn_api_msg         CONSTANT VARCHAR2(20) := 'API_MSG';
  /* 2009.10.23 D.Abe E_T4_00056対応 END */
--
  cb_true                 CONSTANT BOOLEAN := TRUE;
  cb_false                CONSTANT BOOLEAN := FALSE;
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1          CONSTANT VARCHAR2(200) := '<< システム日付取得処理 >>';
  cv_debug_msg2          CONSTANT VARCHAR2(200) := 'od_sysdate = ';
  cv_debug_msg3          CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg4          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_debug_msg5          CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg6          CONSTANT VARCHAR2(200) := 'lv_company_cd = ';
  cv_debug_msg7          CONSTANT VARCHAR2(200) := 'lv_csv_dir    = ';
  cv_debug_msg8          CONSTANT VARCHAR2(200) := 'lv_csv_nm = ';
  cv_debug_msg9          CONSTANT VARCHAR2(200) := 'lv_tsk_stts = ';
  cv_debug_msg10         CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg12         CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg13         CONSTANT VARCHAR2(200) := '<< 起動パラメータ >>';
  cv_debug_msg14         CONSTANT VARCHAR2(200) := '更新日FROM : ';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '更新日TO : ';
  cv_debug_msg16         CONSTANT VARCHAR2(200) := 'lv_tsk_stts = ';
  cv_debug_msg17         CONSTANT VARCHAR2(200) := 'lv_ib_del_stts = ';
  /* 2009.10.07 D.Abe 0001454対応 START */
  cv_debug_msg18         CONSTANT VARCHAR2(200) := '訪問回数 = ';
  cv_debug_msg19         CONSTANT VARCHAR2(200) := 'パーティID = ';
  cv_debug_msg20         CONSTANT VARCHAR2(200) := '訪問時顧客ステータス = ';
  cv_debug_msg21         CONSTANT VARCHAR2(200) := '訪問日 = ';
  /* 2009.10.07 D.Abe 0001454対応 END */
  cv_debug_msg_fnm       CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls      CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_ccls1     CONSTANT VARCHAR2(200) := '<< 例外処理内で訪問実績データ抽出カーソルをクローズしました >>';
  cv_debug_msg_ccls2     CONSTANT VARCHAR2(200) := '<< 例外処理内で前回訪問日抽出カーソルをクローズしました >>';
  cv_debug_msg_skip      CONSTANT VARCHAR2(200) := '<< データ取得失敗のためスキップしました >>';
  cv_debug_msg_err1      CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_debug_msg_err2      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err3      CONSTANT VARCHAR2(200) := 'others例外';
  /* 2009.10.07 D.Abe 0001454対応 START */
  cv_debug_msg_skip1     CONSTANT VARCHAR2(200) := '<< MC訪問のためスキップしました >>';
  /* 2009.10.07 D.Abe 0001454対応 END */
/* 2009.10.23 D.Abe E_T4_00056対応 START */
  cv_debug_msg_skip2     CONSTANT VARCHAR2(200) := '<< タスク更新失敗のためスキップしました >>';
/* 2009.10.23 D.Abe E_T4_00056対応 END */
/* 2009.12.02 T.Maruyama E_本稼動_00081対応 START */
  cv_debug_msg_skip3     CONSTANT VARCHAR2(200) := '<< 顧客マスタ不備のためスキップしました >>';
/* 2009.12.02 T.Maruyama E_本稼動_00081対応 END */
--
  cv_w                   CONSTANT VARCHAR2(1)   := 'w';  -- CSVファイルオープンモード
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand           UTL_FILE.FILE_TYPE;
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義
  TYPE g_get_data_rtype IS RECORD(
     company_cd                VARCHAR2(3)                                      -- 会社コード
    ,actual_end_date           jtf_tasks_b.actual_end_date%TYPE                 -- 実績終了日
    ,task_id                   jtf_tasks_b.task_id%TYPE                         -- 訪問回数
    ,account_number            hz_cust_accounts.account_number%TYPE             -- 顧客コード
    ,employee_number           per_people_f.employee_number%TYPE                -- 営業員コード
    ,external_reference        csi_item_instances.external_reference%TYPE       -- 物件コード
    ,attribute1                jtf_tasks_b.attribute1%TYPE                      -- 訪問区分コード1 
    ,attribute2                jtf_tasks_b.attribute2%TYPE                      -- 訪問区分コード2 
    ,attribute3                jtf_tasks_b.attribute3%TYPE                      -- 訪問区分コード3 
    ,attribute4                jtf_tasks_b.attribute4%TYPE                      -- 訪問区分コード4 
    ,attribute5                jtf_tasks_b.attribute5%TYPE                      -- 訪問区分コード5 
    ,attribute6                jtf_tasks_b.attribute6%TYPE                      -- 訪問区分コード6 
    ,attribute7                jtf_tasks_b.attribute7%TYPE                      -- 訪問区分コード7 
    ,attribute8                jtf_tasks_b.attribute8%TYPE                      -- 訪問区分コード8 
    ,attribute9                jtf_tasks_b.attribute9%TYPE                      -- 訪問区分コード9 
    ,attribute10               jtf_tasks_b.attribute10%TYPE                     -- 訪問区分コード10
    ,attribute12               jtf_tasks_b.attribute12%TYPE                     -- 登録元区分
    ,attribute13               jtf_tasks_b.attribute13%TYPE                     -- 登録元ソース番号
    ,source_object_id          jtf_tasks_b.source_object_id%TYPE                -- パーティID
    ,sale_base_code            xxcmm_cust_accounts.sale_base_code%TYPE          -- 拠点コード
    ,act_vst_dvsn              VARCHAR2(1)                                      -- 有効訪問区分
    ,active_column_number      NUMBER(3)                                        -- 有効コラム数
    ,missing_column_number     NUMBER(3)                                        -- 欠品コラム数
    ,missing_part_time         NUMBER(6)                                        -- 欠品時間
    ,change_out_time_100       xxcos_sales_exp_headers.change_out_time_100%TYPE -- つり銭切れ時間(100円)
    ,change_out_time_10        xxcos_sales_exp_headers.change_out_time_10%TYPE  -- つり銭切れ時間(10円)
    ,actual_end_hour           VARCHAR2(4)                                      -- 訪問時間
    ,actual_end_date_lt        jtf_tasks_b.actual_end_date%TYPE                 -- 前回訪問日
    ,act_vst_dvsn_lt           VARCHAR2(1)                                      -- 有効訪問区分(前回訪問時)
    ,deleted_flag              jtf_tasks_b.deleted_flag%TYPE                    -- 削除フラグ
    ,cprtn_date                DATE                                             -- 連結日時
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_from_value       IN  VARCHAR2         -- パラメータ更新日 FROM
    ,iv_to_value         IN  VARCHAR2         -- パラメータ更新日 TO
    ,od_sysdate          OUT DATE             -- システム日付
    ,od_process_date     OUT DATE             -- 業務処理日付
    ,ov_errbuf           OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg_from         VARCHAR2(5000);
    lv_msg_to           VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 起動パラメータメッセージ出力
    -- ===========================
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    lv_msg_from := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name           --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02      --メッセージコード
                    ,iv_token_name1  => cv_tkn_frm_val        --トークンコード1
                    ,iv_token_value1 => iv_from_value         --トークン値1
                   );
    lv_msg_to := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name           --アプリケーション短縮名
                  ,iv_name         => cv_tkn_number_03      --メッセージコード
                  ,iv_token_name1  => cv_tkn_to_val         --トークンコード1
                  ,iv_token_value1 => iv_to_value           --トークン値1
                 );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_from
    );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_to
    );
    -- ===========================
    -- システム日付取得処理 
    -- ===========================
    od_sysdate := SYSDATE;
    -- *** DEBUG_LOG ***
    -- 取得したシステム日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg1  || CHR(10) ||
                 cv_debug_msg2  || TO_CHAR(od_sysdate,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg3 || CHR(10) ||
                 cv_debug_msg4 || TO_CHAR(od_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
--
    -- 業務処理日付取得に失敗した場合
    IF (od_process_date IS NULL) THEN
      -- 空行の挿入
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_01             --メッセージコード
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : set_param_default
   * Description      : パラメータデフォルトセット(A-2)
   ***********************************************************************************/
  PROCEDURE set_param_default(
     io_from_value       IN OUT NOCOPY VARCHAR2  -- パラメータ更新日 FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- パラメータ更新日 TO
    ,id_process_date     IN DATE                 -- 業務処理日付
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'set_param_default';  -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    -- メッセージ出力用
    lv_msg_set_param    VARCHAR2(5000);
    -- 起動パラメータデフォルトセットフラグ
    lb_set_param_flg    BOOLEAN DEFAULT FALSE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 起動パラメータNULLチェック
    -- ===========================
    -- 更新日FROM がNULLの場合
    IF (io_from_value IS NULL) THEN
      -- 更新日FROM に業務処理日付をセット
      io_from_value := TO_CHAR(id_process_date,'yyyymmdd');
      lb_set_param_flg := cb_true;
    END IF;
    -- 更新日TO がNULLの場合
    IF (io_to_value IS NULL) THEN
      -- 更新日TO に業務処理日付をセット
      io_to_value := TO_CHAR(id_process_date,'yyyymmdd');
      lb_set_param_flg := cb_true;
    END IF;
--
    IF (lb_set_param_flg = cb_true) THEN
      -- ==========================================
      -- パラメータデフォルトセットメッセージ出力
      -- ==========================================
      lv_msg_set_param := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name           --アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_04      --メッセージコード
                          );
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg_set_param
      );
    END IF;
--
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
    -- *** DEBUG_LOG ***
    -- パラメータデフォルトセット後の起動パラメータをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg13 || CHR(10) ||
                 cv_debug_msg14 || io_from_value || CHR(10) ||
                 cv_debug_msg15 || io_to_value   || CHR(10) ||
                 ''
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
  END set_param_default;
--
  /**********************************************************************************
   * Procedure Name   : chk_param
   * Description      : パラメータチェック(A-3)
   ***********************************************************************************/
  PROCEDURE chk_param(
     io_from_value       IN OUT NOCOPY VARCHAR2  -- パラメータ更新日 FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- パラメータ更新日 TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2     -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2     -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2     -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'chk_param';     -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_date_format CONSTANT VARCHAR2(8) := 'YYYYMMDD';
    cv_false       CONSTANT VARCHAR2(5) := 'FALSE';
    -- *** ローカル変数 ***
    -- パラメータチェック戻り値格納用
    lb_chk_date_from BOOLEAN DEFAULT TRUE;
    lb_chk_date_to   BOOLEAN DEFAULT TRUE;
    -- *** ローカル例外 ***
    chk_param_expt   EXCEPTION;  -- パラメータチェック例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===========================
    -- 日付書式チェック
    -- ===========================
    lb_chk_date_from := xxcso_util_common_pkg.check_date(
                          iv_date         => io_from_value
                         ,iv_date_format  => cv_date_format
                        );
    lb_chk_date_to := xxcso_util_common_pkg.check_date(
                        iv_date         => io_to_value
                       ,iv_date_format  => cv_date_format
                      );
--
    -- パラメータ更新日 FROM の日付書式が'YYYYMMDD'形式でない場合
    IF (lb_chk_date_from = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_05             --メッセージコード
                    ,iv_token_name1  => cv_tkn_val                   --トークンコード1
                    ,iv_token_value1 => io_from_value                --トークン値1
                    ,iv_token_name2  => cv_tkn_status                --トークンコード2
                    ,iv_token_value2 => cv_false                     --トークン値2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    -- パラメータ更新日 TO の日付書式が'YYYYMMDD'形式でない場合
    ELSIF (lb_chk_date_to = cb_false) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_05             --メッセージコード
                    ,iv_token_name1  => cv_tkn_val                   --トークンコード1
                    ,iv_token_value1 => io_to_value                  --トークン値1
                    ,iv_token_name2  => cv_tkn_status                --トークンコード2
                    ,iv_token_value2 => cv_false                     --トークン値2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
    -- ===========================
    -- 日付大小関係チェック
    -- ===========================
    IF (TO_DATE(io_from_value,'yyyymmdd') > TO_DATE(io_to_value,'yyyymmdd')) THEN
         lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_06             --メッセージコード
                       ,iv_token_name1  => cv_tkn_frm_val               --トークンコード1
                       ,iv_token_value1 => io_from_value                --トークン値1
                       ,iv_token_name2  => cv_tkn_to_val                --トークンコード2
                       ,iv_token_value2 => io_to_value                  --トークン値2
                      );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE chk_param_expt;
    END IF;
--
  EXCEPTION
    -- *** パラメータチェック例外 ***
    WHEN chk_param_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END chk_param;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得(A-4)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
     ov_company_cd     OUT NOCOPY VARCHAR2  -- 会社コード(固定値001)
    ,ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSVファイル出力先
    ,ov_csv_nm         OUT NOCOPY VARCHAR2  -- CSVファイル名(訪問実績)
    ,ov_tsk_stts_cls   OUT NOCOPY VARCHAR2  -- タスクステータスID(クローズ)
    ,ov_ib_del_stts    OUT NOCOPY VARCHAR2  -- インストールベースステータス(物件削除済)
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_profile_info';  -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################

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
    -- プロファイル名
    -- XXCSO:情報系連携用会社コード
    cv_prfnm_cmp_cd          CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_COMPANY_CD';
    -- XXCSO:情報系連携用CSVファイル出力先
    cv_prfnm_csv_dir         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_DIR';
    -- XXCSO:情報系連携用CSVファイル名(訪問実績)
    cv_prfnm_csv_fnm         CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_VISIT';
    -- XXCSO:タスクステータスID(クローズ)
    cv_prfnm_tsk_stts_cls    CONSTANT VARCHAR2(30)   := 'XXCSO1_TASK_STATUS_CLOSED_ID';
    -- XXCSO:インストールベースステータス(物件削除済)
    cv_ib_del_stts           CONSTANT VARCHAR2(30)   := 'XXCSO1_IB_DELETE_STATUS';
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値格納用
    lv_company_cd               VARCHAR2(2000);      -- 会社コード(固定値001)
    lv_csv_dir                  VARCHAR2(2000);      -- CSVファイル出力先
    lv_csv_nm                   VARCHAR2(2000);      -- CSVファイル名(訪問実績)
    lv_tsk_stts                 VARCHAR2(2000);      -- タスクステータスID(クローズ)
    lv_ib_del_stts              VARCHAR2(2000);      -- インストールベースステータス(物件削除済)
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg_fnm                  VARCHAR2(5000);
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =======================
    -- 変数初期化処理 
    -- =======================
    lv_tkn_value := NULL;
--
    -- =======================
    -- プロファイル値取得処理 
    -- =======================
    FND_PROFILE.GET(
                    name => cv_prfnm_cmp_cd
                   ,val  => lv_company_cd
                   ); -- 会社コード（固定値001）
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_dir
                   ,val  => lv_csv_dir
                   ); -- CSVファイル出力先
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_fnm
                   ,val  => lv_csv_nm
                   ); -- CSVファイル名(訪問実績)
    FND_PROFILE.GET(
                    name => cv_prfnm_tsk_stts_cls
                   ,val  => lv_tsk_stts
                   ); -- タスクステータスID(クローズ)
    FND_PROFILE.GET(
                    name => cv_ib_del_stts
                   ,val  => lv_ib_del_stts
                   ); -- インストールベースステータス(物件削除済)
--
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || lv_company_cd || CHR(10) ||
                 cv_debug_msg7  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg8  || lv_csv_nm     || CHR(10) ||
                 cv_debug_msg16 || lv_tsk_stts   || CHR(10) ||
                 cv_debug_msg17 || lv_ib_del_stts|| CHR(10) ||
                 ''
    );
--
    -- 取得したCSVファイル名をメッセージ出力する
    lv_msg_fnm := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_07      --メッセージコード
                   ,iv_token_name1  => cv_tkn_csv_fnm        --トークンコード1
                   ,iv_token_value1 => lv_csv_nm             --トークン値1
                  );
--
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_fnm
    );
--
    -- 空行の挿入
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- プロファイル値取得に失敗した場合
    -- 会社コード取得失敗時
    IF (lv_company_cd IS NULL) THEN
      lv_tkn_value := cv_prfnm_cmp_cd;
    -- CSVファイル出力先取得失敗時
    ELSIF (lv_csv_dir IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_dir;
    -- CSVファイル名取得失敗時
    ELSIF (lv_csv_nm IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_fnm;
    -- タスクステータスID(クローズ)取得失敗時
    ELSIF (lv_tsk_stts IS NULL) THEN
      lv_tkn_value := cv_prfnm_tsk_stts_cls;
    -- インストールベースステータス(物件削除済)取得失敗時
    ELSIF (lv_ib_del_stts IS NULL) THEN
      lv_tkn_value := cv_ib_del_stts;
    END IF;
    -- エラーメッセージ取得
    IF (lv_tkn_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_08             --メッセージコード
                    ,iv_token_name1  => cv_tkn_prof_nm               --トークンコード1
                    ,iv_token_value1 => lv_tkn_value                 --トークン値1
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_company_cd     :=  lv_company_cd;       -- 会社コード（固定値001）
    ov_csv_dir        :=  lv_csv_dir;          -- CSVファイル出力先
    ov_csv_nm         :=  lv_csv_nm;           -- CSVファイル名
    ov_tsk_stts_cls   :=  lv_tsk_stts;         -- タスクステータスID(クローズ)
    ov_ib_del_stts    :=  lv_ib_del_stts;      -- インストールベースステータス(物件削除済)
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
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file
   * Description      : 訪問実績データCSVファイルオープン(A-5)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm         IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file';  -- プログラム名
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
    -- *** ローカル変数 ***
    -- ファイル存在チェック戻り値用
    lb_retcd        BOOLEAN;
    ln_file_size    NUMBER;
    ln_block_size   NUMBER;
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
       location    => iv_csv_dir
      ,filename    => iv_csv_nm
      ,fexists     => lb_retcd
      ,file_length => ln_file_size
      ,block_size  => ln_block_size
    );
--
    -- すでにファイルが存在した場合
    IF (lb_retcd = cb_true) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_09             --メッセージコード
                    ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                    ,iv_token_value1 => iv_csv_dir                   --トークン値1
                    ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                    ,iv_token_value2 => iv_csv_nm                    --トークン値2
                   );
      lv_errbuf := lv_errmsg || SQLERRM;
      RAISE file_err_expt;
    END IF;
--
    -- ========================
    -- CSVファイルオープン 
    -- ========================
    BEGIN
      -- ファイルオープン
      gf_file_hand := UTL_FILE.FOPEN(
                        location    => iv_csv_dir
                        ,filename   => iv_csv_nm
                        ,open_mode  => cv_w
                      );
    -- *** DEBUG_LOG ***
    -- ファイルオープンしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg10   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name          --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_10     --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc       --トークンコード1
                      ,iv_token_value1 => iv_csv_dir           --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm       --トークンコード2
                      ,iv_token_value2 => iv_csv_nm            --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : get_accounts_data
   * Description      : 顧客マスタ・顧客アドオンマスタ抽出(A-7)
   ***********************************************************************************/
  PROCEDURE get_accounts_data(
     io_get_data_rec    IN OUT NOCOPY g_get_data_rtype     -- 訪問実績データ
    ,id_process_date    IN     DATE                        -- 業務処理日付
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_accounts_data';  -- プログラム名
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
    cv_prcss_nm   CONSTANT VARCHAR2(100) := '顧客マスタ・顧客アドオンマスタ';
    /* 2010.04.08 D.Abe E_本稼動_02021対応 START */
    cv_basecode_nm CONSTANT VARCHAR2(100) := '顧客マスタ・顧客アドオンマスタ(拠点コード)';
    /* 2010.04.08 D.Abe E_本稼動_02021対応 END */
    -- *** ローカル変数 ***
    --編集後実績終了日
    ld_actual_end_date  DATE;
    --編集後業務処理日付
    ld_process_date     DATE;
    --取得データ格納用
    lt_account_number   hz_cust_accounts.account_number%TYPE;
    lv_base_code        VARCHAR(4);
    -- *** ローカル例外 ***
    act_end_date_expt    EXCEPTION;                                  -- 実績終了日未来月例外
    warn_data_expt       EXCEPTION;                                  -- 対象データ警告例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================================
    -- 顧客マスタ・顧客アドオンマスタ抽出
    -- ====================================
    -- 実績終了日を編集
    ld_actual_end_date := TRUNC(io_get_data_rec.actual_end_date,'mm');
    -- 業務処理日付を編集
    ld_process_date    := TRUNC(id_process_date,'mm');
    --
    BEGIN
--
      -- 顧客コード、拠点コードを取得
      SELECT hca.account_number   account_number  -- 顧客コード
             /* 2010.04.08 D.Abe E_本稼動_02021対応 START */
             --,(CASE
             --   WHEN ld_actual_end_date
             --         >= ld_process_date  THEN  xca.sale_base_code      -- 売上拠点コード
             --   ELSE xca.past_sale_base_code                            -- 前月売上拠点コード
             --   END
             -- ) base_code   -- 拠点コード
             /* 2010.04.08 D.Abe E_本稼動_02021対応 END */
      INTO  lt_account_number
           /* 2010.04.08 D.Abe E_本稼動_02021対応 START */
           --,lv_base_code
           /* 2010.04.08 D.Abe E_本稼動_02021対応 END */
      FROM  hz_cust_accounts      hca -- 顧客マスタ
           ,xxcmm_cust_accounts   xca -- 顧客アドオンマスタ
           /* 2009.12.02 T.Maruyama E_本稼動_00081対応 START */
           ,hz_cust_acct_sites    hcas --顧客アカウントサイト
           /* 2009.12.02 T.Maruyama E_本稼動_00081対応 END */
      WHERE  hca.party_id        = io_get_data_rec.source_object_id
        AND  hca.cust_account_id = xca.customer_id
        /* 2009.12.02 T.Maruyama E_本稼動_00081対応 START */
        AND  hcas.cust_account_id = hca.cust_account_id
        /* 2009.12.02 T.Maruyama E_本稼動_00081対応 END */
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND OR 
           TOO_MANY_ROWS THEN
        -- 警告メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_13                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_prcss_nm                            --トークン値1
                      ,iv_token_name2  => cv_tkn_vst_dt                          --トークンコード2
                      ,iv_token_value2 => TO_CHAR(
                                            io_get_data_rec.actual_end_date,'yyyymmdd'
                                          )                                      --トークン値2
                      ,iv_token_name3  => cv_tkn_tsk_id                          --トークンコード3
                      ,iv_token_value3 => TO_CHAR(io_get_data_rec.task_id)       --トークン値3
                      ,iv_token_name4  => cv_tkn_errmsg                          --トークンコード4
                      ,iv_token_value4 => SQLERRM                                --トークン値4
                     );
        lv_errbuf := lv_errmsg;
--
        RAISE warn_data_expt;
      -- OTHERS例外ハンドラ 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_11                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_prcss_nm                            --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage                      --トークンコード4
                      ,iv_token_value2 => SQLERRM                                --トークン値4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    --
    /* 2010.04.08 D.Abe E_本稼動_02021対応 START */
    BEGIN
--
      -- 拠点コードを取得
      SELECT CASE
               WHEN TO_DATE(paf.ass_attribute2, 'YYYYMMDD')  -- 発令日
                      > TRUNC(io_get_data_rec.actual_end_date)
                 THEN paf.ass_attribute6 -- 勤務地拠点コード（旧）
                 ELSE paf.ass_attribute5 -- 勤務地拠点コード（新）
             END  base_code
      INTO   lv_base_code
      FROM   per_people_f ppf
            ,per_assignments_f paf
      WHERE  ppf.employee_number = io_get_data_rec.employee_number
      AND    ppf.person_id       = paf.person_id
      AND    io_get_data_rec.actual_end_date
               BETWEEN TRUNC(ppf.effective_start_date)
                   AND TRUNC(ppf.effective_end_date)
      AND    io_get_data_rec.actual_end_date
               BETWEEN TRUNC(paf.effective_start_date)
                   AND TRUNC(paf.effective_end_date)
      ;
      
    EXCEPTION
      -- OTHERS例外ハンドラ 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_13                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_basecode_nm                         --トークン値1
                      ,iv_token_name2  => cv_tkn_vst_dt                          --トークンコード2
                      ,iv_token_value2 => TO_CHAR(
                                            io_get_data_rec.actual_end_date,'yyyymmdd'
                                          )                                      --トークン値2
                      ,iv_token_name3  => cv_tkn_tsk_id                          --トークンコード3
                      ,iv_token_value3 => TO_CHAR(io_get_data_rec.task_id)       --トークン値3
                      ,iv_token_name4  => cv_tkn_errmsg                          --トークンコード4
                      ,iv_token_value4 => SQLERRM                                --トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE warn_data_expt;
    END;
    /* 2010.04.08 D.Abe E_本稼動_02021対応 END */
    -- 取得した値をOUTパラメータに設定
    io_get_data_rec.account_number := lt_account_number;         -- 顧客コード
    io_get_data_rec.sale_base_code := lv_base_code;              -- 拠点コード
--
  EXCEPTION
    -- *** 対象データ警告例外ハンドラ ***
    WHEN warn_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_accounts_data;
--
  /**********************************************************************************
   * Procedure Name   : get_extrnl_rfrnc
   * Description      : インストールベースマスタ抽出(A-8)
   ***********************************************************************************/
  PROCEDURE get_extrnl_rfrnc(
     io_get_data_rec    IN OUT NOCOPY g_get_data_rtype     -- 訪問実績データ
    ,iv_ib_del_stts     IN            VARCHAR2             -- インストールベースステータス(物件削除済)
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_extrnl_rfrnc';  -- プログラム名
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
    cv_onr_pty_srce_tbl      CONSTANT VARCHAR2(10)  := 'HZ_PARTIES';
    cv_prcss_nm   CONSTANT VARCHAR2(100)            := 'インストールベースマスタ';
    -- *** ローカル変数 ***
    --取得データ格納用
    lt_external_reference    csi_item_instances.external_reference%TYPE;    -- 物件コード
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ============================
    -- インストールベースマスタ抽出
    -- ============================
    BEGIN
      SELECT ciib.external_reference                                  -- 物件コード
      INTO   lt_external_reference
      FROM  ( SELECT  ciia.external_reference     external_reference  -- 物件コード
              FROM    csi_item_instances    ciia                      -- インストールベース
                     ,csi_instance_statuses cis                       -- インストールベースステータス
              WHERE   ciia.owner_party_source_table = cv_onr_pty_srce_tbl
                AND   ciia.owner_party_id           = io_get_data_rec.source_object_id
                AND   ciia.instance_status_id       = cis.instance_status_id
                AND   cis.name                      <> iv_ib_del_stts
              ORDER BY  ciia.install_date
            ) ciib
      WHERE   ROWNUM = 1
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- データが存在しない場合はNULLを設定
      lt_external_reference := NULL;
      -- OTHERS例外ハンドラ 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_11                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_prcss_nm                            --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage                      --トークンコード4
                      ,iv_token_value2 => SQLERRM                                --トークン値4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- 取得した値をOUTパラメータに設定
    io_get_data_rec.external_reference := lt_external_reference;              -- 物件コード
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
  END get_extrnl_rfrnc;
--
  /**********************************************************************************
   * Procedure Name   : get_sl_rslts_data
   * Description      : 販売実績ヘッダーテーブル・販売実績明細テーブル抽出(A-9)
   ***********************************************************************************/
  PROCEDURE get_sl_rslts_data(
     io_get_data_rec    IN OUT NOCOPY g_get_data_rtype     -- 訪問実績データ
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_sl_rslts_data';  -- プログラム名
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
    cv_sld_out_clss1  CONSTANT VARCHAR2(1) := '1';   -- 1:売切区分有効(売切れ有り)
    cv_sld_out_clss2  CONSTANT VARCHAR2(1) := '2';   -- 2:売切区分無効(売切れ無し)
    cv_prcss_nm       CONSTANT VARCHAR2(100) := '販売実績ヘッダテーブル・販売実績明細テーブル';
    /* 2009.04.22 K.Satomura T1_0740対応 START */
    cv_dlv_gds_info CONSTANT VARCHAR2(1) := '3'; -- 登録区分=3:納品情報
    cv_abrb_clclt   CONSTANT VARCHAR2(1) := '5'; -- 登録区分=5:消化計算
    /* 2009.04.22 K.Satomura T1_0740対応 END */
    -- *** ローカル変数 ***
    --取得データ格納用
    ln_missing_column_number  NUMBER;
    ln_active_column_number   NUMBER;
    ln_missing_part_time      NUMBER;
    lt_change_out_time_100    xxcos_sales_exp_headers.change_out_time_100%TYPE;
    lt_change_out_time_10     xxcos_sales_exp_headers.change_out_time_10%TYPE;
    -- *** ローカル例外 ***
    no_data_expt         EXCEPTION;                 -- 対象データ0件例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- =====================================================
    -- 販売実績ヘッダーテーブル・販売実績明細テーブル抽出
    -- =====================================================
    BEGIN
      /* 2009.11.24 D.Abe E_本稼動_00026対応 START */
      --SELECT (SELECT COUNT(xsv1.sold_out_class) sold_out_class1
      --        FROM   xxcso_sales_v xsv1  -- 売上実績ビュー
      --        WHERE  xsv1.sold_out_class = cv_sld_out_clss1
      --        AND    xsv1.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
      --        /* 2009.05.21 K.Satomura T1_1036対応 START */
      --        --AND    xsv1.cancel_correct_class IS NULL
      --        AND    xsv1.digestion_ln_number = 0
      --        /* 2009.05.21 K.Satomura T1_1036対応 END */
      --        ) missing_column_number                            -- 欠品コラム数
      --      ,(SELECT COUNT(xsv2.sold_out_class) sold_out_class2
      --        FROM   xxcso_sales_v xsv2  -- 売上実績ビュー
      --        WHERE  xsv2.sold_out_class = cv_sld_out_clss2
      --        AND    xsv2.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
      --        /* 2009.05.21 K.Satomura T1_1036対応 START */
      --        --AND    xsv2.cancel_correct_class IS NULL
      --        AND    xsv2.digestion_ln_number = 0
      --        /* 2009.05.21 K.Satomura T1_1036対応 END */
      --        ) active_column_number                             -- 有効コラム数
      --        /* 2009.04.22 K.Satomrua T1_0478対応 START */
      --       --,(SELECT SUM(xsv3.sold_out_time) sold_out_time
      --      ,(SELECT SUM(NVL(xsv3.sold_out_time, 0)) sold_out_time
      --        /* 2009.04.22 K.Satomrua T1_0478対応 END */
      --        FROM   xxcso_sales_v  xsv3  -- 売上実績ビュー
      --        WHERE  xsv3.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
      --        /* 2009.05.21 K.Satomura T1_1036対応 START */
      --        --AND    xsv3.cancel_correct_class IS NULL
      --        AND    xsv3.digestion_ln_number = 0
      --        /* 2009.05.21 K.Satomura T1_1036対応 END */
      --        ) missing_part_time                                -- 欠品時間
      SELECT (SELECT COUNT(xsv1.sold_out_class) sold_out_class1
              FROM   xxcso_sales_of_task_v xsv1  -- 有効訪問販売実績ビュー
              /* 2009.12.11 K.Hosoi E_本稼動_00413対応 START */
              --WHERE  xsv1.sold_out_class = cv_sld_out_clss1
              WHERE  xsv1.sold_out_class = cv_sld_out_clss2
              /* 2009.12.11 K.Hosoi E_本稼動_00413対応 END */
              AND    xsv1.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
              AND    xsv1.digestion_ln_number = 0
              ) missing_column_number                            -- 欠品コラム数
            ,(SELECT COUNT(xsv2.sold_out_class) sold_out_class2
              FROM   xxcso_sales_of_task_v xsv2  -- 有効訪問販売実績ビュー
              /* 2009.12.11 K.Hosoi E_本稼動_00413対応 START */
              --WHERE  xsv2.sold_out_class = cv_sld_out_clss2
              WHERE  (xsv2.sold_out_class = cv_sld_out_clss1
                      OR  xsv2.sold_out_class = cv_sld_out_clss2)
              /* 2009.12.11 K.Hosoi E_本稼動_00413対応 END */
              AND    xsv2.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
              AND    xsv2.digestion_ln_number = 0
              ) active_column_number                             -- 有効コラム数
            ,(SELECT SUM(NVL(xsv3.sold_out_time, 0)) sold_out_time
              FROM   xxcso_sales_of_task_v  xsv3  -- 有効訪問販売実績ビュー
              WHERE  xsv3.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
              AND    xsv3.digestion_ln_number = 0
              ) missing_part_time                                -- 欠品時間
      /* 2009.11.24 D.Abe E_本稼動_00026対応 END */
             ,xsv.change_out_time_100  change_out_time_100      -- つり銭切れ時間(100円)
             ,xsv.change_out_time_10   change_out_time_10       -- つり銭切れ時間(10円)
      INTO  ln_missing_column_number
           ,ln_active_column_number
           ,ln_missing_part_time
           ,lt_change_out_time_100
           ,lt_change_out_time_10
      /* 2009.11.24 D.Abe E_本稼動_00026対応 START */
      --FROM  xxcso_sales_v  xsv   -- 売上実績ビュー
      FROM  xxcso_sales_of_task_v  xsv   -- 有効訪問販売実績ビュー
      /* 2009.11.24 D.Abe E_本稼動_00026対応 END */
      WHERE xsv.order_no_hht = TO_NUMBER(io_get_data_rec.attribute13)
        /* 2009.05.21 K.Satomura T1_1036対応 START */
        --AND xsv.cancel_correct_class IS NULL
        AND xsv.digestion_ln_number = 0
        /* 2009.05.21 K.Satomura T1_1036対応 END */
        AND ROWNUM = 1;
--
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 警告メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_13                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_prcss_nm                            --トークン値1
                      ,iv_token_name2  => cv_tkn_vst_dt                          --トークンコード2
                      ,iv_token_value2 => TO_CHAR(
                                            io_get_data_rec.actual_end_date,'yyyymmdd'
                                          )                                      --トークン値2
                      ,iv_token_name3  => cv_tkn_tsk_id                          --トークンコード3
                      ,iv_token_value3 => TO_CHAR(io_get_data_rec.task_id)       --トークン値3
                      ,iv_token_name4  => cv_tkn_errmsg                          --トークンコード4
                      ,iv_token_value4 => SQLERRM                                --トークン値4
                     );
        lv_errbuf := lv_errmsg;
--
      RAISE no_data_expt;
      -- OTHERS例外ハンドラ 
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_11                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_prcss_nm                            --トークン値1
                      ,iv_token_name2  => cv_tkn_errmessage                      --トークンコード4
                      ,iv_token_value2 => SQLERRM                                --トークン値4
                      );
        lv_errbuf  := lv_errmsg;
        RAISE global_api_expt;
    END;
    -- 取得した値をOUTパラメータに設定
    io_get_data_rec.active_column_number  := ln_active_column_number;          -- 有効コラム数
    io_get_data_rec.missing_column_number := ln_missing_column_number;         -- 欠品コラム数
    io_get_data_rec.missing_part_time     := ln_missing_part_time;             -- 欠品時間
    io_get_data_rec.change_out_time_100   := lt_change_out_time_100;           -- つり銭切れ時間(100円)
    io_get_data_rec.change_out_time_10    := lt_change_out_time_10;            -- つり銭切れ時間(10円)
--
  EXCEPTION
    -- *** 対象データ0件例外ハンドラ ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_warn;
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
  END get_sl_rslts_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : 訪問実績データCSV出力(A-11)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
     i_get_data_rec      IN  g_get_data_rtype        -- 訪問実績データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec';     -- プログラム名
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
    cv_sep_com         CONSTANT VARCHAR2(1)  := ',';
    cv_sep_wquot       CONSTANT VARCHAR2(1)  := '"';
--
    -- *** ローカル変数 ***
    lv_data            VARCHAR2(5000);       -- 編集データ格納
--
    -- *** ローカル・レコード ***
    l_vst_rslt_data_rec  g_get_data_rtype;   -- INパラメータ.訪問実績データ格納
    -- *** ローカル例外 ***
    file_put_line_expt   EXCEPTION;          -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをレコード変数に格納
    l_vst_rslt_data_rec := i_get_data_rec;       -- 訪問実績データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- データ作成
      lv_data := cv_sep_wquot||l_vst_rslt_data_rec.company_cd||cv_sep_wquot -- 会社コード
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.actual_end_date, 'yyyymmdd')            -- 実績終了日
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.task_id)                                -- 訪問回数
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.account_number  ||cv_sep_wquot    -- 顧客コード
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.employee_number ||cv_sep_wquot    -- 営業員コード
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.external_reference||cv_sep_wquot  -- 物件コード
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute1      ||cv_sep_wquot    -- 訪問区分コード1 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute2      ||cv_sep_wquot    -- 訪問区分コード2 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute3      ||cv_sep_wquot    -- 訪問区分コード3 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute4      ||cv_sep_wquot    -- 訪問区分コード4 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute5      ||cv_sep_wquot    -- 訪問区分コード5 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute6      ||cv_sep_wquot    -- 訪問区分コード6 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute7      ||cv_sep_wquot    -- 訪問区分コード7 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute8      ||cv_sep_wquot    -- 訪問区分コード8 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute9      ||cv_sep_wquot    -- 訪問区分コード9 
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.attribute10     ||cv_sep_wquot    -- 訪問区分コード10
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.sale_base_code  ||cv_sep_wquot    -- 拠点コード
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.act_vst_dvsn    ||cv_sep_wquot    -- 有効訪問区分
       ||cv_sep_com||TO_CHAR(NVL(l_vst_rslt_data_rec.active_column_number, 0))           -- 有効コラム数
       ||cv_sep_com||TO_CHAR(NVL(l_vst_rslt_data_rec.missing_column_number, 0))          -- 欠品コラム数
       ||cv_sep_com||TO_CHAR(NVL(l_vst_rslt_data_rec.missing_part_time, 0))              -- 欠品時間
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.change_out_time_100||cv_sep_wquot -- つり銭切れ時間(100円)
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.change_out_time_10 ||cv_sep_wquot -- つり銭切れ時間(10円)
       ||cv_sep_com||NVL(l_vst_rslt_data_rec.actual_end_hour, 0000)                      -- 訪問時間
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.actual_end_date_lt, 'yyyymmdd')         -- 前回訪問日
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.act_vst_dvsn_lt ||cv_sep_wquot    -- 有効訪問区分(前回訪問時)
       ||cv_sep_com||cv_sep_wquot||l_vst_rslt_data_rec.deleted_flag||cv_sep_wquot        -- 削除フラグ
       ||cv_sep_com||TO_CHAR(l_vst_rslt_data_rec.cprtn_date, 'yyyymmddhh24miss')         -- 連結日時
      ;
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand
       ,buffer => lv_data
      );
--
    EXCEPTION
      WHEN UTL_FILE.INVALID_FILEHANDLE OR     -- ファイル・ハンドル無効エラー
           UTL_FILE.INVALID_OPERATION  OR     -- オープン不可能エラー
           UTL_FILE.WRITE_ERROR  THEN         -- 書込み操作中オペレーティングエラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                              --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_14                         --メッセージコード
                      ,iv_token_name1  => cv_tkn_vst_dt                            --トークンコード1
                      ,iv_token_value1 => TO_CHAR(i_get_data_rec.actual_end_date,'yyyymmdd')    --トークン値1
                      ,iv_token_name2  => cv_tkn_tsk_id                            --トークンコード2
                      ,iv_token_value2 => TO_CHAR(i_get_data_rec.task_id)          --トークン値2
                      ,iv_token_name3  => cv_tkn_cstm_cd                           --トークンコード3
                      ,iv_token_value3 => i_get_data_rec.account_number            --トークン値3
                      ,iv_token_name4  => cv_tkn_errmsg                            --トークンコード4
                      ,iv_token_value4 => SQLERRM                                  --トークン値4
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_put_line_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_put_line_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END create_csv_rec;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理(A-12)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_csv_dir        IN  VARCHAR2         -- CSVファイル出力先
    ,iv_csv_nm         IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file';  -- プログラム名
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
    -- *** ローカル例外 ***
    file_err_expt   EXCEPTION;  -- ファイル処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
    BEGIN
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
    -- *** DEBUG_LOG ***
    -- ファイルクローズしたことをログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg11   || CHR(10)   ||
                 cv_debug_msg_fnm || iv_csv_nm || CHR(10) ||
                 ''
    );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_12             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_loc               --トークンコード1
                      ,iv_token_value1 => iv_csv_dir                   --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_fnm               --トークンコード2
                      ,iv_token_value2 => iv_csv_nm                    --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE file_err_expt;
    END;
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
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
  END close_csv_file;
--
/* 2009.10.23 D.Abe E_T4_00056対応 START */
  /**********************************************************************************
   * Procedure Name   : update_task
   * Description      : タスクデータ更新 (A-15)
   ***********************************************************************************/
  PROCEDURE update_task(
     in_task_id           IN  NUMBER                      -- タスクID
    ,in_obj_ver_num       IN  NUMBER                      -- オブジェクトバージョン番号
    ,iv_attribute15       IN  VARCHAR2                    -- DFF15
    ,ov_errbuf            OUT NOCOPY VARCHAR2             -- エラー・メッセージ            -- # 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2             -- リターン・コード              -- # 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  -- # 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name          CONSTANT VARCHAR2(100)   := 'update_task';     -- プログラム名
--
-- #####################  固定ローカル変数宣言部 START     #########################
--
    lv_errbuf            VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode           VARCHAR2(1);     -- リターン・コード
    lv_errmsg            VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
-- #####################  固定ローカル変数宣言部 END       #########################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
    cv_task_id           CONSTANT VARCHAR2(30) := 'タスクID:';
    cv_task_id2          CONSTANT VARCHAR2(30) := 'タスクID';
    cv_task_table_nm     CONSTANT VARCHAR2(30) := 'タスクテーブル';
    --
    -- *** ローカル変数 ***
    ln_task_id          NUMBER;
--
    -- *** ローカル例外 ***
    g_lock_expt                   EXCEPTION;   -- ロック例外
    api_expt                      EXCEPTION;   -- タスクAPI例外
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--

    -- =======================
    -- タスクデータロック
    -- =======================
    BEGIN
      SELECT task_id
      INTO   ln_task_id
      FROM   jtf_tasks_b  jtb -- タスクテーブル
      WHERE  jtb.task_id = in_task_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_15           --メッセージコード
                      ,iv_token_name1  => cv_tkn_table               --トークンコード1
                      ,iv_token_value1 => cv_task_table_nm           --トークン値1
                      ,iv_token_name2  => cv_tkn_errmsg1             --トークンコード2
                      ,iv_token_value2 => cv_task_id ||  in_task_id  --トークン値2
                     );
        lv_errbuf := lv_errmsg || SQLERRM;
        RAISE g_lock_expt;
    END;

    -- =======================
    -- タスクデータ更新 
    -- =======================
    xxcso_task_common_pkg.update_task2(
       in_task_id
      ,in_obj_ver_num
      ,iv_attribute15
      ,lv_errbuf
      ,lv_retcode
      ,lv_errmsg
    );
    -- 正常ではない場合
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                 -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_16            -- メッセージコード
                     ,iv_token_name1  => cv_tkn_api_name             -- トークンコード1
                     ,iv_token_value1 => cv_task_id2                 -- トークン値1
                     ,iv_token_name2  => cv_tkn_api_msg              -- トークンコード2
                     ,iv_token_value2 => in_task_id || ',' || lv_errmsg -- トークン値2
                   );
      lv_errbuf := lv_errbuf || cv_msg_part || lv_errmsg;
      RAISE api_expt;
    END IF;
--
  EXCEPTION
    WHEN g_lock_expt THEN
      -- *** SQLロックエラーハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    WHEN api_expt THEN
      -- *** タスク更新API例外ハンドラ ***
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
      --
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
  END update_task;
--
/* 2009.10.23 D.Abe E_T4_00056対応 END */
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     iv_from_value       IN  VARCHAR2          -- パラメータ更新日 FROM
    ,iv_to_value         IN  VARCHAR2          -- パラメータ更新日 TO
    ,ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'submain';     -- プログラム名
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
    cv_src_obj_tp_cd    CONSTANT VARCHAR2(100)   := 'PARTY';        -- ソースタイプ
    cv_owner_tp_cd      CONSTANT VARCHAR2(100)   := 'RS_EMPLOYEE';  -- オーナータイプ
    cv_category         CONSTANT VARCHAR2(100)   := 'EMPLOYEE';     -- カテゴリー
    cv_yes              CONSTANT VARCHAR2(1)     := 'Y';            -- 削除フラグ:Y
    cv_no               CONSTANT VARCHAR2(1)     := 'N';            -- 削除フラグ:N
    cv_normal           CONSTANT VARCHAR2(1)     := '0';            -- 削除フラグ 0:通常
    cv_delete           CONSTANT VARCHAR2(1)     := '1';            -- 削除フラグ 1:削除
    cv_active           CONSTANT VARCHAR2(1)     := '1';            -- 有効訪問区分 1:有効
    cv_invalid          CONSTANT VARCHAR2(1)     := '0';            -- 有効訪問区分 0:無効
    cv_dlv_gds_info     CONSTANT VARCHAR2(1)     := '3';            -- 登録区分     3:納品情報
    cv_abrb_clclt       CONSTANT VARCHAR2(1)     := '5';            -- 登録区分     5:消化計算
    /* 2009.04.22 K.Satomura T1_0478対応 START */
    cv_task_type_visit    CONSTANT VARCHAR2(30)  := 'XXCSO1_TASK_TYPE_VISIT';
    cv_src_obj_tp_cd_opp  CONSTANT VARCHAR2(100) := 'OPPORTUNITY'; -- ソースタイプ
    /* 2009.04.22 K.Satomura T1_0478対応 END */
    /* 2009.10.07 D.Abe 0001454対応 START */
    cv_cust_status10    CONSTANT VARCHAR2(2)     := '10';           -- 顧客ステータス(MC候補)
    cv_cust_status20    CONSTANT VARCHAR2(2)     := '20';           -- 顧客ステータス(MC)
    cv_cust_status25    CONSTANT VARCHAR2(2)     := '25';           -- 顧客ステータス(SP承認)
    cv_cust_status30    CONSTANT VARCHAR2(2)     := '30';           -- 顧客ステータス(承認済)
    /* 2009.10.07 D.Abe 0001454対応 END */
    -- *** ローカル変数 ***
    -- OUTパラメータ格納用
    lv_from_value   VARCHAR2(2000); -- パラメータ更新日 FROM
    lv_to_value     VARCHAR2(2000); -- パラメータ更新日 TO
    ld_from_value   DATE;           -- 編集後パラメータ更新日 FROM 格納用
    ld_to_value     DATE;           -- 編集後パラメータ更新日 TO   格納用
    ld_sysdate      DATE;           -- システム日付
    ld_process_date DATE;           -- 業務処理日付
    lv_company_cd   VARCHAR2(2000); -- 会社コード（固定値001）
    lv_csv_dir      VARCHAR2(2000); -- CSVファイル出力先
    lv_csv_nm       VARCHAR2(2000); -- CSVファイル名
    lv_tsk_stts_cls VARCHAR2(2000); -- タスクステータスID(クローズ)
    lv_ib_del_stts  VARCHAR2(2000); -- インストールベースステータス(物件削除済)
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd   BOOLEAN;
    --
--
    -- *** ローカル・カーソル ***
    -- 訪問実績データ抽出カーソル
    CURSOR get_vst_rslt_data_cur
    IS
      /* 2009.04.22 K.Satomura T1_0478対応 START */
      --SELECT  jtb.actual_end_date           actual_end_date              -- 訪問日
      --       ,jtb.task_id                   task_id                      -- 訪問回数
      --       ,jtb.attribute1                attribute1                   -- 訪問区分コード1
      --       ,jtb.attribute2                attribute2                   -- 訪問区分コード2
      --       ,jtb.attribute3                attribute3                   -- 訪問区分コード3
      --       ,jtb.attribute4                attribute4                   -- 訪問区分コード4
      --       ,jtb.attribute5                attribute5                   -- 訪問区分コード5
      --       ,jtb.attribute6                attribute6                   -- 訪問区分コード6
      --       ,jtb.attribute7                attribute7                   -- 訪問区分コード7
      --       ,jtb.attribute8                attribute8                   -- 訪問区分コード8
      --       ,jtb.attribute9                attribute9                   -- 訪問区分コード9
      --       ,jtb.attribute10               attribute10                  -- 訪問区分コード10
      --       ,TO_CHAR(jtb.actual_end_date,'hh24mi')  actual_end_hour     -- 訪問時間
      --       ,jtb.deleted_flag              deleted_flag                 -- 削除フラグ
      --       ,jtb.source_object_type_code   source_object_type_code      -- ソースタイプ
      --       ,jtb.source_object_id          source_object_id             -- パーティID
      --       ,jtb.attribute11               attribute11                  -- 有効訪問区分
      --       ,jtb.attribute12               attribute12                  -- 登録元区分
      --       ,jtb.attribute13               attribute13                  -- 登録元ソース番号
      --       ,ppf.employee_number           employee_number              -- 営業員コード
      --FROM    jtf_tasks_b           jtb   -- タスクテーブル
      --       ,per_people_f          ppf   -- 従業員マスタ
      --       ,jtf_rs_resource_extns jrre  -- リソースマスタ
      --WHERE  (TRUNC(jtb.last_update_date)
      --         BETWEEN ld_from_value AND ld_to_value
      --       )
      --  AND  jtb.source_object_type_code = cv_src_obj_tp_cd
      --  AND  jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      --  AND  jtb.owner_type_code         = cv_owner_tp_cd
      --  AND  jtb.owner_id                = jrre.resource_id
      --  AND  jrre.category               = cv_category
      --  AND  jrre.source_id              = ppf.person_id
      -- クローズされているタスク
      -- 指定した日付で作成/更新があった訪問実績/訪問予定データ（顧客）
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- 訪問日
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n21) */
             jtb.actual_end_date                   actual_end_date         -- 訪問日
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
            ,jtb.task_id                           task_id                 -- 訪問回数
            ,jtb.attribute1                        attribute1              -- 訪問区分コード1
            ,jtb.attribute2                        attribute2              -- 訪問区分コード2
            ,jtb.attribute3                        attribute3              -- 訪問区分コード3
            ,jtb.attribute4                        attribute4              -- 訪問区分コード4
            ,jtb.attribute5                        attribute5              -- 訪問区分コード5
            ,jtb.attribute6                        attribute6              -- 訪問区分コード6
            ,jtb.attribute7                        attribute7              -- 訪問区分コード7
            ,jtb.attribute8                        attribute8              -- 訪問区分コード8
            ,jtb.attribute9                        attribute9              -- 訪問区分コード9
            ,jtb.attribute10                       attribute10             -- 訪問区分コード10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- 訪問時間
            /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
            --,jtb.deleted_flag                      deleted_flag            -- 削除フラグ
            ,(CASE
                WHEN (TRUNC(jtb.actual_end_date) > ld_process_date) THEN
                  cv_yes
                WHEN (jtb.task_status_id <> lv_tsk_stts_cls) THEN
                  cv_yes
                WHEN (jtb.deleted_flag = cv_yes) THEN
                  cv_yes
                ELSE
                  cv_no
              END
             )                                     deleted_flag            -- 削除フラグ
            /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
            ,jtb.source_object_type_code           source_object_type_code -- ソースタイプ
            ,jtb.source_object_id                  source_object_id        -- パーティID
            ,jtb.attribute11                       attribute11             -- 有効訪問区分
            ,jtb.attribute12                       attribute12             -- 登録元区分
            ,jtb.attribute13                       attribute13             -- 登録元ソース番号
            ,ppf.employee_number                   employee_number         -- 営業員コード
            /* 2009.10.07 D.Abe 0001454対応 START */
            ,jtb.attribute14                       attribute14             -- 顧客ステータス
            /* 2009.10.07 D.Abe 0001454対応 END */
            /* 2009.10.23 D.Abe E_T4_00056対応 START */
            ,jtb.attribute15                       attribute15             -- 情報系連携エラーステータス
            ,jtb.object_version_number             obj_ver_num             -- オブジェクトバージョン番号
            /* 2009.10.23 D.Abe E_T4_00056対応 END */
      FROM   jtf_tasks_b           jtb -- タスクテーブル
            ,per_people_f          ppf -- 従業員マスタ
            ,jtf_rs_resource_extns jrr -- リソースマスタ
      /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code = cv_src_obj_tp_cd
      --AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         = cv_owner_tp_cd
      --AND    jtb.owner_id                = jrr.resource_id
      --AND    jrr.category                = cv_category
      --AND    jrr.source_id               = ppf.person_id
      --AND    jtb.actual_end_date         IS NOT NULL
      --AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.source_object_type_code = cv_src_obj_tp_cd
      AND    jtb.actual_end_date         IS NOT NULL
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      /* 2009.09.09 D.Abe 0001323対応 START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      /* 2009.09.09 D.Abe 0001323対応 END */
      /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
      /* 2009.07.21 K.Satomura 0000070対応 START */
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = lv_tsk_stts_cls
      AND    jtb.deleted_flag            = cv_no
      /* 2009.07.21 K.Satomura 0000070対応 END */
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
      -- クローズ以外の過去日付のタスク
      -- 指定した日付よりも過去に作成/更新されたレコードで当日が訪問日時の訪問実績データ（顧客）
      UNION ALL
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- 訪問日
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n20) */
             jtb.actual_end_date                   actual_end_date         -- 訪問日
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
            ,jtb.task_id                           task_id                 -- 訪問回数
            ,jtb.attribute1                        attribute1              -- 訪問区分コード1
            ,jtb.attribute2                        attribute2              -- 訪問区分コード2
            ,jtb.attribute3                        attribute3              -- 訪問区分コード3
            ,jtb.attribute4                        attribute4              -- 訪問区分コード4
            ,jtb.attribute5                        attribute5              -- 訪問区分コード5
            ,jtb.attribute6                        attribute6              -- 訪問区分コード6
            ,jtb.attribute7                        attribute7              -- 訪問区分コード7
            ,jtb.attribute8                        attribute8              -- 訪問区分コード8
            ,jtb.attribute9                        attribute9              -- 訪問区分コード9
            ,jtb.attribute10                       attribute10             -- 訪問区分コード10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- 訪問時間
            /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
            --,cv_yes                                deleted_flag            -- 削除フラグ
            ,cv_no                                 deleted_flag            -- 削除フラグ
            /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
            ,jtb.source_object_type_code           source_object_type_code -- ソースタイプ
            ,jtb.source_object_id                  source_object_id        -- パーティID
            ,jtb.attribute11                       attribute11             -- 有効訪問区分
            ,jtb.attribute12                       attribute12             -- 登録元区分
            ,jtb.attribute13                       attribute13             -- 登録元ソース番号
            ,ppf.employee_number                   employee_number         -- 営業員コード
            /* 2009.10.07 D.Abe 0001454対応 START */
            ,jtb.attribute14                       attribute14             -- 顧客ステータス
            /* 2009.10.07 D.Abe 0001454対応 END */
            /* 2009.10.23 D.Abe E_T4_00056対応 START */
            ,jtb.attribute15                       attribute15             -- 情報系連携エラーステータス
            ,jtb.object_version_number             obj_ver_num             -- オブジェクトバージョン番号
            /* 2009.10.23 D.Abe E_T4_00056対応 END */
      FROM   jtf_tasks_b           jtb -- タスクテーブル
            ,per_people_f          ppf -- 従業員マスタ
            ,jtf_rs_resource_extns jrr -- リソースマスタ
      /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code =  cv_src_obj_tp_cd
      --AND    jtb.task_status_id          <> TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         =  cv_owner_tp_cd
      --AND    jtb.owner_id                =  jrr.resource_id
      --AND    jrr.category                =  cv_category
      --AND    jrr.source_id               =  ppf.person_id
      --AND    jtb.task_type_id            =  fnd_profile.value(cv_task_type_visit)
      --AND    TRUNC(jtb.actual_end_date)  <= TRUNC(ld_process_date)
      WHERE  TRUNC(jtb.last_update_date)  < ld_from_value
      AND    jtb.task_type_id             = fnd_profile.value(cv_task_type_visit)
      AND    jtb.task_status_id           = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.source_object_type_code  = cv_src_obj_tp_cd
      AND    TRUNC(jtb.actual_end_date)   = ld_process_date
      AND    jtb.owner_type_code          = cv_owner_tp_cd
      AND    jtb.owner_id                 = jrr.resource_id
      AND    jrr.category                 = cv_category
      AND    jrr.source_id                = ppf.person_id
      /* 2009.09.09 D.Abe 0001323対応 START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    jtb.deleted_flag            = cv_no
      /* 2009.09.09 D.Abe 0001323対応 END */
      /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
      UNION ALL
      -- クローズされている商談タスク
      -- 指定した日付で作成/更新があった訪問実績/訪問予定データ（商談）
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- 訪問日
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n21) */
             jtb.actual_end_date                   actual_end_date         -- 訪問日
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
            ,jtb.task_id                           task_id                 -- 訪問回数
            ,jtb.attribute1                        attribute1              -- 訪問区分コード1
            ,jtb.attribute2                        attribute2              -- 訪問区分コード2
            ,jtb.attribute3                        attribute3              -- 訪問区分コード3
            ,jtb.attribute4                        attribute4              -- 訪問区分コード4
            ,jtb.attribute5                        attribute5              -- 訪問区分コード5
            ,jtb.attribute6                        attribute6              -- 訪問区分コード6
            ,jtb.attribute7                        attribute7              -- 訪問区分コード7
            ,jtb.attribute8                        attribute8              -- 訪問区分コード8
            ,jtb.attribute9                        attribute9              -- 訪問区分コード9
            ,jtb.attribute10                       attribute10             -- 訪問区分コード10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- 訪問時間
            /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
            --,jtb.deleted_flag                      deleted_flag            -- 削除フラグ
            ,(CASE
                WHEN (TRUNC(jtb.actual_end_date) > ld_process_date) THEN
                  cv_yes
                WHEN (jtb.task_status_id <> TO_NUMBER(lv_tsk_stts_cls)) THEN
                  cv_yes
                WHEN (jtb.deleted_flag = cv_yes) THEN
                  cv_yes
                ELSE
                  cv_no
              END
             )                                     deleted_flag            -- 削除フラグ
            /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
            ,jtb.source_object_type_code           source_object_type_code -- ソースタイプ
            ,ala.customer_id                       source_object_id        -- パーティID
            ,jtb.attribute11                       attribute11             -- 有効訪問区分
            ,jtb.attribute12                       attribute12             -- 登録元区分
            ,jtb.attribute13                       attribute13             -- 登録元ソース番号
            ,ppf.employee_number                   employee_number         -- 営業員コード
            /* 2009.10.07 D.Abe 0001454対応 START */
            ,jtb.attribute14                       attribute14             -- 顧客ステータス
            /* 2009.10.07 D.Abe 0001454対応 END */
            /* 2009.10.23 D.Abe E_T4_00056対応 START */
            ,jtb.attribute15                       attribute15             -- 情報系連携エラーステータス
            ,jtb.object_version_number             obj_ver_num             -- オブジェクトバージョン番号
            /* 2009.10.23 D.Abe E_T4_00056対応 END */
      FROM   jtf_tasks_b           jtb -- タスクテーブル
            ,per_people_f          ppf -- 従業員マスタ
            ,jtf_rs_resource_extns jrr -- リソースマスタ
            ,as_leads_all          ala -- 商談テーブル
      /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code = cv_src_obj_tp_cd_opp
      --AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         = cv_owner_tp_cd
      --AND    jtb.owner_id                = jrr.resource_id
      --AND    jrr.category                = cv_category
      --AND    jrr.source_id               = ppf.person_id
      --AND    jtb.actual_end_date         IS NOT NULL
      --AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      --AND    ala.lead_id                 = jtb.source_object_id
      WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.source_object_type_code = cv_src_obj_tp_cd_opp
      AND    jtb.actual_end_date         IS NOT NULL
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      /* 2009.09.09 D.Abe 0001323対応 START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      /* 2009.09.09 D.Abe 0001323対応 END */
      AND    ala.lead_id                 = jtb.source_object_id
      /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
      /* 2009.07.21 K.Satomura 0000070対応 START */
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = lv_tsk_stts_cls
      AND    jtb.deleted_flag            = cv_no
      /* 2009.07.21 K.Satomura 0000070対応 END */
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
      UNION ALL
      -- クローズ以外の過去日付の商談タスク
      -- 指定した日付よりも過去に作成/更新されたレコードで当日が訪問日時の訪問実績データ（商談）
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      --SELECT jtb.actual_end_date                   actual_end_date         -- 訪問日
      SELECT /*+ leading(jtb) index(jtb xxcso_jtf_tasks_b_n20) */
             jtb.actual_end_date                   actual_end_date         -- 訪問日
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
            ,jtb.task_id                           task_id                 -- 訪問回数
            ,jtb.attribute1                        attribute1              -- 訪問区分コード1
            ,jtb.attribute2                        attribute2              -- 訪問区分コード2
            ,jtb.attribute3                        attribute3              -- 訪問区分コード3
            ,jtb.attribute4                        attribute4              -- 訪問区分コード4
            ,jtb.attribute5                        attribute5              -- 訪問区分コード5
            ,jtb.attribute6                        attribute6              -- 訪問区分コード6
            ,jtb.attribute7                        attribute7              -- 訪問区分コード7
            ,jtb.attribute8                        attribute8              -- 訪問区分コード8
            ,jtb.attribute9                        attribute9              -- 訪問区分コード9
            ,jtb.attribute10                       attribute10             -- 訪問区分コード10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- 訪問時間
            /* 2009.09.09 D.Abe 0001323対応 START */
            --,cv_yes                                deleted_flag            -- 削除フラグ
            ,cv_no                                 deleted_flag            -- 削除フラグ
            /* 2009.09.09 D.Abe 0001323対応 END */
            ,jtb.source_object_type_code           source_object_type_code -- ソースタイプ
            ,ala.customer_id                       source_object_id        -- パーティID
            ,jtb.attribute11                       attribute11             -- 有効訪問区分
            ,jtb.attribute12                       attribute12             -- 登録元区分
            ,jtb.attribute13                       attribute13             -- 登録元ソース番号
            ,ppf.employee_number                   employee_number         -- 営業員コード
            /* 2009.10.07 D.Abe 0001454対応 START */
            ,jtb.attribute14                       attribute14             -- 顧客ステータス
            /* 2009.10.07 D.Abe 0001454対応 END */
            /* 2009.10.23 D.Abe E_T4_00056対応 START */
            ,jtb.attribute15                       attribute15             -- 情報系連携エラーステータス
            ,jtb.object_version_number             obj_ver_num             -- オブジェクトバージョン番号
            /* 2009.10.23 D.Abe E_T4_00056対応 END */
      FROM   jtf_tasks_b           jtb -- タスクテーブル
            ,per_people_f          ppf -- 従業員マスタ
            ,jtf_rs_resource_extns jrr -- リソースマスタ
            ,as_leads_all          ala -- 商談テーブル
      /* 2009.06.05 K.Satomura T1_0478再修正対応 START */
      --WHERE  (TRUNC(jtb.last_update_date) BETWEEN ld_from_value AND ld_to_value)
      --AND    jtb.source_object_type_code =  cv_src_obj_tp_cd_opp
      --AND    jtb.task_status_id          <> TO_NUMBER(lv_tsk_stts_cls)
      --AND    jtb.owner_type_code         =  cv_owner_tp_cd
      --AND    jtb.owner_id                =  jrr.resource_id
      --AND    jrr.category                =  cv_category
      --AND    jrr.source_id               =  ppf.person_id
      --AND    TRUNC(jtb.actual_end_date)  <= TRUNC(ld_process_date)
      --AND    jtb.task_type_id            =  fnd_profile.value(cv_task_type_visit)
      --AND    ala.lead_id                 =  jtb.source_object_id
      WHERE  TRUNC(jtb.last_update_date)  < ld_from_value
      AND    jtb.task_type_id             = fnd_profile.value(cv_task_type_visit)
      AND    jtb.task_status_id           = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.source_object_type_code  = cv_src_obj_tp_cd_opp
      AND    TRUNC(jtb.actual_end_date)   = ld_process_date
      AND    jtb.owner_type_code         =  cv_owner_tp_cd
      AND    jtb.owner_id                =  jrr.resource_id
      AND    jrr.category                =  cv_category
      AND    jrr.source_id               =  ppf.person_id
      /* 2009.09.09 D.Abe 0001323対応 START */
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    jtb.deleted_flag            = cv_no
      /* 2009.09.09 D.Abe 0001323対応 END */
      AND    ala.lead_id                 =  jtb.source_object_id
      /* 2009.06.05 K.Satomura T1_0478再修正対応 END */
      /* 2009.04.22 K.Satomura T1_0478対応 END */
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      AND    jtb.attribute15             IS NULL
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
      /* 2009.10.23 D.Abe E_T4_00056対応 START */
      UNION ALL
      --連携エラーデータ（顧客訪問タスク）取得
      SELECT /*+ leading(jtb) use_concat index(jtb xxcso_jtf_tasks_b_n22) */
             jtb.actual_end_date                   actual_end_date         -- 訪問日
            ,jtb.task_id                           task_id                 -- 訪問回数
            ,jtb.attribute1                        attribute1              -- 訪問区分コード1
            ,jtb.attribute2                        attribute2              -- 訪問区分コード2
            ,jtb.attribute3                        attribute3              -- 訪問区分コード3
            ,jtb.attribute4                        attribute4              -- 訪問区分コード4
            ,jtb.attribute5                        attribute5              -- 訪問区分コード5
            ,jtb.attribute6                        attribute6              -- 訪問区分コード6
            ,jtb.attribute7                        attribute7              -- 訪問区分コード7
            ,jtb.attribute8                        attribute8              -- 訪問区分コード8
            ,jtb.attribute9                        attribute9              -- 訪問区分コード9
            ,jtb.attribute10                       attribute10             -- 訪問区分コード10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- 訪問時間
            ,cv_no                                 deleted_flag            -- 削除フラグ
            ,jtb.source_object_type_code           source_object_type_code -- ソースタイプ
            ,jtb.source_object_id                  source_object_id        -- パーティID
            ,jtb.attribute11                       attribute11             -- 有効訪問区分
            ,jtb.attribute12                       attribute12             -- 登録元区分
            ,jtb.attribute13                       attribute13             -- 登録元ソース番号
            ,ppf.employee_number                   employee_number         -- 営業員コード
            ,jtb.attribute14                       attribute14             -- 顧客ステータス
            ,jtb.attribute15                       attribute15             -- 情報系連携エラーステータス
            ,jtb.object_version_number             obj_ver_num             -- オブジェクトバージョン番号
      FROM   jtf_tasks_b           jtb -- タスクテーブル
            ,per_people_f          ppf -- 従業員マスタ
            ,jtf_rs_resource_extns jrr -- リソースマスタ
      WHERE  jtb.source_object_type_code = cv_src_obj_tp_cd
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.deleted_flag            = cv_no
      AND    (
              (jtb.attribute15           = cv_yes)
              OR
              (jtb.attribute15 BETWEEN TO_CHAR(ld_from_value,'YYYYMMDD')
                                   AND TO_CHAR(ld_to_value  ,'YYYYMMDD')
              )
             )
      UNION ALL
      --連携エラーデータ（商談タスク）取得
      SELECT /*+ leading(jtb) use_concat index(jtb xxcso_jtf_tasks_b_n22) */
             jtb.actual_end_date                   actual_end_date         -- 訪問日
            ,jtb.task_id                           task_id                 -- 訪問回数
            ,jtb.attribute1                        attribute1              -- 訪問区分コード1
            ,jtb.attribute2                        attribute2              -- 訪問区分コード2
            ,jtb.attribute3                        attribute3              -- 訪問区分コード3
            ,jtb.attribute4                        attribute4              -- 訪問区分コード4
            ,jtb.attribute5                        attribute5              -- 訪問区分コード5
            ,jtb.attribute6                        attribute6              -- 訪問区分コード6
            ,jtb.attribute7                        attribute7              -- 訪問区分コード7
            ,jtb.attribute8                        attribute8              -- 訪問区分コード8
            ,jtb.attribute9                        attribute9              -- 訪問区分コード9
            ,jtb.attribute10                       attribute10             -- 訪問区分コード10
            ,TO_CHAR(jtb.actual_end_date,'hh24mi') actual_end_hour         -- 訪問時間
            ,cv_no                                 deleted_flag            -- 削除フラグ
            ,jtb.source_object_type_code           source_object_type_code -- ソースタイプ
            ,ala.customer_id                       source_object_id        -- パーティID
            ,jtb.attribute11                       attribute11             -- 有効訪問区分
            ,jtb.attribute12                       attribute12             -- 登録元区分
            ,jtb.attribute13                       attribute13             -- 登録元ソース番号
            ,ppf.employee_number                   employee_number         -- 営業員コード
            ,jtb.attribute14                       attribute14             -- 顧客ステータス
            ,jtb.attribute15                       attribute15             -- 情報系連携エラーステータス
            ,jtb.object_version_number             obj_ver_num             -- オブジェクトバージョン番号
      FROM   jtf_tasks_b           jtb -- タスクテーブル
            ,per_people_f          ppf -- 従業員マスタ
            ,jtf_rs_resource_extns jrr -- リソースマスタ
            ,as_leads_all          ala -- 商談テーブル
      WHERE  jtb.source_object_type_code = cv_src_obj_tp_cd_opp
      AND    jtb.owner_type_code         = cv_owner_tp_cd
      AND    jtb.owner_id                = jrr.resource_id
      AND    jrr.category                = cv_category
      AND    jrr.source_id               = ppf.person_id
      AND    TRUNC(jtb.actual_end_date) BETWEEN ppf.effective_start_date
      AND    ppf.effective_end_date
      AND    TRUNC(jtb.actual_end_date) <= ld_process_date
      AND    jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.task_type_id            = fnd_profile.value(cv_task_type_visit)
      AND    jtb.deleted_flag            = cv_no
      AND    (
              (jtb.attribute15           = cv_yes)
              OR
              (jtb.attribute15 BETWEEN TO_CHAR(ld_from_value,'YYYYMMDD')
                                   AND TO_CHAR(ld_to_value  ,'YYYYMMDD')
              )
             )
      AND    ala.lead_id                 = jtb.source_object_id
      /* 2009.10.23 D.Abe E_T4_00056対応 END */
      ;
    -- 前回訪問日抽出カーソル
    CURSOR get_lst_vst_dt_cur(
              it_srce_objct_id  IN jtf_tasks_b.source_object_id%TYPE -- パーティID
             ,it_task_id        IN jtf_tasks_b.task_id%TYPE          -- タスクID
             ,it_act_end_dt     IN jtf_tasks_b.actual_end_date%TYPE  -- 実績終了日
           )
    IS
      SELECT  jtb.actual_end_date   actual_end_date   -- 前回訪問日
             ,jtb.attribute11       attribute11       -- 有効訪問区分
             ,jtb.attribute12       attribute12       -- 登録区分
      FROM   jtf_tasks_b    jtb                       -- タスクテーブル
      WHERE  jtb.source_object_type_code = cv_src_obj_tp_cd
        AND  jtb.task_status_id          = TO_NUMBER(lv_tsk_stts_cls)
        AND  jtb.owner_type_code         = cv_owner_tp_cd
        AND  jtb.source_object_id        = it_srce_objct_id
        AND  jtb.task_id                <> it_task_id
        AND  jtb.actual_end_date        <= it_act_end_dt
        AND  jtb.deleted_flag            = cv_no
      /* 2009.04.22 K.Satomura T1_0478対応 START */
      UNION ALL
      SELECT jtb.actual_end_date actual_end_date -- 前回訪問日
            ,jtb.attribute11     attribute11     -- 有効訪問区分
            ,jtb.attribute12     attribute12     -- 登録区分
      FROM   jtf_tasks_b  jtb -- タスクテーブル
            ,as_leads_all ala -- 商談テーブル
      WHERE  jtb.source_object_type_code =  cv_src_obj_tp_cd_opp
      AND    jtb.task_status_id          =  TO_NUMBER(lv_tsk_stts_cls)
      AND    jtb.owner_type_code         =  cv_owner_tp_cd
      AND    jtb.task_id                 <> it_task_id
      AND    jtb.actual_end_date         <= it_act_end_dt
      AND    jtb.deleted_flag            =  cv_no
      AND    ala.lead_id                 =  jtb.source_object_id
      AND    ala.customer_id             =  it_srce_objct_id
      /* 2009.04.22 K.Satomura T1_0478対応 END */
      ORDER BY actual_end_date DESC
    ;
--
    -- *** ローカル・レコード ***
    l_get_vst_rslt_dt_rec     get_vst_rslt_data_cur%ROWTYPE;
    l_get_lst_vst_dt_rec      get_lst_vst_dt_cur%ROWTYPE;
    l_get_data_rec            g_get_data_rtype;
    -- *** ローカル例外 ***
    error_skip_data_expt           EXCEPTION;   -- 処理スキップ例外
    /* 2009.10.07 D.Abe 0001454対応 START */
    status_skip_data_expt          EXCEPTION;   -- 処理対象外例外
    /* 2009.10.07 D.Abe 0001454対応 END */
    /* 2009.10.23 D.Abe E_T4_00056対応 START */
    update_skip_data_expt          EXCEPTION;   -- 更新例外
    /* 2009.10.23 D.Abe E_T4_00056対応 END */
    /* 2009.12.02 T.Maruyama E_本稼動_00081対応 START */
    cust_error_skip_expt           EXCEPTION;   --  顧客マスタ不備スキップ
    /* 2009.12.02 T.Maruyama E_本稼動_00081対応 END */
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
    /* 2009.10.07 D.Abe 0001454対応 START */
    gn_skip_cnt  := 0;
    /* 2009.10.07 D.Abe 0001454対応 END */
    -- INパラメータ格納
    lv_from_value := iv_from_value;  -- パラメータ更新日 FROM
    lv_to_value   := iv_to_value;    -- パラメータ更新日 TO
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
      iv_from_value    => lv_from_value       -- パラメータ更新日 FROM
     ,iv_to_value      => lv_to_value         -- パラメータ更新日 TO
     ,od_sysdate       => ld_sysdate          -- システム日付
     ,od_process_date  => ld_process_date     -- 業務処理日付
     ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-2.パラメータデフォルトセット
    -- ========================================
    set_param_default(
      io_from_value    => lv_from_value       -- パラメータ更新日 FROM
     ,io_to_value      => lv_to_value         -- パラメータ更新日 TO
     ,id_process_date  => ld_process_date     -- 業務処理日付
     ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
--
    -- ========================================
    -- A-3.パラメータチェック
    -- ========================================
    chk_param(
      io_from_value    => lv_from_value       -- パラメータ更新日 FROM
     ,io_to_value      => lv_to_value         -- パラメータ更新日 TO
     ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );                                        
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.プロファイル値取得
    -- ========================================
    get_profile_info(
      ov_company_cd     =>  lv_company_cd    -- 会社コード(固定値001)
     ,ov_csv_dir        =>  lv_csv_dir       -- CSVファイル出力先
     ,ov_csv_nm         =>  lv_csv_nm        -- CSVファイル名(訪問実績)
     ,ov_tsk_stts_cls   =>  lv_tsk_stts_cls  -- タスクステータスID(クローズ)
     ,ov_ib_del_stts    =>  lv_ib_del_stts   -- インストールベースステータス(物件削除済)
     ,ov_errbuf         =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
     ,ov_retcode        =>  lv_retcode       -- リターン・コード              --# 固定 #
     ,ov_errmsg         =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-5.訪問実績データCSVファイルオープン
    -- ========================================
    open_csv_file(
      iv_csv_dir       => lv_csv_dir          -- CSVファイル出力先
     ,iv_csv_nm        => lv_csv_nm           -- CSVファイル名
     ,ov_errbuf        => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-6.訪問実績データ抽出
    -- ========================================
    -- パラメータ更新日 編集
    ld_from_value := TO_DATE(lv_from_value,'yyyymmdd');
    ld_to_value   := TO_DATE(lv_to_value,'yyyymmdd');
--
    -- カーソルオープン
    OPEN get_vst_rslt_data_cur;
--
    <<get_vst_rslt_data_loop>>
    LOOP
--
      BEGIN
--
        FETCH get_vst_rslt_data_cur INTO l_get_vst_rslt_dt_rec;
        -- 処理対象件数格納
        gn_target_cnt := get_vst_rslt_data_cur%ROWCOUNT;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_vst_rslt_data_cur%NOTFOUND
        OR  get_vst_rslt_data_cur%ROWCOUNT = 0;
--

        /* 2009.10.07 D.Abe 0001454対応 START */
        -- 顧客ステータスがNOT NULLかつ,10(MC候補),20(MC),25(SP承認済),30(承認済)の場合スキップ
        IF ((l_get_vst_rslt_dt_rec.attribute14 IS NOT NULL) AND 
            (l_get_vst_rslt_dt_rec.attribute14 IN ( cv_cust_status10,
                                                    cv_cust_status20,
                                                    cv_cust_status25,
                                                    cv_cust_status30))) THEN
          RAISE status_skip_data_expt;
        END IF;
        /* 2009.10.07 D.Abe 0001454対応 END */
        -- レコード変数初期化
        l_get_data_rec := NULL;
        -- 取得データを格納
        l_get_data_rec.company_cd           :=  lv_company_cd;                             -- 会社コード
        l_get_data_rec.actual_end_date      :=  l_get_vst_rslt_dt_rec.actual_end_date;     -- 実績終了日
        l_get_data_rec.task_id              :=  l_get_vst_rslt_dt_rec.task_id;             -- 訪問回数
        l_get_data_rec.employee_number      :=  l_get_vst_rslt_dt_rec.employee_number;     -- 営業員コード
        l_get_data_rec.attribute1           :=  l_get_vst_rslt_dt_rec.attribute1;          -- 訪問区分コード1 
        l_get_data_rec.attribute2           :=  l_get_vst_rslt_dt_rec.attribute2;          -- 訪問区分コード2 
        l_get_data_rec.attribute3           :=  l_get_vst_rslt_dt_rec.attribute3;          -- 訪問区分コード3 
        l_get_data_rec.attribute4           :=  l_get_vst_rslt_dt_rec.attribute4;          -- 訪問区分コード4 
        l_get_data_rec.attribute5           :=  l_get_vst_rslt_dt_rec.attribute5;          -- 訪問区分コード5 
        l_get_data_rec.attribute6           :=  l_get_vst_rslt_dt_rec.attribute6;          -- 訪問区分コード6 
        l_get_data_rec.attribute7           :=  l_get_vst_rslt_dt_rec.attribute7;          -- 訪問区分コード7 
        l_get_data_rec.attribute8           :=  l_get_vst_rslt_dt_rec.attribute8;          -- 訪問区分コード8 
        l_get_data_rec.attribute9           :=  l_get_vst_rslt_dt_rec.attribute9;          -- 訪問区分コード9 
        l_get_data_rec.attribute10          :=  l_get_vst_rslt_dt_rec.attribute10;         -- 訪問区分コード10
        l_get_data_rec.attribute12          :=  l_get_vst_rslt_dt_rec.attribute12;         -- 登録元区分
        l_get_data_rec.attribute13          :=  l_get_vst_rslt_dt_rec.attribute13;         -- 登録元ソース番号
        l_get_data_rec.source_object_id     :=  l_get_vst_rslt_dt_rec.source_object_id;    -- パーティID
        --
        -- 有効訪問区分=1(有効)かつ登録区分=3(納品情報)もしくは5(消化計算)の場合
        IF (l_get_vst_rslt_dt_rec.attribute11 = cv_active) THEN
          IF ((l_get_vst_rslt_dt_rec.attribute12 = cv_dlv_gds_info)
            OR (l_get_vst_rslt_dt_rec.attribute12 = cv_abrb_clclt))
          THEN
            -- 有効訪問区分に1(有効)を設定
            l_get_data_rec.act_vst_dvsn := cv_active;
          ELSE
            -- 有効訪問区分に0(無効)を設定
            l_get_data_rec.act_vst_dvsn := cv_invalid;
          END IF;
        ELSE
          -- 有効訪問区分に0(無効)を設定
          l_get_data_rec.act_vst_dvsn := cv_invalid;
        END IF;
        l_get_data_rec.actual_end_hour      :=  l_get_vst_rslt_dt_rec.actual_end_hour;     -- 訪問時間
        --
        -- 削除フラグが'Y'の場合
        IF (l_get_vst_rslt_dt_rec.deleted_flag = cv_yes) THEN
          -- 削除フラグに 1:削除 を設定
          l_get_data_rec.deleted_flag       :=  cv_delete;  -- 削除フラグ
        -- 削除フラグが'N'の場合
        ELSIF (l_get_vst_rslt_dt_rec.deleted_flag = cv_no) THEN
          -- 削除フラグに 0:通常 を設定
          l_get_data_rec.deleted_flag       :=  cv_normal;  -- 削除フラグ
        END IF;
        l_get_data_rec.cprtn_date           :=   ld_sysdate;                               -- 連結日時
--
        -- ========================================
        -- A-7.顧客マスタ・顧客アドオンマスタ抽出
        -- ========================================
        get_accounts_data(
           io_get_data_rec    => l_get_data_rec     -- 訪問実績データ
          ,id_process_date    => ld_process_date    -- 業務処理日付
          ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ            --# 固定 #
          ,ov_retcode         => lv_retcode         -- リターン・コード              --# 固定 #
          ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_warn) THEN
          /* 2009.12.02 T.Maruyama E_本稼動_00081対応 START */
          --RAISE error_skip_data_expt;
          RAISE cust_error_skip_expt;
          /* 2009.12.02 T.Maruyama E_本稼動_00081対応 END */
        ELSIF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- ========================================
        -- A-8.インストールベースマスタ抽出
        -- ========================================
        get_extrnl_rfrnc(
           io_get_data_rec    => l_get_data_rec     -- 訪問実績データ
          ,iv_ib_del_stts     => lv_ib_del_stts     -- インストールベースステータス(物件削除済)
          ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ            --# 固定 #
          ,ov_retcode         => lv_retcode         -- リターン・コード              --# 固定 #
          ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
--
        -- 有効訪問区分が有効(1)かつ登録区分が納品情報(3)のもしくは消化計算(5)場合 
        IF (l_get_vst_rslt_dt_rec.attribute11 = cv_active) THEN
          /* 2009.04.22 K.Satomur T1_0740対応 START */
          --IF ((l_get_vst_rslt_dt_rec.attribute12 = cv_dlv_gds_info)
          --  OR (l_get_vst_rslt_dt_rec.attribute12 = cv_abrb_clclt))
          --THEN
          IF (l_get_vst_rslt_dt_rec.attribute12 = cv_dlv_gds_info) THEN
          /* 2009.04.22 K.Satomur T1_0740対応 END */
            -- ========================================
            -- A-9.販売実績ヘッダーテーブル・販売実績明細テーブル抽出
            -- ========================================
            get_sl_rslts_data(
              io_get_data_rec    =>  l_get_data_rec   -- 訪問実績データ
             ,ov_errbuf          =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
             ,ov_retcode         =>  lv_retcode       -- リターン・コード              --# 固定 #
             ,ov_errmsg          =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
            );
--
            IF (lv_retcode = cv_status_warn) THEN
              RAISE error_skip_data_expt;
            ELSIF (lv_retcode = cv_status_error) THEN
              RAISE global_process_expt;
            END IF;
--
          END IF;
        END IF;
        -- ========================================
        -- A-10.前回訪問日抽出
        -- ========================================
        -- カーソルオープン
        OPEN get_lst_vst_dt_cur(
              it_srce_objct_id  => l_get_data_rec.source_object_id  -- パーティID
             ,it_task_id        => l_get_data_rec.task_id           -- タスクID
             ,it_act_end_dt     => l_get_data_rec.actual_end_date   -- 実績終了日
             );
--
        <<get_lst_vst_dt_loop>>
        LOOP
          FETCH get_lst_vst_dt_cur INTO l_get_lst_vst_dt_rec;
          -- 処理対象データが存在しなかった場合、1件目を抽出し終えた場合 EXIT
          EXIT WHEN get_lst_vst_dt_cur%NOTFOUND
          OR  get_lst_vst_dt_cur%ROWCOUNT = 0;
--
          -- 前回訪問日を格納
          l_get_data_rec.actual_end_date_lt := l_get_lst_vst_dt_rec.actual_end_date;
--
        -- 有効訪問区分が有効(1)かつ登録区分が納品情報(3)もしくは消化計算(5)の場合 
          IF (l_get_lst_vst_dt_rec.attribute11 = cv_active) THEN
            IF (l_get_lst_vst_dt_rec.attribute12 IN (cv_dlv_gds_info,cv_abrb_clclt)) THEN
              -- 有効訪問区分に1(有効)を設定
              l_get_data_rec.act_vst_dvsn_lt := cv_active;
            ELSE
              -- 有効訪問区分に0(無効)を設定
              l_get_data_rec.act_vst_dvsn_lt := cv_invalid;
            END IF;
          ELSE
            -- 有効訪問区分に0(無効)を設定
            l_get_data_rec.act_vst_dvsn_lt := cv_invalid;
          END IF;
--
          -- 一件目取得できた時点でループを抜けます。
          EXIT WHEN get_lst_vst_dt_cur%NOTFOUND
          OR  get_lst_vst_dt_cur%ROWCOUNT <> 0;
--
        END LOOP get_lst_vst_dt_loop;
        -- 前回訪問日抽出カーソルで、対象データが存在しなかった場合
        IF (get_lst_vst_dt_cur%ROWCOUNT = 0) THEN
          l_get_data_rec.actual_end_date_lt := NULL;  -- 前回訪問日
          l_get_data_rec.act_vst_dvsn_lt    := NULL;  -- 有効訪問区分
        END IF;
        -- カーソルクローズ
        CLOSE get_lst_vst_dt_cur;

        -- ========================================
        -- A-11.訪問実績データCSV出力
        -- ========================================
        create_csv_rec(
          i_get_data_rec      =>  l_get_data_rec   -- 訪問実績データ
         ,ov_errbuf           =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
         ,ov_retcode          =>  lv_retcode       -- リターン・コード              --# 固定 #
         ,ov_errmsg           =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
        );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;

        /* 2009.10.23 D.Abe E_T4_00056対応 START */
        -- 情報系連携エラーステータスが'Y'の場合
        IF (l_get_vst_rslt_dt_rec.attribute15 = cv_yes ) THEN
          -- ========================================
          -- A-15.タスクデータ更新
          -- ========================================
          update_task(
            in_task_id          =>  l_get_vst_rslt_dt_rec.task_id     --タスクID
           ,in_obj_ver_num      =>  l_get_vst_rslt_dt_rec.obj_ver_num  --オブジェクトバージョン番号
           ,iv_attribute15      =>  TO_CHAR(ld_process_date,'YYYYMMDD')-- DFF15
           ,ov_errbuf           =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
           ,ov_retcode          =>  lv_retcode       -- リターン・コード              --# 固定 #
           ,ov_errmsg           =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
          );
          IF (lv_retcode = cv_status_error) THEN
            RAISE update_skip_data_expt;
          END IF;
          --
        END IF;
        /* 2009.10.23 D.Abe E_T4_00056対応 END */

        -- 成功件数をカウントアップ
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- 取得失敗のためスキップ
        WHEN error_skip_data_expt THEN
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        -- エラー出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
        );
        -- *** DEBUG_LOG ***
        -- データスキップしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip  || CHR(10) ||
                     lv_errbuf          || CHR(10) ||
                     ''
        );
        /* 2009.10.23 D.Abe E_T4_00056対応 START */
        -- ========================================
        -- A-15.タスクデータ更新
        -- ========================================
        update_task(
          in_task_id          =>  l_get_vst_rslt_dt_rec.task_id     --タスクID
         ,in_obj_ver_num      =>  l_get_vst_rslt_dt_rec.obj_ver_num  --オブジェクトバージョン番号
         ,iv_attribute15      =>  cv_yes           -- DFF15
         ,ov_errbuf           =>  lv_errbuf        -- エラー・メッセージ            --# 固定 #
         ,ov_retcode          =>  lv_retcode       -- リターン・コード              --# 固定 #
         ,ov_errmsg           =>  lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        IF (lv_retcode = cv_status_error) THEN
          -- エラー出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          -- 空行の挿入
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
          -- *** DEBUG_LOG ***
          -- データスキップしたことをログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_debug_msg_skip2 || CHR(10) ||
                       lv_errbuf          || CHR(10) ||
                       ''
          );
        END IF;
        /* 2009.10.23 D.Abe E_T4_00056対応 END */
        -- 全体の処理ステータスに警告セット
        ov_retcode := cv_status_warn;
--
        /* 2009.10.07 D.Abe 0001454対応 START */
        -- MC訪問のためスキップ
        WHEN status_skip_data_expt THEN
        -- スキップ件数カウント
        gn_skip_cnt := gn_skip_cnt + 1;
        -- *** DEBUG_LOG ***
        -- データスキップしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip1 || CHR(10) ||
                     cv_debug_msg18 || l_get_vst_rslt_dt_rec.task_id || CHR(10) ||
                     cv_debug_msg19 || l_get_vst_rslt_dt_rec.source_object_id || CHR(10) ||
                     cv_debug_msg20 || l_get_vst_rslt_dt_rec.attribute14 || CHR(10) ||
                     cv_debug_msg21 || TO_CHAR(l_get_vst_rslt_dt_rec.actual_end_date ,'yyyymmdd')|| CHR(10) ||
                     ''
        );
        /* 2009.10.07 D.Abe 0001454対応 END */
--      
        /* 2009.12.02 T.Maruyama E_本稼動_00081対応 START */
        -- 顧客マスタ不備のためスキップ
        WHEN cust_error_skip_expt THEN
          -- エラー件数カウント
          gn_error_cnt := gn_error_cnt + 1;
          -- エラー出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
          );
          -- *** DEBUG_LOG ***
          -- データスキップしたことをログ出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_debug_msg_skip3 || CHR(10) ||
                     cv_debug_msg18 || l_get_vst_rslt_dt_rec.task_id || CHR(10) ||
                     cv_debug_msg19 || l_get_vst_rslt_dt_rec.source_object_id || CHR(10) ||
                     cv_debug_msg20 || l_get_vst_rslt_dt_rec.attribute14 || CHR(10) ||
                     cv_debug_msg21 || TO_CHAR(l_get_vst_rslt_dt_rec.actual_end_date ,'yyyymmdd')|| CHR(10) ||
                     ''
          );
          -- 全体の処理ステータスに警告セット
          ov_retcode := cv_status_warn;
        /* 2009.12.02 T.Maruyama E_本稼動_00081対応 END */
--
        /* 2009.10.23 D.Abe E_T4_00056対応 START */
--
        -- タスク更新エラーのためスキップ
        WHEN update_skip_data_expt THEN
        -- エラー件数カウント
        gn_error_cnt := gn_error_cnt + 1;
        -- *** DEBUG_LOG ***
        -- データスキップしたことをログ出力
        -- エラー出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg                  -- ユーザー・エラーメッセージ
        );
          -- 空行の挿入
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => ''
          );
        -- *** DEBUG_LOG ***
        -- データスキップしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_skip2 || CHR(10) ||
                     lv_errbuf          || CHR(10) ||
                     ''
        );
        -- 全体の処理ステータスに警告セット
        ov_retcode := cv_status_warn;
        /* 2009.10.23 D.Abe E_T4_00056対応 END */
--
      END;
--
    END LOOP get_vst_rslt_data_loop;
--
    -- カーソルクローズ
    CLOSE get_vst_rslt_data_cur;
--
    -- ========================================
    -- A-12.CSVファイルクローズ処理
    -- ========================================
    close_csv_file(
      iv_csv_dir    => lv_csv_dir       -- CSVファイル出力先
     ,iv_csv_nm     => lv_csv_nm        -- CSVファイル名
     ,ov_errbuf     => lv_errbuf        -- エラー・メッセージ            --# 固定 #
     ,ov_retcode    => lv_retcode       -- リターン・コード              --# 固定 #
     ,ov_errmsg     => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_vst_rslt_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_vst_rslt_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_lst_vst_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_lst_vst_dt_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_vst_rslt_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_vst_rslt_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_lst_vst_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_lst_vst_dt_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      gn_error_cnt := gn_error_cnt + 1;
--
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file => gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_vst_rslt_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_vst_rslt_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_lst_vst_dt_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_lst_vst_dt_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls2|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
--
  PROCEDURE main(
     errbuf        OUT NOCOPY VARCHAR2    --   エラー・メッセージ  --# 固定 #
    ,retcode       OUT NOCOPY VARCHAR2    --   リターン・コード    --# 固定 #
    ,iv_from_value IN  VARCHAR2           --   パラメータ更新日 FROM
    ,iv_to_value   IN  VARCHAR2           --   パラメータ更新日 TO
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
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
       iv_from_value  => iv_from_value
      ,iv_to_value    => iv_to_value
      ,ov_errbuf      => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
       --エラー出力
       fnd_file.put_line(
          which  => FND_FILE.OUTPUT
         ,buff   => lv_errmsg                  --ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
          which  => FND_FILE.LOG
         ,buff   => cv_pkg_name||cv_msg_cont||
                    cv_prg_name||cv_msg_part||
                    lv_errbuf                  --エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-8.終了処理 
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
    /* 2009.10.07 D.Abe 0001454対応 START */
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_skip_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_skip_cnt)
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    /* 2009.10.07 D.Abe 0001454対応 END */
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF (lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;      
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
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      -- *** DEBUG_LOG ***
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg12 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO016A04C;
/
