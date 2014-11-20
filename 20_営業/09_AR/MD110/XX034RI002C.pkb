CREATE OR REPLACE PACKAGE BODY APPS.XX034RI002C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name     : XX034RI002C(body)
 * Description      : インターフェーステーブルからの請求依頼データインポート
 * MD.050(CMD.040)  : 部門入力バッチ処理（AR）       OCSJ/BFAFIN/MD050/F702
 * MD.070(CMD.050)  : 部門入力（AR）データインポート OCSJ/BFAFIN/MD070/F702
 * Version          : 11.5.10.2.10H
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
 * ------------ -------------- -----------------------------------------------------------
 *  Date         Ver.           Description
 * ------------ -------------- -----------------------------------------------------------
 *  2005/01/12   1.0            main新規作成
 *  2005/03/02   1.1            ヘッダコメント文書参照番号修正
 *  2005/03/09   1.2            不具合対応
 *  2005/04/06   11.5.10.1.0    不具合対応(支払方法の取得用結合式の変更)
 *  2005/04/25   11.5.10.1.1    不具合対応(単位のチェック追加)
 *  2005/04/27   11.5.10.1.1    不具合対応(単位のチェック処理対応もれのため修正)
 *  2005/08/15   11.5.10.1.4    勘定科目取得のVIEWを、債権本勘定を考慮したものに変更
 *  2005/09/05   11.5.10.1.5    パフォーマンス改善対応
 *  2005/10/20   11.5.10.1.5B   承認者ビューとの結合不具合対応
 *  2005/10/21   11.5.10.1.5C   入力内税フラグと、税金マスターで指定した
 *                              税金コードの内税フラグの一致チェック追加
 *  2005/12/19   11.5.10.1.6    承認者の判断基準の修正対応
 *  2005/12/27   11.5.10.1.6B   税コードを計上日で日付チェックする条件を追加
 *  2005/12/28   11.5.10.1.6C   伝票種別にアプリケーション毎の絞込みを追加
 *  2006/01/06   11.5.10.1.6D   伝票番号の採番条件にオルグを追加
 *  2006/09/05   11.5.10.2.5    アップロード処理で複数ユーザの同時実行可能とする
 *                              制御の誤り、データ削除処理の誤り修正
 *                              メッセージコードの誤り修正
 *  2006/09/20   11.5.10.2.5B   同時実行を可能とする対応の再修正
 *  2006/10/04   11.5.10.2.6    マスタチェックの見直し(有効日のチェックを請求書日付で
 *                              行なう項目とSYSDATEで行なう項目を再確認)
 *  2006/10/27   11.5.10.2.6B   同一伝票中の明細番号の重複チェックを追加
 *  2007/02/23   11.5.10.2.7    プログラム実行時のユーザ・職責に紐付くメニューに
 *                              登録されている伝票種別かのチェックを追加
 *  2007/04/23   11.5.10.2.9    明細の明細備考項目について、入力可能Byteを30Byteとするため
 *                              対象項目のByte数チェック処理を追加
 *  2007/06/20   11.5.10.2.9B   請求内容に関してのデータ抽出サブクエリーが誤っているため
 *                              マスタに存在していてもIDが設定されない事の修正
 *  2007/07/17   11.5.10.2.10   マスタチェックの追加(ヘッダ：取引タイプ,明細：増減事由)
 *                              マスタチェックコメントの修正(明細：請求内容)
 *  2007/08/16   11.5.10.2.10B  銀行支店の無効日は前日まで有効とするように修正
 *  2007/08/28   11.5.10.2.10C  AR通貨有効日の比較対象は請求書日付とする修正
 *  2007/08/29   11.5.10.2.10D  AR通貨有効日の比較対象は請求書日付とする修正
 *  2007/09/28   11.5.10.2.10E  前受近充当伝票番号項目の型の違いを考慮したSQLに修正
 *  2007/10/10   11.5.10.2.10F  パフォーマンス対応のため承認者のチェックSQLを
 *                              メインSQLへ組み込むように修正
 *  2007/12/12   11.5.10.2.10G  単価×数量の結果は通貨書式に丸める処理を追加
 *  2008/02/18   11.5.10.2.10H  明細の納品書番号項目について、入力可能Byteを30Byte
 *                              とするため対象項目のByte数チェック処理を追加
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
  cv_appli_cd       CONSTANT VARCHAR2(30)  := 'AR';                      --アプリケーション種別2
  cv_package_name   CONSTANT VARCHAR2(20)  := 'XX034RI002';              --パッケージ名
  cv_yes            CONSTANT VARCHAR2(1)   := 'Y';  --はい
  cv_no             CONSTANT VARCHAR2(1)   := 'N';  --いいえ
  cv_dept_normal    CONSTANT VARCHAR2(1)   := 'S';  -- 仕訳チェック結果（正常）
  cv_dept_warning   CONSTANT VARCHAR2(1)   := 'W';  -- 仕訳チェック結果（警告）
  cv_dept_error     CONSTANT VARCHAR2(1)   := 'E';  -- 仕訳チェック結果（エラー）
  cv_result_normal  CONSTANT VARCHAR2(1)   := '0';  -- 終了ステータス（正常）
  cv_result_warning CONSTANT VARCHAR2(1)   := '1';  -- 終了ステータス（警告）
  cv_result_error   CONSTANT VARCHAR2(1)   := '2';  -- 終了ステータス（エラー）
--
  cv_prof_GL_ID     CONSTANT VARCHAR2(20)  := 'GL_SET_OF_BKS_ID'; -- 会計帳簿IDの取得用キー値
  cv_appl_AR_ID     CONSTANT VARCHAR2(20)  := 'AR';               -- アプリケーションIDの取得用キー値
--
  -- ver 11.5.10.2.7 Add Start
  cv_menu_url_inp   CONSTANT VARCHAR2(100) := 'OA.jsp?page=/oracle/apps/xx03/ar/input/webui/Xx03InvoiceInputPG';
  -- ver 11.5.10.2.7 Add End
--
  -- ===============================
  -- グローバル変数
  -- ===============================
--  gn_invoice_id     NUMBER;       -- 請求書ID
  gn_receivable_id  NUMBER;       -- 伝票ID
  gn_error_count    NUMBER;       -- エラー件数
  gv_result         VARCHAR2(1);  -- チェック結果ステータス
--
-- Ver11.5.10.1.5 2005/09/06 Add Start
  gv_cur_code    VARCHAR2(15);        -- 機能通貨コード
-- Ver11.5.10.1.5 2005/09/06 Add End
--
  -- ===============================
  -- グローバルカーソル
  -- ===============================
--
-- Ver11.5.10.1.5 2005/09/05 Delete Start
--  -- ヘッダ情報カーソル
--  CURSOR xx03_if_header_cur(h_source VARCHAR2,
--                             h_request_id NUMBER)
--  IS
---- ver 11.5.10.1.0 Change Start
--    SELECT * FROM (
--      SELECT
--          xrsi.INTERFACE_ID            as INTERFACE_ID              -- インターフェースID
--        , xrsi.WF_STATUS               as WF_STATUS                 -- ステータス
--        , xstl.LOOKUP_CODE             as SLIP_TYPE                 -- 伝票種別
--        , TRUNC(xrsi.ENTRY_DATE, 'DD') as ENTRY_DATE                -- 起票日
--        , xpp.PERSON_ID                as REQUESTOR_PERSON_ID       -- 申請者
--        , xpp.EMPLOYEE_DISP            as REQUESTOR_PERSON_NAME     -- 申請者名
--        , xapl.PERSON_ID               as APPROVER_PERSON_ID        -- 承認者
--        , xapl.EMPLOYEE_DISP           as APPROVER_PERSON_NAME      -- 承認者名
--        , xrsi.INVOICE_DATE            as INVOICE_DATE              -- 請求書日付
--        , xttl.CUST_TRX_TYPE_ID        as TRANS_TYPE_ID             -- 取引タイプID
--        , xrsi.TRANS_TYPE_NAME         as TRANS_TYPE_NAME           -- 取引タイプ名
--        , xacl.CUSTOMER_ID             as CUSTOMER_ID               -- 顧客ID
--        , xacl.CUSTOMER_NAME           as CUSTOMER_NAME             -- 顧客名
--        , xcsl.ADDRESS_ID              as CUSTOMER_OFFICE_ID        -- 顧客事業所ID
--        , xrsi.LOCATION                as CUSTOMER_OFFICE_NAME      -- 顧客事業所名
--        , xrsi.CURRENCY_CODE           as INVOICE_CURRENCY_CODE     -- 通貨
--        , xrsi.CONVERSION_RATE         as CONVERSION_RATE           -- レート
--        , xct.CONVERSION_TYPE          as EXCHANGE_RATE_TYPE        -- レートタイプ
--        , xrsi.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE_NAME   -- レートタイプ名
--        , xtl.TERMSID                  as TERMS_ID                  -- 支払条件ID
--        , xrsi.TERMS_NAME              as TERMS_NAME                -- 支払条件名
--        , xrsi.DESCRIPTION             as DESCRIPTION               -- 備考
--        , xpp.ATTRIBUTE28              as ENTRY_DEPARTMENT          -- 起票部門
--        , xpp2.PERSON_ID               as ENTRY_PERSON_ID           -- 伝票入力者
--        , xrsi.GL_DATE                 as GL_DATE                   -- 計上日
--        , xrml.BATCH_SOURCE_ID         as RECEIPT_METHOD_ID         -- 支払方法ID
--        , xrsi.RECEIPT_METHOD_NAME     as RECEIPT_METHOD_NAME       -- 支払方法名
--        , xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME       -- 顧客名称
--        , xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME  -- カナ名
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1  -- 住所１
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2  -- 住所２
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3  -- 住所３
--        , xcsl.TAX_HEADER_LEVEL_FLAG   as AUTO_TAX_CALC_FLAG              -- 消費税計算レベル(事業所単位)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)   as TAX_ROUNDING_RULE    -- 消費税端数処理(事業所単位)
--        , xcsl.TAX_HEADER_LEVEL_FLAG_C as AUTO_TAX_CALC_FLAG_C            -- 消費税計算レベル(顧客単位)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1) as TAX_ROUNDING_RULE_C  -- 消費税端数処理(顧客単位)
--        , xrsi.COMMITMENT_NUMBER       as COMMITMENT_NUMBER         -- 前受金充当伝票番号
--        , xrsi.ORG_ID                  as ORG_ID                    -- オルグID
--        , xrsi.CREATED_BY              as CREATED_BY
--        , xrsi.CREATION_DATE           as CREATION_DATE
--        , xrsi.LAST_UPDATED_BY         as LAST_UPDATED_BY
--        , xrsi.LAST_UPDATE_DATE        as LAST_UPDATE_DATE
--        , xrsi.LAST_UPDATE_LOGIN       as LAST_UPDATE_LOGIN
--        , xrsi.REQUEST_ID              as REQUEST_ID
--        , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
--        , xrsi.PROGRAM_ID              as PROGRAM_ID
--        , xrsi.PROGRAM_UPDATE_DATE     as PROGRAM_UPDATE_DATE
--      FROM
--          XX03_RECEIVABLE_SLIPS_IF     xrsi                         -- 「請求伝票インターフェイス表」
--        , XX03_SLIP_TYPES_LOV_V        xstl
--        , XX03_PER_PEOPLES_V           xpp
--        , XX03_PER_PEOPLES_V           xpp2
--        , XX03_APPROVER_PERSON_LOV_V   xapl
--        , XX03_AR_CUSTOMER_LOV_V       xacl
--        , XX03_AR_CUST_SITE_LOV_V      xcsl
--        , XX03_CONVERSION_TYPES_V      xct
--        , XX03_TERMS_LOV_V             xtl
--        , RA_CUST_TRX_TYPES            xttl
--        ,( select a.NAME
--                , a.CURRENCY_CODE
--                , a.BATCH_SOURCE_ID
--                , b.CUSTOMER_NUMBER
--                , b.LOCATION_NUMBER
--          from    XX03_RECEIPT_METHOD_LOV_V a
--                , XX03_AR_CUST_SITE_LOV_V   b
--          where   a.ADDRESS_ID = b.ADDRESS_ID
--          ) xrml
--      WHERE
--            xrsi.REQUEST_ID              = h_request_id
--        AND xrsi.SOURCE                  = h_source
--        AND xrsi.SLIP_TYPE_NAME          = xstl.DESCRIPTION         (+)
--        AND xrsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER      (+)
--        AND xrsi.ENTRY_PERSON_NUMBER     = xpp2.EMPLOYEE_NUMBER     (+)
--        AND xrsi.APPROVER_PERSON_NUMBER  = xapl.EMPLOYEE_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xacl.CUSTOMER_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xcsl.CUSTOMER_NUMBER     (+)
--        AND xrsi.LOCATION                = xcsl.LOCATION_NUMBER     (+)
--        AND xrsi.CONVERSION_TYPE         = xct.USER_CONVERSION_TYPE (+)
--        AND xrsi.TERMS_NAME              = xtl.NAME                 (+)
--        AND xrsi.TRANS_TYPE_NAME         = xttl.NAME                (+)
--        AND xrsi.CUSTOMER_NUMBER         = xrml.CUSTOMER_NUMBER     
--        AND xrsi.LOCATION                = xrml.LOCATION_NUMBER     
--        AND xrsi.RECEIPT_METHOD_NAME     = xrml.NAME                
--        AND xrsi.CURRENCY_CODE           = xrml.CURRENCY_CODE       
--    UNION ALL
--      SELECT
--          xrsi.INTERFACE_ID            as INTERFACE_ID              -- インターフェースID
--        , xrsi.WF_STATUS               as WF_STATUS                 -- ステータス
--        , xstl.LOOKUP_CODE             as SLIP_TYPE                 -- 伝票種別
--        , TRUNC(xrsi.ENTRY_DATE, 'DD') as ENTRY_DATE                -- 起票日
--        , xpp.PERSON_ID                as REQUESTOR_PERSON_ID       -- 申請者
--        , xpp.EMPLOYEE_DISP            as REQUESTOR_PERSON_NAME     -- 申請者名
--        , xapl.PERSON_ID               as APPROVER_PERSON_ID        -- 承認者
--        , xapl.EMPLOYEE_DISP           as APPROVER_PERSON_NAME      -- 承認者名
--        , xrsi.INVOICE_DATE            as INVOICE_DATE              -- 請求書日付
--        , xttl.CUST_TRX_TYPE_ID        as TRANS_TYPE_ID             -- 取引タイプID
--        , xrsi.TRANS_TYPE_NAME         as TRANS_TYPE_NAME           -- 取引タイプ名
--        , xacl.CUSTOMER_ID             as CUSTOMER_ID               -- 顧客ID
--        , xacl.CUSTOMER_NAME           as CUSTOMER_NAME             -- 顧客名
--        , xcsl.ADDRESS_ID              as CUSTOMER_OFFICE_ID        -- 顧客事業所ID
--        , xrsi.LOCATION                as CUSTOMER_OFFICE_NAME      -- 顧客事業所名
--        , xrsi.CURRENCY_CODE           as INVOICE_CURRENCY_CODE     -- 通貨
--        , xrsi.CONVERSION_RATE         as CONVERSION_RATE           -- レート
--        , xct.CONVERSION_TYPE          as EXCHANGE_RATE_TYPE        -- レートタイプ
--        , xrsi.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE_NAME   -- レートタイプ名
--        , xtl.TERMSID                  as TERMS_ID                  -- 支払条件ID
--        , xrsi.TERMS_NAME              as TERMS_NAME                -- 支払条件名
--        , xrsi.DESCRIPTION             as DESCRIPTION               -- 備考
--        , xpp.ATTRIBUTE28              as ENTRY_DEPARTMENT          -- 起票部門
--        , xpp2.PERSON_ID               as ENTRY_PERSON_ID           -- 伝票入力者
--        , xrsi.GL_DATE                 as GL_DATE                   -- 計上日
--        , NULL                         as RECEIPT_METHOD_ID         -- 支払方法ID
--        , xrsi.RECEIPT_METHOD_NAME     as RECEIPT_METHOD_NAME       -- 支払方法名
--        , xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME       -- 顧客名称
--        , xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME  -- カナ名
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1  -- 住所１
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2  -- 住所２
--        , xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3  -- 住所３
--        , xcsl.TAX_HEADER_LEVEL_FLAG   as AUTO_TAX_CALC_FLAG              -- 消費税計算レベル(事業所単位)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)   as TAX_ROUNDING_RULE    -- 消費税端数処理(事業所単位)
--        , xcsl.TAX_HEADER_LEVEL_FLAG_C as AUTO_TAX_CALC_FLAG_C            -- 消費税計算レベル(顧客単位)
--        , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1) as TAX_ROUNDING_RULE_C  -- 消費税端数処理(顧客単位)
--        , xrsi.COMMITMENT_NUMBER       as COMMITMENT_NUMBER         -- 前受金充当伝票番号
--        , xrsi.ORG_ID                  as ORG_ID                    -- オルグID
--        , xrsi.CREATED_BY              as CREATED_BY
--        , xrsi.CREATION_DATE           as CREATION_DATE
--        , xrsi.LAST_UPDATED_BY         as LAST_UPDATED_BY
--        , xrsi.LAST_UPDATE_DATE        as LAST_UPDATE_DATE
--        , xrsi.LAST_UPDATE_LOGIN       as LAST_UPDATE_LOGIN
--        , xrsi.REQUEST_ID              as REQUEST_ID
--        , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
--        , xrsi.PROGRAM_ID              as PROGRAM_ID
--        , xrsi.PROGRAM_UPDATE_DATE     as PROGRAM_UPDATE_DATE
--      FROM
--          XX03_RECEIVABLE_SLIPS_IF     xrsi                         -- 「請求伝票インターフェイス表」
--        , XX03_SLIP_TYPES_LOV_V        xstl
--        , XX03_PER_PEOPLES_V           xpp
--        , XX03_PER_PEOPLES_V           xpp2
--        , XX03_APPROVER_PERSON_LOV_V   xapl
--        , XX03_AR_CUSTOMER_LOV_V       xacl
--        , XX03_AR_CUST_SITE_LOV_V      xcsl
--        , XX03_CONVERSION_TYPES_V      xct
--        , XX03_TERMS_LOV_V             xtl
--        , RA_CUST_TRX_TYPES            xttl
--      WHERE
--            xrsi.REQUEST_ID              = h_request_id
--        AND xrsi.SOURCE                  = h_source
--        AND xrsi.SLIP_TYPE_NAME          = xstl.DESCRIPTION         (+)
--        AND xrsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER      (+)
--        AND xrsi.ENTRY_PERSON_NUMBER     = xpp2.EMPLOYEE_NUMBER     (+)
--        AND xrsi.APPROVER_PERSON_NUMBER  = xapl.EMPLOYEE_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xacl.CUSTOMER_NUMBER     (+)
--        AND xrsi.CUSTOMER_NUMBER         = xcsl.CUSTOMER_NUMBER     (+)
--        AND xrsi.LOCATION                = xcsl.LOCATION_NUMBER     (+)
--        AND xrsi.CONVERSION_TYPE         = xct.USER_CONVERSION_TYPE (+)
--        AND xrsi.TERMS_NAME              = xtl.NAME                 (+)
--        AND xrsi.TRANS_TYPE_NAME         = xttl.NAME                (+)
--        AND NOT EXISTS
--            (SELECT * 
--             FROM   XX03_RECEIPT_METHOD_LOV_V a
--                  , XX03_AR_CUST_SITE_LOV_V   b
--             WHERE  a.ADDRESS_ID      = b.ADDRESS_ID
--               AND  b.CUSTOMER_NUMBER = xrsi.CUSTOMER_NUMBER
--               AND  b.LOCATION_NUMBER = xrsi.LOCATION
--               AND  a.NAME            = xrsi.RECEIPT_METHOD_NAME
--               AND  a.CURRENCY_CODE   = xrsi.CURRENCY_CODE
--            )
--    )
--    ORDER BY
--      INTERFACE_ID
--  ;
------ ver 1.2 Change Start
----    SELECT
----        xrsi.INTERFACE_ID            as INTERFACE_ID              -- インターフェースID
----      , xrsi.WF_STATUS               as WF_STATUS                 -- ステータス
----      , xstl.LOOKUP_CODE             as SLIP_TYPE                 -- 伝票種別
----      , TRUNC(xrsi.ENTRY_DATE, 'DD') as ENTRY_DATE                -- 起票日
----      , xpp.PERSON_ID                as REQUESTOR_PERSON_ID       -- 申請者
----      , xpp.EMPLOYEE_DISP            as REQUESTOR_PERSON_NAME     -- 申請者名
----      , xapl.PERSON_ID               as APPROVER_PERSON_ID        -- 承認者
----      , xapl.EMPLOYEE_DISP           as APPROVER_PERSON_NAME      -- 承認者名
----      , xrsi.INVOICE_DATE            as INVOICE_DATE              -- 請求書日付
------      , xrsi.TRANS_TYPE_ID           as TRANS_TYPE_ID             -- 取引タイプID
------      , xttl.NAME                    as TRANS_TYPE_NAME           -- 取引タイプ名
------      , xrsi.CUSTOMER_ID             as CUSTOMER_ID               -- 顧客ID
----      , xttl.CUST_TRX_TYPE_ID        as TRANS_TYPE_ID             -- 取引タイプID
----      , xrsi.TRANS_TYPE_NAME         as TRANS_TYPE_NAME           -- 取引タイプ名
----      , xacl.CUSTOMER_ID             as CUSTOMER_ID               -- 顧客ID
----      , xacl.CUSTOMER_NAME           as CUSTOMER_NAME             -- 顧客名
------      , xrsi.CUSTOMER_OFFICE_ID      as CUSTOMER_OFFICE_ID        -- 顧客事業所ID
------      , xcsl.LOCATION                as CUSTOMER_OFFICE_NAME      -- 顧客事業所名
----      , xcsl.ADDRESS_ID              as CUSTOMER_OFFICE_ID        -- 顧客事業所ID
----      , xrsi.LOCATION                as CUSTOMER_OFFICE_NAME      -- 顧客事業所名
----      , xrsi.CURRENCY_CODE           as INVOICE_CURRENCY_CODE     -- 通貨
----      , xrsi.CONVERSION_RATE         as CONVERSION_RATE           -- レート
----      , xct.CONVERSION_TYPE          as EXCHANGE_RATE_TYPE        -- レートタイプ
----      , xrsi.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE_NAME   -- レートタイプ名
----      , xtl.TERMSID                  as TERMS_ID                  -- 支払条件ID
----      , xrsi.TERMS_NAME              as TERMS_NAME                -- 支払条件名
----      , xrsi.DESCRIPTION             as DESCRIPTION               -- 備考
----      , xpp.ATTRIBUTE28              as ENTRY_DEPARTMENT          -- 起票部門
----      , xpp2.PERSON_ID               as ENTRY_PERSON_ID           -- 伝票入力者
----      , xrsi.GL_DATE                 as GL_DATE                   -- 計上日
----      , xrml.BATCH_SOURCE_ID         as RECEIPT_METHOD_ID         -- 支払方法ID
----      , xrsi.RECEIPT_METHOD_NAME     as RECEIPT_METHOD_NAME       -- 支払方法名
----      ,xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME       -- 顧客名称
----      ,xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME  -- カナ名
----      ,xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1  -- 住所１
----      ,xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2  -- 住所２
----      ,xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3  -- 住所３
----      , xcsl.TAX_HEADER_LEVEL_FLAG   as AUTO_TAX_CALC_FLAG              -- 消費税計算レベル(事業所単位)
----      , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)   as TAX_ROUNDING_RULE    -- 消費税端数処理(事業所単位)
----      , xcsl.TAX_HEADER_LEVEL_FLAG_C as AUTO_TAX_CALC_FLAG_C            -- 消費税計算レベル(顧客単位)
----      , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1) as TAX_ROUNDING_RULE_C  -- 消費税端数処理(顧客単位)
----      , xrsi.COMMITMENT_NUMBER       as COMMITMENT_NUMBER         -- 前受金充当伝票番号
----      , xrsi.ORG_ID                  as ORG_ID                    -- オルグID
----      , xrsi.CREATED_BY              as CREATED_BY
----      , xrsi.CREATION_DATE           as CREATION_DATE
----      , xrsi.LAST_UPDATED_BY         as LAST_UPDATED_BY
----      , xrsi.LAST_UPDATE_DATE        as LAST_UPDATE_DATE
----      , xrsi.LAST_UPDATE_LOGIN       as LAST_UPDATE_LOGIN
----      , xrsi.REQUEST_ID              as REQUEST_ID
----      , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
----      , xrsi.PROGRAM_ID              as PROGRAM_ID
----      , xrsi.PROGRAM_UPDATE_DATE     as PROGRAM_UPDATE_DATE
----     FROM
----        XX03_RECEIVABLE_SLIPS_IF     xrsi                         -- 「請求伝票インターフェイス表」
----      , XX03_SLIP_TYPES_LOV_V        xstl
----      , XX03_PER_PEOPLES_V           xpp
----      , XX03_PER_PEOPLES_V           xpp2
----      , XX03_APPROVER_PERSON_LOV_V   xapl
----      , XX03_AR_CUSTOMER_LOV_V       xacl
----      , XX03_AR_CUST_SITE_LOV_V      xcsl
----      , XX03_CONVERSION_TYPES_V      xct
----      , XX03_TERMS_LOV_V             xtl
------      , XX03_RECEIPT_METHOD_LOV_V    xrml
------      , RA_CUST_TRX_TYPES_ALL        xttl
----      , RA_CUST_TRX_TYPES            xttl
----      ,( select a.NAME
----              , a.CURRENCY_CODE
----              , a.BATCH_SOURCE_ID
----              , b.CUSTOMER_NUMBER
----              , b.LOCATION_NUMBER
----        from    XX03_RECEIPT_METHOD_LOV_V a
----              , XX03_AR_CUST_SITE_LOV_V   b
----        where   a.ADDRESS_ID = b.ADDRESS_ID
----        ) xrml
----     WHERE
----          xrsi.REQUEST_ID              = h_request_id
----      AND xrsi.SOURCE                  = h_source
----      AND xrsi.SLIP_TYPE_NAME          = xstl.DESCRIPTION         (+)
----      AND xrsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER      (+)
----      AND xrsi.ENTRY_PERSON_NUMBER     = xpp2.EMPLOYEE_NUMBER     (+)
----      AND xrsi.APPROVER_PERSON_NUMBER  = xapl.EMPLOYEE_NUMBER     (+)
------      AND xrsi.CUSTOMER_ID             = xacl.CUSTOMER_ID         (+)
------      AND xrsi.CUSTOMER_ID             = xcsl.CUSTOMER_ID         (+)
------      AND xrsi.CUSTOMER_OFFICE_ID      = xcsl.ADDRESS_ID          (+)
----      AND xrsi.CUSTOMER_NUMBER         = xacl.CUSTOMER_NUMBER     (+)
----      AND xrsi.CUSTOMER_NUMBER         = xcsl.CUSTOMER_NUMBER     (+)
----      AND xrsi.LOCATION                = xcsl.LOCATION_NUMBER     (+)
----      AND xrsi.CONVERSION_TYPE         = xct.USER_CONVERSION_TYPE (+)
----      AND xrsi.TERMS_NAME              = xtl.NAME                 (+)
------      AND xrsi.RECEIPT_METHOD_NAME     = xrml.NAME                (+)
----      AND xrsi.CUSTOMER_NUMBER         = xrml.CUSTOMER_NUMBER     (+)
----      AND xrsi.LOCATION                = xrml.LOCATION_NUMBER     (+)
----      AND xrsi.RECEIPT_METHOD_NAME     = xrml.NAME                (+)
----      AND xrsi.CURRENCY_CODE           = xrml.CURRENCY_CODE       (+)
------      AND xrsi.TRANS_TYPE_ID           = xttl.CUST_TRX_TYPE_ID    (+)
----      AND xrsi.TRANS_TYPE_NAME         = xttl.NAME                (+)
----     ORDER BY
----      xrsi.INTERFACE_ID
----  ;
------ ver 1.2 Change End
---- ver 11.5.10.1.0 Change End
----
--  --  ヘッダ情報カーソルレコード型
--  xx03_if_header_rec    xx03_if_header_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/05 Delete End
--
-- Ver11.5.10.1.5 2005/09/05 Add Start
  -- ヘッダ明細情報カーソル
  CURSOR xx03_if_head_line_cur( h_source     VARCHAR2
                               ,h_request_id NUMBER)
  IS
    SELECT
       HEAD.INTERFACE_ID           as HEAD_INTERFACE_ID                  -- インターフェースID
     , HEAD.WF_STATUS              as HEAD_WF_STATUS                     -- ステータス
     , HEAD.SLIP_TYPE              as HEAD_SLIP_TYPE                     -- 伝票種別
-- Ver11.5.10.1.6 Add Start
     , HEAD.SLIP_TYPE_APP          as HEAD_SLIP_TYPE_APP                 -- 伝票種別アプリケーション
-- Ver11.5.10.1.6 Add End
     , HEAD.ENTRY_DATE             as HEAD_ENTRY_DATE                    -- 起票日
     , HEAD.REQUESTOR_PERSON_ID    as HEAD_REQUESTOR_PERSON_ID           -- 申請者
     , HEAD.REQUESTOR_PERSON_NAME  as HEAD_REQUESTOR_PERSON_NAME         -- 申請者名
     , HEAD.APPROVER_PERSON_ID     as HEAD_APPROVER_PERSON_ID            -- 承認者
     , HEAD.APPROVER_PERSON_NAME   as HEAD_APPROVER_PERSON_NAME          -- 承認者名
     , HEAD.INVOICE_DATE           as HEAD_INVOICE_DATE                  -- 請求書日付
     , HEAD.TRANS_TYPE_ID          as HEAD_TRANS_TYPE_ID                 -- 取引タイプID
     , HEAD.TRANS_TYPE_NAME        as HEAD_TRANS_TYPE_NAME               -- 取引タイプ名
     , HEAD.CUSTOMER_ID            as HEAD_CUSTOMER_ID                   -- 顧客ID
     , HEAD.CUSTOMER_NAME          as HEAD_CUSTOMER_NAME                 -- 顧客名
     , HEAD.CUSTOMER_OFFICE_ID     as HEAD_CUSTOMER_OFFICE_ID            -- 顧客事業所ID
     , HEAD.CUSTOMER_OFFICE_NAME   as HEAD_CUSTOMER_OFFICE_NAME          -- 顧客事業所名
     , HEAD.INVOICE_CURRENCY_CODE  as HEAD_INVOICE_CURRENCY_CODE         -- 通貨
     -- ver 11.5.10.2.10D Add Start
     , HEAD.CHK_CURRENCY_CODE      as HEAD_CHK_CURRENCY_CODE             -- 通貨マスタチェック用
     -- ver 11.5.10.2.10D Add End
     , HEAD.CONVERSION_RATE        as HEAD_CONVERSION_RATE               -- レート
     , HEAD.EXCHANGE_RATE_TYPE     as HEAD_EXCHANGE_RATE_TYPE            -- レートタイプ
     , HEAD.EXCHANGE_RATE_TYPE_NAME  as HEAD_EXCHANGE_RATE_TYPE_NAME     -- レートタイプ名
     , HEAD.TERMS_ID               as HEAD_TERMS_ID                      -- 支払条件ID
     , HEAD.TERMS_NAME             as HEAD_TERMS_NAME                    -- 支払条件名
     , HEAD.DESCRIPTION            as HEAD_DESCRIPTION                   -- 備考
     , HEAD.ENTRY_DEPARTMENT       as HEAD_ENTRY_DEPARTMENT              -- 起票部門
     , HEAD.ENTRY_PERSON_ID        as HEAD_ENTRY_PERSON_ID               -- 伝票入力者
     , HEAD.GL_DATE                as HEAD_GL_DATE                       -- 計上日
     , HEAD.RECEIPT_METHOD_ID      as HEAD_RECEIPT_METHOD_ID             -- 支払方法ID
     , HEAD.RECEIPT_METHOD_NAME    as HEAD_RECEIPT_METHOD_NAME           -- 支払方法名
     , HEAD.ONETIME_CUSTOMER_NAME       as HEAD_ONE_CUSTOMER_NAME        -- 顧客名称
     , HEAD.ONETIME_CUSTOMER_KANA_NAME  as HEAD_ONE_CUSTOMER_KANA_NAME   -- カナ名
     , HEAD.ONETIME_CUSTOMER_ADDRESS_1  as HEAD_ONE_CUSTOMER_ADDRESS_1   -- 住所１
     , HEAD.ONETIME_CUSTOMER_ADDRESS_2  as HEAD_ONE_CUSTOMER_ADDRESS_2   -- 住所２
     , HEAD.ONETIME_CUSTOMER_ADDRESS_3  as HEAD_ONE_CUSTOMER_ADDRESS_3   -- 住所３
     , HEAD.AUTO_TAX_CALC_FLAG     as HEAD_AUTO_TAX_CALC_FLAG            -- 消費税計算レベル(事業所単位)
     , HEAD.TAX_ROUNDING_RULE      as HEAD_TAX_ROUNDING_RULE             -- 消費税端数処理(事業所単位)
     , HEAD.AUTO_TAX_CALC_FLAG_C   as HEAD_AUTO_TAX_CALC_FLAG_C          -- 消費税計算レベル(顧客単位)
     , HEAD.TAX_ROUNDING_RULE_C    as HEAD_TAX_ROUNDING_RULE_C           -- 消費税端数処理(顧客単位)
     , HEAD.COMMITMENT_NUMBER      as HEAD_COMMITMENT_NUMBER             -- 前受金充当伝票番号
     , HEAD.COM_TRX_NUMBER         as HEAD_COM_TRX_NUMBER                --
     , HEAD.COM_COMMITMENT_AMOUNT  as HEAD_COM_COMMITMENT_AMOUNT         --
     , HEAD.ORG_ID                 as HEAD_ORG_ID                        -- オルグID
     , HEAD.CREATED_BY             as HEAD_CREATED_BY                    -- 
     , HEAD.CREATION_DATE          as HEAD_CREATION_DATE                 -- 
     , HEAD.LAST_UPDATED_BY        as HEAD_LAST_UPDATED_BY               -- 
     , HEAD.LAST_UPDATE_DATE       as HEAD_LAST_UPDATE_DATE              -- 
     , HEAD.LAST_UPDATE_LOGIN      as HEAD_LAST_UPDATE_LOGIN             -- 
     , HEAD.REQUEST_ID             as HEAD_REQUEST_ID                    -- 
     , HEAD.PROGRAM_APPLICATION_ID as HEAD_PROGRAM_APPLICATION_ID        -- 
     , HEAD.PROGRAM_ID             as HEAD_PROGRAM_ID                    -- 
     , HEAD.PROGRAM_UPDATE_DATE    as HEAD_PROGRAM_UPDATE_DATE           -- 
     , LINE.INTERFACE_ID           as LINE_INTERFACE_ID                  -- インターフェースID
     , LINE.LINE_NUMBER            as LINE_LINE_NUMBER                   -- ラインナンバー
     , LINE.SLIP_LINE_TYPE_NAME    as LINE_SLIP_LINE_TYPE_NAME           -- 請求内容
     , LINE.SLIP_LINE_TYPE         as LINE_SLIP_LINE_TYPE                -- 請求内容ID
     , LINE.ENTERED_TAX_AMOUNT     as LINE_ENTERED_TAX_AMOUNT            -- 明細消費税額
     , LINE.SLIP_LINE_UOM          as LINE_SLIP_LINE_UOM                 -- 単位
     , LINE.SLIP_LINE_UOM_NAME     as LINE_SLIP_LINE_UOM_NAME            -- 単位名
     , LINE.SLIP_LINE_UNIT_PRICE   as LINE_SLIP_LINE_UNIT_PRICE          -- 単価
     , LINE.SLIP_LINE_QUANTITY     as LINE_SLIP_LINE_QUANTITY            -- 数量
     , LINE.SLIP_LINE_ENTERED_AMOUNT  as LINE_SLIP_LINE_ENTERED_AMOUNT   -- 入力金額
     , LINE.SLIP_LINE_RECIEPT_NO   as LINE_SLIP_LINE_RECIEPT_NO          -- 納品書番号
     , LINE.SLIP_DESCRIPTION       as LINE_SLIP_DESCRIPTION              -- 備考（明細）
     , LINE.SLIP_LINE_TAX_FLAG     as LINE_SLIP_LINE_TAX_FLAG            -- 内税
     , LINE.SLIP_LINE_TAX_CODE     as LINE_SLIP_LINE_TAX_CODE            -- 税区分
     , LINE.TAX_NAME               as LINE_TAX_NAME                      -- 税区分名
     , LINE.VAT_TAX_ID             as LINE_VAT_TAX_ID                    -- 税区分ID
     -- Ver11.5.10.1.5C 2005/10/21 Add Start
     , LINE.MST_TAX_FLAG           as LINE_MST_TAX_FLAG                  -- 税区分の内税フラグ
     -- Ver11.5.10.1.5C 2005/10/21 Add End
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
     , LINE.SEGMENT8               as LINE_SEGMENT8                      -- 予備１
     , LINE.SEGMENT8_NAME          as LINE_SEGMENT8_NAME                 -- 予備
     , LINE.INCR_DECR_REASON_CODE  as LINE_INCR_DECR_REASON_CODE         -- 増減事由
     , LINE.INCR_DECR_REASON_NAME  as LINE_INCR_DECR_REASON_NAME         -- 増減事由名
     , LINE.RECON_REFERENCE        as LINE_RECON_REFERENCE               -- 消込参照
     , LINE.JOURNAL_DESCRIPTION    as LINE_JOURNAL_DESCRIPTION           -- 備考（明細）
     , LINE.ORG_ID                 as LINE_ORG_ID                        -- オルグID
     , LINE.CREATED_BY             as LINE_CREATED_BY                    -- 
     , LINE.CREATION_DATE          as LINE_CREATION_DATE                 -- 
     , LINE.LAST_UPDATED_BY        as LINE_LAST_UPDATED_BY               -- 
     , LINE.LAST_UPDATE_DATE       as LINE_LAST_UPDATE_DATE              -- 
     , LINE.LAST_UPDATE_LOGIN      as LINE_LAST_UPDATE_LOGIN             -- 
     , LINE.REQUEST_ID             as LINE_REQUEST_ID                    -- 
     , LINE.PROGRAM_APPLICATION_ID as LINE_PROGRAM_APPLICATION_ID        -- 
     , LINE.PROGRAM_ID             as LINE_PROGRAM_ID                    -- 
     , LINE.PROGRAM_UPDATE_DATE    as LINE_PROGRAM_UPDATE_DATE           -- 
     , CNT.INTERFACE_ID            as CNT_INTERFACE_ID                   -- インターフェースID
     , CNT.REC_COUNT               as CNT_REC_COUNT                      --
     -- ver 11.5.10.2.6B Add Start
     , CNT2.INTERFACE_ID           as CNT2_INTERFACE_ID                  -- インターフェースID
     , CNT2.LINE_SUM_NO_FLG        as CNT2_LINE_SUM_NO_FLG               --
     -- ver 11.5.10.2.6B Add End
     -- ver 11.5.10.2.10F Add Start
     , APPROVER.PERSON_ID          as APPROVER_PERSON_ID
     -- ver 11.5.10.2.10F Add End
    FROM
       (SELECT /*+ USE_NL(xrsi) */ 
           xrsi.INTERFACE_ID           as INTERFACE_ID                       -- インターフェースID
         , xrsi.WF_STATUS              as WF_STATUS                          -- ステータス
         , xstl.LOOKUP_CODE            as SLIP_TYPE                          -- 伝票種別
-- Ver11.5.10.1.6 Add Start
         , xstl.ATTRIBUTE14            as SLIP_TYPE_APP                      -- 伝票種別アプリケーション
-- Ver11.5.10.1.6 Add End
         , TRUNC(xrsi.ENTRY_DATE, 'DD')  as ENTRY_DATE                       -- 起票日
         , xpp.PERSON_ID               as REQUESTOR_PERSON_ID                -- 申請者
         , xpp.EMPLOYEE_DISP           as REQUESTOR_PERSON_NAME              -- 申請者名
-- Ver11.5.10.1.5B Chg Start
         --, xapl.PERSON_ID              as APPROVER_PERSON_ID                 -- 承認者
         --, xapl.EMPLOYEE_DISP          as APPROVER_PERSON_NAME               -- 承認者名
         , ppf.person_id               as APPROVER_PERSON_ID                 -- 承認者
         , ppf.EMPLOYEE_NUMBER || 
           XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || 
           ppf.PER_INFORMATION18 || ' ' || 
           ppf.PER_INFORMATION19       as APPROVER_PERSON_NAME               -- 承認者名
-- Ver11.5.10.1.5B Chg End
         , xrsi.INVOICE_DATE           as INVOICE_DATE                       -- 請求書日付
         , xttl.CUST_TRX_TYPE_ID       as TRANS_TYPE_ID                      -- 取引タイプID
         , xrsi.TRANS_TYPE_NAME        as TRANS_TYPE_NAME                    -- 取引タイプ名
         , xacl.CUSTOMER_ID            as CUSTOMER_ID                        -- 顧客ID
         , xacl.CUSTOMER_NAME          as CUSTOMER_NAME                      -- 顧客名
         , xcsl.ADDRESS_ID             as CUSTOMER_OFFICE_ID                 -- 顧客事業所ID
         , xrsi.LOCATION               as CUSTOMER_OFFICE_NAME               -- 顧客事業所名
         , xrsi.CURRENCY_CODE          as INVOICE_CURRENCY_CODE              -- 通貨
         -- ver 11.5.10.2.10D Add Start
         , xfc.CURRENCY_CODE           as CHK_CURRENCY_CODE                  -- 通貨マスタチェック用
         -- ver 11.5.10.2.10D Add End
         , xrsi.CONVERSION_RATE        as CONVERSION_RATE                    -- レート
         , xct.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE                 -- レートタイプ
         , xrsi.CONVERSION_TYPE        as EXCHANGE_RATE_TYPE_NAME            -- レートタイプ名
         , xtl.TERMSID                 as TERMS_ID                           -- 支払条件ID
         , xrsi.TERMS_NAME             as TERMS_NAME                         -- 支払条件名
         , xrsi.DESCRIPTION            as DESCRIPTION                        -- 備考
         , xpp.ATTRIBUTE28             as ENTRY_DEPARTMENT                   -- 起票部門
         , xpp2.PERSON_ID              as ENTRY_PERSON_ID                    -- 伝票入力者
         , xrsi.GL_DATE                as GL_DATE                            -- 計上日
         , xrml.BATCH_SOURCE_ID        as RECEIPT_METHOD_ID                  -- 支払方法ID
         , xrsi.RECEIPT_METHOD_NAME    as RECEIPT_METHOD_NAME                -- 支払方法名
         , xrsi.ONETIME_CUSTOMER_NAME       as ONETIME_CUSTOMER_NAME         -- 顧客名称
         , xrsi.ONETIME_CUSTOMER_KANA_NAME  as ONETIME_CUSTOMER_KANA_NAME    -- カナ名
         , xrsi.ONETIME_CUSTOMER_ADDRESS_1  as ONETIME_CUSTOMER_ADDRESS_1    -- 住所１
         , xrsi.ONETIME_CUSTOMER_ADDRESS_2  as ONETIME_CUSTOMER_ADDRESS_2    -- 住所２
         , xrsi.ONETIME_CUSTOMER_ADDRESS_3  as ONETIME_CUSTOMER_ADDRESS_3    -- 住所３
         , xcsl.TAX_HEADER_LEVEL_FLAG               as AUTO_TAX_CALC_FLAG    -- 消費税計算レベル(事業所単位)
         , SUBSTRB(xcsl.TAX_ROUNDING_RULE, 1, 1)    as TAX_ROUNDING_RULE     -- 消費税端数処理(事業所単位)
         , xcsl.TAX_HEADER_LEVEL_FLAG_C             as AUTO_TAX_CALC_FLAG_C  -- 消費税計算レベル(顧客単位)
         , SUBSTRB(xcsl.TAX_ROUNDING_RULE_C, 1, 1)  as TAX_ROUNDING_RULE_C   -- 消費税端数処理(顧客単位)
         , xrsi.COMMITMENT_NUMBER      as COMMITMENT_NUMBER                  -- 前受金充当伝票番号
         , xcnl.TRX_NUMBER             as COM_TRX_NUMBER                     --
         -- ver 11.5.10.2.10E Chg Start
         --, xcnl.COMMITMENT_AMOUNT      as COM_COMMITMENT_AMOUNT              --
         , to_number(xcnl.COMMITMENT_AMOUNT, xx00_currency_pkg.get_format_mask(xrsi.CURRENCY_CODE, 38)) as COM_COMMITMENT_AMOUNT
         -- ver 11.5.10.2.10E Chg End
         , xrsi.ORG_ID                 as ORG_ID                             -- オルグID
         , xrsi.CREATED_BY             as CREATED_BY
         , xrsi.CREATION_DATE          as CREATION_DATE
         , xrsi.LAST_UPDATED_BY        as LAST_UPDATED_BY
         , xrsi.LAST_UPDATE_DATE       as LAST_UPDATE_DATE
         , xrsi.LAST_UPDATE_LOGIN      as LAST_UPDATE_LOGIN
         , xrsi.REQUEST_ID             as REQUEST_ID
         , xrsi.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xrsi.PROGRAM_ID             as PROGRAM_ID
         , xrsi.PROGRAM_UPDATE_DATE    as PROGRAM_UPDATE_DATE
        FROM
           XX03_RECEIVABLE_SLIPS_IF    xrsi    --「請求伝票インターフェイス表」
-- ver 11.5.10.2.7 Chg Start
-- -- Ver11.5.10.1.6C Chg Start
-- -- -- Ver11.5.10.1.6 Chg Start
-- -- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION
-- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION,XLXV.ATTRIBUTE14
-- -- -- Ver11.5.10.1.6 Chg End
-- --           FROM XX03_SLIP_TYPES_V XLXV
-- --           WHERE XLXV.ENABLED_FLAG = 'Y'
-- --           )                           xstl
--          ,(SELECT XSTLV.LOOKUP_CODE,XSTLV.DESCRIPTION,XSTLV.ATTRIBUTE14
--            FROM XX03_SLIP_TYPES_LOV_V XSTLV
--            WHERE XSTLV.ATTRIBUTE14 = 'AR'
--            )                           xstl
-- -- Ver11.5.10.1.6C Chg End
         ,(select XSTLV.LOOKUP_CODE , XSTLV.DESCRIPTION , XSTLV.ATTRIBUTE14
             from XX03_SLIP_TYPES_LOV_V XSTLV , FND_FORM_FUNCTIONS FFF
            where XSTLV.ATTRIBUTE14 = 'AR'
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
         , XX03_PER_PEOPLES_V          xpp
         , XX03_PER_PEOPLES_V          xpp2
-- Ver11.5.10.1.5B Chg Start
         --, XX03_APPROVER_PERSON_LOV_V  xapl
         , PER_PEOPLE_F                ppf
-- Ver11.5.10.1.5B Chg End
         ,(SELECT RAC_BILL.ACCOUNT_NUMBER || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || RAC_BILL_PARTY.PARTY_NAME  CUSTOMER_NAME
                , RAC_BILL.CUST_ACCOUNT_ID  CUSTOMER_ID , RAC_BILL.ACCOUNT_NUMBER  CUSTOMER_NUMBER
           FROM  HZ_CUST_ACCOUNTS  RAC_BILL , HZ_PARTIES  RAC_BILL_PARTY , HZ_CUST_ACCT_SITES  RAA_BILL , HZ_CUST_SITE_USES  SU_BILL , HZ_PARTY_SITES  RAA_BILL_PS
           WHERE RAC_BILL.STATUS = 'A'  AND RAA_BILL_PS.STATUS = 'A'  AND RAC_BILL_PARTY.STATUS = 'A'  AND RAA_BILL.STATUS = 'A'  AND SU_BILL.STATUS = 'A'
             AND SU_BILL.SITE_USE_CODE = 'BILL_TO'  AND SU_BILL.PRIMARY_FLAG = 'Y'  AND RAC_BILL.PARTY_ID = RAC_BILL_PARTY.PARTY_ID
             AND RAC_BILL.CUST_ACCOUNT_ID = RAA_BILL.CUST_ACCOUNT_ID  AND RAA_BILL.PARTY_SITE_ID = RAA_BILL_PS.PARTY_SITE_ID  AND RAA_BILL.CUST_ACCT_SITE_ID = SU_BILL.CUST_ACCT_SITE_ID
           )                           xacl
         ,(SELECT acv.ACCOUNT_NUMBER CUSTOMER_NUMBER , hsuv.LOCATION LOCATION_NUMBER , addr.CUST_ACCT_SITE_ID ADDRESS_ID , hsuv.TAX_HEADER_LEVEL_FLAG TAX_HEADER_LEVEL_FLAG
                , hsuv.TAX_ROUNDING_RULE TAX_ROUNDING_RULE , acv.TAX_HEADER_LEVEL_FLAG TAX_HEADER_LEVEL_FLAG_C , acv.TAX_ROUNDING_RULE TAX_ROUNDING_RULE_C
           FROM HZ_CUST_ACCT_SITES addr , HZ_PARTY_SITES psite , HZ_LOCATIONS loc , HZ_LOC_ASSIGNMENTS loc_ass , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCOUNTS acv
           WHERE addr.CUST_ACCT_SITE_ID = hsuv.CUST_ACCT_SITE_ID AND addr.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID AND addr.PARTY_SITE_ID = psite.PARTY_SITE_ID AND psite.LOCATION_ID = loc.LOCATION_ID
             AND psite.LOCATION_ID = loc_ass.LOCATION_ID AND NVL(addr.ORG_ID,-99) = NVL(loc_ass.ORG_ID,-99) AND hsuv.STATUS = 'A' AND hsuv.SITE_USE_CODE = 'BILL_TO'
           )                           xcsl
         , XX03_CONVERSION_TYPES_V     xct
         -- ver 11.5.10.2.6 Chg Start
         --, XX03_TERMS_LOV_V            xtl
         ,(SELECT rtt.NAME NAME ,rtt.TERM_ID TERMSID ,xrsi.INTERFACE_ID
           FROM RA_TERMS_TL rtt ,RA_TERMS_B rtb ,XX03_RECEIVABLE_SLIPS_IF xrsi
           WHERE rtt.TERM_ID = rtb.TERM_ID AND rtt.LANGUAGE = USERENV('LANG')
             AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsi.TERMS_NAME = rtt.NAME
             AND xrsi.INVOICE_DATE BETWEEN NVL(rtb.START_DATE_ACTIVE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD'))
                                       AND NVL(rtb.END_DATE_ACTIVE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
           )                           xtl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.6 Chg Start
         --, RA_CUST_TRX_TYPES           xttl
         ,(SELECT RCT.CUST_TRX_TYPE_ID , RCT.NAME ,xrsi.INTERFACE_ID
           FROM RA_CUST_TRX_TYPES_ALL RCT , FND_LOOKUP_VALUES FVL,XX03_SLIP_TYPES_LOV_V XSTLV ,XX03_RECEIVABLE_SLIPS_IF xrsi 
           WHERE RCT.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') AND RCT.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND FVL.LOOKUP_TYPE = 'XX03_SLIP_TYPES'
             AND FVL.LANGUAGE = XX00_GLOBAL_PKG.CURRENT_LANGUAGE AND FVL.ATTRIBUTE15 = RCT.ORG_ID AND FVL.ATTRIBUTE12 = RCT.TYPE
             AND FVL.LOOKUP_CODE = XSTLV.LOOKUP_CODE AND XSTLV.ATTRIBUTE14 = 'AR' AND xrsi.SLIP_TYPE_NAME = XSTLV.DESCRIPTION
             AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsi.TRANS_TYPE_NAME = RCT.NAME
             AND xrsi.INVOICE_DATE BETWEEN NVL(RCT.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(RCT.END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
           )                           xttl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.6 Chg Start
         --,(select arm.NAME as NAME , aba.currency_code as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --        ,NVL(arm.START_DATE , TO_DATE('1000/01/01', 'YYYY/MM/DD')) as REC_START_DATE  ,NVL(arm.END_DATE   , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as REC_END_DATE
         --        ,NVL(acrm.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) as CUST_START_DATE ,NVL(acrm.END_DATE  , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as CUST_END_DATE
         --        ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --  from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --     , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv
         --  where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --    and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'N' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --    and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --    and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --  union all
         --  select arm.NAME as NAME , xclv.CURRENCY_CODE as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --        ,NVL(arm.START_DATE , TO_DATE('1000/01/01', 'YYYY/MM/DD')) as REC_START_DATE  ,NVL(arm.END_DATE   , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as REC_END_DATE
         --        ,NVL(acrm.START_DATE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) as CUST_START_DATE ,NVL(acrm.END_DATE  , TO_DATE('4712/12/31', 'YYYY/MM/DD')) as CUST_END_DATE
         --        , hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --  from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --     , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , XX03_CURRENCIES_LOV_V xclv
         --  where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --    and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'Y' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --    and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --    and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --  )                           xrml
         -- ver 11.5.10.2.10C Chg Start
         --,(select x.NAME ,x.CURRENCY_CODE ,x.BATCH_SOURCE_ID ,x.LOCATION_NUMBER ,x.CUSTOMER_NUMBER ,xrsi.INTERFACE_ID
         --    from (select arm.NAME as NAME , aba.currency_code as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --                ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
         --                ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
         --                ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --                ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
         --                ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
         --            from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --               , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , AP_BANK_BRANCHES abb
         --           where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --             and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'N' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --             and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --             and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --             and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
         --          union all
         --          select arm.NAME as NAME , xclv.CURRENCY_CODE as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
         --                ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
         --                ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
         --               , hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
         --                ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
         --                ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
         --            from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
         --               , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , XX03_CURRENCIES_LOV_V xclv , AP_BANK_BRANCHES abb
         --           where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
         --             and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'Y' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
         --             and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
         --             and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
         --             and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
         --          ) x ,XX03_RECEIVABLE_SLIPS_IF xrsi
         --   where xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source 
         --     AND xrsi.CUSTOMER_NUMBER = x.CUSTOMER_NUMBER AND xrsi.LOCATION = x.LOCATION_NUMBER AND xrsi.RECEIPT_METHOD_NAME = x.NAME AND xrsi.CURRENCY_CODE = x.CURRENCY_CODE
         --     AND xrsi.INVOICE_DATE BETWEEN NVL(x.REC_START_DATE  ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.REC_END_DATE  ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE BETWEEN NVL(x.CUST_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.CUST_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE BETWEEN nvl(x.ARMA_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND nvl(x.ARMA_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE <  nvl(x.ABA_INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     -- ver 11.5.10.2.10B Chg Start
         --     --AND xrsi.INVOICE_DATE <= nvl(x.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     AND xrsi.INVOICE_DATE <  nvl(x.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
         --     -- ver 11.5.10.2.10B Chg End
         --  )                           xrml
         ,(select x.NAME ,x.CURRENCY_CODE ,x.BATCH_SOURCE_ID ,x.LOCATION_NUMBER ,x.CUSTOMER_NUMBER ,xrsi.INTERFACE_ID
             from (select arm.NAME as NAME , aba.currency_code as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
                         ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
                         ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
                         ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
                         ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
                         ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
                         ,xcv.START_DATE_ACTIVE as CURRENCY_START_DATE , xcv.END_DATE_ACTIVE   as CURRENCY_END_DATE
                     from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
                        , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , AP_BANK_BRANCHES abb
                        , XX03_CURRENCIES_V xcv
                    where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
                      and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'N' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
                      and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
                      and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
                      and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
                      and xcv.ENABLED_FLAG = 'Y' and xcv.CURRENCY_FLAG = 'Y' and aba.currency_code = xcv.CURRENCY_CODE
                   union all
                   select arm.NAME as NAME , xcv.CURRENCY_CODE as CURRENCY_CODE , arm.RECEIPT_METHOD_ID as BATCH_SOURCE_ID
                         ,arm.START_DATE  as REC_START_DATE  ,arm.END_DATE  as REC_END_DATE
                         ,acrm.START_DATE as CUST_START_DATE ,acrm.END_DATE as CUST_END_DATE
                         ,hsuv.LOCATION as LOCATION_NUMBER , acv.ACCOUNT_NUMBER as CUSTOMER_NUMBER
                         ,arma.start_date as ARMA_START_DATE , arma.end_date as ARMA_END_DATE
                         ,aba.inactive_date as ABA_INACTIVE_DATE , abb.end_date as ABB_END_DATE
                         ,xcv.START_DATE_ACTIVE as CURRENCY_START_DATE , xcv.END_DATE_ACTIVE as CURRENCY_END_DATE
                     from AR_RECEIPT_METHODS arm , AR_RECEIPT_METHOD_ACCOUNTS_ALL arma , AP_BANK_ACCOUNTS_ALL aba , RA_CUST_RECEIPT_METHODS acrm
                        , HZ_CUST_SITE_USES_ALL hsuv , HZ_CUST_ACCT_SITES_ALL hcas , HZ_CUST_ACCOUNTS acv , AP_BANK_BRANCHES abb
                        , XX03_CURRENCIES_V xcv
                    where arm.RECEIPT_METHOD_ID = arma.RECEIPT_METHOD_ID and arma.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and arma.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
                      and aba.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') and aba.RECEIPT_MULTI_CURRENCY_FLAG = 'Y' and arm.RECEIPT_METHOD_ID = acrm.RECEIPT_METHOD_ID
                      and acrm.SITE_USE_ID = hsuv.SITE_USE_ID AND hsuv.STATUS = 'A' and hsuv.SITE_USE_CODE = 'BILL_TO' and hsuv.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID')
                      and hsuv.CUST_ACCT_SITE_ID = hcas.CUST_ACCT_SITE_ID and hcas.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and hcas.CUST_ACCOUNT_ID = acv.CUST_ACCOUNT_ID
                      and aba.org_id = XX00_PROFILE_PKG.VALUE('ORG_ID') and aba.bank_branch_id = abb.bank_branch_id
                      and xcv.ENABLED_FLAG = 'Y' and xcv.CURRENCY_FLAG = 'Y'
                   ) x ,XX03_RECEIVABLE_SLIPS_IF xrsi
            where xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source 
              AND xrsi.CUSTOMER_NUMBER = x.CUSTOMER_NUMBER AND xrsi.LOCATION = x.LOCATION_NUMBER AND xrsi.RECEIPT_METHOD_NAME = x.NAME AND xrsi.CURRENCY_CODE = x.CURRENCY_CODE
              AND xrsi.INVOICE_DATE BETWEEN NVL(x.REC_START_DATE  ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.REC_END_DATE  ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE BETWEEN NVL(x.CUST_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(x.CUST_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE BETWEEN nvl(x.ARMA_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND nvl(x.ARMA_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE <  nvl(x.ABA_INACTIVE_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE <  nvl(x.ABB_END_DATE      ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
              AND xrsi.INVOICE_DATE BETWEEN nvl(x.CURRENCY_START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND nvl(x.CURRENCY_END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
           )                           xrml
         -- ver 11.5.10.2.10C Chg End
         -- ver 11.5.10.2.6 Chg End
         , XX03_COMMITMENT_NUMBER_LOV_V  xcnl
         -- ver 11.5.10.2.10D Add Start
         ,(SELECT fc.CURRENCY_CODE CURRENCY_CODE ,xrsi.INTERFACE_ID INTERFACE_ID
             FROM FND_CURRENCIES fc ,XX03_RECEIVABLE_SLIPS_IF xrsi
            WHERE fc.ENABLED_FLAG  = 'Y' AND fc.CURRENCY_FLAG = 'Y' AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsi.CURRENCY_CODE = fc.CURRENCY_CODE
              AND TRUNC(xrsi.INVOICE_DATE) BETWEEN NVL(fc.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD')) AND NVL(fc.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'))
           )                           xfc
         -- ver 11.5.10.2.10D Add End
        WHERE
              xrsi.REQUEST_ID               = h_request_id
          AND xrsi.SOURCE                   = h_source
          AND xrsi.SLIP_TYPE_NAME           = xstl.DESCRIPTION           (+)
          AND xrsi.REQUESTOR_PERSON_NUMBER  = xpp.EMPLOYEE_NUMBER        (+)
          AND xrsi.ENTRY_PERSON_NUMBER      = xpp2.EMPLOYEE_NUMBER       (+)
-- Ver11.5.10.1.5B Chg Start
          --AND xrsi.APPROVER_PERSON_NUMBER   = xapl.EMPLOYEE_NUMBER       (+)
          AND xrsi.APPROVER_PERSON_NUMBER   = ppf.EMPLOYEE_NUMBER     (+)
          AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date(+) AND ppf.effective_end_date(+)
          AND ppf.current_employee_flag(+) = 'Y'
-- Ver11.5.10.1.5B Chg End
          AND xrsi.CUSTOMER_NUMBER          = xacl.CUSTOMER_NUMBER       (+)
          AND xrsi.CUSTOMER_NUMBER          = xcsl.CUSTOMER_NUMBER       (+)
          AND xrsi.LOCATION                 = xcsl.LOCATION_NUMBER       (+)
          AND xrsi.CONVERSION_TYPE          = xct.USER_CONVERSION_TYPE   (+)
          AND xrsi.TERMS_NAME               = xtl.NAME                   (+)
          -- ver 11.5.10.2.6 Add Start
          AND xrsi.INTERFACE_ID             = xtl.INTERFACE_ID           (+)
          -- ver 11.5.10.2.6 Add End
          AND xrsi.TRANS_TYPE_NAME          = xttl.NAME                  (+)
          -- ver 11.5.10.2.6 Add Start
          AND xrsi.INTERFACE_ID             = xttl.INTERFACE_ID          (+)
          -- ver 11.5.10.2.6 Add End
          AND xrsi.CUSTOMER_NUMBER          = xrml.CUSTOMER_NUMBER       (+)
          AND xrsi.LOCATION                 = xrml.LOCATION_NUMBER       (+)
          AND xrsi.RECEIPT_METHOD_NAME      = xrml.NAME                  (+)
          AND xrsi.CURRENCY_CODE            = xrml.CURRENCY_CODE         (+)
          -- ver 11.5.10.2.6 Add Start
          AND xrsi.INTERFACE_ID             = xrml.INTERFACE_ID          (+)
          -- ver 11.5.10.2.6 Add End
          AND xrsi.COMMITMENT_NUMBER        = xcnl.TRX_NUMBER            (+)
         -- ver 11.5.10.2.10D Add Start
          AND xrsi.CURRENCY_CODE            = xfc.CURRENCY_CODE          (+)
          AND xrsi.INTERFACE_ID             = xfc.INTERFACE_ID           (+)
         -- ver 11.5.10.2.10D Add End
        ) HEAD
      ,(SELECT /*+ USE_NL(xrsli) */ 
           xrsli.INTERFACE_ID          as INTERFACE_ID                       -- インターフェースID
         , xrsli.LINE_NUMBER           as LINE_NUMBER                        -- ラインナンバー
         , xrsli.SLIP_LINE_TYPE_NAME   as SLIP_LINE_TYPE_NAME                -- 請求内容
         , xall.MEMO_LINE_ID           as SLIP_LINE_TYPE                     -- 請求内容ID
         , xrsli.ENTERED_TAX_AMOUNT    as ENTERED_TAX_AMOUNT                 -- 明細消費税額
         , xuoml.UOM_CODE              as SLIP_LINE_UOM                      -- 単位
         , xrsli.SLIP_LINE_UOM         as SLIP_LINE_UOM_NAME                 -- 単位名
         , xrsli.SLIP_LINE_UNIT_PRICE  as SLIP_LINE_UNIT_PRICE               -- 単価
         , xrsli.SLIP_LINE_QUANTITY    as SLIP_LINE_QUANTITY                 -- 数量
         , xrsli.SLIP_LINE_ENTERED_AMOUNT  as SLIP_LINE_ENTERED_AMOUNT       -- 入力金額
         , xrsli.SLIP_LINE_RECIEPT_NO  as SLIP_LINE_RECIEPT_NO               -- 納品書番号
         , xrsli.SLIP_DESCRIPTION      as SLIP_DESCRIPTION                   -- 備考（明細）
         , xrsli.SLIP_LINE_TAX_FLAG    as SLIP_LINE_TAX_FLAG                 -- 内税
         -- Ver11.5.10.1.5C 2005/10/21 Change Start
         --, xrsli.SLIP_LINE_TAX_CODE    as SLIP_LINE_TAX_CODE                 -- 税区分
         , xtcl.TAX_CODE               as SLIP_LINE_TAX_CODE                 -- 税区分
         -- Ver11.5.10.1.5C 2005/10/21 Change End
         , xtcl.TAX_TYPE               as TAX_NAME                           -- 税区分名
         , xtcl.VAT_TAX_ID             as VAT_TAX_ID                         -- 税区分ID
         -- Ver11.5.10.1.5C 2005/10/21 Add Start
         , xtcl.AMOUNT_INCLUDES_TAX_FLAG  as MST_TAX_FLAG                    -- 税区分の内税フラグ
         -- Ver11.5.10.1.5C 2005/10/21 Add End
         , xcl.FLEX_VALUE              as SEGMENT1                           -- 会社
         , xcl.COMPANIES_COL           as SEGMENT1_NAME                      -- 会社名
         , xdl.FLEX_VALUE              as SEGMENT2                           -- 部門
         , xdl.DEPARTMENTS_COL         as SEGMENT2_NAME                      -- 部門名
         , xal.FLEX_VALUE              as SEGMENT3                           -- 勘定科目
         , xal.ACCOUNTS_COL            as SEGMENT3_NAME                      -- 勘定科目名
         , xsal.FLEX_VALUE             as SEGMENT4                           -- 補助科目
         , xsal.SUB_ACCOUNTS_COL       as SEGMENT4_NAME                      -- 補助科目名
         , xpal.FLEX_VALUE             as SEGMENT5                           -- 相手先
         , xpal.PARTNERS_COL           as SEGMENT5_NAME                      -- 相手先名
         , xbtl.FLEX_VALUE             as SEGMENT6                           -- 事業区分
         , xbtl.BUSINESS_TYPES_COL     as SEGMENT6_NAME                      -- 事業区分名
         , xprl.FLEX_VALUE             as SEGMENT7                           -- プロジェクト
         , xprl.PROJECTS_COL           as SEGMENT7_NAME                      -- プロジェクト名
         , xfl.FLEX_VALUE              as SEGMENT8                           -- 予備１
         , xfl.FUTURES_COL             as SEGMENT8_NAME                      -- 予備
         , xrsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE              -- 増減事由
         , xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME              -- 増減事由名
         , xrsli.RECON_REFERENCE       as RECON_REFERENCE                    -- 消込参照
         , xrsli.JOURNAL_DESCRIPTION   as JOURNAL_DESCRIPTION                -- 備考（明細）
         , xrsli.ORG_ID                as ORG_ID                             -- オルグID
         , xrsli.CREATED_BY            as CREATED_BY
         , xrsli.CREATION_DATE         as CREATION_DATE
         , xrsli.LAST_UPDATED_BY       as LAST_UPDATED_BY
         , xrsli.LAST_UPDATE_DATE      as LAST_UPDATE_DATE
         , xrsli.LAST_UPDATE_LOGIN     as LAST_UPDATE_LOGIN
         , xrsli.REQUEST_ID            as REQUEST_ID
         , xrsli.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID
         , xrsli.PROGRAM_ID            as PROGRAM_ID
         , xrsli.PROGRAM_UPDATE_DATE   as PROGRAM_UPDATE_DATE
        FROM
         -- 2005/12/27 Ver11.5.10.1.6B Change Start
         -- XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
         -- ver 11.5.10.2.6 Chg Start
         --  XX03_RECEIVABLE_SLIPS_IF       xrsi
         --, XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
           XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
         -- ver 11.5.10.2.6 Chg End
         -- 2005/12/27 Ver11.5.10.1.6B Change End
         -- ver 11.5.10.2.6 Chg Start
         --, XX03_TAX_CLASS_LOV_V        xtcl
         ,(SELECT xtclv.TAX_CODE ,xtclv.TAX_TYPE ,xtclv.VAT_TAX_ID ,xtclv.AMOUNT_INCLUDES_TAX_FLAG
                 ,xrsli.INTERFACE_ID ,xrsli.LINE_NUMBER
           FROM XX03_TAX_CLASS_LOV_V xtclv ,XX03_RECEIVABLE_SLIPS_IF xrsi ,XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
           WHERE xrsli.SLIP_LINE_TAX_CODE = xtclv.TAX_CODE AND xrsi.INTERFACE_ID = xrsli.INTERFACE_ID
             AND xrsi.INVOICE_DATE BETWEEN NVL(xtclv.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(xtclv.END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
             AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsli.REQUEST_ID = h_request_id AND xrsli.SOURCE = h_source
           )                           xtcl
         -- ver 11.5.10.2.6 Chg End
         -- ver 11.5.10.2.9B Chg Start
         --,(SELECT amlv.NAME , amlv.MEMO_LINE_ID
         --  FROM AR_MEMO_LINES_VL amlv , XX03_SLIP_TYPES_V xstv
         --  WHERE TRUNC(SYSDATE) BETWEEN amlv.START_DATE AND NVL(amlv.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD')) AND amlv.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND amlv.ATTRIBUTE1 = xstv.LOOKUP_CODE
         --    AND xstv.ENABLED_FLAG = 'Y' AND xstv.ATTRIBUTE14 = 'AR'
         --    AND EXISTS (SELECT '1' FROM XX03_FLEX_VALUE_CHILDREN XFVC , XX03_PER_PEOPLES_V XPPV
         --                WHERE XPPV.USER_ID = XX00_PROFILE_PKG.VALUE('USER_ID') AND amlv.ATTRIBUTE2 = XFVC.PARENT_FLEX_VALUE AND XFVC.FLEX_VALUE = XPPV.ATTRIBUTE28)
         --  )                           xall
         ,(SELECT amlv.NAME , amlv.MEMO_LINE_ID , xrsli.INTERFACE_ID , xrsli.LINE_NUMBER
           FROM AR_MEMO_LINES_VL amlv , XX03_SLIP_TYPES_LOV_V xstlv , XX03_RECEIVABLE_SLIPS_IF xrsi , XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
           WHERE xrsli.SLIP_LINE_TYPE_NAME = amlv.NAME AND xrsi.INVOICE_DATE BETWEEN amlv.START_DATE AND NVL(amlv.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
             AND amlv.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND amlv.ATTRIBUTE1 = xstlv.LOOKUP_CODE AND xrsi.SLIP_TYPE_NAME = xstlv.DESCRIPTION AND xstlv.ATTRIBUTE14 = 'AR'
             AND xrsi.INTERFACE_ID = xrsli.INTERFACE_ID AND xrsi.REQUEST_ID = h_request_id AND xrsi.SOURCE = h_source AND xrsli.REQUEST_ID = h_request_id AND xrsli.SOURCE = h_source
           )                           xall
         -- ver 11.5.10.2.9B Chg End
         , XX03_UNITS_OF_MERSURE_LOV_V  xuoml
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION COMPANIES_COL
           FROM XX03_COMPANIES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xcl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION DEPARTMENTS_COL
           FROM XX03_DEPARTMENTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xdl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION ACCOUNTS_COL
           FROM XX03_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'  AND XV.ATTRIBUTE4 IS NOT NULL
           )                           xal
         ,(SELECT XV.PARENT_FLEX_VALUE_LOW,XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SUB_ACCOUNTS_COL
           FROM XX03_SUB_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xsal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PARTNERS_COL
           FROM XX03_PARTNERS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xpal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION BUSINESS_TYPES_COL
           FROM XX03_BUSINESS_TYPES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xbtl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PROJECTS_COL
           FROM XX03_PROJECTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xprl
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION FUTURES_COL
           FROM XX03_FUTURES_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xfl
         ,(SELECT XV.FFL_FLEX_VALUE FLEX_VALUE,XV.FFL_FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION INCR_DECR_REASONS_COL,XCC.ACCOUNT_CODE PARENT_FLEX_VALUE_LOW
           FROM XX03_INCR_DECR_REASONS_V XV
               ,XX03_CF_COMBINATIONS XCC
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND XCC.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID') AND XCC.INCR_DECR_REASON_CODE = XV.FFL_FLEX_VALUE
           )                           xidrl
        WHERE
              xrsli.REQUEST_ID              = h_request_id
          AND xrsli.SOURCE                  = h_source
          AND xrsli.SLIP_LINE_TAX_CODE      = xtcl.TAX_CODE              (+)
          -- 2005/12/27 Ver11.5.10.1.6B Add Start
          -- ver 11.5.10.2.6 Del Start
          ---- ver 11.5.10.2.5B Add Start
          --AND xrsi.REQUEST_ID               = h_request_id
          --AND xrsi.SOURCE                   = h_source
          ---- ver 11.5.10.2.5B Add End
          --AND xrsi.INTERFACE_ID             = xrsli.INTERFACE_ID
          -- ver 11.5.10.2.6 Del End
          -- ver 11.5.10.2.6 Chg Start
          --AND xrsi.INVOICE_DATE BETWEEN xtcl.START_DATE
          --                          AND NVL(xtcl.END_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD'))
          AND xrsli.INTERFACE_ID            = xtcl.INTERFACE_ID          (+)
          AND xrsli.LINE_NUMBER             = xtcl.LINE_NUMBER           (+)
          -- ver 11.5.10.2.6 Chg End
          -- 2005/12/27 Ver11.5.10.1.6B Add End
          AND xrsli.SLIP_LINE_TYPE_NAME     = xall.NAME                  (+)
          -- ver 11.5.10.2.9B Add Start
          AND xrsli.INTERFACE_ID            = xall.INTERFACE_ID          (+)
          AND xrsli.LINE_NUMBER             = xall.LINE_NUMBER           (+)
          -- ver 11.5.10.2.9B Add End
          AND xrsli.SLIP_LINE_UOM           = xuoml.UNIT_OF_MEASURE      (+)
          AND xrsli.SEGMENT1                = xcl.FLEX_VALUE             (+)
          AND xrsli.SEGMENT2                = xdl.FLEX_VALUE             (+)
          AND xrsli.SEGMENT3                = xal.FLEX_VALUE             (+)
          AND xrsli.SEGMENT3                = xsal.PARENT_FLEX_VALUE_LOW (+)
          AND xrsli.SEGMENT4                = xsal.FLEX_VALUE            (+)
          AND xrsli.SEGMENT5                = xpal.FLEX_VALUE            (+)
          AND xrsli.SEGMENT6                = xbtl.FLEX_VALUE            (+)
          AND xrsli.SEGMENT7                = xprl.FLEX_VALUE            (+)
          AND xrsli.SEGMENT8                = xfl.FLEX_VALUE             (+)
          AND xrsli.SEGMENT3                = xidrl.PARENT_FLEX_VALUE_LOW  (+)
          AND xrsli.INCR_DECR_REASON_CODE   = xidrl.FLEX_VALUE           (+)
        ) LINE
      ,(SELECT /*+ USE_NL(xrsic) */ 
               xrsic.INTERFACE_ID         as INTERFACE_ID
             , COUNT(xrsic.INTERFACE_ID)  as REC_COUNT
        FROM   XX03_RECEIVABLE_SLIPS_IF xrsic
        WHERE  xrsic.REQUEST_ID = h_request_id
          AND  xrsic.SOURCE     = h_source
        GROUP BY xrsic.INTERFACE_ID
        ) CNT
      -- ver 11.5.10.2.6B Add Start
      ,(SELECT /*+ USE_NL(xrsli) */ 
               DISTINCT(xrsi.INTERFACE_ID)  as INTERFACE_ID
             , 'X'                          as LINE_SUM_NO_FLG
        FROM   XX03_RECEIVABLE_SLIPS_IF  xrsi
        WHERE  xrsi.REQUEST_ID = h_request_id
          AND  xrsi.SOURCE     = h_source
          AND  EXISTS (SELECT '1'
                       FROM   XX03_RECEIVABLE_SLIPS_LINE_IF  xrsli
                       WHERE  xrsli.REQUEST_ID  = h_request_id
                         AND  xrsli.SOURCE      = h_source
                         AND  xrsli.INTERFACE_ID = xrsi.INTERFACE_ID
                       GROUP BY INTERFACE_ID , LINE_NUMBER
                       HAVING COUNT(xrsli.LINE_NUMBER) > 1
                       )
        ) CNT2
      -- ver 11.5.10.2.6B Add End
      -- ver 11.5.10.2.10F Add Start
      ,(SELECT /*+ USE_NL(xrsi) */ 
           xrsi.INTERFACE_ID as INTERFACE_ID
          ,ppf.PERSON_ID     as PERSON_ID
        FROM
           XX03_RECEIVABLE_SLIPS_IF    xrsi
         ,(SELECT employee_number ,person_id FROM PER_PEOPLE_F
           WHERE current_employee_flag = 'Y' AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
           ) ppf
        WHERE
              xrsi.APPROVER_PERSON_NUMBER = ppf.EMPLOYEE_NUMBER
          AND EXISTS (SELECT '1'
                      FROM   XX03_APPROVER_PERSON_LOV_V xaplv
                      WHERE  xaplv.PERSON_ID = ppf.person_id
                        AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
                             or xaplv.PROFILE_VAL_DEP = 'AR')
                      )
        ) APPROVER
      -- ver 11.5.10.2.10F Add End
    WHERE
          HEAD.INTERFACE_ID = LINE.INTERFACE_ID
      AND HEAD.INTERFACE_ID = CNT.INTERFACE_ID
      -- ver 11.5.10.2.6B Add Start
      AND HEAD.INTERFACE_ID = CNT2.INTERFACE_ID(+)
      -- ver 11.5.10.2.6B Add End
      -- ver 11.5.10.2.10F Add Start
      AND HEAD.INTERFACE_ID = APPROVER.INTERFACE_ID(+)
      -- ver 11.5.10.2.10F Add End
    ORDER BY
       HEAD.INTERFACE_ID ,LINE.LINE_NUMBER
    ;
--
    -- ヘッダ明細情報カーソルレコード型
    xx03_if_head_line_rec  xx03_if_head_line_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/05 Add End
--
  --  消費税計算レベル・消費税端数処理 システム情報カーソル
  CURSOR sys_tax_cur
  IS
    SELECT
      TAX_ROUNDING_ALLOW_OVERRIDE      as TAX_ROUNDING_ALLOW_OVERRIDE,
      TAX_HEADER_LEVEL_FLAG            as TAX_HEADER_LEVEL_FLAG,
      SUBSTRB(TAX_ROUNDING_RULE, 1, 1) as TAX_ROUNDING_RULE
    FROM
      AR_SYSTEM_PARAMETERS
  ;
--
  --  消費税計算レベル・消費税端数処理 システム情報カーソルレコード型
  sys_tax_rec    sys_tax_cur%ROWTYPE;
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  same_id_header_expt      EXCEPTION;     -- ヘッダレコード重複あり
  get_slip_type_expt       EXCEPTION;     -- 伝票種別入力値なし
  get_approver_expt        EXCEPTION;     -- 承認者入力値なし
  get_invoice_date_expt    EXCEPTION;     -- 請求書日付入力値なし
  get_gl_date_expt         EXCEPTION;     -- 計上日入力値なし
  get_terms_name_expt      EXCEPTION;     -- 支払条件入力値なし
  get_cur_code_expt        EXCEPTION;     -- 通貨入力値なし
  check_pkg_err_expt       EXCEPTION;     -- 共通エラー
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
    cv_prof_ORG_ID CONSTANT VARCHAR2(20) := 'ORG_ID';           -- オルグIDの取得用キー値
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
                        xx00_profile_pkg.value(cv_prof_GL_ID),       -- 会計帳簿ID
                        TO_NUMBER(xx00_profile_pkg.value(cv_prof_ORG_ID)),  -- オルグID
                        xx00_global_pkg.conc_program_id,                    -- コンカレントプログラムID
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
--    ln_line_id     NUMBER;  -- 明細ID
--    ln_line_count  NUMBER;  -- 明細連番
--    ln_amount      NUMBER;  -- 金額
--    ln_ent_amount  NUMBER;  -- 金額
--    ln_segment3    VARCHAR2(150);  --勘定科目ID
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- 明細情報カーソル
--    CURSOR xx03_if_detail_cur(h_source        VARCHAR2,
--                              h_request_id    NUMBER,
--                              h_interface_id  NUMBER,
--                              h_currency_code VARCHAR2)
--    IS
--      SELECT
--          xrsli.INTERFACE_ID             as INTERFACE_ID                        -- インターフェースID
--        , xrsli.SLIP_LINE_TYPE_NAME      as SLIP_LINE_TYPE_NAME                 -- 請求内容
--        , xall.MEMO_LINE_ID              as SLIP_LINE_TYPE                      -- 請求内容ID
--        , xrsli.ENTERED_TAX_AMOUNT       as ENTERED_TAX_AMOUNT                  -- 明細消費税額
--        , xuoml.UOM_CODE                 as SLIP_LINE_UOM                       -- 単位
--        , xrsli.SLIP_LINE_UOM            as SLIP_LINE_UOM_NAME                  -- 単位名
--        , xrsli.SLIP_LINE_UNIT_PRICE     as SLIP_LINE_UNIT_PRICE                -- 単価
--        , xrsli.SLIP_LINE_QUANTITY       as SLIP_LINE_QUANTITY                  -- 数量
--        , xrsli.SLIP_LINE_ENTERED_AMOUNT as SLIP_LINE_ENTERED_AMOUNT            -- 入力金額
--        , xrsli.SLIP_LINE_RECIEPT_NO     as SLIP_LINE_RECIEPT_NO                -- 納品書番号
--        , xrsli.SLIP_DESCRIPTION         as SLIP_DESCRIPTION                    -- 備考（明細）
--        , xrsli.SLIP_LINE_TAX_FLAG       as SLIP_LINE_TAX_FLAG                  -- 内税
--        , xrsli.SLIP_LINE_TAX_CODE       as SLIP_LINE_TAX_CODE                  -- 税区分
--        , xtcl.TAX_TYPE                  as TAX_NAME                            -- 税区分名
--        , xrsli.SEGMENT1                 as SEGMENT1                            -- 会社
--        , xrsli.SEGMENT2                 as SEGMENT2                            -- 部門
--        , xrsli.SEGMENT3                 as SEGMENT3                            -- 勘定科目
--        , xrsli.SEGMENT4                 as SEGMENT4                            -- 補助科目
--        , xrsli.SEGMENT5                 as SEGMENT5                            -- 相手先
--        , xrsli.SEGMENT6                 as SEGMENT6                            -- 事業区分
--        , xrsli.SEGMENT7                 as SEGMENT7                            -- プロジェクト
--        , xrsli.SEGMENT8                 as SEGMENT8                            -- 予備１
--        , xcl.COMPANIES_COL              as SEGMENT1_NAME                       -- 会社名
--        , xdl.DEPARTMENTS_COL            as SEGMENT2_NAME                       -- 部門名
--        , xal.ACCOUNTS_COL               as SEGMENT3_NAME                       -- 勘定科目名
--        , xsal.SUB_ACCOUNTS_COL          as SEGMENT4_NAME                       -- 補助科目名
--        , xpal.PARTNERS_COL              as SEGMENT5_NAME                       -- 相手先名
--        , xbtl.BUSINESS_TYPES_COL        as SEGMENT6_NAME                       -- 事業区分名
--        , xprl.PROJECTS_COL              as SEGMENT7_NAME                       -- プロジェクト名
--        , xfl.FUTURES_COL                as SEGMENT8_NAME                       -- 予備
--        , xrsli.INCR_DECR_REASON_CODE    as INCR_DECR_REASON_CODE               -- 増減事由
--        , xidrl.INCR_DECR_REASONS_COL    as INCR_DECR_REASON_NAME               -- 増減事由名
--        , xrsli.RECON_REFERENCE          as RECON_REFERENCE                     -- 消込参照
--        , xrsli.JOURNAL_DESCRIPTION      as JOURNAL_DESCRIPTION                 -- 備考（明細）
--        , xrsli.ORG_ID                   as ORG_ID                              -- オルグID
--        , xrsli.CREATED_BY
--        , xrsli.CREATION_DATE
--        , xrsli.LAST_UPDATED_BY
--        , xrsli.LAST_UPDATE_DATE
--        , xrsli.LAST_UPDATE_LOGIN
--        , xrsli.REQUEST_ID
--        , xrsli.PROGRAM_APPLICATION_ID
--        , xrsli.PROGRAM_ID
--        , xrsli.PROGRAM_UPDATE_DATE
--      FROM
--          XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
--        , XX03_TAX_CLASS_LOV_V          xtcl
--        , XX03_COMPANIES_LOV_V          xcl
--        , XX03_DEPARTMENTS_LOV_V        xdl
----Ver11.5.10.1.4 2005/08/15 CHANGE START
--        --, XX03_ACCOUNTS_ALL_LOV_V    xal
--        , XX03_AR_ACCOUNTS_ALL_LOV_V    xal
----Ver11.5.10.1.4 2005/08/15 CHANGE END
--        , XX03_SUB_ACCOUNTS_LOV_V       xsal
--        , XX03_PARTNERS_LOV_V           xpal
--        , XX03_BUSINESS_TYPES_LOV_V     xbtl
--        , XX03_PROJECTS_LOV_V           xprl
--        , XX03_INCR_DECR_REASONS_LOV_V  xidrl
--        , XX03_FUTURES_LOV_V            xfl
--        , XX03_AR_LINES_LOV_V           xall
--        , XX03_UNITS_OF_MERSURE_LOV_V   xuoml
--      WHERE
--            xrsli.REQUEST_ID            = h_request_id
--        AND xrsli.SOURCE                = h_source
--        AND xrsli.INTERFACE_ID          = h_interface_id
--        AND xrsli.SLIP_LINE_TAX_CODE    = xtcl.TAX_CODE               (+)
--        AND xrsli.SEGMENT1              = xcl.FLEX_VALUE              (+)
--        AND xrsli.SEGMENT2              = xdl.FLEX_VALUE              (+)
--        AND xrsli.SEGMENT3              = xal.FLEX_VALUE              (+)
--        AND xrsli.SEGMENT4              = xsal.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT3              = xsal.PARENT_FLEX_VALUE_LOW  (+)
--        AND xrsli.SEGMENT5              = xpal.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT6              = xbtl.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT7              = xprl.FLEX_VALUE             (+)
--        AND xrsli.SEGMENT8              = xfl.FLEX_VALUE              (+)
--        AND xrsli.INCR_DECR_REASON_CODE = xidrl.FLEX_VALUE            (+)
--        AND xrsli.SEGMENT3              = xidrl.PARENT_FLEX_VALUE_LOW (+)
--        AND xrsli.SLIP_LINE_TYPE_NAME   = xall.NAME                   (+)
--        AND xrsli.SLIP_LINE_UOM         = xuoml.UNIT_OF_MEASURE       (+)
--      ORDER BY
--        xrsli.LINE_NUMBER;
--    -- 明細情報カーソルレコード型
--    xx03_if_detail_rec xx03_if_detail_cur%ROWTYPE;
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
--    -- 明細連番初期化
--    ln_line_count := 1;
--    -- 明細情報カーソルオープン
--    OPEN xx03_if_detail_cur(iv_source,
--                            in_request_id,
--                            xx03_if_header_rec.INTERFACE_ID,
--                            xx03_if_header_rec.INVOICE_CURRENCY_CODE);
--    <<xx03_if_detail_loop>>
--    LOOP
--      FETCH xx03_if_detail_cur INTO xx03_if_detail_rec;
--      IF xx03_if_detail_cur%NOTFOUND THEN
--        -- 対象データがなくなるまでループ
--        EXIT xx03_if_detail_loop;
--      END IF;
----
--      -- 明細ID取得
--      SELECT XX03_RECEIVABLE_SLIPS_LINE_S.nextval
--        INTO ln_line_id
--        FROM dual;
----
--      -- 摘要名称取得
----    BEGIN
----      SELECT xsltl.SLIP_LINE_TYPES_COL as SLIP_LINE_TYPE_NAME
----        INTO lv_slip_type_name
----        FROM XX03_SLIP_LINE_TYPES_LOV_V xsltl
----       WHERE xsltl.LOOKUP_CODE = xx03_if_detail_rec.SLIP_LINE_TYPE
----         AND xsltl.VENDOR_SITE_ID = xx03_if_header_rec.VENDOR_SITE_ID;
----    EXCEPTION
----      WHEN NO_DATA_FOUND THEN
----        -- 対象データなし時は摘要名称空
----        lv_slip_type_name := '';
----        -- ステータスをエラーに
----        gv_result := cv_result_error;
----        -- エラー件数加算
----        gn_error_count := gn_error_count + 1;
----        xx00_file_pkg.output(
----          xx00_message_pkg.get_msg(
----            'XX03',
----            'APP-XX03-08026',
----            'TOK_XX03_LINE_NUMBER',
----            ln_line_count
----          )
----        );
----    END;
----
--    -- 請求内容IDチェック
--    IF ( xx03_if_detail_rec.SLIP_LINE_TYPE IS NULL ) THEN
--      -- 請求内容IDが空の場合は請求内容入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08032'
--        )
--      );
--    END IF;
--
--    -- 2005.04.22 add start Ver11.5.10.1.1
--    -- 単位チェック
--    -- 2005.04.27 change start Ver11.5.10.1.1
--    -- IF ( xx03_if_detail_rec.SLIP_LINE_UOM IS NULL ) THEN
--      -- 単位が空の場合は単位入力エラー表示
--    IF ( xx03_if_detail_rec.SLIP_LINE_UOM IS NULL ) AND
--      ( xx03_if_detail_rec.SLIP_LINE_UOM_NAME IS NOT NULL ) THEN
--      -- 単位が空で単位名が空でない場合は単位入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08044'
--        )
--      );
--    END IF;
--    -- 2005.04.27 change end Ver11.5.10.1.1
--    -- 2005.04.22 add end Ver11.5.10.1.1
--
------
----    -- 明細本体金額チェック
----    IF ( xx03_if_detail_rec.ENTERED_ITEM_AMOUNT IS NULL ) THEN
----      -- 本体金額が空の場合は本体金額入力エラー表示
----      -- ステータスをエラーに
----      gv_result := cv_result_error;
----      -- エラー件数加算
----      gn_error_count := gn_error_count + 1;
----      xx00_file_pkg.output(
----        xx00_message_pkg.get_msg(
----          'XX03',
----          'APP-XX03-08033'
----        )
----      );
----    END IF;
----
--    -- 明細消費税額チェック
--    IF ( xx03_if_detail_rec.ENTERED_TAX_AMOUNT IS NULL ) THEN
--      -- 消費税額が空の場合は消費税額入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08034'
--        )
--      );
--    END IF;
----
--    -- 税区分チェック
--    IF ( xx03_if_detail_rec.SLIP_LINE_TAX_CODE IS NULL
--           OR TRIM(xx03_if_detail_rec.SLIP_LINE_TAX_CODE) = '' ) THEN
--      -- 税区分が空の場合は税区分入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08035'
--        )
--      );
--    END IF;
----
--    -- 会社チェック
--    IF ( xx03_if_detail_rec.SEGMENT1 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT1) = '' ) THEN
--      -- 会社が空の場合は会社入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08036'
--        )
--      );
--    END IF;
----
--    -- 部門チェック
--    IF ( xx03_if_detail_rec.SEGMENT2 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT2) = '' ) THEN
--      -- 部門が空の場合は部門入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08037'
--        )
--      );
--    END IF;
----
--    -- 勘定科目チェック
--    IF ( xx03_if_detail_rec.SEGMENT3 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT3) = '' ) THEN
--      -- 勘定科目が空もしくは不正の場合は勘定科目入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08038'
--        )
--      );
--    ELSE
--    -- 勘定科目が空でないときは、入力された勘定科目が勘定科目の
--    -- viewに存在するかをチェックする
--      BEGIN
--        SELECT xal.FLEX_VALUE as SEGMENT3
--          INTO ln_segment3
--          FROM XX03_AR_ACCOUNTS_ALL_LOV_V    xal
--         WHERE xal.FLEX_VALUE = xx03_if_detail_rec.SEGMENT3;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- 対象データなし時は勘定科目名称空
--          ln_segment3 := '';
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--            'XX03',
--            'APP-XX03-08038'
--            )
--          );
--      END;
--  END IF;
----
--    -- 補助科目チェック
--    IF ( xx03_if_detail_rec.SEGMENT4 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT4) = '' ) THEN
--      -- 勘定科目が空の場合は勘定科目入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08039'
--        )
--      );
--    END IF;
----
--    -- 相手先チェック
--    IF ( xx03_if_detail_rec.SEGMENT5 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT5) = '' ) THEN
--      -- 相手先が空の場合は相手先入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08040'
--        )
--      );
--    END IF;
----
--    -- 事業区分チェック
--    IF ( xx03_if_detail_rec.SEGMENT6 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT6) = '' ) THEN
--      -- 事業区分が空の場合は事業区分入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08041'
--        )
--      );
--    END IF;
----
--    -- プロジェクトチェック
--    IF ( xx03_if_detail_rec.SEGMENT7 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT7) = '' ) THEN
--      -- プロジェクトが空の場合はプロジェクト入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08042'
--        )
--      );
--    END IF;
----
--    -- 予備チェック
--    IF ( xx03_if_detail_rec.SEGMENT8 IS NULL
--           OR TRIM(xx03_if_detail_rec.SEGMENT8) = '' ) THEN
--      -- 予備が空の場合は予備入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08043'
--        )
--      );
--    END IF;
----
--      -- 入力金額算出
--      -- 入力金額＝単価＊数量
--      ln_amount  :=  xx03_if_detail_rec.SLIP_LINE_UNIT_PRICE * xx03_if_detail_rec.SLIP_LINE_QUANTITY;
--      -- '内税'が'Y'の時
--      IF ( xx03_if_detail_rec.SLIP_LINE_TAX_FLAG = cv_yes ) THEN
--        -- 本体金額＝入力金額－消費税額
--        ln_ent_amount  :=  ln_amount - xx03_if_detail_rec.ENTERED_TAX_AMOUNT;
--      -- '内税'が'N'の時
--      ELSIF  ( xx03_if_detail_rec.SLIP_LINE_TAX_FLAG = cv_no ) THEN
--        -- 本体金額＝入力金額
--        ln_ent_amount  :=  ln_amount;
--      -- それ以外の時
--      ELSE
--        -- 内税入力値エラー
--        ln_ent_amount := 0;
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
--      -- 明細データ保存
--      INSERT INTO XX03_RECEIVABLE_SLIPS_LINE(
--          RECEIVABLE_LINE_ID             -- 明細ID
--        , RECEIVABLE_ID                  -- 伝票ID
--        , LINE_NUMBER                    -- No
--        , SLIP_LINE_TYPE                 -- 請求内容ID
--        , SLIP_LINE_TYPE_NAME            -- 請求内容
--        , SLIP_LINE_UOM                  -- 単位
--        , SLIP_LINE_UOM_NAME             -- 単位名
--        , SLIP_LINE_UNIT_PRICE           -- 単価
--        , SLIP_LINE_QUANTITY             -- 数量
--        , SLIP_LINE_ENTERED_AMOUNT       -- 入力金額
--        , TAX_CODE                       -- 税区分ID
--        , TAX_NAME                       -- 税区分
--        , AMOUNT_INCLUDES_TAX_FLAG       -- 内税
--        , ENTERED_ITEM_AMOUNT            -- 本体金額
--        , ENTERED_TAX_AMOUNT             -- 消費税額
--        , ACCOUNTED_AMOUNT               -- 換算済金額
--        , SLIP_LINE_RECIEPT_NO           -- 納品書番号
--        , SLIP_DESCRIPTION               -- 備考（明細）
--        , SEGMENT1                       -- 会社
--        , SEGMENT2                       -- 部門
--        , SEGMENT3                       -- 勘定科目
--        , SEGMENT4                       -- 補助科目
--        , SEGMENT5                       -- 相手先
--        , SEGMENT6                       -- 事業区分
--        , SEGMENT7                       -- プロジェクト
--        , SEGMENT8                       -- 予備１
--        , SEGMENT9
--        , SEGMENT10
--        , SEGMENT11
--        , SEGMENT12
--        , SEGMENT13
--        , SEGMENT14
--        , SEGMENT15
--        , SEGMENT16
--        , SEGMENT17
--        , SEGMENT18
--        , SEGMENT19
--        , SEGMENT20
--        , SEGMENT1_NAME
--        , SEGMENT2_NAME
--        , SEGMENT3_NAME
--        , SEGMENT4_NAME
--        , SEGMENT5_NAME
--        , SEGMENT6_NAME
--        , SEGMENT7_NAME
--        , SEGMENT8_NAME
--        , INCR_DECR_REASON_CODE          -- 増減事由
--        , INCR_DECR_REASON_NAME          -- 増減事由名
--        , RECON_REFERENCE                -- 消込参照
--        , JOURNAL_DESCRIPTION            -- 備考（仕訳）
--        , ORG_ID                         -- オルグID
--        , ATTRIBUTE_CATEGORY
--        , ATTRIBUTE1
--        , ATTRIBUTE2
--        , ATTRIBUTE3
--        , ATTRIBUTE4
--        , ATTRIBUTE5
--        , ATTRIBUTE6
--        , ATTRIBUTE7
--        , ATTRIBUTE8
--        , ATTRIBUTE9
--        , ATTRIBUTE10
--        , ATTRIBUTE11
--        , ATTRIBUTE12
--        , ATTRIBUTE13
--        , ATTRIBUTE14
--        , ATTRIBUTE15
--        , CREATED_BY
--        , CREATION_DATE
--        , LAST_UPDATED_BY
--        , LAST_UPDATE_DATE
--        , LAST_UPDATE_LOGIN
--        , REQUEST_ID
--        , PROGRAM_APPLICATION_ID
--        , PROGRAM_ID
--        , PROGRAM_UPDATE_DATE
--      )
--      VALUES(
--          ln_line_id                                        -- 明細ID
--        , gn_receivable_id                                  -- 伝票ID
--        , ln_line_count                                     -- No
--        , xx03_if_detail_rec.SLIP_LINE_TYPE                 -- 請求内容ID
--        , xx03_if_detail_rec.SLIP_LINE_TYPE_NAME            -- 請求内容
--        , xx03_if_detail_rec.SLIP_LINE_UOM                  -- 単位
--        , xx03_if_detail_rec.SLIP_LINE_UOM_NAME             -- 単位
--        , xx03_if_detail_rec.SLIP_LINE_UNIT_PRICE           -- 単価
--        , xx03_if_detail_rec.SLIP_LINE_QUANTITY             -- 数量
--        , ln_amount                                         -- 入力金額
--        , xx03_if_detail_rec.SLIP_LINE_TAX_CODE             -- 税区分ID
--        , xx03_if_detail_rec.TAX_NAME                       -- 税区分
--        , xx03_if_detail_rec.SLIP_LINE_TAX_FLAG             -- 内税
--        , ln_ent_amount                                     -- 本体金額
--        , xx03_if_detail_rec.ENTERED_TAX_AMOUNT             -- 消費税額
--        , 0                                                 -- 換算済金額
--        , xx03_if_detail_rec.SLIP_LINE_RECIEPT_NO           -- 納品書番号
--        , xx03_if_detail_rec.SLIP_DESCRIPTION               -- 備考（明細）
--        , xx03_if_detail_rec.SEGMENT1                       -- 会社
--        , xx03_if_detail_rec.SEGMENT2                       -- 部門
--        , xx03_if_detail_rec.SEGMENT3                       -- 勘定科目
--        , xx03_if_detail_rec.SEGMENT4                       -- 補助科目
--        , xx03_if_detail_rec.SEGMENT5                       -- 相手先
--        , xx03_if_detail_rec.SEGMENT6                       -- 事業区分
--        , xx03_if_detail_rec.SEGMENT7                       -- プロジェクト
--        , xx03_if_detail_rec.SEGMENT8                       -- 予備１
--        , NULL                                              -- SEGMENT9
--        , NULL                                              -- SEGMENT10
--        , NULL                                              -- SEGMENT11
--        , NULL                                              -- SEGMENT12
--        , NULL                                              -- SEGMENT13
--        , NULL                                              -- SEGMENT14
--        , NULL                                              -- SEGMENT15
--        , NULL                                              -- SEGMENT16
--        , NULL                                              -- SEGMENT17
--        , NULL                                              -- SEGMENT18
--        , NULL                                              -- SEGMENT19
--        , NULL                                              -- SEGMENT20
--        , xx03_if_detail_rec.SEGMENT1_NAME                  -- 会社名
--        , xx03_if_detail_rec.SEGMENT2_NAME                  -- 部門名
--        , xx03_if_detail_rec.SEGMENT3_NAME                  -- 勘定科目名
--        , xx03_if_detail_rec.SEGMENT4_NAME                  -- 補助科目名
--        , xx03_if_detail_rec.SEGMENT5_NAME                  -- 相手先名
--        , xx03_if_detail_rec.SEGMENT6_NAME                  -- 事業区分名
--        , xx03_if_detail_rec.SEGMENT7_NAME                  -- プロジェクト名
--        , xx03_if_detail_rec.SEGMENT8_NAME                  -- 予備１
--        , xx03_if_detail_rec.INCR_DECR_REASON_CODE          -- 増減事由
--        , xx03_if_detail_rec.INCR_DECR_REASON_NAME          -- 増減事由名
--        , xx03_if_detail_rec.RECON_REFERENCE                -- 消込参照
--        , xx03_if_detail_rec.JOURNAL_DESCRIPTION            -- 備考（仕訳）
--        , xx03_if_detail_rec.ORG_ID                         -- オルグID
--        , NULL                                              -- ATTRIBUTE_CATEGORY
--        , NULL                                              -- ATTRIBUTE1
--        , NULL                                              -- ATTRIBUTE2
--        , NULL                                              -- ATTRIBUTE3
--        , NULL                                              -- ATTRIBUTE4
--        , NULL                                              -- ATTRIBUTE5
--        , NULL                                              -- ATTRIBUTE6
--        , NULL                                              -- ATTRIBUTE7
--        , NULL                                              -- ATTRIBUTE8
--        , NULL                                              -- ATTRIBUTE9
--        , NULL                                              -- ATTRIBUTE10
--        , NULL                                              -- ATTRIBUTE11
--        , NULL                                              -- ATTRIBUTE12
--        , NULL                                              -- ATTRIBUTE13
--        , NULL                                              -- ATTRIBUTE14
--        , NULL                                              -- ATTRIBUTE15
--        , xx00_global_pkg.user_id                           -- CREATED_BY
--        , xx00_date_pkg.get_system_datetime_f               -- CREATION_DATE
--        , xx00_global_pkg.user_id                           -- LAST_UPDATED_BY
--        , xx00_date_pkg.get_system_datetime_f               -- LAST_UPDATE_DATE
--        , xx00_global_pkg.login_id                          -- LAST_UPDATE_LOGIN
--        , xx00_global_pkg.conc_request_id                   -- REQUEST_ID
--        , xx00_global_pkg.prog_appl_id                      -- PROGRAM_APPLICATION_ID
--        , xx00_global_pkg.conc_program_id                   -- PROGRAM_ID
--        , xx00_date_pkg.get_system_datetime_f               -- PROGRAM_UPDATE_DATE
--      );
----
--      -- 明細連番加算
--      ln_line_count := ln_line_count + 1;
----
--    END LOOP xx03_if_detail_loop;
--    CLOSE xx03_if_detail_cur;
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
--   * Description      : 請求依頼の入力チェック(E-2)
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
--    -- 顧客チェック
--    IF ( xx03_if_header_rec.CUSTOMER_NAME IS NULL
--           OR TRIM(xx03_if_header_rec.CUSTOMER_NAME) = '' ) THEN
--      -- 顧客が空の場合は顧客入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08029'
--        )
--      );
--    END IF;
----
--    -- 顧客事業所チェック
--    IF ( xx03_if_header_rec.CUSTOMER_OFFICE_ID IS NULL
--           OR TRIM(xx03_if_header_rec.CUSTOMER_OFFICE_ID) = '' ) THEN
--      -- 顧客事業所が空の場合は顧客事業所入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08030'
--        )
--      );
--    END IF;
----
--    -- 請求書日付チェック
--    IF ( xx03_if_header_rec.INVOICE_DATE IS NULL
--           OR TRIM(xx03_if_header_rec.INVOICE_DATE) = '' ) THEN
--      -- 請求書日付が空の場合は請求書日付入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08014'
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
---- ver 1.2 Change Start
--    -- 支払方法チェック
----    IF ( xx03_if_header_rec.RECEIPT_METHOD_NAME IS NULL
----           OR TRIM(xx03_if_header_rec.RECEIPT_METHOD_NAME) = '' ) THEN
--    IF ( xx03_if_header_rec.RECEIPT_METHOD_ID IS NULL
--           OR TRIM(xx03_if_header_rec.RECEIPT_METHOD_ID) = '' ) THEN
--      -- 支払方法が空の場合は支払方法入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
----          'APP-XX03-08015'
--          'APP-XX03-08031'
--        )
--      );
--    END IF;
---- ver 1.2 Change End
----
--    -- 支払条件チェック
--    IF ( xx03_if_header_rec.TERMS_ID IS NULL
--           OR TRIM(xx03_if_header_rec.TERMS_ID) = '' ) THEN
--      -- 支払条件IDが空の場合は支払条件入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08017'
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
--    ln_total_item_amount NUMBER; -- 本体金額合計
--    ln_total_tax_amount NUMBER;  -- 消費税額合計
--    ln_commitment_amount NUMBER; -- 前受金額
--    lv_cur_code VARCHAR2(15);    -- 機能通貨コード
--    ln_accounted_amount NUMBER;  -- 換算済合計金額
--    wk number;
----
--  BEGIN
----
----##################  固定ステータス初期化部 START   ###################
----
--    ov_retcode := xx00_common_pkg.set_status_normal_f(cv_prg_name);
----
----###########################  固定部 END   ############################
----
--    -- 本体金額合計算出（本体金額＝全明細の本体金額の合計）
--    SELECT SUM(xrsl.ENTERED_ITEM_AMOUNT) as ENTERED_ITEM_AMOUNT
--      INTO ln_total_item_amount
--      FROM XX03_RECEIVABLE_SLIPS_LINE xrsl
--     WHERE xrsl.RECEIVABLE_ID = gn_receivable_id
--    GROUP BY xrsl.RECEIVABLE_ID;
----
--    -- ヘッダレコードに本体合計金額セット
--    UPDATE XX03_RECEIVABLE_SLIPS xrs
--       SET xrs.INV_ITEM_AMOUNT = ln_total_item_amount
--     WHERE xrs.RECEIVABLE_ID   = gn_receivable_id;
----
--    -- 消費税額合計（消費税額＝全明細の消費税額の合計）
--    SELECT SUM(xrsl.ENTERED_TAX_AMOUNT) as ENTERED_TAX_AMOUNT
--      INTO ln_total_tax_amount
--      FROM XX03_RECEIVABLE_SLIPS_LINE xrsl
--     WHERE xrsl.RECEIVABLE_ID = gn_receivable_id
--    GROUP BY xrsl.RECEIVABLE_ID;
----
--    -- ヘッダレコードに本体合計金額セット
--    UPDATE XX03_RECEIVABLE_SLIPS xrs
--       SET xrs.INV_TAX_AMOUNT = ln_total_tax_amount
--     WHERE xrs.RECEIVABLE_ID  = gn_receivable_id;
----
--    -- 充当金額計算
--    -- 前受充当伝票番号の指定がある場合
--    IF ( xx03_if_header_rec.COMMITMENT_NUMBER IS NOT NULL ) THEN
--      BEGIN
--        -- 前受充当伝票番号で選択した伝票番号の充当金額を取得する。
--        SELECT xcnl.COMMITMENT_AMOUNT
--          INTO ln_commitment_amount
--          FROM XX03_COMMITMENT_NUMBER_LOV_V xcnl
--         WHERE xcnl.TRX_NUMBER = xx03_if_header_rec.COMMITMENT_NUMBER;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- 対象データなし時は処理を抜ける
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          RETURN;
--      END;
--      -- レコードの充当金額と、本体金額＋消費税額の小さい方を充当金額とする
--      IF ( ln_commitment_amount > (ln_total_item_amount + ln_total_tax_amount)) THEN
--        ln_commitment_amount := ln_total_item_amount + ln_total_tax_amount;
--      END IF;
--    ELSE
--      -- 充当伝票なし
--      ln_commitment_amount := 0;
--    END IF;
----
--    -- 支払金額計算（支払金額＝本体金額＋消費税額－充当金額）
--    -- ヘッダレコードに支払金額セット
--    UPDATE XX03_RECEIVABLE_SLIPS xrs
--       SET xrs.INV_AMOUNT = (ln_total_item_amount + ln_total_tax_amount) - ln_commitment_amount,
--           xrs.COMMITMENT_AMOUNT = ln_commitment_amount
--     WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
----
--   -- 換算済合計金額計算
--   -- 機能通貨コード取得
--   SELECT gsob.currency_code
--     INTO lv_cur_code
--     FROM gl_sets_of_books gsob
--    WHERE gsob.set_of_books_id = xx00_profile_pkg.value(cv_prof_GL_ID);
----
--   -- 通貨コードが機能通貨の場合
--   IF ( xx03_if_header_rec.INVOICE_CURRENCY_CODE = lv_cur_code ) THEN
----
--     -- 換算済合計金額＝支払金額
--     UPDATE XX03_RECEIVABLE_SLIPS xrs
--        SET xrs.INV_ACCOUNTED_AMOUNT = (ln_total_item_amount + ln_total_tax_amount)
--                                         - ln_commitment_amount
--      WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
--   -- 通貨コードが機能通貨でない場合
--   ELSE
--     -- 換算済合計金額＝（支払金額×レート）を四捨五入した値［※四捨五入を行う単位は機能通貨依存］
--     SELECT TO_NUMBER(
--              TO_CHAR(
--                (((ln_total_item_amount + ln_total_tax_amount) - ln_commitment_amount)
--                  * xx03_if_header_rec.CONVERSION_RATE),
--                xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--              ),
--              xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--            )
--       INTO ln_accounted_amount
--       FROM dual;
----
--     UPDATE XX03_RECEIVABLE_SLIPS xrs
--        SET xrs.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
--      WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
--   END IF;
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
--    ln_interface_id  NUMBER;          -- INTERFACE_ID
--    ln_header_count  NUMBER;          -- INTERFACE_ID同一値ヘッダ件数
--    ld_terms_date    DATE;            -- 入金予定日
--    lv_terms_flg     VARCHAR2(1);     -- 支払予定日変更可能フラグ
--    lv_app_upd       VARCHAR2(1);     -- 重点管理フラグ
--    ln_error_cnt     NUMBER;          -- 仕訳チェックエラー件数
--    lv_error_flg     VARCHAR2(1);     -- 仕訳チェックエラーフラグ
--    lv_error_flg1    VARCHAR2(1);     -- 仕訳チェックエラーフラグ1
--    lv_error_msg1    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ1
--    lv_error_flg2    VARCHAR2(1);     -- 仕訳チェックエラーフラグ2
--    lv_error_msg2    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ2
--    lv_error_flg3    VARCHAR2(1);     -- 仕訳チェックエラーフラグ3
--    lv_error_msg3    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ3
--    lv_error_flg4    VARCHAR2(1);     -- 仕訳チェックエラーフラグ4
--    lv_error_msg4    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ4
--    lv_error_flg5    VARCHAR2(1);     -- 仕訳チェックエラーフラグ5
--    lv_error_msg5    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ5
--    lv_error_flg6    VARCHAR2(1);     -- 仕訳チェックエラーフラグ6
--    lv_error_msg6    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ6
--    lv_error_flg7    VARCHAR2(1);     -- 仕訳チェックエラーフラグ7
--    lv_error_msg7    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ7
--    lv_error_flg8    VARCHAR2(1);     -- 仕訳チェックエラーフラグ8
--    lv_error_msg8    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ8
--    lv_error_flg9    VARCHAR2(1);     -- 仕訳チェックエラーフラグ9
--    lv_error_msg9    VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ9
--    lv_error_flg10   VARCHAR2(1);     -- 仕訳チェックエラーフラグ10
--    lv_error_msg10   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ10
--    lv_error_flg11   VARCHAR2(1);     -- 仕訳チェックエラーフラグ11
--    lv_error_msg11   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ11
--    lv_error_flg12   VARCHAR2(1);     -- 仕訳チェックエラーフラグ12
--    lv_error_msg12   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ12
--    lv_error_flg13   VARCHAR2(1);     -- 仕訳チェックエラーフラグ13
--    lv_error_msg13   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ13
--    lv_error_flg14   VARCHAR2(1);     -- 仕訳チェックエラーフラグ14
--    lv_error_msg14   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ14
--    lv_error_flg15   VARCHAR2(1);     -- 仕訳チェックエラーフラグ15
--    lv_error_msg15   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ15
--    lv_error_flg16   VARCHAR2(1);     -- 仕訳チェックエラーフラグ16
--    lv_error_msg16   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ16
--    lv_error_flg17   VARCHAR2(1);     -- 仕訳チェックエラーフラグ17
--    lv_error_msg17   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ17
--    lv_error_flg18   VARCHAR2(1);     -- 仕訳チェックエラーフラグ18
--    lv_error_msg18   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ18
--    lv_error_flg19   VARCHAR2(1);     -- 仕訳チェックエラーフラグ19
--    lv_error_msg19   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ19
--    lv_error_flg20   VARCHAR2(1);     -- 仕訳チェックエラーフラグ20
--    lv_error_msg20   VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ20
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
--    -- システム情報カーソルオープン
--    OPEN sys_tax_cur;
--      FETCH sys_tax_cur INTO sys_tax_rec;
--    CLOSE sys_tax_cur;
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
--      SELECT COUNT(xrsi.INTERFACE_ID)
--        INTO ln_header_count
--        FROM XX03_RECEIVABLE_SLIPS_IF xrsi
--       WHERE xrsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID
--         AND xrsi.REQUEST_ID   = in_request_id
--         AND xrsi.SOURCE       = iv_source;
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
--        -- 消費税計算レベル・消費税端数処理の設定を判断し変数へ格納する
--        -- システムパラメータOVERRIDE可能なら個別の値を使用
--        IF (sys_tax_rec.TAX_ROUNDING_ALLOW_OVERRIDE = cv_yes) THEN
----
--          IF (xx03_if_header_rec.AUTO_TAX_CALC_FLAG IS NULL) THEN
--          -- 事業所単位が未入力なら上位レベルを使用
--            IF (xx03_if_header_rec.AUTO_TAX_CALC_FLAG_C IS NULL) THEN
--            -- 顧客単位が未入力ならシステムパラメータを使用
--              xx03_if_header_rec.AUTO_TAX_CALC_FLAG := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
--            ELSE
--            -- 顧客単位が入力されていれば顧客単位を使用
--              xx03_if_header_rec.AUTO_TAX_CALC_FLAG := xx03_if_header_rec.AUTO_TAX_CALC_FLAG_C;
--            END IF;
--          END IF;
----
--          IF (xx03_if_header_rec.TAX_ROUNDING_RULE IS NULL) THEN
--          -- 事業所単位が未入力なら上位レベルを使用
--            IF (xx03_if_header_rec.TAX_ROUNDING_RULE_C IS NULL) THEN
--            -- 顧客単位が未入力ならシステムパラメータを使用
--              xx03_if_header_rec.TAX_ROUNDING_RULE := sys_tax_rec.TAX_ROUNDING_RULE;
--            ELSE
--            -- 顧客単位が入力されていれば顧客単位を使用
--              xx03_if_header_rec.TAX_ROUNDING_RULE := xx03_if_header_rec.TAX_ROUNDING_RULE_C;
--            END IF;
--          END IF;
----
--        ELSE
--        -- システムパラメータOVERRIDE不可ならシステムの値を使用
--          xx03_if_header_rec.AUTO_TAX_CALC_FLAG  := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
--          xx03_if_header_rec.TAX_ROUNDING_RULE   := sys_tax_rec.TAX_ROUNDING_RULE;
--        END IF;
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
--          -- ===============================
--          -- 入金予定日取得(E-4)
--          -- ===============================
--        xx03_deptinput_ar_check_pkg.get_terms_date(
--          xx03_if_header_rec.TERMS_ID,                    -- 支払条件ID
--          xx03_if_header_rec.INVOICE_DATE,                -- 請求書日付
--          ld_terms_date,                                  -- 入金予定日
--          lv_errbuf,
--          lv_retcode,
--          lv_errmsg
--        );
--          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
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
--                'APP-XX03-14101',
--                'TOK_XX03_CHECK_ERROR',
--                lv_errmsg
--              )
--            );
--          END IF;
----
--          -- エラーが検出されていない時のみ以降の処理実行
--          IF ( gn_error_count = 0 ) THEN
----
--            -- 伝票ID取得
--            SELECT XX03_RECEIVABLE_SLIPS_S.nextval
--              INTO gn_receivable_id
--              FROM dual;
----
--            -- インターフェーステーブル請求書ID更新
--            UPDATE XX03_RECEIVABLE_SLIPS_IF xrsi
--               SET RECEIVABLE_ID     = gn_receivable_id
--             WHERE xrsi.REQUEST_ID   = in_request_id
--               AND xrsi.SOURCE       = iv_source
--               AND xrsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID;
----
--            -- ヘッダデータ保存
--            INSERT INTO XX03_RECEIVABLE_SLIPS(
--                RECEIVABLE_ID                  -- 伝票ID
--              , WF_STATUS                      -- ステータス
--              , SLIP_TYPE                      -- 伝票種別
--              , RECEIVABLE_NUM                 -- 伝票番号
--              , ENTRY_DATE                     -- 起票日
--              , REQUEST_KEY                    -- 申請キー
--              , REQUESTOR_PERSON_ID            -- 申請者
--              , REQUESTOR_PERSON_NAME          -- 申請者名
--              , APPROVER_PERSON_ID             -- 承認者
--              , APPROVER_PERSON_NAME           -- 承認者名
--              , REQUEST_DATE                   -- 申請日
--              , APPROVAL_DATE                  -- 承認日
--              , REJECTION_DATE                 -- 否認日
--              , ACCOUNT_APPROVER_PERSON_ID     -- 経理承認者
--              , ACCOUNT_APPROVAL_DATE          -- 経理承認日
--              , AR_FORWARD_DATE                -- AR転送日
--              , RECOGNITION_CLASS              -- 承認回数
--              , APPROVER_COMMENTS              -- 承認コメント
--              , REQUEST_ENABLE_FLAG            -- 申請可能フラグ
--              , ACCOUNT_REVISION_FLAG          -- N_FLAG IS '経理修正フラグ
--              , INVOICE_DATE                   -- 請求書日付
--              , TRANS_TYPE_ID                  -- 取引タイプID
--              , TRANS_TYPE_NAME                -- 取引タイプ名
--              , CUSTOMER_ID                    -- 顧客ID
--              , CUSTOMER_NAME                  -- 顧客名
--              , CUSTOMER_OFFICE_ID             -- 顧客事業所ID
--              , CUSTOMER_OFFICE_NAME           -- 顧客事業所名
--              , INV_AMOUNT                     -- 請求合計金額
--              , INV_ACCOUNTED_AMOUNT           -- 換算済合計金額
--              , INV_ITEM_AMOUNT                -- 本体合計金額
--              , INV_TAX_AMOUNT                 -- 消費税合計金額
--              , INV_PREPAY_AMOUNT              -- 充当金額
--              , INVOICE_CURRENCY_CODE          -- 通貨
--              , EXCHANGE_RATE                  -- レート
--              , EXCHANGE_RATE_TYPE             -- レートタイプ
--              , EXCHANGE_RATE_TYPE_NAME        -- レートタイプ名
--              , RECEIPT_METHOD_ID              -- 支払方法ID
--              , RECEIPT_METHOD_NAME            -- 支払方法名
--              , TERMS_ID                       -- 支払条件ID
--              , TERMS_NAME                     -- 支払条件名
--              , DESCRIPTION                    -- 備考
--              , CONTEXT                        -- コンテキスト
--              , ENTRY_DEPARTMENT               -- 起票部門
--              , ENTRY_PERSON_ID                -- 伝票入力者
--              , ORIG_INVOICE_NUM               -- 修正元伝票番号
--              , ACCOUNT_APPROVAL_FLAG          -- 重点管理フラグ
--              , GL_DATE                        -- 計上日
--              , AUTO_TAX_CALC_FLAG             -- 消費税計算レベル
--              , AP_TAX_ROUNDING_RULE           -- 消費税端数処理
--              , ORG_ID                         -- オルグID
--              , SET_OF_BOOKS_ID                -- 会計帳簿ID
--              , COMMITMENT_NUMBER              -- 前受金充当番号
--              , COMMITMENT_AMOUNT              -- 前受金残高金額
--              , PAYMENT_SCHEDULED_DATE         -- 入金予定日
--              , ONETIME_CUSTOMER_NAME          -- 顧客名称
--              , ONETIME_CUSTOMER_KANA_NAME     -- カナ名
--              , ONETIME_CUSTOMER_ADDRESS_1     -- 住所１
--              , ONETIME_CUSTOMER_ADDRESS_2     -- 住所２
--              , ONETIME_CUSTOMER_ADDRESS_3     -- 住所３
--              , COMMITMENT_NAME                -- 摘要
--              , COMMITMENT_ORIGINAL_AMOUNT     -- 金額
--              , COMMITMENT_DATE_FROM           -- 有効日（自）
--              , COMMITMENT_DATE_TO             -- 有効日（至）
--              , ATTRIBUTE_CATEGORY
--              , ATTRIBUTE1
--              , ATTRIBUTE2
--              , ATTRIBUTE3
--              , ATTRIBUTE4
--              , ATTRIBUTE5
--              , ATTRIBUTE6
--              , ATTRIBUTE7
--              , ATTRIBUTE8
--              , ATTRIBUTE9
--              , ATTRIBUTE10
--              , ATTRIBUTE11
--              , ATTRIBUTE12
--              , ATTRIBUTE13
--              , ATTRIBUTE14
--              , ATTRIBUTE15
--              , CREATED_BY
--              , CREATION_DATE
--              , LAST_UPDATED_BY
--              , LAST_UPDATE_DATE
--              , LAST_UPDATE_LOGIN
--              , REQUEST_ID
--              , PROGRAM_APPLICATION_ID
--              , PROGRAM_ID
--              , PROGRAM_UPDATE_DATE
--              , DELETE_FLAG
--              , FIRST_CUSTOMER_FLAG                         -- 一見顧客区分
--            )
--            VALUES(
--                gn_receivable_id                            -- 伝票ID
--              , xx03_if_header_rec.WF_STATUS                -- ステータス
--              , xx03_if_header_rec.SLIP_TYPE                -- 伝票種別
--              , gn_receivable_id                            -- 伝票番号
--              , xx03_if_header_rec.ENTRY_DATE               -- 起票日
--              , NULL                                        -- 申請キー
--              , xx03_if_header_rec.REQUESTOR_PERSON_ID      -- 申請者
--              , xx03_if_header_rec.REQUESTOR_PERSON_NAME    -- 申請者名
--              , xx03_if_header_rec.APPROVER_PERSON_ID       -- 承認者
--              , xx03_if_header_rec.APPROVER_PERSON_NAME     -- 承認者名
--              , NULL                                        -- 申請日
--              , NULL                                        -- 承認日
--              , NULL                                        -- 否認日
--              , NULL                                        -- 経理承認者
--              , NULL                                        -- 経理承認日
--              , NULL                                        -- AR転送日
--              , 0                                           -- 承認回数
--              , NULL                                        -- 承認コメント
--              , 'N'                                         -- 申請可能フラグ
--              , 'N'                                         -- 経理修正フラグ
--              , xx03_if_header_rec.INVOICE_DATE             -- 請求書日付
--              , xx03_if_header_rec.TRANS_TYPE_ID            -- 取引タイプID
--              , xx03_if_header_rec.TRANS_TYPE_NAME          -- 取引タイプ名
--              , xx03_if_header_rec.CUSTOMER_ID              -- 顧客ID
--              , xx03_if_header_rec.CUSTOMER_NAME            -- 顧客名
--              , xx03_if_header_rec.CUSTOMER_OFFICE_ID       -- 顧客事業所ID
--              , xx03_if_header_rec.CUSTOMER_OFFICE_NAME     -- 顧客事業所名
--              , 0                                           -- 請求合計金額（E-3で更新）
--              , 0                                           -- 換算済合計金額
--              , 0                                           -- 本体合計金額（E-3で更新）
--              , 0                                           -- 消費税合計金額（E-3で更新）
--              , 0                                           -- 充当金額
--              , xx03_if_header_rec.INVOICE_CURRENCY_CODE    -- 通貨
--              , xx03_if_header_rec.CONVERSION_RATE          -- レート
--              , xx03_if_header_rec.EXCHANGE_RATE_TYPE       -- レートタイプ
--              , xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME  -- レートタイプ名
--              , xx03_if_header_rec.RECEIPT_METHOD_ID        -- 支払方法ID
--              , xx03_if_header_rec.RECEIPT_METHOD_NAME      -- 支払方法名
--              , xx03_if_header_rec.TERMS_ID                 -- 支払条件ID
--              , xx03_if_header_rec.TERMS_NAME               -- 支払条件名
--              , xx03_if_header_rec.DESCRIPTION              -- 備考
--              , NULL                                        -- コンテキスト
--              , xx03_if_header_rec.ENTRY_DEPARTMENT         -- 起票部門
--              , xx03_if_header_rec.ENTRY_PERSON_ID          -- 伝票入力者
--              , NULL                                        -- 修正元伝票番号
--              , 'N'                                         -- 重点管理フラグ
--              , xx03_if_header_rec.GL_DATE                  -- 計上日
--              , xx03_if_header_rec.AUTO_TAX_CALC_FLAG       -- 消費税計算レベル
--              , xx03_if_header_rec.TAX_ROUNDING_RULE        -- 消費税端数処理
--              , xx03_if_header_rec.ORG_ID                   -- オルグID
--              , xx00_profile_pkg.value(cv_prof_GL_ID)       -- 会計帳簿ID
--              , xx03_if_header_rec.COMMITMENT_NUMBER        -- 前受金充当番号
--              , NULL                                        -- 前受金残高金額
--              , ld_terms_date                               -- 入金予定日
--              , xx03_if_header_rec.ONETIME_CUSTOMER_NAME       -- 顧客名称
--              , xx03_if_header_rec.ONETIME_CUSTOMER_KANA_NAME  -- カナ名
--              , xx03_if_header_rec.ONETIME_CUSTOMER_ADDRESS_1  -- 住所１
--              , xx03_if_header_rec.ONETIME_CUSTOMER_ADDRESS_2  -- 住所２
--              , xx03_if_header_rec.ONETIME_CUSTOMER_ADDRESS_3  -- 住所３
--              , NULL                                        -- 摘要
--              , 0                                           -- 金額
--              , NULL                                        -- 有効日（自）
--              , NULL                                        -- 有効日（至）
--              , NULL                                        -- ATTRIBUTE_CATEGORY
--              , NULL                                        -- ATTRIBUTE1
--              , NULL                                        -- ATTRIBUTE2
--              , NULL                                        -- ATTRIBUTE3
--              , NULL                                        -- ATTRIBUTE4
--              , NULL                                        -- ATTRIBUTE5
--              , NULL                                        -- ATTRIBUTE6
--              , NULL                                        -- ATTRIBUTE7
--              , NULL                                        -- ATTRIBUTE8
--              , NULL                                        -- ATTRIBUTE9
--              , NULL                                        -- ATTRIBUTE10
--              , NULL                                        -- ATTRIBUTE11
--              , NULL                                        -- ATTRIBUTE12
--              , NULL                                        -- ATTRIBUTE13
--              , NULL                                        -- ATTRIBUTE14
--              , NULL                                        -- ATTRIBUTE15
--              , xx00_global_pkg.user_id                     -- CREATED_BY
--              , xx00_date_pkg.get_system_datetime_f         -- CREATION_DATE
--              , xx00_global_pkg.user_id                     -- LAST_UPDATED_BY
--              , xx00_date_pkg.get_system_datetime_f         -- LAST_UPDATE_DATE
--              , xx00_global_pkg.login_id                    -- LAST_UPDATE_LOGIN
--              , xx00_global_pkg.conc_request_id             -- REQUEST_ID
--              , xx00_global_pkg.prog_appl_id                -- PROGRAM_APPLICATION_ID
--              , xx00_global_pkg.conc_program_id             -- PROGRAM_ID
--              , xx00_date_pkg.get_system_datetime_f         -- PROGRAM_UPDATE_DATE
--              , 'N'                                         -- 削除フラグ：Y=削除,N=非削除
--              , DECODE(xx03_if_header_rec.ONETIME_CUSTOMER_NAME, NULL, 'N', 'Y')  -- 一見顧客区分
--            );
----
--            -- ===============================
--            -- 明細データコピー
--            -- ===============================
--            copy_detail_data(
--              iv_source,         -- ソース
--              in_request_id,     -- 要求ID
--              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--              lv_retcode,        -- リターン・コード             --# 固定 #
--              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              RAISE global_process_expt;
--            END IF;
----
--            -- ===============================
--            -- 金額計算(E-3)
--            -- ===============================
--            calc_amount(
--              lv_errbuf,         -- エラー・メッセージ           --# 固定 #
--              lv_retcode,        -- リターン・コード             --# 固定 #
--              lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              RAISE global_process_expt;
--            END IF;
----
--            -- ===============================
--            -- 重点管理チェック(E-5)
--            -- ===============================
--            xx03_deptinput_ar_check_pkg.set_account_approval_flag(
--              gn_receivable_id,
--              lv_app_upd,
--              lv_errbuf,
--              lv_retcode,
--              lv_errmsg
--            );
--            IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
--              -- 結果が正常なら、ヘッダレコードの重点管理フラグを更新
--              UPDATE XX03_RECEIVABLE_SLIPS xrs
--                 SET xrs.ACCOUNT_APPROVAL_FLAG = lv_app_upd    -- 重点管理フラグ
--               WHERE xrs.RECEIVABLE_ID = gn_receivable_id;
--            ELSE
--              -- 結果が正常でなければ、エラーメッセージを出力
--              -- ステータスが現在の値より更に上位の値の時は上書き
--              IF ( TO_NUMBER(lv_retcode) > TO_NUMBER(gv_result)  ) THEN
--                gv_result := lv_retcode;
--              END IF;
--              -- エラー件数加算
--              gn_error_count := gn_error_count + 1;
--              xx00_file_pkg.output(
--                xx00_message_pkg.get_msg(
--                  'XX03',
--                  'APP-XX03-14143'
--                )
--              );
--            END IF;
----
--            -- ===============================
--            -- 仕訳チェック(E-6)
--            -- ===============================
--            xx03_deptinput_ar_check_pkg.check_deptinput_ar (
--              gn_receivable_id,
--              ln_error_cnt,
--              lv_error_flg,
--              lv_error_flg1,
--              lv_error_msg1,
--              lv_error_flg2,
--              lv_error_msg2,
--              lv_error_flg3,
--              lv_error_msg3,
--              lv_error_flg4,
--              lv_error_msg4,
--              lv_error_flg5,
--              lv_error_msg5,
--              lv_error_flg6,
--              lv_error_msg6,
--              lv_error_flg7,
--              lv_error_msg7,
--              lv_error_flg8,
--              lv_error_msg8,
--              lv_error_flg9,
--              lv_error_msg9,
--              lv_error_flg10,
--              lv_error_msg10,
--              lv_error_flg11,
--              lv_error_msg11,
--              lv_error_flg12,
--              lv_error_msg12,
--              lv_error_flg13,
--              lv_error_msg13,
--              lv_error_flg14,
--              lv_error_msg14,
--              lv_error_flg15,
--              lv_error_msg15,
--              lv_error_flg16,
--              lv_error_msg16,
--              lv_error_flg17,
--              lv_error_msg17,
--              lv_error_flg18,
--              lv_error_msg18,
--              lv_error_flg19,
--              lv_error_msg19,
--              lv_error_flg20,
--              lv_error_msg20,
--              lv_errbuf,
--              lv_retcode,
--              lv_errmsg
--            );
----
--            IF ( ln_error_cnt > 0 ) THEN
--              -- ステータスが現在の値より更に上位の値の時は上書き
--              IF ( gv_result = cv_result_normal AND lv_error_flg = cv_dept_warning ) THEN
--                gv_result := cv_result_warning;
--              ELSIF ( lv_error_flg = cv_dept_error ) THEN
--                gv_result := cv_result_error;
--              END IF;
--              -- 仕訳エラー有り時は、存在する分全てエラーメッセージを出力
--              IF ( lv_error_flg1 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg1
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg2 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg2
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg3 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg3
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg4 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg4
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg5 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg5
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg6 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg6
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg7 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg7
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg8 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg8
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg9 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg9
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg10 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg10
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg11 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg11
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg12 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg12
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg13 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg13
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg14 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg14
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg15 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg15
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg16 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg16
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg17 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg17
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg18 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg18
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg19 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg19
--                  )
--                );
--              END IF;
--              IF ( lv_error_flg20 <> cv_dept_normal ) THEN
--                -- エラー件数加算
--                gn_error_count := gn_error_count + 1;
--                xx00_file_pkg.output(
--                  xx00_message_pkg.get_msg(
--                    'XX03', 'APP-XX03-14101', 'TOK_XX03_CHECK_ERROR', lv_error_msg20
--                  )
--                );
--              END IF;
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























  /**********************************************************************************
   * Procedure Name   : ins_header_data
   * Description      : ヘッダデータのコピー
   ***********************************************************************************/
  PROCEDURE ins_header_data(
    iv_source     IN  VARCHAR2,     --  1.ソース
    in_request_id IN  NUMBER,       --  2.要求ID
    id_terms_date IN  DATE,         --  3.支払予定日
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
    -- 請求書ID取得
    SELECT XX03_RECEIVABLE_SLIPS_S.nextval
    INTO   gn_receivable_id
    FROM   dual;
--
    -- インターフェーステーブル請求書ID更新
    UPDATE XX03_RECEIVABLE_SLIPS_IF xrsi
    SET    RECEIVABLE_ID     = gn_receivable_id
    WHERE  xrsi.REQUEST_ID   = in_request_id
      AND  xrsi.SOURCE       = iv_source
      AND  xrsi.INTERFACE_ID = xx03_if_head_line_rec.HEAD_INTERFACE_ID;
--
    -- 消費税計算レベル・消費税端数処理の設定を判断し変数へ格納する
    -- システムパラメータOVERRIDE可能なら個別の値を使用
    IF (sys_tax_rec.TAX_ROUNDING_ALLOW_OVERRIDE = cv_yes) THEN
--
      IF (xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG IS NULL) THEN
      -- 事業所単位が未入力なら上位レベルを使用
        IF (xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG_C IS NULL) THEN
        -- 顧客単位が未入力ならシステムパラメータを使用
          xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
        ELSE
        -- 顧客単位が入力されていれば顧客単位を使用
          xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG := xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG_C;
        END IF;
      END IF;
--
      IF (xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE IS NULL) THEN
      -- 事業所単位が未入力なら上位レベルを使用
        IF (xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE_C IS NULL) THEN
        -- 顧客単位が未入力ならシステムパラメータを使用
          xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE := sys_tax_rec.TAX_ROUNDING_RULE;
        ELSE
        -- 顧客単位が入力されていれば顧客単位を使用
          xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE := xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE_C;
        END IF;
      END IF;
--
    ELSE
    -- システムパラメータOVERRIDE不可ならシステムの値を使用
      xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG  := sys_tax_rec.TAX_HEADER_LEVEL_FLAG;
      xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE   := sys_tax_rec.TAX_ROUNDING_RULE;
    END IF;
--
    -- ヘッダデータ保存
    INSERT INTO XX03_RECEIVABLE_SLIPS(
        RECEIVABLE_ID                  -- 伝票ID
      , WF_STATUS                      -- ステータス
      , SLIP_TYPE                      -- 伝票種別
      , RECEIVABLE_NUM                 -- 伝票番号
      , ENTRY_DATE                     -- 起票日
      , REQUEST_KEY                    -- 申請キー
      , REQUESTOR_PERSON_ID            -- 申請者
      , REQUESTOR_PERSON_NAME          -- 申請者名
      , APPROVER_PERSON_ID             -- 承認者
      , APPROVER_PERSON_NAME           -- 承認者名
      , REQUEST_DATE                   -- 申請日
      , APPROVAL_DATE                  -- 承認日
      , REJECTION_DATE                 -- 否認日
      , ACCOUNT_APPROVER_PERSON_ID     -- 経理承認者
      , ACCOUNT_APPROVAL_DATE          -- 経理承認日
      , AR_FORWARD_DATE                -- AR転送日
      , RECOGNITION_CLASS              -- 承認回数
      , APPROVER_COMMENTS              -- 承認コメント
      , REQUEST_ENABLE_FLAG            -- 申請可能フラグ
      , ACCOUNT_REVISION_FLAG          -- N_FLAG IS '経理修正フラグ
      , INVOICE_DATE                   -- 請求書日付
      , TRANS_TYPE_ID                  -- 取引タイプID
      , TRANS_TYPE_NAME                -- 取引タイプ名
      , CUSTOMER_ID                    -- 顧客ID
      , CUSTOMER_NAME                  -- 顧客名
      , CUSTOMER_OFFICE_ID             -- 顧客事業所ID
      , CUSTOMER_OFFICE_NAME           -- 顧客事業所名
      , INV_AMOUNT                     -- 請求合計金額
      , INV_ACCOUNTED_AMOUNT           -- 換算済合計金額
      , INV_ITEM_AMOUNT                -- 本体合計金額
      , INV_TAX_AMOUNT                 -- 消費税合計金額
      , INV_PREPAY_AMOUNT              -- 充当金額
      , INVOICE_CURRENCY_CODE          -- 通貨
      , EXCHANGE_RATE                  -- レート
      , EXCHANGE_RATE_TYPE             -- レートタイプ
      , EXCHANGE_RATE_TYPE_NAME        -- レートタイプ名
      , RECEIPT_METHOD_ID              -- 支払方法ID
      , RECEIPT_METHOD_NAME            -- 支払方法名
      , TERMS_ID                       -- 支払条件ID
      , TERMS_NAME                     -- 支払条件名
      , DESCRIPTION                    -- 備考
      , CONTEXT                        -- コンテキスト
      , ENTRY_DEPARTMENT               -- 起票部門
      , ENTRY_PERSON_ID                -- 伝票入力者
      , ORIG_INVOICE_NUM               -- 修正元伝票番号
      , ACCOUNT_APPROVAL_FLAG          -- 重点管理フラグ
      , GL_DATE                        -- 計上日
      , AUTO_TAX_CALC_FLAG             -- 消費税計算レベル
      , AP_TAX_ROUNDING_RULE           -- 消費税端数処理
      , ORG_ID                         -- オルグID
      , SET_OF_BOOKS_ID                -- 会計帳簿ID
      , COMMITMENT_NUMBER              -- 前受金充当番号
      , COMMITMENT_AMOUNT              -- 前受金残高金額
      , PAYMENT_SCHEDULED_DATE         -- 入金予定日
      , ONETIME_CUSTOMER_NAME          -- 顧客名称
      , ONETIME_CUSTOMER_KANA_NAME     -- カナ名
      , ONETIME_CUSTOMER_ADDRESS_1     -- 住所１
      , ONETIME_CUSTOMER_ADDRESS_2     -- 住所２
      , ONETIME_CUSTOMER_ADDRESS_3     -- 住所３
      , COMMITMENT_NAME                -- 摘要
      , COMMITMENT_ORIGINAL_AMOUNT     -- 金額
      , COMMITMENT_DATE_FROM           -- 有効日（自）
      , COMMITMENT_DATE_TO             -- 有効日（至）
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
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
      , DELETE_FLAG
      , FIRST_CUSTOMER_FLAG            -- 一見顧客区分
    )
    VALUES(
        gn_receivable_id                                    -- 伝票ID
      , xx03_if_head_line_rec.HEAD_WF_STATUS                -- ステータス
      , xx03_if_head_line_rec.HEAD_SLIP_TYPE                -- 伝票種別
      , gn_receivable_id                                    -- 伝票番号
      , xx03_if_head_line_rec.HEAD_ENTRY_DATE               -- 起票日
      , NULL                                                -- 申請キー
      , xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_ID      -- 申請者
      , xx03_if_head_line_rec.HEAD_REQUESTOR_PERSON_NAME    -- 申請者名
      , xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID       -- 承認者
      , xx03_if_head_line_rec.HEAD_APPROVER_PERSON_NAME     -- 承認者名
      , NULL                                                -- 申請日
      , NULL                                                -- 承認日
      , NULL                                                -- 否認日
      , NULL                                                -- 経理承認者
      , NULL                                                -- 経理承認日
      , NULL                                                -- AR転送日
      , 0                                                   -- 承認回数
      , NULL                                                -- 承認コメント
      , 'N'                                                 -- 申請可能フラグ
      , 'N'                                                 -- 経理修正フラグ
      , xx03_if_head_line_rec.HEAD_INVOICE_DATE             -- 請求書日付
      , xx03_if_head_line_rec.HEAD_TRANS_TYPE_ID            -- 取引タイプID
      , xx03_if_head_line_rec.HEAD_TRANS_TYPE_NAME          -- 取引タイプ名
      , xx03_if_head_line_rec.HEAD_CUSTOMER_ID              -- 顧客ID
      , xx03_if_head_line_rec.HEAD_CUSTOMER_NAME            -- 顧客名
      , xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_ID       -- 顧客事業所ID
      , xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_NAME     -- 顧客事業所名
      , 0                                                   -- 請求合計金額（E-3で更新）
      , 0                                                   -- 換算済合計金額
      , 0                                                   -- 本体合計金額（E-3で更新）
      , 0                                                   -- 消費税合計金額（E-3で更新）
      , 0                                                   -- 充当金額
      , xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE    -- 通貨
      , xx03_if_head_line_rec.HEAD_CONVERSION_RATE          -- レート
      , xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE       -- レートタイプ
      , xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME  -- レートタイプ名
      , xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_ID        -- 支払方法ID
      , xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_NAME      -- 支払方法名
      , xx03_if_head_line_rec.HEAD_TERMS_ID                 -- 支払条件ID
      , xx03_if_head_line_rec.HEAD_TERMS_NAME               -- 支払条件名
      , xx03_if_head_line_rec.HEAD_DESCRIPTION              -- 備考
      , NULL                                                -- コンテキスト
      , xx03_if_head_line_rec.HEAD_ENTRY_DEPARTMENT         -- 起票部門
      , xx03_if_head_line_rec.HEAD_ENTRY_PERSON_ID          -- 伝票入力者
      , NULL                                                -- 修正元伝票番号
      , 'N'                                                 -- 重点管理フラグ
      , xx03_if_head_line_rec.HEAD_GL_DATE                  -- 計上日
      , xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG       -- 消費税計算レベル
      , xx03_if_head_line_rec.HEAD_TAX_ROUNDING_RULE        -- 消費税端数処理
      , xx03_if_head_line_rec.HEAD_ORG_ID                   -- オルグID
      , xx00_profile_pkg.value(cv_prof_GL_ID)               -- 会計帳簿ID
      , xx03_if_head_line_rec.HEAD_COMMITMENT_NUMBER        -- 前受金充当番号
      , NULL                                                -- 前受金残高金額
      , id_terms_date                                       -- 入金予定日
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_NAME        -- 顧客名称
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_KANA_NAME   -- カナ名
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_ADDRESS_1   -- 住所１
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_ADDRESS_2   -- 住所２
      , xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_ADDRESS_3   -- 住所３
      , NULL                                                -- 摘要
      , 0                                                   -- 金額
      , NULL                                                -- 有効日（自）
      , NULL                                                -- 有効日（至）
      , NULL                                                -- ATTRIBUTE_CATEGORY
      , NULL                                                -- ATTRIBUTE1
      , NULL                                                -- ATTRIBUTE2
      , NULL                                                -- ATTRIBUTE3
      , NULL                                                -- ATTRIBUTE4
      , NULL                                                -- ATTRIBUTE5
      , NULL                                                -- ATTRIBUTE6
      , NULL                                                -- ATTRIBUTE7
      , NULL                                                -- ATTRIBUTE8
      , NULL                                                -- ATTRIBUTE9
      , NULL                                                -- ATTRIBUTE10
      , NULL                                                -- ATTRIBUTE11
      , NULL                                                -- ATTRIBUTE12
      , NULL                                                -- ATTRIBUTE13
      , NULL                                                -- ATTRIBUTE14
      , NULL                                                -- ATTRIBUTE15
      , xx00_global_pkg.user_id                             -- CREATED_BY
      , xx00_date_pkg.get_system_datetime_f                 -- CREATION_DATE
      , xx00_global_pkg.user_id                             -- LAST_UPDATED_BY
      , xx00_date_pkg.get_system_datetime_f                 -- LAST_UPDATE_DATE
      , xx00_global_pkg.login_id                            -- LAST_UPDATE_LOGIN
      , xx00_global_pkg.conc_request_id                     -- REQUEST_ID
      , xx00_global_pkg.prog_appl_id                        -- PROGRAM_APPLICATION_ID
      , xx00_global_pkg.conc_program_id                     -- PROGRAM_ID
      , xx00_date_pkg.get_system_datetime_f                 -- PROGRAM_UPDATE_DATE
      , 'N'                                                 -- 削除フラグ：Y=削除,N=非削除
      , DECODE(xx03_if_head_line_rec.HEAD_ONE_CUSTOMER_NAME, NULL, 'N', 'Y')  -- 一見顧客区分
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
    iv_source     IN  VARCHAR2,     --  1.ソース
    in_request_id IN  NUMBER,       --  2.要求ID
    in_line_count IN  NUMBER,       --  3.明細行数
    on_ent_amount OUT NUMBER,          -- 金額
    ov_errbuf     OUT VARCHAR2,     --  エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --  リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --  ユーザー・エラー・メッセージ --# 固定 #
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
    ln_amount         NUMBER;          -- 金額
--    ln_ent_amount     NUMBER;          -- 金額
    lv_slip_type_name VARCHAR2(4000);  -- 摘要名称
--
    -- ver 11.5.10.2.10G Add Start
    ln_precision      NUMBER;          -- 通貨精度
    -- ver 11.5.10.2.10G Add End
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
    -- 明細ID取得
    SELECT XX03_RECEIVABLE_SLIPS_LINE_S.nextval
    INTO   ln_line_id
    FROM   dual;
--
    -- 金額算出
    -- 入力金額＝単価＊数量
    ln_amount := xx03_if_head_line_rec.LINE_SLIP_LINE_UNIT_PRICE * xx03_if_head_line_rec.LINE_SLIP_LINE_QUANTITY;
--
    -- ver 11.5.10.2.10G Add Start
    -- 通貨精度取得
    SELECT NVL(fc.precision ,0) PRECISION
      INTO ln_precision
      FROM fnd_currencies fc
     WHERE fc.currency_code = xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE
    ;
--
    SELECT ROUND(ln_amount ,ln_precision)
      INTO ln_amount
      FROM Dual
    ;
    -- ver 11.5.10.2.10G Add Start
--
    -- '内税'が'Y'の時
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG = cv_yes ) THEN
      -- 本体金額＝入力金額－消費税額
      on_ent_amount  :=  ln_amount - xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
    -- '内税'が'N'の時
    ELSIF  ( xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG = cv_no ) THEN
      -- 本体金額＝入力金額
      on_ent_amount  :=  ln_amount;
    -- それ以外の時
    ELSE
      -- 内税入力値エラー
      on_ent_amount := 0;
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
--
    -- 明細データ保存
    INSERT INTO XX03_RECEIVABLE_SLIPS_LINE(
        RECEIVABLE_LINE_ID             -- 明細ID
      , RECEIVABLE_ID                  -- 伝票ID
      , LINE_NUMBER                    -- No
      , SLIP_LINE_TYPE                 -- 請求内容ID
      , SLIP_LINE_TYPE_NAME            -- 請求内容
      , SLIP_LINE_UOM                  -- 単位
      , SLIP_LINE_UOM_NAME             -- 単位名
      , SLIP_LINE_UNIT_PRICE           -- 単価
      , SLIP_LINE_QUANTITY             -- 数量
      , SLIP_LINE_ENTERED_AMOUNT       -- 入力金額
      , TAX_CODE                       -- 税区分CODE
      , TAX_NAME                       -- 税区分
      , TAX_ID                         -- 税区分ID
      , AMOUNT_INCLUDES_TAX_FLAG       -- 内税
      , ENTERED_ITEM_AMOUNT            -- 本体金額
      , ENTERED_TAX_AMOUNT             -- 消費税額
      , ACCOUNTED_AMOUNT               -- 換算済金額
      , SLIP_LINE_RECIEPT_NO           -- 納品書番号
      , SLIP_DESCRIPTION               -- 備考（明細）
      , SEGMENT1                       -- 会社
      , SEGMENT2                       -- 部門
      , SEGMENT3                       -- 勘定科目
      , SEGMENT4                       -- 補助科目
      , SEGMENT5                       -- 相手先
      , SEGMENT6                       -- 事業区分
      , SEGMENT7                       -- プロジェクト
      , SEGMENT8                       -- 予備１
      , SEGMENT9
      , SEGMENT10
      , SEGMENT11
      , SEGMENT12
      , SEGMENT13
      , SEGMENT14
      , SEGMENT15
      , SEGMENT16
      , SEGMENT17
      , SEGMENT18
      , SEGMENT19
      , SEGMENT20
      , SEGMENT1_NAME
      , SEGMENT2_NAME
      , SEGMENT3_NAME
      , SEGMENT4_NAME
      , SEGMENT5_NAME
      , SEGMENT6_NAME
      , SEGMENT7_NAME
      , SEGMENT8_NAME
      , INCR_DECR_REASON_CODE          -- 増減事由
      , INCR_DECR_REASON_NAME          -- 増減事由名
      , RECON_REFERENCE                -- 消込参照
      , JOURNAL_DESCRIPTION            -- 備考（仕訳）
      , ORG_ID                         -- オルグID
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
      , CREATED_BY
      , CREATION_DATE
      , LAST_UPDATED_BY
      , LAST_UPDATE_DATE
      , LAST_UPDATE_LOGIN
      , REQUEST_ID
      , PROGRAM_APPLICATION_ID
      , PROGRAM_ID
      , PROGRAM_UPDATE_DATE
    )
    VALUES(
        ln_line_id                                        -- 明細ID
      , gn_receivable_id                                  -- 伝票ID
      , in_line_count                                     -- No
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE         -- 請求内容ID
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME    -- 請求内容
      , xx03_if_head_line_rec.LINE_SLIP_LINE_UOM          -- 単位
      , xx03_if_head_line_rec.LINE_SLIP_LINE_UOM_NAME     -- 単位
      , xx03_if_head_line_rec.LINE_SLIP_LINE_UNIT_PRICE   -- 単価
      , xx03_if_head_line_rec.LINE_SLIP_LINE_QUANTITY     -- 数量
      , ln_amount                                         -- 入力金額
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_CODE     -- 税区分ID
      , xx03_if_head_line_rec.LINE_TAX_NAME               -- 税区分
      , xx03_if_head_line_rec.LINE_VAT_TAX_ID             -- 税区分ID
      , xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG     -- 内税
      , on_ent_amount                                     -- 本体金額
      , xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT     -- 消費税額
      , 0                                                 -- 換算済金額
      , xx03_if_head_line_rec.LINE_SLIP_LINE_RECIEPT_NO   -- 納品書番号
      , xx03_if_head_line_rec.LINE_SLIP_DESCRIPTION       -- 備考（明細）
      , xx03_if_head_line_rec.LINE_SEGMENT1               -- 会社
      , xx03_if_head_line_rec.LINE_SEGMENT2               -- 部門
      , xx03_if_head_line_rec.LINE_SEGMENT3               -- 勘定科目
      , xx03_if_head_line_rec.LINE_SEGMENT4               -- 補助科目
      , xx03_if_head_line_rec.LINE_SEGMENT5               -- 相手先
      , xx03_if_head_line_rec.LINE_SEGMENT6               -- 事業区分
      , xx03_if_head_line_rec.LINE_SEGMENT7               -- プロジェクト
      , xx03_if_head_line_rec.LINE_SEGMENT8               -- 予備１
      , NULL                                              -- SEGMENT9
      , NULL                                              -- SEGMENT10
      , NULL                                              -- SEGMENT11
      , NULL                                              -- SEGMENT12
      , NULL                                              -- SEGMENT13
      , NULL                                              -- SEGMENT14
      , NULL                                              -- SEGMENT15
      , NULL                                              -- SEGMENT16
      , NULL                                              -- SEGMENT17
      , NULL                                              -- SEGMENT18
      , NULL                                              -- SEGMENT19
      , NULL                                              -- SEGMENT20
      , xx03_if_head_line_rec.LINE_SEGMENT1_NAME          -- 会社名
      , xx03_if_head_line_rec.LINE_SEGMENT2_NAME          -- 部門名
      , xx03_if_head_line_rec.LINE_SEGMENT3_NAME          -- 勘定科目名
      , xx03_if_head_line_rec.LINE_SEGMENT4_NAME          -- 補助科目名
      , xx03_if_head_line_rec.LINE_SEGMENT5_NAME          -- 相手先名
      , xx03_if_head_line_rec.LINE_SEGMENT6_NAME          -- 事業区分名
      , xx03_if_head_line_rec.LINE_SEGMENT7_NAME          -- プロジェクト名
      , xx03_if_head_line_rec.LINE_SEGMENT8_NAME          -- 予備１
      , xx03_if_head_line_rec.LINE_INCR_DECR_REASON_CODE  -- 増減事由
      , xx03_if_head_line_rec.LINE_INCR_DECR_REASON_NAME  -- 増減事由名
      , xx03_if_head_line_rec.LINE_RECON_REFERENCE        -- 消込参照
      , xx03_if_head_line_rec.LINE_JOURNAL_DESCRIPTION    -- 備考（仕訳）
      , xx03_if_head_line_rec.LINE_ORG_ID                 -- オルグID
      , NULL                                              -- ATTRIBUTE_CATEGORY
      , NULL                                              -- ATTRIBUTE1
      , NULL                                              -- ATTRIBUTE2
      , NULL                                              -- ATTRIBUTE3
      , NULL                                              -- ATTRIBUTE4
      , NULL                                              -- ATTRIBUTE5
      , NULL                                              -- ATTRIBUTE6
      , NULL                                              -- ATTRIBUTE7
      , NULL                                              -- ATTRIBUTE8
      , NULL                                              -- ATTRIBUTE9
      , NULL                                              -- ATTRIBUTE10
      , NULL                                              -- ATTRIBUTE11
      , NULL                                              -- ATTRIBUTE12
      , NULL                                              -- ATTRIBUTE13
      , NULL                                              -- ATTRIBUTE14
      , NULL                                              -- ATTRIBUTE15
      , xx00_global_pkg.user_id                           -- CREATED_BY
      , xx00_date_pkg.get_system_datetime_f               -- CREATION_DATE
      , xx00_global_pkg.user_id                           -- LAST_UPDATED_BY
      , xx00_date_pkg.get_system_datetime_f               -- LAST_UPDATE_DATE
      , xx00_global_pkg.login_id                          -- LAST_UPDATE_LOGIN
      , xx00_global_pkg.conc_request_id                   -- REQUEST_ID
      , xx00_global_pkg.prog_appl_id                      -- PROGRAM_APPLICATION_ID
      , xx00_global_pkg.conc_program_id                   -- PROGRAM_ID
      , xx00_date_pkg.get_system_datetime_f               -- PROGRAM_UPDATE_DATE
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
  END ins_detail_data;
--
  /**********************************************************************************
   * Procedure Name   : check_header_data
   * Description      : 請求依頼の入力チェック(E-2)
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
-- ver 11.5.10.2.10F Del Start
--    -- 承認者情報カーソル
---- Ver11.5.10.1.6 Chg Start
----    CURSOR xx03_approve_chk_cur(i_person_id NUMBER)
--    CURSOR xx03_approve_chk_cur(i_person_id NUMBER, i_val_dep VARCHAR2)
---- Ver11.5.10.1.6 Chg End
--    IS
--      SELECT
--        count('x') rec_cnt
--      FROM
--        XX03_APPROVER_PERSON_LOV_V xaplv
--      WHERE
--        xaplv.PERSON_ID = i_person_id
---- Ver11.5.10.1.6 Add Start
--      AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
--           or xaplv.PROFILE_VAL_DEP = i_val_dep)
---- Ver11.5.10.1.6 Add End
--    ;
--    -- 承認者情報カーソルレコード型
--    xx03_approve_chk_rec xx03_approve_chk_cur%ROWTYPE;
-- ver 11.5.10.2.10F Del End
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
-- ver 11.5.10.2.10F Chg Start
--      -- 承認者名が入力されている場合は承認ビューにて再チェック
---- Ver11.5.10.1.6 Chg Start
----      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID);
--      OPEN xx03_approve_chk_cur(xx03_if_head_line_rec.HEAD_APPROVER_PERSON_ID ,xx03_if_head_line_rec.HEAD_SLIP_TYPE_APP);
---- Ver11.5.10.1.6 Chg End
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
-- ver 11.5.10.2.10F Chg End
-- Ver11.5.10.1.5B Add End
    END IF;
--
-- ver 11.5.10.2.10 Add Start
    -- 取引タイプチェック
    IF ( xx03_if_head_line_rec.HEAD_TRANS_TYPE_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_TRANS_TYPE_ID) = '' ) THEN
      -- 取引タイプIDが空の場合は取引タイプ入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08048'
        )
      );
    END IF;
-- ver 11.5.10.2.10 Add End
--
    -- 顧客チェック
    IF ( xx03_if_head_line_rec.HEAD_CUSTOMER_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_CUSTOMER_NAME) = '' ) THEN
      -- 顧客が空の場合は顧客入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08029'
        )
      );
    END IF;
--
    -- 顧客事業所チェック
    IF ( xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_CUSTOMER_OFFICE_ID) = '' ) THEN
      -- 顧客事業所が空の場合は顧客事業所入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08030'
        )
      );
    END IF;
--
    -- 請求書日付チェック
    IF ( xx03_if_head_line_rec.HEAD_INVOICE_DATE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_INVOICE_DATE) = '' ) THEN
      -- 請求書日付が空の場合は請求書日付入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08014'
        )
      );
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
-- ver 1.2 Change Start
    -- 支払方法チェック
--    IF ( xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_NAME IS NULL
--           OR TRIM(xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_NAME) = '' ) THEN
    IF ( xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_RECEIPT_METHOD_ID) = '' ) THEN
      -- 支払方法が空の場合は支払方法入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
--          'APP-XX03-08015'
          'APP-XX03-08031'
        )
      );
    END IF;
-- ver 1.2 Change End
--
    -- 支払条件チェック
    IF ( xx03_if_head_line_rec.HEAD_TERMS_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_TERMS_ID) = '' ) THEN
      -- 支払条件IDが空の場合は支払条件入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08017'
        )
      );
    END IF;
--
    -- 通貨チェック
    -- ver 11.5.10.2.10D Chg Start
    --IF ( xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE IS NULL
    --       OR TRIM(xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE) = '' ) THEN
    IF ( xx03_if_head_line_rec.HEAD_CHK_CURRENCY_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_CHK_CURRENCY_CODE) = '' ) THEN
    -- ver 11.5.10.2.10D Chg End
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
    -- 前受金充当伝票番号チェック
    IF (xx03_if_head_line_rec.HEAD_COMMITMENT_NUMBER IS NOT NULL
        AND (xx03_if_head_line_rec.HEAD_COM_TRX_NUMBER IS NULL
             OR TRIM(xx03_if_head_line_rec.HEAD_COM_TRX_NUMBER) = '' )) THEN
      -- 前受金充当伝票が空（取得できない）場合は入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14058'
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
  /**********************************************************************************
   * Procedure Name   : check_detail_data
   * Description      : 請求依頼の入力チェック(E-2)
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
-- ver 11.5.10.2.10 Chg Start
--    -- 請求内容IDチェック
    -- 請求内容名称チェック(マスタに無くIDが存在しなくても自由入力が可能)
-- ver 11.5.10.2.10 Del End
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME IS NULL ) THEN
      -- 請求内容IDが空の場合は請求内容入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08032'
        )
      );
    END IF;
--
    -- 単位チェック
      -- 単位が空の場合は単位入力エラー表示
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_UOM IS NULL ) AND
      ( xx03_if_head_line_rec.LINE_SLIP_LINE_UOM_NAME IS NOT NULL ) THEN
      -- 単位が空で単位名が空でない場合は単位入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08044'
        )
      );
    END IF;
--
    -- 明細消費税額チェック
    IF ( xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT IS NULL ) THEN
      -- 消費税額が空の場合は消費税額入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08034'
        )
      );
    END IF;
--
-- ver 11.5.10.2.10H Add Start
    -- 明細納品書番号文字Byteチェック
    IF LENGTHB(xx03_if_head_line_rec.LINE_SLIP_LINE_RECIEPT_NO) > 30 THEN
      -- 明細納品書番号が30Byteを超える場合は入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-13072'
        )
      );
    END IF;
-- ver 11.5.10.2.10H Add Start
--
-- ver 11.5.10.2.9 Add Start
    -- 明細備考(明細)文字Byteチェック
    IF LENGTHB(xx03_if_head_line_rec.LINE_SLIP_DESCRIPTION) > 30 THEN
      -- 明細備考(明細)が30Byteを超える場合は入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-13071'
        )
      );
    END IF;
-- ver 11.5.10.2.9 Add Start
--
    -- 税区分チェック
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_CODE) = '' ) THEN
      -- 税区分が空の場合は税区分入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08035'
        )
      );
    -- Ver11.5.10.1.5C 2005/10/21 Add Start
    -- 税区分が空でない場合のみ、入力内税区分と入力税区分の内税フラグの一致チェックを行う
    ELSIF (  nvl(xx03_if_head_line_rec.LINE_SLIP_LINE_TAX_FLAG ,'N')
        != nvl(xx03_if_head_line_rec.LINE_MST_TAX_FLAG       ,'N') ) THEN
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08045',
          'TOK_XX03_LINE_TAX_NAME',
          xx03_if_head_line_rec.LINE_TAX_NAME
        )
      );
    -- Ver11.5.10.1.5C 2005/10/21 Add End
    END IF;
--
    -- 会社チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT1 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT1) = '' ) THEN
      -- 会社が空の場合は会社入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08036'
        )
      );
    END IF;
--
    -- 部門チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT2 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT2) = '' ) THEN
      -- 部門が空の場合は部門入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08037'
        )
      );
    END IF;
--
    -- 勘定科目チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT3 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT3) = '' ) THEN
      -- 勘定科目が空もしくは不正の場合は勘定科目入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08038'
        )
      );
  END IF;
--
    -- 補助科目チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT4 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT4) = '' ) THEN
      -- 勘定科目が空の場合は勘定科目入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08039'
        )
      );
    END IF;
--
    -- 相手先チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT5 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT5) = '' ) THEN
      -- 相手先が空の場合は相手先入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08040'
        )
      );
    END IF;
--
    -- 事業区分チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT6 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT6) = '' ) THEN
      -- 事業区分が空の場合は事業区分入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08041'
        )
      );
    END IF;
--
    -- プロジェクトチェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT7 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT7) = '' ) THEN
      -- プロジェクトが空の場合はプロジェクト入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08042'
        )
      );
    END IF;
--
    -- 予備チェック
    IF ( xx03_if_head_line_rec.LINE_SEGMENT8 IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SEGMENT8) = '' ) THEN
      -- 予備が空の場合は予備入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08043'
        )
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
    in_total_item_amount IN  NUMBER,       --  1.合計本体金額
    in_total_tax_amount  IN  NUMBER,       --  2.合計税金金額
    in_commitment_amount IN  NUMBER,       --  3.前払充当金額
    iv_cur_code          IN  VARCHAR2,     --  4.通貨コード
    in_conversion_rate   IN  NUMBER,       --  5.換算レート
    ov_errbuf            OUT VARCHAR2,     --   エラー・メッセージ                  --# 固定 #
    ov_retcode           OUT VARCHAR2,     --   リターン・コード                    --# 固定 #
    ov_errmsg            OUT VARCHAR2)     --   ユーザー・エラー・メッセージ        --# 固定 #
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
    lv_app_upd          VARCHAR2(1);         -- 重点管理フラグ
    ln_accounted_amount NUMBER;
--
    ln_error_cnt   NUMBER;          -- 仕訳チェックエラー件数
    lv_error_flg   VARCHAR2(1);     -- 仕訳チェックエラーフラグ
    lv_error_flg1  VARCHAR2(1);     -- 仕訳チェックエラーフラグ1
    lv_error_msg1  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ1
    lv_error_flg2  VARCHAR2(1);     -- 仕訳チェックエラーフラグ2
    lv_error_msg2  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ2
    lv_error_flg3  VARCHAR2(1);     -- 仕訳チェックエラーフラグ3
    lv_error_msg3  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ3
    lv_error_flg4  VARCHAR2(1);     -- 仕訳チェックエラーフラグ4
    lv_error_msg4  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ4
    lv_error_flg5  VARCHAR2(1);     -- 仕訳チェックエラーフラグ5
    lv_error_msg5  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ5
    lv_error_flg6  VARCHAR2(1);     -- 仕訳チェックエラーフラグ6
    lv_error_msg6  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ6
    lv_error_flg7  VARCHAR2(1);     -- 仕訳チェックエラーフラグ7
    lv_error_msg7  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ7
    lv_error_flg8  VARCHAR2(1);     -- 仕訳チェックエラーフラグ8
    lv_error_msg8  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ8
    lv_error_flg9  VARCHAR2(1);     -- 仕訳チェックエラーフラグ9
    lv_error_msg9  VARCHAR2(5000);  -- 仕訳チェックエラーメッセージ9
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
    --通貨コードが機能通貨でない場合は金額をレート換算して換算済合計金額セット
    ln_accounted_amount := (in_total_item_amount + in_total_tax_amount) - in_commitment_amount;
    IF ( iv_cur_code != gv_cur_code ) THEN
      SELECT TO_NUMBER( TO_CHAR( ln_accounted_amount * in_conversion_rate
                                ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
                       ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
      INTO   ln_accounted_amount
      FROM   dual;
    END IF;
--
    -- ヘッダレコードに金額セット
    UPDATE XX03_RECEIVABLE_SLIPS xrs
    SET    xrs.INV_ITEM_AMOUNT      = in_total_item_amount
         , xrs.INV_TAX_AMOUNT       = in_total_tax_amount
         , xrs.INV_AMOUNT           = (in_total_item_amount + in_total_tax_amount) - in_commitment_amount
         , xrs.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
         , xrs.COMMITMENT_AMOUNT    = in_commitment_amount
    WHERE  xrs.RECEIVABLE_ID   = gn_receivable_id;
--
    -- 重点管理チェック
    xx03_deptinput_ar_check_pkg.set_account_approval_flag(
      gn_receivable_id,
      lv_app_upd,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      -- 結果が正常なら、ヘッダレコードの重点管理フラグを更新
      UPDATE XX03_RECEIVABLE_SLIPS xrs
      SET    xrs.ACCOUNT_APPROVAL_FLAG = lv_app_upd    -- 重点管理フラグ
      WHERE  xrs.RECEIVABLE_ID = gn_receivable_id;
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
    xx03_deptinput_ar_check_pkg.check_deptinput_ar(
      gn_receivable_id,
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
    ln_max_line          NUMBER := xx00_profile_pkg.value('VO_MAX_FETCH_SIZE'); -- 最大明細行数
    lv_max_over_flg      VARCHAR2(1);   -- 最大明細行オーバーフラグ
    ln_interface_id      NUMBER;        -- INTERFACE_ID
    ln_if_id_back        NUMBER;        -- INTERFACE_ID前レコード重複チェック
    lv_if_id_new_flg     VARCHAR2(1);   -- INTERFACE_ID変更フラグ
    lv_first_flg         VARCHAR2(1);   -- 初期レコードフラグ
    ln_total_item_amount NUMBER;        -- 本体金額合計
    ln_total_tax_amount  NUMBER;        -- 本体税金合計
    ln_commitment_amount NUMBER;        -- 前受充当金
    lv_cur_code          VARCHAR2(15);  -- 通貨コード
    ln_conversion_rate   NUMBER;        -- 換算レート
    ln_line_count        NUMBER;        -- 明細件数カウント
    ld_terms_date        DATE;          -- 支払予定日
    lv_terms_flg         VARCHAR2(1);   -- 支払予定日変更可能フラグ
    ln_ent_amount        NUMBER;        -- 金額
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
    -- システム情報カーソルオープン
    OPEN sys_tax_cur;
      FETCH sys_tax_cur INTO sys_tax_rec;
    CLOSE sys_tax_cur;
--
    -- 初期レコードフラグ
    lv_first_flg      := '1';
    ln_if_id_back     := -1;
--
    -- ヘッダ明細情報カーソルオープン
    OPEN xx03_if_head_line_cur(iv_source, in_request_id);
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
              ln_total_item_amount, --  1.本体合計金額
              ln_total_tax_amount,  --  2.税金合計金額
              ln_commitment_amount, --  3.前受充当金額
              lv_cur_code,          --  4.通貨コード
              ln_conversion_rate,   --  5.換算レート
              lv_errbuf,            --  エラー・メッセージ           --# 固定 #
              lv_retcode,           --  リターン・コード             --# 固定 #
              lv_errmsg);           --  ユーザー・エラー・メッセージ --# 固定 #
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
        ln_total_item_amount := 0;
        ln_total_tax_amount  := 0;
--
        -- 明細連番初期化
        ln_line_count  := 1;
--
        -- エラー件数初期化
        gn_error_count := 0;
--
      END IF;
--
      -- ver 11.5.10.2.6B Chg Start
      ---- INTERFACE_ID同一値ヘッダが１件の時はヘッダエラー
      --IF (xx03_if_head_line_rec.CNT_REC_COUNT > 1) THEN
      -- INTERFACE_ID同一値ヘッダが１件の時はもしくは明細No重複時はヘッダエラー
      IF (   (xx03_if_head_line_rec.CNT_REC_COUNT > 1         )
          OR (xx03_if_head_line_rec.CNT2_LINE_SUM_NO_FLG = 'X') )THEN
      -- ver 11.5.10.2.6B Chg End
--
        -- 新ヘッダの場合はエラー情報出力
        IF lv_if_id_new_flg = '1'  THEN
--
          -- ver 11.5.10.2.6B Chg Start
          ---- INTERFACE_ID同一値ヘッダが２件以上
          ---- ステータスをエラーに
          --gv_result := cv_result_error;
          ---- エラー件数加算
          --gn_error_count := gn_error_count + 1;
          --
          ---- INTERFACE_ID出力
          --xx00_file_pkg.output(
          --  xx00_message_pkg.get_msg(
          --    'XX03',
          --    'APP-XX03-08008',
          --    'TOK_XX03_INTERFACE_ID',
          --    xx03_if_head_line_rec.HEAD_INTERFACE_ID
          --  )
          --);
          ---- エラー情報出力
          --xx00_file_pkg.output(
          --  xx00_message_pkg.get_msg(
          --    'XX03',
          --    'APP-XX03-08006'
          --  )
          --);
--
          -- ステータスをエラーに
          gv_result := cv_result_error;
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
--
          -- INTERFACE_ID同一値ヘッダが２件以上
          IF (xx03_if_head_line_rec.CNT_REC_COUNT > 1) THEN
            -- エラー件数加算
            gn_error_count := gn_error_count + 1;
            -- エラー情報出力
            xx00_file_pkg.output(
              xx00_message_pkg.get_msg(
                'XX03',
                'APP-XX03-08006'
              )
            );
          END IF;
--
          -- LINEのNo同一値が２件以上ある
          IF (xx03_if_head_line_rec.CNT2_LINE_SUM_NO_FLG = 'X') THEN
            -- エラー件数加算
            gn_error_count := gn_error_count + 1;
            -- エラー情報出力
            xx00_file_pkg.output(
              xx00_message_pkg.get_msg(
                'XX03',
                'APP-XX03-08046'
              )
            );
          END IF;
          -- ver 11.5.10.2.6B Chg End
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
            -- ===============================
            -- 入金予定日取得(E-4)
            -- ===============================
            xx03_deptinput_ar_check_pkg.get_terms_date(
              xx03_if_head_line_rec.HEAD_TERMS_ID,
              xx03_if_head_line_rec.HEAD_INVOICE_DATE,
              ld_terms_date,
              lv_errbuf,
              lv_retcode,
              lv_errmsg
            );
--
            IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
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
                  'APP-XX03-14101',
                  'TOK_XX03_CHECK_ERROR',
                  lv_errmsg
                )
              );
            END IF;
--
          END IF;
--
          -- エラーが検出されていない時のみ以降の処理実行
          IF ( gn_error_count = 0 ) THEN
            -- ヘッダテーブルへ挿入
            ins_header_data(
              iv_source,         -- ソース
              in_request_id,     -- 要求ID
              ld_terms_date,     -- 支払予定日
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
            ln_line_count,     -- 明細行数
            ln_ent_amount,     --
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
          
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 合計金額算出用変数加算
        ln_total_item_amount := ln_total_item_amount + ln_ent_amount;
        ln_total_tax_amount  := ln_total_tax_amount  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
--
        -- 充当金額計算
        IF ( xx03_if_head_line_rec.HEAD_COMMITMENT_NUMBER IS NOT NULL ) THEN
          -- レコードの充当金額と、本体金額＋消費税額の小さい方を充当金額とする
          IF ( nvl(xx03_if_head_line_rec.HEAD_COM_COMMITMENT_AMOUNT,0) > (ln_total_item_amount + ln_total_tax_amount)) THEN
            ln_commitment_amount := ln_total_item_amount + ln_total_tax_amount;
          ELSE
            ln_commitment_amount := nvl(xx03_if_head_line_rec.HEAD_COM_COMMITMENT_AMOUNT,0);
          END IF;
        ELSE
          -- 充当伝票なし
          ln_commitment_amount := 0;
        END IF;
--
        -- 通貨コード・換算レート
        lv_cur_code        := xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE;
        ln_conversion_rate := xx03_if_head_line_rec.HEAD_CONVERSION_RATE;
--
        -- 明細最大行数チェック
        IF ln_line_count > ln_max_line THEN
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
--
        -- 明細連番加算
        ln_line_count := ln_line_count + 1;
--
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
          ln_total_item_amount, --  1.本体合計金額
          ln_total_tax_amount,  --  2.税金合計金額
          ln_commitment_amount, --  3.前受充当金額
          lv_cur_code,          --  4.通貨コード
          ln_conversion_rate,   --  5.換算レート
          lv_errbuf,            -- エラー・メッセージ           --# 固定 #
          lv_retcode,           -- リターン・コード             --# 固定 #
          lv_errmsg);           -- ユーザー・エラー・メッセージ --# 固定 #
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
   * Description      : 請求書番号管理テーブルの更新
   ***********************************************************************************/
  PROCEDURE update_slip_number(
    in_add_count    IN  NUMBER,       -- 1.更新件数
    ov_slip_code    OUT VARCHAR2,     -- 2.請求書コード
    on_slip_number  OUT NUMBER,       -- 3.請求書番号
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
    -- 現在の請求書番号取得
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --SELECT xsnv.TEMPORARY_CODE,
    --       xsnv.SLIP_NUMBER
    --  INTO lv_slip_code,
    --       ln_slip_number
    --  FROM XX03_SLIP_NUMBERS_V xsnv
    -- WHERE xsnv.APPLICATION_SHORT_NAME = cv_appl_AR_ID
    --   AND xsnv.NUM_TYPE = '0'
    --FOR UPDATE NOWAIT;
    SELECT xsn.TEMPORARY_CODE,
           xsn.SLIP_NUMBER
      INTO lv_slip_code,
           ln_slip_number
      FROM XX03_SLIP_NUMBERS xsn
     WHERE xsn.APPLICATION_SHORT_NAME = cv_appl_AR_ID
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID')
    FOR UPDATE NOWAIT;
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- 請求書番号加算
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --UPDATE XX03_SLIP_NUMBERS_V xsnv
    --   SET xsnv.SLIP_NUMBER = ln_slip_number + in_add_count
    -- WHERE xsnv.APPLICATION_SHORT_NAME = cv_appl_AR_ID
    --   AND xsnv.NUM_TYPE = '0';
    UPDATE XX03_SLIP_NUMBERS xsn
       SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
     WHERE xsn.APPLICATION_SHORT_NAME = cv_appl_AR_ID
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID');
    -- Ver11.5.10.1.6D 2006/01/06 Change End
--
    -- 戻り値セット
    ov_slip_code   := lv_slip_code;
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
      rollback;
    WHEN global_api_expt THEN   -- *** 共通関数例外ハンドラ ***
      ov_errmsg := lv_errmsg;
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      rollback;
    WHEN xx00_global_pkg.global_api_others_expt THEN  -- *** 共通関数OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      rollback;
    WHEN OTHERS THEN  -- *** OTHERS例外ハンドラ ***
      ov_errbuf := SUBSTRB(cv_prg_name||xx00_global_pkg.cv_msg_part||SQLERRM,1,5000);
      ov_retcode := xx00_common_pkg.set_status_error_f;
      rollback;
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
--
    -- *** ローカル変数 ***
    ln_update_count NUMBER;     -- 更新件数
    lv_slip_code VARCHAR2(10);  -- 請求書コード
    ln_slip_number NUMBER;      -- 請求書番号
--
    -- *** ローカル・カーソル ***
    -- 更新対象取得カーソル
    CURSOR update_record_cur
    IS
      SELECT xrs.RECEIVABLE_ID
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.REQUEST_ID = xx00_global_pkg.conc_request_id
      ORDER BY xrs.RECEIVABLE_ID;
--
    -- ログ出力用カーソル
    CURSOR outlog_cur(pv_source VARCHAR2,
                        pn_request_id NUMBER)
    IS
      SELECT xrsi.INTERFACE_ID   as INTERFACE_ID,
             xrs.RECEIVABLE_NUM  as RECEIVABLE_NUM        -- 伝票番号
        FROM XX03_RECEIVABLE_SLIPS_IF xrsi,
             XX03_RECEIVABLE_SLIPS    xrs
       WHERE xrsi.REQUEST_ID    = pn_request_id
         AND xrsi.SOURCE        = pv_source
         AND xrsi.RECEIVABLE_ID = xrs.RECEIVABLE_ID;
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
      SELECT COUNT(xrs.RECEIVABLE_ID)
        INTO ln_update_count
        FROM XX03_RECEIVABLE_SLIPS xrs
       WHERE xrs.REQUEST_ID = xx00_global_pkg.conc_request_id;
--
      -- 請求書番号取得
      update_slip_number(
        ln_update_count,              -- IN  更新件数
        lv_slip_code,                 -- OUT 請求書コード
        ln_slip_number,               -- OUT 請求書番号
        lv_errbuf,                    -- OUT エラー・メッセージ
        lv_retcode,                   -- OUT リターン・コード
        lv_errmsg);                   -- OUT ユーザー・エラー・メッセージ
--
      IF (lv_retcode = xx00_common_pkg.set_status_error_f) THEN
        RAISE global_process_expt;
      ELSIF (lv_retcode = xx00_common_pkg.set_status_warn_f) THEN
        RAISE global_process_expt;
      END IF;
--
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
        -- 請求書番号加算
        ln_slip_number := ln_slip_number + 1;
--
        -- 請求書番号更新
        UPDATE XX03_RECEIVABLE_SLIPS xrs
           SET xrs.RECEIVABLE_NUM = lv_slip_code || TO_CHAR(ln_slip_number)
         WHERE xrs.RECEIVABLE_ID = update_record_rec.RECEIVABLE_ID;
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
            outlog_rec.RECEIVABLE_NUM
          )
        );
--
      END LOOP out_log_loop;
      CLOSE outlog_cur;
--
      -- ver 11.5.10.2.5 Del Start
      ---- インターフェーステーブルデータ削除
      --DELETE FROM XX03_RECEIVABLE_SLIPS_IF xrsi
      --      WHERE xrsi.REQUEST_ID = in_request_id
      --        AND xrsi.SOURCE     = iv_source;
      --
      --DELETE FROM XX03_RECEIVABLE_SLIPS_LINE_IF xrsli
      --      WHERE xrsli.REQUEST_ID = in_request_id
      --        AND xrsli.SOURCE     = iv_source;
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
END XX034RI002C;
/

