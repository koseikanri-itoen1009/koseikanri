/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_login_base_direct_v
 * Description     : ログインユーザ拠点直送ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/01/01    1.0   T.Miyata         新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_login_base_direct_v (
  base_code,                            --拠点コード
  base_name,                            --拠点名称
  base_short_name                       --拠点略称
)
AS
  SELECT
    base_code,                              --拠点コード
    base_name,                              --拠点名称
    base_short_name                         --拠点略称
  FROM
    xxcos_login_base_info_v     xlbiv       --ログインユーザ拠点ビュー
  UNION
  SELECT
    'ALL'             base_code,            --拠点コード
    '全拠点'          base_name,            --拠点名称
    '全拠点'          base_short_name       --拠点略称
  FROM
    xxcos_login_own_base_info_v     xlobiv  --ログインユーザ自拠点ビュー
  WHERE
    xlobiv.base_code  =  fnd_profile.value('xxcos1_goods_department_code')
  ORDER BY base_code
  ;
COMMENT ON  COLUMN  xxcos_login_base_direct_v.base_code        IS  '拠点コード'; 
COMMENT ON  COLUMN  xxcos_login_base_direct_v.base_name        IS  '拠点名称';
COMMENT ON  COLUMN  xxcos_login_base_direct_v.base_short_name  IS  '拠点略称';
--
COMMENT ON  TABLE   xxcos_login_base_direct_v                  IS  'ログインユーザ拠点直送ビュー';
