create or replace PACKAGE BODY      xx03_deptinput_ar_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ar_check_pkg(body)
 * Description            : 部門入力(AR)において入力チェックを行う共通関数
 * MD.070                 : 部門入力(AR)共通関数 OCSJ/BFAFIN/MD070/F702
 * Version                : 11.5.10.2.26
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
 *  2010/01/14   11.5.10.2.11   障害「E_本稼動_01066」対応
 *  2010/02/16   11.5.10.2.12   障害「E_本稼動_01408」対応
 *  2010/11/22   11.5.10.2.13   障害「E_本稼動_05407」対応
 *  2010/12/24   11.5.10.2.14   障害「E_本稼動_02004」対応
 *  2011/11/29   11.5.10.2.15   障害「E_本稼動_07768」対応
 *  2012/01/10   11.5.10.2.16   障害「E_本稼動_08887」対応
 *  2012/03/27   11.5.10.2.17   障害「E_本稼動_09336」対応
 *  2013/09/19   11.5.10.2.18   障害「E_本稼動_10999」対応
 *  2014/03/06   11.5.10.2.19   障害「E_本稼動_11634」対応
 *  2016/12/01   11.5.10.2.20   障害「E_本稼動_13901」対応
 *  2018/02/07   11.5.10.2.21   障害 [E_本稼動_14663] 対応
 *  2019/10/25   11.5.10.2.22   障害 [E_本稼動_16009] 対応
 *  2021/04/28   11.5.10.2.23   障害 [E_本稼動_16026] 対応
 *  2021/12/20   11.5.10.2.24   障害 [E_本稼働_17678] 対応
 *  2022/03/29   11.5.10.2.25   [E_本稼動_17926]対応 部門入力の科目制限
 *  2022/11/01   11.5.10.2.26   [E_本稼動_19496]対応 グループ会社統合対応
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
--2021/04/28 Ver11.5.10.2.23 ADD START
    cv_dept_fin   CONSTANT VARCHAR2(4)   := '1011';
    cv_corp_def   CONSTANT VARCHAR2(6)   := '000000';
    cv_cust_def   CONSTANT VARCHAR2(9)   := '000000000';
    cv_yes        CONSTANT VARCHAR2(1)   := 'Y';
    cv_z          CONSTANT VARCHAR2(4)   := 'ZZZZ';
    cv_lookup_liabilities_code CONSTANT VARCHAR2(30) := 'XXCFO1_LIABILITIES_CODE';
--2021/04/28 Ver11.5.10.2.23 ADD END
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
-- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
    -- プロファイル名
    cv_profile_name_01    CONSTANT fnd_profile_options.profile_option_name%TYPE := 'ORG_ID';                        -- MO: 営業単位
    -- クイックコード
    cv_lookup_gyotai_chk3 CONSTANT fnd_lookup_values_vl.lookup_type%TYPE        := 'XXCFR1_TRANSTYPE_GYOTAI_CHK3';  -- フルVD消化
    cv_lookup_gyotai_chk4 CONSTANT fnd_lookup_values_vl.lookup_type%TYPE        := 'XXCFR1_TRANSTYPE_GYOTAI_CHK4';  -- フルVD消化、フルVD以外
    cv_enabled_flag_yes   CONSTANT VARCHAR2(1)  := 'Y';  -- 有効フラグ：有効
    -- 制御コード
    cv_no_exists_code     CONSTANT VARCHAR2(1)  := '0';  -- 該当しない
    cv_ok_exists_code     CONSTANT VARCHAR2(1)  := '1';  -- 該当する
--
-- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
-- ver 11.5.10.2.16 2012/01/10 Add Start [E_本稼動_08887]
    cv_ship_site_use_code CONSTANT VARCHAR2(7)  := 'SHIP_TO';  -- 出荷先
    cv_active_flag        CONSTANT VARCHAR2(1)  := 'A';        -- 有効フラグ：有効
-- ver 11.5.10.2.16 2012/01/10 Add End   [E_本稼動_08887]
--
    -- *** ローカル変数 ***
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1)    INDEX BY BINARY_INTEGER;    -- エラーフラグ用配列タイプ
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;    -- エラーメッセージ用配列タイプ
    errflg_tbl                errflg_tbl_type;
    errmsg_tbl                errmsg_tbl_type;
    ln_err_cnt                NUMBER := 0;         -- パラメータ添字用変数
    ln_books_id               NUMBER;              -- 帳簿ID
-- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
    ln_org_id                 NUMBER;              -- 営業単位ID
-- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
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
-- ver 11.5.10.2.12 Modify Start
    cn_if_line_attribute_length CONSTANT NUMBER := '30'; -- INTERFACE_LINE_ATTRIBUTE列桁数
-- ver 11.5.10.2.12 Modify End
--
-- ver 11.5.10.2.15 Add Start
    cn_percent_char        CONSTANT VARCHAR(1) := '%'; --%記号
-- ver 11.5.10.2.15 Add End
--2021/04/28 Ver11.5.10.2.23 ADD START
    ln_count               NUMBER       := 0;
--2021/04/28 Ver11.5.10.2.23 ADD END
-- Ver11.5.10.2.26 ADD START
    lv_fin_dept_code       VARCHAR2(4);            -- 財務経理部門コード
-- Ver11.5.10.2.26 ADD END
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
--2016/12/01 Ver11.5.10.2.20 ADD START
           , xrsjlv.attribute7            as attribute7                 -- attribute7(稟議決裁番号)
--2016/12/01 Ver11.5.10.2.20 ADD END
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
-- 2019/10/25 Ver11.5.10.2.22 ADD Start
      AND  rownum = 1
-- 2019/10/25 Ver11.5.10.2.22 ADD End
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
-- ver 11.5.10.2.11 Add Start
    --顧客業態チェックカーソル
    CURSOR xx03_gyotai_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   xx03_receivable_slips xrs
          ,ra_cust_trx_types_all rctta
    WHERE xrs.receivable_id = in_receivable_id
    AND   rctta.cust_trx_type_id = xrs.trans_type_id
    AND   (
           (rctta.attribute4 IS NOT NULL
            AND
            EXISTS (SELECT 'X' 
                    FROM xxcmm_cust_accounts xxca
                        ,fnd_lookup_values_vl flvv
                    WHERE xxca.customer_id = xrs.customer_id
                    AND   flvv.lookup_type = rctta.attribute4
                    AND   flvv.lookup_code = xxca.business_low_type
                    AND   flvv.enabled_flag = 'Y'
                    AND   SYSDATE BETWEEN NVL(flvv.start_date_active,SYSDATE) AND NVL(flvv.end_date_active,SYSDATE)))
           OR
           (rctta.attribute4 IS NULL));
--
    --顧客区分チェックカーソル
    CURSOR xx03_customer_class_cur
    IS
    SELECT COUNT(1) exist_check
    FROM xx03_receivable_slips xrs
        ,ra_cust_trx_types_all rctta
        ,hz_cust_accounts hzca
    WHERE xrs.receivable_id = in_receivable_id
    AND   rctta.cust_trx_type_id = xrs.trans_type_id
    AND   rctta.attribute7 = 'Y'
    AND   hzca.cust_account_id = xrs.customer_id
    AND   hzca.customer_class_code = '14';
-- ver 11.5.10.2.11 Add End
-- ver 11.5.10.2.16 2012/01/10 Add Start [E_本稼動_08887]
    --対象顧客チェックカーソル
    CURSOR xx03_cusomer_number_cur (
      in_org_id           IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id  IN  NUMBER  -- 会計帳簿ID
    ) IS
    SELECT /*+ LEADING(xrs)  */
           COUNT( 1 )                AS exist_check
    FROM   xx03_receivable_slips  xrs   -- AR部門入力ヘッダ
          ,ra_cust_trx_types_all  rctt  -- 取引タイプマスタ
    WHERE  xrs.receivable_id     =  in_receivable_id     -- 伝票ID（プロシージャの入力パラメータ）
    AND    xrs.org_id            =  in_org_id            -- 営業単位ID
    AND    xrs.set_of_books_id   =  in_set_of_books_id   -- 会計帳簿ID
    AND    rctt.cust_trx_type_id =  xrs.trans_type_id    -- 取引タイプID
    AND    rctt.org_id           =  xrs.org_id           -- 営業単位ID
    AND    rctt.set_of_books_id  =  xrs.set_of_books_id  -- 会計帳簿ID
    AND    (     rctt.attribute11 IS NULL  -- 顧客コードチェック用参照タイプが未設定
             OR  EXISTS( SELECT  'X'
                         FROM    fnd_lookup_values_vl   flvv  -- クイックコード
                                ,hz_cust_accounts       hca   -- 顧客マスタ
                                ,hz_cust_acct_sites_all hcas  -- 出荷先顧客サイト
                                ,hz_cust_site_uses_all  hcsu  -- 出荷先顧客使用目的
                                ,hz_cust_accounts       hcab  -- 請求先顧客
                                ,hz_cust_acct_sites_all hcasb -- 請求先顧客サイト
                                ,hz_cust_site_uses_all  hcsub -- 請求先顧客使用目的
                         WHERE   flvv.lookup_type        = rctt.attribute11     -- 顧客コードチェック用参照タイプ
                         AND     flvv.lookup_code        = hcab.account_number  -- 請求先顧客コード
                         AND     flvv.enabled_flag       = cv_enabled_flag_yes  -- 有効フラグ
                         AND     hca.cust_account_id     = xrs.customer_id      -- 納品先顧客ID
                         AND     hcas.cust_account_id    = hca.cust_account_id
                         AND     hcas.org_id             = in_org_id
                         AND     hcas.status             = cv_active_flag
                         AND     hcsu.cust_acct_site_id  = hcas.cust_acct_site_id
                         AND     hcsu.site_use_code      = cv_ship_site_use_code
                         AND     hcsu.status             = cv_active_flag
                         AND     hcsu.org_id             = in_org_id
                         AND     hcsub.site_use_id       = hcsu.bill_to_site_use_id
                         AND     hcsub.status            = cv_active_flag
                         AND     hcsub.org_id            = in_org_id
                         AND     hcasb.cust_acct_site_id = hcsub.cust_acct_site_id
                         AND     hcasb.status            = cv_active_flag
                         AND     hcasb.org_id            = in_org_id
                         AND     hcab.cust_account_id    = hcasb.cust_account_id
                         AND     TRUNC( SYSDATE )  BETWEEN NVL( flvv.start_date_active, TRUNC( SYSDATE ) )
                                                   AND     NVL( flvv.end_date_active  , TRUNC( SYSDATE ) )
                 )
           )
    ;
--
    --入力金額上限値チェックカーソル
    CURSOR xx03_limit_check_cur (
      in_org_id           IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id  IN  NUMBER  -- 会計帳簿ID
    ) IS
    SELECT /*+ LEADING(xrs)  */
           COUNT( 1 )      AS exist_check
    FROM   xx03_receivable_slips  xrs   -- AR部門入力ヘッダ
          ,ra_cust_trx_types_all  rctt  -- 取引タイプマスタ
    WHERE  xrs.receivable_id     =  in_receivable_id     -- 伝票ID（プロシージャの入力パラメータ）
    AND    xrs.org_id            =  in_org_id            -- 営業単位ID
    AND    xrs.set_of_books_id   =  in_set_of_books_id   -- 会計帳簿ID
    AND    rctt.cust_trx_type_id =  xrs.trans_type_id    -- 取引タイプID
    AND    rctt.org_id           =  xrs.org_id           -- 営業単位ID
    AND    rctt.set_of_books_id  =  xrs.set_of_books_id  -- 会計帳簿ID
    AND    (   rctt.attribute12  IS NULL                 -- 入力金額上限値が未設定
            OR ABS(xrs.inv_amount) <= TO_NUMBER(rctt.attribute12)   -- 入力金額上限値が税込金額より大きい場合はエラー 
           )
    ;
--
-- ver 11.5.10.2.16 2012/01/10 Add End   [E_本稼動_08887]
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
    -- ver 11.5.10.2.12 Modify Start
    --SELECT COUNT(1) exist_check
    SELECT xrs.slip_type
          ,rct.type
          ,rct.attribute5
    -- ver 11.5.10.2.12 Modify End
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
-- ver 11.5.10.2.11 Add Start
    -- 納品書番号チェックカーソル
    CURSOR xx03_receipt_line_no_chk_cur
    IS
      SELECT rctta.attribute6          AS attribute6,          -- 納品書番号チェック
             xrsl.slip_line_reciept_no AS slip_line_reciept_no -- 納品書番号
      FROM xx03_receivable_slips xrs,
           xx03_receivable_slips_line xrsl,
           ra_cust_trx_types_all rctta
      WHERE xrs.receivable_id = in_receivable_id
      AND   xrsl.receivable_id = xrs.receivable_id
      AND   rctta.cust_trx_type_id = xrs.trans_type_id
      AND   rctta.attribute6 IS NOT NULL;
--
    -- 取消対象伝票消し込みチェックカーソル
-- ver 11.5.10.2.17 Mod Start
--    CURSOR xx03_cancel_chk_cur
--    IS
--      SELECT xrs.orig_invoice_num                          AS orig_invoice_num,
    CURSOR xx03_cancel_chk_cur(
      iv_orig_invoice_num    IN VARCHAR2                 -- 修正元伝票番号
     ,iv_orig_invoice_num_s  IN VARCHAR2                 -- 修正元伝票番号(％つき）
    ) IS
      SELECT /*+ LEADING( rcta ) 
                 USE_NL( rcta xrs_orig acrv araa ) */
             xrs_orig.receivable_num                       AS orig_invoice_num,
-- ver 11.5.10.2.17 Mod End
             acrv.receipt_number                           AS receipt_number,
             acrv.payment_method_dsp                       AS payment_method_dsp,
             acrv.receipt_date                             AS receipt_date,
             acrv.customer_number||':'||acrv.customer_name AS customer,
             acrv.amount                                   AS amount,
             acrv.document_number                          AS document_number
-- ver 11.5.10.2.17 Mod Start
--      FROM xx03_receivable_slips xrs
--          ,ra_customer_trx_all rcta
      FROM ra_customer_trx_all rcta
-- ver 11.5.10.2.17 Mod End
          ,ar_receivable_applications_all araa
          ,ar_cash_receipts_v acrv
-- ver 11.5.10.2.15 Add Start
          ,xx03_receivable_slips xrs_orig
-- ver 11.5.10.2.17 Mod Start
---- ver 11.5.10.2.15 Add ENd
--      WHERE xrs.receivable_id = in_receivable_id
---- ver 11.5.10.2.15 Mod Start
----      AND   rcta.trx_number = xrs.orig_invoice_num
--      AND   rcta.trx_number LIKE xrs.orig_invoice_num || cn_percent_char
---- ver 11.5.10.2.15 Mod End
      WHERE 
            rcta.trx_number LIKE iv_orig_invoice_num_s
-- ver 11.5.10.2.17 Mod END
      AND   rcta.org_id = FND_PROFILE.VALUE('ORG_ID')
      AND   rcta.set_of_books_id = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
      AND   araa.applied_customer_trx_id = rcta.customer_trx_id
      AND   araa.set_of_books_id = rcta.set_of_books_id
      AND   araa.org_id = rcta.org_id
      AND   araa.display = 'Y'
-- ver 11.5.10.2.15 Mod Start
--      AND   acrv.cash_receipt_id = araa.cash_receipt_id;
      AND   acrv.cash_receipt_id   = araa.cash_receipt_id
-- ver 11.5.10.2.17 Mod Start
--      AND   xrs_orig.receivable_num = xrs.orig_invoice_num
      AND   xrs_orig.receivable_num = iv_orig_invoice_num
-- ver 11.5.10.2.17 Mod End
      AND   rcta.cust_trx_type_id  = xrs_orig.trans_type_id
      ;
-- ver 11.5.10.2.15 Mod End
--
    --勘定科目チェックカーソル
    CURSOR xx03_account_chk_cur
    IS
    SELECT xrsl.line_number
    FROM   xx03_receivable_slips xrs
          ,xx03_receivable_slips_line xrsl
          ,ra_cust_trx_types_all rctta
    WHERE xrs.receivable_id = in_receivable_id
    AND   xrsl.receivable_id = xrs.receivable_id
    AND   rctta.cust_trx_type_id = xrs.trans_type_id
    AND   rctta.attribute8 IS NOT NULL
    AND   NOT EXISTS (SELECT 'X' 
                      FROM fnd_lookup_values_vl flvv
                      WHERE flvv.lookup_type = rctta.attribute8
                      AND   flvv.lookup_code = xrsl.segment3
                      AND   flvv.enabled_flag = 'Y'
                      AND   SYSDATE BETWEEN NVL(flvv.start_date_active,SYSDATE) AND NVL(flvv.end_date_active,SYSDATE));
-- ver 11.5.10.2.11 Add Start
--
-- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
  -- 支払条件チェックカーソル(入金時値引を登録する際には、即時(00_00_00)以外認めない)
  CURSOR  xx03_terms_name_chk_cur(
      in_org_id           IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id  IN  NUMBER  -- 会計帳簿ID
  )
  IS
    SELECT COUNT( 1 )  AS exist_check
    FROM   xx03_receivable_slips xrs   -- AR部門入力ヘッダ
          ,ra_cust_trx_types_all rctt  -- 取引タイプマスタ
    WHERE  xrs.receivable_id     =  in_receivable_id     -- 伝票ID（プロシージャの入力パラメータ）
    AND    xrs.org_id            =  in_org_id            -- 営業単位ID
    AND    xrs.set_of_books_id   =  in_set_of_books_id   -- 会計帳簿ID
    AND    rctt.cust_trx_type_id =  xrs.trans_type_id    -- 取引タイプID
    AND    rctt.org_id           =  xrs.org_id           -- 営業単位ID
    AND    rctt.set_of_books_id  =  xrs.set_of_books_id  -- 会計帳簿ID
    AND    (     rctt.attribute9 IS NULL  -- 支払条件参照タイプチェック用が未設定
             OR  EXISTS( SELECT  'X'
                         FROM    fnd_lookup_values_vl  flvv  -- クイックコード
                         WHERE   flvv.lookup_type  =  rctt.attribute9      -- 支払条件参照タイプチェック用
                         AND     flvv.lookup_code  =  xrs.terms_name       -- 支払条件名称
                         AND     flvv.enabled_flag =  cv_enabled_flag_yes  -- 有効フラグ
                         AND     TRUNC( SYSDATE )  BETWEEN NVL( flvv.start_date_active, TRUNC( SYSDATE ) )
                                                   AND     NVL( flvv.end_date_active  , TRUNC( SYSDATE ) )
                         AND     ROWNUM = 1
                 )
           )
  ;
--
  -- 入金時値引の対象顧客チェックカーソル(入金時値引を登録する際には、顧客に値引率が登録されていること)
  CURSOR  xx03_customer_chk_cur(
      in_org_id          IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id IN  NUMBER  -- 会計帳簿ID
  )
  IS
    SELECT xca.receiv_discount_rate     AS receiv_discount_rate -- 入金値引率
          ,xca.contractor_supplier_code AS bm1_code             -- 契約者仕入先CD
          ,xca.bm_pay_supplier_code1    AS bm2_code             -- 紹介者BM支払仕入先CD1
          ,xca.bm_pay_supplier_code2    AS bm3_code             -- 紹介者BM支払仕入先CD2
          ,DECODE(rctt.attribute4        -- 業態チェック用参照タイプ
                 ,cv_lookup_gyotai_chk3  -- クイックコード：AR部門入力業態チェック(入金時値引訂正_フルVD(消化))
                 ,cv_ok_exists_code      -- '1'(フルVD消化の意味)
                 ,cv_no_exists_code      -- '0'
           )                            AS exists_fvd_s         -- フルVD消化
          ,DECODE(rctt.attribute4        -- 業態チェック用参照タイプ
                 ,cv_lookup_gyotai_chk4  -- クイックコード：AR部門入力業態チェック(入金時値引訂正_その他)
                 ,cv_ok_exists_code      -- '1'(フルVD消化、フルVD以外の意味)
                 ,cv_no_exists_code      -- '0'
           )                            AS exists_else          -- フルVD消化、フルVD以外
    FROM   xx03_receivable_slips xrs   -- AR部門入力ヘッダ
          ,xxcmm_cust_accounts   xca   -- 顧客追加情報
          ,ra_cust_trx_types_all rctt  -- 取引タイプマスタ
    WHERE  xrs.receivable_id    = in_receivable_id        -- 伝票ID（プロシージャの入力パラメータ）
    AND    xrs.customer_id      = xca.customer_id         -- 内部ID
    AND    xrs.trans_type_id    = rctt.cust_trx_type_id   -- 内部ID
    AND    xrs.org_id           = in_org_id               -- 営業単位ID
    AND    xrs.set_of_books_id  = in_set_of_books_id      -- 会計帳簿ID
    AND    rctt.attribute4    IN( cv_lookup_gyotai_chk3   -- クイックコード：AR部門入力業態チェック(入金時値引訂正_フルVD(消化))
                                , cv_lookup_gyotai_chk4   -- クイックコード：AR部門入力業態チェック(入金時値引訂正_その他)
                              )
    ;
-- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
--
-- ver 11.5.10.2.12 Modify Start
    -- 文字列バイトチェック
    CURSOR xx03_length_chk_cur
    IS
    SELECT xrsl.line_number
          ,xrsl.slip_line_reciept_no
          ,xrsl.slip_description
    FROM   xx03_receivable_slips xrs
          ,xx03_receivable_slips_line xrsl
    WHERE xrs.receivable_id = in_receivable_id
    AND   xrsl.receivable_id = xrs.receivable_id
    AND   (LENGTHB(xrsl.slip_line_reciept_no) > cn_if_line_attribute_length OR
           LENGTHB(xrsl.slip_description) > cn_if_line_attribute_length)
    ORDER BY xrsl.line_number;
-- ver 11.5.10.2.12 Modify Emd
--
-- ver 11.5.10.2.14 2010/12/24 Add Start [E_本稼動_02004]
    -- 顧客売上拠点チェックカーソル
    CURSOR xx03_sale_base_cur(
      in_org_id          IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id IN  NUMBER  -- 会計帳簿ID
    )
    IS
    SELECT CASE WHEN TRUNC(xrs.gl_date,'MM') <  TRUNC(SYSDATE    ,'MM')
                THEN NULL
                ELSE xca.sale_base_code
           END                AS sale_base_code       -- 売上拠点
          ,CASE WHEN TRUNC(xrs.gl_date,'MM') <  TRUNC(SYSDATE    ,'MM')
                THEN xca.past_sale_base_code
                ELSE NULL
           END                AS past_sale_base_code  -- 前月売上拠点
          ,xrl.segment2       AS segment2             -- AFF部門(収益)
          ,xrl.line_number    AS line_number          -- 明細番号
    FROM   xx03_receivable_slips      xrs   -- AR部門入力ヘッダ
          ,xx03_receivable_slips_line xrl   -- AR部門入力明細
          ,xxcmm_cust_accounts        xca   -- 顧客追加情報
          ,ra_cust_trx_types_all      rctt  -- 取引タイプマスタ
    WHERE xrs.receivable_id    = in_receivable_id       -- 内部ID
    AND   xrs.receivable_id    = xrl.receivable_id      -- 内部ID
    AND   xrs.customer_id      = xca.customer_id        -- 顧客内部ID
    AND   xrs.trans_type_id    = rctt.cust_trx_type_id  -- 取引タイプID
    AND   xrs.org_id           = in_org_id              -- 営業単位ID
    AND   xrs.set_of_books_id  = in_set_of_books_id     -- 会計帳簿ID
    AND   rctt.org_id          = in_org_id              -- 営業単位ID
    AND   rctt.set_of_books_id = in_set_of_books_id     -- 会計帳簿ID
    AND   NVL(rctt.attribute10,'N') = 'Y'               -- 売上拠点チェック
    AND   xrl.segment2        <> ( CASE WHEN TRUNC(xrs.gl_date,'MM') < TRUNC(SYSDATE    ,'MM')
                                        THEN xca.past_sale_base_code  -- 売上拠点(収益) <> 顧客の前月売上拠点
                                        ELSE xca.sale_base_code       -- 売上拠点(収益) <> 顧客の売上拠点
                                   END
                                 )
    ORDER BY xrl.line_number ASC
    ;
-- ver 11.5.10.2.14 2010/12/24 Add End   [E_本稼動_02004]
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
-- 2013/09/19 ver 11.5.10.2.18 ADD START
    -- 項目整合性チェックカーソル
    CURSOR xx03_save_code_chk_cur(
      in_org_id          IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id IN  NUMBER  -- 会計帳簿ID
    )
    IS
      SELECT /*+ LEADING(xrs xrsl) */
             COUNT(1)                AS exist_check
      FROM   xx03_receivable_slips      xrs  -- AR部門入力ヘッダ
           , xx03_receivable_slips_line xrsl -- AR部門入力明細
      WHERE  xrs.receivable_id    = in_receivable_id   -- 伝票ID（プロシージャの入力パラメータ）
      AND    xrs.org_id           = in_org_id          -- 営業単位ID
      AND    xrs.set_of_books_id  = in_set_of_books_id -- 会計帳簿ID
      AND    xrs.receivable_id    = xrsl.receivable_id -- 伝票ID
      AND (
           ( SUBSTRB( xrs.requestor_person_name, 1, 5 ) <> ( SELECT papf.employee_number  AS employee_number -- 申請者名
                                                             FROM   per_all_people_f      papf
                                                             WHERE  papf.person_id = xrs.requestor_person_id
                                                             AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                   AND     papf.effective_end_date ) )
        OR ( SUBSTRB( xrs.approver_person_name, 1, 5 )  <> ( SELECT papf.employee_number  AS employee_number -- 承認者名
                                                             FROM   per_all_people_f      papf
                                                             WHERE  papf.person_id = xrs.approver_person_id
                                                             AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                   AND     papf.effective_end_date ) )
        OR ( xrs.trans_type_name                        <> ( SELECT rctt.name             AS name            -- 取引タイプ名
                                                             FROM   ra_cust_trx_types_all rctt
                                                             WHERE  rctt.cust_trx_type_id = xrs.trans_type_id
                                                             AND    rctt.org_id           = xrs.org_id ) )
        OR ( SUBSTRB( xrs.customer_name, 1, 9 )         <> ( SELECT hca.account_number    AS account_number  -- 顧客名
                                                             FROM   hz_cust_accounts      hca
                                                             WHERE  hca.cust_account_id = xrs.customer_id ) )
        OR ( ( SELECT SUBSTRB( xrs.customer_office_name, 1, LENGTHB(hcsua.location) ) AS customer_office_name
               FROM   hz_cust_site_uses_all                                           hcsua
               WHERE  hcsua.status            = 'A'
               AND    hcsua.site_use_code     = 'BILL_TO'
               AND    hcsua.org_id            = xrs.org_id
               AND    hcsua.cust_acct_site_id = xrs.customer_office_id )
                                                        <> ( SELECT hcsua.location        AS location        -- 顧客事業所名
                                                             FROM   hz_cust_site_uses_all hcsua
                                                             WHERE  hcsua.status            = 'A'
                                                             AND    hcsua.site_use_code     = 'BILL_TO'
                                                             AND    hcsua.org_id            = xrs.org_id
                                                             AND    hcsua.cust_acct_site_id = xrs.customer_office_id ) )
        OR ( ( xrs.receipt_method_id IS NULL )     AND ( xrs.receipt_method_name IS NOT NULL ) )             -- 支払方法名
        OR ( ( xrs.receipt_method_id IS NOT NULL ) AND ( xrs.receipt_method_name IS NULL ) )                 -- 支払方法名
        OR ( xrs.receipt_method_name                    <> ( SELECT arm.name              AS name            -- 支払方法名
                                                             FROM   ar_receipt_methods    arm
                                                             WHERE  arm.receipt_method_id = xrs.receipt_method_id ) )
        OR ( xrs.terms_name                             <> ( SELECT rtt.name              AS name            -- 支払条件名
                                                             FROM   ra_terms_tl           rtt
                                                                  , ra_terms_b            rtb
                                                             WHERE  rtt.term_id  = rtb.term_id
                                                             AND    rtt.LANGUAGE = USERENV('LANG')
                                                             AND    xrs.invoice_date BETWEEN rtb.start_date_active
                                                                                     AND NVL( rtb.end_date_active, TO_DATE('4712/12/31','YYYY/MM/DD') )
                                                             AND    rtt.term_id  = xrs.terms_id ) )
-- 2014/03/06 ver 11.5.10.2.19 DEL START
--        OR (  ( xrsl.slip_line_type IS NOT NULL )
--          AND ( xrsl.slip_line_type_name                <> ( SELECT amlat.name            AS name            -- 請求内容
--                                                             FROM   ar_memo_lines_all_tl  amlat
--                                                                  , ar_memo_lines_all_b   amlab
--                                                             WHERE  amlat.memo_line_id    = amlab.memo_line_id
--                                                             AND    amlat.org_id          = amlab.org_id
--                                                             AND    amlat.language        = USERENV('LANG')
--                                                             AND    xrs.invoice_date BETWEEN amlab.start_date
--                                                                                     AND     NVL( amlab.end_date, TO_DATE('4712/12/31','YYYY/MM/DD') )
--                                                             AND    amlab.org_id          = xrs.org_id
--                                                             AND    amlab.set_of_books_id = xrs.set_of_books_id
--                                                             AND    amlab.memo_line_id    = xrsl.slip_line_type ) ) )
-- 2014/03/06 ver 11.5.10.2.19 DEL END
        OR ( xrsl.tax_code <> SUBSTRB( xrsl.tax_name, 1, LENGTHB(xrsl.tax_code) ) )                          -- 税区分名
        OR ( xrsl.segment1 <> SUBSTRB( xrsl.segment1_name, 1, LENGTHB(xrsl.segment1) ) )                     -- AFF 会社
        OR ( xrsl.segment2 <> SUBSTRB( xrsl.segment2_name, 1, LENGTHB(xrsl.segment2) ) )                     -- AFF 部門
        OR ( xrsl.segment3 <> SUBSTRB( xrsl.segment3_name, 1, LENGTHB(xrsl.segment3) ) )                     -- AFF 勘定科目
        OR ( xrsl.segment4 <> SUBSTRB( xrsl.segment4_name, 1, LENGTHB(xrsl.segment4) ) )                     -- AFF 補助科目
        OR ( xrsl.segment5 <> SUBSTRB( xrsl.segment5_name, 1, LENGTHB(xrsl.segment5) ) )                     -- AFF 顧客
        OR ( xrsl.segment6 <> SUBSTRB( xrsl.segment6_name, 1, LENGTHB(xrsl.segment6) ) )                     -- AFF 企業
        OR ( xrsl.segment7 <> SUBSTRB( xrsl.segment7_name, 1, LENGTHB(xrsl.segment7) ) )                     -- AFF 予備１
        OR ( xrsl.segment8 <> SUBSTRB( xrsl.segment8_name, 1, LENGTHB(xrsl.segment8) ) )                     -- AFF 予備２
          )
      ;
-- 2013/09/19 ver 11.5.10.2.18 ADD END
-- ver 11.5.10.2.24 Add Start
    -- 支払案内書電子データ受領チェック
    CURSOR xx03_payment_ele_data_cur
    IS
      SELECT xrs.request_date         AS request_date
            ,xrs.orig_invoice_num     AS orig_invoice_num
            ,xrs.payment_ele_data_yes AS payment_ele_data_yes
            ,xrs.payment_ele_data_no  AS payment_ele_data_no
      FROM   xx03_receivable_slips      xrs
      WHERE  xrs.receivable_id = in_receivable_id
    ;
-- ver 11.5.10.2.24 Add End
--
-- Ver11.5.10.2.26 ADD START
    -- 伝票作成会社の有効チェック
    CURSOR xx03_drafting_company_cur
    IS
      SELECT xrs.gl_date                       AS gl_date              -- 計上日
            ,NVL(xrs.drafting_company, '001')  AS drafting_company     -- 伝票作成会社
             -- 会社コード変換
            ,xxcfr_common_pkg.conv_company_code(
               NVL(xrs.drafting_company, '001')
              ,xrs.gl_date
             )                                 AS drafting_company_bd  -- 計上日時点の伝票作成会社
      FROM   xx03_receivable_slips  xrs
      WHERE  xrs.receivable_id = in_receivable_id
    ;
--
    -- 伝票作成会社と明細会社の整合性チェック
    CURSOR xx03_drafting_company_2_cur(
      in_line_number  IN NUMBER    -- 1.明細番号
    )
    IS
      SELECT xrsl.line_number         AS line_number          -- 明細番号
            ,NVL(
               xrs.drafting_company
              ,'001'
             )                        AS drafting_company     -- 伝票作成会社
            ,DECODE(
               xrsl.segment1
              ,'999'
              ,'001'  -- 相良会計(999)は伊藤園(001)に置換
              ,xrsl.segment1
             )                        AS segment1             -- 明細の会社
      FROM   xx03_receivable_slips      xrs
            ,xx03_receivable_slips_line xrsl
      WHERE  xrs.receivable_id   = xrsl.receivable_id
      AND    xrs.receivable_id   = in_receivable_id
      AND    xrsl.line_number    = in_line_number
    ;
-- Ver11.5.10.2.26 ADD END
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
-- ver 11.5.10.2.11 Add Start
    --顧客業態チェックカーソルレコード型
    xx03_gyotai_rec              xx03_gyotai_cur%ROWTYPE;
    -- 取消対象伝票消し込みチェックカーソルレコード型
    xx03_cancel_chk_rec          xx03_cancel_chk_cur%ROWTYPE;
    -- 納品書番号チェックカーソル
    xx03_receipt_line_no_chk_rec xx03_receipt_line_no_chk_cur%ROWTYPE;
    -- 顧客区分チェックカーソル
    xx03_customer_class_rec xx03_customer_class_cur%ROWTYPE;
    -- 勘定科目チェックカーソル
    xx03_account_chk_rec xx03_account_chk_cur%ROWTYPE;
-- ver 11.5.10.2.11 Add End
-- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
    -- 支払条件チェックカーソルレコード型
    xx03_terms_name_chk_rec      xx03_terms_name_chk_cur%ROWTYPE;
    -- 入金時値引の対象顧客チェックカーソルレコード型
    xx03_customer_chk_rec        xx03_customer_chk_cur%ROWTYPE;
-- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
-- ver 11.5.10.2.14 2010/12/13 Add Start [E_本稼動_02004]
    xx03_sale_base_rec           xx03_sale_base_cur%ROWTYPE;
-- ver 11.5.10.2.14 2010/12/13 Add End   [E_本稼動_02004]
-- ver 11.5.10.2.16 2012/01/10 Add Start [E_本稼動_08887]
    -- 対象顧客チェックカーソルレコード型
    xx03_cusomer_number_rec      xx03_cusomer_number_cur%ROWTYPE;
    -- 入力金額上限値チェックカーソルレコード型
    xx03_limit_check_rec     xx03_limit_check_cur%ROWTYPE;
-- ver 11.5.10.2.16 2012/01/10 Add End   [E_本稼動_08887]
-- ver 11.5.10.2.12 Modify Start
    -- 文字列バイトチェックレコード型
    xx03_length_chk_rec xx03_length_chk_cur%ROWTYPE;
-- ver 11.5.10.2.12 Modify End
-- 2013/09/19 ver 11.5.10.2.18 ADD START
    -- 項目整合性チェックカーソルレコード型
    xx03_save_code_chk_rec       xx03_save_code_chk_cur%ROWTYPE;
-- 2013/09/19 ver 11.5.10.2.18 ADD END
-- ver 11.5.10.2.24 Add Start
    xx03_payment_ele_data_rec    xx03_payment_ele_data_cur%ROWTYPE;
-- ver 11.5.10.2.24 Add End
-- Ver11.5.10.2.26 ADD START
    xx03_drafting_company_rec    xx03_drafting_company_cur%ROWTYPE;
    xx03_drafting_company_2_rec  xx03_drafting_company_2_cur%ROWTYPE;
-- Ver11.5.10.2.26 ADD END
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
-- ver 11.5.10.2.11 Add Start
    lv_line_rpt_no_chk1  CONSTANT VARCHAR2(1) := '1';                   -- 納品書番号チェック(必須のみチェック)
    lv_line_rpt_no_chk2  CONSTANT VARCHAR2(1) := '2';                   -- 納品書番号チェック(必須＋フォーマットチェック)
    lv_line_rpt_no_chk3  CONSTANT VARCHAR2(1) := '3';                   -- 納品書番号チェック(フォーマットチェックのみ)
    lv_line_rpt_no_rule1 CONSTANT VARCHAR2(1) := 'I';                   -- 納品書番号先頭文字列 
-- ver 11.5.10.2.11 Add End
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
-- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
    -- MO: 営業単位 取得
    ln_org_id := TO_NUMBER( xx00_profile_pkg.value( 'ORG_ID' ) );
-- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
--
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
-- ver 11.5.10.2.11 Add Start
        --顧客業態チェック
        OPEN xx03_gyotai_cur;
        FETCH xx03_gyotai_cur INTO xx03_gyotai_rec;
        IF xx03_gyotai_rec.exist_check = 0 THEN
          -- 顧客チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR', 'APP-XXCFR1-00090');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_gyotai_cur;
--
        --顧客区分チェック
        OPEN xx03_customer_class_cur;
        FETCH xx03_customer_class_cur INTO xx03_customer_class_rec;
        IF xx03_customer_class_rec.exist_check <> 0 THEN
          -- 顧客区分チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR', 'APP-XXCFR1-00091');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_customer_class_cur;
-- ver 11.5.10.2.11 Add End
-- ver 11.5.10.2.16 2012/01/10 Add Start [E_本稼動_08887]
        --対象顧客チェック
        OPEN  xx03_cusomer_number_cur(
                 in_org_id          => ln_org_id    -- 営業単位ID
               , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
              );
        FETCH xx03_cusomer_number_cur INTO xx03_cusomer_number_rec;
        IF xx03_cusomer_number_rec.exist_check = 0 THEN
          -- 対象顧客チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR', 'APP-XXCFR1-00144');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_cusomer_number_cur;
-- ver 11.5.10.2.16 2012/01/10 Add End   [E_本稼動_08887]
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
-- ver 11.5.10.2.17 Add Start
        -- 修正元伝票番号入力時のみチェックする
        IF lv_chk_orig_invoice_num is not NULL THEN
-- ver 11.5.10.2.17 Add End
  -- ver 11.5.10.2.11 Add Start
          --取消伝票消し込みチェック
  -- ver 11.5.10.2.17 Mod Start
  --        OPEN xx03_cancel_chk_cur;
          OPEN xx03_cancel_chk_cur(
                 lv_chk_orig_invoice_num                         -- 修正元伝票番号
                ,lv_chk_orig_invoice_num || cn_percent_char      -- 修正元伝票番号(%記号つき)
               );
  -- ver 11.5.10.2.17 Mod End
          FETCH xx03_cancel_chk_cur INTO xx03_cancel_chk_rec;
          IF xx03_cancel_chk_cur%FOUND THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR',
                                                               'APP-XXCFR1-00088',
                                                               'TRX_NUMBER',
                                                               xx03_cancel_chk_rec.orig_invoice_num,
                                                               'RECEIPT_NUMBER',
                                                               xx03_cancel_chk_rec.receipt_number,
                                                               'PAYMENT_METHOD_DSP',
                                                               xx03_cancel_chk_rec.payment_method_dsp,
                                                               'RECEIPT_DATE',
                                                               xx03_cancel_chk_rec.receipt_date,
                                                               'CUSTOMER',
                                                               xx03_cancel_chk_rec.customer,
                                                               'AMOUNT',
                                                               xx03_cancel_chk_rec.amount,
                                                               'DOCUMENT_NUMBER',
                                                               xx03_cancel_chk_rec.document_number);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
          CLOSE xx03_cancel_chk_cur;
-- ver 11.5.10.2.17 Add Start
        END IF;
-- ver 11.5.10.2.17 Add End
--
        -- 勘定科目チェック
        OPEN xx03_account_chk_cur;
        <<account_chk_loop>>
        LOOP
          FETCH xx03_account_chk_cur INTO xx03_account_chk_rec;
          EXIT WHEN xx03_account_chk_cur%NOTFOUND;
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR',
                                                             'APP-XXCFR1-00092',
                                                             'LINE_NUMBER',
                                                             xx03_account_chk_rec.line_number);
          ln_err_cnt := ln_err_cnt + 1;
        END LOOP account_chk_loop;
        CLOSE xx03_account_chk_cur;
--
        -- 納品書番号フォーマットチェック
        OPEN xx03_receipt_line_no_chk_cur;
        <<receipt_line_no_chk_loop>>
        LOOP 
          FETCH xx03_receipt_line_no_chk_cur INTO xx03_receipt_line_no_chk_rec;
          EXIT WHEN xx03_receipt_line_no_chk_cur%NOTFOUND;
          -- 納品書番号 必須チェックのみの場合
          IF  (xx03_receipt_line_no_chk_rec.attribute6 IN (lv_line_rpt_no_chk1,lv_line_rpt_no_chk2))
          AND (xx03_receipt_line_no_chk_rec.slip_line_reciept_no IS NULL) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR','APP-XXCFR1-00089');
            ln_err_cnt := ln_err_cnt + 1;
            EXIT;
          END IF;
          -- 納品書番号 必須＋フォーマットチェックの場合
          IF  (xx03_receipt_line_no_chk_rec.attribute6 IN (lv_line_rpt_no_chk2,lv_line_rpt_no_chk3))
          AND (xx03_receipt_line_no_chk_rec.slip_line_reciept_no IS NOT NULL) THEN
            DECLARE
              ln_slip_line_receipt_no NUMBER;
            BEGIN
              IF SUBSTRB(xx03_receipt_line_no_chk_rec.slip_line_reciept_no,1,1) = lv_line_rpt_no_rule1 THEN
                ln_slip_line_receipt_no := TO_NUMBER(SUBSTRB(xx03_receipt_line_no_chk_rec.slip_line_reciept_no,2));
              ELSE
                ln_slip_line_receipt_no := TO_NUMBER(xx03_receipt_line_no_chk_rec.slip_line_reciept_no);
              END IF;
            EXCEPTION
              WHEN INVALID_NUMBER OR VALUE_ERROR THEN
                errflg_tbl(ln_err_cnt) := 'E';
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR','APP-XXCFR1-00089');
                ln_err_cnt := ln_err_cnt + 1;
                EXIT;
            END;
          END IF;
        END LOOP receipt_line_no_chk_loop;
        CLOSE xx03_receipt_line_no_chk_cur;
-- ver 11.5.10.2.11 Add End
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
          -- ver 11.5.10.2.12 Modify Start
          --IF xx03_trans_type_name_rec.exist_check = 0 THEN
          IF xx03_trans_type_name_cur%NOTFOUND THEN
          -- ver 11.5.10.2.12 Modify End
            -- 取引タイプチェックエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13060','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          -- ver 11.5.10.2.12 Add Start
          ELSIF (xx03_trans_type_name_rec.type = 'INV')
            AND (   (xx03_trans_type_name_rec.attribute5 IS NULL)
                 OR (xx03_trans_type_name_rec.attribute5 <> xx03_trans_type_name_rec.slip_type))
          THEN
            -- 取引タイプチェックエラー
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13060','SLIP_NUM','');
            ln_err_cnt := ln_err_cnt + 1;
          -- ver 11.5.10.2.12 Add End
          END IF;
          CLOSE xx03_trans_type_name_cur;
-- ver 11.5.10.1.6G Add Start
        END IF;
-- ver 11.5.10.1.6G Add End
--
-- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
        -- 支払条件チェック
        OPEN xx03_terms_name_chk_cur(
                 in_org_id          => ln_org_id    -- 営業単位ID
               , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
             );
        FETCH xx03_terms_name_chk_cur INTO xx03_terms_name_chk_rec;
        IF ( xx03_terms_name_chk_rec.exist_check = 0 ) THEN
          -- 支払条件チェックエラー
          errflg_tbl( ln_err_cnt ) := 'E';
          errmsg_tbl( ln_err_cnt ) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-13064','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_terms_name_chk_cur;
--
        -- 入金時値引の対象顧客チェック
        OPEN xx03_customer_chk_cur(
                 in_org_id          => ln_org_id    -- 営業単位ID
               , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
             );
        FETCH xx03_customer_chk_cur INTO xx03_customer_chk_rec;
--
        -- 入金時値引の取引タイプであるときは顧客をチェックする
        IF ( xx03_customer_chk_cur%FOUND ) THEN
--
          -- 顧客がフルVD消化のとき
          IF    ( xx03_customer_chk_rec.exists_fvd_s = cv_ok_exists_code ) THEN
--
            -- 仕入先CDが一つも設定されていないときはメッセージ出力
            IF ( ( xx03_customer_chk_rec.bm1_code IS NULL )  -- 契約者仕入先CD
             AND ( xx03_customer_chk_rec.bm2_code IS NULL )  -- 紹介者BM支払仕入先CD1
             AND ( xx03_customer_chk_rec.bm3_code IS NULL )  -- 紹介者BM支払仕入先CD2
            ) THEN
              -- 入金時値引が計算不可の為、エラー
              errflg_tbl( ln_err_cnt ) := 'E';
              errmsg_tbl( ln_err_cnt ) := xx00_message_pkg.get_msg('XXCFR','APP-XXCFR1-00129');
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
          -- 顧客がフルVD消化、フルVD以外のとき
          ELSIF ( xx03_customer_chk_rec.exists_else = cv_ok_exists_code ) THEN
--
            -- 入金値引率が0以下もしくは設定されていないときはメッセージ出力
            IF ( ( xx03_customer_chk_rec.receiv_discount_rate IS NULL )  -- 入金値引率
              OR ( xx03_customer_chk_rec.receiv_discount_rate <= 0    )  -- 入金値引率
            ) THEN
              -- 入金時値引が計算不可の為、エラー
              errflg_tbl( ln_err_cnt ) := 'E';
              errmsg_tbl( ln_err_cnt ) := xx00_message_pkg.get_msg('XXCFR','APP-XXCFR1-00129');
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
--
          -- フルVDの時はチェックしない
          ELSE
            NULL;
          END IF;  -- 業態分岐
--
        END IF;  -- カーソル取得分岐
        CLOSE xx03_customer_chk_cur;
-- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
--
-- ver 11.5.10.2.16 2012/01/10 Add Start [E_本稼動_08887]
        --入力金額上限値チェック
        OPEN  xx03_limit_check_cur(
                 in_org_id          => ln_org_id    -- 営業単位ID
               , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
              );
        FETCH xx03_limit_check_cur INTO xx03_limit_check_rec;
        IF xx03_limit_check_rec.exist_check = 0 THEN
          -- 入力金額上限値チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR', 'APP-XXCFR1-00145');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_limit_check_cur;
--
-- ver 11.5.10.2.16 2012/01/10 Add End   [E_本稼動_08887]
-- ver 11.5.10.2.12 Modify Start
        -- 文字列バイトチェック(納品書番号、請求明細備考)
        OPEN  xx03_length_chk_cur;
        <<length_chk_loop>>
        LOOP
          FETCH xx03_length_chk_cur INTO xx03_length_chk_rec;
          EXIT WHEN xx03_length_chk_cur%NOTFOUND;
          IF xx03_length_chk_cur%FOUND THEN
            IF LENGTHB(xx03_length_chk_rec.slip_line_reciept_no) > cn_if_line_attribute_length THEN
              -- 納品書番号バイトチェックエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR',
                                                                 'APP-XXCFR1-00093',
                                                                 'LINE_NUM',
                                                                 xx03_length_chk_rec.line_number,
                                                                 'ITEM_NAME',
                                                                 '納品書番号',
                                                                 'BYTE',
                                                                 TO_CHAR(cn_if_line_attribute_length));
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            IF LENGTHB(xx03_length_chk_rec.slip_description) > cn_if_line_attribute_length THEN
              -- 請求明細備考バイトチェックエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR',
                                                                 'APP-XXCFR1-00093',
                                                                 'LINE_NUM',
                                                                 xx03_length_chk_rec.line_number,
                                                                 'ITEM_NAME',
                                                                 '備考(請求明細)',
                                                                 'BYTE',
                                                                 TO_CHAR(cn_if_line_attribute_length));
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
          END IF;
        END LOOP length_chk_loop;
        CLOSE xx03_length_chk_cur;
-- ver 11.5.10.2.12 Modify End
--
-- ver 11.5.10.2.14 2010/12/24 Add Start [E_本稼動_02004]
--
        -- 初期化
        xx03_sale_base_rec := NULL;
        --収益勘定(部門)チェック
        OPEN xx03_sale_base_cur(
                 in_org_id          => ln_org_id    -- 営業単位ID
               , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
             );
        <<sale_base_loop>>
        LOOP
          FETCH xx03_sale_base_cur INTO xx03_sale_base_rec;
          EXIT WHEN xx03_sale_base_cur%NOTFOUND;
          -- 収益勘定(部門)チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          IF ( xx03_sale_base_rec.sale_base_code IS NULL ) THEN  -- 売上拠点がNULLの場合
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR',
                                                               'APP-XXCFR1-00131',  -- 前月売上拠点を出力
                                                               'PAST_SALE_BASE_CODE',
                                                               xx03_sale_base_rec.past_sale_base_code,
                                                               'DEPARTMENT_CODE',
                                                               xx03_sale_base_rec.segment2,
                                                               'LINE_NUMBER',
                                                               xx03_sale_base_rec.line_number);
          ELSE
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR',
                                                               'APP-XXCFR1-00130',  -- 売上拠点を出力
                                                               'SALE_BASE_CODE',
                                                               xx03_sale_base_rec.sale_base_code,
                                                               'DEPARTMENT_CODE',
                                                               xx03_sale_base_rec.segment2,
                                                               'LINE_NUMBER',
                                                               xx03_sale_base_rec.line_number);
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
        END LOOP sale_base_loop;
        CLOSE xx03_sale_base_cur;
-- ver 11.5.10.2.14 2010/12/24 Add End   [E_本稼動_02004]
--
-- 2006/02/18 Ver11.5.10.1.6E Add END
-- ver 11.5.10.2.24 Add Start
        --請求書電子データ受領チェック
        OPEN xx03_payment_ele_data_cur;
        FETCH xx03_payment_ele_data_cur INTO xx03_payment_ele_data_rec;
        IF ( xx03_payment_ele_data_rec.payment_ele_data_yes = 'Y' 
            AND xx03_payment_ele_data_rec.payment_ele_data_no = 'N' )
          OR ( xx03_payment_ele_data_rec.payment_ele_data_yes = 'N' 
            AND xx03_payment_ele_data_rec.payment_ele_data_no = 'Y' )
          OR ( xx03_payment_ele_data_rec.request_date IS NOT NULL   )
          OR ( xx03_payment_ele_data_rec.orig_invoice_num IS NOT NULL   ) THEN
          NULL;
        ELSE
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR', 'APP-XXCFR1-00159');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_payment_ele_data_cur;
-- ver 11.5.10.2.24 Add End
--
-- Ver11.5.10.2.26 ADD START
        -- 伝票作成会社の有効チェック
        OPEN xx03_drafting_company_cur;
        FETCH xx03_drafting_company_cur INTO xx03_drafting_company_rec;
        IF ( xx03_drafting_company_rec.drafting_company <> xx03_drafting_company_rec.drafting_company_bd ) THEN
          -- 伝票作成会社と計上日時点の伝票作成会社が異なる場合
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg(
                                      'XXCFO'
                                     ,'APP-XXCFO1-00065'
                                     ,'DATE'
                                     ,TO_CHAR(xx03_drafting_company_rec.gl_date, 'YYYY/MM/DD')
                                     ,'DRAFTING_COMPANY'
                                     ,xx03_drafting_company_rec.drafting_company
                                    );
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_drafting_company_cur;
-- Ver11.5.10.2.26 ADD END
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
--2021/04/28 Ver11.5.10.2.23 ADD START
        -- 負債科目かチェック
        SELECT  COUNT(1)
          INTO  ln_count
          FROM  fnd_lookup_values_vl flvv
         WHERE  flvv.lookup_type = cv_lookup_liabilities_code
           AND  flvv.lookup_code = xx03_xrsjlv_rec.segment3
           AND  flvv.enabled_flag  = cv_yes
           AND  NVL( flvv.start_date_active, TRUNC(SYSDATE) ) <= TRUNC(SYSDATE)
           AND  NVL( flvv.end_date_active,   TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
        ;
        -- 負債科目の場合、部門、企業コード、顧客コードの整合性チェック
        IF (ln_count > 0) THEN
-- Ver11.5.10.2.26 ADD START
          -- 財務経理部門コードを取得
          SELECT xxcfr_common_pkg.get_fin_dept_code(
                   NVL(xrs.drafting_company, '001')
                  ,xrs.gl_date
                 )
          INTO   lv_fin_dept_code
          FROM   xx03_receivable_slips  xrs
          WHERE  xrs.receivable_id = in_receivable_id
          ;
-- Ver11.5.10.2.26 ADD END
-- Ver11.5.10.2.26 MOD START
--          IF (NVL(xx03_xrsjlv_rec.segment2,cv_z) != cv_dept_fin OR
          IF (NVL(xx03_xrsjlv_rec.segment2,cv_z) != lv_fin_dept_code OR
-- Ver11.5.10.2.26 MOD END
              NVL(xx03_xrsjlv_rec.segment5,cv_z) != cv_cust_def OR
              NVL(xx03_xrsjlv_rec.segment6,cv_z) != cv_corp_def) THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO'    ,'APP-XXCFO1-00061'
                                                              ,'SLIP_NUM' ,''
                                                              ,'TOK_COUNT',xx03_xrsjlv_rec.line_number
                                                              ,'TOK_ACCT_CODE' ,xx03_xrsjlv_rec.segment3
-- Ver11.5.10.2.26 ADD START
                                                              ,'DEPT_CODE',lv_fin_dept_code
-- Ver11.5.10.2.26 ADD END
                                                              );
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
        -- エラーがない場合CCID取得
        IF ( ln_err_cnt <= 0 ) THEN
--2021/04/28 Ver11.5.10.2.23 ADD END
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
--2021/04/28 Ver11.5.10.2.23 ADD START
        END IF;
--2021/04/28 Ver11.5.10.2.23 ADD END
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
-- ver 11.5.10.2.25 Add Start
        IF  xx03_payment_ele_data_rec.request_date IS NULL      AND
            xx03_payment_ele_data_rec.orig_invoice_num IS NULL  THEN
--
          SELECT  COUNT(*)
          INTO    ln_count
          FROM    FND_LOOKUP_VALUES flv
          WHERE   flv.LOOKUP_TYPE   =       'XXCFO1_FORBIDDEN_ACCOUNT_LIST'
          AND     flv.LANGUAGE      =       USERENV('LANG')
          AND     flv.ENABLED_FLAG  =       'Y'
          AND     flv.LOOKUP_CODE   =       xx03_xrsjlv_rec.segment3  ||  xx03_xrsjlv_rec.segment4
          AND     TRUNC(SYSDATE)    BETWEEN NVL(FLV.START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD'))
                                    AND     NVL(FLV.END_DATE_ACTIVE  , TO_DATE('9999/12/31','YYYY/MM/DD'));
--
          IF  ln_count  >=  1 THEN
            errflg_tbl(ln_err_cnt) := 'E';
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO', 'APP-XXCFO1-00063', 'ACC', xx03_xrsjlv_rec.segment3, 'SUB', xx03_xrsjlv_rec.segment4);
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
        END IF;
-- ver 11.5.10.2.25 Add End
--2016/12/01 Ver11.5.10.2.20 ADD START
        IF ( xx03_xrsjlv_rec.attribute7 IS NOT NULL ) THEN
          --稟議決裁番号形式チェック
          DECLARE
            lv_request_decision  xx03_receivable_slips.attribute7%TYPE;
            ln_request_decision  NUMBER;
          BEGIN
            --桁数チェック
            IF ( LENGTHB(xx03_xrsjlv_rec.attribute7) <> 11 ) THEN
              RAISE INVALID_NUMBER;
            END IF;
            --固定値チェック
--2018/02/07 Ver11.5.10.2.21 MOD START
--            IF ( SUBSTRB(xx03_xrsjlv_rec.attribute7,1,2) <> 'DR' ) THEN
            IF ( SUBSTRB(xx03_xrsjlv_rec.attribute7,1,2) NOT IN ('DR','SP') ) THEN
--2018/02/07 Ver11.5.10.2.21 MOD END
              RAISE INVALID_NUMBER;
            END IF;
            --年チェック
            ln_request_decision := SUBSTRB(xx03_xrsjlv_rec.attribute7,3,4);
            IF ( ln_request_decision < 2000 ) THEN
              RAISE INVALID_NUMBER;
            END IF;
            -- 連番チェック
            lv_request_decision := SUBSTRB(xx03_xrsjlv_rec.attribute7,7,5);
            -- 数値型チェック
            ln_request_decision := lv_request_decision;
            -- 小数チェック
            IF ( INSTR(lv_request_decision, cv_precision_char) <> 0 ) THEN
              RAISE INVALID_NUMBER;
            END IF;
            -- 符号チェック(上1桁が数値かどうかチェック)
            ln_request_decision := SUBSTRB(xx03_xrsjlv_rec.attribute7,7,1);
          EXCEPTION
            WHEN INVALID_NUMBER OR VALUE_ERROR THEN
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO','APP-XXCFO1-00054','TOK_REQUEST_DECISION',xx03_xrsjlv_rec.attribute7);
              ln_err_cnt := ln_err_cnt + 1;
          END;
        END IF;
--2016/12/01 Ver11.5.10.2.20 ADD END
--
-- Ver11.5.10.2.26 ADD START
        -- 伝票作成会社と明細会社の整合性チェック
        OPEN xx03_drafting_company_2_cur(
          xx03_xrsjlv_rec.line_number     -- 1.明細番号
        );
        FETCH xx03_drafting_company_2_cur INTO xx03_drafting_company_2_rec;
        IF ( xx03_drafting_company_2_rec.drafting_company <> xx03_drafting_company_2_rec.segment1 ) THEN
          -- 伝票作成会社と明細の会社が異なる場合
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg(
                                      'XXCFO'
                                     ,'APP-XXCFO1-00070'
                                     ,'LINE_NUM'
                                     ,xx03_drafting_company_2_rec.line_number
                                     ,'DRAFTING_COMPANY'
                                     ,xx03_drafting_company_2_rec.drafting_company
                                     ,'SEGMENT1'
                                     ,xx03_drafting_company_2_rec.segment1
                                    );
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_drafting_company_2_cur;
-- Ver11.5.10.2.26 ADD END
--
      END IF;
--
-- 2006/02/18 Ver11.5.10.1.6E add END
--
-- 2013/09/19 ver 11.5.10.2.18 ADD START
      -- 項目整合性チェック
      OPEN  xx03_save_code_chk_cur(
               in_org_id          => ln_org_id    -- 営業単位ID
             , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
            );
      FETCH xx03_save_code_chk_cur INTO xx03_save_code_chk_rec;
      -- 存在チェック件数が1件でも存在する場合
      IF ( xx03_save_code_chk_rec.exist_check <> 0 ) THEN
        -- 項目相違エラー
        errflg_tbl(ln_err_cnt) := 'E';
        errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFR', 'APP-XXCFR1-00150');
        ln_err_cnt := ln_err_cnt + 1;
      END IF;
      CLOSE xx03_save_code_chk_cur;
-- 2013/09/19 ver 11.5.10.2.18 ADD END
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
      -- Ver.11.5.10.2.13 2010/11/29 Add Start [E_本稼動_05407]
      IF ( xx03_terms_name_chk_cur%ISOPEN ) THEN
        CLOSE xx03_terms_name_chk_cur;
      END IF;
      IF ( xx03_customer_chk_cur%ISOPEN ) THEN
        CLOSE xx03_customer_chk_cur;
      END IF;
      -- Ver.11.5.10.2.13 2010/11/29 Add End   [E_本稼動_05407]
      -- ver 11.5.10.2.14 2010/12/13 Add Start [E_本稼動_02004]
      IF ( xx03_sale_base_cur%ISOPEN ) THEN
        CLOSE xx03_sale_base_cur;
      END IF;
      -- Ver.11.5.10.2.14 2010/12/13 Add End   [E_本稼動_02004]
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
/
