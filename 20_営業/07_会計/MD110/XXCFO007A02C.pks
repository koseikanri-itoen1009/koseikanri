CREATE OR REPLACE PACKAGE APPS.XXCFO007A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCFO007A02C(spec)
 * Description      : EBS AP�I�[�v���C���^�t�F�[�X�̓o�^���ꂽ�f�[�^�𒊏o�AERP Cloud��AP�W���e�[�u���ɓo�^����B
 * MD.050           : T_MD050_CFO_007_A02_���F�ώd���搿�������o_EBS�R���J�����g
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
 *  2022-12-07    1.0   Yamato.Fuku      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_source     IN     VARCHAR2          --   �\�[�X
  );
END XXCFO007A02C;
/
