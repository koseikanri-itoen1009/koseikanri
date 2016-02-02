/************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Table Name      : XXCMM_CUST_ACCOUNTS
 * Description     : 顧客追加情報
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/11/21    1.0  Y.Nagasue        [E_本稼動_12237]倉庫管理システム対応
 *
 ************************************************************************/
ALTER TABLE XXCMM.XXCMM_CUST_ACCOUNTS ADD(
  CUST_FRESH_CON_CODE VARCHAR2(2)
)
/
COMMENT ON COLUMN XXCMM.XXCMM_CUST_ACCOUNTS.CUST_FRESH_CON_CODE IS '顧客別鮮度条件コード';
/
