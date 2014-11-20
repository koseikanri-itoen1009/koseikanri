CREATE OR REPLACE PACKAGE BODY xxcso_ipro_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IPRO_COMMON_PKG(BODY)
 * Description      : ���ʊ֐��iXXCSOIPRO���ʁj
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 * ----------------------  ----  ----  ------------------------------------------------------
 *  Name                   Type  Ret   Description
 * ----------------------  ----  ----  ------------------------------------------------------
 *  get_temp_info          F     V     �e���v���[�g�����l�擾�֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/09    1.0   N.Yabuki         �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name         CONSTANT VARCHAR2(100) := 'xxcso_ipro_common_pkg';   -- �p�b�P�[�W��
--
  /**********************************************************************************
   * Function Name    : get_temp_info
   * Description      : �e���v���[�g�����l�擾�֐�
   ***********************************************************************************/
  FUNCTION get_temp_info(
    in_req_line_id     IN  NUMBER,   -- �����˗�����ID
    iv_attribs_name    IN  VARCHAR2  -- ������
  )
  RETURN VARCHAR2
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name           CONSTANT VARCHAR2(100)  := 'get_temp_info';
    -- ===============================
    -- ���[�J���ϐ�
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
        por_template_info          pti   -- ���ʏ��e�[�u��
      , por_template_attributes_v  ptav  -- �e���v���[�g�����r���[
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
--#################################  �Œ��O������ START   ####################################
--
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      xxcso_common_pkg.raise_api_others_expt( gv_pkg_name, cv_prg_name );
--
--#####################################  �Œ蕔 END   ##########################################
  END get_temp_info;
--
END xxcso_ipro_common_pkg;
/
