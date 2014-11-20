CREATE OR REPLACE PACKAGE xxcmn770007c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770007c(spec)
 * Description      : ���Y�������ٕ\
 * MD.050           : �L���x�����[Issue1.0(T_MD050_BPO_770)
 * MD.070           : �L���x�����[Issue1.0(T_MD070_BPO_77G)
 * Version          : 1.11
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
 *  2008/04/09    1.0   K.Kamiyoshi      �V�K�쐬
 *  2008/05/16    1.1   Y.Majikina       �p�����[�^�F�����N����YYYYM�œ��͂��ꂽ���A�G���[
 *                                       �ƂȂ�_���C���B
 *                                       �S�������A�S���Җ��̍ő咷�������C���B
 *  2008/05/30    1.2   T.Ikehara        �����擾���@�C��
 *  2008/06/03    1.3   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/12    1.4   Y.Ishikawa       ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜
 *  2008/06/24    1.5   T.Ikehara        ���ʁA���z��0�̏ꍇ�ɏo�͂����悤�ɏC��
 *  2008/06/25    1.6   T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/08/29    1.7   A.Shiina         T_TE080_BPO_770 �w�E20�Ή�
 *  2008/10/08    1.8   A.Shiina         T_S_524�Ή�
 *  2008/10/08    1.9   A.Shiina         T_S_455�Ή�
 *  2008/10/09    1.10  A.Shiina         T_S_422�Ή�
 *  2008/11/11    1.11  N.Yoshida        I_S_511�Ή��A�ڍs�f�[�^���ؕs��Ή�
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
-- 2008/10/08 v1.9 DELETE START
--     ,iv_rcv_pay_div     IN    VARCHAR2  -- �󕥋敪
-- 2008/10/08 v1.9 DELETE END
     ,iv_crowd_type      IN    VARCHAR2  -- �W�v���
     ,iv_crowd_code      IN    VARCHAR2  -- �Q�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  -- �o���Q�R�[�h
    );
--
END xxcmn770007c;
/
