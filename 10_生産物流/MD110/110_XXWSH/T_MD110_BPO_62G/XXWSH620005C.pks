CREATE OR REPLACE PACKAGE xxwsh620005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620005c(spec)
 * Description      : ���Y�����i�o�ׁj
 * MD.050/070       : ���Y�����i�o�ׁj          (T_MD050_BPO_401)
 *                    �o�Ɏw���m�F�\            (T_MD070_BPO_40I)
 * Version          : 1.12
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- --------------------- -------------------------------------------------
 *  Date          Ver.  Editor                Description
 * ------------- ----- --------------------- -------------------------------------------------
 *  2008/05/12    1.0   Masakazu Yamashita    �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada            �N�C�b�N�R�[�h�x���敪�̌������O�������ɕύX(�o�׈ړ�)
 *  2008/06/17    1.2   Masao Hokkanji        �V�X�e���e�X�g�s�No150�Ή�
 *  2008/06/18    1.3   Kazuo Kumamoto        ���Ə����VIEW�̌������O�������ɕύX
 *  2008/06/19    1.4   SCS yamane            �z�Ԕz�����VIEW�̌������O�������ɕύX
 *  2008/07/02    1.5   Akiyoshi Shiina       �ύX�v���Ή�#92
 *                                            �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/11    1.6   Kazuo Kumamoto        �����e�X�g��Q�Ή�(�P�ʏo�͐���)
 *  2008/08/05    1.7   Yasuhisa Yamamoto     �����ύX�v���Ή�
 *  2008/09/25    1.8   Yasuhisa Yamamoto     T_TE080_BPO_620 #36,41�A�g�p�s����QT_S_479,501
 *  2008/11/14    1.9   Naoki Fukuda          �ۑ�#62(�����ύX#168)�Ή�(�w���������т����O����)
 *  2009/05/28    1.10  Hitomi Itou           �{�ԏ�Q#1398
 *  2009/09/14    1.11  Hitomi Itou           �{�ԏ�Q#1632
 *  2017/01/27    1.12  Shigeto Niki          E_�{�ғ�_14014
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
  TYPE xml_rec  IS RECORD (tag_name  VARCHAR2(50)
                          ,tag_value VARCHAR2(2000)
                          ,tag_type  CHAR(1));
--
  TYPE xml_data IS TABLE OF xml_rec INDEX BY PLS_INTEGER;
--
--################################  �Œ蕔 END   ###############################
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf                OUT    VARCHAR2
     ,retcode               OUT    VARCHAR2
     ,iv_gyoumu_kbn         IN     VARCHAR2         -- 01:�Ɩ����
     ,iv_block1             IN     VARCHAR2         -- 02:�u���b�N1
     ,iv_block2             IN     VARCHAR2         -- 03:�u���b�N2 
     ,iv_block3             IN     VARCHAR2         -- 04:�u���b�N3
     ,iv_deliver_from_code  IN     VARCHAR2         -- 05:�o�Ɍ�
     ,iv_tanto_code         IN     VARCHAR2         -- 06:�S���҃R�[�h
     ,iv_input_date         IN     VARCHAR2         -- 07:���͓��t
     ,iv_input_time_from    IN     VARCHAR2         -- 08:���͎���FROM
     ,iv_input_time_to      IN     VARCHAR2         -- 09:���͎���TO
-- v1.12 ADD Start
     ,iv_reserve_class      IN     VARCHAR2         -- 10:�蓮�̂�
-- v1.12 ADD End
  );
END xxwsh620005c;
/
