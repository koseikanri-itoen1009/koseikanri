/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_SELLING_TRNS_FROM_V
 * Description : ����U�֌����r���[
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW xxcok_selling_trns_from_v
AS
  SELECT xsfi.ROWID                  AS row_id
       , xsfi.selling_from_info_id   AS selling_from_info_id
       , xsfi.selling_from_cust_code AS selling_from_cust_code
       , base.base_code              AS selling_from_base_code
       , hp.party_name               AS selling_from_cust_name
       , base.base_name              AS selling_from_base_name
       , people.charge_code          AS selling_from_charge_code
       , people.charge_name          AS selling_from_charge_name
       , xsfi.created_by             AS created_by
       , xsfi.creation_date          AS creation_date
       , xsfi.last_updated_by        AS last_updated_by
       , xsfi.last_update_date       AS last_update_date
       , xsfi.last_update_login      AS last_update_login
  FROM   xxcok_selling_from_info xsfi
       , hz_cust_accounts        hca
       , hz_parties              hp
       , xxcmm_cust_accounts     xca
       , (
         SELECT hca.account_number AS base_code
              , hp.party_name      AS base_name
         FROM   hz_cust_accounts hca
              , hz_parties       hp
         WHERE  hca.party_id = hp.party_id
         AND    hca.customer_class_code   = '1'
         ) base
       , (
         SELECT hop.party_id                                            AS party_id
              , jrre.source_number                                      AS charge_code
              , papf.per_information18 || ' ' || papf.per_information19 AS charge_name
         FROM   hz_organization_profiles hop
              , ego_resource_agv         era
              , jtf_rs_resource_extns    jrre
              , per_all_people_f         papf
         WHERE  hop.organization_profile_id    = era.organization_profile_id
         AND    jrre.source_number             = era.resource_no
         AND    papf.person_id                 = jrre.source_id
         AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC(SYSDATE)
         AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC(SYSDATE)
         AND    TRUNC( NVL( era.resource_s_date,       SYSDATE ) ) <= TRUNC(SYSDATE)
         AND    TRUNC( NVL( era.resource_e_date,       SYSDATE ) ) >= TRUNC(SYSDATE)
         AND    TRUNC( NVL( papf.effective_start_date, SYSDATE ) ) <= TRUNC(SYSDATE)
         AND    TRUNC( NVL( papf.effective_end_date,   SYSDATE ) ) >= TRUNC(SYSDATE)
         ) people
  WHERE  xsfi.selling_from_cust_code  = hca.account_number
  AND    hca.party_id                 = hp.party_id
  AND    hca.cust_account_id          = xca.customer_id
  AND    xca.sale_base_code           = base.base_code  (+)
  AND    hca.party_id                 = people.party_id (+)
  AND    hca.customer_class_code     <> '12'
  AND    hp.duns_number_c             = '40'
  AND    xca.selling_transfer_div     = '1'
  AND    xca.chain_store_code        IS NULL;
/
COMMENT ON TABLE  apps.xxcok_selling_trns_from_v                           IS '����U�֌����r���['
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.row_id                    IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_info_id      IS '����U�֌����ID'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_cust_code    IS '�ڋq�R�[�h�i����U�֌��j'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_base_code    IS '���_�R�[�h�i����U�֌��j'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_cust_name    IS '�ڋq���i����U�֌��j'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_base_name    IS '���_���i����U�֌��j'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_charge_code  IS '�S���c�ƃR�[�h�i����U�֌��j'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.selling_from_charge_name  IS '�S���c�Ɩ��i����U�֌��j'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.created_by                IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.creation_date             IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.last_updated_by           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.last_update_date          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_selling_trns_from_v.last_update_login         IS '�ŏI�X�V���O�C��'
/