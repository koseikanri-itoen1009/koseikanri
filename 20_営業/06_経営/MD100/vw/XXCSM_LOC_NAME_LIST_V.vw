/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCSM_LOC_NAME_LIST_V
 * Description     : 部門名称ビュー
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  XXXX/XX/XX    1.0   XXXXXXXX         新規作成
 *  2010/12/14    1.1   Y.Kanami         [E_本稼動_05803]障害No.17対応
 ************************************************************************/
CREATE OR REPLACE VIEW XXCSM_LOC_NAME_LIST_V
(
  base_code
 ,base_name
 ,parent_flag
 ,hierarchy_level
-- //+ADD START 201/12/14 E_本稼動_05803 Y.Kanami
 ,main_dept_cd
-- //+ADD END 201/12/14 E_本稼動_05803 Y.Kanami
)
AS
  SELECT ffv.flex_value      base_code
        ,ffvt.description    base_name
        ,ffv.summary_flag    parent_flag
        ,ffv.hierarchy_level hierarchy_level
-- //+ADD START 201/12/14 E_本稼動_05803 Y.Kanami
        ,ffv.attribute9      main_dept_cd
-- //+ADD END 201/12/14 E_本稼動_05803 Y.Kanami
  FROM   fnd_flex_value_sets ffvs
        ,fnd_flex_values    ffv
        ,fnd_flex_values_tl ffvt
        ,xxcsm_process_date_v xpcdv
  WHERE  ffvs.flex_value_set_name = 'XX03_DEPARTMENT'
  AND    ffvs.flex_value_set_id = ffv.flex_value_set_id
  AND    ffv.flex_value_id = ffvt.flex_value_id
  AND    ffvt.language = USERENV('LANG')
  AND    ffv.enabled_flag = 'Y'
  AND    (ffv.end_date_active >= xpcdv.process_date
          OR ffv.end_date_active IS NULL)
;
--
COMMENT ON COLUMN xxcsm_loc_name_list_v.base_code           IS '部門コード';
COMMENT ON COLUMN xxcsm_loc_name_list_v.base_name           IS '部門名称';
COMMENT ON COLUMN xxcsm_loc_name_list_v.parent_flag         IS '親フラグ';
COMMENT ON COLUMN xxcsm_loc_name_list_v.hierarchy_level     IS '階層';
-- //+ADD START 201/12/14 E_本稼動_05803 Y.Kanami
COMMENT ON COLUMN xxcsm_loc_name_list_v.main_dept_cd        IS '本部コード';
-- //+ADD END 201/12/14 E_本稼動_05803 Y.Kanami
--                
COMMENT ON TABLE  xxcsm_loc_name_list_v IS '部門名称ビュー';
                  
