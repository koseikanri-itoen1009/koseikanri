CREATE OR REPLACE PACKAGE XXINV500002C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXINV500002C(spec)
 * Description      : �ړ��w�����捞
 * MD.050           : �ړ��˗� T_MD050_BPO_500
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
 *  2011/03/04    1.0   SCS Y.Kanami    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT  VARCHAR2,              -- �G���[���b�Z�[�W #�Œ�#
    retcode             OUT  VARCHAR2,              -- �G���[�R�[�h     #�Œ�#
    in_shipped_locat_cd IN   VARCHAR2 DEFAULT NULL  -- �o�Ɍ��R�[�h
  );
END XXINV500002C;
/
