CREATE OR REPLACE FORCE VIEW XXCFR_BD_DEPT_COMP_INFO_V(
/*************************************************************************
 * 
 * View Name       : XXCFR_BD_DEPT_COMP_INFO_V
 * Description     : ��������Џ��r���[
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2023/10/24    1.0  SCSK ��R       ����쐬
 ************************************************************************/
  dept_code,                -- ����R�[�h
  set_of_books_id,          -- ��v����ID
  enabled_flag,             -- �L���t���O
  company_code,             -- ��ЃR�[�h
  company_code_bd,          -- ��ЃR�[�h�i����j
  comp_start_date,          -- ��ЊJ�n��
  comp_end_date             -- ��ЏI����
) AS
  SELECT xdev.flex_value          AS dept_code          -- ����R�[�h
        ,xdev.set_of_books_id     AS set_of_books_id    -- ��v����ID
        ,xdev.enabled_flag        AS enabled_flag       -- �L���t���O
        ,flvv.attribute1          AS company_code       -- ��ЃR�[�h
        ,flvv.attribute2          AS company_code_bd    -- ��ЃR�[�h�i����j
        ,flvv.start_date_active   AS comp_start_date    -- ��ЊJ�n��
        ,flvv.end_date_active     AS comp_end_date      -- ��ЏI����
  FROM   xx03_departments_ext_v  xdev
        ,fnd_lookup_values_vl    flvv
  WHERE  flvv.lookup_type   = 'XXCMM_CONV_COMPANY_CODE'  -- ��ЃR�[�h�ϊ�
  AND    flvv.attribute1    = NVL(xdev.attribute10, '001')
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.dept_code                IS '����R�[�h'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.set_of_books_id          IS '��v����ID'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.enabled_flag             IS '�L���t���O'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.company_code             IS '��ЃR�[�h'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.company_code_bd          IS '��ЃR�[�h�i����j'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.comp_start_date          IS '��ЊJ�n��'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.comp_end_date            IS '��ЏI����'
/
