/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : XXCFO_SECURITY_CHIIKI_V
 * Description     : �n��c�ƃZ�L�����e�B�r���[
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2013/02/14     1.0   T.Ishiwata       [E_�{�ғ�_10421]�V�K�쐬
 * 2013/04/19     1.1   T.Ishiwata       [E_�{�ғ�_10421]�]�ƈ��i���ݑΉ��A�e�[�u���̕ʖ��ύX
 *
 ****************************************************************************************/
CREATE OR REPLACE VIEW xxcfo_security_chiiki_v(
  dept_code    -- ����R�[�h
 ,description  -- ���喼��
)
AS
SELECT /*+ USE_NL(xdv papf fu flvv) */
    xdv.flex_value    AS dept_code
  , xdv.description   AS description
FROM
    xx03_departments_v xdv
  , per_all_people_f   papf
  , fnd_user           fu
  -- �n��c�ƃZ�L�����e�BLOOKUP�ƃ��[�U�̏������_�����������C�����C���r���[
  , (SELECT COUNT(1) cnt
     FROM fnd_lookup_values flv
/* 2013/04/19 Ver1.1 Mod Start */
--        , per_all_people_f  papf
        , per_all_people_f  papf2
/* 2013/04/19 Ver1.1 Mod End   */
        , fnd_user          fu
/* 2013/04/19 Ver1.1 Mod Start */
--     WHERE flv.lookup_code = papf.attribute28
--       AND fu.user_id      = fnd_global.user_id
--       AND fu.employee_id  = papf.person_id
     WHERE flv.lookup_code = papf2.attribute28
       AND fu.user_id      = fnd_global.user_id
       AND fu.employee_id  = papf2.person_id
/* 2013/04/19 Ver1.1 Mod End   */
       AND flv.lookup_type = 'XXCFO1_SECURITY_CHIIKI'
       AND flv.language    = USERENV('lang')
/* 2013/04/19 Ver1.1 Add Start */
       AND NVL(papf2.effective_start_date, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
       AND NVL(papf2.effective_end_date,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
/* 2013/04/19 Ver1.1 Add End   */
       AND NVL(flv.start_date_active, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
       AND NVL(flv.end_date_active,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
    ) flvv
WHERE
  fu.user_id = fnd_global.user_id
  AND fu.employee_id = papf.person_id
/* 2013/04/19 Ver1.1 Add Start */
  AND NVL(papf.effective_start_date, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
  AND NVL(papf.effective_end_date,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
/* 2013/04/19 Ver1.1 Add End   */
  AND (( flvv.cnt = 0 and xdv.flex_value = papf.attribute28 )  -- �C�����C���r���[�̌������O���̏ꍇ�A���O�C�����[�U�̏������_�ōi����
      OR( flvv.cnt <> 0 ))                                     -- �C�����C���r���[�̌������O���ł͂Ȃ��̏ꍇ�A�i���݂Ȃ�
;
COMMENT ON  COLUMN  xxcfo_security_chiiki_v.dept_code    IS '����R�[�h';
COMMENT ON  COLUMN  xxcfo_security_chiiki_v.description  IS '���喼��';
--
COMMENT ON  TABLE   xxcfo_security_chiiki_v              IS '�n��c�ƃZ�L�����e�B�r���[';
