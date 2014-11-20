CREATE OR REPLACE PACKAGE xxinv550001c 
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxinv550001c(spec)
 * Description      : �݌Ɂi���[�j
 * MD.050/070       : �݌Ɂi���[�jIssue1.0  (T_MD050_BPO_550)
 *                    �󕥎c�����X�g        (T_MD070_BPO_55A)
 * Version          : 1.26
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------ -------------------------------------------------
 *  Date          Ver.  Editor             Description
 * ------------- ----- ------------------ -------------------------------------------------
 *  2008/02/01    1.0   Yasuhisa Yamamoto  �V�K�쐬
 *  2008/05/07    1.1   Yasuhisa Yamamoto  �ύX�v���Ή�(Seq83)
 *  2008/05/09    1.2   Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(���o�f�[�^�L���كf�[�^���Ή�)
 *  2008/05/09    1.3   Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(�I�����ʃe�[�u��LotID NULL�Ή�)
 *  2008/05/20    1.4   Yusuke   Tabata    �����ύX�v��(Seq95)���t�^�p�����[�^�^�ϊ��Ή�
 *  2008/05/20    1.5   Kazuo Kumamoto     �����e�X�g��Q�Ή�(�i�ڌ����}�X�^���o�^�Ή�)
 *  2008/05/20    1.6   Kazuo Kumamoto     �����e�X�g��Q�Ή�(�I���X�i�b�v�V���b�g��O�L���b�`)
 *  2008/05/21    1.7   Kazuo Kumamoto     �����e�X�g��Q�Ή�(���v����ALL0�͏��O)
 *  2008/05/21    1.8   Kazuo Kumamoto     �����e�X�g��Q�Ή�(���I�����݌ɐ��̎Z�o�s�)
 *  2008/05/26    1.9   Kazuo Kumamoto     �����e�X�g��Q�Ή�(�P�ʏo�͂̃Y��)
 *  2008/05/26    1.10  Kazuo Kumamoto     �����e�X�g��Q�Ή�(�i�ڌv�o�͏����ύX)
 *  2008/06/07    1.11  Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(���o�f�[�^�s���Ή�)
 *  2008/06/20    1.12  Kazuo Kumamoto     �V�X�e���e�X�g��Q�Ή�(�p�����[�^�����w��̕s�)
 *  2008/07/02    1.13  Satoshi Yunba      �֑������Ή�
 *  2008/07/08    1.14  Yasuhisa Yamamoto  �����e�X�g��Q�Ή�(ADJI����ID��NULL�Ή��A���o�ɐ���0�̏o�͑Ή�)
 *  2008/08/28    1.15  Oracle �R�� ��_   PT 2_1_12 #33,T_S_503�Ή�
 *  2008/09/05    1.16  Yasuhisa Yamamoto  PT 2_1_12 �ĉ��C
 *  2008/09/17    1.17  Yasuhisa Yamamoto  PT 2_1_12 #63
 *  2008/09/19    1.18  Yasuhisa Yamamoto  T_TE080_BPO_550 #32#33,T_S_466,�ύX#171
 *  2008/09/22    1.19  Yasuhisa Yamamoto  PT 2_1_12 #63 �ĉ��C
 *  2008/10/02    1.20  Yasuhisa Yamamoto  PT 2-1_12 #85
 *  2008/10/22    1.21  Yasuhisa Yamamoto  �d�l�s����Q T_S_492
 *  2008/11/10    1.22  Yasuhisa Yamamoto  �����w�E #536�A#547�Ή�
 *  2008/11/17    1.23  Yasuhisa Yamamoto  �����w�E #659�Ή�
 *  2008/12/02    1.24  Yasuhisa Yamamoto  �{�Ԏw�E #321�Ή�
 *  2008/12/04    1.25  Hitomi Itou        �{�Ԏw�E #362�Ή�
 *  2008/12/07    1.26  Natsuki Yoshida    �{�Ԏw�E #520�Ή�
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
     ,iv_date_ym            IN     VARCHAR2         -- 01 : �Ώ۔N��
     ,iv_whse_dept1         IN     VARCHAR2         -- 02 : �q�ɊǗ�����1
     ,iv_whse_dept2         IN     VARCHAR2         -- 03 : �q�ɊǗ�����2
     ,iv_whse_dept3         IN     VARCHAR2         -- 04 : �q�ɊǗ�����3
     ,iv_whse_code1         IN     VARCHAR2         -- 05 : �q�ɃR�[�h1
     ,iv_whse_code2         IN     VARCHAR2         -- 06 : �q�ɃR�[�h2
     ,iv_whse_code3         IN     VARCHAR2         -- 07 : �q�ɃR�[�h3
     ,iv_block_code1        IN     VARCHAR2         -- 08 : �u���b�N1
     ,iv_block_code2        IN     VARCHAR2         -- 09 : �u���b�N2
     ,iv_block_code3        IN     VARCHAR2         -- 10 : �u���b�N3
     ,iv_item_class         IN     VARCHAR2         -- 11 : ���i�敪
     ,iv_um_class           IN     VARCHAR2         -- 12 : �P�ʋ敪
     ,iv_item_div           IN     VARCHAR2         -- 13 : �i�ڋ敪
     ,iv_item_no1           IN     VARCHAR2         -- 14 : �i�ڃR�[�h1
     ,iv_item_no2           IN     VARCHAR2         -- 15 : �i�ڃR�[�h2
     ,iv_item_no3           IN     VARCHAR2         -- 16 : �i�ڃR�[�h3
     ,iv_create_date1       IN     VARCHAR2         -- 17 : �����N����1
     ,iv_create_date2       IN     VARCHAR2         -- 18 : �����N����2
     ,iv_create_date3       IN     VARCHAR2         -- 19 : �����N����3
     ,iv_lot_no1            IN     VARCHAR2         -- 20 : ���b�gNo1
     ,iv_lot_no2            IN     VARCHAR2         -- 21 : ���b�gNo2
     ,iv_lot_no3            IN     VARCHAR2         -- 22 : ���b�gNo3
     ,iv_output_ctl         IN     VARCHAR2         -- 23 : ���كf�[�^�敪
-- 08/09/19 Y.Yamamoto ADD v1.18 Start
     ,iv_inv_ctrl           IN     VARCHAR2         -- 24 : ���`
-- 08/09/19 Y.Yamamoto ADD v1.18 End
    ) ;
END xxinv550001c;
/
