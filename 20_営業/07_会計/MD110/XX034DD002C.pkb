CREATE OR REPLACE PACKAGE BODY APPS.XX034DD002C
AS
/*****************************************************************************************
 * 
 * Copyright(c)Oracle Corporation Japan, 2005. All rights reserved.
 *
 * Package Name     : XX034DD002C(body)
 * Description      : インターフェーステーブルからの仕訳伝票データインポート
 * MD.050(CMD.040)  : 部門入力バッチ処理（GL）       OCSJ/BFAFIN/MD050/F602
 * MD.070(CMD.050)  : 部門入力（GL）データインポート OCSJ/BFAFIN/MD070/F602/03
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  print_header           ヘッダ情報出力
 *  ins_header_data        伝票ヘッダレコードインサート
 *  ins_detail_data        伝票明細レコードインサート
 *  check_header_data      伝票ヘッダデータの入力チェック
 *  check_detail_data      伝票明細データの入力チェック
 *  check_head_line_new    伝票データの（ヘッダ明細関連による）入力チェック
 *  copy_if_data           インターフェースデータのコピー（コントロールメイン）
 *  update_slip_number     請求書番号管理テーブルの更新
 *  out_result             終了処理
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------ -------------- -------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -------------------------------------------------
 *  2004/11/10   1.0            新規作成
 *  2005/06/09   11.5.10.1.3    勘定科目取得エラー,予備名称取得不具合に対応
 *  2005/09/05   11.5.10.1.5    パフォーマンス改善対応
 *  2005/10/20   11.5.10.1.5B   承認者ビューとの結合不具合対応
 *  2005/10/20   11.5.10.1.6    税金コードの有効チェック対応
 *                              ヘッダ明細情報カーソルにて税区分取得時に
 *                              請求書日付において有効な税区分を取得するように変更
 *  2005/12/19   11.5.10.1.6B   承認者の判断基準の修正対応
 *  2005/12/28   11.5.10.1.6C   伝票種別にアプリケーション毎の絞込みを追加
 *  2006/01/06   11.5.10.1.6D   伝票番号の採番条件にオルグを追加
 *  2006/03/01   11.5.10.1.6E   各タイミングで異なるマスタチェックを同じにする
 *  2006/05/08   11.5.10.2.2    ゼロ円明細取込対応、それに伴いチェック項目の変更
 *  2006/05/08   11.5.10.2.2B   エラー時のメッセージ誤りの修正
 *  2006/09/05   11.5.10.2.5    アップロード処理で複数ユーザの同時実行可能とする
 *                              制御の誤り、データ削除処理の誤り修正
 *                              メッセージコードの誤り修正
 *  2006/09/15   11.5.10.2.5B   明細の入力していない貸借の金額に0が設定される修正
 *  2006/09/20   11.5.10.2.5C   同時実行を可能とする対応の再修正
 *  2006/10/04   11.5.10.2.6    マスタチェックの見直し(有効日のチェックを請求書日付で
 *                              行なう項目とSYSDATEで行なう項目を再確認)
 *  2007/02/23   11.5.10.2.7    プログラム実行時のユーザ・職責に紐付くメニューに
 *                              登録されている伝票種別かのチェックを追加
 *  2007/07/17   11.5.10.2.10   マスタチェックの追加(明細：税区分貸方/借方,増減事由)
 *  2007/10/10   11.5.10.2.10B  パフォーマンス対応のため承認者のチェックSQLを
 *                              メインSQLへ組み込むように修正
 *  2007/10/29   11.5.10.2.10C  通貨の精度チェック(入力可能精度か桁チェック)追加のため
 *                              伝票情報取得時に通貨書式に丸める処理を削除
 *  2016/11/04   1.1            障害対応E_本稼動_13901
 *  2020/06/17   1.2            障害対応E_本稼動_16418
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
  -- ===============================
  -- グローバル定数
  -- ===============================
  cv_appli_cd         CONSTANT VARCHAR2(30)  := 'GL';                      --アプリケーション種別2
  cv_package_name     CONSTANT VARCHAR2(20)  := 'XX034DD002';              --パッケージ名
  cv_yes              CONSTANT VARCHAR2(1)   := 'Y';  --はい
  cv_no               CONSTANT VARCHAR2(1)   := 'N';  --いいえ
  cv_dept_normal      CONSTANT VARCHAR2(1)   := 'S';  -- 仕訳チェック結果（正常）
  cv_dept_warning     CONSTANT VARCHAR2(1)   := 'W';  -- 仕訳チェック結果（警告）
  cv_dept_error       CONSTANT VARCHAR2(1)   := 'E';  -- 仕訳チェック結果（エラー）
  cv_result_normal    CONSTANT VARCHAR2(1)   := '0';  -- 終了ステータス（正常）
  cv_result_warning   CONSTANT VARCHAR2(1)   := '1';  -- 終了ステータス（警告）
  cv_result_error     CONSTANT VARCHAR2(1)   := '2';  -- 終了ステータス（エラー）
--
  -- ver 11.5.10.2.7 Add Start
  cv_menu_url_inp   CONSTANT VARCHAR2(100) := 'OA.jsp?page=/oracle/apps/xx03/gl/input/webui/Xx03JournalInputPG';
  -- ver 11.5.10.2.7 Add End
--
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_journal_id NUMBER;       -- 伝票ID
  gn_error_count NUMBER;      -- エラー件数
  gv_result VARCHAR2(1);      -- チェック結果ステータス
--
-- Ver11.5.10.1.5 2005/09/06 Add Start
  gn_org_id      NUMBER;              -- オルグID
  gv_cur_code    VARCHAR2(15);        -- 機能通貨コード
-- Ver11.5.10.1.5 2005/09/06 Add End
  -- ===============================
  -- グローバルカーソル
  -- ===============================
--
-- Ver11.5.10.1.5 2005/09/06 Delete Start
--  -- ヘッダ情報カーソル
--  CURSOR xx03_if_header_cur(h_source VARCHAR2,
--                            h_request_id NUMBER)
--  IS
--    SELECT 
--      xjsi.INTERFACE_ID as INTERFACE_ID,                        -- インターフェースID
--      xjsi.WF_STATUS as WF_STATUS,                              -- ステータス
--      xstl.LOOKUP_CODE as SLIP_TYPE,                            -- 伝票種別
--      TRUNC(xjsi.ENTRY_DATE, 'DD') as ENTRY_DATE,               -- 起票日
--      xpp.PERSON_ID as REQUESTOR_PERSON_ID,                     -- 申請者
--      xpp.EMPLOYEE_DISP as REQUESTOR_PERSON_NAME,               -- 申請者名
--      xapl.PERSON_ID as APPROVER_PERSON_ID,                     -- 承認者
--      xapl.EMPLOYEE_DISP as APPROVER_PERSON_NAME,               -- 承認者名
--      xjsi.INVOICE_CURRENCY_CODE as INVOICE_CURRENCY_CODE,      -- 通貨
--      xjsi.EXCHANGE_RATE as EXCHANGE_RATE,                      -- レート
--      xct.CONVERSION_TYPE as EXCHANGE_RATE_TYPE,                -- レートタイプ
--      xjsi.EXCHANGE_RATE_TYPE_NAME as EXCHANGE_RATE_TYPE_NAME,  -- レートタイプ名
--      xjsi.IGNORE_RATE_FLAG as IGNORE_RATE_FLAG,                -- 換算済金額自動区分
--      xjsi.DESCRIPTION as DESCRIPTION,                          -- 備考
--      xpp.ATTRIBUTE28 as ENTRY_DEPARTMENT,                      -- 起票部門
--      xpp2.PERSON_ID as ENTRY_PERSON_ID,                        -- 伝票入力者
--      xjsi.PERIOD_NAME as PERIOD_NAME,                          -- 会計期間
--      xjsi.GL_DATE as GL_DATE,                                  -- 計上日
--      xgto.CALCULATION_LEVEL_CODE as AUTO_TAX_CALC_FLAG,        -- 消費税計算レベル
--      xgto.INPUT_ROUNDING_RULE_CODE as AP_TAX_ROUNDING_RULE,    -- 消費税端数処理
--      xjsi.ORG_ID as ORG_ID,                                    -- オルグID
--      xjsi.SET_OF_BOOKS_ID as SET_OF_BOOKS_ID,                  -- 会計帳簿ID
--      xjsi.CREATED_BY as CREATED_BY, 
--      xjsi.CREATION_DATE as CREATION_DATE, 
--      xjsi.LAST_UPDATED_BY as LAST_UPDATED_BY, 
--      xjsi.LAST_UPDATE_DATE as LAST_UPDATE_DATE, 
--      xjsi.LAST_UPDATE_LOGIN as LAST_UPDATE_LOGIN, 
--      xjsi.REQUEST_ID as REQUEST_ID, 
--      xjsi.PROGRAM_APPLICATION_ID as PROGRAM_APPLICATION_ID, 
--      xjsi.PROGRAM_ID as PROGRAM_ID, 
--      xjsi.PROGRAM_UPDATE_DATE as PROGRAM_UPDATE_DATE
--     FROM 
--      XX03_JOURNAL_SLIPS_IF xjsi,
--      XX03_SLIP_TYPES_LOV_V xstl,
--      XX03_PER_PEOPLES_V xpp,
--      XX03_PER_PEOPLES_V xpp2,
--      XX03_APPROVER_PERSON_LOV_V xapl,
--      XX03_CONVERSION_TYPES_V xct,
--      XX03_GL_TAX_OPTIONS_V xgto
--     WHERE 
--      xjsi.REQUEST_ID = h_request_id
--      AND xjsi.SOURCE = h_source
--      AND xjsi.SLIP_TYPE_NAME = xstl.DESCRIPTION (+)
--      AND xjsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER (+)
--      AND xjsi.ENTRY_PERSON_NUMBER = xpp2.EMPLOYEE_NUMBER (+)
--      AND xjsi.APPROVER_PERSON_NUMBER = xapl.EMPLOYEE_NUMBER (+)
--      AND xjsi.EXCHANGE_RATE_TYPE_NAME = xct.USER_CONVERSION_TYPE (+)
--      AND xjsi.ORG_ID = xgto.ORG_ID (+)
--      AND xjsi.SET_OF_BOOKS_ID = xgto.SET_OF_BOOKS_ID (+)
--     ORDER BY 
--      xjsi.INTERFACE_ID;
----
--  --  ヘッダ情報カーソルレコード型
--  xx03_if_header_rec    xx03_if_header_cur%ROWTYPE;
----
--  -- 明細情報カーソル
--  CURSOR xx03_if_detail_cur(h_source VARCHAR2,
--                            h_request_id NUMBER,
--                            h_interface_id NUMBER,
--                            h_currency_code VARCHAR2,
--                            s_currency_code VARCHAR2)
--  IS
--    SELECT 
--      xjsli.INTERFACE_ID as INTERFACE_ID,                           -- インターフェースID
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_DR,0,NULL,xjsli.ENTERED_ITEM_AMOUNT_DR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_ITEM_AMOUNT_DR,                         -- 本体金額
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_DR,0,
--                  DECODE(xjsli.ENTERED_TAX_AMOUNT_DR,0,NULL,xjsli.ENTERED_TAX_AMOUNT_DR), xjsli.ENTERED_TAX_AMOUNT_DR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_TAX_AMOUNT_DR,                          -- 消費税額
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_DR,0,
--                  DECODE(xjsli.ACCOUNTED_AMOUNT_DR,0,NULL,xjsli.ACCOUNTED_AMOUNT_DR), xjsli.ACCOUNTED_AMOUNT_DR),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)
--               ) as ACCOUNTED_AMOUNT_DR,                            -- 換算済金額
--      xjsli.AMOUNT_INCLUDES_TAX_FLAG_DR as AMOUNT_INCLUDES_TAX_FLAG_DR,   -- 内税
--      xjsli.TAX_CODE_DR as TAX_CODE_DR,                             -- 税区分
--      xtcl.TAX_CODES_COL as TAX_NAME_DR,                            -- 税区分名
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_CR,0,NULL,xjsli.ENTERED_ITEM_AMOUNT_CR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_ITEM_AMOUNT_CR,                         -- 本体金額
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_CR,0,
--                  DECODE(xjsli.ENTERED_TAX_AMOUNT_CR,0,NULL,xjsli.ENTERED_TAX_AMOUNT_CR), xjsli.ENTERED_TAX_AMOUNT_CR),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--               ) as ENTERED_TAX_AMOUNT_CR,                          -- 消費税額
--      TO_NUMBER(TO_CHAR(DECODE(xjsli.ENTERED_ITEM_AMOUNT_CR,0,
--                  DECODE(xjsli.ACCOUNTED_AMOUNT_CR,0,NULL,xjsli.ACCOUNTED_AMOUNT_CR), xjsli.ACCOUNTED_AMOUNT_CR),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)),
--                  xx00_currency_pkg.get_format_mask(s_currency_code, 38)
--               ) as ACCOUNTED_AMOUNT_CR,                            -- 換算済金額
--      xjsli.AMOUNT_INCLUDES_TAX_FLAG_CR as AMOUNT_INCLUDES_TAX_FLAG_CR,   -- 内税
--      xjsli.TAX_CODE_CR as TAX_CODE_CR,                             -- 税区分
--      xtcl2.TAX_CODES_COL as TAX_NAME_CR,                           -- 税区分名
--      xjsli.DESCRIPTION as DESCRIPTION,                             -- 備考
--      xjsli.SEGMENT1 as SEGMENT1,                                   -- 会社
--      xjsli.SEGMENT2 as SEGMENT2,                                   -- 部門
--      xjsli.SEGMENT3 as SEGMENT3,                                   -- 勘定科目
--      xjsli.SEGMENT4 as SEGMENT4,                                   -- 補助科目
--      xjsli.SEGMENT5 as SEGMENT5,                                   -- 相手先
--      xjsli.SEGMENT6 as SEGMENT6,                                   -- 事業区分
--      xjsli.SEGMENT7 as SEGMENT7,                                   -- プロジェクト
--      xjsli.SEGMENT8 as SEGMENT8,                                   -- 予備
--      xcl.COMPANIES_COL as SEGMENT1_NAME,                           -- 会社名
--      xdl.DEPARTMENTS_COL as SEGMENT2_NAME,                         -- 部門名
--      xal.ACCOUNTS_COL as SEGMENT3_NAME,                            -- 勘定科目名
--      xsal.SUB_ACCOUNTS_COL as SEGMENT4_NAME,                       -- 補助科目名
--      xpal.PARTNERS_COL as SEGMENT5_NAME,                           -- 相手先名
--      xbtl.BUSINESS_TYPES_COL as SEGMENT6_NAME,                     -- 事業区分名
--      xprl.PROJECTS_COL as SEGMENT7_NAME,                           -- プロジェクト名
--    --Ver11.5.10.1.3 Modify START
--      --xjsli.SEGMENT8 as SEGMENT8_NAME,                             -- 予備
--      xfl.FUTURES_COL as SEGMENT8_NAME,                             -- 予備
--    --Ver11.5.10.1.3 Modify END
--      xjsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE,         -- 増減事由
--      xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME,         -- 増減事由名
--      xjsli.RECON_REFERENCE as RECON_REFERENCE,                     -- 消込参照
--      xjsli.ORG_ID as ORG_ID,                                       -- オルグID
--      xjsli.CREATED_BY,
--      xjsli.CREATION_DATE,
--      xjsli.LAST_UPDATED_BY,
--      xjsli.LAST_UPDATE_DATE,
--      xjsli.LAST_UPDATE_LOGIN,
--      xjsli.REQUEST_ID,
--      xjsli.PROGRAM_APPLICATION_ID,
--      xjsli.PROGRAM_ID,
--      xjsli.PROGRAM_UPDATE_DATE
--    FROM 
--      XX03_JOURNAL_SLIP_LINES_IF xjsli,
--      XX03_TAX_CODES_LOV_V xtcl,
--      XX03_TAX_CODES_LOV_V xtcl2,
--      XX03_COMPANIES_LOV_V xcl,
--      XX03_DEPARTMENTS_LOV_V xdl,
--    --Ver11.5.10.1.3 Modify Start
--      --XX03_ACCOUNTS_LOV_V xal,
--      XX03_ACCOUNTS_ALL_LOV_V xal,
--      XX03_FUTURES_LOV_V xfl,
--    --Ver11.5.10.1.3 Modify End
--      XX03_SUB_ACCOUNTS_LOV_V xsal,
--      XX03_PARTNERS_LOV_V xpal,
--      XX03_BUSINESS_TYPES_LOV_V xbtl,
--      XX03_PROJECTS_LOV_V xprl,
--      XX03_INCR_DECR_REASONS_LOV_V xidrl
--    WHERE 
--      xjsli.REQUEST_ID = h_request_id
--      AND xjsli.SOURCE = h_source
--      AND xjsli.INTERFACE_ID = h_interface_id
--      AND xjsli.TAX_CODE_DR = xtcl.NAME (+)
--      AND xjsli.TAX_CODE_CR = xtcl2.NAME (+)
--      AND xjsli.SEGMENT1 = xcl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT2 = xdl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT3 = xal.FLEX_VALUE (+)
--      AND xjsli.SEGMENT4 = xsal.FLEX_VALUE (+)
--      AND xjsli.SEGMENT3 = xsal.PARENT_FLEX_VALUE_LOW (+)
--      AND xjsli.SEGMENT5 = xpal.FLEX_VALUE (+)
--      AND xjsli.SEGMENT6 = xbtl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT7 = xprl.FLEX_VALUE (+)
--    --Ver11.5.10.1.3 add START
--      AND xjsli.SEGMENT8 = xfl.FLEX_VALUE (+)
--    --Ver11.5.10.1.3 add END
--      AND xjsli.INCR_DECR_REASON_CODE = xidrl.FLEX_VALUE (+)
--      AND xjsli.SEGMENT3 = xidrl.PARENT_FLEX_VALUE_LOW (+)
--    ORDER BY 
--      xjsli.LINE_NUMBER;
----
--  -- 明細情報カーソルレコード型
--  xx03_if_detail_rec xx03_if_detail_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/06 Delete End
--
-- Ver11.5.10.1.5 2005/09/06 Add Start
  -- ヘッダ明細情報カーソル
  CURSOR xx03_if_head_line_cur( h_source        VARCHAR2
                               ,h_request_id    NUMBER
                               ,h_base_cur_code VARCHAR2)
  IS
    SELECT
       HEAD.INTERFACE_ID           as HEAD_INTERFACE_ID                  -- インターフェースID
     , HEAD.WF_STATUS              as HEAD_WF_STATUS                     -- ステータス
     , HEAD.SLIP_TYPE              as HEAD_SLIP_TYPE                     -- 伝票種別
-- Ver11.5.10.1.6B Add Start
     , HEAD.SLIP_TYPE_APP          as HEAD_SLIP_TYPE_APP                 -- 伝票種別アプリケーション
-- Ver11.5.10.1.6B Add End
     , HEAD.ENTRY_DATE             as HEAD_ENTRY_DATE                    -- 起票日
     , HEAD.REQUESTOR_PERSON_ID    as HEAD_REQUESTOR_PERSON_ID           -- 申請者
     , HEAD.REQUESTOR_PERSON_NAME  as HEAD_REQUESTOR_PERSON_NAME         -- 申請者名
     , HEAD.APPROVER_PERSON_ID     as HEAD_APPROVER_PERSON_ID            -- 承認者
     , HEAD.APPROVER_PERSON_NAME   as HEAD_APPROVER_PERSON_NAME          -- 承認者名
     , HEAD.INVOICE_CURRENCY_CODE  as HEAD_INVOICE_CURRENCY_CODE         -- 通貨
     , HEAD.EXCHANGE_RATE          as HEAD_EXCHANGE_RATE                 -- レート
     , HEAD.EXCHANGE_RATE_TYPE     as HEAD_EXCHANGE_RATE_TYPE            -- レートタイプ
     , HEAD.EXCHANGE_RATE_TYPE_NAME  as HEAD_EXCHANGE_RATE_TYPE_NAME     -- レートタイプ名
     , HEAD.IGNORE_RATE_FLAG       as HEAD_IGNORE_RATE_FLAG              -- 換算済金額自動区分
     , HEAD.DESCRIPTION            as HEAD_DESCRIPTION                   -- 備考
     , HEAD.ENTRY_DEPARTMENT       as HEAD_ENTRY_DEPARTMENT              -- 起票部門
     , HEAD.ENTRY_PERSON_ID        as HEAD_ENTRY_PERSON_ID               -- 伝票入力者
     , HEAD.PERIOD_NAME            as HEAD_PERIOD_NAME                   -- 会計期間
     , HEAD.GL_DATE                as HEAD_GL_DATE                       -- 計上日
     , HEAD.AUTO_TAX_CALC_FLAG     as HEAD_AUTO_TAX_CALC_FLAG            -- 消費税計算レベル
     , HEAD.AP_TAX_ROUNDING_RULE   as HEAD_AP_TAX_ROUNDING_RULE          -- 消費税端数処理
     , HEAD.ORG_ID                 as HEAD_ORG_ID                        -- オルグID
     , HEAD.SET_OF_BOOKS_ID        as HEAD_SET_OF_BOOKS_ID               -- 会計帳簿ID
     , HEAD.CREATED_BY             as HEAD_CREATED_BY
     , HEAD.CREATION_DATE          as HEAD_CREATION_DATE
     , HEAD.LAST_UPDATED_BY        as HEAD_LAST_UPDATED_BY
     , HEAD.LAST_UPDATE_DATE       as HEAD_LAST_UPDATE_DATE
     , HEAD.LAST_UPDATE_LOGIN      as HEAD_LAST_UPDATE_LOGIN
     , HEAD.REQUEST_ID             as HEAD_REQUEST_ID
     , HEAD.PROGRAM_APPLICATION_ID as HEAD_PROGRAM_APPLICATION_ID
     , HEAD.PROGRAM_ID             as HEAD_PROGRAM_ID
     , HEAD.PROGRAM_UPDATE_DATE    as HEAD_PROGRAM_UPDATE_DATE
     , LINE.INTERFACE_ID           as LINE_INTERFACE_ID                  -- インターフェースID
     , LINE.LINE_NUMBER            as LINE_LINE_NUMBER                   -- 明細番号
     -- ver 11.5.10.2.10C Chg Start
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_ITEM_AMOUNT_DR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_ITEM_AMOUNT_DR        -- 本体金額
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_TAX_AMOUNT_DR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_TAX_AMOUNT_DR         -- 消費税額
     --, TO_NUMBER( TO_CHAR( LINE.ACCOUNTED_AMOUNT_DR
     --                     ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --            )                 as LINE_ACCOUNTED_AMOUNT_DR           -- 換算済金額
     , LINE.ENTERED_ITEM_AMOUNT_DR as LINE_ENTERED_ITEM_AMOUNT_DR        -- 本体金額
     , LINE.ENTERED_TAX_AMOUNT_DR  as LINE_ENTERED_TAX_AMOUNT_DR         -- 消費税額
     , LINE.ACCOUNTED_AMOUNT_DR    as LINE_ACCOUNTED_AMOUNT_DR           -- 換算済金額
     -- ver 11.5.10.2.10C Chg End
     , LINE.AMOUNT_INCLUDES_TAX_FLAG_DR  as LINE_AMOUNT_INC_TAX_FLAG_DR  -- 内税
     , LINE.TAX_CODE_DR            as LINE_TAX_CODE_DR                   -- 税区分
     , LINE.TAX_NAME_DR            as LINE_TAX_NAME_DR                   -- 税区分名
     -- ver 11.5.10.2.10C Chg Start
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_ITEM_AMOUNT_CR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_ITEM_AMOUNT_CR        -- 本体金額
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_TAX_AMOUNT_CR
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_TAX_AMOUNT_CR         -- 消費税額
     --, TO_NUMBER( TO_CHAR( LINE.ACCOUNTED_AMOUNT_CR
     --                     ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(h_base_cur_code, 38)
     --            )                 as LINE_ACCOUNTED_AMOUNT_CR           -- 換算済金額
     , LINE.ENTERED_ITEM_AMOUNT_CR as LINE_ENTERED_ITEM_AMOUNT_CR        -- 本体金額
     , LINE.ENTERED_TAX_AMOUNT_CR  as LINE_ENTERED_TAX_AMOUNT_CR         -- 消費税額
     , LINE.ACCOUNTED_AMOUNT_CR    as LINE_ACCOUNTED_AMOUNT_CR           -- 換算済金額
     -- ver 11.5.10.2.10C Chg End
     , LINE.AMOUNT_INCLUDES_TAX_FLAG_CR  as LINE_AMOUNT_INC_TAX_FLAG_CR  -- 内税
     , LINE.TAX_CODE_CR            as LINE_TAX_CODE_CR                   -- 税区分
     , LINE.TAX_NAME_CR            as LINE_TAX_NAME_CR                   -- 税区分名
     , LINE.DESCRIPTION            as LINE_DESCRIPTION                   -- 備考
     , LINE.SEGMENT1               as LINE_SEGMENT1                      -- 会社
     , LINE.SEGMENT1_NAME          as LINE_SEGMENT1_NAME                 -- 会社名
     , LINE.SEGMENT2               as LINE_SEGMENT2                      -- 部門
     , LINE.SEGMENT2_NAME          as LINE_SEGMENT2_NAME                 -- 部門名
     , LINE.SEGMENT3               as LINE_SEGMENT3                      -- 勘定科目
     , LINE.SEGMENT3_NAME          as LINE_SEGMENT3_NAME                 -- 勘定科目名
     , LINE.SEGMENT4               as LINE_SEGMENT4                      -- 補助科目
     , LINE.SEGMENT4_NAME          as LINE_SEGMENT4_NAME                 -- 補助科目名
     , LINE.SEGMENT5               as LINE_SEGMENT5                      -- 相手先
     , LINE.SEGMENT5_NAME          as LINE_SEGMENT5_NAME                 -- 相手先名
     , LINE.SEGMENT6               as LINE_SEGMENT6                      -- 事業区分
     , LINE.SEGMENT6_NAME          as LINE_SEGMENT6_NAME                 -- 事業区分名
     , LINE.SEGMENT7               as LINE_SEGMENT7                      -- プロジェクト
     , LINE.SEGMENT7_NAME          as LINE_SEGMENT7_NAME                 -- プロジェクト名
     , LINE.SEGMENT8               as LINE_SEGMENT8                      -- 予備
     , LINE.SEGMENT8_NAME          as LINE_SEGMENT8_NAME                 -- 予備名
     , LINE.INCR_DECR_REASON_CODE  as LINE_INCR_DECR_REASON_CODE         -- 増減事由
     , LINE.INCR_DECR_REASON_NAME  as LINE_INCR_DECR_REASON_NAME         -- 増減事由名
     , LINE.RECON_REFERENCE        as LINE_RECON_REFERENCE               -- 消込参照
     , LINE.ORG_ID                 as LINE_ORG_ID                        -- オルグID
-- == 2016/11/04 V1.1 Added START ===============================================================
     , LINE.ATTRIBUTE9             as LINE_ATTRIBUTE9                    -- 稟議決裁番号
-- == 2016/11/04 V1.1 Added END =================================================================
     , LINE.CREATED_BY             as LINE_CREATED_BY
     , LINE.CREATION_DATE          as LINE_CREATION_DATE
     , LINE.LAST_UPDATED_BY        as LINE_LAST_UPDATED_BY
     , LINE.LAST_UPDATE_DATE       as LINE_LAST_UPDATE_DATE
     , LINE.LAST_UPDATE_LOGIN      as LINE_LAST_UPDATE_LOGIN
     , LINE.REQUEST_ID             as LINE_REQUEST_ID
     , LINE.PROGRAM_APPLICATION_ID as LINE_PROGRAM_APPLICATION_ID
     , LINE.PROGRAM_ID             as LINE_PROGRAM_ID
     , LINE.PROGRAM_UPDATE_DATE    as LINE_PROGRAM_UPDATE_DATE
     , CNT.INTERFACE_ID            as CNT_INTERFACE_ID                   -- インターフェースID
     , CNT.REC_COUNT               as CNT_REC_COUNT                      --
     -- ver 11.5.10.2.10B Add Start
     , APPROVER.PERSON_ID          as APPROVER_PERSON_ID
     -- ver 11.5.10.2.10B Add End
    FROM
       (SELECT
           xjsi.INTERFACE_ID         as INTERFACE_ID                  -- インターフェースID
         , xjsi.WF_STATUS            as WF_STATUS                     -- ステータス
         , xstl.LOOKUP_CODE          as SLIP_TYPE                     -- 伝票種別
-- Ver11.5.10.1.6B Add Start
         , xstl.ATTRIBUTE14          as SLIP_TYPE_APP                 -- 伝票種別アプリケーション
-- Ver11.5.10.1.6B Add End
         , TRUNC(xjsi.ENTRY_DATE, 'DD')  as ENTRY_DATE                -- 起票日
         , xpp.PERSON_ID             as REQUESTOR_PERSON_ID           -- 申請者
         , xpp.EMPLOYEE_DISP         as REQUESTOR_PERSON_NAME         -- 申請者名
-- Ver11.5.10.1.5B Chg Start
         --, xapl.PERSON_ID            as APPROVER_PERSON_ID            -- 承認者
         --, xapl.EMPLOYEE_DISP        as APPROVER_PERSON_NAME          -- 承認者名
         , ppf.person_id               as APPROVER_PERSON_ID          -- 承認者
         , ppf.EMPLOYEE_NUMBER || 
           XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || 
           ppf.PER_INFORMATION18 || ' ' || 
           ppf.PER_INFORMATION19       as APPROVER_PERSON_NAME        -- 承認者名
-- Ver11.5.10.1.5B Chg End
         , xjsi.INVOICE_CURRENCY_CODE  as INVOICE_CURRENCY_CODE       -- 通貨
         , xjsi.EXCHANGE_RATE        as EXCHANGE_RATE                 -- レート
         , xct.CONVERSION_TYPE       as EXCHANGE_RATE_TYPE            -- レートタイプ
         , xjsi.EXCHANGE_RATE_TYPE_NAME  as EXCHANGE_RATE_TYPE_NAME   -- レートタイプ名
         , xjsi.IGNORE_RATE_FLAG     as IGNORE_RATE_FLAG              -- 換算済金額自動区分
         , xjsi.DESCRIPTION          as DESCRIPTION                   -- 備考
         , xpp.ATTRIBUTE28           as ENTRY_DEPARTMENT              -- 起票部門
         , xpp2.PERSON_ID            as ENTRY_PERSON_ID               -- 伝票入力者
         , xjsi.PERIOD_NAME          as PERIOD_NAME                   -- 会計期間
         , xjsi.GL_DATE              as GL_DATE                       -- 計上日
         , xgto.CALCULATION_LEVEL_CODE  as AUTO_TAX_CALC_FLAG         -- 消費税計算レベル
         , xgto.INPUT_ROUNDING_RULE_CODE  as AP_TAX_ROUNDING_RULE     -- 消費税端数処理
         , xjsi.ORG_ID               as ORG_ID                        -- オルグID
         , xjsi.SET_OF_BOOKS_ID      as SET_OF_BOOKS_ID               -- 会計帳簿ID
         , xjsi.CREATED_BY           as CREATED_BY
         , xjsi.CREATION_DATE        as CREATION_DATE
         , xjsi.LAST_UPDATED_BY      as LAST_UPDATED_BY
         , xjsi.LAST_UPDATE_DATE     as LAST_UPDATE_DATE
         , xjsi.LAST_UPDATE_LOGIN    as LAST_UPDATE_LOGIN
         , xjsi.REQUEST_ID           as REQUEST_ID
         , xjsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xjsi.PROGRAM_ID           as PROGRAM_ID
         , xjsi.PROGRAM_UPDATE_DATE  as PROGRAM_UPDATE_DATE
        FROM
           XX03_JOURNAL_SLIPS_IF      xjsi
-- ver 11.5.10.2.7 Chg Start
-- -- Ver11.5.10.1.6C Chg Start
-- -- -- Ver11.5.10.1.6B Chg Start
-- -- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION
-- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION,XLXV.ATTRIBUTE14
-- -- -- Ver11.5.10.1.6B Chg End
-- --           FROM  XX03_SLIP_TYPES_V XLXV
-- --           WHERE XLXV.ENABLED_FLAG = 'Y' AND XLXV.ATTRIBUTE14 = 'SQLGL'
-- --           )                          xstl
--          ,(SELECT XSTLV.LOOKUP_CODE,XSTLV.DESCRIPTION,XSTLV.ATTRIBUTE14
--            FROM XX03_SLIP_TYPES_LOV_V XSTLV
--            WHERE XSTLV.ATTRIBUTE14 = 'SQLGL'
--            )                          xstl
         ,(select XSTLV.LOOKUP_CODE , XSTLV.DESCRIPTION , XSTLV.ATTRIBUTE14
             from XX03_SLIP_TYPES_LOV_V XSTLV , FND_FORM_FUNCTIONS FFF
            where XSTLV.ATTRIBUTE14 = 'SQLGL'
              and (   upper(FFF.PARAMETERS) like '%&SLIPTYPE=' || XSTLV.LOOKUP_CODE
                   or upper(FFF.PARAMETERS) like '%&SLIPTYPE=' || XSTLV.LOOKUP_CODE || '&%'
                   or upper(FFF.PARAMETERS) like 'SLIPTYPE='   || XSTLV.LOOKUP_CODE || '&%' )
              and WEB_HTML_CALL = cv_menu_url_inp
              and exists(select '1'
                           from ( (select X.FUNCTION_ID
                                     from ( select MENU_ID MENU_ID , SUB_MENU_ID SUB_MENU_ID , FUNCTION_ID FUNCTION_ID from FND_MENU_ENTRIES where GRANT_FLAG = 'Y'
                                             start with MENU_ID = (select MENU_ID from FND_RESPONSIBILITY where RESPONSIBILITY_ID  = xx00_global_pkg.resp_id) connect by prior SUB_MENU_ID = MENU_ID) X
                                    where X.FUNCTION_ID is not null)
                                  minus
                                  (select B.ACTION_ID FUNCTION_ID
                                     from FND_RESPONSIBILITY A , FND_RESP_FUNCTIONS B
                                    where A.RESPONSIBILITY_ID  = xx00_global_pkg.resp_id and A.APPLICATION_ID = xx00_global_pkg.resp_appl_id
                                      and B.APPLICATION_ID = A.APPLICATION_ID and B.RESPONSIBILITY_ID = A.RESPONSIBILITY_ID and B.RULE_TYPE = 'F')
                                  minus
                                  (select X.FUNCTION_ID
                                     from ( select AA.MENU_ID , AA.SUB_MENU_ID , AA.FUNCTION_ID
                                              from ( ( select MENU_ID MENU_ID , SUB_MENU_ID SUB_MENU_ID , FUNCTION_ID FUNCTION_ID from FND_MENU_ENTRIES where GRANT_FLAG = 'Y')
                                                     union all
                                                     (select 0 MENU_ID , B.ACTION_ID SUB_MENU_ID , null FUNCTION_ID from FND_RESPONSIBILITY A , FND_RESP_FUNCTIONS B
                                                       where A.RESPONSIBILITY_ID = xx00_global_pkg.resp_id and A.APPLICATION_ID = xx00_global_pkg.resp_appl_id
                                                         and B.APPLICATION_ID = A.APPLICATION_ID and B.RESPONSIBILITY_ID = A.RESPONSIBILITY_ID and B.RULE_TYPE = 'M')
                                                    ) AA
                                             start with AA.MENU_ID = 0 connect by prior AA.SUB_MENU_ID = AA.MENU_ID) X )
                                   ) Y
                           where Y.FUNCTION_ID = FFF.FUNCTION_ID)
           )                           xstl
-- ver 11.5.10.2.7 Chg End
-- Ver11.5.10.1.6C Chg End
         , XX03_PER_PEOPLES_V         xpp
         , XX03_PER_PEOPLES_V         xpp2
-- Ver11.5.10.1.5B Chg Start
         --, XX03_APPROVER_PERSON_LOV_V xapl
         , PER_PEOPLE_F               ppf
-- Ver11.5.10.1.5B Chg End
         , XX03_CONVERSION_TYPES_V    xct
         , GL_TAX_OPTIONS             xgto
        WHERE
              xjsi.REQUEST_ID               = h_request_id
          AND xjsi.SOURCE                   = h_source
          AND xjsi.SLIP_TYPE_NAME           = xstl.DESCRIPTION         (+)
          AND xjsi.REQUESTOR_PERSON_NUMBER  = xpp.EMPLOYEE_NUMBER      (+)
          AND xjsi.ENTRY_PERSON_NUMBER      = xpp2.EMPLOYEE_NUMBER     (+)
-- Ver11.5.10.1.5B Chg Start
          --AND xjsi.APPROVER_PERSON_NUMBER   = xapl.EMPLOYEE_NUMBER     (+)
          AND xjsi.APPROVER_PERSON_NUMBER   = ppf.EMPLOYEE_NUMBER      (+)
          AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date(+) AND ppf.effective_end_date(+)
          AND ppf.current_employee_flag(+) = 'Y'
-- Ver11.5.10.1.5B Chg End
          AND xjsi.EXCHANGE_RATE_TYPE_NAME  = xct.USER_CONVERSION_TYPE (+)
          AND xjsi.ORG_ID                   = xgto.ORG_ID              (+)
          AND xjsi.SET_OF_BOOKS_ID          = xgto.SET_OF_BOOKS_ID     (+)
        ) HEAD
      ,(SELECT
           xjsli.INTERFACE_ID        as INTERFACE_ID                  -- インターフェースID
         , xjsli.LINE_NUMBER         as LINE_NUMBER                   -- 明細番号
         -- ver 11.5.10.2.2 Chg Start
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_DR
         --         ,0 ,NULL
         --         ,xjsli.ENTERED_ITEM_AMOUNT_DR)  as ENTERED_ITEM_AMOUNT_DR        -- 本体金額
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_DR
         --         ,0 ,DECODE( xjsli.ENTERED_TAX_AMOUNT_DR
         --                    ,0 ,NULL
         --                    ,xjsli.ENTERED_TAX_AMOUNT_DR)
         --         ,xjsli.ENTERED_TAX_AMOUNT_DR)   as ENTERED_TAX_AMOUNT_DR         -- 消費税額
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_DR
         --         ,0 ,DECODE( xjsli.ACCOUNTED_AMOUNT_DR
         --                    ,0 ,NULL
         --                    ,xjsli.ACCOUNTED_AMOUNT_DR)
         --         ,xjsli.ACCOUNTED_AMOUNT_DR)     as ACCOUNTED_AMOUNT_DR           -- 換算済金額
         , xjsli.ENTERED_ITEM_AMOUNT_DR           as ENTERED_ITEM_AMOUNT_DR        -- 本体金額
         , xjsli.ENTERED_TAX_AMOUNT_DR            as ENTERED_TAX_AMOUNT_DR         -- 消費税額
         , xjsli.ACCOUNTED_AMOUNT_DR              as ACCOUNTED_AMOUNT_DR           -- 換算済金額
         -- ver 11.5.10.2.2 Chg End
         , xjsli.AMOUNT_INCLUDES_TAX_FLAG_DR      as AMOUNT_INCLUDES_TAX_FLAG_DR   -- 内税
         , xjsli.TAX_CODE_DR         as TAX_CODE_DR                   -- 税区分
         , xtcl.TAX_CODES_COL        as TAX_NAME_DR                   -- 税区分名
         -- ver 11.5.10.2.2 Chg Start
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_CR
         --         ,0 ,NULL
         --         ,xjsli.ENTERED_ITEM_AMOUNT_CR)  as ENTERED_ITEM_AMOUNT_CR        -- 本体金額
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_CR
         --         ,0 ,DECODE( xjsli.ENTERED_TAX_AMOUNT_CR
         --                    ,0 ,NULL
         --                    ,xjsli.ENTERED_TAX_AMOUNT_CR)
         --         ,xjsli.ENTERED_TAX_AMOUNT_CR)   as ENTERED_TAX_AMOUNT_CR         -- 消費税額
         --, DECODE( xjsli.ENTERED_ITEM_AMOUNT_CR
         --         ,0 ,DECODE( xjsli.ACCOUNTED_AMOUNT_CR
         --                    ,0 ,NULL
         --                    ,xjsli.ACCOUNTED_AMOUNT_CR)
         --         ,xjsli.ACCOUNTED_AMOUNT_CR)     as ACCOUNTED_AMOUNT_CR           -- 換算済金額
         , xjsli.ENTERED_ITEM_AMOUNT_CR           as ENTERED_ITEM_AMOUNT_CR        -- 本体金額
         , xjsli.ENTERED_TAX_AMOUNT_CR            as ENTERED_TAX_AMOUNT_CR         -- 消費税額
         , xjsli.ACCOUNTED_AMOUNT_CR              as ACCOUNTED_AMOUNT_CR           -- 換算済金額
         -- ver 11.5.10.2.2 Chg End
         , xjsli.AMOUNT_INCLUDES_TAX_FLAG_CR      as AMOUNT_INCLUDES_TAX_FLAG_CR   -- 内税
         , xjsli.TAX_CODE_CR         as TAX_CODE_CR                   -- 税区分
         , xtcl2.TAX_CODES_COL       as TAX_NAME_CR                   -- 税区分名
         , xjsli.DESCRIPTION         as DESCRIPTION                   -- 備考
         , xcl.FLEX_VALUE            as SEGMENT1                      -- 会社
         , xcl.COMPANIES_COL         as SEGMENT1_NAME                 -- 会社名
         , xdl.FLEX_VALUE            as SEGMENT2                      -- 部門
         , xdl.DEPARTMENTS_COL       as SEGMENT2_NAME                 -- 部門名
         , xal.FLEX_VALUE            as SEGMENT3                      -- 勘定科目
         , xal.ACCOUNTS_COL          as SEGMENT3_NAME                 -- 勘定科目名
         , xsal.FLEX_VALUE           as SEGMENT4                      -- 補助科目
         , xsal.SUB_ACCOUNTS_COL     as SEGMENT4_NAME                 -- 補助科目名
         , xpal.FLEX_VALUE           as SEGMENT5                      -- 相手先
         , xpal.PARTNERS_COL         as SEGMENT5_NAME                 -- 相手先名
         , xbtl.FLEX_VALUE           as SEGMENT6                      -- 事業区分
         , xbtl.BUSINESS_TYPES_COL   as SEGMENT6_NAME                 -- 事業区分名
         , xprl.FLEX_VALUE           as SEGMENT7                      -- プロジェクト
         , xprl.PROJECTS_COL         as SEGMENT7_NAME                 -- プロジェクト名
         , xfl.FLEX_VALUE            as SEGMENT8                      -- 予備
         , xfl.FUTURES_COL           as SEGMENT8_NAME                 -- 予備名
         , xjsli.INCR_DECR_REASON_CODE  as INCR_DECR_REASON_CODE      -- 増減事由
         , xidrl.INCR_DECR_REASONS_COL  as INCR_DECR_REASON_NAME      -- 増減事由名
         , xjsli.RECON_REFERENCE     as RECON_REFERENCE               -- 消込参照
         , xjsli.ORG_ID              as ORG_ID                        -- オルグID
-- == 2016/11/04 V1.1 Added START ===============================================================
         , xjsli.ATTRIBUTE9          as ATTRIBUTE9                    -- 稟議決裁番号
-- == 2016/11/04 V1.1 Added END   ===============================================================
         , xjsli.CREATED_BY          as CREATED_BY
         , xjsli.CREATION_DATE       as CREATION_DATE
         , xjsli.LAST_UPDATED_BY     as LAST_UPDATED_BY
         , xjsli.LAST_UPDATE_DATE    as LAST_UPDATE_DATE
         , xjsli.LAST_UPDATE_LOGIN   as LAST_UPDATE_LOGIN
         , xjsli.REQUEST_ID          as REQUEST_ID
         , xjsli.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xjsli.PROGRAM_ID          as PROGRAM_ID
         , xjsli.PROGRAM_UPDATE_DATE as PROGRAM_UPDATE_DATE
        FROM
         -- Ver11.5.10.1.6 2005/12/15 Change Start
         -- XX03_JOURNAL_SLIP_LINES_IF   xjsli
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl2
         -- ver 11.5.10.2.6 Del Start
         --  XX03_JOURNAL_SLIPS_IF        xjsi
         -- ver 11.5.10.2.6 Del End
           XX03_JOURNAL_SLIP_LINES_IF   xjsli
         -- ver 11.5.10.2.6 Chg Start
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL,
         --         ATL.START_DATE, ATL.INACTIVE_DATE
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl
         ,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
                 ,xjsli.INTERFACE_ID ,xjsli.LINE_NUMBER
           FROM AP_TAX_CODES_ALL ATL ,XX03_JOURNAL_SLIPS_IF xjsi ,XX03_JOURNAL_SLIP_LINES_IF xjsli
           WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
             AND xjsli.TAX_CODE_DR = ATL.NAME AND xjsi.INTERFACE_ID = xjsli.INTERFACE_ID
             AND xjsi.GL_DATE BETWEEN NVL(ATL.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(ATL.INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
             AND xjsi.REQUEST_ID = h_request_id AND xjsi.SOURCE = h_source AND xjsli.REQUEST_ID = h_request_id AND xjsli.SOURCE = h_source
           )                            xtcl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.6 Chg Start
         --,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL,
         --         ATL.START_DATE, INACTIVE_DATE
         --  FROM AP_TAX_CODES_ALL ATL
         --  WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
         --  )                            xtcl2
         ,(SELECT ATL.NAME , ATL.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || ATL.DESCRIPTION TAX_CODES_COL
                 ,xjsli.INTERFACE_ID ,xjsli.LINE_NUMBER
           FROM AP_TAX_CODES_ALL ATL ,XX03_JOURNAL_SLIPS_IF xjsi ,XX03_JOURNAL_SLIP_LINES_IF xjsli
           WHERE ATL.ENABLED_FLAG = 'Y'  AND ATL.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND TAX_TYPE != 'AWT'
             AND xjsli.TAX_CODE_CR = ATL.NAME AND xjsi.INTERFACE_ID = xjsli.INTERFACE_ID
             AND xjsi.GL_DATE BETWEEN NVL(ATL.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(ATL.INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
             AND xjsi.REQUEST_ID = h_request_id AND xjsi.SOURCE = h_source AND xjsli.REQUEST_ID = h_request_id AND xjsli.SOURCE = h_source
           )                            xtcl2
         -- ver 11.5.10.2.6 Chg End
         -- Ver11.5.10.1.6 2005/12/15 Change End
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION COMPANIES_COL
           FROM XX03_COMPANIES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xcl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION DEPARTMENTS_COL
           FROM XX03_DEPARTMENTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xdl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION ACCOUNTS_COL
           FROM XX03_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xal
         ,(SELECT XV.PARENT_FLEX_VALUE_LOW,XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SUB_ACCOUNTS_COL
           FROM XX03_SUB_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xsal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PARTNERS_COL
           FROM XX03_PARTNERS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xpal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION BUSINESS_TYPES_COL
           FROM XX03_BUSINESS_TYPES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xbtl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PROJECTS_COL
           FROM XX03_PROJECTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xprl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION FUTURES_COL
           FROM XX03_FUTURES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                            xfl
         ,(SELECT XV.FFL_FLEX_VALUE FLEX_VALUE,XV.FFL_FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION INCR_DECR_REASONS_COL,XCC.ACCOUNT_CODE PARENT_FLEX_VALUE_LOW
           FROM XX03_INCR_DECR_REASONS_V XV
               ,XX03_CF_COMBINATIONS XCC
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND XCC.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') AND XCC.INCR_DECR_REASON_CODE = XV.FFL_FLEX_VALUE
           )                            xidrl
        WHERE
              xjsli.REQUEST_ID              = h_request_id
          AND xjsli.SOURCE                  = h_source
          -- ver 11.5.10.2.6 Chg Start
          ---- Ver11.5.10.1.6 2005/12/15 Add Start
          ---- ver 11.5.10.2.5C Add Start
          --AND xjsi.REQUEST_ID               = h_request_id
          --AND xjsi.SOURCE                   = h_source
          ---- ver 11.5.10.2.5C Add End
          --AND xjsi.INTERFACE_ID             = xjsli.INTERFACE_ID
          --AND xjsi.GL_DATE BETWEEN NVL(xtcl.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) 
          --                     AND NVL(xtcl.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
          --AND xjsi.GL_DATE BETWEEN NVL(xtcl2.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) 
          --                     AND NVL(xtcl2.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
          ---- Ver11.5.10.1.6 2005/12/15 Chg End
          AND xjsli.INTERFACE_ID            = xtcl.INTERFACE_ID           (+)
          AND xjsli.LINE_NUMBER             = xtcl.LINE_NUMBER            (+)
          AND xjsli.INTERFACE_ID            = xtcl2.INTERFACE_ID          (+)
          AND xjsli.LINE_NUMBER             = xtcl2.LINE_NUMBER           (+)
          -- ver 11.5.10.2.6 Chg End
          AND xjsli.TAX_CODE_DR             = xtcl.NAME                   (+)
          AND xjsli.TAX_CODE_CR             = xtcl2.NAME                  (+)
          AND xjsli.SEGMENT1                = xcl.FLEX_VALUE              (+)
          AND xjsli.SEGMENT2                = xdl.FLEX_VALUE              (+)
          AND xjsli.SEGMENT3                = xal.FLEX_VALUE              (+)
          AND xjsli.SEGMENT3                = xsal.PARENT_FLEX_VALUE_LOW  (+)
          AND xjsli.SEGMENT4                = xsal.FLEX_VALUE             (+)
          AND xjsli.SEGMENT5                = xpal.FLEX_VALUE             (+)
          AND xjsli.SEGMENT6                = xbtl.FLEX_VALUE             (+)
          AND xjsli.SEGMENT7                = xprl.FLEX_VALUE             (+)
          AND xjsli.SEGMENT8                = xfl.FLEX_VALUE              (+)
          AND xjsli.SEGMENT3                = xidrl.PARENT_FLEX_VALUE_LOW (+)
          AND xjsli.INCR_DECR_REASON_CODE   = xidrl.FLEX_VALUE            (+)
        ) LINE
     , (SELECT INTERFACE_ID         as INTERFACE_ID
              ,COUNT(INTERFACE_ID)  as REC_COUNT
        FROM   XX03_JOURNAL_SLIPS_IF
        WHERE  REQUEST_ID = h_request_id
          AND  SOURCE     = h_source
        GROUP BY INTERFACE_ID
        ) CNT
      -- ver 11.5.10.2.10B Add Start
      ,(SELECT xjsi.INTERFACE_ID as INTERFACE_ID
              ,ppf.PERSON_ID     as PERSON_ID
        FROM   XX03_JOURNAL_SLIPS_IF    xjsi
             ,(SELECT employee_number ,person_id FROM PER_PEOPLE_F
               WHERE current_employee_flag = 'Y' AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
               ) ppf
        WHERE  xjsi.APPROVER_PERSON_NUMBER = ppf.EMPLOYEE_NUMBER
-- == V1.2 Added START ===============================================================
          AND  xjsi.request_id             = h_request_id
          AND  xjsi.source                 = h_source
-- == V1.2 Added END   ===============================================================
          AND  EXISTS (SELECT '1'
                       FROM   XX03_APPROVER_PERSON_LOV_V xaplv
                       WHERE  xaplv.PERSON_ID = ppf.person_id
                         AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
                              or xaplv.PROFILE_VAL_DEP = 'SQLGL')
                       )
        ) APPROVER
      -- ver 11.5.10.2.10B Add End
    WHERE
          HEAD.INTERFACE_ID = LINE.INTERFACE_ID
      AND HEAD.INTERFACE_ID = CNT.INTERFACE_ID
      -- ver 11.5.10.2.10B Add Start
      AND HEAD.INTERFACE_ID = APPROVER.INTERFACE_ID(+)
      -- ver 11.5.10.2.10B Add End
    ORDER BY
       HEAD.INTERFACE_ID ,LINE.LINE_NUMBER
    ;
--
    -- ヘッダ明細情報カーソルレコード型
    xx03_if_head_line_rec  xx03_if_head_line_cur%ROWTYPE;
-- Ver11.5.10.1.5 2005/09/06 Add End
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : print_header
   * Description      : ヘッダ情報出力
   ***********************************************************************************/
  PROCEDURE print_header(
    iv_source     IN  VARCHAR2,     -- 1.ソース
    in_request_id IN  NUMBER,       -- 2.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'print_header'; -- プログラム名
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
    lv_conc_name fnd_concurrent_programs.concurrent_program_name%TYPE;  -- パラメータ出力用
    l_conc_para_rec        xx03_get_prompt_pkg.g_conc_para_tbl_type;    -- パラメータ出力用
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
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- ログ出力
    xx00_file_pkg.log('iv_source = ' || iv_source);
    xx00_file_pkg.log('in_request_id = ' || TO_CHAR(in_request_id));
    xx00_file_pkg.log(' ');
--
    --コンカレント出力のヘッダー情報を出力
    xx03_header_line_output_pkg.header_line_output_p(
                        cv_appli_cd,                                 -- アプリケーション種別
                        xx00_global_pkg.prog_appl_id,                -- アプリケーションID
                        xx00_profile_pkg.value('GL_SET_OF_BKS_ID'),  -- 会計帳簿ID
                        NULL,                                        -- オルグID
                        xx00_global_pkg.conc_program_id,             -- コンカレントプログラムID
                        ov_errbuf,
                        ov_retcode,
                        ov_errmsg
                       );
--
    -- 改行出力
    xx00_file_pkg.output(' ');
--
    -- コンカレント出力のパラメータ情報を出力
    lv_conc_name := NULL;
    xx03_get_prompt_pkg.conc_parameter_strc(lv_conc_name,l_conc_para_rec);
    xx00_file_pkg.output(RPAD(l_conc_para_rec(1).PARAM_PROMPT,20)
                         ||':'|| iv_source);
    xx00_file_pkg.output(RPAD(l_conc_para_rec(2).PARAM_PROMPT,20)
                         ||':'|| TO_CHAR(in_request_id));
--
    -- 改行出力
    xx00_file_pkg.output(' ');
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
  END print_header;
--
-- Ver11.5.10.1.5 2005/09/06 Change Start
--  /**********************************************************************************
--   * Procedure Name   : check_detail_data
--   * Description      : 仕訳伝票明細データの入力チェック(E-2)
--   ***********************************************************************************/
--  PROCEDURE check_detail_data(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_detail_data'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  固定部 END   ############################
----
--    -- 会社チェック
--    IF ( xx03_if_detail_rec.SEGMENT1 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT1) = '' ) THEN
--      -- 会社セグメントが空の場合は会社入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14114'
--        )
--      );
--    END IF;
----
--    -- 部門チェック
--    IF ( xx03_if_detail_rec.SEGMENT2 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT2) = '' ) THEN
--      -- 部門セグメントが空の場合は部門入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14115'
--        )
--      );
--    END IF;
----
--    -- 勘定科目チェック
--    IF ( xx03_if_detail_rec.SEGMENT3 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT3) = '' ) THEN
--      -- 勘定科目セグメントが空の場合は勘定科目入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14116'
--        )
--      );
--    END IF;
----
--    -- 補助科目チェック
--    IF ( xx03_if_detail_rec.SEGMENT4 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT4) = '' ) THEN
--      -- 補助科目セグメントが空の場合は補助科目入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14117'
--        )
--      );
--    END IF;
----
--    -- 相手先チェック
--    IF ( xx03_if_detail_rec.SEGMENT5 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT5) = '' ) THEN
--      -- 相手先セグメントが空の場合は相手先入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14118'
--        )
--      );
--    END IF;
----
--    -- 事業区分チェック
--    IF ( xx03_if_detail_rec.SEGMENT6 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT6) = '' ) THEN
--      -- 事業区分セグメントが空の場合は事業区分入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14119'
--        )
--      );
--    END IF;
----
--    -- プロジェクトチェック
--    IF ( xx03_if_detail_rec.SEGMENT7 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT7) = '' ) THEN
--      -- プロジェクトセグメントが空の場合はプロジェクト入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-14120'
--        )
--      );
--    END IF;
----
--    -- 予備チェック
--    IF ( xx03_if_detail_rec.SEGMENT7 IS NULL 
--           OR TRIM(xx03_if_detail_rec.SEGMENT7) = '' ) THEN
--      -- 予備セグメントが空の場合は予備入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08023'
--        )
--      );
--    END IF;
----
--    -- 借方本体金額が入力されている場合
--    IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
--           OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
----
--      -- 消費税額(DR)チェック
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR IS NULL 
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR) = '' ) THEN
--        -- 借方消費税額が空の場合は消費税額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14113'
--          )
--        );
--      END IF;
----
--      -- 内税(DR)チェック
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR IS NULL 
--             OR TRIM(xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR) = '' ) THEN
--        -- 借方内税が空の場合は内税入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08022'
--          )
--        );
--      ELSE
--        -- 内税(DR)入力値チェック
--        IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR != cv_yes
--               AND xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR != cv_no ) THEN
--          -- 借方内税の入力値が不正の場合は内税入力値エラー表示
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08027'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- 税区分(DR)チェック
--      IF ( xx03_if_detail_rec.TAX_CODE_DR IS NULL 
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_DR) = '' ) THEN
--        -- 借方税区分が空の場合は税区分入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14111'
--          )
--        );
--      END IF;
----
--      -- 換算済金額(DR)チェック
--      IF xx03_if_header_rec.IGNORE_RATE_FLAG = 'N' THEN
--        IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR IS NULL 
--               OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR) = '' ) THEN
--          -- 借方換算済金額が空の場合は換算済金額入力エラー表示
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-11505'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- 本体金額(CR)チェック
--      IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
--        -- 貸方本体金額が空でない場合は貸方本体金額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11507'
--          )
--        );
--      END IF;
----
--      -- 消費税額(CR)チェック
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR) != '' ) THEN
--        -- 貸方消費税額が空でない場合は貸方消費税額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11508'
--          )
--        );
--      END IF;
----
--      -- 税区分(CR)チェック
--      IF ( xx03_if_detail_rec.TAX_CODE_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_CR) != '' ) THEN
--        -- 貸方税区分が空でない場合は貸方税区分入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11510'
--          )
--        );
--      END IF;
----
--      -- 換算済金額(CR)チェック
--      IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR) != '' ) THEN
--        -- 貸方換算済金額が空でない場合は貸方換算済金額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11511'
--          )
--        );
--      END IF;
--    END IF;
----
--    IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NOT NULL
--           OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
----
--      -- 消費税額(CR)チェック
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR IS NULL 
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR) = '' ) THEN
--        -- 貸方消費税額が空の場合は消費税額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14113'
--          )
--        );
--      END IF;
----
--      -- 内税(CR)チェック
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR IS NULL 
--             OR TRIM(xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR) = '' ) THEN
--        -- 貸方内税が空の場合は内税入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08022'
--          )
--        );
--      ELSE
--        -- 内税(CR)入力値チェック
--        IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR != cv_yes
--               AND xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR != cv_no ) THEN
--          -- 貸方内税の入力値が不正の場合は内税入力値エラー表示
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08027'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- 税区分(CR)チェック
--      IF ( xx03_if_detail_rec.TAX_CODE_CR IS NULL 
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_CR) = '' ) THEN
--        -- 貸方税区分が空の場合は税区分入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-14111'
--          )
--        );
--      END IF;
----
--      -- 換算済金額(CR)チェック
--      IF xx03_if_header_rec.IGNORE_RATE_FLAG = 'N' THEN
--        IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR IS NULL 
--               OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR) = '' ) THEN
--          -- 貸方換算済金額が空の場合は換算済金額入力エラー表示
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-11505'
--            )
--          );
--        END IF;
--      END IF;
----
--      -- 本体金額(DR)チェック
--      IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
--        -- 借方本体金額が空でない場合は借方本体金額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11512'
--          )
--        );
--      END IF;
----
--      -- 消費税額(DR)チェック
--      IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR) != '' ) THEN
--        -- 借方消費税額が空でない場合は借方消費税額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11513'
--          )
--        );
--      END IF;
----
--      -- 税区分(DR)チェック
--      IF ( xx03_if_detail_rec.TAX_CODE_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.TAX_CODE_DR) != '' ) THEN
--        -- 借方税区分が空でない場合は借方税区分入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11515'
--          )
--        );
--      END IF;
----
--      -- 換算済金額(DR)チェック
--      IF ( xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR IS NOT NULL
--             OR TRIM(xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR) != '' ) THEN
--        -- 借方換算済金額が空でない場合は借方換算済金額入力エラー表示
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-11516'
--          )
--        );
--      END IF;
--    END IF;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  固定部 END   ##########################################
----
--  END check_detail_data;
----
--  /**********************************************************************************
--   * Procedure Name   : copy_detail_data
--   * Description      : 明細データのコピー(E-1)
--   ***********************************************************************************/
--  PROCEDURE copy_detail_data(
--    iv_source     IN  VARCHAR2,    --  1.ソース
--    in_request_id IN  NUMBER,       -- 2.要求ID
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_detail_data'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_line_id NUMBER;     -- 明細ID
--    ln_line_count NUMBER;  -- 明細連番
--    ln_line_count_cr NUMBER; -- 貸方明細連番
--    ln_line_count_dr NUMBER; -- 借方明細連番
--    ln_amount_dr NUMBER;   -- 金額
--    ln_amount_cr NUMBER;   -- 金額
--    lv_amount_includes_tax_flag_dr VARCHAR2(100); -- 内税区分
--    lv_amount_includes_tax_flag_cr VARCHAR2(100); -- 内税区分
--    lv_currency_code VARCHAR2(4000); -- 機能通貨コード
--    ln_total_accounted_dr NUMBER;  -- 換算済合計金額
--    ln_total_accounted_cr NUMBER;  -- 換算済合計金額
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        実処理の記述             ***
--    -- ***       共通関数の呼び出し        ***
--    -- ***************************************
----
----
--   -- 機能通貨コード取得
--   SELECT gsob.currency_code
--     INTO lv_currency_code
--     FROM gl_sets_of_books gsob
--    WHERE gsob.set_of_books_id = xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
----
--    -- 明細連番初期化
--    ln_line_count    := 1;
--    ln_line_count_cr := 1;
--    ln_line_count_dr := 1;
----
--    -- 明細情報カーソルオープン
--    OPEN xx03_if_detail_cur(iv_source,
--                            in_request_id, 
--                            xx03_if_header_rec.INTERFACE_ID, 
--                            xx03_if_header_rec.INVOICE_CURRENCY_CODE,
--                            lv_currency_code);
--    <<xx03_if_detail_loop>>
--    LOOP
--      FETCH xx03_if_detail_cur INTO xx03_if_detail_rec;
--      IF xx03_if_detail_cur%NOTFOUND THEN
--        -- 対象データがなくなるまでループ
--        EXIT xx03_if_detail_loop;
--      END IF;
----
--      -- ===============================
--      -- 入力チェック(E-2)
--      -- ===============================
--      check_detail_data(
--        lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--        lv_retcode,        -- リターン・コード             --# 固定 #
--        lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--      IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--        RAISE global_process_expt;
--      END IF;
----
--      -- 明細ID取得
--      SELECT XX03_JOURNAL_SLIP_LINES_S.nextval 
--        INTO ln_line_id
--        FROM dual;
----
--      -- 金額算出
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR = cv_yes ) THEN
--        -- '内税'が'Y'の時は金額は'本体金額+消費税額'
--        ln_amount_dr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR + 
--                        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR;
--      ELSIF  ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR = cv_no ) THEN
--        -- '内税'が'N'の時は金額は'本体金額'
--        ln_amount_dr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR;
--      ELSE
--        -- それ以外の時は内税入力値エラー
--        ln_amount_dr := 0;
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08027'
--          )
--        );
--      END IF;
----
--      -- 金額算出
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR = cv_yes ) THEN
--        -- '内税'が'Y'の時は金額は'本体金額+消費税額'
--        ln_amount_cr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR + 
--                        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR;
--      ELSIF  ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR = cv_no ) THEN
--        -- '内税'が'N'の時は金額は'本体金額'
--        ln_amount_cr := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR;
--      ELSE
--        -- それ以外の時は内税入力値エラー
--        ln_amount_cr := 0;
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08027'
--          )
--        );
--      END IF;
----
--      -- 内税区分
--      IF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NULL THEN
--        lv_amount_includes_tax_flag_dr := NULL;
--      ELSE
--        lv_amount_includes_tax_flag_dr := xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_DR;
--      END IF;
--      IF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NULL THEN
--        lv_amount_includes_tax_flag_cr := NULL;
--      ELSE
--        lv_amount_includes_tax_flag_cr := xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG_CR;
--      END IF;
----
--      -- 明細データ保存
--      INSERT INTO XX03_JOURNAL_SLIP_LINES(
--        JOURNAL_LINE_ID             ,
--        JOURNAL_ID                  ,
--        LINE_NUMBER                 ,
--        SLIP_LINE_TYPE_DR           ,
--        SLIP_LINE_TYPE_NAME_DR      ,
--        ENTERED_AMOUNT_DR           ,
--        ENTERED_ITEM_AMOUNT_DR      ,
--        AMOUNT_INCLUDES_TAX_FLAG_DR ,
--        TAX_CODE_DR                 ,
--        TAX_NAME_DR                 ,
--        ENTERED_TAX_AMOUNT_DR       ,
--        ACCOUNTED_AMOUNT_DR         ,
--        SLIP_LINE_TYPE_CR           ,
--        SLIP_LINE_TYPE_NAME_CR      ,
--        ENTERED_AMOUNT_CR           ,
--        ENTERED_ITEM_AMOUNT_CR      ,
--        AMOUNT_INCLUDES_TAX_FLAG_CR ,
--        TAX_CODE_CR                 ,
--        TAX_NAME_CR                 ,
--        ENTERED_TAX_AMOUNT_CR       ,
--        ACCOUNTED_AMOUNT_CR         ,
--        DESCRIPTION                 ,
--        SEGMENT1                    ,
--        SEGMENT2                    ,
--        SEGMENT3                    ,
--        SEGMENT4                    ,
--        SEGMENT5                    ,
--        SEGMENT6                    ,
--        SEGMENT7                    ,
--        SEGMENT8                    ,
--        SEGMENT9                    ,
--        SEGMENT10                   ,
--        SEGMENT11                   ,
--        SEGMENT12                   ,
--        SEGMENT13                   ,
--        SEGMENT14                   ,
--        SEGMENT15                   ,
--        SEGMENT16                   ,
--        SEGMENT17                   ,
--        SEGMENT18                   ,
--        SEGMENT19                   ,
--        SEGMENT20                   ,
--        SEGMENT1_NAME               ,
--        SEGMENT2_NAME               ,
--        SEGMENT3_NAME               ,
--        SEGMENT4_NAME               ,
--        SEGMENT5_NAME               ,
--        SEGMENT6_NAME               ,
--        SEGMENT7_NAME               ,
--        SEGMENT8_NAME               ,
--        INCR_DECR_REASON_CODE       ,
--        INCR_DECR_REASON_NAME       ,
--        RECON_REFERENCE             ,
--        ORG_ID                      ,
--        ATTRIBUTE_CATEGORY          ,
--        ATTRIBUTE1                  ,
--        ATTRIBUTE2                  ,
--        ATTRIBUTE3                  ,
--        ATTRIBUTE4                  ,
--        ATTRIBUTE5                  ,
--        ATTRIBUTE6                  ,
--        ATTRIBUTE7                  ,
--        ATTRIBUTE8                  ,
--        ATTRIBUTE9                  ,
--        ATTRIBUTE10                 ,
--        ATTRIBUTE11                 ,
--        ATTRIBUTE12                 ,
--        ATTRIBUTE13                 ,
--        ATTRIBUTE14                 ,
--        ATTRIBUTE15                 ,
--        CREATED_BY                  ,
--        CREATION_DATE               ,
--        LAST_UPDATED_BY             ,
--        LAST_UPDATE_DATE            ,
--        LAST_UPDATE_LOGIN           ,
--        REQUEST_ID                  ,
--        PROGRAM_APPLICATION_ID      ,
--        PROGRAM_ID                  ,
--        PROGRAM_UPDATE_DATE       
--      )
--      VALUES(
--        ln_line_id,
--        gn_journal_id,
--        DECODE(xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR, NULL, ln_line_count_dr, ln_line_count_cr),
--        NULL,
--        NULL,
--        ln_amount_dr,
--        xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR,
--        lv_amount_includes_tax_flag_dr,
--        xx03_if_detail_rec.TAX_CODE_DR,
--        xx03_if_detail_rec.TAX_NAME_DR,
--        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_DR,
--        xx03_if_detail_rec.ACCOUNTED_AMOUNT_DR,
--        NULL,
--        NULL,
--        ln_amount_cr,
--        xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR,
--        lv_amount_includes_tax_flag_cr,
--        xx03_if_detail_rec.TAX_CODE_CR,
--        xx03_if_detail_rec.TAX_NAME_CR,
--        xx03_if_detail_rec.ENTERED_TAX_AMOUNT_CR,
--        xx03_if_detail_rec.ACCOUNTED_AMOUNT_CR,
--        xx03_if_detail_rec.DESCRIPTION,
--        xx03_if_detail_rec.SEGMENT1,
--        xx03_if_detail_rec.SEGMENT2,
--        xx03_if_detail_rec.SEGMENT3,
--        xx03_if_detail_rec.SEGMENT4,
--        xx03_if_detail_rec.SEGMENT5,
--        xx03_if_detail_rec.SEGMENT6,
--        xx03_if_detail_rec.SEGMENT7,
--        xx03_if_detail_rec.SEGMENT8,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        xx03_if_detail_rec.SEGMENT1_NAME,
--        xx03_if_detail_rec.SEGMENT2_NAME,
--        xx03_if_detail_rec.SEGMENT3_NAME,
--        xx03_if_detail_rec.SEGMENT4_NAME,
--        xx03_if_detail_rec.SEGMENT5_NAME,
--        xx03_if_detail_rec.SEGMENT6_NAME,
--        xx03_if_detail_rec.SEGMENT7_NAME,
--        xx03_if_detail_rec.SEGMENT8_NAME,
--        xx03_if_detail_rec.INCR_DECR_REASON_CODE,
--        xx03_if_detail_rec.INCR_DECR_REASON_NAME,
--        xx03_if_detail_rec.RECON_REFERENCE,
--        xx03_if_detail_rec.ORG_ID,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        NULL,
--        xx00_global_pkg.user_id,
--        xx00_date_pkg.get_system_datetime_f,
--        xx00_global_pkg.user_id,
--        xx00_date_pkg.get_system_datetime_f,
--        xx00_global_pkg.login_id,
--        xx00_global_pkg.conc_request_id,
--        xx00_global_pkg.prog_appl_id,
--        xx00_global_pkg.conc_program_id,
--        xx00_date_pkg.get_system_datetime_f
--      );
----
--      -- 明細連番加算
--      IF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_DR IS NOT NULL THEN
--        ln_line_count_dr := ln_line_count_dr + 1;
--      ELSIF xx03_if_detail_rec.ENTERED_ITEM_AMOUNT_CR IS NOT NULL THEN
--        ln_line_count_cr := ln_line_count_cr + 1;
--      ELSE
--        ln_line_count := ln_line_count + 1;
--      END IF;
----
--    END LOOP xx03_if_detail_loop;
--    CLOSE xx03_if_detail_cur;
----
--    IF xx03_if_header_rec.IGNORE_RATE_FLAG = cv_no THEN
--      -- 換算済金額合計
--      SELECT SUM(xjsl.ACCOUNTED_AMOUNT_DR) as ACCOUNTED_AMOUNT_DR,
--             SUM(xjsl.ACCOUNTED_AMOUNT_CR) as ACCOUNTED_AMOUNT_CR
--        INTO ln_total_accounted_dr,
--             ln_total_accounted_cr
--        FROM XX03_JOURNAL_SLIP_LINES xjsl
--       WHERE xjsl.JOURNAL_ID = gn_journal_id
--      GROUP BY xjsl.JOURNAL_ID;
--      IF ln_total_accounted_dr != ln_total_accounted_cr THEN
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-03036'
--          )
--        );
--      END IF;
--    END IF;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  固定部 END   ##########################################
----
--  END copy_detail_data;
----
--  /**********************************************************************************
--   * Procedure Name   : check_header_data
--   * Description      : 仕訳伝票データの入力チェック(E-2)
--   ***********************************************************************************/
--  PROCEDURE check_header_data(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_header_data'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  固定部 END   ############################
----
--    -- 伝票種別チェック
--    IF ( xx03_if_header_rec.SLIP_TYPE IS NULL 
--           OR TRIM(xx03_if_header_rec.SLIP_TYPE) = '' ) THEN
--      -- 伝票種別IDが空の場合は伝票種別入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08010'
--        )
--      );
--    END IF;
----
--    -- 承認者チェック
--    IF ( xx03_if_header_rec.APPROVER_PERSON_NAME IS NULL 
--           OR TRIM(xx03_if_header_rec.APPROVER_PERSON_NAME) = '' ) THEN
--      -- 承認者名が空の場合は承認者入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08011'
--        )
--      );
--    END IF;
----
--    -- 計上日チェック
--    IF ( xx03_if_header_rec.GL_DATE IS NULL 
--           OR TRIM(xx03_if_header_rec.GL_DATE) = '' ) THEN
--      -- 計上日が空の場合は計上日入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08015'
--        )
--      );
--    END IF;
----
--    -- 会計期間チェック
--    IF ( xx03_if_header_rec.PERIOD_NAME IS NULL 
--           OR TRIM(xx03_if_header_rec.PERIOD_NAME) = '' ) THEN
--      -- 会計期間が空の場合は会計期間入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08028'
--        )
--      );
--    END IF;
----
--    -- 通貨チェック
--    IF ( xx03_if_header_rec.INVOICE_CURRENCY_CODE IS NULL 
--           OR TRIM(xx03_if_header_rec.INVOICE_CURRENCY_CODE) = '' ) THEN
--      -- 通貨が空の場合は通貨入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08018'
--        )
--      );
--    END IF;
----
--    -- レートタイプチェック
--    IF ( xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME IS NOT NULL 
--           AND ( xx03_if_header_rec.EXCHANGE_RATE_TYPE IS NULL 
--           OR TRIM(xx03_if_header_rec.EXCHANGE_RATE_TYPE) = '' )) THEN
--      -- レートタイプコードが取得できなかった場合はレートタイプ入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08025'
--        )
--      );
--    END IF;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  固定部 END   ##########################################
----
--  END check_header_data;
----
--  /**********************************************************************************
--   * Procedure Name   : calc_amount
--   * Description      : 金額計算(E-3)
--   ***********************************************************************************/
--  PROCEDURE calc_amount(
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'calc_amount'; -- プログラム名
----
----#######################  固定ローカル変数宣言部 START   ######################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_total_item_amount_dr NUMBER; -- 本体金額合計
--    ln_total_tax_amount_dr NUMBER;  -- 消費税額合計
--    ln_total_amount_dr NUMBER;      -- 明細合計金額
--    ln_total_accounted_dr NUMBER;   -- 換算済合計金額
--    ln_total_item_amount_cr NUMBER; -- 本体金額合計
--    ln_total_tax_amount_cr NUMBER;  -- 消費税額合計
--    ln_total_amount_cr NUMBER;      -- 明細合計金額
--    ln_total_accounted_cr NUMBER;   -- 換算済合計金額
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  固定部 END   ############################
----
--    -- 本体金額合計算出
--    SELECT SUM(xjsl.ENTERED_ITEM_AMOUNT_DR) as ENTERED_ITEM_AMOUNT_DR,
--           SUM(xjsl.ENTERED_ITEM_AMOUNT_CR) as ENTERED_ITEM_AMOUNT_CR
--      INTO ln_total_item_amount_dr,
--           ln_total_item_amount_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- ヘッダレコードに本体合計金額セット
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_ITEM_ENTERED_DR = ln_total_item_amount_dr,
--           xjs.TOTAL_ITEM_ENTERED_CR = ln_total_item_amount_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--    -- 消費税額合計
--    SELECT SUM(xjsl.ENTERED_TAX_AMOUNT_DR) as ENTERED_TAX_AMOUNT_DR,
--           SUM(xjsl.ENTERED_TAX_AMOUNT_CR) as ENTERED_TAX_AMOUNT_CR
--      INTO ln_total_tax_amount_dr,
--           ln_total_tax_amount_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- ヘッダレコードに消費税金額セット
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_TAX_ENTERED_DR = ln_total_tax_amount_dr,
--           xjs.TOTAL_TAX_ENTERED_CR = ln_total_tax_amount_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--   -- 合計金額合計
--   SELECT SUM(xjsl.ENTERED_ITEM_AMOUNT_DR+xjsl.ENTERED_TAX_AMOUNT_DR) as ENTERED_AMOUNT_DR,
--          SUM(xjsl.ENTERED_ITEM_AMOUNT_CR+xjsl.ENTERED_TAX_AMOUNT_CR) as ENTERED_AMOUNT_CR
--      INTO ln_total_amount_dr,
--           ln_total_amount_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- ヘッダレコードに明細合計金額セット
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_ENTERED_DR = ln_total_amount_dr,
--           xjs.TOTAL_ENTERED_CR = ln_total_amount_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--    -- 換算済金額合計
--    SELECT SUM(xjsl.ACCOUNTED_AMOUNT_DR) as ACCOUNTED_AMOUNT_DR,
--           SUM(xjsl.ACCOUNTED_AMOUNT_CR) as ACCOUNTED_AMOUNT_CR
--      INTO ln_total_accounted_dr,
--           ln_total_accounted_cr
--      FROM XX03_JOURNAL_SLIP_LINES xjsl
--     WHERE xjsl.JOURNAL_ID = gn_journal_id
--    GROUP BY xjsl.JOURNAL_ID;
----
--    -- ヘッダーレコードに換算済金額合計をセット
--    UPDATE XX03_JOURNAL_SLIPS xjs 
--       SET xjs.TOTAL_ACCOUNTED_DR = ln_total_accounted_dr,
--           xjs.TOTAL_ACCOUNTED_CR = ln_total_accounted_cr
--     WHERE xjs.JOURNAL_ID = gn_journal_id;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  固定部 END   ##########################################
----
--  END calc_amount;
----
--  /**********************************************************************************
--   * Procedure Name   : copy_if_data
--   * Description      : インターフェースデータのコピー(E-1)
--   ***********************************************************************************/
--  PROCEDURE copy_if_data(
--    iv_source     IN  VARCHAR2,     -- 1.ソース
--    in_request_id IN  NUMBER,       -- 2.要求ID
--    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
--    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
--    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
--  IS
--    -- ===============================
--    -- 固定ローカル定数
--    -- ===============================
--    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_if_data'; -- プログラム名
----
----#####################  固定ローカル変数宣言部 START   ########################
----
--    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
--    lv_retcode VARCHAR2(1);     -- リターン・コード
--    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
----
----###########################  固定部 END   ####################################
----
--    -- ===============================
--    -- ユーザー宣言部
--    -- ===============================
--    -- *** ローカル定数 ***
----
--    -- *** ローカル変数 ***
--    ln_interface_id NUMBER;         -- INTERFACE_ID
--    ln_header_count NUMBER;         -- INTERFACE_ID同一値ヘッダ件数
--    ld_terms_date DATE;             -- 支払予定日
--    lv_terms_flg VARCHAR2(1);       -- 支払予定日変更可能フラグ
--    lv_app_upd VARCHAR2(1);         -- 重点管理フラグ
--    ln_error_cnt NUMBER;            -- 仕訳チェックエラー件数
--    lv_error_flg VARCHAR2(1);       -- 仕訳チェックエラーフラグ
--    lv_error_flg1 VARCHAR2(1);      -- 仕訳チェックエラーフラグ1
--    lv_error_msg1 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ1
--    lv_error_flg2 VARCHAR2(1);      -- 仕訳チェックエラーフラグ2
--    lv_error_msg2 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ2
--    lv_error_flg3 VARCHAR2(1);      -- 仕訳チェックエラーフラグ3
--    lv_error_msg3 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ3
--    lv_error_flg4 VARCHAR2(1);      -- 仕訳チェックエラーフラグ4
--    lv_error_msg4 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ4
--    lv_error_flg5 VARCHAR2(1);      -- 仕訳チェックエラーフラグ5
--    lv_error_msg5 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ5
--    lv_error_flg6 VARCHAR2(1);      -- 仕訳チェックエラーフラグ6
--    lv_error_msg6 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ6
--    lv_error_flg7 VARCHAR2(1);      -- 仕訳チェックエラーフラグ7
--    lv_error_msg7 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ7
--    lv_error_flg8 VARCHAR2(1);      -- 仕訳チェックエラーフラグ8
--    lv_error_msg8 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ8
--    lv_error_flg9 VARCHAR2(1);      -- 仕訳チェックエラーフラグ9
--    lv_error_msg9 VARCHAR2(5000);   -- 仕訳チェックエラーメッセージ9
--    lv_error_flg10 VARCHAR2(1);     -- 仕訳チェックエラーフラグ10
--    lv_error_msg10 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ10
--    lv_error_flg11 VARCHAR2(1);     -- 仕訳チェックエラーフラグ11
--    lv_error_msg11 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ11
--    lv_error_flg12 VARCHAR2(1);     -- 仕訳チェックエラーフラグ12
--    lv_error_msg12 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ12
--    lv_error_flg13 VARCHAR2(1);     -- 仕訳チェックエラーフラグ13
--    lv_error_msg13 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ13
--    lv_error_flg14 VARCHAR2(1);     -- 仕訳チェックエラーフラグ14
--    lv_error_msg14 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ14
--    lv_error_flg15 VARCHAR2(1);     -- 仕訳チェックエラーフラグ15
--    lv_error_msg15 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ15
--    lv_error_flg16 VARCHAR2(1);     -- 仕訳チェックエラーフラグ16
--    lv_error_msg16 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ16
--    lv_error_flg17 VARCHAR2(1);     -- 仕訳チェックエラーフラグ17
--    lv_error_msg17 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ17
--    lv_error_flg18 VARCHAR2(1);     -- 仕訳チェックエラーフラグ18
--    lv_error_msg18 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ18
--    lv_error_flg19 VARCHAR2(1);     -- 仕訳チェックエラーフラグ19
--    lv_error_msg19 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ19
--    lv_error_flg20 VARCHAR2(1);     -- 仕訳チェックエラーフラグ20
--    lv_error_msg20 VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ20
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  固定部 END   ############################
----
--    -- ***************************************
--    -- ***        実処理の記述             ***
--    -- ***       共通関数の呼び出し        ***
--    -- ***************************************
----
--    -- ステータス初期化
--    gv_result := cv_result_normal;
--    ln_interface_id := NULL;
----
--    -- ヘッダ情報カーソルオープン
--    OPEN xx03_if_header_cur(iv_source, in_request_id);
--    <<xx03_if_header_loop>>
--    LOOP
--      -- エラー件数初期化
--      gn_error_count := 0;
----
--      FETCH xx03_if_header_cur INTO xx03_if_header_rec;
--      IF xx03_if_header_cur%NOTFOUND THEN
--        -- 対象データがなくなるまでループ
--        EXIT xx03_if_header_loop;
--      END IF;
----
--      -- INTERFACE_ID同一値所持ヘッダ件数取得
--      SELECT COUNT(xjsi.INTERFACE_ID)
--        INTO ln_header_count
--        FROM XX03_JOURNAL_SLIPS_IF xjsi
--       WHERE xjsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID
--         AND xjsi.REQUEST_ID = in_request_id
--         AND xjsi.SOURCE = iv_source;
----
--      -- INTERFACE_ID同一値ヘッダが１件の時のみ後続の処理を行う
--      IF ( ln_header_count > 1 ) THEN
--        -- INTERFACE_ID同一値ヘッダが２件以上
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        IF ( ln_interface_id IS NULL 
--             OR ln_interface_id <> xx03_if_header_rec.INTERFACE_ID ) THEN
--          -- 初出IDの場合はエラー情報出力
--          -- INTERFACE_ID出力
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08008',
--              'TOK_XX03_INTERFACE_ID',
--              xx03_if_header_rec.INTERFACE_ID
--            )
--          );
--          -- エラー情報出力
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08006'
--            )
--          );
--        END IF;
--      ELSE
----
--        -- INTERFACE_ID出力
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08008',
--            'TOK_XX03_INTERFACE_ID',
--            xx03_if_header_rec.INTERFACE_ID
--          )
--        );
----
--        -- ===============================
--        -- 入力チェック(E-2)
--        -- ===============================
--        check_header_data(
--          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--          lv_retcode,        -- リターン・コード             --# 固定 #
--          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--          RAISE global_process_expt;
--        END IF;
----
--        -- エラーが検出されていない時のみ以降の処理実行
--        IF ( gn_error_count = 0 ) THEN
----
--          -- 伝票ID取得
--          SELECT XX03_JOURNAL_SLIPS_S.nextval 
--            INTO gn_journal_id
--            FROM dual;
----
--          -- インターフェーステーブル伝票ID更新
--          UPDATE XX03_JOURNAL_SLIPS_IF xjsi
--             SET JOURNAL_ID = gn_journal_id
--           WHERE xjsi.REQUEST_ID = in_request_id
--             AND xjsi.SOURCE = iv_source
--             AND xjsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID;
----
--          -- ヘッダデータ保存
--          INSERT INTO XX03_JOURNAL_SLIPS(
--            JOURNAL_ID                   ,
--            WF_STATUS                    ,
--            SLIP_TYPE                    ,
--            JOURNAL_NUM                  ,
--            ENTRY_DATE                   ,
--            REQUEST_KEY                  ,
--            REQUESTOR_PERSON_ID          ,
--            REQUESTOR_PERSON_NAME        ,
--            APPROVER_PERSON_ID           ,
--            APPROVER_PERSON_NAME         ,
--            REQUEST_DATE                 ,
--            APPROVAL_DATE                ,
--            REJECTION_DATE               ,
--            ACCOUNT_APPROVER_PERSON_ID   ,
--            ACCOUNT_APPROVAL_DATE        ,
--            GL_FORWORD_DATE              ,
--            RECOGNITION_CLASS            ,
--            APPROVER_COMMENTS            ,
--            REQUEST_ENABLE_FLAG          ,
--            ACCOUNT_REVISION_FLAG        ,
--            TOTAL_ENTERED_DR             ,
--            TOTAL_ACCOUNTED_DR           ,
--            TOTAL_ITEM_ENTERED_DR        ,
--            TOTAL_TAX_ENTERED_DR         ,
--            TOTAL_ENTERED_CR             ,
--            TOTAL_ACCOUNTED_CR           ,
--            TOTAL_ITEM_ENTERED_CR        ,
--            TOTAL_TAX_ENTERED_CR         ,
--            INVOICE_CURRENCY_CODE        ,
--            EXCHANGE_RATE                ,
--            EXCHANGE_RATE_TYPE           ,
--            EXCHANGE_RATE_TYPE_NAME      ,
--            IGNORE_RATE_FLAG             ,
--            DESCRIPTION                  ,
--            ENTRY_DEPARTMENT             ,
--            ENTRY_PERSON_ID              ,
--            ORIG_JOURNAL_NUM             ,
--            ACCOUNT_APPROVAL_FLAG        ,
--            PERIOD_NAME                  ,
--            GL_DATE                      ,
--            AUTO_TAX_CALC_FLAG           ,
--            AP_TAX_ROUNDING_RULE         ,
--            FORM_SELECT_FLAG             ,
--            ORG_ID                       ,
--            SET_OF_BOOKS_ID              ,
--            RECURRING_HEADER_NAME        ,
--            ATTRIBUTE_CATEGORY           ,
--            ATTRIBUTE1                   ,
--            ATTRIBUTE2                   ,
--            ATTRIBUTE3                   ,
--            ATTRIBUTE4                   ,
--            ATTRIBUTE5                   ,
--            ATTRIBUTE6                   ,
--            ATTRIBUTE7                   ,
--            ATTRIBUTE8                   ,
--            ATTRIBUTE9                   ,
--            ATTRIBUTE10                  ,
--            ATTRIBUTE11                  ,
--            ATTRIBUTE12                  ,
--            ATTRIBUTE13                  ,
--            ATTRIBUTE14                  ,
--            ATTRIBUTE15                  ,
--            CREATED_BY                   ,
--            CREATION_DATE                ,
--            LAST_UPDATED_BY              ,
--            LAST_UPDATE_DATE             ,
--            LAST_UPDATE_LOGIN            ,
--            REQUEST_ID                   ,
--            PROGRAM_APPLICATION_ID       ,
--            PROGRAM_UPDATE_DATE          ,
--            PROGRAM_ID                  
--          )
--          VALUES(
--            gn_journal_id,
--            xx03_if_header_rec.WF_STATUS,
--            xx03_if_header_rec.SLIP_TYPE,
--            gn_journal_id,
--            xx03_if_header_rec.ENTRY_DATE,
--            NULL,
--            xx03_if_header_rec.REQUESTOR_PERSON_ID,
--            xx03_if_header_rec.REQUESTOR_PERSON_NAME,
--            xx03_if_header_rec.APPROVER_PERSON_ID,
--            xx03_if_header_rec.APPROVER_PERSON_NAME,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            0,
--            NULL,
--            'N',
--            'N',
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            xx03_if_header_rec.INVOICE_CURRENCY_CODE,
--            xx03_if_header_rec.EXCHANGE_RATE,
--            xx03_if_header_rec.EXCHANGE_RATE_TYPE,
--            xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME,
--            xx03_if_header_rec.IGNORE_RATE_FLAG,
--            xx03_if_header_rec.DESCRIPTION,
--            xx03_if_header_rec.ENTRY_DEPARTMENT,
--            xx03_if_header_rec.ENTRY_PERSON_ID,
--            NULL,
--            'N',
--            xx03_if_header_rec.PERIOD_NAME,
--            xx03_if_header_rec.GL_DATE,
--            xx03_if_header_rec.AUTO_TAX_CALC_FLAG,
--            xx03_if_header_rec.AP_TAX_ROUNDING_RULE,
--            NULL,
--            xx03_if_header_rec.ORG_ID,
--            xx03_if_header_rec.SET_OF_BOOKS_ID,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            NULL,
--            xx00_global_pkg.user_id,
--            xx00_date_pkg.get_system_datetime_f,
--            xx00_global_pkg.user_id,
--            xx00_date_pkg.get_system_datetime_f,
--            xx00_global_pkg.login_id,
--            xx00_global_pkg.conc_request_id,
--            xx00_global_pkg.prog_appl_id,
--            xx00_date_pkg.get_system_datetime_f,
--            xx00_global_pkg.conc_program_id
--          );
----
--          -- ===============================
--          -- 明細データコピー
--          -- ===============================
--          copy_detail_data(
--            iv_source,         -- ソース
--            in_request_id,     -- 要求ID
--            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--            lv_retcode,        -- リターン・コード             --# 固定 #
--            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            RAISE global_process_expt;
--          END IF;
----
--          -- ===============================
--          -- 金額計算(E-3)
--          -- ===============================
--          calc_amount(
--            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--            lv_retcode,        -- リターン・コード             --# 固定 #
--            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            RAISE global_process_expt;
--          END IF;
----
--          -- ===============================
--          -- 重点管理チェック(E-4)
--          -- ===============================
--          xx03_deptinput_gl_check_pkg.set_account_approval_flag(
--            gn_journal_id,
--            lv_app_upd,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
--          IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--            -- 結果が正常なら、ヘッダレコードの重点管理フラグを更新
--            UPDATE XX03_JOURNAL_SLIPS xjs 
--               SET xjs.ACCOUNT_APPROVAL_FLAG = lv_app_upd
--             WHERE xjs.JOURNAL_ID = gn_journal_id;
--          ELSE
--            -- 結果が正常でなければ、エラーメッセージを出力
--            -- ステータスが現在の値より更に上位の値の時は上書き
--            IF ( TO_NUMBER(lv_retcode) > TO_NUMBER(gv_result)  ) THEN
--              gv_result := lv_retcode;
--            END IF;
--            -- エラー件数加算
--            gn_error_count := gn_error_count + 1;
--            xx00_file_pkg.output(
--              xx00_message_pkg.get_msg(
--                'XX03',
--                'APP-XX03-14143'
--              )
--            );
--          END IF;
----
--          -- ===============================
--          -- 仕訳チェック(E-5)
--          -- ===============================
--          xx03_deptinput_gl_check_pkg. check_deptinput_gl (
--            gn_journal_id,
--            ln_error_cnt,
--            lv_error_flg,
--            lv_error_flg1,
--            lv_error_msg1,
--            lv_error_flg2,
--            lv_error_msg2,
--            lv_error_flg3,
--            lv_error_msg3,
--            lv_error_flg4,
--            lv_error_msg4,
--            lv_error_flg5,
--            lv_error_msg5,
--            lv_error_flg6,
--            lv_error_msg6,
--            lv_error_flg7,
--            lv_error_msg7,
--            lv_error_flg8,
--            lv_error_msg8,
--            lv_error_flg9,
--            lv_error_msg9,
--            lv_error_flg10,
--            lv_error_msg10,
--            lv_error_flg11,
--            lv_error_msg11,
--            lv_error_flg12,
--            lv_error_msg12,
--            lv_error_flg13,
--            lv_error_msg13,
--            lv_error_flg14,
--            lv_error_msg14,
--            lv_error_flg15,
--            lv_error_msg15,
--            lv_error_flg16,
--            lv_error_msg16,
--            lv_error_flg17,
--            lv_error_msg17,
--            lv_error_flg18,
--            lv_error_msg18,
--            lv_error_flg19,
--            lv_error_msg19,
--            lv_error_flg20,
--            lv_error_msg20,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
--          IF ( ln_error_cnt > 0 ) THEN
--            -- ステータスが現在の値より更に上位の値の時は上書き
--            IF ( gv_result = cv_result_normal AND lv_error_flg = cv_dept_warning ) THEN
--              gv_result := cv_result_warning;
--            ELSIF ( lv_error_flg = cv_dept_error ) THEN
--              gv_result := cv_result_error;
--            END IF;
--            -- 仕訳エラー有り時は、存在する分全てエラーメッセージを出力
--            IF ( lv_error_flg1 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--               xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg1
--                )
--              );
--            END IF;
--            IF ( lv_error_flg2 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg2
--                )
--              );
--            END IF;
--            IF ( lv_error_flg3 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg3
--                )
--              );
--            END IF;
--            IF ( lv_error_flg4 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg4
--                )
--              );
--            END IF;
--            IF ( lv_error_flg5 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg5
--                )
--              );
--            END IF;
--            IF ( lv_error_flg6 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg6
--                )
--              );
--            END IF;
--            IF ( lv_error_flg7 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg7
--                )
--              );
--            END IF;
--            IF ( lv_error_flg8 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg8
--                )
--              );
--            END IF;
--            IF ( lv_error_flg9 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg9
--                )
--              );
--            END IF;
--            IF ( lv_error_flg10 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg10
--                )
--              );
--            END IF;
--            IF ( lv_error_flg11 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg11
--                )
--              );
--            END IF;
--            IF ( lv_error_flg12 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg12
--                )
--              );
--            END IF;
--            IF ( lv_error_flg13 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg13
--                )
--              );
--            END IF;
--            IF ( lv_error_flg14 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg14
--                )
--              );
--            END IF;
--            IF ( lv_error_flg15 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg15
--                )
--              );
--            END IF;
--            IF ( lv_error_flg16 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg16
--                )
--              );
--            END IF;
--            IF ( lv_error_flg17 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg17
--                )
--              );
--            END IF;
--            IF ( lv_error_flg18 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg18
--                )
--              );
--            END IF;
--            IF ( lv_error_flg19 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg19
--                )
--              );
--            END IF;
--            IF ( lv_error_flg20 <> cv_dept_normal ) THEN
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg20
--                )
--              );
--            END IF;
--          END IF;
--        END IF;
--      END IF;
----
--      -- INTERFACE_ID保存
--      ln_interface_id := xx03_if_header_rec.INTERFACE_ID;
----
--      -- エラーがなかった場合は'エラーなし'出力
--      IF ( gn_error_count = 0 ) THEN
--        xx00_file_pkg.output(
--          xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08020'
--          )
--        );
--      END IF;
----
--    END LOOP xx03_if_header_loop;
--    CLOSE xx03_if_header_cur;
----
--  EXCEPTION
----
----#################################  固定例外処理部 START   ####################################
----
--    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
--      ov_errmsg := lv_errmsg;
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
--    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
--      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
--      ov_retcode := xx00_common_pkg.set_status_error_f;
----
----#####################################  固定部 END   ##########################################
----
--  END copy_if_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_header_data
   * Description      : ヘッダデータのコピー
   ***********************************************************************************/
  PROCEDURE ins_header_data(
    iv_source     IN  VARCHAR2,     --  1.ソース
    in_request_id IN  NUMBER,       --  2.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_header_data'; -- プログラム名
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
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- 伝票ID取得
    SELECT XX03_JOURNAL_SLIPS_S.nextval
    INTO   gn_journal_id
    FROM   dual;
--
    -- インターフェーステーブル伝票ID更新
    UPDATE XX03_JOURNAL_SLIPS_IF xjsi
       SET JOURNAL_ID = gn_journal_id
    WHERE  xjsi.REQUEST_ID   = in_request_id
      AND  xjsi.SOURCE       = iv_source
      AND  xjsi.INTERFACE_ID = xx03_if_head_line_rec.HEAD_INTERFACE_ID;
--
    -- ヘッダデータ保存
    INSERT INTO XX03_JOURNAL_SLIPS(
      JOURNAL_ID                   ,
      WF_STATUS                    ,
      SLIP_TYPE                    ,
      JOURNAL_NUM                  ,
      ENTRY_DATE                   ,
      REQUEST_KEY                  ,
      REQUESTOR_PERSON_ID          ,
      REQUESTOR_PERSON_NAME        ,
      APPROVER_PERSON_ID           ,
      APPROVER_PERSON_NAME         ,
      REQUEST_DATE                 ,
      APPROVAL_DATE                ,
      REJECTION_DATE               ,
      ACCOUNT_APPROVER_PERSON_ID   ,
      ACCOUNT_APPROVAL_DATE        ,
      GL_FORWORD_DATE              ,
      RECOGNITION_CLASS            ,
      APPROVER_COMMENTS            ,
      REQUEST_ENABLE_FLAG          ,
      ACCOUNT_REVISION_FLAG        ,
      TOTAL_ENTERED_DR             ,
      TOTAL_ACCOUNTED_DR           ,
      TOTAL_ITEM_ENTERED_DR        ,
      TOTAL_TAX_ENTERED_DR         ,
      TOTAL_ENTERED_CR             ,
      TOTAL_ACCOUNTED_CR           ,
      TOTAL_ITEM_ENTERED_CR        ,
      TOTAL_TAX_ENTERED_CR         ,
      INVOICE_CURRENCY_CODE        ,
      EXCHANGE_RATE                ,
      EXCHANGE_RATE_TYPE           ,
      EXCHANGE_RATE_TYPE_NAME      ,
      IGNORE_RATE_FLAG             ,
      DESCRIPTION                  ,
      ENTRY_DEPARTMENT             ,
      ENTRY_PERSON_ID              ,
      ORIG_JOURNAL_NUM             ,
      ACCOUNT_APPROVAL_FLAG        ,
      PERIOD_NAME                  ,
      GL_DATE                      ,
      AUTO_TAX_CALC_FLAG           ,
      AP_TAX_ROUNDING_RULE         ,
      FORM_SELECT_FLAG             ,
      ORG_ID                       ,
      SET_OF_BOOKS_ID              ,
      RECURRING_HEADER_NAME        ,
      ATTRIBUTE_CATEGORY           ,
      ATTRIBUTE1                   ,
      ATTRIBUTE2                   ,
      ATTRIBUTE3                   ,
      ATTRIBUTE4                   ,
      ATTRIBUTE5                   ,
      ATTRIBUTE6                   ,
      ATTRIBUTE7                   ,
      ATTRIBUTE8                   ,
      ATTRIBUTE9                   ,
      ATTRIBUTE10                  ,
      ATTRIBUTE11                  ,
      ATTRIBUTE12                  ,
      ATTRIBUTE13                  ,
      ATTRIBUTE14                  ,
      ATTRIBUTE15                  ,
      CREATED_BY                   ,
      CREATION_DATE                ,
      LAST_UPDATED_BY              ,
      LAST_UPDATE_DATE             ,
      LAST_UPDATE_LOGIN            ,
      REQUEST_ID                   ,
      PROGRAM_APPLICATION_ID       ,
      PROGRAM_UPDATE_DATE          ,
      PROGRAM_ID
    )
    VALUES(
      gn_journal_id,
      xx03_if_head_line_rec.HEAD_WF_STATUS,
      xx03_if_head_line_rec.HEAD_SLIP_TYPE,
      gn_journal_id,
      xx03_if_head_line_rec.HEAD_ENTRY_DATE,
      NULL,
      xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_ID,
      xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_NAME,
      xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID,
      xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      0,
      NULL,
      'N',
      'N',
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME,
      xx03_if_head_line_rec.HEAD_IGNORE_RATE_FLAG,
      xx03_if_head_line_rec.HEAD_DESCRIPTION,
      xx03_if_head_line_rec.HEAD_ENTRY_DEPARTMENT,
      xx03_if_head_line_rec.HEAD_ENTRY_PERSON_ID,
      NULL,
      'N',
      xx03_if_head_line_rec.HEAD_PERIOD_NAME,
      xx03_if_head_line_rec.HEAD_GL_DATE,
      xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG,
      xx03_if_head_line_rec.HEAD_AP_TAX_ROUNDING_RULE,
      NULL,
      xx03_if_head_line_rec.HEAD_ORG_ID,
      xx03_if_head_line_rec.HEAD_SET_OF_BOOKS_ID,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
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
  END ins_header_data;
--
  /**********************************************************************************
   * Procedure Name   : ins_detail_data
   * Description      : 明細データのコピー
   ***********************************************************************************/
  PROCEDURE ins_detail_data(
    iv_source        IN  VARCHAR2,     --  1.ソース
    in_request_id    IN  NUMBER,       --  2.要求ID
    in_line_count_dr IN  NUMBER,       --  3.借方明細行数
    in_line_count_cr IN  NUMBER,       --  4.貸方明細行数
    ov_errbuf        OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode       OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg        OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'ins_detail_data'; -- プログラム名
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
    ln_line_id        NUMBER;          -- 明細ID
    ln_amount_dr      NUMBER;          -- 金額
    ln_amount_cr      NUMBER;          -- 金額
    lv_slip_type_name VARCHAR2(4000);  -- 摘要名称
    ln_line_count     NUMBER;          -- 明細行数
    lv_amount_includes_tax_flag_dr VARCHAR2(1);
    lv_amount_includes_tax_flag_cr VARCHAR2(1);
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
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
    -- 明細ID取得
    SELECT XX03_JOURNAL_SLIP_LINES_S.nextval
    INTO   ln_line_id
    FROM   dual;
--
    -- 金額算出
    IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR = cv_yes ) THEN
      -- '内税'が'Y'の時は金額は'本体金額+消費税額'
      ln_amount_dr :=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR
                     + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR;
    ELSIF  ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR = cv_no ) THEN
      -- '内税'が'N'の時は金額は'本体金額'
      ln_amount_dr := xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR;
    ELSE
      -- ver 11.5.10.2.2 Chg Start
      ---- それ以外の時は内税入力値エラー
      --ln_amount_dr := 0;
      ---- ステータスをエラーに
      --gv_result := cv_result_error;
      ---- エラー件数加算
      --gn_error_count := gn_error_count + 1;
      --xx00_file_pkg.output(
      --  xx00_message_pkg.get_msg(
      --    'XX03',
      --    'APP-XX03-08027'
      --  )
      --);
      -- ver 11.5.10.2.5B Chg Start
      ---- それ以外の時は金額を0にする
      --ln_amount_dr := 0;
      -- それ以外の時(明細の入力していない貸借側)は金額をnullにする
      ln_amount_dr := null;
      -- ver 11.5.10.2.5B Chg End
      -- ver 11.5.10.2.2 Chg End
    END IF;
--
    -- 金額算出
    IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR = cv_yes ) THEN
      -- '内税'が'Y'の時は金額は'本体金額+消費税額'
      ln_amount_cr :=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR
                     + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR;
    ELSIF  ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR = cv_no ) THEN
      -- '内税'が'N'の時は金額は'本体金額'
      ln_amount_cr := xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR;
    ELSE
      -- ver 11.5.10.2.2 Chg Start
      ---- それ以外の時は内税入力値エラー
      --ln_amount_cr := 0;
      ---- ステータスをエラーに
      --gv_result := cv_result_error;
      ---- エラー件数加算
      --gn_error_count := gn_error_count + 1;
      --xx00_file_pkg.output(
      --  xx00_message_pkg.get_msg(
      --    'XX03',
      --    'APP-XX03-08027'
      --  )
      --);
      -- ver 11.5.10.2.5B Chg Start
      ---- それ以外の時は金額を0にする
      --ln_amount_cr := 0;
      -- それ以外の時(明細の入力していない貸借側)は金額をnullにする
      ln_amount_cr := null;
      -- ver 11.5.10.2.5B Chg End
      -- ver 11.5.10.2.2 Chg End
    END IF;
--
    -- 税フラグの確定
    IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NULL THEN
      lv_amount_includes_tax_flag_dr := NULL;
    ELSE
      lv_amount_includes_tax_flag_dr := xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR;
    END IF;
    IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
      lv_amount_includes_tax_flag_cr := NULL;
    ELSE
      lv_amount_includes_tax_flag_cr := xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR;
    END IF;
--
    -- 明細行数の確定（貸方借方より）
    IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
      ln_line_count := in_line_count_dr;
    ELSE
      ln_line_count := in_line_count_cr;
    END IF;
--
    -- 明細データ保存
    INSERT INTO XX03_JOURNAL_SLIP_LINES(
      JOURNAL_LINE_ID             ,
      JOURNAL_ID                  ,
      LINE_NUMBER                 ,
      SLIP_LINE_TYPE_DR           ,
      SLIP_LINE_TYPE_NAME_DR      ,
      ENTERED_AMOUNT_DR           ,
      ENTERED_ITEM_AMOUNT_DR      ,
      AMOUNT_INCLUDES_TAX_FLAG_DR ,
      TAX_CODE_DR                 ,
      TAX_NAME_DR                 ,
      ENTERED_TAX_AMOUNT_DR       ,
      ACCOUNTED_AMOUNT_DR         ,
      SLIP_LINE_TYPE_CR           ,
      SLIP_LINE_TYPE_NAME_CR      ,
      ENTERED_AMOUNT_CR           ,
      ENTERED_ITEM_AMOUNT_CR      ,
      AMOUNT_INCLUDES_TAX_FLAG_CR ,
      TAX_CODE_CR                 ,
      TAX_NAME_CR                 ,
      ENTERED_TAX_AMOUNT_CR       ,
      ACCOUNTED_AMOUNT_CR         ,
      DESCRIPTION                 ,
      SEGMENT1                    ,
      SEGMENT2                    ,
      SEGMENT3                    ,
      SEGMENT4                    ,
      SEGMENT5                    ,
      SEGMENT6                    ,
      SEGMENT7                    ,
      SEGMENT8                    ,
      SEGMENT9                    ,
      SEGMENT10                   ,
      SEGMENT11                   ,
      SEGMENT12                   ,
      SEGMENT13                   ,
      SEGMENT14                   ,
      SEGMENT15                   ,
      SEGMENT16                   ,
      SEGMENT17                   ,
      SEGMENT18                   ,
      SEGMENT19                   ,
      SEGMENT20                   ,
      SEGMENT1_NAME               ,
      SEGMENT2_NAME               ,
      SEGMENT3_NAME               ,
      SEGMENT4_NAME               ,
      SEGMENT5_NAME               ,
      SEGMENT6_NAME               ,
      SEGMENT7_NAME               ,
      SEGMENT8_NAME               ,
      INCR_DECR_REASON_CODE       ,
      INCR_DECR_REASON_NAME       ,
      RECON_REFERENCE             ,
      ORG_ID                      ,
      ATTRIBUTE_CATEGORY          ,
      ATTRIBUTE1                  ,
      ATTRIBUTE2                  ,
      ATTRIBUTE3                  ,
      ATTRIBUTE4                  ,
      ATTRIBUTE5                  ,
      ATTRIBUTE6                  ,
      ATTRIBUTE7                  ,
      ATTRIBUTE8                  ,
      ATTRIBUTE9                  ,
      ATTRIBUTE10                 ,
      ATTRIBUTE11                 ,
      ATTRIBUTE12                 ,
      ATTRIBUTE13                 ,
      ATTRIBUTE14                 ,
      ATTRIBUTE15                 ,
      CREATED_BY                  ,
      CREATION_DATE               ,
      LAST_UPDATED_BY             ,
      LAST_UPDATE_DATE            ,
      LAST_UPDATE_LOGIN           ,
      REQUEST_ID                  ,
      PROGRAM_APPLICATION_ID      ,
      PROGRAM_ID                  ,
      PROGRAM_UPDATE_DATE
    )
    VALUES(
      ln_line_id,
      gn_journal_id,
      ln_line_count,
      NULL,
      NULL,
      ln_amount_dr,
      xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR,
      lv_amount_includes_tax_flag_dr,
      xx03_if_head_line_rec.LINE_TAX_CODE_DR,
      xx03_if_head_line_rec.LINE_TAX_NAME_DR,
      xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR,
      xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR,
      NULL,
      NULL,
      ln_amount_cr,
      xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR,
      lv_amount_includes_tax_flag_cr,
      xx03_if_head_line_rec.LINE_TAX_CODE_CR,
      xx03_if_head_line_rec.LINE_TAX_NAME_CR,
      xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR,
      xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR,
      xx03_if_head_line_rec.LINE_DESCRIPTION,
      xx03_if_head_line_rec.LINE_SEGMENT1,
      xx03_if_head_line_rec.LINE_SEGMENT2,
      xx03_if_head_line_rec.LINE_SEGMENT3,
      xx03_if_head_line_rec.LINE_SEGMENT4,
      xx03_if_head_line_rec.LINE_SEGMENT5,
      xx03_if_head_line_rec.LINE_SEGMENT6,
      xx03_if_head_line_rec.LINE_SEGMENT7,
      xx03_if_head_line_rec.LINE_SEGMENT8,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
      xx03_if_head_line_rec.LINE_SEGMENT1_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT2_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT3_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT4_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT5_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT6_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT7_NAME,
      xx03_if_head_line_rec.LINE_SEGMENT8_NAME,
      xx03_if_head_line_rec.LINE_INCR_DECR_REASON_CODE,
      xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME,
      xx03_if_head_line_rec.LINE_RECON_REFERENCE,
      xx03_if_head_line_rec.LINE_ORG_ID,
-- == 2016/11/04 V1.1 Modified START ===============================================================
      xx03_if_head_line_rec.HEAD_SET_OF_BOOKS_ID,
--      NULL,
-- == 2016/11/04 V1.1 Modified END   ===============================================================
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
-- == 2016/11/04 V1.1 Modified START ===============================================================
      xx03_if_head_line_rec.LINE_ATTRIBUTE9,
--      NULL,
-- == 2016/11/04 V1.1 Modified END   ===============================================================
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx00_global_pkg.user_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.user_id,
      xx00_date_pkg.get_system_datetime_f,
      xx00_global_pkg.login_id,
      xx00_global_pkg.conc_request_id,
      xx00_global_pkg.prog_appl_id,
      xx00_global_pkg.conc_program_id,
      xx00_date_pkg.get_system_datetime_f
    );
--
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
  END ins_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : check_header_data
   * Description      : 仕訳伝票データの入力チェック(E-2)
   ***********************************************************************************/
  PROCEDURE check_header_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_header_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
-- Ver11.5.10.1.5B Add Start
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
-- ver 11.5.10.2.10B Del Start
--    -- 承認者情報カーソル
---- Ver11.5.10.1.6B Chg Start
----    CURSOR xx03_approve_chk_cur(i_person_id NUMBER)
--    CURSOR xx03_approve_chk_cur(i_person_id NUMBER, i_val_dep VARCHAR2)
---- Ver11.5.10.1.6B Chg End
--    IS
--      SELECT
--        count('x') rec_cnt
--      FROM
--        XX03_APPROVER_PERSON_LOV_V xaplv
--      WHERE
--        xaplv.PERSON_ID = i_person_id
---- Ver11.5.10.1.6B Add Start
--      AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
--           or xaplv.PROFILE_VAL_DEP = i_val_dep)
---- Ver11.5.10.1.6B Add End
--    ;
--    -- 承認者情報カーソルレコード型
--    xx03_approve_chk_rec xx03_approve_chk_cur%ROWTYPE;
-- ver 11.5.10.2.10B Del End
--
-- Ver11.5.10.1.5B Add End
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- 伝票種別チェック
    IF ( xx03_if_head_line_rec.HEAD_SLIP_TYPE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_SLIP_TYPE) = '' ) THEN
      -- 伝票種別IDが空の場合は伝票種別入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08010'
        )
      );
    END IF;
--
    -- 承認者チェック
    IF ( xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME) = '' ) THEN
      -- 承認者名が空の場合は承認者入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08011'
        )
      );
-- Ver11.5.10.1.5B Add Start
    -- 承認者チェック
    ELSE 
-- ver 11.5.10.2.10B Chg Start
--      -- 承認者名が入力されている場合は承認ビューにて再チェック
---- Ver11.5.10.1.6B Chg Start
----      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID);
--      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID ,xx03_if_head_line_rec.HEAD_SLIP_TYPE_APP);
---- Ver11.5.10.1.6B Chg End
--      FETCH xx03_approve_chk_cur INTO xx03_approve_chk_rec;
----
--      -- カウントカーソルなのでありえないが、パターンとして作成
--      IF xx03_approve_chk_cur%NOTFOUND THEN
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-08011'));
----
--      -- 対象データが取得できなかった場合
--      ELSIF xx03_approve_chk_rec.rec_cnt = 0 THEN
--        -- ステータスをエラーに
--        gv_result := cv_result_error;
--        -- エラー件数加算
--        gn_error_count := gn_error_count + 1;
--        xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-08011'));
--      END IF;
----
--      CLOSE xx03_approve_chk_cur;
--
      -- 承認者名が入力されている場合は承認ビューから取得できているか再チェック
      IF ( xx03_if_head_line_rec.APPROVER_PERSON_ID IS NULL
             OR TRIM(xx03_if_head_line_rec.APPROVER_PERSON_ID) = '' ) THEN
        -- 空の場合は承認者入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08011'
          )
        );
      END IF;
-- ver 11.5.10.2.10B Chg End
-- Ver11.5.10.1.5B Add End
    END IF;
--
    -- 計上日チェック
    IF ( xx03_if_head_line_rec.HEAD_GL_DATE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_GL_DATE) = '' ) THEN
      -- 計上日が空の場合は計上日入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08015'
        )
      );
    END IF;
--
    -- 会計期間チェック
    IF ( xx03_if_head_line_rec.HEAD_PERIOD_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_PERIOD_NAME) = '' ) THEN
      -- 会計期間が空の場合は会計期間入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08028'
        )
      );
    END IF;
--
    -- 通貨チェック
    IF ( xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE) = '' ) THEN
      -- 通貨が空の場合は通貨入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08018'
        )
      );
    END IF;
--
    -- レートタイプチェック
    IF ( xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME IS NOT NULL
           AND ( xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE) = '' )) THEN
      -- レートタイプコードが取得できなかった場合はレートタイプ入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08025'
        )
      );
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
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
  END check_header_data;
--
--
  /**********************************************************************************
   * Procedure Name   : check_detail_data
   * Description      : 仕訳伝票明細データの入力チェック(E-2)
   ***********************************************************************************/
  PROCEDURE check_detail_data(
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_detail_data'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- 会社チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT1 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT1) = '' ) THEN
      -- 会社セグメントが空の場合は会社入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14114'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT1')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- 部門チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT2 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT2) = '' ) THEN
      -- 部門セグメントが空の場合は部門入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14115'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT2')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- 勘定科目チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT3 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT3) = '' ) THEN
      -- 勘定科目セグメントが空の場合は勘定科目入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14116'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT3')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- 補助科目チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT4 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT4) = '' ) THEN
      -- 補助科目セグメントが空の場合は補助科目入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14117'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT4')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- 相手先チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT5 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT5) = '' ) THEN
      -- 相手先セグメントが空の場合は相手先入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14118'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT5')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- 事業区分チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT6 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT6) = '' ) THEN
      -- 事業区分セグメントが空の場合は事業区分入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14119'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT6')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- プロジェクトチェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT7 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT7) = '' ) THEN
      -- プロジェクトセグメントが空の場合はプロジェクト入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-14120'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT7')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
    -- 予備チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT8 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT8) = '' ) THEN
      -- 予備セグメントが空の場合は予備入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        -- ver 11.5.10.2.2B Chg Start
        --xx00_message_pkg.get_msg(
        --  'XX03',
        --  'APP-XX03-08023'
        --)
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14114',
          'TOK_SEGMENT1',
          xx03_get_prompt_pkg.aff_segment('SEGMENT8')
        )
        -- ver 11.5.10.2.2B Chg End
      );
    END IF;
--
-- ver 11.5.10.2.10 Add Start
    -- 増減事由チェック
    IF ( xx03_if_head_line_rec.LINE_INCR_DECR_REASON_CODE IS NOT NULL
           AND ( xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME) = '' )) THEN
      -- 増減事由コード入力時に名称が取得できなかった場合は増減事由入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08047'
        )
      );
    END IF;
-- ver 11.5.10.2.10 Add End
--
    -- ver 11.5.10.2.2 Add Start
    -- 借方貸方が入力されてない場合
    IF (    xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NULL
        AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NULL
        AND xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NULL
        AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NULL
        AND xx03_if_head_line_rec.LINE_TAX_CODE_DR            IS NULL
        AND xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL
        AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NULL
        AND xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NULL
        AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NULL
        AND xx03_if_head_line_rec.LINE_TAX_CODE_CR            IS NULL
        ) THEN
      -- 借方貸方共に入力されていない場合はエラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-11573'
        )
      );
    -- 借方貸方が入力されている場合
    ELSIF (    (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NOT NULL
                OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_TAX_CODE_DR            IS NOT NULL
                )
           AND (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NOT NULL
                OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NOT NULL
                OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NOT NULL
                OR xx03_if_head_line_rec.LINE_TAX_CODE_CR            IS NOT NULL
                )
           ) THEN
      -- 借方貸方共に入力されている場合はエラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-11574'
        )
      );
    ELSE
    -- ver 11.5.10.2.2 Add End
--
    -- ver 11.5.10.2.2 Chg Start
    ---- 借方本体金額が入力されている場合
    --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
    --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
    -- 借方が入力されている場合
    IF (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NOT NULL
        OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_TAX_CODE_DR            IS NOT NULL
        ) THEN
    -- ver 11.5.10.2.2 Chg End
--
      -- ver 11.5.10.2.2 Add Start
      -- 本体金額(DR)チェック
      IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NULL THEN
        -- 借方本体金額が空の場合は借方本体金額入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08021'
          )
        );
      END IF;
      -- ver 11.5.10.2.2 Add Start
--
      -- ver 11.5.10.2.2 Chg Start
      -- 消費税額(DR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR IS NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR) = '' ) THEN
      IF xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR IS NULL THEN
      -- ver 11.5.10.2.2 Chg End
        -- 借方消費税額が空の場合は消費税額入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14113'
          )
        );
      END IF;
--
      -- 内税(DR)チェック
      IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR) = '' ) THEN
        -- 借方内税が空の場合は内税入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08022'
          )
        );
      ELSE
        -- 内税(DR)入力値チェック
        IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR != cv_yes
               AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_DR != cv_no ) THEN
          -- 借方内税の入力値が不正の場合は内税入力値エラー表示
          -- ステータスをエラーに
          gv_result := cv_result_error;
          -- エラー件数加算
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08027'
            )
          );
        END IF;
      END IF;
--
      -- 税区分(DR)チェック
-- ver 11.5.10.2.10 Chg Start
--      IF ( xx03_if_head_line_rec.LINE_TAX_CODE_DR IS NULL
--             OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_DR) = '' ) THEN
      IF ( xx03_if_head_line_rec.LINE_TAX_NAME_DR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_TAX_NAME_DR) = '' ) THEN
-- ver 11.5.10.2.10 Chg End
        -- 借方税区分が空の場合は税区分入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14111'
          )
        );
      END IF;
--
      -- 換算済金額(DR)チェック
      -- ver 11.5.10.2.2 Chg Start
      --IF xx03_if_head_line_rec.HEAD_IGNORE_RATE_FLAG = 'N' THEN
      --  IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR IS NULL
      --         OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR) = '' ) THEN
        IF xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR IS NULL THEN
      -- ver 11.5.10.2.2 Chg End
          -- 借方換算済金額が空の場合は換算済金額入力エラー表示
          -- ステータスをエラーに
          gv_result := cv_result_error;
          -- エラー件数加算
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-11505'
            )
          );
        END IF;
      -- ver 11.5.10.2.2 Chg Start
      --END IF;
      -- ver 11.5.10.2.2 Chg End
--
      -- ver 11.5.10.2.2 Del Start
      ---- 本体金額(CR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
      --  -- 貸方本体金額が空でない場合は貸方本体金額入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11507'
      --    )
      --  );
      --END IF;
--
      ---- 消費税額(CR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR) != '' ) THEN
      --  -- 貸方消費税額が空でない場合は貸方消費税額入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11508'
      --    )
      --  );
      --END IF;
--
      ---- 税区分(CR)チェック
      --IF ( xx03_if_head_line_rec.LINE_TAX_CODE_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_CR) != '' ) THEN
      --  -- 貸方税区分が空でない場合は貸方税区分入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11510'
      --    )
      --  );
      --END IF;
--
      ---- 換算済金額(CR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR) != '' ) THEN
      --  -- 貸方換算済金額が空でない場合は貸方換算済金額入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11511'
      --    )
      --  );
      --END IF;
    -- ver 11.5.10.2.2 Del Start
--
      -- ver 11.5.10.2.2 Add Start
      -- 金額正常入力時チェック
      IF (    xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR    IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  IS NOT NULL ) THEN
      -- ver 11.5.10.2.2 Add End
-- ver 11.5.10.1.6E Add Start
      -- 機能通貨時、入力金額本体＋税金と換算済金額の一致チェック(DR)
      IF (    (xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE  =  gv_cur_code)
          AND (xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR   !=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR
                                                                  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR  ) ) THEN
        -- 一致していない場合は貸方換算済金額入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-11570'
          )
        );
      END IF;
-- ver 11.5.10.1.6E Add End
      -- ver 11.5.10.2.2 Add Start
      END IF;
      -- ver 11.5.10.2.2 Add End
    END IF;
--
    -- ver 11.5.10.2.2 Chg Start
    --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
    --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR) != '' ) THEN
    -- 貸方が入力されている場合
    IF (   xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NOT NULL
        OR xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NOT NULL
        OR xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NOT NULL
        OR xx03_if_head_line_rec.LINE_TAX_CODE_CR            IS NOT NULL
        ) THEN
    -- ver 11.5.10.2.2 Chg End
--
      -- ver 11.5.10.2.2 Add Start
      -- 本体金額(CR)チェック
      IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
        -- 貸方本体金額が空の場合は貸方本体金額入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08021'
          )
        );
      END IF;
      -- ver 11.5.10.2.2 Add End
--
      -- ver 11.5.10.2.2 Chg Start
      -- 消費税額(CR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR IS NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR) = '' ) THEN
      IF xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR IS NULL THEN
      -- ver 11.5.10.2.2 Chg End
        -- 貸方消費税額が空の場合は消費税額入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14113'
          )
        );
      END IF;
--
      -- 内税(CR)チェック
      IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR) = '' ) THEN
        -- 貸方内税が空の場合は内税入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08022'
          )
        );
      ELSE
        -- 内税(CR)入力値チェック
        IF ( xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR != cv_yes
               AND xx03_if_head_line_rec.LINE_AMOUNT_INC_TAX_FLAG_CR != cv_no ) THEN
          -- 貸方内税の入力値が不正の場合は内税入力値エラー表示
          -- ステータスをエラーに
          gv_result := cv_result_error;
          -- エラー件数加算
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08027'
            )
          );
        END IF;
      END IF;
--
      -- 税区分(CR)チェック
-- ver 11.5.10.2.10 Chg Start
--      IF ( xx03_if_head_line_rec.LINE_TAX_CODE_CR IS NULL
--             OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_CR) = '' ) THEN
      IF ( xx03_if_head_line_rec.LINE_TAX_NAME_CR IS NULL
             OR TRIM(xx03_if_head_line_rec.LINE_TAX_NAME_CR) = '' ) THEN
-- ver 11.5.10.2.10 Chg End
        -- 貸方税区分が空の場合は税区分入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-14111'
          )
        );
      END IF;
--
      -- 換算済金額(CR)チェック
      IF xx03_if_head_line_rec.HEAD_IGNORE_RATE_FLAG = 'N' THEN
        IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR IS NULL
               OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR) = '' ) THEN
          -- 貸方換算済金額が空の場合は換算済金額入力エラー表示
          -- ステータスをエラーに
          gv_result := cv_result_error;
          -- エラー件数加算
          gn_error_count := gn_error_count + 1;
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-11505'
            )
          );
        END IF;
      END IF;
--
      -- ver 11.5.10.2.2 Del Start
      ---- 本体金額(DR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR) != '' ) THEN
      --  -- 借方本体金額が空でない場合は借方本体金額入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11512'
      --    )
      --  );
      --END IF;
--
      ---- 消費税額(DR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR) != '' ) THEN
      --  -- 借方消費税額が空でない場合は借方消費税額入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11513'
      --    )
      --  );
      --END IF;
--
      ---- 税区分(DR)チェック
      --IF ( xx03_if_head_line_rec.LINE_TAX_CODE_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_TAX_CODE_DR) != '' ) THEN
      --  -- 借方税区分が空でない場合は借方税区分入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11515'
      --    )
      --  );
      --END IF;
--
      ---- 換算済金額(DR)チェック
      --IF ( xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR IS NOT NULL
      --       OR TRIM(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR) != '' ) THEN
      --  -- 借方換算済金額が空でない場合は借方換算済金額入力エラー表示
      --  -- ステータスをエラーに
      --  gv_result := cv_result_error;
      --  -- エラー件数加算
      --  gn_error_count := gn_error_count + 1;
      --  xx00_file_pkg.output(
      --    xx00_message_pkg.get_msg(
      --      'XX03',
      --      'APP-XX03-11516'
      --    )
      --  );
      --END IF;
      -- ver 11.5.10.2.2 Del End
--
      -- ver 11.5.10.2.2 Add Start
      -- 金額正常入力時チェック
      IF (    xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR    IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NOT NULL
          AND xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  IS NOT NULL ) THEN
      -- ver 11.5.10.2.2 Add End
-- ver 11.5.10.1.6E Add Start
      -- 機能通貨時、入力金額本体＋税金と換算済金額の一致チェック(CR)
      IF (    (xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE  =  gv_cur_code)
          AND (xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR   !=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR
                                                                  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR  ) ) THEN
        -- 一致していない場合は貸方換算済金額入力エラー表示
        -- ステータスをエラーに
        gv_result := cv_result_error;
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-11571'
          )
        );
      END IF;
-- ver 11.5.10.1.6E Add End
      -- ver 11.5.10.2.2 Add Start
      END IF;
      -- ver 11.5.10.2.2 Add End
    END IF;
--
    -- ver 11.5.10.2.2 Add Start
    END IF;
    -- ver 11.5.10.2.2 Add End
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
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
  END check_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : check_head_line_new
   * Description      : 請求書データの入力チェック
   ***********************************************************************************/
  PROCEDURE check_head_line_new(
    in_total_item_amount_dr  IN  NUMBER,       --  1.合計本体金額
    in_total_item_amount_cr  IN  NUMBER,       --  1.合計本体金額
    in_total_tax_amount_dr   IN  NUMBER,       --  2.合計税金金額
    in_total_tax_amount_cr   IN  NUMBER,       --  2.合計税金金額
    in_total_acc_amount_dr   IN  NUMBER,       --  3.合計換算金額
    in_total_acc_amount_cr   IN  NUMBER,       --  3.合計換算金額
    ov_errbuf                OUT VARCHAR2,     --  エラー・メッセージ                  --# 固定 #
    ov_retcode               OUT VARCHAR2,     --  リターン・コード                    --# 固定 #
    ov_errmsg                OUT VARCHAR2)     --  ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'check_head_line_new'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_app_upd VARCHAR2(1);         -- 重点管理フラグ
--
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
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ヘッダ金額更新
    UPDATE XX03_JOURNAL_SLIPS xjs
    SET    xjs.TOTAL_ITEM_ENTERED_DR = in_total_item_amount_dr
         , xjs.TOTAL_ITEM_ENTERED_CR = in_total_item_amount_cr
         , xjs.TOTAL_TAX_ENTERED_DR  = in_total_tax_amount_dr
         , xjs.TOTAL_TAX_ENTERED_CR  = in_total_tax_amount_cr
         , xjs.TOTAL_ENTERED_DR      = (in_total_item_amount_dr + in_total_tax_amount_dr)
         , xjs.TOTAL_ENTERED_CR      = (in_total_item_amount_cr + in_total_tax_amount_cr)
         , xjs.TOTAL_ACCOUNTED_DR    = in_total_acc_amount_dr
         , xjs.TOTAL_ACCOUNTED_CR    = in_total_acc_amount_cr
    WHERE  xjs.JOURNAL_ID = gn_journal_id
      AND  xjs.ORG_ID     = gn_org_id;
--
-- ver 11.5.10.1.6E Add Start
    -- 換算済金額が一致していない場合エラー
    IF (in_total_acc_amount_dr != in_total_acc_amount_cr) THEN
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-11527'));
    END IF;
-- ver 11.5.10.1.6E Add End
--
    -- 重点管理チェック
    xx03_deptinput_gl_check_pkg.set_account_approval_flag(
      gn_journal_id,
      lv_app_upd,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      -- 結果が正常なら、ヘッダレコードの重点管理フラグを更新
      UPDATE XX03_JOURNAL_SLIPS xjs
      SET    xjs.ACCOUNT_APPROVAL_FLAG = lv_app_upd
      WHERE  xjs.JOURNAL_ID = gn_journal_id
        AND  xjs.ORG_ID     = gn_org_id;
    ELSE
      -- 結果が正常でなければ、エラーメッセージを出力
      -- ステータスが現在の値より更に上位の値の時は上書き
      IF ( TO_NUMBER(lv_retcode) > TO_NUMBER(gv_result)  ) THEN
        gv_result := lv_retcode;
      END IF;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14143'
        )
      );
    END IF;
--
    -- 仕訳チェック
    xx03_deptinput_gl_check_pkg.check_deptinput_gl(
      gn_journal_id,
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
    IF ( ln_error_cnt > 0 ) THEN
      -- ステータスが現在の値より更に上位の値の時は上書き
      IF ( gv_result = cv_result_normal AND lv_error_flg = cv_dept_warning ) THEN
        gv_result := cv_result_warning;
      ELSIF ( lv_error_flg = cv_dept_error ) THEN
        gv_result := cv_result_error;
      END IF;
      -- 仕訳エラー有り時は、存在する分全てエラーメッセージを出力
      IF ( lv_error_flg1 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg1
          )
        );
      END IF;
      IF ( lv_error_flg2 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg2
          )
        );
      END IF;
      IF ( lv_error_flg3 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg3
          )
        );
      END IF;
      IF ( lv_error_flg4 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg4
          )
        );
      END IF;
      IF ( lv_error_flg5 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg5
          )
        );
      END IF;
      IF ( lv_error_flg6 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg6
          )
        );
      END IF;
      IF ( lv_error_flg7 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg7
          )
        );
      END IF;
      IF ( lv_error_flg8 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg8
          )
        );
      END IF;
      IF ( lv_error_flg9 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg9
          )
        );
      END IF;
      IF ( lv_error_flg10 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg10
          )
        );
      END IF;
      IF ( lv_error_flg11 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg11
          )
        );
      END IF;
      IF ( lv_error_flg12 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg12
          )
        );
      END IF;
      IF ( lv_error_flg13 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg13
          )
        );
      END IF;
      IF ( lv_error_flg14 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg14
          )
        );
      END IF;
      IF ( lv_error_flg15 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg15
          )
        );
      END IF;
      IF ( lv_error_flg16 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg16
          )
        );
      END IF;
      IF ( lv_error_flg17 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg17
          )
        );
      END IF;
      IF ( lv_error_flg18 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg18
          )
        );
      END IF;
      IF ( lv_error_flg19 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg19
          )
        );
      END IF;
      IF ( lv_error_flg20 <> cv_dept_normal ) THEN
        -- エラー件数加算
        gn_error_count := gn_error_count + 1;
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg20
          )
        );
      END IF;
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
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
  END check_head_line_new;
--
  /**********************************************************************************
   * Procedure Name   : copy_if_data
   * Description      : インターフェースデータのコピー(E-1)
   ***********************************************************************************/
  PROCEDURE copy_if_data(
    iv_source     IN  VARCHAR2,     -- 1.ソース
    in_request_id IN  NUMBER,       -- 2.要求ID
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'copy_if_data'; -- プログラム名
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
    ln_max_line              NUMBER := xx00_profile_pkg.value('VO_MAX_FETCH_SIZE'); -- 最大明細行数
    lv_max_over_flg          VARCHAR2(1);   -- 最大明細行オーバーフラグ
    ln_interface_id          NUMBER;        -- INTERFACE_ID
    ln_if_id_back            NUMBER;        -- INTERFACE_ID前レコード重複チェック
    lv_if_id_new_flg         VARCHAR2(1);   -- INTERFACE_ID変更フラグ
    lv_first_flg             VARCHAR2(1);   -- 初期レコードフラグ
    ln_total_item_amount_dr  NUMBER;        -- 本体金額合計
    ln_total_item_amount_cr  NUMBER;        -- 本体金額合計
    ln_total_tax_amount_dr   NUMBER;        -- 本体税金合計
    ln_total_tax_amount_cr   NUMBER;        -- 本体税金合計
    ln_total_acc_amount_dr   NUMBER;        -- 換算金額合計
    ln_total_acc_amount_cr   NUMBER;        -- 換算金額合計
    ln_line_count_dr         NUMBER;        -- 明細件数カウント
    ln_line_count_cr         NUMBER;        -- 明細件数カウント
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ***************************************
    -- ***        実処理の記述             ***
    -- ***       共通関数の呼び出し        ***
    -- ***************************************
--
    -- オルグIDの取得
    gn_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
--
    -- 機能通貨コード取得
    SELECT gsob.currency_code
      INTO gv_cur_code
      FROM gl_sets_of_books gsob
     WHERE gsob.set_of_books_id = xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
--
    -- ステータス初期化
    gv_result := cv_result_normal;
    ln_interface_id := NULL;
--
--
    -- 初期レコードフラグ
    lv_first_flg      := '1';
    ln_if_id_back     := -1;
--
    -- ヘッダ明細情報カーソルオープン
    OPEN xx03_if_head_line_cur(iv_source, in_request_id, gv_cur_code);
--
    <<xx03_if_loop>>
    LOOP
--
      FETCH xx03_if_head_line_cur INTO xx03_if_head_line_rec;
      IF xx03_if_head_line_cur%NOTFOUND THEN
        -- 対象データがなくなるまでループ
        EXIT xx03_if_loop;
      END IF;
--
      IF ln_if_id_back != xx03_if_head_line_rec.HEAD_INTERFACE_ID THEN
--
        IF lv_first_flg = '1' THEN
          lv_first_flg := '0';
        ELSE
--
          -- エラーが検出されていない時のみ以降の処理実行
          IF ( gn_error_count = 0 ) THEN
            -- ヘッダ明細チェック実行
            check_head_line_new(
              ln_total_item_amount_dr, --  1.本体合計金額
              ln_total_item_amount_cr, --  1.本体合計金額
              ln_total_tax_amount_dr,  --  2.税金合計金額
              ln_total_tax_amount_cr,  --  2.税金合計金額
              ln_total_acc_amount_dr,  --  3.換算金額合計
              ln_total_acc_amount_cr,  --  3.換算金額合計
              lv_errbuf,               --  エラー・メッセージ           --# 固定 #
              lv_retcode,              --  リターン・コード             --# 固定 #
              lv_errmsg);              --  ユーザー・エラー・メッセージ --# 固定 #
          END IF;
--
          -- エラーがなかった場合は'エラーなし'出力
          IF ( gn_error_count = 0 ) THEN
            xx00_file_pkg.output(
              xx00_message_pkg.get_msg(
                'XX03',
                'APP-XX03-08020'
              )
            );
          END IF;
--
        END IF;
--
        -- 一時保存変数
        ln_if_id_back    := xx03_if_head_line_rec.HEAD_INTERFACE_ID;
        lv_if_id_new_flg := '1';
--
        -- 明細最大行オーバーフラグ
        lv_max_over_flg := '0';
--
        -- ヘッダ金額初期化
        ln_total_item_amount_dr := 0;
        ln_total_item_amount_cr := 0;
        ln_total_tax_amount_dr  := 0;
        ln_total_tax_amount_cr  := 0;
        ln_total_acc_amount_dr  := 0;
        ln_total_acc_amount_cr  := 0;
--
        -- 明細連番初期化
        ln_line_count_dr  := 1;
        ln_line_count_cr  := 1;
--
        -- エラー件数初期化
        gn_error_count := 0;
--
      END IF;
--
      -- INTERFACE_ID同一値ヘッダが２件以上の時はヘッダエラー
      IF (xx03_if_head_line_rec.CNT_REC_COUNT > 1) THEN
--
        -- 新ヘッダの場合はエラー情報出力
        IF lv_if_id_new_flg = '1'  THEN
--
          -- INTERFACE_ID同一値ヘッダが２件以上
          -- ステータスをエラーに
          gv_result := cv_result_error;
          -- エラー件数加算
          gn_error_count := gn_error_count + 1;
--
          -- INTERFACE_ID出力
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08008',
              'TOK_XX03_INTERFACE_ID',
              xx03_if_head_line_rec.HEAD_INTERFACE_ID
            )
          );
          -- エラー情報出力
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08006'
            )
          );
        END IF;
--
      -- 明細最大件数を超えていない場合、後続の処理を行う
      ELSIF (lv_max_over_flg = '0') THEN
--
        -- 新ヘッダの場合はINTERFACE_ID出力
        IF lv_if_id_new_flg = '1' THEN
          xx00_file_pkg.output(
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-08008',
              'TOK_XX03_INTERFACE_ID',
              xx03_if_head_line_rec.HEAD_INTERFACE_ID
            )
          );
--
          -- 新ヘッダの場合はヘッダチェック実行
          check_header_data(
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
--
          -- エラーが検出されていない時のみ以降の処理実行
          IF ( gn_error_count = 0 ) THEN
            -- ヘッダテーブルへ挿入
            ins_header_data(
              iv_source,         -- ソース
              in_request_id,     -- 要求ID
              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
              lv_retcode,        -- リターン・コード             --# 固定 #
              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
            
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
              RAISE global_process_expt;
            END IF;
          END IF;
        END IF;
--
        -- 明細の場合は明細チェック実行
        check_detail_data(
          lv_errbuf,         -- エラー・メッセージ           --# 固定 #
          lv_retcode,        -- リターン・コード             --# 固定 #
          lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
        IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
          RAISE global_process_expt;
        END IF;
--
        -- エラーが検出されていない時のみ以降の処理実行
        IF ( gn_error_count = 0 ) THEN
          -- 明細テーブルへ挿入
          ins_detail_data(
            iv_source,         -- ソース
            in_request_id,     -- 要求ID
            ln_line_count_dr,  -- dr明細行数
            ln_line_count_cr,  -- cr明細行数
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 合計金額算出用変数加算
        ln_total_item_amount_dr := ln_total_item_amount_dr + nvl(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_DR ,0);
        ln_total_item_amount_cr := ln_total_item_amount_cr + nvl(xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR ,0);
        ln_total_tax_amount_dr  := ln_total_tax_amount_dr  + nvl(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_DR ,0);
        ln_total_tax_amount_cr  := ln_total_tax_amount_cr  + nvl(xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT_CR ,0);
        ln_total_acc_amount_dr  := ln_total_acc_amount_dr  + nvl(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_DR ,0);
        ln_total_acc_amount_cr  := ln_total_acc_amount_cr  + nvl(xx03_if_head_line_rec.LINE_ACCOUNTED_AMOUNT_CR ,0);
--
        -- 明細連番加算
        IF xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT_CR IS NULL THEN
          ln_line_count_dr := ln_line_count_dr + 1;
        ELSE
          ln_line_count_cr := ln_line_count_cr + 1;
        END IF;
--
        -- 明細最大行数チェック
        IF   ln_line_count_dr > (ln_max_line + 1)
          OR ln_line_count_cr > (ln_max_line + 1) THEN
          lv_max_over_flg := '1';
--
          -- ステータスをエラーに
          gv_result := cv_result_error;
          -- エラー件数加算
          gn_error_count := gn_error_count + 1;
--
          -- 明細最大数エラー出力
          xx00_file_pkg.output(
            -- ver 11.5.10.2.5 Chg Start
            --xx00_message_pkg.get_msg(
            --  'XXK',
            --  'APP-XXK-14064',
            --  'TOK_MAX_LINE',
            --  ln_max_line
            --)
            xx00_message_pkg.get_msg(
              'XX03',
              'APP-XX03-14162',
              'TOK_MAX_LINE',
              ln_max_line
            )
            -- ver 11.5.10.2.5 Chg End
          );
        END IF;
      END IF;
--
      -- 新ヘッダフラグ初期化
      lv_if_id_new_flg := '0';
--
    END LOOP xx03_if_loop;
--
    -- レコード未処理フラグがオフの場合処理する
    IF lv_first_flg = '0' THEN
--
      -- エラーが検出されていない時のみ以降の処理実行
      IF ( gn_error_count = 0 ) THEN
        -- ヘッダ明細チェック実行
        check_head_line_new(
          ln_total_item_amount_dr, --  1.本体合計金額
          ln_total_item_amount_cr, --  1.本体合計金額
          ln_total_tax_amount_dr,  --  2.税金合計金額
          ln_total_tax_amount_cr,  --  2.税金合計金額
          ln_total_acc_amount_dr,  --  3.換算金額合計
          ln_total_acc_amount_cr,  --  3.換算金額合計
          lv_errbuf,               -- エラー・メッセージ           --# 固定 #
          lv_retcode,              -- リターン・コード             --# 固定 #
          lv_errmsg);              -- ユーザー・エラー・メッセージ --# 固定 #
      END IF;
--
      -- エラーがなかった場合は'エラーなし'出力
      IF ( gn_error_count = 0 ) THEN
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03',
            'APP-XX03-08020'
          )
        );
      END IF;
--
    END IF;
--
    CLOSE xx03_if_head_line_cur;
--
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
  END copy_if_data;
-- Ver11.5.10.1.5 2005/09/06 Change End
--
  /**********************************************************************************
   * Procedure Name   : update_slip_number
   * Description      : 伝票番号管理テーブルの更新
   ***********************************************************************************/
  PROCEDURE update_slip_number(
    in_add_count    IN  NUMBER,       -- 1.更新件数
    ov_slip_code    OUT VARCHAR2,     -- 2.仕訳伝票コード
    on_slip_number  OUT NUMBER,       -- 3.伝票番号
    ov_errbuf       OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode      OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg       OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;  --自律トランザクション化
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'update_slip_number'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
    lv_slip_code VARCHAR2(10);
    ln_slip_number NUMBER;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- 現在の伝票番号取得
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --SELECT xsn.TEMPORARY_CODE,
    --       xsn.SLIP_NUMBER
    --  INTO lv_slip_code,
    --       ln_slip_number
    --  FROM XX03_SLIP_NUMBERS_V xsn
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
    --   AND xsn.NUM_TYPE = '0' 
    --FOR UPDATE NOWAIT;
    SELECT xsn.TEMPORARY_CODE,
           xsn.SLIP_NUMBER
      INTO lv_slip_code,
           ln_slip_number
      FROM XX03_SLIP_NUMBERS_V xsn
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
       AND xsn.NUM_TYPE = '0' 
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID')
    FOR UPDATE NOWAIT;
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- 伝票番号加算
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --UPDATE XX03_SLIP_NUMBERS xsn
    --   SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
    --   AND xsn.NUM_TYPE = '0';
    UPDATE XX03_SLIP_NUMBERS xsn
       SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLGL'
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID');
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- 戻り値セット
    ov_slip_code := lv_slip_code;
    on_slip_number := ln_slip_number;
--
    -- COMMIT
    COMMIT;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
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
  END update_slip_number;
--
  /**********************************************************************************
   * Procedure Name   : out_result
   * Description      : 終了処理(E-7)
   ***********************************************************************************/
  PROCEDURE out_result(
    iv_source      IN  VARCHAR2,     -- 1.ソース
    in_request_id  IN  NUMBER,       -- 2.要求ID
    ov_errbuf      OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode     OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg      OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'out_result'; -- プログラム名
--
--#######################  固定ローカル変数宣言部 START   ######################
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
-- == V1.2 Added START ===============================================================
    cv_slip_code CONSTANT VARCHAR2(3) := 'TMP';
-- == V1.2 Added END   ===============================================================
--
    -- *** ローカル変数 ***
    ln_update_count NUMBER;     -- 更新件数
-- == V1.2 Delete START ===============================================================
--    lv_slip_code VARCHAR2(10);  -- 仕訳伝票コード
--    ln_slip_number NUMBER;      -- 伝票番号
-- == V1.2 Delete END   ===============================================================
--
    -- *** ローカル・カーソル ***
    -- 更新対象取得カーソル
    CURSOR update_record_cur
    IS
      SELECT xjs.JOURNAL_ID
        FROM XX03_JOURNAL_SLIPS xjs
       WHERE xjs.REQUEST_ID = xx00_global_pkg.conc_request_id
      ORDER BY xjs.JOURNAL_ID;
--
    -- ログ出力用カーソル
    CURSOR outlog_cur(pv_source VARCHAR2,
                        pn_request_id NUMBER)
    IS
      SELECT xjsi.INTERFACE_ID as INTERFACE_ID,
             xjs.JOURNAL_NUM as JOURNAL_NUM
        FROM XX03_JOURNAL_SLIPS_IF xjsi,
             XX03_JOURNAL_SLIPS xjs
       WHERE xjsi.REQUEST_ID = pn_request_id
         AND xjsi.SOURCE = pv_source
         AND xjsi.JOURNAL_ID = xjs.JOURNAL_ID;
--
    -- *** ローカル・レコード ***
    -- 更新対象取得カーソルレコード型
    update_record_rec      update_record_cur%ROWTYPE;
    -- ログ出力用カーソルレコード型
    outlog_rec   outlog_cur%ROWTYPE;
--
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- チェック結果ステータスがエラーの時は以降の処理を行わない
    IF ( gv_result =  cv_result_error ) THEN
      RETURN;
    ELSE
      -- 更新件数取得
      SELECT COUNT(xjs.JOURNAL_ID)
        INTO ln_update_count
        FROM XX03_JOURNAL_SLIPS xjs
       WHERE xjs.REQUEST_ID = xx00_global_pkg.conc_request_id;
--
-- == V1.2 Delete START ===============================================================
--      -- 伝票番号取得
--      update_slip_number(
--        ln_update_count,
--        lv_slip_code,
--        ln_slip_number,
--        lv_errbuf,
--        lv_retcode,
--        lv_errmsg);
--      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
--        RAISE global_process_expt;
--      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
--        RAISE global_process_expt;
--      END IF;
----
-- == V1.2 Delete END   ===============================================================
      -- 更新対象取得
      OPEN update_record_cur;
      <<update_record_loop>>
      LOOP
--
        FETCH update_record_cur INTO update_record_rec;
        IF update_record_cur%NOTFOUND THEN
          -- 対象データがなくなるまでループ
          EXIT update_record_loop;
        END IF;
--
-- == V1.2 Delete START ===============================================================
--        -- 伝票番号加算
--        ln_slip_number := ln_slip_number + 1;
----
-- == V1.2 Delete END   ===============================================================
        -- 伝票番号更新
        UPDATE XX03_JOURNAL_SLIPS xjs
-- == V1.2 Modified START ===============================================================
--           SET xjs.JOURNAL_NUM = lv_slip_code || TO_CHAR(ln_slip_number)
           SET xjs.JOURNAL_NUM = cv_slip_code || TO_CHAR(xxcfo_slip_number_s1.NEXTVAL)
-- == V1.2 Modified END   ===============================================================
         WHERE xjs.JOURNAL_ID = update_record_rec.JOURNAL_ID;
--
      END LOOP update_record_loop;
      CLOSE update_record_cur;
--
      -- 更新ログ出力
      OPEN outlog_cur(iv_source, in_request_id);
      <<out_log_loop>>
      LOOP
--
        FETCH outlog_cur INTO outlog_rec;
        IF outlog_cur%NOTFOUND THEN
          -- 対象データがなくなるまでループ
          EXIT out_log_loop;
        END IF;
--
        -- ログ出力
        xx00_file_pkg.output(
          xx00_message_pkg.get_msg(
            'XX03', 
            'APP-XX03-08009', 
            'TOK_XX03_INTERFACE_ID', 
            outlog_rec.INTERFACE_ID,
            'TOK_XX03_INVOICE_NUM',
            outlog_rec.JOURNAL_NUM
          )
        );
--
      END LOOP out_log_loop;
      CLOSE outlog_cur;
--
      -- ver 11.5.10.2.5 Del Start
      ---- インターフェーステーブルデータ削除
      --DELETE FROM XX03_JOURNAL_SLIPS_IF xjsi
      --      WHERE xjsi.REQUEST_ID = in_request_id
      --        AND xjsi.SOURCE = iv_source;
      --
      --DELETE FROM XX03_JOURNAL_SLIP_LINES_IF xjsli
      --      WHERE xjsli.REQUEST_ID = in_request_id
      --        AND xjsli.SOURCE = iv_source;
      -- ver 11.5.10.2.5 Del End
--
    END IF;
--
  EXCEPTION
--
--#################################  固定例外処理部 START   ####################################
--
    WHEN global_process_expt THEN   -- *** 処理部共通例外ハンドラ ***
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
  END out_result;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_source     IN  VARCHAR2,     -- 1.ファイル名
    in_request_id IN  NUMBER,       -- 2.要求ID
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
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
--
--###########################  固定部 END   ############################
--
    -- ===============================
    -- ヘッダ情報出力
    -- ===============================
    print_header(
      iv_source,     -- 1.ソース
      in_request_id, -- 2.要求ID
      lv_errbuf,     -- エラー・メッセージ           --# 固定 #
      lv_retcode,    -- リターン・コード             --# 固定 #
      lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      RAISE global_process_expt;
    END IF;
--
    -- ===============================
    -- 一時表からのデータコピー (E-1)
    -- ===============================
    copy_if_data(
      iv_source,         -- ソース
      in_request_id,     -- 要求ID
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      RAISE global_process_expt;
    END IF;
--
    -- 改行出力
    xx00_file_pkg.output(' ');
--
    -- ===============================
    -- 終了処理 (E-7)
    -- ===============================
    out_result(
      iv_source,         -- ソース
      in_request_id,     -- 要求ID
      lv_errbuf,         -- エラー・メッセージ           --# 固定 #
      lv_retcode,        -- リターン・コード             --# 固定 #
      lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
    IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
      RAISE global_process_expt;
    ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
      RAISE global_process_expt;
    END IF;
--
    -- コンカレントの終了ステータスをチェック結果のステータスに
    lv_retcode := gv_result;
    -- エラーの時はエラーメッセージセット
    IF ( lv_retcode = cv_result_error ) THEN
      lv_errbuf := xx00_message_pkg.get_msg('XX03', 'APP-XX03-08007');
      lv_errmsg := xx00_message_pkg.get_msg('XX03', 'APP-XX03-08007');
    END IF;
    ov_retcode := lv_retcode;
    ov_errbuf := lv_errbuf;
    ov_errmsg := lv_errmsg;
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
    iv_source     IN  VARCHAR2,      -- 1.ソース
    in_request_id IN  NUMBER)        -- 2.要求ID
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
      iv_source,     -- 1.ソース
      in_request_id, -- 2.要求ID
      lv_errbuf,     -- エラー・メッセージ           --# 固定 #
      lv_retcode,    -- リターン・コード             --# 固定 #
      lv_errmsg);    -- ユーザー・エラー・メッセージ --# 固定 #
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
--
    --終了ステータスがエラーの場合はROLLBACKする
    IF (retcode = xx00_common_pkg.set_status_error_f) THEN
      ROLLBACK;
    END IF;
--
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
END XX034DD002C;
/
