/*************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 * 
 * View Name       : XXCSO_RESOURCES_SECURITY_V
 * Description     : 共通用：リソースセキュリティビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2013/10/03    1.0   S.Niki       初回作成
 *
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_RESOURCES_SECURITY_V
(
  base_code
, base_name
)
AS
SELECT base.base_code         -- 拠点コード
     , base.base_name         -- 拠点名
FROM
( SELECT DECODE( FND_PROFILE.VALUE('XXCSO1_RS_SECURITY_LEVEL') --XXCSO:リソースセキュリティレベル
               , '1', '1'  --セキュリティあり
               , '0'       --セキュリティなし
         )        security_type
  FROM   DUAL
) sec,
(
  --セキュリティあり（自拠点・管理元の場合は配下の拠点も）
  SELECT 1                 security_type
       , ffv.flex_value    base_code
       , ffv.attribute4    base_name
  FROM   jtf_rs_defresources_vl r
       , fnd_flex_value_sets    ffvs 
       , fnd_flex_values        ffv
       , fnd_flex_values_tl     ffvt
  WHERE  ffvs.flex_value_set_id    = ffv.flex_value_set_id
  AND    ffv.flex_value_id         = ffvt.flex_value_id
  AND    ffvt.language             = 'JA'
  AND    ffv.enabled_flag          = 'Y'
  AND    ffv.summary_flag          = 'N'
  AND    ffvs.flex_value_set_name  = 'XX03_DEPARTMENT'
  AND    r.category                = 'EMPLOYEE'
  AND    r.user_id                 = FND_GLOBAL.USER_ID
  AND  ( xxcso_util_common_pkg.get_rs_base_code(
            r.resource_id
           ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
         )                         = ffv.flex_value
    OR    EXISTS ( SELECT 'X'
                   FROM   hz_cust_accounts    hca
                        , xxcmm_cust_accounts xca
                   WHERE  hca.cust_account_id      = xca.customer_id
                   AND    hca.account_number       = ffv.flex_value
                   AND    hca.customer_class_code  = '1'  -- 顧客区分「1:拠点」
                   AND    xca.management_base_code = xxcso_util_common_pkg.get_rs_base_code(
                                                       r.resource_id
                                                     , TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                                                     )
                 )
       )
  --
  UNION ALL
  --
  --セキュリティなし（全拠点）
  SELECT 0                 security_type
       , ffv.flex_value    base_code
       , ffv.attribute4    base_name
  FROM   fnd_flex_value_sets    ffvs 
       , fnd_flex_values        ffv
       , fnd_flex_values_tl     ffvt
  WHERE  ffvs.flex_value_set_id    = ffv.flex_value_set_id
  AND    ffv.flex_value_id         = ffvt.flex_value_id
  AND    ffvt.language             = 'JA'
  AND    ffv.enabled_flag          = 'Y'
  AND    ffv.summary_flag          = 'N'
  AND    ffvs.flex_value_set_name  = 'XX03_DEPARTMENT'
  AND    EXISTS ( SELECT 'X'
                  FROM   hz_cust_accounts    hca
                       , xxcmm_cust_accounts xca
                  WHERE  hca.cust_account_id      = xca.customer_id
                  AND    hca.account_number       = ffv.flex_value
                  AND    hca.customer_class_code  = '1'  -- 顧客区分「1:拠点」
                )
) base
WHERE sec.security_type            = base.security_type
WITH READ ONLY
;
--
COMMENT ON COLUMN XXCSO_RESOURCES_SECURITY_V.base_code     IS '拠点コード';
COMMENT ON COLUMN XXCSO_RESOURCES_SECURITY_V.base_name     IS '拠点名';
--
COMMENT ON TABLE XXCSO_RESOURCES_SECURITY_V                IS '共通用：リソースセキュリティビュー';
