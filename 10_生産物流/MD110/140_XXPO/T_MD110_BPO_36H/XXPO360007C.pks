CREATE OR REPLACE PACKAGE xxpo360007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360007C(spec)
 * Description      : ���o�ɍ��ٕ\
 * MD.050/070       : �d���i���[�jIssue2.0 (T_MD050_BPO_360)
 *                    �d���i���[�jIssue2.0 (T_MD070_BPO_36H)
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
 *  2008/04/02    1.0   N.Chinen        �V�K�쐬
 *
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
