/*************************************************************************
 * 
 * VIEW Name       : xxcso_pv_extract_term_def_v
 * Description     : 画面用：物件汎用検索画面用ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/02/01    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_pv_extract_term_def_v
(
 extract_term_def_id
,view_id
,setup_number
,column_code
,extract_method_code
,extract_term_text
,extract_term_number
,extract_term_date
,created_by
,creation_date
,last_updated_by
,last_update_date
,last_update_login
,request_id
,program_application_id
,program_id
,program_update_date
)
AS
SELECT
 xpetd.extract_term_def_id
,xpetd.view_id
,xpetd.setup_number
,xpetd.column_code
,xpetd.extract_method_code
,xpetd.extract_term_text
,TO_CHAR(xpetd.extract_term_number) AS extract_term_number
,xpetd.extract_term_date
,xpetd.created_by
,xpetd.creation_date
,xpetd.last_updated_by
,xpetd.last_update_date
,xpetd.last_update_login
,xpetd.request_id
,xpetd.program_application_id
,xpetd.program_id
,xpetd.program_update_date
FROM
XXCSO_PV_EXTRACT_TERM_DEF xpetd
;

COMMENT ON TABLE XXCSO_PV_EXTRACT_TERM_DEF_V IS '画面用：物件汎用検索画面用ビュー';
