CREATE OR REPLACE PACKAGE xxinv100003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV100003C(spec)
 * Description      : Μvζnρ\
 * MD.050/070       : ΜvζEψζvζ (T_MD050_BPO_100)
 *                    Μvζnρ\   (T_MD070_BPO_10C)
 * Version          : 1.8
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 RJgΐst@Co^vV[W
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/02/15   1.0   Tatsuya Kurata   VKμ¬
 *  2008/04/23   1.1   Masanobu Kimura  ΰΟXv#27
 *  2008/04/28   1.2   Sumie Nakamura   dό₯WPΏwb_(AhI)oπRκΞ
 *  2008/04/30   1.3   Yuko Kawano      ΰΟXv#62,76
 *  2008/05/28   1.4   Kazuo Kumamoto   Kρα½(varchargp)Ξ
 *  2008/07/02   1.5   Satoshi Yunba    Φ₯ΆΞ
 *  2009/04/16   1.6   g³ ­χ        {ΤαQΞ(No.1410)
 *  2009/05/29   1.7   g³ ­χ        {ΤαQΞ(No.1509)
 *  2009/10/05   1.8   g³ ­χ        {ΤαQΞ(No.1648)
 *****************************************************************************************/
--
--#######################  ΕθO[oΟιΎ START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  Εθ END   ###############################
--
  --RJgΐst@Co^vV[W
  PROCEDURE main
    (
      errbuf           OUT    VARCHAR2      --   G[bZ[W
     ,retcode          OUT    VARCHAR2      --   G[R[h
     ,iv_year          IN     VARCHAR2      --   01.Nx
     ,iv_prod_div      IN     VARCHAR2      --   02.€iζͺ
     ,iv_gen           IN     VARCHAR2      --   03.’γ
     ,iv_output_unit   IN     VARCHAR2      --   04.oΝPΚ
     ,iv_output_type   IN     VARCHAR2      --   05.oΝνΚ
     ,iv_base_01       IN     VARCHAR2      --   06._P
     ,iv_base_02       IN     VARCHAR2      --   07._Q
     ,iv_base_03       IN     VARCHAR2      --   08._R
     ,iv_base_04       IN     VARCHAR2      --   09._S
     ,iv_base_05       IN     VARCHAR2      --   10._T
     ,iv_base_06       IN     VARCHAR2      --   11._U
     ,iv_base_07       IN     VARCHAR2      --   12._V
     ,iv_base_08       IN     VARCHAR2      --   13._W
     ,iv_base_09       IN     VARCHAR2      --   14._X
     ,iv_base_10       IN     VARCHAR2      --   15._PO
     ,iv_crowd_code_01 IN     VARCHAR2      --   16.QR[hP
     ,iv_crowd_code_02 IN     VARCHAR2      --   17.QR[hQ
     ,iv_crowd_code_03 IN     VARCHAR2      --   18.QR[hR
     ,iv_crowd_code_04 IN     VARCHAR2      --   19.QR[hS
     ,iv_crowd_code_05 IN     VARCHAR2      --   20.QR[hT
     ,iv_crowd_code_06 IN     VARCHAR2      --   21.QR[hU
     ,iv_crowd_code_07 IN     VARCHAR2      --   22.QR[hV
     ,iv_crowd_code_08 IN     VARCHAR2      --   23.QR[hW
     ,iv_crowd_code_09 IN     VARCHAR2      --   24.QR[hX
     ,iv_crowd_code_10 IN     VARCHAR2      --   25.QR[hPO
    );
END xxinv100003c;
/
