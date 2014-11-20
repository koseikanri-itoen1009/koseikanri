CREATE OR REPLACE PACKAGE xxwsh_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common2_pkg(SPEC)
 * Description            : ���ʊ֐�(OAF�p)(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  copy_order_data         F    NUM  �󒍏��R�s�[����
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/04/08   1.0   H.Itou           �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
   -- �󒍏��R�s�[����
  FUNCTION copy_order_data(
    it_header_id     IN  xxwsh_order_lines_all.order_header_id%TYPE)   -- �󒍃w�b�_�A�h�I��ID
  RETURN NUMBER; -- �󒍃w�b�_�A�h�I��ID
END xxwsh_common2_pkg;
/
