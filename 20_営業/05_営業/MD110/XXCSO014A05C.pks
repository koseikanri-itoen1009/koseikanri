CREATE OR REPLACE PACKAGE XXCSO014A05C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO014A05C(spec)
 * Description      : CSV�t�@�C������擾�����m�[�g����EBS��
 *                    �m�[�g�֓o�^���܂��B
 * MD.050           : MD050_CSO_014_A05_HHT-EBS�C���^�[�t�F�[�X�F(IN)�m�[�g
 *
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
 *  2008-11-13    1.0   shun.sou         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode       OUT  NOCOPY  VARCHAR2          -- �G���[�R�[�h     #�Œ�#
  );
END XXCSO014A05C;
/