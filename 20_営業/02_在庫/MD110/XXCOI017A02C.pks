CREATE OR REPLACE PACKAGE APPS.XXCOI017A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A02C(spec)
 * Description      : ���b�g�ʈ������CSV�����[�N�t���[�`���Ŕz�M���܂��B
 * MD.050           : ���b�g�ʏo�׏��z�M <MD050_COI_017_A02>
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
 *  2016/07/22    1.0   K.Kiriu          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode               OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_login_base_code    IN     VARCHAR2,         -- 1.���_�R�[�h
    iv_request_date_from  IN     VARCHAR2,         -- 2.�����iFrom�j
    iv_request_date_to    IN     VARCHAR2          -- 3.�����iTo�j
  );
END XXCOI017A02C;
/
