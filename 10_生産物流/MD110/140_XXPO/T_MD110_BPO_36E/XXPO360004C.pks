CREATE OR REPLACE PACKAGE xxpo360004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : XXPO360004C(spec)
 * Description      : �d�����ו\
 * MD.050/070       : �L���x�����[Issue1.0(T_MD050_BPO_360)
 *                  : �L���x�����[Issue1.0(T_MD070_BPO_36E)
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
 *  2008/03/17    1.0   Y.Majikina       �V�K�쐬
 *  2008/05/12    1.1   Y.Majikina       ����ԕi�A�����Ȃ��ԕi���̑����v�l��
 *                                       �}�C�i�X���|����悤�C��
 *                                       �����Ȃ��d����ԕi�̏ꍇ�A����ԕi���т̊��Z������
 *                                       �擾����悤�C��
 *  2008/05/13    1.2   Y.Majikina       �i�ڂ��Ƃɕi�ڌv���\������Ȃ��_���C��
 *                                       �f�[�^�ɂ���āAYY/MM/DD�AYY/M/D�̂悤�ȏ����ŏo�͂����
 *                                       �_���C��
 *  2008/05/14    1.3   Y.Majikina       �S�������A�S���Җ��̍ő咷������ǉ�
 *                                       �Z�L�����e�B�̏������C��
 *  2008/05/23    1.4   Y.Majikina       ���ʎ擾���ڂ̕ύX�B���z�v�Z�̕s�����C��
 *  2008/05/23    1.5   Y.Majikina       �Z�L�����e�B�敪�Q�Ń��O�C�������Ƃ���SQL�G���[�ɂȂ�_��
 *                                       �C��
 *  2008/05/26    1.6   R.Tomoyose       ��������d����ԕi���A�P���͎���ԕi���уA�h�I�����擾
 *  2008/05/29    1.7   T.Ikehara        �v�̏o���׸ނ�ǉ��A�C��(ڲ��Ă̾���ݏC���Ή��̈�)
 *                                        �p�����[�^�F�S�������̍ۂ̏o�͓��e��ύX
 *  2008/06/13    1.8   Y.Ishikawa        ���b�g�R�s�[�ɂ��쐬���������̎d�����[���o�͂����
 *                                       �A�P�̖��ׂ̏�񂪂Q���ȏコ��Ȃ��悤�C���B
 *  2008/06/16    1.9   I.Higa           TEMP�̈�G���[����̂��߁Axxpo_categories_v���Q�ȏ�g�p
 *                                       ���Ȃ��悤�ɂ���
 *  2008/06/25    1.10  T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/06/25    1.11  Y.Ishikawa       �����́A����(QUANTITY)�ł͂Ȃ�����ԕi����
 *                                       (RCV_RTN_QUANTITY)���Z�b�g����
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
      iv_deliver_from       IN    VARCHAR2,  -- �[����FROM
      iv_deliver_to         IN    VARCHAR2,  -- �[����TO
      iv_item_division      IN    VARCHAR2,  -- ���i�敪
      iv_dept_code          IN    VARCHAR2,  -- �S������
      iv_vendor_code1       IN    VARCHAR2,  -- �����1
      iv_vendor_code2       IN    VARCHAR2,  -- �����2
      iv_vendor_code3       IN    VARCHAR2,  -- �����3
      iv_vendor_code4       IN    VARCHAR2,  -- �����4
      iv_vendor_code5       IN    VARCHAR2,  -- �����5
      iv_art_division       IN    VARCHAR2,  -- �i�ڋ敪
      iv_crowd1             IN    VARCHAR2,  -- �Q1
      iv_crowd2             IN    VARCHAR2,  -- �Q2
      iv_crowd3             IN    VARCHAR2,  -- �Q3
      iv_art1               IN    VARCHAR2,  -- �i��1
      iv_art2               IN    VARCHAR2,  -- �i��2
      iv_art3               IN    VARCHAR2,  -- �i��3
      iv_security_flg       IN    VARCHAR2   -- �Z�L�����e�B�敪
    );
--
END xxpo360004c;
/
