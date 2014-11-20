CREATE OR REPLACE PACKAGE BODY "APPS"."XX03_DEPTINPUT_GL_CHECK_PKG" 
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004. All rights reserved.
 *
 * Package Name           : xx03_deptinput_gl_check_pkg(body)
 * Description            : 部門入力(GL)において入力チェックを行う共通関数
 * MD.070                 : 部門入力(GL)共通関数 OCSJ/BFAFIN/MD070/F601/01
 * Version                : 11.5.10.2.12
 *
 * Program List
 *  -------------------------- ---- ----- ------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- ------------------------------------------------
 *  check_deptinput_gl          P          部門入力(GL)のエラーチェック
 *  set_account_approval_flag   P          重点管理チェック
 *  del_journal_data            P          仕訳伝票レコードの削除
 *
 * Change Record
 * ------------ -------------- -----------------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -----------------------------------------------------------
 *  2004/11/08   1.0            新規作成
 *  2005/02/21   1.1            structure不具合対応
 *  2005/09/02   11.5.10.1.5    パフォーマンス改善対応
 *  2005/10/18   11.5.10.1.5B   取消伝票を再度申請できてしまう不具合対応
 *  2005/11/07   11.5.10.1.6    入力画面での伝票種別取得方法変更に伴う対応
 *  2005/12/15   11.5.10.1.6B   消費税額許容範囲チェック用カーソル内に
 *                              税金コードの有効チェック追加
 *  2006/01/16   11.5.10.1.6C   CF組み合わせマスタ取得エラーを有効にする
 *  2006/01/19   11.5.10.1.6D   ワークテーブルに会計期間を渡すように変更
 *  2006/01/30   11.5.10.1.6E   相互検証ルールのチェックで、日付をGL計上日を
 *                              渡すよう変更
 *  2006/02/15   11.5.10.1.6F   ダブルクリック対応,PKGでcommitするPROCEDURE追加
 *  2006/02/18   11.5.10.1.6G   マスター存在チェックを実施するように変更
 *  2006/03/02   11.5.10.1.6H   エラーチェックテーブルのクリアロジックの不具合
 *  2006/03/02   11.5.10.1.6I   マスターチェックの各タイミングでの処理の統一
 *  2006/03/03   11.5.10.1.6J   承認者の承認権限チェック不具合修正
 *  2006/03/29   11.5.10.2.1    HR対応（従業員履歴レコード対応）
 *  2006/04/07   11.5.10.2.2    承認者が対象伝票に対する承認権限があるかのチェック追加
 *  2006/04/12   11.5.10.2.2B   11.5.10.2.2での修正ミス対応
 *  2006/06/22   11.5.10.2.3    マスタチェック用SQLでデータが取得でなかった時の
 *                              エラー処理が誤っていることの修正
 *  2006/12/06   11.5.10.2.6    会計期間チェック用SQLでGL計上日を元にデータを
 *                              取得しているのを、名称を元に取得するように変更
 *  2007/06/13   11.5.10.2.9    マスターチェック統一修正時の処理漏れ
 *                              javaで存在するチェックを本パッケージにも追加
 *  2007/06/18   11.5.10.2.9B   貸借で同じメッセージを出力していたが、それぞれ
 *                              異なるメッセージを出力するように修正
 *  2007/06/22   11.5.10.2.9C   AP/ARと処理を合わせるため共通関数呼び出し前判定の追加
 *  2007/08/10   11.5.10.2.10   仕訳配分チェックでエラーの時のメッセージに
 *                              ヘッダ･明細･税金のどの配分かを表示するように修正
 *  2007/10/29   11.5.10.2.10B  通貨の精度チェック(入力可能精度か桁チェック)追加
 *  2010/04/05   11.5.10.2.11   [E_本稼動_02174]部門入力エラーチェック結果が警告の場合、
 *                                              共通エラーチェックを実行するように変更
 *  2013/09/19   11.5.10.2.12   [E_本稼動_10999]項目整合性チェック追加
 *
 *****************************************************************************************/
--
  /**********************************************************************************
   * Procedure Name   : check_deptinput_gl
   * Description      : 部門入力(GL)のエラーチェック
   ***********************************************************************************/
  PROCEDURE check_deptinput_gl(
    in_journal_id  IN   NUMBER,    -- 1.チェック対象仕訳伝票ID
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
      'xx03_deptinput_gl_check_pkg.check_deptinput_gl'; -- プログラム名
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
    -- 通貨が取得できなかった場合の精度
    cn_curr_precision CONSTANT fnd_currencies.precision%TYPE := 2;
--
    -- *** ローカル変数 ***
    -- エラーフラグ用配列タイプ
    TYPE  errflg_tbl_type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;
    -- エラーメッセージ用配列タイプ
    TYPE  errmsg_tbl_type IS TABLE OF VARCHAR2(5000) INDEX BY BINARY_INTEGER;
    errflg_tbl errflg_tbl_type;
    errmsg_tbl errmsg_tbl_type;
    ln_err_cnt NUMBER := 0;    -- パラメータ添字用変数
-- ver 11.5.10.2.11 Add Start
    ln_warn_cnt NUMBER := 0;   -- 警告件数
-- ver 11.5.10.2.11 Add End
    ln_books_id gl_tax_options.set_of_books_id%TYPE;    -- 帳簿ID
    ln_org_id   gl_tax_options.org_id%TYPE;             --オルグID
    lv_first_flg VARCHAR2(1) := 'Y';  -- 1件目のレコードか否か
-- ver 11.5.10.1.6H Chg Start
    --ln_check_seq NUMBER;       -- エラーチェックシーケンス番号
    ln_check_seq NUMBER := 0;  -- エラーチェックシーケンス番号
-- ver 11.5.10.1.6H Chg End
    ln_cnt NUMBER;             -- ループカウンタ
    lv_err_status VARCHAR2(1); -- 共通エラーチェックステータス
    lv_currency_code VARCHAR2(15); -- 機能通貨コード
    lv_chk_currency_code VARCHAR2(15);      -- チェック用データ通貨コード
    ln_chk_exchange_rate NUMBER;            -- チェック用データ換算レート
    lv_chk_exchange_rate_type VARCHAR2(30); -- チェック用データ換算レートタイプ
    ld_chk_gl_date DATE;                    -- チェック用データ計上日
    lv_chk_orig_journal_num VARCHAR2(150);  -- チェック用データ修正元伝票番号
    lv_attribute2 VARCHAR2(240);            -- チェック用決算担当フラグ
    -- 2004-12-24:相互検証用パラメータ
    lb_retcode BOOLEAN;
    lv_app_short_name VARCHAR2(100) := 'SQLGL';
    lv_key_flex_code VARCHAR2(1000) := 'GL#'; -- FND_ID_FLEX_STRUCTURES.ID_FLEX_CODE
    ln_structure_number NUMBER; -- FND_ID_FLEX_STRUCTURES.ID_FLEX_NUM, ID_FLEX_STRUCTURE_CODE(設定:会計:フレックスフィールド:キー:セグメント)
    ld_validation_date DATE := SYSDATE;
    ln_segments NUMBER := 8;
    lv_segment_array FND_FLEX_EXT.SEGMENTARRAY;
    on_combination_id NUMBER := null;
    ld_data_set NUMBER := -1;
    -- 2006/03/06 Ver11.5.10.1.6J Add Start
    ld_wf_status              VARCHAR2(25);        -- チェック用ワークフローステータス
    cn_wf_status_dept   VARCHAR2(25) := '20';      -- 部門入力承認待ちステータス
    -- 2006/03/06 Ver11.5.10.1.6J Add End
--
    -- ver 11.5.10.2.2 Add Start
    cn_wf_status_save   VARCHAR2(25) := '00';      -- 部門入力保存ステータス
    cn_wf_status_last   VARCHAR2(25) := '30';      -- 部門入力最終部門承認待ちステータス
    -- ver 11.5.10.2.2 Add End
--
-- ver 11.5.10.2.9 Add Start
    ln_chk_total_dr NUMBER;      -- チェック用データ借方換算済合計金額
    ln_chk_total_cr NUMBER;      -- チェック用データ貸方換算済合計金額
    lv_chk_dr_cr    VARCHAR2(2); -- チェック対象明細貸借区分
-- ver 11.5.10.2.9 Add End
--
    -- ver 11.5.10.2.10 Add Start
    lv_je_err_msg       VARCHAR2(14);              -- 配分チェックエラー時の追加メッセージコード
    -- ver 11.5.10.2.10 Add End
--
    -- ver 11.5.10.2.10B Add Start
    lb_currency_chk        BOOLEAN      := FALSE;  -- 通貨エラーOK/NGフラグ(精度チェック時に使用)
    ln_currency_precision  NUMBER(1)    := 0;      -- 通貨の精度(通貨チェックOK時に精度を取得)
    lv_amount              VARCHAR2(50) := '';     -- 伝票での金額精度取得用
    ln_amount_precision    NUMBER(1)    := 0;      -- 伝票での金額の精度
    cv_precision_char      VARCHAR2(1)  := '.';    -- 小数点記号
    -- ver 11.5.10.2.10B Add End
--
    -- *** ローカル・カーソル ***
    -- 処理対象データ取得カーソル
    CURSOR xx03_xjsjlv_cur
    IS
      SELECT xjsjlv.journal_num as journal_num,
             xjsjlv.line_number as line_number,
             xjsjlv.gl_date as gl_date,
             xjsjlv.invoice_currency_code as invoice_currency_code,
             xjsjlv.code_combination_id as code_combination_id,
             xjsjlv.segment1 as segment1,
             xjsjlv.segment2 as segment2,
             xjsjlv.segment3 as segment3,
             xjsjlv.segment4 as segment4,
             xjsjlv.segment5 as segment5,
             xjsjlv.segment6 as segment6,
             xjsjlv.segment7 as segment7,
             xjsjlv.segment8 as segment8,
             xjsjlv.tax_code as tax_code,
             xjsjlv.incr_decr_reason_code as incr_decr_reason_code,
             xjsjlv.entry_department as entry_department,
             xjsjlv.user_name as user_name,
             xjsjlv.recon_reference as recon_reference,
             xjsjlv.entered_dr as entered_dr,
-- 2005/1/19 Ver11.5.10.1.6D Add Start
--             xjsjlv.entered_cr as entered_cr
             xjsjlv.entered_cr as entered_cr,
             xjsjlv.PERIOD_NAME
-- Ver11.5.10.1.6G Add Start
           , xjsjlv.line_type_lookup_code as line_type_lookup_code
-- Ver11.5.10.1.6G Add End
-- 2005/1/19 Ver11.5.10.1.6D Add End
        FROM xx03_jn_slip_journal_lines_v xjsjlv
       WHERE xjsjlv.journal_id = in_journal_id
       ORDER BY xjsjlv.line_number;
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
    -- 修正元伝票番号チェックカーソル
    CURSOR xx03_orig_num_cur(
      iv_orig_journal_num  IN VARCHAR2 -- 1.修正元伝票番号
    ) IS
-- Ver11.5.10.1.5 2005/09/02 Change Start
--      SELECT *
--        FROM xx03_journal_slips_v xjsv
--       WHERE xjsv.gl_forword_date IS NULL
--         AND xjsv.orig_journal_num = iv_orig_journal_num
--         AND xjsv.wf_status >= 20
--         AND xjsv.journal_id != in_journal_id;
      -- Ver11.5.10.1.5B 2005/10/18 Change Start
      --SELECT *
      --  FROM xx03_journal_slips xjs
      -- WHERE xjs.gl_forword_date IS NULL
      --   AND xjs.orig_journal_num = iv_orig_journal_num
      --   AND xjs.wf_status >= 20
      --   AND xjs.journal_id != in_journal_id
      --   AND xjs.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      SELECT *
        FROM xx03_journal_slips xjs
       WHERE xjs.orig_journal_num = iv_orig_journal_num
         AND xjs.wf_status >= 20
         AND xjs.journal_id != in_journal_id
         AND xjs.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID');
      -- Ver11.5.10.1.5B 2005/10/18 Change End
-- Ver11.5.10.1.5 2005/09/02 Change End
--
-- ver 11.5.10.2.6 Chg Start
    -- 会計期間チェックカーソル
--    CURSOR xx03_gl_period_status_cur(
--      in_books_id   IN NUMBER,    -- 1.帳簿ID
--      id_gl_date    IN DATE       -- 2.GL記帳日
--    ) IS
--      SELECT gps.attribute5 as attribute5,           -- GL部門入力ステータス
--             gps.adjustment_period_flag as adj_flag, -- 調整期間フラグ
--             gps.closing_status as closing_status    -- GLステータス
---- ver 11.5.10.1.6I Add Start
--           , gps.period_name as period_name          -- 会計期間名称
---- ver 11.5.10.1.6I Add End
--        FROM gl_period_statuses gps
--       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLGL')
--         AND gps.set_of_books_id = in_books_id
--         AND gps.start_date <= TRUNC(id_gl_date)
--         AND gps.end_date >= TRUNC(id_gl_date);
    CURSOR xx03_gl_period_status_cur(
      in_books_id     IN NUMBER,    -- 1.帳簿ID
      iv_period_name  IN VARCHAR2   -- 2.会計期間名称
    ) IS
      SELECT gps.attribute5 as attribute5,           -- GL部門入力ステータス
             gps.adjustment_period_flag as adj_flag, -- 調整期間フラグ
             gps.closing_status as closing_status,   -- GLステータス
             gps.start_date as start_date,           -- 開始日付
             gps.end_date as end_date                -- 終了日付
        FROM gl_period_statuses gps
       WHERE gps.application_id = xx03_application_pkg.get_application_id_f('SQLGL')
         AND gps.set_of_books_id = in_books_id
         AND gps.period_name = iv_period_name;
-- ver 11.5.10.2.6 Chg End
--
-- ver 11.5.10.2.2 add Start
    -- 申請者と承認者の関係 チェックカーソル
    CURSOR xx03_req_app_cur
    IS
    SELECT COUNT(1) exist_check
    FROM   XX03_APPROVER_PERSON_V      XAPV
          ,XX03_JOURNAL_SLIPS          XJS
          ,XX03_DEPARTMENTS_V          XDV
          ,XX03_PER_PEOPLES_V          XPPV
          ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
    WHERE  XJS.JOURNAL_ID = in_journal_id
      AND  TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE  AND XAPV.EFFECTIVE_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE          AND XAPV.R_END_DATE
      AND  TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE          AND XAPV.U_END_DATE
      AND  XAPV.PERSON_ID   != XJS.REQUESTOR_PERSON_ID
      AND  XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
      AND  XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
      AND  XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
      AND  XPPV.PERSON_ID   = XJS.REQUESTOR_PERSON_ID
      AND  TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE  AND XPPV.EFFECTIVE_END_DATE
      AND  XAPV.PROFILE_VAL_AUTH != 9
      AND  (   XAPV.PROFILE_VAL_DEP = 'ALL'
            OR XAPV.PROFILE_VAL_DEP = 'SQLGL'   )
      AND  XAPV.PERSON_ID   = XJS.APPROVER_PERSON_ID
    ;
-- ver 11.5.10.2.2 add End
--
--Ver11.5.10.1.6G Add start
--
    --承認者チェックカーソル
    CURSOR xx03_approver_cur
    IS
-- 2006/03/03 Ver11.5.10.1.6J Change Start
--    SELECT COUNT(1) exist_check
--      FROM per_all_assignments_f pa
--          ,xx03_per_peoples_v    xppv
--          ,xx03_journal_slips    xjs
--     WHERE xjs.journal_id   = in_journal_id
--       AND pa.supervisor_id = xppv.person_id
--       AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date
--                              AND pa.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.effective_start_date
--                              AND xppv.effective_end_date
--       AND TRUNC(SYSDATE) BETWEEN xppv.u_start_date
--                              AND xppv.u_end_date
--       AND pa.person_id = xjs.requestor_person_id;
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
                           ,XX03_JOURNAL_SLIPS          XJS
                           ,XX03_DEPARTMENTS_V          XDV
                           ,XX03_PER_PEOPLES_V          XPPV
                           ,XX03_FLEX_VALUE_CHILDREN_V  XFVCV
                      WHERE  XJS.JOURNAL_ID = in_journal_id
                        AND TRUNC(SYSDATE) BETWEEN XAPV.EFFECTIVE_START_DATE
                                               AND XAPV.EFFECTIVE_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.R_START_DATE
                                               AND XAPV.R_END_DATE
                        AND TRUNC(SYSDATE) BETWEEN XAPV.U_START_DATE
                                               AND XAPV.U_END_DATE
                        AND XAPV.PERSON_ID   != XJS.APPROVER_PERSON_ID
                        AND XDV.FLEX_VALUE   = XAPV.ATTRIBUTE28
                        AND XFVCV.FLEX_VALUE = XAPV.ATTRIBUTE28
                        AND XPPV.ATTRIBUTE30 = XFVCV.PARENT_FLEX_VALUE
                        AND XPPV.PERSON_ID     = XJS.APPROVER_PERSON_ID
                        AND TRUNC(SYSDATE) BETWEEN XPPV.EFFECTIVE_START_DATE
                                               AND XPPV.EFFECTIVE_END_DATE
                        AND XAPV.PROFILE_VAL_AUTH != 9
                        AND (   XAPV.PROFILE_VAL_DEP = 'ALL'
                             OR XAPV.PROFILE_VAL_DEP = 'SQLGL'   )) xaplv
                   WHERE xaplv.person_id = xppv2.supervisor_id
                                );
-- 2006/03/03 Ver11.5.10.1.6J Change End
--
    --適用コードチェック
    CURSOR xx03_jsl_slt_dr_cur(
      in_line_number IN number     -- 1.明細番号
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
      AND  XJSL.SLIP_LINE_TYPE_DR      IS NOT NULL;
--
    CURSOR xx03_slip_line_type_dr_cur(
      in_line_number IN number,    -- 1.明細番号
      id_gl_date     IN DATE       -- 2.GL記帳日
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_LOOKUPS_XX03_V     XLXV
          ,XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
      AND  XLXV.LANGUAGE     = USERENV('LANG')
      AND  XLXV.LOOKUP_TYPE  = 'XX03_SLIP_LINE_TYPES'
      AND  XLXV.ATTRIBUTE15  = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  XLXV.ENABLED_FLAG = 'Y'
      AND  XLXV.LOOKUP_CODE = XJSL.SLIP_LINE_TYPE_DR
      AND  id_gl_date BETWEEN XLXV.START_DATE_ACTIVE
                      AND NVL(XLXV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
--
    CURSOR xx03_jsl_slt_cr_cur(
      in_line_number IN number     -- 1.明細番号
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
      AND  XJSL.SLIP_LINE_TYPE_CR      IS NOT NULL;
--
    CURSOR xx03_slip_line_type_cr_cur(
      in_line_number IN number,    -- 1.明細番号
      id_gl_date     IN DATE       -- 2.GL記帳日
    ) IS
    SELECT COUNT(1) exist_check
    FROM   XX03_LOOKUPS_XX03_V     XLXV
          ,XX03_JOURNAL_SLIP_LINES XJSL
    WHERE  XJSL.JOURNAL_ID   = in_journal_id
      AND  XJSL.LINE_NUMBER  = in_line_number
      AND  XJSL.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
      AND  XLXV.LANGUAGE     = USERENV('LANG')
      AND  XLXV.LOOKUP_TYPE  = 'XX03_SLIP_LINE_TYPES'
      AND  XLXV.ATTRIBUTE15  = XX00_PROFILE_PKG.VALUE('ORG_ID')
      AND  XLXV.ENABLED_FLAG = 'Y'
      AND  XLXV.LOOKUP_CODE = XJSL.SLIP_LINE_TYPE_CR
      AND  id_gl_date BETWEEN XLXV.START_DATE_ACTIVE
                      AND NVL(XLXV.END_DATE_ACTIVE, TO_DATE('4712/12/31','YYYY/MM/DD'));
--
--Ver11.5.10.1.6G Add start
--
    -- 共通エラーチェック結果取得カーソル
    CURSOR xx03_errchk_result_cur
    IS
-- ver 11.5.10.1.6I Chg Start
--      SELECT xei.journal_id as journal_id,
--             xei.line_number as line_number,
--             xlgv.meaning as dr_cr,
--             xei.error_code as error_code,
--             xei.error_message as error_message,
--             xei.status as status
--        FROM xx03_error_info xei,
--             xx03_lookups_gl_v xlgv
--       WHERE xei.check_id = ln_check_seq
--       AND   xlgv.lookup_type = 'GL_DR_CR'
--       AND   xlgv.lookup_code = xei.dr_cr
--      -- Ver11.5.10.1.6C 2006/01/16 Change Start
--       ORDER BY xei.dr_cr, line_number;
--      --UNION ALL
--      --SELECT xei.journal_id as journal_id,
--      --       xei.line_number as line_number,
--      --       ' ',
--      --       xei.error_code as error_code,
--      --       xei.error_message as error_message,
--      --       xei.status as status
--      --  FROM xx03_error_info xei
--      -- WHERE xei.check_id = ln_check_seq
--      -- AND   xei.dr_cr = ' ';
--      -- Ver11.5.10.1.6C 2006/01/16 Change End
      SELECT err_info.journal_id
           , err_info.line_number
           , err_info.dr_cr
           , err_info.error_code
           , err_info.error_message
           , err_info.status
        FROM
      (
        SELECT xei.journal_id    as journal_id
             , xei.line_number   as line_number
             , xlgv.meaning      as dr_cr
             , xei.error_code    as error_code
             , xei.error_message as error_message
             , xei.status        as status
          FROM xx03_error_info xei,
               xx03_lookups_gl_v xlgv
         WHERE xei.check_id = ln_check_seq
         AND   xlgv.lookup_type = 'GL_DR_CR'
         AND   xlgv.lookup_code = xei.dr_cr
        UNION ALL
        SELECT xei.journal_id    as journal_id
             , xei.line_number   as line_number
             , ' '               as dr_cr
             , xei.error_code    as error_code
             , xei.error_message as error_message
             , xei.status        as status
          FROM xx03_error_info xei
         WHERE xei.check_id = ln_check_seq
         AND   xei.dr_cr = ' '
       ) err_info
      ORDER BY dr_cr, line_number;
-- ver 11.5.10.1.6I Chg End
--
    --税金オプション表検索
    CURSOR gl_tax_options_cur(
      in_books_id        IN  gl_tax_options.set_of_books_id%TYPE,  -- 1.帳簿ID
      in_org_id          IN  gl_tax_options.org_id %TYPE           -- 2.オルグID
    ) IS
      SELECT a.attribute1,               --許容範囲率
             a.attribute2,               --許容範囲最大金額
             a.input_rounding_rule_code, --仮払端数処理規則
             a.output_rounding_rule_code --仮受端数処理規則
      FROM   gl_tax_options a
      WHERE  a.set_of_books_id       =  in_books_id
      AND    a.org_id                =  in_org_id;
--
    --消費税額許容範囲チェック用カーソル
    CURSOR tax_range_check_cur(
      in_journal_id                 IN  xx03_journal_slip_lines.journal_id%TYPE,      -- 1.伝票ID
      in_books_id                   IN  gl_tax_options.set_of_books_id%TYPE,          -- 2.帳簿ID
      iv_input_rounding_rule_code   IN  gl_tax_options.input_rounding_rule_code%TYPE, -- 3.仮払端数処理規則
      iv_output_rounding_rule_code  IN  gl_tax_options.output_rounding_rule_code%TYPE -- 4.仮受端数処理規則
    ) IS
    SELECT
      xjsjl.journal_id,  --伝票ID
      xjsjl.segment1,    --会社コード
      xjsjl.tax_code,    --税区分
    --
      sum(
        case
          when ac.attribute6 is null then --消費税科目区分がNULL(本科目行)
            case
              when nvl(tc.tax_rate,0) = 0 then
                0 --税率0%（非課税、不課税、免税、課税対象外）は0として計算
              else nvl(xjsjl.entered_dr, xjsjl.entered_cr)
            end
          else 0 --税金行は加算せず。
        end ) sum_no_tax,   --税金行でない行の合計
    --
      sum(
        case
          when ac.attribute6 is null then --消費税科目区分がNULL(本科目行)
          case
            when nvl(tc.tax_rate,0) = 0 then 0 --税率0%は0として計算
            else
              case tc.attribute2    --税区分マスタの課税集計区分
                when '1' then     --課税売上(仮受)
                  case iv_output_rounding_rule_code --変数. 仮受端数処理規則 (output_rounding_rule_code)  --仮受端数処理規則
                    when 'N' then   --四捨五入
                      round(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                    when 'U' then   --切り上げ
                      sign( nvl(xjsjl.entered_dr,xjsjl.entered_cr)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
                    (trunc((abs( nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    else        --切り捨て(d)
                      trunc(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                  end
                else          --課税仕入(仮払)
                  case  iv_input_rounding_rule_code --変数.仮払端数処理規則(input_rounding_rule_code)   --仮払端数処理規則
                    when 'N' then   --四捨五入
                      round(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                    when 'U' then   --切り上げ
                      sign( nvl(xjsjl.entered_dr,xjsjl.entered_cr)  * ( nvl(tc.tax_rate,0) / 100 ) ) *
                    (trunc((abs( nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ) ) + 0.9 * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                       * power( 10,nvl(fc.precision, cn_curr_precision) ) ) * power( 0.1,nvl(fc.precision, cn_curr_precision) ) )
                    else        --切り捨て(d)
                      trunc(nvl(xjsjl.entered_dr,xjsjl.entered_cr) * ( nvl(tc.tax_rate,0) / 100 ), nvl(fc.precision, cn_curr_precision))
                  end
              end
          end
      else 0 --税金行は対象外
      end
      ) sum_cal_tax,    --計算による税金行の合計
    --
      sum(
        case
          when ac.attribute6 is not null then   --消費税科目区分がNOT NULL(税金行)
            nvl(xjsjl.entered_dr,xjsjl.entered_cr)
          else
            0       --税金行でなければ加算せず。
        end
      ) sum_tax     --税金行の合計
    FROM xx03_jn_slip_journal_lines_v  xjsjl, --伝票明細テーブル
         xx03_accounts_v           ac, --勘定科目マスタ
         xx03_tax_codes_v          tc, --税区分マスタ
         fnd_currencies            fc  --通貨マスタ
    WHERE xjsjl.journal_id = in_journal_id
      and xjsjl.segment3   = ac.flex_value
      and xjsjl.tax_code   = tc.name (+)
      and tc.set_of_books_id (+)     = in_books_id --変数.帳簿ID
      and xjsjl.invoice_currency_code = fc. currency_code (+)
      -- Ver11.5.10.1.6B 2005/12/15 Add Start
      and (tc.start_date    IS NULL or tc.start_date  <= xjsjl.gl_date )
      and (tc.inactive_date IS NULL or tc.inactive_date  >= xjsjl.gl_date)
      -- Ver11.5.10.1.6B 2005/12/15 Add End
    GROUP BY
      xjsjl.journal_id,  --仕訳id
      xjsjl.segment1,    --会社コード
      xjsjl.tax_code     --税区分
    ORDER BY
      xjsjl.journal_id,--仕訳id
      xjsjl.segment1,  --会社コード
      xjsjl.tax_code;  --税区分
--
-- ver 11.5.10.2.9 Add Start
    -- ver 11.5.10.2.10B Chg Start
    --CURSOR xx03_inv_currency_cur(
    --  iv_currency_code IN VARCHAR2   -- 1.通貨コード
    --) IS
    --  SELECT COUNT(1) exist_check
    --    FROM fnd_currencies fc
    --   WHERE fc.enabled_flag  = 'Y'
    --     AND fc.currency_flag = 'Y'
    --     AND fc.currency_code = iv_currency_code
    --     AND TRUNC(SYSDATE) BETWEEN NVL(fc.start_date_active, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
    --                            AND NVL(fc.end_date_active  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    --
    --通貨チェック(精度チェック用に精度を取得するように変更)
    CURSOR xx03_inv_currency_cur(
      iv_currency_code IN VARCHAR2   -- 1.通貨コード
    ) IS
    SELECT fc.currency_code      CURRENCY_CODE
          ,NVL(fc.precision , 0) PRECISION
      FROM fnd_currencies fc
     WHERE fc.enabled_flag  = 'Y'
       AND fc.currency_flag = 'Y'
       AND fc.currency_code = iv_currency_code
       AND TRUNC(SYSDATE) BETWEEN NVL(fc.start_date_active, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                AND NVL(fc.end_date_active  , TO_DATE('4712/12/31', 'YYYY/MM/DD'));
    -- ver 11.5.10.2.10B Chg End
--
    --税金コードチェック
    CURSOR xx03_line_tax_cur(
      in_line_number IN number    -- 1.明細番号
     ,iv_drcr_flg    IN VARCHAR2  -- 2.貸借フラグ('DR'or'CR')
     ,id_gl_date     IN DATE      -- 3.GL日付
    ) IS
      SELECT COUNT(1) exist_check
        FROM xx03_journal_slip_lines xjsl
            ,xx03_tax_codes_lov_v    xtclv
       WHERE xjsl.journal_id  = in_journal_id
         AND xjsl.line_number = in_line_number
         AND (    (iv_drcr_flg = 'DR' AND xjsl.tax_code_dr is not null)
               OR (iv_drcr_flg = 'CR' AND xjsl.tax_code_cr is not null) )
         AND xtclv.name       = NVL(xjsl.tax_code_dr ,xjsl.tax_code_cr)
         AND id_gl_date BETWEEN NVL(xtclv.start_date   , TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                            AND NVL(xtclv.inactive_date, TO_DATE('4712/12/31', 'YYYY/MM/DD'));
--
    --機能通貨時、入力と換算済の一致チェック
    CURSOR xx03_enter_account_cur(
      in_line_number IN number    -- 1.明細番号
     ,iv_drcr_flg    IN VARCHAR2  -- 2.貸借フラグ('DR'or'CR')
    ) IS
      SELECT NVL(xjsl.entered_item_amount_dr ,xjsl.entered_item_amount_cr) entered_item_amount
            ,NVL(xjsl.entered_tax_amount_dr  ,xjsl.entered_tax_amount_cr ) entered_tax_amount
            ,NVL(xjsl.accounted_amount_dr    ,xjsl.accounted_amount_cr   ) accounted_amount
        FROM xx03_journal_slip_lines xjsl
       WHERE xjsl.journal_id  = in_journal_id
         AND xjsl.line_number = in_line_number
         AND (    (iv_drcr_flg = 'DR' AND xjsl.entered_amount_dr is not null)
               OR (iv_drcr_flg = 'CR' AND xjsl.entered_amount_cr is not null) );
-- ver 11.5.10.2.9 Add End
--
-- 2013/09/19 ver 11.5.10.2.12 ADD START
    -- 項目整合性チェックカーソル
    CURSOR xx03_save_code_chk_cur(
      in_org_id          IN  NUMBER  -- 営業単位ID
    , in_set_of_books_id IN  NUMBER  -- 会計帳簿ID
    )
    IS
      SELECT /*+ LEADING(xjs xjsl) */
             COUNT(1)                AS exist_check
      FROM   xx03_journal_slips      xjs  -- GL部門入力ヘッダ
           , xx03_journal_slip_lines xjsl -- GL部門入力明細
      WHERE  xjs.journal_id       = in_journal_id      -- 伝票ID
      AND    xjs.org_id           = in_org_id          -- 営業単位ID
      AND    xjs.set_of_books_id  = in_set_of_books_id -- 会計帳簿ID
      AND    xjs.journal_id       = xjsl.journal_id    -- 伝票ID
      AND (
           ( SUBSTRB( xjs.requestor_person_name, 1, 5 ) <> ( SELECT papf.employee_number AS employee_number         -- 申請者名
                                                             FROM   per_all_people_f     papf
                                                             WHERE  papf.person_id = xjs.requestor_person_id
                                                             AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                   AND     papf.effective_end_date ) )
        OR ( SUBSTRB( xjs.approver_person_name, 1, 5 )  <> ( SELECT papf.employee_number AS employee_number         -- 承認者名
                                                             FROM   per_all_people_f     papf
                                                             WHERE  papf.person_id = xjs.approver_person_id
                                                             AND    TRUNC(SYSDATE) BETWEEN papf.effective_start_date
                                                                                   AND     papf.effective_end_date ) )
        OR ( ( xjsl.slip_line_type_dr IS NULL )     AND ( xjsl.slip_line_type_name_dr IS NOT NULL ) )               -- 借方 摘要コード名
        OR ( ( xjsl.slip_line_type_dr IS NOT NULL ) AND ( xjsl.slip_line_type_name_dr IS NULL ) )                   -- 借方 摘要コード名
        OR ( xjsl.slip_line_type_dr <> SUBSTRB( xjsl.slip_line_type_name_dr, 1, LENGTHB(xjsl.slip_line_type_dr) ) ) -- 借方 摘要コード名
        OR ( xjsl.tax_code_dr       <> SUBSTRB( xjsl.tax_name_dr,            1, LENGTHB(xjsl.tax_code_dr) ) )       -- 借方 税金コード名
        OR ( ( xjsl.slip_line_type_cr IS NULL )     AND ( xjsl.slip_line_type_name_cr IS NOT NULL ) )               -- 貸方 摘要コード名
        OR ( ( xjsl.slip_line_type_cr IS NOT NULL ) AND ( xjsl.slip_line_type_name_cr IS NULL ) )                   -- 貸方 摘要コード名
        OR ( xjsl.slip_line_type_cr <> SUBSTRB( xjsl.slip_line_type_name_cr, 1, LENGTHB(xjsl.slip_line_type_cr) ) ) -- 貸方 摘要コード名
        OR ( xjsl.tax_code_cr       <> SUBSTRB( xjsl.tax_name_cr,            1, LENGTHB(xjsl.tax_code_cr) ) )       -- 貸方 税金コード名
        OR ( xjsl.segment1 <> SUBSTRB( xjsl.segment1_name, 1, LENGTHB(xjsl.segment1) ) )                            -- AFF 会社
        OR ( xjsl.segment2 <> SUBSTRB( xjsl.segment2_name, 1, LENGTHB(xjsl.segment2) ) )                            -- AFF 部門
        OR ( xjsl.segment3 <> SUBSTRB( xjsl.segment3_name, 1, LENGTHB(xjsl.segment3) ) )                            -- AFF 勘定科目
        OR ( xjsl.segment4 <> SUBSTRB( xjsl.segment4_name, 1, LENGTHB(xjsl.segment4) ) )                            -- AFF 補助科目
        OR ( xjsl.segment5 <> SUBSTRB( xjsl.segment5_name, 1, LENGTHB(xjsl.segment5) ) )                            -- AFF 顧客
        OR ( xjsl.segment6 <> SUBSTRB( xjsl.segment6_name, 1, LENGTHB(xjsl.segment6) ) )                            -- AFF 企業
        OR ( xjsl.segment7 <> SUBSTRB( xjsl.segment7_name, 1, LENGTHB(xjsl.segment7) ) )                            -- AFF 予備１
        OR ( xjsl.segment8 <> SUBSTRB( xjsl.segment8_name, 1, LENGTHB(xjsl.segment8) ) )                            -- AFF 予備２
          )
      ;
-- 2013/09/19 ver 11.5.10.2.12 ADD END
--
    -- *** ローカル・レコード ***
    -- 処理対象データ取得カーソルレコード型
    xx03_xjsjlv_rec            xx03_xjsjlv_cur%ROWTYPE;
    -- レートカーソルレコード型
    xx03_rate_rec              xx03_rate_cur%ROWTYPE;
    -- 修正元伝票番号チェックカーソルレコード型
    xx03_orig_num_rec          xx03_orig_num_cur%ROWTYPE;
    -- GL会計期間チェックカーソルレコード型
    xx03_gl_period_status_rec  xx03_gl_period_status_cur%ROWTYPE;
    -- 共通エラーチェック結果取得レコード型
    xx03_errchk_result_rec     xx03_errchk_result_cur%ROWTYPE;
    -- 税金オプションシュトクレコード型
    gl_tax_options_rec            gl_tax_options_cur%ROWTYPE;
    -- 消費税許容範囲チェックカーソルレコード型
    tax_range_check_rec           tax_range_check_cur%ROWTYPE;
-- ver 11.5.10.2.2 Add Start
    -- 申請者-承認者 チェックカーソルレコード型
    xx03_req_app_rec             xx03_req_app_cur%ROWTYPE;
-- ver 11.5.10.2.2 Add End
-- Ver11.5.10.1.6G Add Start
    --承認者チェックカーソルレコード型
    xx03_approver_rec                xx03_approver_cur%ROWTYPE;
    --適用コードチェックカーソルレコード型
    xx03_jsl_slt_dr_rec         xx03_jsl_slt_dr_cur%ROWTYPE;
    xx03_slip_line_type_dr_rec  xx03_slip_line_type_dr_cur%ROWTYPE;
    xx03_jsl_slt_cr_rec         xx03_jsl_slt_cr_cur%ROWTYPE;
    xx03_slip_line_type_cr_rec  xx03_slip_line_type_cr_cur%ROWTYPE;
-- Ver11.5.10.1.6G Add End
--
-- ver 11.5.10.2.9 Add Start
    xx03_inv_currency_rec       xx03_inv_currency_cur%ROWTYPE;
    xx03_line_tax_rec           xx03_line_tax_cur%ROWTYPE;
    xx03_enter_account_rec      xx03_enter_account_cur%ROWTYPE;
-- ver 11.5.10.2.9 Add End
-- 2013/09/19 ver 11.5.10.2.12 ADD START
    -- 項目整合性チェックカーソルレコード型
    xx03_save_code_chk_rec       xx03_save_code_chk_cur%ROWTYPE;
-- 2013/09/19 ver 11.5.10.2.12 ADD END
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
    -- オルグID取得
    ln_org_id := xx00_profile_pkg.value ('ORG_ID') ;
--
    -- 処理対象データ取得カーソルオープン
    OPEN xx03_xjsjlv_cur;
    <<xx03_xjsjlv_loop>>
    LOOP
      FETCH xx03_xjsjlv_cur INTO xx03_xjsjlv_rec;
      IF xx03_xjsjlv_cur%NOTFOUND THEN
        IF ( lv_first_flg = 'Y' ) THEN
          -- 1件もデータがない場合
          RAISE NO_DATA_FOUND;
        ELSE
          -- データ終了
          EXIT xx03_xjsjlv_loop;
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
        SELECT xjsv.invoice_currency_code as invoice_currency_code,
               xjsv.exchange_rate as exchange_rate,
               xjsv.exchange_rate_type as exchange_rate_type,
               xjsv.gl_date as gl_date,
               xjsv.orig_journal_num as orig_journal_num
        --2006/03/06 Ver11.5.10.1.6J add start
             , xjsv.WF_STATUS
        --2006/03/06 Ver11.5.10.1.6J add End
-- ver 11.5.10.2.9 Add Start
             , xjsv.TOTAL_ACCOUNTED_DR
             , xjsv.TOTAL_ACCOUNTED_CR
-- ver 11.5.10.2.9 Add Start
          INTO lv_chk_currency_code,
               ln_chk_exchange_rate,
               lv_chk_exchange_rate_type,
               ld_chk_gl_date,
               lv_chk_orig_journal_num
        --2006/03/06 Ver11.5.10.1.6J add start
             , ld_wf_status
        --2006/03/06 Ver11.5.10.1.6J add End
-- ver 11.5.10.2.9 Add Start
             , ln_chk_total_dr
             , ln_chk_total_cr
-- ver 11.5.10.2.9 Add End
-- Ver11.5.10.1.6 2005/11/07 Change Start
--          FROM xx03_journal_slips_v xjsv
          FROM xx03_journal_slips xjsv
-- Ver11.5.10.1.6 2005/11/07 Change End
         WHERE xjsv.journal_id = in_journal_id;
--
        -- チェック用データ取得
        SELECT  xdv.attribute2
          INTO  lv_attribute2
          FROM  xx03_entry_person_lov_v  xeplv
               ,xx03_departments_v xdv
         WHERE  xeplv.attribute28 = xdv.flex_value
           AND  xeplv.user_id = XX00_GLOBAL_PKG.USER_ID;
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
-- Ver11.5.10.1.5 2005/09/02 Change Start
      -- 修正元伝票番号入力時のみチェックする
      IF lv_chk_orig_journal_num is not NULL THEN
-- Ver11.5.10.1.5 2005/09/02 Change End
        -- 修正元伝票番号チェック
        OPEN xx03_orig_num_cur(
          lv_chk_orig_journal_num  -- 1.修正元伝票番号
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
-- ver 11.5.10.2.6 Chg Start
        -- 会計期間チェック
--        OPEN xx03_gl_period_status_cur(
--          ln_books_id,    -- 1.帳簿ID
--          ld_chk_gl_date  -- 2.GL記帳日
--        );
--        FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
--        -- ①会計期間と計上日が同一期間にあるか
--        IF xx03_gl_period_status_cur%NOTFOUND THEN
--          -- GL会計期間未定義エラー
--          errflg_tbl(ln_err_cnt) := 'E';
--          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14013');
--          ln_err_cnt := ln_err_cnt + 1;
---- ver 11.5.10.1.6I Add Start
--        ELSIF xx03_xjsjlv_rec.period_name != xx03_gl_period_status_rec.period_name THEN
--          errflg_tbl(ln_err_cnt) := 'E';
--          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11572');
--          ln_err_cnt := ln_err_cnt + 1;
---- ver 11.5.10.1.6I Add End
        OPEN xx03_gl_period_status_cur(
          ln_books_id,    -- 1.帳簿ID
          xx03_xjsjlv_rec.period_name  -- 2.会計期間名称
        );
        FETCH xx03_gl_period_status_cur INTO xx03_gl_period_status_rec;
        -- ①選択会計期間名称と同じデータがあるか？
        IF xx03_gl_period_status_cur%NOTFOUND THEN
          -- GL会計期間未定義エラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03068');
          ln_err_cnt := ln_err_cnt + 1;
        -- ⑤選択会計期間の開始終了にGL記帳日が入っているか？
        ELSIF xx03_gl_period_status_rec.start_date > TRUNC(ld_chk_gl_date) OR
              xx03_gl_period_status_rec.end_date   < TRUNC(ld_chk_gl_date) THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11575');
          ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.6 Chg End
        ELSE
          -- 起票部門の部門コードの決算担当（部門セグメントのATTRIBUTE2）が”Y"の場合
          IF lv_attribute2 = 'Y' THEN
            -- ②入力された会計期間がGL会計期間のオープン期間に相当するか
            IF ( xx03_gl_period_status_rec.closing_status IS NOT NULL AND
                 xx03_gl_period_status_rec.closing_status != 'O' ) THEN
              -- GL会計期間未オープンエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
          -- 起票部門の部門コードの決算担当（部門セグメントのATTRIBUTE2）が”N"の場合
          ELSE
            -- ③入力された会計期間がGL会計期間およびGL部門入力会計期間のオープン期間に該当するか
            IF ( xx03_gl_period_status_rec.attribute5 IS NOT NULL AND
                 xx03_gl_period_status_rec.attribute5 != 'O' )    OR
               ( xx03_gl_period_status_rec.closing_status IS NOT NULL AND
                 xx03_gl_period_status_rec.closing_status != 'O' ) THEN
              -- GL会計期間未オープンエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
              ln_err_cnt := ln_err_cnt + 1;
            ELSE
              -- ④会計期間が調整期間でないか
              IF xx03_gl_period_status_rec.adj_flag = 'Y' THEN
                -- GL会計期間未オープンエラー
                errflg_tbl(ln_err_cnt) := 'E';
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14012');
                ln_err_cnt := ln_err_cnt + 1;
              END IF;
            END IF;
          END IF;
        END IF;
        CLOSE xx03_gl_period_status_cur;
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
-- Ver11.5.10.1.6G Add start
-- ヘッダーのマスターチェック実施
        --2006/03/06 Ver11.5.10.1.6J Change Start
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
        --2006/03/06 Ver11.5.10.1.6J Change End
--
-- 2006/02/15 Ver11.5.10.1.6G Add END
--
-- ver 11.5.10.2.9 Add Start
        -- ver 11.5.10.2.10B Chg Start
        ----通貨マスタチェック
        --OPEN xx03_inv_currency_cur(lv_chk_currency_code);
        --FETCH xx03_inv_currency_cur INTO xx03_inv_currency_rec;
        --IF xx03_inv_currency_rec.exist_check = 0 THEN
        --  -- 通貨チェックエラー
        --  errflg_tbl(ln_err_cnt) := 'E';
        --  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
        --  ln_err_cnt := ln_err_cnt + 1;
        --END IF;
        --CLOSE xx03_inv_currency_cur;
        --
        --通貨チェック(精度チェック用に精度を取得するように変更)
        OPEN xx03_inv_currency_cur(lv_chk_currency_code);
        FETCH xx03_inv_currency_cur INTO xx03_inv_currency_rec;
        IF (xx03_inv_currency_cur%NOTFOUND) THEN
          -- 通貨チェックエラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-14150','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
--
          lb_currency_chk := FALSE;
          ln_currency_precision := 0;
        ELSE
          lb_currency_chk := TRUE;
          ln_currency_precision := xx03_inv_currency_rec.PRECISION;
        END IF;
        CLOSE xx03_inv_currency_cur;
        -- ver 11.5.10.2.10B Chg End
--
        --換算済貸借金額一致チェック
        IF ln_chk_total_dr != ln_chk_total_cr THEN
          -- 換算済貸借不一致エラー
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11567','SLIP_NUM','');
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
-- ver 11.5.10.2.9 Add End
--
        -- 税金オプション表検索
        OPEN gl_tax_options_cur(
            ln_books_id,         -- 1.帳簿ID
            ln_org_id            -- 2.オルグID
        );
        --読み込み
        FETCH gl_tax_options_cur INTO gl_tax_options_rec;
        IF gl_tax_options_cur%NOTFOUND THEN
          errflg_tbl(ln_err_cnt) := 'E';
          errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11542');
          ln_err_cnt := ln_err_cnt + 1;
        ELSE
          -- 消費税許容範囲カーソル
          OPEN tax_range_check_cur(
            in_journal_id,                                -- 1.伝票ID
            ln_books_id,                                  -- 2.帳簿ID
            gl_tax_options_rec.input_rounding_rule_code,  -- 3.仮払端数処理規則
            gl_tax_options_rec.output_rounding_rule_code  -- 4.仮受端数処理規則
          );
          <<tax_range_check_loop>>
          LOOP
            FETCH tax_range_check_cur INTO tax_range_check_rec;
            EXIT WHEN tax_range_check_cur%NOTFOUND;
--
            --a)許容範囲最大金額チェック
            --変数.差額 := ABS(sum_cal_tax  -  sum_tax )
            --変数.差額 >変数. 許容範囲最大金額の時
            --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
            IF ABS(tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) >
               TO_NUMBER(gl_tax_options_rec.attribute2) THEN
--
              errflg_tbl(ln_err_cnt) := 'W';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03037');
              ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.11 Add Start
              ln_warn_cnt := ln_warn_cnt + 1;
-- ver 11.5.10.2.11 Add End
--
            ELSE
--
              --b)許容範囲率チェック
              --変数.差額 := ABS(sum_cal_tax  -  sum_tax )
              --(変数.差額 / sum_no_tax ) * 100 >変数. 許容範囲率の時
              --エラー情報テーブル出力サブ関数(ins_error_tbl)を呼び出し、エラー情報テーブルを出力します。
              IF tax_range_check_rec.sum_no_tax != 0 THEN
                IF ABS ( (tax_range_check_rec.sum_cal_tax - tax_range_check_rec.sum_tax) / (tax_range_check_rec.sum_no_tax ) * 100 )
                   > TO_NUMBER(gl_tax_options_rec.attribute1) THEN
--
                  errflg_tbl(ln_err_cnt) := 'W';
                  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03038');
                  ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.11 Add Start
                  ln_warn_cnt := ln_warn_cnt + 1;
-- ver 11.5.10.2.11 Add End
--
                END IF;
              ELSE
                IF tax_range_check_rec.sum_tax != 0 THEN
--
                  errflg_tbl(ln_err_cnt) := 'W';
                  errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-03043');
                  ln_err_cnt := ln_err_cnt + 1;
-- ver 11.5.10.2.11 Add Start
                  ln_warn_cnt := ln_warn_cnt + 1;
-- ver 11.5.10.2.11 Add End
--
                END IF;
              END IF;
            END IF;
--
          END LOOP tax_range_check_loop;
--
          CLOSE tax_range_check_cur;
        END IF;
        --カーソルのクローズ
        CLOSE gl_tax_options_cur;
--
        --チェックID取得
        SELECT xx03_err_check_s.NEXTVAL
        INTO   ln_check_seq
        FROM   DUAL;
--
        -- 1件目フラグをおろす
        lv_first_flg := 'N';
      END IF;
--
      -- フレックス・フィールド体系番号の取得
      SELECT sob.chart_of_accounts_id
      INTO   ln_structure_number
      FROM   gl_sets_of_books sob
      WHERE  sob.set_of_books_id = xx00_profile_pkg.VALUE('GL_SET_OF_BKS_ID');
--
      -- 相互検証ルールチェック実行(対象 : ヘッダー以外)
      IF (xx03_xjsjlv_rec.segment1 IS NOT NULL) THEN
        lv_segment_array(1) := xx03_xjsjlv_rec.segment1;
        lv_segment_array(2) := xx03_xjsjlv_rec.segment2;
        lv_segment_array(3) := xx03_xjsjlv_rec.segment3;
        lv_segment_array(4) := xx03_xjsjlv_rec.segment4;
        lv_segment_array(5) := xx03_xjsjlv_rec.segment5;
        lv_segment_array(6) := xx03_xjsjlv_rec.segment6;
        lv_segment_array(7) := xx03_xjsjlv_rec.segment7;
        lv_segment_array(8) := xx03_xjsjlv_rec.segment8;
--
        lb_retcode := FND_FLEX_EXT.GET_COMBINATION_ID(
                        application_short_name => lv_app_short_name,
                        key_flex_code => lv_key_flex_code,
                        structure_number => ln_structure_number,
        -- 2006/01/30 Ver11.5.10.1.6E Change Start
        --              validation_date => ld_validation_date,
                        validation_date => ld_chk_gl_date,
        -- 2006/01/30 Ver11.5.10.1.6E Change End
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
          -- errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11543');
          IF xx03_xjsjlv_rec.entered_dr IS NOT NULL THEN
            errmsg_tbl(ln_err_cnt) := '借方'||xx03_xjsjlv_rec.line_number||':'||FND_FLEX_EXT.GET_MESSAGE;
          ELSIF xx03_xjsjlv_rec.entered_cr IS NOT NULL THEN
            errmsg_tbl(ln_err_cnt) := '貸方'||xx03_xjsjlv_rec.line_number||':'||FND_FLEX_EXT.GET_MESSAGE;
          ELSE
            errmsg_tbl(ln_err_cnt) := xx03_xjsjlv_rec.line_number||':'||FND_FLEX_EXT.GET_MESSAGE;
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
--
-- Ver11.5.10.1.6G Add Start
-- 明細のマスター値チェックを実施する
      --明細行のみチェックする
      IF xx03_xjsjlv_rec.line_type_lookup_code = 'ITEM' THEN
--
        IF (xx03_xjsjlv_rec.entered_dr IS NOT NULL) THEN
--
          --適用コード入力チェック
          OPEN  xx03_jsl_slt_dr_cur(xx03_xjsjlv_rec.line_number);     -- 1.明細番号
          FETCH xx03_jsl_slt_dr_cur INTO xx03_jsl_slt_dr_rec;
          CLOSE xx03_jsl_slt_dr_cur;
--
          IF xx03_jsl_slt_dr_rec.exist_check != 0 THEN
            --適用コード入力時、マスタチェック
            OPEN xx03_slip_line_type_dr_cur(
              xx03_xjsjlv_rec.line_number,    -- 1.明細番号
              ld_chk_gl_date                  -- 2.GL記帳日
            );
            FETCH xx03_slip_line_type_dr_cur INTO xx03_slip_line_type_dr_rec;
            IF xx03_slip_line_type_dr_rec.exist_check = 0 THEN
              -- 適用コードエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11560','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            CLOSE xx03_slip_line_type_dr_cur;
          END IF;
-- ver 11.5.10.2.9 Add Start
          lv_chk_dr_cr := 'DR';
-- ver 11.5.10.2.9 Add End
--
        ELSIF (xx03_xjsjlv_rec.entered_cr IS NOT NULL) THEN
--
          --適用コード入力チェック
          OPEN  xx03_jsl_slt_cr_cur(xx03_xjsjlv_rec.line_number);     -- 1.明細番号
          FETCH xx03_jsl_slt_cr_cur INTO xx03_jsl_slt_cr_rec;
          CLOSE xx03_jsl_slt_cr_cur;
--
          IF xx03_jsl_slt_cr_rec.exist_check != 0 THEN
            --適用コード入力時、マスタチェック
            OPEN xx03_slip_line_type_cr_cur(
              xx03_xjsjlv_rec.line_number,    -- 1.明細番号
              ld_chk_gl_date                  -- 2.GL記帳日
            );
            FETCH xx03_slip_line_type_cr_cur INTO xx03_slip_line_type_cr_rec;
            IF xx03_slip_line_type_cr_rec.exist_check = 0 THEN
              -- 適用コードエラー
              errflg_tbl(ln_err_cnt) := 'E';
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11561','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
            CLOSE xx03_slip_line_type_cr_cur;
          END IF;
-- ver 11.5.10.2.9 Add Start
          lv_chk_dr_cr := 'CR';
-- ver 11.5.10.2.9 Add End
--
        END IF;
--
-- ver 11.5.10.2.9 Add Start
        --税金コードマスタチェック
        OPEN xx03_line_tax_cur(
          xx03_xjsjlv_rec.line_number    -- 1.明細番号
         ,lv_chk_dr_cr                   -- 2.貸借フラグ
         ,ld_chk_gl_date                 -- 3.GL記帳日
        );
        FETCH xx03_line_tax_cur INTO xx03_line_tax_rec;
        IF xx03_line_tax_rec.exist_check = 0 THEN
          -- 税金コードエラー
          errflg_tbl(ln_err_cnt) := 'E';

          IF lv_chk_dr_cr = 'DR' THEN
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11565','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
          ELSE
            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11566','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
          END IF;
          ln_err_cnt := ln_err_cnt + 1;
        END IF;
        CLOSE xx03_line_tax_cur;
--
        -- ver 11.5.10.2.10B Add Start
        -- 通貨が正しく入力されている場合はチェック
        IF lb_currency_chk = TRUE THEN
--
          -- 伝票金額の精度を取得
          IF lv_chk_dr_cr = 'DR' THEN
            lv_amount := TO_CHAR(xx03_xjsjlv_rec.entered_dr);
          ELSIF lv_chk_dr_cr = 'CR' THEN
            lv_amount := TO_CHAR(xx03_xjsjlv_rec.entered_cr);
          END IF;
--
          IF INSTR(lv_amount ,cv_precision_char) = 0 THEN
            ln_amount_precision := 0;
          ELSE
            ln_amount_precision := LENGTH(lv_amount) - INSTR(TO_CHAR(lv_amount) ,cv_precision_char);
          END IF;
--
          -- 伝票金額の精度が通貨の精度を超えていればエラー
          IF ln_currency_precision < ln_amount_precision THEN
            errflg_tbl(ln_err_cnt) := 'E';
            IF lv_chk_dr_cr = 'DR' THEN
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11576','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            ELSIF lv_chk_dr_cr = 'CR' THEN
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11577','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            END IF;
            ln_err_cnt := ln_err_cnt + 1;
          END IF;
--
        END IF;
        -- ver 11.5.10.2.10B Add End
--
        --機能通貨時入力換算金額一致チェック
        IF lv_currency_code = lv_chk_currency_code THEN
--
          OPEN xx03_enter_account_cur(
            xx03_xjsjlv_rec.line_number    -- 1.明細番号
           ,lv_chk_dr_cr                   -- 2.貸借フラグ
          );
          FETCH xx03_enter_account_cur INTO xx03_enter_account_rec;
--
          IF xx03_enter_account_cur%NOTFOUND THEN
            -- レコードが選択されなかった
            errflg_tbl(ln_err_cnt) := 'E';
-- ver 11.5.10.2.9B Chg Start
--            errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            IF lv_chk_dr_cr = 'DR' THEN
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            ELSE
              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11569','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
            END IF;
-- ver 11.5.10.2.9B Chg End
            ln_err_cnt := ln_err_cnt + 1;
          ELSE
            IF ( xx03_enter_account_rec.accounted_amount !=   xx03_enter_account_rec.entered_item_amount
                                                            + xx03_enter_account_rec.entered_tax_amount ) THEN
              -- レートの値が異なる
              errflg_tbl(ln_err_cnt) := 'E';
-- ver 11.5.10.2.9B Chg Start
--              errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              IF lv_chk_dr_cr = 'DR' THEN
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11568','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              ELSE
                errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XX03', 'APP-XX03-11569','SLIP_NUM','','TOK_COUNT',xx03_xjsjlv_rec.line_number);
              END IF;
-- ver 11.5.10.2.9B Chg End
              ln_err_cnt := ln_err_cnt + 1;
            END IF;
          END IF;
          CLOSE xx03_enter_account_cur;
        END IF;
-- ver 11.5.10.2.9 Add End
--
      END IF;
-- Ver11.5.10.1.6G Add End
--
      END IF; -- xx03_xjsjlv_rec.segment1 IS NOT NULL
--
-- 2013/09/19 ver 11.5.10.2.12 ADD START
      -- 項目整合性チェック
      OPEN xx03_save_code_chk_cur(
               in_org_id          => ln_org_id    -- 営業単位ID
             , in_set_of_books_id => ln_books_id  -- 会計帳簿ID
           );
      FETCH xx03_save_code_chk_cur INTO xx03_save_code_chk_rec;
      -- 存在チェック件数が1件でも存在する場合
      IF ( xx03_save_code_chk_rec.exist_check <> 0 ) THEN
        -- 項目相違エラー
        errflg_tbl(ln_err_cnt) := 'E';
        errmsg_tbl(ln_err_cnt) := xx00_message_pkg.get_msg('XXCFO', 'APP-XXCFO1-00049');
        ln_err_cnt := ln_err_cnt + 1;
      END IF;
      CLOSE xx03_save_code_chk_cur;
-- 2013/09/19 ver 11.5.10.2.12 ADD END
--
-- ver 11.5.10.2.9 Add Start
      -- 部門入力エラーチェックでエラーがあった場合はその時点でループ終了
-- ver 11.5.10.2.11 Cng Start
--      IF ( ln_err_cnt > 0 ) THEN
      IF ( ln_err_cnt > 0 ) AND 
         ( ln_err_cnt - ln_warn_cnt <> 0 ) THEN
-- ver 11.5.10.2.11 Cng End
        -- データ終了
        EXIT xx03_xjsjlv_loop;
      END IF;
-- ver 11.5.10.2.9 Add End
--
      -- エラーチェックテーブル書き込み
      IF ( xx03_xjsjlv_rec.line_number = 0 ) THEN
        -- Ver11.5.10.1.6C 2006/01/16 Change Start
        -- -- ヘッダレコード
        --INSERT INTO xx03_error_checks(
        --  CHECK_ID,
        --  JOURNAL_ID,
        --  LINE_NUMBER,
        --  GL_DATE,
        --  PERIOD_NAME,
        --  CURRENCY_CODE,
        --  CODE_COMBINATION_ID,
        --  SEGMENT1,
        --  SEGMENT2,
        --  SEGMENT3,
        --  SEGMENT4,
        --  SEGMENT5,
        --  SEGMENT6,
        --  SEGMENT7,
        --  SEGMENT8,
        --  TAX_CODE,
        --  INCR_DECR_REASON_CODE,
        --  SLIP_NUMBER,
        --  INPUT_DEPARTMENT,
        --  INPUT_USER,
        --  ORIG_SLIP_NUMBER,
        --  RECON_REFERENCE,
        --  ENTERED_DR,
        --  ENTERED_CR,
        --  ATTRIBUTE_CATEGORY,
        --  ATTRIBUTE1,
        --  ATTRIBUTE2,
        --  ATTRIBUTE3,
        --  ATTRIBUTE4,
        --  ATTRIBUTE5,
        --  ATTRIBUTE6,
        --  ATTRIBUTE7,
        --  ATTRIBUTE8,
        --  ATTRIBUTE9,
        --  ATTRIBUTE10,
        --  ATTRIBUTE11,
        --  ATTRIBUTE12,
        --  ATTRIBUTE13,
        --  ATTRIBUTE14,
        --  ATTRIBUTE15,
        --  ATTRIBUTE16,
        --  ATTRIBUTE17,
        --  ATTRIBUTE18,
        --  ATTRIBUTE19,
        --  ATTRIBUTE20,
        --  CREATED_BY,
        --  CREATION_DATE,
        --  LAST_UPDATED_BY,
        --  LAST_UPDATE_DATE,
        --  LAST_UPDATE_LOGIN,
        --  REQUEST_ID,
        --  PROGRAM_APPLICATION_ID,
        --  PROGRAM_UPDATE_DATE,
        --  PROGRAM_ID
        --) VALUES (
        --  ln_check_seq,
        --  xx03_xjsjlv_rec.journal_num,
        --  xx03_xjsjlv_rec.line_number,
        --  xx03_xjsjlv_rec.gl_date,
        --  null,
        --  xx03_xjsjlv_rec.invoice_currency_code,
        --  xx03_xjsjlv_rec.code_combination_id,
        --  xx03_xjsjlv_rec.segment1,
        --  xx03_xjsjlv_rec.segment2,
        --  xx03_xjsjlv_rec.segment3,
        --  xx03_xjsjlv_rec.segment4,
        --  xx03_xjsjlv_rec.segment5,
        --  xx03_xjsjlv_rec.segment6,
        --  xx03_xjsjlv_rec.segment7,
        --  xx03_xjsjlv_rec.segment8,
        --  null,
        --  null,
        --  xx03_xjsjlv_rec.journal_num,
        --  xx03_xjsjlv_rec.entry_department,
        --  xx03_xjsjlv_rec.user_name,
        --  null,
        --  null,
        --  xx03_xjsjlv_rec.entered_dr,
        --  xx03_xjsjlv_rec.entered_cr,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  null,
        --  xx00_global_pkg.user_id,
        --  xx00_date_pkg.get_system_datetime_f,
        --  xx00_global_pkg.user_id,
        --  xx00_date_pkg.get_system_datetime_f,
        --  xx00_global_pkg.login_id,
        --  xx00_global_pkg.conc_request_id,
        --  xx00_global_pkg.prog_appl_id,
        --  xx00_date_pkg.get_system_datetime_f,
        --  xx00_global_pkg.conc_program_id
        --);
        NULL;
        -- Ver11.5.10.1.6C 2006/01/16 Change End
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
          xx03_xjsjlv_rec.journal_num,
          xx03_xjsjlv_rec.line_number,
          xx03_xjsjlv_rec.gl_date,
-- 2005/1/19 Ver11.5.10.1.6D Add Start
--          null,
          xx03_xjsjlv_rec.PERIOD_NAME,
-- 2005/1/19 Ver11.5.10.1.6D Add End
          xx03_xjsjlv_rec.invoice_currency_code,
          xx03_xjsjlv_rec.code_combination_id,
          xx03_xjsjlv_rec.segment1,
          xx03_xjsjlv_rec.segment2,
          xx03_xjsjlv_rec.segment3,
          xx03_xjsjlv_rec.segment4,
          xx03_xjsjlv_rec.segment5,
          xx03_xjsjlv_rec.segment6,
          xx03_xjsjlv_rec.segment7,
          xx03_xjsjlv_rec.segment8,
          xx03_xjsjlv_rec.tax_code,
          xx03_xjsjlv_rec.incr_decr_reason_code,
          xx03_xjsjlv_rec.journal_num,
          xx03_xjsjlv_rec.entry_department,
          xx03_xjsjlv_rec.user_name,
          null,
          xx03_xjsjlv_rec.recon_reference,
          xx03_xjsjlv_rec.entered_dr,
          xx03_xjsjlv_rec.entered_cr,
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
    END LOOP xx03_xjsjlv_loop;
    CLOSE xx03_xjsjlv_cur;
--
-- ver 11.5.10.2.11 Cng Start
---- ver 11.5.10.2.9C Add Start
--    -- 部門入力エラーチェックでエラーがなかった場合のみ共通エラーチェック実行
--    IF ( ln_err_cnt <= 0 ) THEN
---- ver 11.5.10.2.9C Add End
    -- 部門入力エラーチェックで正常、もしくは警告の場合、共通エラーチェク実行
    IF ( ln_err_cnt <= 0 ) OR 
       ( ln_err_cnt > 0 AND ln_err_cnt - ln_warn_cnt <= 0 ) THEN
-- ver 11.5.10.2.11 Cng End
--
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
          -- Ver11.5.10.1.6C 2006/01/16 Delete Start
          -- -- 不要なエラーは削除
          --IF xx03_errchk_result_rec.line_number = '0' AND
          --   ( xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT1'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT2'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT3'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT4'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT5'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT6'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT7'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03089',
          --                                              'TOK_XX03_SEGMENT_PROMPT',
          --                                              xx03_get_prompt_pkg.aff_segment('SEGMENT8'))     OR  -- AFF未指定
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03039') OR  -- CF組合せマスタ取得エラー
          --     xx03_errchk_result_rec.error_message = xx00_message_pkg.get_msg('XX03', 'APP-XX03-03013',     -- 勘定科目組合せエラー
          --                                              'TOK_XX03_NOT_GET_KEY', 'CCID',
          --                                              'TOK_XX03_NOT_GET_VALUE', '')
          --   ) THEN
          --  ln_err_cnt := ln_err_cnt - 1;
          --ELSE
          -- Ver11.5.10.1.6C 2006/01/16 Delete End
            -- エラー件数が20件以下の時のみエラー情報セット
            errflg_tbl(ln_err_cnt) := xx03_errchk_result_rec.status;
-- ver 11.5.10.2.10 Chg Start
--            errmsg_tbl(ln_err_cnt) := xx03_errchk_result_rec.dr_cr ||
--                                      TRUNC(xx03_errchk_result_rec.line_number) || '：' ||
--                                      xx03_errchk_result_rec.error_message;
            if xx03_errchk_result_rec.line_number = 0 THEN
              lv_je_err_msg := 'APP-XX03-14164';
            elsif (xx03_errchk_result_rec.line_number - TRUNC(xx03_errchk_result_rec.line_number)) = 0.5 THEN
              lv_je_err_msg := 'APP-XX03-14166';
            else
              lv_je_err_msg := 'APP-XX03-14165';
            end if;
            errmsg_tbl(ln_err_cnt) := xx03_errchk_result_rec.dr_cr ||
                                      TRUNC(xx03_errchk_result_rec.line_number) || '：' ||
                                      xx03_errchk_result_rec.error_message ||
                                      xx00_message_pkg.get_msg('XX03',lv_je_err_msg);
-- ver 11.5.10.2.10 Chg End
          -- Ver11.5.10.1.6C 2006/01/16 Delete Start
          --END IF;
          -- Ver11.5.10.1.6C 2006/01/16 Delete End
        END IF;
        ln_err_cnt := ln_err_cnt + 1;
--
      END LOOP xx03_errchk_result_loop;
      CLOSE xx03_errchk_result_cur;
    END IF;
--
-- ver 11.5.10.2.9C Add Start
    END IF;
-- ver 11.5.10.2.9C Add End
--
-- ver 11.5.10.1.6H Add Start
    IF ln_check_seq != 0 THEN
-- ver 11.5.10.1.6H Add End
      -- エラーチェック、エラー情報データ削除
    DELETE FROM xx03_error_checks xec
          WHERE xec.check_id = ln_check_seq;
    DELETE FROM xx03_error_info xei
          WHERE xei.check_id = ln_check_seq;
-- ver 11.5.10.1.6H Add Start
    END IF;
-- ver 11.5.10.1.6H Add End
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
      IF xx03_xjsjlv_cur%ISOPEN THEN
        CLOSE xx03_xjsjlv_cur;
      END IF;
      IF xx03_rate_cur%ISOPEN THEN
        CLOSE xx03_rate_cur;
      END IF;
      IF xx03_orig_num_cur%ISOPEN THEN
        CLOSE xx03_orig_num_cur;
      END IF;
      IF xx03_gl_period_status_cur%ISOPEN THEN
        CLOSE xx03_gl_period_status_cur;
      END IF;
      IF xx03_errchk_result_cur%ISOPEN THEN
        CLOSE xx03_errchk_result_cur;
      END IF;
--
-- ver11.5.10.1.6G Add Start
      IF xx03_approver_cur%ISOPEN THEN
        CLOSE xx03_approver_cur;
      END IF;
      IF xx03_jsl_slt_dr_cur%ISOPEN THEN
        CLOSE xx03_jsl_slt_dr_cur;
      END IF;
      IF xx03_slip_line_type_dr_cur%ISOPEN THEN
        CLOSE xx03_slip_line_type_dr_cur;
      END IF;
      IF xx03_jsl_slt_cr_cur%ISOPEN THEN
        CLOSE xx03_jsl_slt_cr_cur;
      END IF;
      IF xx03_slip_line_type_cr_cur%ISOPEN THEN
        CLOSE xx03_slip_line_type_cr_cur;
      END IF;
-- ver11.5.10.1.6G Add End
--
--###############################  固定例外処理部 START   ###################################
--
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
        (-20000,SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM||':'||ln_check_seq||':'||xx03_xjsjlv_rec.journal_num||':'||xx03_xjsjlv_rec.line_number,1,5000),TRUE);
--
--###################################  固定部 END   #########################################
--
  END check_deptinput_gl;
--
  /**********************************************************************************
   * Procedure Name   : set_account_approval_flag
   * Description      : 重点管理チェック
   ***********************************************************************************/
  PROCEDURE set_account_approval_flag(
    in_journal_id IN  NUMBER,    -- 1.チェック対象仕訳伝票ID
    ov_app_upd    OUT VARCHAR2,  -- 2.重点管理更新内容
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_gl_check_pkg.set_account_approval_flag'; -- プログラム名
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
    ln_head_acc_amount NUMBER;       -- 換算済借方合計金額
    lv_slip_type VARCHAR2(25);       -- ヘッダ伝票種別
    lv_gl_app_flag VARCHAR2(240);    -- GL重点管理不要フラグ
    lv_detail_first_flg VARCHAR2(1); -- 明細読込1件目フラグ
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
    -- 仕訳明細情報取得カーソル
    CURSOR xx03_detail_info_cur
    IS
      SELECT xav.attribute7 as attribute7
        FROM xx03_journal_slip_lines xjsl,
             xx03_accounts_v xav
       WHERE xjsl.journal_id = in_journal_id
         AND xjsl.segment3 = xav.flex_value;
--
    -- *** ローカル・レコード ***
    -- 伝票種別マスタ情報取得カーソルレコード型
    xx03_slip_type_rec       xx03_slip_type_cur%ROWTYPE;
    -- 仕訳明細情報取得カーソルレコード型
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
    -- 仕訳ヘッダレコード取得
    SELECT ABS(
             ROUND((xjs.total_item_entered_dr + xjs.total_tax_entered_dr) * NVL(xjs.exchange_rate, 1))
           ) as total_accounted_amount,
           xjs.slip_type as slip_type,
           xdv.attribute3 as gl_app_flag
      INTO ln_head_acc_amount,
           lv_slip_type,
           lv_gl_app_flag
      FROM xx03_journal_slips xjs,
           xx03_departments_v xdv
     WHERE xjs.journal_id = in_journal_id
     AND   xjs.entry_department = xdv.flex_value;
--
    -- 起票部門がGL重点管理不要部門かの判断
    IF lv_gl_app_flag = 'Y' THEN
      ov_app_upd := 'N';
    ELSE
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
      -- 仕訳明細配分レコード取得
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
   * Procedure Name   : del_journal_data
   * Description      : 仕訳伝票レコードの削除
   ***********************************************************************************/
  PROCEDURE del_journal_data(
    in_journal_id IN  NUMBER,    -- 1.削除対象仕訳伝票ID
    ov_errbuf     OUT VARCHAR2,  --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,  --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)  --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --自律トランザクション化
    -- ===============================
    -- ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) :=
      'xx03_deptinput_gl_check_pkg.del_journal_data'; -- プログラム名
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
-- 2005-01-06 ADD START
    cn_wf_status_save CONSTANT xx03_journal_slips.wf_status%TYPE   := '00';
    cn_delete_yes     CONSTANT xx03_journal_slips.delete_flag%TYPE := 'Y';
-- 2005-01-06 ADD END
--
    -- *** ローカル変数 ***
-- 2005-01-06 ADD START
    lv_wf_status        xx03_journal_slips.wf_status%TYPE;
-- 2005-01-06 ADD END
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
    SELECT xjs.wf_status
    INTO   lv_wf_status
    FROM   xx03_journal_slips xjs
    WHERE  xjs.journal_id = in_journal_id;
--
    -- 保存伝票は物理削除を行う
    IF lv_wf_status = cn_wf_status_save THEN
--
        -- 仕訳伝票明細レコード削除
        DELETE FROM xx03_journal_slip_lines xjsl
        WHERE xjsl.journal_id = in_journal_id;
--
        -- 仕訳伝票ヘッダレコード削除
        DELETE FROM xx03_journal_slips xjs
        WHERE xjs.journal_id = in_journal_id;
--
    -- 保存以外の場合は論理削除を行う
    ELSE
        -- 仕訳伝票ヘッダレコード更新
        UPDATE xx03_journal_slips
        SET    delete_flag = cn_delete_yes
              ,last_update_date = SYSDATE
        WHERE  journal_id = in_journal_id;
    END IF;
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
  END del_journal_data;
--
-- ver11.5.10.1.6F Add Start
  /**********************************************************************************
   * Procedure Name   : check_deptinput_gl_input
   * Description      : 部門入力(GL)のエラーチェック(画面用)
   ***********************************************************************************/
  PROCEDURE check_deptinput_gl_input(
    in_journal_id    IN   NUMBER,    -- 1.チェック対象請求書ID
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
      'xx03_deptinput_gl_check_pkg.check_deptinput_gl_input'; -- プログラム名
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
    xx03_deptinput_gl_check_pkg.check_deptinput_gl(
      in_journal_id,
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
      UPDATE xx03_journal_slips xjs
      SET    xjs.request_enable_flag = 'W'
      WHERE  xjs.journal_id = in_journal_id;
    ELSE
      -- 警告以外の場合は申請可能フラグに'Y'セット
      UPDATE xx03_journal_slips xjs
      SET    xjs.request_enable_flag = 'Y'
      WHERE  xjs.journal_id = in_journal_id;
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
  END check_deptinput_gl_input;
-- ver11.5.10.1.6F Add End
--
END xx03_deptinput_gl_check_pkg;
/
