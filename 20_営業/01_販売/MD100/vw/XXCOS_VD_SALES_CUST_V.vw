/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_cust_v
 * Description     : 自販機販売報告書用顧客ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/02/09    1.0   K.Kiriu          [E_本稼動_08359]新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_vd_sales_cust_v(
   customer_code   -- 顧客コード
  ,customer_name   -- 顧客名称
  ,sale_base_code  -- 売上拠点コード
)
AS
SELECT /*+
         USE_NL(xca hca hp)
       */
       hca.account_number  customer_code   --顧客コード
      ,hp.party_name       customer_name   --顧客名称
      ,xca.sale_base_code  sale_base_code  --売上拠点コード
FROM   xxcmm_cust_accounts  xca
      ,hz_cust_accounts     hca
      ,hz_parties           hp
WHERE  xca.customer_id         =  hca.cust_account_id
AND    xca.business_low_type   IN ('24','25')   --フルVD or フルVD(消化)
AND    hca.customer_class_code =  '10'          --顧客
AND    hca.party_id            =  hp.party_id
AND    hp.duns_number_c       >=  '30'          --売上有り
;
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.customer_code   IS '顧客コード';
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.customer_name   IS '顧客名称';
COMMENT ON  COLUMN  xxcos_vd_sales_cust_v.sale_base_code  IS '売上拠点コード';
--
COMMENT ON  TABLE   xxcos_vd_sales_cust_v                 IS '自販機販売報告書用顧客ビュー';
