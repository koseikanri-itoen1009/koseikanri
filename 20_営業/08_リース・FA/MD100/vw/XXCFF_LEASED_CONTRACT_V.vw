CREATE OR REPLACE VIEW XXCFF_LEASED_CONTRACT_V
(
 LEASE_CLASS_NAME       -- リース種別
,LEASE_CLASS            -- リース種別コード
,LEASE_COMPANY_NAME     -- リース会社
,LEASE_COMPANY          -- リース会社コード
,CONTRACT_DATE          -- 契約日
,CONTRACT_NUMBER        -- 契約番号
,COMMENTS               -- 件名
,LEASE_TYPE_NAME        -- リース区分
,LEASE_TYPE             -- リース区分コード
,PAYMENT_FREQUENCY      -- 支払回数
,LEASE_START_DATE       -- リース開始日
,LEASE_END_DATE         -- リース終了日
,CONTRACT_LINE_NUM      -- 枝番
,CONTRACT_STATUS_NAME   -- 契約ステータス
,CONTRACT_STATUS        -- 契約ステータスコード
,LEASE_KIND_NAME        -- リース種類
,LEASE_KIND             -- リース種類コード
,CANCELLATION_DATE      -- 中途解約日
,EXPIRATION_DATE        -- 満了日
,ESTIMATED_CASH_PRICE   -- 見積現金購入価額
,SECOND_CHARGE          -- 2回目以降月額リース料
,SECOND_DEDUCTION       -- 2回目以降月額控除額
,GROSS_CHARGE           -- リース料総額
,OWNER_COMPANY_NAME     -- 本社/工場
,OWNER_COMPANY          -- 本社/工場コード
,DEPARTMENT_NAME        -- 管理部門
,DEPARTMENT_CODE        -- 管理部門コード
,RE_LEASE_TIMES         -- 再リース回数
,OBJECT_CODE            -- 物件コード
,CONTRACT_HEADER_ID     -- リース契約内部ID
,CONTRACT_LINE_ID       -- リース契約明細内部ID
,NOT_LEASE_TIMES        -- リース残回数
,NOT_CHARGE             -- 未経過リース料
,TAX_CODE               -- 税金コード
,TAX_NAME               -- 税金摘要
)
AS
  SELECT
       /*+
       USE_NL(XOH XCL)
       USE_NL(XCL XCH)
       */
       ( SELECT XLV.LEASE_CLASS_NAME
         FROM   XXCFF_LEASE_CLASS_V     XLV
         WHERE  XOH.LEASE_CLASS = XLV.LEASE_CLASS_CODE ) AS LEASE_CLASS_NAME
      ,XOH.LEASE_CLASS                     AS LEASE_CLASS
      ,( SELECT XCV.LEASE_COMPANY_NAME
         FROM   XXCFF_LEASE_COMPANY_V   XCV
         WHERE  XCH.LEASE_COMPANY = XCV.LEASE_COMPANY_CODE ) AS LEASE_COMPANY_NAME
      ,XCH.LEASE_COMPANY                   AS LEASE_COMPANY
      ,XCH.CONTRACT_DATE                   AS CONTRACT_DATE
      ,XCH.CONTRACT_NUMBER                 AS CONTRACT_NUMBER
      ,XCH.COMMENTS                        AS COMMENTS
      ,( SELECT XTV.LEASE_TYPE_NAME
         FROM   XXCFF_LEASE_TYPE_V      XTV
         WHERE  XCH.LEASE_TYPE = XTV.LEASE_TYPE_CODE ) AS LEASE_TYPE_NAME
      ,XCH.LEASE_TYPE                      AS LEASE_TYPE
      ,XCH.PAYMENT_FREQUENCY               AS PAYMENT_FREQUENCY
      ,XCH.LEASE_START_DATE                AS LEASE_START_DATE
      ,XCH.LEASE_END_DATE                  AS LEASE_END_DATE
      ,XCL.CONTRACT_LINE_NUM               AS CONTRACT_LINE_NUM
      ,( SELECT XSV.CONTRACT_STATUS_NAME
         FROM   XXCFF_CONTRACT_STATUS_V XSV
         WHERE  XCL.CONTRACT_STATUS = XSV.CONTRACT_STATUS_CODE ) AS CONTRACT_STATUS_NAME
      ,XCL.CONTRACT_STATUS                 AS CONTRACT_STATUS
      ,( SELECT XKV.LEASE_KIND_NAME
         FROM   XXCFF_LEASE_KIND_V      XKV
         WHERE  XCL.LEASE_KIND = XKV.LEASE_KIND_CODE ) AS LEASE_KIND_NAME
      ,XCL.LEASE_KIND                      AS LEASE_KIND
      ,XCL.CANCELLATION_DATE               AS CANCELLATION_DATE
      ,XCL.EXPIRATION_DATE                 AS EXPIRATION_DATE
      ,XCL.ESTIMATED_CASH_PRICE            AS ESTIMATED_CASH_PRICE
      ,XCL.SECOND_CHARGE                   AS SECOND_CHARGE
      ,XCL.SECOND_DEDUCTION                AS SECOND_DEDUCTION
      ,XCL.GROSS_CHARGE                    AS GROSS_CHARGE
      ,( SELECT XOV.OWNER_COMPANY_NAME
         FROM   XXCFF_OWNER_COMPANY_V   XOV
         WHERE  XOH.OWNER_COMPANY = XOV.OWNER_COMPANY_CODE ) AS OWNER_COMPANY_NAME
      ,XOH.OWNER_COMPANY                   AS OWNER_COMPANY
      ,( SELECT XDV.DEPARTMENT_NAME
         FROM   XXCFF_DEPARTMENT_V      XDV
         WHERE  XOH.DEPARTMENT_CODE = XDV.DEPARTMENT_CODE ) AS DEPARTMENT_NAME
      ,XOH.DEPARTMENT_CODE                 AS DEPARTMENT_CODE
      ,XCH.RE_LEASE_TIMES                  AS RE_LEASE_TIMES
      ,XOH.OBJECT_CODE                     AS OBJECT_CODE
      ,XCL.CONTRACT_HEADER_ID              AS CONTRACT_HEADER_ID
      ,XCL.CONTRACT_LINE_ID                AS CONTRACT_LINE_ID
      ,NVL((SELECT 
               COUNT(XPAY.PAYMENT_FREQUENCY) AS NOT_LEASE_TIMES
            FROM   XXCFF_PAY_PLANNING XPAY
            WHERE  XCL.CONTRACT_LINE_ID       = XPAY.CONTRACT_LINE_ID(+)
            AND    XPAY.ACCOUNTING_IF_FLAG(+) = '1'
--【E_本稼動_13658】MOD START S.Niki
--            GROUP BY 
--                   XPAY.CONTRACT_LINE_ID  ),0) XPP
            AND    XPAY.PAYMENT_MATCH_FLAG(+) <> '9'  --'9'(非表示)を除外
            GROUP BY 
                   XPAY.CONTRACT_LINE_ID  ),0) AS NOT_LEASE_TIMES
--【E_本稼動_13658】MOD END S.Niki
      ,NVL((SELECT 
               SUM(XPAY.LEASE_CHARGE)        AS NOT_CHARGE
            FROM   XXCFF_PAY_PLANNING XPAY
            WHERE  XCL.CONTRACT_LINE_ID       = XPAY.CONTRACT_LINE_ID(+)
            AND    XPAY.ACCOUNTING_IF_FLAG(+) = '1'
--【E_本稼動_13658】MOD START S.Niki
--            GROUP BY 
--                   XPAY.CONTRACT_LINE_ID  ),0) XPP
            AND    XPAY.PAYMENT_MATCH_FLAG(+) <> '9'  --'9'(非表示)を除外
            GROUP BY 
                   XPAY.CONTRACT_LINE_ID  ),0) AS NOT_CHARGE
--【E_本稼動_13658】MOD END S.Niki
--【E_本稼動_10871】MOD START Nakano
--      ,XCH.TAX_CODE                        AS TAX_CODE
--      ,( SELECT APT.DESCRIPTION
--         FROM   AP_TAX_CODES APT
--         WHERE  XCH.TAX_CODE = APT.NAME(+) ) AS TAX_NAME
      ,NVL(XCL.TAX_CODE, XCH.TAX_CODE)     AS TAX_CODE
      ,NVL(
       ( SELECT APT.DESCRIPTION
         FROM   AP_TAX_CODES APT
         WHERE  XCL.TAX_CODE = APT.NAME(+) ),
       ( SELECT APT.DESCRIPTION
         FROM   AP_TAX_CODES APT
         WHERE  XCH.TAX_CODE = APT.NAME(+) )) AS TAX_NAME
--【E_本稼動_10871】MOD END Nakano
FROM   
       XXCFF_OBJECT_HEADERS    XOH
      ,XXCFF_CONTRACT_LINES    XCL
      ,XXCFF_CONTRACT_HEADERS  XCH
WHERE  XOH.OBJECT_HEADER_ID   = XCL.OBJECT_HEADER_ID
AND    XCL.CONTRACT_HEADER_ID = XCH.CONTRACT_HEADER_ID
;
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_CLASS_NAME     IS 'リース種別';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_CLASS          IS 'リース種別コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_COMPANY_NAME   IS 'リース会社';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_COMPANY        IS 'リース会社コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_DATE        IS '契約日';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_NUMBER      IS '契約番号';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.COMMENTS             IS '件名';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_TYPE_NAME      IS 'リース区分';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_TYPE           IS 'リース区分コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.PAYMENT_FREQUENCY    IS '支払回数';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_START_DATE     IS 'リース開始日';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_END_DATE       IS 'リース終了日';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_LINE_NUM    IS '枝番';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_STATUS_NAME IS '契約ステータス';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_STATUS      IS '契約ステータスコード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_KIND_NAME      IS 'リース種類';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.LEASE_KIND           IS 'リース種類コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CANCELLATION_DATE    IS '中途解約日';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.EXPIRATION_DATE      IS '満了日';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.ESTIMATED_CASH_PRICE IS '見積現金購入価額';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.SECOND_CHARGE        IS '2回目以降月額リース料';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.SECOND_DEDUCTION     IS '2回目以降月額控除額';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.GROSS_CHARGE         IS 'リース料総額';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.OWNER_COMPANY_NAME   IS '本社/工場';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.OWNER_COMPANY        IS '本社/工場コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.DEPARTMENT_NAME      IS '管理部門';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.DEPARTMENT_CODE      IS '管理部門コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.RE_LEASE_TIMES       IS '再リース回数';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.OBJECT_CODE          IS '物件コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_HEADER_ID   IS 'リース契約内部ID';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.CONTRACT_LINE_ID     IS 'リース契約明細内部ID';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.NOT_LEASE_TIMES      IS 'リース残回数';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.NOT_CHARGE           IS '未経過リース料';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.TAX_CODE             IS '税金コード';
COMMENT ON COLUMN XXCFF_LEASED_CONTRACT_V.TAX_NAME             IS '税金摘要';
COMMENT ON TABLE XXCFF_LEASED_CONTRACT_V IS 'リース契約一覧画面ビュー';
