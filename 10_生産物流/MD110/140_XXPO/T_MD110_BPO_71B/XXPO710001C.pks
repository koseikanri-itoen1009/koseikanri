CREATE OR REPLACE PACKAGE xxpo710001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxpo710001c(spec)
 * Description      : ���Y�����i�d���j
 * MD.050/070       : ���Y�����i�d���jIssue1.0  (T_MD050_BPO_710)
 *                    �r�������\                (T_MD070_BPO_71B)
 * Version          : 1.4
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
 *  2007/12/28    1.0   Yasuhisa Yamamoto  �V�K�쐬
 *  2008/05/02    1.1   Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(710_10)
 *  2008/05/19    1.2   Masayuki Ikeda     �����ύX�v��#62�Ή�
 *  2008/05/20    1.3   Yohei    Takayama  �����e�X�g��Q�Ή�(710_11)
 *  2008/07/02    1.4   Satoshi Yunba      �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
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
     ,iv_entry_num          IN     VARCHAR2         -- 04 : �`�[NO
     ,iv_item_code          IN     VARCHAR2         -- 05 : �d��i��
     ,iv_department_code    IN     VARCHAR2         -- 06 : ���͕���
     ,iv_employee_number    IN     VARCHAR2         -- 07 : ���͒S����
     ,iv_input_date_from    IN     VARCHAR2         -- 08 : ���͊���FROM
     ,iv_input_date_to      IN     VARCHAR2         -- 09 : ���͊���TO
    ) ;
END xxpo710001c;
/
