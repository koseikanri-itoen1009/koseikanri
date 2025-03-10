create or replace PACKAGE XXCFR003A18C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A18C(spec)
 * Description      : W¿Å²(XÜÊàó)
 * MD.050           : MD050_CFR_003_A18_W¿Å(XÜÊàó)
 * MD.070           : MD050_CFR_003_A18_W¿Å(XÜÊàó)
 * Version          : 1.50
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
 *  2009/09/25    1.00 SCS Àì q  ñì¬
 *  2010/12/10    1.30 SCS În «a    áQuE_{Ò®_05401vÎ
 *  2013/12/02    1.40 SCSK ì Oç   áQuE_{Ò®_11330vÎ
 *  2014/03/27    1.50 SCSK Rº ãÄ¾   áQ [E_{Ò®_11617] Î
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- G[bZ[W #Åè#
    retcode                OUT     VARCHAR2,         -- G[R[h     #Åè#
    iv_target_date         IN      VARCHAR2,         -- ÷ú
    iv_customer_code10     IN      VARCHAR2,         -- Úq
    iv_customer_code20     IN      VARCHAR2,         -- ¿pÚq
    iv_customer_code21     IN      VARCHAR2,         -- ¿pÚq
    iv_customer_code14     IN      VARCHAR2          -- |ÇæÚq
-- Add 2010.12.10 Ver1.30 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- ¿­sTCN
-- Add 2010.12.10 Ver1.30 End
-- Add 2013.12.02 Ver1.40 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- ÅÊàóoÍæª
-- Add 2013.12.02 Ver1.40 End
-- Add 2014.03.27 Ver1.50 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- ¿oÍ`®
-- Add 2014.03.27 Ver1.50 End
  );
END XXCFR003A18C;
/
