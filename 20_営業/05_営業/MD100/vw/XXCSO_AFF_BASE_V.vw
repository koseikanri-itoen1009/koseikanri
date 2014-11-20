/*************************************************************************
 * 
 * VIEW Name       : XXCSO_AFF_BASE_V
 * Description     : ���ʗp�FAFF����}�X�^�r���[
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 *  2009/09/16    1.1  D.Abe         SCS��Q�Ή�(0001242�Ή�)
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_AFF_BASE_V
(
 base_code
,base_name
,row_order
,old_head_office_code
,base_short_name
,start_date_active
,end_date_active
)
AS
SELECT
 ffv.flex_value
,ffv.attribute4
/* 20090916_Abe_0001242 START*/
--,ffv.attribute6
--,ffv.attribute7
,(CASE
      WHEN NVL(ffv.attribute6,TO_CHAR(xxcso_util_common_pkg.get_online_sysdate,'YYYYMMDD'))
              <=  TO_CHAR(xxcso_util_common_pkg.get_online_sysdate,'YYYYMMDD') THEN
        SUBSTR(ffv.attribute9,5,2)
      ELSE 
        SUBSTR(ffv.attribute7,5,2)
  END) attribute6
,(CASE
      WHEN NVL(ffv.attribute6,TO_CHAR(xxcso_util_common_pkg.get_online_sysdate,'YYYYMMDD'))
              <=  TO_CHAR(xxcso_util_common_pkg.get_online_sysdate,'YYYYMMDD') THEN
        SUBSTR(ffv.ATTRIBUTE9,1,4)
      ELSE 
        SUBSTR(ffv.attribute7,1,4)
  END) attribute7
/* 20090916_Abe_0001242 END*/
,ffv.attribute5
,ffv.start_date_active
,ffv.end_date_active
FROM
 gl_sets_of_books gsob
,fnd_id_flex_segments fifs
,fnd_flex_values ffv
WHERE
gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID') AND
fifs.application_id = 101 AND
fifs.id_flex_code = 'GL#' AND
fifs.application_column_name = 'SEGMENT2' AND
fifs.id_flex_num = gsob.chart_of_accounts_id AND
ffv.flex_value_set_id = fifs.flex_value_set_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_code IS '���_�R�[�h';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_name IS '���_��';
/* 20090916_Abe_0001242 START*/
--COMMENT ON COLUMN XXCSO_AFF_BASE_V.row_order IS '���_���я�';
--COMMENT ON COLUMN XXCSO_AFF_BASE_V.old_head_office_code IS '���{���R�[�h';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.row_order IS '�V�����_���я�';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.old_head_office_code IS '�V���{���R�[�h';
/* 20090916_Abe_0001242 END*/
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_short_name IS '���_���i���́j';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.start_date_active IS '�L���J�n��';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.end_date_active IS '�L���I����';

COMMENT ON TABLE XXCSO_AFF_BASE_V IS '���ʗp�FAFF����}�X�^�r���[';
