CREATE OR REPLACE PACKAGE XXCMN810004C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMN810004C(spec)
 * Description      : �i�ڃ}�X�^�̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h     T_MD050_BPO_810
 * MD.070           : �i�ڃ}�X�^�̃A�b�v���[�h T_MD070_BPO_81D
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
 *  2012/11/20    1.0   K.Boku           ����쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    NOCOPY VARCHAR2,  --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT    NOCOPY VARCHAR2,  --   �G���[�R�[�h     #�Œ�#
    iv_file_id     IN     VARCHAR2,         --   �t�@�C���h�c
    iv_format      IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
END XXCMN810004C;
/
