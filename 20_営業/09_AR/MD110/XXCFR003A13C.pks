CREATE OR REPLACE PACKAGE XXCFR003A13C AS
/*************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 * 
 * Package Name    : XXCFR003A13C
 * Description     : Äp¤iiXRWvj¿f[^ì¬
 * MD.050          : MD050_CFR_003_A13_Äp¤iiXRWvj¿f[^ì¬
 * MD.070          : MD050_CFR_003_A13_Äp¤iiXRWvj¿f[^ì¬
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
 *  2008-12-17    1.0  SCS à_ ºê ñì¬
 *  2009-10-05    1.1  SCS A£^²l ¤ÊÛèIE535Î
 ************************************************************************/

--===============================================================
-- RJgÀst@Co^vV[W
--===============================================================
  PROCEDURE main(
    errbuf           OUT VARCHAR2,
    retcode          OUT VARCHAR2,
    iv_target_date   IN  VARCHAR2,    -- ÷ú
-- Modify 2009.10.05 Ver1.1 Start
--    iv_ar_code1      IN  VARCHAR2     -- |R[hP(¿)
    iv_cust_code     IN  VARCHAR2,    -- ÚqR[h
    iv_cust_class    IN  VARCHAR2     -- Úqæª
-- Modify 2009.10.05 Ver1.1 End
  );
END  XXCFR003A13C;
/
