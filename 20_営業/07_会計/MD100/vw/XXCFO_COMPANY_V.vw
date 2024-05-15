CREATE OR REPLACE FORCE VIEW XXCFO_COMPANY_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_COMPANY_V
 * Description     : 会社ビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2023/10/24    1.0  SCSK 大山       初回作成
 ************************************************************************/
  company_code,          -- 会社コード
  company_name           -- 会社名
) AS
  SELECT ffvv.flex_value         company_code      -- 会社コード
        ,ffvv.description        company_name      -- 会社名
  FROM   fnd_flex_value_sets  ffvs
        ,fnd_flex_values_vl   ffvv
  WHERE  ffvs.flex_value_set_name IN ('XX03_COMPANY')
  AND    ffvs.flex_value_set_id = ffvv.flex_value_set_id
  AND    ffvv.flex_value NOT IN ('999')
/
COMMENT ON COLUMN  xxcfo_company_v.company_code          IS '会社コード'
/
COMMENT ON COLUMN  xxcfo_company_v.company_name          IS '会社名'
/
