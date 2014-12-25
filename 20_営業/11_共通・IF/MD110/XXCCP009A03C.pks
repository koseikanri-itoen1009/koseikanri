CREATE OR REPLACE PACKAGE XXCCP009A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCCP009A03C(spec)
 * Description      : �������ۗ��X�e�[�^�X�X�V����
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
 *  2014/10/02    1.0   K.Nakatsu       [E_�{�ғ�_11000]�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf              OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode             OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_exe_mode         IN     VARCHAR2,         --   ���s���[�h
    iv_bill_cust_code   IN     VARCHAR2,         --   ������ڋq
    iv_target_date      IN     VARCHAR2,         --   ����
    iv_business_date    IN     VARCHAR2,         --   �Ɩ����t
    iv_request_id       IN     VARCHAR2,         --   �v��ID
    iv_status_from      IN     VARCHAR2,         --   �X�V�ΏۃX�e�[�^�X
    iv_status_to        IN     VARCHAR2          --   �X�V��X�e�[�^�X
  );
END XXCCP009A03C;
/
