  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOK_BASE_CHILD_V" ("BASE_CODE", "BASE_NAME") AS 
  SELECT  ffvnh.child_flex_value_high AS base_code, -- 拠点コード
          hca.account_name            AS base_name  -- 拠点名
  FROM    fnd_flex_value_norm_hierarchy ffvnh,
          fnd_flex_values_vl ffvv,
          hz_cust_accounts hca
  WHERE   ffvnh.parent_flex_value = (SELECT ffvnh.parent_flex_value
                                     FROM   fnd_flex_value_sets ffvs,
                                            fnd_flex_value_norm_hierarchy ffvnh
                                     WHERE  ffvs.flex_value_set_name    = 'XX03_DEPARTMENT'
                                     AND    ffvs.flex_value_set_id      = ffvnh.flex_value_set_id
                                     AND    ffvnh.child_flex_value_high =
                                                         xxcok_common_pkg.get_base_code_f( SYSDATE,fnd_global.user_id )
                                    )
  AND     ffvv.value_category         = 'XX03_DEPARTMENT'
  AND     ffvnh.child_flex_value_high = ffvv.flex_value
  AND     hca.account_number          = ffvv.flex_value
  AND     hca.customer_class_code     = '1'
  ORDER BY ffvnh.child_flex_value_high
;
 