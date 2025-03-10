CREATE OR REPLACE PACKAGE xxwsh400009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH400009C(spec)
 * Description      : o×ËmF\
 * MD.050           : o×Ë       T_MD050_BPO_401
 * MD.070           : o×ËmF\ T_MD070_BPO_40J
 * Version          : 1.12
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 RJgÀst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Masanobu Kimura  mainVKì¬
 *  2008/06/10    1.1   În  «a       wb_uoÍútvÌ®ðÏX
 *  2008/06/13    1.2   În  «a       STsïÎ
 *  2008/06/23    1.3   În  «a       STsïÎ#106
 *  2008/07/01    1.4   c  ¼÷       STsïÎ#331 ¤iæªÍüÍp[^©çæ¾
 *  2008/07/02    1.5   Satoshi Yunba    Ö¥¶u'vu"vu<vu>vuvÎ
 *  2008/07/03    1.6   Å¼  º\       STsïÎ#344¥357¥406Î
 *  2008/07/10    1.7   ã´  ³D       ÏXv#91Î zæªîñVIEWðOÉÏX
 *  2008/07/15    1.8   F{  aY       TE080wE#3Î(ó¾×AhI.ítOððÉÇÁ)
 *  2008/07/31    1.9   Yuko  Kawano     eXgsïÎ(dÊ/eÏÌZoWbNÏX)
 *  2008/10/20    1.10  Yuko  Kawano     Ûè32,48,62AwE294AT_S_627Î
 *  2008/11/14    1.11  å´  FY       wE567,599,605Î
 *  2008/12/11    1.12  R{  ±v       {ÔáQ#641Î
 *
 *****************************************************************************************/
--
--#######################  ÅèO[oÏé¾ START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  Åè END   ###############################
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                     OUT VARCHAR2,      --   G[bZ[W
    retcode                    OUT VARCHAR2,      --   G[R[h
    iv_head_sales_branch       IN  VARCHAR2,      --   1.Ç_
    iv_input_sales_branch      IN  VARCHAR2,      --   2.üÍ_
    iv_deliver_to              IN  VARCHAR2,      --   3.zæ
    iv_deliver_from            IN  VARCHAR2,      --   4.o×³
    iv_ship_date_from          IN  VARCHAR2,      --   5.oÉúFrom
    iv_ship_date_to            IN  VARCHAR2,      --   6.oÉúTo
    iv_arrival_date_from       IN  VARCHAR2,      --   7.úFrom
    iv_arrival_date_to         IN  VARCHAR2,      --   8.úTo
    iv_order_type_id           IN  VARCHAR2,      --   9.oÉ`Ô
    iv_request_no              IN  VARCHAR2,      --   10.ËNo.
    iv_req_status              IN  VARCHAR2,      --   11.o×ËXe[^X
    iv_confirm_request_class   IN  VARCHAR2,      --   12.¨¬SmFËæª
    iv_prod_class              IN  VARCHAR2       --   13.¤iæª
    );
--
END xxwsh400009c;
/
