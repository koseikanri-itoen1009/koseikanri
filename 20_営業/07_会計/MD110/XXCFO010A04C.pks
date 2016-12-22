CREATE OR REPLACE PACKAGE XXCFO010A04C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 * 
 * Package Name    : XXCFO010A04C(spec)
 * Description     : �g�cWF�A�g
 * MD.050          : MD050_CFO_010_A04_�g�cWF�A�g
 * Version         : 1.0
 * 
 * Program List
 * --------------- ---- ----- --------------------------------------------
 *  Name           Type  Ret   Description
 * --------------- ---- ----- --------------------------------------------
 *  main            P         �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2016-12-09    1.0  SCSK ���H���O  ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_coop_date_from  IN     VARCHAR2,         --   1.�A�g��From
    iv_coop_date_to    IN     VARCHAR2          --   2.�A�g��To
  );
END XXCFO010A04C;
/
