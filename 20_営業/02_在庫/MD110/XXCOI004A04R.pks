CREATE OR REPLACE PACKAGE XXCOI004A04R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI004A04R(spec)
 * Description      : VD�@���݌ɕ\
 * MD.050           : MD050_COI_004_A04
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
 *  2008/12/10    1.0   H.Wada           �V�K�쐬
 *
 *****************************************************************************************/
  PROCEDURE main(
    errbuf           OUT VARCHAR2             --   �G���[�E���b�Z�[�W
   ,retcode          OUT VARCHAR2             --   ���^�[���E�R�[�h
   ,iv_output_base   IN  VARCHAR2             --  1.�o�͋��_
   ,iv_output_period IN  VARCHAR2 DEFAULT '0' --  2.�o�͊���
   ,iv_output_target IN  VARCHAR2             --  3.�o�͑Ώ�
   ,iv_sales_staff_1 IN  VARCHAR2             --  4.�c�ƈ�1
   ,iv_sales_staff_2 IN  VARCHAR2             --  5.�c�ƈ�2
   ,iv_sales_staff_3 IN  VARCHAR2             --  6.�c�ƈ�3
   ,iv_sales_staff_4 IN  VARCHAR2             --  7.�c�ƈ�4
   ,iv_sales_staff_5 IN  VARCHAR2             --  8.�c�ƈ�5
   ,iv_sales_staff_6 IN  VARCHAR2             --  9.�c�ƈ�6
   ,iv_customer_1    IN  VARCHAR2             -- 10.�ڋq1
   ,iv_customer_2    IN  VARCHAR2             -- 11.�ڋq2
   ,iv_customer_3    IN  VARCHAR2             -- 12.�ڋq3
   ,iv_customer_4    IN  VARCHAR2             -- 13.�ڋq4
   ,iv_customer_5    IN  VARCHAR2             -- 14.�ڋq5
   ,iv_customer_6    IN  VARCHAR2             -- 15.�ڋq6
   ,iv_customer_7    IN  VARCHAR2             -- 16.�ڋq7
   ,iv_customer_8    IN  VARCHAR2             -- 17.�ڋq8
   ,iv_customer_9    IN  VARCHAR2             -- 18.�ڋq9
   ,iv_customer_10   IN  VARCHAR2             -- 19.�ڋq10
   ,iv_customer_11   IN  VARCHAR2             -- 20.�ڋq11
   ,iv_customer_12   IN  VARCHAR2             -- 21.�ڋq12
  );
END XXCOI004A04R;
/
