CREATE OR REPLACE PACKAGE xxinv990009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV990009C(spec)
 * Description      : �^���}�X�^�̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h     T_MD050_BPO_990
 * MD.070           : �^���}�X�^�̃A�b�v���[�h T_MD070_BPO_99J
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
 *  2008/02/15    1.0   Oracle �ؗS��   ����쐬
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    NOCOPY VARCHAR2,  --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT    NOCOPY VARCHAR2,  --   �G���[�R�[�h     #�Œ�#
    in_file_id     IN     VARCHAR2,         --   �t�@�C���h�c 2008/04/18 �ύX
    in_file_format IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
END xxinv990009c;
/
