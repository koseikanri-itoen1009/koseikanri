CREATE OR REPLACE PACKAGE BODY XXCOK015A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2018. All rights reserved.
 *
 * Package Name     : XXCOK015A04C(body)
 * Description      : アップロードファイルから支払案内書、販売報告書を出力
 * MD.050           : 支払案内書・販売報告書一括出力 MD050_COK_015_A04
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 一括出力情報(CSVファイル)の取込処理
 *  submain              メイン処理プロシージャ
 *  init_proc            初期処理(A-1)
 *  chk_validate_item    妥当性チェック処理(A-4)
 *  insert_xbsrw         支払案内書、販売報告書出力対象ワーク登録(A-5)
 *  chk_dupulicate_bm    支払案内書の出力対象重複チェック(A-6)
 *  submit_conc_bm_rep   支払案内書コンカレント発行処理
 *  submit_conc_bm_rep   販売報告書コンカレント発行処理
 *  del_file_upload_data ファイルアップロードデータの削除(A-8)
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2018/07/18    1.0   K.Nara           新規作成
 *  2018/08/07    1.1   K.Nara           E_本稼動_15005 支払案内書と販売報告書の販売期間を合わせる対応
 *                                       （支払案内書（印刷）の案内書発行年月をアップロード値＋1ヶ月とする）
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
  ------------------------------------------------------------
  -- ユーザー定義グローバル定数
  ------------------------------------------------------------
  -- パッケージ定義
  cv_pkg_name           CONSTANT VARCHAR2(12) := 'XXCOK015A04C';                 -- パッケージ名
  -- 初期値
  cn_zero               CONSTANT NUMBER       := 0;                              -- 数値:0
  cn_one                CONSTANT NUMBER       := 1;                              -- 数値:1
  cv_zero               CONSTANT VARCHAR2(1)  := '0';                            -- 文字:0
  cv_one                CONSTANT VARCHAR2(1)  := '1';                            -- 文字:1
  cv_msg_wq             CONSTANT VARCHAR2(1)  := '"';                            -- ダブルクォーテイション
  cv_msg_c              CONSTANT VARCHAR2(1)  := ',';                            -- コンマ
  cv_csv_sep            CONSTANT VARCHAR2(1)  := ',';                            -- CSVセパレータ
  cv_yes                CONSTANT VARCHAR2(1)  := 'Y';                            -- 文字:Y
  cv_no                 CONSTANT VARCHAR2(1)  := 'N';                            -- 文字:N
  cv_output             CONSTANT VARCHAR2(6)  := 'OUTPUT';                       -- ヘッダログ出力
  -- アプリケーション短縮名
  cv_ap_type_xxccp      CONSTANT VARCHAR2(5)  := 'XXCCP';                        -- 共通
  cv_ap_type_xxcok      CONSTANT VARCHAR2(5)  := 'XXCOK';                        -- 個別開発
  cv_ap_type_xxcos      CONSTANT VARCHAR2(5)  := 'XXCOS';                        -- 販売
  -- ステータス・コード
  cv_status_check       CONSTANT VARCHAR2(1)  := '9';                            -- チェックエラー:9
  cv_status_lock        CONSTANT VARCHAR2(1)  := '7';                            -- ロックエラー:7
  cv_status_update      CONSTANT VARCHAR2(1)  := '8';                            -- 更新エラー:8
  cv_status_insert      CONSTANT VARCHAR2(1)  := '9';                            -- 挿入エラー:9
  -- 共通メッセージ定義
  cv_normal_msg         CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90004';             -- 正常終了メッセージ
  cv_warn_msg           CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90005';             -- 警告終了メッセージ
  cv_error_msg          CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90006';             -- エラー終了メッセージ
  cv_mainmsg_90000      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90000';             -- 対象件数出力
  cv_mainmsg_90001      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90001';             -- 成功件数出力
  cv_mainmsg_90002      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90002';             -- エラー件数出力
  cv_mainmsg_90003      CONSTANT VARCHAR2(16) := 'APP-XXCCP1-90003';             -- スキップ件数出力
  -- 個別メッセージ定義
  cv_prmmsg_00016       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00016';             -- ファイルIDパラメータ
  cv_prmmsg_00017       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00017';             -- ファイルパターンパラメータ
  cv_errmsg_00028       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00028';             -- 業務処理日付取得エラー
  cv_errmsg_00003       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00003';             -- プロファイル取得エラー
  cv_errmsg_00061       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00061';             -- ファイルアップロードロックエラー
  cv_errmsg_00041       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00041';             -- BLOBデータ変換エラー
  cv_errmsg_00062       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00062';             -- ファイルアップロードIF削除エラー
  cv_errmsg_00015       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-00015';             -- クイックコード取得エラー
  cv_errmsg_10547       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10547';             -- 項目数相違エラーメッセージ
  cv_errmsg_10548       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10548';             -- 項目不備エラーメッセージ
  cv_errmsg_10549       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10549';             -- 出力区分指定エラーメッセージ
  cv_errmsg_10550       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10550';             -- 対象年月書式設定エラーメッセージ
  cv_errmsg_10551       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10551';             -- 仕入先、顧客未設定エラーメッセージ
  cv_errmsg_10552       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10552';             -- 支払案内書、仕入先値リストエラー
  cv_errmsg_10553       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10553';             -- 支払案内書、顧客マスタエラー
  cv_errmsg_10554       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10554';             -- 販売報告書、仕入先値リストエラー
  cv_errmsg_10555       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10555';             -- 販売報告書、顧客値リストエラー
  cv_errmsg_10556       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10556';             -- 支払案内書重複エラーメッセージ
  cv_errmsg_10557       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10557';             -- コンカレント起動エラー
  cv_errmsg_10558       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10558';             -- アップロード処理対象なしエラー
  cv_errmsg_10559       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10559';             -- 発行コンカレントメッセージ
  cv_errmsg_10560       CONSTANT VARCHAR2(16) := 'APP-XXCOK1-10560';             -- コンカレント名取得エラーメッセージ
  -- メッセージトークン定義
  cv_tkn_file_id        CONSTANT VARCHAR2(7)  := 'FILE_ID';                      -- ファイルIDトークン
  cv_tkn_format         CONSTANT VARCHAR2(6)  := 'FORMAT';                       -- ファイルパターントークン
  cv_tkn_profile        CONSTANT VARCHAR2(7)  := 'PROFILE';                      -- プロファイルトークン
  cv_tkn_user_id        CONSTANT VARCHAR2(7)  := 'USER_ID';                      -- ユーザIDトークン
  cv_tkn_table          CONSTANT VARCHAR2(5)  := 'TABLE';                        -- テーブル
  cv_tkn_record_no      CONSTANT VARCHAR2(20) := 'RECORD_NO';                    -- レコードNo
  cv_tkn_errmsg         CONSTANT VARCHAR2(20) := 'ERRMSG';                       -- エラー内容詳細
  cv_tkn_file_name      CONSTANT VARCHAR2(20) := 'FILE_NAME';                    -- ファイル名称
  cv_tkn_item           CONSTANT VARCHAR2(20) := 'ITEM';                         -- 項目
  cv_tkn_output_num     CONSTANT VARCHAR2(20) := 'OUTPUT_NUM';                   -- 出力番号
  cv_tkn_target_date    CONSTANT VARCHAR2(20) := 'TARGET_DATE';                  -- 対象年月
  cv_tkn_row_num        CONSTANT VARCHAR2(7)  := 'ROW_NUM';                      -- エラー行トークン
  cv_tkn_vend_code      CONSTANT VARCHAR2(11) := 'VENDOR_CODE';                  -- 仕入先コードトークン
  cv_tkn_cust_code      CONSTANT VARCHAR2(13) := 'CUST_CODE';                    -- 顧客コードトークン
  cv_tkn_conc           CONSTANT VARCHAR2(30) := 'CONC';                         -- コンカレント短縮名
  cv_tkn_conc_name      CONSTANT VARCHAR2(30) := 'CONC_NAME';                    -- コンカレント名
  cv_tkn_concmsg        CONSTANT VARCHAR2(30) := 'CONCMSG';                      -- コンカレントメッセージ
  cv_tkn_request_id     CONSTANT VARCHAR2(30) := 'REQUEST_ID';                   -- 要求ID
  cv_tkn_count          CONSTANT VARCHAR2(5)  := 'COUNT';                        -- 件数出力トークン
  cv_bm_rep_conc        CONSTANT VARCHAR2(50) := 'XXCOK015A03R3';                -- 支払案内書(印刷)コンカレント
  cv_sales_rep_conc     CONSTANT VARCHAR2(50) := 'XXCOS002A066R';                -- 販売報告書コンカレント
  cv_manager_flag       CONSTANT VARCHAR2(1)  := 'Y';                            -- 管理者フラグ
  cv_execute_type_4     CONSTANT VARCHAR2(1)  := '4';                            -- アップロード起動
  cv_yyyymm             CONSTANT VARCHAR2(6)  := 'YYYYMM';                       -- 対象年月書式
  cv_no_bm              CONSTANT VARCHAR2(1)  := '5';                            -- BM支払区分 5:支払無し
  cv_flag_y             CONSTANT VARCHAR2(1)  := 'Y';                            -- 'Y'
--
  cv_file_id_split      CONSTANT VARCHAR2(5) := '360';  --分割出力
  cv_file_id_all        CONSTANT VARCHAR2(5) := '361';  --一括出力
  -- 出力帳票
  cn_bm_rep             CONSTANT NUMBER := 1;  --支払案内書
  cn_sales_rep          CONSTANT NUMBER := 2;  --販売報告書
  cn_both_rep           CONSTANT NUMBER := 3;  --両方
  ------------------------------------------------------------
  -- ユーザー定義グローバル変数
  ------------------------------------------------------------
  gn_item_cnt                 NUMBER := 0;                      -- CSV規定項目数
  -- チェック項目格納レコード
  TYPE g_chk_item_rtype IS RECORD(
      meaning           fnd_lookup_values.meaning%TYPE    -- 項目名称
    , attribute1        fnd_lookup_values.attribute1%TYPE -- 項目の長さ
    , attribute2        fnd_lookup_values.attribute2%TYPE -- 項目の長さ（小数点以下）
    , attribute3        fnd_lookup_values.attribute3%TYPE -- 必須フラグ
    , attribute4        fnd_lookup_values.attribute4%TYPE -- 属性
  );
  TYPE g_chk_item_ttype       IS TABLE OF g_chk_item_rtype INDEX BY PLS_INTEGER;
  g_chk_item_tab              g_chk_item_ttype;                 -- 項目チェック
  -- チェック済データ格納レコード
  TYPE g_check_data_rtype IS RECORD (
    output_num          xxcok_bm_sales_rep_work.output_num%TYPE      -- 出力番号
   ,output_rep          xxcok_bm_sales_rep_work.output_rep%TYPE      -- 出力帳票
   ,target_ym           xxcok_bm_sales_rep_work.target_ym%TYPE       -- 対象年月
   ,vendor_code         xxcok_bm_sales_rep_work.vendor_code%TYPE     -- 仕入先コード
   ,customer_code       xxcok_bm_sales_rep_work.customer_code%TYPE   -- 顧客コード
  );
  TYPE g_check_data_ttype IS TABLE OF g_check_data_rtype INDEX BY BINARY_INTEGER;
  gt_check_data         g_check_data_ttype;                          -- チェック済データ退避
  --
  gd_proc_date          DATE           := NULL;            -- 業務処理日付
  gt_csv_data           xxcok_common_pkg.g_split_csv_tbl;  -- CSV分割データ（文字区切り処理後）
  gt_bm_rep_conc_name       fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;  --支払案内書コンカレント名
  gt_sales_rep_conc_name    fnd_concurrent_programs_vl.user_concurrent_program_name%TYPE;  --販売報告書コンカレント名
  ------------------------------------------------------------
  -- ユーザー定義例外
  ------------------------------------------------------------
  -- 例外
  global_lock_expt       EXCEPTION; -- グローバル例外
  -- プラグマ
  PRAGMA EXCEPTION_INIT(global_lock_expt, -54);
--
  /**********************************************************************************
   * Procedure Name   : del_file_upload_data
   * Description      : ファイルアップロードデータの削除(A-8)
   ***********************************************************************************/
  PROCEDURE del_file_upload_data(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,in_file_id IN NUMBER    -- ファイルID
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'del_file_upload_data'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_out_msg VARCHAR2(2000);  -- メッセージ
    lb_retcode BOOLEAN;         -- APIリターン・メッセージ用
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- ファイルアップロード削除ロックカーソル定義
    CURSOR file_delete_cur(
       in_file_id IN NUMBER -- ファイルID
    )
    IS
      SELECT xmf.file_id AS file_id          -- ファイルID
      FROM   xxccp_mrp_file_ul_interface xmf -- ファイルアップロードテーブル
      WHERE  xmf.file_id = in_file_id
      FOR UPDATE NOWAIT;
    --===============================
    -- ローカル例外
    --===============================
    delete_err_expt EXCEPTION; -- 削除エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    -------------------------------------------------
    -- 1.ファイルアップロード削除ロック処理
    -------------------------------------------------
    -- ロック処理
    OPEN file_delete_cur(
       in_file_id -- ファイルID
    );
    CLOSE file_delete_cur;
    -------------------------------------------------
    -- 2.ファイルアップロード削除処理
    -------------------------------------------------
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE xmf.file_id = in_file_id;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE delete_err_expt;
    END;
  --
  EXCEPTION
    -- *** ロック例外ハンドラ ****
    WHEN global_lock_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00061
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    -- *** 削除例外ハンドラ ***
    WHEN delete_err_expt THEN
      -- メッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00062
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(in_file_id)
                    );    
      -- メッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
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
  END del_file_upload_data;
  --
  /**********************************************************************************
   * Procedure Name   : submit_conc_bm_rep
   * Description      : 支払案内書コンカレント発行処理
   ***********************************************************************************/
  PROCEDURE submit_conc_bm_rep(
     ov_errbuf     OUT VARCHAR2           -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2           -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2           -- ユーザー・エラー・メッセージ
    ,in_output_num IN  NUMBER             -- 出力番号
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submit_conc_bm_rep'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    lv_out_msg     VARCHAR2(2000);  -- メッセージ
    ln_request_id  NUMBER;
    lb_retcode     BOOLEAN;         -- APIリターン・メッセージ用
    --===============================
    -- ローカル例外
    --===============================
    submit_conc_expt           EXCEPTION;   -- コンカレント発行エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -------------------------------------------------
    -- 1.「支払案内書印刷（明細）_事務センター」コンカレント発行
    -------------------------------------------------
    ln_request_id := fnd_request.submit_request(
      application   => cv_ap_type_xxcok
     ,program       => cv_bm_rep_conc                -- 支払案内書印刷（明細）_事務センター
     ,description   => NULL
     ,start_time    => NULL
     ,sub_request   => FALSE
     ,argument1     => NULL                          --問合せ拠点
     ,argument2     => NULL                          --案内書発行年月
     ,argument3     => NULL                          --支払先
     ,argument4     => cn_request_id                 --要求ID
     ,argument5     => in_output_num                 --出力番号
    );
    -- 正常以外の場合
    IF ( ln_request_id = 0 ) THEN
      RAISE submit_conc_expt;
    END IF;
--
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_errmsg_10559
                    ,iv_token_name1  => cv_tkn_output_num
                    ,iv_token_value1 => TO_CHAR(in_output_num)
                    ,iv_token_name2  => cv_tkn_conc_name
                    ,iv_token_value2 => gt_bm_rep_conc_name
                    ,iv_token_name3  => cv_tkn_request_id
                    ,iv_token_value3 => TO_CHAR(ln_request_id)
                  );    
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero          -- 改行
                  );
--
  EXCEPTION
--
    ----------------------------------------------------------
    -- コンカレント発行例外ハンドラ
    ----------------------------------------------------------
    WHEN submit_conc_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10557
                      ,iv_token_name1  => cv_tkn_conc             -- トークンコード１
                      ,iv_token_value1 => cv_bm_rep_conc          -- コンカレント名
                      ,iv_token_name2  => cv_tkn_concmsg          -- トークンコード２
                      ,iv_token_value2 => TO_CHAR(ln_request_id)  -- 戻り値
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT
                      ,iv_message    => lv_out_msg       -- メッセージ
                      ,in_new_line   => cn_one           -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submit_conc_bm_rep;
  --
  /**********************************************************************************
   * Procedure Name   : submit_conc_sales_rep
   * Description      : 販売報告書コンカレント発行処理
   ***********************************************************************************/
  PROCEDURE submit_conc_sales_rep(
     ov_errbuf     OUT VARCHAR2           -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2           -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2           -- ユーザー・エラー・メッセージ
    ,in_output_num IN  NUMBER             -- 出力番号
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submit_conc_sales_rep'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
    lv_out_msg     VARCHAR2(2000);  -- メッセージ
    ln_request_id  NUMBER;
    lb_retcode     BOOLEAN;         -- APIリターン・メッセージ用
    --===============================
    -- ローカル例外
    --===============================
    submit_conc_expt           EXCEPTION;   -- コンカレント発行エラー
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -------------------------------------------------
    -- 1.「自販機販売報告書アップロード指定」コンカレント発行
    -------------------------------------------------
    ln_request_id := fnd_request.submit_request(
      application   => cv_ap_type_xxcos
     ,program       => cv_sales_rep_conc               -- 自販機販売報告書アップロード指定
     ,description   => NULL
     ,start_time    => NULL
     ,sub_request   => FALSE
     ,argument1     => cv_manager_flag    -- 管理者フラグ
     ,argument2     => cv_execute_type_4  -- 実行区分
     ,argument3     => NULL
     ,argument4     => NULL
     ,argument5     => NULL
     ,argument6     => NULL
     ,argument7     => NULL
     ,argument8     => NULL
     ,argument9     => NULL
     ,argument10    => NULL
     ,argument11    => NULL
     ,argument12    => NULL
     ,argument13    => NULL
     ,argument14    => NULL
     ,argument15    => NULL
     ,argument16    => NULL
     ,argument17    => NULL
     ,argument18    => NULL
     ,argument19    => NULL
     ,argument20    => cn_request_id                 --要求ID
     ,argument21    => in_output_num                 --出力番号
    );
    -- 正常以外の場合
    IF ( ln_request_id = 0 ) THEN
      RAISE submit_conc_expt;
    END IF;
--
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_errmsg_10559
                    ,iv_token_name1  => cv_tkn_output_num
                    ,iv_token_value1 => TO_CHAR(in_output_num)
                    ,iv_token_name2  => cv_tkn_conc_name
                    ,iv_token_value2 => gt_sales_rep_conc_name
                    ,iv_token_name3  => cv_tkn_request_id
                    ,iv_token_value3 => TO_CHAR(ln_request_id)
                  );    
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero          -- 改行
                  );
--
  EXCEPTION
--
    ----------------------------------------------------------
    -- コンカレント発行例外ハンドラ
    ----------------------------------------------------------
    WHEN submit_conc_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10557
                      ,iv_token_name1  => cv_tkn_conc             -- トークンコード１
                      ,iv_token_value1 => cv_sales_rep_conc       -- コンカレント名
                      ,iv_token_name2  => cv_tkn_concmsg          -- トークンコード２
                      ,iv_token_value2 => TO_CHAR(ln_request_id)  -- 戻り値
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT
                      ,iv_message    => lv_out_msg       -- メッセージ
                      ,in_new_line   => cn_one           -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
      --
--#################################  固定例外処理部 START   ####################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--#####################################  固定部 END   ##########################################
--
  END submit_conc_sales_rep;
  --
  /**********************************************************************************
   * Procedure Name   : insert_xbsrw
   * Description      : 支払案内書、販売報告書出力対象ワーク登録(A-5)
   ***********************************************************************************/
  PROCEDURE insert_xbsrw(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'insert_xbsrw';     -- プログラム名
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ln_line_cnt                    PLS_INTEGER;                                 -- CSV処理行カウンタ
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    ov_retcode := cv_status_normal;
    -- ===============================
    -- アップロードデータワーク登録
    -- ===============================
    << ins_xbsrw_loop >>
    FOR ln_line_cnt IN 1..gt_check_data.COUNT LOOP
      INSERT INTO xxcok_bm_sales_rep_work (
          OUTPUT_NUM                                --出力番号
        , OUTPUT_REP                                --出力帳票
        , TARGET_YM                                 --対象年月
        , VENDOR_CODE                               --仕入先コード
        , CUSTOMER_CODE                             --顧客コード
        , CREATED_BY                                --作成者
        , CREATION_DATE                             --作成日
        , LAST_UPDATED_BY                           --最終更新者
        , LAST_UPDATE_DATE                          --最終更新日
        , LAST_UPDATE_LOGIN                         --最終更新ログイン
        , REQUEST_ID                                --要求ID
        , PROGRAM_APPLICATION_ID                    --コンカレント・プログラム・アプリケーションID
        , PROGRAM_ID                                --コンカレント・プログラムID
        , PROGRAM_UPDATE_DATE                       --プログラム更新日
      ) VALUES (
          gt_check_data(ln_line_cnt).output_num     --出力番号
        , DECODE(gt_check_data(ln_line_cnt).output_rep, cn_both_rep, cn_bm_rep, gt_check_data(ln_line_cnt).output_rep)     --出力帳票
-- Ver.1.1 [障害E_本稼動_15005] SCSK K.Nara MOD START
--        , gt_check_data(ln_line_cnt).target_ym      --対象年月
        , DECODE(gt_check_data(ln_line_cnt).output_rep, cn_sales_rep, gt_check_data(ln_line_cnt).target_ym
                                                                    , TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(gt_check_data(ln_line_cnt).target_ym), cv_yyyymm), cn_one), cv_yyyymm))
                )  --対象年月
-- Ver.1.1 [障害E_本稼動_15005] SCSK K.Nara MOD END
        , gt_check_data(ln_line_cnt).vendor_code    --仕入先コード
        , gt_check_data(ln_line_cnt).customer_code  --顧客コード
        , cn_created_by                             --作成者
        , cd_creation_date                          --作成日
        , cn_last_updated_by                        --最終更新者
        , cd_last_update_date                       --最終更新日
        , cn_last_update_login                      --最終更新ログイン
        , cn_request_id                             --要求ID
        , cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
        , cn_program_id                             --コンカレント・プログラムID
        , cd_program_update_date                    --プログラム更新日
      );
      --
      IF gt_check_data(ln_line_cnt).output_rep = cn_both_rep THEN
        INSERT INTO xxcok_bm_sales_rep_work (
            OUTPUT_NUM                                --出力番号
          , OUTPUT_REP                                --出力帳票
          , TARGET_YM                                 --対象年月
          , VENDOR_CODE                               --仕入先コード
          , CUSTOMER_CODE                             --顧客コード
          , CREATED_BY                                --作成者
          , CREATION_DATE                             --作成日
          , LAST_UPDATED_BY                           --最終更新者
          , LAST_UPDATE_DATE                          --最終更新日
          , LAST_UPDATE_LOGIN                         --最終更新ログイン
          , REQUEST_ID                                --要求ID
          , PROGRAM_APPLICATION_ID                    --コンカレント・プログラム・アプリケーションID
          , PROGRAM_ID                                --コンカレント・プログラムID
          , PROGRAM_UPDATE_DATE                       --プログラム更新日
        ) VALUES (
            gt_check_data(ln_line_cnt).output_num     --出力番号
          , cn_sales_rep                              --出力帳票
          , gt_check_data(ln_line_cnt).target_ym      --対象年月
          , gt_check_data(ln_line_cnt).vendor_code    --仕入先コード
          , gt_check_data(ln_line_cnt).customer_code  --顧客コード
          , cn_created_by                             --作成者
          , cd_creation_date                          --作成日
          , cn_last_updated_by                        --最終更新者
          , cd_last_update_date                       --最終更新日
          , cn_last_update_login                      --最終更新ログイン
          , cn_request_id                             --要求ID
          , cn_program_application_id                 --コンカレント・プログラム・アプリケーションID
          , cn_program_id                             --コンカレント・プログラムID
          , cd_program_update_date                    --プログラム更新日
        );
      END IF;
      --
    END LOOP ins_xbsrw_loop;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END insert_xbsrw;
  --
  /**********************************************************************************
   * Procedure Name   : chk_dupulicate_bm
   * Description      : 支払案内書の出力対象重複チェック(A-6)
   ***********************************************************************************/
  PROCEDURE chk_dupulicate_bm(
    ov_errbuf                      OUT VARCHAR2        -- エラー・メッセージ
  , ov_retcode                     OUT VARCHAR2        -- リターン・コード
  , ov_errmsg                      OUT VARCHAR2        -- ユーザー・エラー・メッセージ
  )
  IS
    --==================================================
    -- ローカル定数
    --==================================================
    cv_prg_name                    CONSTANT VARCHAR2(30) := 'chk_dupulicate_bm';     -- プログラム名
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 支払案内書 出力対象重複取得カーソル定義
    CURSOR dup_chk_cur(
      in_request_id IN NUMBER -- 要求ID
    ) IS
      SELECT xbsrw.output_num          AS output_num
            ,xbsrw.target_ym           AS target_ym
            ,cust_ven.customer_code    AS customer_code
            ,cust_ven.vendor_code      AS vendor_code
            ,COUNT(*)
      FROM xxcok_bm_sales_rep_work xbsrw
          ,( 
             SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N02) */
                    xca.customer_code            AS customer_code
                   ,xca.contractor_supplier_code AS vendor_code
             FROM   xxcmm_cust_accounts xca
                   ,xxcok_bm_sales_rep_work xbsrw
             WHERE xbsrw.request_id = in_request_id
             AND   xbsrw.output_rep = cn_bm_rep
             AND   xca.customer_code = NVL(xbsrw.customer_code, xca.customer_code)
             AND   xca.contractor_supplier_code = NVL(xbsrw.vendor_code, xca.contractor_supplier_code)
             UNION 
             SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N03) */
                    xca.customer_code         AS customer_code
                   ,xca.bm_pay_supplier_code1 AS vendor_code
             FROM   xxcmm_cust_accounts xca
                   ,xxcok_bm_sales_rep_work xbsrw
             WHERE xbsrw.request_id = in_request_id
             AND   xbsrw.output_rep = cn_bm_rep
             AND   xca.customer_code = NVL(xbsrw.customer_code, xca.customer_code)
             AND   xca.bm_pay_supplier_code1 = NVL(xbsrw.vendor_code, xca.bm_pay_supplier_code1)
             UNION 
             SELECT /*+ INDEX(xca XXCMM_CUST_ACCOUNTS_N04) */
                    xca.customer_code         AS customer_code
                   ,xca.bm_pay_supplier_code2 AS vendor_code
             FROM   xxcmm_cust_accounts xca
                   ,xxcok_bm_sales_rep_work xbsrw
             WHERE xbsrw.request_id = in_request_id
             AND   xbsrw.output_rep = cn_bm_rep
             AND   xca.customer_code = NVL(xbsrw.customer_code, xca.customer_code)
             AND   xca.bm_pay_supplier_code2 = NVL(xbsrw.vendor_code, xca.bm_pay_supplier_code2)
           ) cust_ven
      WHERE xbsrw.request_id = in_request_id
      AND   xbsrw.output_rep = cn_bm_rep
      AND   cust_ven.customer_code = NVL(xbsrw.customer_code, cust_ven.customer_code)
      AND   cust_ven.vendor_code = NVL(xbsrw.vendor_code, cust_ven.vendor_code)
      GROUP BY xbsrw.output_num
              ,xbsrw.target_ym
              ,cust_ven.customer_code
              ,cust_ven.vendor_code
      HAVING COUNT(*) > 1
      ;
    dup_chk_rec        dup_chk_cur%ROWTYPE;
    --==================================================
    -- ローカル変数
    --==================================================
    lv_errbuf                      VARCHAR2(5000) DEFAULT NULL;                 -- エラー・メッセージ
    lv_retcode                     VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_end_retcode                 VARCHAR2(1)    DEFAULT cv_status_normal;     -- リターン・コード
    lv_errmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- ユーザー・エラー・メッセージ
    lv_outmsg                      VARCHAR2(5000) DEFAULT NULL;                 -- 出力用メッセージ
    lb_retcode                     BOOLEAN        DEFAULT TRUE;                 -- メッセージ出力関数戻り値
    ln_line_cnt                    PLS_INTEGER;                                 -- CSV処理行カウンタ
    ln_title                       NUMBER;
--
  BEGIN
    --==================================================
    -- ステータス初期化
    --==================================================
    ov_retcode := cv_status_normal;
    --
    --==================================================
    -- 出力対象の重複取得
    --==================================================
    OPEN dup_chk_cur(
       cn_request_id
    );
    LOOP
      FETCH dup_chk_cur INTO dup_chk_rec;
      EXIT WHEN dup_chk_cur%NOTFOUND;
      --
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok                -- アプリケーション短縮名
                     , iv_name         => cv_errmsg_10556                 -- メッセージコード
                     , iv_token_name1  => cv_tkn_output_num               -- トークンコード1
                     , iv_token_value1 => TO_CHAR(dup_chk_rec.output_num) -- トークン値1
                     , iv_token_name2  => cv_tkn_target_date              -- トークンコード1
                     , iv_token_value2 => TO_CHAR(dup_chk_rec.target_ym)  -- トークン値2
                     , iv_token_name3  => cv_tkn_vend_code                -- トークンコード1
                     , iv_token_value3 => dup_chk_rec.vendor_code         -- トークン値3
                     , iv_token_name4  => cv_tkn_cust_code                -- トークンコード1
                     , iv_token_value4 => dup_chk_rec.customer_code       -- トークン値4
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_errmsg       -- メッセージ
                      ,in_new_line   => cn_zero         -- 改行
                    );
      gn_error_cnt := gn_error_cnt + 1;
      ov_retcode := cv_status_check;
    END LOOP;
    --
    CLOSE dup_chk_cur;
    --
--
  EXCEPTION
    -- *** 共通関数OTHERS例外 ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** OTHERS例外 ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_dupulicate_bm;
  --
  /**********************************************************************************
   * Procedure Name   : chk_validate_item（ループ部）
   * Description      : 妥当性チェック処理(A-4)
   ***********************************************************************************/
  PROCEDURE chk_validate_item(
     ov_errbuf     OUT VARCHAR2                                          -- エラー・メッセージ
    ,ov_retcode    OUT VARCHAR2                                          -- リターン・コード
    ,ov_errmsg     OUT VARCHAR2                                          -- ユーザー・エラー・メッセージ
    ,in_index      IN  PLS_INTEGER                                       -- 行番号
    ,in_col_cnt    IN  NUMBER                                            -- 項目数
    ,it_csv_data   IN  xxcok_common_pkg.g_split_csv_tbl
    ,ot_segment1   OUT xxcok_bm_sales_rep_work.output_num%TYPE           -- チェック後項目1：出力番号
    ,ot_segment2   OUT xxcok_bm_sales_rep_work.output_rep%TYPE           -- チェック後項目2：出力帳票
    ,ot_segment3   OUT xxcok_bm_sales_rep_work.target_ym%TYPE            -- チェック後項目3：対象年月
    ,ot_segment4   OUT xxcok_bm_sales_rep_work.vendor_code%TYPE          -- チェック後項目4：仕入先コード
    ,ot_segment5   OUT xxcok_bm_sales_rep_work.customer_code%TYPE        -- チェック後項目5：顧客コード
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'chk_validate_item'; -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf        VARCHAR2(5000);                                    -- エラー・メッセージ
    lv_retcode       VARCHAR2(1);                                       -- リターン・コード
    lv_errmsg        VARCHAR2(5000);                                    -- ユーザー・エラー・メッセージ
    ln_cnt           NUMBER;                                            -- カウンタ
    lb_retcode       BOOLEAN;                                           -- APIリターン・メッセージ用
    lb_retbool       BOOLEAN;                                           -- APIリターン・チェック用
    lv_out_msg       VARCHAR2(2000);                                    -- メッセージ
    lv_buf           VARCHAR2(1);
    ld_target_ym     DATE;
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode  := cv_status_normal;
    --
    -------------------------------------------------
    -- 項目数チェック
    -------------------------------------------------
    IF ( gn_item_cnt <> in_col_cnt ) THEN
      -- 項目数相違エラーメッセージ
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok -- アプリケーション短縮名
                     , iv_name         => cv_errmsg_10547  -- メッセージコード
                     , iv_token_name1  => cv_tkn_row_num   -- トークンコード1
                     , iv_token_value1 => in_index         -- トークン値1
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_errmsg       -- メッセージ
                      ,in_new_line   => cn_zero         -- 改行
                    );
      ov_retcode := cv_status_check;
    END IF;
    --
    IF ( ov_retcode = cv_status_check ) THEN
      RETURN;
    END IF;
    -------------------------------------------------
    -- 項目チェック
    -------------------------------------------------
    -- 項目チェックループ
    << item_check_loop >>
    FOR i IN g_chk_item_tab.FIRST .. g_chk_item_tab.COUNT LOOP
      --
      gt_csv_data(i) := TRIM( it_csv_data(i) );
      --
      -- 項目チェック共通関数
      xxccp_common_pkg2.upload_item_check(
          iv_item_name    => g_chk_item_tab(i).meaning    -- 項目名称
        , iv_item_value   => gt_csv_data(i)               -- 項目の値
        , in_item_len     => g_chk_item_tab(i).attribute1 -- 項目の長さ
        , in_item_decimal => g_chk_item_tab(i).attribute2 -- 項目の長さ(小数点以下)
        , iv_item_nullflg => g_chk_item_tab(i).attribute3 -- 必須フラグ
        , iv_item_attr    => g_chk_item_tab(i).attribute4 -- 項目属性
        , ov_errbuf       => lv_errbuf                    -- エラー・メッセージ           --# 固定 #
        , ov_retcode      => lv_retcode                   -- リターン・コード             --# 固定 #
        , ov_errmsg       => lv_errmsg                    -- ユーザー・エラー・メッセージ --# 固定 #
      );
      -- リターンコードが正常以外の場合
      IF ( lv_retcode <> cv_status_normal ) THEN
        -- 項目不備エラーメッセージ
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok            -- アプリケーション短縮名
                       , iv_name         => cv_errmsg_10548             -- メッセージコード
                       , iv_token_name1  => cv_tkn_item                 -- トークンコード1
                       , iv_token_value1 => g_chk_item_tab(i).meaning   -- トークン値1
                       , iv_token_name2  => cv_tkn_record_no            -- トークンコード2
                       , iv_token_value2 => in_index                    -- トークン値2
                       , iv_token_name3  => cv_tkn_errmsg               -- トークンコード3
                       , iv_token_value3 => lv_errmsg                   -- トークン値3
                       , iv_token_name4  => cv_tkn_row_num              -- トークンコード3
                       , iv_token_value4 => in_index                    -- トークン値3
                     );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT -- 出力帳票
                        ,iv_message    => lv_errmsg       -- メッセージ
                        ,in_new_line   => cn_zero         -- 改行
                      );
        --
        ov_retcode := cv_status_check;
        --
      END IF;
      --
    END LOOP item_check_loop;
    --
    -- 項目レベルでエラーがあれば、以降のチェックはスキップ
    IF ( ov_retcode = cv_status_check ) THEN
      RETURN;
    END IF;
    -------------------------------------------------
    -- 出力番号
    -------------------------------------------------
    ot_segment1 := TO_NUMBER(gt_csv_data(1));
    -------------------------------------------------
    -- 出力帳票
    -------------------------------------------------
    --妥当性チェック(1,2,3)
    IF gt_csv_data(2) NOT IN (cn_bm_rep, cn_sales_rep, cn_both_rep) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok       -- アプリケーション短縮名
                     , iv_name         => cv_errmsg_10549        -- メッセージコード
                     , iv_token_name1  => cv_tkn_row_num         -- トークンコード1
                     , iv_token_value1 => in_index               -- トークン値1
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT          -- 出力帳票
                      ,iv_message    => lv_errmsg                -- メッセージ
                      ,in_new_line   => cn_zero                  -- 改行
                    );
      ov_retcode := cv_status_check;
    ELSE
      ot_segment2 := TO_NUMBER(gt_csv_data(2));
    END IF;
    --
    -------------------------------------------------
    -- 対象年月
    -------------------------------------------------
    --妥当性チェック（YYYYMM書式）
    BEGIN
      ld_target_ym := TO_DATE(gt_csv_data(3), cv_yyyymm);
      ot_segment3 := TO_NUMBER(TO_CHAR(ld_target_ym, cv_yyyymm));
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                         iv_application  => cv_ap_type_xxcok       -- アプリケーション短縮名
                       , iv_name         => cv_errmsg_10550        -- メッセージコード
                       , iv_token_name1  => cv_tkn_row_num         -- トークンコード1
                       , iv_token_value1 => in_index               -- トークン値1
                     );
        lb_retcode := xxcok_common_pkg.put_message_f(
                         in_which      => FND_FILE.OUTPUT          -- 出力帳票
                        ,iv_message    => lv_errmsg                -- メッセージ
                        ,in_new_line   => cn_zero                  -- 改行
                      );
        ov_retcode := cv_status_check;
    END;
    --
    -------------------------------------------------
    -- 仕入先コード、顧客コード
    -------------------------------------------------
    -- 両方NULLはエラー
    IF gt_csv_data(4) IS NULL AND gt_csv_data(5) IS NULL THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok         -- アプリケーション短縮名
                     , iv_name         => cv_errmsg_10551          -- メッセージコード
                     , iv_token_name1  => cv_tkn_row_num           -- トークンコード1
                     , iv_token_value1 => in_index                 -- トークン値1
                   );
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT            -- 出力帳票
                      ,iv_message    => lv_errmsg                  -- メッセージ
                      ,in_new_line   => cn_zero                    -- 改行
                    );
      ov_retcode := cv_status_check;
    END IF;
    --
    -------------------------------------------------
    -- 値リスト存在チェック
    -------------------------------------------------
    IF gt_csv_data(2) IN (cn_bm_rep, cn_both_rep) AND gt_csv_data(4) IS NOT NULL THEN
      --支払案内書、仕入先値リスト存在チェック
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  po_vendors          pv
            , po_vendor_sites_all pvsa
        WHERE pv.vendor_id = pvsa.vendor_id
        AND   pvsa.attribute4 <> cv_no_bm
        AND   pvsa.org_id = fnd_global.org_id
        AND   pv.segment1 = gt_csv_data(4)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- アプリケーション短縮名
                         , iv_name         => cv_errmsg_10552        -- メッセージコード
                         , iv_token_name1  => cv_tkn_row_num         -- トークンコード1
                         , iv_token_value1 => in_index               -- トークン値1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- 出力帳票
                          ,iv_message    => lv_errmsg                -- メッセージ
                          ,in_new_line   => cn_zero                  -- 改行
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --
    IF gt_csv_data(2) IN (cn_bm_rep, cn_both_rep) AND gt_csv_data(5) IS NOT NULL THEN
      --支払案内書、販手条件マスタ存在チェック
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  xxcok_mst_bm_contract xmbc
        WHERE xmbc.calc_target_flag = cv_flag_y
        AND   xmbc.cust_code = gt_csv_data(5)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- アプリケーション短縮名
                         , iv_name         => cv_errmsg_10553        -- メッセージコード
                         , iv_token_name1  => cv_tkn_row_num         -- トークンコード1
                         , iv_token_value1 => in_index               -- トークン値1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- 出力帳票
                          ,iv_message    => lv_errmsg                -- メッセージ
                          ,in_new_line   => cn_zero                  -- 改行
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --
    IF gt_csv_data(2) IN (cn_sales_rep, cn_both_rep) AND gt_csv_data(4) IS NOT NULL AND gt_csv_data(5) IS NULL THEN
      --販売報告書、仕入先値リスト存在チェック
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  xxcos_vd_sales_vend_all_v xvsvav
        WHERE xvsvav.vendor_code = gt_csv_data(4)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- アプリケーション短縮名
                         , iv_name         => cv_errmsg_10554        -- メッセージコード
                         , iv_token_name1  => cv_tkn_row_num         -- トークンコード1
                         , iv_token_value1 => in_index               -- トークン値1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- 出力帳票
                          ,iv_message    => lv_errmsg                -- メッセージ
                          ,in_new_line   => cn_zero                  -- 改行
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --
    IF gt_csv_data(2) IN (cn_sales_rep, cn_both_rep) AND gt_csv_data(5) IS NOT NULL THEN
      --販売報告書、顧客値リスト存在チェック
      BEGIN
        SELECT 'x'
        INTO   lv_buf
        FROM  xxcos_vd_sales_cust_v xvscv
        WHERE xvscv.customer_code = gt_csv_data(5)
        AND   ROWNUM = 1
        ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_errmsg := xxccp_common_pkg.get_msg(
                           iv_application  => cv_ap_type_xxcok       -- アプリケーション短縮名
                         , iv_name         => cv_errmsg_10555        -- メッセージコード
                         , iv_token_name1  => cv_tkn_row_num         -- トークンコード1
                         , iv_token_value1 => in_index               -- トークン値1
                       );
          lb_retcode := xxcok_common_pkg.put_message_f(
                           in_which      => FND_FILE.OUTPUT          -- 出力帳票
                          ,iv_message    => lv_errmsg                -- メッセージ
                          ,in_new_line   => cn_zero                  -- 改行
                        );
          ov_retcode := cv_status_check;
      END;
    END IF;
    --無条件設定でも、エラーの場合は使用されない
    ot_segment4 := gt_csv_data(4);
    ot_segment5 := gt_csv_data(5);
  --
  EXCEPTION
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END chk_validate_item;
  --
  /***********************************************************************************
   * Procedure Name   : init_proc
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init_proc(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,in_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name               CONSTANT VARCHAR2(100) := 'init_proc'; -- プログラム名
    cv_tkn_lookup_value_set   CONSTANT VARCHAR2(20)  := 'LOOKUP_VALUE_SET';         -- タイプ
    cv_bm_sales_rep_item      CONSTANT VARCHAR2(30)  := 'XXCOK1_BM_SALES_REP_ITEM'; -- 支払案内書・販売報告書一括出力項目チェック
    ct_lang                   CONSTANT fnd_lookup_values.language%TYPE := USERENV('LANG');
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf      VARCHAR2(5000); -- エラー・メッセージ
    lv_retcode     VARCHAR2(1);    -- リターン・コード
    lv_errmsg      VARCHAR2(5000); -- ユーザー・エラー・メッセージ
    lv_out_msg     VARCHAR2(2000); -- メッセージ
    lb_retcode     BOOLEAN;        -- メッセージ戻り値
    lv_conc        VARCHAR2(50);   -- コンカレント短縮名
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 項目チェックカーソル
    CURSOR chk_item_cur
    IS
      SELECT flv.meaning       AS meaning     -- 項目名称
           , flv.attribute1    AS attribute1  -- 項目の長さ
           , flv.attribute2    AS attribute2  -- 項目の長さ（小数点以下）
           , flv.attribute3    AS attribute3  -- 必須フラグ
           , flv.attribute4    AS attribute4  -- 属性
      FROM   fnd_lookup_values flv
      WHERE  flv.lookup_type  = cv_bm_sales_rep_item
      AND    gd_proc_date BETWEEN NVL( flv.start_date_active, gd_proc_date )
                              AND NVL( flv.end_date_active, gd_proc_date )
      AND    flv.enabled_flag = cv_flag_y
      AND    flv.language     = ct_lang
      ORDER BY flv.lookup_code
    ;
    --===============================
    -- ローカル例外
    --===============================
    get_date_err_expt           EXCEPTION; -- 業務処理日付取得エラー
    get_item_chk_lookup_expt    EXCEPTION; -- 項目チェック用クイックコード取得エラー
    global_api_others_expt      EXCEPTION; -- APIエラー
    get_prof_err_expt           EXCEPTION; -- プロファイル取得エラー
    get_conc_name_err_expt      EXCEPTION; -- コンカレント名取得エラー
  --
  BEGIN
  --
    -------------------------------------------------
    -- 0.初期化
    -------------------------------------------------
    ov_retcode := cv_status_normal;
    gn_target_cnt := 0;
    gn_normal_cnt := 0;
    gn_error_cnt  := 0;
    -------------------------------------------------
    -- 1.コンカレント入力パラメータメッセージ出力
    -------------------------------------------------
    -- コンカレントパラメータ.ファイルIDメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00016
                    ,iv_token_name1  => cv_tkn_file_id
                    ,iv_token_value1 => TO_CHAR(in_file_id)
                  );
    -- コンカレントパラメータ.ファイルIDメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -- コンカレントパラメータ.フォーマットパターンメッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxcok
                    ,iv_name         => cv_prmmsg_00017
                    ,iv_token_name1  => cv_tkn_format
                    ,iv_token_value1 => iv_format
                  );
    -- コンカレントパラメータ.フォーマットパターンメッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_one          -- 改行
                  );
    -------------------------------------------------
    -- 2.業務処理日付取得
    -------------------------------------------------
    gd_proc_date := xxccp_common_pkg2.get_process_date;
    -- NULLの場合はエラー
    IF ( gd_proc_date IS NULL ) THEN
      RAISE get_date_err_expt;
    END IF;
    --
    -------------------------------------------------
    -- 3.項目チェック用定義取得
    -------------------------------------------------
    --カーソルのオープン
    OPEN chk_item_cur;
    -- データの一括取得
    FETCH chk_item_cur BULK COLLECT INTO g_chk_item_tab;
    -- カーソルクローズ
    CLOSE chk_item_cur;
    -- クイックコードが取得できない場合
    IF ( g_chk_item_tab.COUNT = 0 ) THEN
      RAISE get_item_chk_lookup_expt;
    END IF;
    --
    gn_item_cnt := g_chk_item_tab.COUNT;  --項目数取得
--
    -------------------------------------------------
    -- 4.コンカレント名取得
    -------------------------------------------------
    BEGIN
      lv_conc := cv_bm_rep_conc;
      SELECT user_concurrent_program_name
      INTO gt_bm_rep_conc_name
      FROM fnd_concurrent_programs_vl
      WHERE concurrent_program_name = lv_conc
      AND   enabled_flag = cv_yes
      ;
      --
      lv_conc := cv_sales_rep_conc;
      SELECT user_concurrent_program_name
      INTO gt_sales_rep_conc_name
      FROM fnd_concurrent_programs_vl
      WHERE concurrent_program_name = lv_conc
      AND   enabled_flag = cv_yes
      ;
      --
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE get_conc_name_err_expt;
    END;
    --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 業務処理日付取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_date_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00028
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 項目チェック用クイックコード取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_item_chk_lookup_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok          -- アプリケーション短縮名
                     , iv_name         => cv_errmsg_00015           -- メッセージコード
                     , iv_token_name1  => cv_tkn_lookup_value_set   -- トークンコード1
                     , iv_token_value1 => cv_bm_sales_rep_item      -- トークン値1
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- コンカレント名取得例外ハンドラ
    ----------------------------------------------------------
    WHEN get_conc_name_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10560
                      ,iv_token_name1  => cv_tkn_conc
                      ,iv_token_value1 => lv_conc
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END init_proc;
  --
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
     ov_errbuf  OUT VARCHAR2 -- エラー・メッセージ
    ,ov_retcode OUT VARCHAR2 -- リターン・コード
    ,ov_errmsg  OUT VARCHAR2 -- ユーザー・エラー・メッセージ
    ,iv_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name CONSTANT VARCHAR2(100) := 'submain'; -- プログラム名
    --===============================
    -- ローカルカーソル定義
    --===============================
    -- 分割出力対象取得カーソル定義
    CURSOR split_conc_cur
    IS
      SELECT xbsrw.output_rep AS output_rep
            ,xbsrw.output_num AS output_num
      FROM  xxcok_bm_sales_rep_work xbsrw
      WHERE request_id = cn_request_id
      GROUP BY xbsrw.output_rep
              ,xbsrw.output_num
      ORDER BY output_rep
              ,output_num
      ;
    split_conc_rec        split_conc_cur%ROWTYPE;
    -- 一括出力対象取得カーソル定義
    CURSOR lump_conc_cur
    IS
      SELECT xbsrw.output_rep AS output_rep
      FROM  xxcok_bm_sales_rep_work xbsrw
      WHERE request_id = cn_request_id
      GROUP BY xbsrw.output_rep
      ORDER BY output_rep
      ;
    lump_conc_rec        lump_conc_cur%ROWTYPE;
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf                 VARCHAR2(5000);                                    -- エラー・メッセージ
    lv_retcode                VARCHAR2(1);                                       -- リターン・コード
    lv_errmsg                 VARCHAR2(5000);                                    -- ユーザー・エラー・メッセージ
    lv_out_msg                VARCHAR2(2000);                                    -- メッセージ
    lb_retcode                BOOLEAN;                                           -- メッセージ戻り値
    lt_file_id                xxccp_mrp_file_ul_interface.file_id%TYPE;          -- ファイルID
    lt_format                 xxccp_mrp_file_ul_interface.file_format%TYPE;      -- フォーマット
    -- BLOB変換後データ分割後退避用
    ln_col_cnt                PLS_INTEGER := 0;                                  -- CSV項目数
    ln_row_cnt                PLS_INTEGER := 1;                                  -- CSV行数
    ln_line_cnt               PLS_INTEGER := 0;                                  -- CSV処理行カウンタ
    lt_csv_data               xxcok_common_pkg.g_split_csv_tbl;                  -- CSV分割データ
    lt_file_data              xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB変換後データ退避(空白行排除後)
    lt_file_data_all          xxccp_common_pkg2.g_file_data_tbl;                 -- BLOB変換後データ退避(全データ)
    --
    lt_output_num             xxcok_bm_sales_rep_work.output_num%TYPE;           -- チェック後項目1：出力番号
    lt_output_rep             xxcok_bm_sales_rep_work.output_rep%TYPE;           -- チェック後項目2：出力帳票
    lt_target_ym              xxcok_bm_sales_rep_work.target_ym%TYPE;            -- チェック後項目3：対象年月
    lt_vendor_code            xxcok_bm_sales_rep_work.vendor_code%TYPE;          -- チェック後項目4：仕入先コード
    lt_customer_code          xxcok_bm_sales_rep_work.customer_code%TYPE;        -- チェック後項目5：顧客コード
    ln_cnt                    NUMBER;
    --===============================
    -- ローカル例外
    --===============================
    blob_err_expt    EXCEPTION; -- BLOB変換エラー
    no_data_err_expt EXCEPTION; -- アップロード処理対象なしエラー
    proc_err_expt    EXCEPTION; -- 呼出しプログラムのエラー
  --
  BEGIN
  --
    --===============================================
    -- A-0.初期化
    --===============================================
    ov_retcode := cv_status_normal;
    lt_file_id := TO_NUMBER(TRUNC(iv_file_id));
    lt_format  := iv_format;
    lt_file_data.delete;
    lt_file_data_all.delete;
    --===============================================
    -- A-1.初期処理
    --===============================================
    --
    init_proc(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      ,in_file_id => lt_file_id -- ファイルID
      ,iv_format  => lt_format  -- フォーマット
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
    END IF;
    --
    --===============================================
    -- A-2.ファイルアップロードデータ取得
    --===============================================
    --
    -- 1.BLOBデータ変換
    xxccp_common_pkg2.blob_to_varchar2(
       in_file_id   => lt_file_id       -- ファイルID
      ,ov_file_data => lt_file_data_all -- BLOB変換後データ退避(空行,見出しあり)
      ,ov_errbuf    => lv_errbuf        -- エラー・メッセージ
      ,ov_retcode   => lv_retcode       -- リターン・コード
      ,ov_errmsg    => lv_errmsg        -- ユーザー・エラー・メッセージ 
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE blob_err_expt;
    END IF;
    -- 取得したデータから、空白行(カンマのみの行)を排除する
    << blob_data_loop >>
    FOR i IN 2..lt_file_data_all.COUNT LOOP
      IF ( LENGTHB( REPLACE( lt_file_data_all(i), ',', '') ) <> cn_zero ) THEN
        ln_line_cnt := ln_line_cnt + cn_one;
        lt_file_data(ln_line_cnt) := lt_file_data_all(i);  --空行,見出し除外結果
      END IF;
    END LOOP blob_data_loop;
    -- 編集用のテーブル削除
    lt_file_data_all.delete;
    -- CSV処理行カウンタ初期化
    ln_line_cnt := cn_zero;
    -- 処理対象件数を退避
    gn_target_cnt := lt_file_data.COUNT;
    -- 処理対象存在チェック
    IF ( gn_target_cnt <= cn_zero ) THEN
      RAISE no_data_err_expt;
    END IF;
    -- 2.BLOB変換後データチェックループ
    << blob_data_check_loop >>
    FOR ln_line_cnt IN 1..lt_file_data.COUNT LOOP  --空行、見出しなし
      --===============================================
      -- A-3.ファイルアップロードデータ変換
      --===============================================
      --
      -- 1.CSV文字列分割
       xxcok_common_pkg.split_csv_data_p(
         ov_errbuf        => lv_errbuf                 -- エラー・メッセージ
        ,ov_retcode       => lv_retcode                -- リターン・コード
        ,ov_errmsg        => lv_errmsg                 -- ユーザー・エラー・メッセージ
        ,iv_csv_data      => lt_file_data(ln_line_cnt) -- CSV文字列（アップロード1行）
        ,on_csv_col_cnt   => ln_col_cnt                -- CSV項目数
        ,ov_split_csv_tab => lt_csv_data               -- CSV分割データ（配列で返す）
      );
      -- ステータスエラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      END IF;
      --
      --===============================================
      -- A-4.妥当性チェック処理
      --===============================================
      chk_validate_item(
           ov_errbuf    => lv_errbuf             -- エラー・メッセージ
          ,ov_retcode   => lv_retcode            -- リターン・コード
          ,ov_errmsg    => lv_errmsg             -- ユーザー・エラー・メッセージ
          ,in_index     => ln_line_cnt           -- 行番号
          ,in_col_cnt   => ln_col_cnt            -- CSV項目数
          ,it_csv_data  => lt_csv_data           -- CSV分割データ
          ,ot_segment1  => lt_output_num         -- チェック後項目1：出力番号
          ,ot_segment2  => lt_output_rep         -- チェック後項目2：出力帳票
          ,ot_segment3  => lt_target_ym          -- チェック後項目3：対象年月
          ,ot_segment4  => lt_vendor_code        -- チェック後項目4：仕入先コード
          ,ot_segment5  => lt_customer_code      -- チェック後項目5：顧客コード
      );
      --
      -- ステータスエラー判定：正常時
      IF ( lv_retcode = cv_status_normal ) THEN
        -- 正常データ退避
        gt_check_data(ln_row_cnt).output_num    := lt_output_num;
        gt_check_data(ln_row_cnt).output_rep    := lt_output_rep;
        gt_check_data(ln_row_cnt).target_ym     := lt_target_ym;
        gt_check_data(ln_row_cnt).vendor_code   := lt_vendor_code;
        gt_check_data(ln_row_cnt).customer_code := lt_customer_code;
        --
        ln_row_cnt := ln_row_cnt + 1;
      -- ステータスエラー判定：チェックエラー時
      ELSIF ( lv_retcode = cv_status_check ) THEN
        -- エラー件数をインクリメント
        gn_error_cnt := gn_error_cnt + 1;
        ov_retcode := cv_status_check;
      -- ステータスエラー判定：エラー時
      ELSE
        -- エラー終了
        RAISE proc_err_expt;
      END IF;
    --
    END LOOP;
    --
    -- ===============================
    -- A-5.支払案内書、販売報告書出力対象ワーク登録
    -- ===============================
    IF ( ov_retcode = cv_status_normal ) THEN
      --
      insert_xbsrw(
        ov_errbuf     => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode    => lv_retcode          -- リターン・コード
       ,ov_errmsg     => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- ステータスエラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      END IF;
      --
    END IF;
    -- ===============================
    -- A-6.支払案内書の出力対象重複チェック
    -- ===============================
    IF ( ov_retcode = cv_status_normal ) THEN
      --
      chk_dupulicate_bm(
        ov_errbuf     => lv_errbuf           -- エラー・メッセージ
       ,ov_retcode    => lv_retcode          -- リターン・コード
       ,ov_errmsg     => lv_errmsg           -- ユーザー・エラー・メッセージ
      );
      -- ステータスエラー判定
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE proc_err_expt;
      ELSIF ( lv_retcode = cv_status_check ) THEN
        ROLLBACK;  --出力対象ワーク登録を無効に
        ov_retcode := cv_status_check;
      END IF;
      --
    END IF;
    --===============================================
    -- A-7.コンカレント発行
    --===============================================
    IF ( ov_retcode = cv_status_normal ) THEN
      --
      IF iv_format = cv_file_id_split THEN
        -- ===============================
        -- 分割出力のコンカレント発行
        -- ===============================
        OPEN split_conc_cur;
        LOOP
          FETCH split_conc_cur INTO split_conc_rec;
          EXIT WHEN split_conc_cur%NOTFOUND;
          --
          IF split_conc_rec.output_rep = cn_bm_rep THEN
            --支払案内書コンカレント発行
            submit_conc_bm_rep(
              ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
             ,ov_retcode    => lv_retcode                         -- リターン・コード
             ,ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
             ,in_output_num => split_conc_rec.output_num          -- 出力番号
            );
          ELSIF split_conc_rec.output_rep = cn_sales_rep THEN
            --販売報告書コンカレント発行
            submit_conc_sales_rep(
              ov_errbuf     => lv_errbuf                          -- エラー・メッセージ
             ,ov_retcode    => lv_retcode                         -- リターン・コード
             ,ov_errmsg     => lv_errmsg                          -- ユーザー・エラー・メッセージ
             ,in_output_num => split_conc_rec.output_num          -- 出力番号
            );
          END IF;
          -- ステータスエラー判定
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE proc_err_expt;
          END IF;
          --
        END LOOP;
        CLOSE split_conc_cur;
        --
      ELSE
        -- ===============================
        -- 一括出力のコンカレント発行
        -- ===============================
        OPEN lump_conc_cur;
        LOOP
          FETCH lump_conc_cur INTO lump_conc_rec;
          EXIT WHEN lump_conc_cur%NOTFOUND;
          --
          IF lump_conc_rec.output_rep = cn_bm_rep THEN
            --支払案内書コンカレント発行
            submit_conc_bm_rep(
              ov_errbuf     => lv_errbuf           -- エラー・メッセージ
             ,ov_retcode    => lv_retcode          -- リターン・コード
             ,ov_errmsg     => lv_errmsg           -- ユーザー・エラー・メッセージ
             ,in_output_num => NULL                -- 出力番号
            );
          ELSIF lump_conc_rec.output_rep = cn_sales_rep THEN
            --販売報告書コンカレント発行
            submit_conc_sales_rep(
              ov_errbuf     => lv_errbuf           -- エラー・メッセージ
             ,ov_retcode    => lv_retcode          -- リターン・コード
             ,ov_errmsg     => lv_errmsg           -- ユーザー・エラー・メッセージ
             ,in_output_num => NULL                -- 出力番号
            );
          END IF;
          -- ステータスエラー判定
          IF ( lv_retcode = cv_status_error ) THEN
            RAISE proc_err_expt;
          END IF;
          --
        END LOOP;
        CLOSE lump_conc_cur;
        --
      END IF;
      --
    END IF;
    --===============================================
    -- A-8.ファイルアップロードデータの削除
    --===============================================
    del_file_upload_data(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ 
      ,in_file_id => lt_file_id -- ファイルID
    );
    -- ステータスエラー判定
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE proc_err_expt;
    ELSE
      -- チェックエラーの場合、異常終了させるのでここでCOMMIT
      COMMIT;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- BLOB変換例外ハンドラ
    ----------------------------------------------------------
    WHEN blob_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_00041
                      ,iv_token_name1  => cv_tkn_file_id
                      ,iv_token_value1 => TO_CHAR(lt_file_id)
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力帳票
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- アップロード処理対象なし例外ハンドラ
    ----------------------------------------------------------
    WHEN no_data_err_expt THEN
      -- エラーメッセージ取得
      lv_out_msg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_ap_type_xxcok
                      ,iv_name         => cv_errmsg_10558
                    );
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.OUTPUT -- 出力区分
                      ,iv_message    => lv_out_msg      -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_out_msg,1,5000);
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- サブプログラム例外ハンドラ
    ----------------------------------------------------------
    WHEN proc_err_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := lv_errbuf;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
  --
  END submain;
  --
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
     errbuf     OUT VARCHAR2 -- エラー・メッセージ
    ,retcode    OUT VARCHAR2 -- リターン・コード
    ,iv_file_id IN  VARCHAR2 -- ファイルID
    ,iv_format  IN  VARCHAR2 -- フォーマット
  )
  IS
    --===============================
    -- ローカル定数
    --===============================
    cv_prg_name     CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    --===============================
    -- ローカル変数
    --===============================
    lv_errbuf       VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode      VARCHAR2(1);     -- リターン・コード
    lv_errmsg       VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_out_msg      VARCHAR2(2000);  -- メッセージ
    lv_message_code VARCHAR2(5000);  -- 処理終了メッセージ
    lb_retcode      BOOLEAN;         -- メッセージ戻り値
  --
  BEGIN
  --
    --===============================================
    -- 初期化
    --===============================================
    lv_out_msg := NULL;
    --===============================================
    -- コンカレントヘッダ出力
    --===============================================
    --
    xxccp_common_pkg.put_log_header(
       iv_which   => cv_output
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => NULL            -- メッセージ
                    ,in_new_line   => cn_one          -- 改行
                  );
    --
    --===============================================
    -- サブメイン処理
    --===============================================
    --
    submain(
       ov_errbuf  => lv_errbuf  -- エラー・メッセージ
      ,ov_retcode => lv_retcode -- リターン・コード
      ,ov_errmsg  => lv_errmsg  -- ユーザー・エラー・メッセージ
      ,iv_file_id => iv_file_id -- ファイルID
      ,iv_format  => iv_format  -- フォーマット
    );
    --
    IF ( lv_retcode = cv_status_normal ) THEN
      gn_normal_cnt := gn_target_cnt;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      -- エラーメッセージ出力
      lb_retcode := xxcok_common_pkg.put_message_f(
                       in_which      => FND_FILE.LOG    -- 出力帳票
                      ,iv_message    => lv_errbuf       -- メッセージ
                      ,in_new_line   => cn_one          -- 改行
                    );
      -- エラー時処理件数設定
      gn_normal_cnt := cn_zero; -- 正常件数
      gn_error_cnt  := cn_one;  -- エラー件数
    END IF;
    --
    --===============================================
    -- 終了処理
    --===============================================
    -------------------------------------------------
    -- 1.対象件数メッセージ出力
    -------------------------------------------------
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => ' '             -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90000
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_target_cnt)
                  );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 2.成功件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90001
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -------------------------------------------------
    -- 3.成功件数メッセージ出力
    -------------------------------------------------
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => cv_mainmsg_90002
                    ,iv_token_name1  => cv_tkn_count
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_one          -- 改行
                  );
    -------------------------------------------------
    -- 4.終了メッセージ出力
    -------------------------------------------------
    -- 終了メッセージ判断
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_normal_msg;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_error_msg;
    ELSIF ( lv_retcode = cv_status_check ) THEN
      lv_message_code := cv_error_msg;
    END IF;
    -- メッセージ取得
    lv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_ap_type_xxccp
                    ,iv_name         => lv_message_code
                   );
    -- メッセージ出力
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which      => FND_FILE.OUTPUT -- 出力帳票
                    ,iv_message    => lv_out_msg      -- メッセージ
                    ,in_new_line   => cn_zero         -- 改行
                  );
    -- ステータスセット
    retcode := lv_retcode;
    -- ステータスがエラーの場合はROLLBACKする
    IF (retcode = cv_status_error) THEN
      ROLLBACK;
    END IF;
  --
  EXCEPTION
  --
    ----------------------------------------------------------
    -- 共通関数OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
    ----------------------------------------------------------
    -- OTHERS例外ハンドラ
    ----------------------------------------------------------
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
  --
  END main;
  --
END XXCOK015A04C;
/
