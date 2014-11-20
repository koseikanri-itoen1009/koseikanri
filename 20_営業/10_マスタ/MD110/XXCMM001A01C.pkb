CREATE OR REPLACE PACKAGE BODY XXCMM001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM001A01C(spec)
 * Description      : 仕入先マスタIF出力（情報系）
 * MD.050           : 仕入先マスタIF出力（情報系）MD050_CMM_001_A01
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   初期処理(A-1)
 *  output_csv             CSVファイル出力処理(A-3)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/16    1.0   SCS 工藤 真純    初回作成
 *  2009/03/09    1.1   SCS 瀧川 倫太郎  仕入先の銀行口座登録チェックをコメントアウト
 *  2009/05/13    1.2   SCS 吉川 博章    T1_0978対応
 *  2009/12/04    1.3   SCS 仁木 重人    E_本稼動_00307対応
 *  2010/03/08    1.4   SCS 久保島 豊    E_本稼動_01820対応
 *                                       ・預金種別名称に「貯蓄預金,別段預金」を追加
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
--  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1(未使用)
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
--  gn_warn_cnt      NUMBER;                    -- スキップ件数(未使用)
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
  cv_appl_short_name   CONSTANT VARCHAR2(10) := 'XXCMM';             -- アドオン：マスタ
  cv_common_short_name CONSTANT VARCHAR2(10) := 'XXCCP';             -- アドオン：共通・IF
  cv_pkg_name          CONSTANT VARCHAR2(15) := 'XXCMM001A01C';      -- パッケージ名
--
  -- メッセージ番号(マスタ)
  cv_file_data_no_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00001';  -- 対象データ無しメッセージ
  cv_prf_get_err       CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00002';  -- プロファイル取得エラー
  cv_file_pass_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00003';  -- ファイルパス不正エラー
  cv_file_priv_err     CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00007';  -- ファイルアクセス権限エラー
  cv_csv_data_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00009';  -- CSVデータ出力エラー
  cv_csv_file_err      CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00010';  -- CSVファイル存在チェック
  cv_bank_account_err  CONSTANT VARCHAR2(20) := 'APP-XXCMM1-00100';  -- 銀行口座情報なしエラー
  -- メッセージ番号(共通・IF)
  cv_file_name         CONSTANT VARCHAR2(20) := 'APP-XXCCP1-05102';  -- ファイル名メッセージ
  cv_input_no_msg      CONSTANT VARCHAR2(20) := 'APP-XXCCP1-90008';  -- コンカレント入力パラメータなし
--
  -- プロファイル
  cv_prf_dir           CONSTANT VARCHAR2(30) := 'XXCMM1_JYOHO_OUT_DIR';   -- 仕入先マスタ連携用CSVファイル出力先
  cv_prf_fil           CONSTANT VARCHAR2(30) := 'XXCMM1_001A01_OUT_FILE'; -- 仕入先マスタ連携用CSVファイル名
--
  -- トークン
  cv_tkn_ng_profile    CONSTANT VARCHAR2(30) := 'NG_PROFILE';        -- エラープロファイル名
  cv_tkn_ng_word       CONSTANT VARCHAR2(30) := 'NG_WORD';           -- エラー項目名
  cv_tkn_ng_data       CONSTANT VARCHAR2(30) := 'NG_DATA';           -- エラーデータ
  cv_tkn_ng_code       CONSTANT VARCHAR2(30) := 'NG_CODE';           -- エラーコード
  cv_tkn_filename      CONSTANT VARCHAR2(30) := 'FILE_NAME';         -- ファイル名
  cv_prf_dir_nm        CONSTANT VARCHAR2(30) := 'CSVファイル出力先';
  cv_prf_fil_nm        CONSTANT VARCHAR2(30) := 'CSVファイル名';
  cv_vender_num        CONSTANT VARCHAR2(30) := '仕入先番号';
--
  -- ＣＳＶ用固定値
  cc_itoen             CONSTANT CHAR(3)      := '001';               -- 会社コード（001:固定）
  cd_sysdate           DATE                  := SYSDATE;             -- 処理開始時間
  cc_output            CONSTANT CHAR(1)      := 'w';                 -- 出力ステータス
  cc_payment_eft       CONSTANT CHAR(3)      := 'EFT';               -- 電信支払
--
-- 2010/03/08 Ver1.4 E_本稼動_01820 add start by Y.Kuboshima
  -- 参照タイプ
  cv_koza_type         CONSTANT VARCHAR2(30) := 'XXCSO1_KOZA_TYPE';  -- 参照タイプ(口座種別)
-- 2010/03/08 Ver1.4 E_本稼動_01820 add end by Y.Kuboshima
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- 仕入先マスタ情報を格納するレコード
  TYPE  csv_out_rec IS RECORD(
        vender_num              VARCHAR2(9),    --仕入先コード
        vendor_site_code        VARCHAR2(9),    --仕入先サイトコード
        vendor_nm               VARCHAR2(100),  --仕入先名称
        zip                     VARCHAR2(7),    --所在地：郵便番号
        state                   VARCHAR2(100),  --所在地：都道府県
        city                    VARCHAR2(50),   --所在地：郡市区
        address1                VARCHAR2(100),  --所在地：住所１
        pay_nm                  VARCHAR2(8),    --支払条件（締日・払日・サイト）
        bank_num                VARCHAR2(4),    --振込先銀行コード
        bank_nm                 VARCHAR2(50),   --振込先銀行名称
        bank_nm_alt             VARCHAR2(30),   --振込先銀行カナ
        bank_branch_num         VARCHAR2(3),    --振込先銀行支店コード
        bank_branch_nm          VARCHAR2(50),   --振込先銀行支店名称
        bank_branch_nm_alt      VARCHAR2(30),   --振込先銀行支店カナ
        bank_account_type       VARCHAR2(1),    --振込先預金種別口座種別
        bank_account_type_nm    VARCHAR2(30),   --振込先預金種別名称
        bank_account_num        VARCHAR2(30),   --銀行口座番号
        account_holder_nm_alt   VARCHAR2(50)    --振込先口座名義人名カナ
  );
--
  -- 仕入先マスタ情報を格納するテーブル型の定義
  TYPE csv_out_tbl IS TABLE OF csv_out_rec INDEX BY BINARY_INTEGER;
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  gv_directory      VARCHAR2(255);         -- プロファイル・ファイルパス名
  gv_file_name      VARCHAR2(255);         -- プロファイル・ファイル名
  gf_file_hand      UTL_FILE.FILE_TYPE;    -- ファイル・ハンドルの宣言
  gv_csv_file       VARCHAR2(5000);        -- 出力情報
  gt_csv_out_tbl    csv_out_tbl;           -- 結合配列の定義
  gc_del_flg        CHAR(1) := ' ';        -- CSV削除フラグ('1':削除)
--
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_file_chk   BOOLEAN;   --存在チェック結果
    lv_file_size  NUMBER;    --ファイルサイズ
    lv_block_size NUMBER;   --ブロックサイズ
    -- *** ローカル変数 ***
    lc_vender_num  CHAR(9) := NULL; -- エラー仕入先番号
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
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --入力パラメータなしメッセージ出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_input_no_msg
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- プロファイル取得
    -- ===============================
    -- 仕入先マスタ連携用CSVファイル出力先取得
    gv_directory := fnd_profile.value(cv_prf_dir);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_directory IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_dir_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- 仕入先マスタ連携用CSVファイル名取得
    gv_file_name := FND_PROFILE.VALUE(cv_prf_fil);
--
    -- プロファイルが取得できない場合はエラー
    IF (gv_file_name IS NULL) THEN
      lv_errmsg := xxccp_common_pkg.get_msg(
                   iv_application  => cv_appl_short_name
                  ,iv_name         => cv_prf_get_err
                  ,iv_token_name1  => cv_tkn_ng_profile
                  ,iv_token_value1 => cv_prf_fil_nm
                 );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- コンカレントメッセージ出力
    -- ===============================
    --IFファイル名出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_file_name
                 ,iv_token_name1  => cv_tkn_filename
                 ,iv_token_value1 => gv_file_name
                );
--
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    -- ===============================
    -- CSVファイル存在チェック
    -- ===============================
    UTL_FILE.FGETATTR(gv_directory,
                      gv_file_name,
                      lv_file_chk,
                      lv_file_size,
                      lv_block_size
    );
    -- ファイル存在時エラー
    IF (lv_file_chk = TRUE) THEN
       lv_errmsg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_appl_short_name
                   ,iv_name         => cv_csv_file_err
                  );
      lv_errbuf := lv_errmsg;
      RAISE global_api_expt;
    END IF;
--
    -- ===============================
    -- 仕入先サイトマスタ０件チェック
    -- ===============================
--
    BEGIN
      SELECT 1
      INTO   gn_target_cnt
      FROM   po_vendor_sites_all pvs     --仕入先サイトマスタ
      WHERE  ROWNUM = 1;
    EXCEPTION
      -- データなしの場合エラー
      WHEN NO_DATA_FOUND THEN
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_data_no_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
--Ver1.1 2009/03/09 仕入先の銀行口座登録チェックを削除
    -- ===============================
    -- 仕入先の銀行口座登録チェック
    -- ===============================
--
--    --電信支払の仕入先には必ず銀行口座を設定
--    BEGIN
--      SELECT SUBSTRB(pv.segment1,1,9)
--      INTO   lc_vender_num
--      FROM   po_vendors pv,                  --仕入先マスタ
--             ap_bank_account_uses_all abau,  --銀行口座使用情報マスタ
--             po_vendor_sites_all pvs         --仕入先サイトマスタ
--      WHERE  pvs.payment_method_lookup_code = cc_payment_eft
--      AND    pvs.vendor_id = abau.vendor_id(+)
--      AND    pvs.vendor_site_id = abau.vendor_site_id(+)
--      AND    (abau.vendor_site_id IS NULL OR abau.vendor_id IS NULL)
--      AND    pv.vendor_id = pvs.vendor_id
--      AND    ROWNUM = 1;
--
--    EXCEPTION
--      -- データなしの場合継続
--      WHEN NO_DATA_FOUND THEN
--        NULL;
--      WHEN OTHERS THEN
--        RAISE global_api_others_expt;
--    END;
--
--    -- ファイル存在時エラー
--    IF (lc_vender_num IS NOT NULL) then
--      lv_errmsg := xxccp_common_pkg.get_msg(
--                   iv_application  => cv_appl_short_name
--                  ,iv_name         => cv_bank_account_err
--                  ,iv_token_name1  => cv_tkn_ng_code
--                  ,iv_token_value1 => lc_vender_num
--                 );
--      lv_errbuf := lv_errmsg;
--      RAISE global_api_expt;
--    END IF;
--
--End1.1
    -- ===============================
    -- CSVファイルオープン処理
    -- ===============================
    BEGIN
      gf_file_hand := UTL_FILE.FOPEN(
                      gv_directory    -- 出力先
                     ,gv_file_name    -- CSVファイル名
                     ,cc_output       -- 出力ステータス
                    );
    EXCEPTION
      -- ファイルパス不正エラー
      WHEN UTL_FILE.INVALID_PATH THEN
        gn_target_cnt := 0;
        lv_errmsg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_file_pass_err
                   );
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
--
      WHEN OTHERS THEN
        RAISE global_api_others_expt;
    END;
--
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
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
  END init;
--
  /**********************************************************************************
   * Procedure Name   : output_csv
   * Description      : CSVファイル出力処理(A-3)
   ***********************************************************************************/
  PROCEDURE output_csv(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================0
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'output_csv'; -- プログラム名
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
    lv_sep_com      CONSTANT VARCHAR2(1)  := ',';     -- カンマ
    lv_char_dq      CONSTANT VARCHAR2(1)  := '"';     -- ダブルクォーテーション
--
    -- *** ローカル変数 ***
    lc_last_update   CHAR(14); -- 更新日付(YYYYMMDDHH24MISS)
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
    lc_last_update := TO_CHAR(cd_sysdate, 'YYYYMMDDHH24MISS');
--
--
    <<gt_csv_out_tbl_loop>>
    FOR out_cnt IN gt_csv_out_tbl.FIRST .. gt_csv_out_tbl.LAST LOOP
--
      gv_csv_file   := lv_char_dq || cc_itoen || lv_char_dq        -- 会社コード（固定値:001)
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vender_num) || lv_char_dq  -- 仕入先番号
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_site_code) || lv_char_dq  -- 仕入先サイトコード
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).vendor_nm) || lv_char_dq  -- 仕入先名称
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).zip) || lv_char_dq  -- 所在地：郵便番号
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).state) || lv_char_dq  -- 所在地：都道府県
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).city) || lv_char_dq  -- 所在地：郡市区
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).address1) || lv_char_dq  -- 所在地：住所１
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).pay_nm) || lv_char_dq  -- 支払条件（締日・払日・サイト）
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_num) || lv_char_dq  -- 振込先銀行コード
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_nm) || lv_char_dq  -- 振込先銀行名称
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_nm_alt) || lv_char_dq  -- 振込先銀行カナ
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_branch_num) || lv_char_dq  -- 振込先銀行支店コード
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_branch_nm) || lv_char_dq  -- 振込先銀行支店名称
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_branch_nm_alt) || lv_char_dq  -- 振込先銀行支店カナ
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_account_type) || lv_char_dq  -- 振込先預金種別口座種別
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_account_type_nm) || lv_char_dq  -- 振込先預金種別名称
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).bank_account_num) || lv_char_dq  -- 銀行口座番号
        || lv_sep_com || lv_char_dq || RTRIM(gt_csv_out_tbl(out_cnt).account_holder_nm_alt) || lv_char_dq  -- 振込先口座名義人名カナ
        || lv_sep_com || lc_last_update;                        -- 最終更新日時
--
      BEGIN
      -- CSVファイルへ出力
          UTL_FILE.PUT_LINE(gf_file_hand,gv_csv_file);
--
      EXCEPTION
        WHEN UTL_FILE.INVALID_OPERATION THEN       -- ファイルアクセス権限エラー
          -- エラー件数
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_file_priv_err
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
--
        WHEN UTL_FILE.WRITE_ERROR THEN   -- CSVデータ出力エラー
          -- エラー件数
          lv_errmsg := xxccp_common_pkg.get_msg(
                       iv_application  => cv_appl_short_name
                      ,iv_name         => cv_csv_data_err
                      ,iv_token_name1  => cv_tkn_ng_word
                      ,iv_token_value1 => cv_vender_num
                      ,iv_token_name2  => cv_tkn_ng_data
                      ,iv_token_value2 => gt_csv_out_tbl(out_cnt).vender_num
                      );
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
        WHEN OTHERS THEN
          RAISE global_api_others_expt;
      END;
--
      -- 正常件数
      gn_normal_cnt := gn_normal_cnt + 1;
--
    END LOOP gt_csv_out_tblloop;
--
    --==============================================================
    --メッセージ出力をする必要がある場合は処理を記述
    --==============================================================
--
  EXCEPTION
    -- *** 任意で例外処理を記述する ****
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
  END output_csv;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- 仕入先マスタテーブル取得カーソル
    CURSOR vendor_cur
    IS
      SELECT SUBSTRB(pv.segment1,1,9)           vender_num,         --仕入先番号
-- Ver1.2 Mod 2009/05/13 T1_0978対応 仕入先サイトコードは半角のみのため仕入先サイトIDを連携するよう修正
--             SUBSTRB(pvs.vendor_site_code,1,9)  vendor_site_code,   --仕入先サイトコード
             TO_CHAR( pvs.vendor_site_id )      vendor_site_code,   --仕入先サイトコード(仕入先サイトID)
-- End
-- Ver1.3 Mod 2009/12/04 E_本稼動_00307対応
--             SUBSTRB(pv.vendor_name,1,100)      vendor_nm,          --仕入先名
             SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(pv.vendor_name),1,100)      vendor_nm,          --仕入先名
-- End
             DECODE(SUBSTRB(pvs.zip,4,1), '-', SUBSTRB(pvs.zip,1,3)||SUBSTRB(pvs.zip,5,4), SUBSTRB(pvs.zip,1,7))
                                                zip,                --郵便番号
             SUBSTRB(pvs.state,1,100)           state,              --都道府県
             SUBSTRB(pvs.city,1,50)             city,               --郡市区
             SUBSTRB(pvs.address_line1,1,100)   address1,           --所在地１
             SUBSTRB(att.name,1,8)              pay_nm,             --支払条件
             SUBSTRB(abb.bank_number,1,4)       bank_num,           --銀行番号
             SUBSTRB(abb.bank_name,1,50)        bank_nm,            --銀行名
             SUBSTRB(abb.bank_name_alt,1,30)    bank_nm_alt,        --銀行名カナ
             SUBSTRB(abb.bank_num,1,3)          bank_branch_num,    --銀行支店番号
             SUBSTRB(abb.bank_branch_name,1,50) bank_branch_nm,     --銀行支店名
             SUBSTRB(abb.bank_branch_name_alt,1,30)
                                                bank_branch_nm_alt, --銀行支店カナ
             SUBSTRB(aba.bank_account_type,1,1) bank_account_type,  --口座種別
-- 2010/03/08 Ver1.4 E_本稼動_01820 modify start by Y.Kuboshima
--             DECODE(aba.bank_account_type,'1','普通預金','2','当座預金',NULL)
             SUBSTRB(koza.meaning, 1, 30)
-- 2010/03/08 Ver1.4 E_本稼動_01820 modify end by Y.Kuboshima
                                                bank_account_type_nm, --預金種別名称
             SUBSTRB(aba.bank_account_num,1,30) bank_account_num,   --銀行口座番号
             SUBSTRB(aba.account_holder_name_alt,1,50)
                                                account_holder_nm_alt --口座名義人名カナ
      FROM   ap_bank_accounts_all aba,   --銀行口座マスタ
             ap_bank_branches abb,       --銀行支店マスタ
             ap_terms att,               --支払条件マスタ
             po_vendors pv,              --仕入先マスタ
-- Ver1.2 Mod 2009/05/13 T1_0978対応 営業OUのみ対象とする
--             po_vendor_sites_all pvs     --仕入先サイトマスタ
             po_vendor_sites  pvs        --仕入先サイトマスタ
-- End
-- 2010/03/08 Ver1.4 E_本稼動_01820 add start by Y.Kuboshima
            ,(SELECT ffvv.lookup_code
                    ,ffvv.meaning
              FROM   fnd_lookup_values_vl ffvv   --参照タイプマスタ
              WHERE  ffvv.lookup_type  = cv_koza_type
                AND  ffvv.enabled_flag = 'Y'
             ) koza                      --口座種別
-- 2010/03/08 Ver1.4 E_本稼動_01820 add end by Y.Kuboshima
      WHERE  pv.vendor_id = pvs.vendor_id
      AND    EXISTS
             (SELECT 'x'
              FROM   ap_bank_account_uses_all abau  --銀行口座使用情報マスタ
              WHERE  abau.vendor_id = pvs.vendor_id
              AND    abau.vendor_site_id = pvs.vendor_site_id
              AND    abau.primary_flag = 'Y'
              AND    abau.external_bank_account_id = aba.bank_account_id)
      AND    pvs.terms_id = att.term_id(+)
      AND    aba.bank_branch_id = abb.bank_branch_id(+)
-- 2010/03/08 Ver1.4 E_本稼動_01820 add start by Y.Kuboshima
      AND    aba.bank_account_type = koza.lookup_code(+)
-- 2010/03/08 Ver1.4 E_本稼動_01820 add end by Y.Kuboshima
      UNION ALL
      SELECT SUBSTRB(pv.segment1,1,9)           vender_num,         --仕入先番号
-- Ver1.2 Mod 2009/05/13 T1_0978対応 仕入先サイトコードは半角のみのため仕入先サイトIDを連携するよう修正
--             SUBSTRB(pvs.vendor_site_code,1,9)  vendor_site_code,   --仕入先サイトコード
             TO_CHAR( pvs.vendor_site_id )      vendor_site_code,   --仕入先サイトコード(仕入先サイトID)
-- End
-- Ver1.3 Mod 2009/12/04 E_本稼動_00307対応
--             SUBSTRB(pv.vendor_name,1,100)      vendor_nm,          --仕入先名
             SUBSTRB(xxcso_util_common_pkg.conv_multi_byte(pv.vendor_name),1,100)      vendor_nm,          --仕入先名
-- End
             DECODE(SUBSTRB(pvs.zip,4,1), '-', SUBSTRB(pvs.zip,1,3)||SUBSTRB(pvs.zip,5,4), SUBSTRB(pvs.zip,1,7))
                                                zip,                --郵便番号
             SUBSTRB(pvs.state,1,100)           state,              --都道府県
             SUBSTRB(pvs.city,1,50)             city,               --郡市区
             SUBSTRB(pvs.address_line1,1,100)   address1,           --所在地１
             SUBSTRB(att.name,1,8)              pay_nm,             --支払条件
             NULL                               bank_num,           --銀行番号
             NULL                               bank_nm,            --銀行名
             NULL                               bank_nm_alt,        --銀行名カナ
             NULL                               bank_branch_num,    --銀行支店番号
             NULL                               bank_branch_nm,     --銀行支店名
             NULL                               bank_branch_nm_alt, --銀行支店カナ
             NULL                               bank_account_type,  --口座種別
             NULL                               bank_account_type_nm, --預金種別名称
             NULL                               bank_account_num,   --銀行口座番号
             NULL                               account_holder_nm_alt --口座名義人名カナ
      FROM   ap_terms att,               --支払条件マスタ
             po_vendors pv,              --仕入先マスタ
-- Ver1.2 Mod 2009/05/13 T1_0978対応 営業OUのみ対象とする
--             po_vendor_sites_all pvs     --仕入先サイトマスタ
             po_vendor_sites pvs         --仕入先サイトマスタ
-- End
      WHERE  pv.vendor_id = pvs.vendor_id
      AND    NOT EXISTS
             (SELECT 'x'
              FROM   ap_bank_account_uses_all abau  --銀行口座使用情報マスタ
              WHERE  abau.vendor_id = pvs.vendor_id
              AND    abau.vendor_site_id = pvs.vendor_site_id
              AND    abau.primary_flag = 'Y')
      AND    pvs.terms_id = att.term_id(+)
      ORDER  BY  vender_num;
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
    gc_del_flg    := ' ';
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
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ====================================
    -- 仕入先マスタテーブル情報取得(A-2)
    -- ====================================
    OPEN vendor_cur;
--
    <<vendor_loop>>
    LOOP
      FETCH vendor_cur BULK COLLECT INTO gt_csv_out_tbl;
        EXIT WHEN vendor_cur%NOTFOUND;
    END LOOP vendor_loop;
--
    CLOSE vendor_cur;
--
    gn_target_cnt := gt_csv_out_tbl.COUNT;  -- 処理件数カウントアップ
--
    -- ===============================
    -- CSVファイル出力処理(A-3)
    -- ===============================
    output_csv(
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
    -- 成功件数なしの場合
    IF (gn_normal_cnt = 0) THEN
      gc_del_flg    := '1';   --CSV削除
    END IF;
--
    IF (lv_retcode = cv_status_error) THEN
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 終了処理(A-4)
    -- ===============================
--
    -- CSVファイルをクローズする
    UTL_FILE.FCLOSE(gf_file_hand);
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
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
      IF (UTL_FILE.IS_OPEN(gf_file_hand)) THEN
        UTL_FILE.FCLOSE(gf_file_hand);
      END IF;
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
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2       --   リターン・コード    --# 固定 #
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
    -- メッセージ番号(共通・IF)
    cv_target_rec_msg  CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90000'; -- 対象件数メッセージ
    cv_success_rec_msg CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90001'; -- 成功件数メッセージ
    cv_error_rec_msg   CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
--    cv_skip_rec_msg    CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90003'; -- スキップ件数メッセージ
    cv_cnt_token       CONSTANT VARCHAR2(30) := 'COUNT';            -- 件数メッセージ用トークン名
    cv_normal_msg      CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
--    cv_warn_msg        CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90005'; -- 警告終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(30) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
--
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
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = cv_status_error) THEN
      --エラー出力
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => lv_errmsg --ユーザー・エラーメッセージ
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff => lv_errbuf --エラーメッセージ
      );
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => ''
      );
      --異常エラー時は、成功件数０件、エラー件数１件と固定表示
      gn_normal_cnt := 0;
      gn_error_cnt := 1;
    END IF;
--
    --対象件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
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
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_success_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_normal_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => cv_error_rec_msg
                 ,iv_token_name1  => cv_cnt_token
                 ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
    --
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => ''
    );
--
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
      --当処理では警告終了なし
--    ELSIF(lv_retcode = cv_status_warn) THEN
--      lv_message_code := cv_warn_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_common_short_name
                 ,iv_name         => lv_message_code
                );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.OUTPUT
      ,buff   => gv_out_msg
    );
--
    --CSV出力データが０件の場合、CSVファイルを削除する
    IF (gc_del_flg = '1') THEN
       UTL_FILE.FREMOVE(gv_directory,   -- 出力先
                        gv_file_name    -- CSVファイル名
      );
    END IF;
--
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
END XXCMM001A01C;
/
