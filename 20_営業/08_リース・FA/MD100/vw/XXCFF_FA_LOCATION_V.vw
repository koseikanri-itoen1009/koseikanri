CREATE OR REPLACE FORCE VIEW XXCFF_FA_LOCATION_V
(
LOCATION_ID,             -- 事業所ID
SEGMENT1,                -- ロケ_申告地コード
SEGMENT1_DESC,           -- ロケ_申告地名称
SEGMENT2,                -- ロケ_管理部門コード
SEGMENT2_DESC,           -- ロケ_管理部門名称
SEGMENT3,                -- ロケ_事業所コード
SEGMENT3_DESC,           -- ロケ_事業所名称
SEGMENT4,                -- ロケ_場所
SEGMENT5,                -- ロケ_本社工場区分コード
SEGMENT5_DESC,           -- ロケ_本社工場区分名称
ENABLED_FLAG,            -- 有効フラグ
START_DATE_ACTIVE,       -- 開始日
END_DATE_ACTIVE          -- 終了日
)
AS
SELECT FLC.LOCATION_ID                                                  AS LOCATION_ID
      ,FLC.SEGMENT1                                                     AS SEGMENT1
      ,(SELECT  FLV1.DESCRIPTION
        FROM     FND_FLEX_VALUES_VL      FLV1
                ,FND_ID_FLEX_SEGMENTS_VL FIS1
        WHERE  FLV1.FLEX_VALUE_SET_ID        = FIS1.FLEX_VALUE_SET_ID
        AND    FIS1.ID_FLEX_CODE             = 'LOC#'
        AND    FIS1.APPLICATION_COLUMN_NAME  = 'SEGMENT1'
        AND    FLC.SEGMENT1                  = FLV1.FLEX_VALUE
       )                                                                AS SEGMENT1_DESC
      ,FLC.SEGMENT2                                                     AS SEGMENT2
      ,(SELECT  FLV2.DESCRIPTION
        FROM    FND_FLEX_VALUES_VL       FLV2
               ,FND_ID_FLEX_SEGMENTS_VL  FIS2
        WHERE   FLV2.FLEX_VALUE_SET_ID       = FIS2.FLEX_VALUE_SET_ID
        AND     FIS2.ID_FLEX_CODE            = 'LOC#'
        AND     FIS2.APPLICATION_COLUMN_NAME = 'SEGMENT2'
        AND     FLC.SEGMENT2                 = FLV2.FLEX_VALUE
        )                                                               AS SEGMENT2_DESC
       ,FLC.SEGMENT3                                                    AS SEGMENT3
       ,(SELECT  FLV3.DESCRIPTION
         FROM    FND_FLEX_VALUES_VL       FLV3
                ,FND_ID_FLEX_SEGMENTS_VL  FIS3
         WHERE   FLV3.FLEX_VALUE_SET_ID       = FIS3.FLEX_VALUE_SET_ID
         AND     FIS3.ID_FLEX_CODE            = 'LOC#'
         AND     FIS3.APPLICATION_COLUMN_NAME = 'SEGMENT3'
         AND     FLC.SEGMENT3                 = FLV3.FLEX_VALUE
       )                                                                AS SEGMENT3_DESC
       ,FLC.SEGMENT4                                                    AS SEGMENT4
      ,FLC.SEGMENT5                                                     AS SEGMENT5
      ,(SELECT  FLV5.DESCRIPTION
         FROM    FND_FLEX_VALUES_VL       FLV5
                ,FND_ID_FLEX_SEGMENTS_VL  FIS5
         WHERE   FLV5.FLEX_VALUE_SET_ID       = FIS5.FLEX_VALUE_SET_ID
         AND     FIS5.ID_FLEX_CODE            = 'LOC#'
         AND     FIS5.APPLICATION_COLUMN_NAME = 'SEGMENT5'
         AND     FLC.SEGMENT5                 = FLV5.FLEX_VALUE
      )                                                                 AS SEGMENT5_DESC
      ,FLC.ENABLED_FLAG                                                 AS ENABLED_FLAG
      ,FLC.START_DATE_ACTIVE                                            AS START_DATE_ACTIVE
      ,FLC.END_DATE_ACTIVE                                              AS END_DATE_ACTIVE
FROM  FA_LOCATIONS    FLC
;
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.LOCATION_ID IS '事業所ID';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT1 IS 'ロケ_申告地コード';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT1_DESC IS 'ロケ_申告地名称';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT2 IS 'ロケ_管理部門コード';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT2_DESC IS 'ロケ_管理部門名称';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT3 IS 'ロケ_事業所コード';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT3_DESC IS 'ロケ_事業所名称';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT4 IS 'ロケ_場所';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT5 IS 'ロケ_本社工場区分コード';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT5_DESC IS 'ロケ_本社工場区分名称';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.ENABLED_FLAG IS '有効フラグ';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.START_DATE_ACTIVE IS '開始日';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.END_DATE_ACTIVE IS '終了日';
COMMENT ON TABLE XXCFF_FA_LOCATION_V IS '事業所マスタビュー';
