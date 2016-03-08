CREATE OR REPLACE PACKAGE APPS.XXCMM003A42C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCMM003A42C(spec)
 * Description      : ���P�[�V�����}�X�^IF�o�́i���̋@�Ǘ��j
 * MD.050           : ���P�[�V�����}�X�^IF�o�́i���̋@�Ǘ��j MD050_CMM_003_A42
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
 *  2016/02/04    1.0   K.Kiriu          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_update_from  IN     VARCHAR2,         --   1.�ŏI�X�V���i�J�n�j
    iv_update_to    IN     VARCHAR2          --   1.�ŏI�X�V���i�I���j
  );
END XXCMM003A42C;
/
