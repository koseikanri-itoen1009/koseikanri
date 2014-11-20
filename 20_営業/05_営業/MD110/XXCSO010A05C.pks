CREATE OR REPLACE PACKAGE XXCSO010A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO010A05C (spec)
 * Description      : �_�񏑊m���CSV�o��
 * MD.050           : �_�񏑊m���CSV�o�� (MD050_CSO_010A05)
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
 *  2012/08/07    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode       OUT    VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_base_code  IN     VARCHAR2     -- ���㋒�_
   ,iv_status     IN     VARCHAR2     -- �_���
   ,iv_date_from  IN     VARCHAR2     -- ���o�Ώۊ���(FROM)
   ,iv_date_to    IN     VARCHAR2     -- ���o�Ώۊ���(TO)
  );
END XXCSO010A05C;
/
