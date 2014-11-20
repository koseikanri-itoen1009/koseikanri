CREATE OR REPLACE PACKAGE xxinv990008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv990008c(spec)
 * Description      : �z�������}�X�^�̎捞
 * MD.050           : �t�@�C���A�b�v���[�h T_MD050_BPO_990
 * MD.070           : �z�������}�X�^�̎捞 T_MD070_BPO_99I
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
 *  2008/02/27    1.0   R.matusita        main�V�K�쐬
 *  2008/04/18    1.1   Oracle �R�� ��_  �ύX�v��No63�Ή�
 *  2008/04/25    1.2   Oracle �R�� ��_  �ύX�v��No70�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT NOCOPY VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    in_file_id      IN     VARCHAR2,         --   �t�@�C���h�c 2008/04/18 �ύX
    in_file_format  IN     VARCHAR2          --   �t�H�[�}�b�g�p�^�[��
  );
END xxinv990008c;
/
