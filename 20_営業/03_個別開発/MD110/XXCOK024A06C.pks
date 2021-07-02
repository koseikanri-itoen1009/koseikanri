CREATE OR REPLACE PACKAGE APPS.XXCOK024A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A06C (spec)
 * Description      : �̔��T�������d������쐬���A��ʉ�vOIF�ɘA�g���鏈��
 * MD.050           : �̔��T���f�[�^GL�A�g MD050_COK_024_A06
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
 *  2020/01/15    1.0   H.Ishii          �V�K�쐬
 *  2021/06/24    1.1   K.Tomie          E_�{�ғ�_17279�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf        OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
    ,retcode       OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
--Ver 1.1 add start
    ,parallel_group IN    VARCHAR2         --   GL�A�g�p���������s�O���[�v
--Ver 1.1 add end
  );
END XXCOK024A06C;
/
