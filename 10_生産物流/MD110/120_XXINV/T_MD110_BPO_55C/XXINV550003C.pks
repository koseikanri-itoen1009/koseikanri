CREATE OR REPLACE PACKAGE XXINV550003C
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV550003C(spec)
 * Description      : �v��E�ړ��E�݌ɁF�݌�(���[)
 * MD.050/070       : T_MD050_BPO_550_�݌�(���[)Issue1.0 (T_MD050_BPO_550)
 *                  : �U�֖��ו\                         (T_MD070_BPO_55C)
 * Version          : 1.23
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
 *  2008/2/18     1.0  Yusuke Tabata    �V�K�쐬
 *  2008/5/01     1.1  Yusuke Tabata    �ύX�v���Ή�
 *  2008/6/03     1.2  Takao Ohashi     �����e�X�g�s�
 *  2008/6/06     1.3  Takao Ohashi     �����e�X�g�s�
 *  2008/6/17     1.4  Kazuo Kumamoto   �����e�X�g�s�(�\�[�g���ύX�E��������̓`�[�͐�ɏo��)
 *  2008/07/02    1.5  Satoshi Yunba    �֑������Ή�
 *  2008/09/26    1.6  Akiyosi Shiina   T_S_528�Ή�
 *  2008/10/16    1.7  Takao Ohashi     T_S_492,T_S_557,T_S_494�Ή�
 *  2008/11/11    1.8  Takao Ohashi     �w�E549�Ή�
 *  2008/11/20    1.9  Takao Ohashi     �w�E691�Ή�
 *  2008/11/28    1.10 Akiyosi Shiina   �{��#227�Ή�
 *  2008/12/06    1.11 Takahito Miyata  �{��#521�Ή�
 *  2008/12/10    1.12 Takao Ohashi     �{��#639�Ή�
 *  2008/12/16    1.13 Naoki Fukuda     �{��#639�Ή�
 *  2008/12/26    1.14 Takao Ohashi     �{��#809,867�Ή�
 *  2009/01/09    1.15 Takao Ohashi     I_S_50�Ή�(����S�폜)
 *  2009/01/15    1.16 Natsuki Yoshida  I_S_50�Ή�(���[�^�C�g���Ή�)�A�{��#972
 *  2009/01/16    1.17 Takao Ohashi     I_S_50�Ή�(�\���敪�l�C��)
 *  2009/01/20    1.18 Akiyoshi Shiina  �{��#263�Ή�
 *  2009/03/06    1.19 H.Itou           �{��#1283�Ή�
 *  2009/03/12    1.20 Akiyoshi Shiina  �{��#1296�Ή�
 *  2009/03/17    1.21 Akiyoshi Shiina  �{��#1325�Ή�
 *  2009/05/12    1.22 M.Nomura         �{��#1468�Ή�
 *  2009/06/25    1.23 Marushita        �{��#1346�Ή�
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
      errbuf                  OUT    VARCHAR2     -- �G���[���b�Z�[�W
     ,retcode                 OUT    VARCHAR2     -- �G���[�R�[�h
     ,iv_target_class         IN     VARCHAR2     -- 01 : �\���敪
     ,iv_date_from            IN     VARCHAR2     -- 02 : �N����_FROM
     ,iv_date_to              IN     VARCHAR2     -- 03 : �N����_TO
     ,iv_out_item_ctl         IN     VARCHAR2     -- 04 : ���o�i�ڋ敪
     ,iv_item1                IN     VARCHAR2     -- 05 : �i��ID1
     ,iv_item2                IN     VARCHAR2     -- 06 : �i��ID2
     ,iv_item3                IN     VARCHAR2     -- 07 : �i��ID3
     ,iv_reason_code          IN     VARCHAR2     -- 08 : ���R�R�[�h
     ,iv_item_location_id     IN     VARCHAR2     -- 09 : �ۊǑq��ID
     ,iv_dept_id              IN     VARCHAR2     -- 10 : �S������ID
     ,iv_entry_no1            IN     VARCHAR2     -- 11 : �`�[No1
     ,iv_entry_no2            IN     VARCHAR2     -- 12 : �`�[No2
     ,iv_entry_no3            IN     VARCHAR2     -- 13 : �`�[No3
     ,iv_entry_no4            IN     VARCHAR2     -- 14 : �`�[No4
     ,iv_entry_no5            IN     VARCHAR2     -- 15 : �`�[No5
     ,iv_price_ctl_flg        IN     VARCHAR2     -- 16 : ���z�\��
     ,iv_emp_no               IN     VARCHAR2     -- 17 : �S����
     ,iv_creation_date_from   IN     VARCHAR2     -- 18 : �X�V����FROM
     ,iv_creation_date_to     IN     VARCHAR2     -- 19 : �X�V����TO
     
    ) ;
END XXINV550003C ;
/
