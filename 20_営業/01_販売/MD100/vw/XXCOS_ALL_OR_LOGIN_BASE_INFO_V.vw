/***********************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : xxcos_all_or_login_base_info_v
 * Description     : �S���_�܂��̓��O�C�����[�U�������_�r���[
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/1/16     1.0   H.Wajima         �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_all_or_login_base_info_v (
   base_code                             --���_�R�[�h
  ,base_name                             --���_����
)
AS
  -- ���O�C�����[�U�������_���
  SELECT
     xdv.flex_value
    ,xdv.description
  FROM
     xx03_departments_v      xdv
    ,xxcos_login_base_info_v xlbi
  WHERE
     xlbi.base_code = xdv.flex_value
  UNION
  -- �S���_���(���O�C�����[�U�̋��_������̋��_�̏ꍇ�̂�)
  SELECT
     xdv.flex_value
    ,xdv.description
  FROM
   xx03_departments_v xdv
  ,(SELECT
      COUNT(1) cnt
    FROM
       xxcos_login_base_info_v xlbi
      ,fnd_lookup_values       flv
    WHERE
       xlbi.base_code  = flv.lookup_code
    AND
       FLV.LOOKUP_TYPE = 'XXCOS1_002A05_ALL_BASE_CD'
   ) all_base_cnt
  WHERE
  all_base_cnt.cnt <> 0
  ORDER BY
    flex_value
   ,description
;
COMMENT ON  COLUMN  xxcos_all_or_login_base_info_v.base_code  IS  '���_�R�[�h';
COMMENT ON  COLUMN  xxcos_all_or_login_base_info_v.base_name  IS  '���_����'; 
--
COMMENT ON  TABLE   xxcos_all_or_login_base_info_v            IS  '�S���_�܂��̓��O�C�����[�U�������_�r���[';
