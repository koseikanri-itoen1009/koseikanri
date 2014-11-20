CREATE OR REPLACE PACKAGE XXCOK021A06R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK021A06R(spec)
 * Description      : �����≮�Ɋւ��鐿�����ƌ��Ϗ���˂����킹�A�i�ڕʂɐ������ƌ��Ϗ��̓��e��\��
 * MD.050           : �≮�̔������x���`�F�b�N�\ MD050_COK_021_A06
 * Version          : 1.1
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
 *  2008/12/05    1.0   K.Iwabuchi       main�V�K�쐬
 *  2009/02/05    1.1   K.Iwabuchi       [��QCOK_011] �p�����[�^�s��Ή�
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                   OUT    VARCHAR2         -- �G���[���b�Z�[�W
  , retcode                  OUT    VARCHAR2         -- �G���[�R�[�h
  , iv_base_code             IN     VARCHAR2         -- ���_�R�[�h
  , iv_payment_date          IN     VARCHAR2         -- �x���N����
  , iv_selling_month         IN     VARCHAR2         -- ����Ώ۔N��
  , iv_wholesale_code_admin  IN     VARCHAR2         -- �≮�Ǘ��R�[�h
  , iv_cust_code             IN     VARCHAR2         -- �ڋq�R�[�h
  , iv_sales_outlets_code    IN     VARCHAR2         -- �≮������R�[�h
  );
END XXCOK021A06R;
/
