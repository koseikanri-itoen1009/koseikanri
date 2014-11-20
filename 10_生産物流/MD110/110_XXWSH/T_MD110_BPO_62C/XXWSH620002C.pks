CREATE OR REPLACE PACKAGE xxwsh620002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620002c(spec)
 * Description      : �o�ɔz���˗��\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_620
 * MD.070           : �o�ɔz���˗��\ T_MD070_BPO_62C
 * Version          : 1.18
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
 *  2008/04/30    1.0   Yoshitomo Kawasaki �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada       �o�͒S�������̒l���R�[�h���疼�̂ɏC���BGLOBAL�ϐ�������
 *                                       �^���˗����̖��̂� ����=>��Ж� ���� ��Ж� => �����ɏC��
 *  2008/06/12    1.2   Kazuo Kumamoto   �p�����[�^.�Ɩ���ʂɂ���Ē��o�Ώۂ�I��
 *  2008/06/18    1.3   Kazuo Kumamoto   �����e�X�g��Q�Ή�
 *                                       (�z��No���ݒ�̏ꍇ�͐��ʍ��v�A���ݏd�ʁA���ڑ̐ς��o�͂��Ȃ�)
 *  2008/06/23    1.4   Yoshikatsu Shindou �z���敪���VIEW�̃����[�V�������O�������ɕύX
 *                                         (�V�X�e���e�X�g�s�#229)
 *                                         �����敪���擾�ł��Ȃ��ꍇ,�d�ʗe�ύ��v��NULL�Ƃ���B
 *  2008/07/02    1.5   Satoshi Yunba    �֑������Ή�
 *  2008/07/04    1.6   Naoki Fukuda     ST�s��Ή�#394
 *  2008/07/04    1.7   Naoki Fukuda     ST�s��Ή�#409
 *  2008/07/07    1.8   Naoki Fukuda     ST�s��Ή�#337
 *  2008/07/09    1.9   Satoshi Takemoto �ύX�v���Ή�#92,#98
 *  2008/07/17    1.10  Kazuo Kumamoto   �����e�X�g��Q�Ή�
 *                                       1.10.1 �p�����[�^.�i�ڋ敪���w�莞�̕i�ڋ敪�����󗓂Ƃ���B
 *                                       1.10.2 �x���̔z���擙�̏��擾���ύX�B
 *                                       1.10.3 �z���悪���ڂ��Ă���ꍇ�͑S�Ă̔z������o�͂���B
 *  2008/07/17    1.11  Satoshi Takemoto �����e�X�g�s��Ή�(�ύX�v���Ή�#92,#98)
 *  2008/08/04    1.12  Takao Ohashi     �����o�׃e�X�g(�o�גǉ�_18,19,20)�C��
 *  2008/10/27    1.13  Masayoshi Uehara �����w�E297�AT_TE080_BPO_620 �w�E35�w�E45�w�E47
 *                                       T_S_501T_S_601T_S_607�AT_TE110_BPO_230-001 �w�E440
 *                                       �ۑ�#32 �P��/�������Z�̏������W�b�N
 *  2008/11/07    1.14  Y.Yamamoto       �����w�E#143�Ή�(����0�̃f�[�^��ΏۊO�Ƃ���)
 *  2008/11/13    1.15  Y.Yamamoto       �����w�E#595�Ή��A�����ύX#168
 *  2008/11/20    1.16  Y.Yamamoto       �����w�E#464�A#686�Ή�
 *  2008/11/27    1.17  A.Shiina         �{��#185�Ή�
 *  2009/01/23    1.18  N.Yoshida        �{��#765�Ή�
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
     errbuf                     OUT    VARCHAR2         --  �G���[���b�Z�[�W
    ,retcode                    OUT    VARCHAR2         --  �G���[�R�[�h
    ,iv_dept                    IN     VARCHAR2         --  01 : ����
    ,iv_plan_decide_kbn         IN     VARCHAR2         --  02 : �\��/�m��敪
    ,iv_ship_from               IN     VARCHAR2         --  03 : �o�ɓ�From
    ,iv_ship_to                 IN     VARCHAR2         --  04 : �o�ɓ�To
    ,iv_shukko_haisou_kbn       IN     VARCHAR2         --  05 : �o��/�z���敪
    ,iv_gyoumu_shubetsu         IN     VARCHAR2         --  06 : �Ɩ����
    ,iv_notif_date              IN     VARCHAR2         --  07 : �m��ʒm���{��
    ,iv_notif_time_from         IN     VARCHAR2         --  08 : �m��ʒm���{����From
    ,iv_notif_time_to           IN     VARCHAR2         --  09 : �m��ʒm���{����To
    ,iv_freight_carrier_code    IN     VARCHAR2         --  10 : �^���Ǝ�
    ,iv_block1                  IN     VARCHAR2         --  11 : �u���b�N1
    ,iv_block2                  IN     VARCHAR2         --  12 : �u���b�N2
    ,iv_block3                  IN     VARCHAR2         --  13 : �u���b�N3
    ,iv_shipped_locat_code      IN     VARCHAR2         --  14 : �o�Ɍ�
    ,iv_mov_num                 IN     VARCHAR2         --  15 : �˗�No/�ړ�No
    ,iv_shime_date              IN     VARCHAR2         --  16 : ���ߎ��{��
    ,iv_shime_time_from         IN     VARCHAR2         --  17 : ���ߎ��{����From
    ,iv_shime_time_to           IN     VARCHAR2         --  18 : ���ߎ��{����To
    ,iv_online_kbn              IN     VARCHAR2         --  19 : �I�����C���Ώۋ敪
    ,iv_item_kbn                IN     VARCHAR2         --  20 : �i�ڋ敪
    ,iv_shukko_keitai           IN     VARCHAR2         --  21 : �o�Ɍ`��
    ,iv_unsou_irai_inzi_kbn     IN     VARCHAR2         --  22 : �^���˗����󎚋敪
  );
END xxwsh620002c;
/
