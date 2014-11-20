CREATE OR REPLACE PACKAGE apps.xxccp_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name           : xxccp_common_pkg(spec)
 * Description            : 
 * MD.070                 : MD070_IPO_CCP_���ʊ֐�
 * Version                : 1.2
 *
 * Program List
 *  --------------------          ---- ----- --------------------------------------------------
 *   Name                         Type  Ret   Description
 *  --------------------          ---- ----- --------------------------------------------------
 *  set_status_normal               F    VAR    ����X�e�[�^�X�E�Z�b�g�֐�
 *  set_status_error                F    VAR    �G���[�X�e�[�^�X�E�Z�b�g�֐�
 *  set_status_warn                 F    VAR    �x���X�e�[�^�X�E�Z�b�g�֐�
 *  chk_double_byte                 F    BOOL   �S�p�`�F�b�N
 *  char_byte_partition             F    VAR    �o�C�g�����֐�
 *  get_application                 F    NUM    �A�v���P�[�V����ID�擾�֐�
 *  chk_alphabet_kana               F    BOOL   ���p�p�啶���^���p�J�i�啶���`�F�b�N
 *  chk_alphabet_number_only        F    BOOL   ���p�p�����`�F�b�N �t�@���N�V����(�L���s��)
 *  chk_number                      F    BOOL   ���p�����`�F�b�N
 *  put_log_header                  P           �R���J�����g�w�b�_���b�Z�[�W�o�͊֐�
 *  chk_alphabet_number             F    BOOL   ���p�p�����`�F�b�N
 *  chk_tel_format                  F    BOOL   ���p��������уn�C�t���`�F�b�N
 *  chg_double_to_single_byte       F    BOOL   �S�p�J�^�J�i�p�������p�ϊ�
 *  chg_double_to_single_byte_sub   F    VAR    �S�p�J�^�J�i�p�������p�ϊ�(�T�u)
 *  chk_double_byte_kana            F    BOOL   �S�p�J�^�J�i�`�F�b�N
 *  chk_single_byte_kana            F    BOOL   ���p�J�^�J�i�`�F�b�N
 *  get_msg                         F    VAR    ���b�Z�[�W�擾
 *  chk_single_byte_kana            F    BOOL   ���p�J�^�J�i�`�F�b�N
 *  char_delim_partition            F    VAR    �f���~�^���������֐�
 *  chk_single_byte                 F    BOOL   ���p������`�F�b�N
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008-10-01    1.0  Naoki.Watanabe   �V�K�쐬
 *  2009-05-01    1.1  Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *  2009-06-15    1.2  Masayuki.Sano    [T1_1440]�s�v�R�����g���폜
 *****************************************************************************************/
--
  --����X�e�[�^�X�E�Z�b�g�֐�
  FUNCTION set_status_normal
    RETURN VARCHAR2;
  --
  --�G���[�X�e�[�^�X�E�Z�b�g�֐�
  FUNCTION set_status_error
    RETURN VARCHAR2;
  --
  --�x���X�e�[�^�X�E�Z�b�g�֐�
  FUNCTION set_status_warn
    RETURN VARCHAR2;
  --
  --�S�p�`�F�b�N
  FUNCTION chk_double_byte(
                           iv_chk_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                          )
    RETURN BOOLEAN;
  --
  --�o�C�g�����֐�
  FUNCTION char_byte_partition(iv_char      IN VARCHAR2 --����������
                              ,iv_part_byte IN VARCHAR2 --����byte��
                              ,in_part_num  IN NUMBER   --�ԋp�Ώ�INDEX
                              )
    RETURN VARCHAR2;
  --
  --�A�v���P�[�V����ID�擾�֐�
  FUNCTION get_application(
                           iv_application_name IN VARCHAR2 --�A�v���P�[�V�����Z�k��
                          )
    RETURN NUMBER;
  --
  --���p�p�啶���^���p�J�i�啶���`�F�b�N
  FUNCTION chk_alphabet_kana(
                             iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                            ) 
    RETURN BOOLEAN;
  --
  --���p�p�����`�F�b�N �t�@���N�V����(�L���s��)
  FUNCTION chk_alphabet_number_only(
                                    iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                                   )
    RETURN BOOLEAN;
  --
  --���p�����`�F�b�N
  FUNCTION chk_number(
                      iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
                     )
    RETURN BOOLEAN;
  --
  --�R���J�����g�w�b�_���b�Z�[�W�o�͊֐�
  PROCEDURE put_log_header(
               iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT' --�o�͋敪
              ,ov_retcode  OUT VARCHAR2 --���^�[���R�[�h
              ,ov_errbuf   OUT VARCHAR2 --�G���[���b�Z�[�W
              ,ov_errmsg   OUT VARCHAR2 --���[�U�[�E�G���[���b�Z�[�W
              );
  --
  --���p�p�����`�F�b�N
  FUNCTION chk_alphabet_number(
              iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
           )
    RETURN BOOLEAN;
  --
  --���p��������уn�C�t���`�F�b�N
  FUNCTION chk_tel_format(
              iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
           )
    RETURN BOOLEAN;
  --
  --�S�p�J�^�J�i�p�������p�ϊ�
  FUNCTION chg_double_to_single_byte(
              iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
           )
    RETURN VARCHAR2;
  --
  --�S�p�J�^�J�i�p�������p�ϊ��i�T�u�j
  FUNCTION chg_double_to_single_byte_sub(
              iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
           )
    RETURN VARCHAR2;
  --
  --�S�p�J�^�J�i�`�F�b�N
  FUNCTION chk_double_byte_kana(
              iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
           )
    RETURN BOOLEAN;
  --
  --���p�J�^�J�i�`�F�b�N
  FUNCTION chk_single_byte_kana(
              iv_check_char IN VARCHAR2 --�`�F�b�N�Ώە�����
           )
    RETURN BOOLEAN;
  --
  --���b�Z�[�W�擾
  FUNCTION get_msg(
                   iv_application    IN VARCHAR2 --�A�v���P�[�V�����Z�k��
                  ,iv_name           IN VARCHAR2 --���b�Z�[�W�R�[�h
                  ,iv_token_name1    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h1
                  ,iv_token_value1   IN VARCHAR2 DEFAULT NULL --�g�[�N���l1
                  ,iv_token_name2    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h2
                  ,iv_token_value2   IN VARCHAR2 DEFAULT NULL --�g�[�N���l2
                  ,iv_token_name3    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h3
                  ,iv_token_value3   IN VARCHAR2 DEFAULT NULL --�g�[�N���l4
                  ,iv_token_name4    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h4
                  ,iv_token_value4   IN VARCHAR2 DEFAULT NULL --�g�[�N���l4
                  ,iv_token_name5    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h5
                  ,iv_token_value5   IN VARCHAR2 DEFAULT NULL --�g�[�N���l5
                  ,iv_token_name6    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h6
                  ,iv_token_value6   IN VARCHAR2 DEFAULT NULL --�g�[�N���l6
                  ,iv_token_name7    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h7
                  ,iv_token_value7   IN VARCHAR2 DEFAULT NULL --�g�[�N���l7
                  ,iv_token_name8    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h8
                  ,iv_token_value8   IN VARCHAR2 DEFAULT NULL --�g�[�N���l8
                  ,iv_token_name9    IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h9
                  ,iv_token_value9   IN VARCHAR2 DEFAULT NULL --�g�[�N���l9
                  ,iv_token_name10   IN VARCHAR2 DEFAULT NULL --�g�[�N���R�[�h10
                  ,iv_token_value10  IN VARCHAR2 DEFAULT NULL --�g�[�N���l10
                 )
    RETURN VARCHAR2;
  --
  --�f���~�^���������֐�
  FUNCTION char_delim_partition(iv_char     IN VARCHAR2
                               ,iv_delim    IN VARCHAR2
                               ,in_part_num IN NUMBER
                               )
    RETURN VARCHAR2;
  --
--
  -- ���p�`�F�b�N
  FUNCTION chk_single_byte(
    iv_chk_char IN VARCHAR2             --�`�F�b�N�Ώە�����
  )
  RETURN BOOLEAN;
--
END XXCCP_COMMON_PKG;
/
