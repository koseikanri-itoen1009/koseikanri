CREATE OR REPLACE PACKAGE xxcmn770004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770004C(spec)
 * Description      : �󕥂��̑����у��X�g
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77D)
 * Version          : 1.16
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
 *  2008/04/09    1.0   C.Kinjo          �V�K�쐬
 *  2008/05/12    1.1   M.Hamamoto       ���ד��̒��o���s���Ă��Ȃ�
 *  2008/05/16    1.2   T.Endou          �s�ID:5,6,7,8�Ή�
 *                                       5 YYYYM�ł�����ɒ��o�����悤�ɏC��
 *                                       6 �w�b�_�̏o�͓��t�Ɓu�S���F�v�����킹�܂���
 *                                       7 ���[���������[ID���̉��ɂ��܂���
 *                                       8 �i�ڋ敪���́A���i�敪���̂̕����ő咷���l�����܂���
 *  2008/05/28    1.3   Y.Ishikawa       ���b�g�Ǘ��O�̏ꍇ�A���b�g����NULL���o�͂���B
 *  2008/05/30    1.4   Y.Ishikawa       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/13    1.5   T.Endou          ���ד��������ꍇ�́A�\�蒅�ד����g�p����
 *                                       ���Y�����ڍׁi�A�h�I���j��������������O��
 *  2008/06/19    1.6   Y.Ishikawa       ����敪���p�p�A���{�Ɋւ��ẮA�󕥋敪���|���Ȃ�
 *  2008/06/25    1.7   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/07    1.8   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma04_v�v
 *  2008/08/20    1.9   A.Shiina         �����w�E#14�Ή�
 *  2008/10/27    1.10  A.Shiina         T_S_524�Ή�
 *  2008/11/11    1.11  A.Shiina         �ڍs�s��C��
 *  2008/11/19    1.12  N.Yoshida        I_S_684�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/11/29    1.13  N.Yoshida        �{��#210�Ή�
 *  2008/12/03    1.14  H.Itou           �{��#384�Ή�
 *  2008/12/04    1.15  T.Miyata         �{��#454�Ή�
 *  2008/12/08    1.16  T.Ohashi         �{�ԏ�Q���l���킹�Ή�
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
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         --   02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   03 : �i�ڋ敪
     ,iv_div_type1          IN     VARCHAR2         --   04 : �󕥋敪�P
     ,iv_div_type2          IN     VARCHAR2         --   05 : �󕥋敪�Q
     ,iv_div_type3          IN     VARCHAR2         --   06 : �󕥋敪�R
     ,iv_div_type4          IN     VARCHAR2         --   07 : �󕥋敪�S
     ,iv_div_type5          IN     VARCHAR2         --   08 : �󕥋敪�T
     ,iv_reason_code        IN     VARCHAR2         --   09 : ���R�R�[�h
    ) ;
END xxcmn770004c ;
/
