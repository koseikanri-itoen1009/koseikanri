/*************************************************************************
 * 
 * View  Name      : XXSKZ_LOCATIONS_V
 * Description     : XXSKZ_LOCATIONS_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_LOCATIONS_V
(
 LOCATION_ID
,LOCATION_CODE
,LOCATION_NAME
,LOCATION_SHORT_NAME
,START_DATE_ACTIVE
,END_DATE_ACTIVE
)
AS
SELECT  XLA.location_id
       ,HLA.location_code
       ,XLA.location_name
       ,XLA.location_short_name
       ,XLA.start_date_active
       ,XLA.end_date_active
  FROM  hr_locations_all      HLA
       ,xxcmn_locations_all   XLA
 WHERE  HLA.location_id = XLA.location_id
   AND  HLA.inactive_date IS NULL
   AND  XLA.start_date_active <= TRUNC(SYSDATE)
   AND  XLA.end_date_active >= TRUNC(SYSDATE)
/
COMMENT ON TABLE APPS.XXSKZ_LOCATIONS_V IS 'SKYLINK�p����VIEW ���Ə����VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS_V.LOCATION_ID         IS '���Ə�ID'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS_V.LOCATION_CODE       IS '���Ə��R�[�h'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS_V.LOCATION_NAME       IS '���Ə���'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS_V.LOCATION_SHORT_NAME IS '���Ə��Z�k��'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS_V.START_DATE_ACTIVE   IS '�K�p�J�n��'
/
COMMENT ON COLUMN APPS.XXSKZ_LOCATIONS_V.END_DATE_ACTIVE     IS '�K�p�I����'
/
