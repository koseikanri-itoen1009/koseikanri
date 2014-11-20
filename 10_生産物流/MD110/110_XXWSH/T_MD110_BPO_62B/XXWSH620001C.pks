CREATE OR REPLACE PACKAGE xxwsh620001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620001c(spec)
 * Description      : �݌ɕs���m�F���X�g
 * MD.050           : ����/�z��(���[) T_MD050_BPO_620
 * MD.070           : �݌ɕs���m�F���X�g T_MD070_BPO_62B
 * Version          : 1.7
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -----------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -----------------------------------------------
 *  2008/05/05    1.0   Nozomi Kashiwagi   �V�K�쐬
 *  2008/07/08    1.1   Akiyoshi Shiina    �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/09/26    1.2   Hitomi Itou        T_TE080_BPO_600 �w�E38
 *                                         T_TE080_BPO_600 �w�E37
 *                                         T_S_533(PT�Ή�)
 *  2008/10/03    1.3   Hitomi Itou        T_TE080_BPO_600 �w�E37 �݌ɕs���̏ꍇ�A�˗����ɂ͕s������\������
 *  2008/11/13    1.4   Tsuyoki Yoshimoto  �����ύX#168
 *  2008/12/10    1.5   T.Miyata           �{��#637 �p�t�H�[�}���X�Ή�
 *  2008/12/10    1.6   Hitomi Itou        �{�ԏ�Q#650
 *  2009/01/07    1.7   Akiyoshi Shiina    �{�ԏ�Q#873
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1)
                          );
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY BINARY_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf                 OUT    VARCHAR2      -- �G���[���b�Z�[�W
    ,retcode                OUT    VARCHAR2      -- �G���[�R�[�h
    ,iv_block1              IN     VARCHAR2      -- 01:�u���b�N1
    ,iv_block2              IN     VARCHAR2      -- 02:�u���b�N2
    ,iv_block3              IN     VARCHAR2      -- 03:�u���b�N3
    ,iv_tighten_date        IN     VARCHAR2      -- 04:���ߎ��{��
    ,iv_tighten_time_from   IN     VARCHAR2      -- 05:���ߎ��{����From
    ,iv_tighten_time_to     IN     VARCHAR2      -- 06:���ߎ��{����To
    ,iv_shipped_cd          IN     VARCHAR2      -- 07:�o�Ɍ�
    ,iv_item_cd             IN     VARCHAR2      -- 08:�i��
    ,iv_shipped_date_from   IN     VARCHAR2      -- 09:�o�ɓ�From
    ,iv_shipped_date_to     IN     VARCHAR2      -- 10:�o�ɓ�To
  );
END xxwsh620001c;
/
