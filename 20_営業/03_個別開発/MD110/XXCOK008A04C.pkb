CREATE OR REPLACE PACKAGE BODY XXCOK008A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK008A04C(body)
 * Description      : 売上振替割合の登録
 * MD.050           : 売上振替割合の登録 MD050_COK_008_A04
 * Version          : 1.6
 *
 * Program List
 * -------------------------------- ---------------------------------------------------------
 *  Name                            Description
 * -------------------------------- ---------------------------------------------------------
 *  del_interface_at_error          エラー時IFデータ削除処理追加
 *  del_file_upload_interface_tbl   ファイルアップロードI/Fテーブルレコード削除(A-13)
 *  upd_selling_trns_rate_info      売上振替割合情報テーブル更新(「無効フラグ」「売上振替割合」更新)(A-12)
 *  ins_selling_trns_rate_info      売上振替割合情報テーブル挿入(A-11)
 *  upd_invalid_flag                売上振替割合情報テーブル更新(「無効フラグ」の'無効'化)(A-10)
 *  get_selling_trns_rate_info_a9   売上振替割合情報テーブル抽出(「登録・無効区分」='1'(無効))(A-9)
 *  get_selling_trns_rate_info_a8   売上振替割合情報テーブル抽出(「登録・無効区分」='0'(登録))(A-8)
 *  get_tmp_tbl                     売上振替割合登録一時表個別データ抽出(A-7)
 *  get_tmp_tbl_union_data          売上振替割合登録一時表集計データ抽出(A-6)
 *  upd_tmp_tbl_error_flag          売上振替割合登録一時表有効フラグ更新(A-5)
 *  chk_data                        データ妥当性チェック(A-4)
 *  get_tmp_selling_trns_rate       売上振替割合登録一時表データ抽出(A-3)
 *  get_file_upload_interface_date  ファイルのアップロードI/Fデータ取得(A-2)
 *  init                            初期処理(A-1)
 *  submain                         メイン処理プロシージャ
 *  main                            コンカレント実行ファイル登録プロシージャ
 * 
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 * 2008/10/28     1.0   S.Sasaki         新規作成
 * 2009/02/06     1.1   S.Sasaki         [障害COK_019]エラー時IFデータ削除処理追加
 * 2009/02/09     1.2   S.Sasaki         [障害COK_021]売上振替割の値が「0」の場合の対応(「登録」の場合)
 * 2009/02/10     1.3   S.Sasaki         [障害COK_026]必須チェック処理追加
 * 2009/07/13     1.4   M.Hiruta         [障害0000514]処理対象に顧客ステータス「30:承認済」「50:休止」のデータを追加
 * 2009/09/09     1.5   S.Moriyama       [障害0001303]拠点セキュリティ機能追加　振替元拠点と所属拠点が異なる場合は警告とする
 * 2009/12/04     1.6   S.Moriyama       [E_本稼動_00294]振替元/先顧客にEDIチェーン店コードが含まれる顧客を許容するように修正
 *
 *****************************************************************************************/
  -- =========================
  -- グローバル定数
  -- =========================
  --パッケージ名
  cv_pkg_name               CONSTANT VARCHAR2(30)  := 'XXCOK008A04C';
  --アプリケーション短縮名
  cv_xxcok_appl_name        CONSTANT VARCHAR2(10)  := 'XXCOK';
  cv_xxccp_appl_name        CONSTANT VARCHAR2(10)  := 'XXCCP';
  --ステータス・コード
  cv_status_normal          CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_normal;   --正常:0
  cv_status_warn            CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_warn;     --警告:1
  cv_status_error           CONSTANT VARCHAR2(1)   := xxccp_common_pkg.set_status_error;    --異常:2
  --メッセージ名称
  cv_message_00060          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00060'; --データ削除エラーメッセージ
  cv_message_10022          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10022'; --ロックエラー(売上振替割合情報テーブル)
  cv_message_10029          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10029'; --データ更新エラー(売上振替割合情報テーブル)
  cv_message_10028          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10028'; --データ追加エラーメッセージ
  cv_message_10024          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10024'; --ステータス相違警告メッセージ
  cv_message_10025          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10025'; --無効化対象レコード存在なし警告メッセージ
  cv_message_10026          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10026'; --売上振替割合100％以外警告メッセージ
  cv_message_10027          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10027'; --データ更新エラー(売上振替割合登録一時表)
  cv_message_10352          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10352'; --ロックエラー(売上振替割合登録一時表)
  cv_message_10014          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10014'; --登録・無効区分妥当性NG警告メッセージ
  cv_message_10015          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10015'; --売上振替元拠点コードなし警告メッセージ
  cv_message_10016          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10016'; --売上振替元顧客コードなし警告メッセージ
  cv_message_10017          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10017'; --売上振替先顧客コードなし警告メッセージ
  cv_message_10018          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10018'; --元拠点コード、元顧客コード紐付けＮＧ
  cv_message_10019          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10019'; --売上振替割合書式ＮＧ警告メッセージ
  cv_message_10020          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10020'; --売上振替割合数値ＮＧ警告メッセージ
  cv_message_10021          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10021'; --売上振替顧客情報なし警告メッセージ
  cv_message_00006          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00006'; --ファイル名メッセージ出力
  cv_message_00061          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00061'; --ロックエラー:ファイルアップロードIFテーブル
  cv_message_00039          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00039'; --空ファイルエラーメッセージ
  cv_message_00041          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00041'; --BLOBデータ変換エラーメッセージ
  cv_message_00016          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00016'; --ファイルIDメッセージ
  cv_message_00017          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00017'; --フォーマットパターンメッセージ
  cv_message_00046          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00046'; --顧客情報複数取得エラー
  cv_message_00047          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00047'; --売上拠点情報複数取得エラー
  cv_message_00028          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00028'; --業務日付取得エラー
  cv_message_10450          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10450'; --売上振替割合数値ＮＧ警告(登録)メッセージ
  cv_message_10451          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10451'; --必須項目未設定エラーメッセージ
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD START
  cv_message_10458          CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10458'; --所属拠点外アップロードエラーメッセージ
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD END
  cv_message_90000          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90000'; --対象件数メッセージ
  cv_message_90001          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90001'; --成功件数メッセージ
  cv_message_90002          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90002'; --エラー件数メッセージ
  cv_message_90004          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90004'; --正常終了メッセージ
  cv_message_90005          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90005'; --警告終了メッセージ
  cv_message_90006          CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90006'; --エラー終了全ロールバックメッセージ
  --トークン
  cv_token_file_id          CONSTANT VARCHAR2(10)  := 'FILE_ID';           --トークン名(FILE_ID)
  cv_token_file_name        CONSTANT VARCHAR2(10)  := 'FILE_NAME';         --トークン名(FILE_NAME)
  cv_token_from_base        CONSTANT VARCHAR2(15)  := 'FROM_LOCATION';     --トークン名(FROM_LOCATION)
  cv_token_from_cust        CONSTANT VARCHAR2(15)  := 'FROM_CUSTOMER';     --トークン名(FROM_CUSTOMER)
  cv_token_to_cust          CONSTANT VARCHAR2(15)  := 'TO_CUSTOMER';       --トークン名(TO_CUSTOMER)
  cv_token_rate             CONSTANT VARCHAR2(5)   := 'RATE';              --トークン名(RATE)
  cv_token_kubun            CONSTANT VARCHAR2(15)  := 'KUBUN_VALUE';       --トークン名(KUBUN_VALUE)
  cv_token_format           CONSTANT VARCHAR2(10)  := 'FORMAT';            --トークン名(FORMAT)
  cv_token_count            CONSTANT VARCHAR2(5)   := 'COUNT';             --トークン名(COUNT)
  cv_token_cust_code        CONSTANT VARCHAR2(10)  := 'COST_CODE';         --トークン名(CUST_CODE)
  cv_token_sales_loc        CONSTANT VARCHAR2(10)  := 'SALES_LOC';         --トークン名(SALES_LOC)
  --文字列
  cv_0                      CONSTANT VARCHAR2(1)   := '0';       --文字列:0
  cv_1                      CONSTANT VARCHAR2(1)   := '1';       --文字列:1
  cv_12                     CONSTANT VARCHAR2(2)   := '12';      --顧客区分(上様顧客以外)
  cv_40                     CONSTANT VARCHAR2(2)   := '40';      --'顧客'(中止顧客でない)
-- Start 2009/07/13 Ver_1.4 0000514 M.Hiruta ADD
  cv_30                     CONSTANT VARCHAR2(2)   := '30';      --'承認済'
  cv_50                     CONSTANT VARCHAR2(2)   := '50';      --'休止'
-- End   2009/07/13 Ver_1.4 0000514 M.Hiruta ADD
  --数値
  cn_0                      CONSTANT NUMBER        := 0;         --数値：0
  cn_1                      CONSTANT NUMBER        := 1;         --数値：1
  cn_100                    CONSTANT NUMBER        := 100;       --数値：100
  --フォーマット
  cv_number_format          CONSTANT VARCHAR2(5)   := '999.9';   --売上振替割合フォーマット
  cv_date_format            CONSTANT VARCHAR2(2)   := 'MM';      --システム日付フォーマット
  --WHOカラム
  cn_created_by             CONSTANT NUMBER        := fnd_global.user_id;           --CREATED_BY
  cn_last_updated_by        CONSTANT NUMBER        := fnd_global.user_id;           --LAST_UPDATED_BY
  cn_last_update_login      CONSTANT NUMBER        := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id             CONSTANT NUMBER        := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id CONSTANT NUMBER        := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id             CONSTANT NUMBER        := fnd_global.conc_program_id;   --PROGRAM_ID
  cv_msg_part               CONSTANT VARCHAR2(3)   := ' : ';                        --コロン
  cv_msg_cont               CONSTANT VARCHAR2(3)   := '.';                          --ピリオド
  -- =============================================================================
  -- グローバル変数
  -- =============================================================================
  gn_target_cnt   NUMBER        DEFAULT 0;      --対象件数
  gn_normal_cnt   NUMBER        DEFAULT 0;      --成功件数
  gn_error_cnt    NUMBER        DEFAULT 0;      --エラー件数
  gn_file_id      NUMBER        DEFAULT NULL;   --ファイルID(数値型)
  gv_file_id      VARCHAR2(100) DEFAULT NULL;   --ファイルID(文字型)
  gd_process_date DATE;                         --業務処理日付
  -- =============================================================================
  -- グローバル例外
  -- =============================================================================
  -- *** ロックエラーハンドラ ***
  global_lock_fail          EXCEPTION;
  -- *** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  -- *** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  -- *** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);            --ロックエラー
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);   --共通関数OTHERSエラー
--
  /**********************************************************************************
   * Procedure Name   : del_interface_at_error
   * Description      : エラー時IFデータ削除(A-14)
   ***********************************************************************************/
  PROCEDURE del_interface_at_error(
    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    --リターン・コード
  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)     --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(50) := 'del_interface_at_error';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --エラーメッセージ
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --リターンコード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --ユーザーエラーメッセージ
    lv_msg     VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lb_retcode BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- ファイルアップロードIFテーブルのロック取得
    -- =============================================================================
    CURSOR xmfui_cur
    IS
      SELECT 'X'
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  xmfui_cur;
    CLOSE xmfui_cur;
    -- =============================================================================
    -- ファイルアップロードIF表の削除処理
    -- =============================================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id;
    EXCEPTION
      -- *** 削除処理に失敗 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_00060
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => gv_file_id
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --出力区分
                      , iv_message  => lv_msg              --メッセージ
                      , in_new_line => 0                   --改行
                      );
        ov_errmsg  := NULL;
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_interface_at_error;
--
  /***************************************************************************
   * Procedure Name   : del_file_upload_interface_tbl
   * Description      : ファイルアップロードI/Fテーブルレコード削除(A-13)
   ***************************************************************************/
  PROCEDURE del_file_upload_interface_tbl(
    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    --リターン・コード
  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)     --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'del_file_upload_interface_tbl';  --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --メッセージ謫ｾ変数
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ファイルアップロードI/Fテーブルの対象レコードを削除
    -- =============================================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmf
      WHERE  xmf.file_id = in_file_id;
    EXCEPTION
      -- *** 削除に失敗 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_00060
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => gv_file_id
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --出力区分
                      , iv_message  => lv_msg              --メッセージ
                      , in_new_line => 0                   --改行
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_file_upload_interface_tbl;
--
  /***********************************************************************************************
   * Procedure Name   : upd_selling_trns_rate_info
   * Description      : 売上振替割合情報テーブル更新(「無効フラグ」「売上振替割合」更新)(A-12)
   ***********************************************************************************************/
  PROCEDURE upd_selling_trns_rate_info(
    ov_errbuf                     OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                    OUT VARCHAR2    --リターン・コード
  , ov_errmsg                     OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_selling_from_base_code     IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code     IN  VARCHAR2    --売上振替元顧客コード
  , iv_selling_to_cust_code       IN  VARCHAR2    --売上振替先顧客コード
  , in_selling_trns_rate          IN  NUMBER      --売上振替割合
  , iv_invalid_flag               IN  VARCHAR2    --無効フラグ
  , in_selling_trns_rate_info_id  IN  NUMBER)     --売上振替割合情報ID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30)  := 'upd_selling_trns_rate_info';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 売上振替割合情報テーブルのロック取得
    -- =============================================================================
    CURSOR selling_rate_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxcok_selling_rate_info xstri
      WHERE  xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id
      FOR UPDATE OF xstri.selling_trns_rate_info_id NOWAIT;
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  selling_rate_cur;
    CLOSE selling_rate_cur;
    -- =============================================================================
    -- 1.A-8で抽出したレコードの「無効フラグ」が'0'(有効)の場合
    -- =============================================================================
    BEGIN
      IF ( iv_invalid_flag = cv_0 ) THEN
        UPDATE  xxcok_selling_rate_info xstri
        SET     xstri.selling_trns_rate      = in_selling_trns_rate
              , xstri.last_updated_by        = cn_last_updated_by
              , xstri.last_update_date       = SYSDATE
              , xstri.last_update_login      = cn_last_update_login
              , xstri.request_id             = cn_request_id
              , xstri.program_application_id = cn_program_application_id
              , xstri.program_id             = cn_program_id
              , xstri.program_update_date    = SYSDATE
        WHERE   xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id;
      -- =============================================================================
      -- 2.A-8で抽出したレコードの「無効フラグ」が'1'(無効)の場合
      -- =============================================================================
      ELSIF ( iv_invalid_flag = cv_1 ) THEN
        UPDATE  xxcok_selling_rate_info xstri
        SET     xstri.selling_trns_rate      = in_selling_trns_rate
              , xstri.invalid_flag           = cv_0
              , xstri.last_updated_by        = cn_last_updated_by
              , xstri.last_update_date       = SYSDATE
              , xstri.last_update_login      = cn_last_update_login
              , xstri.request_id             = cn_request_id
              , xstri.program_application_id = cn_program_application_id
              , xstri.program_id             = cn_program_id
              , xstri.program_update_date    = SYSDATE
        WHERE   xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id;
      END IF;
      -- *** 成功件数カウント ***
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** 更新処理に失敗した場合 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10029
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10022
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_retcode := cv_status_warn;
      -- *** エラー件数カウント ***
      gn_error_cnt := gn_error_cnt + 1;
      -- *** A-6で設定したセーブポイントへ遷移 ***
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_selling_trns_rate_info;
--
  /******************************************************************************************
   * Procedure Name   : ins_selling_trns_rate_info
   * Description      : 売上振替割合情報テーブル挿入(A-11)
   ****************************************************************************************/
  PROCEDURE ins_selling_trns_rate_info(
    ov_errbuf                 OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                OUT VARCHAR2    --リターン・コード
  , ov_errmsg                 OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_selling_from_base_code IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code IN  VARCHAR2    --売上振替元顧客コード
  , iv_selling_to_cust_code   IN  VARCHAR2    --売上振替先顧客コード
  , in_selling_trns_rate      IN  NUMBER)     --売上振替割合
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'ins_selling_trns_rate_info';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                     VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_registed_by             VARCHAR2(5)    DEFAULT NULL;   --登録担当者
    ln_selling_trns_rate_info  NUMBER         DEFAULT 0;      --売上振替割合情報ID
    lb_retcode                 BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 売上振替割合情報IDの取得
    -- =============================================================================
    SELECT xxcok_selling_rate_info_s01.NEXTVAL AS xxcok_selling_rate_info_s01
    INTO   ln_selling_trns_rate_info
    FROM   DUAL;
    -- =============================================================================
    -- 登録担当者の取得(従業員コード)
    -- =============================================================================
    lv_registed_by := xxcok_common_pkg.get_emp_code_f(
                        in_user_id => cn_created_by
                      );
    -- =============================================================================
    -- A-7で抽出したデータを売上振替割合情報テーブルへ挿入
    -- =============================================================================
    BEGIN
      INSERT INTO xxcok_selling_rate_info(
        selling_trns_rate_info_id   --売上振替割合情報ID
      , selling_from_base_code      --売上振替元拠点コード
      , selling_from_cust_code      --売上振替元顧客コード
      , selling_to_cust_code        --売上振替先顧客コード
      , selling_trns_rate           --売上振替割合
      , invalid_flag                --無効フラグ
      , registed_by                 --登録担当者
      , created_by                  --作成者
      , creation_date               --作成日
      , last_updated_by             --最終更新者
      , last_update_date            --最終更新日
      , last_update_login           --最終更新ログイン
      , request_id                  --要求ID
      , program_application_id      --コンカレント・プログラム・アプリケーションID
      , program_id                  --コンカレント・プログラムID
      , program_update_date         --プログラム更新日
      ) VALUES (
        ln_selling_trns_rate_info   --selling_trns_rate_info_id
      , iv_selling_from_base_code   --selling_from_base_code
      , iv_selling_from_cust_code   --selling_from_cust_code
      , iv_selling_to_cust_code     --selling_to_cust_code
      , in_selling_trns_rate        --selling_trns_rate
      , cv_0                        --invalid_flag
      , lv_registed_by              --registed_by
      , cn_created_by               --created_by
      , SYSDATE                     --creation_date
      , cn_last_updated_by          --last_updated_by
      , SYSDATE                     --last_update_date
      , cn_last_update_login        --last_update_login
      , cn_request_id               --request_id
      , cn_program_application_id   --program_application_id
      , cn_program_id               --program_id
      , SYSDATE                     --program_update_date
      );
      -- *** 成功件数カウント ***
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** 追加に失敗 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10028
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_selling_trns_rate_info;
--
  /******************************************************************************************
   * Procedure Name   : upd_invalid_flag
   * Description      : 売上振替割合情報テーブル更新(「無効フラグ」の'無効'化)(A-10)
   ****************************************************************************************/
  PROCEDURE upd_invalid_flag(
    ov_errbuf                    OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                   OUT VARCHAR2    --リターン・コード
  , ov_errmsg                    OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_selling_from_base_code    IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code    IN  VARCHAR2    --売上振替元顧客コード
  , iv_selling_to_cust_code      IN  VARCHAR2    --売上振替先顧客コード
  , in_selling_trns_rate         IN  NUMBER      --売上振替割合
  , in_selling_trns_rate_info_id IN  NUMBER)     --売上振替割合情報ID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(20)  := 'upd_invalid_flag';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 売上振替割合情報テーブルのロック取得
    -- =============================================================================
    CURSOR selling_rate_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxcok_selling_rate_info xstri
      WHERE  xstri.selling_trns_rate_info_id = in_selling_trns_rate_info_id
      FOR UPDATE OF xstri.selling_trns_rate_info_id NOWAIT;
--
  BEGIN
    OPEN  selling_rate_cur;
    CLOSE selling_rate_cur;
    -- =============================================================================
    -- 「無効フラグ」を'1'(無効)に更新
    -- =============================================================================
    BEGIN
      UPDATE  xxcok_selling_rate_info
      SET     invalid_flag              = cv_1
            , last_updated_by           = cn_last_updated_by
            , last_update_date          = SYSDATE
            , last_update_login         = cn_last_update_login
            , request_id                = cn_request_id
            , program_application_id    = cn_program_application_id
            , program_id                = cn_program_id
            , program_update_date       = SYSDATE
      WHERE   selling_trns_rate_info_id = in_selling_trns_rate_info_id;
      -- *** 成功件数カウント ***
      gn_normal_cnt := gn_normal_cnt + 1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** 更新処理に失敗した場合 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10029
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10022
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_retcode := cv_status_warn;
      -- *** エラー件数カウント ***
      gn_error_cnt := gn_error_cnt + 1;
      -- *** A-6で設定したセーブポイントへ遷移 ***
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_invalid_flag;
--
  /******************************************************************************************
   * Procedure Name   : get_selling_trns_rate_info_a9
   * Description      : 売上振替割合情報テーブル抽出(「登録・無効区分」'1'(無効))(A-9)
   ****************************************************************************************/
  PROCEDURE get_selling_trns_rate_info_a9(
    ov_errbuf                 OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                OUT VARCHAR2    --リターン・コード
  , ov_errmsg                 OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_valid_invalid_type     IN  VARCHAR2    --登録･無効区分
  , iv_selling_from_base_code IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code IN  VARCHAR2    --売上振替元顧客コード
  , iv_selling_to_cust_code   IN  VARCHAR2    --売上振替先顧客コード
  , in_selling_trns_rate      IN  NUMBER)     --売上振替割合
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'get_selling_trns_rate_info_a9';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                     VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode                    VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg                     VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                        VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_selling_from_base_code     VARCHAR2(4)    DEFAULT NULL;   --売上振替元拠点コード
    lv_selling_from_cust_code     VARCHAR2(9)    DEFAULT NULL;   --売上振替元顧客コード
    lv_selling_to_cust_code       VARCHAR2(9)    DEFAULT NULL;   --売上振替先顧客コード
    lv_invalid_flag               VARCHAR2(1)    DEFAULT NULL;   --無効フラグ
    ln_selling_trns_rate_info_id  NUMBER         DEFAULT NULL;   --売上振替割合情報ID
    lb_retcode                    BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 売上振替割合情報テーブル抽出
    -- =============================================================================
    BEGIN
      SELECT  xsri.selling_from_base_code    AS selling_from_base_code
            , xsri.selling_from_cust_code    AS selling_from_cust_code
            , xsri.selling_to_cust_code      AS selling_to_cust_code
            , xsri.invalid_flag              AS invalid_flag
            , xsri.selling_trns_rate_info_id AS selling_trns_rate_info_id
      INTO    lv_selling_from_base_code
            , lv_selling_from_cust_code
            , lv_selling_to_cust_code
            , lv_invalid_flag
            , ln_selling_trns_rate_info_id
      FROM    xxcok_selling_rate_info xsri
      WHERE   xsri.selling_from_base_code = iv_selling_from_base_code
      AND     xsri.selling_from_cust_code = iv_selling_from_cust_code
      AND     xsri.selling_to_cust_code   = iv_selling_to_cust_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- =============================================================================
    -- 1.データが抽出でき、かつ「無効フラグ」が'0'（有効）の場合、A-10へ遷移
    -- =============================================================================
    IF (    ( ln_selling_trns_rate_info_id IS NOT NULL )
        AND ( lv_invalid_flag = cv_0 )
        ) THEN
      upd_invalid_flag(
        ov_errbuf                    => lv_errbuf
      , ov_retcode                   => lv_retcode
      , ov_errmsg                    => lv_errmsg
      , iv_selling_from_base_code    => iv_selling_from_base_code
      , iv_selling_from_cust_code    => iv_selling_from_cust_code
      , iv_selling_to_cust_code      => iv_selling_to_cust_code
      , in_selling_trns_rate         => in_selling_trns_rate
      , in_selling_trns_rate_info_id => ln_selling_trns_rate_info_id
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    -- ===================================================================================
    -- 2.データが抽出でき、かつ「無効フラグ」が'1'（無効）の場合、警告メッセージを出力
    -- ===================================================================================
    ELSIF (    ( ln_selling_trns_rate_info_id IS NOT NULL )
           AND ( lv_invalid_flag = cv_1 )
          ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10024
                , iv_token_name1  => cv_token_from_base
                , iv_token_value1 => iv_selling_from_base_code
                , iv_token_name2  => cv_token_from_cust
                , iv_token_value2 => iv_selling_from_cust_code
                , iv_token_name3  => cv_token_to_cust
                , iv_token_value3 => iv_selling_to_cust_code
                , iv_token_name4  => cv_token_rate
                , iv_token_value4 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                   in_which    => FND_FILE.OUTPUT     --出力区分
                 , iv_message  => lv_msg              --メッセージ
                 , in_new_line => 0                   --改行
                 );
      ov_retcode := cv_status_warn;
--
      gn_error_cnt := gn_error_cnt + 1;
      -- ===================================================================================
      -- A-6で設定したセーブポイントへ遷移
      -- ===================================================================================
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    -- ======================================================
    -- 3.データを抽出できなかった場合、警告メッセージ出力
    -- ======================================================
    ELSIF ( ln_selling_trns_rate_info_id IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10025
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_retcode := cv_status_warn;
--
      gn_error_cnt := gn_error_cnt + 1;
      -- ===================================================================================
      -- A-6で設定したセーブポイントへ遷移
      -- ===================================================================================
      ROLLBACK TO SAVEPOINT get_union_data_seve;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_selling_trns_rate_info_a9;
--
  /*****************************************************************************************
   * Procedure Name   : get_selling_trns_rate_info_a8
   * Description      : 売上振替割合情報テーブル抽出(「登録・無効区分」'0'(登録))(A-8)
   ****************************************************************************************/
  PROCEDURE get_selling_trns_rate_info_a8(
    ov_errbuf                 OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                OUT VARCHAR2    --リターン・コード
  , ov_errmsg                 OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_selling_from_base_code IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code IN  VARCHAR2    --売上振替元顧客コード
  , iv_selling_to_cust_code   IN  VARCHAR2    --売上振替先顧客コード
  , in_selling_trns_rate      IN  NUMBER)     --売上振替割合
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name     CONSTANT VARCHAR2(30) := 'get_selling_trns_rate_info_a8';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode                   VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_selling_from_base_code    VARCHAR2(4)    DEFAULT NULL;   --売上振替元拠点コード
    lv_selling_from_cust_code    VARCHAR2(9)    DEFAULT NULL;   --売上振替元顧客コード
    lv_selling_to_cust_code      VARCHAR2(9)    DEFAULT NULL;   --売上振替先顧客コード
    lv_invalid_flag              VARCHAR2(1)    DEFAULT NULL;   --無効フラグ
    ln_selling_trns_rate_info_id NUMBER         DEFAULT NULL;   --売上振替割合情報ID
    lb_retcode                   BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 売上振替割合情報テーブル抽出
    -- =============================================================================
    BEGIN
      SELECT  xsri.selling_from_base_code    AS selling_from_base_code
            , xsri.selling_from_cust_code    AS selling_from_cust_code
            , xsri.selling_to_cust_code      AS selling_to_cust_code
            , xsri.invalid_flag              AS invalid_flag
            , xsri.selling_trns_rate_info_id AS selling_trns_rate_info_id
      INTO    lv_selling_from_base_code
            , lv_selling_from_cust_code
            , lv_selling_to_cust_code
            , lv_invalid_flag
            , ln_selling_trns_rate_info_id
      FROM    xxcok_selling_rate_info xsri
      WHERE   xsri.selling_from_base_code = iv_selling_from_base_code
      AND     xsri.selling_from_cust_code = iv_selling_from_cust_code
      AND     xsri.selling_to_cust_code   = iv_selling_to_cust_code;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
    -- =============================================================================
    -- 1.データを抽出できなかった場合、A-11へ遷移
    -- =============================================================================
    IF ( ln_selling_trns_rate_info_id IS NULL ) THEN
      ins_selling_trns_rate_info(
        ov_errbuf                 => lv_errbuf                   --エラー・メッセージ
      , ov_retcode                => lv_retcode                  --リターン・コード
      , ov_errmsg                 => lv_errmsg                   --ユーザー・エラー・メッセージ
      , iv_selling_from_base_code => iv_selling_from_base_code   --売上振替元拠点コード
      , iv_selling_from_cust_code => iv_selling_from_cust_code   --売上振替元顧客コード
      , iv_selling_to_cust_code   => iv_selling_to_cust_code     --売上振替先顧客コード
      , in_selling_trns_rate      => in_selling_trns_rate        --売上振替割合
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    -- =============================================================================
    -- 2.データを抽出できた場合、A-12へ遷移
    -- =============================================================================
    ELSIF ( ln_selling_trns_rate_info_id IS NOT NULL ) THEN
      upd_selling_trns_rate_info(
        ov_errbuf                    => lv_errbuf                      --エラー・メッセージ
      , ov_retcode                   => lv_retcode                     --リターン・コード
      , ov_errmsg                    => lv_errmsg                      --ユーザー・エラー・メッセージ
      , iv_selling_from_base_code    => iv_selling_from_base_code      --売上振替元拠点コード
      , iv_selling_from_cust_code    => iv_selling_from_cust_code      --売上振替元顧客コード
      , iv_selling_to_cust_code      => iv_selling_to_cust_code        --売上振替先顧客コード
      , in_selling_trns_rate         => in_selling_trns_rate           --売上振替割合
      , iv_invalid_flag              => lv_invalid_flag                --無効フラグ
      , in_selling_trns_rate_info_id => ln_selling_trns_rate_info_id   --売上振替割合情報ID
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_selling_trns_rate_info_a8;
--
  /**********************************************************************************
   * Procedure Name   : get_tmp_tbl
   * Description      : 売上振替割合登録一時表個別データ抽出(A-7)
   ***********************************************************************************/
  PROCEDURE get_tmp_tbl(
    ov_errbuf                 OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                OUT VARCHAR2    --リターン・コード
  , ov_errmsg                 OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id                IN  NUMBER      --ファイルID
  , iv_selling_from_base_code IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code IN  VARCHAR2)   --売上振替先顧客コード
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(15) := 'get_tmp_tbl';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf     VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode    VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg     VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lb_retcode    BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    -- ======================
    -- ローカル・カーソル
    -- ======================
    -- =============================================================================
    -- 売上振替割合登録一時表データ抽出
    -- =============================================================================
    CURSOR get_tmp_cur
    IS
      SELECT  xtsr.valid_invalid_type     AS  valid_invalid_type       --登録・無効区分
            , xtsr.selling_from_base_code AS  selling_from_base_code   --売上振替元拠点コード
            , xtsr.selling_from_cust_code AS  selling_from_cust_code   --売上振替元顧客コード
            , xtsr.selling_to_cust_code   AS  selling_to_cust_code     --売上振替先顧客コード
            , xtsr.selling_trns_rate      AS  selling_trns_rate        --売上振替割合
      FROM    xxcok_tmp_selling_rate xtsr
      WHERE   xtsr.file_id                = in_file_id
      AND     xtsr.selling_from_base_code = iv_selling_from_base_code
      AND     xtsr.selling_from_cust_code = iv_selling_from_cust_code;
    -- =======================
    -- ローカルTABLE型
    -- =======================
    TYPE tab_type IS TABLE OF get_tmp_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_get_tmp_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN  get_tmp_cur;
    FETCH get_tmp_cur BULK COLLECT INTO l_get_tmp_tab;
    CLOSE get_tmp_cur;
--
    <<loop_3>>
    FOR ln_idx IN 1 .. l_get_tmp_tab.COUNT LOOP
      -- =============================================================================
      -- 登録･無効区分が登録(0)の場合、A-8へ遷移
      -- =============================================================================
      IF ( l_get_tmp_tab( ln_idx ).valid_invalid_type = cv_0 ) THEN
        get_selling_trns_rate_info_a8(
          ov_errbuf                 => lv_errbuf                                        --エラーメッセージ
        , ov_retcode                => lv_retcode                                       --リターンコード
        , ov_errmsg                 => lv_errmsg                                        --ユーザーエラーメッセージ
        , iv_selling_from_base_code => l_get_tmp_tab( ln_idx ).selling_from_base_code   --売上振替元拠点コード
        , iv_selling_from_cust_code => l_get_tmp_tab( ln_idx ).selling_from_cust_code   --売上振替元顧客コード
        , iv_selling_to_cust_code   => l_get_tmp_tab( ln_idx ).selling_to_cust_code     --売上振替先顧客コード
        , in_selling_trns_rate      => l_get_tmp_tab( ln_idx ).selling_trns_rate        --売上振替割合
        );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
          EXIT loop_3;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      -- =============================================================================
      -- 登録･無効区分が無効(1)の場合、A-9へ遷移
      -- =============================================================================
      ELSIF ( l_get_tmp_tab( ln_idx ).valid_invalid_type = cv_1 ) THEN
        get_selling_trns_rate_info_a9(
          ov_errbuf                 => lv_errbuf                                        --エラーメッセージ
        , ov_retcode                => lv_retcode                                       --リターンコード
        , ov_errmsg                 => lv_errmsg                                        --ユーザーエラーメッセージ
        , iv_valid_invalid_type     => l_get_tmp_tab( ln_idx ).valid_invalid_type       --登録･無効区分
        , iv_selling_from_base_code => l_get_tmp_tab( ln_idx ).selling_from_base_code   --売上振替元拠点コード
        , iv_selling_from_cust_code => l_get_tmp_tab( ln_idx ).selling_from_cust_code   --売上振替元顧客コード
        , iv_selling_to_cust_code   => l_get_tmp_tab( ln_idx ).selling_to_cust_code     --売上振替先顧客コード
        , in_selling_trns_rate      => l_get_tmp_tab( ln_idx ).selling_trns_rate        --売上振替割合
        );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
          EXIT loop_3;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_3;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1 ,5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_tbl;
--
  /**********************************************************************************
   * Procedure Name   : get_tmp_tbl_union_data
   * Description      : 売上振替割合登録一時表集計データ抽出(A-6)
   ***********************************************************************************/
  PROCEDURE get_tmp_tbl_union_data(
    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    --リターン・コード
  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)     --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name        CONSTANT VARCHAR2(30)  := 'get_tmp_tbl_union_data';  --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                  VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode                 VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg                  VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                     VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode                 BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    -- =======================
    -- ローカル・カーソル
    -- =======================
    -- =============================================================================
    -- 売上振替元データ集計
    -- =============================================================================
    CURSOR data_union_cur
    IS
      SELECT    inline_view_a.selling_from_base_code AS selling_from_base_code
              , inline_view_a.selling_from_cust_code AS selling_from_cust_code
              , SUM(inline_view_a.selling_trns_rate) AS sum_selling_trns_rate
      FROM     (
                SELECT  xtsr.selling_from_base_code            AS selling_from_base_code
                      , xtsr.selling_from_cust_code            AS selling_from_cust_code
                      , xtsr.selling_to_cust_code              AS selling_to_cust_code
                      , DECODE( xtsr.valid_invalid_type,
                                cv_1, cn_0,
                                cv_0, xtsr.selling_trns_rate ) AS selling_trns_rate
                FROM   xxcok_tmp_selling_rate xtsr
                WHERE  xtsr.file_id    = in_file_id
                AND    xtsr.error_flag = cv_0
                UNION ALL
                SELECT  xsri.selling_from_base_code AS selling_from_base_code
                      , xsri.selling_from_cust_code AS selling_from_cust_code
                      , xsri.selling_to_cust_code   AS selling_to_cust_code
                      , xsri.selling_trns_rate      AS selling_trns_rate
                FROM    xxcok_selling_rate_info xsri
                WHERE   xsri.invalid_flag = cv_0
                AND     NOT EXISTS (
                                    SELECT 'X'
                                    FROM   xxcok_tmp_selling_rate xtsr
                                    WHERE  xtsr.file_id    = in_file_id
                                    AND    xtsr.error_flag = cv_0
                                    AND    xtsr.selling_from_base_code = xsri.selling_from_base_code
                                    AND    xtsr.selling_from_cust_code = xsri.selling_from_cust_code
                                    AND    xtsr.selling_to_cust_code   = xsri.selling_to_cust_code
                                   )
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD START
                AND     EXISTS (
                                    SELECT 'X'
                                    FROM   xxcok_tmp_selling_rate xtsr
                                    WHERE  xtsr.file_id    = in_file_id
                                    AND    xtsr.error_flag = cv_0
                                    AND    xtsr.selling_from_base_code = xsri.selling_from_base_code
                                   )
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD END
               ) inline_view_a
      GROUP BY  selling_from_base_code
              , selling_from_cust_code;
    -- =======================
    -- ローカルTABLE型
    -- =======================
    TYPE tab_type IS TABLE OF data_union_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_data_union_cur_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN  data_union_cur;
    FETCH data_union_cur BULK COLLECT INTO l_data_union_cur_tab;
    CLOSE data_union_cur;
--
    <<loop_2>>
    FOR ln_idx IN 1 .. l_data_union_cur_tab.COUNT LOOP
      -- =============================================================================
      --  ロールバック用にセーブポイント設定
      -- =============================================================================
      SAVEPOINT get_union_data_seve;
      -- =============================================================================
      -- 「売上振替割合」の集計値が'100'もしくは'0'でない場合
      -- 例外処理を行い、次のレコードへ処理を遷移
      -- =============================================================================
      IF NOT (   ( l_data_union_cur_tab( ln_idx ).sum_selling_trns_rate = cn_100 )
              OR ( l_data_union_cur_tab( ln_idx ).sum_selling_trns_rate = cn_0   )
             ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10026
                  , iv_token_name1  => cv_token_from_base
                  , iv_token_value1 => l_data_union_cur_tab( ln_idx ).selling_from_base_code
                  , iv_token_name2  => cv_token_from_cust
                  , iv_token_value2 => l_data_union_cur_tab( ln_idx ).selling_from_cust_code
                  , iv_token_name3  => cv_token_rate
                  , iv_token_value3 => TO_CHAR( l_data_union_cur_tab( ln_idx ).sum_selling_trns_rate )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --出力区分
                      , iv_message  => lv_msg              --メッセージ
                      , in_new_line => 0                   --改行
                      );
        ov_retcode := cv_status_warn;
        -- *** エラー件数カウント ***
        gn_error_cnt := gn_error_cnt + 1;
      -- =============================================================================
      -- 「売上振替割合」の集計値が'100'もしくは'0'の場合、A-7へ遷移
      -- =============================================================================
      ELSE
        get_tmp_tbl(
          ov_errbuf                 => lv_errbuf                                             --エラーメッセージ
        , ov_retcode                => lv_retcode                                            --リターンコード
        , ov_errmsg                 => lv_errmsg                                             --ユーザーエラーメッセージ
        , in_file_id                => in_file_id                                            --ファイルID
        , iv_selling_from_base_code => l_data_union_cur_tab( ln_idx ).selling_from_base_code --売上振替元拠点コード
        , iv_selling_from_cust_code => l_data_union_cur_tab( ln_idx ).selling_from_cust_code --売上振替先顧客コード
        );
        IF ( lv_retcode = cv_status_warn ) THEN
          ov_retcode := cv_status_warn;
        ELSIF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_2;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_tbl_union_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_tmp_tbl_error_flag
   * Description      : 売上振替割合登録一時表有効フラグ更新(A-5)
   ***********************************************************************************/
  PROCEDURE upd_tmp_tbl_error_flag(
    ov_errbuf                 OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                OUT VARCHAR2    --リターン・コード
  , ov_errmsg                 OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id                IN  NUMBER      --ファイルID
  , iv_selling_from_base_code IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code IN  VARCHAR2)   --売上振替元顧客コード
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(30) := 'upd_tmp_tbl_error_flag';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg       VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode   BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 1.売上振替割合登録一時表のロック取得
    -- =============================================================================
    CURSOR tmp_selling_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxcok_tmp_selling_rate xtsr
      WHERE  xtsr.file_id = in_file_id
      AND    (   ( xtsr.selling_from_base_code = iv_selling_from_base_code )
              OR ( xtsr.selling_from_base_code IS NULL )
             )
      AND    (   ( xtsr.selling_from_cust_code = iv_selling_from_cust_code )
              OR ( xtsr.selling_from_cust_code IS NULL )
             )
      FOR UPDATE OF xtsr.file_id NOWAIT;
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  tmp_selling_cur;
    CLOSE tmp_selling_cur;
    -- =============================================================================
    -- 2.売上振替割合一時表の更新処理
    -- =============================================================================
    BEGIN
      UPDATE xxcok_tmp_selling_rate xtsr
      SET    error_flag = cv_1
      WHERE  xtsr.file_id = in_file_id
      AND    (   ( xtsr.selling_from_base_code = iv_selling_from_base_code )
              OR ( xtsr.selling_from_base_code IS NULL )
             )
      AND    (   ( xtsr.selling_from_cust_code = iv_selling_from_cust_code )
              OR ( xtsr.selling_from_cust_code IS NULL )
             )
      AND    xtsr.error_flag <> cv_1;
    EXCEPTION
      WHEN OTHERS THEN
      -- *** 更新処理に失敗した場合 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10027
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10352
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END upd_tmp_tbl_error_flag;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : データ妥当性チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf                  OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode                 OUT VARCHAR2    --リターン・コード
  , ov_errmsg                  OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_valid_invalid_type      IN  VARCHAR2    --登録･無効区分
  , iv_selling_from_base_code  IN  VARCHAR2    --売上振替元拠点コード
  , iv_selling_from_cust_code  IN  VARCHAR2    --売上振替元顧客コード
  , iv_selling_to_cust_code    IN  VARCHAR2    --売上振替先顧客コード
  , in_selling_trns_rate       IN  NUMBER)     --振替割合
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10)  := 'chk_data';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --エラーメッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --リターンコード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --ユーザーエラーメッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    ln_selling  NUMBER         DEFAULT 0;      --売上振替割合書式チェック変数
    ln_rownum   NUMBER         DEFAULT 0;      --ROWNUM
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD START
    ln_base_cnt NUMBER;
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD END

    -- =======================
    -- ローカル例外
    -- =======================
    data_warn_expt  EXCEPTION;   --データ警告
    data_many_expt  EXCEPTION;   --データ複数取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.必須チェック
    -- =============================================================================
    IF (   ( iv_valid_invalid_type     IS NULL )
        OR ( iv_selling_from_base_code IS NULL )
        OR ( iv_selling_from_cust_code IS NULL )
        OR ( iv_selling_to_cust_code   IS NULL )
        OR ( in_selling_trns_rate      IS NULL )
       ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10451
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE data_warn_expt;
    END IF;
    -- =============================================================================
    -- 2.「登録・無効区分」が期待値（ゼロか1）でない場合、警告メッセージ出力
    -- =============================================================================
    IF NOT (   ( iv_valid_invalid_type = cv_0 )
            OR ( iv_valid_invalid_type = cv_1 )
           ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10014
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      RAISE data_warn_expt;
    END IF;
    -- =============================================================================
    -- 「登録・無効区分」が「登録(ゼロ)」の場合
    -- =============================================================================
    IF ( iv_valid_invalid_type = cv_0 ) THEN 
      -- =============================================================================
      -- 3.「売上振替元拠点コード」が顧客マスタに存在するか確認
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    hz_cust_accounts hca
        WHERE   hca.account_number      = iv_selling_from_base_code
        AND     hca.customer_class_code = cv_1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10015
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00047
                    , iv_token_name1  => cv_token_sales_loc
                    , iv_token_value1 => iv_selling_from_base_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 4.「売上振替元顧客コード」がマスタに存在するか確認
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    hz_cust_accounts hca
              , hz_parties hp
              , xxcmm_cust_accounts xca
        WHERE   hca.party_id             = hp.party_id
        AND     hca.cust_account_id      = xca.customer_id
        AND     hca.account_number       = iv_selling_from_cust_code
-- Start 2009/07/13 Ver_1.4 0000514 M.Hiruta REPAIR
--        AND     hp.duns_number_c         = cv_40
        AND     hp.duns_number_c        IN( cv_30 , cv_40 , cv_50 )
-- End   2009/07/13 Ver_1.4 0000514 M.Hiruta REPAIR
        AND     xca.selling_transfer_div = cv_1
-- 2009/12/04 Ver.1.6 [E_本稼動_00294] SCS S.Moriyama DEL START
--        AND     xca.chain_store_code IS NULL
-- 2009/12/04 Ver.1.6 [E_本稼動_00294] SCS S.Moriyama DEL END
        AND     hca.customer_class_code <> cv_12;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10016
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00046
                    , iv_token_name1  => cv_token_cust_code
                    , iv_token_value1 => iv_selling_from_cust_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 5.売上振替元拠点コードと売上振替元顧客コードが正しく紐付いていること確認
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    hz_cust_accounts hca
              , xxcmm_cust_accounts xca
        WHERE   hca.cust_account_id = xca.customer_id
        AND     xca.sale_base_code  = iv_selling_from_base_code
        AND     hca.account_number  = iv_selling_from_cust_code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10018
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00046
                    , iv_token_name1  => cv_token_cust_code
                    , iv_token_value1 => iv_selling_from_cust_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
        RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 6.「売上振替先顧客コード」がマスタに存在するかを確認
      -- =============================================================================
      BEGIN
        SELECT ROWNUM
        INTO   ln_rownum
        FROM   hz_parties hp
             , hz_cust_accounts hca
             , xxcmm_cust_accounts xca
        WHERE  hca.party_id             = hp.party_id
        AND    hca.cust_account_id      = xca.customer_id
        AND    hca.account_number       = iv_selling_to_cust_code
-- Start 2009/07/13 Ver_1.4 0000514 M.Hiruta REPAIR
--        AND    hp.duns_number_c         = cv_40
        AND    hp.duns_number_c        IN( cv_30 , cv_40 , cv_50 )
-- End   2009/07/13 Ver_1.4 0000514 M.Hiruta REPAIR
        AND    xca.selling_transfer_div = cv_1
-- 2009/12/04 Ver.1.6 [E_本稼動_00294] SCS S.Moriyama DEL START
--        AND    xca.chain_store_code IS NULL
-- 2009/12/04 Ver.1.6 [E_本稼動_00294] SCS S.Moriyama DEL END
        AND    hca.customer_class_code <> cv_12;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10017
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_warn_expt;
        WHEN TOO_MANY_ROWS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_00046
                    , iv_token_name1  => cv_token_cust_code
                    , iv_token_value1 => iv_selling_to_cust_code
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
        RAISE data_many_expt;
      END;
      -- =============================================================================
      -- 9.売上振替元情報テーブル、売上振替先情報テーブルに、データが存在するか確認
      -- =============================================================================
      BEGIN
        SELECT  ROWNUM
        INTO    ln_rownum
        FROM    xxcok_selling_from_info xsfi
              , xxcok_selling_to_info xsti
        WHERE   xsfi.selling_from_info_id   = xsti.selling_from_info_id
        AND     xsfi.selling_from_base_code = iv_selling_from_base_code
        AND     xsfi.selling_from_cust_code = iv_selling_from_cust_code
        AND     xsti.selling_to_cust_code   = iv_selling_to_cust_code
        AND     xsti.start_month           <= TO_CHAR( TRUNC( gd_process_date, cv_date_format ), 'YYYYMM' )
        AND     xsti.invalid_flag           = cv_0;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_message_10021
                    , iv_token_name1  => cv_token_kubun
                    , iv_token_value1 => iv_valid_invalid_type
                    , iv_token_name2  => cv_token_from_base
                    , iv_token_value2 => iv_selling_from_base_code
                    , iv_token_name3  => cv_token_from_cust
                    , iv_token_value3 => iv_selling_from_cust_code
                    , iv_token_name4  => cv_token_to_cust
                    , iv_token_value4 => iv_selling_to_cust_code
                    , iv_token_name5  => cv_token_rate
                    , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT     --出力区分
                        , iv_message  => lv_msg              --メッセージ
                        , in_new_line => 0                   --改行
                        );
          RAISE data_warn_expt;
      END;
      -- =============================================================================
      -- 10.売上振替割合の値のチェック
      -- =============================================================================
      IF ( in_selling_trns_rate = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10450
                  , iv_token_name1  => cv_token_kubun
                  , iv_token_value1 => iv_valid_invalid_type
                  , iv_token_name2  => cv_token_from_base
                  , iv_token_value2 => iv_selling_from_base_code
                  , iv_token_name3  => cv_token_from_cust
                  , iv_token_value3 => iv_selling_from_cust_code
                  , iv_token_name4  => cv_token_to_cust
                  , iv_token_value4 => iv_selling_to_cust_code
                  , iv_token_name5  => cv_token_rate
                  , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --出力区分
                      , iv_message  => lv_msg              --メッセージ
                      , in_new_line => 0                   --改行
                      );
        RAISE data_warn_expt;
      END IF;
    END IF;
    -- =============================================================================
    -- 7.「売上振替割合」の書式が”999.9”の書式であるかを確認
    -- =============================================================================
    BEGIN
      ln_selling := TO_NUMBER( in_selling_trns_rate, cv_number_format );
    EXCEPTION
      WHEN VALUE_ERROR THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10019
                  , iv_token_name1  => cv_token_kubun
                  , iv_token_value1 => iv_valid_invalid_type
                  , iv_token_name2  => cv_token_from_base
                  , iv_token_value2 => iv_selling_from_base_code
                  , iv_token_name3  => cv_token_from_cust
                  , iv_token_value3 => iv_selling_from_cust_code
                  , iv_token_name4  => cv_token_to_cust
                  , iv_token_value4 => iv_selling_to_cust_code
                  , iv_token_name5  => cv_token_rate
                  , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT     --出力区分
                      , iv_message  => lv_msg              --メッセージ
                      , in_new_line => 0                   --改行
                      );
        RAISE data_warn_expt;
    END;
    -- =============================================================================
    -- 8.売上振替割合の値がマイナスの場合、警告メッセージ
    -- =============================================================================
    IF ( in_selling_trns_rate < cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10020
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      RAISE data_warn_expt;
    END IF;
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD START
    -- =============================================================================
    -- 11.売上振替元拠点コードと実行ユーザーの所属拠点チェック
    -- =============================================================================
    BEGIN
      SELECT COUNT(base_code)
        INTO ln_base_cnt
        FROM xxcok_lov_base_code_v xlbc
       WHERE xlbc.base_code = iv_selling_from_base_code
         AND ROWNUM = 1
      ;
    EXCEPTION
      WHEN OTHERS THEN
        ln_base_cnt := cn_0;
    END;
--
    IF ( ln_base_cnt = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10458
                , iv_token_name1  => cv_token_kubun
                , iv_token_value1 => iv_valid_invalid_type
                , iv_token_name2  => cv_token_from_base
                , iv_token_value2 => iv_selling_from_base_code
                , iv_token_name3  => cv_token_from_cust
                , iv_token_value3 => iv_selling_from_cust_code
                , iv_token_name4  => cv_token_to_cust
                , iv_token_value4 => iv_selling_to_cust_code
                , iv_token_name5  => cv_token_rate
                , iv_token_value5 => TO_CHAR( in_selling_trns_rate )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      RAISE data_warn_expt;
    END IF;
-- 2009/09/09 Ver.1.5 [障害0001303] SCS S.Moriyama ADD END
  EXCEPTION
    -- *** データチェックで警告の場合 ***
    WHEN data_warn_expt THEN
      ov_retcode := cv_status_warn;
    -- *** 存在チェックで複数取得された場合
    WHEN data_many_expt THEN
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END chk_data;
--
  /**********************************************************************************
   * Procedure Name   : get_tmp_selling_trns_rate
   * Description      : 売上振替割合登録一時表データ抽出(A-3)
   ***********************************************************************************/
  PROCEDURE get_tmp_selling_trns_rate(
    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    --リターン・コード
  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)     --ファイルID
  IS
    -- ======================
    -- ローカル定数
    -- ======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'get_tmp_selling_trns_rate';  --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf            VARCHAR2(5000) DEFAULT NULL;   --エラー・メッセージ
    lv_retcode           VARCHAR2(1)    DEFAULT NULL;   --リターン・コード
    lv_errmsg            VARCHAR2(5000) DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg               VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode           BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    ln_selling_trns_rate NUMBER;                        --売上振替割合(一時表集計値)
    -- =====================
    -- ローカル・カーソル
    -- =====================
    CURSOR temporary_cur
    IS
      -- =============================================================================
      -- A-2で取得された一時表のレコードを抽出
      -- =============================================================================
      SELECT  xtsr.valid_invalid_type     AS valid_invalid_type       --登録・無効区分
            , xtsr.selling_from_base_code AS selling_from_base_code   --売上振替元拠点コード
            , xtsr.selling_from_cust_code AS selling_from_cust_code   --売上振替元顧客コード
            , xtsr.selling_to_cust_code   AS selling_to_cust_code     --売上振替先顧客コード
            , xtsr.selling_trns_rate      AS selling_trns_rate        --売上振替割合
      FROM    xxcok_tmp_selling_rate xtsr
      WHERE   xtsr.file_id = in_file_id;
    -- =======================
    -- ローカルTABLE型
    -- =======================
    TYPE tab_type IS TABLE OF temporary_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_temporary_cur_tab  tab_type;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- *** カーソルオープン ***
    OPEN  temporary_cur;
    FETCH temporary_cur BULK COLLECT INTO l_temporary_cur_tab;
    CLOSE temporary_cur;
    -- *** 対象処理件数カウント ***
    gn_target_cnt := l_temporary_cur_tab.COUNT;
--
    <<loop_1>>
    FOR ln_idx IN 1 .. l_temporary_cur_tab.COUNT LOOP
      -- =============================================================================
      -- データ妥当性チェック(A-4)呼び出し
      -- =============================================================================
      chk_data(
        ov_errbuf                 => lv_errbuf                                             --エラーメッセージ
      , ov_retcode                => lv_retcode                                            --リターンコード
      , ov_errmsg                 => lv_errmsg                                             --ユーザーエラーメッセージ
      , iv_valid_invalid_type     => l_temporary_cur_tab( ln_idx ).valid_invalid_type      --登録・無効区分
      , iv_selling_from_base_code => l_temporary_cur_tab( ln_idx ).selling_from_base_code  --売上振替元拠点コード
      , iv_selling_from_cust_code => l_temporary_cur_tab( ln_idx ).selling_from_cust_code  --売上振替元顧客コード
      , iv_selling_to_cust_code   => l_temporary_cur_tab( ln_idx ).selling_to_cust_code    --売上振替先顧客コード
      , in_selling_trns_rate      => l_temporary_cur_tab( ln_idx ).selling_trns_rate       --売上振替割合
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- =============================================================================
      -- 一時表データ有効フラグ更新(A-5)呼び出し
      -- =============================================================================
      IF ( lv_retcode = cv_status_warn ) THEN
        gn_error_cnt := gn_error_cnt + 1;
--
        upd_tmp_tbl_error_flag(
          ov_errbuf                 => lv_errbuf                                             --エラーメッセージ
        , ov_retcode                => lv_retcode                                            --リターンコード
        , ov_errmsg                 => lv_errmsg                                             --ユーザーエラーメッセージ
        , in_file_id                => in_file_id                                            --ファイルID
        , iv_selling_from_base_code => l_temporary_cur_tab( ln_idx ).selling_from_base_code  --売上振替元拠点コード
        , iv_selling_from_cust_code => l_temporary_cur_tab( ln_idx ).selling_from_cust_code  --売上振替元顧客コード
        );
        IF ( lv_retcode = cv_status_error ) THEN
          RAISE global_process_expt;
        END IF;
      END IF;
    END LOOP loop_1;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_selling_trns_rate;
--
  /**********************************************************************************
   * Procedure Name   : get_file_upload_interface_date
   * Description      : ファイルアップロードI/Fデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_upload_interface_date(
    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    --リターン・コード
  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)     --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30)  := 'get_file_upload_interface_date';  --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                  VARCHAR2(5000)  DEFAULT NULL;   --エラー・メッセージ
    lv_retcode                 VARCHAR2(1)     DEFAULT NULL;   --リターン・コード
    lv_errmsg                  VARCHAR2(5000)  DEFAULT NULL;   --ユーザー・エラー・メッセージ
    lv_msg                     VARCHAR2(5000)  DEFAULT NULL;   --メッセージ取得変数
    lv_file_name               VARCHAR2(256)   DEFAULT NULL;   --ファイル名
    lv_valid_invalid_type      VARCHAR2(1)     DEFAULT NULL;   --登録・無効区分
    lv_selling_from_base_code  VARCHAR2(4)     DEFAULT NULL;   --売上振替元拠点コード
    lv_selling_from_cust_code  VARCHAR2(9)     DEFAULT NULL;   --売上振替元顧客コード
    lv_selling_to_cust_code    VARCHAR2(9)     DEFAULT NULL;   --売上振替先顧客コード
    lv_line                    VARCHAR2(32767) DEFAULT NULL;   --1行のデータ
    ln_selling_trns_rate       NUMBER          DEFAULT NULL;   --売上振替割合
    ln_csv_col_cnt             NUMBER          DEFAULT 0;      --CSV項目数
    lb_retcode                 BOOLEAN         DEFAULT TRUE;   --メッセージ出力の戻り値
    -- =======================
    -- ローカルTABLE型
    -- =======================
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;   --行テーブル格納領域
    l_split_csv_tab   xxcok_common_pkg.g_split_csv_tbl;    --CSV分割データ格納領域
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- ファイルアップロードI/Fテーブルのロック取得
    -- =============================================================================
    CURSOR xmf_cur
    IS
      SELECT 'X' AS dummy
      FROM   xxccp_mrp_file_ul_interface xmf
      WHERE  xmf.file_id = in_file_id
      FOR UPDATE OF xmf.file_id NOWAIT;
    -- =======================
    -- ローカル例外
    -- =======================
    blob_expt  EXCEPTION;   --BLOBデータ変換エラー
    file_expt  EXCEPTION;   --空ファイルエラー
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  xmf_cur;
    CLOSE xmf_cur;
    -- =============================================================================
    -- アップロードファイルのファイル名取得
    -- =============================================================================
    SELECT xmf.file_name AS file_name
    INTO   lv_file_name
    FROM   xxccp_mrp_file_ul_interface xmf
    WHERE  xmf.file_id = in_file_id;
    -- =========================================
    -- 1.アップロードファイルのファイル名出力
    -- =========================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00006
              , iv_token_name1  => cv_token_file_name
              , iv_token_value1 => lv_file_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 1                   --改行
                  );
    -- =============================================================================
    -- 3.ファイルアップロードI/FテーブルのFILE_DATA取得
    -- =============================================================================
    xxccp_common_pkg2.blob_to_varchar2(
      ov_errbuf    => lv_errbuf
    , ov_retcode   => lv_retcode
    , ov_errmsg    => lv_errmsg
    , in_file_id   => in_file_id
    , ov_file_data => l_file_data_tab
    );
    IF NOT ( lv_retcode = cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
    -- =============================================================================
    -- 4.データ件数が1件以下の場合、例外処理
    -- =============================================================================
    IF ( l_file_data_tab.COUNT <= cn_1 ) THEN
      RAISE file_expt;
    END IF;
    -- =============================================
    -- 取得した情報を、行ごとに処理(2行目以降)
    -- =============================================
    <<main_loop>>
    FOR ln_index IN 2 .. l_file_data_tab.COUNT LOOP
      --1行毎のデータを格納
      lv_line := l_file_data_tab( ln_index );
      -- =============================================================================
      -- 5.CSV文字列部分割
      -- =============================================================================
      xxcok_common_pkg.split_csv_data_p(
        ov_errbuf        => lv_errbuf         --エラーバッファ
      , ov_retcode       => lv_retcode        --リターンコード
      , ov_errmsg        => lv_errmsg         --エラーメッセージ
      , iv_csv_data      => lv_line           --CSV文字列
      , on_csv_col_cnt   => ln_csv_col_cnt    --CSV項目数
      , ov_split_csv_tab => l_split_csv_tab   --CSV分割データ
      );
      <<comma_loop>>
      FOR ln_cnt IN 1 .. ln_csv_col_cnt LOOP
        --項目①(登録･無効区分)
        IF ( ln_cnt = 1 ) THEN
          lv_valid_invalid_type := l_split_csv_tab( ln_cnt );
        --項目②(売上振替元拠点コード)
        ELSIF ( ln_cnt = 2 ) THEN
          lv_selling_from_base_code := l_split_csv_tab( ln_cnt );
        --項目③(売上振替元顧客コード)
        ELSIF ( ln_cnt = 3 ) THEN
          lv_selling_from_cust_code := l_split_csv_tab( ln_cnt );
        --項目④(売上振替先顧客コード)
        ELSIF ( ln_cnt = 4 ) THEN
          lv_selling_to_cust_code := l_split_csv_tab( ln_cnt );
        --項目⑤(売上振替割合)
        ELSIF ( ln_cnt = 5 ) THEN
          ln_selling_trns_rate := TO_NUMBER( l_split_csv_tab( ln_cnt ) );
        END IF;
      END LOOP comma_loop;
      -- =============================================================================
      -- 6.売上振替割合登録一時表へ読込み
      -- =============================================================================
      INSERT INTO xxcok_tmp_selling_rate(
        valid_invalid_type           --登録・無効区分
      , selling_from_base_code       --売上振替元拠点コード
      , selling_from_cust_code       --売上振替元顧客コード
      , selling_to_cust_code         --売上振替先顧客コード
      , selling_trns_rate            --振替割合
      , file_id                      --ファイルID
      , error_flag                   --エラーフラグ
      ) VALUES (
        lv_valid_invalid_type        --valid_invalid_type
      , lv_selling_from_base_code    --selling_from_base_code
      , lv_selling_from_cust_code    --selling_from_cust_code
      , lv_selling_to_cust_code      --selling_to_cust_code
      , ln_selling_trns_rate         --selling_trns_rate
      , in_file_id                   --file_id
      , cv_0                         --error_flag
      );
    END LOOP main_loop;
  EXCEPTION
    -- *** ロックエラー ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** BLOBデータ変換エラー ***
    WHEN blob_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00041
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
              );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 空ファイルエラー ***
    WHEN file_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_00039
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => gv_file_id
              );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT     --出力区分
                    , iv_message  => lv_msg              --メッセージ
                    , in_new_line => 0                   --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_file_upload_interface_date;
--
  /**********************************************************************************
   * Procedure Name   : init
   * Description      : 初期処理(A-1)
   ***********************************************************************************/
  PROCEDURE init(
    ov_errbuf          OUT VARCHAR2     --エラー・メッセージ
  , ov_retcode         OUT VARCHAR2     --リターン・コード
  , ov_errmsg          OUT VARCHAR2     --ユーザー・エラー・メッセージ
  , in_file_id         IN  NUMBER       --ファイルID
  , iv_format_pattern  IN  VARCHAR2)    --フォーマットパターン
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name      CONSTANT VARCHAR2(50) := 'init';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;   --エラーメッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT NULL;   --リターンコード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;   --ユーザーエラーメッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lb_retcode  BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    -- =======================
    -- ローカル例外
    -- =======================
    get_process_expt  EXCEPTION;   --業務日付取得エラー
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.コンカレントプログラム入力項目をメッセージ出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00016
              , iv_token_name1  => cv_token_file_id
              , iv_token_value1 => gv_file_id
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                     in_which    => FND_FILE.OUTPUT  --出力区分
                   , iv_message  => lv_msg           --メッセージ
                   , in_new_line => 0                --改行
                   );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 0                 --改行
                  );
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00017
              , iv_token_name1  => cv_token_format
              , iv_token_value1 => iv_format_pattern
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT  --出力区分
                  , iv_message  => lv_msg           --メッセージ
                  , in_new_line => 1                --改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 2                 --改行
                  );
    -- =============================================================================
    -- 2.業務処理日付の取得
    -- =============================================================================
    gd_process_date := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_process_date IS NULL ) THEN
      RAISE get_process_expt;
    END IF;
  EXCEPTION
    -- *** 業務日付取得エラー ***
    WHEN get_process_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_00028
                  );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END init;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf         OUT VARCHAR2     --エラーメッセージ
  , ov_retcode        OUT VARCHAR2     --リターンコード
  , ov_errmsg         OUT VARCHAR2     --ユーザーエラーメッセージ
  , in_file_id        IN  NUMBER       --ファイルID
  , iv_format_pattern IN  VARCHAR2)    --フォーマットパターン
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name  CONSTANT VARCHAR2(10) := 'submain';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;   --エラーメッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT NULL;   --リターンコード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;   --ユーザーエラーメッセージ
    lb_retcode   BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
    ln_counter   NUMBER         DEFAULT 0;      --一時表の有効データカウント
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 初期処理(A-1)の呼出し
    -- =============================================================================
    init(
      ov_errbuf         => lv_errbuf           --エラーメッセージ
    , ov_retcode        => lv_retcode          --リターンコード
    , ov_errmsg         => lv_errmsg           --ユーザーエラーメッセージ
    , in_file_id        => in_file_id          --ファイルID
    , iv_format_pattern => iv_format_pattern   --フォーマットパターン
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- ファイルアップロードI/Fデータ取得(A-2)の呼出し
    -- =============================================================================
    get_file_upload_interface_date(
      ov_errbuf  => lv_errbuf    --エラーメッセージ
    , ov_retcode => lv_retcode   --リターンコード
    , ov_errmsg  => lv_errmsg    --ユーザーエラーメッセージ
    , in_file_id => in_file_id   --ファイルID
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- 一時表データ抽出(A-3)の呼出し
    -- =============================================================================
    get_tmp_selling_trns_rate(
      ov_errbuf  => lv_errbuf    --エラーメッセージ
    , ov_retcode => lv_retcode   --リターンコード
    , ov_errmsg  => lv_errmsg    --ユーザーエラーメッセージ
    , in_file_id => in_file_id   --ファイルID
    );
    IF ( lv_retcode = cv_status_warn ) THEN
      ov_retcode := cv_status_warn;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- 一時表に有効データが存在するかチェック
    -- =============================================================================
    SELECT COUNT(xtsr.file_id)
    INTO   ln_counter
    FROM   xxcok_tmp_selling_rate xtsr
    WHERE  xtsr.file_id    = in_file_id
    AND    xtsr.error_flag = cv_0
    AND    ROWNUM = 1;
    -- =============================================================================
    -- 有効データが存在した場合、一時表集計データ抽出(A-6)の呼出し
    -- =============================================================================
    IF( ln_counter <> 0 ) THEN
      get_tmp_tbl_union_data(
        ov_errbuf  => lv_errbuf    --エラーメッセージ
      , ov_retcode => lv_retcode   --リターンコード
      , ov_errmsg  => lv_errmsg    --ユーザーエラーメッセージ
      , in_file_id => in_file_id   --ファイルID
      );
      IF ( lv_retcode = cv_status_warn ) THEN
        ov_retcode := cv_status_warn;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
    -- =============================================================================
    -- ファイルアップロードI/Fテーブルレコード削除(A-13)
    -- =============================================================================
    IF (   ( lv_retcode = cv_status_normal )
        OR ( lv_retcode = cv_status_warn )
        ) THEN
      del_file_upload_interface_tbl(
        ov_errbuf  => lv_errbuf    --エラーメッセージ
      , ov_retcode => lv_retcode   --リターンコード
      , ov_errmsg  => lv_errmsg    --ユーザーエラーメッセージ
      , in_file_id => in_file_id   --ファイルID
      );
      IF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
    END IF;
  EXCEPTION
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : 売上振替割合の登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf            OUT  VARCHAR2     --エラーメッセージ
  , retcode           OUT  VARCHAR2     --エラーコード
  , iv_file_id        IN   VARCHAR2     --ファイルID
  , iv_format_pattern IN   VARCHAR2)    --フォーマットパターン
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name      CONSTANT VARCHAR2(5) := 'main';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf         VARCHAR2(5000) DEFAULT NULL;   --エラーメッセージ
    lv_retcode        VARCHAR2(1)    DEFAULT NULL;   --リターンコード
    lv_errmsg         VARCHAR2(5000) DEFAULT NULL;   --ユーザーエラーメッセージ
    lv_msg            VARCHAR2(5000) DEFAULT NULL;   --メッセージ取得変数
    lv_message_code   VARCHAR2(5000) DEFAULT NULL;   --メッセージコード
    lb_retcode        BOOLEAN        DEFAULT TRUE;   --メッセージ出力の戻り値
--
  BEGIN
    gn_file_id := TO_NUMBER( iv_file_id );
    gv_file_id := iv_file_id;
    -- =============================================================================
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    -- =============================================================================
    xxccp_common_pkg.put_log_header(
      ov_retcode => lv_retcode
    , ov_errbuf  => lv_errbuf
    , ov_errmsg  => lv_errmsg
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_api_expt;
    END IF;
    -- =============================================================================
    -- submainの呼出し
    -- =============================================================================
    submain(
      ov_errbuf         => lv_errbuf           --エラーメッセージ
    , ov_retcode        => lv_retcode          --リターンコード
    , ov_errmsg         => lv_errmsg           --ユーザーエラーメッセージ
    , in_file_id        => gn_file_id          --ファイルID
    , iv_format_pattern => iv_format_pattern   --フォーマットパターン
    );
    -- =============================================================================
    -- エラー終了の場合、対象件数・成功件数を0件にし、エラー件数を1件にする。
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      gn_target_cnt := cn_0;
      gn_normal_cnt := cn_0;
      gn_error_cnt  := cn_1;
    END IF;
    -- =============================================================================
    -- エラー出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_errmsg         --メッセージ
                    , in_new_line => 1                 --改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      --出力区分
                    , iv_message  => lv_errbuf         --メッセージ
                    , in_new_line => 0                 --改行
                    );
    END IF;
    -- =============================================================================
    -- 警告終了の場合、空行を出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_warn ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => NULL              --メッセージ
                    , in_new_line => 1                 --改行
                    );
    END IF;
    -- =============================================================================
    -- 対象件数出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90000
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_target_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- =============================================================================
    -- 成功件数出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90001
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_normal_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- =============================================================================
    -- エラー件数出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90002
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => TO_CHAR( gn_error_cnt )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 1                   --改行
                  );
    -- =============================================================================
    -- 処理終了メッセージを出力
    -- =============================================================================
    IF ( lv_retcode = cv_status_normal ) THEN
      lv_message_code := cv_message_90004;
    ELSIF ( lv_retcode = cv_status_warn ) THEN
      lv_message_code := cv_message_90005;
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_message_90006;
    END IF;
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => lv_message_code
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- *** ステータスセット ***
    retcode := lv_retcode;
    -- *** 終了ステータスがエラーの場合はROLLBACK ***
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
      --IFテーブルにデータがある場合は削除
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --エラー・メッセージ
      , ov_retcode => lv_retcode     --リターン・コード
      , ov_errmsg  => lv_errmsg      --ユーザー・エラー・メッセージ
      , in_file_id => gn_file_id     --ファイルID
      );
    END IF;
    --エラー時IFデータ削除処理用エラー出力とROLLBACK
    IF ( lv_retcode = cv_status_error ) THEN
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_errmsg         --メッセージ
                    , in_new_line => 1                 --改行
                    );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.LOG      --出力区分
                    , iv_message  => lv_errbuf         --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ROLLBACK;
    END IF;
    --処理の確定
    COMMIT;
  EXCEPTION
    -- *** 共通関数例外ハンドラ ***
    WHEN global_api_expt THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_errbuf, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
      --IFテーブルにデータがある場合は削除
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --エラー・メッセージ
      , ov_retcode => lv_retcode     --リターン・コード
      , ov_errmsg  => lv_errmsg      --ユーザー・エラー・メッセージ
      , in_file_id => gn_file_id     --ファイルID
      );
      --エラー時IFデータ削除処理用エラー出力とROLLBACK
      IF ( lv_retcode = cv_status_error ) THEN
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_errmsg         --メッセージ
                      , in_new_line => 1                 --改行
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      --出力区分
                      , iv_message  => lv_errbuf         --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ROLLBACK;
      END IF;
    --処理の確定
    COMMIT;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      retcode := cv_status_error;
      ROLLBACK;
      --IFテーブルにデータがある場合は削除
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --エラー・メッセージ
      , ov_retcode => lv_retcode     --リターン・コード
      , ov_errmsg  => lv_errmsg      --ユーザー・エラー・メッセージ
      , in_file_id => gn_file_id     --ファイルID
      );
      --エラー時IFデータ削除処理用エラー出力とROLLBACK
      IF ( lv_retcode = cv_status_error ) THEN
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_errmsg         --メッセージ
                      , in_new_line => 1                 --改行
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      --出力区分
                      , iv_message  => lv_errbuf         --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ROLLBACK;
      END IF;
    --処理の確定
    COMMIT;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      retcode := cv_status_error;
      ROLLBACK;
      --IFテーブルにデータがある場合は削除
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --エラー・メッセージ
      , ov_retcode => lv_retcode     --リターン・コード
      , ov_errmsg  => lv_errmsg      --ユーザー・エラー・メッセージ
      , in_file_id => gn_file_id     --ファイルID
      );
      --エラー時IFデータ削除処理用エラー出力とROLLBACK
      IF ( lv_retcode = cv_status_error ) THEN
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_errmsg         --メッセージ
                      , in_new_line => 1                 --改行
                      );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.LOG      --出力区分
                      , iv_message  => lv_errbuf         --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ROLLBACK;
      END IF;
    --処理の確定
    COMMIT;
  END main;
END XXCOK008A04C;
/
