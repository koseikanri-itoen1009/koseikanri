/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_021A02_LINES_V
 * Description : �≮�������Ϗ��˂����킹��ʁi���ׁj�r���[
 * Version     : 1.7
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *  2009/03/12    1.1   K.Yamaguchi      [��QT1_0014]���ڒǉ�
 *  2009/04/21    1.2   K.Yamaguchi      [��QT1_0531]�x���P�����O�̏ꍇ�A
 *                                                    ���Ϗ��̌������s��Ȃ�
 *  2009/09/01    1.3   S.Moriyama       [��Q0001230]OPM�i�ڃ}�X�^�擾�����ǉ�
 *  2009/09/11    1.4   K.Yamaguchi      [��Q0001353]��Q0001230����̏�Q�Ή�
 *  2012/07/05    1.5   T.Osawa          [E_�{�ғ�_08317] �≮���������׃e�[�u���ɒ��o������ǉ�
 *  2017/03/02    1.6   S.Niki           [E_�{�ғ�_14059] �ƑԒ����ނ̌����������C��
 *  2017/06/06    1.7   S.Niki           [E_�{�ғ�_14226] �≮�������Ϗ��˂����킹PT�Ή�
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_021a02_lines_v(
  row_id
, wholesale_bill_detail_id
, wholesale_bill_header_id
, supplier_code
, expect_payment_date
, selling_month
, base_code
, bill_no
, cust_code
, sales_outlets_code
, sales_outlets_name
, item_code_dsp
, item_name_dsp
, acct_code
, sub_acct_code
, demand_unit_type
, demand_qty
, demand_unit_price
, payment_qty
, payment_unit_price
, revise_flag
, status
, status_func
, payment_creation_date
, item_code
, gyotai_chu
, vessel_group
, created_by
, creation_date
, last_updated_by
, last_update_date
, last_update_login
)
AS
SELECT xwbl.ROWID                       AS row_id
     , xwbl.wholesale_bill_detail_id    AS wholesale_bill_detail_id   -- �≮����������ID
     , xwbl.wholesale_bill_header_id    AS wholesale_bill_header_id   -- �≮�������w�b�_ID
     , xwbh.supplier_code               AS supplier_code              -- �d����R�[�h
     , xwbh.expect_payment_date         AS expect_payment_date        -- �x���\���
     , xwbl.selling_month               AS selling_month              -- ����Ώ۔N��
     , xwbh.base_code                   AS base_code                  -- ���_�R�[�h
     , xwbl.bill_no                     AS bill_no                    -- ������No.
     , xwbh.cust_code                   AS cust_code                  -- �ڋq�R�[�h
     , xwbl.sales_outlets_code          AS sales_outlets_code         -- �≮������R�[�h
     , hp.party_name                    AS sales_outlets_name         -- �≮�����於
     , NVL( xwbl.item_code
          , xwbl.acct_code || '-' || xwbl.sub_acct_code )
                                        AS item_code_dsp              -- �i���R�[�h
     , CASE
       WHEN xwbl.item_code IS NOT NULL THEN
         item.item_short_name
       ELSE
         acct.acct_name
       END                              AS item_name_dsp              -- �i��
     , xwbl.acct_code                   AS acct_code                  -- ����ȖڃR�[�h
     , xwbl.sub_acct_code               AS sub_acct_code              -- �⏕�ȖڃR�[�h
     , xwbl.demand_unit_type            AS demand_unit_type           -- �����P��
     , xwbl.demand_qty                  AS demand_qty                 -- ��������
     , xwbl.demand_unit_price           AS demand_unit_price          -- �����P��
     , xwbl.payment_qty                 AS payment_qty                -- �x������
     , xwbl.payment_unit_price          AS payment_unit_price         -- �x���P��
     , xwbl.revise_flag                 AS revise_flag                -- �Ɗǒ����t���O
     , xwbl.status                      AS status                     -- �X�e�[�^�X�R�[�h
-- 2009/04/21 Ver.1.2 [��QT1_0531] SCS K.Yamaguchi REPAIR START
--     , xxcok_common_pkg.get_wholesale_req_est_type_f(
--         xca.wholesale_ctrl_code    -- �≮�Ǘ��R�[�h
--       , xwbl.sales_outlets_code    -- �≮������R�[�h
--       , xwbl.item_code             -- �i�ڃR�[�h
--       , xwbl.payment_unit_price    -- �����P��
--       , xwbl.demand_unit_type      -- �����P��
--       , xwbl.selling_month         -- ����Ώ۔N��
--       )                                AS status_func                -- �֐��߂�l�i�X�e�[�^�X�j
     , CASE
       WHEN xwbl.payment_unit_price <> 0 THEN
         xxcok_common_pkg.get_wholesale_req_est_type_f(
           xca.wholesale_ctrl_code    -- �≮�Ǘ��R�[�h
         , xwbl.sales_outlets_code    -- �≮������R�[�h
         , xwbl.item_code             -- �i�ڃR�[�h
         , xwbl.payment_unit_price    -- �����P��
         , xwbl.demand_unit_type      -- �����P��
         , xwbl.selling_month         -- ����Ώ۔N��
         )
       END                              AS status_func                -- �֐��߂�l�i�X�e�[�^�X�j
-- 2009/04/21 Ver.1.2 [��QT1_0531] SCS K.Yamaguchi REPAIR END
     , xwbl.payment_creation_date       AS payment_creation_date      -- �x���f�[�^�쐬�N����
     , xwbl.item_code                   AS item_code                  -- �i�ڃR�[�h�i���j
     , flv.attribute1                   AS gyotai_chu                 -- ������
     , item.vessel_group                AS vessel_group               -- �e��Q�R�[�h
     , xwbl.created_by                  AS created_by                 -- �쐬��
     , xwbl.creation_date               AS creation_date              -- �쐬��
     , xwbl.last_updated_by             AS last_updated_by            -- �ŏI�X�V��
     , xwbl.last_update_date            AS last_update_date           -- �ŏI�X�V��
     , xwbl.last_update_login           AS last_update_login          -- �ŏI�X�V���O�C��
FROM xxcok_wholesale_bill_line     xwbl      -- �≮���������׃e�[�u��
   , xxcok_wholesale_bill_head     xwbh      -- �≮�������w�b�_�e�[�u��
   , xxcmm_cust_accounts           xca       -- �ڋq�ǉ����i�ڋq�j
   , hz_cust_accounts              hca2      -- �ڋq�}�X�^�i�ڋq�j
   , hz_cust_accounts              hca       -- �ڋq�}�X�^�i�≮������j
   , hz_parties                    hp        -- �p�[�e�B�}�X�^�i�≮������j
   , fnd_lookup_values             flv       -- �N�C�b�N�R�[�h�i�Ƒԏ����ށj
   , ( SELECT iimb.item_no              AS item_no             -- �i���R�[�h
            , ximb.item_short_name      AS item_short_name     -- ����
            , xsib.vessel_group         AS vessel_group        -- �e��Q
-- 2009/09/01 Ver.1.3 [��Q0001230] SCS S.Moriyama ADD START
            , ximb.start_date_active    AS start_date_active   -- �K�p�J�n��
            , ximb.end_date_active      AS end_date_active     -- �K�p�I����
-- 2009/09/01 Ver.1.3 [��Q0001230] SCS S.Moriyama ADD END
-- Ver.1.7 MOD START
--       FROM mtl_parameters         mp
--          , mtl_system_items_b     msib
--          , xxcmm_system_items_b   xsib
       FROM xxcmm_system_items_b   xsib
-- Ver.1.7 MOD END
          , ic_item_mst_b          iimb
          , xxcmn_item_mst_b       ximb
-- Ver.1.7 MOD START
--       WHERE mp.organization_id     = msib.organization_id
--         AND msib.segment1          = xsib.item_code
--         AND msib.segment1          = iimb.item_no
--         AND xsib.item_id           = iimb.item_id
       WHERE xsib.item_id           = iimb.item_id
-- Ver.1.7 MOD END
         AND iimb.item_id           = ximb.item_id
-- Ver.1.7 DEL START
--         AND mp.organization_code   = FND_PROFILE.VALUE( 'XXCOK1_ORG_CODE_SALES' )
-- Ver.1.7 DEL END
     )                             item      -- �i�ڃ}�X�^
   , ( SELECT ffv1.flex_value                AS acct_code           -- ����ȖڃR�[�h
            , ffv2.flex_value                AS sub_acct_code       -- �⏕�ȖڃR�[�h
            ,           ffvt1.description
              || '-' || ffvt2.description    AS acct_name           -- ����Ȗږ�-�⏕�Ȗږ�
       FROM fnd_flex_value_sets    ffvs1
          , fnd_flex_values        ffv1
          , fnd_flex_values_tl     ffvt1
          , fnd_flex_value_sets    ffvs2
          , fnd_flex_values        ffv2
          , fnd_flex_values_tl     ffvt2
       WHERE ffvs1.flex_value_set_id         = ffv1.flex_value_set_id
         AND ffv1.flex_value_id              = ffvt1.flex_value_id
         AND ffvt1.language                  = USERENV( 'LANG' )
         AND ffvs1.flex_value_set_name       = 'XX03_ACCOUNT'
         AND ffvs2.flex_value_set_id         = ffv2.flex_value_set_id
         AND ffv2.flex_value_id              = ffvt2.flex_value_id
         AND ffvt2.language                  = USERENV( 'LANG' )
         AND ffvs2.flex_value_set_name       = 'XX03_SUB_ACCOUNT'
         AND ffv2.parent_flex_value_low      = ffv1.flex_value
     )                             acct      -- AFF����Ȗ�
WHERE xwbl.wholesale_bill_header_id     = xwbh.wholesale_bill_header_id
  AND xwbh.cust_code                    = hca2.account_number
  AND hca2.cust_account_id              = xca.customer_id
  AND xwbl.sales_outlets_code           = hca.account_number
  AND hca.party_id                      = hp.party_id
  AND xwbl.item_code                    = item.item_no(+)
  AND xwbl.acct_code                    = acct.acct_code(+)
  AND xwbl.sub_acct_code                = acct.sub_acct_code(+)
-- 2012/07/05 Ver.1.5 [��QE_�{�ғ�_08317] SCSK T.Osawa ADD START
  AND (
      xwbl.status                       IS NULL
   OR xwbl.status                       <> 'D')
-- 2012/07/05 Ver.1.5 [��QE_�{�ғ�_08317] SCSK T.Osawa ADD END
  AND flv.lookup_type                   = 'XXCMM_CUST_GYOTAI_SHO'
-- Ver.1.6 MOD START
--  AND flv.lookup_code                   = hca.customer_class_code
  AND flv.lookup_code                   = xca.business_low_type
-- Ver.1.6 MOD END
  AND flv.language                      = USERENV( 'LANG' )
-- 2009/09/11 Ver.1.4 [��Q0001353] SCS K.Yamaguchi REPAIR START
---- 2009/09/01 Ver.1.3 [��Q0001230] SCS S.Moriyama ADD START
--  AND xwbh.expect_payment_date BETWEEN item.start_date_active
--                                   AND NVL ( item.end_date_active , xwbh.expect_payment_date )
---- 2009/09/01 Ver.1.3 [��Q0001230] SCS S.Moriyama ADD END
  AND xwbh.expect_payment_date BETWEEN NVL ( item.start_date_active, xwbh.expect_payment_date )
                                   AND NVL ( item.end_date_active  , xwbh.expect_payment_date )
-- 2009/09/11 Ver.1.4 [��Q0001353] SCS K.Yamaguchi REPAIR END
/
COMMENT ON TABLE  apps.xxcok_021a02_lines_v                                IS '�≮�������Ϗ��˂����킹��ʁi���ׁj�r���['
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.row_id                         IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.wholesale_bill_detail_id       IS '�≮����������ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.wholesale_bill_header_id       IS '�≮�������w�b�_ID'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.supplier_code                  IS '�d����R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.expect_payment_date            IS '�x���\���'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.selling_month                  IS '����Ώ۔N��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.base_code                      IS '���_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.bill_no                        IS '������No.'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.cust_code                      IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.sales_outlets_code             IS '�≮������R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.sales_outlets_name             IS '�≮�����於'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.item_code_dsp                  IS '�i���R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.item_name_dsp                  IS '�i��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.acct_code                      IS '����ȖڃR�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.sub_acct_code                  IS '�⏕�ȖڃR�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.demand_unit_type               IS '�����P��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.demand_qty                     IS '��������'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.demand_unit_price              IS '�����P��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.payment_qty                    IS '�x������'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.payment_unit_price             IS '�x���P��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.revise_flag                    IS '�Ɗǒ����t���O'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.status                         IS '�X�e�[�^�X�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.status_func                    IS '�֐��߂�l�i�X�e�[�^�X�j'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.payment_creation_date          IS '�x���f�[�^�쐬�N����'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.item_code                      IS '�i�ڃR�[�h�i���j'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.gyotai_chu                     IS '������'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.vessel_group                   IS '�e��Q�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.created_by                     IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.creation_date                  IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.last_updated_by                IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.last_update_date               IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_021a02_lines_v.last_update_login              IS '�ŏI�X�V���O�C��'
/
