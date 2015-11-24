CREATE OR REPLACE PACKAGE BODY XX032JU001C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX032JU001C(body)
 * Description      : 一般会計システム上のデータに、買掛管理システムで保持するDFFの値を更新します。
 * MD.050           : AP 仕訳付加情報更新処理 OCSJ/BFAFIN/MD050/F204
 * MD.070           : AP 仕訳付加情報更新処理 OCSJ/BFAFIN/MD070/F204
 * Version          : 11.5.10.1.7
 *
 * Program List
 * ---------------------------------- ----------------------------------------------
 *  Name                              Description
 * ---------------------------------- ----------------------------------------------
 *  get_id                            関連データ取得(A-1)
 *  get_add_dff_data                  DFF付加対象データ抽出処理 (A-2)
 *  get_buying_in_invoices            仕入請求書DFF値更新(A-3-1)
 *  proc_tax_incr_decr_dff_values     税コード、増減事由の設定 (A-3-1-1)  2004/03/03 削除
 *  get_tax_code                      税コードの取得 (A-3-1-1-1)
 *  proc_adj_slip_num                 修正元伝票番号の設定 (A-3-1-2)      2004/03/03 削除
 *  proc_detail_desc                  明細摘要の設定 (A-3-1-3)            2004/03/03 削除
 *  proc_slip_num_and_others          伝票番号、その他項目の設定 (A-3-1-4、A-3-1-5)
 *  proc_app_ref_dff_values           消込参照の設定 (A-3-1-6)            2004/03/03 削除
 *  proc_dff_values_not_liability     税コード、増減事由、予備１、予備２、
 *                                    消込用照合の設定 (A-3-1-1、A-3-1-6) 2004/03/03 追加
 *  get_payment                       支払請求書DFF値更新 (A-3-2)
 *  proc_slip_num_journal_name        伝票番号、仕訳名称の設定 (A-3-2-1)
 *  proc_detail_desc_unpaid           明細摘要(支払：未払金AP)の設定 (A-3-2-2)
 *  proc_detail_desc_desposit         明細摘要(支払：預金)の設定 (A-3-2-3)
 *  proc_adj_slip_num_cancel          修正元伝票番号(支払取消)の設定 (A-3-2-4)  2004/03/03 削除
 *  upd_journal_data                  仕訳データの更新処理 (A-4)
 *  msg_output                        プルーフリスト出力処理 (A-5)
 *  upd_reference10                   リファレンス10更新(A-6)             2015/10/13 追加
 *  submain                           メイン処理プロシージャ
 *  main                              コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ------------- ---------------- -------------------------------------------------
 *  Date          Ver.          Editor           Description
 * ------------- ------------- ---------------- -------------------------------------------------
 *  2004/01/15    1.0           H.Ogawa           新規作成
 *  2004/01/27    1.1           H.Ogawa           単体テスト障害修正
 *  2004/02/10    1.2           H.Ogawa           結合テスト障害修正
 *  2004/02/24    1.3           H.Ogawa           システムテスト障害修正
 *  2004/03/19    1.4           H.Ogawa           仕入請求書、前払金充当時の為替差損益、消込行の場合の
 *                                                対応を追加。
 *                                                支払時の端数処理行の場合の対応を追加。
 *  2004/03/26    1.5           H.Ogawa           仕入請求書、前払金等で発生する行番号を持たない
 *                                                自動生成伝票に対するDFF付加処理に対する不具合対処
 *  2004/04/20    1.6           H.Ogawa           支払時、請求書IDの取得方法の修正
 *  2004/06/28    1.7           T.Maeda           支払預金であるかの判断条件に預金(CASH)の場合も追加
 *  2005/02/25    1.8           M.Umeda           障害268「伝票番号に連携する番号誤り」に対応
 *  2005/07/12    11.5.10.1.4   S.Yamada          明細摘要の設定(支払：預金)で個別支払に対応
 *  2005/08/04    11.5.10.1.4B  S.Yamada          仕訳明細科目タイプが'RECOVERABLE TAX'、'AP ACCRUAL'のデータの
 *                                                税コード、増減事由、予備１、予備２、消込用照合キーが設定されるように修正
 *  2005/08/19    11.5.10.1.4C  Y.Matsumura       仕訳明細科目タイプが'FUTURE PAYMENT'のデータが(支払：預金)
 *                                                として処理されるように変更
 *  2006/03/17    11.5.10.1.6   S.Morisawa        CU2でfnd_message.set_tokenの引数による動きの変更で
 *                                                エラーとなる場合があるため、引数を正しく送るように修正
 *  2015/10/13    11.5.10.1.7   Y.Shoji           E_本稼動_13334対応 「A-6．リファレンス10更新」を追加
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
  cv_package_name     CONSTANT VARCHAR2(20) := 'XX032JU001';              --パッケージ名
  cv_execite_tbl_name CONSTANT VARCHAR2(20) := 'GL_INTERFACE';            --処理対象テーブル名
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  get_org_id_expt       EXCEPTION;            -- オルグID未取得エラー
  get_books_id_expt     EXCEPTION;            -- 会計帳簿ID未取得エラー
  warning_status_expt     EXCEPTION;          -- ユーザーエラーハンドル用
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : プルーフリスト出力処理 (A-5)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id                   IN NUMBER,       -- 1.オルグID(IN)
    in_buyning_cnt              IN NUMBER,       -- 2.仕入請求書件数(IN)
    in_payment_cnt              IN NUMBER,       -- 3.支払件数(IN)
    iv_journal_source           IN VARCHAR2,     -- 4.仕訳ソース名(IN)
    iv_buyning_in_invoice       IN VARCHAR2,     -- 5.仕訳カテゴリ別件数(仕入請求書)(IN)
    iv_payment_type             IN VARCHAR2,     -- 6.仕訳カテゴリ別件数(支払)(IN)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    cv_lookup_type_category   CONSTANT VARCHAR2(50) := 'XX03_AP_JOURNAL_CATEGORY';
    -- LOOKUP_TYPE値(件数)
    cv_lookup_type_count      CONSTANT VARCHAR2(50) := 'XX03_AP_COUNT';
--
    -- *** ローカル変数 ***
    lv_msgbuf  VARCHAR2(300);     -- 出力メッセージ
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
    lv_category VARCHAR2(30);     -- 画面表示名(仕訳カテゴリ)
    lv_count    VARCHAR2(10);     -- 画面表示名(件数)
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
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    -- メッセージより画面表示名を取得
    -- 仕訳カテゴリ
    lv_category := xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-02017'); -- メッセージ区分
    -- 件数
    lv_count := xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-02018'); -- メッセージ区分
    -- 正常終了時の画面出力
    -- 見出し部分の表示
    xx03_header_line_output_pkg.header_line_output_p('AP',
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
    -- 5行目(更新件総数)
    xx00_message_pkg.set_name('XX00','APP-XX00-00019');
-- ver 11.5.10.1.6 Chg Start
    --xx00_message_pkg.set_token('COUNT',
    --  TO_CHAR(in_buyning_cnt + in_payment_cnt,'99999'),
    --  TRUE);
    xx00_message_pkg.set_token('COUNT',
      TO_CHAR(in_buyning_cnt + in_payment_cnt,'99999'),
      FALSE);
-- ver 11.5.10.1.6 Chg End
    -- 6行目(処理結果  項目)
    xx00_file_pkg.output(RPAD(lv_category,24,' ') || 
      LPAD(lv_count,7,' '));
    -- 7行目(処理結果  仕入請求書)
    xx00_file_pkg.output(RPAD(iv_buyning_in_invoice,24,' ') || 
      TO_CHAR(in_buyning_cnt,'999999'));
    -- 8行目(処理結果  支払)
    xx00_file_pkg.output(RPAD(iv_payment_type,24,' ') || 
      TO_CHAR(in_payment_cnt,'999999'));
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
    --正常処理後のログ出力
    lv_msgbuf := xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-06016'); -- メッセージ区分(情報)
    lv_msgbuf := lv_msgbuf || cv_package_name || ' ';
    lv_msgbuf := lv_msgbuf || xx00_message_pkg.get_msg(
      'XX03',  --アプリケーション短縮名
      'APP-XX03-06019',
      'TOK_TABLE',
      cv_execite_tbl_name,
      'COUNT',
      TO_CHAR(in_buyning_cnt + in_payment_cnt,'99999'));
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
  /**********************************************************************************
   * Procedure Name   : get_id
   * Description      : 関連データ取得 (A-1)
   ***********************************************************************************/
  PROCEDURE get_id(
    on_gl_book_id           OUT NUMBER,       --   1.会計帳簿帳簿ID(OUT)
    on_org_id               OUT NUMBER,       --   2.オルグID(OUT)
    ov_buyning_in_invoice   OUT VARCHAR2,     --   3.仕訳カテゴリ名(仕入請求書)(OUT)
    ov_payment_type         OUT VARCHAR2,     --   4.仕訳カテゴリ名(支払)(OUT)
    ov_errbuf               OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
      'XX03_AP_JOURNAL_TYPE'; -- LOOKUP_TYPE値
    cv_lookup_code_buying   CONSTANT VARCHAR2(50) := 
      'BUYING_IN_INVOICE'; -- LOOKUP_CODE値(仕入請求書)
    cv_lookup_code_payment  CONSTANT VARCHAR2(50) := 
      'PAYMENT_TYPE'; -- LOOKUP_CODE値(支払)
--
    -- *** ローカル変数 ***
    lv_category_err_tk    VARCHAR2(50); -- 仕訳カテゴリ未取得エラートークン値
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
    xx00_file_pkg.log(' ');
    --オルグIDの取得
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    --オルグID値の検証
    IF (on_org_id IS NULL) THEN
      -- オルグID未取得エラー
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-22001');
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
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06002');
      RAISE get_books_id_expt;
    END IF;
--
    --仕訳カテゴリ名(仕入請求書)の取得
    SELECT  xlxv.meaning
    INTO    ov_buyning_in_invoice
    FROM  xx03_lookups_xx03_v xlxv
    WHERE xlxv.lookup_type = cv_lookup_type_category
    AND xlxv.enabled_flag = 'Y'
    AND xlxv.lookup_code = cv_lookup_code_buying;
    --仕訳カテゴリ名(支払)の取得
    SELECT  xlxv.meaning
    INTO    ov_payment_type
    FROM  xx03_lookups_xx03_v xlxv
    WHERE xlxv.lookup_type = cv_lookup_type_category
    AND xlxv.enabled_flag = 'Y'
    AND xlxv.lookup_code = cv_lookup_code_payment;
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
    WHEN NO_DATA_FOUND THEN                       --*** 仕訳カテゴリ判断値未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      -- 取得できなかった仕訳カテゴリの判断
      IF ov_buyning_in_invoice IS NULL THEN
        lv_category_err_tk := cv_lookup_code_buying;
        IF ov_payment_type IS NULL THEN
          lv_category_err_tk := lv_category_err_tk || cv_lookup_code_payment;
        END IF;
      ELSE
        lv_category_err_tk := cv_lookup_code_payment;
      END IF;
      -- エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06013',
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
   * Procedure Name   : get_tax_code
   * Description      : 税コードの取得 (A-3-1-1-1)
   ***********************************************************************************/
  PROCEDURE get_tax_code(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_tax_code_id              IN NUMBER,      -- 2.税コードID(IN)
    iov_tax_code                IN OUT VARCHAR2, -- 3.税コード(IN OUT)
    in_invoice_id               IN NUMBER,      -- 4.請求書ID(IN)
    in_dist_line_number         IN NUMBER,      -- 5.請求書明細番号(IN)
    ov_errbuf                   OUT VARCHAR2,   --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,   --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)   --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_tax_code'; -- プログラム名
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
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_tax_codes_all');
    xx00_file_pkg.log('key tax_id=' || TO_CHAR(in_tax_code_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 税コードマスタから税コードを取得して設定する
    SELECT  name AS tax_name       -- 税コード
    INTO    iov_tax_code           -- 税コード
    FROM    ap_tax_codes_all atca
    WHERE   atca.tax_id = in_tax_code_id
    AND     atca.org_id = in_org_id;
    -- ログ出力
    xx00_file_pkg.log('update tax_name=' || TO_CHAR(iov_tax_code));
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 税コードの未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06015',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END get_tax_code;
-- Ver1.3 add start 関数の統廃合の為追加
  /**********************************************************************************
   * Procedure Name   : proc_dff_values_not_liability
   * Description      : 税コード、増減事由、
   *                    予備１、予備２、消込用照合の設定 (A-3-1-1、A-3-1-6)
   ***********************************************************************************/
  PROCEDURE proc_dff_values_not_liability(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_invoice_id               IN NUMBER,      -- 2.請求書ID(IN)
    in_dist_line_number         IN NUMBER,      -- 3.請求書明細番号(IN)
    iov_tax_code                IN OUT VARCHAR2,  -- 4.税コード(IN OUT)
    iov_incr_decr               IN OUT VARCHAR2,  -- 5.増減事由(IN OUT)
    iov_app_ref                 IN OUT VARCHAR2,  -- 6.消込用照合(IN OUT)
    iov_reserve1                IN OUT VARCHAR2,  -- 7.予備１(IN OUT)
    iov_reserve2                IN OUT VARCHAR2,  -- 8.予備２(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_dff_values_not_liability'; -- プログラム名
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
    ln_tax_code_id  ap_invoice_distributions_all.tax_code_id%TYPE; -- 税コードID
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
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    -- 請求書明細一覧から税コードID、増減事由、
    -- 予備１、予備２、消込用照合を取得する
    -- 税コードIDを除く項目はそのまま設定する
    SELECT  tax_code_id AS tax_code_id,             -- 税コードID
            attribute1 AS increase_and_decrease,    -- 増減事由
            attribute9 AS reserve1,                 -- 予備１
            attribute10 AS reserve2,                -- 予備２
            attribute2 AS app_ref                   -- 消込用照合
    INTO    ln_tax_code_id,         -- 税コードID
            iov_incr_decr,          -- 増減事由
            iov_reserve1,           -- 予備１
            iov_reserve2,           -- 予備２
            iov_app_ref             -- 消込用照合
    FROM    ap_invoice_distributions_all aida
    WHERE   aida.invoice_id = in_invoice_id
    AND     aida.distribution_line_number = in_dist_line_number;
--    AND     aida.org_id = in_org_id;
--
    -- 税コードマスタから税コードを取得する
    -- 請求書明細一覧から税コードIDを取得できない(NULLだった)
    -- 場合は税コードにNULLをセットする
    IF ln_tax_code_id IS NOT NULL THEN
      get_tax_code(
        in_org_id,                    -- 1.オルグID(IN)
        ln_tax_code_id,               -- 2.税コードID(IN)
        iov_tax_code,                 -- 3.税コード(IN OUT)
        in_invoice_id,                -- 4.請求書ID(IN)
        in_dist_line_number,          -- 5.請求書明細番号(IN)
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
    ELSE
      iov_tax_code := NULL;
    END IF;
    -- ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
    WHEN NO_DATA_FOUND THEN                       --*** 税コード、増減事由の未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06015',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06004',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06011',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_dff_values_not_liability;
-- Ver1.3 add end 関数の統廃合の為追加
-- Ver1.3 Del start 関数の統廃合の為削除
  /**********************************************************************************
   * Procedure Name   : proc_tax_incr_decr_dff_values
   * Description      : 税コード、増減事由の設定 (A-3-1-1)
   ***********************************************************************************/
/*
  PROCEDURE proc_tax_incr_decr_dff_values(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_invoice_id               IN NUMBER,      -- 2.請求書ID(IN)
    in_dist_line_number         IN NUMBER,      -- 3.請求書明細番号(IN)
    iov_tax_code                IN OUT VARCHAR2,   -- 4.税コード(IN OUT)
    iov_incr_decr               IN OUT VARCHAR2,   -- 5.増減事由(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_tax_incr_decr_dff_values'; -- プログラム名
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
    ln_tax_code_id  ap_invoice_distributions_all.tax_code_id%TYPE; -- 税コードID
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
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_invoice_distributions_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key distribution_line_number=' || TO_CHAR(in_dist_line_number));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 請求書明細一覧から税コードID、増減事由を取得して、
    -- 増減事由は増減事由として設定する
    SELECT  tax_code_id AS tax_code_id,           -- 税コードID
            attribute1 AS increase_and_decrease   -- 増減事由
    INTO    ln_tax_code_id,       -- 税コードID
            iov_incr_decr         -- 増減事由
    FROM    ap_invoice_distributions_all aida
    WHERE   aida.invoice_id = in_invoice_id
    AND     aida.distribution_line_number = in_dist_line_number
    AND     aida.org_id = in_org_id;
--
    -- 税コードマスタから税コードを取得する
    -- Ver1.2 add 仕様変更 請求書明細一覧から税コードIDを取得できない(NULLだった)
    -- 場合は税コードにNULLをセットする
    IF ln_tax_code_id IS NOT NULL THEN      -- Ver1.2 add
      get_tax_code(
        in_org_id,                    -- 1.オルグID(IN)
        ln_tax_code_id,               -- 2.税コードID(IN)
        iov_tax_code,                 -- 3.税コード(IN OUT)
        in_invoice_id,                -- 4.請求書ID(IN)
        in_dist_line_number,          -- 5.請求書明細番号(IN)
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
    ELSE                                    -- Ver1.2 add
      iov_tax_code := NULL;                 -- Ver1.2 add
    END IF;
    -- ログ出力
    xx00_file_pkg.log('update tax_code_id=' || TO_CHAR(ln_tax_code_id));
    xx00_file_pkg.log('update increase_and_decrease=' || iov_incr_decr);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN warning_status_expt THEN                       --*** ユーザーエラーハンドル ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
    WHEN NO_DATA_FOUND THEN                       --*** 税コード、増減事由の未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06015',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06004',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_tax_incr_decr_dff_values;
*/
-- Ver1.3 Del End
-- Ver1.3 Del start 関数の統廃合の為削除
  /**********************************************************************************
   * Procedure Name   : proc_adj_slip_num
   * Description      : 修正元伝票番号の設定 (A3-1-2)
   ***********************************************************************************/
/*
  PROCEDURE proc_adj_slip_num(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_invoice_id               IN NUMBER,      -- 2.請求書ID(IN)
    iov_adj_slip_num            IN OUT VARCHAR2, -- 3.修正元伝票番号(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_adj_slip_num'; -- プログラム名
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
    xx00_file_pkg.log('select ap_invoices_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 請求書一覧から修正元伝票番号を取得して、それを修正元伝票番号として設定する
    SELECT  attribute5 AS adj_slip_num    -- 修正元伝票番号
    INTO    iov_adj_slip_num
    FROM    ap_invoices_all aia
    WHERE   aia.invoice_id = in_invoice_id;
    --ログ出力
    xx00_file_pkg.log('update adj_slip_num=' || iov_adj_slip_num);
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 修正元伝票番号未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06005',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_adj_slip_num;
-- Ver1.3 Del End
-- Ver1.3 Del start 仕様変更による不要の為削除
  /**********************************************************************************
   * Procedure Name   : proc_detail_desc
   * Description      : 明細摘要の設定 (A3-1-3)
   ***********************************************************************************/
/*
  PROCEDURE proc_detail_desc(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_invoice_id               IN NUMBER,      -- 2.請求書ID(IN)
    iov_slip_desc               IN OUT VARCHAR2, -- 3.明細摘要(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_detail_desc'; -- プログラム名
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
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_invoices_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 請求書一覧から明細摘要を取得して、それを明細摘要として設定する
    SELECT  attribute5 AS detail_desc   -- 明細摘要
    INTO    iov_slip_desc
    FROM    ap_invoices_all aia
    WHERE   aia.invoice_id = in_invoice_id
    AND     aia.org_id = in_org_id;
    -- ログ出力
    xx00_file_pkg.log('update detail_desc=' || iov_slip_desc);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 明細摘要未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06006',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_detail_desc;
*/
-- Ver1.3 Del end
  /**********************************************************************************
   * Procedure Name   : proc_slip_num_and_others
   * Description      : 伝票番号及びその他の項目の設定 (A-3-1-4、A-3-1-5)
   ***********************************************************************************/
  PROCEDURE proc_slip_num_and_others(
    in_org_id                   IN NUMBER,        -- 1.オルグID(IN)
    in_invoice_id               IN NUMBER,        -- 2.請求書ID(IN)
    iov_slip_num                IN OUT VARCHAR2,  -- 3.伝票番号(IN OUT)
    iov_je_name                 IN OUT VARCHAR2,  -- 4.仕訳名(IN OUT)
    iov_dept                    IN OUT VARCHAR2,  -- 5.起票部門(IN OUT)
    iov_input_user              IN OUT VARCHAR2,  -- 6.入力者(IN OUT)
--Ver1.3 add Start    関数統合の為追加
    iov_adj_slip_num            IN OUT VARCHAR2,  -- 7.修正元伝票番号(IN OUT)
--Ver1.3 add end
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_slip_num_and_others'; -- プログラム名
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
    xx00_file_pkg.log('select ap_invoices_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 請求書一覧から
    -- 請求書番号、文書番号、起票部門、入力者、修正元伝票番号を取得して、
    -- それを各々設定する
    SELECT  invoice_num AS invoice_num,               -- 請求書番号
            doc_sequence_value AS doc_sequence_value, -- 文書番号
            attribute3 AS department,                 -- 起票部門
            attribute4 AS input_user,                 -- 入力者
--Ver1.3 add Start    関数統合の為追加
            attribute5 AS adj_slip_num                -- 修正元伝票番号
--Ver1.3 add End
    INTO    iov_slip_num,        -- 伝票番号
            iov_je_name,         -- 仕訳名
            iov_dept,            -- 起票部門
            iov_input_user,      -- 入力者
--Ver1.3 add Start    関数統合の為追加
            iov_adj_slip_num    -- 修正元伝票番号
--Ver1.3 add end
    FROM    ap_invoices_all aia
    WHERE   aia.invoice_id = in_invoice_id;
    -- ログ出力
    xx00_file_pkg.log('update slip_num=' || iov_slip_num);
    xx00_file_pkg.log('update je_name=' || iov_je_name);
    xx00_file_pkg.log('update dept=' || iov_dept);
    xx00_file_pkg.log('update input_user=' || iov_input_user);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号及びその他の項目未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06007',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06008',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06009',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06010',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
--Ver1.3 add Start    関数統合の為追加
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06005',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id));
--Ver1.3 add End
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_slip_num_and_others;
-- Ver1.3 Del start 関数の統廃合の為削除
  /**********************************************************************************
   * Procedure Name   : proc_app_ref_dff_values
   * Description      : 消込参照の設定 (A-3-1-6)
   ***********************************************************************************/
/*
  PROCEDURE proc_app_ref_dff_values(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_invoice_id               IN NUMBER,      -- 2.請求書ID(IN)
    in_dist_line_number         IN NUMBER,      -- 3.請求書明細番号(IN)
    iov_app_ref                 IN OUT VARCHAR2, -- 4.消込参照(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_app_ref_dff_values'; -- プログラム名
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
    xx00_file_pkg.log('select ap_invoice_distributions_all');
    xx00_file_pkg.log('key invoice_id=' || TO_CHAR(in_invoice_id));
    xx00_file_pkg.log('key distribution_line_number=' || TO_CHAR(in_dist_line_number));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 請求書明細一覧から消込参照を取得して設定する
    SELECT  attribute2 AS app_ref     -- 消込参照
    INTO    iov_app_ref               -- 消込参照
    FROM    ap_invoice_distributions_all aida
    WHERE   aida.invoice_id = in_invoice_id
    AND     aida.distribution_line_number = in_dist_line_number
    AND     aida.org_id = in_org_id;
    -- ログ出力
    xx00_file_pkg.log('update app_ref=' || iov_app_ref);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 消込参照の未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06011',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_invoice_id) || ',' || TO_CHAR(in_dist_line_number));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_app_ref_dff_values;
*/
-- Ver1.3 Del End
  /**********************************************************************************
   * Procedure Name   : proc_slip_num_journal_name
   * Description      : 伝票番号、仕訳名称の設定 (A-3-2-1)
   ***********************************************************************************/
  PROCEDURE proc_slip_num_journal_name(
    in_org_id                   IN NUMBER,        -- 1.オルグID(IN)
    in_check_id                 IN NUMBER,        -- 2.支払バッチチェックID(IN)
    in_payment_id               IN NUMBER,        -- 3.請求書支払ID(IN)
    iov_je_name                 IN OUT VARCHAR2,   -- 4.仕訳名(IN OUT)
    iov_slip_num                IN OUT VARCHAR2,   -- 5.伝票番号(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_slip_num_journal_name'; -- プログラム名
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
--Ver1.8 Start Modify
--    ln_check_number  ap_checks_all.check_number%TYPE; -- 支払文書番号
    ln_doc_sequence_value ap_checks_all.doc_sequence_value%TYPE;  -- 証憑番号
--Ver1.8 End Modify
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
    xx00_file_pkg.log('select ap_checks_all');
    xx00_file_pkg.log('key check_id=' || TO_CHAR(in_check_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 支払バッチ情報から支払文書番号を取得する。
--Ver1.8 Start Modify
--    SELECT  check_number AS check_number  -- 支払文書番号
--    INTO    ln_check_number
    SELECT  doc_sequence_value AS doc_sequence_value  -- 証憑番号
    INTO    ln_doc_sequence_value
    FROM    ap_checks_all aca
    WHERE   aca.check_id = in_check_id
    AND     aca.org_id = in_org_id;
--Ver1.8 End Modify
--
    -- 支払文書番号を伝票番号、仕訳名称として設定する
--Ver1.8 Start Modify
--    iov_je_name := TO_CHAR(ln_check_number);
--    iov_slip_num := TO_CHAR(ln_check_number);
    iov_je_name := TO_CHAR(ln_doc_sequence_value);
    iov_slip_num := TO_CHAR(ln_doc_sequence_value);
--Ver1.8 End Modify
    -- ログ出力
    xx00_file_pkg.log('update je_name=' || iov_je_name);
    xx00_file_pkg.log('update slip_num=' || iov_slip_num);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 伝票番号、仕訳名称未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06007',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      lv_errbuf := lv_errbuf || '  ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06010',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_slip_num_journal_name;
  /**********************************************************************************
   * Procedure Name   : proc_detail_desc_unpaid
   * Description      : 明細摘要(支払：未払金AP)の設定 (A-3-2-2)
   ***********************************************************************************/
  PROCEDURE proc_detail_desc_unpaid(
    in_org_id                   IN NUMBER,        -- 1.オルグID(IN)
    in_payment_id               IN NUMBER,        -- 2.請求書支払ID(IN)
    iov_slip_desc               IN OUT VARCHAR2,   -- 3.明細摘要(IN OUT)
-- Ver1.6 change start 請求書支払IDから請求書IDを検索せず、GL_INTERFACEの請求書IDを
--                     そのまま使用する
    in_invoice_id               IN NUMBER,        -- 4.請求書ID(IN)
-- Ver1.6 change end
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_detail_desc_unpaid'; -- プログラム名
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
    ln_invoice_id   ap_invoices_all.invoice_id%TYPE; -- 請求書ID
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
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_invoice_payments_all');
-- Ver1.6 change start
--    xx00_file_pkg.log('key invoice_payment_id=' || TO_CHAR(in_payment_id));
    xx00_file_pkg.log('key in_invoice_id=' || TO_CHAR(in_invoice_id));
-- Ver1.6 change end
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
-- Ver1.6 delete start 請求書ID取得処理は不要の為削除
--  -- 請求書支払から請求書番号を取得して、それを明細摘要として設定する
-- Ver1.3 change start 仕様バグ修正 
--    SELECT  TO_CHAR(invoice_id) AS invoice_id  -- 請求書番号
--    INTO    iov_slip_desc
--    SELECT  aip.invoice_id AS invoice_id  -- 請求書ID
--    INTO    ln_invoice_id
-- Ver1.3 change end
--    FROM    ap_invoice_payments_all aip
--    WHERE   aip.invoice_payment_id = in_payment_id;
-- Ver1.3 del start 仕様バグ修正 
--    AND     aip.org_id = in_org_id;
-- Ver1.3 del start 仕様バグ修正 
-- Ver1.6 delete end
    -- 請求書IDから請求書番号を取得
    SELECT  aia.invoice_num AS invoice_num    -- 請求書番号
    INTO    iov_slip_desc
    FROM    ap_invoices_all aia
-- Ver1.6 change start
--    WHERE   aia.invoice_id = ln_invoice_id;
    WHERE   aia.invoice_id = in_invoice_id;
-- Ver1.6 change end
    -- ログ出力
    xx00_file_pkg.log('update slip_desc=' || iov_slip_desc);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 明細摘要未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06006',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_detail_desc_unpaid;
  /**********************************************************************************
   * Procedure Name   : proc_detail_desc_desposit
   * Description      : 明細摘要(支払：預金)の設定 (A-3-2-3)
   ***********************************************************************************/
  PROCEDURE proc_detail_desc_desposit(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_check_id                 IN NUMBER,      -- 2.支払バッチチェックID(IN)
    in_payment_id               IN NUMBER,      -- 3.請求書支払ID(IN)
    iov_slip_desc               IN OUT VARCHAR2, -- 4.明細摘要(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_detail_desc_desposit'; -- プログラム名
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
-- Ver11.5.10.1.4 change start
    lv_checkrun_name  ap_checks_all.checkrun_name%TYPE; -- 支払バッチ名
    ln_check_number   ap_checks_all.check_number%TYPE;  -- 文書番号
    ln_checkrun_id    ap_checks_all.checkrun_id%TYPE;   -- 支払バッチＩＤ
-- Ver11.5.10.1.4 change end
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
    -- ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log('select ap_checks_all');
    xx00_file_pkg.log('key check_id=' || TO_CHAR(in_check_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
-- Ver11.5.10.1.4 change start
    -- 支払バッチ情報から支払バッチ名、文書番号、支払バッチＩＤを取得する。
    SELECT  checkrun_name AS checkrun_name, -- 支払バッチ名
            check_number  AS check_number,  -- 文書番号
            checkrun_id   AS checkrun_id    -- 支払バッチＩＤ
    INTO    lv_checkrun_name,
            ln_check_number,
            ln_checkrun_id 
    FROM    ap_checks_all aca
    WHERE   aca.check_id = in_check_id
    AND     aca.org_id = in_org_id;
    -- 支払バッチＩＤがNULLでない場合(支払バッチ)は支払バッチ名を設定する。
    -- それ以外の場合(個別支払)は文書番号を設定する。
    IF (ln_checkrun_id IS NOT NULL) THEN
      iov_slip_desc := lv_checkrun_name;
    ELSE
      iov_slip_desc := TO_CHAR(ln_check_number);
    END IF;
-- Ver11.5.10.1.4 change end
    -- ログ出力
    xx00_file_pkg.log('update checkrun_name=' || iov_slip_desc);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 明細摘要未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06006',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_detail_desc_desposit;
-- Ver1.3 Del start 仕様変更による不要の為削除
  /**********************************************************************************
   * Procedure Name   : proc_adj_slip_num_cancel
   * Description      : 修正元伝票番号(支払取消)の設定 (A-3-2-4)
   ***********************************************************************************/
/*
  PROCEDURE proc_adj_slip_num_cancel(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    in_check_id                 IN NUMBER,      -- 2.支払バッチチェックID(IN)
    in_payment_id               IN NUMBER,      -- 3.請求書支払ID(IN)
    iov_adj_slip_num            IN OUT VARCHAR2,   -- 4.修正元伝票番号(IN OUT)
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'proc_adj_slip_num_cancel'; -- プログラム名
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
    xx00_file_pkg.log('select ap_checks_all');
    xx00_file_pkg.log('key check_id=' || TO_CHAR(in_check_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
    -- 支払バッチ情報から支払文書番号を取得する。
    SELECT  TO_CHAR(check_number) AS check_number  -- 支払文書番号
    INTO    iov_adj_slip_num
    FROM    ap_checks_all aca
    WHERE   aca.check_id = in_check_id
    AND     aca.org_id = in_org_id;
    -- ログ出力
    xx00_file_pkg.log('update check_number=' || iov_adj_slip_num);
    xx00_file_pkg.log('<<'||cv_prg_name || '() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                       --*** 修正元伝票番号未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06005',
        'TOK_XX03_DFF_KEY',
        TO_CHAR(in_payment_id));
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
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
  END proc_adj_slip_num_cancel;
*/
-- Ver1.3 Del end
  /**********************************************************************************
   * Procedure Name   : upd_journal_data
   * Description      : 仕訳データの更新処理 (A-4)
   ***********************************************************************************/
  PROCEDURE upd_journal_data(
    iv_je_name              IN VARCHAR2,    -- 1.仕訳名(IN)
    iv_slip_desc            IN VARCHAR2,    -- 2.明細摘要(IN)
    iv_tax_code             IN VARCHAR2,    -- 3.税コード(IN)
    iv_incr_decr            IN VARCHAR2,    -- 4.増減事由(IN)
    iv_slip_num             IN VARCHAR2,    -- 5.伝票番号(IN)
    iv_dept                 IN VARCHAR2,    -- 6.起票部門(IN)
    iv_input_user           IN VARCHAR2,    -- 7.入力者(IN)
    iv_adj_slip_num         IN VARCHAR2,    -- 8.修正元伝票番号(IN)
    ir_rowid                IN ROWID,       -- 9.ROWID(IN)
    iv_je_soruce            IN VARCHAR2,    -- 10.仕訳ソース名(IN)
    iv_app_ref              IN VARCHAR2,    -- 11.消込参照(IN)
--Ver1.2 Add Start  仕様変更により追加
    iv_context_name         IN VARCHAR2,    -- 12.会計帳簿(コンテキスト)名(IN)
--Ver1.2 Add End
--Ver1.3 Add Start  仕様変更により追加
    iv_reserve1             IN VARCHAR2,    -- 13.予備１(IN)
    iv_reserve2             IN VARCHAR2,    -- 14.予備２(IN)
--Ver1.3 Add end
    ov_errbuf               OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
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
    xx00_file_pkg.log(' ');
    --GLインターフェースグループID取得
    SELECT TO_NUMBER(attribute1)
    INTO   ln_group_id
    FROM   gl_je_sources_tl
    WHERE  user_je_source_name = iv_je_soruce
    AND    language = xx00_global_pkg.current_language;
--
    --GLインターフェース更新処理
    UPDATE gl_interface
    SET    reference4 = iv_je_name,         -- 仕訳名
           reference10 = iv_slip_desc,      -- 明細摘要
           attribute1 = iv_tax_code,        -- 税コード
           attribute2 = iv_incr_decr,       -- 増減事由
           attribute3 = iv_slip_num,        -- 伝票番号
           attribute4 = iv_dept,            -- 起票部門
           attribute5 = iv_input_user,      -- 入力者
           attribute6 = iv_adj_slip_num,    -- 修正元伝票番号
           jgzz_recon_ref = iv_app_ref,     -- 消込参照
-- Ver.1.3 add グループIDのDFF追加
           group_id = ln_group_id,          -- グループID
-- Ver.1.3 add end
-- Ver.1.3 add 予備１、予備２のDFF追加
           attribute9 = iv_reserve1,        -- 予備１
           attribute10 = iv_reserve2,       -- 予備２
-- Ver.1.3 add end
-- Ver.1.2 add 仕様追加　コンテキスト値として会計帳簿名
           context = iv_context_name        -- コンテキスト
-- Ver.1.2 add end
    WHERE  ROWID = ir_rowid;
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
  /**********************************************************************************
   * Procedure Name   : get_buying_in_invoices
   * Description      : 仕入請求書DFF値更新 (A3-1)
   ***********************************************************************************/
  PROCEDURE get_buying_in_invoices(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    iv_journal_type             IN VARCHAR2,    -- 2.仕訳明細科目タイプ(IN)
    in_entered_dr               IN NUMBER,      -- 3.借方金額(IN)
    in_invoice_id               IN NUMBER,      -- 4.請求書ID(IN)
    in_dist_line_number         IN NUMBER,      -- 5.請求書明細番号(IN)
    iov_je_name                 IN OUT VARCHAR2,   -- 6.仕訳名(IN OUT)
--Ver1.3 Del Start  仕様変更により不要となったので削除
--    iov_slip_desc               IN OUT VARCHAR2,   -- 7.明細摘要(IN OUT)
--Ver1.3 Del end
    iov_tax_code                IN OUT VARCHAR2,   -- 7.税コード(IN OUT)
    iov_incr_decr               IN OUT VARCHAR2,   -- 8.増減事由(IN OUT)
    iov_slip_num                IN OUT VARCHAR2,   -- 9.伝票番号(IN OUT)
    iov_dept                    IN OUT VARCHAR2,   -- 10.起票部門(IN OUT)
    iov_input_user              IN OUT VARCHAR2,   -- 11.入力者(IN OUT)
    iov_adj_slip_num            IN OUT VARCHAR2,   -- 12.修正元伝票番号(IN OUT)
    iov_app_ref                 IN OUT VARCHAR2,   -- 13.消込用照合キー(IN OUT)
--Ver1.3 Add Start  仕様変更により追加
    iov_reserve1                IN OUT VARCHAR2,   -- 14.予備１(IN OUT)
    iov_reserve2                IN OUT VARCHAR2,   -- 15.予備２(IN OUT)
--Ver1.3 Add end
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_buying_in_invoices'; -- プログラム名
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
    xx00_file_pkg.log('journal_type=' || iv_journal_type);
    xx00_file_pkg.log('entered_dr=' || TO_CHAR(in_entered_dr));
--Ver1.3 change Start 仕様変更により変更
-- ○仕様 2004/03/03
-- 仕訳明細カテゴリが「仕入請求書」の場合以下の項目を設定する
-- ・伝票番号、起票部門、仕訳名、入力者、修正元伝票番号
-- 明細が債務行以外の場合、以下の項目も設定する。
-- ・税コード、増減事由、予備１、予備２、消込用照合キー(消込参照)
-- 明細が債務行であるか否かは仕訳明細科目タイプが未払金AP(LIABILITY)で
-- あるものを債務行とする。
    -- =============================================================
    -- 伝票番号、起票部門、仕訳名、入力者、修正元伝票番号の設定 
    -- (A-3-1-2、A-3-1-4、A-3-1-5)
      -- ○設定するDFF値を同じテーブルの同じキーによって検索するので
      -- 　パフォーマンス向上(DBアクセス数減)の為、
      -- 　以下２つの関数を一つにまとめる
      --  ・proc_slip_num_and_others
      --  ・proc_adj_slip_num
      -- ============================================================
    proc_slip_num_and_others(
      in_org_id,                     -- 1.オルグID(IN)
      in_invoice_id,                 -- 2.請求書ID(IN)
      iov_slip_num,                  -- 3.伝票番号(IN OUT)
      iov_je_name,                   -- 4.仕訳名(IN OUT)
      iov_dept,                      -- 5.起票部門(IN OUT)
      iov_input_user,                -- 6.入力者(IN OUT)
--Ver1.3 add Start    関数統合の為追加
      iov_adj_slip_num,              -- 7.修正元伝票番号(IN OUT)
--Ver1.3 add end
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
--Ver1.4 change start
    -- 明細が債務行(仕訳明細科目タイプが未払金AP)以外かの判断
    -- 2004/03/19 債務行(LIABILITY)以外に為替差益(GAIN)、為替差損(LOSS)、
    --            消込行(WRITEOFF)にも税コード、増減事由、予備１等の
    --            付加の必要が無い(できない)為、上記の行に付加処理を
    --            行わない(費用、消費税、前払金に行う)ように判断文を変更。
    --IF iv_journal_type <> 'LIABILITY' THEN
    IF iv_journal_type = 'CHARGE' OR
      iv_journal_type = 'NONRECOVERABLE TAX' OR
-- Ver11.5.10.1.4B add start
      iv_journal_type = 'AP ACCRUAL' OR
      iv_journal_type = 'RECOVERABLE TAX' OR
-- Ver11.5.10.1.4B add end
      iv_journal_type = 'PREPAY' THEN
--Ver1.4 change END
      -- ============================================================
      -- 税コード、増減事由(A-3-1-1)、
      -- 予備１、予備２、消込用照合キーの設定 (A-3-1-6)
      -- ○設定するDFF値を同じテーブルの同じキーによって検索するので
      -- 　パフォーマンス向上(DBアクセス数減)の為、
      -- 　以下２つの関数を一つにまとめる
      --  ・proc_tax_incr_decr_dff_values
      --  ・proc_app_ref_dff_values
      -- ============================================================
--Ver1.5 add start
      -- 2004/03/26 前払金行等、請求書明細番号を持たない伝票(自動作成伝票)は
      --            下記DFF付加処理を行えない為、請求書明細番号を持つ行のみ
      --            下記DFF付加処理を行う仕様追加
      IF in_dist_line_number IS NOT NULL THEN
        proc_dff_values_not_liability(
          in_org_id,                    -- 1.オルグID(IN)
          in_invoice_id,                -- 2.請求書ID(IN)
          in_dist_line_number,          -- 3.請求書明細番号(IN)
          iov_tax_code,                 -- 4.税コード(IN OUT)
          iov_incr_decr,                -- 5.増減事由(IN OUT)
          iov_app_ref,                  -- 6.消込用照合キー(IN OUT)
          iov_reserve1,                 -- 7.予備１(IN OUT)
          iov_reserve2,                 -- 8.予備２(IN OUT)
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
--Ver1.5 add End
    END IF;
/*
    -- 仕訳明細科目タイプが未払金AP、前払金以外かの判断
    IF iv_journal_type <> 'LIABILITY' AND iv_journal_type <> 'PREPAY' THEN
      -- =====================================
      -- 税コード、増減事由の設定 (A-3-1-1)
      -- =====================================
      proc_tax_incr_decr_dff_values(
        in_org_id,                    -- 1.オルグID(IN)
        in_invoice_id,                -- 2.請求書ID(IN)
        in_dist_line_number,          -- 3.請求書明細番号(IN)
        iov_tax_code,                  -- 4.税コード(IN OUT)
        iov_incr_decr,                 -- 5.増減事由(IN OUT)
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
--
    -- 仕訳明細科目タイプが前払金以外かつ借方金額がNULLであるかの判断
    IF iv_journal_type <> 'PREPAY' AND in_entered_dr IS NULL THEN
      -- =====================================
      -- 修正元伝票番号の設定 (A-3-1-2)
      -- =====================================
      proc_adj_slip_num(
        in_org_id,                    -- 1.オルグID(IN)
        in_invoice_id,                -- 2.請求書ID(IN)
        iov_adj_slip_num,             -- 3.修正元伝票番号(IN OUT)
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
    END IF;
--
    -- 仕訳明細科目タイプが未払金AP、消費税以外かつ借方金額がNULLであるかの判断
--    IF iv_journal_type <> 'LIABILITY' AND     -- Ver1.2 DEL
      IF iv_journal_type <> 'LIABILITY' AND     -- Ver1.2 change
       iv_journal_type <> 'NONRECOVERABLE TAX' AND 
       in_entered_dr IS NULL THEN
      -- =====================================
      -- 明細摘要の設定 (A-3-1-3)
      -- =====================================
      proc_detail_desc(
        in_org_id,                    -- 1.オルグID(IN)
        in_invoice_id,                -- 2.請求書ID(IN)
        iov_slip_desc,                -- 3.明細摘要(IN OUT)
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
      -- 仕様追加2004.1.20
      -- =====================================
      -- 消込参照の設定 (A-3-1-6)
      -- =====================================
      proc_app_ref_dff_values(
        in_org_id,                    -- 1.オルグID(IN)
        in_invoice_id,                -- 2.請求書ID(IN)
        in_dist_line_number,          -- 3.請求書明細番号(IN)
        iov_app_ref,                  -- 4.消込参照(IN OUT)
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
    END IF;
--
    -- ==============================================
    -- 伝票番号、その他項目の設定 (A-3-1-4、A-3-1-5)
    -- ==============================================
    proc_slip_num_and_others(
      in_org_id,                     -- 1.オルグID(IN)
      in_invoice_id,                 -- 2.請求書ID(IN)
      iov_slip_num,                  -- 3.伝票番号(IN OUT)
      iov_je_name,                   -- 4.仕訳名(IN OUT)
      iov_dept,                      -- 5.起票部門(IN OUT)
      iov_input_user,                -- 6.入力者(IN OUT)
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
*/
--Ver1.3 change End
    --ログ出力
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
  END get_buying_in_invoices;
  /**********************************************************************************
   * Procedure Name   : get_payment
   * Description      : 支払請求書DFF値更新 (A-3-2)
   ***********************************************************************************/
  PROCEDURE get_payment(
    in_org_id                   IN NUMBER,      -- 1.オルグID(IN)
    iv_journal_type             IN VARCHAR2,    -- 2.仕訳明細科目タイプ(IN)
--Ver1.3 Del Start  仕様変更により不要となったので削除
--    in_entered_dr               IN NUMBER,      -- 3.借方金額(IN)
--    in_entered_cr               IN NUMBER,      -- 4.貸方金額(IN)
--Ver1.3 Del End
    in_payment_id               IN NUMBER,        -- 3.請求書支払ID(IN)
    iov_je_name                 IN OUT VARCHAR2,   -- 4.仕訳名(IN OUT)
    iov_slip_desc               IN OUT VARCHAR2,   -- 5.明細摘要(IN OUT)
    iov_slip_num                IN OUT VARCHAR2,   -- 6.伝票番号(IN OUT)
--Ver1.3 Del Start  仕様変更により不要となったので削除
--    iov_adj_slip_num            IN OUT VARCHAR2,   -- 9.修正元伝票番号(IN OUT)
--Ver1.3 Del End
    in_check_id                 IN NUMBER,        -- 7.支払バッチ情報チェックID(IN)
--Ver1.6 add Start 請求書IDはinvoice_id(reference22)を使用する為追加
    iv_invoice_id               IN VARCHAR2,      -- 8.請求書ID(IN)
--Ver1.6 add End
    ov_errbuf                   OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode                  OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg                   OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_payment'; -- プログラム名
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
-- Ver1.2 仕様変更 Del Start
--  ln_check_id   ap_invoice_payments_all.check_id%TYPE; -- 支払バッチ情報チェックID
-- Ver1.2 仕様変更 Del End
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
--Ver1.3 change Start 仕様変更により変更
-- ○仕様 2004/03/03
-- 仕訳明細カテゴリが「支払」の場合以下の項目を設定する。
-- ・伝票番号、仕訳名、明細摘要
-- 明細が支払預金行か支払債務行かで明細摘要に設定する項目が異なる。
-- ・支払預金行(預金)の場合、明細摘要に支払バッチ名を設定する。
-- ・支払債務行(為替差損益、手数料、債務)の場合、明細摘要に支払バッチ名を設定する。
-- 明細が預金行であるか否かは仕訳明細科目タイプが預金(CASH CLEARING)で
-- あるものを預金行とし、以外を債務行とする。
-- 支払と支払取消の行は判別不能の為区別せず、預金行と債務行の場合等
-- 支払と同様に扱う。
-- ○仕様 2004/03/19
-- ・端数処理行(ROUNDING)は預金行と同様の処理を行う。
    -- ==============================================
    -- 伝票番号、仕訳名称の設定 (A-3-2-1)
    -- ==============================================
    proc_slip_num_journal_name(
      in_org_id,                    -- 1.オルグID(IN)
--      ln_check_id,                  -- 2.チェックID(IN) -- Ver1.2 仕様変更 Del 
      in_check_id,                  -- 2.チェックID(IN)   -- Ver1.2 仕様変更 add 
      in_payment_id,                -- 3.請求書支払ID(IN)
      iov_slip_num,                 -- 4.伝票番号(IN OUT)
      iov_je_name,                  -- 5.仕訳名(IN OUT)
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
    -- 支払預金(仕訳明細科目タイプが預金)であるかの判断
--Ver1.4 change start 端数処理行である場合も明細摘要に支払バッチ名を付加する為、
--                    判断文を変更
--Ver1.7 change start 判断条件に預金(CASH)の場合も追加
--    IF iv_journal_type = 'CASH CLEARING' THEN
--    IF iv_journal_type = 'CASH CLEARING' OR iv_journal_type = 'ROUNDING' THEN
    IF iv_journal_type = 'CASH CLEARING' 
       OR iv_journal_type = 'ROUNDING' 
--Ver11.5.10.1.4C Change START
--       OR iv_journal_type = 'CASH' THEN
       OR iv_journal_type = 'CASH'
       OR iv_journal_type = 'FUTURE PAYMENT' THEN
--Ver11.5.10.1.4C Change END
--Ver1.7 change end
--Ver1.4 change END
      -- =====================================
      -- 明細摘要(支払：預金)の設定 (A-3-2-3)
      -- =====================================
      proc_detail_desc_desposit(
        in_org_id,                    -- 1.オルグID(IN)
--        ln_check_id,                  -- 2.チェックID(IN) -- Ver1.2 仕様変更 Del 
        in_check_id,                  -- 2.チェックID(IN)   -- Ver1.2 仕様変更 add 
        in_payment_id,                -- 3.請求書支払ID(IN)
        iov_slip_desc,                -- 4.明細摘要(IN OUT)
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
    ELSE
      -- 支払債務行の処理
      -- =========================================
      -- 明細摘要(支払：債務)の設定 (A-3-2-2)
      -- =========================================
      proc_detail_desc_unpaid(
        in_org_id,                    -- 1.オルグID(IN)
        in_payment_id,                -- 2.請求書支払ID(IN)
        iov_slip_desc,                -- 3.明細摘要(IN OUT)
-- Ver1.6 add start 請求書支払IDから請求書IDを検索せず、GL_INTERFACEの請求書IDを
--                  そのまま使用する
        TO_NUMBER(iv_invoice_id),     -- 4.請求書ID(IN)
-- Ver1.6 add end
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
/*
    xx00_file_pkg.log('journal_type=' || iv_journal_type);
    xx00_file_pkg.log('entered_dr=' || TO_CHAR(in_entered_dr));
    xx00_file_pkg.log('entered_cr=' || TO_CHAR(in_entered_cr));
    xx00_file_pkg.log('select ap_invoice_payments_all');
    xx00_file_pkg.log('key invoice_payment_id=' || TO_CHAR(in_payment_id));
    xx00_file_pkg.log('key org_id=' || TO_CHAR(in_org_id));
*/
-- Ver1.2 仕様変更 Del Start
/*
    -- 支払バッチ情報のチェックIDを取得する。
      SELECT  aip.check_id AS check_id    -- 支払バッチID
      INTO    ln_check_id
      FROM    ap_invoice_payments_all aip
      WHERE   aip.invoice_payment_id = in_payment_id
      AND     aip.org_id = in_org_id;
      xx00_file_pkg.log('get check_id=' || TO_CHAR(ln_check_id));
*/
-- Ver1.2 仕様変更 Del End
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del Start
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del End
--
/*
    -- 未払(仕訳明細科目タイプが未払金APかつ借方金額がNULLではない)かの判断
    IF iv_journal_type = 'LIABILITY' AND in_entered_dr IS NOT NULL THEN
      -- =========================================
      -- 明細摘要(支払：未払金AP)の設定 (A-3-2-2)
      -- =========================================
      proc_detail_desc_unpaid(
        in_org_id,                    -- 1.オルグID(IN)
        in_payment_id,                -- 2.請求書支払ID(IN)
        iov_slip_desc,                -- 3.明細摘要(IN OUT)
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
--
    -- 預金(仕訳明細科目タイプが未払金AP以外かつ貸方金額がNULLではない)かの判断
    ELSIF iv_journal_type <> 'LIABILITY' AND in_entered_cr IS NOT NULL THEN
      -- =====================================
      -- 明細摘要(支払：預金)の設定 (A-3-2-3)
      -- =====================================
      proc_detail_desc_desposit(
        in_org_id,                    -- 1.オルグID(IN)
--        ln_check_id,                  -- 2.チェックID(IN) -- Ver1.2 仕様変更 Del 
        in_check_id,                  -- 2.チェックID(IN)   -- Ver1.2 仕様変更 add 
        in_payment_id,                -- 3.請求書支払ID(IN)
        iov_slip_desc,                -- 4.明細摘要(IN OUT)
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
--
--Ver1.2 add Start 
    -- 仕様変更。仕訳明細科目タイプが未払金AP以外でかつ
    -- 貸方金額がNULLもしくは0である場合支払取消とする。
    IF iv_journal_type <> 'LIABILITY' AND NVL(in_entered_cr,0) = 0 THEN
      -- =====================================
      -- 修正元伝票番号(支払取消)の設定 (A-3-2-4)
      -- =====================================
      proc_adj_slip_num_cancel(
        in_org_id,                    -- 1.オルグID(IN)
  --      ln_check_id,                  -- 2.チェックID(IN) -- Ver1.2 仕様変更 Del 
        in_check_id,                  -- 2.チェックID(IN)   -- Ver1.2 仕様変更 add 
        in_payment_id,                -- 3.請求書支払ID(IN)
        iov_adj_slip_num,             -- 4.修正元伝票番号(IN OUT)
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
--Ver1.2 add End
--
*/
--Ver1.3 change End
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
-- Ver1.2 仕様変更 Del Start
/*
    WHEN NO_DATA_FOUND THEN                       --*** 支払バッチ名未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      --エラーメッセージ取得
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',  --アプリケーション短縮名
        'APP-XX03-06017'); -- メッセージ区分(警告)
      lv_errbuf := lv_errbuf || cv_package_name || ' ';
      IF iv_journal_type = 'LIABILITY' AND in_entered_dr IS NOT NULL THEN
        lv_errbuf := xx00_message_pkg.get_msg(
          'XX03',  --アプリケーション短縮名
          'APP-XX03-06006',
          'TOK_XX03_DFF_KEY',
          in_payment_id);
      ELSE
        lv_errbuf := lv_errbuf || xx00_message_pkg.get_msg(
          'XX03',  --アプリケーション短縮名
          'APP-XX03-06012',
          'TOK_XX03_DFF_KEY',
          in_payment_id);
      END IF;
      xx00_file_pkg.log(lv_errbuf);
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                 --# 任意 #
*/
-- Ver1.2 仕様変更 Del End
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
  END get_payment;
  /**********************************************************************************
   * Procedure Name   : get_add_dff_data
   * Description      : DFF付加対象データ抽出処理 (A-2)
   ***********************************************************************************/
  PROCEDURE get_add_dff_data(
    in_gl_book_id           IN NUMBER,       --   1.会計帳簿帳簿ID(IN)
    in_org_id               IN NUMBER,       --   2.オルグID(IN)
    iv_buyning_in_invoice   IN VARCHAR2,     --   3.仕訳カテゴリ名(仕入請求書)(IN)
    iv_payment_type         IN VARCHAR2,     --   4.仕訳カテゴリ名(支払)(IN)
    iv_je_soruce            IN VARCHAR2,     --   5.仕訳ソース名(IN)
    ion_buyning_cnt         IN OUT NUMBER,   --   6.仕訳カテゴリ別件数(仕入請求書)(OUT)
    ion_payment_cnt         IN OUT NUMBER,   --   7.仕訳カテゴリ別件数(支払)(OUT)
    ov_errbuf               OUT VARCHAR2,    --   エラー・メッセージ           --# 固定 #
    ov_retcode              OUT VARCHAR2,    --   リターン・コード             --# 固定 #
    ov_errmsg               OUT VARCHAR2)    --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_add_dff_data'; -- プログラム名
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
    lv_context_name  gl_interface.context%TYPE;   -- Ver1.2 add コンテキスト値
--
    -- *** ローカル・カーソル ***
    -- GLインターフェースDFFセット値付加対象取得カーソル
    CURSOR gl_add_dff_data_cur
    IS
      SELECT  gi.rowid AS row_id,                 -- ROWID
              gi.user_je_category_name 
                AS user_je_category_name,         -- 仕訳カテゴリ名
              gi.reference22 AS invoice_id,       -- 請求書ID
-- Ver1.2 del Start
--            gi.reference23 AS dist_line_number, -- 請求書明細番号
-- Ver1.2 del End
-- Ver1.2 add Start
              gi.reference23 AS line_number_or_check_id,   -- 請求書明細番号/支払バッチ情報チェックID
-- Ver1.2 add End
              gi.reference29 AS payment_id,       -- 請求書支払ID
              gi.reference30 AS journal_type,     -- 仕訳明細科目タイプ
              gi.entered_dr AS entered_dr,        -- 借方金額
              gi.entered_cr AS entered_cr,        -- 貸方金額
              gi.reference4 AS je_name,           -- 仕訳名
              gi.reference10 AS slip_desc,        -- 明細摘要
              gi.attribute1 AS tax_code,          -- 税コード
              gi.attribute2 AS incr_decr,         -- 増減事由
              gi.attribute3 AS slip_num,          -- 伝票番号
              gi.attribute4 AS dept,              -- 起票部門
              gi.attribute5 AS input_user,        -- 入力者
              gi.attribute6 AS adj_slip_num,      -- 修正元伝票番号
-- Ver1.3 add Start   仕様追加の為追加
              gi.attribute9 AS reserve1,          -- 予備１
              gi.attribute10 AS reserve2,         -- 予備２
-- Ver1.3 add Start
              gi.jgzz_recon_ref AS app_ref        -- 消込参照
      FROM    gl_interface gi                         --GLインターフェース
      WHERE   gi.user_je_source_name = iv_je_soruce   --仕訳ソース名は買掛管理
      AND     gi.set_of_books_id = in_gl_book_id      --会計帳簿IDはプロファイルの値
      AND     gi.status = 'NEW'                       --ステータスは新規
      AND     gi.actual_flag = 'A'                    --予実フラグは実績
      AND     gi.context IS NULL                      --コンテキスト値はNULL
      ORDER BY gi.reference22,gi.reference23 ASC;
--
    -- *** ローカル・レコード ***
    -- GLインターフェースDFFセット値付加対象取得カーソルレコード型
    gl_add_dff_data_rec gl_add_dff_data_cur%ROWTYPE;
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
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('source :' || iv_je_soruce);
    xx00_file_pkg.log(' ');
    xx00_file_pkg.log('ORG_ID : ' || TO_CHAR(in_org_id));
    xx00_file_pkg.log('GL_BOOKS_ID : ' || TO_CHAR(in_gl_book_id));
    xx00_file_pkg.log('JR_CATEGORY_BUYING_IN_INVOICE : ' || iv_buyning_in_invoice);
    xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || iv_payment_type);
    xx00_file_pkg.log(' ');
-- Ver1.2 add Start
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
-- Ver1.2 add End
    --GLインターフェースDFFセット値付加対象取得の取得
    --カーソルオープン
    OPEN gl_add_dff_data_cur;
    <<interface_loop>>
    LOOP
      FETCH gl_add_dff_data_cur INTO gl_add_dff_data_rec;
      --GL_INTERFACE取得チェック
      IF gl_add_dff_data_cur%NOTFOUND THEN
          EXIT interface_loop;
      END IF;
      xx00_file_pkg.log('JR_CATEGORY_PAYMENT : ' || gl_add_dff_data_rec.user_je_category_name);
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del Start
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Del End
      -- 仕訳カテゴリ名の判断
      IF gl_add_dff_data_rec.user_je_category_name = iv_buyning_in_invoice THEN
        -- ===================================
        -- 仕入請求書DFF値セットの取得 (A-3-1)
        -- ===================================
        get_buying_in_invoices(
          in_org_id,                                      -- 1.オルグID(IN)
          gl_add_dff_data_rec.journal_type,               -- 2.仕訳明細科目タイプ(IN)
          gl_add_dff_data_rec.entered_dr,                 -- 3.借方金額(IN)
          TO_NUMBER(gl_add_dff_data_rec.invoice_id),        -- 4.請求書ID(IN)
--Ver1.2 change Start
          TO_NUMBER(gl_add_dff_data_rec.line_number_or_check_id),  -- 5.請求書明細番号(IN)
--Ver1.2 change End
          gl_add_dff_data_rec.je_name,                    -- 6.仕訳名(IN OUT)
--Ver1.3 Del Start  仕様変更により不要となったので削除
--          gl_add_dff_data_rec.slip_desc,                  -- 7.明細摘要(IN OUT)
--Ver1.3 Del end
          gl_add_dff_data_rec.tax_code,                   -- 7.税コード(IN OUT)
          gl_add_dff_data_rec.incr_decr,                  -- 8.増減事由(IN OUT)
          gl_add_dff_data_rec.slip_num,                   -- 9.伝票番号(IN OUT)
          gl_add_dff_data_rec.dept,                       -- 10.起票部門(IN OUT)
          gl_add_dff_data_rec.input_user,                 -- 11.入力者(IN OUT)
          gl_add_dff_data_rec.adj_slip_num,               -- 12.修正元伝票番号(IN OUT)
          gl_add_dff_data_rec.app_ref,                    -- 13.消込用照合キー(IN OUT)
--Ver1.3 Add Start  仕様変更により追加
          gl_add_dff_data_rec.reserve1,                   -- 14.予備１(IN OUT)
          gl_add_dff_data_rec.reserve2,                   -- 15.予備２(IN OUT)
--Ver1.3 Add end
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
        ion_buyning_cnt := ion_buyning_cnt + 1;             -- 仕入請求書DFF処理件数の計上
      ELSIF gl_add_dff_data_rec.user_je_category_name = iv_payment_type THEN
        -- ===================================
        -- 支払DFF値セットの取得 (A-3-2)
        -- ===================================
        get_payment(
          in_org_id,                                    -- 1.オルグID(IN)
          gl_add_dff_data_rec.journal_type,             -- 2.仕訳明細科目タイプ(IN)
--Ver1.3 Del Start  仕様変更により不要となったので削除
--          gl_add_dff_data_rec.entered_dr,               -- 3.借方金額(IN)
--          gl_add_dff_data_rec.entered_cr,               -- 4.貸方金額(IN)
--Ver1.3 Del End
          gl_add_dff_data_rec.payment_id,               -- 3.請求書支払ID(IN)
          gl_add_dff_data_rec.je_name,                  -- 4.仕訳名(IN OUT)
          gl_add_dff_data_rec.slip_desc,                -- 5.明細摘要(IN OUT)
          gl_add_dff_data_rec.slip_num,                 -- 6.伝票番号(IN OUT)
--Ver1.3 Del Start  仕様変更により不要となったので削除
--          gl_add_dff_data_rec.adj_slip_num,             -- 9.修正元伝票番号(IN OUT)
--Ver1.3 Del End
--Ver1.2 add Start
          gl_add_dff_data_rec.line_number_or_check_id,  -- 7.支払バッチ情報チェックID(IN)
--Ver1.2 add End
--Ver1.6 add Start 請求書IDはinvoice_id(reference22)を使用するように変更
          gl_add_dff_data_rec.invoice_id,               -- 8.請求書ID(IN)
--Ver1.6 add End
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
        ion_payment_cnt := ion_payment_cnt + 1;           -- 支払DFF処理件数の計上
      END IF;
--
      -- ===================================
      -- 仕訳データの更新処理 (A-4)
      -- ===================================
      upd_journal_data(
        gl_add_dff_data_rec.je_name,          -- 1.仕訳名(IN)
        gl_add_dff_data_rec.slip_desc,        -- 2.明細摘要(IN)
        gl_add_dff_data_rec.tax_code,         -- 3.税コード(IN)
        gl_add_dff_data_rec.incr_decr,        -- 4.増減事由(IN)
        gl_add_dff_data_rec.slip_num,         -- 5.伝票番号(IN)
        gl_add_dff_data_rec.dept,             -- 6.起票部門(IN)
        gl_add_dff_data_rec.input_user,       -- 7.入力者(IN)
        gl_add_dff_data_rec.adj_slip_num,     -- 8.修正元伝票番号(IN)
        gl_add_dff_data_rec.row_id,           -- 9.ROWID(IN)
        iv_je_soruce,                         -- 10.仕訳ソース名(IN)
        gl_add_dff_data_rec.app_ref,          -- 11.消込参照(IN)
--Ver1.2 Add Start  仕様変更により追加
        lv_context_name,                      -- 12.会計帳簿名(IN)
--Ver1.2 Add end
--Ver1.3 Add Start  仕様変更により追加
        gl_add_dff_data_rec.reserve1,         -- 13.予備１(IN OUT)
        gl_add_dff_data_rec.reserve2,         -- 14.予備２(IN OUT)
--Ver1.3 Add end
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
--
    END LOOP interface_loop;
    --ログ出力
    CLOSE gl_add_dff_data_cur;
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
  END get_add_dff_data;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add Start
  /**********************************************************************************
   * Procedure Name   : upd_reference10
   * Description      : リファレンス10更新(A-6)
   ***********************************************************************************/
  PROCEDURE upd_reference10(
    iv_je_source       IN  VARCHAR2,  -- 仕訳ソース名
    in_gl_book_id      IN  NUMBER,    -- 会計帳簿帳簿ID
    iv_payment_type    IN  VARCHAR2,  -- 仕訳カテゴリ名(支払)
    ov_errbuf          OUT VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode         OUT VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg          OUT VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_reference10'; -- プログラム名
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
    cv_ref10_ap           CONSTANT VARCHAR2(12) := '_買掛金支払_';               -- リファレンス10_買掛金支払
    cv_ref25_mfg          CONSTANT VARCHAR2(4)  := 'MFG%';                       -- リファレンス25_請求書番号MFG
    cv_ref30_liability    CONSTANT VARCHAR2(10) := 'LIABILITY';                  -- リファレンス30_債務
    cv_ref30_discount     CONSTANT VARCHAR2(10) := 'DISCOUNT';                   -- リファレンス30_銀行手数料
    cn_number_1           CONSTANT NUMBER       := 1;
    cn_number_240         CONSTANT NUMBER       := 240;
--
    -- エラーメッセージ用定数
    cv_msg_kbn_cfo        CONSTANT VARCHAR2(5)  := 'XXCFO';                      -- アドオン：会計・アドオン領域のアプリケーション短縮名
    cv_gl_interface_name  CONSTANT VARCHAR2(30) := 'GLインタフェーステーブル';   -- エラーメッセージ用テーブル名
--
    -- メッセージ番号
    cv_msg_cfo1_0019      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00019';           -- データロックエラーメッセージ
    cv_msg_cfo1_0053      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00053';           -- 請求書情報取得エラーメッセージ
    cv_msg_cfo1_0020      CONSTANT VARCHAR2(20) := 'APP-XXCFO1-00020';           -- データ更新エラーメッセージ
--
    -- トークン
    cv_tkn_table          CONSTANT VARCHAR2(20) := 'TABLE';                      -- トークン：テーブル名
    cv_tkn_invoice_num    CONSTANT VARCHAR2(20) := 'INVOICE_NUM';                -- トークン：請求書番号
    cv_tkn_errmsg         CONSTANT VARCHAR2(10) := 'ERRMSG';                     -- トークン：エラー内容
--
    -- ステータス・コード
    cv_status_normal      CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
    cv_status_warn        CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
--
    -- パッケージ名
    cv_pkg_name           CONSTANT VARCHAR2(100) := 'XX032JU001C';
--
    cv_msg_part           CONSTANT VARCHAR2(3) := ' : ';
    cv_msg_cont           CONSTANT VARCHAR2(3) := '.';
--
    -- *** ローカル変数 ***
    ln_count                 NUMBER       DEFAULT 0;           -- 抽出件数のカウント
--
    -- *** ローカル・カーソル ***
    -- GLインタフェーステーブルのロック用カーソル
    CURSOR  gl_interface_lock_cur
    IS
      SELECT gi.rowid         row_id         -- ROWID
            ,gi.reference10   description    -- リファレンス10（摘要）
            ,gi.reference25   invoice_num    -- リファレンス25（請求書番号）
      FROM   gl_interface        gi
      WHERE  gi.user_je_source_name   = iv_je_source        -- 仕訳ソース名
      AND    gi.group_id              = (
                                         SELECT TO_NUMBER(gjst.attribute1)  group_id     -- グループID
                                         FROM   gl_je_sources_tl      gjst     -- 仕訳ソーステーブル
                                         WHERE  gjst.user_je_source_name = iv_je_source                       -- 仕訳ソース名
                                         AND    gjst.language            = xx00_global_pkg.current_language   -- 言語
                                        )                   -- グループID
      AND    gi.set_of_books_id       = in_gl_book_id       -- 会計帳簿ID
      AND    gi.user_je_category_name = iv_payment_type     -- '支払'
      AND    gi.reference30           IN (cv_ref30_liability  -- 債務
                                         ,cv_ref30_discount)  -- 銀行手数料
      AND    gi.reference25           LIKE cv_ref25_mfg     -- 請求書番号MFG
      AND    gi.reference10           LIKE cv_ref25_mfg     -- 摘要が請求書番号MFG
      FOR UPDATE NOWAIT
      ;
--
    -- *** ローカル・レコード ***
    TYPE gl_interface_lock_ttype IS TABLE OF gl_interface_lock_cur%ROWTYPE INDEX BY PLS_INTEGER;
    gl_interface_lock_tab                    gl_interface_lock_ttype;
--
    TYPE reference10_ttype       IS TABLE OF gl_interface.reference10%TYPE INDEX BY PLS_INTEGER;
    reference10_tab                          reference10_ttype;
--
    TYPE description_ttype       IS TABLE OF ap_invoices_all.description%TYPE INDEX BY PLS_INTEGER;
    description_tab                          description_ttype;
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
      -- 1.GLIFテーブルの請求書番号を取得し、対象データをロックします。
      --カーソルオープン
      OPEN gl_interface_lock_cur;
      -- バルクフェッチ
      FETCH gl_interface_lock_cur BULK COLLECT INTO gl_interface_lock_tab;
      -- カーソルクローズ
      IF ( gl_interface_lock_cur%ISOPEN ) THEN
        CLOSE gl_interface_lock_cur;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                        ,cv_msg_cfo1_0019      -- データロックエラーメッセージ
                                                        ,cv_tkn_table          -- トークン'TABLE'
                                                        ,cv_gl_interface_name  -- GLインタフェーステーブル
                                                        )
                               ,1
                               ,5000);
          lv_errbuf := lv_errmsg;
          RAISE global_api_expt;
    END;
--
    <<interface_loop>>
    FOR ln_count in 1..gl_interface_lock_tab.COUNT LOOP
      -- 2.1で取得した請求書番号を元に、AP請求書テーブルから摘要を取得します。
      BEGIN
        SELECT aia.description   description  -- 摘要
        INTO   description_tab(ln_count)
        FROM   ap_invoices_all  aia           -- AP請求書テーブル
        WHERE  aia.invoice_num = gl_interface_lock_tab(ln_count).invoice_num  -- 請求書番号
        ;
      EXCEPTION
        WHEN OTHERS THEN
          lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo                               -- 'XXCFO'
                                                        ,cv_msg_cfo1_0053                             -- 請求書情報取得エラーメッセージ
                                                        ,cv_tkn_invoice_num                           -- トークン:請求書番号
                                                        ,gl_interface_lock_tab(ln_count).invoice_num  -- 請求書番号
                                                        )
                               ,1
                               ,5000);
          xx00_file_pkg.output(lv_errmsg);
          ov_retcode := cv_status_warn;
      END;
      -- 摘要が取得できる場合
      IF ( description_tab.exists(ln_count) ) THEN
        reference10_tab(ln_count) := SUBSTRB( description_tab(ln_count) || cv_ref10_ap || gl_interface_lock_tab(ln_count).invoice_num
                                             ,cn_number_1
                                             ,cn_number_240);
      -- 摘要が取得できない場合
      ELSE
        reference10_tab(ln_count) := gl_interface_lock_tab(ln_count).description;
      END IF;
    END LOOP interface_loop;
--
    BEGIN
      FORALL ln_count IN 1..gl_interface_lock_tab.COUNT
        -- 3.GLIFテーブルの対象データのリファレンス10を更新します。
        UPDATE gl_interface        gi
        SET    gi.reference10 = reference10_tab(ln_count)  -- リファレンス10
        WHERE  gi.rowid = gl_interface_lock_tab(ln_count).row_id   -- ROWID
        ;
    EXCEPTION
      WHEN OTHERS THEN
        lv_errmsg := SUBSTRB(xxccp_common_pkg.get_msg( cv_msg_kbn_cfo        -- 'XXCFO'
                                                      ,cv_msg_cfo1_0020      -- データ更新エラーメッセージ
                                                      ,cv_tkn_table          -- トークン'TABLE'
                                                      ,cv_gl_interface_name  -- GLインタフェーステーブル
                                                      ,cv_tkn_errmsg         -- トークン'ERRMSG'
                                                      ,SQLERRM               -- SQLエラーメッセージ
                                                      )
                             ,1
                             ,5000);
        lv_errbuf := lv_errmsg;
        RAISE global_api_expt;
    END;
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
    --例外発生時、カーソルがオープンされていた場合、カーソルをクローズする。
    IF ( gl_interface_lock_cur%ISOPEN ) THEN
      CLOSE   gl_interface_lock_cur;
    END IF;
  END upd_reference10;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add End
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_journal_source  IN  VARCHAR2,     -- 1.仕訳ソース名
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
    ln_org_id               NUMBER(15,0);             -- オルグID
    lv_buyning_in_invoice   VARCHAR2(30);             -- 仕訳カテゴリ名(仕入請求書)
    lv_payment_type         VARCHAR2(30);             -- 仕訳カテゴリ名(支払)
    ln_buyning_cnt          NUMBER := 0;              -- 仕訳カテゴリ別件数(仕入請求書)
    ln_payment_cnt          NUMBER := 0;              -- 仕訳カテゴリ別件数(支払)
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
      ln_gl_book_id,          -- 1.会計帳簿帳簿ID(OUT)
      ln_org_id,              -- 2.オルグID(OUT)
      lv_buyning_in_invoice,  -- 3.仕訳カテゴリ名(仕入請求書)(OUT)
      lv_payment_type,        -- 4.仕訳カテゴリ名(支払)(OUT)
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- DFF付加対象データ抽出処理 (A-2)
    -- ===============================
    get_add_dff_data(
      ln_gl_book_id,          -- 1.会計帳簿帳簿ID(IN)
      ln_org_id,              -- 2.オルグID(IN)
      lv_buyning_in_invoice,  -- 3.仕訳カテゴリ名(仕入請求書)(IN)
      lv_payment_type,        -- 4.仕訳カテゴリ名(支払)(IN)
      iv_journal_source,      -- 5.仕訳ソース名(IN)
      ln_buyning_cnt,         -- 6.仕訳カテゴリ別件数(仕入請求書)(IN OUT)
      ln_payment_cnt,         -- 7.仕訳カテゴリ別件数(支払)(IN OUT)
      lv_errbuf,              -- エラー・メッセージ           --# 固定 #
      lv_retcode,             -- リターン・コード             --# 固定 #
      lv_errmsg);             -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSE
      -- ===============================
      -- プルーフリスト出力処理 (A-5)
      -- ===============================
      msg_output(
        ln_org_id,              -- 1.オルグID(IN)
        ln_buyning_cnt,         -- 2.仕訳カテゴリ別件数(仕入請求書)(IN)
        ln_payment_cnt,         -- 3.仕訳カテゴリ別件数(支払)(IN)
        iv_journal_source,      -- 4.仕訳ソース名(IN)
        lv_buyning_in_invoice,  -- 5.仕訳カテゴリ名(仕入請求書)(IN)
        lv_payment_type,        -- 6.仕訳カテゴリ名(支払)(IN)
        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
        lv_retcode,        -- リターン・コード             --# 固定 #
        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    END IF;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add Start
    -- ===============================
    -- リファレンス10更新(A-6)
    -- ===============================
    upd_reference10(
      iv_journal_source,  -- 仕訳ソース名
      ln_gl_book_id,      -- 会計帳簿帳簿ID
      lv_payment_type,    -- 仕訳カテゴリ名(支払)
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    ELSIF ( lv_retcode =  xx00_common_pkg.set_status_warn_f ) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    END IF;
--
-- 2015/10/13 Ver.11.5.10.1.7 Y.Shoji Add End
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_je_soruce  IN  VARCHAR2)      -- 1.仕訳ソース名
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
      iv_je_soruce,     -- 1.仕訳ソース名
      lv_errbuf,   -- エラー・メッセージ           --# 固定 #
      lv_retcode,  -- リターン・コード             --# 固定 #
      lv_errmsg);  -- ユーザー・エラー・メッセージ --# 固定 #
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
--
--###########################  固定部 END   #######################################################
--
END XX032JU001C;
/
