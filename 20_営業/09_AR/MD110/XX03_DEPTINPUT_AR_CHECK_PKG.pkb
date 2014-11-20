create or replace PACKAGE BODY      xx03_deptinput_ar_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ar_check_pkg(body)
 * Description            : 部門入力(AR)において入力チェックを行う共通関数
 * MD.070                 : 部門入力(AR)共通関数 OCSJ/BFAFIN/MD070/F702
 * Version                : 11.5.10.2.10D
 *
 * Program List
 *  -------------------------- ---- ----- --------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- --------------------------------------------------
 *  check_deptinput_ar          P          部門入力(AR)のエラー（仕訳）チェック
 *  set_account_approval_flag   P          重点管理チェック
 *  get_terms_date              P          入金予定日の算出
 *  del_receivable_data         P          請求依頼伝票レコードの削除
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2005/01/25   1.0            新規作成
 *  2005/09/02   11.5.10.1.5    パフォーマンス改善対応
 *  2005/10/06   11.5.10.1.5B   顧客事業所に事業所レベルの勘定科目とプロファイルが
 *                              存在するかをチェックする処理を追加
 *  2005/10/18   11.5.10.1.5C   取消伝票を再度申請できてしまう不具合対応
 *  2005/11/04   11.5.10.1.6    入金予定日算出ロジックの不備を修正
 *  2005/11/04   11.5.10.1.6B   前受金の存在チェック不具合修正
 *  2006/01/30   11.5.10.1.6C   相互検証ルールのチェックで、日付をGL計上日を渡すよう変更
 *  2006/02/15   11.5.10.1.6D   ダブルクリック対応,PKGでcommitするPROCEDURE追加
 *  2006/02/15   11.5.10.1.6E   マスター存在チェックを実施するように変更
 *  2006/03/02   11.5.10.1.6F   エラーチェックテーブルのクリアロジックの不具合
 *  2006/03/03   11.5.10.1.6G   取消し伝票の場合伝票種別チェックを止める
 *  2006/03/03   11.5.10.1.6H   承認者の承認権限チェック不具合修正
 *  2006/03/29   11.5.10.2.1    HR対応（従業員履歴レコード対応）
 *  2006/04/07   11.5.10.2.2    承認者が対象伝票に対する承認権限があるかのチェック追加
 *  2006/04/12   11.5.10.2.2B   11.5.10.2.2での修正ミス対応
 *  2006/06/22   11.5.10.2.3    マスタチェック用SQLでデータが取得でなかった時の
 *                              エラー処理が誤っていることの修正
 *  2006/10/03   11.5.10.2.6    マスタチェックの見直し(有効日のチェックを請求書日付で
 *                              行なう項目とSYSDATEで行なう項目を再確認)
 *  2007/08/10   11.5.10.2.10   仕訳配分チェックでエラーの時のメッセージに
 *                              ヘッダ･明細･税金のどの配分かを表示するように修正
 *  2007/08/16   11.5.10.2.10B  銀行支店の無効日は前日まで有効とするように修正
 *  2007/08/28   11.5.10.2.10C  AR通貨有効日の比較対象は請求書日付とする修正
 *  2007/10/29   11.5.10.2.10D  通貨の精度チェック(入力可能精度か桁チェック)追加
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ar
   * Description      : 部門入力(AR)のエラーチェック
   ***********************************************************************************/
  PROCEDURE check_deptinput_ar(
    in_receivable_id IN   NUMBER,    -- 1.チェック対象請求書ID
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
      'xx03_deptinput_ar_check_pkg.check_deptinput_ar'; -- プログラム名
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
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;    -- エラーフラグ用配列タイプ
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    -- エラーメッセージ用配列タイプ
    errflg_tbl                errflg_tbl_type;
    errmsg_tbl                errmsg_tbl_type;
    ln_err_cnt                NUMBER := 0;         -- パラメータ添字用変数
    ln_books_id               NUMBER;              -- 帳簿ID
    lv_first_flg              VARCHAR2(1) := 'Y';  -- 1件目のレコードか否か
-- ver 11.5.10.1.6F Chg Start
    --ln_check_seq              NUMBER;              -- エラーチェックシーケンス番号
    ln_check_seq              NUMBER := 0;         -- エラーチェックシーケンス番号
-- ver 11.5.10.1.6F Chg End
    ln_cnt                    NUMBER;              -- ループカウンタ
    lv_err_status             VARCHAR2(1);         -- 共通エラーチェックステータス
    lv_currency_code          VARCHAR2(15);        -- 機能通貨コード
    lv_chk_currency_code      VARCHAR2(15);        -- チェック用データ通貨コード
    ln_chk_exchange_rate      NUMBER;              -- チェック用データ換算レート
    lv_chk_exchange_rate_type VARCHAR2(30);        -- チェック用データ換算レートタイプ
    ld_chk_gl_date            DATE;                -- チェック用データ計上日
    lv_chk_prerec_num         VARCHAR2(50);        -- チェック用データ前受充当伝票番号
    lv_chk_orig_invoice_num   VARCHAR2(150);       -- チェック用データ修正元伝票番号
    -- Ver11.5.10.1.5B 2005/10/06 Add Start
    ln_chk_customer_office_id NUMBER;              -- チェック用データ顧客事業所ID
    -- Ver11.5.10.1.5B 2005/10/06 Add End
    lv_period_data_flg        VARCHAR2(1);         -- 会計期間データ有無フラグ
    --2006/02/18 Ver11.5.10.1.6E Add START
    ld_chk_invoice_date       DATE;                -- チェック用データ請求書日付
    ld_chk_receipt_method_id  NUMBER;              -- チェック用データ支払方法
    ld_slip_line_uom          VARCHAR2(25);         -- チェック用データ単位
    --2006/02/18 Ver11.5.10.1.6E Add END
    -- 2006/03/06 Ver11.5.10.1.6H Add Start
    ld_wf_status              VARCHAR2(25);        -- チェック用ワークフローステータス
    cn_wf_status_dept   VARCHAR2(25) := '20';      -- 部門入力承認待ちステータス
    -- 2006/03/06 Ver11.5.10.1.6H Add End
--
    -- ver 11.5.10.2.2 Add Start
    cn_wf_status_save   VARCHAR2(25) := '00';      -- 部門入力保存ステータス
    cn_wf_status_last   VARCHAR2(25) := '30';      -- 部門入力最終部門承認待ちステータス
    -- ver 11.5.10.2.2 Add End
--
    -- ver 11.5.10.2.10 Add Start
    lv_je_err_msg       VARCHAR2(14);              -- 配分チェックエラー時の追加メッセージコード
    -- ver 11.5.10.2.10 Add End
--
    -- ver 11.5.10.2.10D Add Start
    lb_currency_chk        BOOLEAN      := FALSE;  -- 通貨エラーOK/NGフラグ(精度チェック時に使用)
    ln_currency_precision  NUMBER(1)    := 0;      -- 通貨の精度(通貨チェックOK時に精度を取得)
    lv_amount              VARCHAR2(50) := '';     -- 伝票での金額精度取得用
    ln_amount_precision    NUMBER(1)    := 0;      -- 伝票での金額の精度
    cv_precision_char      VARCHAR2(1)  := '.';    -- 小数点記号
    -- ver 11.5.10.2.10D Add End
--
    -- *** ローカル・カーソル ***
    -- 処理対象データ取得カーソル
    CURSOR xx03_xrsjlv_cur
    IS
      SELECT xrsjlv.receivable_num        as receivable_num             -- 伝票番号
           , xrsjlv.line_number           as line_number                -- No
           , xrsjlv.gl_date               as gl_date                    -- 計上日
           , xrsjlv.invoice_currency_code as invoice_currency_code      -- 通貨コード
           , xrsjlv.code_combination_id   as code_combination_id        -- コードコンビネーションID
           , xrsjlv.segment1              as segment1                   --
           , xrsjlv.segment2              as segment2                   --
           , xrsjlv.segment3              as segment3                   --
           , xrsjlv.segment4              as segment4                   --
           , xrsjlv.segment5              as segment5                   --
           , xrsjlv.segment6              as segment6                   --
           , xrsjlv.segment7              as segment7                   --
           , xrsjlv.segment8              as segment8                   --
           , xrsjlv.tax_code              as tax_code                   -- 税区分ID
           , xrsjlv.incr_decr_reason_code as incr_decr_reason_code      -- 増減事由コード
           , xrsjlv.entry_department      as entry_department           -- 起票部門
           , xrsjlv.user_name             as user_name                  -- ユーザー名
           , xrsjlv.recon_reference       as recon_reference            -- 消込参照
           , xrsjlv.amount                as amount                     -- 金額
      --2006/02/16 Ver11.5.10.1.6E add START
           , xrsjlv.line_type_lookup_code as line_type_lookup_code      -- ルックアップコード
      --2006/02/16 Ver11.5.10.1.6E add END
        FROM XX03_REC_SLIP_JOURNAL_LINES_V   xrsjlv
       WHERE xrsjlv.RECEIVABLE_ID = in_receivable_id                    -- 伝票ID
       ORDER BY xrsjlv.line_number;
--
    -- レートカーソル
    CURSOR xx03_rate_cur(
      iv_invoice_currency_code IN VARCHAR2,                             -- 1.通貨コード
      iv_exchange_rate_type    IN VARCHAR2,                             -- 2.レートタイプ
      id_gl_date               IN DATE                                  -- 3.GL記帳日
    ) IS
      SELECT xgdr.conversion_rate as conversion_rate                    -- レート
        FROM xx03_gl_daily_rates_v   xgdr
       WHERE xgdr.from_currency   = iv_invoice_currency_code            -- 通貨コード
         AND xgdr.conversion_type = iv_exchange_rate_type               -- レートタイプ
         AND xgdr.conversion_date = TRUNC(id_gl_date);                  -- 換算日
--
    -- 前受充当伝票番号取得チェックカーソル
    CURSOR xx03_prerec_get_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xrsv.COMMITMENT_NUMBER as COMMITMENT_NUMBER                -- 前受充当伝票番号
--        FROM XX03_RECEIVABLE_SLIPS_V xrsv
--       WHERE xrsv.RECEIVABLE_ID = RECEIVABLE_ID;                        -- 伝票ID
      SELECT xrs.COMMITMENT_NUMBER as COMMITMENT_NUMBER                 -- 前受充当伝票番号
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.RECEIVABLE_ID = in_receivable_id;                      -- 伝票ID
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- 前受充当伝票番号正当性チェックカーソル
    CURSOR xx03_prerec_check_cur
    IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT xrsv.RECEIVABLE_ID                                         -- 伝票ID
--        FROM XX03_RECEIVABLE_SLIPS_V      xrsv,
--             XX03_COMMITMENT_NUMBER_LOV_V xcnlv
--       WHERE xrsv.RECEIVABLE_ID         = in_receivable_id              -- 伝票ID
--         AND xrsv.COMMITMENT_NUMBER     = xcnlv.TRX_NUMBER              -- 前受充当伝票番号
--         AND xrsv.CUSTOMER_ID           = xcnlv.CUSTOMER_NUMBER         -- 顧客ID
--         AND xrsv.INVOICE_CURRENCY_CODE = xcnlv.CURRENCY;               -- 通貨コード
      SELECT xrs.RECEIVABLE_ID                                          -- 伝票ID
        FROM XX03_RECEIVABLE_SLIPS        xrs,
             XX03_COMMITMENT_NUMBER_LOV_V xcnlv
       WHERE xrs.RECEIVABLE_ID         = in_receivable_id               -- 伝票ID
         AND xrs.COMMITMENT_NUMBER     = xcnlv.TRX_NUMBER               -- 前受充当伝票番号
-- Ver11.5.10.1.6B Chg Start
--         AND xrs.CUSTOMER_ID           = xcnlv.CUSTOMER_NUMBER          -- 顧客ID
         AND xrs.CUSTOMER_ID           = xcnlv.CUST_ACCOUNT_ID          -- 顧客ID
-- Ver11.5.10.1.6B Chg End
         AND xrs.INVOICE_CURRENCY_CODE = xcnlv.CURRENCY;                -- 通貨コード
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- 前受充当伝票番号チェックカーソル
    CURSOR xx03_prerec_num_cur(
      iv_prerec_num IN VARCHAR2 -- 1.前受充当伝票番号
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM XX03_RECEIVABLE_SLIPS_V xrsv
--       WHERE xrsv.AR_FORWARD_DATE   IS NULL                              -- AR転送日
--         AND xrsv.COMMITMENT_NUMBER =  iv_prerec_num                     -- 前受充当伝票番号
--         AND xrsv.wf_status         >= 20                                -- WFステータス
--         AND xrsv.RECEIVABLE_ID     != in_receivable_id;                 -- 伝票ID
      SELECT *
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.AR_FORWARD_DATE   IS NULL                              -- AR転送日
         AND xrs.COMMITMENT_NUMBER =  iv_prerec_num                     -- 前受充当伝票番号
         AND xrs.wf_status         >= 20                                -- WFステータス
         AND xrs.RECEIVABLE_ID     != in_receivable_id                  -- 伝票ID
         AND xrs.org_id            =  XX00_PROFILE_PKG.VALUE('ORG_ID');
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- 修正元伝票番号チェックカーソル
    CURSOR xx03_orig_num_cur(
      iv_orig_invoice_num  IN VARCHAR2 -- 1.修正元伝票番号
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM XX03_RECEIVABLE_SLIPS_V xrsv
--       WHERE xrsv.AR_FORWARD_DATE  IS NULL
--         AND xrsv.orig_invoice_num =  iv_orig_invoice_num               -- 修正元伝票番号
--         AND xrsv.wf_status        >= 20                                -- WFステータス
--         AND xrsv.RECEIVABLE_ID    != in_receivable_id;                 -- 伝票ID
      -- Ver11.5.10.1.5C 2005/10/18 Change Start
      --SELECT *
      --  FROM XX03_RECEIVABLE_SLIPS xrs
      -- WHERE xrs.AR_FORWARD_DATE  IS NULL
      --   AND xrs.orig_invoice_num =  iv_orig_invoice_num                -- 修正元伝票番号
      --   AND xrs.wf_status        >= 20                                 -- WFステータス
      --   AND xrs.RECEIVABLE_ID    != in_receivable_id                   -- 伝票ID
      --   AND xrs.org_id            =  XX00_PROFILE_PKG.VALUE('ORG_ID');
      SELECT *
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.orig_invoice_num =  iv_orig_invoice_num                -- 修正元伝票番号
         AND xrs.wf_status        >= 20                                 -- WFステータス
         AND xrs.RECEIVABLE_ID    != in_receivable_id                   -- 伝票ID
         AND xrs.org_id            =  XX00_PROFILE_PKG.VALUE('ORG_ID');
      -- Ver11.5.10.1.5C 2005/10/18 Change End
-- Ver11.5.10.1.5 2005/09/02 Change End
--
    -- AR会計期間チェックカーソル
    CURSOR xx03_ar_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.帳簿ID
      id_gl_date    IN DATE       -- 2.GL記帳日
    ) IS
      SELECT gps.closing_status as closing_status
        FROM gl_period_statuses gps
       WHERE gps.application_id         =  xx03_application_pkg.get_application_id_f('AR')
         AND gps.set_of_books_id        =  in_books_id
         AND gps.start_date             <= TRUNC(id_gl_date)
         AND gps.end_date               >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag =  'N';
--
    -- GL会計期間チェックカーソル
    CURSOR xx03_gl_period_status_cur(
      in_books_id   IN NUMBER,    -- 1.帳簿ID
      id_gl_date    IN DATE       -- 2.GL記帳日
    ) IS
      SELECT gps.attribute4 as attribute4
        FROM gl_period_statuses gps
       WHERE gps.application_id         = xx03_application_pkg.get_application_id_f('SQLGL')
         AND gps.set_of_books_id        =  in_books_id
         AND gps.start_date             <= TRUNC(id_gl_date)
         AND gps.end_date               >= TRUNC(id_gl_date)
         AND gps.adjustment_period_flag =  'N';
--
    -- Ver11.5.10.1.5B 2005/10/06 Add Start
    -- 顧客事業所の請求先サイトレベルの勘定科目存在チェックカーソル
    CURSOR xx03_site_accounts_cur(
      ln_chk_customer_office_id   IN NUMBER    -- 1.顧客事業所ID
    ) IS
      SELECT hsuv.gl_id_rec
        FROM hz_cust_site_uses_all hsuv,
             gl_code_combinations gcc
       WHERE hsuv.gl_id_rec             = gcc.code_combination_id
         AND hsuv.cust_acct_site_id     = ln_chk_customer_office_id
         AND hsuv.status                = 'A'
         AND hsuv.site_use_code         = 'BILL_TO';
--
    -- 顧客事業所の顧客所在地レベルのプロファイル存在チェックカーソル
    CURSOR xx03_site_profile_cur(
      ln_chk_customer_office_id   IN NUMBER    -- 1.顧客事業所ID
    ) IS
      SELECT hsuv.site_use_id
        FROM hz_cust_site_uses_all hsuv,
             ar_customer_profiles_v acpv
       WHERE hsuv.site_use_id           = acpv.site_use_id
         AND hsuv.cust_acct_site_id     = ln_chk_customer_office_id
         AND hsuv.status                = 'A'
         AND hsuv.site_use_code         = 'BILL_TO';
    -- Ver11.5.10.1.5B 2005/10/06 Add End
--
-- ver 11.5.10.2.2 add Start
    -- 申請者と承認者の関係 チェックカーソル
    CURSOR xx03_req_app_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_APPROVER_PERSON_V      XAPV
          ,XX03_RECEIVABLE_SLIPS       XRS
          ,XX03_DEPARTMENTS_V          XDV
          ,XX03_PER_PEOPLES_V          XPPV
          ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE  AND XAPV.EFFECTIVE_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE          AND XAPV.R_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE          AND XAPV.U_END_DATE
      AND  XAPV.PERSON_ID   != XRS.REQUESTOR_PERSON_ID
      AND  XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
      AND  XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
      AND  XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
      AND  XPPV.PERSON_ID   = XRS.REQUESTOR_PERSON_ID
      AND  TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE  AND XPPV.EFFECTIVE_END_DATE
      AND  XAPV.PROFILE_VAL_AUTH != 9
      AND  (   XAPV.PROFILE_VAL_DEP = 'ALL'
            OR XAPV.PROFILE_VAL_DEP = 'AR'   )
      AND  XAPV.PERSON_ID   = XRS.APPROVER_PERSON_ID
    ;
-- ver 11.5.10.2.2 add End
--
--2006/02/15 Ver11.5.10.1.6E add start
--各マスター存在チェック
--
    --承認者チェックカーソル
    CURSOR xx03_approver_cur
    IS
-- 2006/03/03 Ver11.5.10.1.6H Change Start
--    SELECT COUNT(1) exist_check
--      FROM per_all_assignments_f pa
--          ,xx03_per_peoples_v    xppv
--          ,xx03_receivable_slips xrs
--     WHERE XRS.RECEIVABLE_ID = in_receivable_id
--       AND pa.supervisor_id = xppv.person_id
--       AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date
--                              AND pa.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.effective_start_date
--                              AND xppv.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.u_start_date
--                              AND xppv.u_end_date
--       AND pa.person_id = xrs.approver_person_id;
--
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
                           ,XX03_RECEIVABLE_SLIPS       XRS
                           ,XX03_DEPARTMENTS_V          XDV
                           ,XX03_PER_PEOPLES_V          XPPV
                           ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
                      WHERE  XRS.RECEIVABLE_ID = in_receivable_id
                        AND TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE
                                               AND XAPV.EFFECTIVE_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE
                                               AND XAPV.R_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE
                                               AND XAPV.U_END_DATE
                        AND XAPV.PERSON_ID   != XRS.APPROVER_PERSON_ID
                        AND XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
                        AND XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
                        AND XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
                        AND XPPV.PERSON_ID     = XRS.APPROVER_PERSON_ID
                        AND TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE
                                               AND XPPV.EFFECTIVE_END_DATE
                        AND XAPV.PROFILE_VAL_AUTH != 9
                        AND (   XAPV.PROFILE_VAL_DEP = 'ALL'
                             OR XAPV.PROFILE_VAL_DEP = 'AR'   )) xaplv
                   WHERE xaplv.person_id = xppv2.supervisor_id
                                );
-- 2006/03/03 Ver11.5.10.1.6H Change END
    --顧客チェックカーソル
    CURSOR xx03_customer_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   HZ_CUST_ACCOUNTS RAA_BILL
          ,XX03_RECEIVABLE_SLIPS XRS
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  RAA_BILL.STATUS = 'A'
      AND  RAA_BILL.CUST_ACCOUNT_ID  = XRS.CUSTOMER_ID;

--
    --顧客事業所チェックカーソル
    CURSOR xx03_cust_office_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,AR_ADDRESSES_V         aav
          ,HZ_CUST_SITE_USES_ALL  hsuv
          ,HZ_CUST_ACCOUNTS       hca
          ,HZ_CUST_ACCT_SITES     hcas
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  hca.CUST_ACCOUNT_ID = aav.CUSTOMER_ID
      AND  aav.ADDRESS_ID = hsuv.CUST_ACCT_SITE_ID
      AND  aav.ADDRESS_ID = hcas.CUST_ACCT_SITE_ID
      AND  hca.STATUS         = 'A'
      AND  hsuv.STATUS        = 'A'
      AND  hsuv.SITE_USE_CODE = 'BILL_TO'
      AND  aav.ADDRESS_ID     = XRS.CUSTOMER_OFFICE_ID
      AND  aav.CUSTOMER_ID    = XRS.CUSTOMER_ID;
--
    -- ver 11.5.10.2.10D Chg Start
    ----通貨チェック
    --CURSOR xx03_currency_name_cur
    --IS
    --SELECT COUNT(1) exist_check
    --FROM   XX03_RECEIVABLE_SLIPS XRS
    --      ,FND_CURRENCIES        FC
    --WHERE  XRS.RECEIVABLE_ID = in_receivable_id
    --  AND  FC.ENABLED_FLAG  = 'Y'
    --  AND  FC.CURRENCY_FLAG = 'Y'
    --  AND  FC.CURRENCY_CODE = XRS.INVOICE_CURRENCY_CODE
    --  -- ver 11.5.10.2.6 Chg Start
    --  --AND  XRS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --  --                          AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  -- ver 11.5.10.2.10C Chg Start
    --  --AND  TRUNC(SYSDATE) BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --  --                        AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  AND  XRS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                            AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --  -- ver 11.5.10.2.10C Chg End
    --  -- ver 11.5.10.2.6 Chg End
    --
    --通貨チェック(精度チェック用に精度を取得するように変更)
    CURSOR xx03_currency_name_cur
    IS
    SELECT FC.CURRENCY_CODE      CURRENCY_CODE
          ,NVL(FC.PRECISION , 0) PRECISION
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,FND_CURRENCIES        FC
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  FC.ENABLED_FLAG  = 'Y'
      AND  FC.CURRENCY_FLAG = 'Y'
      AND  FC.CURRENCY_CODE = XRS.INVOICE_CURRENCY_CODE
      AND  XRS.INVOICE_DATE BETWEEN NVL(FC.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                AND NVL(FC.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    -- ver 11.5.10.2.10D Chg End
--
    --支払方法チェック
    CURSOR xx03_receipt_method_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,XX03_RECEIPT_METHOD_LOV_V xrmlv
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
       AND xrmlv.BATCH_SOURCE_ID = XRS.RECEIPT_METHOD_ID
       AND xrmlv.ADDRESS_ID      = XRS.CUSTOMER_OFFICE_ID
       AND xrmlv.CURRENCY_CODE   = XRS.INVOICE_CURRENCY_CODE
       -- ver 11.5.10.2.6 Chg Start
       --AND XRS.INVOICE_DATE BETWEEN xrmlv.REC_START_DATE
       --                     AND nvl(xrmlv.REC_END_DATE  ,TO_DATE('4712/12/31','YYYY/MM/DD'))
       --AND XRS.INVOICE_DATE BETWEEN xrmlv.CUST_START_DATE
       --                     AND nvl(xrmlv.CUST_END_DATE ,TO_DATE('4712/12/31','YYYY/MM/DD'));
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.REC_START_DATE  ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.REC_END_DATE    ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.CUST_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.CUST_END_DATE   ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.ARMA_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.ARMA_END_DATE   ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE <  nvl(xrmlv.ABA_INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       -- ver 11.5.10.2.10B Chg Start
       --AND XRS.INVOICE_DATE <= nvl(xrmlv.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'));
       -- ver 11.5.10.2.10C Chg Start
       --AND XRS.INVOICE_DATE < nvl(xrmlv.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'));
       AND XRS.INVOICE_DATE < nvl(xrmlv.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       AND XRS.INVOICE_DATE BETWEEN nvl(xrmlv.CURRENCY_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                AND nvl(xrmlv.CURRENCY_END_DATE   ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
       ;
       -- ver 11.5.10.2.10C Chg End
       -- ver 11.5.10.2.10B Chg End
       -- ver 11.5.10.2.6 Chg End
--
    --支払条件チェック
    CURSOR xx03_terms_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS xrs
          ,RA_TERMS_TL rtt
          ,RA_TERMS_B  rtb
    WHERE  XRS.RECEIVABLE_ID = in_receivable_id
      AND  rtt.TERM_ID = rtb.TERM_ID
      AND  rtt.LANGUAGE = USERENV('LANG')
      AND  rtt.TERM_ID  = xrs.TERMS_ID
      AND  xrs.INVOICE_DATE BETWEEN rtb.START_DATE_ACTIVE
                            AND NVL(rtb.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
--
    --取引タイプチェック
    CURSOR xx03_trans_type_name_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS XRS
          ,RA_CUST_TRX_TYPES_ALL RCT
          ,FND_LOOKUP_VALUES     FVL
    WHERE  xrs.RECEIVABLE_ID = in_receivable_id
      AND  RCT.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID')
      AND  RCT.ORG_ID          = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  FVL.LOOKUP_TYPE     = 'XX03_SLIP_TYPES'
      AND  FVL.LANGUAGE        = XX00_GLOBAL_PKG.CURRENT_LANGUAGE
      AND  FVL.ATTRIBUTE15     = RCT.ORG_ID
      AND  FVL.ATTRIBUTE12     = RCT.TYPE
      AND  RCT.CUST_TRX_TYPE_ID = XRS.TRANS_TYPE_ID
      AND  XRS.INVOICE_DATE BETWEEN RCT.START_DATE
                            AND NVL(RCT.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
      AND  FVL.LOOKUP_CODE     = XRS.SLIP_TYPE;
--
    --単位チェック
    -- ver 11.5.10.2.6 Chg Start
    --CURSOR xx03_uom_code_cur(
    --  in_line_number IN number    -- 1.明細番号
    -- ,id_invoice_date IN date     -- 2.請求書日付
    --) IS
    CURSOR xx03_uom_code_cur(
      in_line_number IN number    -- 1.明細番号
    ) IS
    -- ver 11.5.10.2.6 Chg End
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS_LINE XRSL
          ,MTL_UNITS_OF_MEASURE_VL    MUM
    WHERE  XRSL.RECEIVABLE_ID = in_receivable_id
      AND  XRSL.LINE_NUMBER =  in_line_number
      AND  MUM.UOM_CODE = XRSL.SLIP_LINE_UOM
      -- ver 11.5.10.2.6 Chg Start
      --AND  id_invoice_date < NVL(MUM.DISABLE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      AND  TRUNC(SYSDATE) < NVL(MUM.DISABLE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'));
      -- ver 11.5.10.2.6 Chg End
--
    --税金コードチェック
    CURSOR xx03_tax_col_cur(
      in_line_number IN number    -- 1.明細番号
     ,id_invoice_date IN date     -- 2.請求書日付
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_RECEIVABLE_SLIPS      XRS
          ,XX03_RECEIVABLE_SLIPS_LINE XRSL
          ,XX03_TAX_CLASS_LOV_V       XTCLV
    WHERE  XRSL.RECEIVABLE_ID = in_receivable_id
      AND  XRSL.LINE_NUMBER =  in_line_number
      AND  XTCLV.TAX_CODE = XRSL.TAX_CODE
      AND  id_invoice_date BETWEEN NVL(XTCLV.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                               AND NVL(XTCLV.END_DATE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
--
--2006/02/15 Ver11.5.10.1.6E add End
--
    -- 共通エラーチェック結果取得カーソル
    CURSOR xx03_errchk_result_cur
    IS
      SELECT xei.journal_id    as journal_id,
             xei.line_number   as line_number,
             xei.error_code    as error_code,
             xei.error_message as error_message,
             xei.status        as status
        FROM xx03_error_info xei
       WHERE xei. check_id = ln_check_seq
-- ver11.5.10.1.6D Add Start
       ORDER BY xei.line_number;
-- ver11.5.10.1.6D Add End
--
    -- *** ローカル・レコード ***
    xx03_xrsjlv_rec            xx03_xrsjlv_cur          %ROWTYPE;       -- 処理対象データ取得カーソルレコード型
    xx03_rate_rec              xx03_rate_cur            %ROWTYPE;       -- レートカーソルレコード型
    xx03_prerec_get_rec        xx03_prerec_get_cur      %ROWTYPE;       -- 前受充当伝票番号取得カーソルレコード型
    xx03_prerec_check_rec      xx03_prerec_check_cur    %ROWTYPE;       -- 前受充当伝票番号正当性チェックカーソルレコード型
    xx03_prerec_num_rec        xx03_prerec_num_cur      %ROWTYPE;       -- 前受充当伝票番号チェックカーソルレコード型
    xx03_orig_num_rec          xx03_orig_num_cur        %ROWTYPE;       -- 修正元伝票番号チェックカーソルレコード型
    xx03_ar_period_status_rec  xx03_ar_period_status_cur%ROWTYPE;       -- AR会計期間チェックカーソルレコード型
    xx03_gl_period_status_rec  xx03_gl_period_status_cur%ROWTYPE;       -- GL会計期間チェックカーソルレコード型
    -- Ver11.5.10.1.5B 2005/10/06 Add Start
    xx03_site_accounts_rec     xx03_site_accounts_cur   %ROWTYPE;       -- 顧客事業所の請求先サイトレベルの勘定科目存在チェックカーソルレコード型
    xx03_site_profile_rec      xx03_site_profile_cur    %ROWTYPE;       -- 顧客事業所の顧客所在地レベルのプロファイル存在チェックカーソルレコード型
    -- Ver11.5.10.1.5B 2005/10/06 Add End
    xx03_errchk_result_rec     xx03_errchk_result_cur   %ROWTYPE;       -- 共通エラーチェック結果取得レコード型
-- ver 11.5.10.2.2 Add Start
    -- 申請者-承認者 チェックカーソルレコード型
    xx03_req_app_rec             xx03_req_app_cur%ROWTYPE;
-- ver 11.5.10.2.2 Add End
-- 2006/02/18 Ver11.5.10.1.6E Add START
    --承認者チェックカーソルレコード型
    xx03_approver_rec            xx03_approver_cur%ROWTYPE;
    --顧客チェックカーソルレコード型
    xx03_customer_rec              xx03_customer_cur%ROWTYPE;
    --顧客事業所チェックカーソルレコード型
    xx03_cust_office_rec         xx03_cust_office_cur%ROWTYPE;
    --通貨チェックカーソルレコード型
    xx03_currency_name_rec       xx03_currency_name_cur%ROWTYPE;
    --支払方法チェックカーソルレコード型
    xx03_receipt_method_name_rec      xx03_receipt_method_name_cur%ROWTYPE;
    --支払条件チェックカーソルレコード型
    xx03_terms_name_rec          xx03_terms_name_cur%ROWTYPE;
    --取引タイプチェックカーソルレコード型
    xx03_trans_type_name_rec           xx03_trans_type_name_cur%ROWTYPE;
    --単位チェックカーソルレコード型
    xx03_uom_code_rec xx03_uom_code_cur%ROWTYPE;
    --税金コードチェックカーソルレコード型
    xx03_tax_col_rec             xx03_tax_col_cur%ROWTYPE;
-- 2006/02/18 Ver11.5.10.1.6E Add END

--
    -- 相互検証用パラメータ
    lb_retcode          BOOLEAN;
    lv_app_short_name   VARCHAR2(100)  := 'SQLGL';                         -- アプリケーション'General Ledger'
    lv_key_flex_code    VARCHAR2(1000) := 'GL#';                        -- FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE
    ln_structure_number NUMBER         := null;                         -- GL_SETS_OF_BOOKS.CHART_OF_ACCOUNTS_ID
    ld_validation_date  DATE           := SYSDATE;
    ln_segments         NUMBER         := 8;
    lv_segment_array    FND_FLEX_EXT.SEGMENTARRAY;
    on_combination_id   NUMBER         := null;                         -- コンビネーションID
    ld_data_set         NUMBER         := -1;
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
    OPEN xx03_xrsjlv_cur;
    <<xx03_xrsjlv_loop>>
    LOOP
      FETCH xx03_xrsjlv_cur INTO xx03_xrsjlv_rec;
--
      -- 1件もデータがない場合
      IF xx03_xrsjlv_cur%NOTFOUND THEN
        IF ( lv_first_flg = 'Y' ) THEN
          RAISE NO_DATA_FOUND;
        ELSE
          -- データ終了
          EXIT xx03_xrsjlv_loop;
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
        SELECT xrsv.INVOICE_CURRENCY_CODE as INVOICE_CURRENCY_CODE      -- 通貨コード
             , xrsv.EXCHANGE_RATE         as EXCHANGE_RATE              -- レート
             , xrsv.EXCHANGE_RATE_TYPE    as EXCHANGE_RATE_TYPE         -- レートタイプ
             , xrsv.GL_DATE               as GL_DATE                    -- 計上日
        --2006/02/18 Ver11.5.10.1.6E Add START
             , xrsv.INVOICE_DATE          as invoice_date               -- 請求書日付
             , xrsv.RECEIPT_METHOD_ID     as receipt_method_id          -- 支払方法
        --2006/02/18 Ver11.5.10.1.6E Add END
             , xrsv.COMMITMENT_NUMBER     as COMMITMENT_NUMBER          -- 前受充当伝票番号
             , xrsv.ORIG_INVOICE_NUM      as ORIG_INVOICE_NUM           -- 修正元伝票番号
             -- Ver11.5.10.1.5B 2005/10/06 Add Start
             , xrsv.CUSTOMER_OFFICE_ID    as CUSTOMER_OFFICE_ID         -- 顧客事業所ID
             -- Ver11.5.10.1.5B 2005/10/06 Add End
        --2006/03/06 Ver11.5.10.1.6H add start
             , xrsv.WF_STATUS
        --2006/03/06 Ver11.5.10.1.6H add End
        INTO   lv_chk_currency_code
             , ln_chk_exchange_rate
             , lv_chk_exchange_rate_type
             , ld_chk_gl_date
        --2006/02/18 Ver11.5.10.1.6E Add START
             , ld_chk_invoice_date
             , ld_chk_receipt_method_id
        --2006/02/18 Ver11.5.10.1.6E Add END
             , lv_chk_prerec_num
             , lv_chk_orig_invoice_num
             -- Ver11.5.10.1.5B 2005/10/06 Add Start
             , ln_chk_customer_office_id
             -- Ver11.5.10.1.5B 2005/10/06 Add End
        --2006/03/06 Ver11.5.10.1.6H add start
             , ld_wf_status
        --2006/03/06 Ver11.5.10.1.6H add End
-- Ver11.5.10.1.5 2005/09/02 Change Start
--        FROM   XX03_RECEIVABLE_SLIPS_V xrsv
        FROM   XX03_RECEIVABLE_SLIPS xrsv
-- Ver11.5.10.1.5 2005/09/02 Change End
        WHERE  xrsv.RECEIVABLE_ID = in_receivable_id;                   -- 伝票ID
--
        -- レートチェック
        -- 通貨コードが機能通貨コードのとき
        IF ( lv_currency_code = lv_chk_currency_code ) THEN
          -- レートかレートタイプに入力値があればエラー
          IF ( ln_chk_exchange_rate      IS NOT NULL   OR
               lv_chk_exchange_rate_type IS NOT NULL ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14001');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
--
        -- 機能通貨コードでないとき
        ELSE
          -- レートに入力値がなければエラー
          IF ( ln_chk_exchange_rate IS NULL ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14002');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- レートタイプに入力値がなければエラー
          ELSIF ( lv_chk_exchange_rate_type IS NULL ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14003');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- レートタイプが'User'のとき
          ELSIF ( lv_chk_exchange_rate_type != 'User' ) THEN
            OPEN xx03_rate_cur(
              lv_chk_currency_code,       -- 1.通貨コード
              lv_chk_exchange_rate_type,  -- 2.レートタイプ
              ld_chk_gl_date              -- 3.GL記帳日
            );
--
            FETCH xx03_rate_cur INTO xx03_rate_rec;
            -- 該当レコードがなければエラー
            IF xx03_rate_cur%NOTFOUND THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14004');
              ln_err_cnt := ln_err_cnt + 1;
--
            -- 該当レコードがあるとき
            ELSE
              -- レートの値が異なればエラー
              IF ( xx03_rate_rec.conversion_rate != ln_chk_exchange_rate ) THEN
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
        -- 前受金充当伝票番号チェック
        OPEN xx03_prerec_get_cur();
        FETCH xx03_prerec_get_cur INTO xx03_prerec_get_rec;
--
        -- 前受伝票指定なし
        IF (xx03_prerec_get_rec.COMMITMENT_NUMBER IS NULL) THEN
          -- 特に処理なし
          NULL;
--
        -- 前受伝票指定あり
        ELSE
          OPEN xx03_prerec_check_cur();
          FETCH xx03_prerec_check_cur INTO xx03_prerec_check_rec;
--
          -- 該当レコードがなければエラー
          IF xx03_prerec_check_cur%NOTFOUND THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14058');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- レコードが選択された
          ELSE
            -- 特に処理なし
            NULL;
          END IF;
          CLOSE xx03_prerec_check_cur;
        END IF;
        CLOSE xx03_prerec_get_cur;
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- 前払充当伝票番号入力時のみチェックする
      IF lv_chk_prerec_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- 前受充当伝票番号チェック
        OPEN xx03_prerec_num_cur(
          lv_chk_prerec_num  -- 1.前受充当伝票番号
        );
--
        FETCH xx03_prerec_num_cur INTO xx03_prerec_num_rec;
--
        -- 該当レコードが選択されなかった
        IF xx03_prerec_num_cur%NOTFOUND THEN
          -- 特に処理なし
          NULL;
--
        -- 該当レコードがあればエラー
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14059');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_prerec_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- 修正元伝票番号入力時のみチェックする
      IF lv_chk_orig_invoice_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- 修正元伝票番号チェック
        OPEN xx03_orig_num_cur(
          lv_chk_orig_invoice_num  -- 1.修正元伝票番号
        );
--
        FETCH xx03_orig_num_cur INTO xx03_orig_num_rec;
--
        -- レコードが選択されなかった
        IF xx03_orig_num_cur%NOTFOUND THEN
          -- 特に処理なし
          NULL;
--
        -- 該当レコードがあればエラー
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14149');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_orig_num_cur;
-- Ver11.5.10.1.5 2005/09/02 Change Start
      END IF;
-- Ver11.5.10.1.5 2005/09/02 Change End
--
        -- AR会計期間チェック
        OPEN xx03_ar_period_status_cur(
          ln_books_id,    -- 1.修正元伝票番号
          ld_chk_gl_date  -- 2.GL記帳日
        );
        FETCH xx03_ar_period_status_cur INTO xx03_ar_period_status_rec;
--
        -- 会計期間データなしなら、AR会計期間未定義エラー
        IF xx03_ar_period_status_cur%NOTFOUND THEN
          lv_period_data_flg := 'N';
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14060');
          ln_err_cnt := ln_err_cnt + 1;
--
        -- 会計期間データあり
        ELSE
          lv_period_data_flg := 'Y';
--
          -- AR会計期間がオープンでなければ、未オープンエラー
          IF ( xx03_ar_period_status_rec.closing_status != 'O'   AND
               xx03_ar_period_status_rec.closing_status != 'F' ) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14061');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- 'O'、'F'の時は特に処理なし
          ELSE
            NULL;
          END IF;
        END IF;
        CLOSE xx03_ar_period_status_cur;
--
        -- 会計期間データありの時のみ
        IF ( lv_period_data_flg = 'Y' ) THEN
          -- GL会計期間チェック
          OPEN xx03_gl_period_status_cur(
            ln_books_id,    -- 1.修正元伝票番号
            ld_chk_gl_date  -- 2.GL記帳日
          );
--
          FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
--
          -- 該当データがなければ、GL会計期間未定義エラー
          IF xx03_gl_period_status_cur%NOTFOUND THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14013');
            ln_err_cnt := ln_err_cnt + 1;
--
          -- 該当データがあるとき
          ELSE
            -- GL会計期間がオープンされていなければ、未オープンエラー
            IF ( xx03_gl_period_status_rec.attribute4 IS NOT NULL AND
                 xx03_gl_period_status_rec.attribute4 != 'O' )    THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
--
            -- 'O'、Nullの時は特に処理なし
            ELSE
              NULL;
            END IF;
          END IF;
          CLOSE xx03_gl_period_status_cur;
        END IF;
--
        -- Ver11.5.10.1.5B 2005/10/06 Add Start
        -- 顧客事業所の請求先サイトレベルの勘定科目存在チェック
        OPEN xx03_site_accounts_cur(
          ln_chk_customer_office_id  -- 1.顧客事業所ID
        );
--
        FETCH xx03_site_accounts_cur INTO xx03_site_accounts_rec;
--
        -- レコードが選択されなければエラー
        IF xx03_site_accounts_cur%NOTFOUND THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13058');
          ln_err_cnt := ln_err_cnt + 1;
--
        -- 該当レコードあり
        ELSE
          -- 特に処理なし
          NULL;
        END IF;
        CLOSE xx03_site_accounts_cur;
--
        -- 顧客事業所の顧客所在地レベルのプロファイル存在チェック
        OPEN xx03_site_profile_cur(
          ln_chk_customer_office_id  -- 1.顧客事業所ID
        );
--
        FETCH xx03_site_profile_cur INTO xx03_site_profile_rec;
--
        -- レコードが選択されなければエラー
        IF xx03_site_profile_cur%NOTFOUND THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13059');
          ln_err_cnt := ln_err_cnt + 1;
--
        -- 該当レコードあり
        ELSE
          -- 特に処理なし
          NULL;
        END IF;
        CLOSE xx03_site_profile_cur;
        -- Ver11.5.10.1.5B 2005/10/06 Add End
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
-- 2006/02/18 Ver11.5.10.1.6E Add START
-- ヘッダーのマスターチェック実施
        --2006/03/06 Ver11.5.10.1.6H Change Start
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
        --2006/03/06 Ver11.5.10.1.6H Change End
--
        --顧客チェック
        OPEN xx03_customer_cur;
        FETCH xx03_customer_cur INTO xx03_customer_rec;
        IF xx03_customer_rec.exist_check = 0 THEN
          -- 顧客チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13061','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_customer_cur;
--
        --顧客事業所チェック
        OPEN xx03_cust_office_cur;
        FETCH xx03_cust_office_cur INTO xx03_cust_office_rec;
        IF xx03_cust_office_rec.exist_check = 0 THEN
          -- 顧客事業所チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13062','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_cust_office_cur;
--
        -- ver 11.5.10.2.10D Chg Start
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
        -- ver 11.5.10.2.10D Chg End
--
        --支払方法チェック
        --支払方法がNULLでないときのみチェック実施
        IF ld_chk_receipt_method_id IS NOT NULL THEN
          OPEN xx03_receipt_method_name_cur;
          FETCH xx03_receipt_method_name_cur INTO xx03_receipt_method_name_rec;
          IF xx03_receipt_method_name_rec.exist_check = 0 THEN
            -- 支払方法チェックエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13063','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_receipt_method_name_cur;
        END IF;
--
        --支払条件チェック
        OPEN xx03_terms_name_cur;
        FETCH xx03_terms_name_cur INTO xx03_terms_name_rec;
        IF xx03_terms_name_rec.exist_check = 0 THEN
          -- 支払条件チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13064','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_terms_name_cur;
--
        --取引タイプチェック
-- ver 11.5.10.1.6G Add Start
        --取引伝票以外の場合チェックする
        IF lv_chk_orig_invoice_num IS NULL THEN
-- ver 11.5.10.1.6G Add End
          OPEN xx03_trans_type_name_cur;
          FETCH xx03_trans_type_name_cur INTO xx03_trans_type_name_rec;
          IF xx03_trans_type_name_rec.exist_check = 0 THEN
            -- 取引タイプチェックエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13060','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_trans_type_name_cur;
-- ver 11.5.10.1.6G Add Start
        END IF;
-- ver 11.5.10.1.6G Add End
--
-- 2006/02/18 Ver11.5.10.1.6E Add END
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
      -- フレックス・フィールド体系番号の取得
      SELECT   sob.chart_of_accounts_id
        INTO   ln_structure_number
        FROM   gl_sets_of_books sob
       WHERE   xx00_profile_pkg.VALUE('GL_SET_OF_BKS_ID') = sob.set_of_books_id;
--
      -- 相互検証ルールチェック実行(対象 : ヘッダー以外)
      IF (xx03_xrsjlv_rec.segment1 IS NOT NULL) THEN
        lv_segment_array(1) := xx03_xrsjlv_rec.segment1;
        lv_segment_array(2) := xx03_xrsjlv_rec.segment2;
        lv_segment_array(3) := xx03_xrsjlv_rec.segment3;
        lv_segment_array(4) := xx03_xrsjlv_rec.segment4;
        lv_segment_array(5) := xx03_xrsjlv_rec.segment5;
        lv_segment_array(6) := xx03_xrsjlv_rec.segment6;
        lv_segment_array(7) := xx03_xrsjlv_rec.segment7;
        lv_segment_array(8) := xx03_xrsjlv_rec.segment8;
--
        lb_retcode := FND_FLEX_EXT.GET_COMBINATION_ID(
                          application_short_name => lv_app_short_name
                        , key_flex_code          => lv_key_flex_code
                        , structure_number       => ln_structure_number
        -- 2006/01/30 Ver11.5.10.1.6C Change Start
        --              , validation_date        => ld_validation_date
                        , validation_date        => ld_chk_gl_date
        -- 2006/01/30 Ver11.5.10.1.6C Change End
                        , n_segments             => ln_segments
                        , segments               => lv_segment_array
                        , combination_id         => on_combination_id
                        , data_set               => ld_data_set
        );
--
        IF lb_retcode THEN
          NULL;
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := FND_FLEX_EXT.GET_MESSAGE;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
      END IF; -- xx03_xrsjlv_rec.segment1 IS NOT NULL
--
-- 2006/02/18 Ver11.5.10.1.6E add START
-- 明細のマスター値チェックを実施する
      --請求内容チェック
      --明細行のみチェックする
      IF xx03_xrsjlv_rec.line_type_lookup_code = 'ITEM' THEN
--
      --単位チェック
        --単位が入力されているときのみチェック実施
        SELECT SLIP_LINE_UOM
        INTO   ld_slip_line_uom
        FROM   XX03_RECEIVABLE_SLIPS_LINE
        WHERE  RECEIVABLE_ID = in_receivable_id
          AND  LINE_NUMBER   = xx03_xrsjlv_rec.line_number;
        IF ld_slip_line_uom IS NOT NULL THEN
          -- ver 11.5.10.2.6 Chg Start
          --OPEN xx03_uom_code_cur(
          --  xx03_xrsjlv_rec.line_number,    -- 1.明細番号
          --  ld_chk_invoice_date             -- 2.請求書日付
          --);
          OPEN xx03_uom_code_cur(xx03_xrsjlv_rec.line_number);  -- 1.明細番号
          -- ver 11.5.10.2.6 Chg End
          FETCH xx03_uom_code_cur INTO xx03_uom_code_rec;
          IF xx03_uom_code_rec.exist_check = 0 THEN
            -- 単位エラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt)
              := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13066'
                                          ,'SLIP_NUM',''
                                          ,'TOK_COUNT',xx03_xrsjlv_rec.line_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_uom_code_cur;
        END IF;
--
      --税金コードチェック
        OPEN xx03_tax_col_cur(
          xx03_xrsjlv_rec.line_number,    -- 1.明細番号
          ld_chk_invoice_date             -- 2.請求書日付
        );
        FETCH xx03_tax_col_cur INTO xx03_tax_col_rec;
        IF xx03_tax_col_rec.exist_check = 0 THEN
          -- 税金コードエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt)
            := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14151'
                                        ,'SLIP_NUM',''
                                        ,'TOK_COUNT',xx03_xrsjlv_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_tax_col_cur;
--
        -- ver 11.5.10.2.10D Add Start
        -- 通貨が正しく入力されている場合はチェック
        IF lb_currency_chk = TRUE THEN
          -- 伝票金額の精度を取得
          lv_amount := TO_CHAR(xx03_xrsjlv_rec.amount);
          IF INSTR(lv_amount ,cv_precision_char) = 0 THEN
            ln_amount_precision := 0;
          ELSE
            ln_amount_precision := LENGTH(lv_amount) - INSTR(TO_CHAR(lv_amount) ,cv_precision_char);
          END IF;
--
          -- 伝票金額の精度が通貨の精度を超えていればエラー
          IF ln_currency_precision < ln_amount_precision THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt)
              := xx00_message_pkg.get_msg('XX03','APP-XX03-14167'
                                          ,'SLIP_NUM',''
                                          ,'TOK_COUNT',xx03_xrsjlv_rec.line_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        -- ver 11.5.10.2.10D Add End
--
      END IF;
--
-- 2006/02/18 Ver11.5.10.1.6E add END
--
      -- 部門入力エラーチェックでエラーがあった場合はその時点でループ終了
      IF ( ln_err_cnt > 0 ) THEN
        -- データ終了
        EXIT xx03_xrsjlv_loop;
      END IF;
--
      -- エラーチェックテーブル書き込み
      IF ( xx03_xrsjlv_rec.line_number = 0 ) THEN
        -- ヘッダレコード
        INSERT INTO xx03_error_checks(
            CHECK_ID
          , JOURNAL_ID
          , LINE_NUMBER
          , GL_DATE
          , PERIOD_NAME
          , CURRENCY_CODE
          , CODE_COMBINATION_ID
          , SEGMENT1
          , SEGMENT2
          , SEGMENT3
          , SEGMENT4
          , SEGMENT5
          , SEGMENT6
          , SEGMENT7
          , SEGMENT8
          , TAX_CODE
          , INCR_DECR_REASON_CODE
          , SLIP_NUMBER
          , INPUT_DEPARTMENT
          , INPUT_USER
          , ORIG_SLIP_NUMBER
          , RECON_REFERENCE
          , ENTERED_DR
          , ENTERED_CR
          , ATTRIBUTE_CATEGORY
          , ATTRIBUTE1
          , ATTRIBUTE2
          , ATTRIBUTE3
          , ATTRIBUTE4
          , ATTRIBUTE5
          , ATTRIBUTE6
          , ATTRIBUTE7
          , ATTRIBUTE8
          , ATTRIBUTE9
          , ATTRIBUTE10
          , ATTRIBUTE11
          , ATTRIBUTE12
          , ATTRIBUTE13
          , ATTRIBUTE14
          , ATTRIBUTE15
          , ATTRIBUTE16
          , ATTRIBUTE17
          , ATTRIBUTE18
          , ATTRIBUTE19
          , ATTRIBUTE20
          , CREATED_BY
          , CREATION_DATE
          , LAST_UPDATED_BY
          , LAST_UPDATE_DATE
          , LAST_UPDATE_LOGIN
          , REQUEST_ID
          , PROGRAM_APPLICATION_ID
          , PROGRAM_UPDATE_DATE
          , PROGRAM_ID
        ) VALUES (
            ln_check_seq
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.line_number
          , xx03_xrsjlv_rec.gl_date
          , null
          , xx03_xrsjlv_rec.invoice_currency_code
          , xx03_xrsjlv_rec.code_combination_id
          , xx03_xrsjlv_rec.segment1
          , xx03_xrsjlv_rec.segment2
          , xx03_xrsjlv_rec.segment3
          , xx03_xrsjlv_rec.segment4
          , xx03_xrsjlv_rec.segment5
          , xx03_xrsjlv_rec.segment6
          , xx03_xrsjlv_rec.segment7
          , xx03_xrsjlv_rec.segment8
          , null
          , null
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.entry_department
          , xx03_xrsjlv_rec.user_name
          , null
          , null
          , null
          , xx03_xrsjlv_rec.amount
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.login_id
          , xx00_global_pkg.conc_request_id
          , xx00_global_pkg.prog_appl_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.conc_program_id
        );
      ELSE
        -- 明細(税金)レコード
        INSERT INTO xx03_error_checks(
            CHECK_ID
          , JOURNAL_ID
          , LINE_NUMBER
          , GL_DATE
          , PERIOD_NAME
          , CURRENCY_CODE
          , CODE_COMBINATION_ID
          , SEGMENT1
          , SEGMENT2
          , SEGMENT3
          , SEGMENT4
          , SEGMENT5
          , SEGMENT6
          , SEGMENT7
          , SEGMENT8
          , TAX_CODE
          , INCR_DECR_REASON_CODE
          , SLIP_NUMBER
          , INPUT_DEPARTMENT
          , INPUT_USER
          , ORIG_SLIP_NUMBER
          , RECON_REFERENCE
          , ENTERED_DR
          , ENTERED_CR
          , ATTRIBUTE_CATEGORY
          , ATTRIBUTE1
          , ATTRIBUTE2
          , ATTRIBUTE3
          , ATTRIBUTE4
          , ATTRIBUTE5
          , ATTRIBUTE6
          , ATTRIBUTE7
          , ATTRIBUTE8
          , ATTRIBUTE9
          , ATTRIBUTE10
          , ATTRIBUTE11
          , ATTRIBUTE12
          , ATTRIBUTE13
          , ATTRIBUTE14
          , ATTRIBUTE15
          , ATTRIBUTE16
          , ATTRIBUTE17
          , ATTRIBUTE18
          , ATTRIBUTE19
          , ATTRIBUTE20
          , CREATED_BY
          , CREATION_DATE
          , LAST_UPDATED_BY
          , LAST_UPDATE_DATE
          , LAST_UPDATE_LOGIN
          , REQUEST_ID
          , PROGRAM_APPLICATION_ID
          , PROGRAM_UPDATE_DATE
          , PROGRAM_ID
        ) VALUES (
            ln_check_seq
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.line_number
          , xx03_xrsjlv_rec.gl_date
          , null
          , xx03_xrsjlv_rec.invoice_currency_code
          , xx03_xrsjlv_rec.code_combination_id
          , xx03_xrsjlv_rec.segment1
          , xx03_xrsjlv_rec.segment2
          , xx03_xrsjlv_rec.segment3
          , xx03_xrsjlv_rec.segment4
          , xx03_xrsjlv_rec.segment5
          , xx03_xrsjlv_rec.segment6
          , xx03_xrsjlv_rec.segment7
          , xx03_xrsjlv_rec.segment8
          , xx03_xrsjlv_rec.tax_code
          , xx03_xrsjlv_rec.incr_decr_reason_code
          , xx03_xrsjlv_rec.RECEIVABLE_NUM
          , xx03_xrsjlv_rec.entry_department
          , xx03_xrsjlv_rec.user_name
          , null
          , xx03_xrsjlv_rec.recon_reference
          , xx03_xrsjlv_rec.amount
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , null
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.user_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.login_id
          , xx00_global_pkg.conc_request_id
          , xx00_global_pkg.prog_appl_id
          , xx00_date_pkg.get_system_datetime_f
          , xx00_global_pkg.conc_program_id
        );
      END IF;
    END LOOP xx03_xrsjlv_loop;
    CLOSE xx03_xrsjlv_cur;
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
--
          IF xx03_errchk_result_cur%NOTFOUND THEN
            EXIT xx03_errchk_result_loop;
          END IF;
--
          -- 取得したエラー情報を順にエラー情報配列にセット
          IF ( ln_err_cnt <= 19 ) THEN
            -- エラー件数が20件以下の時のみエラー情報セット
            errflg_tbl(ln_err_cnt) := xx03_errchk_result_rec.status;
-- ver 11.5.10.2.10 Chg Start
--            errmsg_tbl(ln_err_cnt) := TRUNC(xx03_errchk_result_rec.line_number) || '：' ||
--                                            xx03_errchk_result_rec.error_message;
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
-- ver 11.5.10.2.10 Chg End
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
--
        END LOOP xx03_errchk_result_loop;
        CLOSE xx03_errchk_result_cur;
      END IF;
--
-- ver 11.5.10.1.6F Del Start
      ---- エラーチェック、エラー情報データ削除
      --DELETE FROM xx03_error_checks xec WHERE xec.check_id = ln_check_seq;
      --DELETE FROM xx03_error_info xei   WHERE xei.check_id = ln_check_seq;
-- ver 11.5.10.1.6F Del End
    END IF;
--
-- ver 11.5.10.1.6F Add Start
    IF ln_check_seq != 0 THEN
      -- エラーチェック、エラー情報データ削除
      DELETE FROM xx03_error_checks xec WHERE xec.check_id = ln_check_seq;
      DELETE FROM xx03_error_info xei   WHERE xei.check_id = ln_check_seq;
    END IF;
-- ver 11.5.10.1.6F Add End
--
    -- OUTパラメータ設定
    ov_error_flg := 'S';
    FOR ln_cnt IN 0..19 LOOP
--
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
    -- エラー件数が２０以上なら、エラー件数は２０を返す。
    IF ln_err_cnt > 20 THEN
      on_error_cnt   := 20;
    ELSE
      on_error_cnt   := ln_err_cnt;
    END IF;
--
    ov_error_flg1  := errflg_tbl(0);
    ov_error_msg1  := errmsg_tbl(0);
    ov_error_flg2  := errflg_tbl(1);
    ov_error_msg2  := errmsg_tbl(1);
    ov_error_flg3  := errflg_tbl(2);
    ov_error_msg3  := errmsg_tbl(2);
    ov_error_flg4  := errflg_tbl(3);
    ov_error_msg4  := errmsg_tbl(3);
    ov_error_flg5  := errflg_tbl(4);
    ov_error_msg5  := errmsg_tbl(4);
    ov_error_flg6  := errflg_tbl(5);
    ov_error_msg6  := errmsg_tbl(5);
    ov_error_flg7  := errflg_tbl(6);
    ov_error_msg7  := errmsg_tbl(6);
    ov_error_flg8  := errflg_tbl(7);
    ov_error_msg8  := errmsg_tbl(7);
    ov_error_flg9  := errflg_tbl(8);
    ov_error_msg9  := errmsg_tbl(8);
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
      IF xx03_xrsjlv_cur%ISOPEN THEN
        CLOSE xx03_xrsjlv_cur;
      END IF;
      IF xx03_rate_cur%ISOPEN THEN
        CLOSE xx03_rate_cur;
      END IF;
      IF xx03_prerec_get_cur%ISOPEN THEN
        CLOSE xx03_prerec_get_cur;
      END IF;
      IF xx03_prerec_check_cur%ISOPEN THEN
        CLOSE xx03_prerec_check_cur;
      END IF;
      IF xx03_prerec_num_cur%ISOPEN THEN
        CLOSE xx03_prerec_num_cur;
      END IF;
      IF xx03_orig_num_cur%ISOPEN THEN
        CLOSE xx03_orig_num_cur;
      END IF;
      IF xx03_ar_period_status_cur%ISOPEN THEN
        CLOSE xx03_ar_period_status_cur;
      END IF;
      IF xx03_gl_period_status_cur%ISOPEN THEN
        CLOSE xx03_gl_period_status_cur;
      END IF;
      -- Ver11.5.10.1.5B 2005/10/06 Add Start
      IF xx03_site_accounts_cur%ISOPEN THEN
        CLOSE xx03_site_accounts_cur;
      END IF;
      IF xx03_site_profile_cur%ISOPEN THEN
        CLOSE xx03_site_profile_cur;
      END IF;
      -- Ver11.5.10.1.5B 2005/10/06 Add End
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
  END check_deptinput_ar;
--
  /**********************************************************************************
   * Procedure Name   : set_account_approval_flag
   * Description      : 重点管理チェック
   ***********************************************************************************/
  PROCEDURE set_account_approval_flag(
    in_receivable_id IN  NUMBER,    -- 1.チェック対象請求書ID
    ov_app_upd       OUT VARCHAR2,  -- 2.重点管理更新内容
    ov_errbuf        OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.set_account_approval_flag'; -- プログラム名
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
    ln_head_acc_amount   NUMBER;                            -- ヘッダ換算額
    lv_slip_type         VARCHAR2(25);                      -- ヘッダ伝票種別
    lv_detail_first_flg  VARCHAR2(1);                       -- 配分読込1件目フラグ
--
    -- *** ローカル・カーソル ***
    -- 伝票種別マスタ情報取得カーソル
    CURSOR xx03_slip_type_cur(
      iv_slip_type   IN  VARCHAR2  -- 1.伝票種別
    ) IS
      SELECT   xst.attribute1 as attribute1
             , xst.attribute2 as attribute2
        FROM   xx03_slip_types_v xst
       WHERE   xst.lookup_code = iv_slip_type;
--
    -- 請求書配分情報取得カーソル
    CURSOR xx03_detail_info_cur
    IS
      SELECT   xav.attribute7              as attribute7
        FROM   XX03_RECEIVABLE_SLIPS_LINE     xrsl
             , xx03_accounts_v                xav
--     WHERE   xrsl.RECEIVABLE_LINE_ID = in_receivable_id   -- 伝票ID
       WHERE   xrsl.RECEIVABLE_ID      = in_receivable_id   -- 伝票ID
         AND   xrsl.segment3           = xav.flex_value;    -- 勘定科目
--
    -- *** ローカル・レコード ***
    xx03_slip_type_rec       xx03_slip_type_cur  %ROWTYPE;  -- 伝票種別マスタ情報取得カーソルレコード型
    xx03_detail_info_rec     xx03_detail_info_cur%ROWTYPE;  -- 請求書配分情報取得カーソルレコード型
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
    SELECT   ABS(
               ROUND((xrs.INV_ITEM_AMOUNT + xrs.INV_TAX_AMOUNT) * NVL(xrs.EXCHANGE_RATE, 1))
             ) as inv_accounted_amount                         -- 換算済合計金額[（本体合計金額 ＋ 消費税合計金額） × レート]
           , xrs.SLIP_TYPE as SLIP_TYPE                        -- 伝票種別
      INTO   ln_head_acc_amount
           , lv_slip_type
      FROM   XX03_RECEIVABLE_SLIPS xrs
     WHERE   xrs.RECEIVABLE_ID = in_receivable_id;             -- 伝票ID
--
    -- 伝票種別マスタ情報取得
    OPEN xx03_slip_type_cur(lv_slip_type);
--
    FETCH xx03_slip_type_cur INTO xx03_slip_type_rec;
--
    -- 伝票種別マスタからデータが取得できないとき
    IF xx03_slip_type_cur%NOTFOUND THEN
      RAISE NO_DATA_FOUND;
--
    -- 伝票種別マスタからデータを取得できたとき
    ELSE
      -- 経理承認重点管理有無が'Y'だった場合は、「重点管理更新内容」に'Y'をセットしてRETURN
      IF ( xx03_slip_type_rec.attribute1 = 'Y' ) THEN
        ov_app_upd := 'Y';
        CLOSE xx03_slip_type_cur;
        RETURN;
--
      -- 経理承認重点管理有無が'N'だった場合
      ELSE
        -- 換算済合計金額 >= 経理承認対象伝票金額のとき
        IF ( ln_head_acc_amount >= xx03_slip_type_rec.attribute2 ) THEN
          -- 「重点管理更新内容」に'Y'をセットし、RETURN
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
--
      -- 1件もなかった場合
      IF xx03_detail_info_cur%NOTFOUND THEN
        -- 初回ならエラー
        IF ( lv_detail_first_flg = 'Y' ) THEN
          RAISE NO_DATA_FOUND;
--
        -- 初回でなければループを離脱する。
        ELSE
          EXIT xx03_detail_info_loop;
        END IF;
      END IF;
--
      -- 初回フラグをOFFにする。
      IF ( lv_detail_first_flg = 'Y' ) THEN
        lv_detail_first_flg := 'N';
      END IF;
--
      -- attribute7が'Y'のレコードがあれば、「重点管理更新内容」に'Y'をセットしてRETURN
      IF ( xx03_detail_info_rec.attribute7 = 'Y' ) THEN
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
   * Description      : 入金予定日の算出
   ***********************************************************************************/
  PROCEDURE get_terms_date(
    in_terms_id   IN  NUMBER,    -- 1.支払条件
    id_start_date IN  DATE,      -- 2.請求書日付
    od_terms_date OUT DATE,      -- 3.入金予定日
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.get_terms_date'; -- プログラム名
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

    -- 支払予定日算出用
    l_due_cutoff_day       RA_TERMS_VL.DUE_CUTOFF_DAY%TYPE;
    l_due_days             RA_TERMS_LINES.DUE_DAYS%TYPE;
    l_due_date             RA_TERMS_LINES.DUE_DATE%TYPE;
    l_due_day_of_month     RA_TERMS_LINES.DUE_DAY_OF_MONTH%TYPE;
    l_due_months_forward   RA_TERMS_LINES.DUE_MONTHS_FORWARD%TYPE;
    ln_start_day           NUMBER;
    ln_cut_day             NUMBER;
    ln_after_day           NUMBER;
    ld_add_day             DATE;
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
--
   -- AR期間情報取得
   SELECT rtl.sequence_num as sequence_num
     INTO ln_sequence_num
     FROM ra_terms_lines rtl
    WHERE rtl.term_id = in_terms_id
      AND rownum = 1
   ORDER BY rtl.sequence_num;
--
/*
  -- 支払予定日を取得
    SELECT DECODE(RTL.DUE_DAYS,
         NULL, TO_DATE(TO_CHAR(ADD_MONTHS(id_start_date,
             NVL(RTL.DUE_MONTHS_FORWARD, 0) +
               DECODE(RT.DUE_CUTOFF_DAY, NULL, 0,
          DECODE(GREATEST(LEAST(NVL(RT.DUE_CUTOFF_DAY, 32),
             TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
             TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
                TO_NUMBER(TO_CHAR(id_start_date, 'DD')), 1, 0))),
                   'YYYY/MM') || '/' ||
          TO_CHAR(LEAST(NVL(RTL.DUE_DAY_OF_MONTH, 32),
           TO_NUMBER(TO_CHAR(LAST_DAY(ADD_MONTHS(id_start_date,
             NVL(RTL.DUE_MONTHS_FORWARD, 0) +
           DECODE(RT.DUE_CUTOFF_DAY, NULL, 0,
           DECODE(GREATEST(LEAST(NVL(RT.DUE_CUTOFF_DAY, 32),
             TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date), 'DD'))),
             TO_NUMBER(TO_CHAR(id_start_date, 'DD'))),
             TO_NUMBER(TO_CHAR(id_start_date, 'DD'))
             , 1, 0)))), 'DD')))
          ),'YYYY/MM/DD'
          ),
          id_start_date + NVL(RTL.DUE_DAYS, 0))
    INTO od_terms_date
    FROM RA_TERMS_VL RT,
         RA_TERMS_LINES RTL
   WHERE RT.TERM_ID = in_terms_id
     AND RT.TERM_ID = RTL.TERM_ID
     AND RTL.SEQUENCE_NUM = ln_sequence_num;
*/
--
  -- 支払予定日算出に必要な項目を取得
  SELECT RT.DUE_CUTOFF_DAY       DUE_CUTOFF_DAY
        ,RTL.DUE_DAYS            DUE_DAYS
        ,RTL.DUE_DATE            DUE_DATE
        ,RTL.DUE_DAY_OF_MONTH    DUE_DAY_OF_MONTH
        ,RTL.DUE_MONTHS_FORWARD  DUE_MONTHS_FORWARD
  INTO   l_due_cutoff_day
        ,l_due_days
        ,l_due_date
        ,l_due_day_of_month
        ,l_due_months_forward
  FROM   ( SELECT TERM_ID
                 ,DUE_CUTOFF_DAY
           FROM   RA_TERMS_VL
           WHERE  TERM_ID = in_terms_id         ) RT
        ,( SELECT TERM_ID
                 ,DUE_DAYS
                 ,DUE_DATE
                 ,DUE_DAY_OF_MONTH
                 ,DUE_MONTHS_FORWARD
           FROM   RA_TERMS_LINES
           WHERE  TERM_ID      = in_terms_id
              AND SEQUENCE_NUM = ln_sequence_num) RTL
  WHERE  RT.TERM_ID = RTL.TERM_ID
  ;

  -- 日付指定が入力されている場合は、そのまま値をセット
  IF l_due_date IS NOT NULL THEN
    od_terms_date := l_due_date;

  -- 日数指定が入力されている場合は、その値を加算してセット
  ELSIF l_due_days IS NOT NULL THEN
    od_terms_date := id_start_date + l_due_days;

  -- 上記以外は各値より計算する
  ELSE

    -- 入力値の日付を取得
    ln_start_day := TO_NUMBER(TO_CHAR(id_start_date,'DD'));
    -- 入力値の末日を締日にセット
    -- Ver11.5.10.1.6 2005/11/04 Change Start
    -- ln_cut_day   := TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date),'DD'));
    ln_cut_day   := TO_NUMBER(TO_CHAR(LAST_DAY(id_start_date),'DD')) + 1;
    -- Ver11.5.10.1.6 2005/11/04 Change End

    -- 締日が入力されている場合は末日と比較して若い日を締日とする
    IF l_due_cutoff_day IS NOT NULL THEN
      IF l_due_cutoff_day < ln_cut_day THEN
        ln_cut_day := l_due_cutoff_day;
      END IF;
    END IF;

    -- 入力日と締日を比較して入力日が締日を以降なら
    -- 月の繰越にさらに１ヶ月追加する
    IF ln_start_day >= ln_cut_day THEN
      ld_add_day := ADD_MONTHS(id_start_date,NVL(l_due_months_forward,0) + 1);
    ELSE
      ld_add_day := ADD_MONTHS(id_start_date,NVL(l_due_months_forward,0));
    END IF;

    -- 月の繰越後の末日をワークにセット
    ln_after_day := TO_NUMBER(TO_CHAR(LAST_DAY(ld_add_day),'DD'));

    -- 支払日付が入力されている場合は末日と比較して若い日を予定日とする
    IF l_due_day_of_month IS NOT NULL THEN
      IF l_due_day_of_month < ln_after_day THEN
        ln_after_day := l_due_day_of_month;
      END IF;
    END IF;

    -- 予定月と予定日より、入金予定日を取得する
    od_terms_date := TO_DATE(TO_CHAR(ld_add_day,'YYYY/MM') || '/' || TO_CHAR(ln_after_day,'00'),'YYYY/MM/DD');

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
      ov_errmsg  := lv_errmsg;                                                           --# 任意 #
      ov_errbuf  := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000); --# 任意 #
      ov_retcode := xx00_common_pkg.set_status_error_f;                                  --# 任意 #
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
  /**********************************************************************************
   * Procedure Name   : del_receivable_data
   * Description      : 支払伝票レコードの削除
   *                    WFステータスが「保存」なら物理削除を行う。
   *                    WFステータスが「否認」（「保存」以外）なら論理削除を行う。
   ***********************************************************************************/
  PROCEDURE del_receivable_data(
    in_receivable_id IN  NUMBER,    -- 1.削除対象請求依頼伝票ID
    ov_errbuf        OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --自律トランザクション化
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_ar_check_pkg.del_receivable_data'; -- プログラム名
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
    cn_wf_status_save CONSTANT XX03_RECEIVABLE_SLIPS.wf_status%TYPE   := '00';  -- WFステータス：保存
    cn_delete_yes     CONSTANT XX03_RECEIVABLE_SLIPS.delete_flag%TYPE := 'Y';   -- 削除フラグ：論理削除状態
--
    -- *** ローカル変数 ***
    lv_wf_status               XX03_RECEIVABLE_SLIPS.wf_status%TYPE;            -- WFステータス
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
--
    -- WFステータスを取得
    SELECT xrs.wf_status
    INTO   lv_wf_status
    FROM   XX03_RECEIVABLE_SLIPS xrs
    WHERE  xrs.RECEIVABLE_ID = in_receivable_id;
--
    -- 保存伝票（WFステータスが「保存」のもの）は物理削除を行う
    IF lv_wf_status = cn_wf_status_save THEN
      -- 仕訳伝票明細レコード削除
      DELETE FROM xx03_receivable_slips_line xrsl
      WHERE xrsl.RECEIVABLE_ID = in_receivable_id;
--
      -- 仕訳伝票ヘッダレコード削除
      DELETE FROM xx03_receivable_slips      xrs
      WHERE xrs.RECEIVABLE_ID = in_receivable_id;
--
    -- 保存以外の場合は論理削除を行う
    ELSE
      -- 仕訳伝票ヘッダレコード更新
      UPDATE xx03_receivable_slips           xrs
      SET    delete_flag = cn_delete_yes
      WHERE xrs.RECEIVABLE_ID = in_receivable_id;
    END IF;
--
    -- コミット発行
    COMMIT;
--
  EXCEPTION
--
    WHEN OTHERS THEN
      ROLLBACK;
      ov_errbuf  := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
--
  END del_receivable_data;
--
-- ver11.5.10.1.6D Add Start
  /**********************************************************************************
   * Procedure Name   : check_deptinput_ar_input
   * Description      : 部門入力(AR)のエラーチェック(画面用)
   ***********************************************************************************/
  PROCEDURE check_deptinput_ar_input(
    in_receivable_id IN   NUMBER,    -- 1.チェック対象請求書ID
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
    xx03_deptinput_ar_check_pkg.check_deptinput_ar(
      in_receivable_id,
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
      UPDATE xx03_receivable_slips xrs
      SET    xrs.request_enable_flag = 'W'
      WHERE  xrs.receivable_id = in_receivable_id;
    ELSE
      -- 警告以外の場合は申請可能フラグに'Y'セット
      UPDATE xx03_receivable_slips xrs
      SET    xrs.request_enable_flag = 'Y'
      WHERE  xrs.receivable_id = in_receivable_id;
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
  END check_deptinput_ar_input;
-- ver11.5.10.1.6D Add End
--
END xx03_deptinput_ar_check_pkg;
