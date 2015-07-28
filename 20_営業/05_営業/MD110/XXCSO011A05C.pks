CREATE OR REPLACE PACKAGE APPS.XXCSO011A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A05C (spec)
 * Description      : �ʐM���f���ݒu�^�s�ύX����
 * MD.050           : �ʐM���f���ݒu�^�s�ύX���� (MD050_CSO_011A05)
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
 *  2015/06/22    1.0   S.Yamashita      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2      --   �G���[���b�Z�[�W #�Œ�#
   ,retcode         OUT    VARCHAR2      --   �G���[�R�[�h     #�Œ�#
   ,iv_cust_code    IN     VARCHAR2      -- 1.�ڋq�R�[�h
   ,iv_install_code IN     VARCHAR2      -- 2.���g�����R�[�h
   ,iv_kbn          IN     VARCHAR2      -- 3.����敪
  );
END XXCSO011A05C;
/
