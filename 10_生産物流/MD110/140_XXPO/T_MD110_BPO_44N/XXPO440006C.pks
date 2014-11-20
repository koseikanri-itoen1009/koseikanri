CREATE OR REPLACE PACKAGE xxpo440006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440006(spec)
 * Description      : �����w����
 * MD.050/070       : �����w����(T_MD050_BPO_444)
 *                    �����w����(T_MD070_BPO_44N)
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
 *  2008/04/21    1.0   Yusuke Tabata    �V�K�쐬
 *  2008/05/20    1.1   Yusuke Tabata   �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/06/03    1.2   Yohei  Takayama �����e�X�g�s����O#440_47
 *  2008/06/04    1.3 Yasuhisa Yamamoto �����e�X�g�s����O#440_48,#440_55
 *  2008/06/07    1.4   Yohei  Takayama �����e�X�g�s����O#440_67
 *  2008/07/02    1.5   Satoshi Yunba      �֑������Ή�
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
      errbuf                 OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode                OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_vendor_code         IN     VARCHAR2         -- 01 : �����
     ,iv_deliver_to_code     IN     VARCHAR2         -- 02 : �z����
     ,iv_design_item_code_01 IN     VARCHAR2         -- 03 : �����i�ڂP
     ,iv_design_item_code_02 IN     VARCHAR2         -- 04 : �����i�ڂQ
     ,iv_design_item_code_03 IN     VARCHAR2         -- 05 : �����i�ڂR
     ,iv_date_from           IN     VARCHAR2         -- 06 : �o�ɓ�From
     ,iv_date_to             IN     VARCHAR2         -- 07 : �o�ɓ�To
     ,iv_design_no           IN     VARCHAR2         -- 08 : �����ԍ�
     ,iv_security_div        IN     VARCHAR2         -- 09 : �L���Z�L�����e�B�敪
    ) ;
--
END xxpo440006c ;
/
