CREATE OR REPLACE PACKAGE APPS.XXCMM004A13C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2017. All rights reserved.
 *
 * Package Name     : XXCMM004A13C(spec)
 * Description      : �ύX�\����ꊇ�o�^
 * MD.050           : �ύX�\����ꊇ�o�^ MD050_CMM_004_A13
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
 *  2017/06/22    1.0   S.Niki           E_�{�ғ�_14300�Ή� �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT    VARCHAR2        -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                 OUT    VARCHAR2        -- �G���[�R�[�h     #�Œ�#
   ,iv_file_id              IN     VARCHAR2        -- �t�@�C��ID
   ,iv_format_pattern       IN     VARCHAR2        -- �t�H�[�}�b�g�p�^�[��
  );
  --
END XXCMM004A13C;
/
