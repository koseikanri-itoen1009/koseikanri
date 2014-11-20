CREATE OR REPLACE PACKAGE xxpo940008c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxpo940008c(spec)
 * Description      : ���b�g�������捞����
 * MD.050           : �����I�����C�� T_MD050_BPO_940
 * MD.070           : ���b�g�������捞���� T_MD070_BPO_94H
 * Version          : 1.2
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
 *
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
