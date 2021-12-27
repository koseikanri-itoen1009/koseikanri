create or replace PACKAGE BODY XX034PT001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX034PT001C(body)
 * Description      : 承認済部門入力データをAP標準I/Fに転送後、部門入力転送日を更新する
 * MD.050           : 部門入力バッチ処理(AP)   OCSJ/BFAFIN/MD050/F212
 * MD.070           : 承認済仕入先請求書の転送 OCSJ/BFAFIN/MD070/F406
 * Version          : 11.5.10.2.11
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  vaild_approval         AP未承認済仕入先請求書データの確認 (A-1)
 *  get_approval_slip_data 経理承認済仕入先請求書データの取得 (A-2)
 *  ins_ap_interface       API/Fの更新 (A-3)
 *  ins_ap_interface_lines APインターフェース(明細)データの取得と挿入 (A-2、A-3)
 *  upd_slip_data          AP転送済仕入先請求書データの更新 (A-4)
 *  msg_output             結果出力 (A-4)
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/02/20   1.0            新規作成
 *  2004/02/27   1.1            単体テスト不具合修正
 *  2005/09/05   11.5.10.1.5    関電フィードバックパフォーマンス対応
 *  2005/11/29   11.5.10.1.6    パフォーマンス対応によりヒント句変更
 *  2007/11/26   11.5.10.2.10   データ転送と転送済フラグ更新タイミングの修正
 *  2021/12/17   11.5.10.2.11   [E_本稼働_17678]対応 電子帳簿保存法改正対応
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
  -- *** グローバル定数 ***
  cv_date_time_format CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';   --結果出力用日付形式1
  cv_date_format      CONSTANT VARCHAR2(30) := 'YYYY/MM/DD';              --結果出力用日付形式2
  cv_appr_status      CONSTANT  xx03_payment_slips.wf_status%TYPE := '80';  -- 経理承認済ステータス
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  vaild_approval_expt       EXCEPTION;              -- AP未承認請求書存在エラー
  chk_data_none_expt        EXCEPTION;              -- AP転送データ未取得エラー
--
  /**********************************************************************************
   * Procedure Name   : vaild_approval
   * Description      : AP未承認仕入先請求書データの確認 (A-1)
   ***********************************************************************************/
  PROCEDURE vaild_approval(
    on_org_id         OUT NUMBER,       -- 1.オルグID(OUT)
    on_books_id       OUT NUMBER,       -- 2.会計帳簿ID(OUT)
    ov_currency_code  OUT VARCHAR2,     -- 3.機能通貨(OUT)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'vaild_approval'; -- プログラム名
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
    -- 請求書未承認ステータス
    cv_unappr_status      CONSTANT  VARCHAR2(30) := 'UNAPPROVED';
-- 1.1 add start 未承認ステータスの追加
    cv_nev_appr_status    CONSTANT  VARCHAR2(30) := 'NEVER APPROVED';
    cv_need_reappr_status CONSTANT  VARCHAR2(30) := 'NEEDS REAPPROVAL';
-- 1.1 add end
    -- 会計期間ステータス(オープン)
    cv_gl_status_open   CONSTANT  gl_period_statuses.closing_status%TYPE := 'O';
--
    -- *** ローカル変数 ***
    ln_app_id         fnd_application.application_id%TYPE;    -- アプリケーションID
    ln_data_cnt       NUMBER;                                 -- 削除対象データ件数
    lv_gl_status      gl_period_statuses.closing_status%TYPE; -- 会計ステータス
--
    -- *** ローカル・カーソル ***
    CURSOR get_ap_unappr_data_cur
    IS
      SELECT
--Ver 11.5.10.1.5 2005/09/05 Change Start 会計期間がオープンしているもののみ取得する
--Ver 11.5.10.1.5 2005/09/05 Change Start
--Ver 11.5.10.1.6 Change Start
       /*+ ORDERED INDEX(aia XX03_AP_INVOICES_N1)
                   INDEX(gps GL_PERIOD_STATUSES_N1) */
--       /*+ INDEX(aia XX03_AP_INVOICES_N1) */
--Ver 11.5.10.1.6 Change End
--Ver 11.5.10.1.5 2005/09/05 Change End
      aia.gl_date AS gl_date,    -- 計上日
-- 1.1 add start エラー時のログ解析用に請求書番号を追加
              aia.invoice_num AS invoice_num     -- 請求書番号
-- 1.1 add end
--Ver 11.5.10.1.6 Change Start
--      FROM    ap_invoices_all aia
----Ver 11.5.10.1.5 2005/09/05 Add Start
--              ,gl_period_statuses  gps
----Ver 11.5.10.1.5 2005/09/05 Add End
      FROM    gl_period_statuses  gps
             ,ap_invoices_all     aia
--Ver 11.5.10.1.6 Change End
      WHERE   aia.org_id = on_org_id
      AND     aia.created_by = xx00_global_pkg.created_by
--Ver 11.5.10.1.5 2005/09/05 Add Start
      AND     gps.application_id = ln_app_id
      AND     gps.set_of_books_id = on_books_id
      AND     aia.set_of_books_id = on_books_id
      AND     aia.gl_date >= gps.start_date
      AND     aia.gl_date < gps.end_date + 1
      AND     gps.adjustment_period_flag  != 'Y'
      AND     gps.closing_status = cv_gl_status_open
--Ver 11.5.10.1.5 2005/09/05 Add End
-- 1.1 change start 未承認ステータスの追加による変更
/*
      AND     cv_unappr_status = ap_invoices_pkg.get_approval_status(
        aia.invoice_id,
        aia.invoice_amount,
        aia.payment_status_flag,
        aia.invoice_type_lookup_code);
*/
      AND (
        cv_unappr_status = ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code)
        OR
        cv_nev_appr_status = ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code)
        OR
        cv_need_reappr_status = ap_invoices_pkg.get_approval_status(
          aia.invoice_id,
          aia.invoice_amount,
          aia.payment_status_flag,
          aia.invoice_type_lookup_code));
-- 1.1 change end
--Ver 11.5.10.1.5 2005/09/05 Add End
--
    -- *** ローカル・レコード ***
    --チェック対象取得カーソルレコード
    get_ap_unappr_data_rec get_ap_unappr_data_cur%ROWTYPE;
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
    xx00_file_pkg.log(' ');
--
    -- オルグIDの取得
    on_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
    -- 会計帳簿IDの取得
    on_books_id := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
    -- アプリケーションIDの取得
    ln_app_id := xx03_application_pkg.get_application_id_f('SQLAP');
    -- 機能通貨の取得
    SELECT  gsob.currency_code AS currency_code
    INTO    ov_currency_code
    FROM    gl_sets_of_books gsob
    WHERE   gsob.set_of_books_id = on_books_id;
--
    -- Ver1.1 add start ログ出力
    xx00_file_pkg.log('org_id = ' || TO_CHAR(on_org_id));
    xx00_file_pkg.log('books_id = ' || TO_CHAR(on_books_id));
    xx00_file_pkg.log('app_id = ' || TO_CHAR(ln_app_id));
    xx00_file_pkg.log('currency_code = ' || ov_currency_code);
    -- Ver1.1 add end
--
    --削除対象取得カーソルオープン
    OPEN get_ap_unappr_data_cur;
    <<get_ap_unappr_loop>>
    LOOP
      FETCH get_ap_unappr_data_cur INTO get_ap_unappr_data_rec;
      -- 0件判定
      IF (get_ap_unappr_data_cur%NOTFOUND) THEN
        EXIT get_ap_unappr_loop;
--Ver 11.5.10.1.5 2005/09/05 Add Start 一件以上有る場合はエラー処理を行う
      ELSE
        RAISE vaild_approval_expt;
--Ver 11.5.10.1.5 2005/09/05 Add End
      END IF;
--Ver 11.5.10.1.5 2005/09/05 Delete Start
/*
      -- 計上日から会計期間ステータスのチェック
      SELECT  gps.closing_status
      INTO    lv_gl_status
      FROM    gl_period_statuses gps
      WHERE   gps.application_id = ln_app_id
      AND     gps.set_of_books_id = on_books_id
      AND     get_ap_unappr_data_rec.gl_date BETWEEN gps.start_date AND gps.end_date
      AND     gps.adjustment_period_flag  != 'Y';
      -- 会計ステータスがオープンであるデータが存在する場合エラーメッセージを出力
      IF lv_gl_status = cv_gl_status_open THEN
        RAISE vaild_approval_expt;
      END IF;
*/
--Ver 11.5.10.1.5 2005/09/05 Delete End
    END LOOP get_ap_unappr_loop;
    CLOSE get_ap_unappr_data_cur;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN vaild_approval_expt THEN        --*** AP未承認請求書存在エラー ***
      -- *** 任意で例外処理を記述する ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08002',                 -- AP未承認請求書存在メッセージ
-- Ver1.1 add start ログメッセージのメッセージ
          'TOK_XX03_INVOICE_NUM',
          get_ap_unappr_data_rec.invoice_num));
-- Ver1.1 add end
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
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
  END vaild_approval;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_interface_lines
   * Description      : APインターフェース(明細)データの取得と挿入 (A-2、A-3)
   ***********************************************************************************/
  PROCEDURE ins_ap_interface_lines(
    in_invoice_id     IN NUMBER,        -- 1.請求書ID(IN)
    in_org_id         IN NUMBER,        -- 2.オルグID(IN)
    id_upd_date       IN DATE,          -- 3.ヘッダー取得時のSYSDATE(IN)
    in_updated_by     IN NUMBER,        -- 4.最終更新者(IN)
    in_update_login   IN NUMBER,        -- 5.最終ログイン(IN)
    in_created_by     IN NUMBER,        -- 6.作成者(IN)
    on_detail_cnt    OUT NUMBER,        -- 7.明細件数(OUT)
--Ver1.1 add start 明細キー(xx03_payment_slipsのinvoice_id)の渡し忘れ
    in_key_invoice_id IN NUMBER,        -- 8.明細キー請求書ID(IN)
--Ver1.1 add end
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_interface_lines'; -- プログラム名
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
    cv_tax_code_override
      CONSTANT ap_invoice_lines_interface.tax_code_override_flag%TYPE := 'Y';
    cv_type_header CONSTANT VARCHAR2(100) := 'HEADER';
--
    -- *** ローカル変数 ***
    ln_line_id      ap_invoice_lines_interface.invoice_line_id%TYPE;  -- 請求書明細ID取得用
    ln_detail_cnt   NUMBER  :=0;                                      -- 明細件数計上用
--
    -- *** ローカル・カーソル ***
    CURSOR get_pay_slip_lines_cur
    IS
      SELECT  xpsjlv.invoice_id AS invoice_id,                        -- 請求書ID
              xpsjlv.line_number * 10 AS line_number,                 -- 明細行番号
              xpsjlv.line_type_lookup_code AS line_type_lookup_code,  -- 明細タイプ
              xpsjlv.amount AS amount,                                -- 明細金額
              xpsjlv.description AS description,                      -- 請求書明細備考
              xpsjlv.tax_code AS tax_code,                            -- 税区分
              xpsjlv.code_concatenated AS code_concatenated,          -- 明細AFF値
              xpsjlv.code_combination_id AS ccid,                     -- 明細AFF CCID
              xpsjlv.incr_decr_reason_code AS incr_decr_reason,       -- 増減事由
              xpsjlv.recon_reference AS recon_reference,              -- 消込参照
--Ver11.5.10.2.11 add start
              xps.invoice_ele_data_yes AS invoice_ele_data_yes,       -- 請求書電子データ受領あり
--Ver11.5.10.2.11 add end
              xpsjlv.attribute1 AS attribute1,                        -- 予備１
              xpsjlv.attribute2 AS attribute2,                        -- 予備２
              xpsjlv.attribute3 AS attribute3,                        -- 予備３
              xpsjlv.attribute4 AS attribute4,                        -- 予備４
              xpsjlv.attribute5 AS attribute5,                        -- 予備５
              xpsjlv.attribute6 AS attribute6,                        -- 予備６
              xpsjlv.attribute7 AS attribute7,                        -- 予備７
              xpsjlv.attribute8 AS attribute8                         -- 予備８
      FROM    xx03_pay_slip_journal_lines_v xpsjlv
--Ver11.5.10.2.11 add start
             ,xx03_payment_slips            xps
--Ver11.5.10.2.11 add end
--Ver1.1 change start 明細キー(xx03_payment_slipsのinvoice_id)間違い
--      WHERE   xpsjlv.invoice_id = in_invoice_id
      WHERE   xpsjlv.invoice_id = in_key_invoice_id
--Ver1.1 change end
      AND     xpsjlv.line_type_lookup_code <> cv_type_header
--Ver11.5.10.2.11 add start
      AND     xps.invoice_id = xpsjlv.invoice_id
--Ver11.5.10.2.11 add end
      ORDER BY xpsjlv.line_number;
--
    -- *** ローカル・レコード ***
    -- AP仕入先請求書明細カーソルレコード
    get_pay_slip_lines_rec get_pay_slip_lines_cur%ROWTYPE;
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
    xx00_file_pkg.log(' ');
    --AP仕入先請求書明細カーソルオープン
    OPEN get_pay_slip_lines_cur;
    <<get_ap_lines_loop>>
    LOOP
      FETCH get_pay_slip_lines_cur INTO get_pay_slip_lines_rec;
      -- 0件判定
      IF (get_pay_slip_lines_cur%NOTFOUND) THEN
        EXIT get_ap_lines_loop;
      END IF;
--
      -- 請求書明細IDの取得
      SELECT  ap_invoice_lines_interface_s.NEXTVAL
      INTO    ln_line_id
      FROM    DUAL;
--
      -- AP標準インターフェース(明細)への挿入
      INSERT INTO ap_invoice_lines_interface (
        invoice_id,
        invoice_line_id,
        line_number,
        line_type_lookup_code,
        amount,
        description,
        tax_code,
        dist_code_concatenated,
        dist_code_combination_id,
        last_update_date,
        last_updated_by,
        last_update_login,
        creation_date,
        created_by,
        attribute_category,
        attribute1,
        attribute2,
        attribute3,
        attribute4,
        attribute5,
        attribute6,
        attribute7,
        attribute8,
        attribute9,
        attribute10,
        org_id,
        tax_code_override_flag
      )
      VALUES (
--Ver1.1 change start 部門入力明細の請求書ID(xx03_payment_slipsのinvoice_id)ではなく、
--                    標準インターフェースヘッダーの請求書IDを設定するのが正しい
--        get_pay_slip_lines_rec.invoice_id,
        in_invoice_id,
--Ver1.1 change end
        ln_line_id,
        get_pay_slip_lines_rec.line_number,
        get_pay_slip_lines_rec.line_type_lookup_code,
        get_pay_slip_lines_rec.amount,
        get_pay_slip_lines_rec.description,
        get_pay_slip_lines_rec.tax_code,
        get_pay_slip_lines_rec.code_concatenated,
        get_pay_slip_lines_rec.ccid,
        id_upd_date,
        in_updated_by,
        in_update_login,
        id_upd_date,
        in_created_by,
        in_org_id,
        get_pay_slip_lines_rec.incr_decr_reason,
        get_pay_slip_lines_rec.recon_reference,
        get_pay_slip_lines_rec.attribute1,
        get_pay_slip_lines_rec.attribute2,
        get_pay_slip_lines_rec.attribute3,
        get_pay_slip_lines_rec.attribute4,
        get_pay_slip_lines_rec.attribute5,
        get_pay_slip_lines_rec.attribute6,
        get_pay_slip_lines_rec.attribute7,
--Ver11.5.10.2.11 change start
--        get_pay_slip_lines_rec.attribute8,
        get_pay_slip_lines_rec.invoice_ele_data_yes,
--Ver11.5.10.2.11 change end
        in_org_id,
        cv_tax_code_override
      );
      ln_detail_cnt := ln_detail_cnt + 1;
    END LOOP get_ap_lines_loop;
    CLOSE get_pay_slip_lines_cur;
--
    on_detail_cnt := ln_detail_cnt;
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
  END ins_ap_interface_lines;
--
  /**********************************************************************************
   * Procedure Name   : ins_ap_interface
   * Description      : APインターフェース(ヘッダー)への挿入 (A-3)
   ***********************************************************************************/
  PROCEDURE ins_ap_interface(
    i_ap_if_rec       IN ap_invoices_interface%ROWTYPE, -- 1.APインターフェースレコード(IN)
    in_org_id         IN NUMBER,                        -- 2.オルグID(IN)
    id_upd_date       IN DATE,                          -- 3.ヘッダー取得時のSYSDATE(IN)
    in_updated_by     IN NUMBER,                        -- 4.最終更新者(IN)
    in_update_login   IN NUMBER,                        -- 5.最終ログイン(IN)
    in_created_by     IN NUMBER,                        -- 6.作成者(IN)
    on_detail_cnt     OUT NUMBER,                       -- 7.明細件数(OUT)
--Ver1.1 add start 明細キー(xx03_payment_slipsのinvoice_id)の渡し忘れ
    in_key_invoice_id IN NUMBER,                        -- 8.明細キー請求書ID(IN)
--Ver1.1 add end
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_ap_interface'; -- プログラム名
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
    ln_detail_cnt   NUMBER := 0;     -- 明細件数
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
    xx00_file_pkg.log(' ');
--
    -- AP標準インターフェースへの挿入
    INSERT INTO ap_invoices_interface (
      invoice_id,
      invoice_num,
      invoice_date,
      vendor_id,
      vendor_site_id,
      invoice_amount,
      invoice_currency_code,
      exchange_rate,
      exchange_rate_type,
      exchange_date,
      terms_id,
      description,
      last_update_date,
      last_updated_by,
      last_update_login,
      creation_date,
      created_by,
      attribute_category,
      attribute2,
      attribute3,
      attribute4,
      attribute5,
      attribute6,
      attribute7,
      attribute8,
      attribute9,
      source,
      payment_method_lookup_code,
      pay_group_lookup_code,
      gl_date,
      org_id,
      prepay_num,
-- Ver1.1 add start 前払充当仕訳計上日の設定漏れ対応
      prepay_gl_date,
-- Ver1.1 add end
      terms_date
    )
    VALUES (
      i_ap_if_rec.invoice_id,
      i_ap_if_rec.invoice_num,
      i_ap_if_rec.invoice_date,
      i_ap_if_rec.vendor_id,
      i_ap_if_rec.vendor_site_id,
      i_ap_if_rec.invoice_amount,
      i_ap_if_rec.invoice_currency_code,
      i_ap_if_rec.exchange_rate,
      i_ap_if_rec.exchange_rate_type,
      i_ap_if_rec.exchange_date,
      i_ap_if_rec.terms_id,
      i_ap_if_rec.description,
      i_ap_if_rec.last_update_date,
      i_ap_if_rec.last_updated_by,
      i_ap_if_rec.last_update_login,
      i_ap_if_rec.creation_date,
      i_ap_if_rec.created_by,
      i_ap_if_rec.attribute_category,
      i_ap_if_rec.attribute2,
      i_ap_if_rec.attribute3,
      i_ap_if_rec.attribute4,
      i_ap_if_rec.attribute5,
      i_ap_if_rec.attribute6,
      i_ap_if_rec.attribute7,
      i_ap_if_rec.attribute8,
      i_ap_if_rec.attribute9,
      i_ap_if_rec.source,
      i_ap_if_rec.payment_method_lookup_code,
      i_ap_if_rec.pay_group_lookup_code,
      i_ap_if_rec.gl_date,
      i_ap_if_rec.org_id,
      i_ap_if_rec.prepay_num,
-- Ver1.1 add start 前払充当仕訳計上日の設定漏れ対応
      i_ap_if_rec.gl_date,
-- Ver1.1 add end
      i_ap_if_rec.terms_date
    );
--
    -- ========================================================
    -- 経理承認済仕入先請求書明細データの取得と更新 (A-2、A-3)
    -- ========================================================
    ins_ap_interface_lines(
      i_ap_if_rec.invoice_id,         -- 1.請求書ID(IN)
      in_org_id,                      -- 2.オルグID(IN)
      id_upd_date,                    -- 3.ヘッダー取得時のSYSDATE(IN)
      in_updated_by,                  -- 4.最終更新者(IN)
      in_update_login,                -- 5.最終ログイン(IN)
      in_created_by,                  -- 6.作成者(IN)
      ln_detail_cnt,                  -- 7.明細件数(OUT)
--Ver1.1 add start 明細キー(xx03_payment_slipsのinvoice_id)の渡し忘れ
      in_key_invoice_id,              -- 8.明細キー請求書ID(IN)
--Ver1.1 add end
      lv_errbuf,      -- エラー・メッセージ           --# 固定 #
      lv_retcode,     -- リターン・コード             --# 固定 #
      lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    on_detail_cnt := ln_detail_cnt;
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
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
  END ins_ap_interface;
--
  /**********************************************************************************
   * Procedure Name   : get_approval_slip_data
   * Description      : 経理承認済仕入先請求書データの取得(A-2)
   ***********************************************************************************/
  PROCEDURE get_approval_slip_data(
    iv_source         IN VARCHAR2,      -- 1.ソース名(IN)
    in_org_id         IN NUMBER,        -- 2.オルグID(IN)
    iv_currency_code  IN VARCHAR2,      -- 3.機能通貨(IN)
    on_header_cnt     OUT NUMBER,       -- 4.ヘッダ件数(OUT)
    on_detail_cnt     OUT NUMBER,       -- 5.明細件数(OUT)
    od_upd_date       OUT DATE,         -- 6.更新日付(OUT)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'get_approval_slip_data'; -- プログラム名
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
    cv_us_rate_type     CONSTANT VARCHAR2(10) := 'User';
    cv_pay_lookup_type  CONSTANT xx03_ap_pay_groups_v.lookup_type%TYPE := 'PAY GROUP';
--
    -- *** ローカル変数 ***
    ln_updated_by     NUMBER;         -- 最終更新者退避用
    ln_update_login   NUMBER;         -- 最終ログイン退避用
    ln_created_by     NUMBER;         -- 作成者退避用
    lv_cur_lang       VARCHAR2(4);    -- 現在の言語コード
    ln_detail_cnt     NUMBER;         -- 明細件数
--
    -- *** ローカル・カーソル ***
    CURSOR get_ap_trance_data_cur
    IS
      SELECT    xps.invoice_num AS invoice_num,
--Ver1.1 add start 明細キー(xx03_payment_slipsのinvoice_id)の渡し忘れ
                xps.invoice_id AS key_invoice_id,
--Ver1.1 add end
                xps.invoice_date AS invoice_date,
                xps.vendor_id AS vendor_id,
                xps.vendor_site_id AS vendor_site_id,
--Ver1.1 change start 合計金額の算出間違い
--                xps.inv_amount AS inv_amount,
                xps.inv_item_amount  AS  inv_item_amount,
                xps.inv_tax_amount  AS  inv_tax_amount,
--Ver1.1 change end 合計金額の算出間違い
                xps.invoice_currency_code AS inv_currency_code,
                xps.exchange_rate AS exchange_rate,
                DECODE(xps.invoice_currency_code,
                  iv_currency_code,
                  NULL,
                  xps.exchange_rate_type) AS exchange_rate_type,
                DECODE(xps.invoice_currency_code,
                  iv_currency_code,
                  NULL,
                  xps.gl_date) AS exchange_date,
                xps.terms_id AS terms_id,
                xps.description AS description,
                xps.vendor_invoice_num AS vendor_invoice_num,
                xps.entry_department AS entry_department,
                xps.entry_person_id AS entry_person_id,
                xps.orig_invoice_num AS orig_invoice_num,
                xps.attribute1 AS attribute1,
                xps.attribute2 AS attribute2,
                xps.attribute3 AS attribute3,
                xps.attribute4 AS attribute4,
                xps.pay_group_lookup_code AS pay_group_lookup_code,
                xps.gl_date AS gl_date,
                xps.org_id AS org_id,
                xps.prepay_num AS prepay_num,
                xps.terms_date AS terms_date,
                SYSDATE AS upd_date
      FROM      xx03_payment_slips xps
      WHERE     xps.wf_status = cv_appr_status
      AND       xps.ap_forword_date IS NULL
      AND       xps.org_id = in_org_id
      ORDER BY  xps.invoice_id
      FOR UPDATE NOWAIT;
--
    -- *** ローカル・レコード ***
    -- AP仕入先請求書転送カーソルレコード
    get_ap_trance_data_rec get_ap_trance_data_cur%ROWTYPE;
    -- AP I/Fヘッダーレコード
    l_ap_if_rec ap_invoices_interface%ROWTYPE;
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
    xx00_file_pkg.log(' ');
--
    -- AP仕入先請求書転送カーソルオープン
    OPEN get_ap_trance_data_cur;
    -- 変数初期化
    on_header_cnt := 0;
--Ver1.1 add start 変数初期化漏れ
    on_detail_cnt := 0;
--Ver1.1 add end
    ln_updated_by := xx00_global_pkg.last_updated_by;
    ln_update_login := xx00_global_pkg.last_update_login;
    ln_created_by := xx00_global_pkg.created_by;
    lv_cur_lang := xx00_global_pkg.current_language;
    <<get_ap_trance_loop>>
    LOOP
      FETCH get_ap_trance_data_cur INTO get_ap_trance_data_rec;
      -- 0件判定
      IF (get_ap_trance_data_cur%NOTFOUND) THEN
        -- 件数判定
        IF on_header_cnt < 1 THEN
          RAISE chk_data_none_expt;
        END IF;
        EXIT get_ap_trance_loop;
      END IF;
      IF on_header_cnt = 0 THEN
        od_upd_date := get_ap_trance_data_rec.upd_date;
      END IF;
      -- APインターフェースレコード型にセット
      -- INVOICE_ID
      SELECT  ap_invoices_interface_s.NEXTVAL
      INTO    l_ap_if_rec.invoice_id
      FROM    DUAL;
      -- INVOICE_NUM
      l_ap_if_rec.invoice_num := get_ap_trance_data_rec.invoice_num;
      -- INVOICE_DATE
      l_ap_if_rec.invoice_date := get_ap_trance_data_rec.invoice_date;
      -- VENDOR_ID
      l_ap_if_rec.vendor_id := get_ap_trance_data_rec.vendor_id;
      -- VENDOR_SITE_ID
      l_ap_if_rec.vendor_site_id := get_ap_trance_data_rec.vendor_site_id;
      -- INVOICE_AMOUNT
--Ver1.1 change start 合計金額の算出間違い
--      l_ap_if_rec.invoice_amount := get_ap_trance_data_rec.inv_amount;
      l_ap_if_rec.invoice_amount := get_ap_trance_data_rec.inv_item_amount +
        get_ap_trance_data_rec.inv_tax_amount;
--Ver1.1 change end
      -- INVOICE_CURRENCY_CODE
      l_ap_if_rec.invoice_currency_code := get_ap_trance_data_rec.inv_currency_code;
      -- EXCHANGE_RATE
      IF get_ap_trance_data_rec.inv_currency_code <> iv_currency_code AND
        get_ap_trance_data_rec.exchange_rate_type = cv_us_rate_type THEN
        l_ap_if_rec.exchange_rate := get_ap_trance_data_rec.exchange_rate;
      ELSE
        l_ap_if_rec.exchange_rate := NULL;
      END IF;
      -- EXCHANGE_RATE_TYPE
      l_ap_if_rec.exchange_rate_type := get_ap_trance_data_rec.exchange_rate_type;
      -- EXCHANGE_DATE
      l_ap_if_rec.exchange_date := get_ap_trance_data_rec.exchange_date;
      -- TERMS_ID
      l_ap_if_rec.terms_id := get_ap_trance_data_rec.terms_id;
      -- DESCRIPTION
      l_ap_if_rec.description := get_ap_trance_data_rec.description;
      -- LAST_UPDATE_DATE
      l_ap_if_rec.last_update_date := get_ap_trance_data_rec.upd_date;
      -- LAST_UPDATED_BY
      l_ap_if_rec.last_updated_by := ln_updated_by;
      -- LAST_UPDATE_LOGIN
      l_ap_if_rec.last_update_login := ln_update_login;
      -- CREATION_DATE
      l_ap_if_rec.creation_date := get_ap_trance_data_rec.upd_date;
      -- CREATED_BY
      l_ap_if_rec.created_by := ln_created_by;
      -- ATTRIBUTE_CATEGORY
      l_ap_if_rec.attribute_category := in_org_id;
      -- ATTRIBUTE2
      l_ap_if_rec.attribute2 := get_ap_trance_data_rec.vendor_invoice_num;
      -- ATTRIBUTE3
      l_ap_if_rec.attribute3 := get_ap_trance_data_rec.entry_department;
      -- ATTRIBUTE4
      SELECT xuv.user_name
      INTO l_ap_if_rec.attribute4
      FROM  xx03_users_v xuv
      WHERE xuv.employee_id = get_ap_trance_data_rec.entry_person_id;
      -- ATTRIBUTE5
      l_ap_if_rec.attribute5 := get_ap_trance_data_rec.orig_invoice_num;
      -- ATTRIBUTE6
      l_ap_if_rec.attribute6 := get_ap_trance_data_rec.attribute1;
      -- ATTRIBUTE7
      l_ap_if_rec.attribute7 := get_ap_trance_data_rec.attribute2;
      -- ATTRIBUTE8
      l_ap_if_rec.attribute8 := get_ap_trance_data_rec.attribute3;
      -- ATTRIBUTE9
      l_ap_if_rec.attribute9 := get_ap_trance_data_rec.attribute4;
      -- SOURCE
      l_ap_if_rec.source := iv_source;
      -- PAYMENT_METHOD_LOOKUP_CODE
      SELECT  xapgv.attribute1
      INTO    l_ap_if_rec.payment_method_lookup_code
      FROM    xx03_ap_pay_groups_v xapgv
      WHERE   xapgv.lookup_type = cv_pay_lookup_type
      AND     xapgv.lookup_code = get_ap_trance_data_rec.pay_group_lookup_code
      AND     xapgv.language = lv_cur_lang;
      -- PAY_GROUP_LOOKUP_CODE
      l_ap_if_rec.pay_group_lookup_code := get_ap_trance_data_rec.pay_group_lookup_code;
      -- GL_DATE
      l_ap_if_rec.gl_date := get_ap_trance_data_rec.gl_date;
      -- ORG_ID
      l_ap_if_rec.org_id := get_ap_trance_data_rec.org_id;
      -- PREPAY_NUM
      l_ap_if_rec.prepay_num := get_ap_trance_data_rec.prepay_num;
      -- TERMS_DATE
      SELECT  DECODE(at.attribute1,
                'Y',
                get_ap_trance_data_rec.terms_date,
                NULL)
      INTO    l_ap_if_rec.terms_date
      FROM    ap_terms_tl at
      WHERE   at.term_id = get_ap_trance_data_rec.terms_id
      AND     at.language = lv_cur_lang;
--
      -- =======================================
      -- API/Fの更新 (A-3)
      -- =======================================
      ins_ap_interface(
        l_ap_if_rec,                              -- 1.APインターフェースレコード(IN)
        in_org_id,                                -- 2.オルグID(IN)
        get_ap_trance_data_rec.upd_date,          -- 3.ヘッダー取得時のSYSDATE(IN)
        ln_updated_by,                            -- 4.最終更新者(IN)
        ln_update_login,                          -- 5.最終ログイン(IN)
        ln_created_by,                            -- 6.作成者(IN)
        ln_detail_cnt,                            -- 7.明細件数(OUT)
--Ver1.1 add start 明細キー(xx03_payment_slipsのinvoice_id)の渡し忘れ
        get_ap_trance_data_rec.key_invoice_id,    -- 8.明細キー請求書ID(IN)
--Ver1.1 add end
        lv_errbuf,      -- エラー・メッセージ           --# 固定 #
        lv_retcode,     -- リターン・コード             --# 固定 #
        lv_errmsg);     -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
--
      -- ver 11.5.10.2.10 Add Start
      -- 正常時処理
      IF (ov_retcode != xx00_common_pkg.set_status_error_f) AND
         (ov_retcode != xx00_common_pkg.set_status_warn_f ) THEN
        UPDATE  xx03_payment_slips xps
        SET     xps.ap_forword_date = od_upd_date,
                xps.last_update_date = od_upd_date,
                xps.last_updated_by = xx00_global_pkg.user_id,
                xps.last_update_login = xx00_global_pkg.last_update_login
        WHERE   xps.invoice_id = get_ap_trance_data_rec.key_invoice_id
        ;
      END IF;
      -- ver 11.5.10.2.10 Add End
--
      -- 件数のカウント
      on_header_cnt := on_header_cnt + 1;
      on_detail_cnt := on_detail_cnt + ln_detail_cnt;
    END LOOP get_ap_trance_loop;
    CLOSE get_ap_trance_data_cur;
--
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
    WHEN chk_data_none_expt THEN        --*** 転送処理対象データ未取得エラー ***
      -- *** 任意で例外処理を記述する ****
      xx00_file_pkg.log(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08003'));           -- 転送処理対象データ未取得エラーメッセージ
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      --Ver1.1 change start ステータスは警告にする
--      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_warn_f;                                  --# 任意 #
      --Ver1.1 change end
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
  END get_approval_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : upd_slip_data
   * Description      : AP転送済仕入先請求書データの更新 (A-4)
   ***********************************************************************************/
  PROCEDURE upd_slip_data(
    in_org_id         IN  NUMBER,       -- 1.オルグID(IN)
    id_sysdate        IN  DATE,         -- 2.更新日付(IN)
    ov_errbuf         OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode        OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg         OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'upd_slip_data'; -- プログラム名
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
    --ログ出力
    xx00_file_pkg.log('>>'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
    --仕入先請求書データの更新
    UPDATE  xx03_payment_slips xps
    SET     xps.ap_forword_date = id_sysdate,
            xps.last_update_date = id_sysdate,
            xps.last_updated_by = xx00_global_pkg.user_id,
            xps.last_update_login = xx00_global_pkg.last_update_login
    WHERE   xps.wf_status = cv_appr_status
    AND     xps.ap_forword_date IS NULL
    AND     xps.org_id = in_org_id;
--
    --ログ出力
    xx00_file_pkg.log('UPDATE table :xx03_payment_slips');
    xx00_file_pkg.log('org_id = '|| TO_CHAR(in_org_id));
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
  END upd_slip_data;
--
  /**********************************************************************************
   * Procedure Name   : msg_output
   * Description      : 結果出力 (A-4)
   ***********************************************************************************/
  PROCEDURE msg_output(
    in_org_id     IN  NUMBER,       --  1.チェックID(IN)
    in_books_id   IN  NUMBER,       --  2.会計帳簿ID(IN)
    in_header_cnt IN  NUMBER,       --  3.ヘッダ件数(IN)
    in_detail_cnt IN  NUMBER,       --  4.明細件数(IN)
    iv_source     IN  VARCHAR2,     --  5.ソース名(IN)
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
--
    -- *** ローカル変数 ***
    lv_conc_name  fnd_concurrent_programs.concurrent_program_name%TYPE;
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
    l_conc_para_rec  xx03_get_prompt_pkg.g_conc_para_tbl_type;
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
--
    -- ヘッダー出力
    xx03_header_line_output_pkg.header_line_output_p('GL',    -- 会計帳簿名を表示する
      xx00_global_pkg.prog_appl_id,
      in_books_id,                        -- 会計帳簿ID
      in_org_id,                          -- オルグID
      xx00_global_pkg.conc_program_id,
      lv_errbuf,
      lv_retcode,
      lv_errmsg);
    IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
    -- パラメータのログ出力
    xx00_file_pkg.output(' ');
--Ver1.1 add Start CD漏れ
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
--Ver1.1 add End
    xx00_file_pkg.output(l_conc_para_rec(1).param_prompt ||
      ':' ||
      iv_source);
    xx00_file_pkg.output(' ');
--
    -- 件数出力
    xx00_file_pkg.output(
    xx00_message_pkg.get_msg(
      'XX03',
      'APP-XX03-04004',             -- 承認済仕入先請求書転送結果出力
      'XX03_TOK_HEAD_CNT',
      in_header_cnt,                -- AP転送件数(ヘッダ)
      'XX03_TOK_DETAIL_CNT',
      in_detail_cnt));              -- AP転送件数(配分)
    --ログ出力
    xx00_file_pkg.log('<<'||cv_prg_name||'() '||
      TO_CHAR(xx00_date_pkg.get_system_datetime_f,cv_date_time_format));
    xx00_file_pkg.log(' ');
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN  -- *** 処理部共通例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
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
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     -- 1.ソース名
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
    ln_org_id         NUMBER(15,0);   -- オルグID
    ln_books_id       gl_sets_of_books.set_of_books_id%TYPE;  -- 会計帳簿ID
    lv_currency_code  gl_sets_of_books.currency_code%TYPE;    -- 機能通貨
    ln_header_cnt     NUMBER;         -- ヘッダ件数
    ln_detail_cnt     NUMBER;         -- 明細件数
    ld_upd_date       DATE;           -- 更新日付
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
    -- =======================================
    -- AP未承認仕入先請求書データの確認 (A-1)
    -- =======================================
    vaild_approval(
      ln_org_id,          -- 1.オルグID(OUT)
      ln_books_id,        -- 2.会計帳簿ID(OUT)
      lv_currency_code,   -- 3.機能通貨(OUT)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    END IF;
--
    -- =======================================
    -- 経理承認済仕入先請求書データの取得(A-2)
    -- =======================================
    get_approval_slip_data(
      iv_source,          -- 1.ソース名(IN)
      ln_org_id,          -- 2.オルグID(IN)
      lv_currency_code,   -- 3.機能通貨(IN)
      ln_header_cnt,      -- 4.ヘッダ件数(OUT)
      ln_detail_cnt,      -- 5.明細件数(OUT)
      ld_upd_date,        -- 6.更新日付(OUT)
      lv_errbuf,          -- エラー・メッセージ           --# 固定 #
      lv_retcode,         -- リターン・コード             --# 固定 #
      lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --(エラー処理)
      RAISE global_process_expt;
    --Ver1.1 add start 警告ステータス時、処理中断
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      ov_retcode := xx00_common_pkg.set_status_warn_f;
    ELSE
--
      -- ver 11.5.10.2.10 Del Start
      ---- =======================================
      ---- AP転送済仕入先請求書データの更新 (A-4)
      ---- =======================================
      --upd_slip_data(
      --  ln_org_id,            -- 1.オルグID(IN)
      --  ld_upd_date,          -- 2.更新日付(IN)
      --  lv_errbuf,            -- エラー・メッセージ           --# 固定 #
      --  lv_retcode,           -- リターン・コード             --# 固定 #
      --  lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
      --IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      --  --(エラー処理)
      --  RAISE global_process_expt;
      --END IF;
      -- ver 11.5.10.2.10 Del End
--
      -- =======================================
      -- 結果出力 (A-4)
      -- =======================================
      msg_output(
        ln_org_id,          --  1.チェックID(IN)
        ln_books_id,        --  2.会計帳簿ID(IN)
        ln_header_cnt,      --  3.ヘッダ件数(IN)
        ln_detail_cnt,      --  4.明細件数(IN)
        iv_source,          --  5.ソース名(IN)
        lv_errbuf,          -- エラー・メッセージ           --# 固定 #
        lv_retcode,         -- リターン・コード             --# 固定 #
        lv_errmsg);         -- ユーザー・エラー・メッセージ --# 固定 #
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        --(エラー処理)
        RAISE global_process_expt;
      END IF;
    --Ver1.1 add end
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
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf        OUT VARCHAR2,      --   エラー・メッセージ  --# 固定 #
    retcode       OUT VARCHAR2,      --   リターン・コード    --# 固定 #
    iv_source     IN  VARCHAR2)      -- 1.ソース名(IN)
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
      iv_source,   -- 1.ソース名(IN)
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
END XX034PT001C;
/
