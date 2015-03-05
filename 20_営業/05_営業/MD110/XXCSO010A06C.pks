CREATE OR REPLACE PACKAGE APPS.XXCSO010A06C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2015. All rights reserved.
 *
 * Package Name     : XXCSO010A06C(spec)
 * Description      : �o���o��
 * MD.050           : �o���o��(MD050_CSO_010A06)
 * Version          : 1.0
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- --------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- --------------------------------------------
 *  2015/02/10    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT    VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode            OUT    VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_report_type     IN     VARCHAR2     -- ���[�敪
   ,iv_contract_number IN     VARCHAR2     -- �_�񏑔ԍ�
   ,in_org_request_id  IN     NUMBER       -- ���s���v��ID
  );
END XXCSO010A06C;
/
