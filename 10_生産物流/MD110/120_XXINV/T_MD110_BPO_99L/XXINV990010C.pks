CREATE OR REPLACE PACKAGE XXINV990010C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XINV990010C(spec)
 * Description      : �ړ��w���̃A�b�v���[�h
 * MD.050           : �t�@�C���A�b�v���[�h   T_MD050_BPO_990
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
 *  2011/02/24    1.0   SCS Y.Kanami     �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT   VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT   VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    in_file_id      IN    VARCHAR2,     --   �t�@�C���h�c
    in_file_format  IN    VARCHAR2      --   �t�H�[�}�b�g�p�^�[��
  );
--
END XXINV990010C;
/
