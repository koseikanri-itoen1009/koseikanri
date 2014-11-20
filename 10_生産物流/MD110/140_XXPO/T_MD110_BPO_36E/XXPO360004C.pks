CREATE OR REPLACE PACKAGE xxpo360004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360004C(spec)
 * Description      : �d�����ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_360)
 *                  : �L���x�����[Issue1.0(T_MD070_BPO_36E)
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
 *  2008/03/17    1.0   Y.Majikina       �V�K�쐬
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
      iv_deliver_from       IN    VARCHAR2,  -- �[����FROM
      iv_deliver_to         IN    VARCHAR2,  -- �[����TO
      iv_item_division      IN    VARCHAR2,  -- ���i�敪
      iv_dept_code          IN    VARCHAR2,  -- �S������
      iv_vendor_code1       IN    VARCHAR2,  -- �����1
      iv_vendor_code2       IN    VARCHAR2,  -- �����2
      iv_vendor_code3       IN    VARCHAR2,  -- �����3
      iv_vendor_code4       IN    VARCHAR2,  -- �����4
      iv_vendor_code5       IN    VARCHAR2,  -- �����5
      iv_art_division       IN    VARCHAR2,  -- �i�ڋ敪
      iv_crowd1             IN    VARCHAR2,  -- �Q1
      iv_crowd2             IN    VARCHAR2,  -- �Q2
      iv_crowd3             IN    VARCHAR2,  -- �Q3
      iv_art1               IN    VARCHAR2,  -- �i��1
      iv_art2               IN    VARCHAR2,  -- �i��2
      iv_art3               IN    VARCHAR2,  -- �i��3
      iv_security_flg       IN    VARCHAR2   -- �Z�L�����e�B�敪
    );
--
END xxpo360004c;
/
