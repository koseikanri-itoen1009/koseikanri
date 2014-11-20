CREATE OR REPLACE PACKAGE XXCMM003A16C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A16C(spec)
 * Description      : AFF�ڋq�}�X�^�X�V
 * MD.050           : MD050_CMM_003_A16_AFF�ڋq�}�X�^�X�V
 * Version          : 1.1
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
 *  2009-02-06    1.0   Takuya.Kaihara   �V�K�쐬
 *  2009/03/09    1.1   Takuya Kaihara   �v���t�@�C���l���ʉ�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W���iAFF�ڋq�}�X�^�X�V�j
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2,     --�G���[�R�[�h     #�Œ�#
    iv_proc_date_from         IN     VARCHAR2,     -- �R���J�����g�E�p�����[�^������(FROM)
    iv_proc_date_to           IN     VARCHAR2      -- �R���J�����g�E�p�����[�^������(TO)
  );
END XXCMM003A16C;
/
