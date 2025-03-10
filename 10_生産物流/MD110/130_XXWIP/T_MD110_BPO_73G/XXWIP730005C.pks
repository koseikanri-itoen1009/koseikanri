CREATE OR REPLACE PACKAGE xxwip730005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP730005C(spec)
 * Description      : ¿^À`FbNXg
 * MD.050/070       : ^ÀvZigUNVj  (T_MD050_BPO_734)
 *                    ¿^À`FbNXg        (T_MD070_BPO_73G)
 * Version          : 1.14
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
 *  2008/04/30    1.0   Masayuki Ikeda   VKì¬
 *  2008/05/23    1.1   Masayuki Ikeda   eXgáQÎ
 *  2008/07/02    1.2   Satoshi Yunba    Ö¥¶Î
 *  2008/07/15    1.3   Masayuki Nomura  STáQÎ#444
 *  2008/07/15    1.4   Masayuki Nomura  STáQÎ#444iLÎj
 *  2008/07/17    1.5   Satoshi Takemoto STáQÎ#456
 *  2008/07/24    1.6   Satoshi Takemoto STáQÎ#477
 *  2008/07/25    1.7   Masayuki Nomura  STáQÎ#456
 *  2008/07/28    1.8   Masayuki Nomura  ÏXveXgáQÎ
 *  2008/08/19    1.9   Takao Ohashi     T_TE080_BPO_730 wE10Î
 *  2008/10/15    1.10  Yasuhisa Yamamoto áQ#300,331
 *  2008/10/24    1.11  Masayuki Nomura  #439Î
 *  2008/12/15    1.12  ìº ³K        {Ô#40Î
 *  2009/01/29    1.13  ìº ³K        {Ô#431Î
 *  2009/07/01    1.14  ìº ³K        {Ô#1551Î
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
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- G[bZ[W
     ,retcode               OUT    VARCHAR2         -- G[R[h
     ,iv_prod_div           IN     VARCHAR2         -- 01 : ¤iæª
     ,iv_carrier_code_from  IN     VARCHAR2         -- 02 : ^ÆÒFrom
     ,iv_carrier_code_to    IN     VARCHAR2         -- 03 : ^ÆÒTo
     ,iv_whs_code_from      IN     VARCHAR2         -- 04 : oÉ³qÉFrom
     ,iv_whs_code_to        IN     VARCHAR2         -- 05 : oÉ³qÉTo
     ,iv_ship_date_from     IN     VARCHAR2         -- 06 : oÉúFrom
     ,iv_ship_date_to       IN     VARCHAR2         -- 07 : oÉúTo
     ,iv_arrival_date_from  IN     VARCHAR2         -- 08 : úFrom
     ,iv_arrival_date_to    IN     VARCHAR2         -- 09 : úTo
     ,iv_judge_date_from    IN     VARCHAR2         -- 10 : ÏúFrom
     ,iv_judge_date_to      IN     VARCHAR2         -- 11 : ÏúTo
     ,iv_report_date_from   IN     VARCHAR2         -- 12 : ñúFrom
     ,iv_report_date_to     IN     VARCHAR2         -- 13 : ñúTo
     ,iv_delivery_no_from   IN     VARCHAR2         -- 14 : zNoFrom
     ,iv_delivery_no_to     IN     VARCHAR2         -- 15 : zNoTo
     ,iv_request_no_from    IN     VARCHAR2         -- 16 : ËNoFrom
     ,iv_request_no_to      IN     VARCHAR2         -- 17 : ËNoTo
     ,iv_invoice_no_from    IN     VARCHAR2         -- 18 : èóNoFrom
     ,iv_invoice_no_to      IN     VARCHAR2         -- 19 : èóNoTo
     ,iv_order_type         IN     VARCHAR2         -- 20 : ó^Cv
     ,iv_wc_class           IN     VARCHAR2         -- 21 : dÊeÏæª
     ,iv_outside_contract   IN     VARCHAR2         -- 22 : _ñO
     ,iv_return_flag        IN     VARCHAR2         -- 23 : mèãÏX
     ,iv_output_flag        IN     VARCHAR2         -- 24 : ·Ù
    ) ;
--
END xxwip730005c ;
/
