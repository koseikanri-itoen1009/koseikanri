CREATE OR REPLACE PACKAGE APPS.XXCMM006A07C
AS
/*************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 * 
 * Package Name    : XXCMM006A07C
 * Description     : �l���X�g�̒lIF���o
 * MD.050          : T_MD050_CMM_006_A07_�l���X�g�̒lIF���o_EBS�R���J�����g
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
 *  2022-12-07    1.0   T.Okuyama     ����쐬
 ************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                  OUT    VARCHAR2         -- �G���[���b�Z�[�W # �Œ� #
    , retcode                 OUT    VARCHAR2         -- �G���[�R�[�h     # �Œ� #
    , iv_flex_value_set_name  IN     VARCHAR2         -- �l�Z�b�g��
  );
END XXCMM006A07C;
/
