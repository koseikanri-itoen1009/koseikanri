CREATE OR REPLACE PACKAGE XXCOK007A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK007A01C(spec)
 * Description      : ������ѐU�֏��쐬(EDI)
 * MD.050           : ������ѐU�֏��쐬(EDI) MD050_COK_007_A01
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                ������ѐU�֏��쐬(EDI)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/25    1.0   S.Sasaki         main�V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf            OUT  VARCHAR2     --�G���[���b�Z�[�W
  ,  retcode           OUT  VARCHAR2     --�G���[�R�[�h
  ,  iv_file_name      IN   VARCHAR2     --�t�@�C����
  ,  iv_execution_type IN   VARCHAR2     --���s�敪 1:�ʏ� 2:���J�o��
  );
END XXCOK007A01C;
/
