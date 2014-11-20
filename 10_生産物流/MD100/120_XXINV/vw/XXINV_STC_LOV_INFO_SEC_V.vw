CREATE OR REPLACE FORCE VIEW "APPS"."XXINV_STC_LOV_INFO_SEC_V" (
   "USER_ID"
  ,"WHSE_CODE"
  ,"WHSE_NAME"
  ) AS 
  SELECT
    INFO_SEC.USER_ID,              -- ���[�U�[ID
    INFO_SEC.WHSE_CODE,            -- �q�ɃR�[�h
    INFO_SEC.WHSE_NAME             -- �E�v
  FROM(
       SELECT
         FU.USER_ID,                  -- ���[�U�[ID
         IWM.WHSE_CODE,               -- �q�ɃR�[�h
         IWM.WHSE_NAME                -- �E�v
       FROM
         FND_USER FU,                    -- ���[�U�[�}�X�^
         PER_ALL_PEOPLE_F PAPF,          -- �]�ƈ������}�X�^
         MTL_ITEM_LOCATIONS MIL,         -- OPM�ۊǏꏊ�}�X�^
         HR_ALL_ORGANIZATION_UNITS HAOU, -- �݌ɑg�D�}�X�^
         IC_WHSE_MST IWM                 -- OPM�q�Ƀ}�X�^
       WHERE
         FU.EMPLOYEE_ID = PAPF.PERSON_ID
       AND TRUNC(SYSDATE) BETWEEN TRUNC(PAPF.EFFECTIVE_START_DATE)
                          AND TRUNC(PAPF.EFFECTIVE_END_DATE)
       AND PAPF.ATTRIBUTE4 = MIL.ATTRIBUTE13
       AND HAOU.ORGANIZATION_ID    =   MIL.ORGANIZATION_ID
       AND IWM.MTL_ORGANIZATION_ID =   HAOU.ORGANIZATION_ID
       AND HAOU.DATE_FROM          <=  TRUNC(SYSDATE)
       AND ( HAOU.DATE_TO IS NULL
         OR  HAOU.DATE_TO >= TRUNC(SYSDATE) )
       AND MIL.DISABLE_DATE        IS NULL
       UNION
       SELECT
         FU.USER_ID,                  -- ���[�U�[ID
         IWM.WHSE_CODE,               -- �q�ɃR�[�h
         IWM.WHSE_NAME                -- �E�v
       FROM
         FND_USER FU,                    -- ���[�U�[�}�X�^
         PER_ALL_PEOPLE_F PAPF,          -- �]�ƈ������}�X�^
         MTL_ITEM_LOCATIONS MIL,         -- OPM�ۊǏꏊ�}�X�^
         MTL_ITEM_LOCATIONS MIL2,        -- OPM�ۊǏꏊ�}�X�^
         HR_ALL_ORGANIZATION_UNITS HAOU, -- �݌ɑg�D�}�X�^
         IC_WHSE_MST IWM                 -- OPM�q�Ƀ}�X�^
       WHERE
         FU.EMPLOYEE_ID = PAPF.PERSON_ID
       AND TRUNC(SYSDATE) BETWEEN TRUNC(PAPF.EFFECTIVE_START_DATE)
                          AND TRUNC(PAPF.EFFECTIVE_END_DATE)
       AND PAPF.ATTRIBUTE4 = MIL.ATTRIBUTE13
       AND MIL.SEGMENT1  = MIL2.ATTRIBUTE8
       AND HAOU.ORGANIZATION_ID    =  MIL2.ORGANIZATION_ID
       AND IWM.MTL_ORGANIZATION_ID =  HAOU.ORGANIZATION_ID
       AND HAOU.DATE_FROM          <= TRUNC(SYSDATE)
       AND ( HAOU.DATE_TO IS NULL
         OR  HAOU.DATE_TO >= TRUNC(SYSDATE) )
       AND MIL.DISABLE_DATE  IS NULL
       AND MIL2.DISABLE_DATE IS NULL
       ) INFO_SEC
  GROUP BY INFO_SEC.USER_ID,
           INFO_SEC.WHSE_CODE,
           INFO_SEC.WHSE_NAME
  ;
--
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.USER_ID  IS '���[�U�[ID';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_CODE  IS '�q�ɃR�[�h';
COMMENT ON COLUMN XXINV_STC_LOV_INFO_SEC_V.WHSE_NAME  IS '�q�ɖ�';
--
COMMENT ON TABLE  XXINV_STC_LOV_INFO_SEC_V IS '�݌�_�l�Z�b�g�pVIEW_���Z�L�����e�B' ;

/