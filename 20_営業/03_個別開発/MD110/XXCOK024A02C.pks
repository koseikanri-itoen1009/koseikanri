CREATE OR REPLACE PACKAGE APPS.XXCOK024A02C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A02C (spec)
 * Description      : �T���}�X�^CSV�o��
 * MD.050           : �T���}�X�^CSV�o�� MD050_COK_024_A02
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
 *  2020/04/23    1.0   Y.Nakajima       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_order_deduction_no           IN     VARCHAR2          -- �T���ԍ�
   ,iv_corp_code                    IN     VARCHAR2          -- ��ƃR�[�h
   ,iv_introduction_code            IN     VARCHAR2          -- �`�F�[���R�[�h
   ,iv_ship_cust_code               IN     VARCHAR2          -- �ڋq�R�[�h
   ,iv_data_type                    IN     VARCHAR2          -- �f�[�^���
   ,iv_tax_code                     IN     VARCHAR2          -- �ŃR�[�h
   ,iv_order_list_date_from         IN     VARCHAR2          -- �o�͊J�n��
   ,iv_order_list_date_to           IN     VARCHAR2          -- �o�͏I����
   ,iv_content                      IN     VARCHAR2          -- ���e
   ,iv_decision_no                  IN     VARCHAR2          -- ����No
   ,iv_agreement_no                 IN     VARCHAR2          -- �_��ԍ�
   ,iv_last_update_date             IN     VARCHAR2          -- �ŏI�X�V��
  );
END XXCOK024A02C;
/
