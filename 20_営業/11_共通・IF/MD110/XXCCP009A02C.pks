CREATE OR REPLACE PACKAGE XXCCP009A02C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP009A02C(spec)
 * Description      : �Ό��V�X�e���W���u�󋵃e�[�u��(�A�h�I��)�̍X�V���s���܂��B
 * MD.050           : MD050_CCP_009_A02_�Ό��V�X�e���W���u�󋵍X�V����
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
 *  2009-01-05    1.0  Koji.Oomata       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_pk_request_id_val    IN     VARCHAR2,         --   �������t�v��ID
    iv_status_code          IN     VARCHAR2          --   �X�e�[�^�X�R�[�h
  );
END XXCCP009A02C;
/
