CREATE OR REPLACE PACKAGE BODY APPS.XXCSO016A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO016A03C(body)
 * Description      : 見積ヘッダ、見積明細データを情報系システムに送信するための
 *                    CSVファイルを作成します。
 * MD.050           : MD050_CSO_016_A03_情報系-EBSインターフェース：
 *                    (OUT)見積情報データ
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  set_param_default      パラメータデフォルトセット(A-2)
 *  chk_param              パラメータチェック(A-3)
 *  get_profile_info       プロファイル値取得(A-4)
 *  open_csv_file_header   見積ヘッダ情報CSVファイルオープン(A-5)
 *  open_csv_file_lines    見積明細情報CSVファイルオープン(A-6)
 *  get_xqh_data_for_sale  販売先用見積ヘッダー抽出(A-8)
 *  get_hcsu_data          顧客使用目的マスタ抽出(A-9)
 *  create_csv_rec_lines   見積明細情報CSV出力(A-11)
 *  create_csv_rec_header  見積ヘッダー情報CSV出力(A-12)
 *  close_csv_file_lines   見積明細情報CSVファイルクローズ処理(A-13)
 *  close_csv_file_header  見積ヘッダ情報CSVファイルクローズ処理(A-14)
 *  submain                メイン処理プロシージャ
 *                           見積ヘッダ情報抽出処理(A-7)
 *                           見積明細情報抽出処理(A-10)
 *  main                   コンカレント実行ファイル登録プロシージャ
 *                           終了処理(A-15)
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-12-09    1.0   Kazuyo.Hosoi     新規作成
 *  2009-02-25    1.1   K.Sai            レビュー結果反映 
 *  2009-04-16    1.2   K.Satomura       システムテスト障害対応(T1_0172,T1_0508)
 *  2009-05-01    1.3   Tomoko.Mori      T1_0897対応
 *  2010-01-08    1.4   Kazuyo.Hosoi     E_本稼動_01017対応
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
  cv_pkg_name            CONSTANT VARCHAR2(100) := 'XXCSO016A03C';  -- パッケージ名
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
  cv_tkn_number_13       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00151';  -- データ抽出警告メッセージ
  cv_tkn_number_14       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00225';  -- CSVファイル出力エラーメッセージ(見積明細)
  cv_tkn_number_15       CONSTANT VARCHAR2(100) := 'APP-XXCSO1-00020';  -- CSVファイル出力エラーメッセージ(見積ヘッダ情報)
  -- トークンコード
  cv_tkn_frm_val           CONSTANT VARCHAR2(20) := 'FROM_VALUE';
  cv_tkn_to_val            CONSTANT VARCHAR2(20) := 'TO_VALUE';
  cv_tkn_val               CONSTANT VARCHAR2(20) := 'VALUE';
  cv_tkn_status            CONSTANT VARCHAR2(20) := 'STATUS';
  cv_tkn_csv_fnm           CONSTANT VARCHAR2(20) := 'CSV_FILE_NAME';
  cv_tkn_prof_nm           CONSTANT VARCHAR2(20) := 'PROF_NAME';
  cv_tkn_csv_loc           CONSTANT VARCHAR2(20) := 'CSV_LOCATION';
  cv_tkn_errmsg            CONSTANT VARCHAR2(20) := 'ERR_MSG';
  cv_tkn_errmessage        CONSTANT VARCHAR2(20) := 'ERR_MESSAGE';
  cv_tkn_prcss_nm          CONSTANT VARCHAR2(20) := 'PROCESSING_NAME';
  cv_tkn_estmt_no          CONSTANT VARCHAR2(20) := 'ESTIMATE_NO';
  cv_tkn_estmt_type        CONSTANT VARCHAR2(20) := 'ESTIMATE_TYPE';
  cv_tkn_estmt_edtn        CONSTANT VARCHAR2(20) := 'ESTIMATE_EDITION';
  cv_tkn_dtl_id            CONSTANT VARCHAR2(20) := 'DETAILE_ID';
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
  cv_debug_msg8          CONSTANT VARCHAR2(200) := 'lv_csv_nm_hdr = ';
  cv_debug_msg9          CONSTANT VARCHAR2(200) := 'lv_csv_nm_lns = ';
  cv_debug_msg10         CONSTANT VARCHAR2(200) := '<< CSVファイルをオープンしました >>' ;
  cv_debug_msg11         CONSTANT VARCHAR2(200) := '<< CSVファイルをクローズしました >>' ;
  cv_debug_msg12         CONSTANT VARCHAR2(200) := '<< ロールバックしました >>' ;
  cv_debug_msg13         CONSTANT VARCHAR2(200) := '<< 起動パラメータ >>';
  cv_debug_msg14         CONSTANT VARCHAR2(200) := '更新日FROM : ';
  cv_debug_msg15         CONSTANT VARCHAR2(200) := '更新日TO : ';
  cv_debug_msg16         CONSTANT VARCHAR2(200) := 'lv_org_id = ';
  cv_debug_msg_fnm       CONSTANT VARCHAR2(200) := 'filename = ';
  cv_debug_msg_fcls      CONSTANT VARCHAR2(200) := '<< 例外処理内でCSVファイルをクローズしました >>';
  cv_debug_msg_ccls3     CONSTANT VARCHAR2(200) := '<< 例外処理内で見積ヘッダ情報取得カーソルをクローズしました >>';
  cv_debug_msg_ccls4     CONSTANT VARCHAR2(200) := '<< 例外処理内で見積明細情報取得カーソルをクローズしました >>';
  cv_debug_msg_skip      CONSTANT VARCHAR2(200) := '<< 販売先用顧客コード取得失敗のためスキップしました >>';
  cv_debug_msg_err1      CONSTANT VARCHAR2(200) := 'global_process_expt';
  cv_debug_msg_err2      CONSTANT VARCHAR2(200) := 'global_api_others_expt';
  cv_debug_msg_err3      CONSTANT VARCHAR2(200) := 'others例外';
--
  cv_w                   CONSTANT VARCHAR2(1)   := 'w';  -- CSVファイルオープンモード
  cv_status_fix          CONSTANT VARCHAR2(1)   := '2';  -- ステータス(2:確定)
  cv_quote_type1         CONSTANT VARCHAR2(1)   := '1';  -- 見積種別(1:販売先用)
  cv_quote_type2         CONSTANT VARCHAR2(1)   := '2';  -- 見積種別(2:帳合問屋先用)
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
  -- ファイル・ハンドルの宣言
  gf_file_hand_header    UTL_FILE.FILE_TYPE;       -- 見積ヘッダ用
  gf_file_hand_lines     UTL_FILE.FILE_TYPE;       -- 見積明細用
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
  -- CSV出力データ格納用レコード型定義(見積ヘッダー情報)
  TYPE g_get_data_hdr_rtype IS RECORD(
     company_cd              VARCHAR2(3)                                       -- 会社コード
    ,quote_number            xxcso_quote_headers.quote_number%TYPE             -- 見積書番号
    ,reference_quote_number  xxcso_quote_headers.reference_quote_number%TYPE   -- 参照見積書番号
    ,quote_revision_number   xxcso_quote_headers.quote_revision_number%TYPE    -- 版数
    ,quote_type              xxcso_quote_headers.quote_type%TYPE               -- 見積種類
    ,account_number_for_sale xxcso_quote_headers.account_number%TYPE           -- 販売先顧客番号
    ,account_number          xxcso_quote_headers.account_number%TYPE           -- 顧客コード
    ,publish_date            xxcso_quote_headers.publish_date%TYPE             -- 発行日
    ,employee_number         xxcso_quote_headers.employee_number%TYPE          -- 担当者コード
    /* 2009.04.16 K.Satomura T1_0172対応 START */
    --,deliv_place             xxcso_quote_headers.deliv_place%TYPE              -- 納入場所
    ,deliv_place             VARCHAR2(60)                                      -- 納入場所
    /* 2009.04.16 K.Satomura T1_0172対応 END */
    ,name                    ra_terms_vl.name%TYPE                             -- 支払条件
    ,quote_info_start_date   xxcso_quote_headers.quote_info_start_date%TYPE    -- 見積情報期間(自)
    ,quote_info_end_date     xxcso_quote_headers.quote_info_end_date%TYPE      -- 見積情報期間(至)
    /* 2009.04.16 K.Satomura T1_0172対応 START */
    --,quote_submit_name       xxcso_quote_headers.quote_submit_name%TYPE        -- 見積書提出先名称
    --,special_note            xxcso_quote_headers.special_note%TYPE             -- 特記事項
    ,quote_submit_name       VARCHAR2(40)                                      -- 見積書提出先名称
    ,special_note            VARCHAR2(100)                                     -- 特記事項
    /* 2009.04.16 K.Satomura T1_0172対応 END */
    ,status                  xxcso_quote_headers.status%TYPE                   -- ステータス
    ,deliv_price_tax_type    xxcso_quote_headers.deliv_price_tax_type%TYPE     -- 店納価格税区分
    ,unit_type               xxcso_quote_headers.unit_type%TYPE                -- 単価区分
    ,cprtn_date              DATE                                              -- 連携日時
  );
  -- CSV出力データ格納用レコード型定義(見積明細情報)
  TYPE g_get_data_lns_rtype IS RECORD(
     company_cd                 VARCHAR2(3)                                        -- 会社コード
    ,quote_line_id              xxcso_quote_lines.quote_line_id%TYPE               -- 明細ID
    ,quote_number               xxcso_quote_headers.quote_number%TYPE              -- 見積書番号
    ,inventory_item_code        mtl_system_items_b.segment1%TYPE                   -- 商品コード
    ,quote_div                  xxcso_quote_lines.quote_div%TYPE                   -- 見積区分
    ,usually_deliv_price        xxcso_quote_lines.usually_deliv_price%TYPE         -- 通常店納価格
    ,this_time_deliv_price      xxcso_quote_lines.this_time_deliv_price%TYPE       -- 今回店納価格
    ,usually_store_sale_price   xxcso_quote_lines.usually_store_sale_price%TYPE    -- 通常店頭価格
    ,quotation_price            xxcso_quote_lines.quotation_price%TYPE             -- 建値
    ,this_time_store_sale_price xxcso_quote_lines.this_time_store_sale_price%TYPE  -- 今回店頭価格
    ,this_time_net_price        xxcso_quote_lines.this_time_net_price%TYPE         -- 今回NET価格
    ,amount_of_margin           xxcso_quote_lines.amount_of_margin%TYPE            -- マージン額
    ,margin_rate                xxcso_quote_lines.margin_rate%TYPE                 -- マージン率
    ,sales_discount_price       xxcso_quote_lines.sales_discount_price%TYPE        -- 値引
    ,business_price             xxcso_quote_lines.business_price%TYPE              -- 営業原価
    ,quote_start_date           xxcso_quote_lines.quote_start_date%TYPE            -- 有効期間(自)
    ,quote_end_date             xxcso_quote_lines.quote_end_date%TYPE              -- 有効期間(至)
    /* 2009.04.16 K.Satomura T1_0172対応 START */
    --,remarks                    xxcso_quote_lines.remarks%TYPE                     -- 備考
    ,remarks                    VARCHAR2(20)                                       -- 備考
    /* 2009.04.16 K.Satomura T1_0172対応 END */
    ,line_order                 xxcso_quote_lines.line_order%TYPE                  -- 並び順
    ,usuall_net_price           xxcso_quote_lines.usuall_net_price%TYPE            -- 通常NET価格
    ,cprtn_date                 DATE                                               -- 連携日時
  );
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
     iv_from_value       IN  VARCHAR2         --   パラメータ更新日 FROM
    ,iv_to_value         IN  VARCHAR2         --   パラメータ更新日 TO
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
     id_process_date     IN DATE                 -- 業務処理日付  
    ,io_from_value       IN OUT NOCOPY VARCHAR2  -- パラメータ更新日 FROM
    ,io_to_value         IN OUT NOCOPY VARCHAR2  -- パラメータ更新日 TO
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
    lb_set_param_flg BOOLEAN DEFAULT FALSE;
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
     ov_company_cd     OUT NOCOPY VARCHAR2  -- 会社コード（固定値001）
    ,ov_csv_dir        OUT NOCOPY VARCHAR2  -- CSVファイル出力先
    ,ov_csv_nm_hdr     OUT NOCOPY VARCHAR2  -- CSVファイル名(見積ヘッダ)
    ,ov_csv_nm_lns     OUT NOCOPY VARCHAR2  -- CSVファイル名(見積明細)
    ,ov_org_id         OUT NOCOPY VARCHAR2  -- ORG_ID
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
    -- XXCSO:情報系連携用CSVファイル名(見積ヘッダ)
    cv_prfnm_csv_estmt_hdr   CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_ESTMT_HDR';
    -- XXCSO:情報系連携用CSVファイル名(見積明細)
    cv_prfnm_csv_estmt_lns   CONSTANT VARCHAR2(30)   := 'XXCSO1_INFO_OUT_CSV_ESTMT_LNS';
    -- OE:品目検証組織
    cv_prfnm_org_id          CONSTANT VARCHAR2(30)   := 'SO_ORGANIZATION_ID';
--
    -- *** ローカル変数 ***
    -- プロファイル値取得戻り値格納用
    lv_company_cd               VARCHAR2(2000);      -- 会社コード（固定値001）
    lv_csv_dir                  VARCHAR2(2000);      -- CSVファイル出力先
    lv_csv_nm_hdr               VARCHAR2(2000);      -- CSVファイル名(見積ヘッダ)
    lv_csv_nm_lns               VARCHAR2(2000);      -- CSVファイル名(見積明細)
    lv_org_id                   VARCHAR2(2000);      -- オルグID
    -- プロファイル値取得失敗時 トークン値格納用
    lv_tkn_value                VARCHAR2(1000);
    -- 取得データメッセージ出力用
    lv_msg_hdr                  VARCHAR2(5000);
    lv_msg_lns                  VARCHAR2(5000);
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
                    name => cv_prfnm_csv_estmt_hdr
                   ,val  => lv_csv_nm_hdr
                   ); -- CSVファイル名(見積ヘッダ)
    FND_PROFILE.GET(
                    name => cv_prfnm_csv_estmt_lns
                   ,val  => lv_csv_nm_lns
                   ); -- CSVファイル名(見積明細)
    FND_PROFILE.GET(
                    name => cv_prfnm_org_id
                   ,val  => lv_org_id
                   ); -- オルグID
    -- *** DEBUG_LOG ***
    -- 取得したプロファイル値をログ出力
    fnd_file.put_line(
       which  => FND_FILE.LOG
      ,buff   => cv_debug_msg5  || CHR(10) ||
                 cv_debug_msg6  || lv_company_cd || CHR(10) ||
                 cv_debug_msg7  || lv_csv_dir    || CHR(10) ||
                 cv_debug_msg8  || lv_csv_nm_hdr || CHR(10) ||
                 cv_debug_msg9  || lv_csv_nm_lns || CHR(10) ||
                 cv_debug_msg16 || lv_org_id     || CHR(10) ||
                 ''
    );
--
    -- 取得したCSVファイル名をメッセージ出力する
    -- CSVファイル名(見積ヘッダ)
    lv_msg_hdr := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_07      --メッセージコード
                   ,iv_token_name1  => cv_tkn_csv_fnm        --トークンコード1
                   ,iv_token_value1 => lv_csv_nm_hdr         --トークン値1
                  );
    -- CSVファイル名(見積明細)
    lv_msg_lns := xxccp_common_pkg.get_msg(
                    iv_application  => cv_app_name           --アプリケーション短縮名
                   ,iv_name         => cv_tkn_number_07      --メッセージコード
                   ,iv_token_name1  => cv_tkn_csv_fnm        --トークンコード1
                   ,iv_token_value1 => lv_csv_nm_lns         --トークン値1
                  );
--
    --メッセージ出力(見積ヘッダ)
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_hdr
    );
    --メッセージ出力(見積明細)
    fnd_file.put_line(
       which  => FND_FILE.OUTPUT
      ,buff   => lv_msg_lns
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
    ELSIF (lv_csv_nm_hdr IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_estmt_hdr;
    ELSIF (lv_csv_nm_lns IS NULL) THEN
      lv_tkn_value := cv_prfnm_csv_estmt_lns;
    ELSIF (lv_org_id IS NULL) THEN
      lv_tkn_value := cv_prfnm_org_id;
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
    ov_csv_nm_hdr     :=  lv_csv_nm_hdr;       -- CSVファイル名(見積ヘッダ)
    ov_csv_nm_lns     :=  lv_csv_nm_lns;       -- CSVファイル名(見積明細)
    ov_org_id         :=  lv_org_id;           -- オルグID
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
   * Procedure Name   : open_csv_file_header
   * Description      : 見積ヘッダ情報CSVファイルオープン(A-5)
   ***********************************************************************************/
  PROCEDURE open_csv_file_header(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file_header';  -- プログラム名
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
      gf_file_hand_header := UTL_FILE.FOPEN(
                               location   => iv_csv_dir
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
  END open_csv_file_header;
--
  /**********************************************************************************
   * Procedure Name   : open_csv_file_lines
   * Description      : 見積明細情報CSVファイルオープン(A-6)
   ***********************************************************************************/
  PROCEDURE open_csv_file_lines(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'open_csv_file_lines';  -- プログラム名
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
      gf_file_hand_lines  := UTL_FILE.FOPEN(
                               location   => iv_csv_dir
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
  END open_csv_file_lines;
--
  /**********************************************************************************
   * Procedure Name   : get_xqh_data_for_sale
   * Description      : 販売先用見積ヘッダー抽出(A-8)
   ***********************************************************************************/
  PROCEDURE get_xqh_data_for_sale(
     io_hdr_data_rec    IN OUT NOCOPY g_get_data_hdr_rtype -- 見積ヘッダデータ
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_xqh_data_for_sale';  -- プログラム名
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
    cv_prcss_nm   CONSTANT VARCHAR2(100) := '販売先用見積ヘッダー';
    -- *** ローカル変数 ***
    --取得データ格納用
    lt_accnt_num_for_sl  xxcso_quote_headers.account_number%TYPE;    -- 販売先用顧客コード
    -- *** ローカル例外 ***
    no_data_expt         EXCEPTION;                                  -- 対象データ0件例外
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
    -- 販売先用見積ヘッダー抽出
    -- ============================
    BEGIN
      SELECT xqh.account_number    account_number       -- 販売先用顧客コード
      INTO   lt_accnt_num_for_sl
      FROM   xxcso_quote_headers  xqh                   -- 見積ヘッダーテーブル
      WHERE  xqh.quote_type   = cv_quote_type1
      AND    xqh.quote_number = io_hdr_data_rec.reference_quote_number
      AND    xqh.status       = cv_status_fix
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- 警告メッセージ取得
        lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_app_name                            --アプリケーション短縮名
                      ,iv_name         => cv_tkn_number_13                       --メッセージコード
                      ,iv_token_name1  => cv_tkn_prcss_nm                        --トークンコード1
                      ,iv_token_value1 => cv_prcss_nm                            --トークン値1
                      ,iv_token_name2  => cv_tkn_estmt_no                        --トークンコード2
                      ,iv_token_value2 => io_hdr_data_rec.quote_number           --トークン値2
                      ,iv_token_name3  => cv_tkn_estmt_type                      --トークンコード3
                      ,iv_token_value3 => io_hdr_data_rec.quote_type             --トークン値3
                      ,iv_token_name4  => cv_tkn_estmt_edtn                      --トークンコード4
                      ,iv_token_value4 => io_hdr_data_rec.quote_revision_number  --トークン値4
                      ,iv_token_name5  => cv_tkn_errmsg                          --トークンコード4
                      ,iv_token_value5 => SQLERRM                                --トークン値4
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
    io_hdr_data_rec.account_number_for_sale := lt_accnt_num_for_sl;              -- 販売先用顧客コード
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
  END get_xqh_data_for_sale;
--
  /**********************************************************************************
   * Procedure Name   : get_hcsu_data
   * Description      : 顧客使用目的マスタ抽出(A-9)
   ***********************************************************************************/
  PROCEDURE get_hcsu_data(
     id_process_date    IN     DATE                        -- 業務処理日付  
    ,io_hdr_data_rec    IN OUT NOCOPY g_get_data_hdr_rtype -- 見積ヘッダデータ
    ,ov_errbuf          OUT    NOCOPY VARCHAR2             -- エラー・メッセージ            --# 固定 #
    ,ov_retcode         OUT    NOCOPY VARCHAR2             -- リターン・コード              --# 固定 #
    ,ov_errmsg          OUT    NOCOPY VARCHAR2             -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hcsu_data';  -- プログラム名
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
    cv_duns_num_c_30  CONSTANT VARCHAR2(2)   := '30';       -- 承認済み
    cv_duns_num_c_40  CONSTANT VARCHAR2(2)   := '40';       -- 顧客
    cv_duns_num_c_50  CONSTANT VARCHAR2(2)   := '50';       -- 休止
    cv_site_use_code  CONSTANT VARCHAR2(10)  := 'BILL_TO';  -- 請求先
    cv_prcss_nm       CONSTANT VARCHAR2(100) := '顧客マスタ・顧客アドオンマスタ';
    /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
    cv_active         CONSTANT VARCHAR2(1)   := 'A';        -- 顧客使用目的マスタ ステータス
    /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
    -- *** ローカル変数 ***
    --取得データ格納用
    lt_name           ra_terms_vl.name%TYPE;    -- 支払条件
    ld_process_date   DATE;                     -- 編集後 業務処理日付 格納
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- 業務処理日付を格納
    ld_process_date := TRUNC(id_process_date);
--
    -- ============================
    -- 顧客使用目的マスタ抽出
    -- ============================
    BEGIN
      SELECT rtv.name                            -- 支払条件
      INTO   lt_name
      FROM   hz_cust_accounts   hca              -- 顧客マスタ
            ,hz_cust_acct_sites hcas             -- 顧客所在地マスタVIEW
            ,hz_cust_site_uses  hcsu             -- 顧客使用目的マスタVIEW
            ,ra_terms_vl        rtv              -- 支払条件マスタVIEW
            ,hz_parties         hp               -- パーティサイト
      WHERE hca.account_number             = io_hdr_data_rec.account_number
        AND hp.duns_number_c IN (cv_duns_num_c_30,cv_duns_num_c_40,cv_duns_num_c_50)
        AND hca.cust_account_id            =  hcas.cust_account_id
        AND hcas.cust_acct_site_id         =  hcsu.cust_acct_site_id
        AND hcsu.site_use_code             =  cv_site_use_code
        AND hcsu.payment_term_id           =  rtv.term_id
        /* 2010.01.08 K.Hosoi E_本稼動_01017対応 START */
        AND hcsu.status                    =  cv_active
        /* 2010.01.08 K.Hosoi E_本稼動_01017対応 END */
        AND rtv.start_date_active          <= ld_process_date
        AND NVL(rtv.end_date_active,ld_process_date)
              >=  ld_process_date
        AND hp.party_id                    =  hca.party_id
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- データが存在しない場合はNULLを設定
      lt_name := NULL;
      WHEN TOO_MANY_ROWS THEN
      -- データが複数取れた場合はNULLを設定
      lt_name := NULL;
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
    io_hdr_data_rec.name := lt_name;              -- 支払条件
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
  END get_hcsu_data;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec_lines
   * Description      : 見積明細情報CSV出力(A-11)
   ***********************************************************************************/
  PROCEDURE create_csv_rec_lines(
     i_lns_data_rec      IN  g_get_data_lns_rtype    -- 見積明細情報データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec_lines';     -- プログラム名
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
    l_lns_data_rec     g_get_data_lns_rtype; -- INパラメータ.見積明細情報データ格納
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
    l_lns_data_rec := i_lns_data_rec;       -- 見積明細情報データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- データ作成
      lv_data := cv_sep_wquot || l_lns_data_rec.company_cd || cv_sep_wquot                     -- 会社コード
        || cv_sep_com || TO_CHAR(l_lns_data_rec.quote_line_id)                                 -- 明細ID
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.quote_number           || cv_sep_wquot -- 見積書番号
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.inventory_item_code    || cv_sep_wquot -- 商品コード
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.quote_div              || cv_sep_wquot -- 見積区分
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.usually_deliv_price, 0))                   -- 通常店納価格
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.this_time_deliv_price, 0))                 -- 今回店納価格
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.usually_store_sale_price, 0))              -- 通常店頭価格
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.quotation_price, 0))                       -- 建値
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.this_time_store_sale_price, 0))            -- 今回店頭価格
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.this_time_net_price, 0))                   -- 今回NET価格
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.amount_of_margin, 0))                      -- マージン額
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.margin_rate, 0))                           -- マージン率
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.sales_discount_price, 0))                  -- 値引
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.business_price, 0))                        -- 営業原価
        || cv_sep_com || TO_CHAR(l_lns_data_rec.quote_start_date, 'yyyymmdd')                  -- 有効期間(自)
        || cv_sep_com || TO_CHAR(l_lns_data_rec.quote_end_date, 'yyyymmdd')                    -- 有効期間(至)
        || cv_sep_com || cv_sep_wquot || l_lns_data_rec.remarks  || cv_sep_wquot               -- 備考
        || cv_sep_com || TO_CHAR(l_lns_data_rec.line_order)                                    -- 並び順
        || cv_sep_com || TO_CHAR(NVL(l_lns_data_rec.usuall_net_price, 0))                      -- 通常NET価格
        || cv_sep_com || TO_CHAR(l_lns_data_rec.cprtn_date, 'yyyymmddhh24miss')                -- 連携日時
      ;
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand_lines
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
                      ,iv_token_name1  => cv_tkn_dtl_id                            --トークンコード1
                      ,iv_token_value1 => TO_CHAR(l_lns_data_rec.quote_line_id)    --トークン値1
                      ,iv_token_name2  => cv_tkn_estmt_no                          --トークンコード2
                      ,iv_token_value2 => l_lns_data_rec.quote_number              --トークン値2
                      ,iv_token_name3  => cv_tkn_errmsg                            --トークンコード3
                      ,iv_token_value3 => SQLERRM                                  --トークン値3
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
  END create_csv_rec_lines;
--
  /**********************************************************************************
   * Procedure Name   : create_csv_rec_header
   * Description      : 見積ヘッダー情報CSV出力(A-12)
   ***********************************************************************************/
  PROCEDURE create_csv_rec_header(
     i_hdr_data_rec      IN  g_get_data_hdr_rtype    -- 見積ヘッダー情報データ
    ,ov_errbuf           OUT NOCOPY VARCHAR2         -- エラー・メッセージ            --# 固定 #
    ,ov_retcode          OUT NOCOPY VARCHAR2         -- リターン・コード              --# 固定 #
    ,ov_errmsg           OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ  --# 固定 #
  )
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100)   := 'create_csv_rec_header';     -- プログラム名
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
    l_hdr_data_rec     g_get_data_hdr_rtype; -- INパラメータ.見積ヘッダー情報データ格納
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
    l_hdr_data_rec := i_hdr_data_rec;       -- 見積明細情報データ
--
    -- ======================
    -- CSV出力処理 
    -- ======================
    BEGIN
      -- データ作成
      lv_data := cv_sep_wquot || l_hdr_data_rec.company_cd || cv_sep_wquot                     -- 会社コード
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.quote_number           || cv_sep_wquot -- 見積書番号
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.reference_quote_number || cv_sep_wquot -- 参照見積書番号
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.quote_revision_number)                         -- 版数
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.quote_type             || cv_sep_wquot -- 見積種類
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.account_number_for_sale|| cv_sep_wquot -- 販売先顧客番号
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.account_number         || cv_sep_wquot -- 顧客コード
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.publish_date,'yyyymmdd')                       -- 発行日
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.employee_number        || cv_sep_wquot -- 担当者コード
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.deliv_place            || cv_sep_wquot -- 納入場所
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.name                   || cv_sep_wquot -- 支払条件
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.quote_info_start_date,'yyyymmdd')              -- 見積情報期間(自)
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.quote_info_end_date,'yyyymmdd')                -- 見積情報期間(至)
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.quote_submit_name      || cv_sep_wquot -- 見積書提出先名称
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.special_note           || cv_sep_wquot -- 特記事項
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.status                 || cv_sep_wquot -- ステータス
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.deliv_price_tax_type   || cv_sep_wquot -- 店納価格税区分
        || cv_sep_com || cv_sep_wquot || l_hdr_data_rec.unit_type              || cv_sep_wquot -- 単価区分
        || cv_sep_com || TO_CHAR(l_hdr_data_rec.cprtn_date, 'yyyymmddhh24miss')                -- 連携日時
      ;
--
      -- データ出力
      UTL_FILE.PUT_LINE(
        file   => gf_file_hand_header
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
                      ,iv_name         => cv_tkn_number_15                         --メッセージコード
                      ,iv_token_name1  => cv_tkn_estmt_no                          --トークンコード1
                      ,iv_token_value1 => l_hdr_data_rec.quote_number              --トークン値1
                      ,iv_token_name2  => cv_tkn_estmt_type                        --トークンコード2
                      ,iv_token_value2 => l_hdr_data_rec.quote_type                --トークン値2
                      ,iv_token_name3  => cv_tkn_estmt_edtn                        --トークンコード3
                      ,iv_token_value3 => l_hdr_data_rec.quote_revision_number     --トークン値3
                      ,iv_token_name4  => cv_tkn_errmsg                            --トークンコード3
                      ,iv_token_value4 => SQLERRM                                  --トークン値3
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
  END create_csv_rec_header;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file_lines
   * Description      : 見積明細情報CSVファイルクローズ処理(A-13)
   ***********************************************************************************/
  PROCEDURE close_csv_file_lines(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file_lines';  -- プログラム名
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
        file => gf_file_hand_lines
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
  END close_csv_file_lines;
--
  /**********************************************************************************
   * Procedure Name   : close_csv_file_header
   * Description      : 見積ヘッダ情報CSVファイルクローズ処理(A-14)
   ***********************************************************************************/
  PROCEDURE close_csv_file_header(
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
    cv_prg_name   CONSTANT VARCHAR2(100) := 'close_csv_file_header';  -- プログラム名
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
        file => gf_file_hand_header
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
  END close_csv_file_header;
--
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
    lv_csv_nm_hdr   VARCHAR2(2000); -- CSVファイル名(見積ヘッダ)
    lv_csv_nm_lns   VARCHAR2(2000); -- CSVファイル名(見積明細)
    lv_org_id       VARCHAR2(2000); -- ORG_ID
    -- ファイルオープン確認戻り値格納
    lb_fopn_retcd_hdr   BOOLEAN;
    lb_fopn_retcd_lns   BOOLEAN;
    --
    lt_quote_header_id xxcso_quote_headers.quote_header_id%TYPE;
--
    -- *** ローカル・カーソル ***
    -- 見積ヘッダ情報抽出カーソル
    CURSOR get_headers_data_cur
    IS
      /* 2009.04.16 K.Satomura T1_0172,T1_0508対応 START */
      --SELECT   xqh.quote_header_id          quote_header_id         -- 見積ヘッダーID
      --        ,xqh.quote_number             quote_number            -- 見積書番号
      --        ,xqh.reference_quote_number   reference_quote_number  -- 参照見積書番号
      --        ,xqh.quote_revision_number    quote_revision_number   -- 版
      --        ,xqh.quote_type               quote_type              -- 見積種類
      --        ,xqh.account_number           account_number          -- 顧客コード
      --        ,xqh.publish_date             publish_date            -- 発行日
      --        ,xqh.employee_number          employee_number         -- 担当者コード
      --        ,xqh.deliv_place              deliv_place             -- 納入場所
      --        ,xqh.quote_info_start_date    quote_info_start_date   -- 見積情報期間(自)
      --        ,xqh.quote_info_end_date      quote_info_end_date     -- 見積情報期間(至)
      --        ,xqh.quote_submit_name        quote_submit_name       -- 見積書提出先名称
      --        ,xqh.special_note             special_note            -- 特記事項
      --        ,xqh.status                   status                  -- ステータス
      --        ,xqh.deliv_price_tax_type     deliv_price_tax_type    -- 店納価格税区分
      --        ,xqh.unit_type                unit_type               -- 単価区分
      SELECT TRANSLATE(xqh.quote_header_id, CHR(10) || CHR(13), '  ')        quote_header_id        -- 見積ヘッダーID
            ,TRANSLATE(xqh.quote_number, CHR(10) || CHR(13), '  ')           quote_number           -- 見積書番号
            ,TRANSLATE(xqh.reference_quote_number, CHR(10) || CHR(13), '  ') reference_quote_number -- 参照見積書番号
            ,TRANSLATE(xqh.quote_revision_number, CHR(10) || CHR(13), '  ')  quote_revision_number  -- 版
            ,TRANSLATE(xqh.quote_type, CHR(10) || CHR(13), '  ')             quote_type             -- 見積種類
            ,TRANSLATE(xqh.account_number, CHR(10) || CHR(13), '  ')         account_number         -- 顧客コード
            ,TRANSLATE(xqh.publish_date, CHR(10) || CHR(13), '  ')           publish_date           -- 発行日
            ,TRANSLATE(xqh.employee_number, CHR(10) || CHR(13), '  ')        employee_number        -- 担当者コード
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xqh.deliv_place, CHR(10) || CHR(13), '  ')),1, 60)      deliv_place            -- 納入場所
            ,TRANSLATE(xqh.quote_info_start_date, CHR(10) || CHR(13), '  ')  quote_info_start_date  -- 見積情報期間(自)
            ,TRANSLATE(xqh.quote_info_end_date, CHR(10) || CHR(13), '  ')    quote_info_end_date    -- 見積情報期間(至)
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xqh.quote_submit_name, CHR(10) || CHR(13), '  ')), 1, 40) quote_submit_name    -- 見積書提出先名称
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xqh.special_note ,CHR(10) || CHR(13), '  ')), 1, 100)   special_note           -- 特記事項
            ,TRANSLATE(xqh.status, CHR(10) || CHR(13), '  ')                 status                 -- ステータス
            ,TRANSLATE(xqh.deliv_price_tax_type, CHR(10) || CHR(13), '  ')   deliv_price_tax_type   -- 店納価格税区分
            ,TRANSLATE(xqh.unit_type, CHR(10) || CHR(13), '  ')              unit_type              -- 単価区分
      /* 2009.04.16 K.Satomura T1_0172,T1_0508対応 END */
      FROM  xxcso_quote_headers  xqh      -- 見積ヘッダーテーブル
      WHERE (TRUNC(xqh.last_update_date)
              BETWEEN ld_from_value AND ld_to_value
             )
        AND xqh.status = cv_status_fix
    ;
--
    -- 見積明細情報抽出カーソル
    CURSOR get_lines_data_cur(
             it_qt_hdr_id IN xxcso_quote_headers.quote_header_id%TYPE  -- 見積ヘッダーID
           )
    IS
      /* 2009.04.16 K.Satomura T1_0172,T1_0508対応 START */
      --SELECT xql.quote_line_id                quote_line_id                -- 明細ID
      --       ,xrh.quote_number                quote_number                 -- 見積書番号
      --       ,msib.segment1                   inventory_item_code          -- 商品コード
      --       ,xql.quote_div                   quote_div                    -- 見積区分
      --       ,xql.usually_deliv_price         usually_deliv_price          -- 通常店納価格
      --       ,xql.this_time_deliv_price       this_time_deliv_price        -- 今回店納価格
      --       ,xql.usually_store_sale_price    usually_store_sale_price     -- 通常店頭価格
      --       ,xql.quotation_price             quotation_price              -- 建値
      --       ,xql.this_time_store_sale_price  this_time_store_sale_price   -- 今回店頭価格
      --       ,xql.usuall_net_price            usuall_net_price             -- 通常NET価格
      --       ,xql.this_time_net_price         this_time_net_price          -- 今回NET価格
      --       ,xql.amount_of_margin            amount_of_margin             -- マージン額
      --       ,xql.margin_rate                 margin_rate                  -- マージン率
      --       ,xql.sales_discount_price        sales_discount_price         -- 売上値引
      --       ,xql.business_price              business_price               -- 営業原価
      --       ,xql.quote_start_date            quote_start_date             -- 有効期間(自)
      --       ,xql.quote_end_date              quote_end_date               -- 有効期間(至)
      --       ,xql.remarks                     remarks                      -- 備考
      --       ,xql.line_order                  line_order                   -- 並び順
      --       ,xql.last_update_date            last_update_date             -- 最終更新日
      SELECT TRANSLATE(xql.quote_line_id, CHR(10), ' ')              quote_line_id              -- 明細ID
            ,TRANSLATE(xrh.quote_number, CHR(10), ' ')               quote_number               -- 見積書番号
            ,TRANSLATE(msib.segment1, CHR(10), ' ')                  inventory_item_code        -- 商品コード
            ,TRANSLATE(xql.quote_div, CHR(10), ' ')                  quote_div                  -- 見積区分
            ,TRANSLATE(xql.usually_deliv_price, CHR(10), ' ')        usually_deliv_price        -- 通常店納価格
            ,TRANSLATE(xql.this_time_deliv_price, CHR(10), ' ')      this_time_deliv_price      -- 今回店納価格
            ,TRANSLATE(xql.usually_store_sale_price, CHR(10), ' ')   usually_store_sale_price   -- 通常店頭価格
            ,TRANSLATE(xql.quotation_price, CHR(10), ' ')            quotation_price            -- 建値
            ,TRANSLATE(xql.this_time_store_sale_price, CHR(10), ' ') this_time_store_sale_price -- 今回店頭価格
            ,TRANSLATE(xql.usuall_net_price, CHR(10), ' ')           usuall_net_price           -- 通常NET価格
            ,TRANSLATE(xql.this_time_net_price, CHR(10), ' ')        this_time_net_price        -- 今回NET価格
            ,TRANSLATE(xql.amount_of_margin, CHR(10), ' ')           amount_of_margin           -- マージン額
            ,TRANSLATE(xql.margin_rate, CHR(10), ' ')                margin_rate                -- マージン率
            ,TRANSLATE(xql.sales_discount_price, CHR(10), ' ')       sales_discount_price       -- 売上値引
            ,TRANSLATE(xql.business_price, CHR(10), ' ')             business_price             -- 営業原価
            ,TRANSLATE(xql.quote_start_date, CHR(10), ' ')           quote_start_date           -- 有効期間(自)
            ,TRANSLATE(xql.quote_end_date, CHR(10), ' ')             quote_end_date             -- 有効期間(至)
            ,SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(TRANSLATE(
                     xql.remarks, CHR(10) || CHR(13), '  ')), 1, 20)  remarks                    -- 備考
            ,TRANSLATE(xql.line_order, CHR(10), ' ')                 line_order                 -- 並び順
            ,TRANSLATE(xql.last_update_date, CHR(10), ' ')           last_update_date           -- 最終更新日
      /* 2009.04.16 K.Satomura T1_0172,T1_0508対応 END */
      FROM   xxcso_quote_lines     xql        -- 見積明細テーブル
             ,xxcso_quote_headers  xrh        -- 見積ヘッダーテーブル
             ,mtl_system_items_b   msib       -- Disc品目マスタ
      WHERE  xql.quote_header_id = it_qt_hdr_id
        AND  xql.quote_header_id = xrh.quote_header_id
        AND  msib.inventory_item_id = xql.inventory_item_id
        AND  msib.organization_id   = TO_NUMBER(lv_org_id)
    ;
--
    -- *** ローカル・レコード ***
    l_get_headers_data_rec   get_headers_data_cur%ROWTYPE;
    l_get_lines_data_rec     get_lines_data_cur%ROWTYPE;
    l_get_hdr_data_rec       g_get_data_hdr_rtype;
    l_get_lns_data_rec       g_get_data_lns_rtype;
    -- *** ローカル例外 ***
    error_skip_data_expt           EXCEPTION;   -- 処理スキップ例外
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
    -- INパラメータ格納
    lv_from_value := iv_from_value;  -- パラメータ更新日 FROM
    lv_to_value   := iv_to_value;    -- パラメータ更新日 TO
--
    -- ========================================
    -- A-1.初期処理 
    -- ========================================
    init(
      iv_from_value   => lv_from_value       --   パラメータ更新日 FROM
     ,iv_to_value     => lv_to_value         --   パラメータ更新日 TO
     ,od_sysdate      => ld_sysdate          -- システム日付
     ,od_process_date => ld_process_date     -- 業務処理日付
     ,ov_errbuf       => lv_errbuf           -- エラー・メッセージ            --# 固定 #
     ,ov_retcode      => lv_retcode          -- リターン・コード              --# 固定 #
     ,ov_errmsg       => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
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
      id_process_date  => ld_process_date    -- 業務処理日付    
     ,io_from_value    => lv_from_value      -- パラメータ更新日 FROM
     ,io_to_value      => lv_to_value        -- パラメータ更新日 TO
     ,ov_errbuf        => lv_errbuf          -- エラー・メッセージ            --# 固定 #
     ,ov_retcode       => lv_retcode         -- リターン・コード              --# 固定 #
     ,ov_errmsg        => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
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
      io_from_value   => lv_from_value     -- パラメータ更新日 FROM
     ,io_to_value     => lv_to_value       -- パラメータ更新日 TO
     ,ov_errbuf       => lv_errbuf         -- エラー・メッセージ            --# 固定 #
     ,ov_retcode      => lv_retcode        -- リターン・コード              --# 固定 #
     ,ov_errmsg       => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
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
      ov_company_cd   => lv_company_cd     -- 会社コード（固定値001）
     ,ov_csv_dir      => lv_csv_dir        -- CSVファイル出力先
     ,ov_csv_nm_hdr   => lv_csv_nm_hdr     -- CSVファイル名(見積ヘッダ)
     ,ov_csv_nm_lns   => lv_csv_nm_lns     -- CSVファイル名(見積明細)
     ,ov_org_id       => lv_org_id         -- ORG_ID
     ,ov_errbuf       => lv_errbuf         -- エラー・メッセージ            --# 固定 #
     ,ov_retcode      => lv_retcode        -- リターン・コード              --# 固定 #
     ,ov_errmsg       => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-5.見積ヘッダ情報CSVファイルオープン
    -- ========================================
    open_csv_file_header(
      iv_csv_dir      => lv_csv_dir        -- CSVファイル出力先
     ,iv_csv_nm       => lv_csv_nm_hdr     -- CSVファイル名(見積ヘッダ)
     ,ov_errbuf       => lv_errbuf         -- エラー・メッセージ            --# 固定 #
     ,ov_retcode      => lv_retcode        -- リターン・コード              --# 固定 #
     ,ov_errmsg       => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-6.見積明細情報CSVファイルオープン
    -- ========================================
    open_csv_file_lines(
      iv_csv_dir      => lv_csv_dir        -- CSVファイル出力先
     ,iv_csv_nm       => lv_csv_nm_lns     -- CSVファイル名(見積明細)
     ,ov_errbuf       => lv_errbuf         -- エラー・メッセージ            --# 固定 #
     ,ov_retcode      => lv_retcode        -- リターン・コード              --# 固定 #
     ,ov_errmsg       => lv_errmsg         -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-7.見積ヘッダ情報抽出処理
    -- ========================================
    -- パラメータ更新日 編集
    ld_from_value := TO_DATE(lv_from_value,'yyyymmdd');
    ld_to_value   := TO_DATE(lv_to_value,'yyyymmdd');
--
    -- カーソルオープン
    OPEN get_headers_data_cur;
--
    <<get_hdr_data_loop>>
    LOOP
--
      BEGIN
--
        FETCH get_headers_data_cur INTO l_get_headers_data_rec;
        -- 処理対象件数格納
        gn_target_cnt := get_headers_data_cur%ROWCOUNT;
--
        -- 処理対象データが存在しなかった場合EXIT
        EXIT WHEN get_headers_data_cur%NOTFOUND
        OR  get_headers_data_cur%ROWCOUNT = 0;
--
        -- レコード変数初期化
        l_get_hdr_data_rec := NULL;
        -- 取得データを格納
        l_get_hdr_data_rec.company_cd             := lv_company_cd;                                 -- 会社コード
        l_get_hdr_data_rec.quote_number           := l_get_headers_data_rec.quote_number;           -- 見積書番号
        l_get_hdr_data_rec.reference_quote_number := l_get_headers_data_rec.reference_quote_number; -- 参照見積書番号
        l_get_hdr_data_rec.quote_revision_number  := l_get_headers_data_rec.quote_revision_number;  -- 版数
        l_get_hdr_data_rec.quote_type             := l_get_headers_data_rec.quote_type;             -- 見積種類
        l_get_hdr_data_rec.account_number         := l_get_headers_data_rec.account_number;         -- 顧客コード
        l_get_hdr_data_rec.publish_date           := l_get_headers_data_rec.publish_date;           -- 発行日
        l_get_hdr_data_rec.employee_number        := l_get_headers_data_rec.employee_number;        -- 担当者コード
        l_get_hdr_data_rec.deliv_place            := l_get_headers_data_rec.deliv_place;            -- 納入場所
        l_get_hdr_data_rec.quote_info_start_date  := l_get_headers_data_rec.quote_info_start_date;  -- 見積情報期間(自)
        l_get_hdr_data_rec.quote_info_end_date    := l_get_headers_data_rec.quote_info_end_date;    -- 見積情報期間(至)
        l_get_hdr_data_rec.quote_submit_name      := l_get_headers_data_rec.quote_submit_name;      -- 見積書提出先名称
        l_get_hdr_data_rec.special_note           := l_get_headers_data_rec.special_note;           -- 特記事項
        l_get_hdr_data_rec.status                 := l_get_headers_data_rec.status;                 -- ステータス
        l_get_hdr_data_rec.deliv_price_tax_type   := l_get_headers_data_rec.deliv_price_tax_type;   -- 店納価格税区分
        l_get_hdr_data_rec.unit_type              := l_get_headers_data_rec.unit_type;              -- 単価区分
        l_get_hdr_data_rec.cprtn_date             := ld_sysdate;                                    -- 連携日時
--
        -- 見積種別が帳合問屋先用(2)の場合
        IF (l_get_headers_data_rec.quote_type = cv_quote_type2) THEN
          -- ========================================
          -- A-8.販売先用見積ヘッダー抽出
          -- ========================================
          get_xqh_data_for_sale(
             io_hdr_data_rec    => l_get_hdr_data_rec -- 見積ヘッダデータ
            ,ov_errbuf          => lv_errbuf          -- エラー・メッセージ            --# 固定 #
            ,ov_retcode         => lv_retcode         -- リターン・コード              --# 固定 #
            ,ov_errmsg          => lv_errmsg          -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = cv_status_warn) THEN
            RAISE error_skip_data_expt;
          ELSIF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        -- 見積種別が販売先用(1)の場合
        ELSIF (l_get_headers_data_rec.quote_type = cv_quote_type1) THEN
          -- ========================================
          -- A-9.顧客使用目的マスタ抽出
          -- ========================================
          get_hcsu_data(
            id_process_date    => ld_process_date     -- 業務処理日付          
           ,io_hdr_data_rec    => l_get_hdr_data_rec  -- 見積ヘッダデータ
           ,ov_errbuf          => lv_errbuf           -- エラー・メッセージ            --# 固定 #
           ,ov_retcode         => lv_retcode          -- リターン・コード              --# 固定 #
           ,ov_errmsg          => lv_errmsg           -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END IF;
        -- ========================================
        -- A-10.見積明細情報抽出処理
        -- ========================================
        -- カーソルオープン
        OPEN get_lines_data_cur( 
               it_qt_hdr_id => l_get_headers_data_rec.quote_header_id -- 見積ヘッダーID
             );
--
        <<get_lns_data_loop>>
        LOOP
          FETCH get_lines_data_cur INTO l_get_lines_data_rec;
--
          -- 処理対象データが存在しなかった場合EXIT
          EXIT WHEN get_lines_data_cur%NOTFOUND
          OR  get_lines_data_cur%ROWCOUNT = 0;
--
          -- レコード変数初期化
          l_get_lns_data_rec := NULL;
          -- 取得データを格納
          l_get_lns_data_rec.company_cd                 := lv_company_cd;                                 -- 会社コード
          l_get_lns_data_rec.quote_line_id              := l_get_lines_data_rec.quote_line_id;            -- 明細ID
          l_get_lns_data_rec.quote_number               := l_get_lines_data_rec.quote_number;             -- 見積書番号
          l_get_lns_data_rec.inventory_item_code        := l_get_lines_data_rec.inventory_item_code;      -- 商品コード
          l_get_lns_data_rec.quote_div                  := l_get_lines_data_rec.quote_div;                -- 見積区分
          l_get_lns_data_rec.usually_deliv_price        := l_get_lines_data_rec.usually_deliv_price;      -- 通常店納価格
          l_get_lns_data_rec.this_time_deliv_price      := l_get_lines_data_rec.this_time_deliv_price;    -- 今回店納価格
          l_get_lns_data_rec.usually_store_sale_price   := l_get_lines_data_rec.usually_store_sale_price; -- 通常店頭価格
          l_get_lns_data_rec.quotation_price            := l_get_lines_data_rec.quotation_price;          -- 建値
          l_get_lns_data_rec.this_time_store_sale_price := l_get_lines_data_rec.this_time_store_sale_price; -- 今回店頭価格
          l_get_lns_data_rec.this_time_net_price        := l_get_lines_data_rec.this_time_net_price;      -- 今回NET価格
          l_get_lns_data_rec.amount_of_margin           := l_get_lines_data_rec.amount_of_margin;         -- マージン額
          l_get_lns_data_rec.margin_rate                := l_get_lines_data_rec.margin_rate;              -- マージン率
          l_get_lns_data_rec.sales_discount_price       := l_get_lines_data_rec.sales_discount_price;     -- 値引
          l_get_lns_data_rec.business_price             := l_get_lines_data_rec.business_price;           -- 営業原価
          l_get_lns_data_rec.quote_start_date           := l_get_lines_data_rec.quote_start_date;         -- 有効期間(自)
          l_get_lns_data_rec.quote_end_date             := l_get_lines_data_rec.quote_end_date;           -- 有効期間(至)
          l_get_lns_data_rec.remarks                    := l_get_lines_data_rec.remarks;                  -- 備考
          l_get_lns_data_rec.line_order                 := l_get_lines_data_rec.line_order;               -- 並び順
          l_get_lns_data_rec.usuall_net_price           := l_get_lines_data_rec.usuall_net_price;         -- 通常NET価格
          l_get_lns_data_rec.cprtn_date                 := ld_sysdate;                                    -- 連携日時
--
          -- ========================================
          -- A-11.見積明細情報CSV出力
          -- ========================================
          create_csv_rec_lines(
            i_lns_data_rec      => l_get_lns_data_rec   -- 見積明細情報データ
           ,ov_errbuf           => lv_errbuf            -- エラー・メッセージ            --# 固定 #
           ,ov_retcode          => lv_retcode           -- リターン・コード              --# 固定 #
           ,ov_errmsg           => lv_errmsg            -- ユーザー・エラー・メッセージ  --# 固定 #
          );
--
          IF (lv_retcode = cv_status_error) THEN
            RAISE global_process_expt;
          END IF;
--
        END LOOP get_lns_data_loop;
        -- カーソルクローズ
        CLOSE get_lines_data_cur;
        -- ========================================
        -- A-12.見積ヘッダー情報CSV出力
        -- ========================================
        create_csv_rec_header(
          i_hdr_data_rec   => l_get_hdr_data_rec    -- 見積ヘッダー情報データ
          ,ov_errbuf       => lv_errbuf             -- エラー・メッセージ            --# 固定 #
          ,ov_retcode      => lv_retcode            -- リターン・コード              --# 固定 #
          ,ov_errmsg       => lv_errmsg             -- ユーザー・エラー・メッセージ  --# 固定 #
         );
--
        IF (lv_retcode = cv_status_error) THEN
          RAISE global_process_expt;
        END IF;
        -- 成功件数カウント
        gn_normal_cnt := gn_normal_cnt + 1;
--
      EXCEPTION
        -- 販売先用顧客コード取得失敗のためスキップ
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
        -- 全体の処理ステータスに警告セット
        ov_retcode := cv_status_warn;
--
      END;
--
    END LOOP get_hdr_data_loop;
--
    -- カーソルクローズ
    CLOSE get_headers_data_cur;
--
--
    -- ========================================
    -- A-13.見積明細情報CSVファイルクローズ処理
    -- ========================================
    close_csv_file_lines(
      iv_csv_dir    => lv_csv_dir       -- CSVファイル出力先
     ,iv_csv_nm     => lv_csv_nm_lns    -- CSVファイル名(見積明細)
     ,ov_errbuf     => lv_errbuf        -- エラー・メッセージ            --# 固定 #
     ,ov_retcode    => lv_retcode       -- リターン・コード              --# 固定 #
     ,ov_errmsg     => lv_errmsg        -- ユーザー・エラー・メッセージ  --# 固定 #
    );
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ========================================
    -- A-14.見積ヘッダ情報CSVファイルクローズ処理
    -- ========================================
    close_csv_file_header(
      iv_csv_dir    => lv_csv_dir       -- CSVファイル出力先
     ,iv_csv_nm     => lv_csv_nm_hdr    -- CSVファイル名(見積ヘッダ)
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
      lb_fopn_retcd_hdr := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_header
                       );
      lb_fopn_retcd_lns := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_lines
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd_hdr = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand_header
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_hdr || CHR(10) ||
                   ''
      );
      END IF;
      IF (lb_fopn_retcd_lns = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand_lines
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_lns || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_headers_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_headers_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls3|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err1 || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_lines_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_lines_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls4|| CHR(10) ||
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
      lb_fopn_retcd_hdr := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_header
                       );
      lb_fopn_retcd_lns := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_lines
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd_hdr = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand_header
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_hdr || CHR(10) ||
                   ''
      );
      END IF;
      IF (lb_fopn_retcd_lns = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand_lines
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_lns || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_headers_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_headers_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls3|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err2 || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_lines_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_lines_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls4|| CHR(10) ||
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
      lb_fopn_retcd_hdr := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_header
                       );
      lb_fopn_retcd_lns := UTL_FILE.IS_OPEN (
                         file => gf_file_hand_lines
                       );
      -- ファイルがクローズされていない場合
      IF (lb_fopn_retcd_hdr = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand_header
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_hdr || CHR(10) ||
                   ''
      );
      END IF;
      IF (lb_fopn_retcd_lns = cb_true) THEN
        -- ファイルクローズ
        UTL_FILE.FCLOSE(
          file => gf_file_hand_lines
        );
      -- *** DEBUG_LOG ***
      -- ファイルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_fcls || CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || cv_msg_part ||
                   cv_debug_msg_fnm  || lv_csv_nm_lns || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_headers_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_headers_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls3|| CHR(10) ||
                   cv_prg_name       || cv_msg_part ||
                   cv_debug_msg_err3 || CHR(10) ||
                   ''
      );
      END IF;
      -- カーソルがクローズされていない場合
      IF (get_lines_data_cur%ISOPEN) THEN
        -- カーソルクローズ
        CLOSE get_lines_data_cur;
      -- *** DEBUG_LOG ***
      -- カーソルクローズしたことをログ出力
      fnd_file.put_line(
         which  => FND_FILE.LOG
        ,buff   => cv_debug_msg_ccls4|| CHR(10) ||
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
END XXCSO016A03C;
/
