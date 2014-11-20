/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : XXCOS_ORDER_LOOKUP_VALUES_V
 * Description     : 参照コードの制御（クイック受注用）
 * Version         : 1.2
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2009/1/26     1.0   T.Tyou           新規作成
 *  2009/2/26     1.1   T.Tyou           attribute2追加
 *  2009/09/03    1.2   M.Sano           障害番号0001227 対応
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_order_lookup_values_v (
  lookup_code,
  meaning,
  lookup_type,
  attribute1,
  attribute2
)
AS 
      SELECT  
              look_val.lookup_code lookup_code,
              look_val.meaning meaning,
              look_val.lookup_type,
              look_val.attribute1,
              look_val.attribute2
      FROM    fnd_lookup_values     look_val,
-- 2009/09/03 Ver1.2 Mod Start
--              fnd_lookup_types_tl   types_tl,
--              fnd_lookup_types      types,
--              fnd_application_tl    appl,
--              fnd_application       app
--              ,( SELECT TRUNC( xxccp_common_pkg2.get_process_date ) process_date FROM dual ) pd
--      WHERE   appl.application_id   = types.application_id
--      AND     look_val.language     = userenv('LANG')
--      AND     appl.language         = userenv('LANG')
--      AND     types_tl.language     = userenv('LANG')
--      AND     types_tl.lookup_type  = look_val.lookup_type
--      AND     app.application_id    = appl.application_id
--      AND     app.application_short_name = 'XXCOS'
--      AND     types.lookup_type = types_tl.lookup_type
--      AND     types.security_group_id = types_tl.security_group_id
--      AND     types.view_application_id = types_tl.view_application_id
              ( SELECT TRUNC( xpd.process_date ) process_date FROM xxccp_process_dates xpd ) pd
      WHERE   look_val.language     = userenv('LANG')
-- 2009/09/03 Ver1.2 Mod End
      AND    pd.process_date      >= NVL(look_val.start_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MIN_DATE'),'YYYY/MM/DD'))
      AND    pd.process_date      <= NVL(look_val.end_date_active,FND_DATE.STRING_TO_DATE(FND_PROFILE.VALUE('XXCOS1_MAX_DATE'),'YYYY/MM/DD'))
      AND    look_val.enabled_flag = 'Y'
;
COMMENT ON  COLUMN  xxcos_order_lookup_values_v.lookup_code  IS  '参照コード';
COMMENT ON  COLUMN  xxcos_order_lookup_values_v.meaning      IS  '内容';
COMMENT ON  COLUMN  xxcos_order_lookup_values_v.lookup_type  IS  '摘要';
COMMENT ON  COLUMN  xxcos_order_lookup_values_v.attribute1   IS  '属性1';
COMMENT ON  COLUMN  xxcos_order_lookup_values_v.attribute2   IS  '属性2';
--
COMMENT ON  TABLE   xxcos_order_lookup_values_v              IS  '参照コードの制御(クイック受注用)';
