CREATE OR REPLACE VIEW xxcfr_bill_customers_v(
/*************************************************************************
 * 
 * View Name       : XXCFR_BILL_CUSTOMERS_V
 * Description     : 請求先顧客ビュー
 * MD.050          : MD.050_LDM_CFR_001
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/11/27    1.0  SCS 吉村 憲司 初回作成
 *  2009/04/07    1.1  SCS 大川 恵   [障害T1_0383] 取得顧客不正対応
 ************************************************************************/
  pay_customer_id,                   -- 入金先顧客ID
  pay_customer_number,               -- 入金先顧客コード
  pay_customer_name,                 -- 入金先顧客名
  receiv_base_code,                  -- 入金拠点コード
  receiv_base_name,                  -- 入金拠点名
  receiv_code1,                      -- 売掛コード1（請求書）
  bill_customer_id,                  -- 請求先顧客ID
  bill_customer_code,                -- 請求先顧客コード
  bill_customer_name,                -- 請求先顧客名
  bill_base_code,                    -- 請求拠点コード
  bill_base_name,                    -- 請求拠点名
  store_code,                        -- 請求先顧客店コード
  tax_div,                           -- 消費税区分
  tax_rounding_rule,                 -- 税金-端数処理
  inv_prt_type,                      -- 請求書出力形式
  cons_inv_flag,                     -- 一括請求書発行フラグ
  org_id                             -- 組織ID
)
AS
  SELECT  NVL(chcar.cust_account_id,bcus.cust_account_id) pay_customer_id,
          NVL(chca.account_number,bcus.customer_code) pay_customer_number,
          NVL(chp.party_name,bcus.customer_name)  pay_customer_name,
          NVL(cxca.receiv_base_code,bcus.bill_base_code) receiv_base_code,
          NVL(cffvv.description,bcus.bill_base_name) receiv_base_name,
          bcus.receiv_code1,
          bcus.cust_account_id,
          bcus.customer_code  bill_customer_code,
          bcus.customer_name  bill_customer_name,
          bcus.bill_base_code,
          bcus.bill_base_name,
          bcus.store_code,
          bcus.tax_div,
          bcus.tax_rounding_rule,
          bcus.inv_prt_type,
          bcus.cons_inv_flag,
          NVL(chcar.org_id,bcus.org_id) org_id
  FROM    hz_cust_acct_relate_all chcar,     -- 顧客関連（入金先-請求先）
          hz_cust_accounts        chca,      -- 顧客（入金先）
          hz_parties              chp,       -- パーティ（入金先）
          xxcmm_cust_accounts     cxca,      -- 顧客アドオン（入金先）
          (SELECT  flex_value,
                   description
           FROM    fnd_flex_values_vl ffv
           WHERE   EXISTS
                   (SELECT  'X'
                    FROM    fnd_flex_value_sets
                    WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                    AND     flex_value_set_id   = ffv.flex_value_set_id)) cffvv,  --値セット値（所属部門）
          (
           --請求先
           SELECT  xhca.cust_account_id,        --請求先顧客ID
                   xhcp.cust_account_profile_id,
                   xhcas.cust_acct_site_id,
                   xhcsu.site_use_id,
                   xhca.party_id,
                   xhp.party_number,
                   xhcsu.attribute4          receiv_code1,         --売掛コード1（請求先）
                   xhca.account_number       customer_code,            --請求先顧客コード
                   xhp.party_name            customer_name,            --請求先顧客名称
                   xhca.status               status,                   --顧客ステータス
                   xhca.customer_type        customer_type,            --顧客タイプ
                   xhca.customer_class_code  customer_class_code,      --顧客区分
                   xxca.bill_base_code       bill_base_code,           --請求拠点コード
                   xffvv.description         bill_base_name,           --請求拠点名
                   xxca.store_code           store_code,               --店舗コード
                   xxca.tax_div              tax_div,                  --消費税区分
                   xhcsu.tax_rounding_rule   tax_rounding_rule,        --税金－端数処理
                   xhcsu.attribute7          inv_prt_type,             --請求書出力形式
                   xhcp.cons_inv_flag        cons_inv_flag,            --一括請求書発行区分
                   xhcas.org_id              org_id                    --組織ID
           FROM    hz_cust_accounts        xhca,                       --顧客アカウント（請求先）
                   hz_parties              xhp,                        --パーティ（請求先）
                   hz_cust_acct_sites_all  xhcas,                      --顧客サイト（請求先）
                   hz_cust_site_uses_all   xhcsu,                      --顧客使用目的（請求先）
                   hz_customer_profiles    xhcp,                       --顧客プロファイル（請求先）
                   xxcmm_cust_accounts     xxca,                       --顧客アドオン（請求先）
                   (SELECT flex_value,
                           description 
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT  'X'
                            FROM    fnd_flex_value_sets
                            WHERE   flex_value_set_name = 'XX03_DEPARTMENT'
                            AND     flex_value_set_id   = ffv.flex_value_set_id)) xffvv  --値セット値（所属部門）
           WHERE   xhca.party_id            = xhp.party_id               
           AND     xhca.customer_class_code = '14'
-- Modify 2009.04.07 Ver1.1 Start
--           AND     xhca.status              = 'A'                       --ステータス
-- Modify 2009.04.07 Ver1.1 END
           AND     xhca.cust_account_id     = xhcas.cust_account_id
-- Modify 2009.04.07 Ver1.1 Start
           AND     xhcas.org_id             = fnd_profile.value('ORG_ID') -- 請求先顧客所在地
-- Modify 2009.04.07 Ver1.1 END
           AND     xhcas.bill_to_flag       IS NOT NULL                 --
           AND     xhcas.cust_acct_site_id  = xhcsu.cust_acct_site_id
           AND     xhcsu.site_use_code      = 'BILL_TO'                 --使用目的
-- Modify 2009.04.07 Ver1.1 Start
           AND     xhcsu.primary_flag       = 'Y'
           AND     xhcsu.status             = 'A'                       --ステータス
-- Modify 2009.04.07 Ver1.1 END
           AND     xhca.cust_account_id     = xhcp.cust_account_id
           AND     xhcp.site_use_id         IS NULL
           AND     xhca.cust_account_id     = xxca.customer_id(+)
           AND     xxca.bill_base_code      = xffvv.flex_value(+)
           AND     EXISTS
                   (SELECT   'X'
                    FROM     hz_cust_acct_relate_all hcar
                    WHERE    hcar.attribute1  = '1'
                    AND      hcar.status      = 'A'
                    AND      hcar.cust_account_id = xhca.cust_account_id
                    )
         UNION ALL
           -- 納品先 AND 請求先
           SELECT  yhca.cust_account_id,                               --請求先顧客id
                   yhcp.cust_account_profile_id,
                   yhcas.cust_acct_site_id,
                   yhcsu.site_use_id,
                   yhca.party_id,
                   yhp.party_number,
                   yhcsu.attribute4          receiv_code1,         --売掛コード1（請求先）
                   yhca.account_number       customer_code,            --請求先顧客コード
                   yhp.party_name            customer_name,            --請求先顧客名称
                   yhca.status               status,                   --顧客ステータス
                   yhca.customer_type        customer_type,            --顧客タイプ
                   yhca.customer_class_code  customer_class_code,      --顧客区分
                   yxca.bill_base_code       bill_base_code,           --請求拠点コード
                   yffvv.description         bill_base_name,           --請求拠点名
                   yxca.store_code           store_code,               --店舗コード
                   yxca.tax_div              tax_div,                  --消費税区分
                   yhcsu.tax_rounding_rule   tax_rounding_rule,        --税金－端数処理
                   yhcsu.attribute7          inv_prt_type,             --請求書出力形式
                   yhcp.cons_inv_flag        cons_inv_flag,            --一括請求書発行区分
                   yhcas.org_id              org_id                    --組織ID
           FROM    hz_cust_accounts        yhca,                       --顧客アカウント（請求先）
                   hz_parties              yhp,                        --パーティ（請求先）
                   hz_cust_acct_sites_all  yhcas,                      --顧客サイト（請求先）
                   hz_cust_site_uses_all   yhcsu,                      --顧客使用目的（請求先）
                   hz_customer_profiles    yhcp,                       --顧客プロファイル（請求先）
                   xxcmm_cust_accounts     yxca,                       --顧客アドオン（請求先）
                   (SELECT  flex_value,
                           description 
                    FROM   fnd_flex_values_vl ffv
                    WHERE  EXISTS
                           (SELECT   'X'
                            FROM     fnd_flex_value_sets
                            WHERE    flex_value_set_name = 'XX03_DEPARTMENT'
                            AND      flex_value_set_id = ffv.flex_value_set_id)) yffvv  --値セット値（所属部門）
           WHERE   yhca.party_id            = yhp.party_id               
           AND     yhca.customer_class_code = '10'
-- Modify 2009.04.07 Ver1.1 Start
--           AND     yhca.status              = 'A'                       --ステータス
-- Modify 2009.04.07 Ver1.1 END
           AND     yhca.cust_account_id     = yhcas.cust_account_id
           AND     yhcas.bill_to_flag       IS NOT NULL                 --
           AND     yhcas.cust_acct_site_id  = yhcsu.cust_acct_site_id
-- Modify 2009.04.07 Ver1.1 Start
           AND     yhcas.org_id             = fnd_profile.value('ORG_ID') -- 請求先顧客所在地
-- Modify 2009.04.07 Ver1.1 END
           AND     yhcsu.site_use_code      = 'BILL_TO'                 --使用目的
-- Modify 2009.04.07 Ver1.1 Start
           AND     yhcsu.primary_flag       = 'Y'
           AND     yhcsu.status             = 'A'                       --ステータス
-- Modify 2009.04.07 Ver1.1 END
           AND     yhca.cust_account_id     = yhcp.cust_account_id
           AND     yhcp.site_use_id         IS NULL
           AND     yhca.cust_account_id     = yxca.customer_id(+)
           AND     yxca.bill_base_code      = yffvv.flex_value(+)
           AND     NOT EXISTS
                   (SELECT   'X'
                    FROM     hz_cust_acct_relate_all hcar
                    WHERE    hcar.attribute1  = '1'
                    AND      hcar.status      = 'A'
                    AND      hcar.related_cust_account_id = yhca.cust_account_id
                   )
          ) bcus
  WHERE   chcar.related_cust_account_id(+) = bcus.cust_account_id
  AND     chcar.org_id(+)                  = bcus.org_id
  AND     chcar.cust_account_id            = chca.cust_account_id(+)
  AND     chca.party_id                    = chp.party_id(+)
  AND     chca.cust_account_id             = cxca.customer_id(+)
  AND     cxca.receiv_base_code            = cffvv.flex_value(+)
  AND     chcar.status(+)                  = 'A'
;

COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_id        IS '入金先顧客ID';
COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_number    IS '入金先顧客コード';
COMMENT ON COLUMN  xxcfr_bill_customers_v.pay_customer_name      IS '入金先顧客名';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_base_code       IS '入金拠点コード';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_base_name       IS '入金拠点名';
COMMENT ON COLUMN  xxcfr_bill_customers_v.receiv_code1           IS '売掛コード1（請求書）';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_id       IS '請求先顧客ID';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_code     IS '請求先顧客コード';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_customer_name     IS '請求先顧客名';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_base_code         IS '請求拠点コード';
COMMENT ON COLUMN  xxcfr_bill_customers_v.bill_base_name         IS '請求拠点名';
COMMENT ON COLUMN  xxcfr_bill_customers_v.store_code             IS '請求先顧客店コード';
COMMENT ON COLUMN  xxcfr_bill_customers_v.tax_div                IS '消費税区分';
COMMENT ON COLUMN  xxcfr_bill_customers_v.tax_rounding_rule      IS '税金';
COMMENT ON COLUMN  xxcfr_bill_customers_v.inv_prt_type           IS '請求書出力形式';
COMMENT ON COLUMN  xxcfr_bill_customers_v.cons_inv_flag          IS '一括請求書発行フラグ';
COMMENT ON COLUMN  xxcfr_bill_customers_v.org_id                 IS '組織ID';

COMMENT ON TABLE  xxcfr_bill_customers_v IS '請求先顧客ビュー';
