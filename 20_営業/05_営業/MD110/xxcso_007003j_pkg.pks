CREATE OR REPLACE PACKAGE apps.xxcso_007003j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007003j_pkg(SPEC)
 * Description      : ���k���������
 * MD.050/070       : 
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  request_sales_approval    P    -     ���k��������͏��F�˗�
 *  get_quotation_price       F    N     ���l�擾
 *  get_baseline_base_code    F    V     ���F�Ҍ����x�[�X�g�D�擾
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/10    1.0   H.Ogawa          �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ���k��������͏��F�˗�
  PROCEDURE request_sales_approval(
    ov_errbuf       OUT VARCHAR2
   ,ov_retcode      OUT VARCHAR2
   ,ov_errmsg       OUT VARCHAR2
  );
--
  -- ���l�擾
  FUNCTION get_quotation_price(
    in_ref_quote_line_id       IN  NUMBER
  ) RETURN NUMBER;
--
  -- ���F�Ҍ����x�[�X�g�D�擾
  FUNCTION get_baseline_base_code
  RETURN VARCHAR2;
--
  FUNCTION get_baseline_base_code(
    iv_base_code               IN  VARCHAR2
  ) RETURN VARCHAR2;
--
END xxcso_007003j_pkg;
/
