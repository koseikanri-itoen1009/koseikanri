CREATE OR REPLACE PACKAGE APPS.XXCMM002A10C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCMM002A10C(spec)
 * Description      : �Ј��f�[�^IF���o_EBS�R���J�����g
 * MD.050           : T_MD050_CMM_002_A10_�Ј��f�[�^IF���o_EBS�R���J�����g
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
 *  2022-11-02    1.0   Y.Ooyama         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                     OUT VARCHAR2,       --   �G���[���b�Z�[�W #�Œ�#
    retcode                    OUT VARCHAR2,       --   �G���[�R�[�h     #�Œ�#
    iv_proc_date_for_recovery  IN  VARCHAR2        --   �Ɩ����t�i���J�o���p�j
  );
END XXCMM002A10C;
/
