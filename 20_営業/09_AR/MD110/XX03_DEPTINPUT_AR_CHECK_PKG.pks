create or replace
PACKAGE      xx03_deptinput_ar_check_pkg
AS
/*****************************************************************************************
 *
 * Copyright(c)Oracle Corporation Japan, 2004-2005. All rights reserved.
 *
 * Package Name           : xx03_deptinput_ar_check_pkg(body)
 * Description            : �������(AR)�ɂ����ē��̓`�F�b�N���s�����ʊ֐�
 * MD.070                 : �������(AR)���ʊ֐� OCSJ/BFAFIN/MD070/F702
 * Version                : 11.5.10.1.6
 *
 * Program List
 *  -------------------------- ---- ----- --------------------------------------------------
 *   Name                      Type  Ret   Description
 *  -------------------------- ---- ----- --------------------------------------------------
 *  check_deptinput_ar          P          �������(AR)�̃G���[�i�d��j�`�F�b�N
 *  set_account_approval_flag   P          �d�_�Ǘ��`�F�b�N
 *  get_terms_date              P          �����\����̎Z�o
 *  del_receivable_data         P          �����˗��`�[���R�[�h�̍폜
 *
 * Change Record
 * ------------ ------------- ------------- -----------------------------------------------
 *  Date         Ver.          Editor        Description
 * ------------ ------------- ------------- -----------------------------------------------
 *  2005-01-20   1.0           T.Noro        �V�K�쐬
 *  2006-02-15   11.5.10.1.6   S.Morisawa    �_�u���N���b�N�Ή�,PKG��commit����PROCEDURE�ǉ�
 *
 *****************************************************************************************/
--
--�������(AR)�̃G���[�`�F�b�N
  PROCEDURE check_deptinput_ar(
    in_receivable_id IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
    on_error_cnt     OUT  NUMBER,    -- 2.�����S�̂ł̃G���[�t���O
    ov_error_flg     OUT  VARCHAR2,  -- 3.�����S�̂ł̃G���[�t���O
    ov_error_flg1    OUT  VARCHAR2,  -- 4.1�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg1    OUT  VARCHAR2,  -- 5.1�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg2    OUT  VARCHAR2,  -- 6.2�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg2    OUT  VARCHAR2,  -- 7.2�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg3    OUT  VARCHAR2,  -- 8.3�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg3    OUT  VARCHAR2,  -- 9.3�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg4    OUT  VARCHAR2,  -- 10.4�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg4    OUT  VARCHAR2,  -- 11.4�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg5    OUT  VARCHAR2,  -- 12.5�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg5    OUT  VARCHAR2,  -- 13.5�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg6    OUT  VARCHAR2,  -- 14.6�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg6    OUT  VARCHAR2,  -- 15.6�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg7    OUT  VARCHAR2,  -- 16.7�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg7    OUT  VARCHAR2,  -- 17.7�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg8    OUT  VARCHAR2,  -- 18.8�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg8    OUT  VARCHAR2,  -- 19.8�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg9    OUT  VARCHAR2,  -- 20.9�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg9    OUT  VARCHAR2,  -- 21.9�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg10   OUT  VARCHAR2,  -- 22.10�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg10   OUT  VARCHAR2,  -- 23.10�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg11   OUT  VARCHAR2,  -- 24.11�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg11   OUT  VARCHAR2,  -- 25.11�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg12   OUT  VARCHAR2,  -- 26.12�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg12   OUT  VARCHAR2,  -- 27.12�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg13   OUT  VARCHAR2,  -- 28.13�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg13   OUT  VARCHAR2,  -- 29.13�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg14   OUT  VARCHAR2,  -- 30.14�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg14   OUT  VARCHAR2,  -- 31.14�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg15   OUT  VARCHAR2,  -- 32.15�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg15   OUT  VARCHAR2,  -- 33.15�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg16   OUT  VARCHAR2,  -- 34.16�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg16   OUT  VARCHAR2,  -- 35.16�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg17   OUT  VARCHAR2,  -- 36.17�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg17   OUT  VARCHAR2,  -- 37.17�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg18   OUT  VARCHAR2,  -- 38.18�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg18   OUT  VARCHAR2,  -- 39.18�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg19   OUT  VARCHAR2,  -- 40.19�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg19   OUT  VARCHAR2,  -- 41.19�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg20   OUT  VARCHAR2,  -- 42.20�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg20   OUT  VARCHAR2,  -- 43.20�ڂ�RETURN�f�[�^�̃G���[���e
    ov_errbuf        OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT  VARCHAR2); --   (�Œ�)���[�U�[�E�G���[�E���b�Z�[�W
--
--�d�_�Ǘ��`�F�b�N
  PROCEDURE set_account_approval_flag(
    in_receivable_id IN  NUMBER,     -- 1.�`�F�b�N�Ώې�����ID
    ov_app_upd       OUT VARCHAR2,   -- 2.�d�_�Ǘ��X�V���e
    ov_errbuf        OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2);  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--�����\����̎Z�o
  PROCEDURE get_terms_date(
    in_terms_id      IN  NUMBER,     -- 1.�x������
    id_start_date    IN  DATE,       -- 2.���������t
    od_terms_date    OUT DATE,       -- 3.�����\���
    ov_errbuf        OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2);  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
--�����˗��`�[���R�[�h�̍폜
  PROCEDURE del_receivable_data(
    in_receivable_id IN  NUMBER,     -- 1.�폜�Ώې����˗�ID
    ov_errbuf        OUT VARCHAR2,   --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT VARCHAR2,   --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT VARCHAR2);  --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
--
-- ver11.5.10.1.6 Add Start
--�������(AR)�̃G���[�`�F�b�N(��ʗp)
  PROCEDURE check_deptinput_ar_input(
    in_receivable_id IN   NUMBER,    -- 1.�`�F�b�N�Ώې�����ID
    on_error_cnt     OUT  NUMBER,    -- 2.�����S�̂ł̃G���[�t���O
    ov_error_flg     OUT  VARCHAR2,  -- 3.�����S�̂ł̃G���[�t���O
    ov_error_flg1    OUT  VARCHAR2,  -- 4.1�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg1    OUT  VARCHAR2,  -- 5.1�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg2    OUT  VARCHAR2,  -- 6.2�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg2    OUT  VARCHAR2,  -- 7.2�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg3    OUT  VARCHAR2,  -- 8.3�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg3    OUT  VARCHAR2,  -- 9.3�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg4    OUT  VARCHAR2,  -- 10.4�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg4    OUT  VARCHAR2,  -- 11.4�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg5    OUT  VARCHAR2,  -- 12.5�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg5    OUT  VARCHAR2,  -- 13.5�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg6    OUT  VARCHAR2,  -- 14.6�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg6    OUT  VARCHAR2,  -- 15.6�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg7    OUT  VARCHAR2,  -- 16.7�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg7    OUT  VARCHAR2,  -- 17.7�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg8    OUT  VARCHAR2,  -- 18.8�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg8    OUT  VARCHAR2,  -- 19.8�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg9    OUT  VARCHAR2,  -- 20.9�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg9    OUT  VARCHAR2,  -- 21.9�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg10   OUT  VARCHAR2,  -- 22.10�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg10   OUT  VARCHAR2,  -- 23.10�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg11   OUT  VARCHAR2,  -- 24.11�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg11   OUT  VARCHAR2,  -- 25.11�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg12   OUT  VARCHAR2,  -- 26.12�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg12   OUT  VARCHAR2,  -- 27.12�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg13   OUT  VARCHAR2,  -- 28.13�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg13   OUT  VARCHAR2,  -- 29.13�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg14   OUT  VARCHAR2,  -- 30.14�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg14   OUT  VARCHAR2,  -- 31.14�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg15   OUT  VARCHAR2,  -- 32.15�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg15   OUT  VARCHAR2,  -- 33.15�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg16   OUT  VARCHAR2,  -- 34.16�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg16   OUT  VARCHAR2,  -- 35.16�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg17   OUT  VARCHAR2,  -- 36.17�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg17   OUT  VARCHAR2,  -- 37.17�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg18   OUT  VARCHAR2,  -- 38.18�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg18   OUT  VARCHAR2,  -- 39.18�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg19   OUT  VARCHAR2,  -- 40.19�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg19   OUT  VARCHAR2,  -- 41.19�ڂ�RETURN�f�[�^�̃G���[���e
    ov_error_flg20   OUT  VARCHAR2,  -- 42.20�ڂ�RETURN�f�[�^�̃G���[�t���O
    ov_error_msg20   OUT  VARCHAR2,  -- 43.20�ڂ�RETURN�f�[�^�̃G���[���e
    ov_errbuf        OUT  VARCHAR2,  -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode       OUT  VARCHAR2,  -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg        OUT  VARCHAR2); --   (�Œ�)���[�U�[�E�G���[�E���b�Z�[�W
-- ver11.5.10.1.6 Add End
--
END xx03_deptinput_ar_check_pkg;
