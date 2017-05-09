CREATE OR REPLACE PACKAGE APPS.XXCOS003A09C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCOS003A09C (spec)
 * Description      : �������i�\�f�[�^�_�E�����[�h
 * MD.050           : �������i�\�f�[�^�_�E�����[�h <MD050_COS_003_A09>
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
 *  2016/04/05    1.0   S.Niki           �V�K�쐬[E_�{�ғ�_14024�Ή�]
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
   ,retcode                OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code           IN     VARCHAR2         --   ���_�R�[�h
   ,iv_customer_code       IN     VARCHAR2         --   �ڋq�R�[�h
   ,iv_item_code           IN     VARCHAR2         --   �i�ڃR�[�h
   ,iv_date_from           IN     VARCHAR2         --   ����(FROM)
   ,iv_date_to             IN     VARCHAR2         --   ����(TO)
  );
END XXCOS003A09C;
/
