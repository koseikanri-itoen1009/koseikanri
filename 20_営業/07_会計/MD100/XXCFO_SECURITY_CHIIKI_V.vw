/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : XXCFO_SECURITY_CHIIKI_V
 * Description     : �n��c�ƃZ�L�����e�B�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2013/02/14     1.0   T.Ishiwata       [E_�{�ғ�_10421]�V�K�쐬
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
        , per_all_people_f  papf
        , fnd_user          fu
     WHERE flv.lookup_code = papf.attribute28
       AND fu.user_id      = fnd_global.user_id
       AND fu.employee_id  = papf.person_id
       AND flv.lookup_type = 'XXCFO1_SECURITY_CHIIKI'
       AND flv.language    = USERENV('lang')
       AND NVL(flv.start_date_active, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
       AND NVL(flv.end_date_active,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
    ) flvv
WHERE
  fu.user_id = fnd_global.user_id
  AND fu.employee_id = papf.person_id
  AND (( flvv.cnt = 0 and xdv.flex_value = papf.attribute28 )  -- �C�����C���r���[�̌������O���̏ꍇ�A���O�C�����[�U�̏������_�ōi����
      OR( flvv.cnt <> 0 ))                                     -- �C�����C���r���[�̌������O���ł͂Ȃ��̏ꍇ�A�i���݂Ȃ�
;
COMMENT ON  COLUMN  xxcfo_security_chiiki_v.dept_code    IS '����R�[�h';
COMMENT ON  COLUMN  xxcfo_security_chiiki_v.description  IS '���喼��';
--
COMMENT ON  TABLE   xxcfo_security_chiiki_v              IS '�n��c�ƃZ�L�����e�B�r���[';
