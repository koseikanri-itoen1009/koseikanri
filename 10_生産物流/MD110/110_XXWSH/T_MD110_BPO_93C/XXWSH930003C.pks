CREATE OR REPLACE PACKAGE xxwsh930003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXWSH930003C(spec)
 * Description      : ���o�ɏ�񍷈ك��X�g�i�o�Ɋ�j
 * MD.050/070       : ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD050_BPO_930)
 *                    ���Y�������ʁi�o�ׁE�ړ��C���^�t�F�[�X�jIssue1.0(T_MD070_BPO_93C)
 * Version          : 1.11
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
 *  2008/02/19    1.0   Masayuki Ikeda   �V�K�쐬
 *  2008/06/23    1.1   Oohashi  Takao   �s����O�Ή�
 *  2008/06/25    1.2   Oohashi  Takao   �s����O�Ή�
 *  2008/06/30    1.3   Oohashi  Takao   �s����O�Ή�
 *  2008/07/02    1.4   Kawano   Yuko    ST�s��Ή�#352
 *  2008/07/07    1.5   Akiyoshi Shiina  �ύX�v���Ή�#92
 *  2008/07/08    1.5   Satoshi  Yunba   �֑������Ή�
 *  2008/07/24    1.6   Akiyoshi Shiina  ST�s�#197�A�����ۑ�#32�A�����ύX�v��#180�Ή�
 *  2008/10/10    1.7   Naoki    Fukuda  �����e�X�g��Q#338�Ή�
 *  2008/10/17    1.8   Naoki    Fukuda  �����e�X�g��Q#146�Ή�
 *  2008/10/17    1.8   Naoki    Fukuda  �ۑ�T_S_458�Ή�(������C�ӓ��̓p�����[�^�ɕύX�BPACKAGE�̏C���͂Ȃ�)
 *  2008/10/17    1.8   Naoki    Fukuda  �ύX�v��#210�Ή�
 *  2008/10/20    1.9   Naoki    Fukuda  �ۑ�T_S_486�Ή�
 *  2008/10/20    1.9   Naoki    Fukuda  �����e�X�g��Q#394(1)�Ή�
 *  2008/10/20    1.9   Naoki    Fukuda  �����e�X�g��Q#394(2)�Ή�
 *  2008/10/31    1.10  Naoki    Fukuda  �����w�E#461�Ή�
 *  2008/11/13    1.11  Naoki    Fukuda  �����w�E#603�Ή�
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
     ,iv_business_type      IN     VARCHAR2         -- 01 : �Ɩ����
     ,iv_prod_div           IN     VARCHAR2         -- 02 : ���i�敪
     ,iv_item_div           IN     VARCHAR2         -- 03 : �i�ڋ敪
     ,iv_date_from          IN     VARCHAR2         -- 04 : �o�ɓ�From
     ,iv_date_to            IN     VARCHAR2         -- 05 : �o�ɓ�To
     ,iv_dept_code          IN     VARCHAR2         -- 06 : ����
     ,iv_output_type        IN     VARCHAR2         -- 07 : �o�͋敪
     ,iv_deliver_type       IN     VARCHAR2         -- 08 : �o�Ɍ`��
     ,iv_block_01           IN     VARCHAR2         -- 09 : �u���b�N�P
     ,iv_block_02           IN     VARCHAR2         -- 10 : �u���b�N�Q
     ,iv_block_03           IN     VARCHAR2         -- 11 : �u���b�N�R
     ,iv_deliver_from       IN     VARCHAR2         -- 12 : �o�Ɍ�
     ,iv_online_type        IN     VARCHAR2         -- 13 : �I�����C���Ώۋ敪
     ,iv_request_no         IN     VARCHAR2         -- 14 : �˗�No�^�ړ�No
    ) ;
--
END xxwsh930003c ;
/
