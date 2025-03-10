CREATE OR REPLACE PACKAGE xxcmn560001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn560001c(spec)
 * Description      : g[TreB
 * MD.050           : g[TreB T_MD050_BPO_560
 * MD.070           : g[TreB T_MD070_BPO_56A
 * Version          : 1.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 RJgΐst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/08    1.0   ORACLE β²q‘  mainVKμ¬
 *  2008/05/27    1.1   Masayuki Ikeda   sοC³
 *  2008/07/02    1.2   ORACLE ΫΊι  zΒQΖh~Ιob`IDπΗΑ
 *  2008/07/03    1.3   ORACLE ΫΊι  zΒQΖh~πC³
 *  2008/08/18    1.4   ORACLE ΕΌΊ\  TE080wE#6Ξ
 *  2008/09/01    1.5   ORACLE ΕΌΊ\  TE080wE#7Ξ
 *                                       PTsοC³
 *  2008/09/03    1.6   ORACLE ΫΊι  PTsοC³ TYPEθ`πVIEWΜTYPEΙC³
 *  2008/09/10    1.7   ORACLE ΕΌΊ\  PT 6-1_26 Ξ
 *  2008/09/26    1.8   ORACLE ΕΌΊ\  PT 6-1_26 C³
 *  2008/10/16    1.9   ORACLE ΕΌΊ\  T_S_427,622Ξ
 *
 *****************************************************************************************/
--
  -- RJgΐst@Co^vV[W
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   G[bZ[W #Εθ#
    retcode         OUT    VARCHAR2,         --   G[R[h     #Εθ#
    iv_item_code    IN     VARCHAR2,         -- 1.iΪR[h
    iv_lot_no       IN     VARCHAR2,         -- 2.bgNo
    iv_out_control  IN     VARCHAR2          -- 3.oΝ§δ
  );
END xxcmn560001c;
/
