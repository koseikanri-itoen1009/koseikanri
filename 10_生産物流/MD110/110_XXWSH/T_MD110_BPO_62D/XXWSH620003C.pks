CREATE OR REPLACE PACKAGE xxwsh620003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620003c(spec)
 * Description      : ���Ɉ˗��\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_620
 * MD.070           : ���Ɉ˗��\ T_MD070_BPO_62D
 * Version          : 1.9
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
 *  2008/03/13    1.0   Nozomi Kashiwagi �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada       �m�菈�������{(�ʒm����=NULL)�̏ꍇ�̏o�͐���
 *  2008/06/23    1.2   Yoshikatu Shindou �z���敪���VIEW�̃����[�V�������O�������ɕύX
 *                                         (�V�X�e���e�X�g�s�#228)
 *  2008/07/02    1.3   Satoshi Yunba    �֑������Ή�
 *  2008/07/10    1.4   Akiyoshi Shiina  �ύX�v���Ή�#92
 *  2008/07/11    1.5   Masayoshi Uehara ST�s�#441�Ή�
 *  2008/07/15    1.6   Akiyoshi Shiina  �ύX�v���Ή�#92�C��
 *  2008/08/04    1.7   Takao Ohashi     �����o�׃e�X�g(�o�גǉ�_19)�C��
 *  2008/10/06    1.8   Yuko Kawano      �����w�E#242�C��(�o�ɓ�FROM��C�ӂɕύX)
 *                                       T_S_501(�\�[�g���̕ύX)
 *  2008/10/20    1.9   Yuko Kawano      �ۑ�#32,�ύX#168�Ή�
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
     errbuf                    OUT    VARCHAR2         --   �G���[���b�Z�[�W
    ,retcode                   OUT    VARCHAR2         --   �G���[�R�[�h
    ,iv_dept                   IN     VARCHAR2         --   01 : ����
    ,iv_plan_decide_kbn        IN     VARCHAR2         --   02 : �\��/�m��敪
    ,iv_ship_from              IN     VARCHAR2         --   03 : �o�ɓ�From
    ,iv_ship_to                IN     VARCHAR2         --   04 : �o�ɓ�To
    ,iv_notif_date             IN     VARCHAR2         --   05 : �m��ʒm���{��
    ,iv_notif_time_from        IN     VARCHAR2         --   06 : �m��ʒm���{����From
    ,iv_notif_time_to          IN     VARCHAR2         --   07 : �m��ʒm���{����To
    ,iv_block1                 IN     VARCHAR2         --   08 : �u���b�N1
    ,iv_block2                 IN     VARCHAR2         --   09 : �u���b�N2
    ,iv_block3                 IN     VARCHAR2         --   10 : �u���b�N3
    ,iv_ship_to_locat_code     IN     VARCHAR2         --   11 : ���ɐ�
    ,iv_shipped_locat_code     IN     VARCHAR2         --   12 : �o�Ɍ�
    ,iv_freight_carrier_code   IN     VARCHAR2         --   13 : �^���Ǝ�
    ,iv_delivery_no            IN     VARCHAR2         --   14 : �z��No
    ,iv_mov_num                IN     VARCHAR2         --   15 : �ړ�No
    ,iv_online_kbn             IN     VARCHAR2         --   16 : �I�����C���Ώۋ敪
    ,iv_item_kbn               IN     VARCHAR2         --   17 : �i�ڋ敪
    ,iv_arrival_date_from      IN     VARCHAR2         --   18 : ����From
    ,iv_arrival_date_to        IN     VARCHAR2         --   19 : ����To
  );
END xxwsh620003c;
/
