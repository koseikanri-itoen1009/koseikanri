
  CREATE OR REPLACE VIEW XX03_TRANSACTION_TYPES_LOV_V ("CUST_TRX_TYPE_ID", "NAME", "STATUS", "LOOKUP_CODE","ATTRIBUTE5"
-- Ver1.2 ADD START
    ,"DRAFTING_COMPANY"
-- Ver1.2 ADD END
  ) AS 
/*************************************************************************
 * 
 * View Name       : XX03_TRANSACTION_TYPES_LOV_V
 * Description     : ����^�C�v�r���[�r���[ALL
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.2
 * 
 * Change Record
 * ------------- ----- -------------  -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------  -------------------------------------
 *  2010/01/15    1.1  SCS ���� �q��   ��Q�uE_�{�ғ�_01066�v�Ή�
 *  2023/10/31    1.2  SCSK ��R�m��   ��Q�uE_�{�ғ�_19496�v�Ή�
 ************************************************************************/
  SELECT RCT.CUST_TRX_TYPE_ID
      ,RCT.NAME
      ,RCT.STATUS
      ,FVL.LOOKUP_CODE
      ,RCT.ATTRIBUTE5
-- Ver1.2 ADD START
      ,RCT.ATTRIBUTE13  -- �`�[�쐬���
-- Ver1.2 ADD END
FROM   RA_CUST_TRX_TYPES_ALL RCT,
       FND_LOOKUP_VALUES FVL
WHERE RCT.SET_OF_BOOKS_ID = XX00_PROFILE_PKG.VALUE('GL_SET_OF_BKS_ID')
  AND RCT.ORG_ID = XX00_PROFILE_PKG.VALUE('ORG_ID')
  AND FVL.LOOKUP_TYPE = 'XX03_SLIP_TYPES'
  AND FVL.LANGUAGE = XX00_GLOBAL_PKG.CURRENT_LANGUAGE
  AND FVL.ATTRIBUTE15 = RCT.ORG_ID
  AND FVL.ATTRIBUTE12 = RCT.TYPE
;
 