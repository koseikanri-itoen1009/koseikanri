/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOK_001A01F_V
 * Description : �ڋq�ڍs���͉�ʁi�ڋq�P�ʁj�r���[
 * Version     : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/15    1.0   T.Osada          �V�K�쐬
 *  2011/02/03    1.1   M.Hirose         [E_�{�ғ�_02010,06187]�Ή�
 *
 **************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_001a01f_v(
  row_id
 ,cust_shift_id
 ,cust_code
 ,cust_name
 ,prev_base_code
 ,prev_base_name
 ,new_base_code
 ,new_base_name
 ,target_acctg_year
 ,cust_shift_date
 ,status
 ,emp_code
 ,shift_type
 ,input_date
 ,create_chg_je_flag
 ,vd_inv_trnsfr_status
 ,sale_base_code
 ,management_base_code
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR START
 ,department_code
 ,new_base_code_from
 ,new_base_code_to
 ,customer_class_code
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR END
 ,created_by
 ,creation_date
 ,last_updated_by
 ,last_update_date
 ,last_update_login
)
AS
SELECT xcsi.ROWID                       AS row_id
     , xcsi.cust_shift_id               AS cust_shift_id
     , xcsi.cust_code                   AS cust_code
     , hp1.party_name                   AS cust_name
     , xcsi.prev_base_code              AS prev_base_code
     , hp2.party_name                   AS prev_base_name
     , xcsi.new_base_code               AS new_base_code
     , hp3.party_name                   AS new_base_name
     , xcsi.target_acctg_year           AS target_acctg_year
     , xcsi.cust_shift_date             AS cust_shift_date
     , xcsi.status                      AS status
     , xcsi.emp_code                    AS emp_code
     , xcsi.shift_type                  AS shift_type
     , xcsi.input_date                  AS input_date
     , xcsi.create_chg_je_flag          AS create_chg_je_flag
     , xcsi.vd_inv_trnsfr_status        AS vd_inv_trnsfr_status
     , xca.sale_base_code               AS sale_base_code
     , xca.management_base_code         AS management_base_code
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR START
     , xadv.aff_department_code         AS department_code
     , TRUNC(xadv.start_date_active)    AS new_base_code_from
     , TRUNC(xadv.end_date_active  )    AS new_base_code_to
     , hca1.customer_class_code         AS customer_class_code
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR END
     , xcsi.created_by                  AS created_by
     , xcsi.creation_date               AS creation_date
     , xcsi.last_updated_by             AS last_updated_by
     , xcsi.last_update_date            AS last_update_date
     , xcsi.last_update_login           AS last_update_login
FROM xxcok_cust_shift_info    xcsi
   , hz_cust_accounts         hca1
   , hz_cust_accounts         hca2
   , hz_cust_accounts         hca3
   , hz_parties               hp1
   , hz_parties               hp2
   , hz_parties               hp3
   , xxcmm_cust_accounts      xca
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR START
   , xxcff_aff_department_v   xadv
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR END
WHERE xcsi.cust_code          = hca1.account_number
  AND xcsi.prev_base_code     = hca2.account_number
  AND xcsi.new_base_code      = hca3.account_number
  AND hca1.party_id           = hp1.party_id
  AND hca2.party_id           = hp2.party_id
  AND hca3.party_id           = hp3.party_id
  AND hca1.cust_account_id    = xca.customer_id
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR START
  AND xcsi.new_base_code      = xadv.aff_department_code(+)
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR END
/
COMMENT ON TABLE  apps.xxcok_001a01f_v                           IS '�ڋq�ڍs���͉�ʁi�ڋq�P�ʁj�r���['
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.row_id                    IS 'ROW_ID'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_shift_id             IS '�ڋq�ڍsID'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_code                 IS '�ڋq�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_name                 IS '�ڋq����'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.prev_base_code            IS '�����_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.prev_base_name            IS '�����_����'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_code             IS '�V���_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_name             IS '�V���_����'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.target_acctg_year         IS '�N�x'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.cust_shift_date           IS '�ڋq�ڍs��'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.status                    IS '�X�e�[�^�X'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.emp_code                  IS '�S����'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.shift_type                IS '�ڍs�敪'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.input_date                IS '���͓�'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.create_chg_je_flag        IS '�ޑK�d��쐬�t���O'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.vd_inv_trnsfr_status      IS 'VD�݌ɕۊǏꏊ�]���X�e�[�^�X'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.sale_base_code            IS '����S�����_�R�[�h'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.management_base_code      IS '�Ǘ������_�R�[�h'
/
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR START
COMMENT ON COLUMN apps.xxcok_001a01f_v.department_code           IS '�V���_�R�[�h�iAFF�j'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_code_from        IS '�V���_�R�[�h�J�n��'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.new_base_code_to          IS '�V���_�R�[�h�I����'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.customer_class_code       IS '�ڋq�敪'
/
-- 2011/02/03 Ver.1.1 [E_�{�ғ�_02010,06187] SCS M.Hirose REPAIR END
COMMENT ON COLUMN apps.xxcok_001a01f_v.created_by                IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.creation_date             IS '�쐬��'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.last_updated_by           IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.last_update_date          IS '�ŏI�X�V��'
/
COMMENT ON COLUMN apps.xxcok_001a01f_v.last_update_login         IS '�ŏI�X�V���O�C��'
/
