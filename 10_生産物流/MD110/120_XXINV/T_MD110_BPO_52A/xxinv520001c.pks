CREATE OR REPLACE PACKAGE xxinv520001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV520001C(spec)
 * Description      : �i�ڐU��
 * MD.050           : �i�ڐU�� T_MD050_BPO_520
 * MD.070           : �i�ڐU�� T_MD070_BPO_52A
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
 *  2008/01/11    1.0  Oracle �a�c ��P  ����쐬
 *  2008/04/28    1.1  Oracle �͖� �D�q  �����ύX�v��#
 *  2008/05/22    1.2  Oracle �F�{ �a�Y  �����e�X�g��Q�Ή�(�X�e�[�^�X�`�F�b�N�E�X�V�����ǉ�)
 *  2008/05/22    1.3  Oracle �F�{ �a�Y  �����e�X�g��Q�Ή�(����p�����[�^�ɂ����s���̃G���[)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT  NOCOPY VARCHAR2, --   �G���[���b�Z�[�W #�Œ�#
    retcode            OUT  NOCOPY VARCHAR2, --   �G���[�R�[�h     #�Œ�#
    iv_inv_loc_code    IN          VARCHAR2, --   1.�ۊǑq�ɃR�[�h
    iv_from_item_no    IN          VARCHAR2, --   2.�U�֌��i��No
    iv_lot_no          IN          VARCHAR2, --   3.�U�֌����b�gNo
    iv_to_item_no      IN          VARCHAR2, --   4.�U�֐�i��No
    iv_quantity        IN          VARCHAR2, --   5.����
    iv_sysdate         IN          VARCHAR2, --   6.�i�ڐU�֎��ѓ�
    iv_remarks         IN          VARCHAR2, --   7.�E�v
    iv_item_chg_aim    IN          VARCHAR2  --   8.�i�ڐU�֖ړI
  );
END xxinv520001c;
/
