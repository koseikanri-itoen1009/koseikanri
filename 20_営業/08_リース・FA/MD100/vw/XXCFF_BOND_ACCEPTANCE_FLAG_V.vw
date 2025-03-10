CREATE OR REPLACE FORCE VIEW XXCFF_BOND_ACCEPTANCE_FLAG_V
(
BOND_ACCEPTANCE_FLAG_CODE, -- 証書受領フラグコード
BOND_ACCEPTANCE_FLAG_NAME, -- 証書受領フラグ名称
ENABLED_FLAG,              -- 有効フラグ
START_DATE_ACTIVE,         -- 開始日
END_DATE_ACTIVE            -- 終了日
)
AS 
SELECT FLV.LOOKUP_CODE        AS BOND_ACCEPTANCE_FLAG_CODE
      ,FLV.DESCRIPTION        AS BOND_ACCEPTANCE_FLAG_NAME
      ,FLV.ENABLED_FLAG       AS ENABLED_FLAG
      ,FLV.START_DATE_ACTIVE  AS START_DATE_ACTIVE
      ,FLV.END_DATE_ACTIVE    AS END_DATE_ACTIVE
FROM   FND_LOOKUP_VALUES_VL FLV
WHERE  FLV.LOOKUP_TYPE             = 'XXCFF1_BOND_ACCEPTANCE_FLAG'
;
COMMENT ON COLUMN XXCFF_BOND_ACCEPTANCE_FLAG_V.BOND_ACCEPTANCE_FLAG_CODE IS '証書受領フラグコード';
COMMENT ON COLUMN XXCFF_BOND_ACCEPTANCE_FLAG_V.BOND_ACCEPTANCE_FLAG_NAME IS '証書受領フラグ名称';
COMMENT ON COLUMN XXCFF_BOND_ACCEPTANCE_FLAG_V.ENABLED_FLAG IS '有効フラグ';
COMMENT ON COLUMN XXCFF_BOND_ACCEPTANCE_FLAG_V.START_DATE_ACTIVE IS '開始日';
COMMENT ON COLUMN XXCFF_BOND_ACCEPTANCE_FLAG_V.END_DATE_ACTIVE IS '終了日';
COMMENT ON TABLE XXCFF_BOND_ACCEPTANCE_FLAG_V IS '証書受領フラグビュー';
