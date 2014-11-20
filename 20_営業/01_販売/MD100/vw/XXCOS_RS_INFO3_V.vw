/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_rs_info3_v
 * Description     : 営業員情報ビュー3
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2011/04/06    1.0   H.Sasaki         新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_rs_info3_v
AS
SELECT  xriv.employee_number                    AS  employee_number
      , xriv.employee_name                      AS  employee_name
      , xriv.base_code                          AS  base_code
      , MIN(xriv.effective_start_date     )     AS  effective_start_date
      , MAX(xriv.effective_end_date       )     AS  effective_end_date
      , MIN(xriv.per_effective_start_date )     AS  per_effective_start_date
      , MAX(xriv.per_effective_end_date   )     AS  per_effective_end_date
      , MIN(xriv.paa_effective_start_date )     AS  paa_effective_start_date
      , MAX(xriv.paa_effective_end_date   )     AS  paa_effective_end_date
FROM    xxcos_rs_info_v       xriv
GROUP BY  xriv.employee_number
        , xriv.employee_name
        , xriv.base_code
/
COMMENT ON  COLUMN  xxcos_rs_info3_v.employee_number            IS  '営業員コード';
COMMENT ON  COLUMN  xxcos_rs_info3_v.employee_name              IS  '営業員名称';
COMMENT ON  COLUMN  xxcos_rs_info3_v.base_code                  IS  '拠点CD';
COMMENT ON  COLUMN  xxcos_rs_info3_v.effective_start_date       IS  '拠点適用開始日';
COMMENT ON  COLUMN  xxcos_rs_info3_v.effective_end_date         IS  '拠点適用終了日';
COMMENT ON  COLUMN  xxcos_rs_info3_v.per_effective_start_date   IS  '従業員適用開始日';
COMMENT ON  COLUMN  xxcos_rs_info3_v.per_effective_end_date     IS  '従業員適用終了日';
COMMENT ON  COLUMN  xxcos_rs_info3_v.paa_effective_start_date   IS  'アサインメント適用開始日';
COMMENT ON  COLUMN  xxcos_rs_info3_v.paa_effective_end_date     IS  'アサインメント適用終了日';
COMMENT ON  TABLE   xxcos_rs_info3_v                            IS  '営業員情報ビュー3';
