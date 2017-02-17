CREATE OR REPLACE PACKAGE APPS.XXCOS002A033C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOS002A033C (spec)
 * Description      : �c�Ɛ��ѕ\�W�v(�O�N)
 * MD.050           : �c�Ɛ��ѕ\�W�v(�O�N) MD050_COS_002_A03
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
 *  2016/04/15    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                 OUT  VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                OUT  VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_delivery_date       IN   VARCHAR2,         -- 1.�[�i��
    iv_processing_class    IN   VARCHAR2          -- 2.�����敪
  );
END XXCOS002A033C;
/
