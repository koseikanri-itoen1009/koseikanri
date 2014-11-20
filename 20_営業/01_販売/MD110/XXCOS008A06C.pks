CREATE OR REPLACE PACKAGE APPS.XXCOS008A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS008A06C(spec)
 * Description      : �o�׈˗����т���̎󒍍쐬
 * MD.050           : �o�׈˗����т���̎󒍍쐬 MD050_COS_008_A06
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
 *  2010/03/23    1.0   H.Itou           main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                         OUT  VARCHAR2        --   �G���[���b�Z�[�W #�Œ�#
   ,retcode                        OUT  VARCHAR2        --   �G���[�R�[�h     #�Œ�#
   ,iv_delivery_base_code          IN   VARCHAR2        -- 01.�[�i���_�R�[�h
   ,iv_input_sales_branch          IN   VARCHAR2        -- 02.���͋��_�R�[�h
   ,iv_head_sales_branch           IN   VARCHAR2        -- 03.�Ǌ����_�R�[�h
   ,iv_request_no                  IN   VARCHAR2        -- 04.�o�׈˗�No
   ,iv_entered_by_code             IN   VARCHAR2        -- 05.�o�׈˗����͎�
   ,iv_cust_code                   IN   VARCHAR2        -- 06.�ڋq�R�[�h
   ,iv_deliver_to                  IN   VARCHAR2        -- 07.�z����R�[�h
   ,iv_location_code               IN   VARCHAR2        -- 08.�o�Ɍ��R�[�h
   ,iv_schedule_ship_date_from     IN   VARCHAR2        -- 09.�o�ɓ��iFROM�j
   ,iv_schedule_ship_date_to       IN   VARCHAR2        -- 10.�o�ɓ��iTO�j
   ,iv_request_date_from           IN   VARCHAR2        -- 11.�����iFROM�j
   ,iv_request_date_to             IN   VARCHAR2        -- 12.�����iTO�j
   ,iv_cust_po_number              IN   VARCHAR2        -- 13.�ڋq�����ԍ�
   ,iv_customer_po_set_type        IN   VARCHAR2        -- 14.�ڋq�����ԍ��敪
   ,iv_uom_type                    IN   VARCHAR2        -- 15.���Z�P�ʋ敪
   ,iv_item_type                   IN   VARCHAR2        -- 16.���i�敪
   ,iv_transaction_type_id         IN   VARCHAR2        -- 17.�o�Ɍ`��
   ,iv_chain_code_sales            IN   VARCHAR2        -- 18.�̔���`�F�[��
   ,iv_chain_code_deliv            IN   VARCHAR2        -- 19.�[�i��`�F�[��
  );
END XXCOS008A06C;
/
