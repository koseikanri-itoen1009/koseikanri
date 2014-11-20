CREATE OR REPLACE
PACKAGE xxwip230002c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwip230002(spec)
 * Description      : ���Y���[�@�\�i���Y����j
 * MD.050/070       : ���Y���[�@�\�i���Y����jIssue1.0  (T_MD050_BPO_230)
 *                    ���Y���[�@�\�i���Y����j          (T_MD070_BPO_23B)
 * Version          : 1.9
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
 *  2008/02/06    1.0   Ryouhei Fujii       �V�K�쐬
 *  2008/05/20    1.1   Yusuke  Tabata      �����ύX�v��(Seq95)���t�^�p�����[�^�^�ϊ��Ή�
 *  2008/05/29    1.2   Ryouhei Fujii       �����e�X�g�s��Ή��@NET���Z�p�^�[����Q
 *  2008/06/04    1.3   Daisuke Nihei       �����e�X�g�s��Ή��@�؁^�v���v�Z���s���Ή�
 *                                          �����e�X�g�s��Ή��@�p�[�Z���g�v�Z���s���Ή�
 *  2008/07/02    1.4   Satoshi Yunba       �֑������Ή�
 *  2008/10/08    1.5   Daisuke  Nihei      T_TE080_BPO_230 No15�Ή� ���͓����̌�������쐬������X�V���ɕύX����
 *  2008/12/02    1.6   Daisuke  Nihei      �{�ԏ�Q#325�Ή�
 *  2008/12/17    1.7   Daisuke  Nihei      �{�ԏ�Q#709�Ή�
 *  2008/12/24    1.8   Akiyoshi Shiina     �{�ԏ�Q#849,#823�Ή�
 *  2008/12/25    1.9   Akiyoshi Shiina     �{�ԏ�Q#823�đΉ�
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : �`�[�敪
     ,iv_plant              IN     VARCHAR2         -- 02 : �v�����g
     ,iv_line_no            IN     VARCHAR2         -- 03 : ���C��No
     ,iv_make_date_from     IN     VARCHAR2         -- 04 : ���Y��(FROM)
     ,iv_make_date_to       IN     VARCHAR2         -- 05 : ���Y��(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 06 : ��zNo(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 07 : ��zNo(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 08 : �i�ڃR�[�h
     ,iv_input_date_from    IN     VARCHAR2         -- 09 : ���͓���(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 10 : ���͓���(TO)
  );
END xxwip230002c;
/