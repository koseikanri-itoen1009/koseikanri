CREATE OR REPLACE PACKAGE xxinv550004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550004c(package)
 * Description      : �I���X�i�b�v�V���b�g�쐬
 * MD.050           : �݌�(���[)               T_MD050_BPO_550
 * MD.070           : �I���X�i�b�v�V���b�g�쐬 T_MD070_BPO_55D
 * Version          : 1.5
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  create_snapshot      �I���X�i�b�v�V���b�g�쐬�t�@���N�V����
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/10    1.0  Oracle ���� ����  �V�K�쐬
 *  2008/05/07    1.1  Oracle ���� ���b  �����ύX�v��#47,#62
 *  2008/05/20    1.2  Oracle �F�{ �a�Y  �����e�X�g��Q(User-Defined Exception)�Ή�
 *  2008/06/23    1.3  Oracle �F�{ �a�Y  �V�X�e���e�X�g��Q#260(�󕥎c�����X�g���I�����Ȃ�)�Ή�
 *  2008/08/28    1.4  Oracle �R�� ��_  PT 2_1_12 #33,T_S_503�Ή�
 *  2008/09/16    1.5   Y.Yamamoto       PT 2-1_12 #63
 *
 *****************************************************************************************/
--
  -- �I���X�i�b�v�V���b�g�쐬�֐�
  FUNCTION create_snapshot(
    iv_invent_ym 	IN  VARCHAR2,                   -- �Ώ۔N��	
    iv_whse_code1	IN  VARCHAR2 DEFAULT NULL,      -- �q�ɃR�[�h�P
    iv_whse_code2       IN  VARCHAR2 DEFAULT NULL,  -- �q�ɃR�[�h�Q
    iv_whse_code3       IN  VARCHAR2 DEFAULT NULL,  -- �q�ɃR�[�h�R
    iv_whse_department1	IN  VARCHAR2 DEFAULT NULL,  -- �q�ɊǗ������P
    iv_whse_department2 IN  VARCHAR2 DEFAULT NULL,  -- �q�ɊǗ������Q
    iv_whse_department3 IN  VARCHAR2 DEFAULT NULL,  -- �q�ɊǗ������R
    iv_block1           IN  VARCHAR2 DEFAULT NULL,  -- �u���b�N�P
    iv_block2           IN  VARCHAR2 DEFAULT NULL,  -- �u���b�N�Q
    iv_block3           IN  VARCHAR2 DEFAULT NULL,  -- �u���b�N�R
    iv_arti_div_code    IN  VARCHAR2,               -- ���i�敪
    iv_item_class_code  IN  VARCHAR2)               -- �i�ڋ敪
    RETURN NUMBER;
END xxinv550004c;
/











































