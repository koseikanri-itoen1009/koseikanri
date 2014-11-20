/***********************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_login_base_info_v
 * Description     : ���O�C�����[�U���_�r���[
 * Version         : 1.4
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kakishita      �V�K�쐬
 *  2009/07/17    1.1   K.Atsushiba      ��Q�ԍ�0000488 �Ή�
 *  2009/07/22    1.2   M.Maruyama       ��Q�ԍ�0000640 �Ή�
 *  2009/09/03    1.3   M.Sano           ��Q�ԍ�0001227 �Ή�
 *  2009/10/16    1.4   K.Atsushiba      ��Q�ԍ�0001113 �Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_login_base_info_v (
  base_code,                            --���_�R�[�h
  base_name,                            --���_����
  base_short_name                       --���_����
)
AS
  SELECT
    hca.account_number                  base_code,                              --���_�R�[�h
    hp.party_name                       base_name,                              --���_����
    hca.account_name                    base_short_name                         --���_����
  FROM
    hz_cust_accounts                    hca,                                    --�ڋq�}�X�^
    hz_parties                          hp,                                     --�p�[�e�B�}�X�^
--  2009/07/17 Ver1.1 Add Start
    xxcmm_cust_accounts                 xca,                                    --�ڋq�ǉ����}�X�^
--  2009/07/17 Ver1.1 Add End
    (
      SELECT
        CASE
--  2009/07/17 Ver1.1 Mod Start   
--          WHEN pd.process_date          >= TRUNC(
--                                             NVL( TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
--                                               pd.process_date
--                                             )
--                                           )
          WHEN pd.process_date          >= NVL( TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
                                               pd.process_date
                                             )
--  2009/07/17 Ver1.1 Mod End
          THEN paaf.ass_attribute5                                              --���_�R�[�h�i�V�j
-- 2009/10/16 Ver1.3 Mod Start
          ELSE paaf.ass_attribute6                                              --���_�R�[�h�i���j
--          ELSE paaf.ass_attribute4                                              --���_�R�[�h�i���j
-- 2009/10/16 Ver1.3 Mod Start
        END own_base_code,
        pd.process_date                 process_date                            --�Ɩ����t
      FROM
        fnd_user                        fu,                                     --���[�U�}�X�^
        per_all_people_f                papf,                                   --�]�ƈ��}�X�^
        per_all_assignments_f           paaf,                                   --�A�T�C�������g�}�X�^
        per_person_types                ppt,                                    --�]�ƈ��^�C�v�}�X�^
        (
--  2009/09/03 Ver1.3 Mod Start   
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date
--          FROM
--            dual
          SELECT
            TRUNC( xpd.process_date ) process_date
          FROM
            xxccp_process_dates       xpd
--  2009/09/03 Ver1.3 Mod End   
        )                               pd                                      --�Ɩ����t
      WHERE
        fu.user_id                      = fnd_global.user_id
      AND fu.employee_id                = papf.person_id
      AND papf.person_id                = paaf.person_id
      AND pd.process_date               >= papf.effective_start_date
      AND pd.process_date               <= papf.effective_end_date
      AND pd.process_date               >= paaf.effective_start_date
      AND pd.process_date               <= paaf.effective_end_date
      AND ppt.business_group_id         = fnd_global.per_business_group_id
      AND ppt.system_person_type        = 'EMP'
      AND ppt.active_flag               = 'Y'
      AND papf.person_type_id           = ppt.person_type_id
      )                                 obc                                     --�����_���
  WHERE
    hca.party_id                        = hp.party_id
--  2009/07/17 Ver1.1 Mod Start
--  AND  hca.account_number                = obc.own_base_code
  AND ( hca.account_number                = obc.own_base_code
        OR
        xca.management_base_code          = obc.own_base_code
      )
  AND xca.customer_id               = hca.cust_account_id
--  2009/07/17 Ver1.1 Mod End
  AND hca.customer_class_code           = '1'
--  2009/07/17 Ver1.1 Mod Start
--  AND obc.process_date                  >= TRUNC(
--                                             NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--                                           )                                           
--  2009/07/22 Ver1.2 Del Start
--  AND obc.process_date                  >= NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--  2009/07/22 Ver1.2 Del End
--  2009/07/17 Ver1.1 Mod End
--  2009/07/17 Ver1.1 Del Start
--  UNION
--  SELECT
--    hca.account_number                  base_code,                              --���_�R�[�h
--    hp.party_name                       base_name,                              --���_����
--    hca.account_name                    base_short_name                         --���_����
--  FROM
--    hz_cust_accounts                    hca,                                    --�ڋq�}�X�^
--    hz_parties                          hp,                                     --�p�[�e�B�}�X�^
--    xxcmm_cust_accounts                 xca,                                    --�ڋq�ǉ����}�X�^
--    (
--      SELECT
--        CASE
--          WHEN pd.process_date          >= NVL( TO_DATE( paaf.ass_attribute2,  'RRRRMMDD' ),
--                                                pd.process_date
--                                              )
--          THEN paaf.ass_attribute5                                              --���_�R�[�h�i�V�j
--          ELSE paaf.ass_attribute4                                              --���_�R�[�h�i���j
--        END own_base_code,
--        pd.process_date                 process_date                            --�Ɩ����t
--      FROM
--        fnd_user                        fu,                                     --���[�U�}�X�^
--        per_all_people_f                papf,                                   --�]�ƈ��}�X�^
--        per_all_assignments_f           paaf,                                   --�A�T�C�������g�}�X�^
--        per_person_types                ppt,                                    --�]�ƈ��^�C�v�}�X�^
--        (
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date        --�Ɩ����t
--          FROM
--            dual
--        )                               pd                                      --�Ɩ����t
--      WHERE
--        fu.user_id                      = fnd_global.user_id
--      AND fu.employee_id                = papf.person_id
--      AND papf.person_id                = paaf.person_id
--      AND pd.process_date               >= papf.effective_start_date
--      AND pd.process_date               <= papf.effective_end_date
--      AND pd.process_date               >= paaf.effective_start_date
--      AND pd.process_date               <= paaf.effective_end_date
--      AND ppt.business_group_id         = fnd_global.per_business_group_id
--      AND ppt.system_person_type        = 'EMP'
--      AND ppt.active_flag               = 'Y'
--      AND papf.person_type_id           = ppt.person_type_id
--    )                                   obc                                     --�����_�Ǌ����_���
--  WHERE
--    hca.party_id                        = hp.party_id
--  AND xca.management_base_code          = obc.own_base_code
--  AND  hca.account_number               =    management_base_code
--  AND hca.cust_account_id               = xca.customer_id
--  AND hca.customer_class_code           = '1'
--  AND obc.process_date                  >= NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--  2009/07/17 Ver1.1 Del End
  ;
COMMENT ON  COLUMN  xxcos_login_base_info_v.base_code        IS  '���_�R�[�h'; 
COMMENT ON  COLUMN  xxcos_login_base_info_v.base_name        IS  '���_����';
COMMENT ON  COLUMN  xxcos_login_base_info_v.base_short_name  IS  '���_����';
--
COMMENT ON  TABLE   xxcos_login_base_info_v                  IS  '���O�C�����[�U���_�r���[';
