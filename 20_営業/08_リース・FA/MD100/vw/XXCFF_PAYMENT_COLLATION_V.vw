CREATE OR REPLACE FORCE VIEW "APPS"."XXCFF_PAYMENT_COLLATION_V" ("PAYMENT_MATCH_FLAG", "LEASE_CLASS", "LEASE_CLASS_NAME", "LEASE_COMPANY", "LEASE_COMPANY_NAME", "LEASE_TYPE_CODE", "LEASE_TYPE_NAME", "CONTRACT_DATE", "CONTRACT_NUMBER", "PAYMENT_FREQUENCY", "PAYMENT_DATE", "ACCOUNTING_IF_FLAG", "LEASE_CHARGE_TTL", "LEASE_CHARGE", "LEASE_TAX_CHARGE", "ACTIVE_FLAG", "LINE_CNT", "LAST_UPDATE_DATE", "CONTRACT_HEADER_ID") AS 
(
SELECT
 /*+
   LEADING(XCH)
-- Modify E_最終移行リハ_00470 2009.10.13 Start
   INDEX(XCL XXCFF_CONTRACT_LINES_U01) --INDEX(XCL XXCFF_CONTRACT_LINES_PK)
-- Modify E_最終移行リハ_00470 2009.10.13 End
   INDEX(XOH XXCFF_OBJECT_HEADERS_PK)
   INDEX(XPP XXCFF_PAY_PLANNING_PK)
 */
 XPP.PAYMENT_MATCH_FLAG                             AS PAYMENT_MATCH_FLAG
,XCH.LEASE_CLASS                                    AS LEASE_CLASS
,(SELECT XLCV.LEASE_CLASS_NAME
  FROM XXCFF_LEASE_CLASS_V    XLCV
  WHERE XCH.LEASE_CLASS = XLCV.LEASE_CLASS_CODE)    AS LEASE_CLASS_NAME
,XCH.LEASE_COMPANY                                  AS LEASE_COMPANY
,(SELECT XLC.LEASE_COMPANY_NAME
  FROM XXCFF_LEASE_COMPANY_V  XLC
  WHERE XCH.LEASE_COMPANY = XLC.LEASE_COMPANY_CODE) AS LEASE_COMPANY_NAME
,XCH.LEASE_TYPE                                     AS LEASE_TYPE_CODE
,(SELECT XLTV.LEASE_TYPE_NAME
  FROM XXCFF_LEASE_TYPE_V     XLTV
  WHERE XCH.LEASE_TYPE = XLTV.LEASE_TYPE_CODE)      AS LEASE_TYPE_NAME
,XCH.CONTRACT_DATE                                  AS CONTRACT_DATE
,XCH.CONTRACT_NUMBER                                AS CONTRACT_NUMBER
,XPP.PAYMENT_FREQUENCY                              AS PAYMENT_FREQUENCY
,XPP.PAYMENT_DATE                                   AS PAYMENT_DATE
,XPP.ACCOUNTING_IF_FLAG                             AS ACCOUNTING_IF_FLAG
,SUM(XPP.LEASE_CHARGE+XPP.LEASE_TAX_CHARGE)         AS LEASE_CHARGE_TTL
,SUM(XPP.LEASE_CHARGE)                              AS LEASE_CHARGE
,SUM(XPP.LEASE_TAX_CHARGE)                          AS LEASE_TAX_CHARGE
,MAX(DECODE(XOH.ACTIVE_FLAG,'N','無効',NULL))       AS ACTIVE_FLAG
,COUNT(XPP.CONTRACT_LINE_ID)                        AS LINE_CNT
,MAX(XPP.LAST_UPDATE_DATE)                          AS XPP_LAST_UPDATE_DATE
,XCH.CONTRACT_HEADER_ID                             AS CONTRACT_HEADER_ID
FROM
 XXCFF_CONTRACT_HEADERS XCH
,XXCFF_CONTRACT_LINES   XCL
,XXCFF_OBJECT_HEADERS   XOH
,XXCFF_PAY_PLANNING     XPP
WHERE
    XCH.CONTRACT_HEADER_ID = XCL.CONTRACT_HEADER_ID
AND XCL.CONTRACT_LINE_ID   = XPP.CONTRACT_LINE_ID
AND XCL.OBJECT_HEADER_ID   = XOH.OBJECT_HEADER_ID
AND XPP.ACCOUNTING_IF_FLAG IN ('1','2','3') --未送信,送信済,照合できず
--【E_本稼動_13658】ADD START S.Niki
AND XPP.PAYMENT_MATCH_FLAG <> '9'           --'9'(非表示)を除外
--【E_本稼動_13658】ADD END S.Niki
GROUP BY
 XPP.PAYMENT_MATCH_FLAG
,XCH.LEASE_CLASS
,XCH.LEASE_COMPANY
,XCH.LEASE_TYPE
,XCH.CONTRACT_DATE
,XCH.CONTRACT_NUMBER
,XPP.PAYMENT_FREQUENCY
,XPP.PAYMENT_DATE
,XPP.ACCOUNTING_IF_FLAG
,XCH.CONTRACT_HEADER_ID
);
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.PAYMENT_MATCH_FLAG IS '支払照合フラグ';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_CLASS IS 'リース種別コード';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_CLASS_NAME IS 'リース種別名称';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_COMPANY IS 'リース会社コード';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_COMPANY_NAME IS 'リース会社名称';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_TYPE_CODE IS 'リース区分コード';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_TYPE_NAME IS 'リース区分名称';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.CONTRACT_DATE IS '契約日';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.CONTRACT_NUMBER IS '契約番号';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.PAYMENT_FREQUENCY IS '回数';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.PAYMENT_DATE IS '支払日';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.ACCOUNTING_IF_FLAG IS '会計IFフラグ';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_CHARGE_TTL IS 'リース金額(税込)';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_CHARGE IS 'リース金額(税抜)';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LEASE_TAX_CHARGE IS '消費税';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.ACTIVE_FLAG IS '物件有効';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LINE_CNT IS '支払計画レコード数';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.LAST_UPDATE_DATE IS '支払計画最新更新日';
COMMENT ON COLUMN XXCFF_PAYMENT_COLLATION_V.CONTRACT_HEADER_ID IS '契約内部ID';
COMMENT ON TABLE XXCFF_PAYMENT_COLLATION_V IS '支払照合登録画面ビュー';
