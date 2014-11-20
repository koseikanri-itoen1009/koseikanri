CREATE OR REPLACE PACKAGE BODY xxcso_ipro_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IPRO_COMMON_PKG(BODY)
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
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_ipro_common_pkg';   -- パッケージ名
--
  /**********************************************************************************
   * Function Name    : get_temp_info
   * Description      : テンプレート属性値取得関数
   ***********************************************************************************/
  FUNCTION get_temp_info(
    in_req_line_id     IN  NUMBER,   -- 発注依頼明細ID
    iv_attribs_name    IN  VARCHAR2  -- 属性名
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100)  := 'get_temp_info';
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_attribute_value    VARCHAR2(240);
--
  BEGIN
--
    SELECT
        pti.attribute_value  attribute_value
    INTO
        lv_attribute_value
    FROM
        por_template_info          pti   -- 特別情報テーブル
      , por_template_attributes_v  ptav  -- テンプレート属性ビュー
    WHERE
        pti.requisition_line_id = in_req_line_id
    AND ptav.attribute_name     = iv_attribs_name
    AND ptav.node_display_flag  = 'Y'
    AND pti.attribute_code      = ptav.attribute_code
    ;
--
    RETURN lv_attribute_value;
--
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
--
--#################################  固定例外処理部 START   ####################################
--
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  固定部 END   ##########################################
  END get_temp_info;
--
END xxcso_ipro_common_pkg;
/
