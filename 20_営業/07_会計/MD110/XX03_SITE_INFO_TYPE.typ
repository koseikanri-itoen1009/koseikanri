/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2005. All rights reserved.
 * Object Name : XX03_SITE_INFO_TYPE
 *  2005/09/22   1.0                        初期作成
 *  2005/09/22   11.5.10.1.5   S.Morisawa   パフォーマンス改善対応
 *  2023/10/23   11.5.10.1.6   Y.Ooyama     E_本稼動_19496対応
*****************************************************************************************/
CREATE OR REPLACE TYPE APPS.XX03_SITE_INFO_TYPE FORCE
AS
OBJECT
(VENDOR_ID                NUMBER
,VENDOR_SITE_ID           NUMBER
,VENDOR_SITE_CODE         VARCHAR2(150)
,BANK_ACCOUNT_NAME        VARCHAR2(80)
,BANK_NAME                VARCHAR2(60)
,BANK_BRANCH_NAME         VARCHAR2(60)
,BANK_ACCOUNT_TYPE        VARCHAR2(25) 
,BANK_ACCOUNT_NUM         VARCHAR2(30)
,INVOICE_CURRENCY_CODE    VARCHAR2(15)
,TERM_ID                  NUMBER(15,0)
,TERM_NAME                VARCHAR2(50)
,PAY_GROUP_CODE           VARCHAR2(30)
,PAY_GROUP_MEANING        VARCHAR2(80)
,AUTO_TAX_CALC_FLAG       VARCHAR2(150)
,AP_TAX_ROUNDING_RULE     VARCHAR2(1)
-- Ver11.5.10.1.6 ADD START
,DRAFTING_COMPANY         VARCHAR2(3)
-- Ver11.5.10.1.6 ADD END
)
/