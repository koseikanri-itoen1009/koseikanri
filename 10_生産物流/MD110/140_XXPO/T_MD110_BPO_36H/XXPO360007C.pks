CREATE OR REPLACE PACKAGE xxpo360007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360007C(spec)
 * Description      : ���o�ɍ��ٕ\
 * MD.050/070       : �d���i���[�jIssue2.0 (T_MD050_BPO_360)
 *                    �d���i���[�jIssue2.0 (T_MD070_BPO_36H)
 * Version          : 1.10
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
 *  2008/04/03    1.0   N.Chinen         �V�K�쐬
 *  2008/05/19    1.1   Y.Ishikawa       �O�����[�U�[���Ɍx���I���ɂȂ�
 *  2008/05/20    1.2   Y.Majikina       �Z�L�����e�B�O���q�ɂ̕s��Ή�
 *  2008/05/22    1.3   Y.Ishikawa       ���̓p�����[�^���كR�[�h��NULL�̏ꍇ�S�f�[�^�Ώۂɂ���B
 *  2008/05/22    1.4   Y.Ishikawa       �i�ڃR�[�h�̕\���s���C��
 *                                       �w�����𐔗ʁ���������(DFF11)�ɕύX
 *  2008/06/10    1.5   Y.Ishikawa       ���b�g�}�X�^�ɓ������b�gNo�����݂���ꍇ�A
 *                                       2���׏o�͂����
 *  2008/06/17    1.6   I.Higa           xxpo_categories_v���g�p���Ȃ��悤�ɂ���
 *  2008/06/24    1.7   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/04    1.8   Y.Ishikawa       xxcmn_item_categories4_v���g�p���Ȃ��悤�ɂ���
 *  2008/11/21    1.9   T.Yoshimoto      �����w�E#703
 *  2009/03/30    1.10  A.Shiina         �{��#1346�Ή�
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                OUT   VARCHAR2,  -- �G���[���b�Z�[�W
      retcode               OUT   VARCHAR2,  -- �G���[�R�[�h
      iv_sai_cd             IN    VARCHAR2,  -- ���َ��R
      iv_rcpt_subinv_code   IN    VARCHAR2,  -- ���ɑq��
      iv_goods_class        IN    VARCHAR2,  -- ���i�敪
      iv_item_class         IN    VARCHAR2,  -- �i�ڋ敪
      iv_dlv_from           IN    VARCHAR2,  -- �[����from
      iv_dlv_to             IN    VARCHAR2,  -- �[����to
      iv_ship_code_from     IN    VARCHAR2,  -- �o�Ɍ�
      iv_order_num          IN    VARCHAR2,  -- �����ԍ�
      iv_item_code          IN    VARCHAR2,  -- �i��
      iv_position           IN    VARCHAR2,  -- �S������
      iv_seqrt_class        IN    VARCHAR2   -- �Z�L�����e�B�敪
    );
--
END xxpo360007c;
/
