CREATE OR REPLACE FORCE VIEW XXCFF_FIXED_ASSETS_V
(
ASSET_ID,                      --���YID
ASSET_NUMBER,                  --���Y�ԍ�
BOOK_TYPE_CODE,                --�䒠��
COST,                          --�擾���z
ADJUSTED_RECOVERABLE_COST,     --���p�Ώۊz
DEPRN_RESERVE,                 --�����뉿�z
-- ADD E_�{�ғ�_04156 2010/08/04 Start
LAST_FISCAL_YEAR,              --�䒠�ŐV��v�N�x
DEPRN_FISCAL_YEAR,             --�ŏI���p����v�N�x
-- ADD E_�{�ғ�_04156 2010/08/04 End
YTD_DEPRN,                     --�N���p�݌v�z
TOTAL_AMOUNT,                  --���p�݌v�z
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
MONTH_DEPRN,                   --�������p�݌v�z
BONUS_DEPRN_AMOUNT,            --�ްŽ���p
BONUS_YTD_DEPRN,               --�ްŽ�N���p�݌v�z
BONUS_DEPRN_RESERVE,           --�ްŽ���p�݌v�z
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
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
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
RATE,                          --���p��(���ʏ��p��)
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
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
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
ATTRIBUTE17,                   --IFRS�s���Y�擾��
ATTRIBUTE18,                   --IFRS�ؓ��R�X�g
ATTRIBUTE19,                   --IFRS���̑�
ATTRIBUTE22,                   --�Œ莑�Y���Y�ԍ�
ATTRIBUTE23,                   --IFRS�Ώێ��Y�ԍ�
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
LAST_UPDATE_DATE,              --�ŏI�X�V��
LAST_UPDATED_BY,               --�ŏI�X�V��
CREATED_BY,                    --�쐬��
CREATION_DATE,                 --�쐬��
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
--LAST_UPDATE_LOGIN              --�ŏI�X�V���O�C��
LAST_UPDATE_LOGIN,              --�ŏI�X�V���O�C��
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
KISYU_BOKA,                       -- ���񒠕뉿�z
YEAR_ADD_AMOUNT,                  -- ���������z
ADD_AMOUNT,                       -- ���������z
YEAR_DEL_AMOUNT,                  -- ���������z
DELETE_AMOUNT,                    -- ���������z
DEPRN_RESERVE_12                  -- ���������뉿�z
-- Modify E_�{�ғ�_14502 2017/12/14 End
)
AS 
-- Modify 2009.08.19 Ver1.1 Start
--  SELECT MAIN.ASSET_ID                AS ASSET_ID--���YID
  SELECT
         /*+   
-- Modify E_�ŏI�ڍs���n_00469 2009.10.13 Start
           LEADING(MAIN) --LEADING(MAIN.B)
-- Modify E_�ŏI�ڍs���n_00469 2009.10.13 End
           USE_NL(MAIN C FC D FA FL CC)
           INDEX(FBC      FA_BOOK_CONTROLS_U1)
           INDEX(C.B      FA_ADDITIONS_B_U1)
           INDEX(C.T      FA_ADDITIONS_TL_U1)
           INDEX(D        FA_DISTRIBUTION_HISTORY_N2)
           INDEX(FA       FA_ASSET_KEYWORDS_U1)
           INDEX(CC.GCC   GL_CODE_COMBINATIONS_U1) 
           INDEX(FC.FCB.T FA_CATEGORIES_TL_U1)
           INDEX(FC.FCB.B FA_CATEGORIES_B_U1)
           INDEX(FL.FLC   FA_LOCATIONS_U1)
         */
       MAIN.ASSET_ID                AS ASSET_ID--���YID
-- Modify 2009.08.19 Ver1.1 End
      ,C.ASSET_NUMBER               AS ASSET_NUMBER--���Y�ԍ�
      ,MAIN.BOOK_TYPE_CODE          AS BOOK_TYPE_CODE--�䒠��
      ,MAIN.COST                    AS COST--�擾���z
      ,MAIN.ADJUSTED_RECOVERABLE_COST  AS ADJUSTED_RECOVERABLE_COST--���p�Ώۊz
      ,MAIN.DEPRN_RESERVE           AS DEPRN_RESERVE--�����뉿�z
--
-- Modify E_�{�ғ�_04156 2010/08/04 Start
      ,MAIN.LAST_FISCAL_YEAR        AS LAST_FISCAL_YEAR  --�䒠�̍ŐV��v�N�x
      ,MAIN.DEPRN_FISCAL_YEAR       AS DEPRN_FISCAL_YEAR --���Y�̍ŏI���p���̉�v�N�x
      ,CASE
         WHEN (MAIN.LAST_FISCAL_YEAR = MAIN.DEPRN_FISCAL_YEAR) THEN
           MAIN.YTD_DEPRN
         ELSE
           0
         END YTD_DEPRN                                       --�N���p�݌v�z
      --,MAIN.YTD_DEPRN               AS YTD_DEPRN--�N���p�݌v�z
-- Modify E_�{�ғ�_04156 2010/08/04 End
--
      ,MAIN.TOTAL_AMOUNT            AS TOTAL_AMOUNT--���p�݌v�z
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
      ,MAIN.MONTH_DEPRN                 AS MONTH_DEPRN                      -- �������p�݌v�z
      ,MAIN.BONUS_DEPRN_AMOUNT          AS BONUS_DEPRN_AMOUNT               -- �ްŽ���p
      ,MAIN.BONUS_YTD_DEPRN             AS BONUS_YTD_DEPRN                  -- �ްŽ�N���p�݌v�z
      ,MAIN.BONUS_DEPRN_RESERVE         AS BONUS_DEPRN_RESERVE              -- �ްŽ���p�݌v�z
-- Modify E_�{�ғ�_14502 2017/12/14 end
--
-- Modify 2009.08.19 Ver1.1 Start
--      ,FDP.PERIOD_NAME              AS PERIOD_NAME--�������p�Ώۊ���
      ,MAIN.PERIOD_NAME             AS PERIOD_NAME--�������p�Ώۊ���
-- Modify 2009.08.19 Ver1.1 End
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
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
      ,MAIN.BASIC_RATE * 100            AS RATE                             -- ���p��(���ʏ��p��)
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
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
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
      ,C.ATTRIBUTE17                    AS ATTRIBUTE17                      -- IFRS�s���Y�擾��
      ,C.ATTRIBUTE18                    AS ATTRIBUTE18                      -- IFRS�ؓ��R�X�g
      ,C.ATTRIBUTE19                    AS ATTRIBUTE19                      -- IFRS���̑�
      ,C.ATTRIBUTE22                    AS ATTRIBUTE22                      -- �Œ莑�Y���Y�ԍ�
      ,C.ATTRIBUTE23                    AS ATTRIBUTE23                      -- IFRS�Ώێ��Y�ԍ�
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
      ,C.LAST_UPDATE_DATE           AS LAST_UPDATE_DATE--�ŏI�X�V��
      ,C.LAST_UPDATED_BY            AS LAST_UPDATED_BY--�ŏI�X�V��
      ,C.CREATED_BY                 AS CREATED_BY--�쐬��
      ,C.CREATION_DATE              AS CREATION_DATE--�쐬��
      ,C.LAST_UPDATE_LOGIN          AS LAST_UPDATE_LOGIN--�ŏI�X�V���O�C��
--
-- Modify E_�{�ғ�_14502 2018/01/12 Start
      ,CASE
         WHEN (NVL(KISYU.KISYU_BOKA, 0) = 0)
         AND  (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE,'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE,'YYYYMM')) THEN
           CASE
             WHEN (MAIN.LAST_FISCAL_YEAR = MAIN.DEPRN_FISCAL_YEAR) THEN
               MAIN.YTD_DEPRN + MAIN.DEPRN_RESERVE            --�ߋ��N�x�̎��Y�𓖔N�Ɏ��Y�ǉ������ꍇ�A����뉿�����Ȃ��̂ŁA-���������뉿�z�{�N���p�݌v�z�ŎZ�o
             ELSE
               MAIN.DEPRN_RESERVE
             END
         ELSE
           NVL(KISYU.KISYU_BOKA, 0)
         END                            AS KISYU_BOKA                       -- ���񒠕뉿�z
-- Modify E_�{�ғ�_14502 2018/01/12 End
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM'))
         AND  (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') >= TO_CHAR(MAIN.CALENDAR_PERIOD_OPEN_DATE , 'YYYYMM')) THEN
           MAIN.COST
         ELSE
           0
         END                            AS YEAR_ADD_AMOUNT                  -- ���������z
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_PLACED_IN_SERVICE, 'YYYYMM') = TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM')) THEN
           MAIN.COST
         ELSE
           0
         END                            AS ADD_AMOUNT                       -- ���������z
      ,CASE
         WHEN (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') <= TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM'))
         AND  (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') >= TO_CHAR(MAIN.CALENDAR_PERIOD_OPEN_DATE, 'YYYYMM')) THEN
           MAIN.NBV_RETIRED     -- �����p���뉿�z
         ELSE
           0
         END                            AS YEAR_DEL_AMOUNT                  -- ���������z
      ,CASE
        WHEN (TO_CHAR(MAIN.DATE_RETIRED, 'YYYYMM') = TO_CHAR(MAIN.CALENDAR_PERIOD_CLOSE_DATE, 'YYYYMM')) THEN
          MAIN.NBV_RETIRED      -- �����p���뉿�z
        ELSE
          0
        END                             AS DELETE_AMOUNT                    -- ���������z
      ,MAIN.DEPRN_RESERVE               AS DEPRN_RESERVE_12                 -- ���������뉿�z
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
-- Modify 2009.08.19 Ver1.1 Start
--FROM   FA_BOOK_CONTROLS          FBC  -- ���Y�䒠
--      ,FA_ADDITIONS              C    -- ���Y�ڍ�
FROM   FA_ADDITIONS              C    -- ���Y�ڍ�
-- Modify 2009.08.19 Ver1.1 End
      ,FA_DISTRIBUTION_HISTORY   D    -- ���Y����
-- Modify 2009.08.19 Ver1.1 Start
--      ,FA_DEPRN_PERIODS          FDP  -- �������p����
-- Modify 2009.08.19 Ver1.1 End
      ,XXCFF_FA_CATEGORY_V       FC   -- ���Y�J�e�S���}�X�^
      ,XXCFF_FA_LOCATION_V       FL   -- ���Ə��}�X�^
      ,XXCFF_FA_CCID_V           CC   -- ����Ȗڑ̌n�}�X�^
      ,FA_ASSET_KEYWORDS         FA
-- Modify 2009.08.19 Ver1.1 Start
--      ,(SELECT  B.ASSET_ID                     AS ASSET_ID--���YID
-- Modify E_�{�ғ�_14502 2018/01/16 Start
--      ,(SELECT  /*+ USE_NL(FBC B FDP FDS FDS_MAX)
--                    INDEX( FDP FA_DEPRN_PERIODS_U3)
--                */
      ,(SELECT  /*+ USE_NL(FBC B FDP FDS FDS_MAX)
                    INDEX( B FA_BOOKS_N1)
                    INDEX( FDP FA_DEPRN_PERIODS_U3)
                */
-- Modify E_�{�ғ�_14502 2018/01/16 End
                B.ASSET_ID                     AS ASSET_ID--���YID
-- Modify 2009.08.19 Ver1.1 End
               ,B.BOOK_TYPE_CODE               AS BOOK_TYPE_CODE--�䒠��
               ,B.COST                         AS COST--�擾���z
               ,B.ADJUSTED_RECOVERABLE_COST    AS ADJUSTED_RECOVERABLE_COST--���p�Ώۊz
               ,DECODE(SIGN(B.COST - NVL(FDS.DEPRN_RESERVE, 0)),1,B.COST - NVL(FDS.DEPRN_RESERVE, 0),0) AS DEPRN_RESERVE--�����뉿�z
               ,FDS.YTD_DEPRN                  AS YTD_DEPRN--�N���p�݌v�z
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
--               ,FDS.DEPRN_RESERVE               AS TOTAL_AMOUNT--���p�݌v�z
               ,FDS.TOTAL_AMOUNT               AS TOTAL_AMOUNT--���p�݌v�z
               ,FDS.DEPRN_AMOUNT                    AS MONTH_DEPRN                          -- �������p�݌v�z
               ,FDS.BONUS_DEPRN_AMOUNT                                                      -- �ްŽ���p
               ,FDS.BONUS_YTD_DEPRN                                                         -- �ްŽ�N���p�݌v�z
               ,FDS.BONUS_DEPRN_RESERVE                                                     -- �ްŽ���p�݌v�z
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
               ,B.ORIGINAL_COST                AS ORIGINAL_COST--�����擾���z
               ,B.SALVAGE_VALUE                AS SALVAGE_VALUE--�c�����z
               ,B.DATE_PLACED_IN_SERVICE       AS DATE_PLACED_IN_SERVICE--���Ƌ��p��
               ,B.DEPRN_METHOD_CODE            AS DEPRN_METHOD_CODE--���p���@
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
               ,B.BASIC_RATE                        AS BASIC_RATE                           -- ���p��(���ʏ��p��)
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
               ,NVL(TRUNC(B.LIFE_IN_MONTHS/12),0)  AS LIFE_IN_YEAR--�ϗp�N��_�N
               ,NVL(  MOD(B.LIFE_IN_MONTHS,12),0)  AS LIFE_IN_MONTHS--�ϗp�N��_��
               ,FDS.PERIOD_COUNTER           AS PERIOD_COUNTER
-- Modify 2009.08.19 Ver1.1 Start
               ,FDP.PERIOD_NAME              AS PERIOD_NAME
-- Modify 2009.08.19 Ver1.1 End
--
-- Add E_�{�ғ�_04156 2010/08/04 Start
               ,FDP.FISCAL_YEAR              AS LAST_FISCAL_YEAR                         --�䒠�̍ŐV��v�N�x
               ,(SELECT /*+ 
                            INDEX( FDP_FISCAL FA_DEPRN_PERIODS_U3)
                        */
                        FDP_FISCAL.FISCAL_YEAR
                 FROM APPS.FA_DEPRN_PERIODS FDP_FISCAL
                 WHERE B.BOOK_TYPE_CODE   = FDP_FISCAL.BOOK_TYPE_CODE
                 AND   FDS.PERIOD_COUNTER = FDP_FISCAL.PERIOD_COUNTER) DEPRN_FISCAL_YEAR --�ŏI���p���̉�v�N�x
-- Add E_�{�ғ�_04156 2010/08/04 End
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
               ,FDP1.CALENDAR_PERIOD_OPEN_DATE                                              -- �i�������p���ԁj���N�x�J�n��
               ,FDP1.PERIOD_COUNTER                                                         -- �i�������p���ԁj���N�x�J�n�̊��Ԕԍ�
               ,FDP.CALENDAR_PERIOD_CLOSE_DATE                                              -- �i�������p���ԁj��������
               ,FDP.PERIOD_COUNTER                                                          -- �i�������p���ԁj�����̊��Ԕԍ�
               ,RET.DATE_RETIRED                                                            -- �����p��
               ,RET.NBV_RETIRED                                                             -- �����p���뉿�z
               ,B.PERIOD_COUNTER_FULLY_RETIRED                                              -- �S�����p���{�������Ԃh�c
               ,FDP1.PERIOD_COUNTER                 AS PERIOD_COUNTER1                      -- ���N�x�J�n�̊��Ԃh�c
               ,FDP1.FISCAL_YEAR                    AS FISCAL_YEAR                          -- ���N�x�J�n�̊��Ԃh�c
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
        FROM    FA_BOOKS                  B    -- ���Y�䒠���
--
              ,(SELECT  FDSY.DEPRN_RESERVE
-- Modify E_�{�ғ�_14502 2017/12/14 Start
                       ,FDSY.DEPRN_AMOUNT               AS DEPRN_AMOUNT-- �������p�z
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
                       ,FDSY.YTD_DEPRN                  AS YTD_DEPRN--�N���p�݌v�z
                       ,FDSY.DEPRN_RESERVE              AS TOTAL_AMOUNT--���p�݌v�z
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
                       ,FDSY.BONUS_DEPRN_AMOUNT         -- �ްŽ���p
                       ,FDSY.BONUS_YTD_DEPRN            -- �ްŽ�N���p�݌v�z
                       ,FDSY.BONUS_DEPRN_RESERVE        -- �ްŽ�N���p�݌v�z
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
                       ,FDSY.PERIOD_COUNTER
                       ,FDSY.ASSET_ID
                       ,FDSY.BOOK_TYPE_CODE
                 FROM   FA_DEPRN_SUMMARY  FDSY
                 WHERE  FDSY.DEPRN_SOURCE_CODE   = 'DEPRN') FDS  -- �������p�T�}��
              ,(SELECT MAX(FDSY.PERIOD_COUNTER) PERIOD_COUNTER
                      ,FDSY.ASSET_ID
                      ,FDSY.BOOK_TYPE_CODE
                FROM   FA_DEPRN_SUMMARY  FDSY
                GROUP BY FDSY.ASSET_ID
                        ,FDSY.BOOK_TYPE_CODE) FDS_MAX
-- Modify 2009.08.19 Ver1.1 Start
              ,FA_BOOK_CONTROLS          FBC  -- ���Y�䒠�}�X�^
              ,FA_DEPRN_PERIODS          FDP  -- �������p����
-- Modify 2009.08.19 Ver1.1 End
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
              ,FA_DEPRN_PERIODS          FDP1 -- �������p���� �N�n
                -- �����p���
              ,(SELECT /*+
                           INDEX( FR FA_RETIREMENTS_N1)
                       */
                       FR.ASSET_ID                  -- ���YID
                      ,FR.BOOK_TYPE_CODE            -- �䒠
                      ,FR.NBV_RETIRED               -- �����p���뉿�z
                      ,FR.DATE_RETIRED              -- �����p��
                      ,FR.TRANSACTION_HEADER_ID_IN  -- ���ID
                FROM   FA_RETIREMENTS FR
                WHERE  EXISTS (
                                SELECT 1
                                FROM   FA_BOOK_CONTROLS          FBC2  -- ���Y�䒠�}�X�^
                                WHERE  1 = 1
                                AND    FBC2.BOOK_TYPE_CODE = FR.BOOK_TYPE_CODE
                                AND    FBC2.DISTRIBUTION_SOURCE_BOOK  IN ( FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
                                                                          ,FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER'))
                              )
               ) RET
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
        WHERE  B.BOOK_TYPE_CODE        = FDS_MAX.BOOK_TYPE_CODE-- �䒠��
        AND    B.TRANSACTION_HEADER_ID_OUT IS NULL  -- �ŐV�̑䒠�f�[�^
        AND    B.ASSET_ID              = FDS_MAX.ASSET_ID -- ���YID
-- Modify 2009.08.19 Ver1.1 Start
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
--        AND   B.PERIOD_COUNTER_FULLY_RETIRED IS NULL  -- ���E���p�ς݂̌Œ莑�Y�͑ΏۊO
        AND    NVL(B.PERIOD_COUNTER_FULLY_RETIRED,9999999) >= FDP1.PERIOD_COUNTER                   --�� ���N�x�ȍ~�̏����p�f�[�^�͏o�͂���B
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
        AND   FBC.BOOK_TYPE_CODE           = B.BOOK_TYPE_CODE
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
--        AND   FBC.DISTRIBUTION_SOURCE_BOOK = FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')        
        AND    FBC.DISTRIBUTION_SOURCE_BOOK                 IN (FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')  ,
                                                                FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER')) --�� IFRS�䒠���\��
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
        AND   FBC.BOOK_TYPE_CODE           = FDP.BOOK_TYPE_CODE
        AND   FBC.LAST_PERIOD_COUNTER      = FDP.PERIOD_COUNTER
-- Modify 2009.08.19 Ver1.1 End
        AND   FDS.PERIOD_COUNTER(+)    =  FDS_MAX.PERIOD_COUNTER
        AND   FDS.ASSET_ID(+)          =  FDS_MAX.ASSET_ID
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
--        AND   FDS.BOOK_TYPE_CODE(+)    =  FDS_MAX.BOOK_TYPE_CODE) MAIN -- ���p
        AND    FDS.BOOK_TYPE_CODE(+)                        = FDS_MAX.BOOK_TYPE_CODE
        AND    FDP.BOOK_TYPE_CODE                           = FDP1.BOOK_TYPE_CODE
        AND    FDP.FISCAL_YEAR                              = FDP1.FISCAL_YEAR
        AND    FDP1.PERIOD_NUM                              = 1                                     -- �N�n
        AND    B.ASSET_ID                                   = RET.ASSET_ID (+)                      -- �����p�̌���
        AND    B.BOOK_TYPE_CODE                             = RET.BOOK_TYPE_CODE (+)                -- �����p�̌���
        AND    B.TRANSACTION_HEADER_ID_IN                   = RET.TRANSACTION_HEADER_ID_IN (+)      -- �����p�̌���
       ) MAIN -- ���p
      ,(SELECT  /*+
                    INDEX( FB FA_BOOKS_N1)
                */
                FDS.ASSET_ID
               ,FDS.BOOK_TYPE_CODE
               ,FDP_FISCAL.FISCAL_YEAR + 1    AS FISCAL_YEAR      -- �N�x
               ,FDP_FISCAL.PERIOD_CLOSE_DATE                      -- �O�N�N���[�Y��
               ,(FB.COST - FDS.DEPRN_RESERVE) AS KISYU_BOKA       -- ����뉿
               ,FB.COST                       AS KISYU_COST       -- ����擾���z
               ,FDS.DEPRN_RESERVE                                 -- ���񌴉��擾�݌v�z
        FROM    APPS.FA_DEPRN_SUMMARY  FDS
               ,APPS.FA_DEPRN_PERIODS  FDP_FISCAL
               ,APPS.FA_BOOKS          FB
        WHERE   1 = 1
        AND     EXISTS (
                        SELECT 1
                        FROM   FA_BOOK_CONTROLS          FBC3  -- ���Y�䒠�}�X�^
                        WHERE  1 = 1
                        AND    FBC3.BOOK_TYPE_CODE = FDS.BOOK_TYPE_CODE
                        AND    FBC3.DISTRIBUTION_SOURCE_BOOK  IN ( FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
                                                                  ,FND_PROFILE.VALUE('XXCFF1_FIXED_IFRS_ASSET_REGISTER'))
                       )
        AND     FDS.BOOK_TYPE_CODE                 = FDP_FISCAL.BOOK_TYPE_CODE
        AND     FDS.PERIOD_COUNTER                 = FDP_FISCAL.PERIOD_COUNTER
        AND     FDS.DEPRN_SOURCE_CODE              = 'DEPRN'
        AND     FB.ASSET_ID                        = FDS.ASSET_ID
        AND     FB.BOOK_TYPE_CODE                  = FDS.BOOK_TYPE_CODE
        AND     FDP_FISCAL.PERIOD_NUM              = 12
        AND     FB.DATE_EFFECTIVE                 <= FDP_FISCAL.PERIOD_CLOSE_DATE
        AND     NVL(FB.DATE_INEFFECTIVE ,SYSDATE) >= FDP_FISCAL.PERIOD_CLOSE_DATE
       ) KISYU
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
-- Modify 2009.08.19 Ver1.1 Start
--WHERE  FBC.DISTRIBUTION_SOURCE_BOOK    =  FND_PROFILE.VALUE('XXCFF1_FIXED_ASSETS_BOOKS')
--AND    FBC.BOOK_TYPE_CODE              = MAIN.BOOK_TYPE_CODE -- �䒠��
--AND    MAIN.ASSET_ID                   = C.ASSET_ID -- 	���YID
WHERE  MAIN.ASSET_ID           = C.ASSET_ID -- ���YID
-- Modify 2009.08.19 Ver1.1 End
AND    D.TRANSACTION_HEADER_ID_OUT IS NULL  -- �ŐV�̊����f�[�^
AND    MAIN.ASSET_ID           = D.ASSET_ID -- ���YID
-- Modify 2009.08.19 Ver1.1 Start
--AND    FBC.LAST_PERIOD_COUNTER = FDP.PERIOD_COUNTER -- �J�����_ID
--AND    FBC.BOOK_TYPE_CODE      = FDP.BOOK_TYPE_CODE -- �䒠��
-- Modify 2009.08.19 Ver1.1 End
AND    C.ASSET_CATEGORY_ID     = FC.CATE_CCID -- ���Y�J�e�S��ID
AND    D.LOCATION_ID           = FL.LOCATION_ID -- ���Ə�ID
AND    D.CODE_COMBINATION_ID   = CC.CCID-- ��v�Z�O�����gID
-- Modify E_�{�ғ�_13168 2015/08/28 Start
--AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID
AND    C.ASSET_KEY_CCID        = FA.CODE_COMBINATION_ID(+)
-- Modify E_�{�ғ�_13168 2015/08/28 End
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
AND    MAIN.ASSET_ID           = KISYU.ASSET_ID(+)  
AND    MAIN.BOOK_TYPE_CODE     = KISYU.BOOK_TYPE_CODE(+)        --���ǉ��F�����p�̌���
AND    MAIN.FISCAL_YEAR        = KISYU.FISCAL_YEAR(+)
-- Modify E_�{�ғ�_14502 2017/12/14 END
;
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ID IS '���YID';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_NUMBER IS '���Y�ԍ�';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BOOK_TYPE_CODE IS '�䒠��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.COST IS '�擾���z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADJUSTED_RECOVERABLE_COST IS '���p�Ώۊz';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE IS '�����뉿�z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_FISCAL_YEAR IS '�䒠�ŐV��v�N�x';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_FISCAL_YEAR IS '�ŏI���p����v�N�x';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YTD_DEPRN IS '�N���p�݌v�z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.TOTAL_AMOUNT IS '���p�݌v�z';
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MONTH_DEPRN IS '�������p�݌v�z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_DEPRN_AMOUNT IS '�ްŽ���p';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_YTD_DEPRN IS '�ްŽ�N���p�݌v�z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.BONUS_DEPRN_RESERVE IS '�ްŽ���p�݌v�z';
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PERIOD_NAME IS '�������p�Ώۊ���';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ORIGINAL_COST IS '�����擾���z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SALVAGE_VALUE IS '�c�����z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DATE_PLACED_IN_SERVICE IS '���Ƌ��p��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_CODE IS '�J�e_���CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CATEGORY_NAME IS '�J�e_���DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_CODE IS '�J�e_���p�\��CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_DPRN_NAME IS '�J�e_���p�\��DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_CODE IS '�J�e_���Y����CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ASSET_ACCOUNT_NAME IS '�J�e_���Y����DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_CODE IS '�J�e_���p�Ȗ�CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACCOUNT_NAME IS '�J�e_���p�Ȗ�DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5 IS '�J�e_�ϗp�N��CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.SEGMENT5_DESC IS '�J�e_�ϗp�N��DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_CODE IS '�J�e_���p���@CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DPRN_METHOD_NAME IS '�J�e_���p���@DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_CODE IS '�J�e_���[�X���CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LEASE_CLASS_NAME IS '�J�e_���[�X���DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_CODE IS '���P_�\���nCODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DCLR_PLACE_NAME IS '���P_�\���nDESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_CODE IS '���P_�Ǘ�����CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPARTMENT_NAME IS '���P_�Ǘ�����DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_CODE IS '���P_���Ə�CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.MNG_PLACE_NAME IS '���P_���Ə�DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_CODE IS '���P_�ꏊCODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.PLACE_NAME IS '���P_�ꏊDESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_CODE IS '���P_�{�ЍH��敪CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.OWNER_COMPANY_NAME IS '���P_�{�ЍH��敪DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_CODE IS '��v_���CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_COMPANY_NAME IS '��v_���DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_CODE IS '��v_����CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DEPARTMENT_NAME IS '��v_����DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_CODE IS '��v_����Ȗ�CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ACCOUNT_NAME IS '��v_����Ȗ�DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_CODE IS '��v_�⏕�Ȗ�CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_SUB_ACCOUNT_NAME IS '��v_�⏕�Ȗ�DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_CODE IS '��v_�ڋq�R�[�hCODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_CUSTOMER_NAME IS '��v_�ڋq�R�[�hDESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_CODE IS '��v_��ƃR�[�hCODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_ENTERPRISE_NAME IS '��v_��ƃR�[�hDESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_CODE IS '��v_�\��1CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE1_NAME IS '��v_�\��1DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_CODE IS '��v_�\��2CODE';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ACC_DPRN_RESERVE2_NAME IS '��v_�\��2DESC';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CODE_COMBINATION_ID IS '�������pID';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DESCRIPTION IS '�E�v';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CURRENT_UNITS IS '�P��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_METHOD_CODE IS '���p���@';
-- Modify E_�{�ғ�_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RATE IS '���p��';
-- Modify E_�{�ғ�_14502 2017/12/14 End
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_YEAR IS '�ϗp�N��_�N';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LIFE_IN_MONTHS IS '�ϗp�N��_��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE1 IS '�\��1';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.RESERVE1_CODE2 IS '�\��2';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE1 IS '�X�V�p���Ƌ��p��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE2 IS '�擾��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE3 IS '�\��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE4 IS '�ז�';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE5 IS '���k�L���E�T������';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE6 IS '���k�T���z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE7 IS '���k��擾���z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE8 IS '���Y�O���[�v�ԍ�';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE9 IS '�����v�Z���ԗ���';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE10 IS '�����R�[�h';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE11 IS '���[�X���Y';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE12 IS '�J���Z�O�����g';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE13 IS '�ʐ�';
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE17 IS 'IFRS�s���Y�擾��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE18 IS 'IFRS�ؓ��R�X�g';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE19 IS 'IFRS���̑�';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE22 IS '�Œ莑�Y���Y�ԍ�';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ATTRIBUTE23 IS 'IFRS�Ώێ��Y�ԍ�';
-- Modify E_�{�ғ�_14502 2017/12/14 End
--
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_DATE IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATED_BY IS '�ŏI�X�V��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATED_BY IS '�쐬��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.CREATION_DATE IS '�쐬��';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.LAST_UPDATE_LOGIN IS '�ŏI�X�V���O�C��';
--
-- Modify E_�{�ғ�_14502 2017/12/14 Start
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.KISYU_BOKA IS '���񒠕뉿�z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YEAR_ADD_AMOUNT IS '���������z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.ADD_AMOUNT IS '���������z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.YEAR_DEL_AMOUNT IS '���������z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DELETE_AMOUNT IS '���������z';
COMMENT ON COLUMN XXCFF_FIXED_ASSETS_V.DEPRN_RESERVE_12 IS '���������뉿�z';
-- Modify E_�{�ғ�_14502 2017/12/14 End
COMMENT ON TABLE XXCFF_FIXED_ASSETS_V IS '�Œ莑�Y�ꗗ�Ɖ�r���[';

