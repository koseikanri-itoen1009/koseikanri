create or replace PACKAGE XXCOI003A05R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOI003A05R(spec)
 * Description      : ���ɍ��يm�F���X�g
 * MD.050           : ���ɍ��يm�F���X�g MD050_COI_003_A05
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
 *  2009/01/20    1.0  SCS.Tsuboi         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_target_date       IN     VARCHAR2,         --   1.�Ώ۔N��
    iv_base_code         IN     VARCHAR2,         --   2.���_
    iv_output_standard   IN     VARCHAR2,         --   3.�o�͊
    iv_output_term       IN     VARCHAR2          --   4.�o�͏���
  );
END XXCOI003A05R;
/
