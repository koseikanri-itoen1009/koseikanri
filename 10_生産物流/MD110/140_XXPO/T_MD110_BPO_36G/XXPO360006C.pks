CREATE OR REPLACE PACKAGE xxpo360006c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360006C(spec)
 * Description      : �d��������ו\
 * MD.050           : �L���x�����[Issue1.0(T_MD050_BPO_360)
 * MD.070           : �L���x�����[Issue1.0(T_MD070_BPO_36G)
 * Version          : 1.24
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
 *  2008/03/13    1.0   K.Kamiyoshi      �V�K�쐬
 *  2008/05/09    1.1   K.Kamiyoshi      �s�ID5-9�Ή�
 *  2008/05/12    1.2   K.Kamiyoshi      �s�ID10�Ή�
 *  2008/05/13    1.3   K.Kamiyoshi      �s�ID11�Ή�
 *  2008/05/13    1.4   T.Endou         (�O�����[�U�[)�����Ȃ��ԕi���A�Z�L�����e�B�v���̑Ή�
 *  2008/05/22    1.5   T.Endou          �ʏ������A�����[������.���K�敪�A���ۋ��敪���g�p����B
 *                                       �����҂͊O�������Ƃ���B
 *                                       �[�����͈͎̔w��́A���ׂĂŎ���ԕi�A�h�I�����g�p����B
 *  2008/05/23    1.6   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/24    1.7   Y.Majikina       �d���ԕi���̕������C��
 *  2008/05/26    1.8   Y.Majikina       ��������d����ԕi���A�������A������P���A�P���A
 *                                       ���K�敪�A���K�A�a����K���z�A���ۋ��敪�A���ۋ��A
 *                                       ���ۋ��z�́A����ԕi���уA�h�I�����擾����
 *  2008/05/28    1.9   Y.Majikina       ���b�`�e�L�X�g�̉��y�[�W�Z�N�V�����̕ύX�ɂ��
 *                                       XML�\���̏C��
 *  2008/05/29    1.10  T.Endou          �[�����͈͎̔w��́A���ׂĎ���ԕi�A�h�I�����g�p����
 *                                       �C���͂��Ă��������A���[�ɕ\�����镔�����C������B
 *  2008/06/03    1.11  T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/11    1.12  T.Endou          �����Ȃ��d����ԕi�̏ꍇ�A�ԕi�A�h�I���̈�����ID���g�p����
 *  2008/06/17    1.13  T.Ikehara        TEMP�̈�G���[����̂��߁Axxpo_categories_v��
 *                                       �g�p���Ȃ��悤�ɂ���
 *  2008/06/24    1.14  T.Ikehara        ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/23    1.15  Y.Ishikawa       XXCMN_ITEM_CATEGORIES3_V��XXCMN_ITEM_CATEGORIES6_V�ύX
 *  2008/11/06    1.16  Y.Yamamoto       �����w�E#471�Ή��AT_S_430�Ή�
 *  2008/12/02    1.17  H.Marushita      �{�ԏ�Q#348�Ή�
 *  2008/12/03    1.18  H.Marushita      �{�ԏ�Q#374�Ή�
 *  2008/12/05    1.19  A.Shiina         �{�ԏ�Q#499,#506�Ή�
 *  2008/12/07    1.20  N.Yoshida        �{�ԏ�Q#533�Ή�
 *  2009/01/09    1.21  N.Yoshida        �{�ԏ�Q#984�Ή�
 *  2009/03/30    1.22  A.Shiina         �{�ԏ�Q#1346�Ή�
 *  2009/04/02    1.23  A.Shiina         �{�ԏ�Q#1370�Ή�
 *  2009/04/03    1.24  A.Shiina         �{�ԏ�Q#1379�Ή�(v1.22�Ή����)
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
      errbuf                OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode               OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_out_flg            IN    VARCHAR2  --�o�͋敪
     ,iv_deliver_from       IN    VARCHAR2  --�[����FROM
     ,iv_deliver_to         IN    VARCHAR2  --�[����TO
     ,iv_dept_code1         IN    VARCHAR2  --�S�������P
     ,iv_dept_code2         IN    VARCHAR2  --�S�������Q
     ,iv_dept_code3         IN    VARCHAR2  --�S�������R
     ,iv_dept_code4         IN    VARCHAR2  --�S�������S
     ,iv_dept_code5         IN    VARCHAR2  --�S�������T
     ,iv_vendor_code1       IN    VARCHAR2  -- �����1
     ,iv_vendor_code2       IN    VARCHAR2  -- �����2
     ,iv_vendor_code3       IN    VARCHAR2  -- �����3
     ,iv_vendor_code4       IN    VARCHAR2  -- �����4
     ,iv_vendor_code5       IN    VARCHAR2  -- �����5
     ,iv_mediator_code1     IN    VARCHAR2  -- ������1
     ,iv_mediator_code2     IN    VARCHAR2  -- ������2
     ,iv_mediator_code3     IN    VARCHAR2  -- ������3
     ,iv_mediator_code4     IN    VARCHAR2  -- ������4
     ,iv_mediator_code5     IN    VARCHAR2  -- ������5
     ,iv_po_num             IN    VARCHAR2  -- �����ԍ�
     ,iv_item_code          IN    VARCHAR2  -- �i�ڃR�[�h
     ,iv_security_flg       IN    VARCHAR2  -- �Z�L�����e�B�敪
    );
--
END xxpo360006c;
/
