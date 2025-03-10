CREATE OR REPLACE PACKAGE xxpo940004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO940004C(spec)
 * Description      : düELEÚ®îño
 * MD.050           : ¶Y¨¬¤Ê                  T_MD050_BPO_940
 * MD.070           : düELEÚ®îño  T_MD070_BPO_94D
 * Version          : 1.5
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
 *  2008/06/10    1.0   Oracle Rª ê_ ñì¬
 *  2008/08/20    1.1   Oracle Rª ê_ T_S_593,T_TE080_BPO_940 wE6,wE7,wE8,wE9Î
 *  2008/09/02    1.2   Oracle Rª ê_ T_S_626,T_TE080_BPO_940 wE10Î
 *  2008/09/18    1.3   Oracle å´ FY T_S_460Î
 *  2008/11/26    1.4   Oracle gc Ä÷ {Ô#113Î
 *  2009/02/04    1.5   Oracle gc Ä÷ {Ô#15Î
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  --   G[EbZ[W  --# Åè #
    retcode                 OUT NOCOPY VARCHAR2,  --   ^[ER[h    --# Åè #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.æª          (K{)
    iv_wf_class          IN            VARCHAR2,  --  2.ÎÛ              (K{)
    iv_wf_notification   IN            VARCHAR2,  --  3.¶æ              (K{)
    iv_data_class        IN            VARCHAR2,  --  4.f[^íÊ        (K{)
    iv_ship_no_from      IN            VARCHAR2,  --  5.zNo.FROM       (CÓ)
    iv_ship_no_to        IN            VARCHAR2,  --  6.zNo.TO         (CÓ)
    iv_req_no_from       IN            VARCHAR2,  --  7.ËNo.FROM       (CÓ)
    iv_req_no_to         IN            VARCHAR2,  --  8.ËNo.TO         (CÓ)
    iv_vendor_code       IN            VARCHAR2,  --  9.æøæ            (CÓ)
    iv_mediation         IN            VARCHAR2,  -- 10.´ùÒ            (CÓ)
    iv_location_code     IN            VARCHAR2,  -- 11.oÉqÉ          (CÓ)
    iv_arvl_code         IN            VARCHAR2,  -- 12.üÉqÉ          (CÓ)
    iv_vendor_site_code  IN            VARCHAR2,  -- 13.zæ            (CÓ)
    iv_carrier_code      IN            VARCHAR2,  -- 14.^ÆÒ          (CÓ)
    iv_ship_date_from    IN            VARCHAR2,  -- 15.[üú/oÉúFROM (K{)
    iv_ship_date_to      IN            VARCHAR2,  -- 16.[üú/oÉúTO   (K{)
    iv_arrival_date_from IN            VARCHAR2,  -- 17.üÉúFROM        (CÓ)
    iv_arrival_date_to   IN            VARCHAR2,  -- 18.üÉúTO          (CÓ)
    iv_instruction_dept  IN            VARCHAR2,  -- 19.w¦          (CÓ)
    iv_item_no           IN            VARCHAR2,  -- 20.iÚ              (CÓ)
    iv_update_time_from  IN            VARCHAR2,  -- 21.XVúFROM      (CÓ)
    iv_update_time_to    IN            VARCHAR2,  -- 22.XVúTO        (CÓ)
    iv_prod_class        IN            VARCHAR2,  -- 23.¤iæª          (CÓ)
    iv_item_class        IN            VARCHAR2,  -- 24.iÚæª          (CÓ)
    iv_sec_class         IN            VARCHAR2   -- 25.ZLeBæª  (K{)
    );
END xxpo940004c;
/
