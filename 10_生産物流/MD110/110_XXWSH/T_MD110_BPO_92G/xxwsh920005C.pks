CREATE OR REPLACE PACKAGE xxwsh920005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh920005c(spec)
 * Description      : �q�ɕi�ڃ}�X�^�̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h T_MD050_BPO_922
 * MD.070           : �q�ɕi�ڃ}�X�^�̃A�b�v���[�h T_MD070_BPO_92G
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
 *  2008/06/16    1.0   Y.shindou        main�V�K�쐬
 * 
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT NOCOPY VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    in_file_id      IN     VARCHAR2,         --   �t�@�C���h�c 
    in_file_format  IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
END xxwsh920005c;
/
