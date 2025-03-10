CREATE OR REPLACE PACKAGE APPS.XXCOS014A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS014A09C (spec)
 * Description      : SÝXèóf[^ì¬ 
 * MD.050           : SÝXèóf[^ì¬ MD050_COS_014_A09
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
 *  2009/02/18    1.0   H.Noda           VKì¬
 *  2009/03/18    1.1   Y.Tsubomatsu     [áQCOS_156] p[^Ìg£( [R[h, [l®)
 *  2009/03/19    1.2   Y.Tsubomatsu     [áQCOS_158] p[^ÌÒW(SÝXR[h,SÝXXÜR[h,}Ô)
 *  2009/04/17    1.3   T.Kitajima       [T1_0375] G[bZ[WóÔC³(`[Ô¨óNo)
 *  2009/09/07    1.4   N.Maeda          [0000403] }ÔÌCÓ»Éº¢}ÔÌ[vÇÁ
 *  2009/11/05    1.5   N.Maeda          [E_T4_00123]ÐR[hZbgàeC³
 *
 *****************************************************************************************/
--
  --RJgÀst@Co^vV[W
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   G[bZ[W #Åè#
    retcode       OUT    VARCHAR2,         --   G[R[h     #Åè#
    iv_file_name                 IN     VARCHAR2,  --  1.t@C¼
    iv_chain_code                IN     VARCHAR2,  --  2.`F[XR[h
    iv_report_code               IN     VARCHAR2,  --  3. [R[h
    in_user_id                   IN     NUMBER,    --  4.[UID
    iv_dept_code                 IN     VARCHAR2,  --  5.SÝXR[h
    iv_dept_name                 IN     VARCHAR2,  --  6.SÝX¼
    iv_dept_store_code           IN     VARCHAR2,  --  7.SÝXXÜR[h
    iv_edaban                    IN     VARCHAR2,  --  8.}Ô
    iv_base_code                 IN     VARCHAR2,  --  9._R[h
    iv_base_name                 IN     VARCHAR2,  -- 10._¼
    iv_data_type_code            IN     VARCHAR2,  -- 11. [íÊR[h
    iv_ebs_business_series_code  IN     VARCHAR2,  -- 12.Æ±nñR[h
    iv_report_name               IN     VARCHAR2,  -- 13. [l®
    iv_shop_delivery_date_from   IN     VARCHAR2,  -- 14.XÜ[iú(FROMj
    iv_shop_delivery_date_to     IN     VARCHAR2,  -- 15.XÜ[iúiTOj
    iv_publish_div               IN     VARCHAR2,  -- 16.[i­sæª
    in_publish_flag_seq          IN     NUMBER     -- 17.[i­stOÔ
  );
END XXCOS014A09C;
/
