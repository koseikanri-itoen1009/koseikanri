CREATE OR REPLACE PACKAGE APPS.XXCSO020A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO020A07C (spec)
 * Description      : SP�ꌈ�����CSV�o��
 * MD.050           : SP�ꌈ�����CSV�o�� (MD050_CSO_020A07)
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
 *  2015/02/10    1.0   S.Yamashita      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT    VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode          OUT    VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_base_code     IN     VARCHAR2     -- �\��(����)���_
   ,iv_app_date_from IN     VARCHAR2     -- �\����(FROM)
   ,iv_app_date_to   IN     VARCHAR2     -- �\����(TO)
   ,iv_status        IN     VARCHAR2     -- �X�e�[�^�X
   ,iv_customer_cd   IN     VARCHAR2     -- �ڋq�R�[�h
   ,iv_kbn           IN     VARCHAR2     -- ����敪
  );
END XXCSO020A07C;
/
