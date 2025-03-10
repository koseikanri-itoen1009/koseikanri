CREATE OR REPLACE PACKAGE xxwsh930004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh930004C(spec)
 * Description      : üoÉîñ·ÙXgiüÉîj
 * MD.050/070       : ¶Y¨¬¤Êio×EÚ®C^tF[XjIssue1.0(T_MD050_BPO_930)
 *                    ¶Y¨¬¤Êio×EÚ®C^tF[XjIssue1.0(T_MD070_BPO_93D)
 * Version          : 1.18
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
 *  2008/02/19    1.0   OracleäàV¼ç   VKì¬
 *  2008/06/23    1.1   Oracleå´FY   sïOÎ
 *  2008/06/25    1.2   Oracleå´FY   sïOÎ
 *  2008/06/30    1.3   Oracleå´FY   sïOÎ
 *  2008/07/08    1.4   Oracle|êNm   Ö¥¶Î
 *  2008/07/09    1.5   OracleÅ¼º\   ÏXvÎ#92
 *  2008/07/28    1.6   OracleÅ¼º\   STsï#197AàÛè#32AàÏXv#180Î
 *  2008/10/09    1.7   Oraclec¼÷   eXgáQ#338Î
 *  2008/10/17    1.8   Oraclec¼÷   ÛèT_S_458Î(ðCÓüÍp[^ÉÏXBPACKAGEÌC³ÍÈµ)
 *  2008/10/17    1.8   Oraclec¼÷   ÏXv#210Î
 *  2008/10/20    1.9   Oraclec¼÷   ÛèT_S_486Î
 *  2008/10/20    1.9   Oraclec¼÷   eXgáQ#394(1)Î
 *  2008/10/20    1.9   Oraclec¼÷   eXgáQ#394(2)Î
 *  2008/10/31    1.10  Oraclec¼÷   wE#462Î
 *  2008/11/17    1.11  Oraclec¼÷   wE#651Î(ÛèT_S_486ÄÎ)
 *  2008/12/17    1.12  Oraclec¼÷   {ÔáQ#764Î
 *  2008/12/25    1.13  Oraclec¼÷   {ÔáQ#831Î
 *  2009/01/06    1.14  OraclegcÄ÷   {ÔáQ#929Î
 *  2009/01/20    1.15  OracleR{±v   {ÔáQ#806,#814,#975Î
 *  2009/01/28    1.16  OracleR{±v   {ÔáQ#1044Î
 *  2009/03/31    1.17  OracleÅ¼º\   {ÔáQ#1290Î
 *  2009/10/02    1.18  SCS É¡ÐÆÝ   {ÔáQ#1286Î
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
     ,iv_item_div           IN     VARCHAR2         -- 02 : iÚæª
     ,iv_date_from          IN     VARCHAR2         -- 03 : oÉúFrom
     ,iv_date_to            IN     VARCHAR2         -- 04 : oÉúTo
     ,iv_dept_code          IN     VARCHAR2         -- 05 : 
     ,iv_output_type        IN     VARCHAR2         -- 06 : oÍæª
     ,iv_block_01           IN     VARCHAR2         -- 07 : ubNP
     ,iv_block_02           IN     VARCHAR2         -- 08 : ubNQ
     ,iv_block_03           IN     VARCHAR2         -- 09 : ubNR
     ,iv_ship_to_locat_code IN     VARCHAR2         -- 10 : oÉ³
     ,iv_online_type        IN     VARCHAR2         -- 11 : ICÎÛæª
     ,iv_request_no         IN     VARCHAR2         -- 12 : ËNo^Ú®No
-- 2009/03/31 v1.17 ADD START
     ,iv_mov_type           IN     VARCHAR2         -- 13 : Ú®^Cv
-- 2009/03/31 v1.17 ADD END
    ) ;
--
END xxwsh930004c ;
/
