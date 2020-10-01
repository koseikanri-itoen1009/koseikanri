CREATE OR REPLACE PACKAGE APPS.XXCOK024A27C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A27C (spec)
 * Description      : �T���f�[�^�p�̔����э쐬
 * MD.050           : �T���f�[�^�p�̔����э쐬 MD050_COK_024_A27
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
 *  2020/05/25    1.0   N.Koyama         �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode                         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_proc_kind                    IN     VARCHAR2,         --   �����敪
    iv_from_date                    IN     VARCHAR2,         --   �������tFrom
    iv_to_date                      IN     VARCHAR2          --   �������tTo
  );
END XXCOK024A27C;
/
