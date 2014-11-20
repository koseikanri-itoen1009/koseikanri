CREATE OR REPLACE PACKAGE APPS.XXCOS002A06R
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCOS002A06R(spec)
 * Description      : ���̋@�̔��񍐏�
 * MD.050           : ���̋@�̔��񍐏� <MD050_COS_002_A06>
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
 * 2012/02/16    1.0   K.Kiriu          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf              OUT VARCHAR2  --    �G���[���b�Z�[�W #�Œ�#
    ,retcode             OUT VARCHAR2  --    �G���[�R�[�h     #�Œ�#
    ,iv_manager_flag     IN  VARCHAR2  --  1.�Ǘ��҃t���O(Y:�Ǘ��� N:���_)
    ,iv_execute_type     IN  VARCHAR2  --  2.���s�敪(1:�ڋq�w�� 2:�d����w��)
    ,iv_target_date      IN  VARCHAR2  --  3.�Ώ۔N��
    ,iv_sales_base_code  IN  VARCHAR2  --  4.���㋒�_�R�[�h(�ڋq�w�莞�̂�)
    ,iv_customer_code_01 IN  VARCHAR2  --  5.�ڋq�R�[�h1(�ڋq�w�莞�̂�)
    ,iv_customer_code_02 IN  VARCHAR2  --  6.�ڋq�R�[�h2(�ڋq�w�莞�̂�)
    ,iv_customer_code_03 IN  VARCHAR2  --  7.�ڋq�R�[�h3(�ڋq�w�莞�̂�)
    ,iv_customer_code_04 IN  VARCHAR2  --  8.�ڋq�R�[�h4(�ڋq�w�莞�̂�)
    ,iv_customer_code_05 IN  VARCHAR2  --  9.�ڋq�R�[�h5(�ڋq�w�莞�̂�)
    ,iv_customer_code_06 IN  VARCHAR2  -- 10.�ڋq�R�[�h6(�ڋq�w�莞�̂�)
    ,iv_customer_code_07 IN  VARCHAR2  -- 11.�ڋq�R�[�h7(�ڋq�w�莞�̂�)
    ,iv_customer_code_08 IN  VARCHAR2  -- 12.�ڋq�R�[�h8(�ڋq�w�莞�̂�)
    ,iv_customer_code_09 IN  VARCHAR2  -- 13.�ڋq�R�[�h9(�ڋq�w�莞�̂�)
    ,iv_customer_code_10 IN  VARCHAR2  -- 14.�ڋq�R�[�h10(�ڋq�w�莞�̂�)
    ,iv_vendor_code_01   IN  VARCHAR2  -- 15.�d����R�[�h1(�d����w�莞�̂�)
    ,iv_vendor_code_02   IN  VARCHAR2  -- 16.�d����R�[�h2(�d����w�莞�̂�)
    ,iv_vendor_code_03   IN  VARCHAR2  -- 17.�d����R�[�h3(�d����w�莞�̂�)
  );
END XXCOS002A06R;
/
