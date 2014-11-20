/*************************************************************************
 * 
 * VIEW Name       : XXCSO_AFF_BASE_V
 * Description     : 共通用：AFF部門マスタビュー
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 *  2009/09/16    1.1  D.Abe         SCS障害対応(0001242対応)
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
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_code IS '拠点コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_name IS '拠点名';
/* 20090916_Abe_0001242 START*/
--COMMENT ON COLUMN XXCSO_AFF_BASE_V.row_order IS '拠点並び順';
--COMMENT ON COLUMN XXCSO_AFF_BASE_V.old_head_office_code IS '旧本部コード';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.row_order IS '新旧拠点並び順';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.old_head_office_code IS '新旧本部コード';
/* 20090916_Abe_0001242 END*/
COMMENT ON COLUMN XXCSO_AFF_BASE_V.base_short_name IS '拠点名（略称）';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.start_date_active IS '有効開始日';
COMMENT ON COLUMN XXCSO_AFF_BASE_V.end_date_active IS '有効終了日';

COMMENT ON TABLE XXCSO_AFF_BASE_V IS '共通用：AFF部門マスタビュー';
