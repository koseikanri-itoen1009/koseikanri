CREATE OR REPLACE PACKAGE xxcso_ipro_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IPRO_COMMON_PKG(SPEC)
 * Description      : 共通関数（XXCSOIPRO共通）
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  get_temp_info          F     V     テンプレート属性値取得関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   N.Yabuki         新規作成
 *
 *****************************************************************************************/
--
  -- テンプレート属性値取得関数
  FUNCTION get_temp_info(
    in_req_line_id     IN  NUMBER,   -- 発注依頼明細ID
    iv_attribs_name    IN  VARCHAR2  -- 属性名
  )
  RETURN VARCHAR2;
--
END xxcso_ipro_common_pkg;
/
