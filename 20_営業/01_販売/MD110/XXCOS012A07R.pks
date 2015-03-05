CREATE OR REPLACE PACKAGE APPS.XXCOS012A07R
AS
 /*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2014. All rights reserved.
 *
 * Package Name     : XXCOS012A07R(Spec)
 * Description      : ���b�g�ʃs�b�N���X�g�i�o�א�E���i�E�̔���ʁj
 * MD.050           : MD050_COS_012_A07_���b�g�ʃs�b�N���X�g�i�o�א�E���i�E�̔���ʁj
 * Version          : 1.00
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
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT     VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                   OUT     VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_login_base_code        IN      VARCHAR2     -- 1.���_
   ,iv_login_chain_store_code IN      VARCHAR2     -- 2.�`�F�[���X
   ,iv_request_date_from      IN      VARCHAR2     -- 3.�����iFrom�j
   ,iv_request_date_to        IN      VARCHAR2     -- 4.�����iTo�j
   ,iv_bargain_class          IN      VARCHAR2     -- 5.��ԓ����敪
   ,iv_edi_received_date      IN      VARCHAR2     -- 6.EDI��M��
   ,iv_shipping_status        IN      VARCHAR2     -- 7.�X�e�[�^�X
   ,iv_order_number           IN      VARCHAR2     -- 8.�󒍔ԍ�
  );
END XXCOS012A07R;
/
