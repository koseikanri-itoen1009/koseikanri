/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_SELLING_TRNS_FROM_V
 * Description : ����U�֌����r���[
 * Version     : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *  2009/04/06    1.1   M.Hiruta         [��QT1_0199�Ή�] �U�֌����_�̒��o���𔄏�U�֌����e�[�u���֕ύX
 *                                       [��QT1_0307�Ή�] �S���c�ƈ����o������SYSDATE���Ɩ����t�֕ύX
 *  2009/04/23    1.2   M.Hiruta         [��QT1_0624�Ή�] �g�D�v���t�@�C���̒��o�����̋Ɩ����t��SYSDATE�֕ύX
 *  2009/06/16    1.3   M.Hiruta         [��QT1_1403�Ή�] �U�֊����o�^��Ɏ��ѐU�֑ΏۊO�ƂȂ����f�[�^��
 *                                                         �����ł���悤�ύX
 *  2009/08/24    1.4   K.Yamaguchi      [��Q0001157�Ή�] �p�t�H�[�}���X��Q�Ή�
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW xxcok_selling_trns_from_v
AS
-- Start 2009/04/06 Ver_1.1 T1_0307 M.Hiruta
  WITH get_date AS (
    SELECT xxccp_common_pkg2.get_process_date AS process_date
    FROM   DUAL
  )
-- End   2009/04/06 Ver_1.1 T1_0307 M.Hiruta
--
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi REPAIR START
--  SELECT xsfi.ROWID                  AS row_id
  SELECT /*+
           INDEX( hca HZ_CUST_ACCOUNTS_U2 )
           INDEX( hca HZ_PARTIES_U1 )
           INDEX( xca XXCMM_CUST_ACCOUNTS_PK )
         */
         xsfi.ROWID                  AS row_id
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi REPAIR END
       , xsfi.selling_from_info_id   AS selling_from_info_id
       , xsfi.selling_from_cust_code AS selling_from_cust_code
-- Start 2009/04/03 Ver_1.1 T1_0199 M.Hiruta
--       , base.base_code              AS selling_from_base_code
       , xsfi.selling_from_base_code AS selling_from_base_code
-- End   2009/04/03 Ver_1.1 T1_0199 M.Hiruta
       , hp.party_name               AS selling_from_cust_name
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi REPAIR START
--       , base.base_name              AS selling_from_base_name
       , ( SELECT hp.party_name
           FROM   hz_cust_accounts hca
                , hz_parties       hp
           WHERE  hca.party_id                 = hp.party_id
           AND    hca.customer_class_code      = '1'
           AND    xsfi.selling_from_base_code  = hca.account_number
         )                           AS selling_from_base_name
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi REPAIR END
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi REPAIR START
--       , people.charge_code          AS selling_from_charge_code
--       , people.charge_name          AS selling_from_charge_name
       , ( SELECT jrre.source_number                                      AS charge_code
           FROM   hz_organization_profiles hop
                , ego_resource_agv         era
                , jtf_rs_resource_extns    jrre
                , per_all_people_f         papf
                , get_date                 get_date
           WHERE  hop.organization_profile_id    = era.organization_profile_id
           AND    jrre.source_number             = era.resource_no
           AND    papf.person_id                 = jrre.source_id
           AND    hca.party_id                   = hop.party_id
           AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC( SYSDATE )
           AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC( SYSDATE )
           AND    TRUNC( NVL( era.resource_s_date,       get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( era.resource_e_date,       get_date.process_date ) ) >= get_date.process_date
           AND    TRUNC( NVL( papf.effective_start_date, get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( papf.effective_end_date,   get_date.process_date ) ) >= get_date.process_date
         )                           AS selling_from_charge_code
       , ( SELECT papf.per_information18 || ' ' || papf.per_information19 AS charge_name
           FROM   hz_organization_profiles hop
                , ego_resource_agv         era
                , jtf_rs_resource_extns    jrre
                , per_all_people_f         papf
                , get_date                 get_date
           WHERE  hop.organization_profile_id    = era.organization_profile_id
           AND    jrre.source_number             = era.resource_no
           AND    papf.person_id                 = jrre.source_id
           AND    hca.party_id                   = hop.party_id
           AND    TRUNC( NVL( hop.effective_start_date,  SYSDATE ) ) <= TRUNC( SYSDATE )
           AND    TRUNC( NVL( hop.effective_end_date,    SYSDATE ) ) >= TRUNC( SYSDATE )
           AND    TRUNC( NVL( era.resource_s_date,       get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( era.resource_e_date,       get_date.process_date ) ) >= get_date.process_date
           AND    TRUNC( NVL( papf.effective_start_date, get_date.process_date ) ) <= get_date.process_date
           AND    TRUNC( NVL( papf.effective_end_date,   get_date.process_date ) ) >= get_date.process_date
         )                           AS selling_from_charge_name
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi REPAIR END
       , xsfi.created_by             AS created_by
       , xsfi.creation_date          AS creation_date
       , xsfi.last_updated_by        AS last_updated_by
       , xsfi.last_update_date       AS last_update_date
       , xsfi.last_update_login      AS last_update_login
  FROM   xxcok_selling_from_info xsfi
       , hz_cust_accounts        hca
       , hz_parties              hp
       , xxcmm_cust_accounts     xca
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi DELETE START
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
--         WHERE  hop.organization_profile_id    = era.organization_profile_id
--         AND    jrre.source_number             = era.resource_no
--         AND    papf.person_id                 = jrre.source_id
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
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi DELETE END
  WHERE  xsfi.selling_from_cust_code  = hca.account_number
  AND    hca.party_id                 = hp.party_id
  AND    hca.cust_account_id          = xca.customer_id
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi DELETE START
---- Start 2009/04/03 Ver_1.1 T1_0199 M.Hiruta
----  AND    xca.sale_base_code           = base.base_code  (+)
--  AND    xsfi.selling_from_base_code  = base.base_code  (+)
---- End   2009/04/03 Ver_1.1 T1_0199 M.Hiruta
--  AND    hca.party_id                 = people.party_id (+)
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi DELETE END
  AND    hca.customer_class_code     <> '12'
-- Start 2009/06/16 Ver_1.3 T1_1403 M.Hiruta
--  AND    hp.duns_number_c             = '40'
--  AND    xca.selling_transfer_div     = '1'
-- Start 2009/06/16 Ver_1.3 T1_1403 M.Hiruta
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi DELETE START
--  AND    xca.chain_store_code        IS NULL
-- 2009/08/24 Ver.1.4 [��Q0001157] SCS K.Yamaguchi DELETE END
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
