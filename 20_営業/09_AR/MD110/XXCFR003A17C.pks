CREATE OR REPLACE PACKAGE XXCFR003A17C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A17C(spec)
 * Description      : CZg[¿f[^ì¬
 * MD.050           : MD050_CFR_003_A17_CZg[¿f[^ì¬
 * MD.070           : MD050_CFR_003_A17_CZg[¿f[^ì¬
 * Version          : 1.2
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
 *  2009-02-23    1.00  SCS » K¢     VKì¬
 *  2009-09-29    1.10  SCS Àì q     ¤ÊÛèuIE535vÎ
 *  2024-03-06    1.2   SCSK åR mî    E_{Ò®_19496 O[vïÐÎ
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                 OUT     VARCHAR2,         -- G[bZ[W #Åè#
    retcode                OUT     VARCHAR2,         -- G[R[h     #Åè#
    iv_target_date         IN      VARCHAR2,         -- ÷ú
-- Modify 2009-09-29 Ver1.10 Start
    iv_customer_code10     IN      VARCHAR2,         -- Úq
    iv_customer_code20     IN      VARCHAR2,         -- ¿pÚq
    iv_customer_code21     IN      VARCHAR2,         -- ¿pÚq
    iv_customer_code14     IN      VARCHAR2          -- |ÇæÚq
-- Modify 2009-09-29 Ver1.10 End
-- Ver1.2 ADD START
   ,iv_company_cd          IN      VARCHAR2          -- ïÐR[h
-- Ver1.2 ADD END
  );
END XXCFR003A17C;
/
