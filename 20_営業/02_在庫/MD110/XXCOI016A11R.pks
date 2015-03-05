CREATE OR REPLACE PACKAGE XXCOI016A11R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A11R(spec)
 * Description      : ���b�g�ʎ󕥎c���\�i�q�Ɂj
 * MD.050           : MD050_COI_016_A11_���b�g�ʎ󕥎c���\�i�q�Ɂj.doc
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
 *  2014/11/06    1.0   Y.Nagasue        main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT VARCHAR2 -- �G���[���b�Z�[�W 
   ,retcode              OUT VARCHAR2 -- �G���[�R�[�h     
   ,iv_exe_type          IN  VARCHAR2 -- ���s�敪
   ,iv_target_date       IN  VARCHAR2 -- �Ώۓ�
   ,iv_target_month      IN  VARCHAR2 -- �Ώی�
   ,iv_login_base_code   IN  VARCHAR2 -- ���_
   ,iv_subinventory_code IN  VARCHAR2 -- �ۊǏꏊ
  );
END XXCOI016A11R;
/
