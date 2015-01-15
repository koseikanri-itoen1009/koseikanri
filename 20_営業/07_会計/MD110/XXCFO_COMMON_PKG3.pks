create or replace PACKAGE XXCFO_COMMON_PKG3
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : xxcfo_common_pkg3(spec)
 * Description      : ���ʊ֐��i��v�j
 * MD.070           : MD070_IPO_CFO_001_���ʊ֐���`��
 * Version          : 1.0
 *
 * Program List
 *  --------------------      ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  --------------------      ---- ----- --------------------------------------------------
 *  init_proc                 P           ���ʏ�������
 *  chk_period_status         P           �d��쐬�p��v���ԃ`�F�b�N
 *  chk_gl_if_status          P           �d��쐬�pGL�A�g�`�F�b�N
 *  chk_ap_period_status      P           AP�������쐬�p��v���ԃ`�F�b�N
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014-09-19    1.0   K.Kubo           �V�K�쐬
 *
 *****************************************************************************************/
--
  -- ���ʏ�������
  PROCEDURE init_proc(
      ov_company_code_mfg         OUT VARCHAR2  -- ��ЃR�[�h�i�H��j
    , ov_aff5_customer_dummy      OUT VARCHAR2  -- �ڋq�R�[�h_�_�~�[�l
    , ov_aff6_company_dummy       OUT VARCHAR2  -- ��ƃR�[�h_�_�~�[�l
    , ov_aff7_preliminary1_dummy  OUT VARCHAR2  -- �\��1_�_�~�[�l
    , ov_aff8_preliminary2_dummy  OUT VARCHAR2  -- �\��2_�_�~�[�l
    , ov_je_invoice_source_mfg    OUT VARCHAR2  -- �d��\�[�X_���Y�V�X�e��
    , on_org_id_mfg               OUT NUMBER    -- ���YORG_ID
    , on_sales_set_of_bks_id      OUT NUMBER    -- �c�ƃV�X�e����v����ID
    , ov_sales_set_of_bks_name    OUT VARCHAR2  -- �c�ƃV�X�e����v���떼
    , ov_currency_code            OUT VARCHAR2  -- �c�ƃV�X�e���@�\�ʉ݃R�[�h
    , od_process_date             OUT DATE      -- �Ɩ����t
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  );
--
  -- �d��쐬�p��v���ԃ`�F�b�N
  PROCEDURE chk_period_status(
      iv_period_name              IN  VARCHAR2  -- ��v���ԁiYYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- ��v����ID
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  );
--
  -- �d��쐬�pGL�A�g�`�F�b�N
  PROCEDURE chk_gl_if_status(
      iv_period_name              IN  VARCHAR2  -- ��v���ԁiYYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- ��v����ID
    , iv_func_name                IN  VARCHAR2  -- �@�\���i�R���J�����g�Z�k���j
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  );
--
  -- AP�������쐬�p��v���ԃ`�F�b�N
  PROCEDURE chk_ap_period_status(
      iv_period_name              IN  VARCHAR2  -- ��v���ԁiYYYY-MM)
    , in_sales_set_of_bks_id      IN  NUMBER    -- ��v����ID
    , ov_errbuf                   OUT VARCHAR2  -- �G���[�o�b�t�@
    , ov_retcode                  OUT VARCHAR2  -- ���^�[���R�[�h
    , ov_errmsg                   OUT VARCHAR2  -- ���[�U�[�E�G���[���b�Z�[�W
  );
--
END XXCFO_COMMON_PKG3;
/
