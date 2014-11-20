CREATE OR REPLACE PACKAGE APPS.XXCSO013A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO013A02C(spec)
 * Description      : ���̋@�Ǘ��V�X�e������A�g���ꂽ���[�X�����Ɋ֘A�����Ƃ̏����A
 *                    ���[�X�A�h�I���ɔ��f���܂��B
 * MD.050           :  MD050_CSO_013_A02_CSI��FA�C���^�t�F�[�X�F�iOUT�j���[�X���Y���
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-02-02    1.0   Tomoko.Mori      �V�K�쐬
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf          OUT NOCOPY VARCHAR2    --   �G���[�E���b�Z�[�W  --# �Œ� #
    ,retcode         OUT NOCOPY VARCHAR2    --   ���^�[���E�R�[�h    --# �Œ� #
    ,iv_process_div  IN  VARCHAR2           --   �����敪
    ,iv_process_date IN  VARCHAR2           --   �������s��
  );
END XXCSO013A02C;
/
