CREATE OR REPLACE PACKAGE XXCFR003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A16C(spec)
 * Description      : W¿Å
 * MD.050           : MD050_CFR_003_A16_W¿Å²
 * MD.070           : MD050_CFR_003_A16_W¿Å²
 * Version          : 1.10
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
 *  2008/12/11    1.00 SCS åì b      ñì¬
 *  2009/09/25    1.3  SCS A£ ^²l  [¤ÊÛèIE535] ¿âèÎ
 *  2010/12/10    1.7  SCS În «a    [E_{Ò®_05401] p[^u¿­sTCNvÌÇÁ
 *  2013/11/25    1.8  SCSK Ë¶ aK   [E_{Ò®_11330] ÅÊàóoÍÎ
 *  2014/03/27    1.9  SCSK Rº ãÄ¾   [E_{Ò®_11617] ¿oÍ`®ªÆÒÏõÌÚqÎ
 *  2023/11/20    1.10 SCSK åR mî   [E_{Ò®_19496] O[vïÐÎ
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- G[bZ[W #Åè#
    retcode                OUT     VARCHAR2,         -- G[R[h     #Åè#
    iv_target_date         IN      VARCHAR2,         -- ÷ú
-- Modify 2009.09.25 Ver1.3 Start
--    iv_ar_code1            IN      VARCHAR2          -- |R[hP(¿)
    iv_custome_cd          IN      VARCHAR2,         -- ÚqÔ(Úq)
    iv_invoice_cd          IN      VARCHAR2,         -- ÚqÔ(¿p)
    iv_payment_cd          IN      VARCHAR2          -- ÚqÔ(|Çæ)
-- Modify 2009.09.25 Ver1.3 End
-- Add 2010.12.10 Ver1.7 Start
   ,iv_bill_pub_cycle      IN      VARCHAR2          -- ¿­sTCN
-- Add 2010.12.10 Ver1.7 End
-- Add 2013.11.25 Ver1.8 Start
   ,iv_tax_output_type     IN      VARCHAR2          -- ÅÊàóoÍæª
-- Add 2013.11.25 Ver1.8 End
-- Add 2014.03.27 Ver1.9 Start
   ,iv_bill_invoice_type   IN      VARCHAR2          -- ¿oÍ`®
-- Add 2014.03.27 Ver1.9 End
-- Ver1.10 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- ïÐR[h
-- Ver1.10 ADD END
  );
END XXCFR003A16C;
/
