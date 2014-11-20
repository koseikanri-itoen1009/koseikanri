CREATE OR REPLACE PACKAGE xxcso_auto_code_assign_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_AUTO_CODE_ASSIGN_PKG(SPEC)
 * Description      : ���ʊ֐�(XXCSO�̔ԁj
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  auto_code_assign          F    -     �����̔Ԋ֐�
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/21    1.0   T.maruyama       �V�K�쐬
 *
 *****************************************************************************************/
--
  -- �����̔Ԋ֐�
  FUNCTION auto_code_assign(
    iv_cl_assign             IN  VARCHAR2,               -- �̔Ԏ��
    iv_base_code             IN  VARCHAR2,               -- ���_�R�[�h
    id_base_date             IN  DATE                    -- �������t�iYYYMMDD�j
  ) RETURN VARCHAR2;
--
END XXCSO_AUTO_CODE_ASSIGN_PKG;
/
