CREATE OR REPLACE PACKAGE APPS.XXCSO013A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO013A03C(spec)
 * Description      : �Œ莑�Y�̕��������[�X�EFA�̈�ɘA�g����OIF�f�[�^���쐬���܂��B
 * MD.050           : CSI��FA�C���^�t�F�[�X�F�iOUT�j�Œ莑�Y���Y��� <MD050_CSO_013_A03>
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
 * 2014/06/10    1.0   Kazuyuki Kiriu   main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf          OUT    VARCHAR2         --   �G���[���b�Z�[�W #�Œ�#
    ,retcode         OUT    VARCHAR2         --   �G���[�R�[�h     #�Œ�#
    ,iv_process_date IN     VARCHAR2         -- 1.�������s��
  );
END XXCSO013A03C;
/
