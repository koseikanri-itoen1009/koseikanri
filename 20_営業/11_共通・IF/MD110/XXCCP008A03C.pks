CREATE OR REPLACE PACKAGE APPS.XXCCP008A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP008A03C(spec)
 * Description      : ���[�X�x���v��f�[�^CSV�o��
 * Version          : 1.0
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
 *  2012/10/05    1.00  SCSK ������a    �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT   VARCHAR2,       --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT   VARCHAR2,       --   �G���[�R�[�h     #�Œ�#
    iv_contract_number  IN    VARCHAR2,       --    1.�_��ԍ�
    iv_lease_company    IN    VARCHAR2,       --    2.���[�X���
    iv_object_code_01   IN    VARCHAR2,       --    3.�����R�[�h1
    iv_object_code_02   IN    VARCHAR2,       --    4.�����R�[�h2
    iv_object_code_03   IN    VARCHAR2,       --    5.�����R�[�h3
    iv_object_code_04   IN    VARCHAR2,       --    6.�����R�[�h4
    iv_object_code_05   IN    VARCHAR2,       --    7.�����R�[�h5
    iv_object_code_06   IN    VARCHAR2,       --    8.�����R�[�h6
    iv_object_code_07   IN    VARCHAR2,       --    9.�����R�[�h7
    iv_object_code_08   IN    VARCHAR2,       --   10.�����R�[�h8
    iv_object_code_09   IN    VARCHAR2,       --   11.�����R�[�h9
    iv_object_code_10   IN    VARCHAR2        --   12.�����R�[�h10
  );
END XXCCP008A03C;
/
