CREATE OR REPLACE PACKAGE XXCMM003A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCMM003A41C(spec)
 * Description      : �ڋq�֘A�ꊇ�X�V
 * MD.050           : �ڋq�֘A�ꊇ�X�V MD050_CMM_003_A41
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
 *  2012/11/26    1.0   M.Takasaki       �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT    VARCHAR2        -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                 OUT    VARCHAR2        -- �G���[�R�[�h     #�Œ�#
   ,iv_file_id              IN     VARCHAR2        -- �t�@�C��ID
   ,iv_format               IN     VARCHAR2        -- �t�H�[�}�b�g�p�^�[��
  );
  --
END XXCMM003A41C;
/
