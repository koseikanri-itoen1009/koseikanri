CREATE OR REPLACE PACKAGE xxpo710002c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo710002c(spec)
 * Description      : ���Y�����i�d���j
 * MD.050/070       : ���Y�����i�d���jIssue1.0  (T_MD050_BPO_710)
 *                    �r�������\�݌v            (T_MD070_BPO_71C)
 * Version          : 1.2
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/01/22    1.0   Yasuhisa Yamamoto  �V�K�쐬
 *  2008/05/20    1.1   Yohei    Takayama  �����e�X�g�Ή�(710_11)
 *  2008/07/02    1.2   Satoshi Yunba      �֑������Ή�
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_report_type        IN     VARCHAR2         -- 01 : ���[���
     ,iv_creat_date_from    IN     VARCHAR2         -- 02 : ��������FROM
     ,iv_creat_date_to      IN     VARCHAR2         -- 03 : ��������TO
    ) ;
END xxpo710002c;
/
