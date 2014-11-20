/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_vend_all_v
 * Description     : 自販機販売報告書用仕入先(管理者用)ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/02/09    1.0   K.Kiriu          [E_本稼動_08359]新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_vd_sales_vend_all_v(
  vendor_code  -- 仕入先コード
 ,vendor_name  -- 仕入先名称
)
AS
SELECT pv.segment1        vendor_code
      ,REPLACE( pv.vendor_name, pv.segment1, '' )
                          vendor_name
FROM   po_vendors  pv     --仕入先マスタ
WHERE  pv.segment1      LIKE '8%'
AND    EXISTS (
         SELECT /*+
                  INDEX(xca2 XXCMM_CUST_ACCOUNTS_N02)
                */
                1
         FROM   xxcmm_cust_accounts xca    --顧客追加情報
               ,hz_cust_accounts    hca    --顧客マスタ
               ,hz_parties          hp     --パーティマスタ
         WHERE  xca.contractor_supplier_code =  pv.segment1         --BM1の仕入先
         AND    xca.business_low_type        =  '25'                --フルVD(フルVD消化は仕入先なしかダミー)
         AND    xca.customer_id              =  hca.cust_account_id
         AND    hca.customer_class_code      =  '10'                --顧客区分(顧客)
         AND    hca.party_id                 =  hp.party_id
         AND    hp.duns_number_c             >= '30'                --顧客ステータス(売上が上がるステータス)
       )
;
COMMENT ON  COLUMN  xxcos_vd_sales_vend_all_v.vendor_code  IS '仕入先コード';
COMMENT ON  COLUMN  xxcos_vd_sales_vend_all_v.vendor_name  IS '仕入先名称';
--
COMMENT ON  TABLE   xxcos_vd_sales_vend_all_v              IS '自販機販売報告書用仕入先(管理者用)ビュー';
