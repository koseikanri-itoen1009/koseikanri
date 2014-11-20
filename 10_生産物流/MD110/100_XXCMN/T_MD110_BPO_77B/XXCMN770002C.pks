CREATE OR REPLACE PACKAGE xxcmn770002c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770002C(spec)
 * Description      : �󕥎c���\�i�T�j���i
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77B)
 * Version          : 1.6
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
 *  2008/04/08    1.0   T.Hokama         �V�K�쐬
 *  2008/05/15    1.1   T.Endou          �s�ID11,13�Ή�
 *                                       11 ���̓p���A������yyyym�Ή�
 *                                       13 �w�b�_�[�����̍ő啶���������̕ύX
 *  2008/05/30    1.2   R.Tomoyose       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *  2008/06/12    1.3   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜�B
 *                                       ����敪�� = �d����ԕi�͕��o�����o�͈ʒu�͎���̕�����
 *                                       �o�͂���B
 *  2008/06/24    1.4   T.Endou          ���ʁE���z���ڂ�NULL�ł�0�o�͂���B
 *                                       ���ʁE���z�̊Ԃ��l�߂�B
 *  2008/06/25    1.5   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/05    1.6   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma02_v�v
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
      errbuf                OUT    VARCHAR2         --   �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         --   �G���[�R�[�h
     ,iv_exec_year_month    IN     VARCHAR2         --   01 : �����N��
     ,iv_goods_class        IN     VARCHAR2         --   02 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   03 : �i�ڋ敪
     ,iv_print_kind         IN     VARCHAR2         --   04 : ���[���
     ,iv_locat_code         IN     VARCHAR2         --   05 : �q�ɃR�[�h
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : �Q���
     ,iv_crowd_code         IN     VARCHAR2         --   07 : �Q�R�[�h
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : �o���Q�R�[�h
    ) ;
END xxcmn770002c ;
/
