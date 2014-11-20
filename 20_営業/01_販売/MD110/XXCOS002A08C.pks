CREATE OR REPLACE PACKAGE APPS.XXCOS002A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A08C(spec)
 * Description      : ����ڕW�̃��[���z�M���s��
 * MD.050           : �ڕW�B���󋵃��[���z�M <MD050_COS_002_A08>
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
 * 2013/06/12    1.0   K.Kiriu          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_process    IN     VARCHAR2,         -- 1.�����敪 ( 1�F����W�v 2�F�]�ƈ��W�v 3:�p�[�W����)
    iv_trg_time   IN     VARCHAR2          -- 2.�z�M�^�C�~���O ( HH24:MI �`��)
  );
END XXCOS002A08C;
/
