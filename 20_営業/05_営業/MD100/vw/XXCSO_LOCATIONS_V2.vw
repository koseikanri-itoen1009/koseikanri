/*************************************************************************
 * 
 * VIEW Name       : XXCSO_LOCATIONS_V2
 * Description     : 共通用：事業所マスタ（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_LOCATIONS_V2
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
xla.location_id = hla.location_id AND
NVL(xla.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(xla.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.location_id IS '事業所ID';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.dept_code IS '拠点コード';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.start_date_active IS '適用開始日';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.end_date_active IS '適用終了日';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.location_name IS '正式名';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.location_short_name IS '略称';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.location_name_alt IS 'カナ名';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.zip IS '郵便番号';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.address_line1 IS '住所';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.phone IS '電話番号';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.fax IS 'FAX番号';
COMMENT ON COLUMN XXCSO_LOCATIONS_V2.division_code IS '本部コード';

COMMENT ON TABLE XXCSO_LOCATIONS_V2 IS '共通用：事業所マスタ（最新）ビュー';
