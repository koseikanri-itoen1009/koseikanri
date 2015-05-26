CREATE OR REPLACE PACKAGE APPS.XXCOI016A99C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOI016A99C(spec)
 * Description      : ���b�g�ʏo�׏��쐬_�ڍs�p
 * MD.050           : -
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
 *  2015/05/12    1.0   S.Yamashita       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                    OUT VARCHAR2 -- �G���[���b�Z�[�W #�Œ�#
    , retcode                   OUT VARCHAR2 -- �G���[�R�[�h     #�Œ�#
    , iv_login_base_code        IN  VARCHAR2 -- ���_
    , iv_delivery_date_from     IN  VARCHAR2 -- ����From
    , iv_delivery_date_to       IN  VARCHAR2 -- ����To
    , iv_login_chain_store_code IN  VARCHAR2 -- �`�F�[���X
    , iv_login_customer_code    IN  VARCHAR2 -- �ڋq
    , iv_customer_po_number     IN  VARCHAR2 -- �ڋq�����ԍ�
    , iv_subinventory_code      IN  VARCHAR2 -- �ۊǏꏊ
    , iv_priority_flag          IN  VARCHAR2 -- �D�惍�P�[�V�����g�p
    , iv_lot_reversal_flag      IN  VARCHAR2 -- ���b�g�t�]��
    , iv_kbn                    IN  VARCHAR2 -- ����敪
  );
END XXCOI016A99C;
/
