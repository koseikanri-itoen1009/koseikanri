/*************************************************************************
 * 
 * VIEW Name       : XXCSO_ROUTE_MANAGEMENT_BASE_V
 * Description     : ルート管理用拠点セキュリティビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2018/02/15    1.0   K.Kiriu      初回作成(E_本稼動_14722)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_route_management_base_v(
  base_code
 ,base_name
)
AS
SELECT  xcav.account_number base_code
       ,xcav.party_name     base_name
FROM    xxcso_cust_accounts_v xcav
WHERE   xcav.customer_class_code = '1'
AND     xcav.account_number = ( SELECT xxcso_util_common_pkg.get_rs_base_code(
                                         xrv.resource_id
                                        ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                                       ) base_code
                                FROM   xxcso_resources_v2 xrv
                                WHERE  xrv.user_id = fnd_global.user_id
                              )
AND     '0' = FND_PROFILE.VALUE('XXCSO1_SECURITY_019_A09')
UNION
SELECT  xcav.account_number base_code
       ,xcav.party_name     base_name
FROM    xxcso_cust_accounts_v xcav
WHERE   xcav.customer_class_code = '1'
AND     xcav.management_base_code = ( SELECT xxcso_util_common_pkg.get_rs_base_code(
                                               xrv.resource_id
                                              ,TRUNC(xxcso_util_common_pkg.get_online_sysdate)
                                             ) base_code
                                      FROM   xxcso_resources_v2 xrv
                                      WHERE  xrv.user_id = fnd_global.user_id
                                    )
AND     '0' = FND_PROFILE.VALUE('XXCSO1_SECURITY_019_A09')
UNION ALL
SELECT  xcav.account_number base_code
       ,xcav.party_name     base_name
FROM    xxcso_cust_accounts_v xcav
WHERE   xcav.customer_class_code = '1'
AND     '1' = FND_PROFILE.VALUE('XXCSO1_SECURITY_019_A09')
/
COMMENT ON COLUMN xxcso_route_management_base_v.base_code IS '拠点コード';
COMMENT ON COLUMN xxcso_route_management_base_v.base_name IS '拠点名';
COMMENT ON TABLE xxcso_route_management_base_v            IS 'ルート管理用拠点セキュリティビュー';
