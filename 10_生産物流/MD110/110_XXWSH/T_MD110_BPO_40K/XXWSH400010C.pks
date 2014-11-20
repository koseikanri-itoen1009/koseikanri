CREATE OR REPLACE PACKAGE xxwsh400010c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh400010c(spec)
 * Description      : �o�׈˗����߉�������
 * MD.050           : �o�׈˗� T_MD050_BPO_401
 * MD.070           : �o�׈˗����߉�������  T_MD070_BPO_40K
 * Version          : 1.3
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
 *  2008/04/04    1.0  Oracle �㌴���D   ����쐬
 *  2008/5/19     1.1  Oracle �㌴���D   �����ύX�v��#80�Ή� �p�����[�^�u���_�v�ǉ�
 *  2008/07/04    1.2  Oracle �k�������v ST#366�Ή� ���������̋��_�A���_�J�e�S����ALL�̍ۂ�
 *                                       ���������ʊ֐��̏����ƈقȂ邽�ߋ��ʊ֐�����R�s�[��
 *                                       ����
 *  2009/01/20    1.3  Oracle �ɓ��ЂƂ� �{�ԏ�Q#1053�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT NOCOPY VARCHAR2,  -- �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT NOCOPY VARCHAR2,  -- �G���[�R�[�h     #�Œ�#
    iv_transaction_type_id  IN VARCHAR2,          -- �o�Ɍ`��
    iv_shipped_locat_code     IN VARCHAR2,          -- �o�Ɍ�
    iv_sales_branch           IN VARCHAR2,          -- ���_
    iv_sales_branch_category  IN VARCHAR2,          -- ���_�J�e�S��
    iv_lead_time_day          IN VARCHAR2,          -- ���Y����LT/����ύXLT
    iv_ship_date              IN VARCHAR2,          -- �o�ɓ�
    iv_base_record_class      IN VARCHAR2,          -- ����R�[�h�敪
    iv_prod_class             IN VARCHAR2           -- ���i�敪
  );
END xxwsh400010c;
/
