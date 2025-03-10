CREATE OR REPLACE PACKAGE XXCOS_TASK_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS_TASK_PKG(spec)
 * Description      : ¤ÊÖpbP[W(Ì)
 * MD.070           : ¤ÊÖ    MD070_IPO_COS
 * Version          : 1.4
 *
 * Program List
 * --------------------------- ------ ---------- -----------------------------------------
 *  Name                        Type   Return     Description
 * --------------------------- ------ ---------- -----------------------------------------
 *  task_entry                  P                 KâELøÀÑo^
 *  
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------------
 *  2008/12/12    1.0   T.kitajima       VKì¬
 *  2009/02/18    1.1   T.kitajima       [COS_091]Á»VDÎ
 *  2009/05/18    1.2   T.kitajima       [T1_0652]üàîñÌo^³\[XÔK{ð
 *  2009/11/24    1.3   S.Miyakoshi      TASKf[^æ¾ÌútÌðÏX
 *  2017/12/18    1.4   S.Yamashita      [E_{Ò®_14486] HHT©çÌKâæªAgÇÁ
 *
 ****************************************************************************************/
--
  /************************************************************************
   * Procedure Name  : task_entry
   * Description     : KâELøÀÑo^
   ************************************************************************/
  PROCEDURE task_entry(
               ov_errbuf          OUT NOCOPY  VARCHAR2                --G[bZ[W
              ,ov_retcode         OUT NOCOPY  VARCHAR2                --^[R[h
              ,ov_errmsg          OUT NOCOPY  VARCHAR2                --[U[EG[EbZ[W
              ,in_resource_id     IN          NUMBER    DEFAULT NULL  --\[XID
              ,in_party_id        IN          NUMBER    DEFAULT NULL  --p[eBID
              ,iv_party_name      IN          VARCHAR2  DEFAULT NULL  --p[eB¼Ì
              ,id_visit_date      IN          DATE      DEFAULT NULL  --Kâú
              ,iv_description     IN          VARCHAR2  DEFAULT NULL  --Ú×àe
              ,in_sales_amount    IN          NUMBER    DEFAULT NULL  --ãàz(2008/12/12 ÇÁ)
              ,iv_input_division  IN          VARCHAR2  DEFAULT NULL  --üÍæª(2008/12/17 ÇÁ)
-- Ver.1.4 ADD Start
              ,iv_attribute1      IN          VARCHAR2  DEFAULT NULL  --ceePiKâæª1j
              ,iv_attribute2      IN          VARCHAR2  DEFAULT NULL  --ceeQiKâæª2j
              ,iv_attribute3      IN          VARCHAR2  DEFAULT NULL  --ceeRiKâæª3j
              ,iv_attribute4      IN          VARCHAR2  DEFAULT NULL  --ceeSiKâæª4j
              ,iv_attribute5      IN          VARCHAR2  DEFAULT NULL  --ceeTiKâæª5j
              ,iv_attribute6      IN          VARCHAR2  DEFAULT NULL  --ceeUiKâæª6j
              ,iv_attribute7      IN          VARCHAR2  DEFAULT NULL  --ceeViKâæª7j
              ,iv_attribute8      IN          VARCHAR2  DEFAULT NULL  --ceeWiKâæª8j
              ,iv_attribute9      IN          VARCHAR2  DEFAULT NULL  --ceeXiKâæª9j
              ,iv_attribute10     IN          VARCHAR2  DEFAULT NULL  --ceePOiKâæª10j
-- Ver.1.4 ADD End
              ,iv_entry_class     IN          VARCHAR2  DEFAULT NULL  --ceePQio^æªj
              ,iv_source_no       IN          VARCHAR2  DEFAULT NULL  --ceePRio^³\[XÔj
              ,iv_customer_status IN          VARCHAR2  DEFAULT NULL  --ceePSiÚqXe[^Xj
              );
  --
END XXCOS_TASK_PKG;
/
