CREATE OR REPLACE PACKAGE XXCFF_COMMON1_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON1_PKG(spec)
 * Description      : ���[�X�EFA�̈拤�ʊ֐��P
 * MD.050           : �Ȃ�
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ---- ----- ----------------------------------------------
 *  Name                        Type  Ret   Description
 * ---------------------------- ---- ----- ----------------------------------------------
 *  init                         P    -     ��������
 *  put_log_param                P    -     �R���J�����g�p�����[�^�o�͏���
 *  chk_fa_location              P    -     ���Ə��}�X�^�`�F�b�N
 *  chk_fa_category              P    -     ���Y�J�e�S���`�F�b�N
 *  chk_life                     P    -     �ϗp�N���`�F�b�N
 *  �쐬���ɋL�q���Ă�������
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/17    1.0   SCS�R�݌���      �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  TYPE init_rtype IS RECORD (
     process_date              DATE         -- �Ɩ����t
    ,set_of_books_id           NUMBER(15)   -- ��v����ID
    ,currency_code             VARCHAR2(15) -- �@�\�ʉ�
    ,org_id                    NUMBER(15)   -- �c�ƒP��
    ,gl_application_short_name VARCHAR2(50) -- GL�A�v���P�[�V�����Z�k��
    ,chart_of_accounts_id      NUMBER(15)   -- �Ȗڑ̌n�ԍ�ID
    ,id_flex_code              VARCHAR2(4)  -- �L�[�t���b�N�X�R�[�h
   );
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
--
  -- ===============================
  -- ���[�U�[��`���ʊ֐�
  -- ===============================
  -- ��������
  PROCEDURE init(
    or_init_rec   OUT NOCOPY init_rtype,   --   �߂�l
    ov_errbuf     OUT NOCOPY VARCHAR2,     --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode    OUT NOCOPY VARCHAR2,     --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg     OUT NOCOPY VARCHAR2      --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �R���J�����g�p�����[�^�o�͏���
  PROCEDURE put_log_param(
    iv_which    IN  VARCHAR2 DEFAULT 'OUTPUT',  -- �o�͋敪
    ov_errbuf   OUT NOCOPY VARCHAR2,            --�G���[���b�Z�[�W
    ov_retcode  OUT NOCOPY VARCHAR2,            --���^�[���R�[�h
    ov_errmsg   OUT NOCOPY VARCHAR2             --���[�U�[�E�G���[���b�Z�[�W
  );
--
  -- ���Ə��}�X�^�`�F�b�N
  PROCEDURE chk_fa_location(
    iv_segment1    IN  VARCHAR2 DEFAULT NULL, -- �\���n
    iv_segment2    IN  VARCHAR2,              -- �Ǘ�����
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- ���Ə�
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- �ꏊ
    iv_segment5    IN  VARCHAR2,              -- �{�Ё^�H��
    on_location_id OUT NOCOPY NUMBER,         -- ���Ə�ID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- ���Y�J�e�S���`�F�b�N
  PROCEDURE chk_fa_category(
    iv_segment1    IN  VARCHAR2,              -- ���
    iv_segment2    IN  VARCHAR2 DEFAULT NULL, -- �\�����p
    iv_segment3    IN  VARCHAR2 DEFAULT NULL, -- ���Y����
    iv_segment4    IN  VARCHAR2 DEFAULT NULL, -- ���p�Ȗ�
    iv_segment5    IN  VARCHAR2,              -- �ϗp�N��
    iv_segment6    IN  VARCHAR2 DEFAULT NULL, -- ���p���@
    iv_segment7    IN  VARCHAR2,              -- ���[�X���
    on_category_id OUT NOCOPY NUMBER,         -- ���Y�J�e�S��ID
    ov_errbuf      OUT NOCOPY VARCHAR2,       -- �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,       -- ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );
--
  -- �ϗp�N���`�F�b�N
  PROCEDURE chk_life(
    iv_category    IN  VARCHAR2,           --   ���Y���
    iv_life        IN  VARCHAR2,           --   �ϗp�N��
    ov_errbuf      OUT NOCOPY VARCHAR2,    --   �G���[�E���b�Z�[�W           --# �Œ� #
    ov_retcode     OUT NOCOPY VARCHAR2,    --   ���^�[���E�R�[�h             --# �Œ� #
    ov_errmsg      OUT NOCOPY VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  );

END XXCFF_COMMON1_PKG;
/
