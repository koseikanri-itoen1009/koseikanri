CREATE OR REPLACE PACKAGE xxpo440005c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440005(spec)
 * Description      : �L�����ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44M)
 * Version          : 1.5
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
 *  2008/04/09    1.0   Yusuke Tabata    �V�K�쐬
 *  2008/05/20    1.1   Yusuke Tabata   �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/06/03    1.2   Yohei  Takayama �����e�X�g�s�#440_46�Ή�
 *  2008/06/04    1.3 Yasuhisa Yamamoto �����e�X�g�s����O#440_54
 *  2008/06/19    1.4   Kazuo Kumamoto  �����e�X�g���r���[�w�E����#18�Ή�
 *  2008/07/02    1.5   Satoshi Yunba   �֑������u'�v�u"�v�u<�v�u>�v�u&�v�Ή�
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
     ,iv_date_from          IN     VARCHAR2         -- 01 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 02 : �o�ɓ�To
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_dept_code          IN     VARCHAR2         -- 04 : �S������
     ,iv_vendor_code_01     IN     VARCHAR2         -- 05 : �����P
     ,iv_vendor_code_02     IN     VARCHAR2         -- 06 : �����Q
     ,iv_vendor_code_03     IN     VARCHAR2         -- 07 : �����R
     ,iv_vendor_code_04     IN     VARCHAR2         -- 08 : �����S
     ,iv_vendor_code_05     IN     VARCHAR2         -- 09 : �����T
     ,iv_item_div           IN     VARCHAR2         -- 10 : �i�ڋ敪
     ,iv_crowd_code_01      IN     VARCHAR2         -- 11 : �Q�P
     ,iv_crowd_code_02      IN     VARCHAR2         -- 12 : �Q�Q
     ,iv_crowd_code_03      IN     VARCHAR2         -- 13 : �Q�R
     ,iv_item_code_01       IN     VARCHAR2         -- 14 : �i�ڂP
     ,iv_item_code_02       IN     VARCHAR2         -- 15 : �i�ڂQ
     ,iv_item_code_03       IN     VARCHAR2         -- 16 : �i�ڂR
     ,iv_security_div       IN     VARCHAR2         -- 17 : �L���Z�L�����e�B�敪
    ) ;
--
END xxpo440005c ;
/
