CREATE OR REPLACE PACKAGE xxpo440004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo440004(spec)
 * Description      : ���o�ɍ��ٖ��ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_444)
 *                    �L���x�����[Issue1.0(T_MD070_BPO_44L)
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
 *  2008/03/18    1.0   Yusuke Tabata    �V�K�쐬
 *  2008/05/20    1.1   Yusuke Tabata    �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/05/28    1.2   Yusuke Tabata    �����s��Ή�(�o�׎��ьv��ς̃R�[�h���)
 *  2008/07/01    1.3   Oracle �Ŗ�      �����ύX�v��142
 *  2009/12/14    1.4   SCS    �g�� ���� E_�{�ғ�_00430�Ή�
 *  2009/12/15    1.5   SCS    �g�� ���� E_�{�ғ�_00430�Ή�
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
     ,iv_diff_reason_code   IN     VARCHAR2         -- 01 : ���َ��R
     ,iv_deliver_from_code  IN     VARCHAR2         -- 02 : �o�ɑq��
     ,iv_prod_div           IN     VARCHAR2         -- 03 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 04 : �i�ڋ敪
     ,iv_date_from          IN     VARCHAR2         -- 05 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 06 : �o�ɓ�To
     ,iv_dlv_vend_code      IN     VARCHAR2         -- 07 : �z����
     ,iv_request_no         IN     VARCHAR2         -- 08 : �˗�No
     ,iv_item_code          IN     VARCHAR2         -- 09 : �i��
     ,iv_dept_code          IN     VARCHAR2         -- 10 : �S������
     ,iv_security_div       IN     VARCHAR2         -- 11 : �L���Z�L�����e�B�敪
    ) ;
--
END xxpo440004c ;
/
