CREATE OR REPLACE VIEW XXCFF_FA_CATEGORY_V (
 CATE_CCID       -- 資産カテゴリID
,SEGMENT1        -- カテゴリ種類コード
,SEGMENT1_DESC   -- カテゴリ種類名称
,SEGMENT2        -- カテゴリ償却申告コード
,SEGMENT2_DESC   -- カテゴリ償却申告名称
,SEGMENT3        -- カテゴリ資産勘定コード
,SEGMENT3_DESC   -- カテゴリ資産勘定名称
,SEGMENT4        -- カテゴリ償却方法コード
,SEGMENT4_DESC   -- カテゴリ償却方法名称
,SEGMENT5        -- カテゴリ耐用年数コード
,SEGMENT5_DESC   -- カテゴリ耐用年数名称
,SEGMENT6        -- カテゴリ償却科目コード
,SEGMENT6_DESC   -- カテゴリ償却科目名称
,SEGMENT7        -- カテゴリリース種別コード
,SEGMENT7_DESC   -- カテゴリリース種別名称
)
AS
SELECT FCB.CATEGORY_ID                                                   AS CATE_CCID
      ,FCB.SEGMENT1                                                      AS SEGMENT1
      ,(SELECT FLV1.DESCRIPTION
        FROM   FND_FLEX_VALUES_VL                          FLV1
              ,FND_ID_FLEX_SEGMENTS_VL                     FIS1
        WHERE  FLV1.FLEX_VALUE_SET_ID         = FIS1.FLEX_VALUE_SET_ID
        AND    FIS1.ID_FLEX_CODE              = 'CAT#'
        AND    FIS1.APPLICATION_COLUMN_NAME   = 'SEGMENT1'
        AND    FLV1.FLEX_VALUE                = FCB.SEGMENT1)            AS SEGMENT1_DESC
      ,FCB.SEGMENT2                                                      AS SEGMENT2
      ,(SELECT FLV2.DESCRIPTION
        FROM   FND_FLEX_VALUES_VL                          FLV2
              ,FND_ID_FLEX_SEGMENTS_VL                     FIS2
        WHERE  FLV2.FLEX_VALUE_SET_ID         = FIS2.FLEX_VALUE_SET_ID
        AND    FIS2.ID_FLEX_CODE              = 'CAT#'
        AND    FIS2.APPLICATION_COLUMN_NAME   = 'SEGMENT2'
        AND    FLV2.FLEX_VALUE                = FCB.SEGMENT2)            AS SEGMENT2_DESC
      ,FCB.SEGMENT3                                                      AS SEGMENT3
      ,(SELECT FLV3.DESCRIPTION
        FROM   FND_FLEX_VALUES_VL                          FLV3
              ,FND_ID_FLEX_SEGMENTS_VL                     FIS3
        WHERE  FLV3.FLEX_VALUE_SET_ID         = FIS3.FLEX_VALUE_SET_ID
        AND    FIS3.ID_FLEX_CODE              = 'CAT#'
        AND    FIS3.APPLICATION_COLUMN_NAME   = 'SEGMENT3'
        AND    FLV3.FLEX_VALUE                = FCB.SEGMENT3)            AS SEGMENT3_DESC
      ,FCB.SEGMENT4                                                      AS SEGMENT4
      ,(SELECT FLV4.DESCRIPTION
        FROM   FND_FLEX_VALUES_VL                          FLV4
              ,FND_ID_FLEX_SEGMENTS_VL                     FIS4
        WHERE  FLV4.FLEX_VALUE_SET_ID         = FIS4.FLEX_VALUE_SET_ID
        AND    FIS4.ID_FLEX_CODE              = 'CAT#'
        AND    FIS4.APPLICATION_COLUMN_NAME   = 'SEGMENT4'
        AND    FLV4.FLEX_VALUE                = FCB.SEGMENT4)            AS SEGMENT4_DESC
      ,FCB.SEGMENT5                                                      AS SEGMENT5
      ,(SELECT  FLV5.DESCRIPTION
        FROM    FND_FLEX_VALUES_VL                            FLV5
               ,FND_ID_FLEX_SEGMENTS_VL                       FIS5
        WHERE  FLV5.FLEX_VALUE_SET_ID           = FIS5.FLEX_VALUE_SET_ID
        AND    FIS5.ID_FLEX_CODE                = 'CAT#'
        AND    FIS5.APPLICATION_COLUMN_NAME     = 'SEGMENT5'
        AND    FLV5.FLEX_VALUE                  = FCB.SEGMENT5
        AND    FLV5.PARENT_FLEX_VALUE_LOW       = FCB.SEGMENT1)          AS SEGMENT5_DESC
      ,FCB.SEGMENT6                                                      AS SEGMENT6
      ,(SELECT  FLV6.DESCRIPTION
        FROM    FND_FLEX_VALUES_VL                            FLV6
               ,FND_ID_FLEX_SEGMENTS_VL                       FIS6
        WHERE  FLV6.FLEX_VALUE_SET_ID           = FIS6.FLEX_VALUE_SET_ID
        AND    FIS6.ID_FLEX_CODE                = 'CAT#'
        AND    FIS6.APPLICATION_COLUMN_NAME     = 'SEGMENT6'
        AND    FLV6.FLEX_VALUE                  = FCB.SEGMENT6)          AS SEGMENT6_DESC
      ,FCB.SEGMENT7                                                      AS SEGMENT7
      ,(SELECT  FLV7.DESCRIPTION
        FROM    FND_FLEX_VALUES_VL                            FLV7
               ,FND_ID_FLEX_SEGMENTS_VL                       FIS7
        WHERE  FLV7.FLEX_VALUE_SET_ID           = FIS7.FLEX_VALUE_SET_ID
        AND    FIS7.ID_FLEX_CODE                = 'CAT#'
        AND    FIS7.APPLICATION_COLUMN_NAME     = 'SEGMENT7'
        AND    FLV7.FLEX_VALUE                  = FCB.SEGMENT7)          AS SEGMENT7_DESC
  FROM  FA_CATEGORIES FCB
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.CATE_CCID IS '資産カテゴリID'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT1 IS 'カテゴリ種類コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT1_DESC IS 'カテゴリ種類名称'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT2 IS 'カテゴリ償却申告コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT2_DESC IS 'カテゴリ償却申告名称'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT3 IS 'カテゴリ資産勘定コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT3_DESC IS 'カテゴリ資産勘定名称'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT4 IS 'カテゴリ償却方法コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT4_DESC IS 'カテゴリ償却方法名称'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT5 IS 'カテゴリ耐用年数コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT5_DESC IS 'カテゴリ耐用年数名称'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT6 IS 'カテゴリ償却科目コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT6_DESC IS 'カテゴリ償却科目名称'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT7 IS 'カテゴリリース種別コード'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT7_DESC IS 'カテゴリリース種別名称'
/
COMMENT ON TABLE XXCFF_FA_CATEGORY_V IS '資産カテゴリマスタビュー'
/
