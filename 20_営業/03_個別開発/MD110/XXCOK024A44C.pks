CREATE OR REPLACE PACKAGE APPS.XXCOK024A44C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2022. All rights reserved.
 *
 * Package Name     : XXCOK024A44C (spec)
 * Description      : �T�����쐬�������E�`�[CSV�o��
 * MD.050           : �T�����쐬�������E�`�[CSV�o�� MD050_COK_024_A44
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
 *  2022/10/07    1.0   R.Oikawa         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_record_date_from             IN     VARCHAR2          -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- �v���(TO)
   ,iv_cust_code                    IN     VARCHAR2          -- �ڋq
   ,iv_base_code                    IN     VARCHAR2          -- �N�[����
   ,iv_user_name                    IN     VARCHAR2          -- ���͎�
   ,iv_slip_line_type_name          IN     VARCHAR2          -- �������e
   ,iv_payment_scheduled_date       IN     VARCHAR2          -- �����\���
  );
END XXCOK024A44C;
/
