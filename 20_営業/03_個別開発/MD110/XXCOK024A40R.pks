CREATE OR REPLACE PACKAGE APPS.XXCOK024A40R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A40R (spec)
 * Description      : �≮�����P���`�F�b�N���X�g
 * MD.050           : MD050_COK_024_A40_�≮�����P���`�F�b�N���X�g.doc
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
 *  2022/01/28    1.0   K.Yoshikawa      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT VARCHAR2  -- �G���[�E���b�Z�[�W
  , retcode                  OUT VARCHAR2  -- ���^�[���E�R�[�h
  , iv_payment_date          IN  VARCHAR2  -- �x���N����
  , iv_selling_date          IN  VARCHAR2  -- ����Ώ۔N��
  , iv_base_code             IN  VARCHAR2  -- ���_�R�[�h
  , iv_wholesale_vendor_code IN  VARCHAR2  -- �d����R�[�h
  , iv_bill_no               IN  VARCHAR2  -- �������ԍ�
  , iv_chain_code            IN  VARCHAR2  -- �T���p�`�F�[���R�[�h
  );
END XXCOK024A40R;
/
