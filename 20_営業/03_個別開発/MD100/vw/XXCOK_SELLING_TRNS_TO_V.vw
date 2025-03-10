/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_SELLING_TRNS_TO_V
 * Description : 売上振替先情報ビュー
 * Version     : 1.3
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          新規作成
 *  2009/04/06    1.1   M.Hiruta         [障害T1_0307対応] 担当営業員抽出条件のSYSDATEを業務日付へ変更
 *  2009/04/23    1.2   M.Hiruta         [障害T1_0624対応] 組織プロファイルの抽出条件の業務日付をSYSDATEへ変更
 *  2009/06/16    1.3   M.Hiruta         [障害T1_1403対応] 振替割合登録後に実績振替対象外となったデータを
 *                                                         検索できるよう変更
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW xxcok_selling_trns_to_v
AS
-- Start 2009/04/06 Ver_1.1 T1_0307 M.Hiruta
  WITH get_date AS (
    SELECT xxccp_common_pkg2.get_process_date AS process_date
    FROM   DUAL
  )
-- End   2009/04/06 Ver_1.1 T1_0307 M.Hiruta
--
  SELECT xsti.ROWID                AS row_id
       , xsti.selling_to_info_id   AS selling_to_info_id
       , xsti.selling_from_info_id AS selling_from_info_id
       , xsti.selling_to_cust_code AS selling_to_cust_code
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi REPAIR START
--       , base.base_code            AS selling_to_base_code
       , ( SELECT hca.account_number AS base_code
           FROM   hz_cust_accounts hca
                , hz_parties       hp
           WHERE  hca.party_id = hp.party_id
           AND    hca.customer_class_code   = '1'
           AND    xca.sale_base_code         = hca.account_number
         )                         AS selling_to_base_code
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi REPAIR END
       , hp.party_name             AS selling_to_cust_name
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi REPAIR START
--       , base.base_name            AS selling_to_base_name
       , ( SELECT hp.party_name      AS base_name
           FROM   hz_cust_accounts hca
                , hz_parties       hp
           WHERE  hca.party_id = hp.party_id
           AND    hca.customer_class_code   = '1'
           AND    xca.sale_base_code         = hca.account_number
         )                         AS selling_to_base_name
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi REPAIR END
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi REPAIR START
--       , people.charge_code        AS selling_to_charge_code
--       , people.charge_name        AS selling_to_charge_name
       , ( SELECT jrre.source_number                                      AS charge_code
           FROM   hz_organization_profiles hop
                , ego_resource_agv         era
                , jtf_rs_resource_extns    jrre
                , per_all_people_f         papf
           WHERE  hop.organization_profile_id = era.organization_profile_id
           AND    jrre.source_number          = era.resource_no
           AND    papf.person_id              = jrre.source_id
           AND    hca.party_id               = hop.party_id
           AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC( SYSDATE )
           AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC( SYSDATE )
           AND    TRUNC( NVL( era.resource_s_date,       get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( era.resource_e_date,       get_date.process_date ) ) >= get_date.process_date
           AND    TRUNC( NVL( papf.effective_start_date, get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( papf.effective_end_date,   get_date.process_date ) ) >= get_date.process_date
         )                         AS selling_to_charge_code
       , ( SELECT papf.per_information18 || ' ' || papf.per_information19 AS charge_name
           FROM   hz_organization_profiles hop
                , ego_resource_agv         era
                , jtf_rs_resource_extns    jrre
                , per_all_people_f         papf
           WHERE  hop.organization_profile_id = era.organization_profile_id
           AND    jrre.source_number          = era.resource_no
           AND    papf.person_id              = jrre.source_id
           AND    hca.party_id               = hop.party_id
           AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC( SYSDATE )
           AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC( SYSDATE )
           AND    TRUNC( NVL( era.resource_s_date,       get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( era.resource_e_date,       get_date.process_date ) ) >= get_date.process_date
           AND    TRUNC( NVL( papf.effective_start_date, get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( papf.effective_end_date,   get_date.process_date ) ) >= get_date.process_date
         )                         AS selling_to_charge_name
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi REPAIR END
       , xsti.start_month          AS start_month
       , xsti.invalid_flag         AS invalid_flag
       , xsti.created_by           AS created_by
       , xsti.creation_date        AS creation_date
       , xsti.last_updated_by      AS last_updated_by
       , xsti.last_update_date     AS last_update_date
       , xsti.last_update_login    AS last_update_login
  FROM   xxcok_selling_to_info xsti
       , hz_cust_accounts      hca
       , hz_parties            hp
       , xxcmm_cust_accounts   xca
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi ADD START
       , get_date              get_date
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi ADD END
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi DELETE START
--       , (
--         SELECT hca.account_number AS base_code
--              , hp.party_name      AS base_name
--         FROM   hz_cust_accounts hca
--              , hz_parties       hp
--         WHERE  hca.party_id = hp.party_id
--         AND    hca.customer_class_code   = '1'
--         ) base
--       , (
--         SELECT hop.party_id                                            AS party_id
--              , jrre.source_number                                      AS charge_code
--              , papf.per_information18 || ' ' || papf.per_information19 AS charge_name
--         FROM   hz_organization_profiles hop
--              , ego_resource_agv         era
--              , jtf_rs_resource_extns    jrre
--              , per_all_people_f         papf
---- Start 2009/04/06 Ver_1.1 T1_0307 M.Hiruta
--              , get_date                 get_date
---- End   2009/04/06 Ver_1.1 T1_0307 M.Hiruta
--         WHERE  hop.organization_profile_id = era.organization_profile_id
--         AND    jrre.source_number          = era.resource_no
--         AND    papf.person_id              = jrre.source_id
---- Start 2009/04/06 Ver_1.1 T1_0307 M.Hiruta
----         AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC(SYSDATE)
----         AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC(SYSDATE)
----         AND    TRUNC( NVL( era.resource_s_date,       SYSDATE ) ) <= TRUNC(SYSDATE)
----         AND    TRUNC( NVL( era.resource_e_date,       SYSDATE ) ) >= TRUNC(SYSDATE)
----         AND    TRUNC( NVL( papf.effective_start_date, SYSDATE ) ) <= TRUNC(SYSDATE)
----         AND    TRUNC( NVL( papf.effective_end_date,   SYSDATE ) ) >= TRUNC(SYSDATE)
---- End   2009/04/06 Ver_1.1 T1_0307 M.Hiruta
---- Start 2009/04/23 Ver_1.2 T1_0624 M.Hiruta
----         AND    TRUNC( NVL( hop.effective_start_date,  get_date.process_date ) ) <= get_date.process_date
----         AND    TRUNC( NVL( hop.effective_end_date,    get_date.process_date ) ) >= get_date.process_date
--         AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC(SYSDATE)
--         AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC(SYSDATE)
---- End   2009/04/23 Ver_1.2 T1_0624 M.Hiruta
---- Start 2009/04/06 Ver_1.1 T1_0307 M.Hiruta
--         AND    TRUNC( NVL( era.resource_s_date,       get_date.process_date ) ) <= get_date.process_date
--         AND    TRUNC( NVL( era.resource_e_date,       get_date.process_date ) ) >= get_date.process_date
--         AND    TRUNC( NVL( papf.effective_start_date, get_date.process_date ) ) <= get_date.process_date
--         AND    TRUNC( NVL( papf.effective_end_date,   get_date.process_date ) ) >= get_date.process_date
---- End   2009/04/06 Ver_1.1 T1_0307 M.Hiruta
--         ) people
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi DELETE END
  WHERE  xsti.selling_to_cust_code  = hca.account_number
  AND    hca.party_id               = hp.party_id
  AND    hca.cust_account_id        = xca.customer_id
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi DELETE START
--  AND    xca.sale_base_code         = base.base_code  (+)
--  AND    hca.party_id               = people.party_id (+)
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi DELETE END
  AND    hca.customer_class_code   <> '12'
-- Start 2009/06/16 Ver_1.3 T1_1403 M.Hiruta
--  AND    hp.duns_number_c           = '40'
--  AND    xca.selling_transfer_div   = '1'
-- End   2009/06/16 Ver_1.3 T1_1403 M.Hiruta
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi DELETE START
--  AND    xca.chain_store_code      IS NULL
-- 2009/08/24 Ver.1.4 [障害0001157] SCS K.Yamaguchi DELETE END
/
COMMENT ON TABLE  apps.xxcok_selling_trns_to_v                         IS '売上振替先情報ビュー'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.row_id                  IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_info_id      IS '売上振替先情報ID'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_from_info_id    IS '売上振替元情報ID'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_cust_code    IS '顧客コード（売上振替先）'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_base_code    IS '拠点コード（売上振替先）'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_cust_name    IS '顧客名（売上振替先）'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_base_name    IS '拠点名（売上振替先）'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_charge_code  IS '担当営業コード（売上振替先）'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.selling_to_charge_name  IS '担当営業名（売上振替先）'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.start_month             IS '振替開始月'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.invalid_flag            IS '無効フラグ'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.created_by              IS '作成者'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.creation_date           IS '作成日'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.last_updated_by         IS '最終更新者'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.last_update_date        IS '最終更新日'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_to_v.last_update_login       IS '最終更新ログイン'
/
