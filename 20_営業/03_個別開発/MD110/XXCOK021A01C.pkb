CREATE OR REPLACE PACKAGE BODY XXCOK021A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A01C(body)
 * Description      : 問屋販売条件請求書Excelアップロード
 * MD.050           : 問屋販売条件請求書Excelアップロード MD050_COK_021_A01
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  init                         初期処理(A-1)
 *  get_file_data                ファイルデータ取得(A-2)
 *  get_tmp_wholesale_bill       一時表データ取得(A-3)
 *  chk_data                     妥当性チェック(A-4)
 *  chk_wholesale_bill_data      問屋請求書テーブルデータチェック(A-5)
 *  del_wholesale_bill_details   明細データ削除(A-6)
 *  ins_wholesale_bill_tbl       問屋請求書テーブルデータ登録(A-7)
 *  del_mrp_file_ul_interface    処理データ削除(A-8)
 *  del_interface_at_error       エラー時IFデータ削除(A-10)
 *  submain                      メイン処理プロシージャ
 *  main                         コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/11    1.0   S.Sasaki         新規作成
 *  2009/02/02    1.1   S.Sasaki         [障害COK_005]取得条件追加、エラー時IFデータ削除処理追加
 *  2009/03/10    1.2   K.Yamaguchi      [障害T1_0009]問屋請求書明細テーブル削除処理変更
 *  2009/04/10    1.3   M.Hiruta         [障害T1_0400]数値チェックでマイナス値をチェックできるよう変更
 *                                       [障害T1_0493]妥当性チェックのNULLチェック時に正確な項目を参照するよう修正
 *  2009/08/27    1.4   T.Taniguchi      [障害0001176]問屋請求書明細テーブル削除条件追加
 *  2009/09/30    1.5   S.Moriyama       [障害0001392]E_T3_00592対応：請求数量、請求単価に0以外が設定されている場合に
 *                                                                    請求金額の必須チェックを行うよう修正
 *                                                                    勘定科目支払時に支払数量が1以外の場合エラーとする
 *  2009/12/18    1.6   K.Yamaguchi      [E_本稼動_00539] 妥当性チェック追加
 *  2009/12/24    1.7   K.Nakamura       [E_本稼動_00554] 問屋請求書テーブルデータチェック処理、明細データ削除処理に条件追加
 *  2009/12/25    1.8   K.Nakamura       [E_本稼動_00608] 請求単価、支払単価チェック修正
 *
 *****************************************************************************************/
--
  -- =============================================================================
  -- グローバル定数
  -- =============================================================================
  --パッケージ名
  cv_pkg_name                CONSTANT VARCHAR2(20) := 'XXCOK021A01C';
  --アプリケーション短縮名
  cv_xxcok_appl_name         CONSTANT VARCHAR2(10) := 'XXCOK';
  cv_xxccp_appl_name         CONSTANT VARCHAR2(10) := 'XXCCP';
  --ステータス・コード
  cv_status_normal           CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn             CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error            CONSTANT VARCHAR2(1)  := xxccp_common_pkg.set_status_error;  --異常:2
  cv_status_continue         CONSTANT VARCHAR2(1)  := '9';                                --継続エラー
  --メッセージ名称
  cv_err_msg_00062           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00062';   --IF表削除エラー
  cv_err_msg_10093           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10093';   --明細テーブルロック取得エラー
  cv_err_msg_10094           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10094';   --明細テーブルデータ削除エラー
  cv_err_msg_10092           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10092';   --既存データステータスエラー
  cv_err_msg_10161           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10161';   --必須チェックエラー
  cv_err_msg_10140           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10140';   --請求数量半角数字チェックエラー
  cv_err_msg_10141           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10141';   --請求単価半角数字チェックエラー
  cv_err_msg_10142           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10142';   --請求金額半角数字チェックエラー
  cv_err_msg_10143           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10143';   --支払数量半角数字チェックエラー
  cv_err_msg_10144           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10144';   --支払単価半角数字チェックエラー
  cv_err_msg_10145           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10145';   --支払金額半角数字チェックエラー
  cv_err_msg_10153           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10153';   --支払予定日日付チェックエラー
  cv_err_msg_10152           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10152';   --売上対象年月日付チェックエラー
  cv_err_msg_10147           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10147';   --請求書No桁数チェックエラー
  cv_err_msg_10148           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10148';   --請求数量桁数チェックエラー
  cv_err_msg_10149           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10149';   --請求単価桁数チェックエラー
  cv_err_msg_10150           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10150';   --請求金額桁数チェックエラー
  cv_err_msg_10151           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10151';   --請求単位桁数チェックエラー
  cv_err_msg_10154           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10154';   --支払数量桁数チェックエラー
  cv_err_msg_10155           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10155';   --支払単価桁数チェックエラー
  cv_err_msg_10156           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10156';   --支払金額桁数チェックエラー
  cv_err_msg_10162           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10162';   --仕入先コードチェックエラー
  cv_err_msg_10163           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10163';   --拠点コードチェックエラー
  cv_err_msg_10382           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10382';   --拠点コードチェックエラー(拠点内務員)
  cv_err_msg_10164           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10164';   --顧客コードチェックエラー
  cv_err_msg_10165           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10165';   --問屋帳合先コードチェックエラー
  cv_err_msg_10166           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10166';   --品目コードチェックエラー
  cv_err_msg_10167           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10167';   --勘定科目コードチェックエラー
  cv_err_msg_10168           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10168';   --補助科目コードチェックエラー
  cv_err_msg_10169           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10169';   --支払予定日チェックエラー
-- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama ADD START
  cv_err_msg_10464           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10464';   --請求金額条件必須メッセージー
  cv_err_msg_10465           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10465';   --請求、支払数量チェックエラー
-- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama ADD END
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
  cv_err_msg_10466           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10466';   --品目または勘定科目必須
  cv_err_msg_10467           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10467';   --勘定科目支払時、勘定科目・補助科目必須
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD START
  cv_err_msg_10470           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10470';   --勘定科目支払時、請求単価チェックエラー
  cv_err_msg_10471           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10471';   --勘定科目支払時、請求単価チェックエラー
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD END
  cv_err_msg_00061           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00061';   --IF表ロック取得エラー
  cv_err_msg_00041           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00041';   --BLOBデータ変換エラー
  cv_err_msg_00039           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00039';   --空ファイルエラー
  cv_err_msg_00003           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00003';   --プロファイル取得エラー
  cv_err_msg_00030           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00030';   --所属部門取得エラー
  cv_err_msg_00028           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00028';   --業務日付取得エラーメッセージ
  cv_message_00016           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00016';   --入力パラメータ(ファイルID)
  cv_message_00017           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00017';   --入力パラメータ(フォーマットパターン)
  cv_message_00006           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-00006';   --ファイル名メッセージ出力
  cv_message_10385           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10385';   --支払数量・支払単価・支払金額チェック
  cv_message_10388           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10388';   --拠点コードステータスエラー
  cv_message_10389           CONSTANT VARCHAR2(500) := 'APP-XXCOK1-10389';   --顧客コードステータスエラー
  cv_message_90000           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90000';   --対象件数メッセージ
  cv_message_90001           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90001';   --成功件数メッセージ
  cv_message_90002           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90002';   --エラー件数メッセージ
  cv_message_90004           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90004';   --正常終了メッセージ
  cv_message_90006           CONSTANT VARCHAR2(500) := 'APP-XXCCP1-90006';   --エラー終了全ロールバックメッセージ
  --プロファイル
  cv_dept_code_p             CONSTANT VARCHAR2(100) := 'XXCOK1_AFF2_DEPT_ACT';   --業務管理部の部門コード
  cv_org_id_p                CONSTANT VARCHAR2(100) := 'ORG_ID';                 --営業単位ID
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
  cv_organization_code       CONSTANT VARCHAR2(100) := 'XXCOK1_ORG_CODE_SALES';  --在庫組織
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
  --トークン
  cv_token_file_id           CONSTANT VARCHAR2(10)  := 'FILE_ID';         --トークン名(FILE_ID)
  cv_token_format            CONSTANT VARCHAR2(10)  := 'FORMAT';          --トークン名(FORMAT)
  cv_token_user_id           CONSTANT VARCHAR2(10)  := 'USER_ID';         --トークン名(USER_ID)
  cv_token_file_name         CONSTANT VARCHAR2(10)  := 'FILE_NAME';       --トークン名(FILE_NAME)
  cv_token_customer_code     CONSTANT VARCHAR2(15)  := 'CUSTOMER_CODE';   --トークン名(CUSTOMER_CODE)
  cv_token_invoice_no        CONSTANT VARCHAR2(10)  := 'INVOICE_NO';      --トークン名(INVOICE_NO)
  cv_token_row_num           CONSTANT VARCHAR2(10)  := 'ROW_NUM';         --トークン名(ROW_NUM)
  cv_token_vendor_code       CONSTANT VARCHAR2(15)  := 'VENDOR_CODE';     --トークン名(VENDOR_CODE)
  cv_token_kyoten_code       CONSTANT VARCHAR2(15)  := 'KYOTEN_CODE';     --トークン名(KYOTEN_CODE)
  cv_token_tonya_code        CONSTANT VARCHAR2(10)  := 'TONYA_CODE';      --トークン名(TONYA_CODE)
  cv_token_item_code         CONSTANT VARCHAR2(10)  := 'ITEM_CODE';       --トークン名(ITEM_CODE)
  cv_token_account_code      CONSTANT VARCHAR2(15)  := 'ACCOUNT_CODE';    --トークン名(ACCOUNT_CODE)
  cv_token_sub_code          CONSTANT VARCHAR2(10)  := 'SUB_CODE';        --トークン名(SUB_CODE)
  cv_token_payment_date      CONSTANT VARCHAR2(15)  := 'PAYMENT_DATE';    --トークン名(PAYMENT_DATE)
  cv_token_profile           CONSTANT VARCHAR2(10)  := 'PROFILE';         --トークン名(PROFILE)
  cv_token_emp               CONSTANT VARCHAR2(10)  := 'EMP_CODE';        --トークン名(EMP_CODE)
  cv_token_count             CONSTANT VARCHAR2(5)   := 'COUNT';           --トークン名(COUNT)
  --フォーマット
  cv_date_format1            CONSTANT VARCHAR2(10)  := 'FXYYYYMMDD';   --支払予定日のフォーマット
  cv_date_format2            CONSTANT VARCHAR2(8)   := 'FXYYYYMM';     --売上対象年月のフォーマット
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD START
  cv_number_format1          CONSTANT VARCHAR2(7)   := '9999999';      --勘定科目支払時の単価フォーマット
  cv_number_format2          CONSTANT VARCHAR2(10)  := '9999999.99';   --勘定科目支払時以外の単価フォーマット
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD END
  --記号
  cv_msg_part                CONSTANT VARCHAR2(3)   := ' : ';   --コロン
  cv_msg_cont                CONSTANT VARCHAR2(3)   := '.';     --ピリオド
  cv_comma                   CONSTANT VARCHAR2(1)   := ',';     --カンマ
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
  cv_minus                   CONSTANT VARCHAR2(1)   := '-';     --マイナス
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
  --文字列
  cv_revise_flag             CONSTANT VARCHAR2(1)   := '0';    --業管訂正フラグ(0:未訂正)
  cv_base_code               CONSTANT VARCHAR2(1)   := '1';    --顧客区分(拠点コード)
  cv_sales_wholesale         CONSTANT VARCHAR2(2)   := '12';   --帳合問屋
  cv_sales_outlets           CONSTANT VARCHAR2(2)   := '16';   --問屋帳合先
  cv_status_a                CONSTANT VARCHAR2(1)   := 'A';    --A:確定済
  cv_status_i                CONSTANT VARCHAR2(1)   := 'I';    --I:業管訂正
  cv_status_p                CONSTANT VARCHAR2(1)   := 'P';    --P:支払済
  cv_cust_status_80          CONSTANT VARCHAR2(2)   := '80';   --80:更正債権
  cv_cust_status_90          CONSTANT VARCHAR2(2)   := '90';   --90:中止決裁済
  --数値
  cn_0                       CONSTANT NUMBER        := 0;      --数値:0
  cn_1                       CONSTANT NUMBER        := 1;      --数値:1
  cn_2                       CONSTANT NUMBER        := 2;      --数値:2
  cn_9                       CONSTANT NUMBER        := 9;      --数値:9
  cn_10                      CONSTANT NUMBER        := 10;     --数値:10
  --WHOカラム
  cn_created_by              CONSTANT NUMBER        := fnd_global.user_id;           --CREATED_BY
  cn_last_updated_by         CONSTANT NUMBER        := fnd_global.user_id;           --LAST_UPDATED_BY
  cn_last_update_login       CONSTANT NUMBER        := fnd_global.login_id;          --LAST_UPDATE_LOGIN
  cn_request_id              CONSTANT NUMBER        := fnd_global.conc_request_id;   --REQUEST_ID
  cn_program_application_id  CONSTANT NUMBER        := fnd_global.prog_appl_id;      --PROGRAM_APPLICATION_ID
  cn_program_id              CONSTANT NUMBER        := fnd_global.conc_program_id;   --PROGRAM_ID
  -- =============================================================================
  -- グローバル変数
  -- =============================================================================
  gn_target_cnt     NUMBER        DEFAULT 0;                  --対象件数
  gn_normal_cnt     NUMBER        DEFAULT 0;                  --成功件数
  gn_error_cnt      NUMBER        DEFAULT 0;                  --エラー件数
  gv_user_dept_code VARCHAR2(100) DEFAULT NULL;               --ユーザ担当拠点(A-1,A-4)
  gv_dept_code      VARCHAR2(100) DEFAULT NULL;               --カスタム･プロファイル取得変数
  gn_org_id         NUMBER;                                   --プロファイル(営業単位)
  gd_prdate         DATE;                                     --業務日付
  gv_chk_code       VARCHAR2(1)   DEFAULT cv_status_normal;   --妥当性チェックの処理結果ステータス
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
  gv_organization_code  mtl_parameters.organization_code%TYPE DEFAULT NULL;  --在庫組織
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
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
  PRAGMA EXCEPTION_INIT(global_lock_fail, -54);
  PRAGMA EXCEPTION_INIT(global_api_others_expt, -20000);
--
  /**********************************************************************************
   * Procedure Name   : del_interface_at_error
   * Description      : エラー時IFデータ削除(A-10)
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
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
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
                  , iv_name         => cv_err_msg_00062
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => TO_CHAR( in_file_id )
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
    -- *** ロック失敗 ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_interface_at_error;
--
  /**********************************************************************************
   * Procedure Name   : del_mrp_file_ul_interface
   * Description      : 処理データ削除(A-8)
   ***********************************************************************************/
  PROCEDURE del_mrp_file_ul_interface(
    ov_errbuf   OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2    --リターン・コード
  , ov_errmsg   OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)     --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'del_mrp_file_ul_interface';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf  VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg  VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg     VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lb_retcode BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- ファイルアップロードIF表の削除処理
    -- =============================================================================
    BEGIN
      DELETE FROM xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id;
      COMMIT;
    EXCEPTION
      -- *** 削除処理に失敗 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_00062
                  , iv_token_name1  => cv_token_file_id
                  , iv_token_value1 => TO_CHAR( in_file_id )
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
      ov_errbuf  := cv_pkg_name || cv_msg_cont ||cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END del_mrp_file_ul_interface;
--
  /**********************************************************************************
   * Procedure Name   : ins_wholesale_bill_tbl
   * Description      : 問屋請求書テーブルデータ登録(A-7)
   ***********************************************************************************/
  PROCEDURE ins_wholesale_bill_tbl(
    ov_errbuf               OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode              OUT VARCHAR2    --リターン・コード
  , ov_errmsg               OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , iv_supplier_code        IN  VARCHAR2    --仕入先コード
  , iv_expect_payment_date  IN  VARCHAR2    --支払予定日
  , iv_selling_month        IN  VARCHAR2    --売上対象年月
  , iv_base_code            IN  VARCHAR2    --拠点コード
  , iv_bill_no              IN  VARCHAR2    --請求書No.
  , iv_cust_code            IN  VARCHAR2    --顧客コード
  , iv_sales_outlets_code   IN  VARCHAR2    --問屋帳合先コード
  , iv_item_code            IN  VARCHAR2    --品目コード
  , iv_acct_code            IN  VARCHAR2    --勘定科目コード
  , iv_sub_acct_code        IN  VARCHAR2    --補助科目コード
  , iv_demand_unit_type     IN  VARCHAR2    --請求単位
  , iv_demand_qty           IN  VARCHAR2    --請求数量
  , iv_demand_unit_price    IN  VARCHAR2    --請求単価(税抜)
  , iv_demand_amt           IN  VARCHAR2    --請求金額(税抜)
  , iv_payment_qty          IN  VARCHAR2    --支払数量
  , iv_payment_unit_price   IN  VARCHAR2    --支払単価(税抜)
  , iv_payment_amt          IN  VARCHAR2)   --支払金額(税抜)
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'ins_wholesale_bill_tbl';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf                    VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode                   VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg                    VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg                       VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lb_retcode                   BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
    ln_wholesale_bill_header_id  NUMBER;                                    --問屋請求書ヘッダーID
    ln_wholesale_bill_detail_id  NUMBER;                                    --問屋請求書明細ID
    ln_payment_qty               NUMBER;                                    --支払数量
    ln_payment_unit_price        NUMBER;                                    --支払単価
    ln_payment_amt               NUMBER;                                    --支払金額
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.問屋請求書ヘッダーテーブルに、既に対象となるヘッダーが存在するかチェック
    -- =============================================================================
    BEGIN
      SELECT xwbh.wholesale_bill_header_id AS wholesale_bill_header_id
      INTO   ln_wholesale_bill_header_id
      FROM   xxcok_wholesale_bill_head xwbh
      WHERE  xwbh.base_code           = iv_base_code
      AND    xwbh.cust_code           = iv_cust_code
      AND    xwbh.supplier_code       = iv_supplier_code
      AND    xwbh.expect_payment_date = TO_DATE( iv_expect_payment_date, cv_date_format1 );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      -- =============================================================================
      -- 問屋請求書ヘッダーIDをシーケンスより取得
      -- =============================================================================
      SELECT xxcok_wholesale_bill_head_s01.NEXTVAL AS xxcok_wholesale_bill_head_s01
      INTO   ln_wholesale_bill_header_id
      FROM   DUAL;
      -- =============================================================================
      -- 2.問屋請求書ヘッダーテーブルへレコードの追加
      -- =============================================================================
      INSERT INTO xxcok_wholesale_bill_head(
        wholesale_bill_header_id                             --問屋請求書ヘッダーID
      , base_code                                            --拠点コード
      , cust_code                                            --顧客コード
      , supplier_code                                        --仕入先コード
      , expect_payment_date                                  --支払予定日
      , created_by                                           --作成者
      , creation_date                                        --作成日
      , last_updated_by                                      --最終更新者
      , last_update_date                                     --最終更新日
      , last_update_login                                    --最終更新ログイン
      , request_id                                           --要求ID
      , program_application_id                               --コンカレント・プログラム・アプリケーションID
      , program_id                                           --コンカレント・プログラムID
      , program_update_date                                  --プログラム更新日
      ) VALUES (
        ln_wholesale_bill_header_id                          --wholesale_bill_header_id
      , iv_base_code                                         --base_code
      , iv_cust_code                                         --cust_code
      , iv_supplier_code                                     --supplier_code
      , TO_DATE( iv_expect_payment_date, cv_date_format1 )   --expect_payment_date
      , cn_created_by                                        --created_by
      , SYSDATE                                              --creation_date
      , cn_last_updated_by                                   --last_updated_by
      , SYSDATE                                              --last_update_date
      , cn_last_update_login                                 --last_update_login
      , cn_request_id                                        --request_id
      , cn_program_application_id                            --program_application_id
      , cn_program_id                                        --program_id
      , SYSDATE                                              --program_update_date
      );
    END;
    -- =============================================================================
    -- 支払数量、支払単価、支払金額がすべて'NULL'の場合、A-3で取得した
    -- 請求数量、請求単価(税抜)、請求金額(税抜)を設定
    -- =============================================================================
    IF (    ( iv_payment_qty        IS NULL )
        AND ( iv_payment_unit_price IS NULL )
        AND ( iv_payment_amt        IS NULL )
       ) THEN
      ln_payment_qty        := TO_NUMBER( iv_demand_qty );
      ln_payment_unit_price := TO_NUMBER( iv_demand_unit_price );
      ln_payment_amt        := TO_NUMBER( iv_demand_amt );
    ELSE
      ln_payment_qty        := TO_NUMBER( iv_payment_qty );
      ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price );
      ln_payment_amt        := TO_NUMBER( iv_payment_amt );
    END IF;
    -- =============================================================================
    -- 問屋請求書明細IDをシーケンスより取得
    -- =============================================================================
    SELECT xxcok_wholesale_bill_line_s01.NEXTVAL AS xxcok_wholesale_bill_line_s01
    INTO   ln_wholesale_bill_detail_id
    FROM   DUAL;
    -- =============================================================================
    -- 3.問屋請求書明細テーブルへレコードの追加
    -- =============================================================================
    INSERT INTO xxcok_wholesale_bill_line(
      wholesale_bill_detail_id            --問屋請求書明細ID
    , wholesale_bill_header_id            --問屋請求書ヘッダーID
    , bill_no                             --請求書No
    , sales_outlets_code                  --問屋帳合先コード
    , item_code                           --品目コード
    , demand_qty                          --請求数量
    , demand_unit_price                   --請求単価
    , demand_amt                          --請求金額
    , selling_month                       --売上対象年月
    , demand_unit_type                    --請求単位
    , acct_code                           --勘定科目コード
    , sub_acct_code                       --補助科目コード
    , payment_qty                         --支払数量
    , payment_unit_type                   --支払単位
    , payment_unit_price                  --支払単価
    , payment_amt                         --支払金額
    , status                              --ステータス
    , revise_flag                         --業管訂正フラグ
    , payment_creation_date               --支払データ作成年月日
    , created_by                          --作成者
    , creation_date                       --作成日
    , last_updated_by                     --最終更新者
    , last_update_date                    --最終更新日
    , last_update_login                   --最終更新ログイン
    , request_id                          --要求ID
    , program_application_id              --コンカレント・プログラム・アプリケーションID
    , program_id                          --コンカレント・プログラムID
    , program_update_date                 --プログラム更新日
    ) VALUES (
      ln_wholesale_bill_detail_id         --wholesale_bill_detail_id
    , ln_wholesale_bill_header_id         --wholesale_bill_header_id
    , iv_bill_no                          --bill_no
    , iv_sales_outlets_code               --sales_outlets_code
    , iv_item_code                        --item_code
    , TO_NUMBER( iv_demand_qty )          --demand_qty
    , TO_NUMBER( iv_demand_unit_price )   --demand_unit_price
    , TO_NUMBER( iv_demand_amt )          --demand_amt
    , iv_selling_month                    --selling_month
    , iv_demand_unit_type                 --demand_unit_type
    , iv_acct_code                        --acct_code
    , iv_sub_acct_code                    --sub_acct_code
    , ln_payment_qty                      --payment_qty
    , iv_demand_unit_type                 --payment_unit_type
    , ln_payment_unit_price               --payment_unit_price
    , ln_payment_amt                      --payment_amt
    , NULL                                --status
    , cv_revise_flag                      --revise_flag
    , NULL                                --payment_creation_date
    , cn_created_by                       --created_by
    , SYSDATE                             --creation_date
    , cn_last_updated_by                  --last_updated_by
    , SYSDATE                             --last_update_date
    , cn_last_update_login                --last_update_login
    , cn_request_id                       --request_id
    , cn_program_application_id           --program_application_id
    , cn_program_id                       --program_id
    , SYSDATE                             --program_update_date
    );
    -- *** 成功件数カウント ***
    gn_normal_cnt := gn_normal_cnt + 1;
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END ins_wholesale_bill_tbl;
--
  /**********************************************************************************
   * Procedure Name   : del_wholesale_bill_details
   * Description      : 明細データ削除(A-6)
   ***********************************************************************************/
  PROCEDURE del_wholesale_bill_details(
    ov_errbuf               OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode              OUT VARCHAR2    --リターン・コード
  , ov_errmsg               OUT VARCHAR2    --ユーザー・エラー・メッセージ
  )
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'del_wholesale_bill_details';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf   VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode  VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg   VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg      VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lb_retcode  BOOLEAN        DEFAULT NULL;               --メッセージ出力の戻り値
    lr_rowid    ROWID;                                     --ROWID
    -- =======================
    -- ローカルカーソル
    -- =======================
-- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama UPD START
--    CURSOR get_xwbl_lock_cur
--    IS
--      SELECT 'X'
--      FROM xxcok_wholesale_bill_line     xwbl
--      WHERE EXISTS ( SELECT 'X'
--                     FROM xxcok_wholesale_bill_head     xwbh
--                        , xxcok_tmp_wholesale_bill      xtwb
--                     WHERE xwbl.wholesale_bill_header_id = xwbh.wholesale_bill_header_id
--                       AND xtwb.cust_code                = xwbh.cust_code
--                       AND xtwb.expect_payment_date      = TO_CHAR( xwbh.expect_payment_date, cv_date_format1 )
--                       AND xtwb.bill_no                  = xwbl.bill_no
---- 2009/08/26 Ver.1.4 [障害0001176] SCS T.Taniguchi START
--                       AND xwbl.status IS NULL
---- 2009/08/26 Ver.1.4 [障害0001176] SCS T.Taniguchi END
--                   )
--      FOR UPDATE OF xwbl.wholesale_bill_detail_id NOWAIT
--    ;
    CURSOR get_xwbl_lock_cur
    IS
      SELECT 'X'
        FROM xxcok_wholesale_bill_line     xwbl
       WHERE xwbl.status IS NULL
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura MOD START
--         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n01) */
         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n02) */
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura MOD END
                             'X'
                        FROM xxcok_wholesale_bill_head     xwbh
                           , xxcok_tmp_wholesale_bill      xtwb
                       WHERE xwbh.cust_code                = xtwb.cust_code
                         AND xwbh.expect_payment_date      = TO_DATE( xtwb.expect_payment_date, cv_date_format1 )
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD START
                         AND xwbh.supplier_code            = xtwb.supplier_code
                         AND xwbh.base_code                = xtwb.base_code
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD END
                         AND xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id
                         AND xtwb.bill_no                  = xwbl.bill_no
                         AND ROWNUM = 1
                    )
      FOR UPDATE OF xwbl.wholesale_bill_detail_id NOWAIT
    ;
-- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama UPD END
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.問屋請求書明細テーブルのロックを取得
    -- =============================================================================
    OPEN  get_xwbl_lock_cur;
    CLOSE get_xwbl_lock_cur;
    -- =============================================================================
    -- 2.問屋請求書明細テーブルの削除処理
    -- =============================================================================
    BEGIN
-- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama UPD START
--      DELETE
--      FROM xxcok_wholesale_bill_line     xwbl
--      WHERE EXISTS ( SELECT 'X'
--                     FROM xxcok_wholesale_bill_head     xwbh
--                        , xxcok_tmp_wholesale_bill      xtwb
--                     WHERE xwbl.wholesale_bill_header_id = xwbh.wholesale_bill_header_id
--                       AND xtwb.cust_code                = xwbh.cust_code
--                       AND xtwb.expect_payment_date      = TO_CHAR( xwbh.expect_payment_date, cv_date_format1 )
--                       AND xtwb.bill_no                  = xwbl.bill_no
---- 2009/08/26 Ver.1.4 [障害0001176] SCS T.Taniguchi START
--                       AND xwbl.status IS NULL
---- 2009/08/26 Ver.1.4 [障害0001176] SCS T.Taniguchi END
--                   )
--      ;
      DELETE FROM xxcok_wholesale_bill_line     xwbl
       WHERE xwbl.status IS NULL
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD START
--         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n01) */
         AND EXISTS ( SELECT /*+ LEADING(xtwb) INDEX(xwbh, xxcok_wholesale_bill_head_n02) */
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD END
                             'X'
                        FROM xxcok_wholesale_bill_head     xwbh
                           , xxcok_tmp_wholesale_bill      xtwb
                       WHERE xwbh.cust_code                = xtwb.cust_code
                         AND xwbh.expect_payment_date      = TO_DATE( xtwb.expect_payment_date, cv_date_format1 )
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD START
                         AND xwbh.supplier_code            = xtwb.supplier_code
                         AND xwbh.base_code                = xtwb.base_code
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD END
                         AND xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id
                         AND xtwb.bill_no                  = xwbl.bill_no
                         AND ROWNUM = 1
                    )
      ;
-- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama UPD END
    EXCEPTION
      -- *** 削除処理に失敗 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10094
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
        ov_retcode := cv_status_error;
    END;
  EXCEPTION
    -- *** ロック失敗 ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10093
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
  END del_wholesale_bill_details;
--
  /**********************************************************************************
   * Procedure Name   : chk_data
   * Description      : 妥当性チェック(A-4)
   ***********************************************************************************/
  PROCEDURE chk_data(
    ov_errbuf              OUT VARCHAR2    --エラー・メッセージ
  , ov_retcode             OUT VARCHAR2    --リターン・コード
  , ov_errmsg              OUT VARCHAR2    --ユーザー・エラー・メッセージ
  , in_loop_cnt            IN  NUMBER      --LOOPカウンタ
  , iv_supplier_code       IN  VARCHAR2    --仕入先コード
  , iv_expect_payment_date IN  VARCHAR2    --支払予定日
  , iv_selling_month       IN  VARCHAR2    --売上対象年月
  , iv_base_code           IN  VARCHAR2    --拠点コード
  , iv_bill_no             IN  VARCHAR2    --請求書No.
  , iv_cust_code           IN  VARCHAR2    --顧客コード
  , iv_sales_outlets_code  IN  VARCHAR2    --問屋帳合先コード
  , iv_item_code           IN  VARCHAR2    --品目コード
  , iv_acct_code           IN  VARCHAR2    --勘定科目コード
  , iv_sub_acct_code       IN  VARCHAR2    --補助科目コード
  , iv_demand_unit_type    IN  VARCHAR2    --請求単位
  , iv_demand_qty          IN  VARCHAR2    --請求数量
  , iv_demand_unit_price   IN  VARCHAR2    --請求単価(税抜)
  , iv_demand_amt          IN  VARCHAR2    --請求金額(税抜)
  , iv_payment_qty         IN  VARCHAR2    --支払数量
  , iv_payment_unit_price  IN  VARCHAR2    --支払単価(税抜)
  , iv_payment_amt         IN  VARCHAR2)   --支払金額(税抜)
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(10) := 'chk_data';     --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf               VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode              VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg               VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg                  VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lv_cust_status          VARCHAR2(2)    DEFAULT NULL;               --顧客ステータス
    lb_retcode              BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    lb_chk_number           BOOLEAN        DEFAULT TRUE;               --半角数字チェックの結果
    ln_chk_number           NUMBER         DEFAULT NULL;               --半角数字チェック用
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
    ld_expect_payment_date  DATE;                                      --支払予定日(日付型変換後)
    ld_selling_month        DATE;                                      --売上対象年月(日付型変換後)
    ln_chr_length           NUMBER         DEFAULT 0;                  --桁数チェック
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura MOD START
--    ln_demand_unit_price    NUMBER(8,2);                               --請求単価(税抜)
--    ln_payment_unit_price   NUMBER(8,2);                               --支払単価(税抜)
    ln_demand_unit_price    xxcok_wholesale_bill_line.demand_unit_price%TYPE;                       --請求単価(税抜)
    ln_payment_unit_price   xxcok_wholesale_bill_line.payment_unit_price%TYPE;                      --支払単価(税抜)
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura MOD END
    ln_count                NUMBER;                                    --COUNT
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
    ln_demand_qty           NUMBER;
    ln_demand_amt           NUMBER;
    ln_payment_qty          NUMBER;
    ln_payment_amt          NUMBER;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 1.必須項目チェック
    -- =============================================================================
        
    IF (    ( iv_base_code          IS NULL )
         OR ( iv_cust_code          IS NULL )
         OR ( iv_supplier_code      IS NULL )
         OR ( iv_bill_no            IS NULL )
         OR ( iv_sales_outlets_code IS NULL )
         OR ( iv_demand_qty         IS NULL )
         OR ( iv_demand_unit_type   IS NULL )
         OR ( iv_demand_unit_price  IS NULL )
         OR ( iv_selling_month      IS NULL )
         OR ( iv_expect_payment_date IS NULL )
       ) THEN
      -- *** 項目がNULLの場合、例外処理 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10161
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi DELETE START
---- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama ADD START
--    ELSIF ( ( iv_demand_qty <> 0
--              OR iv_demand_unit_price <> 0
--            )
--           AND iv_demand_amt IS NULL
--          ) THEN
--      -- *** 項目がNULLの場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10464
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    ELSIF ( iv_acct_code IS NOT NULL
--           AND ( ( iv_payment_qty != 1 AND iv_payment_qty IS NOT NULL )
--              OR iv_demand_qty != 1
--               )
--          ) THEN
--      -- *** 勘定科目支払時に請求数量もしくは支払数量が1以外の場合、例外処理 ***
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_err_msg_10465
--                , iv_token_name1  => cv_token_row_num
--                , iv_token_value1 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
---- 2009/09/30 Ver.1.5 [障害E_T3_00592] SCS S.Moriyama ADD END
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi DELETE END
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
    --==================================================
    -- 条件必須
    --==================================================
    -- 品目コードまたは勘定科目どちらか必須
    IF(    (     ( iv_item_code     IS     NULL )
             AND ( iv_acct_code     IS     NULL )
             AND ( iv_sub_acct_code IS     NULL )
           )
        OR (     ( iv_item_code     IS NOT NULL )
             AND ( iv_acct_code     IS NOT NULL OR iv_sub_acct_code IS NOT NULL )
           )
    ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10466
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    ELSIF(     ( iv_item_code IS NULL )
           AND ( iv_acct_code IS NULL OR iv_sub_acct_code IS NULL )
    ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10467
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
    -- =============================================================================
    -- 2.①請求数量のデータ型チェック(半角数字チェック)
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
    lb_chk_number := xxccp_common_pkg.chk_number(
                       iv_check_char => iv_demand_qty
                     );

    IF ( lb_chk_number = FALSE ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10140
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
*/
    BEGIN
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR START
--      ln_chk_number := TO_NUMBER( iv_demand_qty );
      ln_demand_qty := TO_NUMBER( iv_demand_qty );
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR END
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10140
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
    END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    -- =============================================================================
    -- 2.②請求金額(税抜)のデータ型チェック(半角数字チェック)
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
    lb_chk_number := xxccp_common_pkg.chk_number(
                       iv_check_char => iv_demand_amt
                     );
--
    IF ( lb_chk_number = FALSE ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10142
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
*/
    BEGIN
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR START
--      ln_chk_number := TO_NUMBER( iv_demand_amt );
      ln_demand_amt := TO_NUMBER( iv_demand_amt );
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR END
--
    EXCEPTION
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10142
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
    END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    -- =============================================================================
    -- 2.③支払数量のデータ型チェック(半角数字チェック)(値がNULLの場合チェック対象外)
    -- =============================================================================
    IF ( iv_payment_qty IS NOT NULL ) THEN
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
      lb_chk_number := xxccp_common_pkg.chk_number(
                         iv_check_char => iv_payment_qty
                       );
--
      IF ( lb_chk_number = FALSE ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10143
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
*/
      BEGIN
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR START
--        ln_chk_number := TO_NUMBER( iv_payment_qty );
        ln_payment_qty := TO_NUMBER( iv_payment_qty );
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR END
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10143
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          ov_retcode := cv_status_continue;
      END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
    END IF;
--
    -- ====================================================================================
    -- 2.④支払金額(税抜)のデータ型チェック(半角数字チェック)(値がNULLの場合チェック対象外)
    -- ====================================================================================
-- Start 2009/04/10 Ver_1.3 T1_0493 M.Hiruta
--    IF ( iv_payment_qty IS NOT NULL ) THEN
    IF ( iv_payment_amt IS NOT NULL ) THEN
-- End   2009/04/10 Ver_1.3 T1_0493 M.Hiruta
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
/*
      lb_chk_number := xxccp_common_pkg.chk_number(
                         iv_check_char => iv_payment_amt
                       );
--
      IF ( lb_chk_number = FALSE ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10145
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
*/
      BEGIN
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR START
--        ln_chk_number := TO_NUMBER( iv_payment_amt );
        ln_payment_amt := TO_NUMBER( iv_payment_amt );
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR END
--
      EXCEPTION
        WHEN OTHERS THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10145
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          ov_retcode := cv_status_continue;
      END;
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
    END IF;
--
    -- =============================================================================
    -- 支払予定日の日付型変換チェック
    -- =============================================================================
    BEGIN
      ld_expect_payment_date := TO_DATE( iv_expect_payment_date, cv_date_format1 );
    EXCEPTION
      -- *** 変換できなかった場合、例外処理 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10153
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
    END;
    -- =============================================================================
    -- 売上対象年月の日付型変換チェック
    -- =============================================================================
    BEGIN
      ld_selling_month := TO_DATE( iv_selling_month, cv_date_format2 );
    EXCEPTION
      -- *** 変換できなかった場合、例外処理 ***
      WHEN OTHERS THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10152
                  , iv_token_name1  => cv_token_row_num
                  , iv_token_value1 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
    END;
    -- =============================================================================
    -- 3.①請求書Noの桁数チェック
    -- =============================================================================
    ln_chr_length := LENGTHB( iv_bill_no );
--
    IF ( ln_chr_length > cn_10 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10147
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.②請求数量の桁数チェック
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_demand_qty );
    ln_chr_length := LENGTHB( REPLACE( iv_demand_qty , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_9 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10148
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.③請求単価(税抜)の桁数チェック
    -- =============================================================================
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD START
    IF ( iv_acct_code IS NOT NULL ) AND ( iv_sub_acct_code IS NOT NULL ) THEN
      BEGIN
        ln_demand_unit_price := TO_NUMBER( iv_demand_unit_price , cv_number_format1 );
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10470
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          ov_retcode := cv_status_continue;
      END;
    ELSE
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD END
      BEGIN
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Yamaguchi REPAIR START
--        ln_demand_unit_price := TO_NUMBER( iv_demand_unit_price );
        ln_demand_unit_price := TO_NUMBER( iv_demand_unit_price, cv_number_format2 );
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Yamaguchi REPAIR END
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10149
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          ov_retcode := cv_status_continue;
      END;
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD START
    END IF;
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD END
    -- =============================================================================
    -- 3.④請求金額(税抜)の桁数チェック
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_demand_amt );
    ln_chr_length := LENGTHB( REPLACE( iv_demand_amt , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_10 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10150
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.⑤請求単位の桁数チェック
    -- =============================================================================
    ln_chr_length := LENGTHB( iv_demand_unit_type );
--
    IF NOT ( ln_chr_length = cn_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10151
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.⑥支払数量の桁数チェック
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_payment_qty );
    ln_chr_length := LENGTHB( REPLACE( iv_payment_qty , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_9 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10154
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 3.⑦支払単価(税抜)の桁数チェック
    -- =============================================================================
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD START
    IF ( iv_acct_code IS NOT NULL ) AND ( iv_sub_acct_code IS NOT NULL ) THEN
      BEGIN
        ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price , cv_number_format1 );
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10471
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          ov_retcode := cv_status_continue;
      END;
    ELSE
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD END
      BEGIN
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Yamaguchi REPAIR START
--        ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price );
        ln_payment_unit_price := TO_NUMBER( iv_payment_unit_price, cv_number_format2 );
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Yamaguchi REPAIR END
      EXCEPTION
        WHEN VALUE_ERROR THEN
          lv_msg := xxccp_common_pkg.get_msg(
                      iv_application  => cv_xxcok_appl_name
                    , iv_name         => cv_err_msg_10155
                    , iv_token_name1  => cv_token_row_num
                    , iv_token_value1 => TO_CHAR( in_loop_cnt )
                    );
          lb_retcode := xxcok_common_pkg.put_message_f(
                          in_which    => FND_FILE.OUTPUT   --出力区分
                        , iv_message  => lv_msg            --メッセージ
                        , in_new_line => 0                 --改行
                        );
          ov_retcode := cv_status_continue;
      END;
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD START
    END IF;
-- 2009/12/25 Ver.1.8 [E_本稼動_00608] SCS K.Nakamura ADD END
    -- =============================================================================
    -- 3.⑧支払金額(税抜)の桁数チェック
    -- =============================================================================
-- Start 2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--    ln_chr_length := LENGTHB( iv_payment_amt );
    ln_chr_length := LENGTHB( REPLACE( iv_payment_amt , cv_minus ) );
-- End   2009/04/10 Ver_1.3 T1_0400 M.Hiruta
--
    IF ( ln_chr_length > cn_10 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10156
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 4.仕入先コードが仕入先マスタに存在することをチェック
    -- =============================================================================
    SELECT  COUNT('X') AS cnt
    INTO    ln_count
    FROM    po_vendors          pv     --仕入先マスタ
          , po_vendor_sites_all pvsa   --仕入先サイトマスタ
    WHERE   pv.segment1  = iv_supplier_code
    AND     pv.vendor_id = pvsa.vendor_id
    AND     (   ( pv.end_date_active > gd_prdate )
             OR ( pv.end_date_active IS NULL     )
            )
    AND     (   ( pvsa.inactive_date > gd_prdate )
             OR ( pvsa.inactive_date IS NULL     )
            )
    AND     pvsa.org_id  = gn_org_id
    AND     ROWNUM       = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10162
                , iv_token_name1  => cv_token_vendor_code
                , iv_token_value1 => iv_supplier_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 5.拠点コードが顧客マスタに存在することをチェック
    -- =============================================================================
    SELECT  COUNT('X') AS cnt
    INTO    ln_count
    FROM    hz_cust_accounts hca
    WHERE   hca.account_number      = iv_base_code
    AND     hca.customer_class_code = cv_base_code
    AND     ROWNUM                  = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10163
                , iv_token_name1  => cv_token_kyoten_code
                , iv_token_value1 => iv_base_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    ELSE
      IF (    ( gv_dept_code      <> gv_user_dept_code )
          AND ( gv_user_dept_code <> iv_base_code )
         ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10382
                  , iv_token_name1  => cv_token_kyoten_code
                  , iv_token_value1 => iv_base_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
      -- =============================================================================
      -- 顧客ステータスを取得し、「90(中止決裁済)」の場合エラー
      -- =============================================================================
      SELECT hp.duns_number_c
      INTO   lv_cust_status
      FROM   hz_cust_accounts hca
           , hz_parties hp
      WHERE  hca.party_id            = hp.party_id
      AND    hca.account_number      = iv_base_code
      AND    hca.customer_class_code = cv_base_code
      AND    ROWNUM                  = cn_1;
      IF ( lv_cust_status = cv_cust_status_90 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10388
                  , iv_token_name1  => cv_token_kyoten_code
                  , iv_token_value1 => iv_base_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi DELETE START
--    -- =============================================================================
--    -- 顧客ステータスを取得し、「90(中止決裁済)」の場合エラー
--    -- =============================================================================
--    SELECT hp.duns_number_c
--    INTO   lv_cust_status
--    FROM   hz_cust_accounts hca
--         , hz_parties hp
--    WHERE  hca.party_id            = hp.party_id
--    AND    hca.account_number      = iv_base_code
--    AND    hca.customer_class_code = cv_base_code
--    AND    ROWNUM                  = cn_1;
----
--    IF ( lv_cust_status = cv_cust_status_90 ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_message_10388
--                , iv_token_name1  => cv_token_kyoten_code
--                , iv_token_value1 => iv_base_code
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi DELETE END
    -- =============================================================================
    -- 6.顧客コードが顧客マスタに存在することをチェック
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   hz_cust_accounts hca
         , xxcmm_cust_accounts xca
    WHERE  hca.cust_account_id   = xca.customer_id
    AND    hca.account_number    = iv_cust_code
    AND    xca.business_low_type = cv_sales_wholesale
    AND    ROWNUM                = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10164
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => iv_cust_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
    ELSE
      -- =============================================================================
      -- 顧客ステータスを取得し、「80(更正債権)」または「90(中止決裁済)」の場合エラー
      -- =============================================================================
      SELECT hp.duns_number_c
      INTO   lv_cust_status
      FROM   hz_cust_accounts hca
           , hz_parties hp
           , xxcmm_cust_accounts xca
      WHERE  hca.cust_account_id   = xca.customer_id
      AND    hca.party_id          = hp.party_id
      AND    hca.account_number    = iv_cust_code
      AND    xca.business_low_type = cv_sales_wholesale
      AND    ROWNUM                = cn_1;
      IF (   ( lv_cust_status = cv_cust_status_80 )
          OR ( lv_cust_status = cv_cust_status_90 )
          ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_message_10389
                  , iv_token_name1  => cv_token_customer_code
                  , iv_token_value1 => iv_cust_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi DELETE START
--    -- =============================================================================
--    -- 顧客ステータスを取得し、「80(更正債権)」または「90(中止決裁済)」の場合エラー
--    -- =============================================================================
--    SELECT hp.duns_number_c
--    INTO   lv_cust_status
--    FROM   hz_cust_accounts hca
--         , hz_parties hp
--         , xxcmm_cust_accounts xca
--    WHERE  hca.cust_account_id   = xca.customer_id
--    AND    hca.party_id          = hp.party_id
--    AND    hca.account_number    = iv_cust_code
--    AND    xca.business_low_type = cv_sales_wholesale
--    AND    ROWNUM                = cn_1;
----
--    IF (   ( lv_cust_status = cv_cust_status_80 )
--        OR ( lv_cust_status = cv_cust_status_90 )
--        ) THEN
--      lv_msg := xxccp_common_pkg.get_msg(
--                  iv_application  => cv_xxcok_appl_name
--                , iv_name         => cv_message_10389
--                , iv_token_name1  => cv_token_customer_code
--                , iv_token_value1 => iv_cust_code
--                , iv_token_name2  => cv_token_row_num
--                , iv_token_value2 => TO_CHAR( in_loop_cnt )
--                );
--      lb_retcode := xxcok_common_pkg.put_message_f(
--                      in_which    => FND_FILE.OUTPUT   --出力区分
--                    , iv_message  => lv_msg            --メッセージ
--                    , in_new_line => 0                 --改行
--                    );
--      ov_retcode := cv_status_continue;
--    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi DELETE END
    -- =============================================================================
    -- 7.問屋帳合先コードが顧客マスタに存在することをチェック
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   hz_cust_accounts hca
    WHERE  hca.account_number      = iv_sales_outlets_code
    AND    hca.customer_class_code = cv_sales_outlets
    AND    ROWNUM                  = cn_1;
--
    IF ( ln_count = cn_0 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10165
                , iv_token_name1  => cv_token_tonya_code
                , iv_token_value1 => iv_sales_outlets_code
                , iv_token_name2  => cv_token_row_num
                , iv_token_value2 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 8.品目コードがNULL以外の場合、品目マスタに存在することをチェック
    -- =============================================================================
    IF ( iv_item_code IS NOT NULL ) THEN
      SELECT COUNT('X') AS cnt
      INTO   ln_count
      FROM   mtl_system_items_b mti
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
           , mtl_parameters     mp
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
      WHERE  mti.segment1 = iv_item_code
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
      AND    mti.organization_id  = mp.organization_id
      AND    mp.organization_code = gv_organization_code
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
      AND    ROWNUM       = cn_1;
--
      IF ( ln_count = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10166
                  , iv_token_name1  => cv_token_item_code
                  , iv_token_value1 => iv_item_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
    END IF;
    -- =============================================================================
    -- 9.勘定科目コードがNULL以外の場合、AFF勘定科目に存在することをチェック
    -- =============================================================================
    IF ( iv_acct_code IS NOT NULL ) THEN
      SELECT COUNT('X') AS cnt
      INTO   ln_count
      FROM   xx03_accounts_v xav
      WHERE  xav.flex_value = iv_acct_code
      AND    ROWNUM         = cn_1;
--
      IF ( ln_count = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10167
                  , iv_token_name1  => cv_token_account_code
                  , iv_token_value1 => iv_acct_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
    END IF;
    -- =============================================================================
    -- 10.補助科目コードがNULL以外の場合、AFF補助科目に存在することをチェック
    -- =============================================================================
    IF ( iv_sub_acct_code IS NOT NULL ) THEN
      SELECT COUNT('X') AS cnt
      INTO   ln_count
      FROM   xx03_sub_accounts_v xsav
      WHERE  xsav.flex_value             = iv_sub_acct_code
      AND    xsav.parent_flex_value_low  = iv_acct_code
      AND    ROWNUM = cn_1;
--
      IF ( ln_count = cn_0 ) THEN
        lv_msg := xxccp_common_pkg.get_msg(
                    iv_application  => cv_xxcok_appl_name
                  , iv_name         => cv_err_msg_10168
                  , iv_token_name1  => cv_token_sub_code
                  , iv_token_value1 => iv_sub_acct_code
                  , iv_token_name2  => cv_token_row_num
                  , iv_token_value2 => TO_CHAR( in_loop_cnt )
                  );
        lb_retcode := xxcok_common_pkg.put_message_f(
                        in_which    => FND_FILE.OUTPUT   --出力区分
                      , iv_message  => lv_msg            --メッセージ
                      , in_new_line => 0                 --改行
                      );
        ov_retcode := cv_status_continue;
      END IF;
    END IF;
    -- =============================================================================
    -- 11.支払予定日が同一顧客、同一請求書No.内で同じ日付であることをチェック
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   xxcok_tmp_wholesale_bill xtwb
    WHERE  xtwb.cust_code           =  iv_cust_code
    AND    xtwb.bill_no             =  iv_bill_no
    AND    xtwb.expect_payment_date <> iv_expect_payment_date
    AND    ROWNUM                   =  cn_1;
--
    IF ( ln_count = cn_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10169
                , iv_token_name1  => cv_token_payment_date
                , iv_token_value1 => iv_expect_payment_date
                , iv_token_name2  => cv_token_customer_code
                , iv_token_value2 => iv_cust_code
                , iv_token_name3  => cv_token_invoice_no
                , iv_token_value3 => iv_bill_no
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
    -- =============================================================================
    -- 12.支払数量・支払単価・支払金額のチェック
    -- =============================================================================
    IF NOT ( (    ( iv_payment_qty        IS NOT NULL )
              AND ( iv_payment_unit_price IS NOT NULL )
              AND ( iv_payment_amt        IS NOT NULL )
             )
           OR 
             (    ( iv_payment_qty        IS NULL )
              AND ( iv_payment_unit_price IS NULL )
              AND ( iv_payment_amt        IS NULL )
             )
           ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_message_10385
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
    IF (     ( ln_demand_qty <> 0 OR ln_demand_unit_price <> 0 )
         AND ( ln_demand_amt IS NULL )
    ) THEN
      -- *** 項目がNULLの場合、例外処理 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10464
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    ELSIF ( iv_acct_code IS NOT NULL
           AND ( ( ln_payment_qty != 1 AND ln_payment_qty IS NOT NULL )
              OR ln_demand_qty != 1
               )
    ) THEN
      -- *** 勘定科目支払時に請求数量もしくは支払数量が1以外の場合、例外処理 ***
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10465
                , iv_token_name1  => cv_token_row_num
                , iv_token_value1 => TO_CHAR( in_loop_cnt )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
    -- =============================================================================
    -- 問屋請求書テーブルデータチェック(A-5)
    -- 問屋請求書ヘッダーテーブル、問屋請求書明細テーブルの既存データチェックを行う
    -- =============================================================================
    SELECT COUNT('X') AS cnt
    INTO   ln_count
    FROM   xxcok_wholesale_bill_head xwbh
         , xxcok_wholesale_bill_line xwbl
    WHERE  xwbh.cust_code                = iv_cust_code
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR START
--    AND    xwbh.expect_payment_date      = TO_DATE( iv_expect_payment_date, cv_date_format1 )
    AND    xwbh.expect_payment_date      = ld_expect_payment_date
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi REPAIR END
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD START
    AND    xwbh.supplier_code            = iv_supplier_code
    AND    xwbh.base_code                = iv_base_code
-- 2009/12/24 Ver.1.7 [E_本稼動_00554] SCS K.Nakamura ADD END
    AND    xwbl.bill_no                  = iv_bill_no
    AND    xwbl.status IN( cv_status_a,  cv_status_i,  cv_status_p )
    AND    xwbh.wholesale_bill_header_id = xwbl.wholesale_bill_header_id
    AND    ROWNUM                        = cn_1 ;
    -- *** 該当データが存在する場合、例外処理 ***
    IF ( ln_count = cn_1 ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_10092
                , iv_token_name1  => cv_token_customer_code
                , iv_token_value1 => iv_cust_code
                , iv_token_name2  => cv_token_invoice_no
                , iv_token_value2 => iv_bill_no
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT    --出力区分
                    , iv_message  => lv_msg             --メッセージ
                    , in_new_line => 0                  --改行
                    );
      ov_retcode := cv_status_continue;
    END IF;
  EXCEPTION
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
   * Procedure Name   : get_tmp_wholesale_bill
   * Description      : 問屋請求書Excelアップロードワークテーブルデータ取得(A-3)
   ***********************************************************************************/
  PROCEDURE get_tmp_wholesale_bill(
    ov_errbuf   OUT VARCHAR2     --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2     --リターン・コード
  , ov_errmsg   OUT VARCHAR2     --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)      --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(30) := 'get_tmp_wholesale_bill';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lb_retcode   BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
    -- =======================
    -- ローカル･カーソル
    -- =======================
    CURSOR get_wk_tab_cur
    IS
      SELECT   xtwb.supplier_code       AS supplier_code
             , xtwb.expect_payment_date AS expect_payment_date
             , xtwb.selling_month       AS selling_month
             , xtwb.base_code           AS base_code
             , xtwb.bill_no             AS bill_no
             , xtwb.cust_code           AS cust_code
             , xtwb.sales_outlets_code  AS sales_outlets_code
             , xtwb.item_code           AS item_code
             , xtwb.acct_code           AS acct_code
             , xtwb.sub_acct_code       AS sub_acct_code
             , xtwb.demand_unit_type    AS demand_unit_type
             , xtwb.demand_qty          AS demand_qty
             , xtwb.demand_unit_price   AS demand_unit_price
             , xtwb.demand_amt          AS demand_amt
             , xtwb.payment_qty         AS payment_qty
             , xtwb.payment_unit_price  AS payment_unit_price
             , xtwb.payment_amt         AS payment_amt
      FROM     xxcok_tmp_wholesale_bill xtwb
      WHERE    xtwb.file_id = in_file_id
      ORDER BY xtwb.sort_no;
    -- =======================
    -- ローカルTABLE型変数
    -- =======================
    TYPE l_tab_ttype IS TABLE OF get_wk_tab_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    l_get_tmp_cur_tab  l_tab_ttype;
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 明細データ削除(A-6)呼出し
    -- =============================================================================
    del_wholesale_bill_details(
      ov_errbuf              => lv_errbuf                                         --エラー・メッセージ
    , ov_retcode             => lv_retcode                                        --リターン・コード
    , ov_errmsg              => lv_errmsg                                         --ユーザー・エラー・メッセージ
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- *** カーソルオープン ***
    OPEN  get_wk_tab_cur;
    FETCH get_wk_tab_cur BULK COLLECT INTO l_get_tmp_cur_tab;
    CLOSE get_wk_tab_cur;
    -- 対象件数を格納
    gn_target_cnt := l_get_tmp_cur_tab.COUNT;
--
    <<loop_1>>
    FOR ln_idx IN 1 .. l_get_tmp_cur_tab.COUNT LOOP
      -- =============================================================================
      -- 妥当性チェック(A-4)呼出し
      -- =============================================================================
      chk_data(
        ov_errbuf              => lv_errbuf                                         --エラー・メッセージ
      , ov_retcode             => lv_retcode                                        --リターン・コード
      , ov_errmsg              => lv_errmsg                                         --ユーザー・エラー・メッセージ
      , in_loop_cnt            => ln_idx                                            --LOOPカウンタ
      , iv_supplier_code       => l_get_tmp_cur_tab( ln_idx ).supplier_code         --仕入先コード
      , iv_expect_payment_date => l_get_tmp_cur_tab( ln_idx ).expect_payment_date   --支払予定日
      , iv_selling_month       => l_get_tmp_cur_tab( ln_idx ).selling_month         --売上対象年月
      , iv_base_code           => l_get_tmp_cur_tab( ln_idx ).base_code             --拠点コード
      , iv_bill_no             => l_get_tmp_cur_tab( ln_idx ).bill_no               --請求書No.
      , iv_cust_code           => l_get_tmp_cur_tab( ln_idx ).cust_code             --顧客コード
      , iv_sales_outlets_code  => l_get_tmp_cur_tab( ln_idx ).sales_outlets_code    --問屋帳合先コード
      , iv_item_code           => l_get_tmp_cur_tab( ln_idx ).item_code             --品目コード
      , iv_acct_code           => l_get_tmp_cur_tab( ln_idx ).acct_code             --勘定科目コード
      , iv_sub_acct_code       => l_get_tmp_cur_tab( ln_idx ).sub_acct_code         --補助科目コード
      , iv_demand_unit_type    => l_get_tmp_cur_tab( ln_idx ).demand_unit_type      --請求単位
      , iv_demand_qty          => l_get_tmp_cur_tab( ln_idx ).demand_qty            --請求数量
      , iv_demand_unit_price   => l_get_tmp_cur_tab( ln_idx ).demand_unit_price     --請求単価(税抜)
      , iv_demand_amt          => l_get_tmp_cur_tab( ln_idx ).demand_amt            --請求金額(税抜)
      , iv_payment_qty         => l_get_tmp_cur_tab( ln_idx ).payment_qty           --支払数量
      , iv_payment_unit_price  => l_get_tmp_cur_tab( ln_idx ).payment_unit_price    --支払単価(税抜)
      , iv_payment_amt         => l_get_tmp_cur_tab( ln_idx ).payment_amt           --支払金額(税抜)
      );
--
      IF ( lv_retcode = cv_status_continue ) THEN
        gv_chk_code  := lv_retcode;
        ov_retcode   := lv_retcode;
        gn_error_cnt := gn_error_cnt + 1;
      ELSIF ( lv_retcode = cv_status_error ) THEN
        RAISE global_process_expt;
      END IF;
      -- =============================================================================
      -- 妥当性チェックでエラーが発生していなければA-6、A-7を実行
      -- =============================================================================
      IF NOT ( gv_chk_code = cv_status_continue ) THEN
        -- =============================================================================
        -- 問屋請求書テーブルデータ登録(A-7)呼出し
        -- =============================================================================
        ins_wholesale_bill_tbl(
          ov_errbuf              => lv_errbuf                                         --エラー・メッセージ
        , ov_retcode             => lv_retcode                                        --リターン・コード
        , ov_errmsg              => lv_errmsg                                         --ユーザー・エラー・メッセージ
        , iv_supplier_code       => l_get_tmp_cur_tab( ln_idx ).supplier_code         --仕入先コード
        , iv_expect_payment_date => l_get_tmp_cur_tab( ln_idx ).expect_payment_date   --支払予定日
        , iv_selling_month       => l_get_tmp_cur_tab( ln_idx ).selling_month         --売上対象年月
        , iv_base_code           => l_get_tmp_cur_tab( ln_idx ).base_code             --拠点コード
        , iv_bill_no             => l_get_tmp_cur_tab( ln_idx ).bill_no               --請求書No.
        , iv_cust_code           => l_get_tmp_cur_tab( ln_idx ).cust_code             --顧客コード
        , iv_sales_outlets_code  => l_get_tmp_cur_tab( ln_idx ).sales_outlets_code    --問屋帳合先コード
        , iv_item_code           => l_get_tmp_cur_tab( ln_idx ).item_code             --品目コード
        , iv_acct_code           => l_get_tmp_cur_tab( ln_idx ).acct_code             --勘定科目コード
        , iv_sub_acct_code       => l_get_tmp_cur_tab( ln_idx ).sub_acct_code         --補助科目コード
        , iv_demand_unit_type    => l_get_tmp_cur_tab( ln_idx ).demand_unit_type      --請求単位
        , iv_demand_qty          => l_get_tmp_cur_tab( ln_idx ).demand_qty            --請求数量
        , iv_demand_unit_price   => l_get_tmp_cur_tab( ln_idx ).demand_unit_price     --請求単価(税抜)
        , iv_demand_amt          => l_get_tmp_cur_tab( ln_idx ).demand_amt            --請求金額(税抜)
        , iv_payment_qty         => l_get_tmp_cur_tab( ln_idx ).payment_qty           --支払数量
        , iv_payment_unit_price  => l_get_tmp_cur_tab( ln_idx ).payment_unit_price    --支払単価(税抜)
        , iv_payment_amt         => l_get_tmp_cur_tab( ln_idx ).payment_amt           --支払金額(税抜)
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
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || SQLERRM, 1, 5000 );
      ov_retcode := cv_status_error;
  END get_tmp_wholesale_bill;
--
  /**********************************************************************************
   * Procedure Name   : get_file_data
   * Description      : ファイルデータ取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_file_data(
    ov_errbuf   OUT VARCHAR2     --エラー・メッセージ
  , ov_retcode  OUT VARCHAR2     --リターン・コード
  , ov_errmsg   OUT VARCHAR2     --ユーザー・エラー・メッセージ
  , in_file_id  IN  NUMBER)      --ファイルID
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(15) := 'get_file_data';   --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf               VARCHAR2(5000)  DEFAULT NULL;               --エラー・メッセージ
    lv_retcode              VARCHAR2(1)     DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg               VARCHAR2(5000)  DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg                  VARCHAR2(5000)  DEFAULT NULL;               --メッセージ取得変数
    lv_file_name            VARCHAR2(256)   DEFAULT NULL;               --ファイル名
    lv_supplier_code        VARCHAR2(100)   DEFAULT NULL;               --仕入先コード
    lv_expect_payment_date  VARCHAR2(100)   DEFAULT NULL;               --支払予定日
    lv_selling_month        VARCHAR2(100)   DEFAULT NULL;               --売上対象年月
    lv_base_code            VARCHAR2(100)   DEFAULT NULL;               --拠点コード
    lv_bill_no              VARCHAR2(100)   DEFAULT NULL;               --請求書No.
    lv_cust_code            VARCHAR2(100)   DEFAULT NULL;               --顧客コード
    lv_sales_outlets_code   VARCHAR2(100)   DEFAULT NULL;               --問屋帳合先コード
    lv_item_code            VARCHAR2(100)   DEFAULT NULL;               --品目コード
    lv_acct_code            VARCHAR2(100)   DEFAULT NULL;               --勘定科目コード
    lv_sub_acct_code        VARCHAR2(100)   DEFAULT NULL;               --補助科目コード
    lv_demand_unit_type     VARCHAR2(100)   DEFAULT NULL;               --請求単位
    lv_demand_qty           VARCHAR2(100)   DEFAULT NULL;               --請求数量
    lv_demand_unit_price    VARCHAR2(100)   DEFAULT NULL;               --請求単価(税抜)
    lv_demand_amt           VARCHAR2(100)   DEFAULT NULL;               --請求金額(税抜)
    lv_payment_qty          VARCHAR2(100)   DEFAULT NULL;               --支払数量
    lv_payment_unit_price   VARCHAR2(100)   DEFAULT NULL;               --支払単価(税抜)
    lv_payment_amt          VARCHAR2(100)   DEFAULT NULL;               --支払金額(税抜)
    lv_line                 VARCHAR2(32767) DEFAULT NULL;               --1行のデータ
    lb_retcode              BOOLEAN         DEFAULT TRUE;               --メッセージ出力の戻り値
    ln_col                  NUMBER          DEFAULT 0;                  --カラム
    ln_loop_cnt             NUMBER          DEFAULT 0;                  --LOOPカウンタ
    ln_csv_col_cnt          NUMBER;                                     --CSV項目数
    -- =======================
    -- ローカルTABLE型変数
    -- =======================
    l_file_data_tab   xxccp_common_pkg2.g_file_data_tbl;   --行テーブル格納領域
    l_split_csv_tab   xxcok_common_pkg.g_split_csv_tbl;    --CSV分割データ格納領域
    -- =======================
    -- ローカルカーソル
    -- =======================
    -- =============================================================================
    -- 1.ファイルアップロードIF表のデータ・ロックを取得
    -- =============================================================================
    CURSOR xmfui_cur
    IS
      SELECT xmfui.file_name AS file_name
      FROM   xxccp_mrp_file_ul_interface xmfui
      WHERE  xmfui.file_id = in_file_id
      FOR UPDATE OF xmfui.file_id NOWAIT;
    -- =======================
    -- ローカルレコード
    -- =======================
    xmfui_rec  xmfui_cur%ROWTYPE;
    -- =======================
    -- ローカル例外
    -- =======================
    blob_expt  EXCEPTION;   --BLOBデータ変換エラー
    file_expt  EXCEPTION;   --空ファイルエラー
--
  BEGIN
    ov_retcode := cv_status_normal;
--
    OPEN  xmfui_cur;
      FETCH xmfui_cur INTO xmfui_rec;
      lv_file_name := xmfui_rec.file_name;
    CLOSE xmfui_cur;
    -- =============================================================================
    -- 2.ファイル名メッセージ出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxcok_appl_name
              , iv_name         => cv_message_00006
              , iv_token_name1  => cv_token_file_name
              , iv_token_value1 => lv_file_name
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 1                 --改行
                  );
    -- =============================================================================
    -- 4.BLOBデータ変換
    -- =============================================================================
    xxccp_common_pkg2.blob_to_varchar2(
      ov_errbuf    => lv_errbuf
    , ov_retcode   => lv_retcode
    , ov_errmsg    => lv_errmsg
    , in_file_id   => in_file_id
    , ov_file_data => l_file_data_tab
    );
    -- *** リターンコードが0(正常)以外の場合、例外処理 ***
    IF NOT ( lv_retcode = cv_status_normal ) THEN
      RAISE blob_expt;
    END IF;
    -- =============================================================================
    -- 5.取得したデータ件数をチェック(件数が1件以下の場合、例外処理)
    -- =============================================================================
    IF ( l_file_data_tab.COUNT <= cn_1 ) THEN
      RAISE file_expt;
    END IF;
    -- =============================================================================
    -- 6.文字列を分割
    -- =============================================================================
    <<main_loop>>
    FOR ln_index IN 2 .. l_file_data_tab.COUNT LOOP
      --LOOPカウンタ
      ln_loop_cnt := ln_loop_cnt + 1;
      --1行毎のデータを格納
      lv_line := l_file_data_tab( ln_index );
      -- =============================================================================
      -- 変数の初期化
      -- =============================================================================
      l_split_csv_tab.delete;
--
      lv_supplier_code       := NULL;
      lv_expect_payment_date := NULL;
      lv_selling_month       := NULL;
      lv_base_code           := NULL;
      lv_bill_no             := NULL;
      lv_cust_code           := NULL;
      lv_sales_outlets_code  := NULL;
      lv_item_code           := NULL;
      lv_acct_code           := NULL;
      lv_sub_acct_code       := NULL;
      lv_demand_unit_type    := NULL;
      lv_demand_qty          := NULL;
      lv_demand_unit_price   := NULL;
      lv_demand_amt          := NULL;
      lv_payment_qty         := NULL;
      lv_payment_unit_price  := NULL;
      lv_payment_amt         := NULL;
      -- =============================================================================
      -- CSV文字列分割
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
        --項目1(仕入先コード)
        IF ( ln_cnt = 1 ) THEN
           lv_supplier_code := l_split_csv_tab( ln_cnt );
        --項目2(支払予定日)
        ELSIF ( ln_cnt = 2 ) THEN
          lv_expect_payment_date := l_split_csv_tab( ln_cnt );
        --項目3(売上対象年月)
        ELSIF ( ln_cnt = 3 ) THEN
          lv_selling_month := l_split_csv_tab( ln_cnt );
        --項目4(拠点コード)
        ELSIF ( ln_cnt = 4 ) THEN
          lv_base_code := l_split_csv_tab( ln_cnt );
        --項目5(請求書No.)
        ELSIF ( ln_cnt = 5 ) THEN
          lv_bill_no := l_split_csv_tab( ln_cnt );
        --項目6(顧客コード)
        ELSIF ( ln_cnt = 6 ) THEN
          lv_cust_code := l_split_csv_tab( ln_cnt );
        --項目7(問屋帳合先コード)
        ELSIF ( ln_cnt = 7 ) THEN
          lv_sales_outlets_code := l_split_csv_tab( ln_cnt );
        --項目8(品目コード)
        ELSIF ( ln_cnt = 8 ) THEN
          lv_item_code := l_split_csv_tab( ln_cnt );
        --項目9(勘定科目コード)
        ELSIF ( ln_cnt = 9 ) THEN
          lv_acct_code := l_split_csv_tab( ln_cnt );
        --項目10(補助科目コード)
        ELSIF ( ln_cnt = 10 ) THEN
          lv_sub_acct_code := l_split_csv_tab( ln_cnt );
        --項目11(請求単位)
        ELSIF ( ln_cnt = 11 ) THEN
          lv_demand_unit_type := l_split_csv_tab( ln_cnt );
        --項目12(請求数量)
        ELSIF ( ln_cnt = 12 ) THEN
          lv_demand_qty := l_split_csv_tab( ln_cnt );
        --項目13(請求単価(税抜))
        ELSIF ( ln_cnt = 13 ) THEN
          lv_demand_unit_price := l_split_csv_tab( ln_cnt );
        --項目14(請求金額(税抜))
        ELSIF ( ln_cnt = 14 ) THEN
          lv_demand_amt := l_split_csv_tab( ln_cnt );
        --項目15(支払数量)
        ELSIF ( ln_cnt = 15 ) THEN
          lv_payment_qty := l_split_csv_tab( ln_cnt );
        --項目16(支払単価(税抜))
        ELSIF ( ln_cnt = 16 ) THEN
          lv_payment_unit_price := l_split_csv_tab( ln_cnt );
        --項目17(支払金額(税抜))
        ELSIF ( ln_cnt = 17 ) THEN
          lv_payment_amt := l_split_csv_tab( ln_cnt );
        END IF;
      END LOOP comma_loop;
      -- =============================================================================
      -- 7.問屋請求書Excelアップロードワークテーブルへ取り込む
      -- =============================================================================
      INSERT INTO xxcok_tmp_wholesale_bill(
        sort_no                   --ソートNo(LOOPカウンタ)
      , file_id                   --ファイルID
      , supplier_code             --仕入先コード
      , expect_payment_date       --支払予定日
      , selling_month             --売上対象年月
      , base_code                 --拠点コード
      , bill_no                   --請求書No.
      , cust_code                 --顧客コード
      , sales_outlets_code        --問屋帳合先コード
      , item_code                 --品目コード
      , acct_code                 --勘定科目コード
      , sub_acct_code             --補助科目コード
      , demand_unit_type          --請求単位
      , demand_qty                --請求数量
      , demand_unit_price         --請求単価(税抜)
      , demand_amt                --請求金額(税抜)
      , payment_qty               --支払数量
      , payment_unit_price        --支払単価(税抜)
      , payment_amt               --支払金額(税抜)
      ) VALUES (
        ln_loop_cnt               --sort_no
      , in_file_id                --file_id
      , lv_supplier_code          --supplier_code
      , lv_expect_payment_date    --expect_payment_date
      , lv_selling_month          --selling_month
      , lv_base_code              --base_code
      , lv_bill_no                --bill_no
      , lv_cust_code              --cust_code
      , lv_sales_outlets_code     --sales_outlets_code
      , lv_item_code              --item_code
      , lv_acct_code              --acct_code
      , lv_sub_acct_code          --sub_acct_code
      , lv_demand_unit_type       --demand_unit_type
      , lv_demand_qty             --demand_qty
      , lv_demand_unit_price      --demand_unit_price
      , lv_demand_amt             --demand_amt
      , lv_payment_qty            --payment_qty
      , lv_payment_unit_price     --payment_unit_price
      , lv_payment_amt            --payment_amt
      );
    END LOOP main_loop;
  EXCEPTION
    -- *** ロック失敗 ***
    WHEN global_lock_fail THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00061
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** BLOBデータ変換エラー ***
    WHEN blob_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00041
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 空ファイルエラー ***
    WHEN file_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00039
                , iv_token_name1  => cv_token_file_id
                , iv_token_value1 => TO_CHAR( in_file_id )
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
  END get_file_data;
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
    cv_prg_name   CONSTANT VARCHAR2(5) := 'init';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf       VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode      VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg       VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg          VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lv_emp_code     VARCHAR2(5)    DEFAULT NULL;               --従業員コード取得変数
    lv_profile_code VARCHAR2(100)  DEFAULT NULL;               --プロファイル値
    lb_retcode      BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
    -- =======================
    -- ローカル例外
    -- =======================
    get_profile_expt EXCEPTION;   --カスタム･プロファイル取得エラー
    get_process_expt EXCEPTION;   --業務処理日付取得エラー
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
              , iv_token_value1 => TO_CHAR( in_file_id )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 0                 --改行
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
              , iv_token_value1 => TO_CHAR( iv_format_pattern )
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT   --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 1                 --改行
                  );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.LOG      --出力区分
                  , iv_message  => lv_msg            --メッセージ
                  , in_new_line => 2                 --改行
                  );
    -- =============================================================================
    -- 2.(1)プロファイルを取得(業務管理部の部門コード)
    -- =============================================================================
    gv_dept_code := FND_PROFILE.VALUE( cv_dept_code_p );
--
    IF ( gv_dept_code IS NULL ) THEN
      lv_profile_code := cv_dept_code_p;
      RAISE get_profile_expt;
    END IF;
    -- =============================================================================
    -- 2.(2)プロファイルを取得(営業単位ID)
    -- =============================================================================
    gn_org_id := TO_NUMBER ( FND_PROFILE.VALUE( cv_org_id_p ) );
--
    IF ( gn_org_id IS NULL ) THEN
      lv_profile_code := cv_org_id_p;
      RAISE get_profile_expt;
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD START
    --==================================================
    -- 在庫組織
    --==================================================
    gv_organization_code  := FND_PROFILE.VALUE( cv_organization_code );
    IF ( gv_organization_code IS NULL ) THEN
      lv_profile_code := cv_organization_code;
      RAISE get_profile_expt;
    END IF;
-- 2009/12/18 Ver.1.6 [E_本稼動_00539] SCS K.Yamaguchi ADD END
    -- =============================================================================
    -- 3.ユーザの所属部門を取得
    -- =============================================================================
    gv_user_dept_code := xxcok_common_pkg.get_department_code_f(
                           in_user_id => cn_created_by
                         );
--
    IF ( gv_user_dept_code IS NULL ) THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00030
                , iv_token_name1  => cv_token_user_id
                , iv_token_value1 => cn_created_by
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    END IF;
    -- =============================================================================
    -- 4.業務処理日付取得
    -- =============================================================================
    gd_prdate := xxccp_common_pkg2.get_process_date;
--
    IF ( gd_prdate IS NULL ) THEN
      RAISE get_process_expt;
    END IF;
  EXCEPTION
    -- *** プロファイル取得エラー ***
    WHEN get_profile_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00003
                , iv_token_name1  => cv_token_profile
                , iv_token_value1 => lv_profile_code
                );
      lb_retcode := xxcok_common_pkg.put_message_f(
                      in_which    => FND_FILE.OUTPUT   --出力区分
                    , iv_message  => lv_msg            --メッセージ
                    , in_new_line => 0                 --改行
                    );
      ov_errmsg  := NULL;
      ov_errbuf  := SUBSTRB( cv_pkg_name || cv_msg_cont || cv_prg_name || cv_msg_part || lv_msg, 1, 5000 );
      ov_retcode := cv_status_error;
    -- *** 業務日付取得エラー ***
    WHEN get_process_expt THEN
      lv_msg := xxccp_common_pkg.get_msg(
                  iv_application  => cv_xxcok_appl_name
                , iv_name         => cv_err_msg_00028
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
    ov_errbuf         OUT VARCHAR2     --エラー・メッセージ
  , ov_retcode        OUT VARCHAR2     --リターン・コード
  , ov_errmsg         OUT VARCHAR2     --ユーザー・エラー・メッセージ
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
    lv_errbuf    VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode   VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg    VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lb_retcode   BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
--
  BEGIN
    ov_retcode := cv_status_normal;
    -- =============================================================================
    -- 初期処理(A-1)の呼出し
    -- =============================================================================
    init(
      ov_errbuf         => lv_errbuf
    , ov_retcode        => lv_retcode
    , ov_errmsg         => lv_errmsg
    , in_file_id        => in_file_id
    , iv_format_pattern => iv_format_pattern
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- ファイルデータ取得(A-2)の呼出し
    -- =============================================================================
    get_file_data(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    , in_file_id => in_file_id
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- 一時表データ取得(A-3)の呼出し
    -- =============================================================================
    get_tmp_wholesale_bill(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    , in_file_id => in_file_id
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    ELSIF ( lv_retcode = cv_status_continue ) THEN
      ROLLBACK;
    END IF;
    -- =============================================================================
    -- 処理データ削除(A-8)の呼出し
    -- =============================================================================
    del_mrp_file_ul_interface(
      ov_errbuf  => lv_errbuf
    , ov_retcode => lv_retcode
    , ov_errmsg  => lv_errmsg
    , in_file_id => in_file_id
    );
    IF ( lv_retcode = cv_status_error ) THEN
      RAISE global_process_expt;
    END IF;
    -- =============================================================================
    -- 妥当性チェックでエラーが発生した場合、ステータスをエラーに設定
    -- =============================================================================
    IF ( gv_chk_code = cv_status_continue ) THEN
      ov_retcode := cv_status_error;
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
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
  PROCEDURE main(
    errbuf            OUT  VARCHAR2    --エラーメッセージ
  , retcode           OUT  VARCHAR2    --エラーコード
  , iv_file_id        IN   VARCHAR2    --ファイルID
  , iv_format_pattern IN   VARCHAR2    --フォーマットパターン
  )
  IS
    -- =======================
    -- ローカル定数
    -- =======================
    cv_prg_name   CONSTANT VARCHAR2(5) := 'main';    --プログラム名
    -- =======================
    -- ローカル変数
    -- =======================
    lv_errbuf        VARCHAR2(5000) DEFAULT NULL;               --エラー・メッセージ
    lv_retcode       VARCHAR2(1)    DEFAULT cv_status_normal;   --リターン・コード
    lv_errmsg        VARCHAR2(5000) DEFAULT NULL;               --ユーザー・エラー・メッセージ
    lv_msg           VARCHAR2(5000) DEFAULT NULL;               --メッセージ取得変数
    lv_message_code  VARCHAR2(500)  DEFAULT NULL;               --メッセージコード
    lb_retcode       BOOLEAN        DEFAULT TRUE;               --メッセージ出力の戻り値
    ln_file_id       NUMBER;                                    --ファイルID
--
  BEGIN
    ln_file_id := TO_NUMBER( iv_file_id );
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
      ov_errbuf         => lv_errbuf
    , ov_retcode        => lv_retcode
    , ov_errmsg         => lv_errmsg
    , in_file_id        => ln_file_id
    , iv_format_pattern => iv_format_pattern
    );
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
    -- 対象件数出力
    -- =============================================================================
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90000
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => gn_target_cnt
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    -- =============================================================================
    -- 成功件数出力
    -- =============================================================================
    -- *** リターンコードがエラーの場合、成功件数を'0'件にする ***
    IF ( lv_retcode = cv_status_error ) THEN
      gn_normal_cnt := cn_0;
    END IF;
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application  => cv_xxccp_appl_name
              , iv_name         => cv_message_90001
              , iv_token_name1  => cv_token_count
              , iv_token_value1 => gn_normal_cnt
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
              , iv_token_value1 => gn_error_cnt
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
    ELSIF ( lv_retcode = cv_status_error ) THEN
      lv_message_code := cv_message_90006;
    END IF;
--
    lv_msg := xxccp_common_pkg.get_msg(
                iv_application => cv_xxccp_appl_name
              , iv_name        => lv_message_code
              );
    lb_retcode := xxcok_common_pkg.put_message_f(
                    in_which    => FND_FILE.OUTPUT     --出力区分
                  , iv_message  => lv_msg              --メッセージ
                  , in_new_line => 0                   --改行
                  );
    --ステータスセット
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACK
    IF ( retcode = cv_status_error ) THEN
      ROLLBACK;
      --IFテーブルにデータがある場合は削除
      del_interface_at_error(
        ov_errbuf  => lv_errbuf      --エラー・メッセージ
      , ov_retcode => lv_retcode     --リターン・コード
      , ov_errmsg  => lv_errmsg      --ユーザー・エラー・メッセージ
      , in_file_id => ln_file_id     --ファイルID
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
      , in_file_id => ln_file_id     --ファイルID
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
      , in_file_id => ln_file_id     --ファイルID
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
      , in_file_id => ln_file_id     --ファイルID
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
END XXCOK021A01C;
/
