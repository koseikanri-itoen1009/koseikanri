CREATE OR REPLACE PACKAGE APPS.XXCOK024A15C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A15 (spec)
 * Description      : �T�������쐬API(AP�≮�x��)
 * MD.050           : �T�������쐬API(AP�≮�x��) MD050_COK_024_A15
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
 *  2020/04/28    1.0   Y.Nakajima       main�V�K�쐬
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
   ,od_target_date_end              OUT    DATE              -- �Ώۊ���(TO)
   ,iv_payee_code                   IN     VARCHAR2          -- �x����R�[�h
   ,iv_invoice_number               IN     VARCHAR2          -- �≮�������ԍ�
   ,iv_terms_name                   IN     VARCHAR2          -- �x������
   ,id_invoice_date                 IN     DATE              -- ���������t
   ,iv_target_data_type             IN     VARCHAR2          -- �Ώۃf�[�^���
  );
END XXCOK024A15C;
/
