CREATE OR REPLACE PACKAGE xxcmn770009c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770009C(spec)
 * Description      : ������U�֌������ٕ\
 * MD.050/070       : �����Y�؏������[Issue1.0(T_MD050_BPO_770)
 *                  : �����Y�؏������[Issue1.0(T_MD070_BPO_77I)
 * Version          : 1.9
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
 *  2008/04/19    1.0   M.Hamamoto       �V�K�쐬
 *  2008/05/16    1.1   M.Hamamoto       �p�����[�^�F�����N����YYYYM�œ��͂����ƃG���[�ɂȂ�
 *                                       �_���C���B
 *                                       ���[�ɏo�͂���Ă���̂́A�p�����[�^�̏����N���݂̂�
 *                                       ���̓p�����[�^��200804�ł͂Ȃ��A20084�Ƃ���Ɛ���ɒ��o
 *                                       ����邪�A�w�b�_�̏����N�������[�o�͎��ɏ����fYYYY/MM
 *                                       �f�֕ϊ������悤�C���B
 *  2008/05/31    1.2   M.Hamamoto       �����擾���@���C���B
 *  2008/06/19    1.3   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
 *  2008/06/25    1.4   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/23    1.5   Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V��XXCMN_ITEM_CATEGORIES6_V�ύX
 *  2008/08/07    1.6   R.Tomoyose       �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma09_v�v
 *  2008/08/27    1.7   A.Shiina         T_TE080_BPO_770 �w�E18�Ή�
 *  2008/10/14    1.8   N.Yoshida        T_S_524�Ή�(PT�Ή�)
 *  2008/10/28    1.9   T.Ohashi         T_S_524�Ή�(PT�Ή�)�đΉ�
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
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  -- �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  -- �����N��TO
     ,iv_prod_div        IN    VARCHAR2  -- ���i�敪
     ,iv_item_div        IN    VARCHAR2  -- �i�ڋ敪
     ,iv_rcv_pay_div     IN    VARCHAR2  -- �󕥋敪
     ,iv_crowd_type      IN    VARCHAR2  -- �W�v���
     ,iv_crowd_code      IN    VARCHAR2  -- �Q�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  -- �o���Q�R�[�h
    );
--
END xxcmn770009c;
/
