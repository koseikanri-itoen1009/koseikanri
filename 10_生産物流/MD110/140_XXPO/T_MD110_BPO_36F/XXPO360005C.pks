CREATE OR REPLACE PACKAGE xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(spec)
 * Description      : ��s�������i���[�j
 * MD.050/070       : �d���i���[�jIssue1.0  (T_MD050_BPO_360)
 *                    ��s������            (T_MD070_BPO_36F)
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
 *  2008/03/28    1.0   T.Endou          �V�K�쐬
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_deliver_from       IN     VARCHAR2         -- �[����FROM
     ,iv_deliver_to         IN     VARCHAR2         -- �[����TO
     ,iv_vendor_code1       IN     VARCHAR2         -- �����P
     ,iv_vendor_code2       IN     VARCHAR2         -- �����Q
     ,iv_vendor_code3       IN     VARCHAR2         -- �����R
     ,iv_vendor_code4       IN     VARCHAR2         -- �����S
     ,iv_vendor_code5       IN     VARCHAR2         -- �����T
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- �����҂P
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- �����҂Q
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- �����҂R
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- �����҂S
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- �����҂T
     ,iv_dept_code1         IN     VARCHAR2         -- �S�������P
     ,iv_dept_code2         IN     VARCHAR2         -- �S�������Q
     ,iv_dept_code3         IN     VARCHAR2         -- �S�������R
     ,iv_dept_code4         IN     VARCHAR2         -- �S�������S
     ,iv_dept_code5         IN     VARCHAR2         -- �S�������T
     ,iv_security_flg       IN     VARCHAR2         -- �Z�L�����e�B�敪
    ) ;
END xxpo360005c ;
/
