CREATE OR REPLACE PACKAGE XXCOS010A15C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2024. All rights reserved.
 * 
 * Package Name    : XXCOS010A15C(spec)
 * Description     : PaaS���הԍ��A�g����
 * MD.050          : T_MD050_COS_010_A15_PaaS���הԍ��A�g����
 * Version         : 1.0
 * 
 * Program List
 * -------------------- -----------------------------------------------------
 *  Name                Description
 * -------------------- -----------------------------------------------------
 *  main                �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * 
 * Change Record
 * ------------- ----- ------------- -------------------------------------
 *  Date          Ver.  Editor        Description
 * ------------- ----- ------------- -------------------------------------
 *  2024-10-08    1.0   Y.Ooyama      ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2         -- �G���[���b�Z�[�W # �Œ� #
    , retcode                 OUT    VARCHAR2         -- �G���[�R�[�h     # �Œ� #
  );
END XXCOS010A15C;
/
