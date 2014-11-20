CREATE OR REPLACE PACKAGE xxpo940008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940008c(spec)
 * Description      : ���b�g�������捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : ���b�g�������捞���� T_MD070_BPO_94H
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
 *  2008/06/19    1.0  Oracle �g�c�Ď�   ����쐬
 *  2008/07/22    1.1  Oracle �g�c�Ď�   �����ۑ�#32�A#66�A�����ύX#166�Ή�
 *  2008/07/29    1.2  Oracle �g�c�Ď�   ST�s��Ή�(�̔ԂȂ�)
 *  2008/08/22    1.3  Oracle �R����_   T_TE080_BPO_940 �w�E4,�w�E5,�w�E17�Ή�
 *  2008/10/08    1.4  Oracle �ɓ��ЂƂ� �����e�X�g�w�E240�Ή�
 *  2009/02/09    1.5  Oracle �g�c �Ď�  �{��#15�A1121�Ή�
 *  2009/02/25    1.6  Oracle �g�c �Ď�  �{��#1121�Ή��đΉ�
 *  2009/04/15    1.7  SCS    �ɓ��ЂƂ� �{��#1403,1405�Ή�
 *  2009/04/17    1.8  SCS    �Ŗ� ���\  ���b�g�Ǘ��O�i�̓��b�gID��NULL�Ƃ��Ď擾
 *  2009/04/23    1.9  SCS    �Ŗ� ���\  �{��#1420�Ή�
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                    OUT VARCHAR2,              --  �G���[���b�Z�[�W #�Œ�#
    retcode                   OUT VARCHAR2,              --  �G���[�R�[�h     #�Œ�#
    iv_data_class             IN  VARCHAR2,              --  �f�[�^���
    iv_deliver_from           IN  VARCHAR2,              --  �q��
    iv_shipped_date_from      IN  VARCHAR2,              --  �o�ɓ�FROM
    iv_shipped_date_to        IN  VARCHAR2,              --  �o�ɓ�TO
    iv_instruction_dept       IN  VARCHAR2,              --  �w������
    iv_security_kbn           IN  VARCHAR2               --  �Z�L�����e�B�敪
  );
END xxpo940008c;
/
