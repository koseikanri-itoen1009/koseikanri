CREATE OR REPLACE PACKAGE XXCFR006A04C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR006A04C(spec)
 * Description      : �����ꊇ�����A�b�v���[�h
 * MD.050           : MD050_CFR_006_A04_�����ꊇ�����A�b�v���[�h
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   p �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2010/05/26    1.0   SCS ���� ����    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_id     IN     VARCHAR2,         --   1.�t�@�C��ID
    iv_file_format IN     VARCHAR2          --   2.�t�@�C���t�H�[�}�b�g
  );
END XXCFR006A04C;
/
