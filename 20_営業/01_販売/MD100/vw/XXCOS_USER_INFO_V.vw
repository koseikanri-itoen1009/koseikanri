/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_user_info_v
 * Description     : ���[�U���view
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Kumamoto       �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_user_info_v (
  user_id
 ,person_id
 ,user_name
 ,base_code
)
AS
  SELECT
   fu.user_id
  ,fu.employee_id
  ,fu.user_name
  ,paaf.ass_attribute5
  FROM
   fnd_user fu
  ,per_all_people_f papf
  ,per_all_assignments_f paaf
  WHERE TRUNC(SYSDATE) BETWEEN TRUNC(fu.start_date) AND NVL(TRUNC(fu.end_date),TRUNC(SYSDATE))
  AND papf.person_id = fu.employee_id
  AND TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date) AND NVL(TRUNC(papf.effective_end_date),TRUNC(SYSDATE))
  AND paaf.person_id = papf.person_id
  AND TRUNC(SYSDATE) BETWEEN TRUNC(paaf.effective_start_date) AND NVL(TRUNC(paaf.effective_end_date),TRUNC(SYSDATE))
;
COMMENT ON  COLUMN  xxcos_user_info_v.user_id           IS  '���[�UID';
COMMENT ON  COLUMN  xxcos_user_info_v.person_id         IS  '�]�ƈ�ID';
COMMENT ON  COLUMN  xxcos_user_info_v.user_name         IS  '���[�U����';
COMMENT ON  COLUMN  xxcos_user_info_v.base_code         IS  '�����R�[�h';
--
COMMENT ON  TABLE   xxcos_user_info_v                   IS  '���[�U���r���[';
