CREATE OR REPLACE PACKAGE xxpo360006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360006C(spec)
 * Description      : �d��������ו\
 * MD.050           : �L���x�����[Issue1.0(T_MD050_BPO_360)
 * MD.070           : �L���x�����[Issue1.0(T_MD070_BPO_36G)
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
 *  2008/03/13    1.0   K.Kamiyoshi      main �V�K�쐬
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
      errbuf                OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode               OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_out_flg            IN    VARCHAR2  --�o�͋敪
     ,iv_deliver_from       IN    VARCHAR2  --�[����FROM
     ,iv_deliver_to         IN    VARCHAR2  --�[����TO
     ,iv_dept_code1         IN    VARCHAR2  --�S�������P
     ,iv_dept_code2         IN    VARCHAR2  --�S�������Q
     ,iv_dept_code3         IN    VARCHAR2  --�S�������R
     ,iv_dept_code4         IN    VARCHAR2  --�S�������S
     ,iv_dept_code5         IN    VARCHAR2  --�S�������T
     ,iv_vendor_code1       IN    VARCHAR2  -- �����1
     ,iv_vendor_code2       IN    VARCHAR2  -- �����2
     ,iv_vendor_code3       IN    VARCHAR2  -- �����3
     ,iv_vendor_code4       IN    VARCHAR2  -- �����4
     ,iv_vendor_code5       IN    VARCHAR2  -- �����5
     ,iv_mediator_code1     IN    VARCHAR2  -- ������1
     ,iv_mediator_code2     IN    VARCHAR2  -- ������2
     ,iv_mediator_code3     IN    VARCHAR2  -- ������3
     ,iv_mediator_code4     IN    VARCHAR2  -- ������4
     ,iv_mediator_code5     IN    VARCHAR2  -- ������5
     ,iv_po_num             IN    VARCHAR2  -- �����ԍ�
     ,iv_item_code          IN    VARCHAR2  -- �i�ڃR�[�h
     ,iv_security_flg       IN    VARCHAR2  -- �Z�L�����e�B�敪
    );
--
END xxpo360006c;
/
