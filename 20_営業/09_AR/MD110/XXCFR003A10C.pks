CREATE OR REPLACE PACKAGE XXCFR003A10C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A10C
 * Description     : Δp€iiXPiWvjΏf[^μ¬
 * MD.050          : MD050_CFR_003_A10_Δp€iiXPiWvjΏf[^μ¬
 * MD.070          : MD050_CFR_003_A10_Δp€iiXPiWvjΏf[^μ¬
 * Version         : 1.1
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         RJgΐst@Co^vV[W
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2008-12-02    1.0  SCS ΐμ q ρμ¬
 *  2009-10-07    1.1  SCS ΄ LΖ ARdlΟXIE535Ξ
 ************************************************************************/

--===============================================================
-- RJgΐst@Co^vV[W
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- χϊ
-- Modify 2009/10/07 Ver1.1 Start ----------------------------------------------
--    iv_ar_code1      IN  VARCHAR2     -- |R[hP(Ώ)
    iv_cust_code     IN  VARCHAR2,    -- ΪqR[h
    iv_cust_class    IN  VARCHAR2     -- Ϊqζͺ
-- Modify 2009/10/07 Ver1.1 End ----------------------------------------------
  );
END  XXCFR003A10C;
/
