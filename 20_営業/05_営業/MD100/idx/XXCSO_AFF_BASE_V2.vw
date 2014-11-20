/*************************************************************************
 * 
 * VIEW Name       : XXCSO_AFF_BASE_V2
 * Description     : 共通用：AFF部門マスタ（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_AFF_BASE_V2
(
 base_code
,base_name
,row_order
,old_head_office_code
,base_short_name
)
AS
SELECT
 ffv.flex_value
,ffv.attribute4
,ffv.attribute6
,ffv.attribute7
,ffv.attribute5
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
ffv.flex_value_set_id = fifs.flex_value_set_id AND
NVL(ffv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate) AND
NVL(ffv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_AFF_BASE_V2.base_code IS '拠点コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_V2.base_name IS '拠点名';
COMMENT ON COLUMN XXCSO_AFF_BASE_V2.row_order IS '拠点並び順';
COMMENT ON COLUMN XXCSO_AFF_BASE_V2.old_head_office_code IS '旧本部コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_V2.base_short_name IS '拠点名（略称）';
COMMENT ON TABLE XXCSO_AFF_BASE_V2 IS '共通用：AFF部門マスタ（最新）ビュー';
