CREATE OR REPLACE PACKAGE XXCOI017A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCOI017A01C(spec)
 * Description      : ���b�g�ʓ��o�ɏ������[�N�t���[�`���Ŕz�M���܂��B
 * MD.050           : ���b�g�ʓ��o�ɏ��z�M<MD050_COI_017_A01>
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
 *  2016/07/21    1.0   S.Yamashita      �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT VARCHAR2    -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode               OUT VARCHAR2    -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_base_code          IN  VARCHAR2    -- 1.���_
   ,iv_trx_date_from      IN  VARCHAR2    -- 2.�����(From)
   ,iv_trx_date_to        IN  VARCHAR2    -- 3.�����(To)
  );
END XXCOI017A01C;
/
