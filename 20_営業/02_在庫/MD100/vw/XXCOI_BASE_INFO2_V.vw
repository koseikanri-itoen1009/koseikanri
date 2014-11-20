/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_BASE_INFO2_V
 * Description : 拠点情報ビュー2
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2008/11/28    1.0   U.Sai            新規作成
 *  2009/04/30    1.1   T.Nakamura       [障害T1_0877] カラムコメント、バックスラッシュを追加
 *
 ************************************************************************/

  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_BASE_INFO2_V" ("BASE_CODE", "BASE_SHORT_NAME", "FOCUS_BASE_CODE") AS 
  SELECT hca.account_number                                 -- 拠点コード
        ,SUBSTRB(hca.account_name,1,8)                      -- 拠点略称
        ,xca.management_base_code                           -- 絞込み拠点
  FROM   hz_cust_accounts hca                               -- 顧客マスタ
        ,xxcmm_cust_accounts xca                            -- 顧客追加情報
  WHERE  hca.customer_class_code = '1'
  AND    hca.status = 'A'
  AND    hca.cust_account_id = xca.customer_id
  AND    xca.management_base_code IS NOT NULL
  UNION ALL
  SELECT hca.account_number                                 -- 拠点コード
        ,SUBSTRB(hca.account_name,1,8)                      -- 拠点略称
        ,hca.account_number                                 -- 絞込み拠点
  FROM   hz_cust_accounts hca                               -- 顧客マスタ
        ,xxcmm_cust_accounts xca                            -- 顧客追加情報
  WHERE  hca.customer_class_code = '1'
  AND    hca.status = 'A'
  AND    hca.cust_account_id = xca.customer_id
  AND    hca.account_number <> NVL(xca.management_base_code,'99999');
/
COMMENT ON TABLE  XXCOI_BASE_INFO2_V                   IS '拠点情報ビュー2';
/
COMMENT ON COLUMN XXCOI_BASE_INFO2_V.BASE_CODE         IS '拠点コード';
/
COMMENT ON COLUMN XXCOI_BASE_INFO2_V.BASE_SHORT_NAME   IS '拠点略称';
/
COMMENT ON COLUMN XXCOI_BASE_INFO2_V.FOCUS_BASE_CODE   IS '絞込み拠点';
/
