CREATE OR REPLACE PACKAGE xxcmn770008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770008c(spec)
 * Description      : �ԕi�����������ٕ\
 * MD.050/070       : �����Y�؏����i�o���jIssue1.0(T_MD050_BPO_770)
 *                    �ԕi�����������ٕ\Draft1A(T_MD070_BPO_77H)
 * Version          : 1.5
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
 *  2008/04/14    1.0   T.Ikehara        �V�K�쐬
 *  2008/05/15    1.1   T.Ikehara        �����N���p��YYYYM���͑Ή�
 *                                       �S�������A�S���Җ��̍ő咷�������C��
 *  2008/06/03    1.2   T.Endou          �S�������܂��͒S���Җ������擾���͐���I���ɏC��
 *  2008/06/10    1.3   T.Ikehara        �����i�Ɛ��i�̃��C���^�C�v���C��
 *  2008/06/13    1.4   T.Ikehara        ���Y�����ڍ�(�A�h�I��)�̌������s�v�̈׍폜
 *  2008/06/19    1.5   Y.Ishikawa       ���z�A���ʂ�NULL�̏ꍇ��0��\������B
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
      errbuf                  OUT    VARCHAR2    -- �G���[���b�Z�[�W
     ,retcode                 OUT    VARCHAR2    -- �G���[�R�[�h
     ,iv_proc_date            IN     VARCHAR2    -- 01 : �����N��
     ,iv_product_class        IN     VARCHAR2    -- 02 : ���i�敪
     ,iv_item_class           IN     VARCHAR2    -- 03 : �i�ڋ敪
     ,iv_rcv_pay_div          IN     VARCHAR2);  -- 04 : �󕥋敪
  END xxcmn770008c;
/
