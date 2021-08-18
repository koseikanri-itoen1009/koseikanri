CREATE OR REPLACE PACKAGE APPS.XXCOK024A14C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A14 (spec)
 * Description      : �T�������쐬API(AP�x��)
 * MD.050           : �T�������쐬API(AP�x��) MD050_COK_024_A14
 * Version          : 1.1
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
 *  2020/04/30    1.0   Y.Nakajima       main�V�K�쐬
 *  2021/07/21    1.1   K.Yoshikawa      [E_�{�ғ�_17382](Q4148)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,ov_recon_slip_num               OUT    VARCHAR2          -- �x���`�[�ԍ�
   ,iv_recon_base_code              IN     VARCHAR2          -- �x���������_
   ,id_recon_due_date               IN     DATE              -- �x���\���
   ,id_gl_date                      IN     DATE              -- GL�L����
   ,id_target_date_end              IN     DATE              -- �Ώۊ���(TO)
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_corp_code                    IN     VARCHAR2          -- ��ƃR�[�h
   ,iv_deduction_chain_code         IN     VARCHAR2          -- �T���p�`�F�[���R�[�h
   ,iv_cust_code                    IN     VARCHAR2          -- �ڋq�R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- ��̐������ԍ�
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
-- 2021/07/21 Ver1.1 ADD Start
   ,iv_condition_no                 IN     VARCHAR2          -- �T���ԍ�(�J���}��؂�ő�50��)
-- 2021/07/21 Ver1.1 ADD End
  );
END XXCOK024A14C;
/
