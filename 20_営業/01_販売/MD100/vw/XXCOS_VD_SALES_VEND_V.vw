/************************************************************************
 * Copyright c 2011, SCSK Corporation. All rights reserved.
 *
 * View Name       : xxcos_vd_sales_vend_v
 * Description     : 自販機販売報告書用仕入先(拠点用)ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2012/02/09    1.0   K.Kiriu          [E_本稼動_08359]新規作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_vd_sales_vend_v(
  vendor_code  -- 仕入先コード
 ,vendor_name  -- 仕入先名称
)
AS
-- ユーザ拠点(管理下込み)が売上拠点の仕入先
SELECT /*+
         NO_MERGE(xlbiv1)
       */
       DISTINCT
       pv1.segment1        vendor_code
      ,REPLACE( pv1.vendor_name, pv1.segment1, '' )
                           vendor_name
FROM   xxcos_login_base_info_v xlbiv1  --ユーザ拠点ビュー
      ,xxcmm_cust_accounts     xca1    --顧客追加情報
      ,hz_cust_accounts        hca1    --顧客マスタ
      ,hz_parties              hp1     --パーティマスタ
      ,po_vendors              pv1     --仕入先マスタ
WHERE  xlbiv1.base_code              =  xca1.sale_base_code
AND    xca1.business_low_type        =  '25'                   --フルVD(フルVD消化は仕入先なしかダミー)
AND    xca1.customer_id              =  hca1.cust_account_id
AND    hca1.customer_class_code      =  '10'                   --顧客区分(顧客)
AND    hca1.party_id                 =  hp1.party_id
AND    hp1.duns_number_c             >= '30'                   --顧客ステータス(売上が上がるステータス)
AND    xca1.contractor_supplier_code =  pv1.segment1           --BM1の仕入先
UNION
-- 自拠点が問合せ担当拠点の仕入先
SELECT /*+
         NO_MERGE(xlbiv2)
       */
       DISTINCT
       pv2.segment1        vendor_code
      ,REPLACE( pv2.vendor_name, pv2.segment1, '' )
                           vendor_name
FROM   xxcos_login_base_info_v      xlbiv2  --ユーザ拠点ビュー
      ,po_vendor_sites_all          pvsa2   --仕入先サイト
      ,po_vendors                   pv2     --仕入先マスタ
WHERE  xlbiv2.base_code  =    pvsa2.attribute5
AND    pv2.segment1      LIKE '8%'
AND    pvsa2.vendor_id   =    pv2.vendor_id
AND    EXISTS (
         SELECT /*+
                  INDEX(xca2 XXCMM_CUST_ACCOUNTS_N02)
                */
                1
         FROM   xxcmm_cust_accounts xca2    --顧客追加情報
               ,hz_cust_accounts    hca2    --顧客マスタ
               ,hz_parties          hp2     --パーティマスタ
         WHERE  xca2.contractor_supplier_code =  pv2.segment1         --BM1の仕入先
         AND    xca2.business_low_type        =  '25'                 --フルVD(フルVD消化は仕入先なしかダミー)
         AND    xca2.customer_id              =  hca2.cust_account_id
         AND    hca2.customer_class_code      =  '10'                 --顧客区分(顧客)
         AND    hca2.party_id                 =  hp2.party_id
         AND    hp2.duns_number_c             >= '30'                 --顧客ステータス(売上が上がるステータス)
         AND    ROWNUM                        = 1
       )
;
COMMENT ON  COLUMN  xxcos_vd_sales_vend_v.vendor_code  IS '仕入先コード';
COMMENT ON  COLUMN  xxcos_vd_sales_vend_v.vendor_name  IS '仕入先名称';
--
COMMENT ON  TABLE   xxcos_vd_sales_vend_v              IS '自販機販売報告書用仕入先(拠点用)ビュー';
