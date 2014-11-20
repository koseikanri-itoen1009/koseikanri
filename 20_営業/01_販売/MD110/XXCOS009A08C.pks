CREATE OR REPLACE PACKAGE APPS.XXCOS009A08C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS009A08C (spec)
 * Description      : �ėp�G���[���X�g
 * MD.050           : �ėp�G���[���X�g MD050_COS_009_A08
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
 *  2010/09/02    1.0   T.Ishiwata       �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_base_code                    IN     VARCHAR2,         --   ���_�R�[�h
    iv_process_date                 IN     VARCHAR2,         --   �������t
    iv_conc_name                    IN     VARCHAR2          --   �@�\��
  );
END XXCOS009A08C;
/
