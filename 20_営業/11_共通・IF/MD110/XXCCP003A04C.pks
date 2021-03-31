CREATE OR REPLACE PACKAGE APPS.XXCCP003A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2021. All rights reserved.
 *
 * Package Name     : XXCCP003A04C(spec)
 * Description      : �≮���m��f�[�^�o�́i���v�F���j
 * MD.070           : �≮���m��f�[�^�o�́i���v�F���j (MD070_IPO_CCP_003_A04)
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
 *  2021/01/05    1.0   SCSK N.Abe       [E_�{�ғ�_11084]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT    VARCHAR2      --   �G���[���b�Z�[�W #�Œ�#
   ,retcode               OUT    VARCHAR2      --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code          IN     VARCHAR2      --   1.���_
   ,iv_payment_date_from  IN     VARCHAR2      --   2.�x���\���FROM
   ,iv_payment_date_to    IN     VARCHAR2      --   3.�x���\���TO
   ,iv_selling_date_from  IN     VARCHAR2      --   4.����Ώ۔N��FROM
   ,iv_selling_date_to    IN     VARCHAR2      --   5.����Ώ۔N��TO
   ,iv_cust_code          IN     VARCHAR2      --   6.�ڋq
   ,iv_bill_no            IN     VARCHAR2      --   7.������No
   ,iv_supplier_code      IN     VARCHAR2      --   8.�d����CD
   ,iv_status             IN     VARCHAR2      --   9.�X�e�[�^�X(0:�S��,1:����,2:�x����,3:�폜��)
  );
END XXCCP003A04C;
/
