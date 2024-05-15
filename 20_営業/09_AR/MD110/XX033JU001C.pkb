CREATE OR REPLACE PACKAGE BODY XX033JU001C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX033JU001C(body)
 * Description      : 一般会計システム上のデータに、売掛管理システムで保持するDFFの値を更新します。
 * MD.050           : AR 仕訳付加情報更新処理 OCSJ/BFAFIN/MD050/F302
 * MD.070           : AR 仕訳付加情報更新処理 OCSJ/BFAFIN/MD070/F306
 * Version          : 11.5.10.2.4
 *
 * Program List
 * ---------------------------------- ----------------------------------------------
 *  Name                              Description
 * ---------------------------------- ----------------------------------------------
 *  get_id                            関連データ取得(A-1)
 *  get_add_dff_data_1                DFF付加対象データ抽出処理    (A2:Sales Invoices)
 *  get_trx_type_1                    前受金請求判定および注釈取得 (A2-1)
 *  get_add_dff_lines_data_1          請求書明細会計情報取得1      (A2-2)
 *  get_ra_customer_trx_lines_all_1   請求書明細会計情報取得2      (A2-3)
 *  get_ar_vat_tax_all_1              AR税情報取得                 (A2-4)
 
 *  get_add_dff_data_2                DFF付加対象データ抽出処理    (A3:Credit Memos)
 *  get_trx_number                    割当済請求書番号取得処理     (A3-1)
 *  get_add_dff_lines_data_2          請求書明細会計情報取得1      (A3-2)
 *  get_ra_customer_trx_lines_all_2   請求書明細会計情報取得2      (A3-3)
 *  get_ar_vat_tax_all_2              AR税情報取得 (A3-4)

 *  get_add_dff_data_3                DFF付加対象データ抽出処理    (A4:CM Applications)
 
 *  get_add_dff_data_4                DFF付加対象データ抽出処理    (A5:Adjistment)
 *  get_ra_customer_rx_all_1          前受金請求判定および注釈取得1(A5-1)
 *  get_ra_customer_rx_all_2          前受金請求判定および注釈取得2(A5-2)
 *  get_trx_type_2                    前受金請求判定および注釈取得 (A5-3)
 *  get_ar_vat_tax_all_3              AR税情報取得                 (A5-4)

 *  get_add_dff_data_5                DFF付加対象データ抽出処理    (A6:Trade Receipts)
 *  get_ra_hz_cust_account            顧客ヘッダーテーブルより設定値取得処理 (A6-1)
 *  get_hz_parties                    一見顧客出ない場合、パーティテーブルより取得処理 (A6-2)
 *  get_ar_cash_receipt_his_all_1     入金文書番号取得処理1        (A6-3)
 *  get_ar_cash_receipts_all          入金文書番号取得処理2戻し検索(A6-4)

 *  get_add_dff_data_6                DFF付加対象データ抽出処理    (A7:Cross Currency)

 *  upd_journal_data                  仕訳データの更新処理         (A8)
 *  upd_journal_data_1                仕訳データの更新処理(税区分対応)(A8_1)
 *  msg_output                        プルーフリスト出力処理       (A9)
 *  submain                           メイン処理プロシージャ
 *  main                              コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ----------- ------------ ------------- -------------------------------------------------
 *  Date        Ver.         Editor        Description
 * ----------- ------------ ------------- -------------------------------------------------
 *  2004/03/26  1.0          N.Iba         新規作成
 *  2004/05/06  1.1          N.Iba         消込参照更新不備、増減事由がセットされている
 *  2004/05/12  1.2          N.Iba         税区分更新処理修正対応
 *  2004/05/19  1.3          N.Iba         請求書ヘッダーテーブル情報取得条件追加
 *                                          1.売掛金／未収金入金　'TRADE_ACC'
 *                                          2.全共通　会計帳簿ID　追加
 *  2004/05/25  1.4          N.Iba         請求書ヘッダーテーブル情報取得条件追加
 *                                          1.銀行手数料　'TRADE_BANK_CHARGES'
 *  2005/01/31  1.5          K.Hattori     更新内容変更
 *                                         税コード、増減事由、起票部門、伝票入力者
 *                                         消込参照、予備１、予備２
 *                                         前受金充当請求書判断の変更
 *  2005/03/07  1.6          M.Marukawa    クレジット・メモの仕訳付加情報の取得先を、参照先
 *                                         取引(請求書)レコードの配分レコードに変更
 *  2005/03/14  1.7          M.Marukawa    過入金消込(明細仕訳タイプ=TRADE_ACTIVITY)の仕訳情報
 *                                         付加ロジックを追加
 *  2005/06/17  11.5.10.1.3  Y.Matsumura   請求書に紐づかないクレジット・メモがデータとして
 *                                         OMなどから入ってきた際に親請求書を検索しないよう変更
 *  2005/07/14  11.5.10.1.4  S.Yamada      受取手形機能への対応
 *                                         仕訳カテゴリがTrade ReceiptsのDFF付加対象データ抽出処理に
 *                                         以下の明細仕訳タイプを追加。
 *                                         TRADE_CONFIRMATION、TRADE_REMITTANCE、
 *                                         TRADE_FACTOR、TRADE_SHORT_TERM_DEBT
 *  2005/12/15  11.5.10.1.6  A.Okusa       税区分がNULLの時のGL_INTERFACE更新ロジック削除
 *                                         税区分がNULLの時に対象外の税金コードを取得する処理を削除
 *  2006/01/30  11.5.10.1.6B Y.Matsumura   get_trx_type_1中のSELECT文にORG_IDの条件を追加
 *  2006/06/09  11.5.10.2.3  S.Morisawa    gl_add_dff_data_cur_3でSELECT時の帳簿ID条件の追加
 *  2024/01/10  11.5.10.2.4  K.Nakagawa    [E_本稼動_19496]対応 分社化対応
 *
 *****************************************************************************************/
--
--#####################  固定共通例外宣言部 START   ####################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
--
--###########################  固定部 END   ############################
--
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --結果出力用日付形式1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --結果出力用日付形式2
  cv_package_name     CONSTANT VARCHAR2(20) := 'XX033JU001';              --パッケージ名
  cv_execite_tbl_name CONSTANT VARCHAR2(20) := 'GL_INTERFACE';            --処理対象テーブル名
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  get_org_id_expt       EXCEPTION;            -- オルグID未取得エラー
  get_books_id_expt     EXCEPTION;            -- 会計帳簿ID未取得エラー
  get_xx03_name_id_expt EXCEPTION;            -- XX03_TRX_CODES_V 税区分未取得エラー
  warning_status_expt   EXCEPTION;            -- ユーザーエラーハンドル用
--
  -- ===============================
  -- グローバル定数
  -- ===============================
-- 20050131 V1.5 START
  -- 修正タイプ
  cv_adjustment_type_c         CONSTANT VARCHAR2(3)  := 'C';  -- 前受金充当請求書
-- 20050131 V1.5 END
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : プルーフリスト出力処理 (A9)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    ln_sales_invoices_cnt       IN NUMBER,      -- 2.請求書件数(IN)(売上請求書)
    ln_trade_receipts_cnt       IN NUMBER,      -- 3.請求書件数(IN)(売掛／未収金入金)
    ln_adjustment_cnt           IN NUMBER,      -- 4.請求書件数(IN)(修正)
    ln_credit_memos_cnt         IN NUMBER,      -- 5.請求書件数(IN)(クレジットメモ)
    ln_credit_memo_app_cnt      IN NUMBER,      -- 6.請求書件数(IN)(クレジットメモ消込)
    ln_cross_currency_cnt       IN NUMBER,      -- 7.請求書件数(IN)(相互通貨)
    iv_journal_source           IN VARCHAR2,    -- 8.仕訳ソース名(IN)
    lv_sales_invoices           IN VARCHAR2,    -- 9.仕訳カテゴリ名(売上請求書)(IN)
    lv_trade_receipts           IN VARCHAR2,    -- 10.仕訳カテゴリ名(売掛／未収金入金)(IN)
    lv_adjustment               IN VARCHAR2,    -- 11.仕訳カテゴリ名(修正)(IN)
    lv_credit_memos             IN VARCHAR2,    -- 12.仕訳カテゴリ名(クレジットメモ)(IN)
    lv_credit_memo_applications IN VARCHAR2,    -- 13.仕訳カテゴリ名(クレジットメモ消込)(IN)
    lv_cross_currency           IN VARCHAR2,    -- 14.仕訳カテゴリ名(相互通貨)(IN)
    ov_errbuf                   OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,   -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'msg_output'; -- プログラム名
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
    -- LOOKUP_TYPE値(仕訳カテゴリ)
    cv_lookup_type_category   CONSTANT VARCHAR2(50) := 'XX03_AR_JOURNAL_CATEGORY';
    -- LOOKUP_TYPE値(件数)
    cv_lookup_type_count      CONSTANT VARCHAR2(50) := 'XX03_AR_COUNT';
--
    -- *** ローカル変数 ***
    lv_msgbuf  VARCHAR2(5000);     -- 出力メッセージ
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
    lv_category VARCHAR2(100);     -- 画面表示名(仕訳カテゴリ)
    lv_count    VARCHAR2(100);     -- 画面表示名(件数)
    lv_count_all NUMBER;          -- (件数)
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    lv_count_all := (ln_sales_invoices_cnt + ln_trade_receipts_cnt + 
     ln_adjustment_cnt + ln_credit_memos_cnt + ln_credit_memo_app_cnt + ln_cross_currency_cnt);
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    -- メッセージより画面表示名を取得
    -- 仕訳カテゴリ
    lv_category := xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-03414'); -- メッセージ区分
    -- 件数
    lv_count := xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-03415'); -- メッセージ区分
    -- 正常終了時の画面出力
    -- 見出し部分の表示
    xx03_header_line_output_pkg.header_line_output_p('AR',
      xx00_global_pkg.prog_appl_id,
      0,
      in_org_id,
      xx00_global_pkg.conc_program_id,
      lv_errbuf,
      lv_retcode,
      lv_errmsg);
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- 2行目(空行)
    xx00_file_pkg.output(' ');
    -- 3行目(パラメータ名)
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' || 
      iv_journal_source);
    xx00_file_pkg.output(xx00_message_pkg.get);
    -- 4行目(空行)
    xx00_file_pkg.output('');
    -- 5行目(処理結果  項目)
    xx00_file_pkg.output(RPAD(lv_category,24,' ') || 
      LPAD(lv_count,7,' '));
    -- 6行目(処理結果  売上請求書)
    xx00_file_pkg.output(RPAD(lv_sales_invoices,24,' ') || 
      TO_CHAR(ln_sales_invoices_cnt,'999999'));
    -- 7行目(処理結果  売掛／未収金入金)
    xx00_file_pkg.output(RPAD(lv_trade_receipts,24,' ') || 
      TO_CHAR(ln_trade_receipts_cnt,'999999'));
    -- 8行目(処理結果  修正)
    xx00_file_pkg.output(RPAD(lv_adjustment,24,' ') || 
      TO_CHAR(ln_adjustment_cnt,'999999'));
    -- 9行目(処理結果  クレジットメモ)
    xx00_file_pkg.output(RPAD(lv_credit_memos,24,' ') || 
      TO_CHAR(ln_credit_memos_cnt,'999999'));
    -- 10行目(処理結果  クレジットメモ消込)
    xx00_file_pkg.output(RPAD(lv_credit_memo_applications,24,' ') || 
      TO_CHAR(ln_credit_memo_app_cnt,'999999'));
    -- 11行目(処理結果  相互通貨)
    xx00_file_pkg.output(RPAD(lv_cross_currency,24,' ') || 
      TO_CHAR(ln_cross_currency_cnt,'999999'));
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    --正常処理後のログ出力
    lv_msgbuf := xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-07002'); -- メッセージ区分(情報)
    lv_msgbuf := lv_msgbuf || cv_package_name || ' ';
    lv_msgbuf := lv_msgbuf || xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-07005',
      'TOK_TABLE',
      cv_execite_tbl_name,
      'COUNT',
      TO_CHAR(lv_count_all,'99999'));
    xx00_file_pkg.log(lv_msgbuf);
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END msg_output;
--
--##############################################################################################
------------------------------------------- A2 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_trx_type_1
   * Description      : 前受金請求書判定および注釈取得処理 [Sales Invoices](A2-1)
   ***********************************************************************************/
  PROCEDURE get_trx_type_1(
    lv_cust_trx_type_id_1       IN  NUMBER,      -- 請求書タイプID(IN)
    lv_type                     OUT VARCHAR2,    -- 請求書タイプ(OUT)
    ov_errbuf                   OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_type_1'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_trx_type_1');
    xx00_file_pkg.log('key lv_cust_trx_type_id_1=' || TO_CHAR(lv_cust_trx_type_id_1));
    -- タイプを取得する
    SELECT  rctta.type  AS type                      -- タイプ
    INTO    lv_type
    FROM    ra_cust_trx_types_all rctta              -- 請求書タイプ
    --2006/01/30 Ver11.5.10.1.6B Add Start
    --WHERE   rctta.cust_trx_type_id  = lv_cust_trx_type_id_1;
    WHERE   rctta.cust_trx_type_id  = lv_cust_trx_type_id_1
     AND    rctta.ORG_ID = xx00_profile_pkg.value('ORG_ID');
    --2006/01/30 Ver11.5.10.1.6B Add End
    -- ログ出力
    xx00_file_pkg.log('update type=' || lv_type);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03050',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_cust_trx_type_id_1));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_trx_type_1;
--
-- 20050307 V1.6 START
  /**********************************************************************************
   * Procedure Name   : get_cust_trx_line_gl_dist_dff
   * Description      : 顧客取引明細GL配分DFF取得処理 [共通](A3-2)
   **********************************************************************************/
--
  PROCEDURE get_cust_trx_line_gl_dist_dff(
    ln_customer_trx_line_id       IN   NUMBER,              -- 請求書明細ID(IN)
    lv_cust_trx_line_attribute1   OUT  VARCHAR2,            -- 増減事由(OUT)
    lv_cust_trx_line_attribute2   OUT  VARCHAR2,            -- 消込参照(OUT)
    lv_cust_trx_line_attribute9   OUT  VARCHAR2,            -- 予備１(OUT)
    lv_cust_trx_line_attribute10  OUT  VARCHAR2,            -- 予備２(OUT)
    ov_errbuf                     OUT  VARCHAR2,            -- エラー・メッセージ  --# 固定 #
    ov_retcode                    OUT  VARCHAR2,            -- リターン・コード    --# 固定 #
    ov_errmsg                     OUT  VARCHAR2)
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_cust_trx_line_gl_dist_dff'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('  ln_customer_trx_line_id(IN) = ' || TO_CHAR(ln_customer_trx_line_id));
--
    -- 顧客取引明細DFFを取得
    SELECT TLD.attribute1   attribute1,                     -- 増減事由
           TLD.attribute2   attribute2,                     -- 消込参照
           TLD.attribute9   attribute9,                     -- 予備１
           TLD.attribute10  attribute10                     -- 予備２
    INTO   lv_cust_trx_line_attribute1, 
           lv_cust_trx_line_attribute2,
           lv_cust_trx_line_attribute9,
           lv_cust_trx_line_attribute10
    FROM   ra_cust_trx_line_gl_dist_all  TLD                -- 顧客取引明細GL配分テーブル
    WHERE  TLD.customer_trx_line_id = ln_customer_trx_line_id;
--
    -- ログ出力
    xx00_file_pkg.log('  lv_cust_trx_line_attribute1(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute1));
    xx00_file_pkg.log('  lv_cust_trx_line_attribute2(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute2));
    xx00_file_pkg.log('  lv_cust_trx_line_attribute9(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute9));
    xx00_file_pkg.log('  lv_cust_trx_line_attribute10(OUT) = ' || TO_CHAR(lv_cust_trx_line_attribute10));
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03052',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(ln_customer_trx_line_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--

   END get_cust_trx_line_gl_dist_dff;
-- 20050307 V1.6 END
--
  /**********************************************************************************
   * Procedure Name   : get_add_dff_lines_data_1
   * Description      : 請求書明細会計情報取得処理１ [Sales Invoices](A2-2)
   **********************************************************************************/
--
  -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
  PROCEDURE get_add_dff_lines_data_1(
   lv_dis_line_number_1           IN VARCHAR2,     -- 請求書タイプＩＤ(IN)
   lv_line_attribute1_1           OUT VARCHAR2,    -- 増減事由(OUT)
   lv_line_attribute2_1           OUT VARCHAR2,    -- 消込参照(OUT)
   lv_line_customer_trx_line_id_1 OUT NUMBER,      -- 請求書明細ID(OUT)
   lv_line_attribute9_1           OUT VARCHAR2,    -- 予備１(OUT)
   lv_line_attribute10_1          OUT VARCHAR2,    -- 予備２(OUT)
   ov_errbuf                      OUT VARCHAR2,    -- エラー・メッセージ   --# 固定 #
   ov_retcode                     OUT VARCHAR2,    -- リターン・コード     --# 固定 #
   ov_errmsg                      OUT VARCHAR2)
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_lines_data_1'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_lines_data_1');
    xx00_file_pkg.log('key lv_dis_line_number_1=' || TO_CHAR(lv_dis_line_number_1));
    -- タイプを取得する
    -- 20050131 V1.5 予備１・予備２の追加
    SELECT rctlgda.attribute1 AS attribute1,    --増減事由
  --       rctlgda.attribute1 AS attribute2,    20040506 修正
           rctlgda.attribute2 AS attribute2,    --消込参照
           rctlgda.customer_trx_line_id AS customer_trx_line_id,  --請求書明細ID
           rctlgda.attribute9 AS attribute9,    --予備１
           rctlgda.attribute10 AS attribute10   --予備２
    INTO   lv_line_attribute1_1, 
           lv_line_attribute2_1,
           lv_line_customer_trx_line_id_1,
           lv_line_attribute9_1,
           lv_line_attribute10_1
    FROM   ra_cust_trx_line_gl_dist_all  rctlgda  --請求書明細会計情報
    WHERE  lv_dis_line_number_1 =  rctlgda.cust_trx_line_gl_dist_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03052',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_dis_line_number_1));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
   END get_add_dff_lines_data_1;
  /**********************************************************************************
   * Procedure Name   : get_ra_cus_trx_lines_all_1
   * Description      : 請求書明細会計情報取得処理２ [Sales Invoices](A2-3)
   **********************************************************************************/
--
  PROCEDURE get_ra_cus_trx_lines_all_1(
   lv_line_cust_trx_line_id_1 IN VARCHAR2,    -- 請求書明細ID(IN)
   lv_vat_tax_id              OUT NUMBER,     -- 税ID(OUT)
   lv_descripion              OUT VARCHAR2,   -- 明細摘要(OUT)
   ov_errbuf                  OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
   ov_retcode                 OUT VARCHAR2,   -- リターン・コード             --# 固定 #
   ov_errmsg                  OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_cus_trx_lines_all_1'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_cus_trx_lines_all_1');
    xx00_file_pkg.log('key lv_line_cust_trx_line_id_1=' || TO_CHAR(lv_line_cust_trx_line_id_1));
    -- タイプを取得する
    SELECT  rctla.vat_tax_id AS vat_tax_id,   --税ID
            rctla.description AS description  --明細摘要
    INTO    lv_vat_tax_id,
            lv_descripion
    FROM    ra_customer_trx_lines_all rctla
    WHERE   rctla.customer_trx_line_id  = lv_line_cust_trx_line_id_1;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03053',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_line_cust_trx_line_id_1));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ra_cus_trx_lines_all_1;
  /**********************************************************************************
   * Procedure Name   : get_ar_vat_tax_all_1
   * Description      : AR税テーブル情報取得処理 [Sales Invoices](A2-4)
   **********************************************************************************/
--
  PROCEDURE get_ar_vat_tax_all_1(
   lv_vat_tax_id         IN  NUMBER,      -- 税ID(IN)
   lv_avta_tax_code      OUT VARCHAR2,    -- 税コード(OUT)
   ov_errbuf             OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
   ov_retcode            OUT VARCHAR2,    -- リターン・コード             --# 固定 #
   ov_errmsg             OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_vat_tax_all_1'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_vat_tax_all_1');
    xx00_file_pkg.log('key lv_vat_tax_id=' || TO_CHAR(lv_vat_tax_id));
    -- タイプを取得する
    SELECT  avta.tax_code AS tax_code    --税コード
    INTO    lv_avta_tax_code
    FROM    ar_vat_tax_all  avta
    WHERE   avta.vat_tax_id  = lv_vat_tax_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                 --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03054',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_vat_tax_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_vat_tax_all_1;
--
--##############################################################################################
------------------------------------------- A3 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_trx_number
   * Description      : 割当済請求書番号の取得処理 [Credit Memo](A3-1)
   ***********************************************************************************/
  PROCEDURE get_trx_number(
    lv_previous_cust_trx_id    IN  VARCHAR2,     -- 親請求書ＩＤ(IN)
    lv_trx_number              OUT VARCHAR2,     -- 請求書番号(OUT)
    ov_errbuf                  OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode                 OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg                  OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_number'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_trx_number');
    xx00_file_pkg.log('key lv_previous_cust_trx_id=' || TO_CHAR(lv_previous_cust_trx_id));
    -- タイプを取得する
    SELECT  rcta.trx_number AS trx_number   --請求書番号
    INTO    lv_trx_number 
    FROM    ra_customer_trx_all rcta        --請求書ヘッダテーブル
    WHERE   lv_previous_cust_trx_id = rcta.customer_trx_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03051',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_previous_cust_trx_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_trx_number;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_lines_data_2
   * Description      : 請求書明細会計情報取得処理１ [Credit Memo](A3-2)
   **********************************************************************************/
--
  -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
  PROCEDURE get_add_dff_lines_data_2(
   lv_dis_line_number_2            IN  VARCHAR2,  -- 請求書配分ID(IN)
   lv_line_attribute1_2            OUT VARCHAR2,  -- 増減事由(OUT)
   lv_line_attribute2_2            OUT VARCHAR2,  -- 消込参照(OUT)
   lv_line_customer_trx_line_id_2  OUT NUMBER,    -- 請求書明細ID(OUT)
   lv_line_attribute9_2            OUT VARCHAR2,  -- 予備１(OUT)
   lv_line_attribute10_2           OUT VARCHAR2,  -- 予備２(OUT)
   ov_errbuf                       OUT VARCHAR2,  -- エラー・メッセージ   --# 固定 #
   ov_retcode                      OUT VARCHAR2,  -- リターン・コード     --# 固定 #
   ov_errmsg                       OUT VARCHAR2)
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_lines_data_2'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_lines_data_2');
    xx00_file_pkg.log('key lv_dis_line_number_2=' || TO_CHAR(lv_dis_line_number_2));
    -- タイプを取得する
    -- 20050131 V1.5 予備１・予備２の追加
    SELECT rctlgda.attribute1 AS attribute1,    --増減事由
--         rctlgda.attribute1 AS attribute2,    20040506 修正
           rctlgda.attribute2 AS attribute2,    --消込参照
           rctlgda.customer_trx_line_id AS customer_trx_line_id,  --請求書明細ID
           rctlgda.attribute9 AS attribute9,    --予備１
           rctlgda.attribute10 AS attribute10   --予備２
    INTO   lv_line_attribute1_2, 
           lv_line_attribute2_2,
           lv_line_customer_trx_line_id_2,
           lv_line_attribute9_2,
           lv_line_attribute10_2
    FROM   ra_cust_trx_line_gl_dist_all  rctlgda  --請求書明細会計情報
    WHERE  lv_dis_line_number_2 =  rctlgda.cust_trx_line_gl_dist_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03052',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_dis_line_number_2));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
   END get_add_dff_lines_data_2;
  /**********************************************************************************
   * Procedure Name   : get_ra_cus_trx_lines_all_2
   * Description      : 請求書明細会計情報取得処理２ [Credit Memo](A3-3)
   **********************************************************************************/
--
  PROCEDURE get_ra_cus_trx_lines_all_2(
   lv_line_cust_trx_line_id_2   IN VARCHAR2,   -- 請求書明細ID(IN)
   lv_vat_tax_id_2              OUT NUMBER,    -- 税ID(OUT)
   lv_descripion_2              OUT VARCHAR2,  -- 明細摘要(OUT)
   ov_errbuf                    OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
   ov_retcode                   OUT VARCHAR2,  -- リターン・コード             --# 固定 #
   ov_errmsg                    OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_cus_trx_lines_all_2'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_cus_trx_lines_all_2');
    xx00_file_pkg.log('key lv_line_cust_trx_line_id_2=' || TO_CHAR(lv_line_cust_trx_line_id_2));
    -- タイプを取得する
    SELECT  rctla.vat_tax_id AS vat_tax_id,   --税ID
            rctla.description AS description  --明細摘要
    INTO    lv_vat_tax_id_2,
            lv_descripion_2
    FROM    ra_customer_trx_lines_all rctla
    WHERE   rctla.customer_trx_line_id  = lv_line_cust_trx_line_id_2;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03053',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_line_cust_trx_line_id_2));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ra_cus_trx_lines_all_2;
  /**********************************************************************************
   * Procedure Name   : get_ar_vat_tax_all_2
   * Description      : AR税テーブル情報取得処理 [Credit Memo](A3-4)
   **********************************************************************************/
--
  PROCEDURE get_ar_vat_tax_all_2(
   lv_vat_tax_id_2         IN  NUMBER,      -- 税ID(IN)
   lv_avta_tax_code_2      OUT VARCHAR2,    -- 税コード(OUT)
   ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
   ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
   ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_vat_tax_all_2'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_vat_tax_all_2');
    xx00_file_pkg.log('key lv_vat_tax_id_2=' || TO_CHAR(lv_vat_tax_id_2));
    -- タイプを取得する
    SELECT  avta.tax_code AS tax_code    --税コード
    INTO    lv_avta_tax_code_2
    FROM    ar_vat_tax_all  avta
    WHERE   avta.vat_tax_id  = lv_vat_tax_id_2;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03054',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_vat_tax_id_2));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_vat_tax_all_2;
--##############################################################################################
------------------------------------------- A5 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_ra_customer_rx_all_1
   * Description      : 前受金請求書判定および注釈取得処理_1 [adjustment](A5-1)
   ***********************************************************************************/
  PROCEDURE get_ra_customer_rx_all_1(
    lv_customer_trx_id               IN  NUMBER,    -- 請求書タイプID(IN)
    lv_rcta2_trx_number              OUT VARCHAR2,  -- 請求書番号(OUT)
    lv_rcta2_attribute5              OUT VARCHAR2,  -- 起票部門(OUT)
    lv_rcta2_attribute6              OUT VARCHAR2,  -- 入力者(OUT)
    lv_rcta2_initial_cust_trx_id     OUT VARCHAR2,  -- 取引約定(OUT)
    ov_errbuf                        OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode                       OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg                        OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_customer_rx_all_1'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_customer_rx_all_1');
    xx00_file_pkg.log('key lv_customer_trx_id=' || TO_CHAR(lv_customer_trx_id));
    -- タイプを取得する
    SELECT  rcta2.trx_number  AS trx_number,    --請求書番号
            rcta2.attribute5 AS attribute5,     --起票部門
            rcta2. attribute6 AS attribute6,    --入力者
            rcta2.initial_customer_trx_id AS initial_customer_trx_id    --取引約定
    INTO    lv_rcta2_trx_number,
            lv_rcta2_attribute5,
            lv_rcta2_attribute6,
            lv_rcta2_initial_cust_trx_id
    FROM    ra_customer_trx_all rcta2           --請求書ヘッダテーブル
    WHERE   rcta2.customer_trx_id = lv_customer_trx_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                    --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03055',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_customer_trx_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ra_customer_rx_all_1;
  /**********************************************************************************
   * Procedure Name   : get_ra_customer_rx_all_2
   * Description      : 前受金請求書判定および注釈取得処理_2 [adjustment](A5-2)
   **********************************************************************************/
--
  PROCEDURE get_ra_customer_rx_all_2(
   lv_initial_customer_trx_id   IN  NUMBER,    -- 請求書ID(IN)
   lv_cust_trx_type_id          OUT NUMBER,    -- 請求書タイプID(OUT)
   lv_flg_1                     OUT VARCHAR2,  -- 判定フラグ(OUT)
   ov_errbuf                    OUT VARCHAR2,  -- エラー・メッセージ   --# 固定 #
   ov_retcode                   OUT VARCHAR2,  -- リターン・コード     --# 固定 #
   ov_errmsg                    OUT VARCHAR2)
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_customer_rx_all_2'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_customer_rx_all_2');
    xx00_file_pkg.log('key lv_initial_customer_trx_id=' || TO_CHAR(lv_initial_customer_trx_id));
    -- タイプを取得する
    SELECT  rcta3.cust_trx_type_id  AS cust_trx_type_id    --請求書タイプＩＤ
    INTO    lv_cust_trx_type_id 
    FROM    ra_customer_trx_all rcta3                      --請求書ヘッダテーブル
    WHERE   rcta3.customer_trx_id =  lv_initial_customer_trx_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
         lv_flg_1 := '1';                         -- 判定フラグ
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
   END get_ra_customer_rx_all_2;
  /**********************************************************************************
   * Procedure Name   : get_trx_type_2
   * Description      : 前受金請求書判定および注釈取得処理_3 [adjustment](A5-3)
   **********************************************************************************/
--
  PROCEDURE get_trx_type_2(
   lv_cust_trx_type_id  IN NUMBER,           -- 請求書タイプID(IN)
   lv_type              OUT VARCHAR2,        -- タイプ(OUT)
   lv_flg_2             OUT VARCHAR2,        -- 判定フラグ(OUT)
   ov_errbuf            OUT VARCHAR2,        -- エラー・メッセージ           --# 固定 #
   ov_retcode           OUT VARCHAR2,        -- リターン・コード             --# 固定 #
   ov_errmsg            OUT VARCHAR2)        -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_trx_type_2'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_trx_type_2');
    xx00_file_pkg.log('key lv_cust_trx_type_id=' || TO_CHAR(lv_cust_trx_type_id));
    -- タイプを取得する

    SELECT  rctta1.type  AS type              --タイプ
    INTO    lv_type 
    FROM    ra_cust_trx_types_all rctta1      --請求書タイプ
    WHERE   rctta1.cust_trx_type_id  =  lv_cust_trx_type_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
         lv_flg_2 := '1';                         -- 判定フラグ
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_trx_type_2;
  /**********************************************************************************
   * Procedure Name   : get_ar_vat_tax_all_3
   * Description      : AR税テーブル情報取得処理 [adjustment](A5-4)
   **********************************************************************************/
--
  -- 20050131 V1.5 パラメータの変更
  --                 （AFF組合せID（lv_code_combination_id）
  --                                                      ⇒ 請求書ID（invoice_id））
  --                及び
  --               パラメータの追加（明細仕訳タイプ（payment_id））
  PROCEDURE get_ar_vat_tax_all_3(
   lv_invoice_id         IN  VARCHAR2,   -- 請求書ID (IN)
   lv_payment_id         IN  VARCHAR2,   -- 明細仕訳タイプ
   lv_xx03_tax_code      IN  VARCHAR2,   -- XX03_TAX_CODES(NAME)(IN)
   lv_tax_code           OUT VARCHAR2,     -- 税コード(OUT)
   ov_errbuf             OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
   ov_retcode            OUT VARCHAR2,     -- リターン・コード             --# 固定 #
   ov_errmsg             OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_vat_tax_all_3'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_vat_tax_all_3');
--    xx00_file_pkg.log('key lv_code_combination_id=' || TO_CHAR(lv_code_combination_id));
    -- タイプを取得する
-- 20050131 V1.5 START
--    SELECT  avta.tax_code AS tax_code      --税コード
--    INTO    lv_tax_code
--    FROM    ar_vat_tax_all  avta           --AR税テーブル
--    WHERE   avta.tax_account_id = lv_code_combination_id;
--
    IF lv_payment_id = 'ADJ_ADJ' OR 
       lv_payment_id = 'ADJ_TAX' OR 
       lv_payment_id = 'ADJ_ADJ_NON_REC_TAX' THEN
         SELECT  avta.tax_code AS tax_code      --税コード
         INTO    lv_tax_code
         FROM    ar_distributions_all ada,       --AR配分
                 ar_vat_tax_all  avta           --AR税テーブル
         WHERE   ada.tax_code_id = avta.vat_tax_id
         AND     ada.source_id   = lv_invoice_id;
    END IF;
--
-- 20050131 V1.5 END
--
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                   --*** 伝票番号及びその他の項目未取得エラー ***
-- 2004/04/20 データNOT FOUND 時の対応（データ対応）
      lv_tax_code := lv_xx03_tax_code;
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
-- 2004/04/20 保留（データ対応）   
--      lv_errbuf := xx00_message_pkg.get_msg(
--        'XX03',  --アプリケーション短縮名
--        'APP-XX03-07003'); -- メッセージ区分(警告)
--      lv_errbuf := lv_errbuf || cv_package_name || ' ';
--      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
--        'XX03',  --アプリケーション短縮名
--        'APP-XX03-03054',
--        'TOK_XX03_DFF_KEY',
--        TO_CHAR(lv_code_combination_id));
--      xx00_file_pkg.log(lv_errbuf);
--      ov_errmsg := lv_errmsg;                                                           --# 任意 #
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
--      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_vat_tax_all_3;
--##############################################################################################
------------------------------------------- A6 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_ra_hz_cust_account
   * Description      : 顧客ヘッダーテーブルより設定値取得処理 [Trade Receipts] (A6-1)
   ***********************************************************************************/
  PROCEDURE get_ra_hz_cust_account(
    lv_pay_from_customer        IN  VARCHAR2,    -- 支払顧客(IN)
    lv_hca_account_number       OUT VARCHAR2,    -- 顧客番号(OUT)
    lv_hca_party_id             OUT NUMBER,      -- パーティID(OUT)
    lv_hca_attribute2           OUT VARCHAR2,    -- 一見顧客区分(OUT)
    ov_errbuf                   OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ra_hz_cust_account'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ra_hz_cust_account');
    xx00_file_pkg.log('key lv_pay_from_customer=' || TO_CHAR(lv_pay_from_customer));
    -- タイプを取得する
    SELECT  hca.account_number  AS account_number,  -- 顧客番号
            hca.party_id  AS party_id,              -- パーティＩＤ
            hca.attribute2  AS attribute2           -- 一見顧客区分
    INTO    lv_hca_account_number,
            lv_hca_party_id,  
            lv_hca_attribute2
    FROM    hz_cust_accounts hca                    -- 顧客
    WHERE   lv_pay_from_customer  =   hca.cust_account_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03058',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_pay_from_customer));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ra_hz_cust_account;
  /**********************************************************************************
   * Procedure Name   : get_hz_parties
   * Description      : 一見顧客出ない場合、パーティテーブルより取得処理  [Trade Receipts] (A6-2)
   **********************************************************************************/
--
  PROCEDURE get_hz_parties(
   lv_hca_party_id          IN  NUMBER,    -- パーティID(IN)
   lv_hp_party_name         OUT VARCHAR2,  -- パーティ名(OUT)
   ov_errbuf                OUT VARCHAR2,  -- エラー・メッセージ   --# 固定 #
   ov_retcode               OUT VARCHAR2,  -- リターン・コード     --# 固定 #
   ov_errmsg                OUT VARCHAR2)
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_hz_parties'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_hz_parties');
    xx00_file_pkg.log('key lv_hca_party_id=' || TO_CHAR(lv_hca_party_id));
    -- タイプを取得する
    SELECT  hp.party_name  AS party_name     --パーティ名
    INTO    lv_hp_party_name
    FROM    hz_parties hp                    --パーティ
    WHERE   lv_hca_party_id = hp.party_id;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03059',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_hca_party_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
   END get_hz_parties;
  /**********************************************************************************
   * Procedure Name   : get_ar_cash_receipt_his_all_1
   * Description      : 入金文書番号取得処理１ [Trade Receipts] (A6-3)
   **********************************************************************************/
--
  PROCEDURE get_ar_cash_receipt_his_all_1(
   lv_invoice_id        IN  VARCHAR2,     -- 入金ID(IN)
   lv_acrha_status      OUT VARCHAR2,     -- ステータス(OUT)
   ov_errbuf            OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
   ov_retcode           OUT VARCHAR2,     -- リターン・コード             --# 固定 #
   ov_errmsg            OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_cash_receipt_his_all_1'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_cash_receipt_his_all_1');
    xx00_file_pkg.log('key lv_invoice_id=' || TO_CHAR(lv_invoice_id));
    -- タイプを取得する
    SELECT  acrha.status AS status             --ステータス
    INTO    lv_acrha_status
    FROM    ar_cash_receipt_history_all acrha --入金履歴情報テーブル
    WHERE   acrha.cash_receipt_history_id = substr(lv_invoice_id, instr(lv_invoice_id,'C',1)+1);
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03060',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_cash_receipt_his_all_1;
  /**********************************************************************************
   * Procedure Name   : get_ar_cash_receipts_all
   * Description      : 入金文書番号取得処理２戻し [Trade Receipts] (A6-4)
   **********************************************************************************/
--
  PROCEDURE get_ar_cash_receipts_all(
   lv_invoice_id              IN  VARCHAR2,   -- 入金ID(IN)
   lv_acra_doc_sequence_value OUT NUMBER,     -- 入金文書番号戻し(OUT)
   ov_errbuf                  OUT VARCHAR2,   -- エラー・メッセージ           --# 固定 #
   ov_retcode                 OUT VARCHAR2,   -- リターン・コード             --# 固定 #
   ov_errmsg                  OUT VARCHAR2)   -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   ###########################
--
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_ar_cash_receipts_all'; -- プログラム名
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
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_ar_cash_receipts_all');
    xx00_file_pkg.log('key lv_invoice_id=' || TO_CHAR(lv_invoice_id));
    -- タイプを取得する
    SELECT  acra.doc_sequence_value AS doc_sequence_value  --入金文書番号
    INTO    lv_acra_doc_sequence_value
    FROM    ar_cash_receipts_all acra                      --入金情報テーブル
    WHERE   acra.cash_receipt_id = substr(lv_invoice_id, instr(lv_invoice_id,'C',1)+1);
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03060',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(lv_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_ar_cash_receipts_all;
  /**********************************************************************************
   * Procedure Name   : get_id
   * Description      : 関連データ取得 (A-1)
   ***********************************************************************************/
  PROCEDURE get_id(
    on_gl_book_id           OUT NUMBER,       -- 1.会計帳簿帳簿ID(OUT)
    on_org_id               OUT NUMBER,       -- 2.オルグID(OUT)
    ov_sales_invoices       OUT VARCHAR2,     -- 3.仕訳カテゴリ名(売上請求書)(OUT)
    ov_trade_receipts       OUT VARCHAR2,     -- 4.仕訳カテゴリ名(売掛／未収金入金)(OUT)
    ov_adjustment           OUT VARCHAR2,     -- 5.仕訳カテゴリ名(修正)(OUT)
    ov_credit_memos         OUT VARCHAR2,     -- 6.仕訳カテゴリ名(クレジットメモ)(OUT)
    ov_credit_memo_applications OUT VARCHAR2, -- 7.仕訳カテゴリ名(クレジットメモ消込)(OUT)
    ov_cross_currency       OUT VARCHAR2,     -- 8.仕訳カテゴリ名(相互通貨)(OUT)
    ov_xx03_tax_code        OUT VARCHAR2,     -- 9.XX03_TAX_CODES_V(NAME)(OUT)
    ov_errbuf               OUT VARCHAR2,     -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_id'; -- プログラム名
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
    cv_lookup_type_category   CONSTANT VARCHAR2(50) := 
      'XX03_AR_JOURNAL_TYPE'; -- LOOKUP_TYPE値
    cv_lookup_code_buying   CONSTANT VARCHAR2(50) := 
      'BUYING_IN_INVOICE'; -- LOOKUP_CODE値(請求書)
    cv_lookup_code_payment  CONSTANT VARCHAR2(50) := 
      'PAYMENT_TYPE'; -- LOOKUP_CODE値(支払)
--
    -- *** ローカル変数 ***
    lv_category_err_tk    VARCHAR2(50); -- 仕訳カテゴリ未取得エラートークン値
    -- Ver11.5.10.1.6 2005/12/15 Delete Start
    -- ov_xx03_tax_code_cnt  NUMBER;       -- XX03_TAX_CODES_V(NAME)件数
    -- Ver11.5.10.1.6 2005/12/15 Delete End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_id');
    --オルグIDの取得
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    --オルグID値の検証
    IF (on_org_id IS NULL) THEN
      -- オルグID未取得エラー
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03045');
      RAISE get_org_id_expt;
    END IF;
--
    --会計帳簿IDの取得
    on_gl_book_id := TO_NUMBER(xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    --会計帳簿ID値の検証
    IF on_gl_book_id IS NULL THEN
      -- 会計帳簿ID未取得エラー
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03044');
      RAISE get_books_id_expt;
    END IF;
--
    --仕訳カテゴリ名(売上請求書)の取得
    SELECT  gjsv.user_je_category_name
    INTO    ov_sales_invoices
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Sales Invoices';
    
    --仕訳カテゴリ名(売掛／未収金入)の取得
    SELECT  gjsv.user_je_category_name
    INTO    ov_trade_receipts
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Trade Receipts';
    
    --仕訳カテゴリ名(修正)の取得
    SELECT  gjsv.user_je_category_name
    INTO    ov_adjustment
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Adjustment';
    
    --仕訳カテゴリ名(クレジットメモ)の取得
    SELECT  gjsv.user_je_category_name
    INTO    ov_credit_memos
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Credit Memos';
    
    --仕訳カテゴリ名(クレジットメモ消込)の取得
    SELECT  gjsv.user_je_category_name
    INTO    ov_credit_memo_applications
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Credit Memo Applications';
    
    --仕訳カテゴリ名(相互通貨)の取得
    SELECT  gjsv.user_je_category_name
    INTO    ov_cross_currency
    FROM  gl_je_categories_vl gjsv
    WHERE gjsv.je_category_name = 'Cross Currency';
    
    -- Ver11.5.10.1.6 2005/12/15 Delete Start
    --20040512 XX03_TAX_CODES_V(NAME) 追加 START
    --20040512 XX03_TAX_CODES_V(NAME)の取得
    --SELECT  count(xx03_tcv.name)
    --INTO    ov_xx03_tax_code_cnt
    --FROM  xx03_tax_codes_v xx03_tcv
    --WHERE xx03_tcv.attribute1 IS NULL;
    --IF ov_xx03_tax_code_cnt > 1 OR
    --   ov_xx03_tax_code_cnt = 0 THEN
    -- --件数取得エラー処理（０件 or ２件以上存在した場合）
    --  -- エラーメッセージ取得
    --  lv_category_err_tk := 'ov_xx03_tax_codes_v';
    --  lv_errbuf := xx00_message_pkg.get_msg(
    --    'XX03',  --アプリケーション短縮名
    --    'APP-XX03-07003'); -- メッセージ区分(警告)
    --  lv_errbuf := lv_errbuf || cv_package_name || ' ';
    --  lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
    --    'XX03',  --アプリケーション短縮名
    --    'APP-XX03-03082',
    --    'TOK_XX03_LOOKUP_TYPE',
    --    lv_category_err_tk);  -- 未取得仕訳カテゴリ名
    --  RAISE get_xx03_name_id_expt;
    --END IF;
    --SELECT  xx03_tax_code.name
    --INTO    ov_xx03_tax_code
    --FROM  xx03_tax_codes_v xx03_tax_code
    --WHERE xx03_tax_code.attribute1 IS NULL;
    -- --20040512 XX03_TAX_CODES_V(NAME) 追加 END
    -- Ver11.5.10.1.6 2005/12/15 Delete End
--
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN get_org_id_expt THEN                       --*** オルグID未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
    WHEN get_books_id_expt THEN                       --*** 会計帳簿ID未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
    WHEN get_xx03_name_id_expt THEN                       --*** 会計帳簿ID未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
    WHEN NO_DATA_FOUND THEN                       --*** 仕訳カテゴリ判断値未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      -- 取得できなかった仕訳カテゴリの判断
      IF ov_sales_invoices IS NULL THEN
        lv_category_err_tk := 'Sales Invoices';
      END IF;
      IF ov_trade_receipts IS NULL THEN
        lv_category_err_tk := 'Trade Receipts';
      END IF;
      IF ov_adjustment IS NULL THEN
        lv_category_err_tk := 'Adjustment';
      END IF;
      IF ov_credit_memos IS NULL THEN
        lv_category_err_tk := 'Credit Memos';
      END IF;
      IF ov_credit_memo_applications IS NULL THEN
        lv_category_err_tk := 'Credit Memo Applications';
      END IF;
      IF ov_cross_currency IS NULL THEN
        lv_category_err_tk := 'Cross Currency';
      END IF;
      -- Ver11.5.10.1.6 2005/12/15 Delete Start
      -- --20040512 XX03_TAX_CODES_V(NAME) 追加 START
      --  IF ov_xx03_tax_code IS NULL THEN
      --    lv_category_err_tk := 'ov_xx03_tax_codes_v';
      --  END IF;
      -- --20040512 XX03_TAX_CODES_V(NAME) 追加 END
      -- Ver11.5.10.1.6 2005/12/15 Delete End
      -- エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-07003'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-03082',
        'TOK_XX03_LOOKUP_TYPE',
        lv_category_err_tk);  -- 未取得仕訳カテゴリ名
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_id;

  /**********************************************************************************
   * Procedure Name   : upd_journal_data
   * Description      : 仕訳データの更新処理 (A8)
   ***********************************************************************************/
  -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
  PROCEDURE upd_journal_data(
    ir_rowid                IN ROWID,      -- 1.ROWID(IN)
    iv_je_source            IN VARCHAR2,   -- 2.仕訳ソース名(IN)
    iv_je_name              IN VARCHAR2,   -- 3.仕訳名(IN)
    iv_group_id             IN NUMBER,     -- 4.仕訳名(IN)
    iv_context_name         IN VARCHAR2,   -- 5.会計帳簿(コンテキスト)名(IN)
    iv_trx_number           IN VARCHAR2,   -- 6.請求書番号(IN)
    iv_doc_sequence_value   IN VARCHAR2,   -- 7.請求書文書番号(IN)
    iv_rcta_attribut5       IN VARCHAR2,   -- 8.起票部門(IN)
    iv_rcta_attribut6       IN VARCHAR2,   -- 9.入力者(IN)
    iv_avta_tax_code        IN VARCHAR2,   -- 10.税コード(IN)
    iv_line_attribute1_1    IN VARCHAR2,   -- 11.増減事由(IN)
    iv_line_attribute2_1    IN VARCHAR2,   -- 12.消込参照(IN)
    iv_descripion           IN VARCHAR2,   -- 13.明細摘要/注釈(IN)
    iv_attribute6           IN VARCHAR2,   -- 14.修正元伝票番号(IN)
    iv_attribute9           IN VARCHAR2,   -- 15,予備１(IN)
    iv_attribute10          IN VARCHAR2,   -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
    iv_rctlda_attribute11   IN VARCHAR2,   -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
    ov_errbuf               OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_journal_data'; -- プログラム名
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
    ln_group_id   gl_interface.group_id%TYPE; -- GLインターフェースグループID
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
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('upd_journal_data');
--
    --GLインターフェース更新処理
    -- 20050131 V1.5 予備１・予備２の追加
    UPDATE gl_interface
    SET    group_id    = iv_group_id,             -- グループID
           context     = iv_context_name,         -- コンテキスト（会計帳簿名）
           reference4  = iv_doc_sequence_value,   -- 仕訳名
           reference10 = iv_descripion,           -- 明細摘要
           jgzz_recon_ref = iv_line_attribute2_1, -- 消込参照
           attribute1  = iv_avta_tax_code,        -- 税コード
           attribute2  = iv_line_attribute1_1,    -- 増減事由
           attribute3  = iv_trx_number,           -- 伝票番号（請求書番号）
           attribute4  = iv_rcta_attribut5,       -- 起票部門
           attribute5  = iv_rcta_attribut6,       -- 入力者
           attribute6  = iv_attribute6,           -- 修正元伝票番号（請求書文書番号）
           attribute9  = iv_attribute9,           -- 予備１
           attribute10 = iv_attribute10           -- 予備２
-- ver 11.5.10.2.4 Add Start
          ,attribute15 = iv_rctlda_attribute11    -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
    WHERE  ROWID = ir_rowid;
-- 20050131 V1.5 END
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_journal_data;
--
-- 20040512 GL_INTERFACE 税区分（NULL）データの対応 START
-- GL_INTERFACE（売掛管理レコードに対する付加情報更新後に税区分（NULL）データに対し
-- XX03_TAX_CODES_VテーブルのATTRIBUTE1 = NULL 条件のNAME項目を取得し税区分にセット
  /**********************************************************************************
   * Procedure Name   : upd_journal_data_1
   * Description      : 仕訳データの更新処理 税区分（NULL）データ対応(A8_1)
   ***********************************************************************************/
  PROCEDURE upd_journal_data_1(
    lv_xx03_tax_code        IN VARCHAR2,     -- 1.xx03_tax_code(IN)
    lv_journal_source       IN VARCHAR2,     -- 2.仕訳ソース名(IN)
    ov_errbuf               OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_journal_data_1'; -- プログラム名
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
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('upd_journal_data_1');
--
    --GLインターフェース更新処理
    UPDATE gl_interface
    SET    attribute1  = lv_xx03_tax_code        -- 税コード
    WHERE   user_je_source_name =  lv_journal_source        -- 仕訳ソース名
    AND     status ='NEW'
    AND     actual_flag = 'A'
    AND     attribute1  IS NULL; 
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END upd_journal_data_1;
-- 20040512 GL_INTERFACE 税区分（NULL）データの対応 END
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_1
   * Description      : DFF付加対象データ抽出処理 [Sales Invoices] (A2)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_1(
    in_gl_book_id           IN NUMBER,       -- 1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       -- 2.オルグID(IN)
    lv_sales_invoices       IN VARCHAR2,     -- 3.仕訳カテゴリ名(売上請求書)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    ln_sales_invoices_cnt   IN OUT NUMBER,   -- 5.仕訳カテゴリ別件数(売上請求書)(OUT)
    lv_group_id             IN NUMBER,       -- 6.グループID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_1'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE;   -- コンテキスト値
    lv_A2_flg                         VARCHAR2(1);     -- 前受金請求書判定
    lv_type                           VARCHAR2(20);    -- タイプ
    lv_line_attribute1_1              VARCHAR2(150);   -- 増減事由
    lv_line_attribute2_1              VARCHAR2(150);   -- 消込参照
    lv_vat_tax_id                     NUMBER(15);      -- 税ID
    lv_descripion                     VARCHAR2(240);   -- 明細摘要
    lv_line_customer_trx_line_id_1    NUMBER(15);      -- 請求書明細ID
    lv_avta_tax_code                  VARCHAR2(50);    -- 税コード
-- 20050131 V1.5 START
    lv_line_attribute9_1              VARCHAR2(150);   -- 予備１
    lv_line_attribute10_1             VARCHAR2(150);   -- 予備２
-- 20050131 V1.5 END
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    -- 20040519 条件追加 V1.3 会計帳簿帳簿ID
    CURSOR gl_add_dff_data_cur_1
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- 仕訳カテゴリ-仕訳カテゴリ
              gi.reference22 AS invoice_id,                      -- 請求書ID
              gi.reference23 AS distribution_line_number,        -- 請求書明細番号/支払ID
              gi.reference29 AS payment_id,                      -- 明細仕訳タイプ
              gi.group_id AS group_id ,                          -- パラメータグループID
              gi.context AS context ,                            -- 会計帳簿名
              gi.reference4 AS reference4,                       -- 抽出済ＧＬ仕訳単位
              gi.reference10 AS reference10,                     -- 抽出済明細概要
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- 抽出済消込参照
              gi.attribute1 AS attribute1,                       -- 抽出済税区分
              gi.attribute2 AS attribute2,                       -- 抽出済増減事由
              gi.attribute3 AS attribute3,                       -- 抽出済伝票番号
              gi.attribute4 AS attribute4,                       -- 抽出済起票部門
              gi.attribute5 AS attribute5,                       -- 抽出済入力者
              gi.attribute6 AS attribute6,                       -- 抽出済修正元伝票番号
              rcta.trx_number AS trx_number,                     -- 請求書番号
              rcta.doc_sequence_value AS doc_sequence_value,     -- 請求書文書番号
              rcta.attribute5 AS rcta_attribut5,                 -- 起票部門
              rcta.attribute6 AS rcta_attribut6,                 -- 入力者
              rcta.previous_customer_trx_id AS previous_customer_trx_id, --親請求書ＩＤ
              rcta.cust_trx_type_id AS cust_trx_type_id,         -- 請求書タイプＩＤ
              rcta.comments AS comments                          -- 注釈
-- ver 11.5.10.2.4 Add Start
             ,rctlda.attribute11 AS rctlda_attribute11           -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                              -- GLインターフェーステーブル
              ra_customer_trx_all rcta                           -- 請求書ヘッダテーブル
-- ver 11.5.10.2.4 Add Start
             ,ra_cust_trx_line_gl_dist_all rctlda                -- 請求書明細会計情報
-- ver 11.5.10.2.4 Add End
      WHERE   gi.user_je_source_name =  lv_journal_source        -- 仕訳ソース名
      AND     gi.user_je_category_name = lv_sales_invoices       -- 仕訳カテゴリ名(売上請求書)
      AND     rcta.customer_trx_id = gi.reference22
-- ver 11.5.10.2.4 Add Start
      AND     rctlda.cust_trx_line_gl_dist_id(+) = gi.reference23
-- ver 11.5.10.2.4 Add End
      AND     gi.status ='NEW'
      AND     gi.actual_flag = 'A'
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      AND     (gi.reference29 in ('INV_REC','INV_REV','INV_TAX'))
      ORDER BY gi.reference22,gi.reference23  ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec_1 gl_add_dff_data_cur_1%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('upd_journal_data');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_sales_invoices);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
      lv_retcode,                    -- リターン・コード             --# 固定 #
      lv_errmsg,                     -- ユーザー・エラー・メッセージ --# 固定 #
      lv_context_name,               -- 会計帳簿名
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --共通エラー処理
      RAISE global_process_expt;
    END IF;
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur_1;
    <<interface_loop>>
    LOOP
      FETCH gl_add_dff_data_cur_1 INTO gl_add_dff_data_rec_1;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur_1%NOTFOUND THEN
          EXIT interface_loop;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_1.user_je_category_name);

      lv_A2_flg := '0';                                   -- 前受金請求書判定初期値
      lv_line_attribute1_1 := '';                         -- 増減事由初期値
      lv_line_attribute2_1 := '';                         -- 消込参照初期値
      lv_descripion := '';                                -- 明細摘要初期値
      lv_avta_tax_code := '';                             -- 税コード初期値
      lv_descripion := gl_add_dff_data_rec_1.reference10; -- 明細摘要セット初期値
-- 20050131 V1.5 START
      lv_line_attribute9_1 := '';                         -- 予備１初期値
      lv_line_attribute10_1 := '';                        -- 予備２初期値
-- 20050131 V1.5 END

      -- ==========================================================
      -- 前受金請求書判定および注釈取得処理 [Sales Invoices](A2-1)
      -- ==========================================================
      -- 明細仕訳タイプの判断
      IF gl_add_dff_data_rec_1.payment_id = 'INV_REC' OR 
         gl_add_dff_data_rec_1.payment_id = 'INV_REV' THEN
        get_trx_type_1(
            gl_add_dff_data_rec_1.cust_trx_type_id,       -- 請求書タイプID(IN)
            lv_type,                                      -- 請求書タイプ(OUT)
            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
            lv_retcode,                    -- リターン・コード             --# 固定 #
            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --ユーザーエラー処理
              RAISE warning_status_expt;
            END IF;
          END IF;
          --前受金請求書チェック処理
          IF lv_type = 'DEP' THEN
              lv_A2_flg := '1';                                   -- 前受金請求書判定あり
             --明細摘要項目へ注釈セット処理
             lv_descripion := gl_add_dff_data_rec_1.reference10;  -- 明細摘要セット初期値
             IF gl_add_dff_data_rec_1.payment_id = 'INV_REV' THEN -- 'INV_REV'の場合
                lv_descripion := gl_add_dff_data_rec_1.comments;  -- 明細摘要セット
             END IF;
          END IF;
      END IF;
    -- ====================================================
    -- 請求書明細会計情報取得処理１ [Sales Invoices](A2-2)
    -- ====================================================
      IF lv_A2_flg = '0' THEN
        IF gl_add_dff_data_rec_1.payment_id = 'INV_REV' OR 
           gl_add_dff_data_rec_1.payment_id = 'INV_TAX' THEN
          -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
          get_add_dff_lines_data_1(
            gl_add_dff_data_rec_1.distribution_line_number, --請求書明細番号/支払ID(IN)
            lv_line_attribute1_1,                           -- 増減事由(OUT)
            lv_line_attribute2_1,                           -- 消込参照(OUT)
            lv_line_customer_trx_line_id_1,                 -- 請求書明細ID(OUT)
            lv_line_attribute9_1,                           -- 予備１(OUT)
            lv_line_attribute10_1,                          -- 予備２(OUT)
            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
            lv_retcode,                    -- リターン・コード             --# 固定 #
            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                --共通エラー処理
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --ユーザーエラー処理
                RAISE warning_status_expt;
              END IF;
            END IF;
        -- ====================================================
        -- 請求書明細会計情報取得処理２ [Sales Invoices](A2-3)
        -- ====================================================
            get_ra_cus_trx_lines_all_1(
              lv_line_customer_trx_line_id_1, -- 請求書明細ID(IN)
              lv_vat_tax_id,                  -- 税ID(OUT)
              lv_descripion,                  -- 明細摘要(OUT)
              lv_errbuf,                      -- エラー・メッセージ          --# 固定 #
              lv_retcode,                     -- リターン・コード             --# 固定 #
              lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
                IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                  --共通エラー処理
                  RAISE global_process_expt;
                ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                  --ユーザーエラー処理
                  RAISE warning_status_expt;
                END IF;
              END IF;
             --明細摘要項目へ注釈セット処理
             IF gl_add_dff_data_rec_1.payment_id <> 'INV_REV' THEN  -- 'INV_REV'以外の場合
                lv_descripion := gl_add_dff_data_rec_1.reference10; -- 明細摘要セット初期値
             END IF;
        -- =================================================
        -- AR税テーブル情報取得処理 [Sales Invoices](A2-4)
        -- =================================================
-- 2004/05/12 データNOT FOUND 時の対応（データ対応）
             lv_avta_tax_code := lv_xx03_tax_code;
             IF lv_vat_tax_id IS NOT NULL THEN
               get_ar_vat_tax_all_1(
               lv_vat_tax_id,                 -- 税ID(IN)
               lv_avta_tax_code,              -- 税コード(OUT)
               lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
               lv_retcode,                    -- リターン・コード             --# 固定 #
               lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
               IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
                 IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                   --共通エラー処理
                   RAISE global_process_expt;
                 ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                   --ユーザーエラー処理
                   RAISE warning_status_expt;
                 END IF;
               END IF;
             END IF;
        END IF;
      END IF;
        -- ===================================
        -- 仕訳データの更新処理 (A8)
        -- ===================================
        -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
        upd_journal_data(
          gl_add_dff_data_rec_1.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.仕訳ソース名(IN)
          gl_add_dff_data_rec_1.user_je_category_name, -- 3.仕訳名(IN)
          lv_group_id,                                 -- 4.グループID(IN)
          lv_context_name,                             -- 5.会計帳簿名(IN)
          gl_add_dff_data_rec_1.trx_number,            -- 6.伝票番号(IN)
          gl_add_dff_data_rec_1.doc_sequence_value,    -- 7.請求書文書番号(IN)
          gl_add_dff_data_rec_1.rcta_attribut5,        -- 8.起票部門(IN)
          gl_add_dff_data_rec_1.rcta_attribut6,        -- 9.入力者(IN)
          lv_avta_tax_code,                            -- 10.税コード(IN)
          lv_line_attribute1_1,                        -- 11.増減事由(IN)
          lv_line_attribute2_1,                        -- 12.消込参照(IN)
          lv_descripion,                               -- 13.明細摘要(IN)
          gl_add_dff_data_rec_1.attribute6,            -- 14.修正元伝票番号(IN)
          lv_line_attribute9_1,                        -- 15.予備１(IN)
          lv_line_attribute10_1,                       -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_1.rctlda_attribute11,    -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
          lv_retcode,                           -- リターン・コード             --# 固定 #
          lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --共通エラー処理
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --ユーザーエラー処理
            RAISE warning_status_expt;
          END IF;
        END IF;
        ln_sales_invoices_cnt := ln_sales_invoices_cnt + 1; -- 仕入請求書DFF処理件数の計上
--
    END LOOP interface_loop;
    --ログ出力
    CLOSE gl_add_dff_data_cur_1;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_add_dff_data_1;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_2
   * Description      : DFF付加対象データ抽出処理 [Credit Memo] (A3)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_2(
    in_gl_book_id           IN NUMBER,       -- 1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       -- 2.オルグID(IN)
    lv_credit_memos         IN VARCHAR2,     -- 3.仕訳カテゴリ名(クレジットメモ)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    ln_credit_memos_cnt     IN OUT NUMBER,   -- 5.仕訳カテゴリ別件数(クレジットメモ)(OUT)
    lv_group_id             IN NUMBER,       -- 6.グループID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_2'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE; -- コンテキスト値
    lv_A3_flg  VARCHAR2(1);                          -- 判定フラグ
    lv_trx_number         VARCHAR2(20);              -- 請求書番号
    lv_line_attribute1_2  VARCHAR2(150);             -- 増減事由
    lv_line_attribute2_2  VARCHAR2(150);             -- 消込参照
    lv_vat_tax_id_2       NUMBER(15);                -- 税ID
    lv_descripion_2       VARCHAR2(240);             -- 明細摘要
    lv_line_customer_trx_line_id_2 NUMBER(15);       -- 請求書明細ID
    lv_avta_tax_code_2    VARCHAR2(50);              -- 税コード
    lv_vat_tax_id         NUMBER(15);                -- 税ID2
-- 20050131 V1.5 START
    lv_line_attribute9_2  VARCHAR2(150);   -- 予備１
    lv_line_attribute10_2 VARCHAR2(150);   -- 予備２
-- 20050131 V1.5 END
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    -- 20040519 条件追加 V1.3 会計帳簿帳簿ID
    CURSOR gl_add_dff_data_cur_2
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- 仕訳カテゴリ-仕訳カテゴリ
              gi.reference22 AS invoice_id,                      -- 請求書ID
-- 20050307 V1.6 START
              rctla.customer_trx_line_id AS customer_trx_line_id,-- 請求書明細ID
-- 20050307 V1.6 END
              gi.reference23 AS distribution_line_number,        -- 請求書配分ID
              gi.reference29 AS payment_id,                      -- 明細仕訳タイプ
              gi.group_id AS group_id ,                          -- パラメータグループID
              gi.context AS context ,                            -- 会計帳簿名
              gi.reference4 AS reference4,                       -- 抽出済ＧＬ仕訳単位
              gi.reference10 AS reference10,                     -- 抽出済明細概要
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- 抽出済消込参照
              gi.attribute1 AS attribute1,                       -- 抽出済税区分
              gi.attribute2 AS attribute2,                       -- 抽出済増減事由
              gi.attribute3 AS attribute3,                       -- 抽出済伝票番号
              gi.attribute4 AS attribute4,                       -- 抽出済起票部門
              gi.attribute5 AS attribute5,                       -- 抽出済入力者
              gi.attribute6 AS attribute6,                       -- 抽出済修正元伝票番号
              rcta.trx_number AS trx_number,                     -- 請求書番号
              rcta.doc_sequence_value AS doc_sequence_value,     -- 請求書文書番号
              rcta.attribute5 AS rcta_attribut5,                 -- 起票部門
              rcta.attribute6 AS rcta_attribut6,                 -- 入力者
              rcta.previous_customer_trx_id AS previous_customer_trx_id, --親請求書ＩＤ
-- 20050307 V1.6 START
              rctla.previous_customer_trx_line_id AS previous_customer_trx_line_id, --親請求書明細ID
-- 20050307 V1.6 END
              rcta.cust_trx_type_id AS cust_trx_type_id,         -- 請求書タイプＩＤ
              rcta.comments AS comments                          -- 注釈
-- ver 11.5.10.2.4 Add Start
             ,rctlda_p.attribute11 AS rctlda_attribute11         -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                                   -- GLインターフェーステーブル
              ra_customer_trx_all rcta,                          -- 請求書ヘッダテーブル
-- 20050307 V1.6 START
              ra_customer_trx_lines_all rctla,                   -- 請求書明細テーブル
              ra_cust_trx_line_gl_dist_all rctlda                -- 請求書明細GL配分テーブル
-- 20050307 V1.6 END
-- ver 11.5.10.2.4 Add Start
             ,(SELECT rcta2.customer_trx_id     AS customer_trx_id
                     ,MAX(rctlda2.attribute11)  AS attribute11
               FROM   ra_customer_trx_all          rcta2        -- 請求書ヘッダテーブル(親)
                     ,ra_cust_trx_line_gl_dist_all rctlda2      -- 請求書明細GL配分テーブル(親)
               WHERE  rcta2.customer_trx_id = rctlda2.customer_trx_id
               GROUP BY rcta2.customer_trx_id
              ) rctlda_p
-- ver 11.5.10.2.4 Add End
      WHERE   gi.user_je_source_name =  lv_journal_source        -- 仕訳ソース名
      AND     gi.user_je_category_name = lv_credit_memos         -- 仕訳カテゴリ名(クレジットメモ)
      AND     rcta.customer_trx_id = gi.reference22
      AND     gi.status ='NEW'     
      AND     gi.actual_flag = 'A'
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      AND     (gi.reference29 in ('CM_REC','CM_REV','CM_TAX'))
-- 20050307 V1.6 START
      AND     rctlda.cust_trx_line_gl_dist_id = gi.reference23
      AND     rctla.customer_trx_line_id(+) = rctlda.customer_trx_line_id
-- 20050307 V1.6 END
-- ver 11.5.10.2.4 Add Start
      AND     rcta.previous_customer_trx_id = rctlda_p.customer_trx_id(+)
-- ver 11.5.10.2.4 Add End
      ORDER BY gi.reference22,gi.reference23  ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec_2 gl_add_dff_data_cur_2%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_1');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_credit_memos);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
      lv_retcode,                    -- リターン・コード             --# 固定 #
      lv_errmsg,                     -- ユーザー・エラー・メッセージ --# 固定 #
      lv_context_name,               -- 会計帳簿名
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --共通エラー処理
      RAISE global_process_expt;
    END IF;
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur_2;
    <<interface_loop_2>>
    LOOP
      FETCH gl_add_dff_data_cur_2 INTO gl_add_dff_data_rec_2;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur_2%NOTFOUND THEN
          EXIT interface_loop_2;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_2.user_je_category_name);

      lv_A3_flg := '0';                                   -- 前受金請求書判定初期値
-- 20050131 V1.5 START
      lv_line_attribute9_2 := '';                         -- 予備１初期値
      lv_line_attribute10_2 := '';                        -- 予備２初期値
-- 20050131 V1.5 END
      -- ==========================================================
      -- 割当済請求書番号の取得処理 [Credit Memo](A3-1)
      -- ==========================================================
      IF gl_add_dff_data_rec_2.previous_customer_trx_id IS  NULL THEN
        lv_trx_number := gl_add_dff_data_rec_2.previous_customer_trx_id;
      ELSE
        get_trx_number(
            gl_add_dff_data_rec_2.previous_customer_trx_id,   -- 親請求書ＩＤ(IN)
            lv_trx_number,                 -- 親請求書番号(OUT)
            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
            lv_retcode,                    -- リターン・コード             --# 固定 #
            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --共通エラー処理
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --ユーザーエラー処理
            RAISE warning_status_expt;
          END IF;
        END IF;
      END IF;
      lv_A3_flg := '1';                                   -- 判定あり
    -- ====================================================
    -- 請求書明細会計情報取得処理１ [Credit Memo](A3-2)
    -- ====================================================
      IF gl_add_dff_data_rec_2.payment_id = 'CM_REV' OR 
         gl_add_dff_data_rec_2.payment_id = 'CM_TAX' THEN
-- 20050307 V1.6 START
--Ver11.5.10.1.3 2005/05/17 Modify START
      --親請求書IDがNULLの場合はプロシージャを呼ばずに各変数にnullを挿入
        IF gl_add_dff_data_rec_2.previous_customer_trx_line_id IS NOT NULL THEN
--Ver11.5.10.1.3 2005/05/17 Modify END
          get_cust_trx_line_gl_dist_dff(
            gl_add_dff_data_rec_2.previous_customer_trx_line_id, -- 参照先請求書明細ID(IN)
            lv_line_attribute1_2,                           -- 増減事由(OUT)
            lv_line_attribute2_2,                           -- 消込参照(OUT)
            lv_line_attribute9_2,                           -- 予備１(OUT)
            lv_line_attribute10_2,                          -- 予備２(OUT)
            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
            lv_retcode,                    -- リターン・コード             --# 固定 #
            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--        get_add_dff_lines_data_2(
--          gl_add_dff_data_rec_2.distribution_line_number, -- 請求書配分ID(IN)
--          lv_line_attribute1_2,                           -- 増減事由(OUT)
--          lv_line_attribute2_2,                           -- 消込参照(OUT)
--          lv_line_customer_trx_line_id_2,                 -- 請求書明細ID(OUT)
--          lv_line_attribute9_2,                           -- 予備１(OUT)
--          lv_line_attribute10_2,                          -- 予備２(OUT)
--          lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
--          lv_retcode,                    -- リターン・コード             --# 固定 #
--          lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
-- 20050307 V1.6 END
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --ユーザーエラー処理
              RAISE warning_status_expt;
            END IF;
          END IF;
--Ver11.5.10.1.3 2005/05/17 Add START
        ELSE
          lv_line_attribute1_2  := NULL;                          -- 増減事由(OUT)
          lv_line_attribute2_2  := NULL;                          -- 消込参照(OUT)
          lv_line_attribute9_2  := NULL;                          -- 予備１(OUT)
          lv_line_attribute10_2 := NULL;                          -- 予備２(OUT)
        END IF;
--Ver11.5.10.1.3 2005/05/17 Add END
        -- ====================================================
        -- 請求書明細会計情報取得処理２ [Credit Memo](A3-3)
        -- ====================================================
        get_ra_cus_trx_lines_all_2(
-- 20050307 V1.6 START
          gl_add_dff_data_rec_2.customer_trx_line_id, -- 請求書明細ID(IN)
--          lv_line_customer_trx_line_id_2, -- 請求書明細ID(IN)
-- 20050307 V1.6 END
          lv_vat_tax_id_2,                -- 税ID(OUT)
          lv_descripion_2,                -- 明細摘要(OUT)
          lv_errbuf,                      -- エラー・メッセージ           --# 固定 #
          lv_retcode,                     -- リターン・コード             --# 固定 #
          lv_errmsg);                     -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --ユーザーエラー処理
              RAISE warning_status_expt;
            END IF;
          END IF;
          --明細摘要項目へ初期値セット処理
          IF gl_add_dff_data_rec_2.payment_id <> 'CM_REV' THEN
            lv_descripion_2 := gl_add_dff_data_rec_2.reference10; -- 明細摘要セット初期値
          END IF;
        -- =================================================
        -- AR税テーブル情報取得処理 [Credit Memo](A3-4)
        -- =================================================
-- 2004/05/12 データNOT FOUND 時の対応（データ対応）
          lv_avta_tax_code_2 := lv_xx03_tax_code;
          IF lv_vat_tax_id_2 IS NOT NULL THEN
           get_ar_vat_tax_all_2(
             lv_vat_tax_id_2,               -- 税ID(IN)
             lv_avta_tax_code_2,            -- 税コード(OUT)
             lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
             lv_retcode,                    -- リターン・コード             --# 固定 #
             lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
             IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
               IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                 --共通エラー処理
                 RAISE global_process_expt;
               ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                 --ユーザーエラー処理
                 RAISE warning_status_expt;
               END IF;
             END IF;
          END IF;
      ELSE
          --'CM_REC' の場合
          lv_avta_tax_code_2   := gl_add_dff_data_rec_2.attribute1;     -- 税コード
          lv_line_attribute1_2 := gl_add_dff_data_rec_2.attribute2;     -- 増減事由
          lv_line_attribute2_2 := gl_add_dff_data_rec_2.jgzz_recon_ref; -- 消込参照
          lv_descripion_2      := gl_add_dff_data_rec_2.reference10;    -- 明細摘要
      END IF;
        -- ===================================
        -- 仕訳データの更新処理 (A8)
        -- ===================================
          -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
          upd_journal_data(
          gl_add_dff_data_rec_2.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.仕訳ソース名(IN)
          gl_add_dff_data_rec_2.user_je_category_name, -- 3.仕訳名(IN)
          lv_group_id,                                 -- 4.グループID(IN)
          lv_context_name,                             -- 5.会計帳簿名(IN)
          gl_add_dff_data_rec_2.trx_number,            -- 6.伝票番号(IN)
          gl_add_dff_data_rec_2.doc_sequence_value,    -- 7.請求書文書番号(IN)
          gl_add_dff_data_rec_2.rcta_attribut5,        -- 8.起票部門(IN)
          gl_add_dff_data_rec_2.rcta_attribut6,        -- 9.入力者(IN)
          lv_avta_tax_code_2,                          -- 10.税コード(IN)
          lv_line_attribute1_2,                        -- 11.増減事由(IN)
          lv_line_attribute2_2,                        -- 12.消込参照(IN)
          lv_descripion_2,                             -- 13.明細摘要(IN)
          lv_trx_number,                               -- 14.参照元伝票番号(IN)
          lv_line_attribute9_2,                        -- 15.予備１(IN)
          lv_line_attribute10_2,                       -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_2.rctlda_attribute11,    -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
          lv_retcode,                           -- リターン・コード             --# 固定 #
          lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --ユーザーエラー処理
              RAISE warning_status_expt;
            END IF;
          END IF;
          ln_credit_memos_cnt := ln_credit_memos_cnt + 1; -- カテゴリ別件数(クレジットメモ)計上
--
    END LOOP interface_loop_2;
    --ログ出力
    CLOSE gl_add_dff_data_cur_2;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_add_dff_data_2;
--
--##############################################################################################
------------------------------------------- A4 START -------------------------------------------
--##############################################################################################
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_3
   * Description      : DFF付加対象データ抽出処理 [CM Applications] (A4)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_3(
    in_gl_book_id           IN NUMBER,       -- 1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       -- 2.オルグID(IN)
    lv_credit_memo_applications IN VARCHAR2, -- 3.仕訳カテゴリ名(クレジットメモ取消)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    ln_credit_memo_app_cnt  IN OUT NUMBER,   -- 5.仕訳カテゴリ別件数(クレジットメモ取消)(OUT)
    lv_group_id             IN NUMBER,       -- 6.グループID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_3'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE;   -- コンテキスト値
    lv_A4_flg  VARCHAR2(1);                       -- 判定フラグ
-- 20050131 V1.5 START
    lv_line_attribute9_3   VARCHAR2(150);   -- 予備１
    lv_line_attribute10_3  VARCHAR2(150);   -- 予備２
-- 20050131 V1.5 END
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    -- 20040519 条件追加 V1.3 会計帳簿帳簿ID
    CURSOR gl_add_dff_data_cur_3
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- 仕訳カテゴリ-仕訳カテゴリ
              gi.reference22 AS invoice_id,                      -- 請求書ID
              gi.reference23 AS distribution_line_number,        -- 請求書明細番号/支払ID
              gi.reference24 AS reference24,                     -- 伝票番号
              gi.reference29 AS payment_id,                      -- 明細仕訳タイプ
              gi.group_id AS group_id ,                          -- パラメータグループID
              gi.context AS context ,                            -- 会計帳簿名
              gi.reference4 AS reference4,                       -- 抽出済ＧＬ仕訳単位
              gi.reference10 AS reference10,                     -- 抽出済明細概要
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- 抽出済消込参照
              gi.attribute1 AS attribute1,                       -- 抽出済税区分
              gi.attribute2 AS attribute2,                       -- 抽出済増減事由
              gi.attribute3 AS attribute3,                       -- 抽出済伝票番号
              gi.attribute4 AS attribute4,                       -- 抽出済起票部門
              gi.attribute5 AS attribute5,                       -- 抽出済入力者
              gi.attribute6 AS attribute6,                       -- 抽出済修正元伝票番号
              rcta.trx_number AS trx_number,                     -- 請求書番号
              rcta.doc_sequence_value AS doc_sequence_value,     -- 請求書文書番号
              rcta.attribute5 AS rcta_attribut5,                 -- 起票部門
              rcta.attribute6 AS rcta_attribut6,                 -- 入力者
              rcta.previous_customer_trx_id AS previous_customer_trx_id, -- 親請求書ＩＤ
              rcta.cust_trx_type_id AS cust_trx_type_id,         -- 請求書タイプＩＤ
              rcta.comments AS comments                          -- 注釈
-- ver 11.5.10.2.4 Add Start
             ,gi.attribute15 AS attribute15                      -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                              -- GLインターフェーステーブル
              ra_customer_trx_all rcta                           -- 請求書ヘッダテーブル
      WHERE   gi.user_je_source_name =  lv_journal_source        -- 仕訳ソース名
      AND     gi.user_je_category_name = lv_credit_memo_applications -- 仕訳カテゴリ名(ＣＭ取消)
      AND     rcta.trx_number = gi.reference24              
      AND     gi.status ='NEW'                                       
      AND     gi.actual_flag = 'A'                                   
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      -- ver 11.5.10.2.3 Add Start
      AND     rcta.set_of_books_id = in_gl_book_id
      -- ver 11.5.10.2.3 Add End
      AND     (gi.reference29 in ('CMAPP_REC','CMAPP_APP'))
      ORDER BY gi.reference22,gi.reference23  ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec_3 gl_add_dff_data_cur_3%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_3');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_credit_memo_applications);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
      lv_retcode,                    -- リターン・コード             --# 固定 #
      lv_errmsg,                     -- ユーザー・エラー・メッセージ --# 固定 #
      lv_context_name,               -- 会計帳簿名
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --共通エラー処理
      RAISE global_process_expt;
    END IF;
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur_3;
    <<interface_loop_3>>
    LOOP
      FETCH gl_add_dff_data_cur_3 INTO gl_add_dff_data_rec_3;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur_3%NOTFOUND THEN
          EXIT interface_loop_3;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_3.user_je_category_name);

      lv_A4_flg := '0';                                   -- 前受金請求書判定初期値
-- 20050131 V1.5 START
      lv_line_attribute9_3 := '';                         -- 予備１初期値
      lv_line_attribute10_3 := '';                        -- 予備２初期値
-- 20050131 V1.5 END
      -- ===================================
      -- 仕訳データの更新処理 (A8)
      -- ===================================
      -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
      upd_journal_data(
          gl_add_dff_data_rec_3.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.仕訳ソース名(IN)
          gl_add_dff_data_rec_3.user_je_category_name, -- 3.仕訳名(IN)
          lv_group_id,                                 -- 4.グループID(IN)
          lv_context_name,                             -- 5.会計帳簿名(IN)
          gl_add_dff_data_rec_3.trx_number,            -- 6.伝票番号(IN)
          gl_add_dff_data_rec_3.doc_sequence_value,    -- 7.修正元伝票番号(IN)
          gl_add_dff_data_rec_3.rcta_attribut5,        -- 8.起票部門(IN)
          gl_add_dff_data_rec_3.rcta_attribut6,        -- 9.入力者(IN)
          gl_add_dff_data_rec_3.attribute1,            -- 10.税コード(IN)
          gl_add_dff_data_rec_3.attribute2,            -- 11.増減事由(IN)
          gl_add_dff_data_rec_3.jgzz_recon_ref,        -- 12.消込参照(IN)
          gl_add_dff_data_rec_3.reference10,           -- 13.明細摘要(IN)
          gl_add_dff_data_rec_3.attribute6,            -- 14.修正元伝票番号(IN)
          lv_line_attribute9_3,                        -- 15.予備１(IN)
          lv_line_attribute10_3,                       -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_3.attribute15,           -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
          lv_retcode,                           -- リターン・コード             --# 固定 #
          lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --共通エラー処理
          RAISE global_process_expt;
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ユーザーエラー処理
          RAISE warning_status_expt;
        END IF;
      END IF;
      ln_credit_memo_app_cnt := ln_credit_memo_app_cnt + 1; -- カテゴリ別件数(CM取消)計上
--
    END LOOP interface_loop_3;
    --ログ出力
    CLOSE gl_add_dff_data_cur_3;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_add_dff_data_3;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_4
   * Description      : DFF付加対象データ抽出処理 [adjustment] (A5)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_4(
    in_gl_book_id           IN NUMBER,       -- 1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       -- 2.オルグID(IN)
    lv_adjustment           IN VARCHAR2,     -- 3.仕訳カテゴリ名(修正)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    ln_adjustment_cnt       IN OUT NUMBER,   -- 5.仕訳カテゴリ別件数(修正)(OUT)
    lv_group_id             IN NUMBER,       -- 6.グループID(IN)
    lv_xx03_tax_code        IN VARCHAR2,     -- 7.xx03_tax_code(IN)
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_4'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE;  -- コンテキスト値
    lv_A5_flg      VARCHAR2(1);                       -- 判定フラグ
    lv_trx_number  VARCHAR2(20);                      -- 前受金請求書判定
    lv_attribute5  VARCHAR2(150);                     -- 起票部門(OUT)
    lv_attribute6  VARCHAR2(150);                     -- 入力者(OUT)
    lv_initial_customer_trx_id   NUMBER(15);          -- 取引約定(OUT)
    lv_cust_trx_type_id   NUMBER(15);                 -- 前受金請求書判定
    lv_type        VARCHAR2(20);                      -- タイプ(OUT)
    lv_tax_code    VARCHAR2(50);                      -- 税コード(OUT)
    lv_flg_1       VARCHAR2(1) := '0';                -- 判定FLG_1
    lv_flg_2       VARCHAR2(1) := '0';                -- 判定FLG_2
    lv_flg_3       VARCHAR2(1) := '0';                -- 判定FLG_3

    lv_out_tax_code    VARCHAR2(50);                  -- 税コード
    lv_out_attribute1  VARCHAR2(150);                 -- 増減事由
    lv_out_attribute5  VARCHAR2(150);                 -- 起票部門
    lv_out_attribute6  VARCHAR2(150);                 -- 入力者
    lv_out_attribute2  VARCHAR2(150);                 -- 消込参照
    lv_out_comments    VARCHAR2(150);                 -- 明細摘要
-- 20050131 V1.5 START
    lv_out_attribute9  VARCHAR2(150);                 -- 予備１
    lv_out_attribute10 VARCHAR2(150);                 -- 予備２
-- 20050131 V1.5 END
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    -- 20040519 条件追加 V1.3 会計帳簿帳簿ID
    -- 20050131 V1.5 仕訳修正（予備１・予備２）の追加
    --               仕訳修正（消込参照）の変更（attribute6 ⇒ attribute2）
    CURSOR gl_add_dff_data_cur_4
    IS
      SELECT  gi.rowid AS row_id,                                -- ROWID
              gi.user_je_category_name AS user_je_category_name, -- 仕訳カテゴリ
              gi.reference22 AS invoice_id,                      -- 請求書ID
              gi.reference23 AS distribution_line_number,        -- 請求書明細番号/支払ID
              gi.reference29 AS payment_id,                      -- 明細仕訳タイプ
              gi.group_id AS group_id,                           -- パラメータグループID
              gi.context AS context,                             -- 会計帳簿名
              gi.reference4 AS reference4,                       -- 抽出済ＧＬ仕訳単位
              gi.reference10 AS reference10,                     -- 抽出済明細概要
              gi.jgzz_recon_ref AS jgzz_recon_ref,               -- 抽出済消込参照
              gi.attribute1 AS attribute1,                       -- 抽出済税区分
              gi.attribute2 AS attribute2,                       -- 抽出済増減事由
              gi.attribute3 AS attribute3,                       -- 抽出済伝票番号
              gi.attribute4 AS attribute4,                       -- 抽出済起票部門
              gi.attribute5 AS attribute5,                       -- 抽出済入力者
              gi.attribute6 AS attribute6,                       -- 抽出済修正元伝票番号
              aaa.customer_trx_id AS customer_trx_id,            -- 請求書ヘッダＩＤ
              aaa.comments AS comments,                          -- 注釈
              aaa.doc_sequence_value AS doc_sequence_value,      -- 請求書文書番号
              aaa.attribute5 AS aaa_attribute1,                  -- 増減事由
              aaa.attribute2 AS aaa_attribute2,                  -- 消込参照
              gi.code_combination_id AS code_combination_id,     -- AFF組合せID
              aaa.adjustment_type AS adjustment_type,            -- 修正タイプ
              aaa.attribute9 AS attribute9,                      -- 予備１
              aaa.attribute10 AS attribute10                     -- 予備２
-- ver 11.5.10.2.4 Add Start
             ,gi.attribute15 AS attribute15                      -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
      FROM    gl_interface gi,                              -- GLインターフェーステーブル
              ar_adjustments_all aaa                             -- 仕訳修正テーブル
      WHERE   gi.user_je_source_name   = lv_journal_source
      AND     gi.user_je_category_name = lv_Adjustment
      AND     aaa.adjustment_id        = gi.reference22 
      AND     gi.status ='NEW'
      AND     gi.actual_flag = 'A'
      AND     gi.context IS NULL
      AND     gi.set_of_books_id = in_gl_book_id
      AND     (gi.reference29 in ('ADJ_REC','ADJ_ADJ','ADJ_TAX','ADJ_ADJ_NON_REC_TAX'))
      ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec_4 gl_add_dff_data_cur_4%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_4');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_Adjustment);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
      lv_retcode,                    -- リターン・コード             --# 固定 #
      lv_errmsg,                     -- ユーザー・エラー・メッセージ --# 固定 #
      lv_context_name,               -- 会計帳簿名
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --共通エラー処理
      RAISE global_process_expt;
    END IF;
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur_4;
    <<interface_loop_4>>
    LOOP
      FETCH gl_add_dff_data_cur_4 INTO gl_add_dff_data_rec_4;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur_4%NOTFOUND THEN
          EXIT interface_loop_4;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_4.user_je_category_name);
      -- =================================================
      --初期値の編集
      -- =================================================
        lv_out_tax_code   := gl_add_dff_data_rec_4.attribute1;     -- 税コード
        lv_out_attribute1 := gl_add_dff_data_rec_4.attribute2;     -- 増減事由
        lv_out_attribute5 := gl_add_dff_data_rec_4.attribute4;     -- 起票部門
        lv_out_attribute6 := gl_add_dff_data_rec_4.attribute5;     -- 入力者
        lv_out_attribute2 := gl_add_dff_data_rec_4.jgzz_recon_ref; -- 消込参照
        lv_out_comments   := gl_add_dff_data_rec_4.reference10;    -- 明細摘要
-- 20050131 V1.5 START
        lv_out_attribute9  := '';                                  -- 予備１
        lv_out_attribute10 := '';                                  -- 予備２
-- 20050131 V1.5 END
      -- ==========================================================
      -- 前受金請求書判定および注釈取得処理_1 [adjustment](5-1)
      -- ==========================================================
      get_ra_customer_rx_all_1(
          gl_add_dff_data_rec_4.customer_trx_id,    -- 請求書タイプＩＤ(IN)
          lv_trx_number,                            -- 請求書番号(OUT)
          lv_attribute5,                            -- 起票部門(OUT)
          lv_attribute6,                            -- 入力者(OUT)
          lv_initial_customer_trx_id,               -- 取引約定(OUT)
          lv_errbuf,                                -- エラー・メッセージ           --# 固定 #
          lv_retcode,                               -- リターン・コード             --# 固定 #
          lv_errmsg);                               -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --共通エラー処理
          RAISE global_process_expt;
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ユーザーエラー処理
          RAISE warning_status_expt;
        END IF;
      END IF;
-- 20050131 V1.5 START
      lv_out_attribute5 := lv_attribute5;     -- 起票部門
      lv_out_attribute6 := lv_attribute6;     -- 入力者
-- 20050131 V1.5 END
    -- =========================================================
    -- 前受金請求書判定および注釈取得処理_2  [adjustment](A5-2)
    -- =========================================================
      get_ra_customer_rx_all_2(
        lv_initial_customer_trx_id,   -- 請求書ID(IN)
        lv_cust_trx_type_id,          -- 請求書タイプＩＤ(OUT)
        lv_flg_1,                     -- 前受金請求書判定(OUT)
        lv_errbuf,                    -- エラー・メッセージ           --# 固定 #
        lv_retcode,                   -- リターン・コード             --# 固定 #
        lv_errmsg);                   -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --共通エラー処理
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --ユーザーエラー処理
            RAISE warning_status_expt;
          END IF;
        END IF;
        -- =========================================================
        -- 前受金請求書判定および注釈取得処理_3 [adjustment](A5-3)
        -- =========================================================
        IF lv_flg_1 = '0' THEN 
          get_trx_type_2(
            lv_cust_trx_type_id,           -- 請求書タイプＩＤ(IN)
            lv_type,                       -- タイプ(OUT)
            lv_flg_2,                      -- 前受金請求書判定(OUT)
            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
            lv_retcode,                    -- リターン・コード             --# 固定 #
            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --ユーザーエラー処理
                RAISE warning_status_expt;
              END IF;
            END IF;
            -- 判定 タイプ（ＤＥＰ）判定処理
            IF lv_type = 'DEP' THEN
              lv_flg_3 := '1';                         -- 前受金充当請求書
            END IF;
        END IF;
        -- =================================================
        -- AR税テーブル情報取得処理 [adjustment](A5-4)
        -- =================================================
        -- 明細仕訳タイプの判断
        -- 20040512 IF条件で対象を全てとするに修正
--        IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' OR 
--           gl_add_dff_data_rec_4.payment_id = 'ADJ_TAX' THEN
        -- 20050131 V1.5 パラメータの変更
        --                 （AFF組合せID（lv_code_combination_id）
        --                                                      ⇒ 請求書ID（invoice_id））
        --                及び
        --               パラメータの追加（明細仕訳タイプ（payment_id））
          get_ar_vat_tax_all_3(
            gl_add_dff_data_rec_4.invoice_id,           --  請求書ID(IN)
            gl_add_dff_data_rec_4.payment_id,           --  明細仕訳タイプ(IN)
            lv_xx03_tax_code,              -- XX03_TAX_CODES(NAME)(IN)
            lv_tax_code,                   -- 税コード(OUT)
            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
            lv_retcode,                    -- リターン・コード             --# 固定 #
            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                --共通エラー処理
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --ユーザーエラー処理
                RAISE warning_status_expt;
              END IF;
            END IF;
--        END IF;
        --前受金充当請求書でない場合の編集
-- 20050131 V1.5 START
--          IF lv_flg_1 = '1' OR lv_flg_2 = '1' THEN
          IF lv_flg_1 = '1' OR lv_flg_2 = '1' OR
              gl_add_dff_data_rec_4.adjustment_type <> cv_adjustment_type_c THEN
-- 20050131 V1.5 END
            IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' OR 
               gl_add_dff_data_rec_4.payment_id = 'ADJ_TAX' OR 
               gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ_NON_REC_TAX' THEN
                 lv_out_tax_code   := lv_tax_code;     -- 税コード
                 lv_out_attribute1 := gl_add_dff_data_rec_4.aaa_attribute1; -- 増減事由
                 lv_out_attribute2 := gl_add_dff_data_rec_4.aaa_attribute2; -- 消込参照
                 IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' THEN 
                   lv_out_comments   := gl_add_dff_data_rec_4.comments;     -- 明細摘要
-- 20050131 V1.5 START
                   lv_out_attribute9 := gl_add_dff_data_rec_4.attribute9;   -- 予備１
                   lv_out_attribute10 := gl_add_dff_data_rec_4.attribute10; -- 予備２
-- 20050131 V1.5 END
                 END IF;
             END IF;
          ELSE --前受金充当請求書の場合の編集
-- 20050131 V1.5 START
--            lv_out_attribute5 := lv_attribute5;     -- 起票部門
--            lv_out_attribute6 := lv_attribute6;     -- 入力者
-- 20050131 V1.5 END
            IF gl_add_dff_data_rec_4.payment_id = 'ADJ_ADJ' THEN 
              lv_out_tax_code   := lv_tax_code;     -- 税コード
            END IF;
          END IF;
        -- ===================================
        -- 仕訳データの更新処理 (A8)
        -- ===================================
          -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
          upd_journal_data(
          gl_add_dff_data_rec_4.row_id,                -- 1.ROWID(IN)
          lv_journal_source,                           -- 2.仕訳ソース名(IN)
          gl_add_dff_data_rec_4.user_je_category_name, -- 3.仕訳名(IN)
          lv_group_id,                                 -- 4.グループID(IN)
          lv_context_name,                             -- 5.会計帳簿名(IN)
          lv_trx_number,                               -- 6.伝票番号(IN)
          gl_add_dff_data_rec_4.doc_sequence_value,    -- 7.修正元伝票番号(IN)
          lv_out_attribute5,                           -- 8.起票部門(IN)
          lv_out_attribute6,                           -- 9.入力者(IN)
          lv_out_tax_code,                             -- 10.税コード(IN)
          lv_out_attribute1,                           -- 11.増減事由(IN)
          lv_out_attribute2,                           -- 12.消込参照(IN)
          lv_out_comments,                             -- 13.明細摘要(IN)
          gl_add_dff_data_rec_4.attribute6,            -- 14.修正元伝票番号(IN)
          lv_out_attribute9,                           -- 15.予備１(IN)
          lv_out_attribute10,                          -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
          gl_add_dff_data_rec_4.attribute15,           -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
          lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
          lv_retcode,                           -- リターン・コード             --# 固定 #
          lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --ユーザーエラー処理
              RAISE warning_status_expt;
            END IF;
          END IF;
          ln_adjustment_cnt := ln_adjustment_cnt + 1; -- カテゴリ別件数(クレジットメモ)計上
--
    END LOOP interface_loop_4;
    --ログ出力
    CLOSE gl_add_dff_data_cur_4;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_add_dff_data_4;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_5
   * Description      : DFF付加対象データ抽出処理 [Trade Receipts] (A6)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_5(
    in_gl_book_id           IN NUMBER,       -- 1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       -- 2.オルグID(IN)
    lv_trade_receipts       IN VARCHAR2,     -- 3.仕訳カテゴリ名(売掛／未収金入金)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    ln_trade_receipts_cnt   IN OUT NUMBER,   -- 5.仕訳カテゴリ別件数(売掛／未収金入金)(OUT)
    lv_group_id             IN NUMBER,       -- 6.グループID(IN)
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_5'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE;   -- コンテキスト値
    lv_A6_flg              VARCHAR2(1);                -- 判定フラグ
    lv_trx_number          VARCHAR2(20);               -- 前受金請求書判定
    lv_pay_from_customer   NUMBER(15);                 -- 支払顧客
    lv_hca_account_number  VARCHAR2(30);               -- 顧客番号(OUT)
    lv_hca_party_id        NUMBER(15);                 -- パーティID(OUT)
    lv_hca_attribute2      VARCHAR2(150);              -- 一見顧客区分(OUT)
    lv_acra_attribute1     VARCHAR2(150);              -- 振込依頼人名(OUT)
    lv_hp_party_name       VARCHAR2(360);              -- パーティ名(OUT)
    lv_acrha_status        VARCHAR2(30);               -- ステータス(OUT)
    lv_acra_doc_sequence_value  NUMBER(15);            -- 入金文書番号(OUT)
    lv_invoice_id         VARCHAR2(240);               -- 請求書ID(OUT)
    lv_out_tax_code    VARCHAR2(50);                   -- 税コード
    lv_out_attribute1  VARCHAR2(150);                  -- 増減事由
    lv_out_attribute5  VARCHAR2(150);                  -- 起票部門
    lv_out_attribute6  VARCHAR2(150);                  -- 入力者
    lv_out_attribute2  VARCHAR2(150);                  -- 消込参照
    lv_out_comments    VARCHAR2(150);                  -- 明細摘要
    lv_out_attribute7  VARCHAR2(150);                  -- 修正元伝票番号
-- 20050131 V1.5 START
    lv_out_attribute9  VARCHAR2(150);                  -- 予備１
    lv_out_attribute10 VARCHAR2(150);                  -- 予備２
-- 20050131 V1.5 END
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    -- 20040519 V1.3 条件追加：'TRADE_ACC'
    -- 20040519 条件追加 V1.3 会計帳簿帳簿ID
    CURSOR gl_add_dff_data_cur_5
    IS
    SELECT  gi.rowid AS row_id,                                 -- ROWID
            gi.user_je_category_name AS user_je_category_name,  -- 仕訳カテゴリ
            gi.reference22 AS invoice_id,                       -- 請求書ID
            gi.reference23 AS distribution_line_number,         -- 請求書明細番号/支払ID
            gi.reference29 AS payment_id,                       -- 明細仕訳タイプ
            gi.group_id AS group_id,                            -- パラメータグループID
            gi.context AS context,                              -- 会計帳簿名
            gi.reference4 AS reference4,                        -- 抽出済ＧＬ仕訳単位
            gi.reference10 AS reference10,                      -- 抽出済明細概要
            gi.jgzz_recon_ref AS jgzz_recon_ref,                -- 抽出済消込参照
            gi.attribute1 AS attribute1,                        -- 抽出済税区分
            gi.attribute2 AS attribute2,                        -- 抽出済増減事由
            gi.attribute3 AS attribute3,                        -- 抽出済伝票番号
            gi.attribute4 AS attribute4,                        -- 抽出済起票部門
            gi.attribute5 AS attribute5,                        -- 抽出済入力者
            gi.attribute6 AS attribute6,                        -- 抽出済修正元伝票番号
            gi.reference27 AS reference27,                      -- 請求先顧客ＩＤ
            gi.reference25 AS reference25,                      -- 請求書番号
            acra.doc_sequence_value AS doc_sequence_value,      -- 入金文書番号
            acra.pay_from_customer AS pay_from_customer,        -- 支払顧客
            acra.attribute1 AS acra_attribute1,                 -- 振込依頼人名
            acra.status AS acra_status                          -- ステータス
-- ver 11.5.10.2.4 Add Start
           ,gi.attribute15 AS attribute15                       -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
    FROM    gl_interface gi,                               -- GLインターフェーステーブル
            ar_cash_receipts_all acra                           -- 入金情報テーブル
    WHERE   gi.user_je_source_name =  lv_journal_source
    AND     gi.user_je_category_name = lv_trade_receipts
    AND     acra.cash_receipt_id = substr(gi.reference22, 1,instr(gi.reference22,'C',1)-1)  
    AND     gi.status ='NEW'
    AND     gi.actual_flag = 'A'
    AND     gi.context IS NULL
    AND     gi.set_of_books_id = in_gl_book_id
-- 20050311 V1.7 Added 'TRADE_ACTIVITY'
-- 20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
    AND     (gi.reference29 in ('TRADE_CASH','TRADE_UNAPP','TRADE_ACC','TRADE_ACTIVITY','TRADE_UNID',
             'TRADE_REC','TRADE_EXCH_GAIN','TRADE_EXCH_LOSS','TRADE_BANK_CHARGES','TRADE_CONFIRMATION',
             'TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'))
-- 20050714 V11.5.10.1.4 End
-- 20050311 V1.7 End
    ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec_5 gl_add_dff_data_cur_5%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_5');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_trade_receipts);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
      lv_retcode,                    -- リターン・コード             --# 固定 #
      lv_errmsg,                     -- ユーザー・エラー・メッセージ --# 固定 #
      lv_context_name,               -- 会計帳簿名
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --共通エラー処理
      RAISE global_process_expt;
    END IF;
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur_5;
    <<interface_loop_5>>
    LOOP
      FETCH gl_add_dff_data_cur_5 INTO gl_add_dff_data_rec_5;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur_5%NOTFOUND THEN
          EXIT interface_loop_5;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_5.user_je_category_name);
      lv_acra_attribute1 := gl_add_dff_data_rec_5.acra_attribute1; --振込依頼人名
      lv_A6_flg := '0';                                  -- 前受金請求書判定初期値
      lv_hca_attribute2 := '';                           -- NULL
-- 20050131 V1.5 START
      lv_out_attribute9 := '';                           -- 予備１初期値
      lv_out_attribute10 := '';                          -- 予備２初期値
-- 20050131 V1.5 END
    -- =================================================
    --初期値の編集
    -- =================================================
      lv_out_tax_code   := gl_add_dff_data_rec_5.attribute1;     -- 税コード
      lv_out_attribute1 := gl_add_dff_data_rec_5.attribute2;     -- 増減事由
      lv_out_attribute5 := gl_add_dff_data_rec_5.attribute4;     -- 起票部門
      lv_out_attribute6 := gl_add_dff_data_rec_5.attribute5;     -- 入力者
      lv_out_attribute2 := gl_add_dff_data_rec_5.jgzz_recon_ref; -- 消込参照
      lv_out_comments   := gl_add_dff_data_rec_5.reference10;    -- 明細摘要
      lv_out_attribute7 := gl_add_dff_data_rec_5.attribute6;     -- 修正元伝票番号

  -- ==========================================================
  -- 顧客ヘッダーテーブルより設定値取得処理 [Trade Receipts] (A6-1)
  -- ==========================================================
--20040525 V1.4 ADD 'TRADE_BANK_CHARGES'
--20050714 V1. ADD 'TRADE_BANK_CHARGES'
--20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
      IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_CONFIRMATION' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_REMITTANCE' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_FACTOR' OR
         gl_add_dff_data_rec_5.payment_id = 'TRADE_SHORT_TERM_DEBT' THEN
         IF gl_add_dff_data_rec_5.reference27 IS NOT NULL THEN
          get_ra_hz_cust_account(
            gl_add_dff_data_rec_5.pay_from_customer, --支払顧客(IN)
            lv_hca_account_number,                   -- 顧客番号(OUT)
            lv_hca_party_id,                         --パーティID(OUT)
            lv_hca_attribute2,                       --一見顧客区分(OUT)
            lv_errbuf,                               -- エラー・メッセージ           --# 固定 #
            lv_retcode,                              -- リターン・コード             --# 固定 #
            lv_errmsg);                              -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
              --共通エラー処理
              RAISE global_process_expt;
            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
              --ユーザーエラー処理
              RAISE warning_status_expt;
            END IF;
          END IF;
    -- =========================================================
    -- 一見顧客出ない場合、パーティテーブルより取得処理  [Trade Receipts] (A6-2)
    -- =========================================================
          IF lv_hca_attribute2 = 'N' THEN
            get_hz_parties(
              lv_hca_party_id,               -- パーティID(IN)
              lv_hp_party_name,              -- パーティ名(OUT)
              lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
              lv_retcode,                    -- リターン・コード             --# 固定 #
              lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                --共通エラー処理
                RAISE global_process_expt;
              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
                --ユーザーエラー処理
                RAISE warning_status_expt;
              END IF;
            END IF;
          END IF;
         END IF;
      END IF;
    -- =========================================================
    -- 入金文書番号取得処理1 [Trade Receipts] (A6-3)
    -- =========================================================
--  2004/04/20 保留処理 start
--  2004/05/19 条件追加 'TRADE_ACC'
--  2004/05/25 条件追加 'TRADE_BANK_CHARGES'
--        IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR 
--           gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR
--           gl_add_dff_data_rec_5.payment_id = 'TRADE_UNAPP' OR
--           gl_add_dff_data_rec_5.payment_id = 'TRADE_ACC' THEN
--         get_ar_cash_receipt_his_all_1(
--            gl_add_dff_data_rec_5.invoice_id,  --入金ID(IN)
--            lv_acrha_status,               -- ステータス(OUT)
--            lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
--            lv_retcode,                    -- リターン・コード             --# 固定 #
--            lv_errmsg);                    -- ユーザー・エラー・メッセージ --# 固定 #
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
--              --共通エラー処理
--              RAISE global_process_expt;
--            ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
--              --ユーザーエラー処理
--              RAISE warning_status_expt;
--            END IF;
--          END IF;
    -- =========================================================
    -- 入金文書番号取得処理2 [Trade Receipts] (A6-4)
    -- =========================================================
--          IF lv_acrha_status = 'REVERSED' THEN 
--           get_ar_cash_receipts_all(
--              gl_add_dff_data_rec_5.invoice_id,  --入金ID(IN)
--              lv_acra_doc_sequence_value,        -- 入金文書番号戻し(OUT)
--              lv_errbuf,                         -- エラー・メッセージ           --# 固定 #
--              lv_retcode,                        -- リターン・コード             --# 固定 #
--              lv_errmsg);                        -- ユーザー・エラー・メッセージ --# 固定 #
--            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
--                --共通エラー処理
--                RAISE global_process_expt;
--              ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
--                --ユーザーエラー処理
--                RAISE warning_status_expt;
--              END IF;
--            END IF;
--          END IF;
--        END IF;
--  2004/04/20 保留処理 end
      --入金戻しの場合編集
        IF gl_add_dff_data_rec_5.acra_status = 'REV' THEN 
--  2004/04/20 保留処理 start/end
--          lv_out_attribute7 := lv_acra_doc_sequence_value;     -- 修正元伝票番号
--20040525 V1.4 ADD 'TRADE_BANK_CHARGES'
--20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
          IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR 
             gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_CONFIRMATION' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_REMITTANCE' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_FACTOR' OR
             gl_add_dff_data_rec_5.payment_id = 'TRADE_SHORT_TERM_DEBT' THEN 
            IF lv_hca_attribute2 = 'N' THEN
               lv_out_comments := SUBSTRB(lv_hca_account_number||lv_hp_party_name,1,150);
            ELSE
--               lv_out_comments := gl_add_dff_data_rec_5.acra_attribute1; -- 明細摘要
               lv_out_comments := SUBSTRB(lv_hca_account_number||gl_add_dff_data_rec_5.acra_attribute1,1,150); -- 明細摘要
            END IF;
          END IF;
        ELSE
      --入金の場合編集(不明入金は対象外)
--20040525 V1.4 ADD 'TRADE_BANK_CHARGES'
--20050714 V11.5.10.1.4 Added 'TRADE_CONFIRMATION','TRADE_REMITTANCE','TRADE_FACTOR','TRADE_SHORT_TERM_DEBT'
          IF gl_add_dff_data_rec_5.reference27 IS NOT NULL THEN 
            IF gl_add_dff_data_rec_5.payment_id = 'TRADE_CASH' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_BANK_CHARGES' OR 
               gl_add_dff_data_rec_5.payment_id = 'TRADE_CONFIRMATION' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_REMITTANCE' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_FACTOR' OR
               gl_add_dff_data_rec_5.payment_id = 'TRADE_SHORT_TERM_DEBT' THEN 
              IF lv_hca_attribute2 = 'N' THEN
                 lv_out_comments := SUBSTRB(lv_hca_account_number||lv_hp_party_name,1,150);
              ELSE
--                 lv_out_comments := gl_add_dff_data_rec_5.acra_attribute1; -- 明細摘要
                 lv_out_comments := SUBSTRB(lv_hca_account_number||gl_add_dff_data_rec_5.acra_attribute1,1,150); -- 明細摘要
              END IF;
            END IF;
          END IF;
        END IF;
      --入金取り消しの場合編集
        IF gl_add_dff_data_rec_5.payment_id = 'TRADE_REC' THEN 
           lv_out_comments := gl_add_dff_data_rec_5.reference25; -- 明細摘要
        END IF;
    -- ===================================
    -- 仕訳データの更新処理 (A8)
    -- ===================================
        -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
        upd_journal_data(
        gl_add_dff_data_rec_5.row_id,                -- 1.ROWID(IN)
        lv_journal_source,                           -- 2.仕訳ソース名(IN)
        gl_add_dff_data_rec_5.user_je_category_name, -- 3.仕訳名(IN)
        lv_group_id,                                 -- 4.グループID(IN)
        lv_context_name,                             -- 5.会計帳簿名(IN)
        gl_add_dff_data_rec_5.doc_sequence_value,    -- 6.伝票番号(IN)
        gl_add_dff_data_rec_5.doc_sequence_value,    -- 7.GL仕訳単位(IN)
        lv_out_attribute5,                           -- 8.起票部門(IN)
        lv_out_attribute6,                           -- 9.入力者(IN)
        lv_out_tax_code,                             -- 10.税コード(IN)
        lv_out_attribute1,                           -- 11.増減事由(IN)
        lv_out_attribute2,                           -- 12.消込参照(IN)
        lv_out_comments,                             -- 13.明細摘要(IN)
        lv_out_attribute7,                           -- 14.修正元伝票番号(IN)
        lv_out_attribute9,                           -- 15.予備１(IN)
        lv_out_attribute10,                          -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
        gl_add_dff_data_rec_5.attribute15,           -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
        lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
        lv_retcode,                           -- リターン・コード             --# 固定 #
        lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
            --共通エラー処理
            RAISE global_process_expt;
          ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
            --ユーザーエラー処理
            RAISE warning_status_expt;
          END IF;
        END IF;
      ln_trade_receipts_cnt := ln_trade_receipts_cnt + 1; -- カテゴリ別件数(売掛／未収金入金)
--
    END LOOP interface_loop_5;
    --ログ出力
    CLOSE gl_add_dff_data_cur_5;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_add_dff_data_5;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data_6
   * Description      : DFF付加対象データ抽出処理 [Cross Currency](A7,A7-1)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data_6(
    in_gl_book_id           IN NUMBER,       -- 1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       -- 2.オルグID(IN)
    lv_cross_currency       IN VARCHAR2,     -- 3.仕訳カテゴリ名(相互通貨)(IN)
    lv_journal_source       IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    lv_cross_currency_cnt   IN OUT NUMBER,   -- 5.仕訳カテゴリ別件数(相互通貨)(OUT)
    lv_group_id             IN NUMBER,       -- 6.グループID(IN)
    ov_errbuf               OUT VARCHAR2,    -- エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    -- リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data_6'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE;  -- コンテキスト値
    lv_out_tax_code    VARCHAR2(50);                  -- 税コード
    lv_out_attribute1  VARCHAR2(150);                 -- 増減事由
    lv_out_attribute5  VARCHAR2(150);                 -- 起票部門
    lv_out_attribute6  VARCHAR2(150);                 -- 入力者
    lv_out_attribute2  VARCHAR2(150);                 -- 消込参照
    lv_out_comments    VARCHAR2(150);                 -- 明細摘要
    lv_out_attribute7  VARCHAR2(150);                 -- 修正元伝票番号
-- 20050131 V1.5 START
    lv_out_attribute9  VARCHAR2(150);                  -- 予備１
    lv_out_attribute10 VARCHAR2(150);                  -- 予備２
-- 20050131 V1.5 END
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    -- 20040519 条件追加 V1.3 会計帳簿帳簿ID
    CURSOR gl_add_dff_data_cur_6
    IS
    SELECT  gi.rowid AS row_id,                                 -- ROWID
            gi.user_je_category_name AS user_je_category_name,  -- 仕訳カテゴリ
            gi.reference22 AS invoice_id,                       -- 請求書ID
            gi.reference23 AS distribution_line_number,         -- 請求書明細番号/支払ID
            gi.reference29 AS payment_id,                       -- 明細仕訳タイプ
            gi.group_id AS group_id,                            -- パラメータグループID
            gi.context AS context,                              -- 会計帳簿名
            gi.reference4 AS reference4,                        -- 抽出済ＧＬ仕訳単位
            gi.reference10 AS reference10,                      -- 抽出済明細概要
            gi.jgzz_recon_ref AS jgzz_recon_ref,                -- 抽出済消込参照
            gi.attribute1 AS attribute1,                        -- 抽出済税区分
            gi.attribute2 AS attribute2,                        -- 抽出済増減事由
            gi.attribute3 AS attribute3,                        -- 抽出済伝票番号
            gi.attribute4 AS attribute4,                        -- 抽出済起票部門
            gi.attribute5 AS attribute5,                        -- 抽出済入力者
            gi.attribute6 AS attribute6,                        -- 抽出済修正元伝票番号
            gi.reference27 AS reference27,                      -- 請求先顧客ＩＤ
            gi.reference25 AS reference25,                      -- 請求書番号
            acra.doc_sequence_value AS doc_sequence_value,      -- 入金文書番号
            acra.pay_from_customer AS pay_from_customer,        -- 支払顧客
            acra.attribute1 AS acra_attribute1                  -- 振込依頼人名
-- ver 11.5.10.2.4 Add Start
           ,gi.attribute15 AS attribute15                       -- 伝票作成会社
-- ver 11.5.10.2.4 Add End
    FROM    gl_interface gi,                               -- GLインターフェーステーブル
            ar_cash_receipts_all acra                           -- 入金情報テーブル
    WHERE   gi.user_je_source_name =  lv_journal_source
    AND     gi.user_je_category_name = lv_cross_currency
    AND     acra.cash_receipt_id = substr(gi.reference22, 1,instr(gi.reference22,'C',1)-1)  
    AND     gi.status ='NEW'
    AND     gi.actual_flag = 'A'
    AND     gi.context IS NULL
    AND     gi.set_of_books_id = in_gl_book_id
    AND     (gi.reference29 in ('CCURR_UNAPP','CCURR_REC','CCURR_EXCH_GAIN','CCURR_EXCH_LOSS'))
    ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec_6 gl_add_dff_data_cur_6%ROWTYPE;
--
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('get_add_dff_data_6');
    xx00_file_pkg.log('source :' || lv_journal_source);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_SALES_IN_INVOICE : ' || lv_cross_currency);
    xx00_file_pkg.log(' ');
    XX03_BOOKS_ORG_NAME_GET_PKG.set_of_books_name(
      lv_errbuf,                     -- エラー・メッセージ           --# 固定 #
      lv_retcode,                    -- リターン・コード             --# 固定 #
      lv_errmsg,                     -- ユーザー・エラー・メッセージ --# 固定 #
      lv_context_name,               -- 会計帳簿名
      xx00_profile_pkg.value('GL_SET_OF_BKS_ID'));
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --共通エラー処理
      RAISE global_process_expt;
    END IF;
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur_6;
    <<interface_loop_6>>
    LOOP
      FETCH gl_add_dff_data_cur_6 INTO gl_add_dff_data_rec_6;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur_6%NOTFOUND THEN
          EXIT interface_loop_6;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec_6.user_je_category_name);
    -- =================================================
    --初期値の編集
    -- =================================================
      lv_out_tax_code   := gl_add_dff_data_rec_6.attribute1;     -- 税コード
      lv_out_attribute1 := gl_add_dff_data_rec_6.attribute2;     -- 増減事由
      lv_out_attribute5 := gl_add_dff_data_rec_6.attribute4;     -- 起票部門
      lv_out_attribute6 := gl_add_dff_data_rec_6.attribute5;     -- 入力者
      lv_out_attribute2 := gl_add_dff_data_rec_6.jgzz_recon_ref; -- 消込参照
      lv_out_comments   := gl_add_dff_data_rec_6.reference10;    -- 明細摘要
      lv_out_attribute7 := gl_add_dff_data_rec_6.attribute6;     -- 修正元伝票番号
    --入金番号編集
      IF gl_add_dff_data_rec_6.payment_id = 'CCURR_REC' THEN 
         lv_out_comments := gl_add_dff_data_rec_6.reference25; -- 明細摘要
      END IF;
-- 20050131 V1.5 START
      lv_out_attribute9 := '';                                   -- 予備１
      lv_out_attribute10 := '';                                  -- 予備２
-- 20050131 V1.5 END
    -- ===================================
    -- 仕訳データの更新処理 (A8)
    -- ===================================
      -- 20050131 V1.5 パラメータ（予備１・予備２）の追加
      upd_journal_data(
      gl_add_dff_data_rec_6.row_id,                -- 1.ROWID(IN)
      lv_journal_source,                           -- 2.仕訳ソース名(IN)
      gl_add_dff_data_rec_6.user_je_category_name, -- 3.仕訳名(IN)
      lv_group_id,                                 -- 4.グループID(IN)
      lv_context_name,                             -- 5.会計帳簿名(IN)
      gl_add_dff_data_rec_6.doc_sequence_value,    -- 6.伝票番号(IN)
      gl_add_dff_data_rec_6.doc_sequence_value,    -- 7.GL仕訳単位(IN)
      lv_out_attribute5,                           -- 8.起票部門(IN)
      lv_out_attribute6,                           -- 9.入力者(IN)
      lv_out_tax_code,                             -- 10.税コード(IN)
      lv_out_attribute1,                           -- 11.増減事由(IN)
      lv_out_attribute2,                           -- 12.消込参照(IN)
      lv_out_comments,                             -- 13.明細摘要(IN)
      lv_out_attribute7,                           -- 14.修正元伝票番号(IN)
      lv_out_attribute9,                           -- 15.予備１(IN)
      lv_out_attribute10,                          -- 16.予備２(IN)
-- ver 11.5.10.2.4 Add Start
      gl_add_dff_data_rec_6.attribute15,           -- 17.伝票作成会社(IN)
-- ver 11.5.10.2.4 Add End
      lv_errbuf,                            -- エラー・メッセージ           --# 固定 #
      lv_retcode,                           -- リターン・コード             --# 固定 #
      lv_errmsg);                           -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
          --共通エラー処理
          RAISE global_process_expt;
        ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
          --ユーザーエラー処理
          RAISE warning_status_expt;
        END IF;
      END IF;
      lv_cross_currency_cnt := lv_cross_currency_cnt + 1; -- カテゴリ別件数(相互通貨)
--
    END LOOP interface_loop_6;
    --ログ出力
    CLOSE gl_add_dff_data_cur_6;
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--#####################################  固定部 END   ##########################################
--
  END get_add_dff_data_6;

  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_journal_source  IN  VARCHAR2,     -- 1.仕訳ソース名
    iv_group_id        IN  VARCHAR2,     -- 2.グループID
    ov_errbuf          OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    ln_gl_book_id  gl_interface.set_of_books_id%TYPE; -- 会計帳簿帳簿ID
    ln_org_id                   NUMBER(15,0);     -- オルグID
    lv_sales_invoices           VARCHAR2(30);     -- 仕訳カテゴリ名(売上請求書)
    lv_trade_receipts           VARCHAR2(30);     -- 仕訳カテゴリ名(売掛／未収金入金)
    lv_adjustment               VARCHAR2(30);     -- 仕訳カテゴリ名(修正)
    lv_credit_memos             VARCHAR2(30);     -- 仕訳カテゴリ名(クレジットメモ)
    lv_credit_memo_applications VARCHAR2(30);     -- 仕訳カテゴリ名(クレジットメモ消込)
    lv_cross_currency           VARCHAR2(30);     -- 仕訳カテゴリ名(相互通貨)
    ln_sales_invoices_cnt       NUMBER := 0;      -- 仕訳カテゴリ別件数(売上請求書)
    ln_trade_receipts_cnt       NUMBER := 0;      -- 仕訳カテゴリ別件数(売掛／未収金入金)
    ln_adjustment_cnt           NUMBER := 0;      -- 仕訳カテゴリ別件数(修正)
    ln_credit_memos_cnt         NUMBER := 0;      -- 仕訳カテゴリ別件数(クレジットメモ)
    ln_credit_memo_app_cnt      NUMBER := 0;      -- 仕訳カテゴリ別件数(クレジットメモ消込)
    ln_cross_currency_cnt       NUMBER := 0;      -- 仕訳カテゴリ別件数(相互通貨)
-- 20040512 1.2 START
    lv_xx03_tax_code            VARCHAR2(15);     -- XX03_TAX_CODES_V(NAME)
-- 20040512 1.2 END
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
--
    --*********************************************
    --***      MD.050のフロー図を表す           ***
    --***      分岐と処理部の呼び出しを行う     ***
    --*********************************************
--
    -- ===============================
    -- 関連データ取得 (A-1)
    -- ===============================
    get_id(
      ln_gl_book_id,               -- 1.会計帳簿帳簿ID(OUT)
      ln_org_id,                   -- 2.オルグID(OUT)
      lv_sales_invoices,           -- 3.仕訳カテゴリ名(売上請求書)(OUT)
      lv_trade_receipts,           -- 4.仕訳カテゴリ名(売掛／未収金入金)(OUT)
      lv_adjustment,               -- 5.仕訳カテゴリ名(修正)(OUT)
      lv_credit_memos,             -- 6.仕訳カテゴリ名(クレジットメモ)(OUT)
      lv_credit_memo_applications, -- 7.仕訳カテゴリ名(クレジットメモ消込)(OUT)
      lv_cross_currency,           -- 8.仕訳カテゴリ名(相互通貨)(OUT)
      lv_xx03_tax_code,            -- 9.XX03_TAX_CODES_V(NAME)(OUT)
      lv_errbuf,                   -- エラー・メッセージ           --# 固定 #
      lv_retcode,                  -- リターン・コード             --# 固定 #
      lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    --*********************************************
    --***      仕訳カテゴリ                     ***
    --***      [ 売上請求書 ]   A2              ***
    --*********************************************

    -- =================================================
    -- DFF付加対象データ抽出処理 [Sales Invoices](A2)
    -- =================================================
    get_add_dff_data_1(
      ln_gl_book_id,          -- 1.会計帳簿帳簿ID(IN)
      ln_org_id,              -- 2.オルグID(IN)
      lv_sales_invoices,      -- 3.仕訳カテゴリ名(売上請求書)(IN)
      iv_journal_source,      -- 4.仕訳ソース名(IN)
      ln_sales_invoices_cnt,  -- 5.仕訳カテゴリ別件数(売上請求書)
      iv_group_id,            -- 6.グループID(IN)
      lv_xx03_tax_code,       -- 7.XX03_TAX_CODE(IN)
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSE

    --*********************************************
    --***      仕訳カテゴリ                     ***
    --***      [ クレジットメモ ]   A3          ***
    --*********************************************
    -- =================================================
    -- DFF付加対象データ抽出処理 [Credit Memo](A3)
    -- =================================================
      get_add_dff_data_2(
        ln_gl_book_id,          -- 1.会計帳簿帳簿ID(IN)
        ln_org_id,              -- 2.オルグID(IN)
        lv_credit_memos,        -- 3.仕訳カテゴリ名(クレジットメモ)(IN)
        iv_journal_source,      -- 4.仕訳ソース名(IN)
        ln_credit_memos_cnt,    -- 5.仕訳カテゴリ別件数(クレジットメモ)
        iv_group_id,            -- 6.グループID(IN)
        lv_xx03_tax_code,       -- 7.XX03_TAX_CODE(IN)
        lv_errbuf,              -- エラー・メッセージ           --# 固定 #
        lv_retcode,             -- リターン・コード             --# 固定 #
        lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
        --(エラー処理)
        RAISE global_process_expt;
      ELSE
    --*********************************************
    --***      仕訳カテゴリ                     ***
    --***      [ クレジットメモ消込 ]  A4       ***
    --*********************************************
    -- =================================================
    -- DFF付加対象データ抽出処理 [CM Applications](A4)
    -- =================================================
        get_add_dff_data_3(
          ln_gl_book_id,               -- 1.会計帳簿帳簿ID(IN)
          ln_org_id,                   -- 2.オルグID(IN)
          lv_credit_memo_applications, -- 3.仕訳カテゴリ名(クレジットメモ消込)(IN)
          iv_journal_source,           -- 4.仕訳ソース名(IN)
          ln_credit_memo_app_cnt,      -- 5.仕訳カテゴリ別件数(クレジットメモ消込)
          iv_group_id,                 -- 6.グループID(IN)
          lv_xx03_tax_code,            -- 7.XX03_TAX_CODE(IN)
          lv_errbuf,                   -- エラー・メッセージ           --# 固定 #
          lv_retcode,                  -- リターン・コード             --# 固定 #
          lv_errmsg);                  -- ユーザー・エラー・メッセージ --# 固定 #
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          --(エラー処理)
          RAISE global_process_expt;
        ELSE
 
    --*********************************************
    --***      仕訳カテゴリ                     ***
    --***      [ 修正 ]     A5                  ***
    --*********************************************
    -- =================================================
    -- DFF付加対象データ抽出処理 [Adjistment](A5)
    -- =================================================
          get_add_dff_data_4(
            ln_gl_book_id,          -- 1.会計帳簿帳簿ID(IN)
            ln_org_id,              -- 2.オルグID(IN)
            lv_adjustment,          -- 3.仕訳カテゴリ名(修正)(IN)
            iv_journal_source,      -- 4.仕訳ソース名(IN)
            ln_adjustment_cnt,      -- 5.仕訳カテゴリ別件数(修正)
            iv_group_id,            -- 6.グループID(IN)
            lv_xx03_tax_code,       -- 7.XX03_TAX_CODE(IN)
            lv_errbuf,              -- エラー・メッセージ           --# 固定 #
            lv_retcode,             -- リターン・コード             --# 固定 #
            lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            --(エラー処理)
            RAISE global_process_expt;
          ELSE
    --*********************************************
    --***      仕訳カテゴリ                     ***
    --***      [ 売掛／未収金入金 ]    A6       ***
    --*********************************************
    -- =================================================
    -- DFF付加対象データ抽出処理 [Trade Receipts](A6)
    -- =================================================
            get_add_dff_data_5(
              ln_gl_book_id,          -- 1.会計帳簿帳簿ID(IN)
              ln_org_id,              -- 2.オルグID(IN)
              lv_trade_receipts,      -- 3.仕訳カテゴリ名(売掛／未収金入金)(IN)
              iv_journal_source,      -- 4.仕訳ソース名(IN)
              ln_trade_receipts_cnt,  -- 5.仕訳カテゴリ別件数(売掛／未収金入金)
              iv_group_id,            -- 6.グループID(IN)
              lv_errbuf,              -- エラー・メッセージ           --# 固定 #
              lv_retcode,             -- リターン・コード             --# 固定 #
              lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              --(エラー処理)
              RAISE global_process_expt;
            ELSE
     --*********************************************
    --***      仕訳カテゴリ                     ***
    --***      [ 相互通貨 ]          A7         ***
    --*********************************************
    -- ======================================================
    -- DFF付加対象データ抽出処理 [Cross Currency](A7,A7-1)
    -- ======================================================
              get_add_dff_data_6(
                ln_gl_book_id,          -- 1.会計帳簿帳簿ID(IN)
                ln_org_id,              -- 2.オルグID(IN)
                lv_cross_currency,      -- 3.仕訳カテゴリ名(相互通貨)(IN)
                iv_journal_source,      -- 4.仕訳ソース名(IN)
                ln_cross_currency_cnt,  -- 5.仕訳カテゴリ別件数(相互通貨)
                iv_group_id,            -- 6.グループID(IN)
                lv_errbuf,              -- エラー・メッセージ           --# 固定 #
                lv_retcode,             -- リターン・コード             --# 固定 #
                lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
              IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
                --(エラー処理)
                RAISE global_process_expt;
              ELSE
-- Ver11.5.10.1.6 2005/12/15 Delete Start
-- -- 20040512 GL_INTERFACE更新追加 START
--    --*********************************************
--    --***      GL_INTERFACE更新                 ***
--    --***      [ 税区分　NULL対応 ]   A8_1      ***
--    --*********************************************
--    -- ===================================
--    -- 仕訳データの更新処理 (A8_1)
--    -- ===================================
--               upd_journal_data_1(
--                 lv_xx03_tax_code,         -- 1.税コード(IN)
--                 iv_journal_source,        -- 2.仕訳ソース名(IN)
--                 lv_errbuf,                -- エラー・メッセージ           --# 固定 #
--                 lv_retcode,               -- リターン・コード             --# 固定 #
--                 lv_errmsg);               -- ユーザー・エラー・メッセージ --# 固定 #
--               IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--                 --(エラー処理)
--                 RAISE global_process_expt;
--               ELSE
-- 20040512 GL_INTERFACE更新追加 END
-- Ver11.5.10.1.6 2005/12/15 Delete End
    --*********************************************
    --***      プルーフリスト出力処理           ***
    --***       A8                              ***
    --*********************************************
                msg_output(
                  ln_org_id,                   -- 1.オルグID(IN)
                  ln_sales_invoices_cnt,       -- 2.請求書件数(IN)(売上請求書)
                  ln_trade_receipts_cnt,       -- 3.請求書件数(IN)(売掛／未収金入金)
                  ln_adjustment_cnt,           -- 4.請求書件数(IN)(修正)
                  ln_credit_memos_cnt,         -- 5.請求書件数(IN)(クレジットメモ)
                  ln_credit_memo_app_cnt,      -- 6.請求書件数(IN)(クレジットメモ消込)
                  ln_cross_currency_cnt,       -- 7.請求書件数(IN)(相互通貨)
                  iv_journal_source,           -- 8.仕訳ソース名(IN)
                  lv_sales_invoices,           -- 9.仕訳カテゴリ名(売上請求書)(IN)
                  lv_trade_receipts,           -- 10.仕訳カテゴリ名(売掛／未収金入金)(IN)
                  lv_adjustment,               -- 11.仕訳カテゴリ名(修正)(IN)
                  lv_credit_memos,             -- 12.仕訳カテゴリ名(クレジットメモ)(IN)
                  lv_credit_memo_applications, -- 13.仕訳カテゴリ名(クレジットメモ消込)(IN)
                  lv_cross_currency,           -- 14.仕訳カテゴリ名(相互通貨)(IN)
                  ov_errbuf,               --   エラー・メッセージ           --# 固定 #
                  ov_retcode,              --   リターン・コード             --# 固定 #
                  ov_errmsg);              --   ユーザー・エラー・メッセージ --# 固定 #
                IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
                  --(エラー処理)
                  RAISE global_process_expt;
                END IF;
               -- Ver11.5.10.1.6 2005/12/15 Delete Start
               --END IF;
               -- Ver11.5.10.1.6 2005/12/15 Delete End
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ###################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN xx00_global_pkg.global_api_others_expt THEN  --*** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
--####################################  固定部 END   ##########################################
--
  END submain;
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_je_source  IN  VARCHAR2,      --   1.仕訳ソース名
    iv_group_id   IN  VARCHAR2)      --   2.グループID
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main';  -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
  BEGIN
    -- ===============================
    -- ログヘッダの出力
    -- ===============================
    xx00_file_pkg.log_header;
--
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
      iv_je_source,     -- 1.仕訳ソース名
      iv_group_id,      -- 2.グループID
      lv_errbuf,        -- エラー・メッセージ           --# 固定 #
      lv_retcode,       -- リターン・コード             --# 固定 #
      lv_errmsg);       -- ユーザー・エラー・メッセージ --# 固定 #
--
--###########################  固定部 START   #####################################################
    -- ======================
    -- エラー・メッセージ出力
    -- ======================
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      IF (lv_errmsg IS NULL) THEN
        --定型メッセージ・セット
        lv_errmsg := xx00_message_pkg.get_msg('XX00','APP-XX00-00001');
      ELSIF (lv_errbuf IS NULL) THEN
        --ユーザー・エラー・メッセージのコピー
        lv_errbuf := lv_errmsg;
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      xx00_file_pkg.output(lv_errmsg);
    END IF;
    -- ===============================
    -- ログフッタの出力
    -- ===============================
    xx00_file_pkg.log_footer;
    -- ==================================
    -- リターン・コードのセット、終了処理
    -- ==================================
    retcode := lv_retcode;
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
  EXCEPTION
    WHEN xx00_global_pkg.global_api_others_expt THEN     -- *** 共通関数OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
    WHEN OTHERS THEN                              -- *** OTHERS例外ハンドラ ***
        errbuf := cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM;
        retcode := xx00_common_pkg.set_status_error_f;
  END main;
END XX033JU001C;
/
