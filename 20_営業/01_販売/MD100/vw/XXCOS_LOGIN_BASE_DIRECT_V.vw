/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_login_base_direct_v
 * Description     : ���O�C�����[�U���_�����r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Miyata         �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_login_base_direct_v (
  base_code,                            --���_�R�[�h
  base_name,                            --���_����
  base_short_name                       --���_����
)
AS
  SELECT
    base_code,                              --���_�R�[�h
    base_name,                              --���_����
    base_short_name                         --���_����
  FROM
    xxcos_login_base_info_v     xlbiv       --���O�C�����[�U���_�r���[
  UNION
  SELECT
    'ALL'             base_code,            --���_�R�[�h
    '�S���_'          base_name,            --���_����
    '�S���_'          base_short_name       --���_����
  FROM
    xxcos_login_own_base_info_v     xlobiv  --���O�C�����[�U�����_�r���[
  WHERE
    xlobiv.base_code  =  fnd_profile.value('xxcos1_goods_department_code')
  ORDER BY base_code
  ;
COMMENT ON  COLUMN  xxcos_login_base_direct_v.base_code        IS  '���_�R�[�h'; 
COMMENT ON  COLUMN  xxcos_login_base_direct_v.base_name        IS  '���_����';
COMMENT ON  COLUMN  xxcos_login_base_direct_v.base_short_name  IS  '���_����';
--
COMMENT ON  TABLE   xxcos_login_base_direct_v                  IS  '���O�C�����[�U���_�����r���[';
