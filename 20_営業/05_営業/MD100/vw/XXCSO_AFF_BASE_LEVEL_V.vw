/*************************************************************************
 * 
 * VIEW Name       : XXCSO_AFF_BASE_LEVEL_V
 * Description     : 共通用：AFF部門階層マスタビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_AFF_BASE_LEVEL_V
(
 base_code
,child_base_code
)
AS
SELECT
 ffv.flex_value
,ffvnh.child_flex_value_low
FROM
 gl_sets_of_books gsob
,fnd_id_flex_segments fifs
,fnd_flex_values ffv
,fnd_flex_value_norm_hierarchy ffvnh
WHERE
gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID') AND
fifs.application_id = 101 AND
fifs.id_flex_code = 'GL#' AND
fifs.application_column_name = 'SEGMENT2' AND
fifs.id_flex_num = gsob.chart_of_accounts_id AND
ffv.flex_value_set_id = fifs.flex_value_set_id AND
ffvnh.flex_value_set_id(+) = ffv.flex_value_set_id AND
ffvnh.parent_flex_value(+) = ffv.flex_value
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_AFF_BASE_LEVEL_V.base_code IS '拠点コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_LEVEL_V.child_base_code IS '拠点コード（子）';
COMMENT ON TABLE XXCSO_AFF_BASE_LEVEL_V IS '共通用：AFF部門階層マスタビュー';
