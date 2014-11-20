CREATE OR REPLACE PACKAGE BODY APPS.XXCSO011A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A04C(body)
 * Description      : 発注明細搬送のDFFを更新します。
 * MD.050           : 発注更新アップロード (MD050_CSO_011A04)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  get_upload_data        ファイルアップロードIFデータ抽出(A-2)
 *  business_data_check    データ内容チェック(A-3)
 *  update_distributions   発注明細搬送DFF更新(A-4)
 *  delete_file_ul_if      ファイルアップロードIFデータ削除(A-5)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2014/05/08    1.0   Kazuyuki Kiriu   新規作成
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
  -- ユーザー定義例外
  -- ===============================
  global_lock_expt          EXCEPTION;  -- ロック例外
--
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name                       CONSTANT VARCHAR2(100) := 'XXCSO011A04C';      -- パッケージ名
--
  cv_app_name                       CONSTANT VARCHAR2(5)   := 'XXCSO';             -- アプリケーション短縮名
--
  --メッセージ
  cv_msg_file_id                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00271';  -- ファイルID
  cv_msg_fmt_ptn                    CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00275';  -- フォーマットパターン
  cv_msg_param_required             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00325';  -- パラメータ必須エラー
  cv_msg_param_nm_file_id           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00673';  -- ファイルID(メッセージ文字列)
  cv_msg_err_param_valuel           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00252';  -- パラメータ妥当性チェックエラー
  cv_msg_param_nm_fmt_ptn           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00674';  -- フォーマットパターン(メッセージ文字列)
  cv_msg_err_get_proc_date          CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00011';  -- 業務処理日付取得エラー
  cv_msg_err_get_org_id             CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00014';  -- プロファイル取得エラー
  cv_msg_err_get_data_ul            CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00274';  -- ファイルアップロード名称抽出エラー
  cv_msg_file_ul_name               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00276';  -- ファイルアップロード名称
  cv_msg_file_name                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00152';  -- CSVファイル名
  cv_msg_err_get_lock               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00278';  -- ロックエラー
  cv_msg_nm_file_ul_if              CONSTANT VARCHAR2(50)  := 'APP-XXCSO1-00676';  -- ファイルアップロードIF(メッセージ文字列)
  cv_msg_err_get_data               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00554';  -- データ抽出エラー
  cv_msg_err_no_data                CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00399';  -- 対象件数0件メッセージ
  cv_msg_err_file_fmt               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00677';  -- CSV項目数エラー
  cv_msg_no_target                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00679';  -- 更新対象なしエラー
  cv_msg_not_found                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00683';  -- 存在チェックエラー
  cv_msg_dclr_place                 CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00662';  -- 申告地(メッセージ文字列)
  cv_msg_lease_kbn                  CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00670';  -- リース区分(メッセージ文字列)
  cv_msg_price                      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00684';  -- 取得価格エラー
  cv_msg_update_error               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00337';  -- 更新エラー
  cv_msg_po_distributions           CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00685';  -- 発注明細搬送(メッセージ文字列)
  cv_msg_po_distributions_lock      CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00686';  -- ロックエラー（発注搬送明細)
  cv_msg_err_del_data               CONSTANT VARCHAR2(30)  := 'APP-XXCSO1-00270';  -- データ削除エラー
  --トークン
  cv_tkn_file_id                    CONSTANT VARCHAR2(30)  := 'FILE_ID';
  cv_tkn_fmt_ptn                    CONSTANT VARCHAR2(30)  := 'FORMAT_PATTERN';
  cv_tkn_param_name                 CONSTANT VARCHAR2(30)  := 'PARAM_NAME';
  cv_tkn_prof_name                  CONSTANT VARCHAR2(30)  := 'PROF_NAME';
  cv_tkn_item                       CONSTANT VARCHAR2(30)  := 'ITEM';
  cv_tkn_file_ul_name               CONSTANT VARCHAR2(30)  := 'UPLOAD_FILE_NAME';
  cv_tkn_file_name                  CONSTANT VARCHAR2(30)  := 'CSV_FILE_NAME';
  cv_tkn_table                      CONSTANT VARCHAR2(30)  := 'TABLE';
  cv_tkn_err_msg                    CONSTANT VARCHAR2(30)  := 'ERR_MSG';
  cv_tkn_index                      CONSTANT VARCHAR2(30)  := 'INDEX';
  cv_tkn_po_num                     CONSTANT VARCHAR2(30)  := 'PO_NUM';
  cv_tkn_po_line_num                CONSTANT VARCHAR2(30)  := 'PO_LINE_NUM';
  cv_tkn_po_rec_num                 CONSTANT VARCHAR2(30)  := 'PO_REQ_NUM';
  cv_tkn_po_rec_line_num            CONSTANT VARCHAR2(30)  := 'PO_REQ_LINE_NUM';
  cv_tkn_action                     CONSTANT VARCHAR2(30)  := 'ACTION';
  cv_tkn_error_msg                  CONSTANT VARCHAR2(30)  := 'ERROR_MESSAGE';
  --プロファイル
  cv_org_id                         CONSTANT VARCHAR2(30)  := 'ORG_ID';                     --営業単位
  --参照タイプ
  cv_lkup_file_ul_obj               CONSTANT VARCHAR2(50)  := 'XXCCP1_FILE_UPLOAD_OBJ';     -- ファイルアップロードOBJ
  cv_lkup_lease_kbn                 CONSTANT VARCHAR2(50)  := 'XXCSO1_LEASE_KBN';           -- リース区分
  -- 値セット名
  cv_flex_dclr_place                CONSTANT VARCHAR2(30)  := 'XXCFF_DCLR_PLACE';           -- 申告地
  --CSVファイルの項目位置(使用しないものも宣言)
  cn_col_pos_po_num                 CONSTANT NUMBER        := 1;   -- 発注番号
  cn_col_pos_po_line_num            CONSTANT NUMBER        := 2;   -- 発注明細
  cn_col_pos_req_num                CONSTANT NUMBER        := 3;   -- 購買依頼番号
  cn_col_pos_req_line_num           CONSTANT NUMBER        := 4;   -- 購買依頼明細番号
  cn_col_pos_machine                CONSTANT NUMBER        := 5;   -- 機種
  cn_col_pos_machine_lease_type     CONSTANT NUMBER        := 6;   -- 機種リース区分
  cn_col_pos_machine_lease_nm       CONSTANT NUMBER        := 7;   -- 機種リース区分名
  cn_col_pos_usually_price          CONSTANT NUMBER        := 8;   -- 標準取得価格
  cn_col_pos_customer_code          CONSTANT NUMBER        := 9;   -- 設置先顧客
  cn_col_pos_customer_name          CONSTANT NUMBER        := 10;  -- 設置先顧客名
  cn_col_pos_customer_site          CONSTANT NUMBER        := 11;  -- 設置先住所
  cn_col_pos_lease_type             CONSTANT NUMBER        := 12;  -- リース区分
  cn_col_pos_lease_nm               CONSTANT NUMBER        := 13;  -- リース区分名
  cn_col_pos_price                  CONSTANT NUMBER        := 14;  -- 取得価格
  cn_col_pos_dclr_place             CONSTANT NUMBER        := 15;  -- 申告地コード
  cn_col_pos_dclr_place_nm          CONSTANT NUMBER        := 16;  -- 申告地
  --その他CSV関連
  cn_csv_file_col_num               CONSTANT NUMBER        := 16;  -- CSVファイル項目数
  cn_header_rec                     CONSTANT NUMBER        := 1;   -- CSVファイルヘッダ行
  cv_price_num                      CONSTANT NUMBER        := 10;  -- 取得価格の桁数
  cv_col_separator                  CONSTANT VARCHAR2(1)   := ','; -- 項目区切文字
  cv_dqu                            CONSTANT VARCHAR2(1)   := '"'; -- 文字列括り
--
  --汎用固定値
  cv_yes                            CONSTANT VARCHAR2(1)   := 'Y';             -- 汎用Y
  cv_no                             CONSTANT VARCHAR2(1)   := 'N';             -- 汎用N
  cv_language                       CONSTANT VARCHAR2(2)   := USERENV('LANG'); -- LANGAGE
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- アップロードデータ分割取得用
  TYPE gt_col_data_ttype  IS TABLE OF VARCHAR(2000)     INDEX BY BINARY_INTEGER;                    -- 1次元配列(項目)
  TYPE gt_rec_data_ttype  IS TABLE OF gt_col_data_ttype INDEX BY BINARY_INTEGER;                    -- 2次元配列(列)(項目)
  --発注明細搬送更新用
  TYPE g_row_id_ttype     IS TABLE OF ROWID INDEX BY BINARY_INTEGER;                                -- 発注明細搬送ROWID
  TYPE g_lease_kbn_ttype  IS TABLE OF po_distributions_all.attribute1%TYPE INDEX BY BINARY_INTEGER; -- リース区分
  TYPE g_price_ttype      IS TABLE OF po_distributions_all.attribute2%TYPE INDEX BY BINARY_INTEGER; -- 取得価格
  TYPE g_dclr_place_ttype IS TABLE OF po_distributions_all.attribute3%TYPE INDEX BY BINARY_INTEGER; -- 申告地
--
  gt_row_id_tab     g_row_id_ttype;      -- 発注明細搬送ROWID(BULK更新用)
  gt_lease_kbn_tab  g_lease_kbn_ttype;   -- リース区分(BULK更新用)
  gt_price_ttype    g_price_ttype;       -- 取得価格(BULK更新用)
  gt_dclr_place     g_dclr_place_ttype;  -- 申告地(BULK更新用)
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  gn_org_id        NUMBER;  -- 営業単位
  gd_process_date  DATE;    -- 業務処理日付
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_file_id    IN  VARCHAR2     -- 1.ファイル名
    ,iv_fmt_ptn    IN  VARCHAR2     -- 2.フォーマットパターン
    ,on_file_id    OUT NUMBER       -- 3.ファイルID（型変換後）
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_msg           VARCHAR2(5000);                             --メッセージ出力用
    lv_msg_tnk       VARCHAR2(5000);                             --メッセージトークン取得用
    lv_file_ul_name  fnd_lookup_values_vl.meaning%TYPE;          --ファイルアップロード名称
    lv_file_name     xxccp_mrp_file_ul_interface.file_name%TYPE; --ファイル名
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    --==============================================================
    --パラメータ出力
    --==============================================================
    -- ファイルID
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name
                ,iv_name         => cv_msg_file_id
                ,iv_token_name1  => cv_tkn_file_id
                ,iv_token_value1 => iv_file_id
              );
    -- ファイルIDメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    -- フォーマットパターンメッセージ
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name
                ,iv_name         => cv_msg_fmt_ptn
                ,iv_token_name1  => cv_tkn_fmt_ptn
                ,iv_token_value1 => iv_fmt_ptn
              );
    -- フォーマットパターンメッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
    --==============================================================
    --パラメータチェック
    --==============================================================
    --ファイルIDチェックエラー時のトークン取得
    lv_msg_tnk := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_nm_file_id
                  );
    -- ファイルIDの必須入力チェック
    IF (iv_file_id IS NULL) THEN
      --エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_param_required
                     ,iv_token_name1  => cv_tkn_param_name
                     ,iv_token_value1 => lv_msg_tnk
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ファイルIDの型チェック(数値型に変換できない場合はエラー
    IF (NOT xxcop_common_pkg.chk_number_format(iv_file_id)) THEN
      --エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_param_valuel
                     ,iv_token_name1  => cv_tkn_item
                     ,iv_token_value1 => lv_msg_tnk
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    on_file_id := TO_NUMBER(iv_file_id);
--
    --==============================================================
    --処理関連データ取得
    --==============================================================
    --業務処理日付
    gd_process_date := xxccp_common_pkg2.get_process_date;
    --業務処理日付取得チェック
    IF (gd_process_date IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_proc_date
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    --営業単位の取得
    gn_org_id  := TO_NUMBER(FND_PROFILE.VALUE( cv_org_id ));
    --営業単位取得チェック
    IF (gn_org_id IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_org_id
                     ,iv_token_name1  => cv_tkn_prof_name
                     ,iv_token_value1 => cv_org_id
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_process_expt;
    END IF;
--
    -- ファイルアップロード名称
    BEGIN
      SELECT flv.meaning  meaning
      INTO   lv_file_ul_name
      FROM   fnd_lookup_values_vl flv
      WHERE  flv.lookup_type  = cv_lkup_file_ul_obj
      AND    flv.lookup_code  = iv_fmt_ptn
      AND    flv.enabled_flag = cv_yes
      AND    gd_process_date  BETWEEN TRUNC(flv.start_date_active)
                              AND     NVL(flv.end_date_active, gd_process_date)
      ;
    EXCEPTION
      WHEN OTHERS THEN
      --エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data_ul
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
    -- ファイルアップロード名称
    lv_msg := xxccp_common_pkg.get_msg(
                 iv_application  => cv_app_name
                ,iv_name         => cv_msg_file_ul_name
                ,iv_token_name1  => cv_tkn_file_ul_name
                ,iv_token_value1 => lv_file_ul_name
              );
    -- ファイルアップロード名称メッセージ出力
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg
    );
--
    BEGIN
      --エラー時のトークン取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_nm_file_ul_if
                    );
      --CSVファイル名
      SELECT xmfui.file_name file_name
      INTO   lv_file_name
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = on_file_id
      FOR UPDATE NOWAIT
      ;
      -- CSVファイル名メッセージ
      lv_msg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_app_name
                  ,iv_name         => cv_msg_file_name
                  ,iv_token_name1  => cv_tkn_file_name
                  ,iv_token_value1 => lv_file_name
                );
      -- CSVファイル名メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_msg
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
    EXCEPTION
      WHEN global_lock_expt THEN
        --ロックエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_lock
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tnk
                       ,iv_token_name2  => cv_tkn_err_msg
                       ,iv_token_value2 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
      WHEN OTHERS THEN
        --データ抽出エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_get_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tnk
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => on_file_id
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    -- *** 処理エラー例外 ***
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : get_upload_data
   * Description      : ファイルアップロードIFデータ抽出(A-2)
   ***********************************************************************************/
  PROCEDURE get_upload_data(
     in_file_id      IN  NUMBER            -- 1.ファイルID
    ,ov_sep_data_tab OUT gt_rec_data_ttype -- 2.項目分割後データ
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_upload_data'; -- プログラム名
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
    ln_line_cnt          NUMBER;
    ln_col_num           NUMBER;
    ln_column_cnt        NUMBER;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
    l_file_data_tab     xxccp_common_pkg2.g_file_data_tbl;  -- 行単位データ格納用配列
    l_sep_data_tab      gt_rec_data_ttype;                  -- 分割データ格納用配列
    lv_msg_tnk          VARCHAR2(5000);                     -- メッセージトークン用
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- BLOBデータ変換関数により行単位データを抽出
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => in_file_id       -- ファイルID
      ,ov_file_data => l_file_data_tab  -- ファイルデータ
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ            -- # 固定 #
      ,ov_retcode   => lv_retcode       -- リターン・コード              -- # 固定 #
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ  -- # 固定 #
    );
    IF (lv_retcode = cv_status_error) THEN
      -- トークン取得
      lv_msg_tnk := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name
                      ,iv_name         => cv_msg_nm_file_ul_if
                    );
      --データ抽出エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_get_data
                     ,iv_token_name1  => cv_tkn_table
                     ,iv_token_value1 => lv_msg_tnk
                     ,iv_token_name2  => cv_tkn_file_id
                     ,iv_token_value2 => in_file_id
                     ,iv_token_name3  => cv_tkn_err_msg
                     ,iv_token_value3 => lv_errbuf
                   );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
    --==============================================================
    --データチェック
    --==============================================================
    --ヘッダ行を除いたデータが0行の場合
    IF (l_file_data_tab.COUNT - cn_header_rec <= 0) THEN
      --対象件数0件メッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_app_name
                     ,iv_name         => cv_msg_err_no_data
                   );
      --対象件数0件メッセージ出力
      fnd_file.put_line(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg
      );
      gn_warn_cnt := gn_warn_cnt + 1;
      ov_retcode  := cv_status_warn;
      --データ無しのため以下の処理は行わない。
      RETURN;
    END IF;
--
    --対象件数の取得
    gn_target_cnt := l_file_data_tab.COUNT - cn_header_rec;
--
    --項目数のチェック
    <<line_data_loop>>
    FOR ln_line_cnt IN 1 .. l_file_data_tab.COUNT LOOP
      --項目数取得(区切り文字の数で判定)
      ln_col_num := NVL(LENGTH(l_file_data_tab(ln_line_cnt)), 0)
                      - NVL(LENGTH(REPLACE(l_file_data_tab(ln_line_cnt), cv_col_separator, NULL)), 0) + 1;
      --項目数チェック
      IF (ln_col_num <> cn_csv_file_col_num) THEN
        --汎用CSVフォーマットエラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_file_fmt
                       ,iv_token_name1  => cv_tkn_index
                       ,iv_token_value1 => ln_line_cnt - 1
                     );
        --メッセージ出力
        fnd_file.put_line(
           which  => FND_FILE.OUTPUT
          ,buff   => lv_errmsg
        );
        gn_warn_cnt := gn_warn_cnt + 1;
        ov_retcode  := cv_status_warn;
      ELSE
        --正常な行は項目数を分割する
        <<col_sep_loop>>
        FOR ln_column_cnt IN 1 .. cn_csv_file_col_num LOOP
          --項目分割(文字列括りは削除)
          l_sep_data_tab(ln_line_cnt)(ln_column_cnt) := REPLACE(xxccp_common_pkg.char_delim_partition(
                                                          iv_char     => l_file_data_tab(ln_line_cnt)
                                                         ,iv_delim    => cv_col_separator
                                                         ,in_part_num => ln_column_cnt
                                                        ), cv_dqu, NULL);
        END LOOP col_sep_loop;
      END IF;
    END LOOP line_data_loop;
--
    ov_sep_data_tab := l_sep_data_tab;
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
  END get_upload_data;
--
  /**********************************************************************************
   * Procedure Name   : business_data_check
   * Description      : データ内容チェック(A-3)
   ***********************************************************************************/
  PROCEDURE business_data_check(
     iv_sep_data_tab IN  gt_rec_data_ttype -- 1.項目分割後データ
    ,ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'business_data_check'; -- プログラム名
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
    cv_aprv_status    CONSTANT VARCHAR2(8)   := 'APPROVED';  -- 承認済
--
    -- *** ローカル変数 ***
    ln_data_num                NUMBER;                       --ループカウンタ
    lr_po_dis_row_id           ROWID;
    lv_msg                     VARCHAR2(5000);               --エラーメッセージ取得用
    lv_msg_tkn                 VARCHAR2(5000);               --エラーメッセージトークン取得用
    lv_dummy                   VARCHAR2(1);                  --存在チェック用
    ln_upd_cnt                 NUMBER := 0;                  --更新配列の添え字
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- ヘッダ行を除いて処理する
    <<chk_loop>>
    FOR ln_data_num IN 2 .. iv_sep_data_tab.COUNT LOOP
      --------------------------------------------
      -- 業務チェック
      --------------------------------------------
      --更新対象の存在チェック
      BEGIN
        SELECT pd.rowid  row_id
        INTO   lr_po_dis_row_id                   -- 更新用のROWID
        FROM   po_headers_all               ph    -- 発注ヘッダ
              ,po_lines_all                 pl    -- 発注明細
              ,po_distributions_all         pd    -- 発注搬送
              ,po_requisition_headers_all   prh   -- 購買依頼ヘッダ
              ,po_requisition_lines_all     prl   -- 購買依頼明細
              ,po_req_distributions_all     prd   -- 購買依頼搬送
              ,xxcso_wk_requisition_proc    xwrp  -- 作業依頼／発注情報連携対象テーブル
        WHERE  ph.po_header_id            = pl.po_header_id
        AND    ph.po_header_id            = pd.po_header_id
        AND    pl.po_line_id              = pd.po_line_id
        AND    pd.req_distribution_id     = prd.distribution_id
        AND    prd.requisition_line_id    = prl.requisition_line_id
        AND    prl.requisition_header_id  = prh.requisition_header_id
        AND    prl.requisition_line_id    = xwrp.requisition_line_id
        AND    ph.segment1                = iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num)       -- 発注番号
        AND    pl.line_num                = iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)  -- 発注明細番号
        AND    prh.segment1               = iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)      -- 購買依頼番号
        AND    prl.line_num               = iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num) -- 購買依頼明細番号
        AND    xwrp.interface_flag        = cv_no                                                 -- 自販機システム未連携
        AND    (
                   ph.authorization_status IS NULL
                OR ph.authorization_status  <> cv_aprv_status
               )                                                                                  -- 承認済以外
        FOR UPDATE OF
               pd.po_distribution_id
        NOWAIT
        ;
      EXCEPTION
        WHEN global_lock_expt THEN
          --ロックエラーメッセージ
          lv_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_po_distributions_lock
                       ,iv_token_name1  => cv_tkn_po_num
                       ,iv_token_value1 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                       ,iv_token_name2  => cv_tkn_po_line_num
                       ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                       ,iv_token_name3  => cv_tkn_po_rec_num
                       ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                       ,iv_token_name4  => cv_tkn_po_rec_line_num
                       ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                     );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode  := cv_status_warn;
        WHEN NO_DATA_FOUND THEN
          --エラーメッセージ
          lv_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_no_target
                       ,iv_token_name1  => cv_tkn_po_num
                       ,iv_token_value1 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                       ,iv_token_name2  => cv_tkn_po_line_num
                       ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                       ,iv_token_name3  => cv_tkn_po_rec_num
                       ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                       ,iv_token_name4  => cv_tkn_po_rec_line_num
                       ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                     );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode  := cv_status_warn;
      END;
--
      --更新用のリース区分がNULL以外の場合
      IF ( iv_sep_data_tab(ln_data_num)(cn_col_pos_lease_type) IS NOT NULL ) THEN
        --リース区分の存在チェック
        BEGIN
          SELECT '1' dummy
          INTO   lv_dummy
          FROM   fnd_lookup_values_vl flvv
          WHERE  flvv.lookup_type  = cv_lkup_lease_kbn -- リース区分
          AND    flvv.enabled_flag = cv_yes
          AND    gd_process_date  >= NVL(flvv.start_date_active ,gd_process_date)
          AND    gd_process_date  <= NVL(flvv.end_date_active   ,gd_process_date)
          AND    flvv.lookup_code  = iv_sep_data_tab(ln_data_num)(cn_col_pos_lease_type)  --更新用のリース区分
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --トークン取得
            lv_msg_tkn := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_lease_kbn
                          );
            --エラーメッセージ
            lv_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_not_found
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => lv_msg_tkn
                         ,iv_token_name2  => cv_tkn_po_num
                         ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                         ,iv_token_name3  => cv_tkn_po_line_num
                         ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                         ,iv_token_name4  => cv_tkn_po_rec_num
                         ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                         ,iv_token_name5  => cv_tkn_po_rec_line_num
                         ,iv_token_value5 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                       );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode  := cv_status_warn;
        END;
      END IF;
--
      --更新用の取得価格がNULL以外の場合
      IF ( iv_sep_data_tab(ln_data_num)(cn_col_pos_price) IS NOT NULL ) THEN
        --取得価格のチェック
        IF (
                ( LENGTHB( iv_sep_data_tab(ln_data_num)(cn_col_pos_price) ) > cv_price_num )               --10桁以内
             OR ( xxccp_common_pkg.chk_number( iv_sep_data_tab(ln_data_num)(cn_col_pos_price) ) = FALSE )  --半角英数・マイナス値
           )
        THEN
          --エラーメッセージ
          lv_msg  := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_price
                       ,iv_token_name1  => cv_tkn_po_num
                       ,iv_token_value1 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                       ,iv_token_name2  => cv_tkn_po_line_num
                       ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                       ,iv_token_name3  => cv_tkn_po_rec_num
                       ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                       ,iv_token_name4  => cv_tkn_po_rec_line_num
                       ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                     );
          -- メッセージ出力
          fnd_file.put_line(
             which  => FND_FILE.OUTPUT
            ,buff   => lv_msg
          );
          gn_warn_cnt := gn_warn_cnt + 1;
          ov_retcode  := cv_status_warn;
        END IF;
      END IF;
--
      --更新用の申告地がNULL以外の場合
      IF ( iv_sep_data_tab(ln_data_num)(cn_col_pos_dclr_place) IS NOT NULL ) THEN
        --申告地の存在チェック
        BEGIN
          SELECT '1' dummy
          INTO   lv_dummy
          FROM   fnd_flex_values      ffv
               , fnd_flex_values_tl   ffvt
               , fnd_flex_value_sets  ffvs
          WHERE  ffv.flex_value_id        = ffvt.flex_value_id
          AND    ffvt.language            = cv_language
          AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
          AND    ffvs.flex_value_set_name = cv_flex_dclr_place  -- 申告地
          AND    ffv.enabled_flag         = cv_yes
          AND    gd_process_date         >= NVL(ffv.start_date_active ,gd_process_date)
          AND    gd_process_date         <= NVL(ffv.end_date_active   ,gd_process_date)
          AND    ffv.flex_value           = iv_sep_data_tab(ln_data_num)(cn_col_pos_dclr_place)  --更新用申告地コード
          ;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            --トークン取得
            lv_msg_tkn := xxccp_common_pkg.get_msg(
                            iv_application  => cv_app_name
                           ,iv_name         => cv_msg_dclr_place
                          );
            --エラーメッセージ
            lv_msg  := xxccp_common_pkg.get_msg(
                          iv_application  => cv_app_name
                         ,iv_name         => cv_msg_not_found
                         ,iv_token_name1  => cv_tkn_item
                         ,iv_token_value1 => lv_msg_tkn
                         ,iv_token_name2  => cv_tkn_po_num
                         ,iv_token_value2 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_num) 
                         ,iv_token_name3  => cv_tkn_po_line_num
                         ,iv_token_value3 => iv_sep_data_tab(ln_data_num)(cn_col_pos_po_line_num)
                         ,iv_token_name4  => cv_tkn_po_rec_num
                         ,iv_token_value4 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_num)
                         ,iv_token_name5  => cv_tkn_po_rec_line_num
                         ,iv_token_value5 => iv_sep_data_tab(ln_data_num)(cn_col_pos_req_line_num)
                       );
            -- メッセージ出力
            fnd_file.put_line(
               which  => FND_FILE.OUTPUT
              ,buff   => lv_msg
            );
            gn_warn_cnt := gn_warn_cnt + 1;
            ov_retcode  := cv_status_warn;
        END;
      END IF;
--
      --エラーが存在しない場合、更新用の配列に格納(1レコードでもエラーの場合は以降チェックのみ)
      IF ( ov_retcode = cv_status_normal ) THEN
        ln_upd_cnt                   := ln_upd_cnt + 1;                                      --添え字カウント
        gt_row_id_tab(ln_upd_cnt)    := lr_po_dis_row_id;                                    --発注明細搬送ROWID
        gt_lease_kbn_tab(ln_upd_cnt) := iv_sep_data_tab(ln_data_num)(cn_col_pos_lease_type); --リース区分
        gt_dclr_place(ln_upd_cnt)    := iv_sep_data_tab(ln_data_num)(cn_col_pos_dclr_place); --申告地
        gt_price_ttype(ln_upd_cnt)   := iv_sep_data_tab(ln_data_num)(cn_col_pos_price);      --取得価格
      END IF;
--
    END LOOP chk_loop;
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
  END business_data_check;
--
  /**********************************************************************************
   * Procedure Name   : update_distributions
   * Description      : 発注明細搬送DFF更新(A-4)
   ***********************************************************************************/
  PROCEDURE update_distributions(
     ov_errbuf       OUT VARCHAR2          --   エラー・メッセージ           --# 固定 #
    ,ov_retcode      OUT VARCHAR2          --   リターン・コード             --# 固定 #
    ,ov_errmsg       OUT VARCHAR2)         --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_distributions'; -- プログラム名
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
    lv_msg_tkn  VARCHAR2(5000);
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- *** ローカル・テーブル ***
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
      FORALL i IN 1..gt_row_id_tab.COUNT
        UPDATE  po_distributions_all pda
        SET     pda.attribute_category     = TO_CHAR(gn_org_id)             --アトリビュートカテゴリ(営業)
               ,pda.attribute1             = gt_lease_kbn_tab(i)            --リース区分
               ,pda.attribute2             = gt_price_ttype(i)              --取得価格
               ,pda.attribute3             = gt_dclr_place(i)               --申告地
               ,pda.last_updated_by        = cn_last_updated_by             --最終更新者
               ,pda.last_update_date       = cd_last_update_date            --最終更新日
               ,pda.last_update_login      = cn_last_update_login           --最終更新ﾛｸﾞｲﾝ
               ,pda.request_id             = cn_request_id                  --要求ID
               ,pda.program_application_id = cn_program_application_id      --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑ･ｱﾌﾟﾘｹｰｼｮﾝID
               ,pda.program_id             = cn_program_id                  --ｺﾝｶﾚﾝﾄ･ﾌﾟﾛｸﾞﾗﾑID
               ,pda.program_update_date    = cd_program_update_date         --ﾌﾟﾛｸﾞﾗﾑ更新日
        WHERE   pda.ROWID  =  gt_row_id_tab(i)
        ;
    EXCEPTION
      WHEN OTHERS THEN
        --トークン取得
        lv_msg_tkn := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_po_distributions
                      );
        --エラーメッセージ
        lv_errmsg  := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_update_error
                        ,iv_token_name1  => cv_tkn_action
                        ,iv_token_value1 => lv_msg_tkn
                        ,iv_token_name2  => cv_tkn_error_msg
                        ,iv_token_value2 => SQLERRM
                      );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
--
    --成功件数の取得
    gn_normal_cnt := gt_row_id_tab.COUNT;
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
  END update_distributions;
--
  /**********************************************************************************
   * Procedure Name   : delete_file_ul_if
   * Description      : ファイルアップロードIFデータ削除(A-8)
   ***********************************************************************************/
  PROCEDURE delete_file_ul_if(
    in_file_id    IN  NUMBER,    -- ファイルID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'delete_file_ul_if'; -- プログラム名
--
--#####################  固定ローカル変数宣言部 START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_msg_tnk VARCHAR2(5000);  -- メッセージトークン取得用
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
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE xmfui.file_id = in_file_id
      ;
    EXCEPTION
      WHEN OTHERS THEN
        --エラー時のトークン取得
        lv_msg_tnk := xxccp_common_pkg.get_msg(
                         iv_application  => cv_app_name
                        ,iv_name         => cv_msg_nm_file_ul_if
                      );
        -- データ削除エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                        iv_application  => cv_app_name
                       ,iv_name         => cv_msg_err_del_data
                       ,iv_token_name1  => cv_tkn_table
                       ,iv_token_value1 => lv_msg_tnk
                       ,iv_token_name2  => cv_tkn_file_id
                       ,iv_token_value2 => TO_CHAR( in_file_id )
                       ,iv_token_name3  => cv_tkn_err_msg
                       ,iv_token_value3 => SQLERRM
                     );
        lv_errbuf := lv_errmsg;
        RAISE global_process_expt;
    END;
--
  EXCEPTION
    WHEN global_process_expt THEN                           --*** 処理エラー例外 ***
      -- *** 任意で例外処理を記述する ****
      ov_errmsg  := lv_errmsg;                                                  --# 任意 #
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;                                            --# 任意 #
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
  END delete_file_ul_if;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     iv_file_id    IN  VARCHAR2     -- 1.ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2     -- 2.フォーマットパターン  )
    ,ov_errbuf     OUT VARCHAR2     --   エラー・メッセージ           --# 固定 #
    ,ov_retcode    OUT VARCHAR2     --   リターン・コード             --# 固定 #
    ,ov_errmsg     OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_file_id  NUMBER;
--
    -- *** ローカル・テーブル ***
    lv_sep_data_tab  gt_rec_data_ttype;  --項目分割データ取得用
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
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 初期処理(A-1)
    -- ===============================
    init(
       iv_file_id => iv_file_id   -- 1.ファイルID
      ,iv_fmt_ptn => iv_fmt_ptn   -- 2.フォーマットパターン
      ,on_file_id => ln_file_id   -- 3.ファイルID（型変換後）
      ,ov_errbuf  => lv_errbuf    --   エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode   --   リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg);  --   ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- ファイルアップロードIFデータ抽出(A-2)
    -- ===============================
    get_upload_data(
       in_file_id      => ln_file_id
      ,ov_sep_data_tab => lv_sep_data_tab    -- 項目分割後データ
      ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
      ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
      ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = cv_status_warn) THEN
      ov_retcode := lv_retcode;
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================
      -- データ内容チェック(A-3)
      -- ===============================
      business_data_check(
         iv_sep_data_tab => lv_sep_data_tab
        ,ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
        ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = cv_status_warn) THEN
        ov_retcode := lv_retcode;
      END IF;
--
    END IF;
--
    IF (lv_retcode = cv_status_normal) THEN
      -- ===============================
      -- 発注明細搬送DFF更新(A-4)
      -- ===============================
      update_distributions(
         ov_errbuf       => lv_errbuf          -- エラー・メッセージ           --# 固定 #
        ,ov_retcode      => lv_retcode         -- リターン・コード             --# 固定 #
        ,ov_errmsg       => lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
      IF (lv_retcode = cv_status_error) THEN
        RAISE global_process_expt;
      END IF;
--
    END IF;
--
    -- ===============================
    -- ファイルアップロードIFデータ削除(A-5)
    -- ===============================
    delete_file_ul_if(
       in_file_id  => ln_file_id
      ,ov_errbuf   =>  lv_errbuf
      ,ov_retcode  =>  lv_retcode
      ,ov_errmsg   =>  lv_errmsg);
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
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
     errbuf        OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
    ,retcode       OUT VARCHAR2      --   リターン・コード    --# 固定 #
    ,iv_file_id    IN  VARCHAR2      -- 1.ファイルID
    ,iv_fmt_ptn    IN  VARCHAR2)     -- 2.フォーマットパターン
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
    cv_appl_short_name CONSTANT VARCHAR2(10)  := 'XXCCP';            -- アドオン：共通・IF領域
    cv_target_rec_msg  CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_warn_msg        CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_warn_rec_msg    CONSTANT VARCHAR2(100) := 'APP-XXCCP1-00001'; -- 警告件数メッセージ
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
       iv_file_id => iv_file_id   -- 1.ファイルID
      ,iv_fmt_ptn => iv_fmt_ptn   -- 2.フォーマットパターン
      ,ov_errbuf  => lv_errbuf    --   エラー・メッセージ           --# 固定 #
      ,ov_retcode => lv_retcode   --   リターン・コード             --# 固定 #
      ,ov_errmsg  => lv_errmsg    --   ユーザー・エラー・メッセージ --# 固定 #
    );
--
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
      -- 対象件数初期化
      gn_target_cnt := 0;
      -- 成功件数初期化
      gn_normal_cnt := 0;
      -- エラー件数の取得
      gn_error_cnt  := 1;
    END IF;
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --警告件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_warn_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_warn_cnt)
                   );
    FND_FILE.PUT_LINE(
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
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_warn) THEN
      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
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
END XXCSO011A04C;
/
