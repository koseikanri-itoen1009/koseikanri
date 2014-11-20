CREATE OR REPLACE PACKAGE APPS.XXCCP001A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP001A01C(spec)
 * Description      : �Ɩ����t�Ɖ�X�V
 * MD.050           : MD050_CCP_001_A01_�Ɩ����t�X�V�Ɖ�
 * Version          : 1.00
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  init                   ��������(A-1)
 *  con_get_process_date   �Ɩ����t�Ɖ��(A-2)
 *  update_process_date    �Ɩ����t�X�V����(A-3)
 *  insert_process_date    �Ɩ����t�o�^����(A-4)
 *  submain                ���C�������v���V�[�W��
 *  main                   �R���J�����g���s�t�@�C���o�^�v���V�[�W��(�㏈��)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/11/10    1.00  �n�Ӓ���         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT   VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode          OUT   VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_handle_area   IN    VARCHAR2,         --   �����敪
    iv_process_date  IN    VARCHAR2          --   �Ɩ����t
  );
END XXCCP001A01C;
/
