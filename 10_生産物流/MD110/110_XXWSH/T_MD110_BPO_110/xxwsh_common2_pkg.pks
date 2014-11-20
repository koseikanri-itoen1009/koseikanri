CREATE OR REPLACE PACKAGE xxwsh_common2_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common2_pkg(SPEC)
 * Description            : ���ʊ֐�(OAF�p)(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.4
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  copy_order_data         F    NUM  �󒍏��R�s�[����
 *  upd_order_req_status    P         �󒍃w�b�_�X�e�[�^�X�X�V������ǉ�
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/04/08   1.0   H.Itou           �V�K�쐬
 *  2008/12/06   1.1   T.Miyata         �R�s�[�쐬���A�o�׎��уC���^�t�F�[�X�σt���O��N(�Œ�)�Ƃ���B
 *  2008/12/16   1.2   D.Nihei          �ǉ��ΏہF���ьv��ϋ敪��ǉ��B
 *  2008/12/19   1.3   M.Hokkanji       �ړ����b�g�ڍו��ʎ��ɒ����O���ѐ��ʂ�ǉ�
 *  2009/02/09   1.4   M.Hokkanji       �󒍃w�b�_�X�e�[�^�X�X�V������ǉ�
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
-- Ver1.4 M.Hokkanji Start
  -- �󒍃w�b�_�X�e�[�^�X�X�V����
  PROCEDURE upd_order_req_status(
    in_order_header_id  IN  NUMBER   -- �w�b�_ID
   ,iv_req_status       IN  VARCHAR2 -- �X�V����X�e�[�^�X
   ,ov_ret_code         OUT VARCHAR2 -- ���^�[���R�[�h
   ,ov_errmsg           OUT VARCHAR2 -- �G���[���b�Z�[�W
  );
-- Ver1.4 M.Hokkanji End
END xxwsh_common2_pkg;
/
