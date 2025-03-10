CREATE OR REPLACE PACKAGE xxpo940003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940003c(spec)
 * Description      : bgέΙξρo
 * MD.050           : ΆY¨¬€Κ                  T_MD050_BPO_940
 * MD.070           : bgέΙξρo        T_MD070_BPO_94C
 * Version          : 1.5
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
 *  2008/07/01    1.0   Oracle ε΄ FY ρμ¬
 *  2008/08/01    1.1   Oracle gc Δχ STsοΞ,PTΞ
 *  2008/08/04    1.2   Oracle gc Δχ PTΞ
 *  2008/08/19    1.3   Oracle Rͺ κ_ dlsυEwE15
 *  2008/09/17    1.4   Oracle ε΄ FY T_S_460Ξ
 *  2009/02/04    1.5   Oracle gc Δχ {Τ#15Ξ
 *****************************************************************************************/
--
  --RJgΐst@Co^vV[W
  PROCEDURE main(
    errbuf                  OUT NOCOPY VARCHAR2,  --   G[EbZ[W  --# Εθ #
    retcode                 OUT NOCOPY VARCHAR2,  --   ^[ER[h    --# Εθ #
    iv_wf_ope_div        IN            VARCHAR2,  --  1.ζͺ          (K{)
    iv_wf_class          IN            VARCHAR2,  --  2.ΞΫ              (K{)
    iv_wf_notification   IN            VARCHAR2,  --  3.Άζ              (K{)
    iv_prod_class        IN            VARCHAR2,  --  4.€iζͺ          (K{)
    iv_item_class        IN            VARCHAR2,  --  5.iΪζͺ          (K{)
    iv_frequent_whse_div IN            VARCHAR2,  --  6.γ\qΙζͺ      (CΣ)
    iv_whse              IN            VARCHAR2,  --  7.qΙ              (CΣ)
    iv_vendor_id         IN            VARCHAR2,  --  8.ζψζ            (CΣ)
    iv_item_no           IN            VARCHAR2,  --  9.iΪ              (CΣ)
    iv_lot_no            IN            VARCHAR2,  -- 10.bg            (CΣ)
    iv_Manufacture_date  IN            VARCHAR2,  -- 11.»’ϊ            (CΣ)
    iv_expiration_date   IN            VARCHAR2,  -- 12.ά‘ϊΐ          (CΣ)
    iv_uniqe_sign        IN            VARCHAR2,  -- 13.ΕLL          (CΣ)
    iv_mf_factory        IN            VARCHAR2,  -- 14.»’Hκ          (CΣ)
    iv_mf_lot            IN            VARCHAR2,  -- 15.»’bg        (CΣ)
    iv_home              IN            VARCHAR2,  -- 16.Yn              (CΣ)
    iv_r1                IN            VARCHAR2,  -- 17.R1                (CΣ)
    iv_r2                IN            VARCHAR2,  -- 18.R2                (CΣ)
    iv_sec_class         IN            VARCHAR2   -- 19.ZLeBζͺ  (K{)
    );
END xxpo940003c;
/
