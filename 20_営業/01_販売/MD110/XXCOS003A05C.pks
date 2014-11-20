CREATE OR REPLACE PACKAGE XXCOS003A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS003A01C(spec)
 * Description      : �P���}�X�^IF�o�́i�t�@�C���쐬�j
 * MD.050           : �P���}�X�^IF�o�́i�t�@�C���쐬�j MD050_COS_003_A05
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
 *  2008/12/05   1.0   K.Okaguchi       �V�K�쐬
 *  2009/01/17   1.1   K.Okaguchi       [��QCOS_124] �t�@�C���o�͕ҏW�̃o�O���C��
 *  2009/02/24   1.2   T.Nakamura       [��QCOS_130] ���b�Z�[�W�o�́A���O�o�͂ւ̏o�͓��e�̒ǉ��E�C��
 *  2009/04/15   1.3    N.Maeda         [ST��QNo.T1_0067�Ή�] �t�@�C���o�͎���CHAR�^VARCHAR�^�ȊO�ւ̢"��t���̍폜
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
  );
END XXCOS003A05C;
/
