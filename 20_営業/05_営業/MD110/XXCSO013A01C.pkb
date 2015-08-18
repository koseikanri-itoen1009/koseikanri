CREATE OR REPLACE PACKAGE BODY APPS.XXCSO013A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO013A01C(body)
 * Description      : 自販機管理システム側での引揚の完了後、顧客ステータスを休止にします。
 *                    また、自販機-EBSインタフェース：(IN)物件マスタ情報(IB)にて
 *                    顧客ステータスを「顧客」にすることができなかった場合のリカバリとして、
 *                    顧客獲得日が設定されていて、顧客ステータスが「承認済」の場合、
 *                    顧客ステータスを「顧客」に更新します。
 * MD.050           : MD050_CSO_013_A01_CSI→ARインタフェース：（OUT）顧客マスタ
 *
 * Version          : 1.6
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_profile_info       プロファイル値取得(A-2)
 *  get_cust_status        顧客ステータス抽出(A-3)
 *  chk_ib_info            物件存在チェック処理(A-5)
 *  get_cust_info          顧客情報抽出処理(A-6)
 *  chk_cust_ib            設置先顧客・物件チェック処理(A-7)
 *  update_cust_status     顧客ステータス更新処理(A-9)
 *  work_data_lock         作業データロック処理(A-11)
 *  update_work_data       作業データ更新処理(A-12)
 *  upd_xxcmm_cust_acnts   顧客アドオンマスタ更新処理(A-15)
 *  submain                メイン処理プロシージャ
 *                           作業データ抽出(A-4)
 *                           セーブポイント設定(A-8)
 *                           セーブポイント２設定(A-10)
 *                           顧客情報抽出(A-13)
 *                           セーブポイント３設定(A-14)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-16)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-17    1.0   Noriyuki.Yabuki  新規作成
 *  2009-03-12    1.1   Daisuke.Abe      変更依頼:IE_108対応
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
 *  2009-05-07    1.3   Tomoko.Mori      【T1_0439対応】自販機のみ顧客関連情報更新
 *  2009-07-23    1.4   Kazuo.Satomura   0000671対応
 *  2009-07-23    1.5   T.Maruyama       E_本稼動_00270対応
 *  2015-07-27    1.6   S.Yamashita      E_本稼動_13237対応
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
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO013A01C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(5)   := 'XXCSO';         -- アプリケーション短縮名
  cv_app_name_xxccp      CONSTANT VARCHAR2(5)   := 'XXCCP';         -- アプリケーション短縮名（アドオン：共通・IF領域）
  --
  -- メッセージコード
  cv_tkn_number_01       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラーメッセージ
  cv_tkn_number_02       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
  cv_tkn_number_03       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ抽出エラーメッセージ（作業データ、顧客）
  cv_tkn_number_04       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00056';  -- 物件存在チェック警告メッセージ
  cv_tkn_number_05       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00541';  -- 物件マスタ抽出エラーメッセージ（物件存在チェック）
  cv_tkn_number_06       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00385';  -- 処理エラーメッセージ（顧客情報抽出）
  cv_tkn_number_07       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00241';  -- ロックエラーメッセージ
  cv_tkn_number_08       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00058';  -- 顧客・物件チェック警告
  cv_tkn_number_09       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00534';  -- 物件マスタ抽出エラーメッセージ（設置先顧客・物件チェック）
  cv_tkn_number_10       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00235';  -- 処理エラーメッセージ（顧客ステータス更新）
  cv_tkn_number_11       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00169';  -- 顧客ステータス警告メッセージ
  cv_tkn_number_12       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00234';  -- 処理成功メッセージ
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00243';  -- データ抽出エラーメッセージ（パーティマスタ、顧客アドオンマスタ）
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00284';  -- 顧客ステータス更新成功メッセージ
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00285';  -- 顧客ステータス更新エラーメッセージ
  cv_tkn_number_16       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00321';  -- 作業データ処理エラーメッセージ（ロックエラー）
  cv_tkn_number_17       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00322';  -- 作業データ処理エラーメッセージ（抽出、更新）
  cv_tkn_number_18       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00385';  -- 処理エラーメッセージ（顧客アドオンマスタ更新）
  cv_tkn_number_19       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00542';  -- 休止処理メッセージ
  cv_tkn_number_20       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00543';  -- 承認済→顧客処理メッセージ
  cv_tkn_number_21       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00544';  -- 顧客情報なし警告メッセージ
  cv_tkn_number_22       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00545';  -- 参照タイプ内容取得エラーメッセージ
  cv_tkn_number_23       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00253';  -- 参照タイプ抽出エラーメッセージ
  --
  cv_tkn_num_xxccp_01    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
  --
  -- トークンコード
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';
  cv_tkn_errmsg          CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_base_val        CONSTANT VARCHAR2(20) := 'BASE_VALUE';
  cv_tkn_prof_nm         CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';
  cv_tkn_bukken          CONSTANT VARCHAR2(20) := 'BUKKEN';
  cv_tkn_kokyaku         CONSTANT VARCHAR2(20) := 'KOKYAKU';
  cv_tkn_action          CONSTANT VARCHAR2(20) := 'ACTION';
  cv_tkn_api_errmsg      CONSTANT VARCHAR2(20) := 'API_ERR_MSG';
  cv_tkn_task_nm         CONSTANT VARCHAR2(20) := 'TASK_NAME';
  cv_tkn_slip_num        CONSTANT VARCHAR2(20) := 'SLIP_NUM';
  cv_tkn_slip_branch_num CONSTANT VARCHAR2(20) := 'SLIP_BRANCH_NUM';
  cv_tkn_line_num        CONSTANT VARCHAR2(20) := 'LINE_NUM';
  cv_tkn_account_id      CONSTANT VARCHAR2(20) := 'ACCOUNT_ID';
  cv_tkn_lookup_type_nm  CONSTANT VARCHAR2(20) := 'LOOKUP_TYPE_NAME';
  --
  -- トークン値
  cv_tkn_val_cust_info       CONSTANT VARCHAR2(30) := '顧客情報';
  cv_tkn_val_wk_data_tbl     CONSTANT VARCHAR2(30) := '作業データテーブル';
  cv_tkn_val_selection       CONSTANT VARCHAR2(30) := '抽出';
  cv_tkn_val_lock            CONSTANT VARCHAR2(30) := 'ロック';
  cv_tkn_val_update          CONSTANT VARCHAR2(30) := '更新';
  cv_tkn_val_cust_sts        CONSTANT VARCHAR2(30) := '顧客ステータス';
  cv_tkn_val_upd_suspnd_sts  CONSTANT VARCHAR2(30) := '更新（顧客→休止）';
  cv_tkn_val_upd_cust_sts    CONSTANT VARCHAR2(30) := '更新（承認済→顧客）';
  cv_tkn_val_party_mst       CONSTANT VARCHAR2(30) := 'パーティマスタ';
  cv_tkn_val_party_id        CONSTANT VARCHAR2(30) := 'パーティID';
  cv_tkn_val_cust_addon_mst  CONSTANT VARCHAR2(30) := '顧客アドオンマスタ';
  cv_tkn_val_cust_cd         CONSTANT VARCHAR2(30) := '顧客コード';
  cv_tkn_val_lkup_type       CONSTANT VARCHAR2(30) := '参照タイプ';
  --
  -- 処理区分
  cv_proc_kbn1               CONSTANT VARCHAR2(1) := '1';
  cv_proc_kbn2               CONSTANT VARCHAR2(1) := '2';
  -- 業態（小分類）
  cv_business_low_type24               CONSTANT VARCHAR2(2) := '24';
  cv_business_low_type25               CONSTANT VARCHAR2(2) := '25';
  cv_business_low_type27               CONSTANT VARCHAR2(2) := '27';
  --
  -- その他
  cv_true                    CONSTANT VARCHAR2(10) := 'TRUE';    -- 共通関数戻り値判定用
  cv_false                   CONSTANT VARCHAR2(10) := 'FALSE';   -- 共通関数戻り値判定用
  cv_suspend_proc_end        CONSTANT VARCHAR2(1) := '2';        -- 休止処理済フラグ（処理済）
  cv_suspend_proc_unprc      CONSTANT VARCHAR2(1) := '1';        -- 休止処理済フラグ（未処理）
  cv_job_kbn_withdraw        CONSTANT VARCHAR2(1) := '5';        -- 作業区分（引揚）
  cv_completion_kbn_cmplt    CONSTANT VARCHAR2(1) := '1';        -- 完了区分（完了）
  cv_install2_proc_end       CONSTANT VARCHAR2(1) := 'Y';        -- 物件２処理済フラグ（処理済）
  cv_withdrawal_type_nrml    CONSTANT VARCHAR2(1) := '1';        -- 引揚区分（引揚）
  cv_category_kbn_withdraw   CONSTANT VARCHAR2(2) := '50';       -- カテゴリ区分（引揚）
  cv_case_arc_left           CONSTANT VARCHAR2(1)  := '(';
  cv_case_arc_right          CONSTANT VARCHAR2(1)  := ')';
  cv_msg_equal               CONSTANT VARCHAR2(1)  := '=';
/*20090507_mori_T1_0439 START*/
  cv_instance_type_vd        CONSTANT VARCHAR2(1) := '1';        -- インスタンスステータスタイプ（自販機）
  cv_cust_upd_y              CONSTANT VARCHAR2(1) := 'Y';        -- 顧客情報更新フラグ（更新する）
  cv_cust_upd_n              CONSTANT VARCHAR2(1) := 'N';        -- 顧客情報更新フラグ（更新しない）
/*20090507_mori_T1_0439 END*/
  --
  -- LOG用メッセージ
  cv_log_msg1          CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_log_msg2          CONSTANT VARCHAR2(200) := 'od_process_date = ';
  cv_log_msg3          CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_log_msg4          CONSTANT VARCHAR2(200) := 'lv_cust_sts_suspended = ';
  cv_log_msg5          CONSTANT VARCHAR2(200) := 'lv_cust_sts_approved  = ';
  cv_log_msg6          CONSTANT VARCHAR2(200) := 'lv_cust_sts_customer  = ';
  cv_log_msg7          CONSTANT VARCHAR2(200) := 'lv_req_sts_approved   = ';
  cv_log_msg8          CONSTANT VARCHAR2(200) := 'lv_org_id = ' ;
  cv_log_msg9          CONSTANT VARCHAR2(200) := '<< 顧客ステータス抽出処理 >>';
  cv_log_msg10         CONSTANT VARCHAR2(200) := '<< ロールバックしました >>';
  cv_log_msg_copn1     CONSTANT VARCHAR2(200) := '<< 作業データ抽出カーソルをオープンしました >>';
  cv_log_msg_copn2     CONSTANT VARCHAR2(200) := '<< 顧客情報抽出カーソルをオープンしました >>';
  cv_log_msg_ccls1     CONSTANT VARCHAR2(200) := '<< 作業データ抽出カーソルをクローズしました >>';
  cv_log_msg_ccls2     CONSTANT VARCHAR2(200) := '<< 顧客情報抽出カーソルをクローズしました >>';
  cv_log_msg_ccls1_ex  CONSTANT VARCHAR2(200) := '<< 例外処理内で作業データ抽出カーソルをクローズしました >>';
  cv_log_msg_ccls2_ex  CONSTANT VARCHAR2(200) := '<< 例外処理内で顧客情報抽出カーソルをクローズしました >>';
  cv_log_msg_err1      CONSTANT VARCHAR2(200) := 'process_warn_expt';
  cv_log_msg_err2      CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_log_msg_err3      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_log_msg_err4      CONSTANT VARCHAR2(200) := 'others例外';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- 承認済→顧客処理用
  gn_target_cnt2    NUMBER;    -- 対象件数
  gn_normal_cnt2    NUMBER;    -- 正常件数
  gn_error_cnt2     NUMBER;    -- エラー件数
  gn_warn_cnt2      NUMBER;    -- スキップ件数
/*20090507_mori_T1_0439 START*/
  gv_cust_upd_flg   VARCHAR2(1);  -- 顧客情報更新フラグ
/*20090507_mori_T1_0439 END*/
  --
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 作業データ格納要レコード型定義
  TYPE g_work_data_rtype IS RECORD(
      slip_no           xxcso_in_work_data.slip_no%TYPE          -- 伝票No
    , slip_branch_no    xxcso_in_work_data.slip_branch_no%TYPE   -- 伝票枝番
    , line_number       xxcso_in_work_data.line_number%TYPE      -- 行番号
    , install_code      xxcso_in_work_data.install_code2%TYPE    -- 物件コード
    , account_number    xxcso_in_work_data.account_number2%TYPE  -- 顧客コード
    , actual_work_date  xxcso_in_work_data.actual_work_date%TYPE -- 実作業日
  /*20090507_mori_T1_0439 START*/
    , instance_type_code  csi_item_instances.instance_type_code%TYPE -- インスタンスタイプコード
  /*20090507_mori_T1_0439 END*/
  /* 2009/12/03 T.maruyama E_本稼動_00270対応 START */
    , seq_no            xxcso_in_work_data.seq_no%TYPE           -- シーケンス番号
  /* 2009/12/03 T.maruyama E_本稼動_00270対応 END */
  );
  --
  -- 顧客情報格納用レコード型定義
  TYPE g_cust_rtype IS RECORD(
      object_version_number    hz_parties.object_version_number%TYPE  -- オブジェクトバージョン番号
    , party_id                 hz_parties.party_id%TYPE               -- パーティID
    , account_number           hz_cust_accounts.account_number%TYPE   -- 顧客コード
    , cust_account_id          hz_cust_accounts.cust_account_id%TYPE  -- アカウントID
    , cnvs_date                xxcso_cust_accounts_v.cnvs_date%TYPE   -- 顧客獲得日
    , party_name               hz_parties.party_name%TYPE             -- 顧客名
    , duns_number_c            hz_parties.duns_number_c%TYPE          -- DUNS番号（顧客ステータス）
  );
  -- ===============================
  -- ユーザー定義グローバル例外
  -- ===============================
  global_lock_expt        EXCEPTION;    -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  --
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
      od_process_date  OUT        DATE      -- 業務処理日付
    , ov_errbuf        OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    , ov_errmsg        OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100)  := 'init';    -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
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
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
--
    -- =====================
    -- 入力パラメータなしメッセージ出力
    -- =====================
    lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application => cv_app_name_xxccp    -- アプリケーション短縮名
                   , iv_name        => cv_tkn_num_xxccp_01  -- メッセージコード
                 );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => lv_errmsg
    );
    --
    -- =====================
    -- 業務処理日付取得処理
    -- =====================
    od_process_date := xxccp_common_pkg2.get_process_date;
    --
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg1 || CHR(10) ||
                 cv_log_msg2 || TO_CHAR( od_process_date, 'YYYY/MM/DD HH24:MI:SS' ) || CHR(10) ||
                 ''
    );
    --
    -- 業務処理日付取得に失敗した場合
    IF ( od_process_date IS NULL ) THEN
      -- 空行の挿入
      fnd_file.put_line(
          which => FND_FILE.OUTPUT
        , buff  => ''
      );
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application => cv_app_name       -- アプリケーション短縮名
                     , iv_name        => cv_tkn_number_01  -- メッセージコード
                   );
      lv_errbuf := lv_errmsg;
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
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
      ov_cust_sts_suspended  OUT NOCOPY VARCHAR2  -- 顧客ステータス（休止）
    , ov_cust_sts_approved   OUT NOCOPY VARCHAR2  -- 顧客ステータス（承認済）
    , ov_cust_sts_customer   OUT NOCOPY VARCHAR2  -- 顧客ステータス（顧客）
    , ov_req_sts_approved    OUT NOCOPY VARCHAR2  -- 発注依頼ステータスコード（承認済）
    , ov_org_id              OUT NOCOPY VARCHAR2  -- オルグID
    , ov_errbuf              OUT NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    , ov_retcode             OUT NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    , ov_errmsg              OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'get_profile_info';  -- プログラム名
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
    -- XXCSO:顧客ステータス（休止）
    cv_cust_sts_suspended    CONSTANT VARCHAR2(30) := 'XXCSO1_CUST_STATUS_SUSPENDED';
    -- XXCSO:顧客ステータス（承認済）
    cv_cust_sts_approved     CONSTANT VARCHAR2(30) := 'XXCSO1_CUST_STATUS_APPROVED';
    -- XXCSO:顧客ステータス（顧客）
    cv_cust_sts_customer     CONSTANT VARCHAR2(30) := 'XXCSO1_CUST_STATUS_CUSTOMER';
    -- XXCSO:発注依頼ステータスコード（承認済）
    cv_req_sts_approved      CONSTANT VARCHAR2(30) := 'XXCSO1_PO_REQ_STATUS_CD_APRVD';
    -- MO:営業単位
    cv_org_id                CONSTANT VARCHAR2(30) := 'ORG_ID';
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値格納用
    lv_cust_sts_suspended    VARCHAR2(2000);  -- 顧客ステータス（休止）
    lv_cust_sts_approved     VARCHAR2(2000);  -- 顧客ステータス（承認済）
    lv_cust_sts_customer     VARCHAR2(2000);  -- 顧客ステータス（顧客）
    lv_req_sts_approved      VARCHAR2(2000);  -- 発注依頼ステータスコード（承認済）
    lv_org_id                VARCHAR2(2000);  -- オルグID
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value             VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg_fnm               VARCHAR2(5000);
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
    -- 顧客ステータス（休止）
    FND_PROFILE.GET(
        name => cv_cust_sts_suspended
      , val  => lv_cust_sts_suspended
    );
    --
    -- 顧客ステータス（承認済）
    FND_PROFILE.GET(
        name => cv_cust_sts_approved
      , val  => lv_cust_sts_approved
    );
    --
    -- 顧客ステータス（顧客）
    FND_PROFILE.GET(
        name => cv_cust_sts_customer
      , val  => lv_cust_sts_customer
    );
    --
    -- 発注依頼ステータスコード（承認済）
    FND_PROFILE.GET(
        name => cv_req_sts_approved
      , val  => lv_req_sts_approved
    );
    --
    -- オルグID
    FND_PROFILE.GET(
        name => cv_org_id
      , val  => lv_org_id
    );
--
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg3 || CHR(10) ||
                 cv_log_msg4 || lv_cust_sts_suspended || CHR(10) ||
                 cv_log_msg5 || lv_cust_sts_approved  || CHR(10) ||
                 cv_log_msg6 || lv_cust_sts_customer  || CHR(10) ||
                 cv_log_msg7 || lv_req_sts_approved   || CHR(10) ||
                 cv_log_msg8 || lv_org_id             || CHR(10) ||
                 ''
    );
--
    -- プロファイル値取得に失敗した場合
    -- 顧客ステータス（休止）取得失敗時
    IF ( lv_cust_sts_suspended IS NULL ) THEN
      lv_tkn_value := cv_cust_sts_suspended;
      --
    -- 顧客ステータス（承認済）取得失敗時
    ELSIF ( lv_cust_sts_approved IS NULL ) THEN
      lv_tkn_value := cv_cust_sts_approved;
      --
    -- 顧客ステータス（顧客）取得失敗時
    ELSIF ( lv_cust_sts_customer IS NULL ) THEN
      lv_tkn_value := cv_cust_sts_customer;
      --
    -- 発注依頼ステータスコード（承認済）取得失敗時
    ELSIF ( lv_req_sts_approved IS NULL ) THEN
      lv_tkn_value := cv_req_sts_approved;
      --
    -- オルグID取得失敗時
    ELSIF ( lv_org_id IS NULL ) THEN
      lv_tkn_value := cv_org_id;
      --
    END IF;
    -- エラーメッセージ取得
    IF ( lv_tkn_value IS NOT NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name       -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_02  -- メッセージコード
                     , iv_token_name1  => cv_tkn_prof_nm    -- トークンコード1
                     , iv_token_value1 => lv_tkn_value      -- トークン値1
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
      --
    END IF;
--
    -- 取得したプロファイル値をOUTパラメータに設定
    ov_cust_sts_suspended := lv_cust_sts_suspended;  -- 顧客ステータス（休止）
    ov_cust_sts_approved  := lv_cust_sts_approved;   -- 顧客ステータス（承認済）
    ov_cust_sts_customer  := lv_cust_sts_customer;   -- 顧客ステータス（顧客）
    ov_req_sts_approved   := lv_req_sts_approved;    -- 発注依頼ステータスコード（承認済）
    ov_org_id             := lv_org_id;              -- オルグID
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END get_profile_info;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_status
   * Description      : 顧客ステータス抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_cust_status(
      it_cust_status_nm  IN         fnd_lookup_values_vl.meaning%TYPE  -- 顧客ステータス名
    , id_process_date    IN         DATE                               -- 業務処理日付
    , ot_cust_status_cd  OUT NOCOPY hz_parties.duns_number_c%TYPE      -- 顧客ステータス
    , ov_errbuf          OUT NOCOPY VARCHAR2                           -- エラー・メッセージ            --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2                           -- リターン・コード              --# 固定 #
    , ov_errmsg          OUT NOCOPY VARCHAR2                           -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_status';  -- プログラム名
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
    cv_lkup_tp_cust_status  CONSTANT VARCHAR2(30) := 'XXCMM_CUST_KOKYAKU_STATUS';
    cv_enabled_flag_yes     CONSTANT VARCHAR2(1)  := 'Y';
    --
    -- *** ローカル変数 ***
    --
    -- *** ローカル例外 ***
    sql_expt    EXCEPTION;
    --
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
    -- 顧客ステータス抽出
    -- ====================================
    BEGIN
      SELECT flvl.lookup_code  lookup_code    -- コード（顧客ステータス）
      INTO   ot_cust_status_cd                -- コード（顧客ステータス）
      FROM   fnd_lookup_values_vl  flvl       -- クイックコードビュー
      WHERE  flvl.lookup_type  = cv_lkup_tp_cust_status    -- タイプ
      AND    flvl.meaning      = it_cust_status_nm         -- 内容
      AND    TRUNC( id_process_date )
               BETWEEN TRUNC( NVL( flvl.start_date_active, id_process_date ) )  -- 有効開始日
               AND     TRUNC( NVL( flvl.end_date_active, id_process_date ) )    -- 有効終了日
      AND    flvl.enabled_flag = cv_enabled_flag_yes                            -- 使用可能フラグ
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                                  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_22                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm                               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_lkup_type                         -- トークン値1
                       , iv_token_name2  => cv_tkn_lookup_type_nm                        -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_cust_sts || cv_case_arc_left
                                              || it_cust_status_nm || cv_case_arc_right  -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                                  -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_23                             -- メッセージコード
                       , iv_token_name1  => cv_tkn_task_nm                               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_lkup_type                         -- トークン値1
                       , iv_token_name2  => cv_tkn_lookup_type_nm                        -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_cust_sts || cv_case_arc_left
                                              || it_cust_status_nm || cv_case_arc_right  -- トークン値2
                       , iv_token_name3  => cv_tkn_errmsg                                -- トークンコード3
                       , iv_token_value3 => SQLERRM                                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END get_cust_status;
--
  /**********************************************************************************
   * Procedure Name   : chk_ib_info
   * Description      : 物件存在チェック処理(A-5)
   ***********************************************************************************/
  PROCEDURE chk_ib_info(
      i_work_data_rec  IN         g_work_data_rtype    -- 作業データ情報
    , ov_errbuf        OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    , ov_errmsg        OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'chk_ib_info';  -- プログラム名
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
    ln_cnt      NUMBER;
    --
    -- *** ローカル例外 ***
    sql_expt    EXCEPTION;
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
      SELECT COUNT(0)  cnt    -- 件数
      INTO  ln_cnt            -- 件数
      FROM  csi_item_instances  cii    -- インストールベースマスタ（物件マスタ）
      WHERE cii.external_reference = i_work_data_rec.install_code  -- 外部参照（物件コード）
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_05                -- メッセージコード
                       , iv_token_name1  => cv_tkn_slip_num                 -- トークンコード1
                       , iv_token_value1 => i_work_data_rec.slip_no         -- トークン値1
                       , iv_token_name2  => cv_tkn_slip_branch_num          -- トークンコード2
                       , iv_token_value2 => i_work_data_rec.slip_branch_no  -- トークン値2
                       , iv_token_name3  => cv_tkn_line_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.line_number     -- トークン値3
                       , iv_token_name4  => cv_tkn_bukken                   -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.install_code    -- トークン値4
                       , iv_token_name5  => cv_tkn_errmsg                   -- トークンコード5
                       , iv_token_value5 => SQLERRM                         -- トークン値5
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
    IF ln_cnt = 0 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                     -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_04                -- メッセージコード
                     , iv_token_name1  => cv_tkn_bukken                   -- トークンコード1
                     , iv_token_value1 => i_work_data_rec.install_code    -- トークン値1
                     , iv_token_name2  => cv_tkn_slip_num                 -- トークンコード2
                     , iv_token_value2 => i_work_data_rec.slip_no         -- トークン値2
                     , iv_token_name3  => cv_tkn_slip_branch_num          -- トークンコード3
                     , iv_token_value3 => i_work_data_rec.slip_branch_no  -- トークン値3
                     , iv_token_name4  => cv_tkn_line_num                 -- トークンコード4
                     , iv_token_value4 => i_work_data_rec.line_number     -- トークン値4
                   );
      lv_errbuf := lv_errmsg;
      RAISE sql_expt;
      --
    END IF;
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END chk_ib_info;
--
  /**********************************************************************************
   * Procedure Name   : get_cust_info
   * Description      : 顧客情報抽出処理(A-6)
   ***********************************************************************************/
  PROCEDURE get_cust_info(
      i_work_data_rec  IN         g_work_data_rtype    -- 作業データ情報
    , iv_cust_status   IN         VARCHAR2             -- 顧客ステータス
    , o_cust_rec       OUT NOCOPY g_cust_rtype         -- 顧客情報
    , ov_errbuf        OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    , ov_errmsg        OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_info';  -- プログラム名
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
    --
    -- *** ローカル例外 ***
    sql_expt    EXCEPTION;
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
      SELECT hca.cust_account_id        cust_account_id        -- アカウントID
           , hca.account_number         account_number         -- 顧客コード
           , hpa.object_version_number  object_version_number  -- オブジェクトバージョン番号
           , hpa.party_id               party_id               -- パーティID
           , hpa.party_name             party_name             -- 顧客名
           , hpa.duns_number_c          duns_number_c          -- DUNS番号（顧客ステータス）
      INTO  o_cust_rec.cust_account_id        -- アカウントID
          , o_cust_rec.account_number         -- 顧客コード
          , o_cust_rec.object_version_number  -- オブジェクトバージョン番号
          , o_cust_rec.party_id               -- パーティID
          , o_cust_rec.party_name             -- 顧客名
          , o_cust_rec.duns_number_c          -- DUNS番号（顧客ステータス）
      FROM  hz_cust_accounts  hca    -- 顧客マスタ
          , hz_parties               hpa    -- パーティマスタ
      WHERE hca.party_id       = hpa.party_id                    -- パーティID
      AND   hca.account_number = i_work_data_rec.account_number  -- 顧客コード
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_21                -- メッセージコード
                       , iv_token_name1  => cv_tkn_slip_num                 -- トークンコード1
                       , iv_token_value1 => i_work_data_rec.slip_no         -- トークン値1
                       , iv_token_name2  => cv_tkn_slip_branch_num          -- トークンコード2
                       , iv_token_value2 => i_work_data_rec.slip_branch_no  -- トークン値2
                       , iv_token_name3  => cv_tkn_line_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.line_number     -- トークン値3
                       , iv_token_name4  => cv_tkn_kokyaku                  -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.account_number  -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
        --
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_06                -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                    -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_cust_info            -- トークン値1
                       , iv_token_name2  => cv_tkn_action                   -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_selection            -- トークン値2
                       , iv_token_name3  => cv_tkn_slip_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- トークン値3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- トークン値4
                       , iv_token_name5  => cv_tkn_line_num                 -- トークンコード5
                       , iv_token_value5 => i_work_data_rec.line_number     -- トークン値5
                       , iv_token_name6  => cv_tkn_kokyaku                  -- トークンコード6
                       , iv_token_value6 => i_work_data_rec.account_number  -- トークン値6
                       , iv_token_name7  => cv_tkn_errmsg                   -- トークンコード7
                       , iv_token_value7 => SQLERRM                         -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
    -- 顧客ステータスのチェック
    /* 2009.07.23 K.Satomura 0000671対応 START */
    --IF o_cust_rec.duns_number_c <> iv_cust_status THEN
    --  lv_errmsg := xxccp_common_pkg.get_msg(
    --                   iv_application  => cv_app_name                     -- アプリケーション短縮名
    --                 , iv_name         => cv_tkn_number_11                -- メッセージコード
    --                 , iv_token_name1  => cv_tkn_slip_num                 -- トークンコード1
    --                 , iv_token_value1 => i_work_data_rec.slip_no         -- トークン値1
    --                 , iv_token_name2  => cv_tkn_slip_branch_num          -- トークンコード2
    --                 , iv_token_value2 => i_work_data_rec.slip_branch_no  -- トークン値2
    --                 , iv_token_name3  => cv_tkn_line_num                 -- トークンコード3
    --                 , iv_token_value3 => i_work_data_rec.line_number     -- トークン値3
    --                 , iv_token_name4  => cv_tkn_kokyaku                  -- トークンコード4
    --                 , iv_token_value4 => i_work_data_rec.account_number  -- トークン値4
    --               );
    --  lv_errbuf := lv_errmsg;
    --  RAISE sql_expt;
    --END IF;
    /* 2009.07.23 K.Satomura 0000671対応 END */
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END get_cust_info;
--
  /**********************************************************************************
   * Procedure Name   : chk_cust_ib
   * Description      : 設置先顧客・物件チェック処理(A-7)
   ***********************************************************************************/
  PROCEDURE chk_cust_ib(
      i_work_data_rec  IN         g_work_data_rtype    -- 作業データ情報
    , in_acnt_id       IN         NUMBER               -- アカウントID
    , ov_errbuf        OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    , ov_retcode       OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    , ov_errmsg        OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'chk_cust_ib';  -- プログラム名
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
    ln_cnt      NUMBER;
    --
    -- *** ローカル例外 ***
    sql_expt    EXCEPTION;
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
      SELECT COUNT(0)  cnt  -- 件数
      INTO  ln_cnt          -- 件数
      FROM  csi_item_instances  cii  -- インストールベースマスタ（物件マスタ）
      WHERE cii.owner_party_account_id  =  in_acnt_id                    -- 所有者アカウントID（アカウントID）
    /*20090507_mori_T1_0439 START*/
--      AND   cii.external_reference      <> i_work_data_rec.install_code  -- 外部参照（物件コード）
    /*20090507_mori_T1_0439 END*/
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_09                -- メッセージコード
                       , iv_token_name1  => cv_tkn_slip_num                 -- トークンコード1
                       , iv_token_value1 => i_work_data_rec.slip_no         -- トークン値1
                       , iv_token_name2  => cv_tkn_slip_branch_num          -- トークンコード2
                       , iv_token_value2 => i_work_data_rec.slip_branch_no  -- トークン値2
                       , iv_token_name3  => cv_tkn_line_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.line_number     -- トークン値3
                       , iv_token_name4  => cv_tkn_account_id               -- トークンコード4
                       , iv_token_value4 => in_acnt_id                      -- トークン値4
                       , iv_token_name5  => cv_tkn_errmsg                   -- トークンコード5
                       , iv_token_value5 => SQLERRM                         -- トークン値5
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
    -- 抽出件数が0より大きい場合
    IF ln_cnt > 0 THEN
    /*20090507_mori_T1_0439 START*/
      gv_cust_upd_flg := cv_cust_upd_n;
    /*20090507_mori_T1_0439 END*/
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                       -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_08                  -- メッセージコード
                     , iv_token_name1  => cv_tkn_kokyaku                    -- トークンコード1
                     , iv_token_value1 => i_work_data_rec.account_number    -- トークン値1
                     , iv_token_name2  => cv_tkn_bukken                     -- トークンコード2
                     , iv_token_value2 => i_work_data_rec.install_code      -- トークン値2
                     , iv_token_name3  => cv_tkn_slip_num                   -- トークンコード3
                     , iv_token_value3 => i_work_data_rec.slip_no           -- トークン値3
                     , iv_token_name4  => cv_tkn_slip_branch_num            -- トークンコード4
                     , iv_token_value4 => i_work_data_rec.slip_branch_no    -- トークン値4
                     , iv_token_name5  => cv_tkn_line_num                   -- トークンコード5
                     , iv_token_value5 => i_work_data_rec.line_number       -- トークン値5
                   );
      lv_errbuf := lv_errmsg;
        --
    /*20090507_mori_T1_0439 START*/
      lv_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      gv_cust_upd_flg := cv_cust_upd_n;
        -- 警告内容をメッセージ、ログへ出力
        fnd_file.put_line(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg    -- ユーザー・エラーメッセージ
        );
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => lv_errbuf    -- エラーメッセージ
        );
--      RAISE sql_expt;
    /*20090507_mori_T1_0439 END*/
    END IF;
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END chk_cust_ib;
--
  /**********************************************************************************
   * Procedure Name   : update_cust_status
   * Description      : 顧客ステータス更新処理(A-9)
   ***********************************************************************************/
  PROCEDURE update_cust_status(
      iv_proc_kbn       IN         VARCHAR2             -- 処理区分
    , i_work_data_rec   IN         g_work_data_rtype    -- 作業データ情報
    , i_cust_rec        IN         g_cust_rtype         -- 顧客情報
    , iv_duns_number_c  IN         VARCHAR2             -- DUNS番号（顧客ステータス）
    , ov_errbuf         OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    , ov_retcode        OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    , ov_errmsg         OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_cust_status';  -- プログラム名
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
    cv_encoded_false    CONSTANT VARCHAR2(1) := 'F';
    --
    -- *** ローカル変数 ***
    lv_init_msg_list     VARCHAR2(2000);    -- メッセージリスト
    ln_obj_ver_num       NUMBER;            -- オブジェクトバージョン番号
    --
    -- API入出力レコード値格納用
    l_party_rec           hz_party_v2pub.party_rec_type;
    l_organization_rec    hz_party_v2pub.organization_rec_type;
    --
    -- 戻り値格納用
    ln_profile_id       NUMBER;          -- プロファイルID
    lv_return_status    VARCHAR2(10);    -- 戻り値ステータス
    ln_msg_count        NUMBER;
    lv_msg_data         VARCHAR2(5000);
    ln_io_msg_count     NUMBER;
    lv_io_msg_data      VARCHAR2(5000);
    --
    -- *** ローカル例外 ***
    update_error_expt    EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- メッセージスタックの初期化
    FND_MSG_PUB.INITIALIZE;
    --
    -- オブジェクトバージョン番号の設定
    ln_obj_ver_num := i_cust_rec.object_version_number;
    --
    -- パーティレコードの作成
    l_party_rec.party_id := i_cust_rec.party_id;                      -- パーティID
    --
    -- 顧客情報レコードの作成
    l_organization_rec.organization_name := i_cust_rec.party_name;    -- 顧客名
    l_organization_rec.duns_number_c     := iv_duns_number_c;         -- DUNS番号（顧客ステータス）
    l_organization_rec.party_rec         := l_party_rec;              -- パーティレコード
    --
    -- 標準APIよりパーティマスタを更新する
    HZ_PARTY_V2PUB.UPDATE_ORGANIZATION(
        p_init_msg_list               => lv_init_msg_list
      , p_organization_rec            => l_organization_rec
      , p_party_object_version_number => ln_obj_ver_num
      , x_profile_id                  => ln_profile_id
      , x_return_status               => lv_return_status
      , x_msg_count                   => ln_msg_count
      , x_msg_data                    => lv_msg_data
    );
    --
    IF ( lv_return_status <> FND_API.G_RET_STS_SUCCESS ) THEN
      RAISE update_error_expt;
      --
    END IF;
    --
    -- ========================================
    -- 正常終了の場合
    -- ========================================
    IF iv_proc_kbn = cv_proc_kbn1 THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                     -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_12                -- メッセージコード
                     , iv_token_name1  => cv_tkn_table                    -- トークンコード1
                     , iv_token_value1 => cv_tkn_val_cust_sts             -- トークン値1
                     , iv_token_name2  => cv_tkn_action                   -- トークンコード2
                     , iv_token_value2 => cv_tkn_val_upd_suspnd_sts       -- トークン値2
                     , iv_token_name3  => cv_tkn_slip_num                 -- トークンコード3
                     , iv_token_value3 => i_work_data_rec.slip_no         -- トークン値3
                     , iv_token_name4  => cv_tkn_slip_branch_num          -- トークンコード4
                     , iv_token_value4 => i_work_data_rec.slip_branch_no  -- トークン値4
                     , iv_token_name5  => cv_tkn_line_num                 -- トークンコード5
                     , iv_token_value5 => i_work_data_rec.line_number     -- トークン値5
                     , iv_token_name6  => cv_tkn_bukken                   -- トークンコード6
                     , iv_token_value6 => i_work_data_rec.install_code    -- トークン値6
                     , iv_token_name7  => cv_tkn_kokyaku                  -- トークンコード7
                     , iv_token_value7 => i_work_data_rec.account_number  -- トークン値7
                   );
    ELSE
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                -- アプリケーション短縮名
                     , iv_name         => cv_tkn_number_14           -- メッセージコード
                     , iv_token_name1  => cv_tkn_table               -- トークンコード1
                     , iv_token_value1 => cv_tkn_val_cust_sts        -- トークン値1
                     , iv_token_name2  => cv_tkn_action              -- トークンコード2
                     , iv_token_value2 => cv_tkn_val_upd_cust_sts    -- トークン値2
                     , iv_token_name3  => cv_tkn_kokyaku             -- トークンコード3
                     , iv_token_value3 => i_cust_rec.account_number  -- トークン値3
                   );
    END IF;
    lv_errbuf := lv_errmsg;
--
    -- 顧客ステータス更新成功メッセージをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => lv_errmsg || CHR(10) ||
                 ''
    );
--
  EXCEPTION
    -- *** APIエラーハンドラ ***
    WHEN update_error_expt THEN
      --
      IF ( FND_MSG_PUB.Count_Msg > 0 ) THEN
        FOR i IN 1..FND_MSG_PUB.COUNT_MSG LOOP
          FND_MSG_PUB.Get(
              p_msg_index     => i
            , p_encoded       => cv_encoded_false
            , p_data          => lv_io_msg_data
            , p_msg_index_out => ln_io_msg_count
          );
          lv_msg_data := lv_msg_data || lv_io_msg_data;
        END LOOP;
      END IF;
      IF iv_proc_kbn = cv_proc_kbn1 THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_10                -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                    -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_cust_sts             -- トークン値1
                       , iv_token_name2  => cv_tkn_action                   -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_upd_suspnd_sts       -- トークン値2
                       , iv_token_name3  => cv_tkn_slip_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- トークン値3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- トークン値4
                       , iv_token_name5  => cv_tkn_line_num                 -- トークンコード5
                       , iv_token_value5 => i_work_data_rec.line_number     -- トークン値5
                       , iv_token_name6  => cv_tkn_bukken                   -- トークンコード6
                       , iv_token_value6 => i_work_data_rec.install_code    -- トークン値6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- トークンコード7
                       , iv_token_value7 => i_work_data_rec.account_number  -- トークン値7
                       , iv_token_name8  => cv_tkn_api_errmsg               -- トークンコード8
                       , iv_token_value8 => lv_msg_data                     -- トークン値8
                     );
      ELSE
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_15           -- メッセージコード
                       , iv_token_name1  => cv_tkn_table               -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_cust_sts        -- トークン値1
                       , iv_token_name2  => cv_tkn_action              -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_upd_cust_sts    -- トークン値2
                       , iv_token_name3  => cv_tkn_kokyaku             -- トークンコード3
                       , iv_token_value3 => i_cust_rec.account_number  -- トークン値3
                       , iv_token_name4  => cv_tkn_api_errmsg          -- トークンコード4
                       , iv_token_value4 => lv_msg_data                -- トークン値4
                     );
      END IF;
      --
      lv_errbuf := lv_errmsg;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END update_cust_status;
--
  /**********************************************************************************
   * Procedure Name   : work_data_lock
   * Description      : 作業データロック処理(A-11)
   ***********************************************************************************/
  PROCEDURE work_data_lock(
      i_work_data_rec    IN         g_work_data_rtype    -- 作業データ情報
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    , ov_errmsg          OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'work_data_lock';  -- プログラム名
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
    lt_slip_no    xxcso_in_work_data.slip_no%TYPE;
    --
    -- *** ローカル例外 ***
    sql_expt     EXCEPTION;
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
      SELECT xiwd.slip_no  -- 伝票No
      INTO  lt_slip_no     -- 伝票No
      FROM  xxcso_in_work_data  xiwd  -- 作業データテーブル
      WHERE xiwd.slip_no        = i_work_data_rec.slip_no         -- 伝票No
      AND   xiwd.slip_branch_no = i_work_data_rec.slip_branch_no  -- 伝票枝番
      AND   xiwd.line_number    = i_work_data_rec.line_number     -- 行番号
      /* 2009/12/03 T.maruyama E_本稼動_00270対応 START */
      AND   xiwd.seq_no         = i_work_data_rec.seq_no          -- シーケンス番号
      /* 2009/12/03 T.maruyama E_本稼動_00270対応 END */
      FOR UPDATE NOWAIT
      ;
      --
    EXCEPTION
      -- *** ロックに失敗した場合 ***
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_16                -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                    -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_wk_data_tbl          -- トークン値1
                       , iv_token_name2  => cv_tkn_action                   -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_lock                 -- トークン値2
                       , iv_token_name3  => cv_tkn_slip_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- トークン値3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- トークン値4
                       , iv_token_name5  => cv_tkn_line_num                 -- トークンコード5
                       , iv_token_value5 => i_work_data_rec.line_number     -- トークン値5
                       , iv_token_name6  => cv_tkn_bukken                   -- トークンコード6
                       , iv_token_value6 => i_work_data_rec.install_code    -- トークン値6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- トークンコード7
                       , iv_token_value7 => i_work_data_rec.account_number  -- トークン値7
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
        --
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_17                -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                    -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_wk_data_tbl          -- トークン値1
                       , iv_token_name2  => cv_tkn_action                   -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_selection            -- トークン値2
                       , iv_token_name3  => cv_tkn_slip_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- トークン値3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- トークン値4
                       , iv_token_name5  => cv_tkn_line_num                 -- トークンコード5
                       , iv_token_value5 => i_work_data_rec.line_number     -- トークン値5
                       , iv_token_name6  => cv_tkn_bukken                   -- トークンコード6
                       , iv_token_value6 => i_work_data_rec.install_code    -- トークン値6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- トークンコード7
                       , iv_token_value7 => i_work_data_rec.account_number  -- トークン値7
                       , iv_token_name8  => cv_tkn_errmsg                   -- トークンコード8
                       , iv_token_value8 => SQLERRM                         -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END work_data_lock;
--
  /**********************************************************************************
   * Procedure Name   : update_work_data
   * Description      : 作業データ更新処理(A-12)
   ***********************************************************************************/
  PROCEDURE update_work_data(
      i_work_data_rec    IN         g_work_data_rtype    -- 作業データ情報
    , ov_errbuf          OUT NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    , ov_retcode         OUT NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    , ov_errmsg          OUT NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_work_data';  -- プログラム名
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
    --
    -- *** ローカル例外 ***
    sql_expt     EXCEPTION;
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
      UPDATE xxcso_in_work_data  xiwd  -- 作業データテーブル
      SET   xiwd.suspend_processed_flag = cv_suspend_proc_end          -- 休止処理済フラグ
          , xiwd.last_updated_by        = cn_last_updated_by           -- 最終更新者
          , xiwd.last_update_date       = cd_last_update_date          -- 最終更新日
          , xiwd.last_update_login      = cn_last_update_login         -- 最終更新ログイン
          , xiwd.request_id             = cn_request_id                -- 要求ID
          , xiwd.program_application_id = cn_program_application_id    -- コンカレント・プログラム・アプリケーションID
          , xiwd.program_id             = cn_program_id                -- コンカレント・プログラムID
          , xiwd.program_update_date    = cd_program_update_date       -- プログラム更新日
      WHERE xiwd.slip_no        = i_work_data_rec.slip_no         -- 伝票No
      AND   xiwd.slip_branch_no = i_work_data_rec.slip_branch_no  -- 伝票枝番
      AND   xiwd.line_number    = i_work_data_rec.line_number     -- 行番号
      /* 2009/12/03 T.maruyama E_本稼動_00270対応 START */
      AND   xiwd.seq_no         = i_work_data_rec.seq_no          -- シーケンス番号
      /* 2009/12/03 T.maruyama E_本稼動_00270対応 END */
      ;
      --
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name                     -- アプリケーション短縮名
                       , iv_name         => cv_tkn_number_17                -- メッセージコード
                       , iv_token_name1  => cv_tkn_table                    -- トークンコード1
                       , iv_token_value1 => cv_tkn_val_wk_data_tbl          -- トークン値1
                       , iv_token_name2  => cv_tkn_action                   -- トークンコード2
                       , iv_token_value2 => cv_tkn_val_update               -- トークン値2
                       , iv_token_name3  => cv_tkn_slip_num                 -- トークンコード3
                       , iv_token_value3 => i_work_data_rec.slip_no         -- トークン値3
                       , iv_token_name4  => cv_tkn_slip_branch_num          -- トークンコード4
                       , iv_token_value4 => i_work_data_rec.slip_branch_no  -- トークン値4
                       , iv_token_name5  => cv_tkn_line_num                 -- トークンコード5
                       , iv_token_value5 => i_work_data_rec.line_number     -- トークン値5
                       , iv_token_name6  => cv_tkn_bukken                   -- トークンコード6
                       , iv_token_value6 => i_work_data_rec.install_code    -- トークン値6
                       , iv_token_name7  => cv_tkn_kokyaku                  -- トークンコード7
                       , iv_token_value7 => i_work_data_rec.account_number  -- トークン値7
                       , iv_token_name8  => cv_tkn_errmsg                   -- トークンコード8
                       , iv_token_value8 => SQLERRM                         -- トークン値8
                     );
        lv_errbuf := lv_errmsg;
        RAISE sql_expt;
    END;
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END update_work_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_xxcmm_cust_acnts
   * Description      : 顧客アドオンマスタ更新処理(A-15)
   ***********************************************************************************/
  PROCEDURE upd_xxcmm_cust_acnts(
      iv_proc_kbn         IN         VARCHAR2        -- 処理区分
    , i_cust_rec          IN         g_cust_rtype    -- 顧客情報
    , iv_duns_number_c    IN         VARCHAR2        -- DUNS番号（顧客ステータス）
    , id_actual_work_date IN         DATE            -- 実作業日
    , iv_account_number   IN         VARCHAR2        -- 顧客コード
    , id_process_date     IN         DATE            -- 業務処理日付
    , ov_errbuf           OUT NOCOPY VARCHAR2        -- エラー・メッセージ            --# 固定 #
    , ov_retcode          OUT NOCOPY VARCHAR2        -- リターン・コード              --# 固定 #
    , ov_errmsg           OUT NOCOPY VARCHAR2        -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_xxcmm_cust_acnts';  -- プログラム名
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
    lv_chk_rslt       VARCHAR2(10);
    ln_customer_id    NUMBER;
    --
    -- *** ローカル例外 ***
    sql_expt     EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ========================================
    -- 1.AR会計期間チェック
    -- ========================================
    IF (iv_proc_kbn = cv_proc_kbn1) THEN
      --実作業日
      lv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
                       id_standard_date => TO_DATE(id_actual_work_date)
                     );
    ELSE
      -- 顧客獲得日
      lv_chk_rslt := xxcso_util_common_pkg.check_ar_gl_period_status(
                       id_standard_date => i_cust_rec.cnvs_date
                     );
    END IF;
    --
    -- AR会計期間がクローズの場合
    IF ((iv_proc_kbn = cv_proc_kbn1 AND 
          TO_CHAR(id_actual_work_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
          lv_chk_rslt = cv_true
        ) OR
        (iv_proc_kbn = cv_proc_kbn2 AND
          TO_CHAR(i_cust_rec.cnvs_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
          lv_chk_rslt = cv_true
        ) OR
        (iv_proc_kbn = cv_proc_kbn2 AND lv_chk_rslt = cv_false)
       )
    THEN
      -- ========================================
      -- 2.顧客アドオンマスタロック
      -- ========================================
      BEGIN
        SELECT xca.customer_id  customer_id  -- 顧客ID
        INTO  ln_customer_id                 -- 顧客ID
        FROM  xxcmm_cust_accounts  xca  -- 顧客アドオンマスタ
        WHERE xca.customer_id = i_cust_rec.cust_account_id  -- 顧客ID（アカウントID）

        FOR UPDATE NOWAIT
        ;
        --
      EXCEPTION
        -- *** ロックに失敗した場合 ***
        WHEN global_lock_expt THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_07           -- メッセージコード
                         , iv_token_name1  => cv_tkn_table               -- トークンコード1
                         , iv_token_value1 => cv_tkn_val_cust_addon_mst  -- トークン値1
                         , iv_token_name2  => cv_tkn_item                -- トークンコード2
                         , iv_token_value2 => cv_tkn_val_cust_cd         -- トークン値2
                         , iv_token_name3  => cv_tkn_base_val            -- トークンコード3
                         , iv_token_value3 => iv_account_number          -- トークン値3
                       );
          lv_errbuf := lv_errmsg;
          RAISE sql_expt;
          --
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_13           -- メッセージコード
                         , iv_token_name1  => cv_tkn_task_nm             -- トークンコード1
                         , iv_token_value1 => cv_tkn_val_cust_addon_mst  -- トークン値1
                         , iv_token_name2  => cv_tkn_item                -- トークンコード2
                         , iv_token_value2 => cv_tkn_val_cust_cd         -- トークン値2
                         , iv_token_name3  => cv_tkn_base_val            -- トークンコード3
                         , iv_token_value3 => iv_account_number          -- トークン値3
                         , iv_token_name4  => cv_tkn_errmsg              -- トークンコード4
                         , iv_token_value4 => SQLERRM                    -- トークン値4
                       );
          lv_errbuf := lv_errmsg;
          RAISE sql_expt;
      END;
      --
      -- ========================================
      -- 3.顧客アドオンマスタ更新
      -- ========================================
      BEGIN
        -- (A-15-2にて②b)の場合
        IF (iv_proc_kbn = cv_proc_kbn2 AND lv_chk_rslt = cv_false ) THEN
          UPDATE xxcmm_cust_accounts  -- 顧客アドオンマスタ
          SET   cnvs_date              = id_process_date              -- 顧客獲得日
              , last_updated_by        = cn_last_updated_by           -- 最終更新者
              , last_update_date       = cd_last_update_date          -- 最終更新日
              , last_update_login      = cn_last_update_login         -- 最終更新ログイン
              , request_id             = cn_request_id                -- 要求ID
              , program_application_id = cn_program_application_id    -- コンカレント・プログラム・アプリケーションID
              , program_id             = cn_program_id                -- コンカレント・プログラムID
              , program_update_date    = cd_program_update_date       -- プログラム更新日
          WHERE customer_id = i_cust_rec.cust_account_id  -- 顧客ID（アカウントID）
          ;
        -- A-15-2にて①の場合 またはA-15-2にて②a)の場合
        ELSIF ((iv_proc_kbn = cv_proc_kbn1 AND 
                TO_CHAR(id_actual_work_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                lv_chk_rslt = cv_true 
               ) OR
               (iv_proc_kbn = cv_proc_kbn2 AND
                TO_CHAR(i_cust_rec.cnvs_date , 'YYYYMM') = TO_CHAR(ADD_MONTHS(id_process_date , -1 ),'YYYYMM') AND
                lv_chk_rslt = cv_true 
               )
              )
        THEN
          UPDATE xxcmm_cust_accounts  -- 顧客アドオンマスタ
          SET   past_customer_status   = iv_duns_number_c             -- DUNS番号（顧客ステータス）
              , last_updated_by        = cn_last_updated_by           -- 最終更新者
              , last_update_date       = cd_last_update_date          -- 最終更新日
              , last_update_login      = cn_last_update_login         -- 最終更新ログイン
              , request_id             = cn_request_id                -- 要求ID
              , program_application_id = cn_program_application_id    -- コンカレント・プログラム・アプリケーションID
              , program_id             = cn_program_id                -- コンカレント・プログラムID
              , program_update_date    = cd_program_update_date       -- プログラム更新日
          WHERE customer_id = i_cust_rec.cust_account_id  -- 顧客ID（アカウントID）
          ;
        END IF;
      EXCEPTION
        -- *** OTHERS例外ハンドラ ***
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name                -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_18           -- メッセージコード
                         , iv_token_name1  => cv_tkn_table               -- トークンコード1
                         , iv_token_value1 => cv_tkn_val_cust_addon_mst  -- トークン値1
                         , iv_token_name2  => cv_tkn_action              -- トークンコード2
                         , iv_token_value2 => cv_tkn_val_update          -- トークン値2
                         , iv_token_name3  => cv_tkn_kokyaku             -- トークンコード3
                         , iv_token_value3 => iv_account_number          -- トークン値3
                         , iv_token_name4  => cv_tkn_errmsg              -- トークンコード4
                         , iv_token_value4 => SQLERRM                    -- トークン値4
                       );
          lv_errbuf := lv_errmsg;
          RAISE sql_expt;
      END;
      --
    END IF;
--
  EXCEPTION
    -- *** SQL例外ハンドラ ***
    WHEN sql_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_warn;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
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
--
  END upd_xxcmm_cust_acnts;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
      ov_errbuf   OUT NOCOPY VARCHAR2    -- エラー・メッセージ            --# 固定 #
    , ov_retcode  OUT NOCOPY VARCHAR2    -- リターン・コード              --# 固定 #
    , ov_errmsg   OUT NOCOPY VARCHAR2    -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain';    -- プログラム名
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
    lv_proc_kbn               VARCHAR2(1);
    --
    -- OUTパラメータ格納用
    ld_sysdate                DATE;                                              -- システム日付
    ld_process_date           DATE;                                              -- 業務処理日付
    ld_actual_work_date       DATE;                                              -- 実作業日
    lt_cust_sts_nm_suspended  VARCHAR2(100);                                     -- 顧客ステータス（休止）
    lt_cust_sts_nm_approved   VARCHAR2(100);                                     -- 顧客ステータス（承認済）
    lt_cust_sts_nm_customer   VARCHAR2(100);                                     -- 顧客ステータス（顧客）
    lt_cust_sts_suspended     hz_parties.duns_number_c%TYPE;                     -- 顧客ステータス（休止）
    lt_cust_sts_approved      hz_parties.duns_number_c%TYPE;                     -- 顧客ステータス（承認済）
    lt_cust_sts_customer      hz_parties.duns_number_c%TYPE;                     -- 顧客ステータス（顧客）
    lt_req_sts_approved       po_requisition_headers.authorization_status%TYPE;  -- 発注依頼ステータスコード（承認済）
    lv_org_id                 NUMBER;                                            -- オルグID
    --
    -- *** ローカル・カーソル ***
    -- 作業データ抽出カーソル
    CURSOR get_work_data_cur(
              id_process_date          IN DATE
            , it_auth_status_approved  IN po_requisition_headers.authorization_status%TYPE
           )
    IS
-- 2015/07/27 S.Yamashita E_本稼動_13237対応 MOD START
--      SELECT 
        SELECT /*+
                 LEADING(xiwd)
                 INDEX(xiwd XXCSO_IN_WORK_DATA_N09)
                 USE_NL(xiwd prh xrlv.prl xrlv.mcb xrlv.fllv cii)
               */
-- 2015/07/27 S.Yamashita E_本稼動_13237対応 MOD END
             xiwd.install_code2    install_code    -- 物件コード２（引揚用）
           , xiwd.account_number2  account_number  -- 顧客コード２（現設置先）
           , xiwd.slip_no          slip_no         -- 伝票No
           , xiwd.slip_branch_no   slip_branch_no  -- 伝票枝番
           , xiwd.line_number      line_number     -- 行番号
           , xiwd.actual_work_date actual_work_date -- 実作業日
         /*20090507_mori_T1_0439 START*/
           , cii.instance_type_code instance_type_code           -- インスタンスタイプコード
         /*20090507_mori_T1_0439 END*/
         /* 2009/12/03 T.maruyama E_本稼動_00270対応 START */
           , xiwd.seq_no           seq_no           -- シーケンス番号
         /* 2009/12/03 T.maruyama E_本稼動_00270対応 END */
      FROM   xxcso_in_work_data         xiwd    -- 作業データテーブル
           , po_requisition_headers     prh     -- 発注依頼ヘッダビュー
           , xxcso_requisition_lines_v  xrlv    -- 発注依頼明細情報ビュー
         /*20090507_mori_T1_0439 START*/
           , csi_item_instances         cii     -- インストールベースマスタ（物件マスタ）
         /*20090507_mori_T1_0439 END*/
      WHERE  xiwd.job_kbn                          = cv_job_kbn_withdraw       -- 作業区分（引揚）
      AND    xiwd.completion_kbn                   = cv_completion_kbn_cmplt   -- 完了区分（完了）
      AND    xiwd.install2_processed_flag          = cv_install2_proc_end      -- 物件２処理済フラグ（処理済）
      AND    xiwd.suspend_processed_flag           = cv_suspend_proc_unprc     -- 休止処理済フラグ（未処理）
      AND    SUBSTRB( xrlv.withdrawal_type, 1, 1 ) = cv_withdrawal_type_nrml   -- 引揚区分（引揚）
      AND    xrlv.category_kbn                     = cv_category_kbn_withdraw  -- カテゴリ区分（引揚）
      AND    prh.authorization_status              = it_auth_status_approved   -- 承認ステータス
      AND    prh.segment1               = TO_CHAR( xiwd.po_req_number )    -- 発注依頼番号
      AND    xrlv.requisition_header_id = prh.requisition_header_id        -- 発注依頼ヘッダID
-- 2015/07/27 S.Yamashita E_本稼動_13237対応 DEL START
--      AND    xrlv.line_num              = xiwd.line_num                    -- 発注依頼明細番号
--      AND    xrlv.withdraw_install_code = xiwd.install_code2               -- 引揚用物件コード（物件コード）
-- 2015/07/27 S.Yamashita E_本稼動_13237対応 DEL END
    /*20090507_mori_T1_0439 START*/
      AND    cii.external_reference     = xiwd.install_code2               -- 引揚用物件コード（物件コード）
    /*20090507_mori_T1_0439 END*/
      ;
    --
    -- 顧客情報抽出カーソル
    CURSOR get_cust_acnt_cur(
              it_cust_stat_approved  IN hz_parties.duns_number_c%TYPE
           )
    IS
      SELECT xcav.party_id              party_id               -- パーティID
           , xcav.account_number        account_number         -- 顧客コード
           , xcav.cust_account_id       cust_account_id        -- アカウントID
           , xcav.cnvs_date             cnvs_date              -- 顧客獲得日
           , xcav.party_name            party_name             -- 顧客名
           , xcav.customer_status       customer_status        -- 顧客ステータス
           , hpa.object_version_number  object_version_number  -- オブジェクトバージョン番号
      FROM   xxcso_cust_accounts_v  xcav    -- 顧客マスタビュー
           , hz_parties             hpa     -- パーティマスタ
      WHERE  xcav.cnvs_date IS NOT NULL                    -- 顧客獲得日
      AND    xcav.customer_status = it_cust_stat_approved  -- 承認ステータス
      AND    xcav.party_id        = hpa.party_id           -- パーティID
      AND    xcav.business_low_type IN (cv_business_low_type24,cv_business_low_type25,cv_business_low_type27)
      
      ;
    --
    -- *** ローカル・レコード ***
    l_work_data_rec        g_work_data_rtype;
    l_cust_rec             g_cust_rtype;
    l_cust_rec2            g_cust_rtype;
    l_get_work_data_rec    get_work_data_cur%ROWTYPE;
    l_get_cust_acnt_rec    get_cust_acnt_cur%ROWTYPE;
    --
    -- *** ローカル例外 ***
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
    -- 件数カウントの初期化
    gn_target_cnt  := 0;
    gn_normal_cnt  := 0;
    gn_warn_cnt    := 0;
    gn_error_cnt   := 0;
    gn_target_cnt2 := 0;
    gn_normal_cnt2 := 0;
    gn_warn_cnt2   := 0;
    gn_error_cnt2  := 0;
--
    -- 処理区分の設定（処理区分=「休止処理」）
    lv_proc_kbn := cv_proc_kbn1;
    --
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
       od_process_date => ld_process_date  -- 業務処理日付
     , ov_errbuf       => lv_errbuf        -- エラー・メッセージ            --# 固定 #
     , ov_retcode      => lv_retcode       -- リターン・コード              --# 固定 #
     , ov_errmsg       => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.プロファイル値取得
    -- ========================================
    get_profile_info(
        ov_cust_sts_suspended => lt_cust_sts_nm_suspended  -- 顧客ステータス（休止）
      , ov_cust_sts_approved  => lt_cust_sts_nm_approved   -- 顧客ステータス（承認済）
      , ov_cust_sts_customer  => lt_cust_sts_nm_customer   -- 顧客ステータス（顧客）
      , ov_req_sts_approved   => lt_req_sts_approved       -- 発注依頼ステータスコード（承認済）
      , ov_org_id             => lv_org_id                 -- オルグID
      , ov_errbuf             => lv_errbuf                 -- エラー・メッセージ            --# 固定 #
      , ov_retcode            => lv_retcode                -- リターン・コード              --# 固定 #
      , ov_errmsg             => lv_errmsg                 -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-3.顧客ステータス抽出
    -- ========================================
--
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg9 || CHR(10)
    );
--
    -- 顧客ステータス：「休止」
    get_cust_status(
        it_cust_status_nm => lt_cust_sts_nm_suspended  -- 顧客ステータス名
      , id_process_date   => ld_process_date           -- 業務処理日付
      , ot_cust_status_cd => lt_cust_sts_suspended     -- 顧客ステータス
      , ov_errbuf         => lv_errbuf                 -- エラー・メッセージ            --# 固定 #
      , ov_retcode        => lv_retcode                -- リターン・コード              --# 固定 #
      , ov_errmsg         => lv_errmsg                 -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    -- 取得した顧客ステータスをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_tkn_val_cust_sts           || cv_case_arc_left
                   || lt_cust_sts_nm_suspended || cv_case_arc_right
                   || cv_msg_equal             || lt_cust_sts_suspended || CHR(10)
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- 顧客ステータス：「承認済」
    get_cust_status(
        it_cust_status_nm => lt_cust_sts_nm_approved  -- 顧客ステータス名
      , id_process_date   => ld_process_date          -- 業務処理日付
      , ot_cust_status_cd => lt_cust_sts_approved     -- 顧客ステータス
      , ov_errbuf         => lv_errbuf                -- エラー・メッセージ            --# 固定 #
      , ov_retcode        => lv_retcode               -- リターン・コード              --# 固定 #
      , ov_errmsg         => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    -- 取得した顧客ステータスをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_tkn_val_cust_sts          || cv_case_arc_left
                   || lt_cust_sts_nm_approved || cv_case_arc_right
                   || cv_msg_equal            || lt_cust_sts_approved || CHR(10)
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    --
    -- 顧客ステータス：「顧客」
    get_cust_status(
        it_cust_status_nm => lt_cust_sts_nm_customer  -- 顧客ステータス名
      , id_process_date   => ld_process_date          -- 業務処理日付
      , ot_cust_status_cd => lt_cust_sts_customer     -- 顧客ステータス
      , ov_errbuf         => lv_errbuf                -- エラー・メッセージ            --# 固定 #
      , ov_retcode        => lv_retcode               -- リターン・コード              --# 固定 #
      , ov_errmsg         => lv_errmsg                -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    --
    -- 取得した顧客ステータスをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_tkn_val_cust_sts          || cv_case_arc_left
                   || lt_cust_sts_nm_customer || cv_case_arc_right
                   || cv_msg_equal            || lt_cust_sts_customer || CHR(10)
                   || ''
    );
    --
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-4.作業データ抽出
    -- ========================================
    -- 作業データ抽出カーソルオープン
    OPEN get_work_data_cur(
        id_process_date         => ld_process_date
      , it_auth_status_approved => lt_req_sts_approved
    );
--
    -- 作業データ抽出カーソルをオープンしたことをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_copn1 || CHR(10) ||
                 ''
    );
--
    << get_work_data_loop >>
    LOOP
      --
      BEGIN
        --
        FETCH get_work_data_cur INTO l_get_work_data_rec;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name             -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_03        -- メッセージコード
                         , iv_token_name1  => cv_tkn_table            -- トークンコード1
                         , iv_token_value1 => cv_tkn_val_wk_data_tbl  -- トークン値1
                         , iv_token_name2  => cv_tkn_errmsg           -- トークンコード2
                         , iv_token_value2 => SQLERRM                 -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          RAISE global_process_expt;
      END;
      --
      -- 処理対象件数格納
      gn_target_cnt := get_work_data_cur%ROWCOUNT;
      --
      -- 処理対象データが存在しなかった場合EXIT
      EXIT WHEN get_work_data_cur%NOTFOUND
      OR  get_work_data_cur%ROWCOUNT = 0;
      --
      l_work_data_rec.slip_no        := l_get_work_data_rec.slip_no;
      l_work_data_rec.slip_branch_no := l_get_work_data_rec.slip_branch_no;
      l_work_data_rec.line_number    := l_get_work_data_rec.line_number;
      l_work_data_rec.install_code   := l_get_work_data_rec.install_code;
      l_work_data_rec.account_number := l_get_work_data_rec.account_number;
      l_work_data_rec.actual_work_date := l_get_work_data_rec.actual_work_date;
      /*20090507_mori_T1_0439 START*/
      l_work_data_rec.instance_type_code := l_get_work_data_rec.instance_type_code;
      /*20090507_mori_T1_0439 END*/
      /* 2009/12/03 T.maruyama E_本稼動_00270対応 START */
      l_work_data_rec.seq_no := l_get_work_data_rec.seq_no;
      /* 2009/12/03 T.maruyama E_本稼動_00270対応 END */
      --
      -- 実作業日を設定
      ld_actual_work_date := TO_DATE(l_get_work_data_rec.actual_work_date,'YYYY/MM/DD');
      --
      -- 作業データ関連処理スキップ用ループ開始
      << wk_data_proc_skip_loop >>
      LOOP
      /*20090507_mori_T1_0439 START*/
        -- 顧客情報更新フラグ初期化
        gv_cust_upd_flg := cv_cust_upd_y;
      /*20090507_mori_T1_0439 END*/
        -- ========================================
        -- A-5.物件存在チェック処理
        -- ========================================
        chk_ib_info(
            i_work_data_rec => l_work_data_rec    -- 作業データ情報
          , ov_errbuf       => lv_errbuf          -- エラー・メッセージ            --# 固定 #
          , ov_retcode      => lv_retcode         -- リターン・コード              --# 固定 #
          , ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 次のレコードへ処理をスキップ
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-6.顧客情報抽出処理
        -- ========================================
        get_cust_info(
            i_work_data_rec => l_work_data_rec         -- 作業データ情報
          , iv_cust_status  => lt_cust_sts_customer    -- 顧客ステータス
          , o_cust_rec      => l_cust_rec              -- 顧客情報
          , ov_errbuf       => lv_errbuf               -- エラー・メッセージ            --# 固定 #
          , ov_retcode      => lv_retcode              -- リターン・コード              --# 固定 #
          , ov_errmsg       => lv_errmsg               -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- 次のレコードへ処理をスキップ
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        /* 2009.07.23 K.Satomura 0000671対応 START */
        IF (l_cust_rec.duns_number_c = lt_cust_sts_customer) THEN
        /* 2009.07.23 K.Satomura 0000671対応 END */
          /*20090507_mori_T1_0439 START*/
          -- 引揚物件が自販機である場合
          IF (l_work_data_rec.instance_type_code = cv_instance_type_vd) THEN
          /*20090507_mori_T1_0439 END*/
            -- ========================================
            -- A-7.設置先顧客・物件チェック処理
            -- ========================================
            chk_cust_ib(
                i_work_data_rec => l_work_data_rec               -- 作業データ情報
              , in_acnt_id      => l_cust_rec.cust_account_id    -- アカウントID
              , ov_errbuf       => lv_errbuf                     -- エラー・メッセージ            --# 固定 #
              , ov_retcode      => lv_retcode                    -- リターン・コード              --# 固定 #
              , ov_errmsg       => lv_errmsg                     -- ユーザー・エラー・メッセージ  --# 固定 #
            );
            --
            IF ( lv_retcode = cv_status_warn ) THEN
              -- 次のレコードへ処理をスキップ
              EXIT;
              --
            ELSIF ( lv_retcode = cv_status_error ) THEN
              RAISE global_process_expt;
              --
            END IF;
          /*20090507_mori_T1_0439 START*/
          END IF;
          /*20090507_mori_T1_0439 END*/
          --
        /* 2009.07.23 K.Satomura 0000671対応 START */
        END IF;
        /* 2009.07.23 K.Satomura 0000671対応 END */
        -- ========================================
        -- A-8.セーブポイント設定
        -- ========================================
        SAVEPOINT g_save_pt;
        --
        /* 2009.07.23 K.Satomura 0000671対応 START */
        IF (l_cust_rec.duns_number_c = lt_cust_sts_customer) THEN
        /* 2009.07.23 K.Satomura 0000671対応 END */
          /*20090507_mori_T1_0439 START*/
          -- 引揚物件が自販機且つ現設置先顧客の自販機残数が0件である場合
          IF (
                  (gv_cust_upd_flg = cv_cust_upd_y)
              AND (l_work_data_rec.instance_type_code = cv_instance_type_vd)
             ) THEN
          /*20090507_mori_T1_0439 END*/
            -- ========================================
            -- A-15.顧客アドオンマスタ更新処理
            -- ========================================
            upd_xxcmm_cust_acnts(
                iv_proc_kbn       => cv_proc_kbn1                        -- 処理区分
              , i_cust_rec        => l_cust_rec                          -- 顧客情報
              , iv_duns_number_c  => lt_cust_sts_suspended                -- DUNS番号（顧客ステータス（休止））
              , id_actual_work_date => ld_actual_work_date               -- 実作業日
              , iv_account_number => l_work_data_rec.account_number      -- 顧客コード
              , id_process_date   => ld_process_date                     -- 業務処理日付
              , ov_errbuf         => lv_errbuf                           -- エラー・メッセージ            --# 固定 #
              , ov_retcode        => lv_retcode                          -- リターン・コード              --# 固定 #
              , ov_errmsg         => lv_errmsg                           -- ユーザー・エラー・メッセージ  --# 固定 #
            );
            --
            IF ( lv_retcode = cv_status_warn ) THEN
              -- セーブポイントまでロールバックし、次のレコードへ処理をスキップ
              ROLLBACK TO g_save_pt;
              EXIT;
              --
            ELSIF ( lv_retcode = cv_status_error ) THEN
              --
              RAISE global_process_expt;
              --
            END IF;
            -- ========================================
            -- A-9.顧客ステータス更新処理（休止処理）
            -- ========================================
            update_cust_status(
                iv_proc_kbn      => cv_proc_kbn1           -- 処理区分
              , i_work_data_rec  => l_work_data_rec        -- 作業データ情報
              , i_cust_rec       => l_cust_rec             -- 顧客情報
              , iv_duns_number_c => lt_cust_sts_suspended  -- DUNS番号（顧客ステータス（休止））
              , ov_errbuf        => lv_errbuf              -- エラー・メッセージ            --# 固定 #
              , ov_retcode       => lv_retcode             -- リターン・コード              --# 固定 #
              , ov_errmsg        => lv_errmsg              -- ユーザー・エラー・メッセージ  --# 固定 #
            );
            --
            IF ( lv_retcode = cv_status_warn ) THEN
              -- セーブポイントまでロールバックし、次のレコードへ処理をスキップ
              ROLLBACK TO g_save_pt;
              EXIT;
              --
            ELSIF ( lv_retcode = cv_status_error ) THEN
              --
              RAISE global_process_expt;
              --
            END IF;
          /*20090507_mori_T1_0439 START*/
          END IF;
          /*20090507_mori_T1_0439 END*/
          --
        /* 2009.07.23 K.Satomura 0000671対応 START */
        END IF;
        /* 2009.07.23 K.Satomura 0000671対応 END */
        -- ========================================
        -- A-10.セーブポイント２設定
        -- ========================================
        SAVEPOINT g_save_pt2;
        --
        -- ========================================
        -- A-11.作業データロック処理
        -- ========================================
        work_data_lock(
            i_work_data_rec => l_work_data_rec    -- 作業データ情報
          , ov_errbuf       => lv_errbuf          -- エラー・メッセージ            --# 固定 #
          , ov_retcode      => lv_retcode         -- リターン・コード              --# 固定 #
          , ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイント２までロールバックし、次のレコードへ処理をスキップ
          ROLLBACK TO g_save_pt2;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-12.作業データ更新処理
        -- ========================================
        update_work_data(
            i_work_data_rec => l_work_data_rec    -- 作業データ情報
          , ov_errbuf       => lv_errbuf          -- エラー・メッセージ            --# 固定 #
          , ov_retcode      => lv_retcode         -- リターン・コード              --# 固定 #
          , ov_errmsg       => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイント２までロールバックし、次のレコードへ処理をスキップ
          ROLLBACK TO g_save_pt2;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
          --
        END IF;
        --
        -- 作業データ関連処理スキップ用ループからEXIT
        EXIT;
        --
      END LOOP;  -- 作業データ関連処理スキップ用ループ終了
      --
      -- リターン・コードが正常の場合
      IF ( lv_retcode = cv_status_normal ) THEN
      /*20090507_mori_T1_0439 START*/
        -- 引揚物件が自販機且つ現設置先顧客の自販機残数が0件以上である場合、
        -- 処理を警告とし、スキップ件数にカウントする。
        IF (
                (gv_cust_upd_flg = cv_cust_upd_n)
            AND (l_work_data_rec.instance_type_code = cv_instance_type_vd)
           ) THEN
          -- スキップ件数カウント
          gn_warn_cnt := gn_warn_cnt + 1;
          --
          -- リターンコードに警告ステータスを設定
          ov_retcode := cv_status_warn;
          --
        ELSE
          -- 成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
        END IF;
--        -- 成功件数カウント
--        gn_normal_cnt := gn_normal_cnt + 1;
      /*20090507_mori_T1_0439 END*/
        --
      -- リターン・コードが警告の場合
      ELSE
        -- スキップ件数カウント
        gn_warn_cnt := gn_warn_cnt + 1;
        --
        -- 警告内容をメッセージ、ログへ出力
        fnd_file.put_line(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg    -- ユーザー・エラーメッセージ
        );
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => lv_errbuf    -- エラーメッセージ
        );
        --
        -- リターンコードに警告ステータスを設定
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    END LOOP;
    --
    -- 作業データ抽出カーソルクローズ
    CLOSE get_work_data_cur;
--
    -- 作業データ抽出カーソルをクローズしたことをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_ccls1 || CHR(10) ||
                 ''
    );
--
    -- 作業データ情報、顧客情報格納用変数を初期化
    l_work_data_rec := NULL;
    l_cust_rec      := NULL;
    --
    -- 処理区分の設定（処理区分=「承認済→顧客処理」）
    lv_proc_kbn := cv_proc_kbn2;
--
    -- ========================================
    -- A-13.顧客情報抽出
    -- ========================================
    -- 顧客情報抽出カーソルオープン
    OPEN get_cust_acnt_cur(
        it_cust_stat_approved => lt_cust_sts_approved
    );
--
    -- 顧客情報抽出カーソルをオープンしたことをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_copn2 || CHR(10) ||
                 ''
    );
--
    << get_cust_acnt_loop >>
    LOOP
      --
      BEGIN
        --
        FETCH get_cust_acnt_cur INTO l_get_cust_acnt_rec;
        --
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_app_name           -- アプリケーション短縮名
                         , iv_name         => cv_tkn_number_03      -- メッセージコード
                         , iv_token_name1  => cv_tkn_table          -- トークンコード1
                         , iv_token_value1 => cv_tkn_val_cust_info  -- トークン値1
                         , iv_token_name2  => cv_tkn_errmsg         -- トークンコード2
                         , iv_token_value2 => SQLERRM               -- トークン値2
                       );
          lv_errbuf := lv_errmsg;
          --
          -- スキップ件数カウント
          gn_warn_cnt2 := gn_warn_cnt2 + 1;
          --
          -- 警告内容をメッセージ、ログへ出力
          fnd_file.put_line(
              which => FND_FILE.OUTPUT
            , buff  => lv_errmsg    -- ユーザー・エラーメッセージ
          );
          fnd_file.put_line(
              which => FND_FILE.LOG
            , buff  => lv_errbuf    -- エラーメッセージ
          );
          --
          -- リターンコードに警告ステータスを設定
          ov_retcode := cv_status_warn;
          --
          EXIT;
          --
      END;
      --
      -- 処理対象件数格納
      gn_target_cnt2 := get_cust_acnt_cur%ROWCOUNT;
      --
      -- 処理対象データが存在しなかった場合EXIT
      EXIT WHEN get_cust_acnt_cur%NOTFOUND
      OR  get_cust_acnt_cur%ROWCOUNT = 0;
      --
      l_cust_rec2.object_version_number := l_get_cust_acnt_rec.object_version_number;
      l_cust_rec2.party_id              := l_get_cust_acnt_rec.party_id;
      l_cust_rec2.account_number        := l_get_cust_acnt_rec.account_number;
      l_cust_rec2.cust_account_id       := l_get_cust_acnt_rec.cust_account_id;
      l_cust_rec2.cnvs_date             := l_get_cust_acnt_rec.cnvs_date;
      l_cust_rec2.party_name            := l_get_cust_acnt_rec.party_name;
      l_cust_rec2.duns_number_c         := l_get_cust_acnt_rec.customer_status;
      --
      -- 顧客情報関連処理スキップ用ループ開始
      << cust_proc_skip_loop >>
      LOOP
        -- ========================================
        -- A-14.セーブポイント３設定
        -- ========================================
        SAVEPOINT g_save_pt3;
        --
        -- ========================================
        -- A-15.顧客アドオンマスタ更新処理
        -- ========================================
        upd_xxcmm_cust_acnts(
            iv_proc_kbn       => cv_proc_kbn2                        -- 処理区分
          , i_cust_rec        => l_cust_rec2                         -- 顧客情報
          , iv_duns_number_c => lt_cust_sts_customer                 -- DUNS番号（顧客ステータス（顧客））
          , id_actual_work_date => ld_actual_work_date               -- 実作業日
          , iv_account_number => l_get_cust_acnt_rec.account_number  -- 顧客コード
          , id_process_date   => ld_process_date                     -- 業務処理日付
          , ov_errbuf         => lv_errbuf                           -- エラー・メッセージ            --# 固定 #
          , ov_retcode        => lv_retcode                          -- リターン・コード              --# 固定 #
          , ov_errmsg         => lv_errmsg                           -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイント３までロールバックし、次のレコードへ処理をスキップ
          ROLLBACK TO g_save_pt3;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --
          RAISE global_process_expt;
          --
        END IF;
        --
        -- ========================================
        -- A-9.顧客ステータス更新処理（承認済→顧客処理）
        -- ========================================
        update_cust_status(
            iv_proc_kbn      => cv_proc_kbn2          -- 処理区分
          , i_work_data_rec  => l_work_data_rec       -- 作業データ情報
          , i_cust_rec       => l_cust_rec2           -- 顧客情報
          , iv_duns_number_c => lt_cust_sts_customer  -- DUNS番号（顧客ステータス（顧客））
          , ov_errbuf        => lv_errbuf             -- エラー・メッセージ            --# 固定 #
          , ov_retcode       => lv_retcode            -- リターン・コード              --# 固定 #
          , ov_errmsg        => lv_errmsg             -- ユーザー・エラー・メッセージ  --# 固定 #
        );
        --
        IF ( lv_retcode = cv_status_warn ) THEN
          -- セーブポイント３までロールバックし、次のレコードへ処理をスキップ
          ROLLBACK TO g_save_pt3;
          EXIT;
          --
        ELSIF ( lv_retcode = cv_status_error ) THEN
          --
          RAISE global_process_expt;
          --
        END IF;
        --
        -- 顧客情報関連処理スキップ用ループからEXIT
        EXIT;
        --
      END LOOP;  -- 顧客情報関連処理スキップ用ループ終了
      --
      -- リターン・コードが正常の場合
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 成功件数カウント
        gn_normal_cnt2 := gn_normal_cnt2 + 1;
        --
      -- リターン・コードが警告の場合
      ELSE
        -- スキップ件数カウント
        gn_warn_cnt2 := gn_warn_cnt2 + 1;
        --
        -- 警告内容をメッセージ、ログへ出力
        fnd_file.put_line(
            which => FND_FILE.OUTPUT
          , buff  => lv_errmsg    -- ユーザー・エラーメッセージ
        );
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => lv_errbuf    -- エラーメッセージ
        );
        --
        -- リターンコードに警告ステータスを設定
        ov_retcode := cv_status_warn;
        --
      END IF;
      --
    END LOOP;
    --
    -- 顧客情報抽出カーソルクローズ
    CLOSE get_cust_acnt_cur;
--
    -- 顧客情報抽出カーソルをオープンしたことをログ出力
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => cv_log_msg_ccls2 || CHR(10) ||
                 ''
    );
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      -- エラー件数カウント
      IF ( lv_proc_kbn = cv_proc_kbn1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        gn_error_cnt2 := gn_error_cnt2 + 1;
        --
      END IF;
      --
      -- カーソルがクローズされていない場合
      IF ( get_work_data_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_work_data_cur;
        --
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls1_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err2     || CHR(10)     ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF ( get_cust_acnt_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_cust_acnt_cur;
        --
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls2_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err2     || CHR(10)     ||
                     ''
        );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      -- エラー件数カウント
      IF ( lv_proc_kbn = cv_proc_kbn1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        gn_error_cnt2 := gn_error_cnt2 + 1;
        --
      END IF;
      --
      -- カーソルがクローズされていない場合
      IF ( get_work_data_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_work_data_cur;
        --
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls1_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err3     || CHR(10)     ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF ( get_cust_acnt_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_cust_acnt_cur;
        --
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls2_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err3     || CHR(10)     ||
                     ''
        );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      -- エラー件数カウント
      IF ( lv_proc_kbn = cv_proc_kbn1 ) THEN
        gn_error_cnt := gn_error_cnt + 1;
        --
      ELSE
        gn_error_cnt2 := gn_error_cnt2 + 1;
        --
      END IF;
      --
      -- カーソルがクローズされていない場合
      IF ( get_work_data_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_work_data_cur;
        --
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls1_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err4     || CHR(10)     ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      IF ( get_cust_acnt_cur%ISOPEN ) THEN
        -- カーソルクローズ
        CLOSE get_cust_acnt_cur;
        --
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
            which => FND_FILE.LOG
          , buff  => cv_log_msg_ccls2_ex || CHR(10)     ||
                     cv_prg_name         || cv_msg_part ||
                     cv_log_msg_err4     || CHR(10)     ||
                     ''
        );
      END IF;
      --
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
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
      , ov_errbuf  => lv_errbuf
      , ov_errmsg  => lv_errmsg
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
        ov_errbuf  => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      , ov_retcode => lv_retcode    -- リターン・コード              --# 固定 #
      , ov_errmsg  => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF ( lv_retcode = cv_status_error ) THEN
       --エラー出力
       fnd_file.put_line(
           which => FND_FILE.OUTPUT
         , buff  => lv_errmsg                  -- ユーザー・エラーメッセージ
       );
       fnd_file.put_line(
           which => FND_FILE.LOG
         , buff  => cv_pkg_name || cv_msg_cont ||
                    cv_prg_name || cv_msg_part ||
                    lv_errbuf                  -- エラーメッセージ
       );
    END IF;
--
    -- =======================
    -- A-16.終了処理 
    -- =======================
    --空行の出力
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => ''
    );
    --
    ----------------------------------------
    -- 休止処理の各件数出力
    ----------------------------------------
    -- 見出し出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name         -- アプリケーション短縮名
                  , iv_name         => cv_tkn_number_19    -- メッセージコード
                );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    ----------------------------------------
    -- 承認済→顧客処理の各件数出力
    ----------------------------------------
    -- 見出し出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name         -- アプリケーション短縮名
                  , iv_name         => cv_tkn_number_20    -- メッセージコード
                );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- 対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_target_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_target_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- 成功件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_success_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_normal_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- スキップ件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_skip_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_warn_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
    -- エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_appl_short_name
                    , iv_name         => cv_error_rec_msg
                    , iv_token_name1  => cv_cnt_token
                    , iv_token_value1 => TO_CHAR( gn_error_cnt2 )
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    ----------------------------------------
    -- 終了メッセージ出力
    ----------------------------------------
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_warn_msg;
    ELSIF( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                      iv_application => cv_appl_short_name
                    , iv_name        => lv_message_code
                  );
    fnd_file.put_line(
        which => FND_FILE.OUTPUT
      , buff  => gv_out_msg
    );
    --
--
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
      --
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
          which => FND_FILE.LOG
        , buff  => cv_log_msg10 || CHR(10) ||
                   ''
      );
    END IF;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM || lv_errbuf;
      retcode := cv_status_error;
      ROLLBACK;
      --
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_log_msg10 || CHR(10) ||
                   ''
      );
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --
      -- ロールバックしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_log_msg10 || CHR(10) ||
                   ''
      );
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCSO013A01C;
/
