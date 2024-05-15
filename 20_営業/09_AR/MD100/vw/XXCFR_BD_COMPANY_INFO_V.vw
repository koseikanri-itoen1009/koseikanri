CREATE OR REPLACE FORCE VIEW XXCFR_BD_COMPANY_INFO_V(
/*************************************************************************
 * 
 * View Name       : XXCFR_BD_COMPANY_INFO_V
 * Description     : 基準日会社情報ビュー
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
  company_code,             -- 会社コード
  company_code_bd,          -- 会社コード（基準日）
  start_date_active,        -- 有効開始日
  end_date_active,          -- 有効終了日
  lookup_type,              -- 参照タイプ
  attribute1,               -- DFF1
  attribute2,               -- DFF2
  attribute3,               -- DFF3
  attribute4,               -- DFF4
  attribute5,               -- DFF5
  attribute6,               -- DFF6
  attribute7,               -- DFF7
  attribute8,               -- DFF8
  attribute9,               -- DFF9
  attribute10               -- DFF10
) AS
  SELECT flvv1.attribute1         AS company_code       -- 会社コード
        ,flvv1.attribute2         AS company_code_bd    -- 会社コード（基準日）
        ,flvv1.start_date_active  AS start_date_active  -- 有効開始日
        ,flvv1.end_date_active    AS end_date_active    -- 有効終了日
        ,flvv2.lookup_type        AS lookup_type        -- 参照タイプ
        ,flvv2.attribute1         AS attribute1         -- DFF1
        ,flvv2.attribute2         AS attribute2         -- DFF2
        ,flvv2.attribute3         AS attribute3         -- DFF3
        ,flvv2.attribute4         AS attribute4         -- DFF4
        ,flvv2.attribute5         AS attribute5         -- DFF5
        ,flvv2.attribute6         AS attribute6         -- DFF6
        ,flvv2.attribute7         AS attribute7         -- DFF7
        ,flvv2.attribute8         AS attribute8         -- DFF8
        ,flvv2.attribute9         AS attribute9         -- DFF9
        ,flvv2.attribute10        AS attribute10        -- DFF10
  FROM   fnd_lookup_values_vl  flvv1
        ,fnd_lookup_values_vl  flvv2
  WHERE  flvv1.lookup_type   = 'XXCMM_CONV_COMPANY_CODE'  -- 会社コード変換
  AND    flvv1.attribute2    = flvv2.lookup_code
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.company_code               IS '会社コード'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.company_code_bd            IS '会社コード（基準日）'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.start_date_active          IS '有効開始日'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.end_date_active            IS '有効終了日'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.lookup_type                IS '参照タイプ'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute1                 IS 'DFF1'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute2                 IS 'DFF2'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute3                 IS 'DFF3'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute4                 IS 'DFF4'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute5                 IS 'DFF5'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute6                 IS 'DFF6'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute7                 IS 'DFF7'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute8                 IS 'DFF8'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute9                 IS 'DFF9'
/
COMMENT ON COLUMN  xxcfr_bd_company_info_v.attribute10                IS 'DFF10'
/
