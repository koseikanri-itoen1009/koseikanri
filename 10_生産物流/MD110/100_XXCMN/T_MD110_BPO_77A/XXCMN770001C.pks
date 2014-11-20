CREATE OR REPLACE PACKAGE xxcmn770001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770001c(spec)
 * Description      : �󕥎c���\�i�T�j�����E���ށE�����i
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77A)
 * Version          : 1.29
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
 *  2008/04/02    1.0   M.Inamine        �V�K�쐬
 *  2008/05/16    1.1   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂����ƃG���[�ɂȂ�
 *                                       �_���C���B
 *                                       ���[��ʖ��́A�i�ڋ敪���́A���i�敪���́A�Q��ʖ��̂�
 *                                       �ő咷������ǉ��B
 *                                       �S�������A�S���Җ��̍ő咷������ύX�B
 *                                       (SUBSTR �� SUBSTRB)
 *  2008/05/30    1.2   R.Tomoyose       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/03    1.3   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/12    1.4   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜�B
 *                                       ����敪�� = �d����ԕi�͕��o�����o�͈ʒu�͎���̕�����
 *                                       �o�͂���B
 *  2008/06/24    1.5   T.Endou          ���ʁE���z���ڂ�NULL�ł�0�o�͂���B
 *                                       ���ʁE���z�̊Ԃ��l�߂�B
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/05    1.7   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma01_v�v
 *  2008/08/20    1.8   A.Shiina         T_TE080_BPO_770 �w�E9�Ή�
 *  2008/08/22    1.9   A.Shiina         T_TE080_BPO_770 �w�E14�Ή�
 *  2008/10/20    1.10  A.Shiina         T_S_524�Ή�
 *  2008/10/31    1.11  A.Shiina         �U��_����̎�����ʂ�+-�������C��
 *  2008/11/04    1.12  A.Shiina         �ڍs�s��C��
 *  2008/11/06    1.13  A.Shiina         ������֏C���A�U�ւ̃J�e�S���C��
 *  2008/11/06    1.14  A.Shiina         �q���g��̏C��
 *  2008/11/07    1.15  A.Shiina         �������׉��Z��IF�����C��
 *  2008/11/11    1.16  A.Shiina         �ڍs�s��C��
 *  2008/11/13    1.16  N.Fukuda         �����w�E#634�Ή�(�ڍs�f�[�^���ؕs��Ή�)
 *  2008/11/17    1.17  A.Shiina         ���񥌎���݌ɕs��C��
 *  2008/11/19    1.18  N.Yoshida        I_S_684�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/11/25    1.19  A.Shiina         �{�Ԏw�E52�Ή�
 *  2008/12/03    1.20  A.Shiina         �{�Ԏw�E361�Ή�
 *  2008/12/05    1.21  H.Maru           �{�ԏ�Q492�Ή�
 *  2008/12/08    1.22  N.Yoshida        �{�ԏ�Q���l���킹�Ή�(�󒍃w�b�_�̍ŐV�t���O��ǉ�)
 *  2008/12/08    1.23  A.Shiina         �{�ԏ�Q565�Ή�
 *  2008/12/09    1.24  H.Marushita      �{�ԏ�Q565�Ή�
 *  2008/12/10    1.25  A.Shiina         �{�ԏ�Q617,636�Ή�
 *  2008/12/11    1.26  N.Yoshida        �{�ԏ�Q580�Ή�
 *  2008/12/18    1.27  N.Yoshida        �{�ԏ�Q773�Ή�
 *  2008/12/22    1.28  N.Yoshida        �{�ԏ�Q838�Ή�
 *  2008/12/25    1.29  A.Shiina         �{�ԏ�Q674�Ή�
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
      errbuf                  OUT    VARCHAR2    -- �G���[���b�Z�[�W
     ,retcode                 OUT    VARCHAR2    -- �G���[�R�[�h
     ,iv_yyyymm               IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class        IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class           IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_report_type          IN     VARCHAR2    -- 04 : ���[���
     ,iv_whse_code            IN     VARCHAR2    -- 05 : �q�ɃR�[�h
     ,iv_group_type           IN     VARCHAR2    -- 06 : �Q���
     ,iv_group_code           IN     VARCHAR2    -- 07 : �Q�R�[�h
     ,iv_accounting_grp_code  IN     VARCHAR2);  -- 08 : �o���Q�R�[�h
END xxcmn770001c;
/