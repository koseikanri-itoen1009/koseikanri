/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name   : XXCOI_BASE_INFO3_V
 * Description : 拠点情報ビュー3（商品部のみ全拠点）
 * Version     : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/01/18    1.0   H.Sasaki         新規作成
 *
 ************************************************************************/
  CREATE OR REPLACE FORCE VIEW "APPS"."XXCOI_BASE_INFO3_V" ("BASE_CODE", "BASE_SHORT_NAME") AS 
  SELECT DISTINCT xbiv.base_code
                , xbiv.base_short_name
  FROM xxcoi_base_info2_v       xbiv
  WHERE xbiv.focus_base_code =  CASE  WHEN xxcoi_common_pkg.get_base_code(fnd_global.user_id, SYSDATE) = fnd_profile.value('XXCOI1_ITEM_DEPT_BASE_CODE')
                                        THEN xbiv.focus_base_code
                                      ELSE xxcoi_common_pkg.get_base_code(fnd_global.user_id, SYSDATE)
                                END
  ORDER BY  xbiv.base_code
/
COMMENT ON TABLE  XXCOI_BASE_INFO3_V                   IS '拠点情報ビュー3';
/
COMMENT ON COLUMN XXCOI_BASE_INFO3_V.BASE_CODE         IS '拠点コード';
/
COMMENT ON COLUMN XXCOI_BASE_INFO3_V.BASE_SHORT_NAME   IS '拠点略称';
/
