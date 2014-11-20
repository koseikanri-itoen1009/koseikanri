/*************************************************************************
 * 
 * VIEW Name       : XXCSO_AFF_BASE_V
 * Description     : 共通用：AFF部門マスタビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
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
,ffv.attribute6
,ffv.attribute7
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
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_code IS '拠点コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_name IS '拠点名';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.row_order IS '拠点並び順';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.old_head_office_code IS '旧本部コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_short_name IS '拠点名（略称）';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.start_date_active IS '有効開始日';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.end_date_active IS '有効終了日';

COMMENT ON TABLE XXCSO_AFF_BASE_V IS '共通用：AFF部門マスタビュー';
