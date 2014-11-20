/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : XXCFO_SECURITY_CHIIKI_V
 * Description     : 地域営業セキュリティビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 * 2013/02/14     1.0   T.Ishiwata       [E_本稼動_10421]新規作成
 * 2013/04/19     1.1   T.Ishiwata       [E_本稼動_10421]従業員絞込み対応、テーブルの別名変更
 *
 ****************************************************************************************/
CREATE OR REPLACE VIEW xxcfo_security_chiiki_v(
  dept_code    -- 部門コード
 ,description  -- 部門名称
)
AS
SELECT /*+ USE_NL(xdv papf fu flvv) */
    xdv.flex_value    AS dept_code
  , xdv.description   AS description
FROM
    xx03_departments_v xdv
  , per_all_people_f   papf
  , fnd_user           fu
  -- 地域営業セキュリティLOOKUPとユーザの所属拠点を結合したインラインビュー
  , (SELECT COUNT(1) cnt
     FROM fnd_lookup_values flv
/* 2013/04/19 Ver1.1 Mod Start */
--        , per_all_people_f  papf
        , per_all_people_f  papf2
/* 2013/04/19 Ver1.1 Mod End   */
        , fnd_user          fu
/* 2013/04/19 Ver1.1 Mod Start */
--     WHERE flv.lookup_code = papf.attribute28
--       AND fu.user_id      = fnd_global.user_id
--       AND fu.employee_id  = papf.person_id
     WHERE flv.lookup_code = papf2.attribute28
       AND fu.user_id      = fnd_global.user_id
       AND fu.employee_id  = papf2.person_id
/* 2013/04/19 Ver1.1 Mod End   */
       AND flv.lookup_type = 'XXCFO1_SECURITY_CHIIKI'
       AND flv.language    = USERENV('lang')
/* 2013/04/19 Ver1.1 Add Start */
       AND NVL(papf2.effective_start_date, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
       AND NVL(papf2.effective_end_date,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
/* 2013/04/19 Ver1.1 Add End   */
       AND NVL(flv.start_date_active, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
       AND NVL(flv.end_date_active,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
    ) flvv
WHERE
  fu.user_id = fnd_global.user_id
  AND fu.employee_id = papf.person_id
/* 2013/04/19 Ver1.1 Add Start */
  AND NVL(papf.effective_start_date, xxccp_common_pkg2.get_process_date()) <= xxccp_common_pkg2.get_process_date()
  AND NVL(papf.effective_end_date,   xxccp_common_pkg2.get_process_date()) >= xxccp_common_pkg2.get_process_date()
/* 2013/04/19 Ver1.1 Add End   */
  AND (( flvv.cnt = 0 and xdv.flex_value = papf.attribute28 )  -- インラインビューの件数が０件の場合、ログインユーザの所属拠点で絞込み
      OR( flvv.cnt <> 0 ))                                     -- インラインビューの件数が０件ではないの場合、絞込みなし
;
COMMENT ON  COLUMN  xxcfo_security_chiiki_v.dept_code    IS '部門コード';
COMMENT ON  COLUMN  xxcfo_security_chiiki_v.description  IS '部門名称';
--
COMMENT ON  TABLE   xxcfo_security_chiiki_v              IS '地域営業セキュリティビュー';
