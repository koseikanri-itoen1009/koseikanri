CREATE OR REPLACE PACKAGE xxcso_ipro_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_IPRO_COMMON_PKG(SPEC)
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
  -- �e���v���[�g�����l�擾�֐�
  FUNCTION get_temp_info(
    in_req_line_id     IN  NUMBER,   -- �����˗�����ID
    iv_attribs_name    IN  VARCHAR2  -- ������
  )
  RETURN VARCHAR2;
--
END xxcso_ipro_common_pkg;
/
