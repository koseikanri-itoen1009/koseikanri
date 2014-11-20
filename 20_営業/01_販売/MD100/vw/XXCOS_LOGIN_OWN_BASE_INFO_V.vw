/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_login_own_base_info_v
 * Description     : ���O�C�����[�U�����_�r���[
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   K.Kakishita      �V�K�쐬
 *  2009/07/22    1.1   M.Maruyama       ��Q�ԍ�0000640 �Ή�
 *  2009/09/03    1.2   M.Sano           ��Q�ԍ�0001227 �Ή�
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_login_own_base_info_v (
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
    (
      SELECT
        CASE
          WHEN pd.process_date          >= TRUNC(
                                             NVL( TO_DATE( paaf.ass_attribute2, 'RRRRMMDD' ),
                                               pd.process_date
                                             )
                                           )
          THEN paaf.ass_attribute5                                              --���_�R�[�h�i�V�j
          ELSE paaf.ass_attribute4                                              --���_�R�[�h�i���j
        END                             own_base_code,                          --���_�R�[�h
        pd.process_date                 process_date                            --�Ɩ����t
      FROM
        fnd_user                        fu,                                     --���[�U�}�X�^
        per_all_people_f                papf,                                   --�]�ƈ��}�X�^
        per_all_assignments_f           paaf,                                   --�A�T�C�������g�}�X�^
        per_person_types                ppt,                                    --�]�ƈ��^�C�v�}�X�^
        (
-- 2009/09/03 Ver1.2 Mod Start
--          SELECT
--            TRUNC( xxccp_common_pkg2.get_process_date )     process_date        --�Ɩ����t
--          FROM
--            dual
          SELECT TRUNC( xpd.process_date )                  process_date        --�Ɩ����t
          FROM   xxccp_process_dates xpd
-- 2009/09/03 Ver1.2 Mod End
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
    )                                   obc
  WHERE
    hca.party_id                        = hp.party_id
  AND hca.account_number                = obc.own_base_code
  AND hca.customer_class_code           = '1'
--  2009/7/22 Ver1.1 Del Start
--  AND obc.process_date                  >= TRUNC(
--                                             NVL( TO_DATE( hca.attribute3,  'RRRR/MM/DD' ),
--                                               obc.process_date
--                                             )
--                                           )
--  2009/7/22 Ver1.1 Del End
  ;
COMMENT ON  COLUMN  xxcos_login_own_base_info_v.base_code        IS  '���_�R�[�h'; 
COMMENT ON  COLUMN  xxcos_login_own_base_info_v.base_name        IS  '���_����';
COMMENT ON  COLUMN  xxcos_login_own_base_info_v.base_short_name  IS  '���_����';
--
COMMENT ON  TABLE   xxcos_login_own_base_info_v                  IS  '���O�C�����[�U�����_�r���[';
