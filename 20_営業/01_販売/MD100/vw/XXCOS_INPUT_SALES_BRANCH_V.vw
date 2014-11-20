/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_input_sales_branch_v
 * Description     : 出荷依頼実績入力拠点ビュー
 * Version         : 1.0
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/04/05    1.0   S.Tomita         新規作成
 ************************************************************************/
CREATE OR REPLACE VIEW xxcos_input_sales_branch_v (
  dsp_code         -- 表示順
 ,input_base_code  -- 拠点コード
 ,input_base_name  -- 拠点名称
)
AS
SELECT  flv.lookup_code  dsp_code
       ,flv.meaning      input_base_code
       ,flv.description  input_base_name
FROM   xxcos_lookup_values_v flv
WHERE  trunc(sysdate) >=flv.start_date_active
AND    trunc(sysdate) <=NVL(flv.end_date_active,trunc(sysdate))
AND    flv.lookup_type ='XXCOS1_INPUT_SALES_BRANCH'
UNION
SELECT '00'              dsp_code
       ,base_code        input_base_code
       ,base_short_name  input_base_name
FROM   xxcos_login_own_base_info_v;
--
COMMENT ON  COLUMN  xxcos_input_sales_branch_v.dsp_code          IS  '表示順';
COMMENT ON  COLUMN  xxcos_input_sales_branch_v.input_base_code   IS  '拠点コード';
COMMENT ON  COLUMN  xxcos_input_sales_branch_v.input_base_name   IS  '拠点名称';
--
COMMENT ON  TABLE   xxcos_input_sales_branch_v                   IS  '出荷依頼実績入力拠点ビュー';
