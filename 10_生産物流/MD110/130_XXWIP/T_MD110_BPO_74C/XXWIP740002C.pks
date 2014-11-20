CREATE OR REPLACE PACKAGE xxwip740002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWIP740002(spec)
 * Description      : ������
 * MD.050/070       : ������(T_MD050_BPO_740)
 *                    ������(T_MD070_BPO_74C)
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
 *  2008/04/25    1.0   Yusuke Tabata    �V�K�쐬
 *  2008/07/02    1.1   Satoshi Yunba   �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
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
  PROCEDURE main
    (
      errbuf                OUT  VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode               OUT  VARCHAR2  -- �G���[�R�[�h
     ,iv_billing_code       IN   VARCHAR2  -- 01 : ������R�[�h
     ,iv_billing_date       IN   VARCHAR2  -- 02 : �����N��
    ) ;
--
END xxwip740002c ;
/
