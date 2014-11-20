create or replace PACKAGE xxcmn770010cp
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770010CP(spec)
 * Description      : �W����������\(�v���g)
 * MD.050/070       : �����Y�؏������[Issue1.0 (T_MD050_BPO_770)
 *                    �����Y�؏������[Issue1.0 (T_MD070_BPO_77J)
 * Version          : 1.26
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
 *  2008/04/14    1.0   N.Chinen         �V�K�쐬
 *  2008/05/13    1.1   N.Chinen         ���ד��Ńf�[�^�𒊏o����悤�C���B
 *  2008/05/16    1.2   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂����ƃG���[��
 *                                       �Ȃ�_���C���B
 *  2008/06/12    1.3   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜
 *  2008/06/19    1.4   Y.Ishikawa       ����敪���p�p�A���{�Ɋւ��ẮA�󕥋敪���|���Ȃ�
 *  2008/06/19    1.5   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/23    1.7   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V��XXCMN_ITEM_CATEGORIES6_V�ύX
 *  2008/08/07    1.8   Y.Majikina       �Q�Ƃ���VIEW��XXCMN_RCV_PAY_MST_PORC_RMA_V ��
 *                                       XXCMN_RCV_PAY_MST_PORC_RMA10_V�֕ύX
 *  2008/08/28    1.9   A.Shiina         T_TE080_BPO_770 �w�E19�Ή�
 *  2008/10/23    1.10  N.Yoshida        T_S_524�Ή�(PT�Ή�)
 *  2008/11/14    1.11  N.Yoshida        �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/19    1.12  N.Yoshida        I_S_684�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/11/29    1.13  N.Yoshida        �{��#215�Ή�
 *  2008/12/02    1.14  N.Yoshida        �{�ԏ�Q�Ή�(�U�֓��ɁA�Ήc�P�A�Ήc�Q�ǉ��Ή�)
 *  2008/12/06    1.15  T.Miyata         �{��#495�Ή�
 *  2008/12/06    1.16  T.Miyata         �{��#498�Ή�
 *  2008/12/07    1.17  N.Yoshida        �{��#496�Ή�
 *  2008/12/11    1.18  A.Shiina         �{��#580�Ή�
 *  2008/12/13    1.19  T.Ohashi         �{��#580�Ή�
 *  2008/12/14    1.20  N.Yoshida        �{�ԏ�Q669�Ή�
 *  2008/12/15    1.21  N.Yoshida        �{�ԏ�Q727�Ή�
 *  2008/12/22    1.22  N.Yoshida        �{�ԏ�Q825�A828�Ή�
 *  2009/01/15    1.23  N.Yoshida        �{�ԏ�Q1023�Ή�
 *  2009/03/10    1.24  A.Shiina         �{�ԏ�Q1298�Ή�
 *  2009/04/10    1.25  A.Shiina         �{�ԏ�Q1396�Ή�
 *  2009/05/29    1.26  Marushita        �{�ԏ�Q1511�Ή�
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
     ,iv_exec_date_from     IN     VARCHAR2         --   01 : �����N��(from)
     ,iv_exec_date_to       IN     VARCHAR2         --   02 : �����N��(to)
     ,iv_goods_class        IN     VARCHAR2         --   03 : ���i�敪
     ,iv_item_class         IN     VARCHAR2         --   04 : �i�ڋ敪
     ,iv_rcv_pay_div        IN     VARCHAR2         --   05 : �󕥋敪
     ,iv_crowd_kind         IN     VARCHAR2         --   06 : �W�v���
     ,iv_crowd_code         IN     VARCHAR2         --   07 : �Q�R�[�h
     ,iv_acct_crowd_code    IN     VARCHAR2         --   08 : �o���Q�R�[�h
    );
END xxcmn770010cp;
/
