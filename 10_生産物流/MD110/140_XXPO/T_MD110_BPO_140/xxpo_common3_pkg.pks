create or replace PACKAGE xxpo_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name           : xxpo_common3_pkg(SPEC)
 * Description            : ���ʊ֐�(�d�����э쐬�����Ǘ�Tbl�A�N�Z�X����)(SPEC)
 * MD.070(CMD.050)        : �Ȃ�
 * Version                : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  check_result              F     V     �d�����я��`�F�b�N
 *  insert_result             F     V     �d�����я��o�^
 *  delete_result             P     -     �d�����я��폜
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2011/06/03   1.0   K.Kubo           �V�K�쐬
 *****************************************************************************************/
--
  -- �d�����я��`�F�b�N
  FUNCTION check_result(
    in_po_header_id       IN  NUMBER         -- �����w�b�_�h�c
  ) 
  RETURN VARCHAR2;
--
  -- �d�����я��o�^
  FUNCTION insert_result(
    in_po_header_id      IN  NUMBER         -- �����w�b�_�h�c
   ,iv_po_header_number  IN  VARCHAR2       -- �����ԍ�
   ,in_created_by        IN  NUMBER         -- �쐬��
   ,id_creation_date     IN  DATE           -- �쐬��
   ,in_last_updated_by   IN  NUMBER         -- �ŏI�X�V��
   ,id_last_update_date  IN  DATE           -- �ŏI�X�V��
   ,in_last_update_login IN  NUMBER         -- �ŏI�X�V���O�C��
  ) 
  RETURN VARCHAR2;
--
  -- �d�����я��폜
  PROCEDURE delete_result(
    in_po_header_id       IN  NUMBER             -- (IN)�����w�b�_�h�c
   ,ov_errbuf             OUT NOCOPY VARCHAR2    -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode            OUT NOCOPY VARCHAR2    -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg             OUT NOCOPY VARCHAR2    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
END xxpo_common3_pkg;
