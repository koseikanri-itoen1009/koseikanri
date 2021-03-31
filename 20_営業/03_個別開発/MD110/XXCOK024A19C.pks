CREATE OR REPLACE PACKAGE XXCOK024A19C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A19C_pks(spec)
 * Description      : �c�ƃV�X�e���\�z�v���W�F�N�g
 * MD.050           : �A�h�I���F�T���f�[�^���z���z���� MD050_COK_024_A19
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
 *  2020/03/12    1.0   Y.Koh            �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    ov_errbuf                           OUT VARCHAR2        -- �G���[�E���b�Z�[�W
  , ov_retcode                          OUT VARCHAR2        -- ���^�[���E�R�[�h
  , ov_errmsg                           OUT VARCHAR2        -- ���[�U�[�E�G���[�E���b�Z�[�W
  , iv_recon_slip_num                   IN  VARCHAR2        -- �x���`�[�ԍ�
  );
END XXCOK024A19C;
/