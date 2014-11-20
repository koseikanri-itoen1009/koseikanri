CREATE OR REPLACE PACKAGE XXCMM003A28C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2009. All rights reserved.
 *
 * Package Name     : XXCMM003A28C(spec)
 * Description      : �ڋq�ꊇ�X�V�p�b�r�u�_�E�����[�h
 * MD.050           : MD050_CMM_003_A28_�ڋq�ꊇ�X�V�pCSV�_�E�����[�h
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
 *  2009/01/07    1.0   ���� �S��        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W���i�ڋq�ꊇ�X�V�p�b�r�u�_�E�����[�h�j
  PROCEDURE main(
    errbuf                    OUT    VARCHAR2,     --�G���[���b�Z�[�W #�Œ�#
    retcode                   OUT    VARCHAR2,     --�G���[�R�[�h     #�Œ�#
    iv_customer_class         IN     VARCHAR2,     --�ڋq�敪
    iv_ar_invoice_grp_code    IN     VARCHAR2,     --���|�R�[�h�P�i�������j
    iv_ar_location_code       IN     VARCHAR2,     --���|�R�[�h�Q�i���Ə��j
    iv_ar_others_code         IN     VARCHAR2,     --���|�R�[�h�R�i���̑��j
    iv_kigyou_code            IN     VARCHAR2,     --��ƃR�[�h
    iv_sales_chain_code       IN     VARCHAR2,     --�`�F�[���X�R�[�h�i�̔���j
    iv_delivery_chain_code    IN     VARCHAR2,     --�`�F�[���X�R�[�h�i�[�i��j
    iv_policy_chain_code      IN     VARCHAR2,     --�`�F�[���X�R�[�h�i�����p�j
    iv_chain_store_edi        IN     VARCHAR2,     --�`�F�[���X�R�[�h�i�d�c�h�j
    iv_gyotai_sho             IN     VARCHAR2,     --�Ƒԁi�����ށj
    iv_chiku_code             IN     VARCHAR2      --�n��R�[�h
  );
END XXCMM003A28C;
/
