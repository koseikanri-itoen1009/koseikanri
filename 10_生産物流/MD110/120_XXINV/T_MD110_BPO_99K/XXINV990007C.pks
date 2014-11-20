CREATE OR REPLACE PACKAGE xxinv990007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV990007C(spec)
 * Description      : �^�����捞�����̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h            T_MD050_BPO_990
 * MD.070           : �^�����捞�����̃A�b�v���[�h  T_MD070_BPO_99K
 * Version          : 1.3
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
 *  2008/04/10    1.0   Oracle �R�� ��_ ����쐬
 *  2008/04/25    1.1   Oracle �R�� ��_ �ύX�v��No68�Ή�
 *  2008/04/25    1.1   Oracle �R�� ��_ �ύX�v��No70�Ή�
 *  2008/04/28    1.2   Y.Kawano         �����ύX�v��No74�Ή�
 *  2008/05/28    1.3   Oracle �R�� ��_ �ύX�v��No124�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT NOCOPY VARCHAR2,      --   �G���[�E���b�Z�[�W  --# �Œ� #
    retcode           OUT NOCOPY VARCHAR2,      --   ���^�[���E�R�[�h    --# �Œ� #
    iv_file_id     IN            VARCHAR2,      -- 1.FILE_ID
    iv_file_format IN            VARCHAR2);     -- 2.�t�H�[�}�b�g�p�^�[��
END xxinv990007c;
/
