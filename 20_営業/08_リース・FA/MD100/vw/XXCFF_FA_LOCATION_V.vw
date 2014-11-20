CREATE OR REPLACE FORCE VIEW XXCFF_FA_LOCATION_V
(
LOCATION_ID,             -- ���Ə�ID
SEGMENT1,                -- ���P_�\���n�R�[�h
SEGMENT1_DESC,           -- ���P_�\���n����
SEGMENT2,                -- ���P_�Ǘ�����R�[�h
SEGMENT2_DESC,           -- ���P_�Ǘ����喼��
SEGMENT3,                -- ���P_���Ə��R�[�h
SEGMENT3_DESC,           -- ���P_���Ə�����
SEGMENT4,                -- ���P_�ꏊ
SEGMENT5,                -- ���P_�{�ЍH��敪�R�[�h
SEGMENT5_DESC,           -- ���P_�{�ЍH��敪����
ENABLED_FLAG,            -- �L���t���O
START_DATE_ACTIVE,       -- �J�n��
END_DATE_ACTIVE          -- �I����
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
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.LOCATION_ID IS '���Ə�ID';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT1 IS '���P_�\���n�R�[�h';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT1_DESC IS '���P_�\���n����';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT2 IS '���P_�Ǘ�����R�[�h';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT2_DESC IS '���P_�Ǘ����喼��';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT3 IS '���P_���Ə��R�[�h';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT3_DESC IS '���P_���Ə�����';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT4 IS '���P_�ꏊ';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT5 IS '���P_�{�ЍH��敪�R�[�h';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.SEGMENT5_DESC IS '���P_�{�ЍH��敪����';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.ENABLED_FLAG IS '�L���t���O';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.START_DATE_ACTIVE IS '�J�n��';
COMMENT ON COLUMN XXCFF_FA_LOCATION_V.END_DATE_ACTIVE IS '�I����';
COMMENT ON TABLE XXCFF_FA_LOCATION_V IS '���Ə��}�X�^�r���[';
