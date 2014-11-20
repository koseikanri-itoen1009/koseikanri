CREATE OR REPLACE PACKAGE xxcmn770026c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770026c(spec)
 * Description      : �o�Ɏ��ѕ\
 * MD.050/070       : �����Y����(�o��)Issue1.0 (T_MD050_BPO_770)
 *                    �����Y����(�o��)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.25
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
 *  2008/04/11    1.0   Y.Itou           �V�K�쐬
 *  2008/05/16    1.1   T.Endou          �s�ID:77F-09,10�Ή�
 *                                       77F-09 �����N���p��YYYYM���͑Ή�
 *                                       77F-10 �S�������A�S���Җ��̍ő啶���������̏C��
 *  2008/05/16    1.2   T.Endou          ���ی����擾���@�̕ύX
 *  2008/06/16    1.3   T.Endou          ����敪
 *                                        �E�L��
 *                                        �E�U�֗L��_�o��
 *                                        �E���i�U�֗L��_�o��
 *                                       �ꍇ�́A�󒍃w�b�_�A�h�I��.�����T�C�gID�ŕR�t����
 *  2008/06/24    1.4   I.Higa           �f�[�^���������ڂł��O���o�͂���
 *  2008/06/25    1.5   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/18    1.6   T.Ikehara        �o�͌����J�E���g�^�O�ǉ�
 *  2008/08/07    1.7   T.Endou          �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma26_v�v
 *  2008/09/02    1.8   A.Shiina         �d�l�s����Q#T_S_475�Ή�
 *  2008/09/22    1.9   A.Shiina         �����ύX�v��#236�Ή�
 *  2008/10/15    1.10  A.Shiina         T_S_524�Ή�
 *  2008/10/24    1.12  T.Yoshida        T_S_524�Ή�(�đΉ�2)
 *                                           �ύX�ӏ������̂��߁A�C���������c���Ă��Ȃ��̂ŁA
 *                                           �C���ӏ��m�F�̍ۂ͑OVer�ƍ�����r���邱��
 *  2008/11/12    1.13  N.Yoshida        �ڍs�f�[�^���ؕs��Ή�(�����폜)
 *  2008/12/02    1.14  A.Shiina         �{��#207�Ή�
 *  2008/12/08    1.15  N.Yoshida        �{�ԏ�Q���l���킹�Ή�(�󒍃w�b�_�̍ŐV�t���O��ǉ�)
 *  2008/12/13    1.16  A.Shiina         �{��#428�Ή�
 *  2008/12/13    1.17  N.Yoshida        �{��#428�Ή�(�đΉ�)
 *  2008/12/16    1.18  A.Shiina         �{��#749�Ή�
 *  2008/12/16    1.19  A.Shiina         �{��#754�Ή� -- �Ή��폜
 *  2008/12/17    1.20  A.Shiina         �{��#428�Ή�(PT�Ή�)
 *  2008/12/18    1.21  A.Shiina         �{��#799�Ή�
 *  2009/01/09    1.22  A.Shiina         �{��#987�Ή�
 *  2009/01/10    1.23  A.Shiina         �{��#987�Ή�(�đΉ�)
 *  2009/01/21    1.24  N.Yoshida        �{��#1016�Ή�
 *  2009/05/29    1.25  Marushita        �{�ԏ�Q1511�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
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
     ,iv_proc_from       IN    VARCHAR2  --   01 : �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : �����N��TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : �󕥋敪
     ,iv_prod_div        IN    VARCHAR2  --   04 : ���i�敪
     ,iv_item_div        IN    VARCHAR2  --   05 : �i�ڋ敪
     ,iv_result_post     IN    VARCHAR2  --   06 : ���ѕ���
     ,iv_whse_code       IN    VARCHAR2  --   07 : �q�ɃR�[�h
     ,iv_party_code      IN    VARCHAR2  --   08 : �o�א�R�[�h
     ,iv_crowd_type      IN    VARCHAR2  --   09 : �S���
     ,iv_crowd_code      IN    VARCHAR2  --   10 : �S�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : �o���Q�R�[�h
     ,iv_output_type     IN    VARCHAR2  --   12 : �o�͎��
    );
--
END xxcmn770026c;
/
