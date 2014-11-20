CREATE OR REPLACE PACKAGE xxinv510001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXINV510001C(spec)
 * Description      : �ړ��`�[
 * MD.050/070       : �ړ����� T_MD050_BPO_510
 *                  : �ړ��`�[ T_MD070_BPO_51A
 * Version          : 1.8
 *
 * Program List
 * ---------------------------- ----------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------
 *  convert_into_xml            �f�[�^�ϊ������t�@���N�V����
 *  output_xml                  XML�f�[�^�o�͏����v���V�[�W��
 *  prc_create_zeroken_xml_data �擾�����O�����w�l�k�f�[�^�쐬
 *  create_xml_head             XML�f�[�^�쐬�����v���V�[�W��(�w�b�_��)
 *  create_xml_line             XML�f�[�^�쐬�����v���V�[�W��(���ו�)
 *  create_xml_sum              XML�f�[�^�쐬�����v���V�[�W��(���v��)
 *  create_xml                  XML�f�[�^�쐬�����v���V�[�W��
 *  submain                     ���C�������v���V�[�W��
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/03/05    1.0   Yuki Komikado      ����쐬
 *  2008/05/26    1.1   Kazuo Kumamoto     �����e�X�g��Q�Ή�
 *  2008/05/28    1.2   Yuko Kawano        �����e�X�g��Q�Ή�
 *  2008/05/29    1.3   Yuko Kawano        �����e�X�g��Q�Ή�
 *  2008/06/24    1.4   Yasuhisa Yamamoto  �ύX�v���Ή�#92
 *  2008/07/18    1.5   Yasuhisa Yamamoto  �����ύX�v���Ή�
 *  2008/07/29    1.6   Marushita          �֑������u'�v�u"�v�u<�v�u>�v�u���v�Ή�
 *  2008/07/30    1.7   Yuko Kawano        �����ύX�v���Ή�#164
 *  2008/11/04    1.8   Yasuhisa Yamamoto  ������Q#508,554
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
  PROCEDURE main (
    errbuf                OUT    VARCHAR2,         -- �G���[���b�Z�[�W
    retcode               OUT    VARCHAR2,         -- �G���[�R�[�h
    iv_product_class      IN     VARCHAR2,         -- 01.���i���ʋ敪
    iv_prod_class_code    IN     VARCHAR2,         -- 02.���i�敪
    iv_target_class       IN     VARCHAR2,         -- 03.�w��/���ы敪
    iv_move_no            IN     VARCHAR2,         -- 04.�ړ��ԍ�
    iv_move_instr_post_cd IN     VARCHAR2,         -- 05.�ړ��w������
    iv_ship               IN     VARCHAR2,         -- 06.�o�Ɍ�
    iv_arrival            IN     VARCHAR2,         -- 07.���ɐ�
    iv_ship_date_from     IN     VARCHAR2,         -- 08.�o�ɓ�FROM
    iv_ship_date_to       IN     VARCHAR2,         -- 09.�o�ɓ�TO
    iv_delivery_no        IN     VARCHAR2);        -- 10.�z��No.
END xxinv510001c;
/
