CREATE OR REPLACE PACKAGE xxcmn770025c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXCMN770025(spec)
 * Description      : �d�����ѕ\�쐬
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �����Y�؏����i�o���jIssue1.0(T_MD070_BPO_77E)
 * Version          : 1.14
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
 *  2008/04/14    1.0   T.Endou          �V�K�쐬
 *  2008/05/16    1.1   T.Ikehara        �s�ID:77E-17�Ή�  �����N���p��YYYYM���͑Ή�
 *  2008/05/30    1.2   T.Endou          ���ےP���擾���@�̕ύX
 *  2008/06/24    1.3   I.Higa           �f�[�^���������ڂł��O���o�͂���
 *  2008/06/25    1.4   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/22    1.5   T.Endou          ���y�[�W���A�w�b�_���o�Ȃ��p�^�[���Ή�
 *  2008/10/14    1.6   A.Shiina         T_S_524�Ή�
 *  2008/10/28    1.7   H.Itou           T_S_524�Ή�(�đΉ�)
 *  2008/11/13    1.8   A.Shiina         �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/19    1.9   N.Yoshida        �ڍs�f�[�^���ؕs��Ή�
 *  2008/11/28    1.10  N.Yoshida        �{��#182�Ή�
 *  2008/12/04    1.11  N.Yoshida        �{��#389�Ή�
 *  2008/12/05    1.12  A.Shiina         �{��#500�Ή�
 *  2008/12/05    1.13  A.Shiina         �{��#473�Ή�
 *  2008/12/12    1.14  A.Shiina         �{��#425�Ή�
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
      iv_proc_from          IN    VARCHAR2, -- 01 : �����N��(FROM)
      iv_proc_to            IN    VARCHAR2, -- 02 : �����N��(TO)
      iv_prod_div           IN    VARCHAR2, -- 03 : ���i�敪
      iv_item_div           IN    VARCHAR2, -- 04 : �i�ڋ敪
      iv_result_post        IN    VARCHAR2, -- 05 : ���ѕ���
      iv_party_code         IN    VARCHAR2, -- 06 : �d����
      iv_crowd_type         IN    VARCHAR2, -- 07 : �Q���
      iv_crowd_code         IN    VARCHAR2, -- 08 : �Q�R�[�h
      iv_acnt_crowd_code    IN    VARCHAR2  -- 09 : �o���Q�R�[�h
    );
--
END xxcmn770025c;
/
