CREATE OR REPLACE VIEW XXCFF_FA_CATEGORY_V (
 CATE_CCID       -- ���Y�J�e�S��ID
,SEGMENT1        -- �J�e�S����ރR�[�h
,SEGMENT1_DESC   -- �J�e�S����ޖ���
,SEGMENT2        -- �J�e�S�����p�\���R�[�h
,SEGMENT2_DESC   -- �J�e�S�����p�\������
,SEGMENT3        -- �J�e�S�����Y����R�[�h
,SEGMENT3_DESC   -- �J�e�S�����Y���薼��
,SEGMENT4        -- �J�e�S�����p���@�R�[�h
,SEGMENT4_DESC   -- �J�e�S�����p���@����
,SEGMENT5        -- �J�e�S���ϗp�N���R�[�h
,SEGMENT5_DESC   -- �J�e�S���ϗp�N������
,SEGMENT6        -- �J�e�S�����p�ȖڃR�[�h
,SEGMENT6_DESC   -- �J�e�S�����p�Ȗږ���
,SEGMENT7        -- �J�e�S�����[�X��ʃR�[�h
,SEGMENT7_DESC   -- �J�e�S�����[�X��ʖ���
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
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.CATE_CCID IS '���Y�J�e�S��ID'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT1 IS '�J�e�S����ރR�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT1_DESC IS '�J�e�S����ޖ���'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT2 IS '�J�e�S�����p�\���R�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT2_DESC IS '�J�e�S�����p�\������'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT3 IS '�J�e�S�����Y����R�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT3_DESC IS '�J�e�S�����Y���薼��'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT4 IS '�J�e�S�����p���@�R�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT4_DESC IS '�J�e�S�����p���@����'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT5 IS '�J�e�S���ϗp�N���R�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT5_DESC IS '�J�e�S���ϗp�N������'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT6 IS '�J�e�S�����p�ȖڃR�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT6_DESC IS '�J�e�S�����p�Ȗږ���'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT7 IS '�J�e�S�����[�X��ʃR�[�h'
/
COMMENT ON COLUMN XXCFF_FA_CATEGORY_V.SEGMENT7_DESC IS '�J�e�S�����[�X��ʖ���'
/
COMMENT ON TABLE XXCFF_FA_CATEGORY_V IS '���Y�J�e�S���}�X�^�r���['
/
