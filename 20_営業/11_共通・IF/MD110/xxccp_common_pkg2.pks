create or replace PACKAGE apps.xxccp_common_pkg2
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg2(spec)
 * Description            :
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.4
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  get_process_date          F    DATE   �Ɩ��������擾�֐�
 *  get_working_day           F    DATE   �c�Ɠ����t�擾�֐�
 *  chk_moji                  F    BOOL   �֑������`�F�b�N
 *  blob_to_varchar2          P           BLOB�f�[�^�ϊ�
 *  upload_item_check         P           ���ڃ`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-24    1.0  Naoki.Watanabe   �V�K�쐬
 *  2008-11-11    1.1  Yutaka.Kuboshima �֑������`�F�b�N,BLOB�f�[�^�ϊ�,���ڃ`�F�b�N�֐��ǉ�
 *  2009-01-30    1.2  Yutaka.Kuboshima �֑������`�F�b�N�̔��p�X�y�[�X,�A���_�[�o�[��
 *                                      �֑��������珜�O
 *  2009-03-23    1.3  Shinya.Kayahara  �ŏI�s�ɃX���b�V���ǉ�
 *  2009-05-01    1.4  Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *****************************************************************************************/
--
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
  --�c�Ɠ����t�擾�֐�
  FUNCTION get_working_day(
              id_date          IN DATE
             ,in_working_day   IN NUMBER
             ,iv_calendar_code IN VARCHAR2 DEFAULT NULL
           )
    RETURN DATE;


  --�Ɩ����t�擾�֐�
  FUNCTION get_process_date
    RETURN DATE;


  --�֑������`�F�b�N
  FUNCTION chk_moji(
    iv_check_char  IN VARCHAR2,
    iv_check_scope IN VARCHAR2)
    RETURN BOOLEAN;
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
    iv_item_nullflg   IN          VARCHAR2,       -- �K�{�t���O�i��L�萔��ݒ�j-- �K�{
    iv_item_attr      IN          VARCHAR2,       -- ���ڑ����i��L�萔��ݒ�j  -- �K�{
    ov_errbuf         OUT NOCOPY VARCHAR2,        -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode        OUT NOCOPY VARCHAR2,        -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg         OUT NOCOPY VARCHAR2);       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  --
END XXCCP_COMMON_PKG2;
/
