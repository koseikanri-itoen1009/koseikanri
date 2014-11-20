CREATE OR REPLACE PACKAGE xxpo360005c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360005C(spec)
 * Description      : ��s�������i���[�j
 * MD.050/070       : �d���i���[�jIssue1.0  (T_MD050_BPO_360)
 *                    ��s������            (T_MD070_BPO_36F)
 * Version          : 1.15
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
 *  2008/04/04    1.0   T.Endou          �V�K�쐬
 *  2008/05/09    1.1   T.Endou          �����Ȃ��d����ԕi�f�[�^�����o����Ȃ��Ή�
 *  2008/05/13    1.2   T.Endou          OPM�i�ڏ��VIEW�Q�Ƃ��폜
 *  2008/05/13    1.3   T.Endou          �����Ȃ��d����ԕi�̂Ƃ��Ɏg�p����P�����s��
 *                                       �u�P���v����u������P���v�ɏC��
 *  2008/05/14    1.4   T.Endou          �Z�L�����e�B�v���s��Ή�
 *  2008/05/23    1.5   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/26    1.6   T.Endou          ��������d����ԕi�̏ꍇ�́A�ȉ����g�p����C��
 *                                       1.�ԕi�A�h�I��.������P��
 *                                       2.�ԕi�A�h�I��.�a������K���z
 *                                       3.�ԕi�A�h�I��.���ۋ��z
 *  2008/05/26    1.7   T.Endou          �O���q�Ƀ��[�U�[�̃Z�L�����e�B�͕s�v�Ȃ��ߍ폜
 *  2008/06/25    1.8   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/10/22    1.9   I.Higa           �����̎擾���ڂ��s���i�d���於�ː������j
 *  2008/10/24    1.10  T.Ohashi         T_S_432�Ή��i�h�̂̕t�^�j
 *  2008/11/04    1.11  Y.Yamamoto       ������Q#471
 *  2008/11/28    1.12  T.Yoshimoto      �{�ԏ�Q#204
 *  2009/01/08    1.13  N.Yoshida        �{�ԏ�Q#970
 *  2009/03/30    1.14  A.Shiina         �{�ԏ�Q#1346
 *  2009/05/26    1.15  T.Yoshimoto      �{�ԏ�Q#1478
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
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_deliver_from       IN     VARCHAR2         -- �[����FROM
     ,iv_deliver_to         IN     VARCHAR2         -- �[����TO
     ,iv_vendor_code1       IN     VARCHAR2         -- �����P
     ,iv_vendor_code2       IN     VARCHAR2         -- �����Q
     ,iv_vendor_code3       IN     VARCHAR2         -- �����R
     ,iv_vendor_code4       IN     VARCHAR2         -- �����S
     ,iv_vendor_code5       IN     VARCHAR2         -- �����T
     ,iv_assen_vendor_code1 IN     VARCHAR2         -- �����҂P
     ,iv_assen_vendor_code2 IN     VARCHAR2         -- �����҂Q
     ,iv_assen_vendor_code3 IN     VARCHAR2         -- �����҂R
     ,iv_assen_vendor_code4 IN     VARCHAR2         -- �����҂S
     ,iv_assen_vendor_code5 IN     VARCHAR2         -- �����҂T
     ,iv_dept_code1         IN     VARCHAR2         -- �S�������P
     ,iv_dept_code2         IN     VARCHAR2         -- �S�������Q
     ,iv_dept_code3         IN     VARCHAR2         -- �S�������R
     ,iv_dept_code4         IN     VARCHAR2         -- �S�������S
     ,iv_dept_code5         IN     VARCHAR2         -- �S�������T
     ,iv_security_flg       IN     VARCHAR2         -- �Z�L�����e�B�敪
    ) ;
END xxpo360005c ;
/
