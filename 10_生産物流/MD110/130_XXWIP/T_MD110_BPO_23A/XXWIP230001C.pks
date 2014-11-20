create or replace
PACKAGE xxwip230001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007. All rights reserved.
 *
 * Package Name     : xxwip230001c(spec)
 * Description      : ���Y���[�@�\�i���Y�˗��������Y�w�}���j
 * MD.050/070       : ���Y���[�@�\�i���Y�˗��������Y�w�}���jIssue1.0  (T_MD050_BPO_230)
 *                    ���Y���[�@�\�i���Y�˗��������Y�w�}���j          (T_MD070_BPO_23A)
 * Version          : 1.7
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2007/12/13    1.0   Masakazu Yamashita  �V�K�쐬
 *  2008/05/20    1.1   Yusuke   Tabata     �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/05/20    1.2   Daisuke  Nihei      �����e�X�g�s��Ή��i���ށF�˗������\������Ȃ��j
 *  2008/05/30    1.3   Daisuke  Nihei      �����e�X�g�s��Ή��i�����F�\��敪�s��)
 *  2008/06/04    1.4   Daisuke  Nihei      �����e�X�g�s��Ή��i���Y�w�����\���s��)
 *  2008/07/02    1.5   Satoshi  Yunba      �֑������Ή�
 *  2008/07/18    1.6   Hitomi   Itou       �����e�X�g �w�E23�Ή� ���Y�˗����̎��A�ۗ����E��z�ς��ΏۂƂ���
 *  2008/07/18    1.7   Daisuke  Nihei      ������Q#183�Ή� ���͓����̌�������쐬������X�V���ɕύX����
 *                                          ������Q#196�Ή� ��x�������ĂĂ���i�ڂ̃f�t�H���g���b�g��\�����Ȃ�
 *                                          T_TE080_BPO_230 No15�Ή� ���Y�w�}���̎��A��z�ς��ΏۂƂ���
 *                                          ������Q#499�Ή� �������A�݌ɓ����̎Q�Ɛ�ύX
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
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : �`�[�敪
     ,iv_chohyo_kbn         IN     VARCHAR2         -- 02 : ���[�敪
     ,iv_plant              IN     VARCHAR2         -- 03 : �v�����g
     ,iv_line_no            IN     VARCHAR2         -- 04 : ���C��No
     ,iv_make_plan_from     IN     VARCHAR2         -- 05 : ���Y�\���(FROM)
     ,iv_make_plan_to       IN     VARCHAR2         -- 06 : ���Y�\���(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 07 : ��zNo(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 08 : ��zNo(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 09 : �i�ڃR�[�h
     ,iv_input_date_from    IN     VARCHAR2         -- 10 : ���͓���(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 11 : ���͓���(TO)
    ) ;
END xxwip230001c;
/
