/***********************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * View Name       : xxcos_all_or_login_base_info_v
 * Description     : 全拠点またはログインユーザ所属拠点ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2014/1/16     1.0   H.Wajima         新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_all_or_login_base_info_v (
   base_code                             --拠点コード
  ,base_name                             --拠点名称
)
AS
  -- ログインユーザ所属拠点情報
  SELECT
     xdv.flex_value
    ,xdv.description
  FROM
     xx03_departments_v      xdv
    ,xxcos_login_base_info_v xlbi
  WHERE
     xlbi.base_code = xdv.flex_value
  UNION
  -- 全拠点情報(ログインユーザの拠点が特定の拠点の場合のみ)
  SELECT
     xdv.flex_value
    ,xdv.description
  FROM
   xx03_departments_v xdv
  ,(SELECT
      COUNT(1) cnt
    FROM
       xxcos_login_base_info_v xlbi
      ,fnd_lookup_values       flv
    WHERE
       xlbi.base_code  = flv.lookup_code
    AND
       FLV.LOOKUP_TYPE = 'XXCOS1_002A05_ALL_BASE_CD'
   ) all_base_cnt
  WHERE
  all_base_cnt.cnt <> 0
  ORDER BY
    flex_value
   ,description
;
COMMENT ON  COLUMN  xxcos_all_or_login_base_info_v.base_code  IS  '拠点コード';
COMMENT ON  COLUMN  xxcos_all_or_login_base_info_v.base_name  IS  '拠点名称'; 
--
COMMENT ON  TABLE   xxcos_all_or_login_base_info_v            IS  '全拠点またはログインユーザ所属拠点ビュー';
