CREATE OR REPLACE PACKAGE xxwsh620006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620006c(spec)
 * Description      : �o�ɒ����\
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �o�ɒ����\ T_MD070_BPO_62H
 * Version          : 1.4
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
 *  2008/04/18    1.0   Nozomi Kashiwagi �V�K�쐬
 *  2008/06/04    1.1   Jun Nakada       �N�C�b�N�R�[�h�x���敪�̌������O�������ɕύX(�o�׈ړ�)
 *  2008/06/20    1.2   Y.Shindo         �z���敪���VIEW2�̌������O�������ɕύX
 *  2008/07/03    1.3   Akiyoshi Shiina  �ύX�v���Ή�#92
 *                                       �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/10    1.4   Naoki Fukuda     �ړ��̊��Z�P�ʕs��Ή�
 *  2008/07/16    1.5   Kazuo Kumamoto   �����e�X�g��Q�Ή�(�z��No���ݒ莞�͈˗�No���ɉ^���Ǝҏ����o��)
 *
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
    ,iv_concurrent_id       IN     VARCHAR2      -- 01:�R���J�����gID
    ,iv_biz_type            IN     VARCHAR2      -- 02:�Ɩ����
    ,iv_block1              IN     VARCHAR2      -- 03:�u���b�N1
    ,iv_block2              IN     VARCHAR2      -- 04:�u���b�N2
    ,iv_block3              IN     VARCHAR2      -- 05:�u���b�N3
    ,iv_shiped_code         IN     VARCHAR2      -- 06:�o�Ɍ�
    ,iv_shiped_date_from    IN     VARCHAR2      -- 07:�o�ɓ�From  ���K�{
    ,iv_shiped_date_to      IN     VARCHAR2      -- 08:�o�ɓ�To
    ,iv_shiped_form         IN     VARCHAR2      -- 09:�o�Ɍ`��
    ,iv_confirm_request     IN     VARCHAR2      -- 10:�m�F�˗�
    ,iv_warning             IN     VARCHAR2      -- 11:�x��
  );
END xxwsh620006c;
/
