CREATE OR REPLACE PACKAGE XXCOI016A07C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI016A07C(spec)
 * Description      : ���b�g�ʈ������������ꂩ�̃X�e�[�^�X�ɂ�CSV�o�͂��s���܂��B
 * MD.050           : ���b�g�ʏo�׏��CSV�o��<MD050_COI_016_A07>
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
 *  2014/10/28    1.0   Y.Koh            ���ō쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT VARCHAR2        -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                   OUT VARCHAR2        -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_login_base_code        IN  VARCHAR2        -- 1.���_
   ,iv_login_chain_store_code IN  VARCHAR2        -- 2.�`�F�[���X
   ,iv_request_date_from      IN  VARCHAR2        -- 3.�����iFrom�j
   ,iv_request_date_to        IN  VARCHAR2        -- 4.�����iTo�j
   ,iv_bargain_class          IN  VARCHAR2        -- 5.��ԓ����敪
   ,iv_edi_received_date      IN  VARCHAR2        -- 6.EDI��M��
   ,iv_shipping_status        IN  VARCHAR2        -- 7.�X�e�[�^�X
   ,iv_order_number           IN  VARCHAR2        -- 8.�󒍔ԍ�
  );
END XXCOI016A07C;
/
