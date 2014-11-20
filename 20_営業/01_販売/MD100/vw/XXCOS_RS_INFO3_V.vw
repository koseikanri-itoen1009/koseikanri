/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_rs_info3_v
 * Description     : �c�ƈ����r���[3
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2011/04/06    1.0   H.Sasaki         �V�K�쐬
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_rs_info3_v
AS
SELECT  xriv.employee_number                    AS  employee_number
      , xriv.employee_name                      AS  employee_name
      , xriv.base_code                          AS  base_code
      , MIN(xriv.effective_start_date     )     AS  effective_start_date
      , MAX(xriv.effective_end_date       )     AS  effective_end_date
      , MIN(xriv.per_effective_start_date )     AS  per_effective_start_date
      , MAX(xriv.per_effective_end_date   )     AS  per_effective_end_date
      , MIN(xriv.paa_effective_start_date )     AS  paa_effective_start_date
      , MAX(xriv.paa_effective_end_date   )     AS  paa_effective_end_date
FROM    xxcos_rs_info_v       xriv
GROUP BY  xriv.employee_number
        , xriv.employee_name
        , xriv.base_code
/
COMMENT ON  COLUMN  xxcos_rs_info3_v.employee_number            IS  '�c�ƈ��R�[�h';
COMMENT ON  COLUMN  xxcos_rs_info3_v.employee_name              IS  '�c�ƈ�����';
COMMENT ON  COLUMN  xxcos_rs_info3_v.base_code                  IS  '���_CD';
COMMENT ON  COLUMN  xxcos_rs_info3_v.effective_start_date       IS  '���_�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_rs_info3_v.effective_end_date         IS  '���_�K�p�I����';
COMMENT ON  COLUMN  xxcos_rs_info3_v.per_effective_start_date   IS  '�]�ƈ��K�p�J�n��';
COMMENT ON  COLUMN  xxcos_rs_info3_v.per_effective_end_date     IS  '�]�ƈ��K�p�I����';
COMMENT ON  COLUMN  xxcos_rs_info3_v.paa_effective_start_date   IS  '�A�T�C�������g�K�p�J�n��';
COMMENT ON  COLUMN  xxcos_rs_info3_v.paa_effective_end_date     IS  '�A�T�C�������g�K�p�I����';
COMMENT ON  TABLE   xxcos_rs_info3_v                            IS  '�c�ƈ����r���[3';
