CREATE OR REPLACE PACKAGE XXCCP009A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A06C(spec)
 * Description      : GL�d��iAR�J�e�S���ʃT�}���[�j�擾
 * MD.070           : GL�d��iAR�J�e�S���ʃT�}���[�j�擾 (MD070_IPO_CCP_009_A06)
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
 *  2014/12/16     1.0  SCSK K.Nakatsu   [E_�{�ғ�_12777]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_period_name  IN     VARCHAR2          --   ��v����
  );
END XXCCP009A06C;
/
