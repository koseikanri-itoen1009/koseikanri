CREATE OR REPLACE PACKAGE XXCFR003A14C
AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A14C
 * Description     : Äp¿N®
 * MD.050          : MD050_CFR_003_A14_Äp¿N®
 * MD.070          : MD050_CFR_003_A14_Äp¿N®
 * Version         : 1.1
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         RJgÀst@Co^vV[W
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2009-10-14    1.0  SCS Àì q ñì¬
 *  2009-09-18    1.1  SCS ´ LÆ ARdlÏXIE535Î
 ************************************************************************/

--===============================================================
-- RJgÀst@Co^vV[W
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ÷ú
-- Modify 2009.10.14 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2,    -- |R[hP(¿)
    iv_cust_code     IN  VARCHAR2,    -- ÚqR[h
-- Modify 2009.10.14 Ver1.1 End    
    iv_exec_003A06C  IN  VARCHAR2,    -- ÄpXÊ¿
    iv_exec_003A07C  IN  VARCHAR2,    -- Äp`[Ê¿
    iv_exec_003A08C  IN  VARCHAR2,    -- Äp¤iiS¾×j
    iv_exec_003A09C  IN  VARCHAR2,    -- Äp¤iiPiWvj
    iv_exec_003A10C  IN  VARCHAR2,    -- Äp¤iiXPiWvj
    iv_exec_003A11C  IN  VARCHAR2,    -- Äp¤iiP¿Wvj
    iv_exec_003A12C  IN  VARCHAR2,    -- Äp¤iiXP¿Wvj
    iv_exec_003A13C  IN  VARCHAR2     -- ÄpiXRWvj
  );
END  XXCFR003A14C;
/
