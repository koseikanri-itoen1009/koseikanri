CREATE OR REPLACE PACKAGE XXCOI001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI001A01C(spec)
 * Description      : ���Y�����V�X�e������c�ƃV�X�e���ւ̏o�׈˗��f�[�^�̒��o�E�f�[�^�A�g���s��
 * MD.050           : ���ɏ��擾 MD050_COI_001_A01
 * Version          : 1.22
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
 *  2009/01/20    1.0   S.Moriyama       main�V�K�쐬
 *  2018/01/10    1.22  H.Sasaki         [E_�{�ғ�_14486] JOB�N�������ύX�ɔ����Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf        OUT    VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
    ,retcode       OUT    VARCHAR2          --   �G���[�R�[�h     #�Œ�#
    , iv_inv_close_flag   IN  VARCHAR2      --  INV���ߓ��t���O       --  2018/01/10 V1.22 Added
    , iv_exec_flag        IN  VARCHAR2      --  �N���t���O            --  2018/01/10 V1.22 Added
  );
END XXCOI001A01C;
/
