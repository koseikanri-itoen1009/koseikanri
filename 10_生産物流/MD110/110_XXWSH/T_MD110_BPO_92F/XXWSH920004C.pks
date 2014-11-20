CREATE OR REPLACE PACKAGE xxwsh920004c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxwsh920004c(spec)
 * Description      : �o�׍w���˗��ꗗ
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��������jIssue1.0 (T_MD050_BPO_921)
 *                    ���Y�������ʁi�o�ׁE�ړ��������jIssue1.0 (T_MD070_BPO_92F)
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
 *  2008/03/25    1.0   Yoshitomo Kawasaki �V�K�쐬
 *  2008/06/11    1.1   Kazuo Kumamoto     �����ύX�v��#131�Ή�
 *  2008/07/08    1.2   Satoshi Yunba      �֑������Ή�
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
       errbuf                 OUT   VARCHAR2          -- �G���[���b�Z�[�W
      ,retcode                OUT   VARCHAR2          -- �G���[�R�[�h
      ,iv_delivery_dest       IN    VARCHAR2          -- 01 : �[����
      ,iv_delivery_form       IN    VARCHAR2          -- 02 : �o�Ɍ`��
      ,iv_delivery_date       IN    VARCHAR2          -- 03 : �[��
      ,iv_delivery_day_from   IN    VARCHAR2          -- 04 : �o�ɓ�From
      ,iv_delivery_day_to     IN    VARCHAR2          -- 05 : �o�ɓ�To
    ) ;
END xxwsh920004c;
/
