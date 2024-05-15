CREATE OR REPLACE FORCE VIEW XXCFR_BD_DEPT_COMP_INFO_V(
/*************************************************************************
 * 
 * View Name       : XXCFR_BD_DEPT_COMP_INFO_V
 * Description     : 基準日部門会社情報ビュー
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
  dept_code,                -- 部門コード
  set_of_books_id,          -- 会計帳簿ID
  enabled_flag,             -- 有効フラグ
  company_code,             -- 会社コード
  company_code_bd,          -- 会社コード（基準日）
  comp_start_date,          -- 会社開始日
  comp_end_date             -- 会社終了日
) AS
  SELECT xdev.flex_value          AS dept_code          -- 部門コード
        ,xdev.set_of_books_id     AS set_of_books_id    -- 会計帳簿ID
        ,xdev.enabled_flag        AS enabled_flag       -- 有効フラグ
        ,flvv.attribute1          AS company_code       -- 会社コード
        ,flvv.attribute2          AS company_code_bd    -- 会社コード（基準日）
        ,flvv.start_date_active   AS comp_start_date    -- 会社開始日
        ,flvv.end_date_active     AS comp_end_date      -- 会社終了日
  FROM   xx03_departments_ext_v  xdev
        ,fnd_lookup_values_vl    flvv
  WHERE  flvv.lookup_type   = 'XXCMM_CONV_COMPANY_CODE'  -- 会社コード変換
  AND    flvv.attribute1    = NVL(xdev.attribute10, '001')
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.dept_code                IS '部門コード'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.set_of_books_id          IS '会計帳簿ID'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.enabled_flag             IS '有効フラグ'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.company_code             IS '会社コード'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.company_code_bd          IS '会社コード（基準日）'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.comp_start_date          IS '会社開始日'
/
COMMENT ON COLUMN  xxcfr_bd_dept_comp_info_v.comp_end_date            IS '会社終了日'
/
