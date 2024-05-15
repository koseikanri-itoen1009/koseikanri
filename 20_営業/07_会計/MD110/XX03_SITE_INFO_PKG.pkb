CREATE OR REPLACE PACKAGE BODY xx03_site_info_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2003. All rights reserved.
 *
 * Package Name     : xx03_site_info_pkg(body)
 * Description      : サイト情報取得Function表
 * Version          : 11.5.10.1.6
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  site_info                 サイト情報取得Function表
 *
 * Change Record
 * ------------- ------------- ------------- -------------------------------------------------
 *  Date          Ver.          Editor        Description
 * ------------- ------------- ------------- -------------------------------------------------
 *  2005/09/22    1.0           S.Morisawa    新規作成
 *  2005/09/22    11.5.10.1.5   S.Morisawa    パフォーマンス改善対応
 *  2023/10/23    11.5.10.1.6   Y.Ooyama      E_本稼動_19496対応
 *
 *****************************************************************************************/
--
--
  -- ===============================
  -- グローバル・カーソル
  -- ===============================
  CURSOR site_cur(
    in_vendor_id       IN NUMBER
  )
  IS
  SELECT     XVSV.VENDOR_ID              VENDOR_ID
       , MAX(XVSV.VENDOR_SITE_ID)        VENDOR_SITE_ID
       , MAX(XVSV.VENDOR_SITE_CODE)      VENDOR_SITE_CODE
       , MAX(XVSV.BANK_ACCOUNT_NAME)     BANK_ACCOUNT_NAME
       , MAX(XVSV.BANK_NAME)             BANK_NAME
       , MAX(XVSV.BANK_BRANCH_NAME)      BANK_BRANCH_NAME
       , MAX(XVSV.BANK_ACCOUNT_TYPE)     BANK_ACCOUNT_TYPE
       , MAX(XVSV.BANK_ACCOUNT_NUM)      BANK_ACCOUNT_NUM
       , MAX(XVSV.INVOICE_CURRENCY_CODE) INVOICE_CURRENCY_CODE
       , MAX(XVSV.TERM_ID)               TERM_ID
       , MAX(XVSV.TERM_NAME)             TERM_NAME
       , MAX(XVSV.PAY_GROUP_CODE)        PAY_GROUP_CODE
       , MAX(XVSV.PAY_GROUP_MEANING)     PAY_GROUP_MEANING
       , MAX(XVSV.AUTO_TAX_CALC_FLAG)    AUTO_TAX_CALC_FLAG
       , MAX(XVSV.AP_TAX_ROUNDING_RULE)  AP_TAX_ROUNDING_RULE
-- Ver11.5.10.1.6 ADD START
       , MAX(XVSV.DRAFTING_COMPANY)      DRAFTING_COMPANY
-- Ver11.5.10.1.6 ADD END
  FROM   XX03_VENDOR_SITES_LOV_V  XVSV
  WHERE  XVSV.vendor_id = in_vendor_id
  GROUP BY  XVSV.VENDOR_ID
  HAVING    COUNT(XVSV.VENDOR_ID) = 1;


  l_site XX03_SITE_INFO_TYPE := XX03_SITE_INFO_TYPE(NULL ,NULL ,NULL
                                     ,NULL ,NULL ,NULL
                                     ,NULL ,NULL ,NULL
                                     ,NULL ,NULL ,NULL
                                     ,NULL ,NULL ,NULL
-- Ver11.5.10.1.6 ADD START
                                     ,NULL
-- Ver11.5.10.1.6 ADD END
                                     );
--
  /**********************************************************************************
   * Function Name    : site_info
   * Description      : 
   ***********************************************************************************/
  FUNCTION site_info(
    in_vendor_id       IN NUMBER
    )RETURN XX03_SITE_INFO_TMP pipelined
  IS
  BEGIN
    FOR site_rec IN site_cur(in_vendor_id) LOOP
      l_site.VENDOR_ID             := site_rec.VENDOR_ID;
      l_site.VENDOR_SITE_ID        := site_rec.VENDOR_SITE_ID;
      l_site.VENDOR_SITE_CODE      := site_rec.VENDOR_SITE_CODE;
      l_site.BANK_ACCOUNT_NAME     := site_rec.BANK_ACCOUNT_NAME;
      l_site.BANK_NAME             := site_rec.BANK_NAME;
      l_site.BANK_BRANCH_NAME      := site_rec.BANK_BRANCH_NAME;
      l_site.BANK_ACCOUNT_TYPE     := site_rec.BANK_ACCOUNT_TYPE;
      l_site.BANK_ACCOUNT_NUM      := site_rec.BANK_ACCOUNT_NUM;
      l_site.INVOICE_CURRENCY_CODE := site_rec.INVOICE_CURRENCY_CODE;
      l_site.TERM_ID               := site_rec.TERM_ID;
      l_site.TERM_NAME             := site_rec.TERM_NAME;
      l_site.PAY_GROUP_CODE        := site_rec.PAY_GROUP_CODE;
      l_site.PAY_GROUP_MEANING     := site_rec.PAY_GROUP_MEANING;
      l_site.AUTO_TAX_CALC_FLAG    := site_rec.AUTO_TAX_CALC_FLAG;
      l_site.AP_TAX_ROUNDING_RULE  := site_rec.AP_TAX_ROUNDING_RULE;
-- Ver11.5.10.1.6 ADD START
      l_site.DRAFTING_COMPANY      := site_rec.DRAFTING_COMPANY;
-- Ver11.5.10.1.6 ADD END
      pipe row (l_site);
    END LOOP;
    RETURN;
  END site_info;
END xx03_site_info_pkg;
/
