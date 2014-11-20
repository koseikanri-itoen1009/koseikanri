/*************************************************************************
 * 
 * VIEW Name       : XXCSO_LOCATIONS_V
 * Description     : ���ʗp�F���Ə��}�X�^�r���[
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_LOCATIONS_V
(
 location_id
,dept_code
,start_date_active
,end_date_active
,location_name
,location_short_name
,location_name_alt
,zip
,address_line1
,phone
,fax
,division_code
)
AS
SELECT
 hla.location_id
,hla.location_code
,xla.start_date_active
,xla.end_date_active
,xla.location_name
,xla.location_short_name
,xla.location_name_alt
,xla.zip
,xla.address_line1
,xla.phone
,xla.fax
,xla.division_code
FROM
 hr_locations_all hla
,xxcmn_locations_all xla
WHERE
xla.location_id = hla.location_id
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_LOCATIONS_V.location_id IS '���Ə�ID';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.dept_code IS '���_�R�[�h';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.start_date_active IS '�K�p�J�n��';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.end_date_active IS '�K�p�I����';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.location_name IS '������';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.location_short_name IS '����';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.location_name_alt IS '�J�i��';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.zip IS '�X�֔ԍ�';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.address_line1 IS '�Z��';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.phone IS '�d�b�ԍ�';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.fax IS 'FAX�ԍ�';
COMMENT ON COLUMN XXCSO_LOCATIONS_V.division_code IS '�{���R�[�h';

COMMENT ON TABLE XXCSO_LOCATIONS_V IS '���ʗp�F���Ə��}�X�^�r���[';
