CREATE OR REPLACE PACKAGE XXCFF_COMMON2_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON2_PKG(spec)
 * Description      : FA���[�X���ʏ���
 * MD.050           : �Ȃ�
 * Version          : 1.2
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  payment_match_chk      �x���ƍ��σ`�F�b�N
 *  get_lease_key          ���[�X�L�[�̎擾
 *  get_object_info        �����R�[�h���[�X�敪�A���[�X��ʃ`�F�b�N
 *  chk_object_term        �����R�[�h���`�F�b�N
 *  get_lease_class_info   ���[�X���DFF���擾
 *  <program name>         <����> (�����ԍ�)
 *  �쐬���ɋL�q���Ă�������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0    SCS���          �V�K�쐬
 *  2008/12/05    1.1    SCS���c          �ǉ��F�����R�[�h���`�F�b�N
 *  2018/03/27    1.2    SCSK���         �ǉ��F���[�X���DFF���擾
 *
 *****************************************************************************************/
--
  --�x���ƍ��σ`�F�b�N
 PROCEDURE payment_match_chk(
    in_line_id    IN  NUMBER,          -- 1.�_�����ID
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  );
  --���[�X�L�[�̎擾
  PROCEDURE get_lease_key(
    iv_objectcode IN  VARCHAR2,        --   1.�����R�[�h(�K�{)
    on_object_id  OUT NUMBER,          --   2.���������h�c
    on_contact_id OUT NUMBER,          --   3.�_������h�c
    on_line_id    OUT NUMBER,          --   4.�_�񖾍ד����h�c
    ov_errbuf     OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  );
  --�����R�[�h���[�X�敪�A���[�X��ʃ`�F�b�N
  PROCEDURE get_object_info(
    in_object_id   IN  NUMBER,          --   1.�����R�[�h(�K�{)
    iv_lease_type  IN  VARCHAR2,        --   2.���[�X�敪(�K�{)
    iv_lease_class IN  VARCHAR2,        --   3.���[�X���(�K�{)
    in_re_lease_times IN  NUMBER,       --   4.�ă��[�X�񐔁i�K�{�j
    ov_errbuf      OUT NOCOPY VARCHAR2, --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2, --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2  --   ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
  );
  --�����R�[�h���`�F�b�N
  PROCEDURE chk_object_term(
    in_object_header_id  IN  NUMBER,               --   1.��������ID(�K�{)
    iv_term_appl_chk_flg IN  VARCHAR2 DEFAULT 'N', --   2.���\���`�F�b�N�t���O(�f�t�H���g�l�F'N')
    ov_errbuf            OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode           OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg            OUT NOCOPY VARCHAR2       --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
  -- ���[�X���DFF���擾
  PROCEDURE get_lease_class_info(
    iv_lease_class  IN VARCHAR2,          -- 1.���[�X���
    ov_ret_dff4     OUT VARCHAR2,         -- DFF4�̃f�[�^�i�[�p
    ov_ret_dff5     OUT VARCHAR2,         -- DFF5�̃f�[�^�i�[�p
    ov_ret_dff6     OUT VARCHAR2,         -- DFF6�̃f�[�^�i�[�p
    ov_ret_dff7     OUT VARCHAR2,         -- DFF7�̃f�[�^�i�[�p
    ov_errbuf       OUT NOCOPY VARCHAR2,  --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode      OUT NOCOPY VARCHAR2,  --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg       OUT NOCOPY VARCHAR2   --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
END XXCFF_COMMON2_PKG;
/
