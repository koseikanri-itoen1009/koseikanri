CREATE OR REPLACE PACKAGE BODY xx03_deptinput_ap_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ap_check_pkg(body)
 * Description            : 部門入力(AP)において入力チェックを行う共通関数
 * MD.070                 : 部門入力(AP)共通関数 OCSJ/BFAFIN/MD070/F409
 * Version                : 11.5.10.2.11
 *
 * Program List
 *  -------------------------- ---- ----- --------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- --------------------------------------------------
 *  check_deptinput_ap          P          部門入力(AP)のエラーチェック
 *  set_account_approval_flag   P          重点管理チェック
 *  get_terms_date              P          支払起算日の算出
 *  del_pay_data                P          支払伝票レコードの削除
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/02/09   1.0            新規作成
 *  2004/02/18   1.1            単体テストでの不具合修正
 *  2004/02/19   1.2            仕様変更
 *  2004/02/23   1.3            get_terms_dateの支払予定日SQLを修正
 *  2004/02/26   1.4            支払伝票レコードの削除プロシージャ追加
 *  2004/03/26   1.5            前払伝票番号正当性チェック処理追加
 *  2004/04/13   1.6            重点管理の判定方法変更
 *  2005/01/17   1.7            相互検証ルールの機能実装
 *  2005/01/22   1.8            支払伝票レコードの削除処理の変更
 *  2005/09/02   11.5.10.1.5    パフォーマンス改善対応
 *  2005/10/18   11.5.10.1.5B   取消伝票を再度申請できてしまう不具合対応
 *  2006/01/30   11.5.10.1.6    相互検証ルールのチェックで、日付をGL計上日を
 *                              渡すよう変更
 *  2006/02/15   11.5.10.1.6B   ダブルクリック対応,PKGでcommitするPROCEDURE追加
 *  2006/02/15   11.5.10.1.6C   マスター存在チェックを実施するように変更
 *  2006/03/02   11.5.10.1.6D   エラーチェックテーブルのクリアロジックの不具合
 *  2006/03/06   11.5.10.1.6E   承認者の承認権限チェック不具合修正
 *  2006/03/29   11.5.10.2.1    HR対応（従業員履歴レコード対応）
 *  2006/04/07   11.5.10.2.2    承認者が対象伝票に対する承認権限があるかのチェック追加
 *  2006/04/12   11.5.10.2.2B   11.5.10.2.2での修正ミス対応
 *  2006/06/22   11.5.10.2.3    マスタチェック用SQLでデータが取得でなかった時の
 *                              エラー処理が誤っていることの修正
 *  2006/07/12   11.5.10.2.3B   振込先口座チェック用SQLで必須条件誤りの修正
 *  2006/08/17   11.5.10.2.4    仕入先・サイトのマスタチェックで有効日を
 *                              請求書日付ではなくSYSDATEでチェックするように修正
 *  2006/09/06   11.5.10.2.5    振込先口座チェック条件の変更(仕入先サイトの支払方法が
 *                              電信の場合のみ口座の有効存在チェックを行なう)
 *  2006/10/03   11.5.10.2.6    マスタチェックの見直し(有効日のチェックを請求書日付で
 *                              行なう項目とSYSDATEで行なう項目を再確認)
 *  2007/07/17   11.5.10.2.10   摘要コードチェックの修正(有効日自が未入力はOKとする)
 *  2007/08/06   11.5.10.2.10B  支払グループチェックの修正(有効日自が未入力はOKとする)
 *  2007/08/10   11.5.10.2.10C  仕訳配分チェックでエラーの時のメッセージに
 *                              ヘッダ･明細･税金のどの配分かを表示するように修正
 *  2007/08/16   11.5.10.2.10D  銀行支店/銀行口座の無効日は前日まで有効とするように修正
 *  2007/10/04   11.5.10.2.10E  振込先口座チェック時に支払方法が電信かどうかという
 *                              判断を行っているが、仕入先サイトの支払方法ではなく
 *                              支払グループのDFF支払方法を使用するように修正
 *  2007/10/29   11.5.10.2.10F  通貨の精度チェック(入力可能精度か桁チェック)追加
 *  2008/01/07   11.5.10.2.10G  to_date関数にて書式指定を行っていない箇所があり
 *                              yyyy/mm/ddを自動認識できない場合にエラーとなる事の修正
 *  2012/02/15   11.5.10.2.11   [E_本稼動_09132]対応 摘要コードのDFF10(税コード)と
 *                              入力した税コードが一致しているかチェックする修正
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ap
   * Description      : 部門入力(AP)のエラーチェック
   ***********************************************************************************/
  PROCEDURE check_deptinput_ap(
    in_invoice_id  IN   NUMBER,    -- 1.チェック対象請求書ID
    on_error_cnt   OUT  NUMBER,    -- 2.処理全体でのエラーフラグ
    ov_error_flg   OUT  VARCHAR2,  -- 3.処理全体でのエラーフラグ
    ov_error_flg1  OUT  VARCHAR2,  -- 4.1個目のRETURNデータのエラーフラグ
    ov_error_msg1  OUT  VARCHAR2,  -- 5.1個目のRETURNデータのエラー内容
    ov_error_flg2  OUT  VARCHAR2,  -- 6.2個目のRETURNデータのエラーフラグ
    ov_error_msg2  OUT  VARCHAR2,  -- 7.2個目のRETURNデータのエラー内容
    ov_error_flg3  OUT  VARCHAR2,  -- 8.3個目のRETURNデータのエラーフラグ
    ov_error_msg3  OUT  VARCHAR2,  -- 9.3個目のRETURNデータのエラー内容
    ov_error_flg4  OUT  VARCHAR2,  -- 10.4個目のRETURNデータのエラーフラグ
    ov_error_msg4  OUT  VARCHAR2,  -- 11.4個目のRETURNデータのエラー内容
    ov_error_flg5  OUT  VARCHAR2,  -- 12.5個目のRETURNデータのエラーフラグ
    ov_error_msg5  OUT  VARCHAR2,  -- 13.5個目のRETURNデータのエラー内容
    ov_error_flg6  OUT  VARCHAR2,  -- 14.6個目のRETURNデータのエラーフラグ
    ov_error_msg6  OUT  VARCHAR2,  -- 15.6個目のRETURNデータのエラー内容
    ov_error_flg7  OUT  VARCHAR2,  -- 16.7個目のRETURNデータのエラーフラグ
    ov_error_msg7  OUT  VARCHAR2,  -- 17.7個目のRETURNデータのエラー内容
    ov_error_flg8  OUT  VARCHAR2,  -- 18.8個目のRETURNデータのエラーフラグ
    ov_error_msg8  OUT  VARCHAR2,  -- 19.8個目のRETURNデータのエラー内容
    ov_error_flg9  OUT  VARCHAR2,  -- 20.9個目のRETURNデータのエラーフラグ
    ov_error_msg9  OUT  VARCHAR2,  -- 21.9個目のRETURNデータのエラー内容
    ov_error_flg10 OUT  VARCHAR2,  -- 22.10個目のRETURNデータのエラーフラグ
    ov_error_msg10 OUT  VARCHAR2,  -- 23.10個目のRETURNデータのエラー内容
    ov_error_flg11 OUT  VARCHAR2,  -- 24.11個目のRETURNデータのエラーフラグ
    ov_error_msg11 OUT  VARCHAR2,  -- 25.11個目のRETURNデータのエラー内容
    ov_error_flg12 OUT  VARCHAR2,  -- 26.12個目のRETURNデータのエラーフラグ
    ov_error_msg12 OUT  VARCHAR2,  -- 27.12個目のRETURNデータのエラー内容
    ov_error_flg13 OUT  VARCHAR2,  -- 28.13個目のRETURNデータのエラーフラグ
    ov_error_msg13 OUT  VARCHAR2,  -- 29.13個目のRETURNデータのエラー内容
    ov_error_flg14 OUT  VARCHAR2,  -- 30.14個目のRETURNデータのエラーフラグ
    ov_error_msg14 OUT  VARCHAR2,  -- 31.14個目のRETURNデータのエラー内容
    ov_error_flg15 OUT  VARCHAR2,  -- 32.15個目のRETURNデータのエラーフラグ
    ov_error_msg15 OUT  VARCHAR2,  -- 33.15個目のRETURNデータのエラー内容
    ov_error_flg16 OUT  VARCHAR2,  -- 34.16個目のRETURNデータのエラーフラグ
    ov_error_msg16 OUT  VARCHAR2,  -- 35.16個目のRETURNデータのエラー内容
    ov_error_flg17 OUT  VARCHAR2,  -- 36.17個目のRETURNデータのエラーフラグ
    ov_error_msg17 OUT  VARCHAR2,  -- 37.17個目のRETURNデータのエラー内容
    ov_error_flg18 OUT  VARCHAR2,  -- 38.18個目のRETURNデータのエラーフラグ
    ov_error_msg18 OUT  VARCHAR2,  -- 39.18個目のRETURNデータのエラー内容
    ov_error_flg19 OUT  VARCHAR2,  -- 40.19個目のRETURNデータのエラーフラグ
    ov_error_msg19 OUT  VARCHAR2,  -- 41.19個目のRETURNデータのエラー内容
    ov_error_flg20 OUT  VARCHAR2,  -- 42.20個目のRETURNデータのエラーフラグ
    ov_error_msg20 OUT  VARCHAR2,  -- 43.20個目のRETURNデータのエラー内容
    ov_errbuf      OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode     OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg      OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.check_deptinput_ap'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ###############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    -- エラーフラグ用配列タイプ
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
    -- エラーメッセージ用配列タイプ
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
    errflg_tbl errflg_tbl_type;
    errmsg_tbl errmsg_tbl_type;
    ln_err_cnt NUMBER := 0;    -- パラメータ添字用変数
    ln_books_id NUMBER;        -- 帳簿ID
    lv_first_flg VARCHAR2(1) := 'Y';  -- 1件目のレコードか否か
-- ver 11.5.10.1.6D Chg Start
    --ln_check_seq NUMBER;       -- エラーチェックシーケンス番号
    ln_check_seq NUMBER := 0;  -- エラーチェックシーケンス番号
-- ver 11.5.10.1.6D Chg End
    ln_cnt NUMBER;             -- ループカウンタ
    lv_err_status VARCHAR2(1); -- 共通エラーチェックステータス
    lv_currency_code VARCHAR2(15); -- 機能通貨コード
    lv_chk_currency_code VARCHAR2(15);      -- チェック用データ通貨コード
    ln_chk_exchange_rate NUMBER;            -- チェック用データ換算レート
    lv_chk_exchange_rate_type VARCHAR2(30); -- チェック用データ換算レートタイプ
    ld_chk_gl_date DATE;                    -- チェック用データ計上日
    lv_chk_prepay_num VARCHAR2(50);         -- チェック用データ前払充当伝票番号
    lv_chk_orig_invoice_num VARCHAR2(150);  -- チェック用データ修正元伝票番号
    -- 2004/02/19 ADD START
    lv_period_data_flg VARCHAR2(1);         -- 会計期間データ有無フラグ
    -- 2004/02/19 ADD END
    -- 2005/01/17:相互検証用パラメータ
    lb_retcode BOOLEAN;
    lv_app_short_name VARCHAR2(100) := 'SQLGL'; -- アプリケーション'General Ledger'
    lv_key_flex_code VARCHAR2(1000) := 'GL#'; -- FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE
    ln_structure_number NUMBER := null; -- GL_SETS_OF_BOOKS.CHART_OF_ACCOUNTS_ID,
    ld_validation_date DATE := SYSDATE;
    ln_segments NUMBER := 8;
    lv_segment_array FND_FLEX_EXT.SEGMENTARRAY;
    on_combination_id NUMBER := null;
    ld_data_set NUMBER := -1;
    --2006/02/18 Ver11.5.10.1.6C Add START
    ld_chk_invoice_date DATE;                    -- チェック用データ請求書日付
    --2006/02/18 Ver11.5.10.1.6C Add END
    -- 2006/03/06 Ver11.5.10.1.6E Add Start
    ld_wf_status              VARCHAR2(25);        -- チェック用ワークフローステータス
    cn_wf_status_dept   VARCHAR2(25) := '20';      -- 部門入力承認待ちステータス
    -- 2006/03/06 Ver11.5.10.1.6E Add End
--
    -- ver 11.5.10.2.2 Add Start
    cn_wf_status_save   VARCHAR2(25) := '00';      -- 部門入力保存ステータス
    cn_wf_status_last   VARCHAR2(25) := '30';      -- 部門入力最終部門承認待ちステータス
    -- ver 11.5.10.2.2 Add End
--
    -- ver 11.5.10.2.5 Add Start
    cv_vendor_sites_eft VARCHAR2(3) := 'EFT';      -- 仕入先サイトの支払方法の値｢電信｣
    -- ver 11.5.10.2.5 Add End
--
    -- ver 11.5.10.2.10C Add Start
    lv_je_err_msg       VARCHAR2(14);              -- 配分チェックエラー時の追加メッセージコード
    -- ver 11.5.10.2.10C Add End
--
    -- ver 11.5.10.2.10F Add Start
    lb_currency_chk        BOOLEAN      := FALSE;  -- 通貨エラーOK/NGフラグ(精度チェック時に使用)
    ln_currency_precision  NUMBER(1)    := 0;      -- 通貨の精度(通貨チェックOK時に精度を取得)
    lv_amount              VARCHAR2(50) := '';     -- 伝票での金額精度取得用
    ln_amount_precision    NUMBER(1)    := 0;      -- 伝票での金額の精度
    cv_precision_char      VARCHAR2(1)  := '.';    -- 小数点記号
    -- ver 11.5.10.2.10F Add End
--
    -- *** ローカル・カーソル ***
    -- 処理対象データ取得カーソル
    CURSOR xx03_xpsjlv_cur
    IS
      SELECT xpsjlv.invoice_num as invoice_num,
             xpsjlv.line_number as line_number,
             xpsjlv.gl_date as gl_date,
             xpsjlv.invoice_currency_code as invoice_currency_code,
             xpsjlv.code_combination_id as code_combination_id,
             xpsjlv.segment1 as segment1,
             xpsjlv.segment2 as segment2,
             xpsjlv.segment3 as segment3,
             xpsjlv.segment4 as segment4,
             xpsjlv.segment5 as segment5,
             xpsjlv.segment6 as segment6,
             xpsjlv.segment7 as segment7,
             xpsjlv.segment8 as segment8,
             xpsjlv.tax_code as tax_code,
             xpsjlv.incr_decr_reason_code as incr_decr_reason_code,
             xpsjlv.entry_department as entry_department,
             xpsjlv.user_name as user_name,
             xpsjlv.recon_reference as recon_reference,
      --2006/02/16 Ver11.5.10.1.6C add START
             --xpsjlv.amount as amount
             xpsjlv.amount as amount,
             xpsjlv.line_type_lookup_code as line_type_lookup_code
      --2006/02/16 Ver11.5.10.1.6C add END
        FROM xx03_pay_slip_journal_lines_v xpsjlv
       WHERE xpsjlv.invoice_id = in_invoice_id
       ORDER BY xpsjlv.line_number;
--
    -- レートカーソル
    CURSOR xx03_rate_cur(
      iv_invoice_currency_code IN VARCHAR2, -- 1.通貨コード
      iv_exchange_rate_type IN VARCHAR2,    -- 2.レートタイプ
      id_gl_date IN DATE                    -- 3.GL記帳日
    ) IS
      SELECT xgdr.conversion_rate as conversion_rate
        FROM xx03_gl_daily_rates_v xgdr
       WHERE xgdr.from_currency = iv_invoice_currency_code
         AND xgdr.conversion_type = iv_exchange_rate_type
         AND xgdr.conversion_date = TRUNC(id_gl_date);
--
-- ver1.5 ADD START
    -- 前払充当伝票番号取得チェックカーソル
    CURSOR xx03_prepay_get_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xpsv.prepay_num as prepay_num
--        FROM xx03_payment_slips_v xpsv
--       WHERE xpsv.invoice_id = in_invoice_id;
      SELECT xps.prepay_num as prepay_num
        FROM xx03_payment_slips xps
       WHERE xps.invoice_id = in_invoice_id;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- 前払充当伝票番号正当性チェックカーソル
    CURSOR xx03_prepay_check_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xpsv.invoice_id
--        FROM xx03_payment_slips_v xpsv,
--             xx03_prepayment_lov_v xplv
--       WHERE xpsv.invoice_id = in_invoice_id
--         AND xpsv.prepay_num = xplv.invoice_num
--         AND xpsv.vendor_id = xplv.vendor_id
--         AND xpsv.invoice_currency_code = xplv.invoice_currency_code;
      SELECT xps.invoice_id
        FROM xx03_payment_slips xps,
             xx03_prepayment_lov_v xplv
       WHERE xps.invoice_id = in_invoice_id
         AND xps.prepay_num = xplv.invoice_num
         AND xps.vendor_id = xplv.vendor_id
         AND xps.invoice_currency_code = xplv.invoice_currency_code;
-- Ver11.5.10.1.5 2005/09/02 Change End
-- ver1.5 ADD END
--
    -- 前払充当伝票番号チェックカーソル
    CURSOR xx03_prepay_num_cur(
      iv_prepay_num IN VARCHAR2 -- 1.前払充当伝票番号
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM xx03_payment_slips_v xpsv
--       WHERE xpsv.ap_forword_date IS NULL
--         AND xpsv.prepay_num = iv_prepay_num
--         AND xpsv.wf_status >= 20
--         AND xpsv.invoice_id != in_invoice_id;
      SELECT *
        FROM xx03_payment_slips xps
       WHERE xps.ap_forword_date IS NULL
         AND xps.prepay_num = iv_prepay_num
         AND xps.wf_status >= 20
         AND xps.invoice_id != in_invoice_id
         AND xps.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- 修正元伝票番号チェックカーソル
    CURSOR xx03_orig_num_cur(
      iv_orig_invoice_num  IN VARCHAR2 -- 1.修正元伝票番号
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM xx03_payment_slips_v xpsv
--       WHERE xpsv.ap_forword_date IS NULL
--         AND xpsv.orig_invoice_num = iv_orig_invoice_num
--         AND xpsv.wf_status >= 20
--         AND xpsv.invoice_id != in_invoice_id;
      -- Ver11.5.10.1.5B 2005/10/18 Change Start
      --SELECT *
      --  FROM xx03_payment_slips xps
      -- WHERE xps.ap_forword_date IS NULL
      --   AND xps.orig_invoice_num = iv_orig_invoice_num
      --   AND xps.wf_status >= 20
      --   AND xps.invoice_id != in_invoice_id
      --   AND xps.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      SELECT *
        FROM xx03_payment_slips xps
       WHERE xps.orig_invoice_num = iv_orig_invoice_num
         AND xps.wf_status >= 20
         AND xps.invoice_id != in_invoice_id
         AND xps.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      -- Ver11.5.10.1.5B 2005/10/18 Change End
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- AP会計期間チェックカーソル
    CURSOR xx03_ap_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.帳簿ID
      id_gl_date    IN DATE       -- 2.GL記帳日
    ) IS
      SELECT gps.closing_status as closing_status
        FROM gl_period_statuses gps
       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLAP')
         AND gps.set_of_books_id = in_books_id
         AND gps.start_date <= TRUNC(id_gl_date)
         AND gps.end_date >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag = 'N';
--
    -- GL会計期間チェックカーソル
    CURSOR xx03_gl_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.帳簿ID
      id_gl_date    IN DATE       -- 2.GL記帳日
    ) IS
      SELECT gps.attribute1 as attribute1
        FROM gl_period_statuses gps
       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLGL')
         AND gps.set_of_books_id = in_books_id
         AND gps.start_date <= TRUNC(id_gl_date)
         AND gps.end_date >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag = 'N';
--
-- ver 11.5.10.2.2 add Start
    -- 申請者と承認者の関係 チェックカーソル
    CURSOR xx03_req_app_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_APPROVER_PERSON_V      XAPV
          ,XX03_PAYMENT_SLIPS          XPS
          ,XX03_DEPARTMENTS_V          XDV
          ,XX03_PER_PEOPLES_V          XPPV
          ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE  AND XAPV.EFFECTIVE_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE          AND XAPV.R_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE          AND XAPV.U_END_DATE
      AND  XAPV.PERSON_ID   != XPS.REQUESTOR_PERSON_ID
      AND  XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
      AND  XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
      AND  XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
      AND  XPPV.PERSON_ID   = XPS.REQUESTOR_PERSON_ID
      AND  TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE  AND XPPV.EFFECTIVE_END_DATE
      AND  XAPV.PROFILE_VAL_AUTH != 9
      AND  (   XAPV.PROFILE_VAL_DEP = 'ALL'
            OR XAPV.PROFILE_VAL_DEP = 'SQLAP'   )
      AND  XAPV.PERSON_ID   = XPS.APPROVER_PERSON_ID
    ;
-- ver 11.5.10.2.2 add End
--
--2006/02/15 Ver11.5.10.1.6C add start
--各マスター存在チェック
--
    --承認者チェックカーソル
    CURSOR xx03_approver_cur
    IS
-- 2006/03/06 Ver11.5.10.1.6E Change Start
--    SELECT COUNT(1) exist_check
--      FROM per_all_assignments_f pa
--          ,xx03_per_peoples_v    xppv
--          ,xx03_payment_slips xps
--     WHERE xps.invoice_id = in_invoice_id
--       AND pa.supervisor_id = xppv.person_id
--       AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date
--                              AND pa.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.effective_start_date
--                              AND xppv.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.u_start_date
--                              AND xppv.u_end_date
--       AND pa.person_id = xps.requestor_person_id;
    SELECT COUNT(1) exist_check
    FROM   xx03_per_peoples_v xppv1
          ,(SELECT paf.supervisor_id
            FROM   xx03_per_peoples_v xppv
                  ,per_assignments_f  paf
            WHERE  xppv.user_id  = XX00_PROFILE_PKG.VALUE('USER_ID')
              -- ver 11.5.10.2.1 Add Start
              AND  SYSDATE BETWEEN paf.effective_start_date
                               AND paf.effective_end_date
              -- ver 11.5.10.2.1 Add End
              AND  paf.person_id = xppv.person_id
            ) xppv2
    WHERE  xppv1.person_id = xppv2.supervisor_id
      AND  EXISTS (SELECT '1'
                   FROM   
                     (SELECT XAPV.PERSON_ID
                       FROM XX03_APPROVER_PERSON_V      XAPV
                           ,XX03_PAYMENT_SLIPS          XPS
                           ,XX03_DEPARTMENTS_V          XDV
                           ,XX03_PER_PEOPLES_V          XPPV
                           ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
                      WHERE  XPS.INVOICE_ID = in_invoice_id
                        AND TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE
                                               AND XAPV.EFFECTIVE_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE
                                               AND XAPV.R_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE
                                               AND XAPV.U_END_DATE
                        AND XAPV.PERSON_ID   != XPS.APPROVER_PERSON_ID
                        AND XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
                        AND XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
                        AND XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
                        AND XPPV.PERSON_ID     = XPS.APPROVER_PERSON_ID
                        AND TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE
                                               AND XPPV.EFFECTIVE_END_DATE
                        AND XAPV.PROFILE_VAL_AUTH != 9
                        AND (   XAPV.PROFILE_VAL_DEP = 'ALL'
                             OR XAPV.PROFILE_VAL_DEP = 'SQLAP'   )) xaplv
                   WHERE xaplv.person_id = xppv2.supervisor_id
                                );
-- 2006/03/06 Ver11.5.10.1.6E Change End
--
    --仕入先チェックカーソル
    CURSOR xx03_vendor_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   PO_VENDORS PV
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  PV.VENDOR_ID = XPS.VENDOR_ID
      -- ver 11.5.10.2.4 Add Start
      --AND  XPS.INVOICE_DATE < NVL(PV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) < NVL(PV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.4 Add End
--
    --仕入先サイトチェックカーソル
    CURSOR xx03_vendor_site_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   PO_VENDOR_SITES_ALL PVS
          ,XX03_PAYMENT_SLIPS  XPS
    WHERE  PVS.ORG_ID             = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  PVS.PAY_SITE_FLAG      = 'Y'
      AND  PVS.AUTO_TAX_CALC_FLAG = 'N'
      AND  PVS.VENDOR_ID      = XPS.VENDOR_ID
      AND  PVS.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
      AND  XPS.INVOICE_ID = in_invoice_id
      -- ver 11.5.10.2.4 Add Start
      --AND  XPS.INVOICE_DATE < NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) < NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.4 Add End
--
    --振込先口座チェック
    -- ver 11.5.10.2.5 Chg Start
    --CURSOR xx03_bank_name_cur
    --IS
    --SELECT COUNT(1) exist_check
    --FROM   PO_VENDOR_SITES_ALL      PVS
    --      ,AP_BANK_ACCOUNT_USES_ALL ABAU
    --      ,AP_BANK_ACCOUNTS_ALL     ABA
    --      ,AP_BANK_BRANCHES         ABB
    --      ,XX03_PAYMENT_SLIPS       XPS
    --WHERE  XPS.INVOICE_ID = in_invoice_id
    --  AND  PVS.PAY_SITE_FLAG = 'Y'
    --  AND  PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --  AND  PVS.VENDOR_ID      = XPS.VENDOR_ID
    --  AND  PVS.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
    --  AND  PVS.VENDOR_ID      = ABAU.VENDOR_ID
    --  AND  PVS.VENDOR_SITE_ID = ABAU.VENDOR_SITE_ID
    --  AND  ABAU.PRIMARY_FLAG  = 'Y'
    --  -- ver 11.5.10.2.3B Add Start
    --  --AND  XPS.INVOICE_DATE BETWEEN ABAU.START_DATE
    --  --                     AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --  AND  XPS.INVOICE_DATE BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                       AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --  -- ver 11.5.10.2.3B Add End
    --  AND  ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --  AND  ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
    --  AND  XPS.INVOICE_DATE < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --  AND  ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID
    --  AND  XPS.INVOICE_DATE < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
    --
--
    -- ver 11.5.10.2.10E Chg Start
    --CURSOR xx03_bank_name_cur
    --IS
    --SELECT PVS.PAYMENT_METHOD_LOOKUP_CODE PAYMETHOD
    --      ,AP_BANK.NAME NAME
    --FROM   XX03_PAYMENT_SLIPS       XPS
    --      ,PO_VENDOR_SITES_ALL      PVS
    --      ,(SELECT ABAU.VENDOR_ID      VENDOR_ID
    --              ,ABAU.VENDOR_SITE_ID VENDOR_SITE_ID
    --              -- ver 11.5.10.2.6 Chg Start
    --              --,ABB.BANK_NAME        || ' ' || ABB.BANK_BRANCH_NAME || ' ' ||
    --              -- DECODE(ABA.BANK_ACCOUNT_TYPE, '1', '普通', '2', '当座', '') || ' ' || ABA.BANK_ACCOUNT_NUM
    --              -- NAME
    --              ,NVL2(ABB.BANK_NAME ,ABB.BANK_NAME || ' ' || ABB.BANK_BRANCH_NAME || ' ' ||
    --                                   DECODE(ABA.BANK_ACCOUNT_TYPE ,'1' ,'普通' ,'2' ,'当座' ,'') || ' ' || ABA.BANK_ACCOUNT_NUM
    --                                  ,null) NAME
    --              -- ver 11.5.10.2.6 Chg End
    --        FROM   XX03_PAYMENT_SLIPS       XPS
    --              ,AP_BANK_ACCOUNT_USES_ALL ABAU
    --              ,AP_BANK_ACCOUNTS_ALL     ABA
    --              ,AP_BANK_BRANCHES         ABB
    --        WHERE  XPS.INVOICE_ID = in_invoice_id
    --          AND  ABAU.VENDOR_ID      = XPS.VENDOR_ID
    --          AND  ABAU.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
    --          AND  ABAU.PRIMARY_FLAG  = 'Y'
    --          -- ver 11.5.10.2.6 Chg Start
    --          --AND  XPS.INVOICE_DATE BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --          --                          AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          AND  TRUNC(SYSDATE) BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                                  AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.6 Chg End
    --          AND  ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --          AND  ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
    --          -- ver 11.5.10.2.6 Chg Start
    --          --AND  XPS.INVOICE_DATE < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg Start
    --          --AND  TRUNC(SYSDATE) <= NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          AND  TRUNC(SYSDATE) < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg End
    --          -- ver 11.5.10.2.6 Chg End
    --          AND  ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID
    --          -- ver 11.5.10.2.6 Chg Start
    --          --AND  XPS.INVOICE_DATE < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg Start
    --          --AND  TRUNC(SYSDATE) <= NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          AND  TRUNC(SYSDATE) < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    --          -- ver 11.5.10.2.10D Chg End
    --          -- ver 11.5.10.2.6 Chg End
    --        ) AP_BANK
    --WHERE  XPS.INVOICE_ID = in_invoice_id
    --  AND  PVS.PAY_SITE_FLAG = 'Y'
    --  AND  PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
    --  AND  PVS.VENDOR_ID       = XPS.VENDOR_ID
    --  AND  PVS.VENDOR_SITE_ID  = XPS.VENDOR_SITE_ID
    --  AND  PVS.VENDOR_ID       = AP_BANK.VENDOR_ID     (+)
    --  AND  PVS.VENDOR_SITE_ID  = AP_BANK.VENDOR_SITE_ID(+)
    --;
    ---- ver 11.5.10.2.5 Chg End
--
    --振込先口座取得
    CURSOR xx03_bank_name_cur
    IS
    SELECT NVL2(ABB.BANK_NAME ,ABB.BANK_NAME || ' ' || ABB.BANK_BRANCH_NAME || ' ' ||
                DECODE(ABA.BANK_ACCOUNT_TYPE ,'1' ,'普通' ,'2' ,'当座' ,'') || ' ' || ABA.BANK_ACCOUNT_NUM
                ,null) NAME
    FROM   XX03_PAYMENT_SLIPS       XPS
          ,AP_BANK_ACCOUNT_USES_ALL ABAU
          ,AP_BANK_ACCOUNTS_ALL     ABA
          ,AP_BANK_BRANCHES         ABB
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  ABAU.VENDOR_ID      = XPS.VENDOR_ID
      AND  ABAU.VENDOR_SITE_ID = XPS.VENDOR_SITE_ID
      AND  ABAU.PRIMARY_FLAG  = 'Y'
      AND  TRUNC(SYSDATE) BETWEEN NVL(ABAU.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                              AND NVL(ABAU.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
      AND  ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID
      AND  TRUNC(SYSDATE) < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
      AND  ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID
      AND  TRUNC(SYSDATE) < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
    ;
--
    --支払方法取得
    CURSOR xx03_pay_group_method_cur
    IS
    SELECT FLV.ATTRIBUTE1 PAYMETHOD
    FROM   FND_LOOKUP_VALUES  FLV
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  FLV.LOOKUP_TYPE = 'PAY GROUP'
      AND  FLV.LANGUAGE = USERENV('LANG')
      AND  FLV.ENABLED_FLAG = 'Y'
      AND  FLV.LOOKUP_CODE = XPS.PAY_GROUP_LOOKUP_CODE
      AND  TRUNC(SYSDATE) BETWEEN NVL(FLV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                              AND NVL(FLV.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
    -- ver 11.5.10.2.10E Chg End
--
    -- ver 11.5.10.2.10F Chg Start
    ----通貨チェック
    --CURSOR xx03_currency_name_cur
    --IS
    --SELECT COUNT(1) exist_check
    --FROM   FND_CURRENCIES     FC
    --      ,XX03_PAYMENT_SLIPS XPS
    --WHERE  XPS.INVOICE_ID   = in_invoice_id
    --  AND  FC.ENABLED_FLAG  = 'Y'
    --  AND  FC.CURRENCY_FLAG = 'Y'
    --  AND  FC.CURRENCY_CODE = XPS.INVOICE_CURRENCY_CODE
    --  -- ver 11.5.10.2.6 Chg Start
    --  --AND  XPS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --  --                          AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  AND  TRUNC(SYSDATE) BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                          AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  -- ver 11.5.10.2.6 Chg End
    --
    --通貨チェック(精度チェック用に精度を取得するように変更)
    CURSOR xx03_currency_name_cur
    IS
    SELECT FC.CURRENCY_CODE      CURRENCY_CODE
          ,NVL(FC.PRECISION , 0) PRECISION
    FROM   FND_CURRENCIES     FC
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID   = in_invoice_id
      AND  FC.ENABLED_FLAG  = 'Y'
      AND  FC.CURRENCY_FLAG = 'Y'
      AND  FC.CURRENCY_CODE = XPS.INVOICE_CURRENCY_CODE
      AND  TRUNC(SYSDATE) BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                              AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    -- ver 11.5.10.2.10F Chg End
--
    --支払グループチェック
    CURSOR xx03_pay_group_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   FND_LOOKUP_VALUES  FLV
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID = in_invoice_id
      AND  FLV.LOOKUP_TYPE = 'PAY GROUP'
      AND  FLV.LANGUAGE = USERENV('LANG')
      AND  FLV.ENABLED_FLAG = 'Y'
      AND  FLV.LOOKUP_CODE = XPS.PAY_GROUP_LOOKUP_CODE
      -- ver 11.5.10.2.6 Chg Start
      --AND  XPS.INVOICE_DATE BETWEEN FLV.START_DATE_ACTIVE
      --                          AND NVL(FLV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
-- ver 11.5.10.2.10B Chg Start
--      AND  TRUNC(SYSDATE) BETWEEN FLV.START_DATE_ACTIVE
--                              AND NVL(FLV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) BETWEEN NVL(FLV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                              AND NVL(FLV.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
-- ver 11.5.10.2.10B Chg End
      -- ver 11.5.10.2.6 Chg End
--
    --支払条件チェック
    CURSOR xx03_terms_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   AP_TERMS           AT
          ,XX03_PAYMENT_SLIPS XPS
    WHERE  XPS.INVOICE_ID  = in_invoice_id
      AND  AT.ENABLED_FLAG = 'Y'
      AND  AT.TERM_ID = XPS.TERMS_ID
      -- ver 11.5.10.2.6 Chg Start
      --AND  XPS.INVOICE_DATE BETWEEN AT.START_DATE_ACTIVE
      --                          AND NVL(AT.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  NVL(AT.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD')) <= TRUNC(SYSDATE)
      AND  TRUNC(SYSDATE) < NVL(AT.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.6 Chg End
--
    --適用コードチェック
    CURSOR xx03_slip_line_type_name_cur(
      in_line_number  IN number,    -- 1.明細番号
      id_invoice_date IN DATE       -- 2.請求書日付
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_LOOKUPS_XX03_V     XLXV
          ,XX03_PAYMENT_SLIP_LINES XPSL
    WHERE  XPSL.INVOICE_ID   = in_invoice_id
      AND  XPSL.LINE_NUMBER  = in_line_number
      AND  XLXV.LANGUAGE     = USERENV('LANG')
      AND  XLXV.LOOKUP_TYPE  = 'XX03_SLIP_LINE_TYPES'
      AND  XLXV.ATTRIBUTE15  = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  XLXV.ENABLED_FLAG = 'Y'
      AND  XLXV.LOOKUP_CODE = XPSL.SLIP_LINE_TYPE
-- ver 11.5.10.2.10 Chg Start
--      AND  id_invoice_date BETWEEN XLXV.START_DATE_ACTIVE
--                           AND NVL(XLXV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  id_invoice_date BETWEEN NVL(XLXV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                               AND NVL(XLXV.END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'));
-- ver 11.5.10.2.10 Chg Start
--
    --税金コードチェック
    CURSOR xx03_tax_col_cur(
      in_line_number  IN number,    -- 1.明細番号
      id_invoice_date IN DATE       -- 2.請求書日付
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_TAX_CODES_LOV_V    XTCL
          ,XX03_PAYMENT_SLIP_LINES XPSL
    WHERE  XPSL.INVOICE_ID  = in_invoice_id
      AND  XPSL.LINE_NUMBER  = in_line_number
      AND  XTCL.NAME = XPSL.TAX_CODE
      AND  id_invoice_date BETWEEN NVL(XTCL.START_DATE   , TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                          AND NVL(XTCL.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'));
--
--2006/02/15 Ver11.5.10.1.6C add End
--2012/02/15 Ver11.5.10.2.11 ADD START
--
    --税金コード変更チェック
    CURSOR xx03_tax_chenge_cur(
      in_line_number  IN number,    -- 1.明細番号
      id_invoice_date IN DATE       -- 2.請求書日付
    ) IS
    SELECT xlxv.attribute10                            line_type_tax_code       -- 摘要コード税コード
          ,xlxv.attribute10 || '-' || atca.description line_type_tax_name       -- 摘要コード税名
          ,xpsl.tax_code                               input_tax_code           -- 入力した税コード
    FROM   xx03_lookups_xx03_v     xlxv
          ,xx03_payment_slip_lines xpsl
          ,ap_tax_codes_all        atca
    WHERE  xpsl.invoice_id   = in_invoice_id
      AND  xpsl.line_number  = in_line_number
      AND  xlxv.language     = USERENV('LANG')
      AND  xlxv.lookup_type  = 'XX03_SLIP_LINE_TYPES'
      AND  xlxv.attribute15  = xx00_profile_pkg.value('ORG_ID')
      AND  xlxv.enabled_flag = 'Y'
      AND  xlxv.lookup_code  = xpsl.slip_line_type
      AND  xlxv.attribute10  = atca.name(+)
      AND  id_invoice_date BETWEEN NVL(xlxv.start_date_active, TO_DATE('1000/01/01','YYYY/MM/DD'))
                               AND NVL(xlxv.end_date_active  , TO_DATE('4712/12/31','YYYY/MM/DD'));
--
--2012/02/15 Ver11.5.10.2.11 ADD END
--
    -- 共通エラーチェック結果取得カーソル
    CURSOR xx03_errchk_result_cur
    IS
      SELECT xei.journal_id as journal_id,
             xei.line_number as line_number,
             xei.error_code as error_code,
             xei.error_message as error_message,
             xei.status as status
        FROM xx03_error_info xei
       WHERE xei. check_id = ln_check_seq
-- ver11.5.10.1.6B Add Start
       ORDER BY xei.line_number;
-- ver11.5.10.1.6B Add End
--
    -- *** ローカル・レコード ***
    -- 処理対象データ取得カーソルレコード型
    xx03_xpsjlv_rec            xx03_xpsjlv_cur%ROWTYPE;
    -- レートカーソルレコード型
    xx03_rate_rec              xx03_rate_cur%ROWTYPE;
-- ver1.5 ADD START
    -- 前払充当伝票番号取得カーソルレコード型
    xx03_prepay_get_rec        xx03_prepay_get_cur%ROWTYPE;
    -- 前払充当伝票番号正当性チェックカーソルレコード型
    xx03_prepay_check_rec      xx03_prepay_check_cur%ROWTYPE;
-- ver1.5 ADD END
    -- 前払充当伝票番号チェックカーソルレコード型
    xx03_prepay_num_rec        xx03_prepay_num_cur%ROWTYPE;
    -- 修正元伝票番号チェックカーソルレコード型
    xx03_orig_num_rec          xx03_orig_num_cur%ROWTYPE;
    -- AP会計期間チェックカーソルレコード型
    xx03_ap_period_status_rec  xx03_ap_period_status_cur%ROWTYPE;
    -- GL会計期間チェックカーソルレコード型
    xx03_gl_period_status_rec  xx03_gl_period_status_cur%ROWTYPE;
    -- 共通エラーチェック結果取得レコード型
    xx03_errchk_result_rec     xx03_errchk_result_cur%ROWTYPE;
    -- ver 11.5.10.2.2 Add Start
    -- 申請者-承認者 チェックカーソルレコード型
    xx03_req_app_rec             xx03_req_app_cur%ROWTYPE;
    -- ver 11.5.10.2.2 Add End
-- 2006/02/15 Ver11.5.10.1.6C Add START
    --承認者チェックカーソルレコード型
    xx03_approver_rec            xx03_approver_cur%ROWTYPE;
    --仕入先IDチェックカーソルレコード型
    xx03_vendor_rec              xx03_vendor_cur%ROWTYPE;
    --仕入先サイトチェックカーソルレコード型
    xx03_vendor_site_rec         xx03_vendor_site_cur%ROWTYPE;
    --振込先口座チェックカーソルレコード型
    xx03_bank_name_rec           xx03_bank_name_cur%ROWTYPE;
--
    -- ver 11.5.10.2.10E Add Start
    --支払方法取得カーソルレコード型
    xx03_pay_group_method_rec    xx03_pay_group_method_cur%ROWTYPE;
    -- ver 11.5.10.2.10E Add End
--
    --通貨チェックカーソルレコード型
    xx03_currency_name_rec       xx03_currency_name_cur%ROWTYPE;
    --支払グループチェックカーソルレコード型
    xx03_pay_group_name_rec      xx03_pay_group_name_cur%ROWTYPE;
    --支払条件チェックカーソルレコード型
    xx03_terms_name_rec          xx03_terms_name_cur%ROWTYPE;
    --適用コードチェックカーソルレコード型
    xx03_slip_line_type_name_rec xx03_slip_line_type_name_cur%ROWTYPE;
    --税金コードチェックカーソルレコード型
    xx03_tax_col_rec             xx03_tax_col_cur%ROWTYPE;
-- 2006/02/15 Ver11.5.10.1.6C Add END
-- 2012/02/15 Ver11.5.10.2.11 ADD START
    -- 税金コード変更チェックカーソルレコード型
    xx03_tax_chenge_rec          xx03_tax_chenge_cur%ROWTYPE;
-- 2012/02/15 Ver11.5.10.2.11 ADD END
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- OUTパラメータ初期化
    FOR ln_cnt IN 0..19 LOOP
      errflg_tbl(ln_cnt) := 'S';
      errmsg_tbl(ln_cnt) := '';
    END LOOP;
--
    -- 帳簿ID取得
    ln_books_id := xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
--
    -- 処理対象データ取得カーソルオープン
    OPEN xx03_xpsjlv_cur;
    <<xx03_xpsjlv_loop>>
    LOOP
      FETCH xx03_xpsjlv_cur INTO xx03_xpsjlv_rec;
      IF xx03_xpsjlv_cur%NOTFOUND THEN
        IF ( lv_first_flg = 'Y' ) THEN
          -- 1件もデータがない場合
          RAISE NO_DATA_FOUND;
        ELSE
          -- データ終了
          EXIT xx03_xpsjlv_loop;
        END IF;
      END IF;
--
      -- 1件目に対してはエラーチェック実行
      IF ( lv_first_flg = 'Y' ) THEN
        -- 機能通貨コード取得
        SELECT gsob.currency_code as currency_code
          INTO lv_currency_code
          FROM gl_sets_of_books gsob
         WHERE gsob.set_of_books_id = ln_books_id;
--
        -- チェック用データ取得
-- Ver11.5.10.1.5 2005/09/02 Change Start
--        SELECT xpsv.invoice_currency_code as invoice_currency_code,
--               xpsv.exchange_rate as exchange_rate,
--               xpsv.exchange_rate_type as exchange_rate_type,
--               xpsv.gl_date as gl_date,
--               xpsv.prepay_num as prepay_num,
--               xpsv. orig_invoice_num as orig_invoice_num
--          INTO lv_chk_currency_code,
--               ln_chk_exchange_rate,
--               lv_chk_exchange_rate_type,
--               ld_chk_gl_date,
--               lv_chk_prepay_num,
--               lv_chk_orig_invoice_num
--          FROM xx03_payment_slips_v xpsv
--         WHERE xpsv.invoice_id = in_invoice_id;
        SELECT XPS.INVOICE_CURRENCY_CODE  as invoice_currency_code,
               XPS.EXCHANGE_RATE          as exchange_rate,
               XPS.EXCHANGE_RATE_TYPE     as exchange_rate_type,
               XPS.GL_DATE                as gl_date,
        --2006/02/18 Ver11.5.10.1.6C Add START
               XPS.INVOICE_DATE           as invoice_date,
        --2006/02/18 Ver11.5.10.1.6C Add END
               XPS.PREPAY_NUM             as prepay_num,
               XPS.ORIG_INVOICE_NUM       as orig_invoice_num
        --2006/03/06 Ver11.5.10.1.6E add start
             , XPS.WF_STATUS
        --2006/03/06 Ver11.5.10.1.6E add End
        INTO   lv_chk_currency_code,
               ln_chk_exchange_rate,
               lv_chk_exchange_rate_type,
               ld_chk_gl_date,
        --2006/02/18 Ver11.5.10.1.6C Add START
               ld_chk_invoice_date,
        --2006/02/18 Ver11.5.10.1.6C Add END
               lv_chk_prepay_num,
               lv_chk_orig_invoice_num
        --2006/03/06 Ver11.5.10.1.6E add start
             , ld_wf_status
        --2006/03/06 Ver11.5.10.1.6E add End
        FROM   XX03_PAYMENT_SLIPS XPS 
        WHERE  XPS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
          AND  XPS.INVOICE_ID = in_invoice_id
        ;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
        -- レートチェック
        IF ( lv_currency_code = lv_chk_currency_code ) THEN
          IF ( ln_chk_exchange_rate IS NOT NULL
               OR  lv_chk_exchange_rate_type IS NOT NULL ) THEN
            -- 通貨コードが機能通貨で、且つレートかレートタイプに入力値あり
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14001');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        ELSE
          IF ( ln_chk_exchange_rate IS NULL ) THEN
            -- 通貨コードが機能通貨でなく、且つレートに入力値なし
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14002');
            ln_err_cnt := ln_err_cnt + 1;
          ELSIF ( lv_chk_exchange_rate_type IS NULL ) THEN
            -- 通貨コードが機能通貨でなく、且つレートタイプに入力値なし
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14003');
            ln_err_cnt := ln_err_cnt + 1;
          ELSIF ( lv_chk_exchange_rate_type != 'User' ) THEN
            -- 通貨コードが機能通貨でなく、且つレート、レートタイプ共に入力値あり、
            -- 且つレートタイプが'User'
            OPEN xx03_rate_cur(
              lv_chk_currency_code,       -- 1.通貨コード
              lv_chk_exchange_rate_type,  -- 2.レートタイプ
              ld_chk_gl_date              -- 3.GL記帳日
            );
            FETCH xx03_rate_cur INTO xx03_rate_rec;
            IF xx03_rate_cur%NOTFOUND THEN
              -- レコードが選択されなかった
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14004');
              ln_err_cnt := ln_err_cnt + 1;
            ELSE
              IF ( xx03_rate_rec.conversion_rate != ln_chk_exchange_rate ) THEN
                -- レートの値が異なる
                errflg_tbl(ln_err_cnt) := 'E';
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14004');
                ln_err_cnt := ln_err_cnt + 1;
              END IF;
            END IF;
            CLOSE xx03_rate_cur;
          ELSE
            -- 通貨コードが機能通貨でなく、且つレート、レートタイプ共に入力値あり、
            -- 且つレートタイプが'User'以外の場合は特に処理はなし
            NULL;
          END IF;
        END IF;
--
-- ver1.5 ADD START
        -- 前払充当伝票番号チェック
        OPEN xx03_prepay_get_cur();
        FETCH xx03_prepay_get_cur INTO xx03_prepay_get_rec;
        IF (xx03_prepay_get_rec.prepay_num IS NULL) THEN
          -- 前払伝票指定なし
          -- 特に処理なし
          NULL;
        ELSE
          -- 前払伝票指定あり
          OPEN xx03_prepay_check_cur();
          FETCH xx03_prepay_check_cur INTO xx03_prepay_check_rec;
          IF xx03_prepay_check_cur%NOTFOUND THEN
            -- レコードが選択されなかった
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14057');
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            -- レコードが選択された
            -- 特に処理なし
            NULL;
          END IF;
          CLOSE xx03_prepay_check_cur;
        END IF;
        CLOSE xx03_prepay_get_cur;
-- ver1.5 ADD END
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- 前払充当伝票番号入力時のみチェックする
      IF lv_chk_prepay_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- 前払充当伝票番号チェック
        OPEN xx03_prepay_num_cur(
          lv_chk_prepay_num  -- 1.前払充当伝票番号
        );
        FETCH xx03_prepay_num_cur INTO xx03_prepay_num_rec;
        IF xx03_prepay_num_cur%NOTFOUND THEN
          -- レコードが選択されなかった
          -- 特に処理なし
          NULL;
        ELSE
          -- レコードが選択された
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14005');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_prepay_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- 修正元伝票番号入力時のみチェックする
      IF lv_chk_orig_invoice_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- 修正元伝票番号チェック
        OPEN xx03_orig_num_cur(
          lv_chk_orig_invoice_num  -- 1.修正元伝票番号
        );
        FETCH xx03_orig_num_cur INTO xx03_orig_num_rec;
        IF xx03_orig_num_cur%NOTFOUND THEN
          -- レコードが選択されなかった
          -- 特に処理なし
          NULL;
        ELSE
          -- レコードが選択された
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14149');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_orig_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
        -- AP会計期間チェック
        OPEN xx03_ap_period_status_cur(
          ln_books_id,    -- 1.修正元伝票番号
          ld_chk_gl_date  -- 2.GL記帳日
        );
        FETCH xx03_ap_period_status_cur INTO xx03_ap_period_status_rec;
        IF xx03_ap_period_status_cur%NOTFOUND THEN
-- 2004/02/19 ADD START
          -- 会計期間データなし
          lv_period_data_flg := 'N';
-- 2004/02/19 ADD END
          -- AP会計期間未定義エラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14009');
          ln_err_cnt := ln_err_cnt + 1;
        ELSE
-- 2004/02/19 ADD START
          -- 会計期間データあり
          lv_period_data_flg := 'Y';
-- 2004/02/19 ADD END
          IF ( xx03_ap_period_status_rec.closing_status != 'O' AND
                 xx03_ap_period_status_rec.closing_status != 'F' ) THEN
            -- AP会計期間未オープンエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14010');
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            -- 'O'、'F'の時は特に処理なし
            NULL;
          END IF;
        END IF;
        CLOSE xx03_ap_period_status_cur;
--
-- 2004/02/19 ADD START
        -- 会計期間データありの時のみ
        IF ( lv_period_data_flg = 'Y' ) THEN
          -- GL会計期間チェック
          OPEN xx03_gl_period_status_cur(
            ln_books_id,    -- 1.修正元伝票番号
            ld_chk_gl_date  -- 2.GL記帳日
          );
          FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
          IF xx03_gl_period_status_cur%NOTFOUND THEN
            -- GL会計期間未定義エラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14013');
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            IF ( xx03_gl_period_status_rec.attribute1 IS NOT NULL AND
                   xx03_gl_period_status_rec.attribute1 != 'O' ) THEN
              -- GL会計期間未オープンエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
            ELSE
              -- 'O'、Nullの時は特に処理なし
              NULL;
            END IF;
          END IF;
          CLOSE xx03_gl_period_status_cur;
        END IF;
-- 2004/02/19 ADD END
--
        -- ver 11.5.10.2.2 Add Start
        -- ver 11.5.10.2.2B Chg Start
        ---- 申請者-承認者チェック(WF_STATUSが｢保存｣｢承認待ち｣｢最終承認待ち｣の時、実施)
        --IF (   ld_wf_status = cn_wf_status_save
        --    OR ld_wf_status = cn_wf_status_dept
        --    OR ld_wf_status = cn_wf_status_last ) THEN
        -- 申請者-承認者チェック(WF_STATUSが｢承認待ち｣｢最終承認待ち｣の時、実施)
        IF (   ld_wf_status = cn_wf_status_dept
            OR ld_wf_status = cn_wf_status_last ) THEN
        -- ver 11.5.10.2.2B Chg End
          OPEN xx03_req_app_cur;
          FETCH xx03_req_app_cur INTO xx03_req_app_rec;
          IF xx03_req_app_rec.exist_check = 0 THEN
            -- 承認者チェックエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14160','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_req_app_cur;
        END IF;
        -- ver 11.5.10.2.2 Add End
--
-- 2006/02/15 Ver11.5.10.1.6C Add START
-- ヘッダーのマスターチェック実施
        --2006/03/06 Ver11.5.10.1.6E Change Start
        --承認者チェック(WF_STATUSが部門入力待ち状態のときのみ実施)
        IF ld_wf_status = cn_wf_status_dept THEN
          OPEN xx03_approver_cur;
          FETCH xx03_approver_cur INTO xx03_approver_rec;
          IF xx03_approver_rec.exist_check = 0 THEN
            -- 承認者チェックエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14154','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_approver_cur;
        END IF;
        --2006/03/06 Ver11.5.10.1.6E Change End
--
        --仕入先IDチェック
        OPEN xx03_vendor_cur;
        FETCH xx03_vendor_cur INTO xx03_vendor_rec;
        IF xx03_vendor_rec.exist_check = 0 THEN
          -- 仕入先IDチェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12504','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_vendor_cur;
--
        --仕入先サイトチェック
        OPEN xx03_vendor_site_cur;
        FETCH xx03_vendor_site_cur INTO xx03_vendor_site_rec;
        IF xx03_vendor_site_rec.exist_check = 0 THEN
          -- 仕入先サイトチェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12505','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_vendor_site_cur;
--
        -- ver 11.5.10.2.10E Del Start
        ----振込先口座チェック
        --OPEN xx03_bank_name_cur;
        --FETCH xx03_bank_name_cur INTO xx03_bank_name_rec;
        ---- ver 11.5.10.2.5 Chg Start
        ----IF xx03_bank_name_rec.exist_check = 0 THEN
        ----  -- 振込先口座チェックエラー
        ----  errflg_tbl(ln_err_cnt) := 'E';
        ----  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12509','SLIP_NUM','');
        ----  ln_err_cnt := ln_err_cnt + 1;
        ----END IF;
        --
        ---- 振込先口座取得エラー
        --IF xx03_bank_name_cur%NOTFOUND THEN
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12509','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        ---- 振込先口座チェックエラー(電信の場合のみ振込先口座必須)
        --ELSIF xx03_bank_name_rec.PAYMETHOD = cv_vendor_sites_eft
        --    and xx03_bank_name_rec.NAME is NULL THEN
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12509','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        --END IF;
        ---- ver 11.5.10.2.5 Chg End
        --CLOSE xx03_bank_name_cur;
        ---- ver 11.5.10.2.10E Del End
--
        -- ver 11.5.10.2.10F Chg Start
        ----通貨チェック
        --OPEN xx03_currency_name_cur;
        --FETCH xx03_currency_name_cur INTO xx03_currency_name_rec;
        --IF xx03_currency_name_rec.exist_check = 0 THEN
        --  -- 通貨チェックエラー
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        --END IF;
        --CLOSE xx03_currency_name_cur;
        --
        --通貨チェック(精度チェック用に精度を取得するように変更)
        OPEN xx03_currency_name_cur;
        FETCH xx03_currency_name_cur INTO xx03_currency_name_rec;
        IF (xx03_currency_name_cur%NOTFOUND) THEN
          -- 通貨チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
--
          lb_currency_chk := FALSE;
          ln_currency_precision := 0;
        ELSE
          lb_currency_chk := TRUE;
          ln_currency_precision := xx03_currency_name_rec.PRECISION;
        END IF;
        CLOSE xx03_currency_name_cur;
        -- ver 11.5.10.2.10F Chg End
--
        --支払グループチェック
        OPEN xx03_pay_group_name_cur;
        FETCH xx03_pay_group_name_cur INTO xx03_pay_group_name_rec;
        IF xx03_pay_group_name_rec.exist_check = 0 THEN
          -- 支払グループチェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12506','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_pay_group_name_cur;
--
        -- ver 11.5.10.2.10E Add Start
        -- 支払方法取得
        OPEN xx03_pay_group_method_cur;
        FETCH xx03_pay_group_method_cur INTO xx03_pay_group_method_rec;
--
        -- 支払グループから支払方法が取得できた場合は振込先口座チェック
        IF xx03_pay_group_method_cur%FOUND THEN
          -- 振込先口座チェックエラー(電信の場合のみ振込先口座必須)
          IF xx03_pay_group_method_rec.PAYMETHOD = cv_vendor_sites_eft THEN
            -- 振込先口座取得チェック
            OPEN xx03_bank_name_cur;
            FETCH xx03_bank_name_cur INTO xx03_bank_name_rec;
            IF xx03_bank_name_cur%NOTFOUND THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12516','SLIP_NUM','');
              ln_err_cnt := ln_err_cnt + 1;
            ELSIF xx03_bank_name_rec.NAME IS NULL THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12516','SLIP_NUM','');
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            CLOSE xx03_bank_name_cur;
          END IF;
        END IF;
        CLOSE xx03_pay_group_method_cur;
        -- ver 11.5.10.2.10E Add End
--
        --支払条件チェック
        OPEN xx03_terms_name_cur;
        FETCH xx03_terms_name_cur INTO xx03_terms_name_rec;
        IF xx03_terms_name_rec.exist_check = 0 THEN
          -- 支払条件チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12507','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_terms_name_cur;
--
-- 2006/02/15 Ver11.5.10.1.6C Add END
--
        -- 部門入力エラーチェックでエラーがなかった場合のみチェックID取得
        IF ( ln_err_cnt <= 0 ) THEN
          --チェックID取得
          SELECT xx03_err_check_s.NEXTVAL
          INTO   ln_check_seq
          FROM   DUAL;
        END IF;
--
        -- 1件目フラグをおろす
        lv_first_flg := 'N';
      END IF;
--
-- 2005/01/17 Add start
      -- フレックス・フィールド体系番号の取得
      SELECT   sob.chart_of_accounts_id
        INTO   ln_structure_number
        FROM   gl_sets_of_books sob
       WHERE   xx00_profile_pkg.VALUE('GL_SET_OF_BKS_ID')
                 = sob.set_of_books_id;
--
      -- 相互検証ルールチェック実行(対象 : ヘッダー以外)
      IF (xx03_xpsjlv_rec.segment1 IS NOT NULL) THEN
        lv_segment_array(1) := xx03_xpsjlv_rec.segment1;
        lv_segment_array(2) := xx03_xpsjlv_rec.segment2;
        lv_segment_array(3) := xx03_xpsjlv_rec.segment3;
        lv_segment_array(4) := xx03_xpsjlv_rec.segment4;
        lv_segment_array(5) := xx03_xpsjlv_rec.segment5;
        lv_segment_array(6) := xx03_xpsjlv_rec.segment6;
        lv_segment_array(7) := xx03_xpsjlv_rec.segment7;
        lv_segment_array(8) := xx03_xpsjlv_rec.segment8;
--
        lb_retcode := FND_FLEX_EXT.GET_COMBINATION_ID(
                        application_short_name => lv_app_short_name,
                        key_flex_code => lv_key_flex_code,
                        structure_number => ln_structure_number,
        -- 2006/01/30 Ver11.5.10.1.6 Change Start
                        --validation_date => ld_validation_date,
                        validation_date => ld_chk_gl_date,
        -- 2006/01/30 Ver11.5.10.1.6 Change End
                        n_segments => ln_segments,
                        segments => lv_segment_array,
                        combination_id => on_combination_id,
                        data_set => ld_data_set
        );
--
        IF lb_retcode THEN
          NULL;
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := FND_FLEX_EXT.GET_MESSAGE;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
--
      END IF; -- xx03_xpsjlv_rec.segment1 IS NOT NULL
-- 2005/05/17 Add end
--
-- 2006/02/15 Ver11.5.10.1.6C add START
-- 明細のマスター値チェックを実施する
      --適用コードチェック
      --明細行のみチェックする
      IF xx03_xpsjlv_rec.line_type_lookup_code = 'ITEM' THEN
        OPEN xx03_slip_line_type_name_cur(
          xx03_xpsjlv_rec.line_number,    -- 1.明細番号
          ld_chk_invoice_date             -- 2.請求書日付
        );
        FETCH xx03_slip_line_type_name_cur INTO xx03_slip_line_type_name_rec;
        IF xx03_slip_line_type_name_rec.exist_check = 0 THEN
          -- 適用コードエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-12508','SLIP_NUM','','TOK_COUNT',xx03_xpsjlv_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_slip_line_type_name_cur;
--
      -- 税金コードチェック
         OPEN xx03_tax_col_cur(
          xx03_xpsjlv_rec.line_number,    -- 1.明細番号
          ld_chk_invoice_date             -- 2.請求書日付
        );
        FETCH xx03_tax_col_cur INTO xx03_tax_col_rec;
        IF xx03_tax_col_rec.exist_check = 0 THEN
          -- 税金コードエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14151','SLIP_NUM','','TOK_COUNT',xx03_xpsjlv_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_tax_col_cur;
-- 2012/02/15 Ver11.5.10.2.11 ADD START
--
         -- 税金コード変更チェック
         OPEN xx03_tax_chenge_cur(
          xx03_xpsjlv_rec.line_number,    -- 1.明細番号
          ld_chk_invoice_date             -- 2.請求書日付
        );
        FETCH xx03_tax_chenge_cur INTO xx03_tax_chenge_rec;
        --
        -- 摘要コードの税コードがNULLならばチェックしない
        IF xx03_tax_chenge_rec.line_type_tax_code IS NOT NULL THEN
          -- 摘要コードの税コードと明細の税コードが不一致の場合
          IF ( xx03_tax_chenge_rec.line_type_tax_code <> xx03_tax_chenge_rec.input_tax_code ) THEN
            -- 税金コード変更エラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO'    ,'APP-XXCFO1-00041'
                                                              ,'SLIP_NUM' ,''
                                                              ,'TOK_COUNT',xx03_xpsjlv_rec.line_number
                                                              ,'TAX_CODE' ,xx03_tax_chenge_rec.line_type_tax_name
                                                              );
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        CLOSE xx03_tax_chenge_cur;
--
-- 2012/02/15 Ver11.5.10.2.11 ADD END
--
        -- ver 11.5.10.2.10F Add Start
        -- 通貨が正しく入力されている場合はチェック
        IF lb_currency_chk = TRUE THEN
          -- 伝票金額の精度を取得
          lv_amount := TO_CHAR(xx03_xpsjlv_rec.amount);
          IF INSTR(lv_amount ,cv_precision_char) = 0 THEN
            ln_amount_precision := 0;
          ELSE
            ln_amount_precision := LENGTH(lv_amount) - INSTR(TO_CHAR(lv_amount) ,cv_precision_char);
          END IF;
--
          -- 伝票金額の精度が通貨の精度を超えていればエラー
          IF ln_currency_precision < ln_amount_precision THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03','APP-XX03-14167','SLIP_NUM','','TOK_COUNT',xx03_xpsjlv_rec.line_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        -- ver 11.5.10.2.10F Add End
      END IF;
--
-- 2006/02/15 Ver11.5.10.1.6C add END
--
      -- 部門入力エラーチェックでエラーがあった場合はその時点でループ終了
      IF ( ln_err_cnt > 0 ) THEN
        -- データ終了
        EXIT xx03_xpsjlv_loop;
      END IF;
--
      -- エラーチェックテーブル書き込み
      IF ( xx03_xpsjlv_rec.line_number = 0 ) THEN
        -- ヘッダレコード
        INSERT INTO xx03_error_checks(
          CHECK_ID,
          JOURNAL_ID,
          LINE_NUMBER,
          GL_DATE,
          PERIOD_NAME,
          CURRENCY_CODE,
          CODE_COMBINATION_ID,
          SEGMENT1,
          SEGMENT2,
          SEGMENT3,
          SEGMENT4,
          SEGMENT5,
          SEGMENT6,
          SEGMENT7,
          SEGMENT8,
          TAX_CODE,
          INCR_DECR_REASON_CODE,
          SLIP_NUMBER,
          INPUT_DEPARTMENT,
          INPUT_USER,
          ORIG_SLIP_NUMBER,
          RECON_REFERENCE,
          ENTERED_DR,
          ENTERED_CR,
          ATTRIBUTE_CATEGORY,
          ATTRIBUTE1,
          ATTRIBUTE2,
          ATTRIBUTE3,
          ATTRIBUTE4,
          ATTRIBUTE5,
          ATTRIBUTE6,
          ATTRIBUTE7,
          ATTRIBUTE8,
          ATTRIBUTE9,
          ATTRIBUTE10,
          ATTRIBUTE11,
          ATTRIBUTE12,
          ATTRIBUTE13,
          ATTRIBUTE14,
          ATTRIBUTE15,
          ATTRIBUTE16,
          ATTRIBUTE17,
          ATTRIBUTE18,
          ATTRIBUTE19,
          ATTRIBUTE20,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN,
          REQUEST_ID,
          PROGRAM_APPLICATION_ID,
          PROGRAM_UPDATE_DATE,
          PROGRAM_ID
        ) VALUES (
          ln_check_seq,
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.line_number,
          xx03_xpsjlv_rec.gl_date,
          null,
          xx03_xpsjlv_rec.invoice_currency_code,
          xx03_xpsjlv_rec.code_combination_id,
          xx03_xpsjlv_rec.segment1,
          xx03_xpsjlv_rec.segment2,
          xx03_xpsjlv_rec.segment3,
          xx03_xpsjlv_rec.segment4,
          xx03_xpsjlv_rec.segment5,
          xx03_xpsjlv_rec.segment6,
          xx03_xpsjlv_rec.segment7,
          xx03_xpsjlv_rec.segment8,
          null,
          null,
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.entry_department,
          xx03_xpsjlv_rec.user_name,
          null,
          null,
          null,
          xx03_xpsjlv_rec.amount,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          xx00_global_pkg.user_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.user_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.login_id,
          xx00_global_pkg.conc_request_id,
          xx00_global_pkg.prog_appl_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.conc_program_id
        );
      ELSE
        -- 明細(税金)レコード
        INSERT INTO xx03_error_checks(
          CHECK_ID,
          JOURNAL_ID,
          LINE_NUMBER,
          GL_DATE,
          PERIOD_NAME,
          CURRENCY_CODE,
          CODE_COMBINATION_ID,
          SEGMENT1,
          SEGMENT2,
          SEGMENT3,
          SEGMENT4,
          SEGMENT5,
          SEGMENT6,
          SEGMENT7,
          SEGMENT8,
          TAX_CODE,
          INCR_DECR_REASON_CODE,
          SLIP_NUMBER,
          INPUT_DEPARTMENT,
          INPUT_USER,
          ORIG_SLIP_NUMBER,
          RECON_REFERENCE,
          ENTERED_DR,
          ENTERED_CR,
          ATTRIBUTE_CATEGORY,
          ATTRIBUTE1,
          ATTRIBUTE2,
          ATTRIBUTE3,
          ATTRIBUTE4,
          ATTRIBUTE5,
          ATTRIBUTE6,
          ATTRIBUTE7,
          ATTRIBUTE8,
          ATTRIBUTE9,
          ATTRIBUTE10,
          ATTRIBUTE11,
          ATTRIBUTE12,
          ATTRIBUTE13,
          ATTRIBUTE14,
          ATTRIBUTE15,
          ATTRIBUTE16,
          ATTRIBUTE17,
          ATTRIBUTE18,
          ATTRIBUTE19,
          ATTRIBUTE20,
          CREATED_BY,
          CREATION_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATE_LOGIN,
          REQUEST_ID,
          PROGRAM_APPLICATION_ID,
          PROGRAM_UPDATE_DATE,
          PROGRAM_ID
        ) VALUES (
          ln_check_seq,
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.line_number,
          xx03_xpsjlv_rec.gl_date,
          null,
          xx03_xpsjlv_rec.invoice_currency_code,
          xx03_xpsjlv_rec.code_combination_id,
          xx03_xpsjlv_rec.segment1,
          xx03_xpsjlv_rec.segment2,
          xx03_xpsjlv_rec.segment3,
          xx03_xpsjlv_rec.segment4,
          xx03_xpsjlv_rec.segment5,
          xx03_xpsjlv_rec.segment6,
          xx03_xpsjlv_rec.segment7,
          xx03_xpsjlv_rec.segment8,
          xx03_xpsjlv_rec.tax_code,
          xx03_xpsjlv_rec.incr_decr_reason_code,
          xx03_xpsjlv_rec.invoice_num,
          xx03_xpsjlv_rec.entry_department,
          xx03_xpsjlv_rec.user_name,
          null,
          xx03_xpsjlv_rec.recon_reference,
          xx03_xpsjlv_rec.amount,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          null,
          xx00_global_pkg.user_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.user_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.login_id,
          xx00_global_pkg.conc_request_id,
          xx00_global_pkg.prog_appl_id,
          xx00_date_pkg.get_system_datetime_f,
          xx00_global_pkg.conc_program_id
        );
      END IF;
    END LOOP xx03_xpsjlv_loop;
    CLOSE xx03_xpsjlv_cur;
--
    -- 部門入力エラーチェックでエラーがなかった場合のみ共通エラーチェック実行
    IF ( ln_err_cnt <= 0 ) THEN
      -- 共通エラーチェック処理実行
      lv_err_status := xx03_je_error_check_pkg.je_error_check(ln_check_seq);
--
      IF (lv_err_status != 'S' ) THEN
        -- 共通エラーチェック結果取得
        OPEN xx03_errchk_result_cur;
        <<xx03_errchk_result_loop>>
        LOOP
          FETCH xx03_errchk_result_cur INTO xx03_errchk_result_rec;
          IF xx03_errchk_result_cur%NOTFOUND THEN
            EXIT xx03_errchk_result_loop;
          END IF;
--
          -- 取得したエラー情報を順にエラー情報配列にセット
          IF ( ln_err_cnt <= 19 ) THEN
            -- エラー件数が20件以下の時のみエラー情報セット
            errflg_tbl(ln_err_cnt) := xx03_errchk_result_rec.status;
-- ver 11.5.10.2.10C Chg Start
--            errmsg_tbl(ln_err_cnt) := TRUNC(xx03_errchk_result_rec.line_number) || '：' ||
--                                           xx03_errchk_result_rec.error_message;
            if xx03_errchk_result_rec.line_number = 0 THEN
              lv_je_err_msg := 'APP-XX03-14164';
            elsif (xx03_errchk_result_rec.line_number - TRUNC(xx03_errchk_result_rec.line_number)) = 0.5 THEN
              lv_je_err_msg := 'APP-XX03-14166';
            else
              lv_je_err_msg := 'APP-XX03-14165';
            end if;
            errmsg_tbl(ln_err_cnt) := TRUNC(xx03_errchk_result_rec.line_number) || '：' ||
                                           xx03_errchk_result_rec.error_message ||
                                           xx00_message_pkg.get_msg('XX03',lv_je_err_msg);
-- ver 11.5.10.2.10C Chg End
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
--
        END LOOP xx03_errchk_result_loop;
        CLOSE xx03_errchk_result_cur;
      END IF;
--
-- ver 11.5.10.1.6D Del Start
      ---- エラーチェック、エラー情報データ削除
      --DELETE FROM xx03_error_checks xec
      --      WHERE xec.check_id = ln_check_seq;
      --DELETE FROM xx03_error_info xei
      --      WHERE xei.check_id = ln_check_seq;
-- ver 11.5.10.1.6D Del End
    END IF;
--
-- ver 11.5.10.1.6D Add Start
    IF ln_check_seq != 0 THEN
      -- エラーチェック、エラー情報データ削除
      DELETE FROM xx03_error_checks xec WHERE xec.check_id = ln_check_seq;
      DELETE FROM xx03_error_info xei   WHERE xei.check_id = ln_check_seq;
    END IF;
-- ver 11.5.10.1.6D Add End
--
    -- OUTパラメータ設定
    ov_error_flg := 'S';
    FOR ln_cnt IN 0..19 LOOP
      IF ( ov_error_flg = 'S' AND errflg_tbl(ln_cnt) != 'S' ) THEN
        -- 正常 → 警告orエラー
        ov_error_flg := errflg_tbl(ln_cnt);
      ELSIF ( ov_error_flg = 'W' AND errflg_tbl(ln_cnt) = 'E' ) THEN
        -- 警告 → エラー
        ov_error_flg := errflg_tbl(ln_cnt);
      END IF;
--
      IF ( ov_error_flg = 'E') THEN
        -- ステータスがエラーになった時点でループは抜ける
        EXIT;
      END IF;
    END LOOP;
--
    on_error_cnt := ln_err_cnt;
    ov_error_flg1 := errflg_tbl(0);
    ov_error_msg1 := errmsg_tbl(0);
    ov_error_flg2 := errflg_tbl(1);
    ov_error_msg2 := errmsg_tbl(1);
    ov_error_flg3 := errflg_tbl(2);
    ov_error_msg3 := errmsg_tbl(2);
    ov_error_flg4 := errflg_tbl(3);
    ov_error_msg4 := errmsg_tbl(3);
    ov_error_flg5 := errflg_tbl(4);
    ov_error_msg5 := errmsg_tbl(4);
    ov_error_flg6 := errflg_tbl(5);
    ov_error_msg6 := errmsg_tbl(5);
    ov_error_flg7 := errflg_tbl(6);
    ov_error_msg7 := errmsg_tbl(6);
    ov_error_flg8 := errflg_tbl(7);
    ov_error_msg8 := errmsg_tbl(7);
    ov_error_flg9 := errflg_tbl(8);
    ov_error_msg9 := errmsg_tbl(8);
    ov_error_flg10 := errflg_tbl(9);
    ov_error_msg10 := errmsg_tbl(9);
    ov_error_flg11 := errflg_tbl(10);
    ov_error_msg11 := errmsg_tbl(10);
    ov_error_flg12 := errflg_tbl(11);
    ov_error_msg12 := errmsg_tbl(11);
    ov_error_flg13 := errflg_tbl(12);
    ov_error_msg13 := errmsg_tbl(12);
    ov_error_flg14 := errflg_tbl(13);
    ov_error_msg14 := errmsg_tbl(13);
    ov_error_flg15 := errflg_tbl(14);
    ov_error_msg15 := errmsg_tbl(14);
    ov_error_flg16 := errflg_tbl(15);
    ov_error_msg16 := errmsg_tbl(15);
    ov_error_flg17 := errflg_tbl(16);
    ov_error_msg17 := errmsg_tbl(16);
    ov_error_flg18 := errflg_tbl(17);
    ov_error_msg18 := errmsg_tbl(17);
    ov_error_flg19 := errflg_tbl(18);
    ov_error_msg19 := errmsg_tbl(18);
    ov_error_flg20 := errflg_tbl(19);
    ov_error_msg20 := errmsg_tbl(19);
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                --*** 対象データなし ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
      -- ver 11.5.10.2.3 Add Start
      -- OUTパラメータ設定
      ov_error_flg := 'E';
      on_error_cnt := 1;
      ov_error_flg1 := xx00_common_pkg.set_status_error_f;
      ov_error_msg1 := lv_errmsg;
      -- ver 11.5.10.2.3 Add Start
--
      -- カーソルクローズ
      IF xx03_xpsjlv_cur%ISOPEN THEN
        CLOSE xx03_xpsjlv_cur;
      END IF;
      IF xx03_rate_cur%ISOPEN THEN
        CLOSE xx03_rate_cur;
      END IF;
-- ver1.5 ADD START
      IF xx03_prepay_get_cur%ISOPEN THEN
        CLOSE xx03_prepay_get_cur;
      END IF;
      IF xx03_prepay_check_cur%ISOPEN THEN
        CLOSE xx03_prepay_check_cur;
      END IF;
-- ver1.5 ADD END
      IF xx03_prepay_num_cur%ISOPEN THEN
        CLOSE xx03_prepay_num_cur;
      END IF;
      IF xx03_orig_num_cur%ISOPEN THEN
        CLOSE xx03_orig_num_cur;
      END IF;
      IF xx03_ap_period_status_cur%ISOPEN THEN
        CLOSE xx03_ap_period_status_cur;
      END IF;
      IF xx03_gl_period_status_cur%ISOPEN THEN
        CLOSE xx03_gl_period_status_cur;
      END IF;
      IF xx03_errchk_result_cur%ISOPEN THEN
        CLOSE xx03_errchk_result_cur;
      END IF;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_deptinput_ap;
--
  /**********************************************************************************
   * Procedure Name   : set_account_approval_flag
   * Description      : 重点管理チェック
   ***********************************************************************************/
  PROCEDURE set_account_approval_flag(
    in_invoice_id IN  NUMBER,    -- 1.チェック対象請求書ID
    ov_app_upd    OUT VARCHAR2,  -- 2.重点管理更新内容
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.set_account_approval_flag'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ###############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_head_acc_amount NUMBER;  -- ヘッダ換算額
    lv_slip_type VARCHAR2(25);  -- ヘッダ伝票種別
    lv_detail_first_flg VARCHAR2(1);  -- 配分読込1件目フラグ
--
    -- *** ローカル・カーソル ***
    -- 伝票種別マスタ情報取得カーソル
    CURSOR xx03_slip_type_cur(
      iv_slip_type   IN  VARCHAR2  -- 1.伝票種別
    ) IS
      SELECT xst.attribute1 as attribute1,
             xst.attribute2 as attribute2
        FROM xx03_slip_types_v xst
       WHERE xst.lookup_code = iv_slip_type;
--
    -- 請求書配分情報取得カーソル
    CURSOR xx03_detail_info_cur
    IS
      SELECT xav.attribute7 as attribute7
        FROM xx03_payment_slip_lines xpsl,
             xx03_accounts_v xav
       WHERE xpsl.invoice_id = in_invoice_id
         AND xpsl.segment3 = xav.flex_value;
--
    -- *** ローカル・レコード ***
    -- 伝票種別マスタ情報取得カーソルレコード型
    xx03_slip_type_rec       xx03_slip_type_cur%ROWTYPE;
    -- 請求書配分情報取得カーソルレコード型
    xx03_detail_info_rec     xx03_detail_info_cur%ROWTYPE;
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 戻り値初期化
    ov_app_upd := 'N';
--
    -- 請求書ヘッダレコード取得
-- Ver1.6 Update Start
--    SELECT ABS(xps.inv_accounted_amount) as inv_accounted_amount,
    SELECT ABS(
             ROUND((xps.inv_item_amount + xps.inv_tax_amount) * NVL(xps.exchange_rate, 1))
           ) as inv_accounted_amount,
-- Ver1.6 Update End
           xps.slip_type as slip_type
      INTO ln_head_acc_amount,
           lv_slip_type
      FROM xx03_payment_slips xps
     WHERE xps.invoice_id = in_invoice_id;
--
    -- 伝票種別マスタ情報取得
    OPEN xx03_slip_type_cur(lv_slip_type);
    FETCH xx03_slip_type_cur INTO xx03_slip_type_rec;
    IF xx03_slip_type_cur%NOTFOUND THEN
      RAISE NO_DATA_FOUND;
    ELSE
      IF ( xx03_slip_type_rec.attribute1 = 'Y' ) THEN
        -- attribute1が'Y'だった場合は、ov_app_updに'Y'をセットしてRETURN
        ov_app_upd := 'Y';
        CLOSE xx03_slip_type_cur;
        RETURN;
      ELSE
        IF ( ln_head_acc_amount >= xx03_slip_type_rec.attribute2 ) THEN
          -- attribute1が'N'で、且つinv_accounted_amount>=attribute2だった場合は、
          -- ov_app_updに'Y'をセットし、RETURN
          ov_app_upd := 'Y';
          CLOSE xx03_slip_type_cur;
          RETURN;
        END IF;
      END IF;
    END IF;
    CLOSE xx03_slip_type_cur;
--
    -- 請求書配分レコード取得
    lv_detail_first_flg := 'Y';
    OPEN xx03_detail_info_cur;
    <<xx03_detail_info_loop>>
    LOOP
      FETCH xx03_detail_info_cur INTO xx03_detail_info_rec;
      IF xx03_detail_info_cur%NOTFOUND THEN
        IF ( lv_detail_first_flg = 'Y' ) THEN
          -- 1件もなかった場合はエラー
          RAISE NO_DATA_FOUND;
        ELSE
          EXIT xx03_detail_info_loop;
        END IF;
      END IF;
      IF ( lv_detail_first_flg = 'Y' ) THEN
        lv_detail_first_flg := 'N';
      END IF;
--
      IF ( xx03_detail_info_rec.attribute7 = 'Y' ) THEN
        -- attribute7が'Y'のレコードがあれば、ov_app_updに'Y'をセットしてRETURN
        ov_app_upd := 'Y';
        CLOSE xx03_detail_info_cur;
        RETURN;
      END IF;
--
    END LOOP xx03_detail_info_loop;
    CLOSE xx03_detail_info_cur;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                --*** 対象データなし ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
      -- カーソルクローズ
      IF xx03_slip_type_cur%ISOPEN THEN
        CLOSE xx03_slip_type_cur;
      END IF;
      IF xx03_detail_info_cur%ISOPEN THEN
        CLOSE xx03_detail_info_cur;
      END IF;
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END set_account_approval_flag;
--
  /**********************************************************************************
   * Procedure Name   : get_terms_date
   * Description      : 支払起算日の算出
   ***********************************************************************************/
  PROCEDURE get_terms_date(
    in_terms_id   IN  NUMBER,    -- 1.支払条件
    id_start_date IN  DATE,      -- 2.支払起算日
    id_terms_date IN  DATE,      -- 3.支払予定日
    od_terms_date OUT DATE,      -- 4.支払予定日
    ov_terms_flg  OUT VARCHAR2,  -- 5.変更可能フラグ
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.get_terms_date'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ###############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_sequence_num NUMBER;     -- シーケンス
    lv_calendar VARCHAR2(30);   -- 特別カレンダー
--
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    -- 変更可能フラグ取得
    SELECT at.attribute1
      INTO ov_terms_flg
      FROM ap_terms_v at
     WHERE at.term_id = in_terms_id;
--
   -- 変更可能フラグ'Y'で、id_terms_dateになんらかの値が入っていた場合は
   -- id_terms_dateの値をod_terms_dateにセットしてRETURN
   IF ( ov_terms_flg = 'Y' AND id_terms_date IS NOT NULL ) THEN
     od_terms_date := id_terms_date;
     RETURN;
   END IF;
--
   -- AP期間情報取得
   SELECT atl.sequence_num as sequence_num,
          atl.calendar as calendar
     INTO ln_sequence_num,
          lv_calendar
     FROM ap_terms_lines atl
    WHERE atl.term_id = in_terms_id
      AND rownum = 1
   ORDER BY atl.sequence_num;
--
  IF ( lv_calendar IS NOT NULL ) THEN
    -- 特別カレンダーが指定されていた場合は、特別カレンダーから支払予定日を取得
    BEGIN
      SELECT aop.due_date
        INTO od_terms_date
        FROM ap_other_periods aop
       WHERE aop.period_type = lv_calendar
         AND aop.module = 'PAYMENT TERMS'
         AND trunc(id_start_date) between aop.start_date and aop.end_date;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN                --*** 対象データなし ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14008');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14008');
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
    END;
  ELSE
    -- 特別カレンダーが指定されていなかった場合は、ロジックで支払予定日を取得
-- Var1.3 CHANGE START
    SELECT NVL(ATL.FIXED_DATE,
             (DECODE(ATL.DUE_DAYS,
             NULL, TO_DATE(TO_CHAR(ADD_MONTHS(id_start_date,
                 NVL(ATL.DUE_MONTHS_FORWARD, 0) +
                   DECODE(AT.DUE_CUTOFF_DAY, NULL, 0,
              DECODE(GREATEST(LEAST(NVL(AT.DUE_CUTOFF_DAY, 32),
                 TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
                 TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
                    TO_NUMBER(TO_CHAR(id_start_date, 'DD')), 1, 0))),
                       'RRRR/MM') || '/' ||
              TO_CHAR(LEAST(NVL(ATL.DUE_DAY_OF_MONTH, 32),
               TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_start_date,
                 NVL(ATL.DUE_MONTHS_FORWARD, 0) +
               DECODE(AT.DUE_CUTOFF_DAY, NULL, 0,
               DECODE(GREATEST(LEAST(NVL(AT.DUE_CUTOFF_DAY, 32),
                 TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
                 TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
                 TO_NUMBER(TO_CHAR(id_start_date, 'DD'))
                 , 1, 0)))), 'DD'))))
              -- ver 11.5.10.2.10G Chg Start
              --),
              ,'yyyy/mm/dd'),
              -- ver 11.5.10.2.10G Chg End
              id_start_date + NVL(ATL.DUE_DAYS, 0))))
-- Var1.3 CHANGE END
      INTO od_terms_date
      FROM AP_TERMS_V AT,
           AP_TERMS_LINES ATL
     WHERE AT.TERM_ID = in_terms_id
       AND AT.TERM_ID = ATL.TERM_ID
       AND ATL.SEQUENCE_NUM = ln_sequence_num;
  END IF;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN                --*** 対象データなし ***
      lv_errmsg := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      lv_errbuf := xx00_message_pkg.get_msg(
        'XX03',
        'APP-XX03-14007');
      ov_errmsg := lv_errmsg;                                                           --# 任意 #
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                 --# 任意 #
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END get_terms_date;
--
-- Var1.4 ADD START
  /**********************************************************************************
   * Procedure Name   : del_pay_data
   * Description      : 支払伝票レコードの削除
   ***********************************************************************************/
  PROCEDURE del_pay_data(
    in_invoice_id IN  NUMBER,    -- 1.削除対象請求書ID
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --自律トランザクション化
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ap_check_pkg.del_pay_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ###############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- 2005-01-22 ADD START (v1.8)
    cn_wf_status_save CONSTANT xx03_payment_slips.wf_status%TYPE   := '00';
    cn_delete_yes     CONSTANT xx03_payment_slips.delete_flag%TYPE := 'Y';
    -- 2005-01-22 ADD END
--
    -- *** ローカル変数 ***
--
    -- 2005-01-22 ADD START(v.18)
    lv_wf_status        xx03_payment_slips.wf_status%TYPE;
    -- 2005-01-22 ADD END
    -- *** ローカル・カーソル ***
--
    -- *** ローカル・レコード ***
--
    -- ===============================
    -- ユーザー定義例外
    -- ===============================
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
--
    -- 2005-01-22 ADD START(v.18)
    -- WFステータスを取得
    SELECT xps.wf_status
    INTO   lv_wf_status
    FROM   xx03_payment_slips xps
    WHERE  xps.invoice_id = in_invoice_id;
    -- 2005-01-22 ADD END
--
    -- 2005-01-22 ADD START(v.18)
    -- 保存伝票は物理削除を行う
    IF lv_wf_status = cn_wf_status_save THEN
    -- 2005-01-22 ADD END
--
      -- 支払伝票明細レコード削除
      DELETE FROM xx03_payment_slip_lines xpsl
      WHERE xpsl.invoice_id = in_invoice_id;
--
      -- 支払伝票ヘッダレコード削除
      DELETE FROM xx03_payment_slips xps
      WHERE xps.invoice_id = in_invoice_id;
--
    -- 2005-01-22 ADD START(v.18)
    -- 保存以外の場合は論理削除を行う
    ELSE
        -- 仕訳伝票ヘッダレコード更新
        UPDATE xx03_payment_slips
        SET    delete_flag = cn_delete_yes
        WHERE  invoice_id = in_invoice_id;
    END IF;
    -- 2005-01-22 ADD END
--
    -- コミット発行
    COMMIT;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ROLLBACK;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
  END del_pay_data;
-- Var1.4 ADD END
--
-- ver11.5.10.1.6B Add Start
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ap_input
   * Description      : 部門入力(AP)のエラーチェック(画面用)
   ***********************************************************************************/
  PROCEDURE check_deptinput_ap_input(
    in_invoice_id    IN   NUMBER,    -- 1.チェック対象請求書ID
    on_error_cnt     OUT  NUMBER,    -- 2.処理全体でのエラーフラグ
    ov_error_flg     OUT  VARCHAR2,  -- 3.処理全体でのエラーフラグ
    ov_error_flg1    OUT  VARCHAR2,  -- 4.1個目のRETURNデータのエラーフラグ
    ov_error_msg1    OUT  VARCHAR2,  -- 5.1個目のRETURNデータのエラー内容
    ov_error_flg2    OUT  VARCHAR2,  -- 6.2個目のRETURNデータのエラーフラグ
    ov_error_msg2    OUT  VARCHAR2,  -- 7.2個目のRETURNデータのエラー内容
    ov_error_flg3    OUT  VARCHAR2,  -- 8.3個目のRETURNデータのエラーフラグ
    ov_error_msg3    OUT  VARCHAR2,  -- 9.3個目のRETURNデータのエラー内容
    ov_error_flg4    OUT  VARCHAR2,  -- 10.4個目のRETURNデータのエラーフラグ
    ov_error_msg4    OUT  VARCHAR2,  -- 11.4個目のRETURNデータのエラー内容
    ov_error_flg5    OUT  VARCHAR2,  -- 12.5個目のRETURNデータのエラーフラグ
    ov_error_msg5    OUT  VARCHAR2,  -- 13.5個目のRETURNデータのエラー内容
    ov_error_flg6    OUT  VARCHAR2,  -- 14.6個目のRETURNデータのエラーフラグ
    ov_error_msg6    OUT  VARCHAR2,  -- 15.6個目のRETURNデータのエラー内容
    ov_error_flg7    OUT  VARCHAR2,  -- 16.7個目のRETURNデータのエラーフラグ
    ov_error_msg7    OUT  VARCHAR2,  -- 17.7個目のRETURNデータのエラー内容
    ov_error_flg8    OUT  VARCHAR2,  -- 18.8個目のRETURNデータのエラーフラグ
    ov_error_msg8    OUT  VARCHAR2,  -- 19.8個目のRETURNデータのエラー内容
    ov_error_flg9    OUT  VARCHAR2,  -- 20.9個目のRETURNデータのエラーフラグ
    ov_error_msg9    OUT  VARCHAR2,  -- 21.9個目のRETURNデータのエラー内容
    ov_error_flg10   OUT  VARCHAR2,  -- 22.10個目のRETURNデータのエラーフラグ
    ov_error_msg10   OUT  VARCHAR2,  -- 23.10個目のRETURNデータのエラー内容
    ov_error_flg11   OUT  VARCHAR2,  -- 24.11個目のRETURNデータのエラーフラグ
    ov_error_msg11   OUT  VARCHAR2,  -- 25.11個目のRETURNデータのエラー内容
    ov_error_flg12   OUT  VARCHAR2,  -- 26.12個目のRETURNデータのエラーフラグ
    ov_error_msg12   OUT  VARCHAR2,  -- 27.12個目のRETURNデータのエラー内容
    ov_error_flg13   OUT  VARCHAR2,  -- 28.13個目のRETURNデータのエラーフラグ
    ov_error_msg13   OUT  VARCHAR2,  -- 29.13個目のRETURNデータのエラー内容
    ov_error_flg14   OUT  VARCHAR2,  -- 30.14個目のRETURNデータのエラーフラグ
    ov_error_msg14   OUT  VARCHAR2,  -- 31.14個目のRETURNデータのエラー内容
    ov_error_flg15   OUT  VARCHAR2,  -- 32.15個目のRETURNデータのエラーフラグ
    ov_error_msg15   OUT  VARCHAR2,  -- 33.15個目のRETURNデータのエラー内容
    ov_error_flg16   OUT  VARCHAR2,  -- 34.16個目のRETURNデータのエラーフラグ
    ov_error_msg16   OUT  VARCHAR2,  -- 35.16個目のRETURNデータのエラー内容
    ov_error_flg17   OUT  VARCHAR2,  -- 36.17個目のRETURNデータのエラーフラグ
    ov_error_msg17   OUT  VARCHAR2,  -- 37.17個目のRETURNデータのエラー内容
    ov_error_flg18   OUT  VARCHAR2,  -- 38.18個目のRETURNデータのエラーフラグ
    ov_error_msg18   OUT  VARCHAR2,  -- 39.18個目のRETURNデータのエラー内容
    ov_error_flg19   OUT  VARCHAR2,  -- 40.19個目のRETURNデータのエラーフラグ
    ov_error_msg19   OUT  VARCHAR2,  -- 41.19個目のRETURNデータのエラー内容
    ov_error_flg20   OUT  VARCHAR2,  -- 42.20個目のRETURNデータのエラーフラグ
    ov_error_msg20   OUT  VARCHAR2,  -- 43.20個目のRETURNデータのエラー内容
    ov_errbuf        OUT  VARCHAR2,  -- エラー・メッセージ           --# 固定 #
    ov_retcode       OUT  VARCHAR2,  -- リターン・コード             --# 固定 #
    ov_errmsg        OUT  VARCHAR2)  -- ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.check_deptinput_ar_input'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
--
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--################################  固定部 END   ###############################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ln_error_cnt NUMBER;            -- 仕訳チェックエラー件数
    lv_error_flg VARCHAR2(1);       -- 仕訳チェックエラーフラグ
    lv_error_flg1 VARCHAR2(1);      -- 仕訳チェックエラーフラグ1
    lv_error_msg1 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ1
    lv_error_flg2 VARCHAR2(1);      -- 仕訳チェックエラーフラグ2
    lv_error_msg2 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ2
    lv_error_flg3 VARCHAR2(1);      -- 仕訳チェックエラーフラグ3
    lv_error_msg3 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ3
    lv_error_flg4 VARCHAR2(1);      -- 仕訳チェックエラーフラグ4
    lv_error_msg4 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ4
    lv_error_flg5 VARCHAR2(1);      -- 仕訳チェックエラーフラグ5
    lv_error_msg5 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ5
    lv_error_flg6 VARCHAR2(1);      -- 仕訳チェックエラーフラグ6
    lv_error_msg6 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ6
    lv_error_flg7 VARCHAR2(1);      -- 仕訳チェックエラーフラグ7
    lv_error_msg7 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ7
    lv_error_flg8 VARCHAR2(1);      -- 仕訳チェックエラーフラグ8
    lv_error_msg8 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ8
    lv_error_flg9 VARCHAR2(1);      -- 仕訳チェックエラーフラグ9
    lv_error_msg9 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ9
    lv_error_flg10 VARCHAR2(1);     -- 仕訳チェックエラーフラグ10
    lv_error_msg10 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ10
    lv_error_flg11 VARCHAR2(1);     -- 仕訳チェックエラーフラグ11
    lv_error_msg11 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ11
    lv_error_flg12 VARCHAR2(1);     -- 仕訳チェックエラーフラグ12
    lv_error_msg12 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ12
    lv_error_flg13 VARCHAR2(1);     -- 仕訳チェックエラーフラグ13
    lv_error_msg13 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ13
    lv_error_flg14 VARCHAR2(1);     -- 仕訳チェックエラーフラグ14
    lv_error_msg14 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ14
    lv_error_flg15 VARCHAR2(1);     -- 仕訳チェックエラーフラグ15
    lv_error_msg15 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ15
    lv_error_flg16 VARCHAR2(1);     -- 仕訳チェックエラーフラグ16
    lv_error_msg16 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ16
    lv_error_flg17 VARCHAR2(1);     -- 仕訳チェックエラーフラグ17
    lv_error_msg17 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ17
    lv_error_flg18 VARCHAR2(1);     -- 仕訳チェックエラーフラグ18
    lv_error_msg18 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ18
    lv_error_flg19 VARCHAR2(1);     -- 仕訳チェックエラーフラグ19
    lv_error_msg19 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ19
    lv_error_flg20 VARCHAR2(1);     -- 仕訳チェックエラーフラグ20
    lv_error_msg20 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ20
    lv_error_msg   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ
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
    -- ***********************************************
    -- ***      共通関数処理ロジックの記述         ***
    -- ***********************************************
    --  仕訳チェック関数呼び出し
    xx03_deptinput_ap_check_pkg.check_deptinput_ap(
      in_invoice_id,
      ln_error_cnt,
      lv_error_flg,
      lv_error_flg1,
      lv_error_msg1,
      lv_error_flg2,
      lv_error_msg2,
      lv_error_flg3,
      lv_error_msg3,
      lv_error_flg4,
      lv_error_msg4,
      lv_error_flg5,
      lv_error_msg5,
      lv_error_flg6,
      lv_error_msg6,
      lv_error_flg7,
      lv_error_msg7,
      lv_error_flg8,
      lv_error_msg8,
      lv_error_flg9,
      lv_error_msg9,
      lv_error_flg10,
      lv_error_msg10,
      lv_error_flg11,
      lv_error_msg11,
      lv_error_flg12,
      lv_error_msg12,
      lv_error_flg13,
      lv_error_msg13,
      lv_error_flg14,
      lv_error_msg14,
      lv_error_flg15,
      lv_error_msg15,
      lv_error_flg16,
      lv_error_msg16,
      lv_error_flg17,
      lv_error_msg17,
      lv_error_flg18,
      lv_error_msg18,
      lv_error_flg19,
      lv_error_msg19,
      lv_error_flg20,
      lv_error_msg20,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
--
    -- 戻り値取得
    IF ( lv_error_flg = 'W' ) THEN
      -- 警告の場合は申請可能フラグに警告セット
      UPDATE xx03_payment_slips xps
      SET    xps.request_enable_flag = 'W'
      WHERE  xps.invoice_id = in_invoice_id;
    ELSE
      -- 警告以外の場合は申請可能フラグに'Y'セット
      UPDATE xx03_payment_slips xps
      SET    xps.request_enable_flag = 'Y'
      WHERE  xps.invoice_id = in_invoice_id;
    END IF;
--
    -- データ確定
    COMMIT;
--
    -- OUTパラメータセット
    on_error_cnt   := ln_error_cnt;
    ov_error_flg   := lv_error_flg;
    ov_error_flg1  := lv_error_flg1;
    ov_error_msg1  := lv_error_msg1;
    ov_error_flg2  := lv_error_flg2;
    ov_error_msg2  := lv_error_msg2;
    ov_error_flg3  := lv_error_flg3;
    ov_error_msg3  := lv_error_msg3;
    ov_error_flg4  := lv_error_flg4;
    ov_error_msg4  := lv_error_msg4;
    ov_error_flg5  := lv_error_flg5;
    ov_error_msg5  := lv_error_msg5;
    ov_error_flg6  := lv_error_flg6;
    ov_error_msg6  := lv_error_msg6;
    ov_error_flg7  := lv_error_flg7;
    ov_error_msg7  := lv_error_msg7;
    ov_error_flg8  := lv_error_flg8;
    ov_error_msg8  := lv_error_msg8;
    ov_error_flg9  := lv_error_flg9;
    ov_error_msg9  := lv_error_msg9;
    ov_error_flg10 := lv_error_flg10;
    ov_error_msg10 := lv_error_msg10;
    ov_error_flg11 := lv_error_flg11;
    ov_error_msg11 := lv_error_msg11;
    ov_error_flg12 := lv_error_flg12;
    ov_error_msg12 := lv_error_msg12;
    ov_error_flg13 := lv_error_flg13;
    ov_error_msg13 := lv_error_msg13;
    ov_error_flg14 := lv_error_flg14;
    ov_error_msg14 := lv_error_msg14;
    ov_error_flg15 := lv_error_flg15;
    ov_error_msg15 := lv_error_msg15;
    ov_error_flg16 := lv_error_flg16;
    ov_error_msg16 := lv_error_msg16;
    ov_error_flg17 := lv_error_flg17;
    ov_error_msg17 := lv_error_msg17;
    ov_error_flg18 := lv_error_flg18;
    ov_error_msg18 := lv_error_msg18;
    ov_error_flg19 := lv_error_flg19;
    ov_error_msg19 := lv_error_msg19;
    ov_error_flg20 := lv_error_flg20;
    ov_error_msg20 := lv_error_msg20;
    ov_errbuf      := lv_errbuf;
    ov_retcode     := lv_retcode;
    ov_errmsg      := lv_errmsg;
--
  EXCEPTION
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_deptinput_ap_input;
-- ver11.5.10.1.6B Add End
--
END xx03_deptinput_ap_check_pkg;
/
