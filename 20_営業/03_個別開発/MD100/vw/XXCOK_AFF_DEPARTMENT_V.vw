/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name   : XXCOK_AFF_DEPARTMENT_V
 * Description : ����r���[
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2011/11/01    1.0   A.Shirakawa      �V�K�쐬
 *
 *****************************************************************************************/
CREATE OR REPLACE VIEW apps.xxcok_aff_department_v(
  aff_department_code  -- ����R�[�h
 ,aff_department_name  -- ���喼
 ,enabled_flag         -- �L���t���O
 ,start_date_active    -- �J�n��
 ,end_date_active      -- �I����
)
AS 
SELECT fflexval.flex_value         AS aff_department_code
      ,fflexvaltl.description      AS aff_department_name
      ,fflexval.enabled_flag       AS enabled_flag
      ,fflexval.start_date_active  AS start_date_active
      ,fflexval.end_date_active    AS end_date_active
FROM   fnd_flex_value_sets    fflexvalset
      ,fnd_flex_values        fflexval
      ,fnd_flex_values_tl     fflexvaltl
WHERE  fflexvalset.flex_value_set_name = 'XX03_DEPARTMENT'
AND    fflexvalset.flex_value_set_id   = fflexval.flex_value_set_id
AND    fflexval.flex_value_id          = fflexvaltl.flex_value_id
AND    fflexvaltl.language             = USERENV('LANG')
AND    fflexval.summary_flag           = 'N'
AND    fflexval.enabled_flag           = 'Y'
/
COMMENT ON TABLE apps.xxcok_aff_department_v                       IS '����r���['
/
COMMENT ON COLUMN apps.xxcok_aff_department_v.aff_department_code  IS '����R�[�h'
/
COMMENT ON COLUMN apps.xxcok_aff_department_v.aff_department_name  IS '���喼'
/
COMMENT ON COLUMN apps.xxcok_aff_department_v.enabled_flag         IS '�L���t���O'
/
COMMENT ON COLUMN apps.xxcok_aff_department_v.start_date_active    IS '�J�n��'
/
COMMENT ON COLUMN apps.xxcok_aff_department_v.end_date_active      IS '�I����'
/
