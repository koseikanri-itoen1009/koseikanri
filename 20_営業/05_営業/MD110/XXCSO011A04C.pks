CREATE OR REPLACE PACKAGE APPS.XXCSO011A04C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A04C(spec)
 * Description      : �������ה�����DFF���X�V���܂��B
 * MD.050           : �����X�V�A�b�v���[�h (MD050_CSO_011A04)
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
 * 2014/05/08    1.0   Kazuyuki Kiriu   main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
     errbuf        OUT    VARCHAR2       --   �G���[���b�Z�[�W #�Œ�#
    ,retcode       OUT    VARCHAR2       --   �G���[�R�[�h     #�Œ�#
    ,iv_file_id    IN     VARCHAR2       -- 1.�t�@�C��ID
    ,iv_fmt_ptn    IN     VARCHAR2       -- 2.�t�H�[�}�b�g�p�^�[��
  );
END XXCSO011A04C;
/
