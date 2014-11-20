CREATE OR REPLACE PACKAGE xxwsh620008c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620008c(spec)
 * Description      : �ύ��w����
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �ύ��w���� T_MD070_BPO_62J
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
 *  2008/03/31    1.0   Yoshitomo Kawasaki �V�K�쐬
 *  2008/06/23    1.1   Yoshikatsu Shindou �z���敪���VIEW�̃����[�V�������O�������ɕύX
 *                                         �����敪��NULL�̎��̏�����ǉ�
 *  2008/07/03    1.2   Jun Nakada         ST�s��Ή�No412 �d�ʗe�ς̏������ʐ؂�グ
 *  2008/07/07    1.3   Akiyoshi Shiina    �ύX�v���Ή�#92
 *                                         �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/15    1.4   Masayoshi Uehara   �����̏�������؂�̂ĂāA�����ŕ\��
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
       errbuf                   OUT   VARCHAR2          -- �G���[���b�Z�[�W
      ,retcode                  OUT   VARCHAR2          -- �G���[�R�[�h
      ,iv_business_type         IN    VARCHAR2          -- 01 : �Ɩ����
      ,iv_block_1               IN    VARCHAR2          -- 02 : �u���b�N�P
      ,iv_block_2               IN    VARCHAR2          -- 03 : �u���b�N�Q
      ,iv_block_3               IN    VARCHAR2          -- 04 : �u���b�N�R
      ,iv_delivery_origin       IN    VARCHAR2          -- 05 : �o�Ɍ�
      ,iv_delivery_day          IN    VARCHAR2          -- 06 : �o�ɓ�
      ,iv_delivery_no           IN    VARCHAR2          -- 07 : �z����
      ,iv_delivery_form         IN    VARCHAR2          -- 08 : �o�Ɍ`��
      ,iv_jurisdiction_base     IN    VARCHAR2          -- 09 : �Ǌ����_
      ,iv_addre_delivery_dest   IN    VARCHAR2          -- 10 : �z����/���ɐ�
      ,iv_request_movement_no   IN    VARCHAR2          -- 11 : �˗���/�ړ���
      ,iv_commodity_div         IN    VARCHAR2          -- 12 : ���i�敪
    ) ;
END xxwsh620008c;
/
