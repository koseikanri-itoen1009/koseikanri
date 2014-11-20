CREATE OR REPLACE PACKAGE xxcmn770003c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770003C(spec)
 * Description      : �󕥎c���\�i�U�j
 * MD.050/070       : �����Y�؏������[Issue1.0(T_MD050_BPO_770)
 *                  : �����Y�؏������[Issue1.0(T_MD070_BPO_77C)
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
 *  2008/04/08    1.0   Y.Majikina       �V�K�쐬
 *  2008/05/15    1.1   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂��ꂽ���A�G���[
 *                                       �ƂȂ�_���C���B
 *                                       �S�������A�S���Җ��̍ő咷�������C���B
 *  2008/05/30    1.2   Y.Ishikawa       ���ی����𒊏o���鎞�A�����Ǘ��敪�����ی����̏ꍇ�A
 *                                       ���b�g�Ǘ��̑Ώۂ̏ꍇ�̓��b�g�ʌ����e�[�u��
 *                                       ���b�g�Ǘ��̑ΏۊO�̏ꍇ�͕W�������}�X�^�e�[�u�����擾
 *
 *  2008/06/12    1.3   I.Higa           ����敪��"�I����"�܂���"�I����"�̏ꍇ�A�}�C�i�X�f�[�^��
 *                                       �����Ă���̂Ő�Βl�v�Z���s�킸�A�ݒ�l�ŏW�v���s���B
 *  2008/06/13    1.4   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜�B
 *  2008/06/24    1.5   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/05    1.7   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma03_v�v
 *  2008/08/28    1.8   A.Shiina         ������ʂ͎擾���Ɏ󕥋敪���|����B
 *  2008/10/22    1.9   N.Yoshida        T_S_524�Ή�(PT�Ή�)
 *  2008/11/04    1.10  N.Yoshida        �ڍs���n�b��Ή�
 *  2008/11/12    1.11  N.Fukuda         �����w�E#634�Ή�(�ڍs�f�[�^���ؕs��Ή�)
 *  2008/11/19    1.12  N.Yoshida        I_S_684�Ή��A�ڍs�f�[�^���ؕs��Ή�
 *  2008/12/08    1.13  H.Marushita      �{�Ԑ��l���؎󒍃w�b�_�ŐV�t���O����ѕW�������v�Z�C��
 *  2008/12/08    1.14  A.Shiina         �{��#562�Ή�
 *  2008/12/11    1.15  N.Yoshida        �{�ԏ�Q580�Ή�
 *  2008/12/12    1.16  N.Yoshida        �{�ԏ�Q669�Ή�
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
      errbuf                OUT   VARCHAR2,  -- �G���[���b�Z�[�W
      retcode               OUT   VARCHAR2,  -- �G���[�R�[�h
      iv_process_year       IN    VARCHAR2,  -- �����N��
      iv_item_division      IN    VARCHAR2,  -- ���i�敪
      iv_art_division       IN    VARCHAR2,  -- �i�ڋ敪
      iv_report_type        IN    VARCHAR2,  -- ���|�[�g�敪
      iv_warehouse_code     IN    VARCHAR2,  -- �q�ɃR�[�h
      iv_crowd_type         IN    VARCHAR2,  -- �Q���
      iv_crowd_code         IN    VARCHAR2,  -- �Q�R�[�h
      iv_account_code       IN    VARCHAR2   -- �o���Q�R�[�h
    );
--
END xxcmn770003c;
/
