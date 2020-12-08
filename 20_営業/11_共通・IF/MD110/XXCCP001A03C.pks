CREATE OR REPLACE PACKAGE APPS.XXCCP001A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP001A03C(spec)
 * Description      : WF�s���󒍖��׌��m���ΏۊO�X�V
 * MD.070           : WF�s���󒍖��׌��m���ΏۊO�X�V (MD070_IPO_CCP_001_A03)
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
 *  2020/12/01    1.0   N.Koyama         [E_�{�ғ�_16819]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2      --   �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT    VARCHAR2      --   �G���[�R�[�h     #�Œ�#
   ,iv_exe_mode        IN     VARCHAR2      --   ���s���[�h
   ,in_back_num        IN     NUMBER        --   �Ώ�FROM��
  );
END XXCCP001A03C;
/