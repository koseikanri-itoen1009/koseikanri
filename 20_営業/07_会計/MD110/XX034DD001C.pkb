CREATE OR REPLACE PACKAGE BODY XX034DD001C
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : XX034DD001C(body)
 * Description      : インターフェーステーブルからの請求書データインポート
 * MD.050(CMD.040)  : 部門入力バッチ処理（AP） OCSJ/BFAFIN/MD050/F212
 * MD.070(CMD.050)  : 部門入力（AP）データインポート OCSJ/BFAFIN/MD070/F423
 * Version          : 11.5.10.2.11
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
 *  2004/04/23   1.0            新規作成
 *  2004/04/28   1.1            単体テスト実施結果による修正
 *  2005/02/17   1.2            検索条件の追加【ORG_ID】
 *  2005/04/05   11.5.10.1.0    DELETE_FLAG更新
 *  2005/09/05   11.5.10.1.5    パフォーマンス改善対応
 *  2005/10/19   11.5.10.1.5B   承認者ビューとの結合不具合対応
 *  2005/12/15   11.5.10.1.6    税金コードの有効チェック対応
 *                              ヘッダ明細情報カーソルにて税区分取得時に
 *                              請求書日付において有効な税区分を取得するように変更
 *  2005/12/19   11.5.10.1.6B   承認者の判断基準の修正対応
 *  2005/12/28   11.5.10.1.6C   伝票種別にアプリケーション毎の絞込みを追加
 *  2006/01/06   11.5.10.1.6D   伝票番号の採番条件にオルグを追加
 *  2006/01/20   11.5.10.1.6E   11.5.10.1.5での修正不具合再修正
 *  2006/03/03   11.5.10.1.6F   各タイミングで異なるマスタチェックを同じにする
 *  2006/09/05   11.5.10.2.5    アップロード処理で複数ユーザの同時実行可能とする
 *                              制御の誤り、データ削除処理の誤り修正
 *                              メッセージコードの誤り修正
 *  2006/09/20   11.5.10.2.5B   同時実行を可能とする対応の再修正
 *  2006/10/03   11.5.10.2.6    マスタチェックの見直し(有効日のチェックを請求書日付で
 *                              行なう項目とSYSDATEで行なう項目を再確認)
 *  2007/02/23   11.5.10.2.7    プログラム実行時のユーザ・職責に紐付くメニューに
 *                              登録されている伝票種別かのチェックを追加
 *  2007/07/17   11.5.10.2.10   マスタチェックの追加(明細：増減事由)
 *  2007/08/10   11.5.10.2.10B  摘要コード名称取得のSQLが誤っていることの修正
 *  2007/08/16   11.5.10.2.10C  銀行支店/銀行口座の無効日は前日まで有効とするように修正
 *  2007/10/04   11.5.10.2.10D  振込先口座チェック時に支払方法が電信かどうかという
 *                              判断を行っているが、仕入先サイトの支払方法ではなく
 *                              支払グループのDFF支払方法を使用するように修正
 *  2007/10/10   11.5.10.2.10E  パフォーマンス対応のため承認者のチェックSQLを
 *                              メインSQLへ組み込むように修正
 *  2007/10/17   11.5.10.2.10F  11.5.10.2.10Eにて組み込んだSQLで使用している
 *                              モジュールコードの誤りを修正
 *  2007/10/29   11.5.10.2.10G  通貨の精度チェック(入力可能精度か桁チェック)追加のため
 *                              伝票情報取得時に通貨書式に丸める処理を削除
 *  2016/11/11   11.5.10.2.10H  [E_本稼動_13901]対応 稟議決済番号の追加
 *  2020/02/02   11.5.10.2.10I  障害対応E_本稼動_16026
 *  2021/12/20   11.5.10.2.11   [E_本稼働_17678]対応 電子帳簿保存法改正対応
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
  cv_appli_cd        CONSTANT VARCHAR2(30)  := 'GL';            -- アプリケーション種別2
  cv_package_name    CONSTANT VARCHAR2(20)  := 'XX034DD001';    -- パッケージ名
  cv_yes             CONSTANT VARCHAR2(1)   := 'Y';             -- はい
  cv_no              CONSTANT VARCHAR2(1)   := 'N';             -- いいえ
  cv_dept_normal     CONSTANT VARCHAR2(1)   := 'S';             -- 仕訳チェック結果（正常）
  cv_dept_warning    CONSTANT VARCHAR2(1)   := 'W';             -- 仕訳チェック結果（警告）
  cv_dept_error      CONSTANT VARCHAR2(1)   := 'E';             -- 仕訳チェック結果（エラー）
  cv_result_normal   CONSTANT VARCHAR2(1)   := '0';             -- 終了ステータス（正常）
  cv_result_warning  CONSTANT VARCHAR2(1)   := '1';             -- 終了ステータス（警告）
  cv_result_error    CONSTANT VARCHAR2(1)   := '2';             -- 終了ステータス（エラー）
  -- ver 11.5.10.2.6 Add Start
  cv_paymethod_eft   CONSTANT VARCHAR2(3)   := 'EFT';           -- 仕入先サイト支払方法｢電信｣('EFT')
  -- ver 11.5.10.2.6 Add End
--
  -- ver 11.5.10.2.7 Add Start
  cv_menu_url_inp   CONSTANT VARCHAR2(100) := 'OA.jsp?page=/oracle/apps/xx03/ap/webui/XX03ApInvoiceInputPG';
  -- ver 11.5.10.2.7 Add End
--
  -- ===============================
  -- グローバル変数
  -- ===============================
  gn_invoice_id  NUMBER;              -- 請求書ID
  gn_error_count NUMBER;              -- エラー件数
  gv_result      VARCHAR2(1);         -- チェック結果ステータス
--
-- 20050217 V1.2 START
  gn_org_id      NUMBER;              -- オルグID
-- 20050217 V1.2 END
-- Ver11.5.10.1.5 2005/09/05 Add Start
  gv_cur_code    VARCHAR2(15);        -- 機能通貨コード
-- Ver11.5.10.1.5 2005/09/05 Add End
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
--    SELECT
--      xpsi.INTERFACE_ID as INTERFACE_ID,                        -- インターフェースID
--      xpsi.WF_STATUS as WF_STATUS,                              -- ステータス
--      xstl.LOOKUP_CODE as SLIP_TYPE,                            -- 伝票種別
--      TRUNC(xpsi.ENTRY_DATE, 'DD') as ENTRY_DATE,               -- 起票日
--      xpp.PERSON_ID as REQUESTOR_PERSON_ID,                     -- 申請者
--      xpp.EMPLOYEE_DISP as REQUESTOR_PERSON_NAME,               -- 申請者名
--      xapl.PERSON_ID as APPROVER_PERSON_ID,                     -- 承認者
--      xapl.EMPLOYEE_DISP as APPROVER_PERSON_NAME,               -- 承認者名
--      xpsi.INVOICE_DATE as INVOICE_DATE,                        -- 請求書日付
--      xvl.VENDOR_ID as VENDOR_ID,                               -- 仕入先ID
--      xvl.VENDORS_COL as VENDOR_NAME,                           -- 仕入先名
--      xvsl.VENDOR_SITE_ID as VENDOR_SITE_ID,                    -- 仕入先サイトID
--      xpsi.VENDOR_SITE_CODE as VENDOR_SITE_NAME,                -- 仕入先サイト名
--      xpsi.INVOICE_CURRENCY_CODE as INVOICE_CURRENCY_CODE,      -- 通貨
--      xpsi.EXCHANGE_RATE as EXCHANGE_RATE,                      -- レート
--      xct.CONVERSION_TYPE as EXCHANGE_RATE_TYPE,                -- レートタイプ
--      xpsi.EXCHANGE_RATE_TYPE_NAME as EXCHANGE_RATE_TYPE_NAME,  -- レートタイプ名
--      xatl.TERM_ID as TERMS_ID,                                 -- 支払条件ID
--      xpsi.TERMS_NAME as TERMS_NAME,                            -- 支払条件名
--      xpsi.DESCRIPTION as DESCRIPTION,                          -- 備考
--      xpsi.VENDOR_INVOICE_NUM as VENDOR_INVOICE_NUM,            -- 仕入先請求書番号
--      xpp.ATTRIBUTE28 as ENTRY_DEPARTMENT,                      -- 起票部門
--      xpp2.PERSON_ID as ENTRY_PERSON_ID,                        -- 伝票入力者
--      xapgl.LOOKUP_CODE as PAY_GROUP_LOOKUP_CODE,               -- 支払グループ
--      xpsi.PAY_GROUP_LOOKUP_NAME as PAY_GROUP_LOOKUP_NAME,      -- 支払グループ名
--      xpsi.GL_DATE as GL_DATE,                                  -- 計上日
--      xvsl.AUTO_TAX_CALC_FLAG as AUTO_TAX_CALC_FLAG,            -- 消費税計算レベル
--      xvsl.AP_TAX_ROUNDING_RULE as AP_TAX_ROUNDING_RULE,        -- 消費税端数処理
--      xpsi.PREPAY_NUM as PREPAY_NUM,                            -- 前払金充当伝票番号
--      xpsi.TERMS_DATE as TERMS_DATE,                            -- 支払予定日
--      xatl.ATTRIBUTE1 as TERMS_CHANGE_FLG,                      -- 支払予定日変更可否
--      xpsi.ORG_ID as ORG_ID,                                    -- オルグID
--      xpsi.CREATED_BY as CREATED_BY,
--      xpsi.CREATION_DATE as CREATION_DATE,
--      xpsi.LAST_UPDATED_BY as LAST_UPDATED_BY,
--      xpsi.LAST_UPDATE_DATE as LAST_UPDATE_DATE,
--      xpsi.LAST_UPDATE_LOGIN as LAST_UPDATE_LOGIN,
--      xpsi.REQUEST_ID as REQUEST_ID,
--      xpsi.PROGRAM_APPLICATION_ID as PROGRAM_APPLICATION_ID,
--      xpsi.PROGRAM_ID as PROGRAM_ID,
--      xpsi.PROGRAM_UPDATE_DATE as PROGRAM_UPDATE_DATE
--     FROM
--      XX03_PAYMENT_SLIPS_IF xpsi,
--      XX03_SLIP_TYPES_LOV_V xstl,
--      XX03_PER_PEOPLES_V xpp,
--      XX03_PER_PEOPLES_V xpp2,
--      XX03_APPROVER_PERSON_LOV_V xapl,
--      XX03_VENDORS_LOV_V xvl,
--      XX03_VENDOR_SITES_LOV_V xvsl,
--      XX03_CONVERSION_TYPES_V xct,
--      XX03_AP_TERMS_LOV_V xatl,
--      XX03_AP_PAY_GROUPS_LOV_V xapgl
--     WHERE
--      xpsi.REQUEST_ID = h_request_id
--      AND xpsi.SOURCE = h_source
--      AND xpsi.SLIP_TYPE_NAME = xstl.DESCRIPTION (+)
--      AND xpsi.REQUESTOR_PERSON_NUMBER = xpp.EMPLOYEE_NUMBER (+)
--      AND xpsi.ENTRY_PERSON_NUMBER = xpp2.EMPLOYEE_NUMBER (+)
--      AND xpsi.APPROVER_PERSON_NUMBER = xapl.EMPLOYEE_NUMBER (+)
--      AND xpsi.VENDOR_CODE = xvl.SEGMENT1 (+)
--      AND xpsi.VENDOR_CODE = xvsl.VENDOR_NUMBER (+)
--      AND xpsi.VENDOR_SITE_CODE = xvsl.VENDOR_SITE_CODE (+)
--      AND xpsi.EXCHANGE_RATE_TYPE_NAME = xct.USER_CONVERSION_TYPE (+)
--      AND xpsi.TERMS_NAME = xatl.NAME (+)
--      AND xpsi.PAY_GROUP_LOOKUP_NAME = xapgl.MEANING (+)
--     ORDER BY
--      xpsi.INTERFACE_ID;
----
--  --  ヘッダ情報カーソルレコード型
--  xx03_if_header_rec    xx03_if_header_cur%ROWTYPE;
----
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
-- Ver11.5.10.1.6B Add Start
     , HEAD.SLIP_TYPE_APP          as HEAD_SLIP_TYPE_APP                 -- 伝票種別アプリケーション
-- Ver11.5.10.1.6B Add End
     , HEAD.ENTRY_DATE             as HEAD_ENTRY_DATE                    -- 起票日
     , HEAD.REQUESTOR_PERSON_ID    as HEAD_REQUESTOR_PERSON_ID           -- 申請者
     , HEAD.REQUESTOR_PERSON_NAME  as HEAD_REQUESTOR_PERSON_NAME         -- 申請者名
     , HEAD.APPROVER_PERSON_ID     as HEAD_APPROVER_PERSON_ID            -- 承認者
     , HEAD.APPROVER_PERSON_NAME   as HEAD_APPROVER_PERSON_NAME          -- 承認者名
     , HEAD.INVOICE_DATE           as HEAD_INVOICE_DATE                  -- 請求書日付
     , HEAD.VENDOR_ID              as HEAD_VENDOR_ID                     -- 仕入先ID
     , HEAD.VENDOR_NAME            as HEAD_VENDOR_NAME                   -- 仕入先名
     , HEAD.VENDOR_SITE_ID         as HEAD_VENDOR_SITE_ID                -- 仕入先サイトID
     , HEAD.VENDOR_SITE_NAME       as HEAD_VENDOR_SITE_NAME              -- 仕入先サイト名
     -- ver 11.5.10.2.6 Add Start
     -- ver 11.5.10.2.10D Del Start
     --, HEAD.VENDOR_PAYMETHOD       as HEAD_VENDOR_PAYMETHOD              -- 仕入先サイト支払方法
     -- ver 11.5.10.2.10D Del End
     , HEAD.VENDOR_BANK_NAME       as HEAD_VENDOR_BANK_NAME              -- 仕入先サイト振込先口座名
     -- ver 11.5.10.2.6 Add End
     , HEAD.INVOICE_CURRENCY_CODE  as HEAD_INVOICE_CURRENCY_CODE         -- 通貨
     , HEAD.EXCHANGE_RATE          as HEAD_EXCHANGE_RATE                 -- レート
     , HEAD.EXCHANGE_RATE_TYPE     as HEAD_EXCHANGE_RATE_TYPE            -- レートタイプ
     , HEAD.EXCHANGE_RATE_TYPE_NAME  as HEAD_EXCHANGE_RATE_TYPE_NAME     -- レートタイプ名
     , HEAD.TERMS_ID               as HEAD_TERMS_ID                      -- 支払条件ID
     , HEAD.TERMS_NAME             as HEAD_TERMS_NAME                    -- 支払条件名
     , HEAD.DESCRIPTION            as HEAD_DESCRIPTION                   -- 備考
     , HEAD.VENDOR_INVOICE_NUM     as HEAD_VENDOR_INVOICE_NUM            -- 仕入先請求書番号
     , HEAD.ENTRY_DEPARTMENT       as HEAD_ENTRY_DEPARTMENT              -- 起票部門
     , HEAD.ENTRY_PERSON_ID        as HEAD_ENTRY_PERSON_ID               -- 伝票入力者
     , HEAD.PAY_GROUP_LOOKUP_CODE  as HEAD_PAY_GROUP_LOOKUP_CODE         -- 支払グループ
     , HEAD.PAY_GROUP_LOOKUP_NAME  as HEAD_PAY_GROUP_LOOKUP_NAME         -- 支払グループ名
     -- ver 11.5.10.2.10D Add Start
     , HEAD.PAY_GROUP_PAYMETHOD    as HEAD_PAY_GROUP_PAYMETHOD           -- 支払グループDFF支払方法
     -- ver 11.5.10.2.10D Add End
     , HEAD.GL_DATE                as HEAD_GL_DATE                       -- 計上日
     , HEAD.AUTO_TAX_CALC_FLAG     as HEAD_AUTO_TAX_CALC_FLAG            -- 消費税計算レベル
     , HEAD.AP_TAX_ROUNDING_RULE   as HEAD_AP_TAX_ROUNDING_RULE          -- 消費税端数処理
     , HEAD.PREPAY_NUM             as HEAD_PREPAY_NUM                    -- 前払金充当伝票番号
     , HEAD.PREPAY_INVOICE_NUM     as HEAD_PREPAY_INVOICE_NUM            --
     , HEAD.PREPAY_AMOUNT_APPLIED  as HEAD_PREPAY_AMOUNT_APPLIED         --
     , HEAD.TERMS_DATE             as HEAD_TERMS_DATE                    -- 支払予定日
     , HEAD.TERMS_CHANGE_FLG       as HEAD_TERMS_CHANGE_FLG              -- 支払予定日変更可否
     , HEAD.ORG_ID                 as HEAD_ORG_ID                        -- オルグID
     -- ver 11.5.10.2.11 Add Start
     , HEAD.INVOICE_ELE_DATA_YES   as HEAD_INVOICE_ELE_DATA_YES          -- 請求書電子データ受領あり
     , HEAD.INVOICE_ELE_DATA_NO    as HEAD_INVOICE_ELE_DATA_NO           -- 請求書電子データ受領なし
     -- ver 11.5.10.2.11 Add End
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
     , LINE.SLIP_LINE_TYPE         as LINE_SLIP_LINE_TYPE                -- 摘要コード
     -- ver 11.5.10.1.6F Add Start
     , LINE.SLIP_LINE_TYPE_NAME    as LINE_SLIP_LINE_TYPE_NAME           -- 摘要コード名称
     -- ver 11.5.10.1.6F Add Start
     -- ver 11.5.10.2.10G Chg Start
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_ITEM_AMOUNT
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_ITEM_AMOUNT           -- 本体金額
     --, TO_NUMBER( TO_CHAR( LINE.ENTERED_TAX_AMOUNT
     --                     ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --                     )
     --            ,xx00_currency_pkg.get_format_mask(HEAD.INVOICE_CURRENCY_CODE, 38)
     --            )                 as LINE_ENTERED_TAX_AMOUNT            -- 消費税額
     , LINE.ENTERED_ITEM_AMOUNT    as LINE_ENTERED_ITEM_AMOUNT           -- 本体金額
     , LINE.ENTERED_TAX_AMOUNT     as LINE_ENTERED_TAX_AMOUNT            -- 消費税額
     -- ver 11.5.10.2.10G Chg Start
     , LINE.DESCRIPTION            as LINE_DESCRIPTION                   -- 備考
     , LINE.AMOUNT_INCLUDES_TAX_FLAG  as LINE_AMOUNT_INCLUDES_TAX_FLAG   -- 内税
     , LINE.TAX_CODE               as LINE_TAX_CODE                      -- 税区分
     , LINE.TAX_NAME               as LINE_TAX_NAME                      -- 税区分名
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
-- ver 11.5.10.2.10H Add Start
     , LINE.ATTRIBUTE7             as LINE_ATTRIBUTE7                    -- 稟議決済番号
-- ver 11.5.10.2.10H Add End
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
     -- ver 11.5.10.2.10E Add Start
     , APPROVER.PERSON_ID          as APPROVER_PERSON_ID
     -- ver 11.5.10.2.10E Add End
    FROM
       (SELECT /*+ USE_NL(xpsi) */
           xpsi.INTERFACE_ID           as INTERFACE_ID                       -- インターフェースID
         , xpsi.WF_STATUS              as WF_STATUS                          -- ステータス
         , xstl.LOOKUP_CODE            as SLIP_TYPE                          -- 伝票種別
-- Ver11.5.10.1.6B Add Start
         , xstl.ATTRIBUTE14            as SLIP_TYPE_APP                      -- 伝票種別アプリケーション
-- Ver11.5.10.1.6B Add End
         , TRUNC(xpsi.ENTRY_DATE, 'DD')  as ENTRY_DATE                       -- 起票日
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
         , xpsi.INVOICE_DATE           as INVOICE_DATE                       -- 請求書日付
         , xvl.VENDOR_ID               as VENDOR_ID                          -- 仕入先ID
         , xvl.VENDORS_COL             as VENDOR_NAME                        -- 仕入先名
         , xvsl.VENDOR_SITE_ID         as VENDOR_SITE_ID                     -- 仕入先サイトID
         , xvsl.VENDOR_SITE_CODE       as VENDOR_SITE_NAME                   -- 仕入先サイト名
         -- ver 11.5.10.2.6 Add Start
         -- ver 11.5.10.2.10D Del Start
         --, xvsl.PAYMETHOD              as VENDOR_PAYMETHOD                   -- 仕入先サイト支払方法
         -- ver 11.5.10.2.10D Del End
         , xvsl.BANK_NAME              as VENDOR_BANK_NAME                   -- 仕入先サイト振込先口座名
         -- ver 11.5.10.2.6 Add Start
         , xpsi.INVOICE_CURRENCY_CODE  as INVOICE_CURRENCY_CODE              -- 通貨
         , xpsi.EXCHANGE_RATE          as EXCHANGE_RATE                      -- レート
         , xct.CONVERSION_TYPE         as EXCHANGE_RATE_TYPE                 -- レートタイプ
         , xpsi.EXCHANGE_RATE_TYPE_NAME  as EXCHANGE_RATE_TYPE_NAME          -- レートタイプ名
         , xatl.TERM_ID                as TERMS_ID                           -- 支払条件ID
         , xpsi.TERMS_NAME             as TERMS_NAME                         -- 支払条件名
         , xpsi.DESCRIPTION            as DESCRIPTION                        -- 備考
         , xpsi.VENDOR_INVOICE_NUM     as VENDOR_INVOICE_NUM                 -- 仕入先請求書番号
         , xpp.ATTRIBUTE28             as ENTRY_DEPARTMENT                   -- 起票部門
         , xpp2.PERSON_ID              as ENTRY_PERSON_ID                    -- 伝票入力者
         , xapgl.LOOKUP_CODE           as PAY_GROUP_LOOKUP_CODE              -- 支払グループ
         , xpsi.PAY_GROUP_LOOKUP_NAME  as PAY_GROUP_LOOKUP_NAME              -- 支払グループ名
         -- ver 11.5.10.2.10D Add Start
         , xapgl.ATTRIBUTE1            as PAY_GROUP_PAYMETHOD                -- 支払グループDFF支払方法
         -- ver 11.5.10.2.10D Add End
         , xpsi.GL_DATE                as GL_DATE                            -- 計上日
         , xvsl.AUTO_TAX_CALC_FLAG     as AUTO_TAX_CALC_FLAG                 -- 消費税計算レベル
         , xvsl.AP_TAX_ROUNDING_RULE   as AP_TAX_ROUNDING_RULE               -- 消費税端数処理
         , xpsi.PREPAY_NUM             as PREPAY_NUM                         -- 前払金充当伝票番号
         , xpl.INVOICE_NUM             as PREPAY_INVOICE_NUM                 --
         , xpl.PREPAY_AMOUNT_APPLIED   as PREPAY_AMOUNT_APPLIED              --
         , xpsi.TERMS_DATE             as TERMS_DATE                         -- 支払予定日
         , xatl.ATTRIBUTE1             as TERMS_CHANGE_FLG                   -- 支払予定日変更可否
         , xpsi.ORG_ID                 as ORG_ID                             -- オルグID
-- ver 11.5.10.2.11 Add Start
         , xpsi.INVOICE_ELE_DATA_YES   as INVOICE_ELE_DATA_YES               -- 請求書電子データ受領あり
         , xpsi.INVOICE_ELE_DATA_NO    as INVOICE_ELE_DATA_NO                -- 請求書電子データ受領なし
-- ver 11.5.10.2.11 Add End
         , xpsi.CREATED_BY             as CREATED_BY                         --
         , xpsi.CREATION_DATE          as CREATION_DATE                      --
         , xpsi.LAST_UPDATED_BY        as LAST_UPDATED_BY                    --
         , xpsi.LAST_UPDATE_DATE       as LAST_UPDATE_DATE                   --
         , xpsi.LAST_UPDATE_LOGIN      as LAST_UPDATE_LOGIN                  --
         , xpsi.REQUEST_ID             as REQUEST_ID                         --
         , xpsi.PROGRAM_APPLICATION_ID as PROGRAM_APPLICATION_ID             --
         , xpsi.PROGRAM_ID             as PROGRAM_ID                         --
         , xpsi.PROGRAM_UPDATE_DATE    as PROGRAM_UPDATE_DATE                --
        FROM
           XX03_PAYMENT_SLIPS_IF       xpsi
-- ver 11.5.10.2.7 Chg Start
-- -- Ver11.5.10.1.6C Chg Start
-- -- -- Ver11.5.10.1.6B Chg Start
-- -- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION
-- --         ,(SELECT XLXV.LOOKUP_CODE,XLXV.DESCRIPTION,XLXV.ATTRIBUTE14
-- -- -- Ver11.5.10.1.6B Chg End
-- --           FROM XX03_SLIP_TYPES_V XLXV
-- --           WHERE XLXV.ENABLED_FLAG = 'Y'
-- --          )                           xstl
--          ,(SELECT XSTLV.LOOKUP_CODE,XSTLV.DESCRIPTION,XSTLV.ATTRIBUTE14
--            FROM XX03_SLIP_TYPES_LOV_V XSTLV
--            WHERE XSTLV.ATTRIBUTE14 = 'SQLAP'
--            )                           xstl
-- -- Ver11.5.10.1.6C Chg End
         ,(select XSTLV.LOOKUP_CODE , XSTLV.DESCRIPTION , XSTLV.ATTRIBUTE14
             from XX03_SLIP_TYPES_LOV_V XSTLV , FND_FORM_FUNCTIONS FFF
            where XSTLV.ATTRIBUTE14 = 'SQLAP'
              and (   upper(FFF.PARAMETERS) like '%&SLIPTYPECODE=' || XSTLV.LOOKUP_CODE
                   or upper(FFF.PARAMETERS) like '%&SLIPTYPECODE=' || XSTLV.LOOKUP_CODE || '&%'
                   or upper(FFF.PARAMETERS) like 'SLIPTYPECODE='   || XSTLV.LOOKUP_CODE || '&%' )
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
         ,(SELECT PV.VENDOR_ID , PV.SEGMENT1 , PV.SEGMENT1 || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || PV.VENDOR_NAME VENDORS_COL
           FROM PO_VENDORS PV
           WHERE NVL(PV.END_DATE_ACTIVE, TO_DATE('4712/12/31', 'YYYY/MM/DD')) > TRUNC(SYSDATE)
           )                           xvl
         -- ver 11.5.10.2.6 Chg Start
         --,(SELECT PV.SEGMENT1 VENDOR_NUMBER , PVS.VENDOR_SITE_CODE VENDOR_SITE_CODE , PVS.ATTRIBUTE3 AUTO_TAX_CALC_FLAG
         --       , PVS.AP_TAX_ROUNDING_RULE AP_TAX_ROUNDING_RULE , PVS.VENDOR_SITE_ID VENDOR_SITE_ID
         --  FROM PO_VENDORS PV , PO_VENDOR_SITES_ALL PVS , AP_BANK_ACCOUNT_USES_ALL ABAU
         --  WHERE PV.VENDOR_ID = PVS.VENDOR_ID AND PVS.VENDOR_ID = ABAU.VENDOR_ID(+) AND PVS.VENDOR_SITE_ID = ABAU.VENDOR_SITE_ID(+)
         --    AND 'Y' = ABAU.PRIMARY_FLAG(+) AND PVS.PAY_SITE_FLAG = 'Y' AND PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND PVS.AUTO_TAX_CALC_FLAG = 'N'
         --    AND NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD')) > TRUNC(SYSDATE) AND NVL(ABAU.END_DATE , TO_DATE('4712/12/31', 'YYYY/MM/DD')) > TRUNC(SYSDATE)
         --  )                           xvsl
         ,(SELECT PV.SEGMENT1 VENDOR_NUMBER ,PVS.VENDOR_SITE_CODE VENDOR_SITE_CODE ,PVS.ATTRIBUTE3 AUTO_TAX_CALC_FLAG ,PVS.AP_TAX_ROUNDING_RULE AP_TAX_ROUNDING_RULE
                 -- ver 11.5.10.2.10D Chg Start
                 --,PVS.VENDOR_SITE_ID VENDOR_SITE_ID ,PVS.PAYMENT_METHOD_LOOKUP_CODE PAYMETHOD ,AP_BANK.NAME BANK_NAME
                 ,PVS.VENDOR_SITE_ID VENDOR_SITE_ID ,AP_BANK.NAME BANK_NAME
                 -- ver 11.5.10.2.10D Chg End
             FROM PO_VENDORS PV ,PO_VENDOR_SITES_ALL PVS
                 ,(SELECT ABAU.VENDOR_ID VENDOR_ID ,ABAU.VENDOR_SITE_ID VENDOR_SITE_ID
                         ,NVL2(ABB.BANK_NAME ,ABB.BANK_NAME || ' ' || ABB.BANK_BRANCH_NAME || ' ' || DECODE(ABA.BANK_ACCOUNT_TYPE, '1', '普通', '2', '当座', '')
                                              || ' ' || ABA.BANK_ACCOUNT_NUM ,null) NAME
                     FROM AP_BANK_ACCOUNT_USES_ALL ABAU ,AP_BANK_ACCOUNTS_ALL ABA ,AP_BANK_BRANCHES ABB
                    WHERE ABAU.PRIMARY_FLAG  = 'Y' AND TRUNC(SYSDATE) BETWEEN NVL(ABAU.START_DATE ,TO_DATE('1000/01/01' ,'YYYY/MM/DD')) AND NVL(ABAU.END_DATE ,TO_DATE('4712/12/31' ,'YYYY/MM/DD'))
                      -- ver 11.5.10.2.10C Chg Start
                      --AND ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID AND TRUNC(SYSDATE) <= NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
                      --AND ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID AND TRUNC(SYSDATE) <= NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))  ) AP_BANK
                      AND ABA.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND ABAU.EXTERNAL_BANK_ACCOUNT_ID = ABA.BANK_ACCOUNT_ID AND TRUNC(SYSDATE) < NVL(ABA.INACTIVE_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))
                      AND ABA.BANK_BRANCH_ID = ABB.BANK_BRANCH_ID AND TRUNC(SYSDATE) < NVL(ABB.END_DATE, TO_DATE('4712/12/31','YYYY/MM/DD'))  ) AP_BANK
                      -- ver 11.5.10.2.10C Chg End
            WHERE PV.VENDOR_ID = PVS.VENDOR_ID AND PVS.PAY_SITE_FLAG = 'Y' AND PVS.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID') AND PVS.VENDOR_ID = AP_BANK.VENDOR_ID (+)
              AND PVS.VENDOR_SITE_ID  = AP_BANK.VENDOR_SITE_ID (+) AND TRUNC(SYSDATE) < NVL(PVS.INACTIVE_DATE, TO_DATE('4712/12/31', 'YYYY/MM/DD')) AND PVS.AUTO_TAX_CALC_FLAG = 'N'
           )                           xvsl
         -- ver 11.5.10.2.6 Chg End
         , XX03_CONVERSION_TYPES_V     xct
         ,(SELECT XV.TERM_ID,XV.ATTRIBUTE1,XV.NAME
           FROM XX03_AP_TERMS_V XV
           -- ver 11.5.10.2.6 Chg Start
           --WHERE XV.ENABLED_FLAG = 'Y'  AND NVL(XV.ATTRIBUTE15 ,XX00_PROFILE_PKG.VALUE('ORG_ID')) = XX00_PROFILE_PKG.VALUE('ORG_ID')
           WHERE XV.ENABLED_FLAG = 'Y'
             AND NVL(START_DATE_ACTIVE, TO_DATE('1000/01/01','YYYY/MM/DD')) <= TRUNC(SYSDATE)
             AND TRUNC(SYSDATE) < NVL(END_DATE_ACTIVE  , TO_DATE('4712/12/31','YYYY/MM/DD'))
           -- ver 11.5.10.2.6 Chg End
           )                           xatl
         -- ver 11.5.10.2.10D Chg Start
         --,(SELECT XV.LOOKUP_CODE,XV.MEANING
         ,(SELECT XV.LOOKUP_CODE,XV.MEANING,XV.ATTRIBUTE1
         -- ver 11.5.10.2.10D Add End
           FROM XX03_AP_PAY_GROUPS_V XV
           WHERE XV.ENABLED_FLAG = 'Y'
           -- ver 11.5.10.2.6 Chg Start
             AND TRUNC(SYSDATE) BETWEEN NVL(XV.START_DATE_ACTIVE, TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                    AND NVL(XV.END_DATE_ACTIVE  , TO_DATE('4712/12/31', 'YYYY/MM/DD'))
           -- ver 11.5.10.2.6 Chg End
           )                           xapgl
          ,XX03_PREPAYMENT_LOV_V       xpl
        WHERE
              xpsi.REQUEST_ID               = h_request_id
          AND xpsi.SOURCE                   = h_source
          AND xpsi.SLIP_TYPE_NAME           = xstl.DESCRIPTION         (+)
          AND xpsi.REQUESTOR_PERSON_NUMBER  = xpp.EMPLOYEE_NUMBER      (+)
          AND xpsi.ENTRY_PERSON_NUMBER      = xpp2.EMPLOYEE_NUMBER     (+)
-- Ver11.5.10.1.5B Chg Start
          --AND xpsi.APPROVER_PERSON_NUMBER   = xapl.EMPLOYEE_NUMBER     (+)
          AND xpsi.APPROVER_PERSON_NUMBER   = ppf.EMPLOYEE_NUMBER     (+)
          AND TRUNC(SYSDATE) BETWEEN ppf.effective_start_date(+) AND ppf.effective_end_date(+)
          AND ppf.current_employee_flag(+) = 'Y'
-- Ver11.5.10.1.5B Chg End
          AND xpsi.VENDOR_CODE              = xvl.SEGMENT1             (+)
          AND xpsi.VENDOR_CODE              = xvsl.VENDOR_NUMBER       (+)
          AND xpsi.VENDOR_SITE_CODE         = xvsl.VENDOR_SITE_CODE    (+)
          AND xpsi.EXCHANGE_RATE_TYPE_NAME  = xct.USER_CONVERSION_TYPE (+)
          AND xpsi.TERMS_NAME               = xatl.NAME                (+)
          AND xpsi.PAY_GROUP_LOOKUP_NAME    = xapgl.MEANING            (+)
          AND xpsi.PREPAY_NUM               = xpl.INVOICE_NUM          (+)
        ) HEAD
      ,(SELECT /*+ USE_NL(xpsli) */
           xpsli.INTERFACE_ID          as INTERFACE_ID                       -- インターフェースID
         , xpsli.LINE_NUMBER           as LINE_NUMBER                        -- ラインナンバー
         , xpsli.SLIP_LINE_TYPE        as SLIP_LINE_TYPE                     -- 摘要コード
         -- ver 11.5.10.1.6F Add Start
         , xlxv.SLIP_LINE_TYPE_NAME    as SLIP_LINE_TYPE_NAME                -- 摘要コード名称
         -- ver 11.5.10.1.6F Add Start
         , xpsli.ENTERED_ITEM_AMOUNT   as ENTERED_ITEM_AMOUNT                -- 本体金額
         , xpsli.ENTERED_TAX_AMOUNT    as ENTERED_TAX_AMOUNT                 -- 消費税額
         , xpsli.DESCRIPTION           as DESCRIPTION                        -- 備考
         , xpsli.AMOUNT_INCLUDES_TAX_FLAG  as AMOUNT_INCLUDES_TAX_FLAG       -- 内税
         , xpsli.TAX_CODE              as TAX_CODE                           -- 税区分
         , xtcl.TAX_CODES_COL          as TAX_NAME                           -- 税区分名
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
         , xbtl.BUSINESS_TYPE_COL      as SEGMENT6_NAME                      -- 事業区分名
         , xprl.FLEX_VALUE             as SEGMENT7                           -- プロジェクト
         , xprl.PROJECTS_COL           as SEGMENT7_NAME                      -- プロジェクト名
         , xfl.FLEX_VALUE              as SEGMENT8                           -- 予備
         , xfl.FUTURES_COL             as SEGMENT8_NAME                      -- 予備名
         , xpsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE              -- 増減事由
         , xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME              -- 増減事由名
         , xpsli.RECON_REFERENCE       as RECON_REFERENCE                    -- 消込参照
         , xpsli.ORG_ID                as ORG_ID                             -- オルグID
-- ver 11.5.10.2.10H Add Start
         , xpsli.ATTRIBUTE7            as ATTRIBUTE7                         -- 稟議決済番号
-- ver 11.5.10.2.10H Add End
         , xpsli.CREATED_BY            as CREATED_BY                         --
         , xpsli.CREATION_DATE         as CREATION_DATE                      --
         , xpsli.LAST_UPDATED_BY       as LAST_UPDATED_BY                    --
         , xpsli.LAST_UPDATE_DATE      as LAST_UPDATE_DATE                   --
         , xpsli.LAST_UPDATE_LOGIN     as LAST_UPDATE_LOGIN                  --
         , xpsli.REQUEST_ID            as REQUEST_ID                         --
         , xpsli.PROGRAM_APPLICATION_ID  as PROGRAM_APPLICATION_ID           --
         , xpsli.PROGRAM_ID            as PROGRAM_ID                         --
         , xpsli.PROGRAM_UPDATE_DATE   as PROGRAM_UPDATE_DATE                --
      FROM
         -- Ver11.5.10.1.6 2005/12/15 Change Start
         --  XX03_PAYMENT_SLIP_LINES_IF  xpsli
         --,(SELECT XV.NAME,XV.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION TAX_CODES_COL
         --  FROM XX03_TAX_CODES_V XV
         --  WHERE XV.ENABLED_FLAG = 'Y'
         --  )                           xtcl
         -- ver 11.5.10.1.6F Chg Start
         --  XX03_PAYMENT_SLIPS_IF       xpsi
         --, XX03_PAYMENT_SLIP_LINES_IF  xpsli
         --,(SELECT XV.NAME,XV.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION TAX_CODES_COL,
         --         XV.START_DATE, XV.INACTIVE_DATE
         --  FROM XX03_TAX_CODES_V XV
         --  WHERE XV.ENABLED_FLAG = 'Y'
         --  )                           xtcl
          XX03_PAYMENT_SLIP_LINES_IF  xpsli
         ,(SELECT XV.NAME,XV.NAME || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION TAX_CODES_COL
--                 ,XV.START_DATE, XV.INACTIVE_DATE
                 ,xpsli.INTERFACE_ID
                 ,xpsli.LINE_NUMBER
           FROM XX03_TAX_CODES_V            XV
              , XX03_PAYMENT_SLIPS_IF       xpsi
              , XX03_PAYMENT_SLIP_LINES_IF  xpsli
           WHERE XV.ENABLED_FLAG = 'Y'
             AND xpsli.TAX_CODE = XV.NAME
             AND xpsi.INTERFACE_ID = xpsli.INTERFACE_ID
             AND xpsi.INVOICE_DATE BETWEEN NVL(XV.START_DATE    ,TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                       AND NVL(XV.INACTIVE_DATE ,TO_DATE('4712/12/31', 'YYYY/MM/DD'))
             -- ver 11.5.10.2.5B Add Start
             AND xpsi.REQUEST_ID   = h_request_id
             AND xpsi.SOURCE       = h_source
             AND xpsli.REQUEST_ID  = h_request_id
             AND xpsli.SOURCE      = h_source
             -- ver 11.5.10.2.5B Add End
           )                           xtcl
         -- ver 11.5.10.1.6F Chg End
         -- Ver11.5.10.1.6 2005/12/15 Change End
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
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'  AND XV.ATTRIBUTE5 IS NOT NULL
           )                           xal
         ,(SELECT XV.PARENT_FLEX_VALUE_LOW,XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SUB_ACCOUNTS_COL
           FROM XX03_SUB_ACCOUNTS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xsal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION PARTNERS_COL
           FROM XX03_PARTNERS_V XV
           WHERE XV.SUMMARY_FLAG = 'N'  AND XV.ENABLED_FLAG = 'Y'  AND SUBSTRB(XV.COMPILED_VALUE_ATTRIBUTES, 3, 1) = 'Y'
           )                           xpal
         ,(SELECT XV.FLEX_VALUE,XV.FLEX_VALUE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION BUSINESS_TYPE_COL
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
         -- ver 11.5.10.1.6F Add Start
         -- ver 11.5.10.2.10B Chg Start
         --,(SELECT XV.LOOKUP_CODE LOOKUP_CODE ,XV.DESCRIPTION SLIP_LINE_TYPE_NAME
         ,(SELECT XV.LOOKUP_CODE LOOKUP_CODE
                 ,XV.LOOKUP_CODE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || XV.DESCRIPTION SLIP_LINE_TYPE_NAME
         -- ver 11.5.10.2.10B Chg End
--                 ,XV.START_DATE_ACTIVE START_DATE_ACTIVE ,XV.END_DATE_ACTIVE END_DATE_ACTIVE
                 ,xpsli.INTERFACE_ID
                 ,xpsli.LINE_NUMBER
           FROM XX03_LOOKUPS_XX03_V         XV
              , XX03_PAYMENT_SLIPS_IF       xpsi
              , XX03_PAYMENT_SLIP_LINES_IF  xpsli
           WHERE  XV.LANGUAGE = USERENV('LANG')  AND XV.LOOKUP_TYPE = 'XX03_SLIP_LINE_TYPES'  AND XV.ATTRIBUTE15 = XX00_PROFILE_PKG.VALUE('ORG_ID')  AND XV.ENABLED_FLAG = 'Y'
             AND xpsi.INTERFACE_ID    = xpsli.INTERFACE_ID
             AND xpsli.SLIP_LINE_TYPE = XV.LOOKUP_CODE
             AND xpsi.INVOICE_DATE BETWEEN NVL(XV.START_DATE_ACTIVE ,TO_DATE('1000/01/01', 'YYYY/MM/DD'))
                                       AND NVL(XV.END_DATE_ACTIVE   ,TO_DATE('4712/12/31', 'YYYY/MM/DD'))
             -- ver 11.5.10.2.5B Add Start
             AND xpsi.REQUEST_ID   = h_request_id
             AND xpsi.SOURCE       = h_source
             AND xpsli.REQUEST_ID  = h_request_id
             AND xpsli.SOURCE      = h_source
             -- ver 11.5.10.2.5B Add End
           )                           xlxv
         -- ver 11.5.10.1.6F Add End
      WHERE
            xpsli.REQUEST_ID                = h_request_id
        AND xpsli.SOURCE                    = h_source
        -- ver 11.5.10.1.6F Chg Start
        --AND xpsli.TAX_CODE                  = xtcl.NAME                   (+)
        ---- Ver11.5.10.1.6 2005/12/15 Add Start
        --AND xpsi.INTERFACE_ID               = xpsli.INTERFACE_ID
        --AND xpsi.INVOICE_DATE BETWEEN NVL(xtcl.START_DATE    ,TO_DATE('1000/01/01', 'YYYY/MM/DD'))
        --                          AND NVL(xtcl.INACTIVE_DATE ,TO_DATE('4712/12/31', 'YYYY/MM/DD'))
        AND xpsli.INTERFACE_ID              = xtcl.INTERFACE_ID           (+)
        AND xpsli.LINE_NUMBER               = xtcl.LINE_NUMBER            (+)
        ---- Ver11.5.10.1.6 2005/12/15 Add End
        -- ver 11.5.10.1.6F Chg End
        AND xpsli.SEGMENT1                  = xcl.FLEX_VALUE              (+)
        AND xpsli.SEGMENT2                  = xdl.FLEX_VALUE              (+)
        AND xpsli.SEGMENT3                  = xal.FLEX_VALUE              (+)
        AND xpsli.SEGMENT3                  = xsal.PARENT_FLEX_VALUE_LOW  (+)
        AND xpsli.SEGMENT4                  = xsal.FLEX_VALUE             (+)
        AND xpsli.SEGMENT5                  = xpal.FLEX_VALUE             (+)
        AND xpsli.SEGMENT6                  = xbtl.FLEX_VALUE             (+)
        AND xpsli.SEGMENT7                  = xprl.FLEX_VALUE             (+)
        AND xpsli.SEGMENT8                  = xfl.FLEX_VALUE              (+)
        AND xpsli.SEGMENT3                  = xidrl.PARENT_FLEX_VALUE_LOW (+)
        AND xpsli.INCR_DECR_REASON_CODE     = xidrl.FLEX_VALUE            (+)
        -- ver 11.5.10.1.6F Add Start
        AND xpsli.INTERFACE_ID              = xlxv.INTERFACE_ID           (+)
        AND xpsli.LINE_NUMBER               = xlxv.LINE_NUMBER            (+)
        -- ver 11.5.10.1.6F Add End
        ) LINE
      ,(SELECT /*+ USE_NL(xpsic) */
               xpsic.INTERFACE_ID         as INTERFACE_ID
              ,COUNT(xpsic.INTERFACE_ID)  as REC_COUNT
        FROM   XX03_PAYMENT_SLIPS_IF xpsic
        WHERE  xpsic.REQUEST_ID = h_request_id
          AND  xpsic.SOURCE     = h_source
        GROUP BY xpsic.INTERFACE_ID
        ) CNT
      -- ver 11.5.10.2.10E Add Start
      ,(SELECT /*+ USE_NL(xpsi) */
           xpsi.INTERFACE_ID as INTERFACE_ID
          ,ppf.PERSON_ID     as PERSON_ID
        FROM
           XX03_PAYMENT_SLIPS_IF xpsi
         ,(SELECT employee_number ,person_id FROM PER_PEOPLE_F
           WHERE current_employee_flag = 'Y' AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
           ) ppf
        WHERE
              xpsi.APPROVER_PERSON_NUMBER = ppf.EMPLOYEE_NUMBER
          -- ver 11.5.10.2.10I Add Start
          AND  xpsi.request_id             = h_request_id
          AND  xpsi.source                 = h_source
          -- ver 11.5.10.2.10I Add End
          AND EXISTS (SELECT '1'
                      FROM   XX03_APPROVER_PERSON_LOV_V xaplv
                      WHERE  xaplv.PERSON_ID = ppf.person_id
                        AND (   xaplv.PROFILE_VAL_DEP = 'ALL'
                      -- ver 11.5.10.2.10F Chg Start
                      --       or xaplv.PROFILE_VAL_DEP = 'SQLGL')
                             or xaplv.PROFILE_VAL_DEP = 'SQLAP')
                      -- ver 11.5.10.2.10F Chg End
                      )
        ) APPROVER
      -- ver 11.5.10.2.10E Add End
    WHERE
          HEAD.INTERFACE_ID = LINE.INTERFACE_ID
      AND HEAD.INTERFACE_ID = CNT.INTERFACE_ID
      -- ver 11.5.10.2.10E Add Start
      AND HEAD.INTERFACE_ID = APPROVER.INTERFACE_ID(+)
      -- ver 11.5.10.2.10E Add End
    ORDER BY
       HEAD.INTERFACE_ID ,LINE.LINE_NUMBER
    ;
--
    -- ヘッダ明細情報カーソルレコード型
    xx03_if_head_line_rec  xx03_if_head_line_cur%ROWTYPE;
--
-- Ver11.5.10.1.5 2005/09/05 Add End
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
  same_id_header_expt      EXCEPTION;     -- ヘッダレコード重複あり
  get_slip_type_expt       EXCEPTION;     -- 伝票種別入力値なし
  get_approver_expt        EXCEPTION;     -- 承認者入力値なし
  get_vendor_expt          EXCEPTION;     -- 仕入先入力値なし
  get_vendor_site_expt     EXCEPTION;     -- 仕入先サイト入力値なし
  get_invoice_date_expt    EXCEPTION;     -- 請求書日付入力値なし
  get_gl_date_expt         EXCEPTION;     -- 計上日入力値なし
  get_pay_group_expt       EXCEPTION;     -- 支払グループ入力値なし
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
-- Ver11.5.10.1.5 2005/09/05 Change Start
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
--    ln_amount NUMBER;      -- 金額
--    lv_slip_type_name VARCHAR2(4000);  -- 摘要名称
----
--    -- ===============================
--    -- ローカル・カーソル
--    -- ===============================
--    -- 明細情報カーソル
--    CURSOR xx03_if_detail_cur(h_source VARCHAR2,
--                                h_request_id NUMBER,
--                                h_interface_id NUMBER,
--                                h_currency_code VARCHAR2)
--    IS
--      SELECT
--        xpsli.INTERFACE_ID as INTERFACE_ID,                           -- インターフェースID
--        xpsli.SLIP_LINE_TYPE as SLIP_LINE_TYPE,                       -- 摘要コード
--        TO_NUMBER(TO_CHAR(xpsli.ENTERED_ITEM_AMOUNT,
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--                 ) as ENTERED_ITEM_AMOUNT,                           -- 本体金額
--        TO_NUMBER(TO_CHAR(xpsli.ENTERED_TAX_AMOUNT,
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)),
--                    xx00_currency_pkg.get_format_mask(h_currency_code, 38)
--                 ) as ENTERED_TAX_AMOUNT,                            -- 消費税額
--        xpsli.DESCRIPTION as DESCRIPTION,                             -- 備考
--        xpsli.AMOUNT_INCLUDES_TAX_FLAG as AMOUNT_INCLUDES_TAX_FLAG,   -- 内税
--        xpsli.TAX_CODE as TAX_CODE,                                   -- 税区分
--        xtcl.TAX_CODES_COL as TAX_NAME,                               -- 税区分名
--        xpsli.SEGMENT1 as SEGMENT1,                                   -- 会社
--        xpsli.SEGMENT2 as SEGMENT2,                                   -- 部門
--        xpsli.SEGMENT3 as SEGMENT3,                                   -- 勘定科目
--        xpsli.SEGMENT4 as SEGMENT4,                                   -- 補助科目
--        xpsli.SEGMENT5 as SEGMENT5,                                   -- 相手先
--        xpsli.SEGMENT6 as SEGMENT6,                                   -- 事業区分
--        xpsli.SEGMENT7 as SEGMENT7,                                   -- プロジェクト
--        xpsli.SEGMENT8 as SEGMENT8,                                   -- 予備
--        xcl.COMPANIES_COL as SEGMENT1_NAME,                           -- 会社名
--        xdl.DEPARTMENTS_COL as SEGMENT2_NAME,                         -- 部門名
--        xal.ACCOUNTS_COL as SEGMENT3_NAME,                            -- 勘定科目名
--        xsal.SUB_ACCOUNTS_COL as SEGMENT4_NAME,                       -- 補助科目名
--        xpal.PARTNERS_COL as SEGMENT5_NAME,                           -- 相手先名
--        xbtl.BUSINESS_TYPES_COL as SEGMENT6_NAME,                     -- 事業区分名
--        xprl.PROJECTS_COL as SEGMENT7_NAME,                           -- プロジェクト名
--        xpsli.SEGMENT8 as SEGMENT8_NAME,                              -- 予備
--        xpsli.INCR_DECR_REASON_CODE as INCR_DECR_REASON_CODE,         -- 増減事由
--        xidrl.INCR_DECR_REASONS_COL as INCR_DECR_REASON_NAME,         -- 増減事由名
--        xpsli.RECON_REFERENCE as RECON_REFERENCE,                     -- 消込参照
--        xpsli.ORG_ID as ORG_ID,                                       -- オルグID
--        xpsli.CREATED_BY,
--        xpsli.CREATION_DATE,
--        xpsli.LAST_UPDATED_BY,
--        xpsli.LAST_UPDATE_DATE,
--        xpsli.LAST_UPDATE_LOGIN,
--        xpsli.REQUEST_ID,
--        xpsli.PROGRAM_APPLICATION_ID,
--        xpsli.PROGRAM_ID,
--        xpsli.PROGRAM_UPDATE_DATE
--      FROM
--        XX03_PAYMENT_SLIP_LINES_IF xpsli,
--        XX03_TAX_CODES_LOV_V xtcl,
--        XX03_COMPANIES_LOV_V xcl,
--        XX03_DEPARTMENTS_LOV_V xdl,
--        XX03_ACCOUNTS_LOV_V xal,
--        XX03_SUB_ACCOUNTS_LOV_V xsal,
--        XX03_PARTNERS_LOV_V xpal,
--        XX03_BUSINESS_TYPES_LOV_V xbtl,
--        XX03_PROJECTS_LOV_V xprl,
--        XX03_INCR_DECR_REASONS_LOV_V xidrl
--      WHERE
--        xpsli.REQUEST_ID = h_request_id
--        AND xpsli.SOURCE = h_source
--        AND xpsli.INTERFACE_ID = h_interface_id
--        AND xpsli.TAX_CODE = xtcl.NAME (+)
--        AND xpsli.SEGMENT1 = xcl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT2 = xdl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT3 = xal.FLEX_VALUE (+)
--        AND xpsli.SEGMENT4 = xsal.FLEX_VALUE (+)
--        AND xpsli.SEGMENT3 = xsal.PARENT_FLEX_VALUE_LOW (+)
--        AND xpsli.SEGMENT5 = xpal.FLEX_VALUE (+)
--        AND xpsli.SEGMENT6 = xbtl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT7 = xprl.FLEX_VALUE (+)
--        AND xpsli.INCR_DECR_REASON_CODE = xidrl.FLEX_VALUE (+)
--        AND xpsli.SEGMENT3 = xidrl.PARENT_FLEX_VALUE_LOW (+)
--      ORDER BY
--        xpsli.LINE_NUMBER;
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
----
--    -- 明細連番初期化
--    ln_line_count := 1;
--    -- 明細情報カーソルオープン
--    OPEN xx03_if_detail_cur(iv_source,
--                              in_request_id,
--                              xx03_if_header_rec.INTERFACE_ID,
--                              xx03_if_header_rec.INVOICE_CURRENCY_CODE);
--    <<xx03_if_detail_loop>>
--    LOOP
--      FETCH xx03_if_detail_cur INTO xx03_if_detail_rec;
--      IF xx03_if_detail_cur%NOTFOUND THEN
--        -- 対象データがなくなるまでループ
--        EXIT xx03_if_detail_loop;
--      END IF;
----
--      -- 明細ID取得
--      SELECT XX03_PAYMENT_SLIP_LINES_S.nextval
--        INTO ln_line_id
--        FROM dual;
----
--      -- 摘要名称取得
--      BEGIN
--        SELECT xsltl.SLIP_LINE_TYPES_COL as SLIP_LINE_TYPE_NAME
--          INTO lv_slip_type_name
--          FROM XX03_SLIP_LINE_TYPES_LOV_V xsltl
--         WHERE xsltl.LOOKUP_CODE = xx03_if_detail_rec.SLIP_LINE_TYPE
--           AND xsltl.VENDOR_SITE_ID = xx03_if_header_rec.VENDOR_SITE_ID;
--      EXCEPTION
--        WHEN NO_DATA_FOUND THEN
--          -- 対象データなし時は摘要名称空
--          lv_slip_type_name := '';
--          -- ステータスをエラーに
--          gv_result := cv_result_error;
--          -- エラー件数加算
--          gn_error_count := gn_error_count + 1;
--          xx00_file_pkg.output(
--            xx00_message_pkg.get_msg(
--              'XX03',
--              'APP-XX03-08026',
--              'TOK_XX03_LINE_NUMBER',
--              ln_line_count
--            )
--          );
--      END;
----
--      -- 金額算出
--      IF ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG = cv_yes ) THEN
--        -- '内税'が'Y'の時は金額は'本体金額+消費税額'
--        ln_amount := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT +
--                      xx03_if_detail_rec.ENTERED_TAX_AMOUNT;
--      ELSIF  ( xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG = cv_no ) THEN
--        -- '内税'が'N'の時は金額は'本体金額'
--        ln_amount := xx03_if_detail_rec.ENTERED_ITEM_AMOUNT;
--      ELSE
--        -- それ以外の時は内税入力値エラー
--        ln_amount := 0;
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
--      INSERT INTO XX03_PAYMENT_SLIP_LINES(
--        INVOICE_LINE_ID           ,
--        INVOICE_ID                ,
--        LINE_NUMBER               ,
--        SLIP_LINE_TYPE            ,
--        SLIP_LINE_TYPE_NAME       ,
--        ENTERED_AMOUNT            ,
--        ENTERED_ITEM_AMOUNT       ,
--        ENTERED_TAX_AMOUNT        ,
--        DESCRIPTION               ,
--        AMOUNT_INCLUDES_TAX_FLAG  ,
--        TAX_CODE                  ,
--        TAX_NAME                  ,
--        SEGMENT1                  ,
--        SEGMENT2                  ,
--        SEGMENT3                  ,
--        SEGMENT4                  ,
--        SEGMENT5                  ,
--        SEGMENT6                  ,
--        SEGMENT7                  ,
--        SEGMENT8                  ,
--        SEGMENT9                  ,
--        SEGMENT10                 ,
--        SEGMENT11                 ,
--        SEGMENT12                 ,
--        SEGMENT13                 ,
--        SEGMENT14                 ,
--        SEGMENT15                 ,
--        SEGMENT16                 ,
--        SEGMENT17                 ,
--        SEGMENT18                 ,
--        SEGMENT19                 ,
--        SEGMENT20                 ,
--        SEGMENT1_NAME             ,
--        SEGMENT2_NAME             ,
--        SEGMENT3_NAME             ,
--        SEGMENT4_NAME             ,
--        SEGMENT5_NAME             ,
--        SEGMENT6_NAME             ,
--        SEGMENT7_NAME             ,
--        SEGMENT8_NAME             ,
--        INCR_DECR_REASON_CODE     ,
--        INCR_DECR_REASON_NAME     ,
--        RECON_REFERENCE           ,
--        ORG_ID                    ,
--        ATTRIBUTE_CATEGORY        ,
--        ATTRIBUTE1                ,
--        ATTRIBUTE2                ,
--        ATTRIBUTE3                ,
--        ATTRIBUTE4                ,
--        ATTRIBUTE5                ,
--        ATTRIBUTE6                ,
--        ATTRIBUTE7                ,
--        ATTRIBUTE8                ,
--        ATTRIBUTE9                ,
--        ATTRIBUTE10               ,
--        ATTRIBUTE11               ,
--        ATTRIBUTE12               ,
--        ATTRIBUTE13               ,
--        ATTRIBUTE14               ,
--        ATTRIBUTE15               ,
--        CREATED_BY                ,
--        CREATION_DATE             ,
--        LAST_UPDATED_BY           ,
--        LAST_UPDATE_DATE          ,
--        LAST_UPDATE_LOGIN         ,
--        REQUEST_ID                ,
--        PROGRAM_APPLICATION_ID    ,
--        PROGRAM_ID                ,
--        PROGRAM_UPDATE_DATE
--      )
--      VALUES(
--        ln_line_id,
--        gn_invoice_id,
--        ln_line_count,
--        xx03_if_detail_rec.SLIP_LINE_TYPE,
--        lv_slip_type_name,
--        ln_amount,
--        xx03_if_detail_rec.ENTERED_ITEM_AMOUNT,
--        xx03_if_detail_rec.ENTERED_TAX_AMOUNT,
--        xx03_if_detail_rec.DESCRIPTION,
--        xx03_if_detail_rec.AMOUNT_INCLUDES_TAX_FLAG,
--        xx03_if_detail_rec.TAX_CODE,
--        xx03_if_detail_rec.TAX_NAME,
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
--      ln_line_count := ln_line_count + 1;
----
--    END LOOP xx03_if_detail_loop;
--    CLOSE xx03_if_detail_cur;
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
--   * Description      : 請求書データの入力チェック(E-2)
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
--    -- 仕入先チェック
--    IF ( xx03_if_header_rec.VENDOR_ID IS NULL
--           OR TRIM(xx03_if_header_rec.VENDOR_ID) = '' ) THEN
--      -- 仕入先IDが空の場合は仕入先入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08012'
--        )
--      );
--    END IF;
----
--    -- 仕入先サイトチェック
--    IF ( xx03_if_header_rec.VENDOR_SITE_ID IS NULL
--           OR TRIM(xx03_if_header_rec.VENDOR_SITE_ID) = '' ) THEN
--      -- 仕入先サイトIDが空の場合は仕入先サイト入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08013'
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
--    -- 支払グループチェック
--    IF ( xx03_if_header_rec.PAY_GROUP_LOOKUP_CODE IS NULL
--           OR TRIM(xx03_if_header_rec.PAY_GROUP_LOOKUP_CODE) = '' ) THEN
--      -- 支払グループが空の場合は支払グループ入力エラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08016'
--        )
--      );
--    END IF;
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
--    -- 支払条件、支払予定日関連性チェック
--    IF (( xx03_if_header_rec.TERMS_CHANGE_FLG = cv_yes
--          AND ( xx03_if_header_rec.TERMS_DATE IS NULL
--                OR TRIM(xx03_if_header_rec.TERMS_DATE) = ''))
--        OR ( xx03_if_header_rec.TERMS_CHANGE_FLG = cv_no
--          AND ( xx03_if_header_rec.TERMS_DATE IS NOT NULL
--                OR TRIM(xx03_if_header_rec.TERMS_DATE) <> ''))) THEN
--      -- 支払予定日変更不可で入力あり、もしくは支払予定日変更可で入力なしはエラー表示
--      -- ステータスをエラーに
--      gv_result := cv_result_error;
--      -- エラー件数加算
--      gn_error_count := gn_error_count + 1;
--      xx00_file_pkg.output(
--        xx00_message_pkg.get_msg(
--          'XX03',
--          'APP-XX03-08019'
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
--    ln_prepay_amount NUMBER;     -- 前払金額
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
---- 20050217 V1.2 START
---- 条件追加【ORG_ID】
--    -- 本体金額合計算出
--    SELECT SUM(xpsl.ENTERED_ITEM_AMOUNT) as ENTERED_ITEM_AMOUNT
--      INTO ln_total_item_amount
--      FROM XX03_PAYMENT_SLIP_LINES xpsl
--     WHERE xpsl.INVOICE_ID = gn_invoice_id
--       AND xpsl.ORG_ID = gn_org_id
--    GROUP BY xpsl.INVOICE_ID;
----
--    -- ヘッダレコードに本体合計金額セット
--    UPDATE XX03_PAYMENT_SLIPS xps
--       SET xps.INV_ITEM_AMOUNT = ln_total_item_amount
--     WHERE xps.INVOICE_ID = gn_invoice_id
--       AND xps.ORG_ID = gn_org_id;
----
--    -- 消費税額合計
--    SELECT SUM(xpsl.ENTERED_TAX_AMOUNT) as ENTERED_TAX_AMOUNT
--      INTO ln_total_tax_amount
--      FROM XX03_PAYMENT_SLIP_LINES xpsl
--     WHERE xpsl.INVOICE_ID = gn_invoice_id
--       AND xpsl.ORG_ID = gn_org_id
--    GROUP BY xpsl.INVOICE_ID;
----
--    -- ヘッダレコードに本体合計金額セット
--    UPDATE XX03_PAYMENT_SLIPS xps
--       SET xps.INV_TAX_AMOUNT = ln_total_tax_amount
--     WHERE xps.INVOICE_ID = gn_invoice_id
--       AND xps.ORG_ID = gn_org_id;
----
--    -- 充当金額計算
--    IF ( xx03_if_header_rec.PREPAY_NUM IS NOT NULL ) THEN
--      -- 充当伝票あり
--      BEGIN
--        SELECT xpl.PREPAY_AMOUNT_APPLIED
--          INTO ln_prepay_amount
--          FROM XX03_PREPAYMENT_LOV_V xpl
--         WHERE xpl.INVOICE_NUM = xx03_if_header_rec.PREPAY_NUM;
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
--      IF ( ln_prepay_amount > (ln_total_item_amount + ln_total_tax_amount)) THEN
--        ln_prepay_amount := ln_total_item_amount + ln_total_tax_amount;
--      END IF;
---- 20050217 V1.2 START
---- 条件追加【ORG_ID】
--      -- ヘッダレコードに充当金額セット
--      UPDATE XX03_PAYMENT_SLIPS xps
--         SET xps.INV_PREPAY_AMOUNT = ln_prepay_amount
--       WHERE xps.INVOICE_ID = gn_invoice_id
--         AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
--    ELSE
--      -- 充当伝票なし
--      ln_prepay_amount := 0;
--    END IF;
----
---- 20050217 V1.2 START
---- 条件追加【ORG_ID】
--    -- 支払金額計算
--    -- ヘッダレコードに支払金額セット
--    UPDATE XX03_PAYMENT_SLIPS xps
--       SET xps.INV_AMOUNT = (ln_total_item_amount + ln_total_tax_amount) - ln_prepay_amount
--     WHERE xps.INVOICE_ID = gn_invoice_id
--       AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
----
--   -- 換算済合計金額計算
--   -- 機能通貨コード取得
--   SELECT gsob.currency_code
--     INTO lv_cur_code
--     FROM gl_sets_of_books gsob
--    WHERE gsob.set_of_books_id = xx00_profile_pkg.value('GL_SET_OF_BKS_ID');
----
--   IF ( xx03_if_header_rec.INVOICE_CURRENCY_CODE = lv_cur_code ) THEN
---- 20050217 V1.2 START
---- 条件追加【ORG_ID】
--     --通貨コードが機能通貨の場合は換算済合計金額に支払金額をセット
--     UPDATE XX03_PAYMENT_SLIPS xps
--        SET xps.INV_ACCOUNTED_AMOUNT = (ln_total_item_amount + ln_total_tax_amount)
--                                         - ln_prepay_amount
--      WHERE xps.INVOICE_ID = gn_invoice_id
--        AND xps.ORG_ID = org_id;
---- 20050217 V1.2 END
--   ELSE
--     --通貨コードが機能通貨でない場合は支払金額をレート換算して換算済合計金額セット
--     SELECT TO_NUMBER(
--              TO_CHAR(
--                (((ln_total_item_amount + ln_total_tax_amount) - ln_prepay_amount)
--                  * xx03_if_header_rec.EXCHANGE_RATE),
--                xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--              ),
--              xx00_currency_pkg.get_format_mask(lv_cur_code, 38)
--            )
--       INTO ln_accounted_amount
--       FROM dual;
----
---- 20050217 V1.2 START
---- 条件追加【ORG_ID】
--     UPDATE XX03_PAYMENT_SLIPS xps
--        SET xps.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
--      WHERE xps.INVOICE_ID = gn_invoice_id
--        AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
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
---- 20050217 V1.2 START
--    -- オルグIDの取得
--    gn_org_id := TO_NUMBER(xx00_profile_pkg.value('ORG_ID'));
---- 20050217 V1.2 END
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
--      SELECT COUNT(xpsi.INTERFACE_ID)
--        INTO ln_header_count
--        FROM XX03_PAYMENT_SLIPS_IF xpsi
--       WHERE xpsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID
--         AND xpsi.REQUEST_ID = in_request_id
--         AND xpsi.SOURCE = iv_source;
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
--          -- ===============================
--          -- 支払予定日取得(E-4)
--          -- ===============================
--          xx03_deptinput_ap_check_pkg.get_terms_date(
--            xx03_if_header_rec.TERMS_ID,
--            xx03_if_header_rec.INVOICE_DATE,
--            xx03_if_header_rec.TERMS_DATE,
--            ld_terms_date,
--            lv_terms_flg,
--            lv_errbuf,
--            lv_retcode,
--            lv_errmsg
--          );
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
--            -- 請求書ID取得
--            SELECT XX03_PAYMENT_SLIPS_S.nextval
--              INTO gn_invoice_id
--              FROM dual;
----
--            -- インターフェーステーブル請求書ID更新
--            UPDATE XX03_PAYMENT_SLIPS_IF xpsi
--               SET INVOICE_ID = gn_invoice_id
--             WHERE xpsi.REQUEST_ID = in_request_id
--               AND xpsi.SOURCE = iv_source
--               AND xpsi.INTERFACE_ID = xx03_if_header_rec.INTERFACE_ID;
----
--            -- ヘッダデータ保存
--            INSERT INTO XX03_PAYMENT_SLIPS(
--              INVOICE_ID                   ,
--              WF_STATUS                    ,
--              SLIP_TYPE                    ,
--              INVOICE_NUM                  ,
--              ENTRY_DATE                   ,
--              REQUEST_KEY                  ,
--              REQUESTOR_PERSON_ID          ,
--              REQUESTOR_PERSON_NAME        ,
--              APPROVER_PERSON_ID           ,
--              APPROVER_PERSON_NAME         ,
--              REQUEST_DATE                 ,
--              APPROVAL_DATE                ,
--              REJECTION_DATE               ,
--              ACCOUNT_APPROVER_PERSON_ID   ,
--              ACCOUNT_APPROVAL_DATE        ,
--              AP_FORWORD_DATE              ,
--              RECOGNITION_CLASS            ,
--              APPROVER_COMMENTS            ,
--              REQUEST_ENABLE_FLAG          ,
--              ACCOUNT_REVISION_FLAG        ,
--              INVOICE_DATE                 ,
--              VENDOR_ID                    ,
--              VENDOR_NAME                  ,
--              VENDOR_SITE_ID               ,
--              VENDOR_SITE_NAME             ,
--              INV_AMOUNT                   ,
--              INV_ACCOUNTED_AMOUNT         ,
--              INV_ITEM_AMOUNT              ,
--              INV_TAX_AMOUNT               ,
--              INV_PREPAY_AMOUNT            ,
--              INVOICE_CURRENCY_CODE        ,
--              EXCHANGE_RATE                ,
--              EXCHANGE_RATE_TYPE           ,
--              EXCHANGE_RATE_TYPE_NAME      ,
--              TERMS_ID                     ,
--              TERMS_NAME                   ,
--              DESCRIPTION                  ,
--              VENDOR_INVOICE_NUM           ,
--              ENTRY_DEPARTMENT             ,
--              ENTRY_PERSON_ID              ,
--              ORIG_INVOICE_NUM             ,
--              ACCOUNT_APPROVAL_FLAG        ,
--              PAY_GROUP_LOOKUP_CODE        ,
--              PAY_GROUP_LOOKUP_NAME        ,
--              GL_DATE                      ,
--              ACCTS_PAY_CODE_COMBINATION_ID,
--              AUTO_TAX_CALC_FLAG           ,
--              AP_TAX_ROUNDING_RULE         ,
--              PREPAY_NUM                   ,
--              TERMS_DATE                   ,
--              FORM_SELECT_FLAG             ,
-- -- 2005/04/05 Ver11.5.10.1.0 ADD Start
--              DELETE_FLAG                  ,
-- -- 2005/04/05 Ver11.5.10.1.0 ADD End
--              ORG_ID                       ,
--              ATTRIBUTE_CATEGORY           ,
--              ATTRIBUTE1                   ,
--              ATTRIBUTE2                   ,
--              ATTRIBUTE3                   ,
--              ATTRIBUTE4                   ,
--              ATTRIBUTE5                   ,
--              ATTRIBUTE6                   ,
--              ATTRIBUTE7                   ,
--              ATTRIBUTE8                   ,
--              ATTRIBUTE9                   ,
--              ATTRIBUTE10                  ,
--              ATTRIBUTE11                  ,
--              ATTRIBUTE12                  ,
--              ATTRIBUTE13                  ,
--              ATTRIBUTE14                  ,
--              ATTRIBUTE15                  ,
--              ATTRIBUTE16                  ,
--              ATTRIBUTE17                  ,
--              ATTRIBUTE18                  ,
--              ATTRIBUTE19                  ,
--              ATTRIBUTE20                  ,
--              CREATED_BY                   ,
--              CREATION_DATE                ,
--              LAST_UPDATED_BY              ,
--              LAST_UPDATE_DATE             ,
--              LAST_UPDATE_LOGIN            ,
--              REQUEST_ID                   ,
--              PROGRAM_APPLICATION_ID       ,
--              PROGRAM_UPDATE_DATE          ,
--              PROGRAM_ID
--            )
--            VALUES(
--              gn_invoice_id,
--              xx03_if_header_rec.WF_STATUS,
--              xx03_if_header_rec.SLIP_TYPE,
--              gn_invoice_id,
--              xx03_if_header_rec.ENTRY_DATE,
--              NULL,
--              xx03_if_header_rec.REQUESTOR_PERSON_ID,
--              xx03_if_header_rec.REQUESTOR_PERSON_NAME,
--              xx03_if_header_rec.APPROVER_PERSON_ID,
--              xx03_if_header_rec.APPROVER_PERSON_NAME,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              0,
--              NULL,
--              'N',
--              'N',
--              xx03_if_header_rec.INVOICE_DATE,
--              xx03_if_header_rec.VENDOR_ID,
--              xx03_if_header_rec.VENDOR_NAME,
--              xx03_if_header_rec.VENDOR_SITE_ID,
--              xx03_if_header_rec.VENDOR_SITE_NAME,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              xx03_if_header_rec.INVOICE_CURRENCY_CODE,
--              xx03_if_header_rec.EXCHANGE_RATE,
--              xx03_if_header_rec.EXCHANGE_RATE_TYPE,
--              xx03_if_header_rec.EXCHANGE_RATE_TYPE_NAME,
--              xx03_if_header_rec.TERMS_ID,
--              xx03_if_header_rec.TERMS_NAME,
--              xx03_if_header_rec.DESCRIPTION,
--              xx03_if_header_rec.VENDOR_INVOICE_NUM,
--              xx03_if_header_rec.ENTRY_DEPARTMENT,
--              xx03_if_header_rec.ENTRY_PERSON_ID,
--              NULL,
--              'N',
--              xx03_if_header_rec.PAY_GROUP_LOOKUP_CODE,
--              xx03_if_header_rec.PAY_GROUP_LOOKUP_NAME,
--              xx03_if_header_rec.GL_DATE,
--              NULL,
--              xx03_if_header_rec.AUTO_TAX_CALC_FLAG,
--              xx03_if_header_rec.AP_TAX_ROUNDING_RULE,
--              xx03_if_header_rec.PREPAY_NUM,
--              ld_terms_date,
--              NULL,
-- -- 2005/04/05 Ver11.5.10.1.0 ADD Start
--              'N',
-- -- 2005/04/05 Ver11.5.10.1.0 ADD End
--              xx03_if_header_rec.ORG_ID,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              NULL,
--              xx00_global_pkg.user_id,
--              xx00_date_pkg.get_system_datetime_f,
--              xx00_global_pkg.user_id,
--              xx00_date_pkg.get_system_datetime_f,
--              xx00_global_pkg.login_id,
--              xx00_global_pkg.conc_request_id,
--              xx00_global_pkg.prog_appl_id,
--              xx00_date_pkg.get_system_datetime_f,
--              xx00_global_pkg.conc_program_id
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
--            xx03_deptinput_ap_check_pkg.set_account_approval_flag(
--              gn_invoice_id,
--              lv_app_upd,
--              lv_errbuf,
--              lv_retcode,
--              lv_errmsg
--            );
--            IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
---- 20050217 V1.2 START
---- 条件追加【ORG_ID】
--              -- 結果が正常なら、ヘッダレコードの重点管理フラグを更新
--              UPDATE XX03_PAYMENT_SLIPS xps
--                 SET xps.ACCOUNT_APPROVAL_FLAG = lv_app_upd
--               WHERE xps.INVOICE_ID = gn_invoice_id
--                 AND xps.ORG_ID = gn_org_id;
---- 20050217 V1.2 END
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
--            xx03_deptinput_ap_check_pkg. check_deptinput_ap (
--              gn_invoice_id,
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
--
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
    SELECT XX03_PAYMENT_SLIPS_S.nextval
      INTO gn_invoice_id
      FROM dual;
--
    -- インターフェーステーブル請求書ID更新
    UPDATE XX03_PAYMENT_SLIPS_IF xpsi
       SET INVOICE_ID = gn_invoice_id
     WHERE xpsi.REQUEST_ID = in_request_id
       AND xpsi.SOURCE = iv_source
       AND xpsi.INTERFACE_ID = xx03_if_head_line_rec.HEAD_INTERFACE_ID;
--
    -- ヘッダデータ保存
    INSERT INTO XX03_PAYMENT_SLIPS(
      INVOICE_ID                   ,
      WF_STATUS                    ,
      SLIP_TYPE                    ,
      INVOICE_NUM                  ,
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
      AP_FORWORD_DATE              ,
      RECOGNITION_CLASS            ,
      APPROVER_COMMENTS            ,
      REQUEST_ENABLE_FLAG          ,
      ACCOUNT_REVISION_FLAG        ,
      INVOICE_DATE                 ,
      VENDOR_ID                    ,
      VENDOR_NAME                  ,
      VENDOR_SITE_ID               ,
      VENDOR_SITE_NAME             ,
      INV_AMOUNT                   ,
      INV_ACCOUNTED_AMOUNT         ,
      INV_ITEM_AMOUNT              ,
      INV_TAX_AMOUNT               ,
      INV_PREPAY_AMOUNT            ,
      INVOICE_CURRENCY_CODE        ,
      EXCHANGE_RATE                ,
      EXCHANGE_RATE_TYPE           ,
      EXCHANGE_RATE_TYPE_NAME      ,
      TERMS_ID                     ,
      TERMS_NAME                   ,
      DESCRIPTION                  ,
      VENDOR_INVOICE_NUM           ,
      ENTRY_DEPARTMENT             ,
      ENTRY_PERSON_ID              ,
      ORIG_INVOICE_NUM             ,
      ACCOUNT_APPROVAL_FLAG        ,
      PAY_GROUP_LOOKUP_CODE        ,
      PAY_GROUP_LOOKUP_NAME        ,
      GL_DATE                      ,
      ACCTS_PAY_CODE_COMBINATION_ID,
      AUTO_TAX_CALC_FLAG           ,
      AP_TAX_ROUNDING_RULE         ,
      PREPAY_NUM                   ,
      TERMS_DATE                   ,
      FORM_SELECT_FLAG             ,
      DELETE_FLAG                  ,
      ORG_ID                       ,
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
      ATTRIBUTE16                  ,
      ATTRIBUTE17                  ,
      ATTRIBUTE18                  ,
      ATTRIBUTE19                  ,
      ATTRIBUTE20                  ,
-- ver 11.5.10.2.11 Add Start
      INVOICE_ELE_DATA_YES         ,
      INVOICE_ELE_DATA_NO          ,
-- ver 11.5.10.2.11 Add End
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
      gn_invoice_id,
      xx03_if_head_line_rec.HEAD_WF_STATUS,
      xx03_if_head_line_rec.HEAD_SLIP_TYPE,
      gn_invoice_id,
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
      xx03_if_head_line_rec.HEAD_INVOICE_DATE,
      xx03_if_head_line_rec.HEAD_VENDOR_ID,
      xx03_if_head_line_rec.HEAD_VENDOR_NAME,
      xx03_if_head_line_rec.HEAD_VENDOR_SITE_ID,
      xx03_if_head_line_rec.HEAD_VENDOR_SITE_NAME,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE,
      xx03_if_head_line_rec.HEAD_EXCHANGE_RATE_TYPE_NAME,
      xx03_if_head_line_rec.HEAD_TERMS_ID,
      xx03_if_head_line_rec.HEAD_TERMS_NAME,
      xx03_if_head_line_rec.HEAD_DESCRIPTION,
      xx03_if_head_line_rec.HEAD_VENDOR_INVOICE_NUM,
      xx03_if_head_line_rec.HEAD_ENTRY_DEPARTMENT,
      xx03_if_head_line_rec.HEAD_ENTRY_PERSON_ID,
      NULL,
      'N',
      xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_CODE,
      xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_NAME,
      xx03_if_head_line_rec.HEAD_GL_DATE,
      NULL,
      xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG,
      xx03_if_head_line_rec.HEAD_AP_TAX_ROUNDING_RULE,
      xx03_if_head_line_rec.HEAD_PREPAY_NUM,
      id_terms_date,
      NULL,
      'N',
      xx03_if_head_line_rec.HEAD_ORG_ID,
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
      NULL,
      NULL,
      NULL,
      NULL,
-- ver 11.5.10.2.11 Add Start
      xx03_if_head_line_rec.HEAD_INVOICE_ELE_DATA_YES,
      xx03_if_head_line_rec.HEAD_INVOICE_ELE_DATA_NO,
-- ver 11.5.10.2.11 Add End
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
    iv_source     IN  VARCHAR2,     --  1.ソース
    in_request_id IN  NUMBER,       --  2.要求ID
    in_line_count IN  NUMBER,       --  3.明細行数
    ov_errbuf     OUT VARCHAR2,     --   エラー・メッセージ           --# 固定 #
    ov_retcode    OUT VARCHAR2,     --   リターン・コード             --# 固定 #
    ov_errmsg     OUT VARCHAR2)     --   ユーザー・エラー・メッセージ --# 固定 #
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
    lv_slip_type_name VARCHAR2(4000);  -- 摘要名称
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
    SELECT XX03_PAYMENT_SLIP_LINES_S.nextval
    INTO   ln_line_id
    FROM   dual;
--
    -- ver 11.5.10.2.6 Del Start
    ---- 摘要名称取得
    --BEGIN
    --  SELECT xsltv.LOOKUP_CODE || XX00_PROFILE_PKG.VALUE('XX03_TEXT_DELIMITER') || xsltv.DESCRIPTION as SLIP_LINE_TYPE_NAME
    --  INTO   lv_slip_type_name
    --  FROM   XX03_SLIP_LINE_TYPES_V xsltv
    --  WHERE  XSLTV.ENABLED_FLAG = 'Y'
    --    AND  xsltv.LOOKUP_CODE  = xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE
    --  ;
    --EXCEPTION
    --  WHEN NO_DATA_FOUND THEN
    --    -- 対象データなし時は摘要名称空
    --    lv_slip_type_name := '';
    --    -- ステータスをエラーに
    --    gv_result := cv_result_error;
    --    -- エラー件数加算
    --    gn_error_count := gn_error_count + 1;
    --    xx00_file_pkg.output(
    --      xx00_message_pkg.get_msg(
    --        'XX03',
    --        'APP-XX03-08026'
    --      )
    --    );
    --END;
    -- ver 11.5.10.2.6 Del End
--
    -- 金額算出
    IF ( xx03_if_head_line_rec.LINE_AMOUNT_INCLUDES_TAX_FLAG = cv_yes ) THEN
      -- '内税'が'Y'の時は金額は'本体金額+消費税額'
      ln_amount :=  xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT
                  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
    ELSIF  ( xx03_if_head_line_rec.LINE_AMOUNT_INCLUDES_TAX_FLAG = cv_no ) THEN
      -- '内税'が'N'の時は金額は'本体金額'
      ln_amount := xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT;
    ELSE
      -- それ以外の時は内税入力値エラー
      ln_amount := 0;
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
    INSERT INTO XX03_PAYMENT_SLIP_LINES(
      INVOICE_LINE_ID           ,
      INVOICE_ID                ,
      LINE_NUMBER               ,
      SLIP_LINE_TYPE            ,
      SLIP_LINE_TYPE_NAME       ,
      ENTERED_AMOUNT            ,
      ENTERED_ITEM_AMOUNT       ,
      ENTERED_TAX_AMOUNT        ,
      DESCRIPTION               ,
      AMOUNT_INCLUDES_TAX_FLAG  ,
      TAX_CODE                  ,
      TAX_NAME                  ,
      SEGMENT1                  ,
      SEGMENT2                  ,
      SEGMENT3                  ,
      SEGMENT4                  ,
      SEGMENT5                  ,
      SEGMENT6                  ,
      SEGMENT7                  ,
      SEGMENT8                  ,
      SEGMENT9                  ,
      SEGMENT10                 ,
      SEGMENT11                 ,
      SEGMENT12                 ,
      SEGMENT13                 ,
      SEGMENT14                 ,
      SEGMENT15                 ,
      SEGMENT16                 ,
      SEGMENT17                 ,
      SEGMENT18                 ,
      SEGMENT19                 ,
      SEGMENT20                 ,
      SEGMENT1_NAME             ,
      SEGMENT2_NAME             ,
      SEGMENT3_NAME             ,
      SEGMENT4_NAME             ,
      SEGMENT5_NAME             ,
      SEGMENT6_NAME             ,
      SEGMENT7_NAME             ,
      SEGMENT8_NAME             ,
      INCR_DECR_REASON_CODE     ,
      INCR_DECR_REASON_NAME     ,
      RECON_REFERENCE           ,
      ORG_ID                    ,
      ATTRIBUTE_CATEGORY        ,
      ATTRIBUTE1                ,
      ATTRIBUTE2                ,
      ATTRIBUTE3                ,
      ATTRIBUTE4                ,
      ATTRIBUTE5                ,
      ATTRIBUTE6                ,
      ATTRIBUTE7                ,
      ATTRIBUTE8                ,
      ATTRIBUTE9                ,
      ATTRIBUTE10               ,
      ATTRIBUTE11               ,
      ATTRIBUTE12               ,
      ATTRIBUTE13               ,
      ATTRIBUTE14               ,
      ATTRIBUTE15               ,
      CREATED_BY                ,
      CREATION_DATE             ,
      LAST_UPDATED_BY           ,
      LAST_UPDATE_DATE          ,
      LAST_UPDATE_LOGIN         ,
      REQUEST_ID                ,
      PROGRAM_APPLICATION_ID    ,
      PROGRAM_ID                ,
      PROGRAM_UPDATE_DATE
    )
    VALUES(
      ln_line_id,
      gn_invoice_id,
      in_line_count,
      xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE,
      -- ver 11.5.10.2.6 Chg Start
      --lv_slip_type_name,
      xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME,
      -- ver 11.5.10.2.6 Chg End
      ln_amount,
      xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT,
      xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT,
      xx03_if_head_line_rec.LINE_DESCRIPTION,
      xx03_if_head_line_rec.LINE_AMOUNT_INCLUDES_TAX_FLAG,
      xx03_if_head_line_rec.LINE_TAX_CODE,
      xx03_if_head_line_rec.LINE_TAX_NAME,
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
-- ver 11.5.10.2.10H Mod Start
--      NULL,
      xx03_if_head_line_rec.LINE_ORG_ID,
-- ver 11.5.10.2.10H Mod End
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
      NULL,
-- ver 11.5.10.2.10H Mod Start
--      NULL,
      xx03_if_head_line_rec.LINE_ATTRIBUTE7,
-- ver 11.5.10.2.10H Mod End
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
      xx00_global_pkg.conc_program_id,
      xx00_date_pkg.get_system_datetime_f
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
   * Description      : 請求書データの入力チェック(E-2)
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
-- ver 11.5.10.2.10E Del Start
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
-- ver 11.5.10.2.10E Del End
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
-- ver 11.5.10.2.10E Chg Start
----      -- 承認者名が入力されている場合は承認ビューにて再チェック
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
        xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-08011'));
      END IF;
-- ver 11.5.10.2.10E Chg End
-- Ver11.5.10.1.5B Add End
    END IF;
--
    -- 仕入先チェック
    IF ( xx03_if_head_line_rec.HEAD_VENDOR_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_VENDOR_ID) = '' ) THEN
      -- 仕入先IDが空の場合は仕入先入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08012'
        )
      );
    END IF;
--
    -- 仕入先サイトチェック
    IF ( xx03_if_head_line_rec.HEAD_VENDOR_SITE_ID IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_VENDOR_SITE_ID) = '' ) THEN
      -- 仕入先サイトIDが空の場合は仕入先サイト入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08013'
        )
      );
    END IF;
--
    -- ver 11.5.10.2.6 Add Start
    -- 振込先口座チェック
    -- ver 11.5.10.2.10D Chg Start
    --IF      ( xx03_if_head_line_rec.HEAD_VENDOR_PAYMETHOD = cv_paymethod_eft
    IF      ( xx03_if_head_line_rec.HEAD_PAY_GROUP_PAYMETHOD = cv_paymethod_eft
    -- ver 11.5.10.2.10D Chg End
        AND ( xx03_if_head_line_rec.HEAD_VENDOR_BANK_NAME IS NULL
                OR TRIM(xx03_if_head_line_rec.HEAD_VENDOR_BANK_NAME) = '' )) THEN
      -- 仕入先サイト支払方法が電信で振込先口座が空の場合は振込先口座入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          -- ver 11.5.10.2.10D Chg Start
          --'APP-XX03-12509' ,
          'APP-XX03-12516' ,
          -- ver 11.5.10.2.10D Chg End
          'SLIP_NUM' ,''
        )
      );
    END IF;
    -- ver 11.5.10.2.6 Add End
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
    -- 支払グループチェック
    IF ( xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_CODE IS NULL
           OR TRIM(xx03_if_head_line_rec.HEAD_PAY_GROUP_LOOKUP_CODE) = '' ) THEN
      -- 支払グループが空の場合は支払グループ入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08016'
        )
      );
    END IF;
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
    -- 支払条件、支払予定日関連性チェック
    IF (( xx03_if_head_line_rec.HEAD_TERMS_CHANGE_FLG = cv_yes
          AND ( xx03_if_head_line_rec.HEAD_TERMS_DATE IS NULL
                OR TRIM(xx03_if_head_line_rec.HEAD_TERMS_DATE) = ''))
        OR ( xx03_if_head_line_rec.HEAD_TERMS_CHANGE_FLG = cv_no
          AND ( xx03_if_head_line_rec.HEAD_TERMS_DATE IS NOT NULL
                OR TRIM(xx03_if_head_line_rec.HEAD_TERMS_DATE) <> ''))) THEN
      -- 支払予定日変更不可で入力あり、もしくは支払予定日変更可で入力なしはエラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08019'
        )
      );
    END IF;
--
    -- 前払金充当伝票番号チェック
    IF (xx03_if_head_line_rec.HEAD_PREPAY_NUM IS NOT NULL
        AND (xx03_if_head_line_rec.HEAD_PREPAY_INVOICE_NUM IS NULL
             OR TRIM(xx03_if_head_line_rec.HEAD_PREPAY_INVOICE_NUM) = '' )) THEN
      -- 前払金充当伝票が空（取得できない）場合は入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-14057'
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
   * Description      : 請求書データの入力チェック(E-2)
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
--
    -- ver 11.5.10.1.6F Add Start
    -- 摘要コードチェック
    IF ( xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_SLIP_LINE_TYPE_NAME) = '' ) THEN
      -- 摘要コード名が空の場合は摘要コード入力エラー表示
      -- ステータスをエラーに
      gv_result := cv_result_error;
      -- エラー件数加算
      gn_error_count := gn_error_count + 1;
      xx00_file_pkg.output(
        xx00_message_pkg.get_msg(
          'XX03',
          'APP-XX03-08026'
        )
      );
    END IF;
--
    -- 税区分チェック
    IF ( xx03_if_head_line_rec.LINE_TAX_NAME IS NULL
           OR TRIM(xx03_if_head_line_rec.LINE_TAX_NAME) = '' ) THEN
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
    END IF;
    -- ver 11.5.10.1.6F Add End
--
-- Ver11.5.10.1.6E Add Start
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
-- Ver11.5.10.1.6E Add End
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
    in_prepay_amount     IN  NUMBER,       --  3.前払充当金額
    iv_cur_code          IN  VARCHAR2,     --  4.通貨コード
    in_exchange_rate     IN  NUMBER,       --  5.換算レート
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
--
    --通貨コードが機能通貨でない場合は支払金額をレート換算して換算済合計金額セット
    ln_accounted_amount := (in_total_item_amount + in_total_tax_amount) - in_prepay_amount;
    IF ( iv_cur_code != gv_cur_code ) THEN
      SELECT TO_NUMBER( TO_CHAR( ln_accounted_amount * in_exchange_rate
                                ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
                       ,xx00_currency_pkg.get_format_mask(gv_cur_code, 38))
      INTO   ln_accounted_amount
      FROM   dual;
    END IF;
--
    -- ヘッダ金額更新
    UPDATE XX03_PAYMENT_SLIPS xps
    SET    xps.INV_ITEM_AMOUNT      = in_total_item_amount
         , xps.INV_TAX_AMOUNT       = in_total_tax_amount
         , xps.INV_AMOUNT           = (in_total_item_amount + in_total_tax_amount) - in_prepay_amount
         , xps.INV_ACCOUNTED_AMOUNT = ln_accounted_amount
    WHERE  xps.INVOICE_ID = gn_invoice_id
      AND  xps.ORG_ID     = gn_org_id;
--
    -- 重点管理チェック
    xx03_deptinput_ap_check_pkg.set_account_approval_flag(
      gn_invoice_id,
      lv_app_upd,
      lv_errbuf,
      lv_retcode,
      lv_errmsg
    );
    IF (lv_retcode = xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
      -- 結果が正常なら、ヘッダレコードの重点管理フラグを更新
      UPDATE XX03_PAYMENT_SLIPS xps
      SET    xps.ACCOUNT_APPROVAL_FLAG = lv_app_upd
      WHERE  xps.INVOICE_ID = gn_invoice_id
        AND  xps.ORG_ID = gn_org_id;
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
    xx03_deptinput_ap_check_pkg.check_deptinput_ap(
      gn_invoice_id,
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
   * Description      : インターフェースデータのコピー
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
    ln_prepay_amount     NUMBER;        -- 前払充当金
    lv_cur_code          VARCHAR2(15);  -- 通貨コード
    ln_exchange_rate     NUMBER;        -- 換算レート
    ln_line_count        NUMBER;        -- 明細件数カウント
    ld_terms_date        DATE;          -- 支払予定日
    lv_terms_flg         VARCHAR2(1);   -- 支払予定日変更可能フラグ
--
    -- ver 11.5.10.1.6F Add Start
    lv_first_tax_code    VARCHAR2(15);  -- １明細目の税金コード
    lb_chk_tax_code      BOOLEAN;       -- 税金コード一致チェック用
    -- ver 11.5.10.1.6F Add End
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
              ln_prepay_amount,     --  3.前払充当金額
              lv_cur_code,          --  4.通貨コード
              ln_exchange_rate,     --  5.換算レート
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
        -- ver 11.5.10.1.6F Add Start
        -- 伝票の１レコード目の明細の税区分を保存
        -- 税計算レベルチェックに使用
        lv_first_tax_code := xx03_if_head_line_rec.LINE_TAX_CODE;
        lb_chk_tax_code   := true;
        -- ver 11.5.10.1.6F Add End
--
      END IF;
--
      -- INTERFACE_ID同一値ヘッダが１件より多い時はヘッダエラー
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
            -- ===============================
            -- 支払予定日取得(E-4)
            -- ===============================
            xx03_deptinput_ap_check_pkg.get_terms_date(
              xx03_if_head_line_rec.HEAD_TERMS_ID,
              xx03_if_head_line_rec.HEAD_INVOICE_DATE,
              xx03_if_head_line_rec.HEAD_TERMS_DATE,
              ld_terms_date,
              lv_terms_flg,
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
--
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
        -- ver 11.5.10.1.6F Add Start
        -- 消費税計算レベルがヘッダの場合明細の税区分一致が必要
        IF xx03_if_head_line_rec.HEAD_AUTO_TAX_CALC_FLAG = 'Y' THEN
          -- 伝票の１レコード目の明細の税区分と比較
          IF lv_first_tax_code != xx03_if_head_line_rec.LINE_TAX_CODE AND lb_chk_tax_code = true THEN
            -- ステータスをエラーに
            lb_chk_tax_code := false;
            gv_result := cv_result_error;
            -- エラー件数加算
            gn_error_count := gn_error_count + 1;
            xx00_file_pkg.output(xx00_message_pkg.get_msg('XX03','APP-XX03-12512'));
          END IF;
        END IF;
        -- ver 11.5.10.1.6F Add End
--
        -- エラーが検出されていない時のみ以降の処理実行
        IF ( gn_error_count = 0 ) THEN
          -- 明細テーブルへ挿入
          ins_detail_data(
            iv_source,         -- ソース
            in_request_id,     -- 要求ID
            ln_line_count,     -- 明細行数
            lv_errbuf,         -- エラー・メッセージ           --# 固定 #
            lv_retcode,        -- リターン・コード             --# 固定 #
            lv_errmsg);        -- ユーザー・エラー・メッセージ --# 固定 #
--
          IF (lv_retcode <> xx00_common_pkg.set_status_normal_f(cv_prg_name)) THEN
            RAISE global_process_expt;
          END IF;
        END IF;
--
        -- 合計金額算出用変数加算
        ln_total_item_amount := ln_total_item_amount + xx03_if_head_line_rec.LINE_ENTERED_ITEM_AMOUNT;
        ln_total_tax_amount  := ln_total_tax_amount  + xx03_if_head_line_rec.LINE_ENTERED_TAX_AMOUNT;
--
        -- 充当金額計算
        IF ( xx03_if_head_line_rec.HEAD_PREPAY_NUM IS NOT NULL ) THEN
          -- レコードの充当金額と、本体金額＋消費税額の小さい方を充当金額とする
          IF ( nvl(xx03_if_head_line_rec.HEAD_PREPAY_AMOUNT_APPLIED,0) > (ln_total_item_amount + ln_total_tax_amount)) THEN
            ln_prepay_amount := ln_total_item_amount + ln_total_tax_amount;
          ELSE
            ln_prepay_amount := nvl(xx03_if_head_line_rec.HEAD_PREPAY_AMOUNT_APPLIED,0);
          END IF;
        ELSE
          -- 充当伝票なし
          ln_prepay_amount := 0;
        END IF;
--
        -- 通貨コード・換算レート
        lv_cur_code      := xx03_if_head_line_rec.HEAD_INVOICE_CURRENCY_CODE;
        ln_exchange_rate := xx03_if_head_line_rec.HEAD_EXCHANGE_RATE;
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
          ln_prepay_amount,     --  3.前払充当金額
          lv_cur_code,          --  4.通貨コード
          ln_exchange_rate,     --  5.換算レート
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
-- Ver11.5.10.1.5 2005/09/05 Change End
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
-- 20050217 V1.2 START
-- 条件追加【ORG_ID】
    -- 現在の請求書番号取得
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --SELECT xsn.TEMPORARY_CODE,
    --       xsn.SLIP_NUMBER
    --  INTO lv_slip_code,
    --       ln_slip_number
    --  FROM XX03_SLIP_NUMBERS xsn
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
    --   AND xsn.NUM_TYPE = '0'
    --   AND xsn.ORG_ID = gn_org_id
    --FOR UPDATE NOWAIT;
    SELECT xsn.TEMPORARY_CODE,
           xsn.SLIP_NUMBER
      INTO lv_slip_code,
           ln_slip_number
      FROM XX03_SLIP_NUMBERS xsn
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
       AND xsn.NUM_TYPE = '0'
       AND xsn.ORG_ID = xx00_profile_pkg.value('ORG_ID')
    FOR UPDATE NOWAIT;
    -- Ver11.5.10.1.6D 2006/01/06 Change End
-- 20050217 V1.2 END
--
    -- 請求書番号加算
    -- Ver11.5.10.1.6D 2006/01/06 Change Start
    --UPDATE XX03_SLIP_NUMBERS xsn
    --   SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
    -- WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
    --   AND xsn.NUM_TYPE = '0';
    UPDATE XX03_SLIP_NUMBERS xsn
       SET xsn.SLIP_NUMBER = ln_slip_number + in_add_count
     WHERE xsn.APPLICATION_SHORT_NAME = 'SQLAP'
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
    -- ver 11.5.10.2.10I Add Start
    cv_slip_code CONSTANT VARCHAR2(3) := 'TMP';
    -- ver 11.5.10.2.10I Add End
--
    -- *** ローカル変数 ***
    ln_update_count NUMBER;     -- 更新件数
-- ver 11.5.10.2.10I Del Start
--    lv_slip_code VARCHAR2(10);  -- 請求書コード
--    ln_slip_number NUMBER;      -- 請求書番号
-- ver 11.5.10.2.10I Del Start
--
    -- *** ローカル・カーソル ***
    -- 更新対象取得カーソル
    CURSOR update_record_cur
    IS
      SELECT xps.INVOICE_ID
        FROM XX03_PAYMENT_SLIPS xps
       WHERE xps.REQUEST_ID = xx00_global_pkg.conc_request_id
      ORDER BY xps.INVOICE_ID;
--
    -- ログ出力用カーソル
    CURSOR outlog_cur(pv_source VARCHAR2,
                        pn_request_id NUMBER)
    IS
      SELECT xpsi.INTERFACE_ID as INTERFACE_ID,
             xps.INVOICE_NUM as INVOICE_NUM
        FROM XX03_PAYMENT_SLIPS_IF xpsi,
             XX03_PAYMENT_SLIPS xps
       WHERE xpsi.REQUEST_ID = pn_request_id
         AND xpsi.SOURCE = pv_source
         AND xpsi.INVOICE_ID = xps.INVOICE_ID;
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
      SELECT COUNT(xps.INVOICE_ID)
        INTO ln_update_count
        FROM XX03_PAYMENT_SLIPS xps
       WHERE xps.REQUEST_ID = xx00_global_pkg.conc_request_id;
--
-- ver 11.5.10.2.10I Del Start
--      -- 請求書番号取得
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
-- ver 11.5.10.2.10I Del End
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
-- ver 11.5.10.2.10I Del Start
--        -- 請求書番号加算
--        ln_slip_number := ln_slip_number + 1;
-- ver 11.5.10.2.10I Del Del
--
-- 20050217 V1.2 START
-- 条件追加【ORG_ID】
        -- 請求書番号更新
        UPDATE XX03_PAYMENT_SLIPS xps
-- ver 11.5.10.2.10I Mod Start
--           SET xps.INVOICE_NUM = lv_slip_code || TO_CHAR(ln_slip_number)
           SET xps.INVOICE_NUM = cv_slip_code || TO_CHAR(xxcfo_slip_number_ap_s1.NEXTVAL)
-- ver 11.5.10.2.10I Mod End
         WHERE xps.INVOICE_ID = update_record_rec.INVOICE_ID
           AND xps.ORG_ID = gn_org_id;
-- 20050217 V1.2 END
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
            outlog_rec.INVOICE_NUM
          )
        );
--
      END LOOP out_log_loop;
      CLOSE outlog_cur;
--
      -- ver 11.5.10.2.5 Del Start
      ---- インターフェーステーブルデータ削除
      --DELETE FROM XX03_PAYMENT_SLIPS_IF xpsi
      --      WHERE xpsi.REQUEST_ID = in_request_id
      --        AND xpsi.SOURCE = iv_source;
      ----
      --DELETE FROM XX03_PAYMENT_SLIP_LINES_IF xpsli
      --      WHERE xpsli.REQUEST_ID = in_request_id
      --        AND xpsli.SOURCE = iv_source;
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
END XX034DD001C;
/
