CREATE OR REPLACE PACKAGE APPS.XXCCP007A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCCP007A08C(spec)
 * Description      : oï¸Z­¶Rf[^oÍ
 * MD.070           : oï¸Z­¶Rf[^oÍ (MD070_IPO_CCP_007_A08)
 * Version          : 1.0
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
 *  2015/11/09     1.0  Y.Shoji         [E_{Ò®_13393]VKì¬
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   G[bZ[W #Åè#
   ,retcode               OUT    VARCHAR2      --   G[R[h     #Åè#
   ,iv_gl_date_from       IN     VARCHAR2      --    1.GLL ú FROM
   ,iv_gl_date_to         IN     VARCHAR2      --    2.GLL ú TO
   ,iv_department_code    IN     VARCHAR2      --    3.åR[h
   ,iv_segment3_code1     IN     VARCHAR2      --    4.oïÈÚR[hP
   ,iv_segment3_code2     IN     VARCHAR2      --    5.oïÈÚR[hQ
   ,iv_segment3_code3     IN     VARCHAR2      --    6.oïÈÚR[hR
   ,iv_segment3_code4     IN     VARCHAR2      --    7.oïÈÚR[hS
   ,iv_segment3_code5     IN     VARCHAR2      --    8.oïÈÚR[hT
   ,iv_segment3_code6     IN     VARCHAR2      --    9.oïÈÚR[hU
   ,iv_segment3_code7     IN     VARCHAR2      --   10.oïÈÚR[hV
   ,iv_segment3_code8     IN     VARCHAR2      --   11.oïÈÚR[hW
   ,iv_segment3_code9     IN     VARCHAR2      --   12.oïÈÚR[hX
   ,iv_segment3_code10    IN     VARCHAR2      --   13.oïÈÚR[hPO
  );
END XXCCP007A08C;
/