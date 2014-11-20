CREATE OR REPLACE PACKAGE BODY APPS.XXCSO012A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO012A03C(body)
 * Description      : ファイルアップロードIFに取込まれた自動販売機更新データにて
 *                    物件マスタ情報(IB)を更新します。
 * MD.050           : 自動販売機データ更新 <MD050_CSO_012_A03>
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理 (A-1)
 *  get_item_instances     ファイルアップロードデータ抽出 (A-2)
 *  chk_data_layout        レイアウトチェック処理 (A-3)
 *  chk_data_exist         存在チェック処理 (A-4)
 *  update_item_instances  物件データ更新処理 (A-5)
 *  rock_file_interface    ファイルデータロック処理 (A-6)
 *  delete_file_interface  ファイルデータ削除処理 (A-7)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                         終了処理 (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2014/09/16    1.0   Taketo Oda       新規作成
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
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
  cv_pkg_name               CONSTANT VARCHAR2(100) := 'XXCSO012A03C';      -- パッケージ名
  cv_app_name               CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  -- メッセージコード
  cv_tkn_number_32          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00518';  -- データ抽出0件メッセージ
  cv_tkn_number_33          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00271';  -- ファイルID出力
  cv_tkn_number_34          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00275';  -- フォーマットパターン出力
  cv_tkn_number_61          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00256';  -- パラメータNullエラー
  cv_tkn_number_02          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_tkn_number_35          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00274';  -- アップロードファイル名称取得エラー
  cv_tkn_number_36          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00276';  -- アップロードファイル名称出力
  cv_tkn_number_10          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00100';  -- 取引タイプID取得エラー
  cv_tkn_number_11          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00101';  -- 取引タイプID抽出エラー
  cv_tkn_number_12          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00103';  -- 追加属性ID抽出エラー
  cv_tkn_number_49          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00278';  -- データロックエラー
  cv_tkn_number_40          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00554';  -- BLOB変換エラー
  cv_tkn_number_39          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00152';  -- アップロードファイル名称出力
  cv_tkn_number_41          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00181';  -- 必須チェックエラー
  cv_tkn_number_45          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00118';  -- データ抽出、登録警告メッセージ
  cv_tkn_number_48          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00270';  -- データ削除エラー
  cv_tkn_number_51          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00550';  -- CSVデータフォーマットエラー
  cv_tkn_number_53          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00662';  -- 申告地
  cv_tkn_number_56          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00031';  -- 存在エラー
  cv_tkn_number_58          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00681';  -- 値セット ：
  cv_tkn_number_59          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00670';  -- リース区分
  cv_tkn_number_60          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00696';  -- 物件コード
  cv_tkn_number_62          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00051';  -- 物件存在チェック警告メッセージ
  cv_tkn_number_63          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00710';  -- 固定資産チェックエラー
  cv_tkn_number_64          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00711';  -- 取引タイプの取引タイプID
  cv_tkn_number_65          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00712';  -- 設置機器拡張属性定義情報の追加属性ID
  cv_tkn_number_66          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00713';  -- 自動販売機更新データ
  cv_tkn_number_67          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00676';  -- ファイルアップロードIF
  cv_tkn_number_68          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00704';  -- ロック
  cv_tkn_number_69          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00714';  -- 物件マスタ
  cv_tkn_number_70          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00703';  -- 更新
  cv_tkn_number_71          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00715';  -- 抽出
  cv_tkn_number_72          CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00716';  -- エラー：
  cv_target_rec_msg         CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000';  -- 対象件数メッセージ
  cv_success_rec_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001';  -- 成功件数メッセージ
  cv_error_rec_msg          CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002';  -- エラー件数メッセージ
  cv_normal_msg             CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004';  -- 正常終了メッセージ
  cv_error_msg              CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006';  -- エラー終了全ロールバック
--
  -- トークンコード
  cv_tkn_file_id            CONSTANT VARCHAR2(20)  := 'FILE_ID';
  cv_tkn_format             CONSTANT VARCHAR2(20)  := 'FORMAT_PATTERN';
  cv_tkn_prof_nm            CONSTANT VARCHAR2(20)  := 'PROF_NAME';
  cv_tkn_upload             CONSTANT VARCHAR2(20)  := 'UPLOAD_FILE_NAME';
  cv_tkn_src_tran_type      CONSTANT VARCHAR2(20)  := 'SRC_TRAN_TYPE';
  cv_tkn_task_nm            CONSTANT VARCHAR2(20)  := 'TASK_NAME';
  cv_tkn_errmsg             CONSTANT VARCHAR2(20)  := 'ERR_MSG';
  cv_tkn_attribute_name     CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_NAME';
  cv_tkn_attribute_code     CONSTANT VARCHAR2(20)  := 'ADD_ATTRIBUTE_CODE';
  cv_tkn_value_set_name     CONSTANT VARCHAR2(20)  := 'VALUE_SET_NAME';
  cv_tkn_table              CONSTANT VARCHAR2(20)  := 'TABLE';
  cv_tkn_csv_upload         CONSTANT VARCHAR2(20)  := 'CSV_FILE_NAME';
  cv_tkn_item               CONSTANT VARCHAR2(20)  := 'ITEM';
  cv_tkn_base_value         CONSTANT VARCHAR2(20)  := 'BASE_VALUE';
  cv_tkn_process            CONSTANT VARCHAR2(20)  := 'PROCESS';
  cv_tkn_bukken             CONSTANT VARCHAR2(20)  := 'BUKKEN';
  cv_tkn_lookup_type_name   CONSTANT VARCHAR2(20)  := 'LOOKUP_TYPE_NAME';
  cv_cnt_token              CONSTANT VARCHAR2(10)  := 'COUNT';             -- 件数メッセージ用トークン名
--
  cv_encoded_f              CONSTANT VARCHAR2(1)   := 'F';                 -- FALSE
--
  cv_msg_conm               CONSTANT VARCHAR2(1)   := ',';                 -- カンマ
--
  cv_hyphen                 CONSTANT VARCHAR2(1)   := '-';                 -- ハイフン
  -- 値セット
  cv_xxcff_dclr_place       CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';  -- 申告地
  -- 参照タイプ
  cv_xxcso1_lease_kbn       CONSTANT VARCHAR2(30)  := 'XXCSO1_LEASE_KBN';  -- リース区分
  --
  cv_fixed_assets           CONSTANT VARCHAR2(1)   := '4';                 -- リース区分「固定資産」
  cv_y                      CONSTANT VARCHAR2(1)   := 'Y';                 -- 有効フラグY
  ct_language               CONSTANT fnd_flex_values_tl.language%TYPE := USERENV('LANG'); -- 言語
  -- リース区分
  cv_lease_kbn              CONSTANT VARCHAR2(100) := 'LEASE_KBN';
  -- 申告地
  cv_dclr_place             CONSTANT VARCHAR2(100) := 'DCLR_PLACE';
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gt_txn_type_id            csi_txn_types.transaction_type_id%TYPE;        -- 取引タイプID
  gd_process_date           DATE;                                          -- 業務日付
  gv_file_name              VARCHAR2(1000);                                -- 入力ファイル名
  gt_instance_id            csi_item_instances.instance_id%TYPE;           -- 物件ID
  gt_object_version_number  csi_item_instances.object_version_number%TYPE; -- オブジェクトバージョン番号
  gt_lease_kbn              csi_iea_values.attribute_value%TYPE;           -- リース区分
--
  -- 追加属性ID格納用レコード型定義
  TYPE gr_ib_ext_attribs_id_rtype IS RECORD(
     lease_kbn              NUMBER                  -- リース区分
    ,dclr_place             NUMBER                  -- 申告地
  );
  -- 追加属性ID格納用レコード変数
  gr_ext_attribs_id_rec     gr_ib_ext_attribs_id_rtype;
--
  --BLOBデータ格納配列
  gr_file_data_tbl          xxccp_common_pkg2.g_file_data_tbl;
--
  --BLOBデータ分割データ格納
  TYPE gr_blob_data_rtype IS RECORD(
    object_code             VARCHAR2(10)            -- 物件コード
   ,dclr_place              VARCHAR2(5)             -- 申告地
  );
  gr_blob_data gr_blob_data_rtype;
--  
  -- *** ユーザー定義グローバル例外 ***
  global_lock_expt          EXCEPTION;              -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     in_file_id           IN  NUMBER                -- ファイルID
    ,iv_format            IN  VARCHAR2              -- フォーマットパターン
    ,ov_errbuf            OUT NOCOPY VARCHAR2       -- エラー・メッセージ           --# 固定 #
    ,ov_retcode           OUT NOCOPY VARCHAR2       -- リターン・コード             --# 固定 #
    ,ov_errmsg            OUT NOCOPY VARCHAR2)      -- ユーザー・エラー・メッセージ --# 固定 #
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
    -- *** ローカル定数 ***
    -- アプリケーション短縮名
    cv_appl_short_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
    -- ファイルアップロード名称
    cv_xxcso1_file_name       CONSTANT VARCHAR2(30)  := 'XXCCP1_FILE_UPLOAD_OBJ';
    -- ソーストランザクションタイプ
    cv_src_transaction_type   CONSTANT VARCHAR2(30)  := 'IB_UI';
    -- ファイルアップロードコード
    cv_xxcso1_file_code       CONSTANT VARCHAR2(30)  := '680';
--
    -- *** ローカル変数 ***
    -- 業務処理日
    ld_process_date           DATE;
    -- コンカレント入力パラメータなしメッセージ格納用
    lv_noprm_msg              VARCHAR2(5000);  
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value              VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg                    VARCHAR2(5000);
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
    -- 入力パラメータメッセージ出力
    -- ============================
    --ファイルID
    lv_noprm_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_33           --メッセージコード
                       ,iv_token_name1  => cv_tkn_file_id
                       ,iv_token_value1 => in_file_id
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg
    );
--
    --フォーマットパターン
    lv_noprm_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  --アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_34             --メッセージコード
                     ,iv_token_name1  => cv_tkn_format
                     ,iv_token_value1 => iv_format
                    );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
    -- ==========================
    -- 入力パラメータ必須チェック
    -- ==========================
    --ファイルID
    IF (in_file_id IS NULL) THEN
      -- =================================
      -- 入力パラメータなしメッセージ出力(異常終了させること) 
      -- =================================
      lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name         --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_61    --メッセージコード
                      );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- =====================
    -- 業務処理日付取得処理 
    -- =====================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    -- 業務処理日付取得に失敗した場合
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                   --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_02              --メッセージコード
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    ld_process_date :=TRUNC(gd_process_date);
--
    -- =================================
    -- ファイルアップロード名称取得処理 
    -- =================================
    BEGIN
      SELECT flvv.meaning    meaning  -- ファイルアップロード名称
      INTO   gv_file_name
      FROM   fnd_lookup_values_vl  flvv  -- 参照タイプ
      WHERE  flvv.lookup_type      = cv_xxcso1_file_name
      AND    flvv.lookup_code      = cv_xxcso1_file_code
      AND    flvv.enabled_flag     = cv_y
      AND    NVL(flvv.start_date_active, ld_process_date) <= ld_process_date
      AND    NVL(flvv.end_date_active,   ld_process_date) >= ld_process_date
      ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_35           -- メッセージコード
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    --取得したファイルアップロード名称をファイル出力
    lv_noprm_msg  := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                 --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_36            --メッセージコード
                      ,iv_token_name1  => cv_tkn_upload
                      ,iv_token_value1 => gv_file_name
                     );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_noprm_msg || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- ====================
    -- 取引タイプID取得処理 
    -- ====================
    BEGIN
      SELECT ctt.transaction_type_id    transaction_type_id       -- トランザクションタイプID
      INTO   gt_txn_type_id
      FROM   csi_txn_types ctt                                    -- 取引タイプ
      WHERE  ctt.source_transaction_type = cv_src_transaction_type
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- データが存在しない場合
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_10           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_number_64           -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type       -- トークンコード2
                       ,iv_token_value2 => cv_src_transaction_type    -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
        -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_11           -- メッセージコード
                       ,iv_token_name1  => cv_tkn_task_nm             -- トークンコード1
                       ,iv_token_value1 => cv_tkn_number_64           -- トークン値1
                       ,iv_token_name2  => cv_tkn_src_tran_type       -- トークンコード2
                       ,iv_token_value2 => cv_src_transaction_type    -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg              -- トークンコード3
                       ,iv_token_value3 => SQLERRM                    -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ====================
    -- 追加属性ID取得処理 
    -- ====================
    -- 初期化
    gr_ext_attribs_id_rec := NULL;
--
    -- 追加属性ID(リース区分)
    gr_ext_attribs_id_rec.lease_kbn := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                          cv_lease_kbn
                                         ,ld_process_date);
    IF (gr_ext_attribs_id_rec.lease_kbn IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_tkn_number_65             -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_tkn_number_59             -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_lease_kbn                 -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
    -- 追加属性ID(申告地)
    gr_ext_attribs_id_rec.dclr_place := xxcso_ib_common_pkg.get_ib_ext_attribs_id(
                                           cv_dclr_place
                                          ,ld_process_date
                                        );
    IF ( gr_ext_attribs_id_rec.dclr_place IS NULL ) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                  -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_12             -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm               -- トークンコード1
                     ,iv_token_value1 => cv_tkn_number_65             -- トークン値1
                     ,iv_token_name2  => cv_tkn_attribute_name        -- トークンコード2
                     ,iv_token_value2 => cv_tkn_number_53             -- トークン値2
                     ,iv_token_name3  => cv_tkn_attribute_code        -- トークンコード3
                     ,iv_token_value3 => cv_dclr_place                -- トークン値3
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--    
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_item_instances
   * Description      : ファイルアップロードデータ抽出 (A-2)
   ***********************************************************************************/
  PROCEDURE get_item_instances(
     in_file_id              IN     NUMBER                  -- ファイルID
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_item_instances'; -- プログラム名
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
    lv_file_name             xxccp_mrp_file_ul_interface.file_name%TYPE;  -- CSVファイル名
    lv_msg                   VARCHAR2(5000);
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
    -- ***************************************************
    -- 1.CSVファイル名取得
    -- ***************************************************
    SELECT xciwd.file_name  file_name  -- ファイル名
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface    xciwd
    WHERE  xciwd.file_id = in_file_id
    ;
--
    --取得したCSVファイル名をメッセージ出力
    lv_msg   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  --アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_39             --メッセージコード
                       ,iv_token_name1  => cv_tkn_csv_upload
                       ,iv_token_value1 => lv_file_name
                      );
    --メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                 lv_msg       || CHR(10) ||
                 ''                           -- 空行の挿入
    );
--
    -- ***************************************************
    -- 2.BLOBデータ変換
    -- ***************************************************
    --共通アップロードデータ変換処理
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- ファイルＩＤ
      ,ov_file_data => gr_file_data_tbl -- 変換後VARCHAR2データ
      ,ov_retcode   => lv_retcode
      ,ov_errbuf    => lv_errbuf
      ,ov_errmsg    => lv_errmsg
    );
    --
    IF (lv_retcode <> cv_status_normal) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_40,    -- メッセージ：データ変換エラー
                     cv_tkn_table,
                     cv_tkn_number_67,
                     cv_tkn_file_id,
                     in_file_id,
                     cv_tkn_errmsg,
                     SQLERRM);
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
  EXCEPTION
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
  END get_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_layout
   * Description      : レイアウトチェック (A-3)
   ***********************************************************************************/
  PROCEDURE chk_data_layout(
     it_blob_data            IN     xxccp_common_pkg2.g_file_data_tbl                  -- blobデータ(行単位)
    ,in_data_num             IN     NUMBER                  -- 配列番号
    ,ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_layout'; -- プログラム名
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
    cn_format_col_cnt        CONSTANT NUMBER := 2;  -- 項目数
--
    -- *** ローカル変数 ***
    lb_ret                   BOOLEAN;
    lb_format_flag           BOOLEAN := TRUE;
    lv_tmp                   VARCHAR2(2000);
    ln_pos                   NUMBER;
    ln_cnt                   NUMBER := 1;
    lv_msg                   VARCHAR2(5000);
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
    -- ***************************************************
    -- 1.項目数取得
    -- ***************************************************
    IF (it_blob_data(in_data_num) IS NULL) THEN
      lb_format_flag := FALSE;
    END IF;
--
    IF lb_format_flag THEN
      lv_tmp := it_blob_data(in_data_num);
      LOOP
        ln_pos := INSTR(lv_tmp, cv_msg_conm);
        IF ((ln_pos IS NULL) OR (ln_pos = 0)) THEN
          EXIT;
        ELSE
          ln_cnt := ln_cnt + 1;
          lv_tmp := SUBSTR(lv_tmp, ln_pos + 1);
          ln_pos := 0;
        END IF;
      END LOOP;
    END IF;
--
    -- 1.項目数チェック
    IF ((lb_format_flag = FALSE) OR (ln_cnt <> cn_format_col_cnt)) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name                -- アプリケーション短縮名
                     ,iv_name         => cv_tkn_number_51           -- メッセージコード
                     ,iv_token_name1  => cv_tkn_task_nm             -- トークンコード1
                     ,iv_token_value1 => cv_tkn_number_66           -- トークン値1
                     ,iv_token_name2  => cv_tkn_base_value          -- トークンコード1
                     ,iv_token_value2 => it_blob_data(in_data_num)  -- トークン値1
                   );
      lv_errbuf  := lv_errmsg;
      RAISE global_process_expt;
    END IF;

    -- ***************************************************
    -- 2.blobデータ分割、3.必須チェック
    -- ***************************************************
    --物件コード
    gr_blob_data.object_code := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,1);
    IF (gr_blob_data.object_code IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_tkn_number_60,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --申告地
    gr_blob_data.dclr_place := xxccp_common_pkg.char_delim_partition(it_blob_data(in_data_num)
                                                                     ,cv_msg_conm
                                                                     ,2);
    IF (gr_blob_data.dclr_place IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                     cv_app_name,         -- アプリケーション短縮名：XXCSO
                     cv_tkn_number_41,
                     cv_tkn_item,
                     cv_tkn_number_53,
                     cv_tkn_base_value,
                     it_blob_data(in_data_num)
                     );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END chk_data_layout;
--
  /**********************************************************************************
   * Procedure Name   : chk_data_exist
   * Description      : 存在チェック (A-4)
   ***********************************************************************************/
  PROCEDURE chk_data_exist(
     ov_errbuf               OUT    NOCOPY VARCHAR2  -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2  -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2  -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'chk_data_exist'; -- プログラム名
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
    ln_cnt                   NUMBER;
    lv_msg                   VARCHAR2(5000);
    lv_msg2                  VARCHAR2(5000);
    lb_ret                   BOOLEAN DEFAULT TRUE;
    lt_dclr_place            fnd_flex_values.flex_value%TYPE;   -- 申告地
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
    -- ***************************************************
    -- 1.物件コード存在チェック
    -- ***************************************************
    BEGIN
      SELECT cii.instance_id             instance_id            -- インスタンスID
            ,cii.object_version_number   object_version_number  -- オブジェクトバージョン番号
            ,civ.attribute_value         attribute_value        -- リース区分
      INTO   gt_instance_id
            ,gt_object_version_number
            ,gt_lease_kbn
      FROM   csi_item_instances         cii
            ,csi_i_extended_attribs     ciea
            ,csi_iea_values             civ
      WHERE  cii.external_reference = gr_blob_data.object_code
      AND    cii.instance_id        = civ.instance_id(+)
      AND    ciea.attribute_code    = cv_lease_kbn
      AND    ciea.attribute_id      = civ.attribute_id
      ;
--
    EXCEPTION
      -- 更新対象の物件コードがインストールベースに存在しない場合
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_62              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_bukken                 -- トークンコード1
                       ,iv_token_value1  => gr_blob_data.object_code      -- トークン値1
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
--
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45              -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1  => cv_tkn_number_69              -- トークン値1
                       ,iv_token_name2   => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2  => SQLERRM                       -- トークン値2
                       ,iv_token_name3   => cv_tkn_process                -- トークンコード3
                       ,iv_token_value3  => cv_tkn_number_71              -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.dclr_place             -- トークン値4
        );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
      -- 更新対象の物件情報のリース区分が固定資産でない場合
    IF gt_lease_kbn <> cv_fixed_assets THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application   => cv_app_name                   -- アプリケーション短縮名
                    ,iv_name          => cv_tkn_number_63              -- メッセージコード
                    ,iv_token_name1   => cv_tkn_bukken                 -- トークンコード1
                    ,iv_token_value1  => gr_blob_data.object_code      -- トークン値1
                    ,iv_token_name2   => cv_tkn_base_value             -- トークンコード2
                    ,iv_token_value2  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.dclr_place             -- トークン値2
      );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
  -- ***************************************************
  -- 2.申告地マスタ存在チェック
  -- ***************************************************
    --
    -- 申告地のマスタチェック
    BEGIN
      SELECT ffv.flex_value       flex_value
      INTO   lt_dclr_place
      FROM   fnd_flex_values      ffv
            ,fnd_flex_values_tl   ffvt
            ,fnd_flex_value_sets  ffvs
      WHERE  ffv.flex_value_id        = ffvt.flex_value_id
      AND    ffv.flex_value_set_id    = ffvs.flex_value_set_id
      AND    ffvs.flex_value_set_name = cv_xxcff_dclr_place
      AND    gd_process_date BETWEEN NVL(ffv.start_date_active, gd_process_date)
                             AND     NVL(ffv.end_date_active, gd_process_date)
      AND    ffv.enabled_flag         = cv_y
      AND    ffvt.language            = ct_language
      AND    ffv.flex_value           = gr_blob_data.dclr_place
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        lv_msg    := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_53               -- メッセージ
                     );
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_58               -- メッセージ
                       ,iv_token_name1  => cv_tkn_value_set_name          -- トークンコード1
                       ,iv_token_value1 => cv_xxcff_dclr_place            -- トークン値1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_56               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_item                    -- トークンコード1
                       ,iv_token_value1 => lv_msg                         -- トークン値1
                       ,iv_token_name2  => cv_tkn_table                   -- トークンコード2
                       ,iv_token_value2 => lv_msg2                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_base_value              -- トークンコード3
                       ,iv_token_value3 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.dclr_place        -- トークン値3
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合
      WHEN OTHERS THEN
        lv_msg2   := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_58               -- メッセージ
                       ,iv_token_name1  => cv_tkn_value_set_name          -- トークンコード1
                       ,iv_token_value1 => cv_xxcff_dclr_place            -- トークン値1
                     );
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                    -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_45               -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                   -- トークンコード1
                       ,iv_token_value1 => lv_msg2                        -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                  -- トークンコード2
                       ,iv_token_value2 => SQLERRM                        -- トークン値2
                       ,iv_token_name3  => cv_tkn_process                 -- トークンコード3
                       ,iv_token_value3 => cv_tkn_number_71               -- トークン値3
                       ,iv_token_name4  => cv_tkn_base_value              -- トークンコード4
                       ,iv_token_value4 => gr_blob_data.object_code || cv_msg_conm ||
                                           gr_blob_data.dclr_place     -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END chk_data_exist;
--
  /**********************************************************************************
   * Procedure Name   : update_item_instances
   * Description      : 物件データ更新処理 (A-5)
   ***********************************************************************************/
  PROCEDURE update_item_instances(
     ov_errbuf               OUT    NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT    NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT    NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_item_instances'; -- プログラム名
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
    cn_api_version             CONSTANT NUMBER        := 1.0;
--
    -- *** ローカル変数 ***
    ln_validation_level        NUMBER;                  -- バリデーションレーベル
    lv_commit                  VARCHAR2(1);             -- コミットフラグ
    lv_init_msg_list           VARCHAR2(2000);          -- メッセージリスト
--
    -- API戻り値格納用
    lv_return_status           VARCHAR2(1);
    lv_msg_data                VARCHAR2(5000);
    lv_io_msg_data             VARCHAR2(5000); 
    ln_msg_count               NUMBER;
    ln_io_msg_count            NUMBER;
--
    -- API入出力レコード値格納用
    l_txn_rec                  csi_datastructures_pub.transaction_rec;
    l_instance_rec             csi_datastructures_pub.instance_rec;
    l_party_tab                csi_datastructures_pub.party_tbl;
    l_account_tab              csi_datastructures_pub.party_account_tbl;
    l_pricing_attrib_tab       csi_datastructures_pub.pricing_attribs_tbl;
    l_org_assignments_tab      csi_datastructures_pub.organization_units_tbl;
    l_asset_assignment_tab     csi_datastructures_pub.instance_asset_tbl;
    l_ext_attrib_values_tab    csi_datastructures_pub.extend_attrib_values_tbl;
    l_ext_attrib_rec           csi_iea_values%ROWTYPE;
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
--
--###########################  固定部 END   ############################
    -- データの格納
    lv_commit             := fnd_api.g_false;
    lv_init_msg_list      := fnd_api.g_true;
--
    -- ================================
    -- 1.インスタンスレコード作成
    -- ================================
    l_instance_rec.instance_id              := gt_instance_id;              -- 物件ID
    l_instance_rec.object_version_number    := gt_object_version_number;    -- オブジェクトバージョン番号
--
    -- ==================================
    -- 2.登録用設置機器拡張属性値情報作成
    -- ==================================
    -- 申告地
    l_ext_attrib_rec := xxcso_ib_common_pkg.get_ib_ext_attrib_info2(gt_instance_id, cv_dclr_place);
    l_ext_attrib_values_tab(0).attribute_value_id    := l_ext_attrib_rec.attribute_value_id;
    l_ext_attrib_values_tab(0).attribute_value       := gr_blob_data.dclr_place;
    l_ext_attrib_values_tab(0).instance_id           := gt_instance_id;
    l_ext_attrib_values_tab(0).object_version_number := l_ext_attrib_rec.object_version_number;
--
    -- ===============================
    -- 3.取引レコードデータ作成
    -- ===============================
--
    l_txn_rec.transaction_date              := SYSDATE;
    l_txn_rec.source_transaction_date       := SYSDATE;
    l_txn_rec.transaction_type_id           := gt_txn_type_id;
--
    -- =================================
    -- 4.標準APIより、物件更新処理を行う
    -- =================================
--
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
--
    -- 正常終了でない場合
    IF (lv_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
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
        lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application   => cv_app_name                   -- アプリケーション短縮名
                     ,iv_name          => cv_tkn_number_45              -- メッセージコード
                     ,iv_token_name1   => cv_tkn_table                  -- トークンコード1
                     ,iv_token_value1  => cv_tkn_number_69              -- トークン値1
                     ,iv_token_name2   => cv_tkn_process                -- トークンコード2
                     ,iv_token_value2  => cv_tkn_number_70              -- トークン値2
                     ,iv_token_name3   => cv_tkn_errmsg                 -- トークンコード3
                     ,iv_token_value3  => lv_msg_data                   -- トークン値3
                     ,iv_token_name4   => cv_tkn_base_value             -- トークンコード4
                     ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||
                                          gr_blob_data.dclr_place       -- トークン値4
                   );
        lv_errbuf := lv_errmsg;
        RAISE update_error_expt;
      END IF;
    END IF;
--
  EXCEPTION
    -- *** 更新失敗例外ハンドラ ***
    WHEN update_error_expt THEN
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => ''           || CHR(10) ||   -- 空行の挿入
                   XXCCP_COMMON_PKG.GET_MSG(    -- "エラー："
                        IV_APPLICATION   => 'XXCSO'              -- アプリケーション短縮名
                       ,IV_NAME          => 'APP-XXCSO1-00716')  -- メッセージコード
                   ||lv_errmsg|| CHR(10) ||
                   ''                           -- 空行の挿入
      );
--
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
  END update_item_instances;
--
  /**********************************************************************************
   * Procedure Name   : rock_file_interface
   * Description      : ファイルデータロック処理 (A-6)
   ***********************************************************************************/
  PROCEDURE rock_file_interface(
     in_file_id              IN  NUMBER                  -- ファイルID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'rock_file_interface'; -- プログラム名
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
    -- *** ローカル・レコード ***
    CURSOR rock_interface_cur IS
      SELECT xmfui.file_id    file_id
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
--
    rock_interface_rec rock_interface_cur%ROWTYPE;
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
    -- ファイルアップロードIF抽出
    BEGIN
--
      OPEN rock_interface_cur;
      FETCH rock_interface_cur INTO rock_interface_rec;
      CLOSE rock_interface_cur;
--
    EXCEPTION
      -- ロック失敗した場合の例外
      WHEN global_lock_expt THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                   -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_49              -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                  -- トークンコード1
                       ,iv_token_value1 => cv_tkn_number_67              -- トークン値1
                       ,iv_token_name2  => cv_tkn_errmsg                 -- トークンコード2
                       ,iv_token_value2 => SQLERRM                       -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      -- 抽出に失敗した場合の例外
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application   => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name          => cv_tkn_number_45             -- メッセージコード
                       ,iv_token_name1   => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1  => cv_tkn_number_67             -- トークン値1
                       ,iv_token_name2   => cv_tkn_process               -- トークンコード2
                       ,iv_token_value2  => cv_tkn_number_68             -- トークン値2
                       ,iv_token_name3   => cv_tkn_errmsg                -- トークンコード3
                       ,iv_token_value3  => SQLERRM                      -- トークン値3
                       ,iv_token_name4   => cv_tkn_base_value            -- トークンコード4
                       ,iv_token_value4  => gr_blob_data.object_code||cv_msg_conm||gr_blob_data.dclr_place   -- トークン値4
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END rock_file_interface;
--
   /**********************************************************************************
   * Procedure Name   : delete_file_interface
   * Description      : ファイルデータ削除(A-7)
   ***********************************************************************************/
  PROCEDURE delete_file_interface(
     in_file_id              IN  NUMBER                  -- ファイルID
    ,ov_errbuf               OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode              OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg               OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_interface';  -- プログラム名
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
    -- *** ローカル・例外 ***
    delete_error_expt        EXCEPTION;
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
      -- ==========================================
      -- ファイルデータ削除処理 
      -- ==========================================
      DELETE
      FROM   xxccp_mrp_file_ul_interface  xmfui                  -- ファイルアップロードIF
      WHERE  xmfui.file_id = in_file_id
      ;
--
    EXCEPTION
      -- 削除に失敗した場合
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name                  -- アプリケーション短縮名
                       ,iv_name         => cv_tkn_number_48             -- メッセージコード
                       ,iv_token_name1  => cv_tkn_table                 -- トークンコード1
                       ,iv_token_value1 => cv_tkn_number_67             -- トークン値1
                       ,iv_token_name2  => cv_tkn_file_id               -- トークンコード2
                       ,iv_token_value2 => in_file_id                   -- トークン値2
                       ,iv_token_name3  => cv_tkn_errmsg                -- トークンコード2
                       ,iv_token_value3 => SQLERRM                      -- トークン値2
                     );
        lv_errbuf := lv_errmsg;
        RAISE delete_error_expt;
    END;
--
  EXCEPTION
--
    -- *** データ更新例外ハンドラ ***
    WHEN delete_error_expt THEN  
      ov_errmsg  := lv_errmsg;      
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理例外ハンドラ ***
    WHEN global_process_expt THEN
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
  END delete_file_interface;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2,     --   ユーザー・エラー・メッセージ --# 固定 #
    in_file_id    IN  NUMBER,       --   ファイルID
    iv_format     IN  VARCHAR2)     --   フォーマットパターン
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
    lv_errbuf      VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);     -- リターン・コード
    lv_sub_retcode VARCHAR2(1);     -- サーブリターン・コード
    lv_errmsg      VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
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
    -- *** ローカル・レコード ***
--
    -- *** ローカル例外 ***
    skip_process_expt       EXCEPTION;
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
--
    -- ================================
    -- A-1.初期処理 
    -- ================================
--
    init(
       in_file_id            => in_file_id          -- ファイルID
      ,iv_format             => iv_format           -- フォーマットパターン
      ,ov_errbuf             => lv_errbuf           -- エラー・メッセージ            --# 固定 #
      ,ov_retcode            => lv_retcode          -- リターン・コード              --# 固定 #
      ,ov_errmsg             => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-2.ファイルアップロードデータ抽出処理
    -- ========================================
    get_item_instances(
       in_file_id       => in_file_id     -- ファイルID
      ,ov_errbuf        => lv_errbuf      -- エラー・メッセージ            --# 固定 #
      ,ov_retcode       => lv_retcode     -- リターン・コード              --# 固定 #
      ,ov_errmsg        => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 処理対象件数格納
    gn_target_cnt := gr_file_data_tbl.COUNT;
--
    FOR i IN gr_file_data_tbl.FIRST..gr_file_data_tbl.LAST LOOP
      -- ===========================
      -- A-3.レイアウトチェック処理
      -- ===========================
      chk_data_layout(
        it_blob_data => gr_file_data_tbl
       ,in_data_num  => i
       ,ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ===========================
      -- A-4.存在チェック処理
      -- ===========================
    -- グローバル変数の初期化
      gt_instance_id := NULL;
      gt_object_version_number := NULL;
      gt_lease_kbn  := NULL;
--
      chk_data_exist(
        ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- ========================================
      -- A-5.物件データ更新処理
      -- ========================================
      update_item_instances(
        ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
--
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
--
      -- 正常件数カウントアップ
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP;
--
    -- 処理対象件数が0件の場合
    IF (gn_target_cnt = 0) THEN
      -- エラーメッセージ取得
      lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_app_name                  --アプリケーション短縮名
                    ,iv_name         => cv_tkn_number_32             --メッセージコード
                   );
      -- メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg                                         -- ユーザー・エラーメッセージ
      );
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_pkg_name||cv_msg_cont||
                   cv_prg_name||cv_msg_part||
                   lv_errmsg                                         -- エラーメッセージ
      );
--     
    ELSE
      -- ========================================
      -- A-6.ファイルデータロック処理
      -- ========================================
      rock_file_interface(
        in_file_id   => in_file_id     -- ファイルID
       ,ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
  --
      -- ========================================
      -- A-7.ファイルデータ削除処理
      -- ========================================
      delete_file_interface(
        in_file_id   => in_file_id     -- ファイルID
       ,ov_errbuf    => lv_errbuf      -- エラー・メッセージ            --# 固定 #
       ,ov_retcode   => lv_retcode     -- リターン・コード              --# 固定 #
       ,ov_errmsg    => lv_errmsg      -- ユーザー・エラー・メッセージ  --# 固定 #
      );
  --
      IF (lv_retcode <> cv_status_normal) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
--
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
--
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
      ov_retcode := cv_status_error;
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
--
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
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
    errbuf        OUT  NOCOPY  VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT  NOCOPY  VARCHAR2,      --   リターン・コード    --# 固定 #
    in_file_id    IN   NUMBER,                --   ファイルID
    iv_format     IN   VARCHAR2               --   フォーマットパターン
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
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
      ov_errbuf   => lv_errbuf,           -- エラー・メッセージ            --# 固定 #
      ov_retcode  => lv_retcode,          -- リターン・コード              --# 固定 #
      ov_errmsg   => lv_errmsg,           -- ユーザー・エラー・メッセージ  --# 固定 #
      in_file_id  => in_file_id,          -- ファイルID
      iv_format   => iv_format            -- ファイルフォーマット
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
      -- 対象件数初期化
      gn_target_cnt := 0;
      -- 成功件数初期化
      gn_normal_cnt := 0;
      -- エラー件数の取得
      gn_error_cnt  := 1;
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
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
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
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM||lv_errbuf;
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
END XXCSO012A03C;
/
