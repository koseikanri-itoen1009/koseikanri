CREATE OR REPLACE PACKAGE xxcmn_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxcmn_common3_pkg(SPEC)
 * Description            : ���ʊ֐�(SPEC)
 * MD.070(CMD.050)        : T_MD050_BPO_000_���ʊ֐�3�i�⑫�����j.xls
 * Version                : 1.0
 *
 * Program List
 *  -------------------- ---- ----- --------------------------------------------------
 *   Name                Type  Ret   Description
 *  -------------------- ---- ----- --------------------------------------------------
 *  blob_to_varchar2       P         BLOB�ϊ�
 *  upload_item_check      P         ���ڃ`�F�b�N
 *  delete_fileup_proc     P         �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/01/29   1.0   ohba             �V�K�쐬
 *  2008/01/30   1.0   nomura           ���ڃ`�F�b�N�ǉ�
 *  2008/02/01   1.0   nomura           �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜�ǉ�
 *
 *****************************************************************************************/
--
  -- ===============================
  -- �O���[�o���^
  -- ===============================
--
  -- �ϊ���VARCHAR2�f�[�^���i�[����z��
  TYPE g_file_data_tbl IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;
--
  -- �K�{�t���O
  gv_null_ok  CONSTANT VARCHAR2(7)  := 'NULL_OK';    -- �C�Ӎ���
  gv_null_ng  CONSTANT VARCHAR2(7)  := 'NULL_NG';    -- �K�{����
  -- ���ڑ���
  gv_attr_vc2  CONSTANT VARCHAR2(1) := '0';   -- VARCHAR2�i�����`�F�b�N�Ȃ��j
  gv_attr_num  CONSTANT VARCHAR2(1) := '1';   -- NUMBER  �i���l�`�F�b�N�j
  gv_attr_dat  CONSTANT VARCHAR2(1) := '2';   -- DATE    �i���t�^�`�F�b�N�j
--
  -- ===============================
  -- �v���V�[�W������уt�@���N�V����
  -- ===============================
--
  -- BLOB�f�[�^�ϊ�
  PROCEDURE blob_to_varchar2(
    in_file_id   IN         NUMBER,          -- �t�@�C���h�c
    ov_file_data OUT NOCOPY g_file_data_tbl, -- �ϊ���VARCHAR2�f�[�^
    ov_errbuf    OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode   OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg    OUT NOCOPY VARCHAR2);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- ���ڃ`�F�b�N
  PROCEDURE upload_item_check(
    iv_item_name      IN          VARCHAR2,       -- ���ږ��́i���ڂ̓��{�ꖼ�j  -- �K�{
    iv_item_value     IN          VARCHAR2,       -- ���ڂ̒l                    -- �C��
    in_item_len       IN          NUMBER,         -- ���ڂ̒���                  -- �K�{
    in_item_decimal   IN          NUMBER,         -- ���ڂ̒����i�����_�ȉ��j    -- �����t�K�{
    in_item_nullflg   IN          VARCHAR2,       -- �K�{�t���O�i��L�萔��ݒ�j-- �K�{
    iv_item_attr      IN          VARCHAR2,       -- ���ڑ����i��L�萔��ݒ�j  -- �K�{
    ov_errbuf         OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
  -- �t�@�C���A�b�v���[�h�C���^�t�F�[�X�f�[�^�폜
  PROCEDURE delete_fileup_proc(
    iv_file_format IN         VARCHAR2,     --   �t�H�[�}�b�g�p�^�[��
    id_now_date    IN         DATE,         --   �Ώۓ��t
    in_purge_days  IN         NUMBER,       --   �p�[�W�Ώۊ���
    ov_errbuf      OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2);    --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
END xxcmn_common3_pkg;
/
