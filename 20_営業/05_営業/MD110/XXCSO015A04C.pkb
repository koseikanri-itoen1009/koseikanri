CREATE OR REPLACE PACKAGE BODY XXCSO015A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO015A04C(spec)
 * Description      : 拠点分割等により顧客マスタの拠点コードが変更になった物件マスタの情報と廃棄申請、
 *                    廃棄決裁の作業依頼情報を自販機管理システムに連携します。
 *                    
 * MD050            : MD050_CSO_015_A04_自販機-EBSインタフェース：（OUT）物件マスタ情報
 *                    
 * Version          : 1.3
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        初期処理 (A-1)
 *  get_profile_info            プロファイル値取得 (A-2)
 *  open_csv_file               CSVファイルオープン (A-3)
 *  chk_str                     禁則文字チェック (A-6,A-10)
 *  update_item_instance        拠点変更物件マスタ情報更新 (A-7)
 *  create_csv_rec              CSVファイル出力 (A-8,A-13)
 *  update_wk_reqst_tbl         作業依頼／発注情報処理結果テーブル更新(A-12)
 *  close_csv_file              CSVファイルクローズ処理 (A-14)
 *  submain                     メイン処理プロシージャ
 *                                セーブポイント(ファイルクローズ失敗用)発行(A-4)
 *                                拠点変更物件マスタ情報抽出 (A-5)
 *                                廃棄作業依頼情報データ抽出(A-9)
 *                                セーブポイント(廃棄作業依頼情報連携失敗)発行(A-11)
 *  main                        コンカレント実行ファイル登録プロシージャ
 *                                  終了処理 (A-16)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-06    1.0   kyo              新規作成
 *  2009-03-13    1.1   abe              拠点変更データの障害時対応
 *  2009-03-16    1.2   N.Yabuki         作業依頼／発注情報処理結果テーブルのWHOカラム更新処理追加
 *  2009-04-13    1.3   K.Satomura       システムテスト障害対応(T1_0409)
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
  cv_msg_part               CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont               CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg                VARCHAR2(2000);
  gn_target_cnt             NUMBER;                    -- 対象件数
  gn_normal_cnt             NUMBER;                    -- 正常件数
  gn_error_cnt              NUMBER;                    -- エラー件数
--
  gv_csv_process_kbn        VARCHAR2(100);              -- 拠点変更・廃棄情報CSV出力処理区分
  gv_date_value             VARCHAR2(100);              -- 処理日付
--
--################################  固定部 END   ##################################
--
    -- 抽出内容名(取引タイプの取引タイプID)
    cv_csi_txn_types          CONSTANT VARCHAR2(100) := '取引タイプの取引タイプID';

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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO015A04C';  -- パッケージ名
  cv_app_name            CONSTANT VARCHAR2(10)  := 'XXCSO';         -- アプリケーション短縮名
  cv_appl_short_name     CONSTANT VARCHAR2(10)  := 'XXCCP';         -- アドオン：共通・IF領域
--
  cv_active_status       CONSTANT VARCHAR2(1)   := 'A';             -- アクティブ
  cv_csv_proc_kbn_1      CONSTANT VARCHAR2(1)   := '1';             -- 廃棄情報出力処理
  cv_csv_proc_kbn_2      CONSTANT VARCHAR2(1)   := '2';             -- 拠点変更出力処理
  cv_language            CONSTANT VARCHAR2(10)  := 'JA';            -- 言語
  cv_disposal_sinsei     CONSTANT VARCHAR2(10)  := '60';            -- 廃棄申請
  cv_disposal_kessai     CONSTANT VARCHAR2(10)  := '70';            -- 廃棄決裁
  cv_status_app          CONSTANT VARCHAR2(10)  := 'APPROVED';      -- 承認ステータス
  cv_interface_flag_n    CONSTANT VARCHAR2(10)  := 'N';             -- 連携済フラグ
  cv_interface_flag_y    CONSTANT VARCHAR2(10)  := 'Y';             -- 連携済フラグ  
  cv_src_transaction_type CONSTANT VARCHAR2(10)  := 'IB_UI';      -- ソーストランザクションタイプ
  
--
  -- メッセージコード
  cv_tkn_number_01  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00226';  -- パラメータ出力
  cv_tkn_number_02  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00227';
    -- パラメータ不正エラー（拠点変更・廃棄情報CSV出力処理区分）
  cv_tkn_number_03  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日取得エラーメッセージ
  cv_tkn_number_04  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- インターフェースファイル名
  cv_tkn_number_05  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00014';  -- プロファイル取得エラーメッセージ
  cv_tkn_number_06  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00123';  -- CSVファイル残存エラーメッセージ
  cv_tkn_number_07  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00015';  -- CSVファイルオープンエラーメッセージ
  cv_tkn_number_08  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00024';  -- データ抽出エラーメッセージ
  cv_tkn_number_09  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00190';  -- 追加属性値なし警告メッセージ
  cv_tkn_number_10  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00159';  -- 禁則文字チェックエラーメッセージ
  cv_tkn_number_12  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00194';  -- CSVファイル出力エラーメッセージ(物件マスタ情報)
  cv_tkn_number_13  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00196';
    -- ロックエラーメッセージ(作業依頼／発注情報処理結果テーブル)
  cv_tkn_number_14  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00197';  -- データ更新エラーメッセージ
  cv_tkn_number_15  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00195';  -- CSV出力エラーメッセージ(作業依頼情報)
  cv_tkn_number_16  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00198';  -- 物件マスタ情報連携済正常メッセージ(拠点変更)
  cv_tkn_number_17  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00199';
    -- 作業依頼情報連携済正常メッセージ(廃棄申請、廃棄決裁)
  cv_tkn_number_18  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00018';  -- CSVファイルクローズエラーメッセージ
  cv_tkn_number_19  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00493';  -- パラメータ処理日付
  cv_tkn_number_20  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00012';  -- 日付書式エラー
  cv_tkn_number_21  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00525';
    -- 抽出エラーメッセージ(作業依頼／発注情報処理結果テーブル)
  cv_tkn_number_22  CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00224';  -- CSVファイル出力0件メッセージ
    -- 取引タイプエラー
  cv_tkn_number_23        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- 取引タイプID取得エラー
  cv_tkn_number_24        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- 取引タイプID抽出エラー
  cv_tkn_number_25        CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00158';  -- データ登録、更新失敗

  -- トークンコード
  cv_tkn_bukken          CONSTANT VARCHAR2(20) := 'BUKKEN';                -- 物件コード
  cv_tkn_err_msg         CONSTANT VARCHAR2(20) := 'ERR_MSG';               -- エラーメッセージ
  cv_tkn_task_name       CONSTANT VARCHAR2(20) := 'TASK_NAME';             -- 抽出内容
  cv_tkn_add_att_name    CONSTANT VARCHAR2(20) := 'ADD_ATTRIBUTE_NAME';    -- 追加属性定義名
  cv_tkn_prof_name       CONSTANT VARCHAR2(20) := 'PROF_NAME';             -- プロファイル・オプション名
  cv_tkn_csv_location    CONSTANT VARCHAR2(20) := 'CSV_LOCATION';          -- CSVファイル出力先 
  cv_tkn_csv_file_name   CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';         -- CSVファイル名 
  cv_tkn_item            CONSTANT VARCHAR2(20) := 'ITEM';                  -- チェック対象項目名
  cv_tkn_item_value      CONSTANT VARCHAR2(20) := 'ITEM_VALUE';            -- チェック対象の値
  cv_tkn_check_range     CONSTANT VARCHAR2(20) := 'CHECK_RANGE';           -- チェック範囲
  cv_tkn_req_line_id     CONSTANT VARCHAR2(50) := 'REQUISITION_LINE_ID';   -- 発注依頼明細ID
  cv_tkn_req_header_id   CONSTANT VARCHAR2(50) := 'REQUISITION_HEADER_ID'; -- 発注依頼ヘッダID
  cv_tkn_line_num        CONSTANT VARCHAR2(20) := 'LINE_NUM';              -- 発注依頼明細番号
  cv_tkn_table           CONSTANT VARCHAR2(20) := 'TABLE';                 -- 抽出データ内容
  cv_tkn_csv_proc_kbn    CONSTANT VARCHAR2(20) := 'CSV_PROCESS_KBN'; -- パラメータ値(拠点変更・廃棄情報CSV出力処理区分)
  cv_tkn_value           CONSTANT VARCHAR2(20) := 'VALUE';                 -- 入力値
  cv_tkn_process         CONSTANT VARCHAR2(20) := 'PROCESS';               -- プロセス
  cv_tkn_status          CONSTANT VARCHAR2(20) := 'STATUS';                -- リターンステータス(日付書式チェック結果)
  cv_tkn_message         CONSTANT VARCHAR2(20) := 'MESSAGE';               -- メッセージ 
  cv_tkn_src_tran_type    CONSTANT VARCHAR2(20) := 'SRC_TRAN_TYPE';

--
  cb_true                CONSTANT BOOLEAN := TRUE;
  cb_false               CONSTANT BOOLEAN := FALSE;
--
  -- DEBUG_LOG用メッセージ
  cv_debug_msg1           CONSTANT VARCHAR2(200) := '<< 入力パラメータ >>';
  cv_debug_msg2           CONSTANT VARCHAR2(200) := 'gv_csv_process_kbn     = ';
  cv_debug_msg3           CONSTANT VARCHAR2(200) := 'gv_date_value          = ';
  cv_debug_msg4           CONSTANT VARCHAR2(200) := '<< 業務処理日付取得処理 >>';
  cv_debug_msg5           CONSTANT VARCHAR2(200) := 'ld_process_date = ';
  cv_debug_msg6           CONSTANT VARCHAR2(200) := '<< プロファイル値取得処理 >>';
  cv_debug_msg7           CONSTANT VARCHAR2(200) := 'lv_file_dir        = ';
  cv_debug_msg8           CONSTANT VARCHAR2(200) := 'lv_file_name       = ';
  cv_debug_msg10          CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg11          CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg12          CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
--
  cv_debug_msg_fnm        CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls       CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_location   CONSTANT VARCHAR2(200) := '<<--「拠点変更出力処理」--';
  cv_debug_msg_dis        CONSTANT VARCHAR2(200) := '<<--「廃棄情報出力処理」--';
  cv_debug_msg_copn       CONSTANT VARCHAR2(200) := '<<カーソルをオープンしました >>';
  cv_debug_msg_ccls1      CONSTANT VARCHAR2(200) := '<< カーソルをクローズしました >>';
  cv_debug_msg_ccls2      CONSTANT VARCHAR2(200) := '<< 例外処理内でカーソルをクローズしました >>';
  cv_debug_msg_err1       CONSTANT VARCHAR2(200) := 'file_err_expt';
  cv_debug_msg_err2       CONSTANT VARCHAR2(200) := 'global_api_expt';
  cv_debug_msg_err3       CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err4       CONSTANT VARCHAR2(200) := 'others例外';
  cv_debug_msg_err5       CONSTANT VARCHAR2(200) := 'select_error_expt';
  cv_debug_msg_err6       CONSTANT VARCHAR2(200) := 'global_process_expt';
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gb_rollback_upd_flg    BOOLEAN;                                     -- ロールバック判断
  -- ファイル・ハンドルの宣言
  gf_file_hand    UTL_FILE.FILE_TYPE;
  gt_txn_type_id          csi_txn_types.transaction_type_id%TYPE;        -- 取引タイプID
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- 抽出出力データ
    TYPE g_value_rtype IS RECORD(
      external_reference        csi_item_instances.external_reference%TYPE,      -- 物件コード
      old_head_office_code      fnd_flex_values.ATTRIBUTE7%TYPE,                 -- 旧本部コード
      row_order                 fnd_flex_values.ATTRIBUTE6%TYPE,                 -- 拠点並び順
      sale_base_code            xxcso_cust_accounts_v.sale_base_code%TYPE,       -- 拠点(部門)コード
      jotai_kbn3                VARCHAR2(100),                                   -- 機器状態(廃棄情報)
      haiki_date                VARCHAR2(100),                                   -- 廃棄決裁日
      requisition_line_id       xxcso_requisition_lines_v.requisition_line_id%TYPE, --発注依頼明細ID
      requisition_header_id     xxcso_requisition_lines_v.requisition_header_id%TYPE, -- ログ用発注依頼ヘッダID
      line_num                  xxcso_requisition_lines_v.line_num%TYPE          -- ログ用発注依頼明細番号
    );
  --*** ロック例外 ***
  global_lock_expt        EXCEPTION;                                 -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt,-54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理 (A-1)
   ***********************************************************************************/
  PROCEDURE init(
    od_process_date     OUT NOCOPY DATE,      -- システム日付
    ov_errbuf           OUT NOCOPY VARCHAR2,  -- エラー・メッセージ            --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,  -- リターン・コード              --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'init';             -- プログラム名
--
    cv_false                CONSTANT VARCHAR2(100)   := 'FALSE';             -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    ld_process_date      DATE;    -- システム日付
    lb_check_date_value  BOOLEAN;          -- 日付の書式判断
    lv_format            VARCHAR2(100);    -- 日付書式
    lv_init_msg          VARCHAR2(5000);   -- エラーメッセージを格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 初期化
    lv_format := 'YYYY/MM/DD';
    -- 起動パラメータを出力
    -- パラメータ出力(拠点変更・廃棄情報CSV出力処理区分)
    lv_init_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_01
                    ,iv_token_name1  => cv_tkn_csv_proc_kbn
                    ,iv_token_value1 => gv_csv_process_kbn
                   );
    -- 出力ファイルに出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                  lv_init_msg
    );
    -- パラメータ処理日付
    lv_init_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_19
                    ,iv_token_name1  => cv_tkn_value
                    ,iv_token_value1 => gv_date_value
                   );
    -- 出力ファイルに出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_init_msg || CHR(10) ||
                 ''
    );
    -- 拠点変更・廃棄情報CSV出力処理区分が「’1’廃棄情報出力処理」、
    -- 或いは’「2’拠点変更出力処理」であるかのチェック
    IF (NVL(gv_csv_process_kbn, ' ') <> cv_csv_proc_kbn_1 
          AND NVL(gv_csv_process_kbn, ' ') <> cv_csv_proc_kbn_2) THEN
--
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- アプリケーション短縮名
             ,iv_name         => cv_tkn_number_02            -- メッセージコード
             ,iv_token_name1  => cv_tkn_csv_proc_kbn
             ,iv_token_value1 => gv_csv_process_kbn
      );
      lv_errbuf  := lv_errmsg || SQLERRM;
      RAISE global_api_expt;
--
    END IF;      
    -- パラメータ処理日付が「NULL」であるかのチェック
    IF (gv_date_value IS NOT NULL) THEN
      -- 日付書式チェック
      --取得したパラメータの書式が指定された日付の書式（YYYYMMDD）であるかを確認
      lb_check_date_value := xxcso_util_common_pkg.check_date(
                                    iv_date         => gv_date_value
                                   ,iv_date_format  => lv_format
      );
      --リターンステータスが「FALSE」の場合,例外処理を行う
      IF (lb_check_date_value = cb_false) THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name               -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_20          -- メッセージコード
                        ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                        ,iv_token_value1 => gv_date_value             -- トークン値1パラメータ
                        ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                        ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                        ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                        ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
        );
        lv_errbuf  := lv_errmsg||SQLERRM;
        RAISE global_api_expt;
      END IF;
    END IF;
--
    -- 業務処理日付取得処理 
    ld_process_date := xxccp_common_pkg2.get_process_date; 
    -- *** DEBUG_LOG ***
    -- 取得した業務処理日付をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg4 || CHR(10) ||
                 cv_debug_msg5 || TO_CHAR(ld_process_date,'yyyy/mm/dd hh24:mi:ss') || CHR(10) ||
                 ''
    );
    -- 業務処理日付取得に失敗した場合
    IF (ld_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
              iv_application  => cv_app_name                 -- アプリケーション短縮名
             ,iv_name         => cv_tkn_number_03            -- メッセージコード
      );
      lv_errbuf  := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    od_process_date := ld_process_date;
    fnd_file.put_line(
        which => FND_FILE.LOG
      , buff  => 'od_process_date:' || od_process_date || CHR(10) ||
                 ''
    );

    -- ====================
    -- 取引タイプID取得処理 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id                                    -- トランザクションタイプID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                          -- 取引タイプ
      WHERE  ctt.source_transaction_type  = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_23             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_name             -- トークンコード1
                       ,iv_token_value1 => cv_csi_txn_types             -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- トークンコード2
                       ,iv_token_value2 => cv_src_transaction_type      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_24             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_name             -- トークンコード1
                       ,iv_token_value1 => cv_csi_txn_types             -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type         -- トークンコード2
                       ,iv_token_value2 => cv_src_transaction_type      -- トークン値2
                       ,iv_token_name3  => cv_tkn_err_msg               -- トークンコード3
                       ,iv_token_value3 => SQLERRM                      -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_profile_info
   * Description      : プロファイル値を取得 (A-2)
   ***********************************************************************************/
  PROCEDURE get_profile_info(
    ov_file_dir             OUT NOCOPY VARCHAR2,        -- CSVファイル出力先
    ov_file_name            OUT NOCOPY VARCHAR2,        -- CSVファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100)  := 'get_profile_info';            -- プログラム名
--
      -- インターフェースファイル名トークン名
    cv_file_dir         CONSTANT VARCHAR2(100)  := 'XXCSO1_VM_OUT_CSV_DIR';          -- CSVファイル出力先
    cv_file_name        CONSTANT VARCHAR2(100)  := 'XXCSO1_VM_OUT_CSV_BUKKEN_INFO';  -- CSVファイル名

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
    lv_file_dir       VARCHAR2(2000);             -- CSVファイル出力先
    lv_file_name      VARCHAR2(2000);             -- CSVファイル名
    lv_msg_set        VARCHAR2(1000);             -- メッセージ格納
    lv_value          VARCHAR2(1000);             -- プロファイルオプション値
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- プロファイル値を取得
    -- ===============================
--
    -- 変数初期化処理 
    lv_value := NULL;
--    
    -- CSVファイル出力先の値取得
    fnd_profile.get(
                  cv_file_dir
                 ,lv_file_dir
    );
    -- CSVファイル名の値取得
    fnd_profile.get(
                  cv_file_name
                 ,lv_file_name
    );
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg6 || CHR(10) ||
                 cv_debug_msg7 || lv_file_dir    || CHR(10) ||
                 cv_debug_msg8 || lv_file_name   || CHR(10) ||
                 ''
    );
    --インターフェースファイル名メッセージ出力
    lv_msg_set := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name
                    ,iv_name         => cv_tkn_number_04
                    ,iv_token_name1  => cv_tkn_csv_file_name
                    ,iv_token_value1 => lv_file_name
                   );
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_set ||CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- 戻り値が「NULL」であった場合,例外処理を行う
    IF (lv_file_dir IS NULL) THEN
      -- CSVファイル出力先
      lv_value     := cv_file_dir;
    ELSIF (lv_file_name IS NULL) THEN
      -- CSVファイル名
      lv_value     := cv_file_name;
    END IF;
--
    IF (lv_value IS NOT NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_05         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_prof_name         -- トークンコード1
                        ,iv_token_value1 => lv_value                 -- トークン値1引揚拠点コード
      );
      lv_errbuf  := lv_errmsg||SQLERRM;
      RAISE global_api_expt;    
    END IF;
--
    -- 取得した値をOUTパラメータに設定
    ov_file_dir   := lv_file_dir;       -- CSVファイル出力先
    ov_file_name  := lv_file_name;      -- CSVファイル名
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
   * Description      : CSVファイルオープン (A-3)
   ***********************************************************************************/
  PROCEDURE open_csv_file(
    iv_file_dir             IN  VARCHAR2,               -- CSVファイル出力先
    iv_file_name            IN  VARCHAR2,               -- CSVファイル名
    ov_errbuf               OUT NOCOPY VARCHAR2,        -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT NOCOPY VARCHAR2,        -- リターン・コード             --# 固定 #
    ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'open_csv_file';     -- プログラム名
--
    cv_open_writer          CONSTANT VARCHAR2(100)  := 'W';                 -- 入出力モード

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
    lv_file_dir       VARCHAR2(1000);      -- CSVファイル出力先
    lv_file_name      VARCHAR2(1000);      -- CSVファイル名
    lv_exists         BOOLEAN;             -- 存在チェック結果
    lv_file_length    VARCHAR2(1000);      -- ファイルサイズ
    lv_blocksize      VARCHAR2(1000);      -- ブロックサイズ
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
    -- INパラメータをローカル変数に代入
    lv_file_dir   := iv_file_dir;       -- CSVファイル出力先
    lv_file_name  := iv_file_name;      -- CSVファイル名
    -- ========================
    -- CSVファイル存在チェック 
    -- ========================
    UTL_FILE.FGETATTR(
                  location    => lv_file_dir
                 ,filename    => lv_file_name
                 ,fexists     => lv_exists
                 ,file_length => lv_file_length
                 ,block_size  => lv_blocksize
    );
    --CSVファイルが存在した場合
    IF (lv_exists = cb_true) THEN
      -- CSVファイル残存エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name              -- アプリケーション短縮名
                        ,iv_name         => cv_tkn_number_06         -- メッセージコード
                        ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                        ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                        ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                        ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
      );
      lv_errbuf := lv_errmsg||SQLERRM;
      RAISE file_err_expt;
    END IF;
--    
    -- CSVファイルオープン 
    BEGIN
--
      -- ファイルIDを取得
      gf_file_hand := UTL_FILE.FOPEN(
                           location   => lv_file_dir
                          ,filename   => lv_file_name
                          ,open_mode  => cv_open_writer
      );
      -- *** DEBUG_LOG ***
      -- ファイルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg10    || CHR(10)   ||
                   cv_debug_msg_fnm  || lv_file_name || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.INVALID_PATH       OR       -- ファイルパス不正エラー
           UTL_FILE.INVALID_MODE       OR       -- open_modeパラメータ不正エラー
           UTL_FILE.INVALID_OPERATION  OR       -- オープン不可能エラー
           UTL_FILE.INVALID_MAXLINESIZE  THEN   -- MAX_LINESIZE値無効エラー
        -- CSVファイルオープンエラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name              -- アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_07         -- メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_location      -- トークンコード1
                      ,iv_token_value1 => lv_file_dir              -- トークン値1CSVファイル出力先
                      ,iv_token_name2  => cv_tkn_csv_file_name     -- トークンコード1
                      ,iv_token_value2 => lv_file_name             -- トークン値1CSVファイル名
        );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      -- 取得した値をOUTパラメータに設定
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err4 || cv_msg_part ||
                   cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                   ''
      );
--      
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END open_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : chk_str
   * Description      : 禁則文字チェック (A-6,A-10)
   ***********************************************************************************/
  PROCEDURE chk_str(
    i_get_rec       IN g_value_rtype,                  -- 情報データ
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'chk_str';       -- プログラム名
    cv_sep_com                 CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot               CONSTANT VARCHAR2(3)    := '"';
--
    cv_check_range             CONSTANT  VARCHAR2(30)  := 'VENDING_MACHINE_SYSTEM';
    cv_account_master          CONSTANT VARCHAR2(100)  := '顧客マスタ';
    cv_external_reference      CONSTANT VARCHAR2(100)  := '物件コード';
    cv_old_head_office_code    CONSTANT VARCHAR2(100)  := '旧本部コード';
    cv_row_order               CONSTANT VARCHAR2(100)  := '拠点並び順';
    cv_sale_base_code          CONSTANT VARCHAR2(100)  := '拠点(部門)コード';
    cv_jotai_kbn3              CONSTANT VARCHAR2(100)  := '機器状態(廃棄情報)';
    cv_haiki_date              CONSTANT VARCHAR2(100)  := '廃棄決裁日';
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lb_str_check_flg         BOOLEAN;         -- 禁則文字チェックフラグ
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;            -- 情報データ
    -- *** ローカル例外 ***
    select_error_expt     EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    l_get_rec := i_get_rec;
    -- 禁則文字チェック
    -- 物件コード
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.external_reference, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => cv_external_reference          -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                     ,iv_token_value2 => l_get_rec.external_reference   -- トークン値2
                     ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                     ,iv_token_value3 => cv_check_range                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- 旧本部コード
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.old_head_office_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => cv_old_head_office_code        -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                     ,iv_token_value2 => l_get_rec.old_head_office_code -- トークン値2
                     ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                     ,iv_token_value3 => cv_check_range                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- 拠点並び順
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.row_order, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => cv_row_order                   -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                     ,iv_token_value2 => l_get_rec.row_order            -- トークン値2
                     ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                     ,iv_token_value3 => cv_check_range                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- 拠点(部門)コード
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.sale_base_code, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => cv_sale_base_code              -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                     ,iv_token_value2 => l_get_rec.sale_base_code       -- トークン値2
                     ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                     ,iv_token_value3 => cv_check_range                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- 機器状態3(廃棄情報)
    -- 廃棄決裁日
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.jotai_kbn3, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => cv_jotai_kbn3                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                     ,iv_token_value2 => l_get_rec.jotai_kbn3           -- トークン値2
                     ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                     ,iv_token_value3 => cv_check_range                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
    -- 廃棄決裁日
    lb_str_check_flg := xxccp_common_pkg2.chk_moji(
                         l_get_rec.haiki_date, cv_check_range);
    IF (lb_str_check_flg = FALSE) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                    -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_10               -- メッセージコード
                     ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                     ,iv_token_value1 => cv_haiki_date                  -- トークン値1
                     ,iv_token_name2  => cv_tkn_item_value              -- トークンコード2
                     ,iv_token_value2 => l_get_rec.haiki_date           -- トークン値2
                     ,iv_token_name3  => cv_tkn_check_range             -- トークンコード3
                     ,iv_token_value3 => cv_check_range                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE select_error_expt;
    END IF;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN select_error_expt THEN
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
  END chk_str;
--
  /**********************************************************************************
   * Procedure Name   : update_item_instance
   * Description      : 拠点変更物件マスタ情報更新 (A-7)
   ***********************************************************************************/
  PROCEDURE update_item_instance(
    in_instance_id           IN  csi_item_instances.instance_id%TYPE,           -- インスタンスID
    in_object_version_number IN csi_item_instances.object_version_number%TYPE,  -- オブジェクトバージョン
    iv_external_reference    IN csi_item_instances.external_reference%TYPE,     -- 物件コード
    ov_errbuf       OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode      OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg       OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name                CONSTANT VARCHAR2(100)  := 'update_item_instance';       -- プログラム名
    cn_api_version             CONSTANT NUMBER         := 1.0;
    cv_inst_base_update        CONSTANT VARCHAR2(100)  := '物件マスタ';
    cv_update_process          CONSTANT VARCHAR2(100)  := '更新';
    cv_encoded_f               CONSTANT VARCHAR2(1)    := 'F';  -- FALSE   
--
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_commit                VARCHAR2(1);     -- コミットフラグ
    lv_init_msg_list         VARCHAR2(2000);  -- メッセージリスト
    ln_validation_level        NUMBER;                  -- バリデーションレーベル
    -- API戻り値格納用
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
    lv_io_msg_data             VARCHAR2(5000); 

    -- API入出力レコード値格納用
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
    l_instance_id_lst          csi_datastructures_pub.id_tbl;
--
    -- *** ローカル例外 ***
    update_error_expt          EXCEPTION;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
--
--###########################  固定部 END   ############################
--
    -- インスタンスレコード作成
    l_instance_rec.instance_id                := in_instance_id;               -- インスタンスID
    l_instance_rec.object_version_number      := in_object_version_number;     -- オブジェクトバージョン番号
    l_instance_rec.request_id                 := cn_request_id;                -- REQUEST_ID
    l_instance_rec.program_application_id     := cn_program_application_id;    -- PROGRAM_APPLICATION_ID
    l_instance_rec.program_id                 := cn_program_id;                -- PROGRAM_ID
    l_instance_rec.program_update_date        := cd_program_update_date;       -- PROGRAM_UPDATE_DATE
    l_instance_rec.attribute7                 := TO_CHAR(SYSDATE,'YYYY/MM/DD');
    -- 取引レコードデータ作成
    l_txn_rec.transaction_date                   := SYSDATE;
    l_txn_rec.source_transaction_date            := SYSDATE;
    l_txn_rec.transaction_type_id                := gt_txn_type_id;

    BEGIN
      CSI_ITEM_INSTANCE_PUB.update_item_instance(
         p_api_version           => cn_api_version
        ,p_commit                => lv_commit
        ,p_init_msg_list         => lv_init_msg_list
        ,p_validation_level      => ln_validation_level
        ,p_instance_rec          => l_instance_rec
        ,p_ext_attrib_values_tbl => l_ext_attrib_values_tab
        ,p_party_tbl             => l_party_tab
        ,p_account_tbl           => l_account_tab
        ,p_pricing_attrib_tbl    => l_pricing_attrib_tab
        ,p_org_assignments_tbl   => l_org_assignments_tab
        ,p_asset_assignment_tbl  => l_asset_assignment_tab
        ,p_txn_rec               => l_txn_rec
        ,x_instance_id_lst       => l_instance_id_lst
        ,x_return_status         => lv_return_status
        ,x_msg_count             => ln_msg_count
        ,x_msg_data              => lv_msg_data
      );
      -- 正常終了でない場合
      IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        RAISE update_error_expt;
      END IF;
    EXCEPTION
      -- *** OTHERS例外ハンドラ ***
      WHEN OTHERS THEN
        IF (FND_MSG_PUB.Count_Msg > 0) THEN
          FOR i IN 1..FND_MSG_PUB.Count_Msg LOOP
            FND_MSG_PUB.Get(
               p_msg_index     => i
              ,p_encoded       => cv_encoded_f
              ,p_data          => lv_io_msg_data
              ,p_msg_index_out => ln_io_msg_count
            );
            lv_msg_data := lv_msg_data || lv_io_msg_data;
          END LOOP;
        END IF;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_25              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_inst_base_update           -- トークン値1
                       ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2  => cv_update_process             -- トークン値2
                       ,iv_token_name3   => cv_tkn_bukken                 -- トークンコード3
                       ,iv_token_value3  => iv_external_reference         -- トークン値3
                       ,iv_token_name4   => cv_tkn_err_msg                -- トークンコード4
                       ,iv_token_value4  => lv_msg_data                   -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
    END;
--
  EXCEPTION
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
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
  END update_item_instance;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec
   * Description      : CSVファイル出力 (A-8,A-13)
   ***********************************************************************************/
  PROCEDURE create_csv_rec(
    i_get_rec   IN g_value_rtype,                  -- 情報データ
    ov_errbuf   OUT NOCOPY VARCHAR2,               -- エラー・メッセージ           --# 固定 #
    ov_retcode  OUT NOCOPY VARCHAR2,               -- リターン・コード             --# 固定 #
    ov_errmsg   OUT NOCOPY VARCHAR2                -- ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)  := 'create_csv_rec';       -- プログラム名
    cv_sep_com              CONSTANT VARCHAR2(3)    := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)    := '"';
--
    cv_up_99999             CONSTANT VARCHAR2(50)   := '99999';                -- 更新担当者コード
    cv_up_999999            CONSTANT VARCHAR2(50)   := '999999';               -- 更新部署コード
    cv_up_pro_id            CONSTANT VARCHAR2(50)   := 'BUKKEN_2UD';           -- 更新プログラムID
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--_
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル変数 ***
    lv_data          VARCHAR2(5000);                -- 編集データ
    lv_suc_msg       VARCHAR2(5000);                -- 連携済正常メッセージ
    lt_external_reference  csi_item_instances.external_reference%TYPE;  -- 物件コード
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;                  -- 情報データ
    -- *** ローカル例外 ***
    file_put_line_expt             EXCEPTION;       -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    l_get_rec             := i_get_rec;               -- データを格納するレコード
    lt_external_reference := REPLACE(l_get_rec.external_reference,'-');
--
    BEGIN
--
      --データ作成
      lv_data := cv_sep_wquot || lt_external_reference || cv_sep_wquot             -- 物件コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 機種
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 機番
        || cv_sep_com                                                              -- 機器区分
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- メーカー
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 年式
        || cv_sep_com                                                              -- セレ数
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 特殊機１
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 特殊機２
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 特殊機３
        || cv_sep_com                                                              -- 初回設置日
        || cv_sep_com                                                              -- カウンターNo．
        || cv_sep_com || cv_sep_wquot || l_get_rec.old_head_office_code
        || l_get_rec.row_order || cv_sep_wquot                                     -- 地区コード
        || cv_sep_com || cv_sep_wquot || l_get_rec.sale_base_code || cv_sep_wquot  -- 拠点（部門）コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 作業会社コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 事業所コード
        || cv_sep_com                                                              -- 最終作業伝票No．
        || cv_sep_com                                                              -- 最終作業区分
        || cv_sep_com                                                              -- 最終作業進捗
        || cv_sep_com                                                              -- 最終作業完了予定日
        || cv_sep_com                                                              -- 最終作業完了日
        || cv_sep_com                                                              -- 最終整備内容
        || cv_sep_com                                                              -- 最終設置伝票No．
        || cv_sep_com                                                              -- 最終設置区分
        || cv_sep_com                                                              -- 最終設置予定日
        || cv_sep_com                                                              -- 最終設置進捗
        || cv_sep_com                                                              -- 機器状態１（稼動状態）
        || cv_sep_com                                                              -- 機器状態２（状態詳細）
        || cv_sep_com || SUBSTR(l_get_rec.jotai_kbn3,1,1)                          -- 機器状態３（廃棄情報）
        || cv_sep_com                                                              -- 入庫日
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 引揚会社コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 引揚事業所コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先名
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先担当者名
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先TEL１
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先TEL２
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先TEL３
        || cv_sep_com                                                              -- 設置先郵便番号
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先住所１
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先住所２
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先住所３
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先住所４
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 設置先住所５
        || cv_sep_com || l_get_rec.haiki_date                                      -- 廃棄決裁日
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 転売廃棄業者
        || cv_sep_com                                                              -- 転売廃棄伝票No.
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 所有者
        || cv_sep_com                                                              -- リース開始日
        || cv_sep_com                                                              -- リース料
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 原契約番号
        || cv_sep_com                                                              -- 原契約番号－枝番
        || cv_sep_com                                                              -- 現契約日
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 現契約番号
        || cv_sep_com                                                              -- 現契約番号－枝番
        || cv_sep_com                                                              -- 転売廃棄状況フラグ
        || cv_sep_com                                                              -- 転売完了区分
        || cv_sep_com                                                              -- 削除フラグ
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 作成担当者コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 作成部署コード
        || cv_sep_com || cv_sep_wquot || cv_sep_wquot                              -- 作成プログラムID
        || cv_sep_com || cv_sep_wquot || cv_up_99999 || cv_sep_wquot               -- 更新担当者コード
        || cv_sep_com || cv_sep_wquot || cv_up_999999 || cv_sep_wquot              -- 更新部署コード
        || cv_sep_com || cv_sep_wquot || cv_up_pro_id || cv_sep_wquot              -- 更新プログラムID
        || cv_sep_com                                                              -- 作成日時時分秒
        || cv_sep_com || TO_CHAR(SYSDATE, 'yyyymmddhh24miss')                      -- 更新日時時分秒
      ;
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
        IF (gv_csv_process_kbn = cv_csv_proc_kbn_2) THEN
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                     -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_12                -- メッセージコード
                       ,iv_token_name1  => cv_tkn_bukken                   -- トークンコード1
                       ,iv_token_value1 => l_get_rec.external_reference    -- トークン値1
                       ,iv_token_name2  => cv_tkn_err_msg                  -- トークンコード2
                       ,iv_token_value2 => SQLERRM                         -- トークン値2
                      );
        ELSE
          -- エラーメッセージ取得
          lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                              -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_15                         -- メッセージコード
                       ,iv_token_name1  => cv_tkn_req_line_id                       -- トークンコード1
                       ,iv_token_value1 => TO_CHAR(l_get_rec.requisition_line_id)   -- トークン値1
                       ,iv_token_name2  => cv_tkn_req_header_id                     -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(l_get_rec.requisition_header_id) -- トークン値2
                       ,iv_token_name3  => cv_tkn_line_num                          -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(l_get_rec.line_num)              -- トークン値3
                       ,iv_token_name4  => cv_tkn_err_msg                  -- トークンコード4
                       ,iv_token_value4 => SQLERRM                         -- トークン値4
                      );
        END IF;
        lv_errbuf := lv_errmsg;
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
   * Procedure Name   : update_wk_reqst_tbl
   * Description      : 作業依頼／発注情報処理結果テーブル更新 (A-12)
   ***********************************************************************************/
  PROCEDURE update_wk_reqst_tbl(
     i_get_rec         IN g_value_rtype     -- 抽出出力データ
    ,id_process_date   IN DATE              -- 業務処理日
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ              --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード                --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'update_wk_reqst_tbl';    -- プログラム名
--
    cv_work_ipro_table  CONSTANT VARCHAR2(100) := '作業依頼／発注情報処理結果テーブル';
    cv_process_upd      CONSTANT VARCHAR2(100) := '更新';
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
    ld_process_date  DATE;                                                  -- 業務処理日
    lt_req_line_id   xxcso_requisition_lines_v.requisition_line_id%TYPE;    -- 発注依頼明細ID
    lt_req_header_id       xxcso_requisition_lines_v.requisition_header_id%TYPE; -- ログ用発注依頼ヘッダID
    lt_line_num            xxcso_requisition_lines_v.line_num%TYPE;         -- ログ用発注依頼明細番号
    -- *** ローカル・レコード ***
    l_get_rec       g_value_rtype;                  -- 情報データ
    -- *** ローカル例外 ***
    skip_process_expt             EXCEPTION;       -- データ出力処理例外
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- INパラメータをローカル変数に代入
    l_get_rec        := i_get_rec;                       -- データを格納するレコード
    ld_process_date  := id_process_date;                 -- 業務処理日
    lt_req_line_id   := l_get_rec.requisition_line_id;   -- 発注依頼明細ID
    lt_req_header_id := l_get_rec.requisition_header_id; -- ログ用発注依頼ヘッダID
    lt_line_num      := l_get_rec.line_num;              -- ログ用発注依頼明細番号
--
    BEGIN
      SELECT xwrp.requisition_line_id                    -- 発注依頼明細ID
      INTO lt_req_line_id
      FROM xxcso_wk_requisition_proc xwrp                -- 作業依頼／発注情報処理結果テーブル
      WHERE xwrp.requisition_line_id = lt_req_line_id
      FOR UPDATE NOWAIT
      ;
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_13              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_work_ipro_table            -- トークン値1
                       ,iv_token_name2  => cv_tkn_req_line_id            -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(lt_req_line_id)       -- トークン値2
                       ,iv_token_name3  => cv_tkn_req_header_id          -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(lt_req_header_id)     -- トークン値3
                       ,iv_token_name4  => cv_tkn_line_num               -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(lt_line_num)          -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_21              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_work_ipro_table            -- トークン値1
                       ,iv_token_name2  => cv_tkn_req_line_id            -- トークンコード2
                       ,iv_token_value2 => TO_CHAR(lt_req_line_id)       -- トークン値2
                       ,iv_token_name3  => cv_tkn_req_header_id          -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(lt_req_header_id)     -- トークン値3
                       ,iv_token_name4  => cv_tkn_line_num               -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(lt_line_num)          -- トークン値4
                       ,iv_token_name5  => cv_tkn_err_msg                -- トークンコード5
                       ,iv_token_value5 => SQLERRM                       -- トークン値5
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
    -- 作業依頼／発注情報処理結果テーブルの連携済フラグを更新
    BEGIN

      UPDATE xxcso_wk_requisition_proc                 -- 作業依頼／発注情報処理結果テーブル
      SET    interface_flag         = cv_interface_flag_y        -- 連携済フラグ
           , interface_date         = ld_process_date            -- 連携日
           , last_updated_by        = cn_last_updated_by         -- 最終更新者
           , last_update_date       = cd_last_update_date        -- 最終更新日
           , last_update_login      = cn_last_update_login       -- 最終更新ログイン
           , request_id             = cn_request_id              -- 要求ID
           , program_application_id = cn_program_application_id  -- コンカレント・プログラム・アプリケーションID
           , program_id             = cn_program_id              -- コンカレント・プログラムID
           , program_update_date    = cd_program_update_date     -- プログラム更新日
      WHERE  requisition_line_id = lt_req_line_id
      ;
    EXCEPTION
      -- 更新に失敗した場合の例外
      WHEN OTHERS THEN
        gb_rollback_upd_flg := TRUE;
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_14              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_work_ipro_table            -- トークン値1
                       ,iv_token_name2  => cv_tkn_process                -- トークンコード2
                       ,iv_token_value2 => cv_process_upd                -- トークン値2
                       ,iv_token_name3  => cv_tkn_req_line_id            -- トークンコード3
                       ,iv_token_value3 => TO_CHAR(lt_req_line_id)       -- トークン値3
                       ,iv_token_name4  => cv_tkn_req_header_id          -- トークンコード4
                       ,iv_token_value4 => TO_CHAR(lt_req_header_id)     -- トークン値4
                       ,iv_token_name5  => cv_tkn_line_num               -- トークンコード5
                       ,iv_token_value5 => TO_CHAR(lt_line_num)          -- トークン値5
                       ,iv_token_name6  => cv_tkn_err_msg                -- トークンコード6
                       ,iv_token_value6 => SQLERRM                       -- トークン値6
                     );
        lv_errbuf := lv_errmsg;
        RAISE skip_process_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN skip_process_expt THEN
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
  END update_wk_reqst_tbl;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file
   * Description      : CSVファイルクローズ処理 (A-14)
   ***********************************************************************************/
  PROCEDURE close_csv_file(
     iv_file_dir       IN  VARCHAR2         -- CSVファイル出力先
    ,iv_file_name      IN  VARCHAR2         -- CSVファイル名
    ,ov_errbuf         OUT NOCOPY VARCHAR2  -- エラー・メッセージ              --# 固定 #
    ,ov_retcode        OUT NOCOPY VARCHAR2  -- リターン・コード                --# 固定 #
    ,ov_errmsg         OUT NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ    --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name         CONSTANT VARCHAR2(100) := 'close_csv_file';    -- プログラム名
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
    BEGIN
    -- ====================
    -- CSVファイルクローズ 
    -- ====================
      UTL_FILE.FCLOSE(
        file => gf_file_hand
      );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg11   || CHR(10)   ||
                   cv_debug_msg_fnm || iv_file_name || CHR(10) ||
                   ''
      );
    EXCEPTION
      WHEN UTL_FILE.WRITE_ERROR          OR     -- オペレーティングシステムエラー
           UTL_FILE.INVALID_FILEHANDLE   THEN   -- ファイル・ハンドル無効エラー
        -- エラーメッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                  --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_18             --メッセージコード
                      ,iv_token_name1  => cv_tkn_csv_location          --トークンコード1
                      ,iv_token_value1 => iv_file_dir                  --トークン値1
                      ,iv_token_name2  => cv_tkn_csv_file_name         --トークンコード1
                      ,iv_token_value2 => iv_file_name                 --トークン値1
                     );
        lv_errbuf := lv_errmsg||SQLERRM;
        RAISE file_err_expt;
    END;
--
  EXCEPTION
    -- *** ファイル処理例外ハンドラ ***
    WHEN file_err_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err1 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
      -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err2 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
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
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
--
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || iv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END close_csv_file;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   ***********************************************************************************/
  PROCEDURE submain(
     ov_errbuf           OUT NOCOPY VARCHAR2   -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2   -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2   -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name            CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
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
---- *** ローカル定数 ***
    cv_sep_com              CONSTANT VARCHAR2(3)     := ',';
    cv_sep_wquot            CONSTANT VARCHAR2(3)     := '"';
--
    cv_false                CONSTANT VARCHAR2(100)   := 'FALSE';            -- FALSE
    cv_jotai_kbn3           CONSTANT VARCHAR2(100)   := 'JOTAI_KBN3';       -- 機器状態3(廃棄情報)
    cv_haikikessai_dt       CONSTANT VARCHAR2(100)   := 'HAIKIKESSAI_DT';   -- 廃棄決裁日
    cv_final_format         CONSTANT VARCHAR2(100)   := 'yyyy/mm/dd';       -- 日付書式
--
    cv_bukken_data          CONSTANT VARCHAR2(100)   := '物件マスタ情報';
    cv_work_ipro_data       CONSTANT VARCHAR2(100)   := '廃棄作業依頼情報';
    cv_add_pro_data         CONSTANT VARCHAR2(100)   := '追加属性値';
    cv_bukken_cd            CONSTANT VARCHAR2(100)   := '物件コード:';
    -- *** ローカル変数 ***
    lv_sub_retcode         VARCHAR2(1);                                 -- サーブメイン用リターン・コード
    lv_sub_msg             VARCHAR2(5000);                              -- 警告用メッセージ
    lv_sub_buf             VARCHAR2(5000);                              -- 警告用エラー・メッセージ
    ld_process_date        DATE;                                        -- 業務処理日
    ld_process_date_t      DATE;                                        -- 業務処理日(TRUNC)
    lv_file_dir            VARCHAR2(2000);                              -- CSVファイル出力先
    lv_file_name           VARCHAR2(2000);                              -- CSVファイル名
    lt_instance_id         csi_item_instances.instance_id%TYPE;         -- インスタンスID
    lt_external_reference  csi_item_instances.external_reference%TYPE;  -- 物件コード
    lt_attribute1_cd       csi_item_instances.attribute1%TYPE;          -- 機種
    lt_cust_account_id     xxcso_cust_accounts_v.cust_account_id%TYPE;  -- アカウントID
    lt_sale_base_code      xxcso_cust_accounts_v.sale_base_code%TYPE;   -- 売上拠点コード
    lt_past_sale_base_code xxcso_cust_accounts_v.past_sale_base_code%TYPE; -- 前月売上拠点コード
    lt_old_head_offi_code  fnd_flex_values.ATTRIBUTE7%TYPE;             -- 旧本部コード
    lt_row_order           fnd_flex_values.ATTRIBUTE6%TYPE;             -- 拠点並び順
    lt_object_version_number csi_item_instances.object_version_number%TYPE;-- オブジェクトバージョン
    lt_req_line_id         xxcso_requisition_lines_v.requisition_line_id%TYPE;   --発注依頼明細ID
    lt_req_header_id       xxcso_requisition_lines_v.requisition_header_id%TYPE; -- ログ用発注依頼ヘッダID
    lt_line_num            xxcso_requisition_lines_v.line_num%TYPE;     -- ログ用発注依頼明細番号
    lt_jotai_kbn3          VARCHAR2(2000);                              -- 機器状態3(廃棄情報)
    lt_haiki_date          VARCHAR2(2000);                              -- 廃棄決裁日
    lv_format              VARCHAR2(100);                               -- 日付書式
    lb_check_date_value    BOOLEAN;                                     -- 日付の書式判断
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd          BOOLEAN;
    -- メッセージ出力用
    lv_msg          VARCHAR2(2000);
    -- *** ローカル・カーソル ***
    -- 拠点変更物件マスタ情報抽出
    CURSOR bukken_info_location_data_cur
    IS
      SELECT cii.instance_id instance_id                      -- インスタンスID
            ,cii.external_reference external_reference        -- 物件コード
            ,cii.attribute1 attribute1_cd                     -- 機種
            ,xcav.cust_account_id cust_account_id             -- アカウントID
            ,xcav.sale_base_code sale_base_code               -- 売上拠点コード
            ,xcav.past_sale_base_code past_sale_base_code     -- 前月売上拠点コード
            ,xabv.old_head_office_code old_head_office_code   -- 旧本部コード
            ,xabv.row_order row_order                         -- 拠点並び順
            ,cii.object_version_number object_version_number  -- オブジェクトバージョン
      FROM   csi_item_instances cii                           -- インストールベースマスタ
            ,xxcso_cust_accounts_v xcav                       -- 顧客マスタビュー
            ,xxcso_aff_base_v xabv                            -- AFF部門マスタビュー
      WHERE cii.owner_party_account_id = xcav.cust_account_id
        AND NVL(xcav.sale_base_code, ' ') <> NVL(xcav.past_sale_base_code, ' ')
        AND xcav.sale_base_code = xabv.base_code
        AND NVL(xabv.start_date_active,ld_process_date_t) <= ld_process_date_t
        AND NVL(xabv.end_date_active,ld_process_date_t) >= ld_process_date_t
        AND xcav.account_status = cv_active_status
        AND ((TRUNC(TO_DATE(cii.attribute7, cv_final_format)) = NVL(TRUNC(TO_DATE(gv_date_value, cv_final_format)),
                                                                  TRUNC(TO_DATE(cii.attribute7, cv_final_format)))
             AND gv_date_value IS NOT NULL)
            OR  (gv_date_value IS NULL))
        /* 2009.04.13 K.Satomura T1_0409対応 START */
        AND xcav.past_sale_base_code IS NOT NULL
        /* 2009.04.13 K.Satomura T1_0409対応 END */
        ;
    -- 廃棄作業依頼情報データ抽出
    CURSOR bukken_info_dis_work_data_cur
    IS
      SELECT xrl.requisition_line_id requisition_line_id              -- 発注依頼明細ID
            ,xrl.abolishment_install_code abolishment_install_code    -- 物件コード
            ,cii.instance_id instance_id                              -- インスタンスID
            ,xabv.old_head_office_code old_head_office_code           -- 旧本部コード
            ,xabv.row_order row_order                                 -- 拠点並び順
            ,xcav.sale_base_code sale_base_code                       -- 拠点(部門コード)
            ,xrl.requisition_header_id requisition_header_id          -- ログ用発注依頼ヘッダID
            ,xrl.line_num line_num                                    -- ログ用発注依頼明細番号
      FROM  xxcso_requisition_lines_v   xrl                           -- 発注依頼明細情報ビュー
           ,po_requisition_headers      prh                           -- 発注依頼ヘッダビュー
           ,xxcso_wk_requisition_proc   xwrp                          -- 作業依頼/発注情報処理結果テーブル
           ,csi_item_instances          cii                           -- インストールベースマスタ
           ,xxcso_cust_accounts_v       xcav                          -- 顧客マスタビュー
           ,xxcso_aff_base_v            xabv                          -- AFF部門マスタビュー
      WHERE  xrl.category_kbn IN (cv_disposal_sinsei,cv_disposal_kessai)
         AND xrl.requisition_header_id = prh.requisition_header_id
         AND prh.authorization_status = cv_status_app
         AND xrl.requisition_line_id = xwrp.requisition_line_id 
         AND (xwrp.interface_flag = cv_interface_flag_n
                OR TRUNC(xwrp.interface_date) = TRUNC(TO_DATE(gv_date_value, cv_final_format)))
         AND cii.external_reference = xrl.abolishment_install_code
         AND cii.owner_party_account_id = xcav.cust_account_id
         AND xcav.account_status = cv_active_status
         AND xcav.sale_base_code = xabv.base_code
         AND  NVL(xabv.start_date_active,ld_process_date_t) <= ld_process_date_t
              AND NVL(xabv.end_date_active,ld_process_date_t) >= ld_process_date_t
         AND    (ld_process_date_t between(NVL(xrl.lookup_start_date, ld_process_date_t)) and
                       TRUNC(nvl(xrl.lookup_end_date, ld_process_date_t)))
         AND    (ld_process_date_t between(NVL(xrl.category_start_date, ld_process_date_t)) and
                       TRUNC(NVL(xrl.category_end_date, ld_process_date_t)));
    -- *** ローカル・レコード ***
    l_location_data_cur        bukken_info_location_data_cur%ROWTYPE;       -- 拠点変更物件マスタ情報
    l_dis_work_data_cur        bukken_info_dis_work_data_cur%ROWTYPE;       -- 廃棄作業依頼情報データ
    l_get_rec                  g_value_rtype;
    -- *** ローカル・例外 ***
    select_error_expt   EXCEPTION;
    select_warn_expt    EXCEPTION;
    lv_process_expt     EXCEPTION;
    no_data_expt        EXCEPTION;
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
--
    -- ローカル変数初期化
    gb_rollback_upd_flg := cb_false;
    -- ================================
    -- A-1.初期処理 
    -- ================================
    init(
      od_process_date     => ld_process_date,  -- 業務処理日
      ov_errbuf           => lv_errbuf,        -- エラー・メッセージ            --# 固定 #
      ov_retcode          => lv_retcode,       -- リターン・コード              --# 固定 #
      ov_errmsg           => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    ); 
    ld_process_date_t := TRUNC(ld_process_date);
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-2.プロファイル値を取得 
    -- =================================================
    get_profile_info(
       ov_file_dir    => lv_file_dir    -- CSVファイル出力先
      ,ov_file_name   => lv_file_name   -- CSVファイル名
      ,ov_errbuf      => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode     => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg      => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- =================================================
    -- A-5.CSVファイルオープン 
    -- =================================================
--
    open_csv_file(
       iv_file_dir  => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name => lv_file_name  -- CSVファイル名
      ,ov_errbuf    => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode   => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg    => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    IF (gv_csv_process_kbn = cv_csv_proc_kbn_1) THEN  -- 廃棄情報出力処理
--
      -- =================================================
      -- A-9.廃棄作業依頼情報データ抽出
      -- =================================================
--
      -- カーソルオープン
      OPEN bukken_info_dis_work_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn || CHR(10) ||
                   ''
      );
--
      <<get_disposal_data_loop>>
      LOOP
--
        BEGIN
          FETCH bukken_info_dis_work_data_cur INTO l_dis_work_data_cur;
        EXCEPTION
          WHEN OTHERS THEN
            -- データ抽出エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- アプリケーション短縮名
                                ,iv_name         => cv_tkn_number_08          -- メッセージコード
                                ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                                ,iv_token_value1 => cv_work_ipro_data         -- トークン値1
                                ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                                ,iv_token_value2 => SQLERRM                   -- トークン値2
                );
            lv_errbuf  := lv_errmsg||SQLERRM;
            RAISE global_process_expt;
        END;
--
        BEGIN
          -- データ初期化
          lv_sub_msg := NULL;
          lv_sub_buf := NULL;
          -- レコード変数初期化
          l_get_rec         := NULL;
          -- 処理対象件数格納
          gn_target_cnt := bukken_info_dis_work_data_cur%ROWCOUNT;
          -- 対象件数がO件の場合
          EXIT WHEN bukken_info_dis_work_data_cur%NOTFOUND
          OR  bukken_info_dis_work_data_cur%ROWCOUNT = 0;
          -- 取得データをローカル変数に格納
          lt_req_line_id        := l_dis_work_data_cur.requisition_line_id;      -- 発注依頼明細ID
          lt_external_reference := l_dis_work_data_cur.abolishment_install_code; -- 物件コード
          lt_instance_id        := l_dis_work_data_cur.instance_id;              -- インスタンスID
          lt_old_head_offi_code := l_dis_work_data_cur.old_head_office_code;     -- 旧本部コード
          lt_row_order          := l_dis_work_data_cur.row_order;                -- 拠点並び順
          lt_sale_base_code     := l_dis_work_data_cur.sale_base_code;           -- 拠点(部門)コード
          lt_req_header_id      := l_dis_work_data_cur.requisition_header_id;
            -- ログ用発注依頼ヘッダID
          lt_line_num            := l_dis_work_data_cur.line_num;            -- ログ用発注依頼明細番号
          -- 機器状態3(廃棄情報)と廃棄決裁日の追加属性値を抽出
          -- 機器状態3(廃棄情報)
          lt_jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- インスタンスID
                             ,iv_attribute_code => cv_jotai_kbn3            -- 属性コード
          );
--
          lv_format := 'YYYY/MM/DD';
          -- 廃棄決裁日
          lt_haiki_date := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- インスタンスID
                             ,iv_attribute_code => cv_haikikessai_dt        -- 属性コード
          );
          IF (lt_haiki_date IS NOT NULL) THEN
            --取得したパラメータの書式が指定された日付の書式（YYYYMMDD）であるかを確認
            lb_check_date_value := xxcso_util_common_pkg.check_date(
                                          iv_date         => lt_haiki_date
                                         ,iv_date_format  => lv_format
            );
            --リターンステータスが「FALSE」の場合,例外処理を行う
            IF (lb_check_date_value = cb_false) THEN
              lv_sub_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_20          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                              ,iv_token_value1 => lt_haiki_date             -- トークン値1パラメータ
                              ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                              ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                              ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                              ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
              );
              lv_sub_msg  := lv_sub_msg||cv_bukken_cd||lt_external_reference;
              lv_sub_buf  := lv_sub_msg;
              RAISE select_warn_expt;
            END IF;
            lt_haiki_date := TO_CHAR(TO_DATE(lt_haiki_date,'yyyy/mm/dd'), 'yyyymmdd');
          END IF;
-- DEBUG
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => '機器状態３(廃棄情報)：' || lt_jotai_kbn3 ||CHR(10) ||
                   '廃棄決裁日：' || lt_haiki_date ||
                   ''
      );             
-- DEBUG
--
          -- 取得データを抽出出力データに格納
          l_get_rec.external_reference    := lt_external_reference;      -- 物件コード
          l_get_rec.old_head_office_code  := lt_old_head_offi_code;      -- 旧本部コード
          l_get_rec.row_order             := lt_row_order;               -- 拠点並び順
          l_get_rec.sale_base_code        := lt_sale_base_code;          -- 拠点(部門)コード
          l_get_rec.jotai_kbn3            := lt_jotai_kbn3;              -- 機器状態3(廃棄情報)
          l_get_rec.haiki_date            := lt_haiki_date;              -- 廃棄決裁日
          l_get_rec.requisition_line_id   := lt_req_line_id;             -- 発注依頼明細ID
          l_get_rec.requisition_header_id := lt_req_header_id;           -- ログ用発注依頼ヘッダID
          l_get_rec.line_num              := lt_line_num;                -- ログ用発注依頼明細番号
          
--
          -- ================================================================
          -- A-10 禁則文字チェック
          -- ================================================================
          chk_str(
             i_get_rec        => l_get_rec        -- 抽出出力データ
            ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- ================================================================
          -- A-11 セーブポイント(廃棄作業依頼情報連携失敗)発行
          -- ================================================================
          SAVEPOINT bukken_info_disposal_work;
--
          -- ================================================================
          -- A-12 作業依頼／発注情報処理結果テーブル更新
          -- ================================================================
          update_wk_reqst_tbl(
             i_get_rec        => l_get_rec         -- 抽出出力データ
            ,id_process_date  => ld_process_date   -- 業務処理日
            ,ov_errbuf        => lv_sub_buf        -- エラー・メッセージ          --# 固定 #
            ,ov_retcode       => lv_sub_retcode    -- リターン・コード            --# 固定 #
            ,ov_errmsg        => lv_sub_msg        -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- ================================================================
          -- A-13 廃棄作業依頼情報データCSV出力
          -- ================================================================
--
          create_csv_rec(
             i_get_rec        => l_get_rec        -- 拠点変更物件マスタ情報
            ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ    --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            gb_rollback_upd_flg := TRUE;
            RAISE select_warn_expt;
          END IF;
--
          -- 出力に成功した場合
          lv_sub_msg :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_17              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_req_line_id            -- トークンコード1
                           ,iv_token_value1 => TO_CHAR(lt_req_line_id)       -- トークン値1
                           ,iv_token_name2  => cv_tkn_req_header_id          -- トークンコード2
                           ,iv_token_value2 => TO_CHAR(lt_req_header_id)     -- トークン値2
                           ,iv_token_name3  => cv_tkn_line_num               -- トークンコード3
                           ,iv_token_value3 => TO_CHAR(lt_line_num)          -- トークン値3
                          );
          -- 出力に出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg
          );
          -- ログに出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_msg 
          );
--          
          --成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** データ抽出時の警告例外ハンドラ ***
          WHEN select_warn_expt THEN
            --エラー件数カウント
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            --警告出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_sub_msg                  --ユーザー・エラーメッセージ
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf 
            );
            -- ロールバック
            IF gb_rollback_upd_flg = TRUE THEN
              ROLLBACK TO SAVEPOINT bukken_info_disposal_work;          -- ROLLBACK
              gb_rollback_upd_flg := FALSE;
              -- ログ出力
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => '' || CHR(10) ||cv_debug_msg12|| CHR(10) || ''
              );
            END IF;
          -- *** スキップ例外OTHERSハンドラ ***
          WHEN OTHERS THEN
            --エラー件数カウント
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf ||SQLERRM
            );
            -- ロールバック
            IF gb_rollback_upd_flg = TRUE THEN
              ROLLBACK TO SAVEPOINT bukken_info_disposal_work;          -- ROLLBACK
              gb_rollback_upd_flg := FALSE;
              -- ログ出力
              fnd_file.put_line(
                 which  => FND_FILE.LOG
                ,buff   => '' || CHR(10) ||cv_debug_msg12|| CHR(10) || ''
              );
            END IF;
        END;
      END LOOP get_locaton_data_loop;
--
      -- カーソルクローズ
      CLOSE bukken_info_dis_work_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                   ''
      );
--
    ELSIF (gv_csv_process_kbn = cv_csv_proc_kbn_2) THEN -- 拠点変更出力処理
--
      -- =================================================
      -- A-5.拠点変更物件マスタ情報抽出
      -- =================================================
--
      -- カーソルオープン
      OPEN bukken_info_location_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルオープンしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_copn || CHR(10) ||
                   ''
      );
--
      <<get_locaton_data_loop>>
      LOOP
--
        BEGIN
          FETCH bukken_info_location_data_cur INTO l_location_data_cur;
        EXCEPTION
          WHEN OTHERS THEN
            -- データ抽出エラーメッセージ
            lv_errmsg := xxccp_common_pkg.get_msg(
                                 iv_application  => cv_app_name               -- アプリケーション短縮名
                                ,iv_name         => cv_tkn_number_08          -- メッセージコード
                                ,iv_token_name1  => cv_tkn_table              -- トークンコード1
                                ,iv_token_value1 => cv_bukken_data            -- トークン値1
                                ,iv_token_name2  => cv_tkn_err_msg            -- トークンコード2
                                ,iv_token_value2 => SQLERRM                   -- トークン値2
                );
            lv_errbuf  := lv_errmsg||SQLERRM;
            RAISE global_process_expt;
        END;
--
        BEGIN
          -- データ初期化
          lv_sub_msg := NULL;
          lv_sub_buf := NULL;
          -- レコード変数初期化
          l_get_rec         := NULL;
          -- 処理対象件数格納
          gn_target_cnt := bukken_info_location_data_cur%ROWCOUNT;
          -- 対象件数がO件の場合
          EXIT WHEN bukken_info_location_data_cur%NOTFOUND
          OR  bukken_info_location_data_cur%ROWCOUNT = 0;
          -- 取得データをローカル変数に格納
          lt_instance_id         := l_location_data_cur.instance_id;            -- インスタンスID
          lt_external_reference  := l_location_data_cur.external_reference;     -- 物件コード
          lt_attribute1_cd       := l_location_data_cur.attribute1_cd;          -- 機種
          lt_cust_account_id     := l_location_data_cur.cust_account_id;        -- アカウントID
          lt_sale_base_code      := l_location_data_cur.sale_base_code;         -- 売上拠点コード
          lt_past_sale_base_code := l_location_data_cur.past_sale_base_code;    -- 前月売上拠点コ
          lt_old_head_offi_code  := l_location_data_cur.old_head_office_code;   -- 旧本部コード
          lt_row_order           := l_location_data_cur.row_order;              -- 拠点並び順
          lt_object_version_number := l_location_data_cur.object_version_number;-- オブジェクトバージョン
          -- 機器状態3(廃棄情報)と廃棄決裁日の追加属性値を抽出
          -- 機器状態3(廃棄情報)
          lt_jotai_kbn3 := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- インスタンスID
                             ,iv_attribute_code => cv_jotai_kbn3            -- 属性コード
          );
--
          -- 廃棄決裁日
          lv_format     := 'YYYY/MM/DD';
          lt_haiki_date := xxcso_ib_common_pkg.get_ib_ext_attribs2(
                              in_instance_id    => lt_instance_id           -- インスタンスID
                             ,iv_attribute_code => cv_haikikessai_dt        -- 属性コード
          );
--          
          IF (lt_haiki_date IS NOT NULL) THEN
            --取得したパラメータの書式が指定された日付の書式（YYYYMMDD）であるかを確認
            lb_check_date_value := xxcso_util_common_pkg.check_date(
                                          iv_date         => lt_haiki_date
                                         ,iv_date_format  => lv_format
            );
            --リターンステータスが「FALSE」の場合,例外処理を行う
            IF (lb_check_date_value = FALSE) THEN
              lv_sub_msg := xxccp_common_pkg.get_msg(
                               iv_application  => cv_app_name               -- アプリケーション短縮名
                              ,iv_name         => cv_tkn_number_20          -- メッセージコード
                              ,iv_token_name1  => cv_tkn_value              -- トークンコード1
                              ,iv_token_value1 => lt_haiki_date             -- トークン値1パラメータ
                              ,iv_token_name2  => cv_tkn_status             -- トークンコード2
                              ,iv_token_value2 => cv_false                  -- トークン値2リターンステータス
                              ,iv_token_name3  => cv_tkn_message            -- トークンコード3
                              ,iv_token_value3 => NULL                      -- トークン値3リターンメッセージ
              );
              lv_sub_msg  := lv_sub_msg||cv_bukken_cd||lt_external_reference;
              lv_sub_buf  := lv_sub_msg;
              RAISE select_warn_expt;
            END IF;
            lt_haiki_date := TO_CHAR(TO_DATE(lt_haiki_date,'yyyy/mm/dd'), 'yyyymmdd');
          END IF;
--
          -- 取得データを抽出出力データに格納
          l_get_rec.external_reference   := lt_external_reference;      -- 物件コード
          l_get_rec.old_head_office_code := lt_old_head_offi_code;      -- 旧本部コード
          l_get_rec.row_order            := lt_row_order;               -- 拠点並び順
          l_get_rec.sale_base_code       := lt_sale_base_code;          -- 拠点(部門)コード
          l_get_rec.jotai_kbn3           := lt_jotai_kbn3;              -- 機器状態(廃棄情報)
          l_get_rec.haiki_date           := lt_haiki_date;              -- 廃棄決裁日
--
          -- ================================================================
          -- A-6 禁則文字チェック
          -- ================================================================
          chk_str(
             i_get_rec        => l_get_rec        -- 抽出出力データ
            ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- ================================================================
          -- A-7 拠点変更物件マスタ情報更新
          -- ================================================================
          -- セーブポイント設定(更新失敗用)
          --
          SAVEPOINT item_proc_up;
          update_item_instance(
             in_instance_id           => lt_instance_id            -- インスタンスID
            ,in_object_version_number => lt_object_version_number  -- オブジェクトバージョン
            ,iv_external_reference    => lt_external_reference     -- 物件コード
            ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            ROLLBACK TO SAVEPOINT item_proc_up;          -- ROLLBACK
            -- ログ出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
               ,buff   => '' || CHR(10) ||cv_debug_msg12|| CHR(10) || ''
            );
            RAISE select_warn_expt;
          END IF;

--
          -- ================================================================
          -- A-8 拠点変更物件マスタ情報CSV出力
          -- ================================================================
--
          create_csv_rec(
             i_get_rec        => l_get_rec        -- 拠点変更物件マスタ情報
            ,ov_errbuf        => lv_sub_buf       -- エラー・メッセージ            --# 固定 #
            ,ov_retcode       => lv_sub_retcode   -- リターン・コード              --# 固定 #
            ,ov_errmsg        => lv_sub_msg       -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_sub_retcode = cv_status_error) THEN
            RAISE select_warn_expt;
          END IF;
--
          -- 出力に成功した場合
          lv_sub_msg :=  xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name                   -- アプリケーション短縮名
                           ,iv_name         => cv_tkn_number_16              -- メッセージコード
                           ,iv_token_name1  => cv_tkn_bukken                 -- トークンコード1
                           ,iv_token_value1 => l_get_rec.external_reference  -- トークン値1
                          );
          -- 出力に出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_sub_msg
          );
          -- ログに出力
          fnd_file.put_line(
             which  => FND_FILE.LOG
            ,buff   => cv_pkg_name||cv_msg_cont||
                       cv_prg_name||cv_msg_part||
                       lv_sub_msg 
          );
--          
          --成功件数カウント
          gn_normal_cnt := gn_normal_cnt + 1;
--
        EXCEPTION
          -- *** データ抽出時の警告例外ハンドラ ***
          WHEN select_warn_expt THEN
            --エラー件数カウント
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            --警告出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_sub_msg                  --ユーザー・エラーメッセージ
            );
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf 
            );
          -- *** データ抽出時の警告例外ハンドラ ***
          WHEN OTHERS THEN
            --エラー件数カウント
            gn_error_cnt  := gn_error_cnt + 1;
            --
            lv_sub_retcode := cv_status_warn;
            ov_retcode     := lv_sub_retcode;
            --警告出力
            fnd_file.put_line(
               which  => FND_FILE.LOG
              ,buff   => cv_pkg_name||cv_msg_cont||
                         cv_prg_name||cv_msg_part||
                         lv_sub_buf 
            );
        END;
      END LOOP get_locaton_data_loop;
--
      -- カーソルクローズ
      CLOSE bukken_info_location_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls1 || CHR(10) ||
                   ''
      );
--
    END IF;
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_22             --メッセージコード
                   );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                        -- ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- エラーメッセージ
          );
    END IF;
--
    -- ========================================
    -- A-14.CSVファイルクローズ  
    -- ========================================
--
    close_csv_file(
       iv_file_dir   => lv_file_dir   -- CSVファイル出力先
      ,iv_file_name  => lv_file_name  -- CSVファイル名
      ,ov_errbuf     => lv_errbuf     -- エラー・メッセージ            --# 固定 #
      ,ov_retcode    => lv_retcode    -- リターン・コード              --# 固定 #
      ,ov_errmsg     => lv_errmsg     -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE select_error_expt;
    END IF;
--
  EXCEPTION
    -- *** ロールバックがある例外ハンドラ ***
    WHEN select_error_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err5 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      -- 廃棄情報出力処理
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err5 || CHR(10) ||
                     ''
       );
      END IF;
      -- 拠点変更出力処理
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err5 || CHR(10) ||
                     ''
       );
      END IF;
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,4000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      -- 廃棄情報出力処理
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
                     ''
       );
      END IF;
      -- 拠点変更出力処理
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err6 || CHR(10) ||
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
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      -- 廃棄情報出力処理
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                     ''
        );
      END IF;
      -- 拠点変更出力処理
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err3 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      lb_fopn_retcd := UTL_FILE.IS_OPEN (
                         file =>gf_file_hand
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file =>gf_file_hand
        );
        -- *** DEBUG_LOG ***
        -- ファイルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_fcls || CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || cv_msg_part ||
                     cv_debug_msg_fnm  || lv_file_name   || CHR(10) ||
                     ''
        );
      END IF;
      -- カーソルがクローズされていない場合
      -- 廃棄情報出力処理
      IF (bukken_info_location_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_location_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_dis || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
                     ''
        );
      END IF;
      -- 拠点変更出力処理
      IF (bukken_info_dis_work_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE bukken_info_dis_work_data_cur;
        -- *** DEBUG_LOG ***
        -- カーソルクローズしたことをログ出力
        fnd_file.put_line(
           which  => FND_FILE.LOG
          ,buff   => cv_debug_msg_location || CHR(10) ||
                     cv_debug_msg_ccls2|| CHR(10) ||
                     cv_prg_name       || cv_msg_part ||
                     cv_debug_msg_err4 || CHR(10) ||
                     ''
        );
      END IF;
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf              OUT NOCOPY VARCHAR2         -- エラーメッセージ #固定#
   ,retcode             OUT NOCOPY VARCHAR2         -- エラーコード     #固定#
   ,iv_csv_process_kbn  IN VARCHAR2                 -- 拠点変更・廃棄情報CSV出力処理区分
   ,iv_date_value       IN VARCHAR2                 -- 処理日付
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
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了
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
    -- INパラメータを代入
    gv_csv_process_kbn := iv_csv_process_kbn;               -- 拠点変更・廃棄情報CSV出力処理区分
    gv_date_value      := iv_date_value     ;               -- 処理日付
    --
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       ov_errbuf   => lv_errbuf          -- エラー・メッセージ            --# 固定 #
      ,ov_retcode  => lv_retcode         -- リターン・コード              --# 固定 #
      ,ov_errmsg   => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
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
    -- A-10.終了処理 
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
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
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
END XXCSO015A04C;
/
