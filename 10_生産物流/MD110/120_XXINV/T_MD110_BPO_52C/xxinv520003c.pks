CREATE OR REPLACE PACKAGE xxinv520003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv520003c(spec)
 * Description      : �i�ڐU��
 * MD.050           : �i�ڐU�� T_MD050_BPO_520
 * MD.070           : �i�ڐU�� T_MD070_BPO_52C
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2008/11/11    1.0  Oracle ��r ���    ����쐬
 *  2009/01/15    1.1  SCS    �ɓ� �ЂƂ�  �w�E2,7�Ή�
 *  2009/02/03    1.2  SCS    �ɓ� �ЂƂ�  �{�ԏ�Q#1113�Ή�
 *  2009/03/03    1.3  SCS    �Ŗ� ���\    �{�ԏ�Q#1241,#1251�Ή�
 *  2009/03/19    1.4  SCS    �Ŗ� ���\    �{�ԏ�Q#1308�Ή�
 *  2009/06/02    1.5  SCS    �ɓ� �ЂƂ�  �{�ԏ�Q#1517�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT  NOCOPY VARCHAR2, --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT  NOCOPY VARCHAR2, --   �G���[�R�[�h     #�Œ�#
    iv_process_type    IN          VARCHAR2, --   1.�����敪(1:�\��,2:�\�����,3:�\����,4:����)
    iv_plan_batch_id   IN          VARCHAR2, --   2.�o�b�`ID(�\��)
    iv_inv_loc_code    IN          VARCHAR2, --   3.�ۊǑq�ɃR�[�h
    iv_from_item_no    IN          VARCHAR2, --   4.�U�֌��i��No
    iv_lot_no          IN          VARCHAR2, --   5.�U�֌����b�gNo
    iv_to_item_no      IN          VARCHAR2, --   6.�U�֐�i��No
    iv_quantity        IN          VARCHAR2, --   7.����
    iv_sysdate         IN          VARCHAR2, --   8.�i�ڐU�֗\���
    iv_remarks         IN          VARCHAR2, --   9.�E�v
    iv_item_chg_aim    IN          VARCHAR2  --  10.�i�ڐU�֖ړI
  );
END xxinv520003c;
/
