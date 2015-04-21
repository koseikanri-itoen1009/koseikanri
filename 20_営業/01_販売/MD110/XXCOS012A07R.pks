CREATE OR REPLACE PACKAGE APPS.XXCOS012A07R
AS
 /*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCOS012A07R(Spec)
 * Description      : ���b�g�ʃs�b�N���X�g�i�o�א�E���i�E�̔���ʁj
 * MD.050           : MD050_COS_012_A07_���b�g�ʃs�b�N���X�g�i�o�א�E���i�E�̔���ʁj
 * Version          : 1.1
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2014/10/06    1.0   S.Itou           �V�K�쐬
 *  2015/04/10    1.1   S.Yamashita     �yE_�{�ғ�_13004�z�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                   OUT     VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_login_base_code        IN      VARCHAR2     -- 1.���_
   ,iv_login_chain_store_code IN      VARCHAR2     -- 2.�`�F�[���X
--  Add Ver1.1 S.Yamashita Start
   ,iv_login_customer_code    IN      VARCHAR2     -- 3.�ڋq
--  Add Ver1.1 S.Yamashita End
   ,iv_request_date_from      IN      VARCHAR2     -- 4.�����iFrom�j
   ,iv_request_date_to        IN      VARCHAR2     -- 5.�����iTo�j
   ,iv_bargain_class          IN      VARCHAR2     -- 6.��ԓ����敪
   ,iv_edi_received_date      IN      VARCHAR2     -- 7.EDI��M��
   ,iv_shipping_status        IN      VARCHAR2     -- 8.�X�e�[�^�X
   ,iv_order_number           IN      VARCHAR2     -- 9.�󒍔ԍ�
  );
END XXCOS012A07R;
/
