CREATE OR REPLACE FORCE VIEW XXCFF_FIXED_ASSETS_V
(
ASSET_ID,                      --���YID
ASSET_NUMBER,                  --���Y�ԍ�
BOOK_TYPE_CODE,                --�䒠��
COST,                          --�擾���z
ADJUSTED_RECOVERABLE_COST,     --���p�Ώۊz
DEPRN_RESERVE,                 --�����뉿�z
YTD_DEPRN,                     --�N���p�݌v�z
TOTAL_AMOUNT,                  --���p�݌v�z
PERIOD_NAME,                   --�������p�Ώۊ���
ORIGINAL_COST,                 --�����擾���z
SALVAGE_VALUE,                 --�c�����z
DATE_PLACED_IN_SERVICE,        --���Ƌ��p��
CATEGORY_CODE,                 --�J�e_���CODE
CATEGORY_NAME,                 --�J�e_���DESC
DCLR_DPRN_CODE,                --�J�e_���p�\��CODE
DCLR_DPRN_NAME,                --�J�e_���p�\��DESC
ASSET_ACCOUNT_CODE,            --�J�e_���Y����CODE
ASSET_ACCOUNT_NAME,            --�J�e_���Y����DESC
ACCOUNT_CODE,                  --�J�e_���p�Ȗ�CODE
ACCOUNT_NAME,                  --�J�e_���p�Ȗ�DESC
SEGMENT5,                      --�J�e_�ϗp�N��CODE
SEGMENT5_DESC,                 --�J�e_�ϗp�N��DESC
DPRN_METHOD_CODE,              --�J�e_���p���@CODE
DPRN_METHOD_NAME,              --�J�e_���p���@DESC
LEASE_CLASS_CODE,              --�J�e_���[�X���CODE
LEASE_CLASS_NAME,              --�J�e_���[�X���DESC
DCLR_PLACE_CODE,               --���P_�\���nCODE
DCLR_PLACE_NAME,               --���P_�\���nDESC
DEPARTMENT_CODE,               --���P_�Ǘ�����CODE
DEPARTMENT_NAME,               --���P_�Ǘ�����DESC
MNG_PLACE_CODE,                --���P_���Ə�CODE
MNG_PLACE_NAME,                --���P_���Ə�DESC
PLACE_CODE,                    --���P_�ꏊCODE
PLACE_NAME,                    --���P_�ꏊDESC
OWNER_COMPANY_CODE,            --���P_�{�ЍH��敪CODE
OWNER_COMPANY_NAME,            --���P_�{�ЍH��敪DESC
ACC_COMPANY_CODE,              --��v_���CODE
ACC_COMPANY_NAME,              --��v_���DESC
ACC_DEPARTMENT_CODE,           --��v_����CODE
ACC_DEPARTMENT_NAME,           --��v_����DESC
ACC_DPRN_ACCOUNT_CODE,         --��v_����Ȗ�CODE
ACC_DPRN_ACCOUNT_NAME,         --��v_����Ȗ�DESC
ACC_DPRN_SUB_ACCOUNT_CODE,     --��v_�⏕�Ȗ�CODE
ACC_DPRN_SUB_ACCOUNT_NAME,     --��v_�⏕�Ȗ�DESC
ACC_DPRN_CUSTOMER_CODE,        --��v_�ڋq�R�[�hCODE
ACC_DPRN_CUSTOMER_NAME,        --��v_�ڋq�R�[�hDESC
ACC_DPRN_ENTERPRISE_CODE,      --��v_��ƃR�[�hCODE
ACC_DPRN_ENTERPRISE_NAME,      --��v_��ƃR�[�hDESC
ACC_DPRN_RESERVE1_CODE,        --��v_�\��1CODE
ACC_DPRN_RESERVE1_NAME,        --��v_�\��1DESC
ACC_DPRN_RESERVE2_CODE,        --��v_�\��2CODE
ACC_DPRN_RESERVE2_NAME,        --��v_�\��2DESC
CODE_COMBINATION_ID,           --�������pID
DESCRIPTION,                   --�E�v
CURRENT_UNITS,                 --�P��
DEPRN_METHOD_CODE,             --���p���@
LIFE_IN_YEAR,                  --�ϗp�N��_�N
LIFE_IN_MONTHS,                --�ϗp�N��_��
RESERVE1_CODE1,                --�\��1
RESERVE1_CODE2,                --�\��2
ATTRIBUTE1,                    --�X�V�p���Ƌ��p��
ATTRIBUTE2,                    --�擾��
ATTRIBUTE3,                    --�\��
ATTRIBUTE4,                    --�ז�
ATTRIBUTE5,                    --���k�L���E�T������
ATTRIBUTE6,                    --���k�T���z
ATTRIBUTE7,                    --���k��擾���z
ATTRIBUTE8,                    --���Y�O���[�v�ԍ�
ATTRIBUTE9,                    --�����v�Z���ԗ���
ATTRIBUTE10,                   --�����R�[�h
ATTRIBUTE11,                   --���[�X���Y
ATTRIBUTE12,                   --�J���Z�O�����g
ATTRIBUTE13,                   --�ʐ�
LAST_UPDATE_DATE,              --�ŏI�X�V��
LAST_UPDATED_BY,               --�ŏI�X�V��
CREATED_BY,                    --�쐬��
CREATION_DATE,                 --�쐬��
LAST_UPDATE_LOGIN              --�ŏI�X�V���O�C��
)
AS 
SELECT MAIN.ASSET_ID                AS ASSET_ID--���YID
      ,C.ASSET_NUMBER               AS ASSET_NUMBER--���Y�ԍ�
      ,MAIN.BOOK_TYPE_CODE          AS BOOK_TYPE_CODE--�䒠��
      ,MAIN.COST                    AS COST--�擾���z
      ,MAIN.ADJUSTED_RECOVERABLE_COST  AS ADJUSTED_RECOVERABLE_COST--���p�Ώۊz
      ,MAIN.DEPRN_RESERVE           AS DEPRN_RESERVE--�����뉿�z
      ,MAIN.YTD_DEPRN               AS YTD_DEPRN--�N���p�݌v�z
      ,MAIN.TOTAL_AMOUNT            AS TOTAL_AMOUNT--���p�݌v�z
      ,FDP.PERIOD_NAME              AS PERIOD_NAME--�������p�Ώۊ���
      ,MAIN.ORIGINAL_COST           AS ORIGINAL_COST--�����擾���z
      ,MAIN.SALVAGE_VALUE           AS SALVAGE_VALUE--�c�����z
      ,MAIN.DATE_PLACED_IN_SERVICE  AS DATE_PLACED_IN_SERVICE--���Ƌ��p��
      ,FC.SEGMENT1                  AS CATEGORY_CODE--�J�e_���CODE
      ,FC.SEGMENT1_DESC             AS CATEGORY_NAME--�J�e_���DESC
      ,FC.SEGMENT2                  AS DCLR_DPRN_CODE--�J�e_���p�\��CODE
      ,FC.SEGMENT2_DESC             AS DCLR_DPRN_NAME--�J�e_���p�\��DESC
      ,FC.SEGMENT3                  AS ASSET_ACCOUNT_CODE--�J�e_���Y����CODE
      ,FC.SEGMENT3_DESC             AS ASSET_ACCOUNT_NAME--�J�e_���Y����DESC
      ,FC.SEGMENT4                  AS ACCOUNT_CODE--�J�e_���p�Ȗ�CODE
      ,FC.SEGMENT4_DESC             AS ACCOUNT_NAME--�J�e_���p�Ȗ�DESC
      ,FC.SEGMENT5                  AS SEGMENT5--�J�e_�ϗp�N��CODE
      ,FC.SEGMENT5_DESC             AS SEGMENT5_DESC--�J�e_�ϗp�N��DESC
      ,FC.SEGMENT6                  AS DPRN_METHOD_CODE--�J�e_���p���@CODE
      ,FC.SEGMENT6_DESC             AS DPRN_METHOD_NAME--�J�e_���p���@DESC
      ,FC.SEGMENT7                  AS LEASE_CLASS_CODE--�J�e_���[�X���CODE
      ,FC.SEGMENT7_DESC             AS LEASE_CLASS_NAME--�J�e_���[�X���DESC
      ,FL.SEGMENT1                  AS DCLR_PLACE_CODE--���P_�\���nCODE
      ,FL.SEGMENT1_DESC             AS DCLR_PLACE_NAME--���P_�\���nDESC
      ,FL.SEGMENT2                  AS DEPARTMENT_CODE--���P_�Ǘ�����CODE
      ,FL.SEGMENT2_DESC             AS DEPARTMENT_NAME--���P_�Ǘ�����DESC
      ,FL.SEGMENT3                  AS MNG_PLACE_CODE--���P_���Ə�CODE
      ,FL.SEGMENT3_DESC             AS MNG_PLACE_NAME--���P_���Ə�DESC
      ,FL.SEGMENT4                  AS PLACE_CODE--���P_�ꏊCODE
      ,FL.SEGMENT4                  AS PLACE_NAME--���P_�ꏊDESC
      ,FL.SEGMENT5                  AS OWNER_COMPANY_CODE--���P_�{�ЍH��敪CODE
      ,FL.SEGMENT5_DESC             AS OWNER_COMPANY_NAME--���P_�{�ЍH��敪DESC
      ,CC.SEGMENT1                  AS ACC_COMPANY_CODE--��v_���CODE
      ,CC.SEGMENT1_DESC             AS ACC_COMPANY_NAME--��v_���DESC
      ,CC.SEGMENT2                  AS ACC_DEPARTMENT_CODE--��v_����CODE
      ,CC.SEGMENT2_DESC             AS ACC_DEPARTMENT_NAME--��v_����DESC
      ,CC.SEGMENT3                  AS ACC_DPRN_ACCOUNT_CODE--��v_����Ȗ�CODE
      ,CC.SEGMENT3_DESC             AS ACC_DPRN_ACCOUNT_NAME--��v_����Ȗ�DESC
      ,CC.SEGMENT4                  AS ACC_DPRN_SUB_ACCOUNT_CODE--��v_�⏕�Ȗ�CODE
      ,CC.SEGMENT4_DESC             AS ACC_DPRN_SUB_ACCOUNT_NAME--��v_�⏕�Ȗ�DESC
      ,CC.SEGMENT5                  AS ACC_DPRN_CUSTOMER_CODE--��v_�ڋq�R�[�hCODE
      ,CC.SEGMENT5_DESC             AS ACC_DPRN_CUSTOMER_NAME--��v_�ڋq�R�[�hDESC
      ,CC.SEGMENT6                  AS ACC_DPRN_ENTERPRISE_CODE--��v_��ƃR�[�hCODE
      ,CC.SEGMENT6_DESC             AS ACC_DPRN_ENTERPRISE_NAME--��v_��ƃR�[�hDESC
      ,CC.SEGMENT7                  AS ACC_DPRN_RESERVE1_CODE--��v_�\��1CODE
      ,CC.SEGMENT7_DESC             AS ACC_DPRN_RESERVE1_NAME--��v_�\��1DESC
      ,CC.SEGMENT8                  AS ACC_DPRN_RESERVE2_CODE--��v_�\��2CODE
      ,CC.SEGMENT8_DESC             AS ACC_DPRN_RESERVE2_NAME--��v_�\��2DESC
      ,D.CODE_COMBINATION_ID        AS CODE_COMBINATION_ID--�������pID
      ,C.DESCRIPTION                AS DESCRIPTION--�E�v
      ,C.CURRENT_UNITS              AS CURRENT_UNITS--�P��
      ,MAIN.DEPRN_METHOD_CODE       AS DEPRN_METHOD_CODE--���p���@
      ,MAIN.LIFE_IN_YEAR            AS LIFE_IN_YEAR--�ϗp�N��_�N
      ,MAIN.LIFE_IN_MONTHS          AS LIFE_IN_MONTHS--�ϗp�N��_��
      ,FA.SEGMENT1                  AS RESERVE1_CODE1  --�\��1
      ,FA.SEGMENT2                  AS RESERVE1_CODE2  --�\��2
      ,C.ATTRIBUTE1                 AS ATTRIBUTE1--�X�V�p���Ƌ��p��
      ,C.ATTRIBUTE2                 AS ATTRIBUTE2--�擾��
      ,C.ATTRIBUTE3                 AS ATTRIBUTE3--�\��
      ,C.ATTRIBUTE4                 AS ATTRIBUTE4--�ז�
      ,C.ATTRIBUTE5                 AS ATTRIBUTE5--"���k�L���E�T������"
      ,C.ATTRIBUTE6                 AS ATTRIBUTE6--���k�T���z
      ,C.ATTRIBUTE7                 AS ATTRIBUTE7--���k��擾���z
      ,C.ATTRIBUTE8                 AS ATTRIBUTE8--���Y�O���[�v�ԍ�
      ,C.ATTRIBUTE9                 AS ATTRIBUTE9--�����v�Z���ԗ���
      ,C.ATTRIBUTE10                AS ATTRIBUTE10--�����R�[�h
      ,C.ATTRIBUTE11                AS ATTRIBUTE11--���[�X���Y
      ,C.ATTRIBUTE12                AS ATTRIBUTE12--�J���Z�O�����g
      ,C.ATTRIBUTE13                AS ATTRIBUTE13--�ʐ�
      ,C.LAST_UPDATE_DATE           AS LAST_UPDATE_DATE--�ŏI�X�V��
      ,C.LAST_UPDATED_BY            AS LAST_UPDATED_BY--�ŏI�X�V��
      ,C.CREATED_BY                 AS CREATED_BY--�쐬��
      ,C.CREATION_DATE              AS CREATION_DATE--�쐬��
      ,C.LAST_UPDATE_LOGIN          AS LAST_UPDATE_LOGIN--�ŏI�X�V���O�C��
FROM   FA_BOOK_CONTROLS          FBC  -- ���Y�䒠      
      ,FA_ADDITIONS              C    -- ���Y�ڍ�
      ,FA_DISTRIBUTION_HISTORY   D    -- ���Y����
      ,FA_DEPRN_PERIODS          FDP  -- �������p����
      ,XXCFF_FA_CATEGORY_V       FC   -- ���Y�J�e�S���}�X�^
      ,XXCFF_FA_LOCATION_V       FL   -- ���Ə��}�X�^
      ,XXCFF_FA_CCID_V           CC   -- ����Ȗڑ̌n�}�X�^
      ,FA_ASSET_KEYWORDS         FA
      ,(SELECT  B.ASSET_ID                     AS ASSET_ID--���YID
               ,B.BOOK_TYPE_CODE               AS BOOK_TYPE_CODE--�䒠��
               ,B.COST                         AS COST--�擾���z
               ,B.ADJUSTED_RECOVERABLE_COST    AS ADJUSTED_RECOVERABLE_COST--���p�Ώۊz
               ,DECODE(SIGN(B.COST - NVL(FDS.DEPRN_RESERVE, 0)),1,B.COST - NVL(FDS.DEPRN_RESERVE, 0),0) AS DEPRN_RESERVE--�����뉿�z
               ,FDS.YTD_DEPRN                  AS YTD_DEPRN--�N���p�݌v�z
               ,FDS.DEPRN_RESERVE              AS TOTAL_AMOUNT--���p�݌v�z
               ,B.ORIGINAL_COST                AS ORIGINAL_COST--�����擾���z
               ,B.SALVAGE_VALUE                AS SALVAGE_VALUE--�c�����z
               ,B.DATE_PLACED_IN_SERVICE       AS DATE_PLACED_IN_SERVICE--���Ƌ��p��
               ,B.DEPRN_METHOD_CODE            AS DEPRN_METHOD_CODE--���p���@
               ,NVL(TRUNC(B.LIFE_IN_MONTHS/12),0)  AS LIFE_IN_YEAR--�ϗp�N��_�N
               ,NVL(  MOD(B.LIFE_IN_MONTHS,12),0)  AS LIFE_IN_MONTHS--�ϗp�N��_��
               ,FDS.PERIOD_COUNTER           AS PERIOD_COUNTER
        FROM    FA_BOOKS                  B    -- ���Y�䒠���
              ,(SELECT  FDSY.DEPRN_RESERVE
                       ,FDSY.YTD_DEPRN                  AS YTD_DEPRN--�N���p�݌v�z
                       ,FDSY.DEPRN_RESERVE              AS TOTAL_AMOUNT--���p�݌v�z
                       ,FDSY.PERIOD_COUNTER
                       ,FDSY.ASSET_ID
                       ,FDSY.BOOK_TYPE_CODE
                 FROM   FA_DEPRN_SUMMARY  FDSY
                 WHERE  FDSY.DEPRN_SOURCE_CODE   = 'DEPRN')FDS  -- �������p�T�}��
              ,(SELECT MAX(FDSY.PERIOD_COUNTER) PERIOD_COUNTER
                      ,FDSY.ASSET_ID
                      ,FDSY.BOOK_TYPE_CODE
                FROM   FA_DEPRN_SUMMARY  FDSY
                GROUP BY FDSY.ASSET_ID
                        ,FDSY.BOOK_TYPE_CODE) FDS_MAX
        WHERE  B.BOOK_TYPE_CODE        = FDS_MAX.BOOK_TYPE_CODE-- �䒠��
        AND    B.TRANSACTION_HEADER_ID_OUT IS NULL  -- �ŐV�̑䒠�f�[�^
        AND    B.ASSET_ID              = FDS_MAX.ASSET_ID -- ���YID
        AND   FDS.PERIOD_COUNTER(+)    =  FDS_MAX.PERIOD_COUNTER
        AND   FDS.ASSET_ID(+)          =  FDS_MAX.ASSET_ID
        AND   FDS.BOOK_TYPE_CODE(+)    =  FDS_MAX.BOOK_TYPE_CODE) MAIN -- ���p
WHERE  FBC.DISTRIBUTION_SOURCE_BOOK    =  FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
AND    FBC.BOOK_TYPE_CODE              = MAIN.BOOK_TYPE_CODE -- �䒠��
AND    MAIN.ASSET_ID                   = C.ASSET_ID -- 	���YID
AND    D.TRANSACTION_HEADER_ID_OUT IS NULL  -- �ŐV�̊����f�[�^
AND    MAIN.ASSET_ID           = D.ASSET_ID -- ���YID
AND    FBC.LAST_PERIOD_COUNTER = FDP.PERIOD_COUNTER -- �J�����_ID
AND    FBC.BOOK_TYPE_CODE      = FDP.BOOK_TYPE_CODE -- �䒠��
AND    C.ASSET_CATEGORY_ID     = FC.CATE_CCID -- ���Y�J�e�S��ID
AND    D.LOCATION_ID           = FL.LOCATION_ID -- ���Ə�ID
AND    D.CODE_COMBINATION_ID   = CC.CCID-- ��v�Z�O�����gID
AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ID IS '���YID'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_NUMBER IS '���Y�ԍ�'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BOOK_TYPE_CODE IS '�䒠��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.COST IS '�擾���z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADJUSTED_RECOVERABLE_COST IS '���p�Ώۊz'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE IS '�����뉿�z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YTD_DEPRN IS '�N���p�݌v�z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.TOTAL_AMOUNT IS '���p�݌v�z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PERIOD_NAME IS '�������p�Ώۊ���'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ORIGINAL_COST IS '�����擾���z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SALVAGE_VALUE IS '�c�����z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DATE_PLACED_IN_SERVICE IS '���Ƌ��p��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_CODE IS '�J�e_���CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_NAME IS '�J�e_���DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_CODE IS '�J�e_���p�\��CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_NAME IS '�J�e_���p�\��DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_CODE IS '�J�e_���Y����CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_NAME IS '�J�e_���Y����DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_CODE IS '�J�e_���p���@CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_NAME IS '�J�e_���p���@DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5 IS '�J�e_�ϗp�N��CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5_DESC IS '�J�e_�ϗp�N��DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_CODE IS '�J�e_���p�Ȗ�CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_NAME IS '�J�e_���p�Ȗ�DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_CODE IS '�J�e_���[�X���CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_NAME IS '�J�e_���[�X���DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_CODE IS '���P_�\���nCODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_NAME IS '���P_�\���nDESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_CODE IS '���P_�Ǘ�����CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_NAME IS '���P_�Ǘ�����DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_CODE IS '���P_���Ə�CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_NAME IS '���P_���Ə�DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_CODE IS '���P_�ꏊCODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_NAME IS '���P_�ꏊDESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_CODE IS '���P_�{�ЍH��敪CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_NAME IS '���P_�{�ЍH��敪DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_CODE IS '��v_���CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_NAME IS '��v_���DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_CODE IS '��v_����CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_NAME IS '��v_����DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_CODE IS '��v_����Ȗ�CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_NAME IS '��v_����Ȗ�DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_CODE IS '��v_�⏕�Ȗ�CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_NAME IS '��v_�⏕�Ȗ�DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_CODE IS '��v_�ڋq�R�[�hCODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_NAME IS '��v_�ڋq�R�[�hDESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_CODE IS '��v_��ƃR�[�hCODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_NAME IS '��v_��ƃR�[�hDESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_CODE IS '��v_�\��1CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_NAME IS '��v_�\��1DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_CODE IS '��v_�\��2CODE'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_NAME IS '��v_�\��2DESC'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CODE_COMBINATION_ID IS '�������pID'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DESCRIPTION IS '�E�v'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CURRENT_UNITS IS '�P��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_METHOD_CODE IS '���p���@'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_YEAR IS '�ϗp�N��_�N'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_MONTHS IS '�ϗp�N��_��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE1 IS '�\��1'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE2 IS '�\��2'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE1 IS '�X�V�p���Ƌ��p��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE2 IS '�擾��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE3 IS '�\��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE4 IS '�ז�'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE5 IS '���k�L���E�T������'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE6 IS '���k�T���z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE7 IS '���k��擾���z'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE8 IS '���Y�O���[�v�ԍ�'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE9 IS '�����v�Z���ԗ���'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE10 IS '�����R�[�h'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE11 IS '���[�X���Y'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE12 IS '�J���Z�O�����g'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE13 IS '�ʐ�'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_DATE IS '�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATED_BY IS '�ŏI�X�V��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATED_BY IS '�쐬��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATION_DATE IS '�쐬��'
/
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_LOGIN IS '�ŏI�X�V���O�C��'
/
COMMENT ON TABLE XXCFF_FIXED_ASSETS_V IS '�Œ莑�Y�ꗗ�Ɖ�r���['
/
