--//+UPD START 2009/02/13 CT017 S.Son
--CREATE OR REPLACE PACKAGE XXCSM002A05
CREATE OR REPLACE PACKAGE XXCSM002A05C
--//+UPD END 2009/02/13 CT017 S.Son
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A05(spec)
 * Description      : ���i�v��P�i�ʈ�����
 * MD.050           : ���i�v��P�i�ʈ����� MD050_CSM_002_A05
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
 *  2008/11/17    1.0   sonshubai        �V�K�쐬
 *  2009/02/13    1.1   S.Son            [��QCT_017] �R���p�C���G���[�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT    VARCHAR2,         -- �G���[���b�Z�[�W
    retcode       OUT    VARCHAR2,         -- �G���[�R�[�h
    iv_kyoten_cd  IN     VARCHAR2,         -- 1.���_�R�[�h
    iv_deal_cd    IN     VARCHAR2          -- 2.����Q�R�[�h
  );
--//+UPD START 2009/02/13 CT017 S.Son
--END XXCSM002A05;
END XXCSM002A05C;
--//+UPD END 2009/02/13 CT017 S.Son
/
