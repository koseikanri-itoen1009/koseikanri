
  CREATE OR REPLACE VIEW XX03_TRANSACTION_TYPES_LOV_V ("CUST_TRX_TYPE_ID", "NAME", "STATUS", "LOOKUP_CODE","ATTRIBUTE5"
-- Ver1.2 ADD START
    ,"DRAFTING_COMPANY"
-- Ver1.2 ADD END
  ) AS 
/*************************************************************************
 * 
 * View Name       : XX03_TRANSACTION_TYPES_LOV_V
 * Description     : 取引タイプビュービューALL
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.2
 * 
 * Change Record
 * ------------- ----- -------------  -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- -------------  -------------------------------------
 *  2010/01/15    1.1  SCS 安川 智博   障害「E_本稼動_01066」対応
 *  2023/10/31    1.2  SCSK 大山洋介   障害「E_本稼動_19496」対応
 ************************************************************************/
  SELECT RCT.CUST_TRX_TYPE_ID
      ,RCT.NAME
      ,RCT.STATUS
      ,FVL.LOOKUP_CODE
      ,RCT.ATTRIBUTE5
-- Ver1.2 ADD START
      ,RCT.ATTRIBUTE13  -- 伝票作成会社
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
 