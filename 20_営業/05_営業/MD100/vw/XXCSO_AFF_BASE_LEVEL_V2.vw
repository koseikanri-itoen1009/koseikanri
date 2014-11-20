/*************************************************************************
 * 
 * VIEW Name       : XXCSO_AFF_BASE_LEVEL_V2
 * Description     : 共通用：AFF部門階層マスタ（最新）ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXCSO_AFF_BASE_LEVEL_V2
(
 base_code
,child_base_code
)
AS
SELECT  
 ffvnh.parent_flex_value      base_code
,ffvnh.child_flex_value_low   child_base_code
FROM
 gl_sets_of_books gsob
,fnd_id_flex_segments fifs
,fnd_flex_value_norm_hierarchy ffvnh
WHERE   
gsob.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID') AND
fifs.application_id = 101 AND
fifs.id_flex_code = 'GL#' AND
fifs.application_column_name = 'SEGMENT2' AND
fifs.id_flex_num = gsob.chart_of_accounts_id AND
ffvnh.flex_value_set_id = fifs.flex_value_set_id AND
EXISTS (
    SELECT  1
    FROM    fnd_flex_values ffv
    WHERE   ffv.flex_value_set_id = ffvnh.flex_value_set_id
    AND     ffv.flex_value        = ffvnh.parent_flex_value
    AND     NVL(ffv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(ffv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
       ) AND
EXISTS (
    SELECT  1
    FROM    fnd_flex_values ffv
    WHERE   ffv.flex_value_set_id = ffvnh.flex_value_set_id
    AND     ffv.flex_value        = ffvnh.child_flex_value_low
    AND     NVL(ffv.start_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) <= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
    AND     NVL(ffv.end_date_active, TRUNC(xxcso_util_common_pkg.get_online_sysdate)) >= TRUNC(xxcso_util_common_pkg.get_online_sysdate)
       )
WITH READ ONLY
;
COMMENT ON COLUMN XXCSO_AFF_BASE_LEVEL_V2.base_code IS '拠点コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_LEVEL_V2.child_base_code IS '拠点コード（子）';
COMMENT ON TABLE XXCSO_AFF_BASE_LEVEL_V2 IS '共通用：AFF部門階層マスタ（最新）ビュー';
