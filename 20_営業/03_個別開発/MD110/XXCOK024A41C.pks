CREATE OR REPLACE PACKAGE APPS.XXCOK024A41C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A41C (spec)
 * Description      : �x�����A�g�T���f�[�^�o��
 * MD.050           : �x�����A�g�T���f�[�^�o�� MD050_COK_024_A41
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
 *  2022/09/07    1.0   M.Akachi         main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2          -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2          -- �G���[�R�[�h     #�Œ�#
   ,iv_data_type                    IN     VARCHAR2          -- �f�[�^���
   ,iv_record_date_from             IN     VARCHAR2          -- �v���(FROM)
   ,iv_record_date_to               IN     VARCHAR2          -- �v���(TO)
   ,iv_base_code                    IN     VARCHAR2          -- �{���S�����_
   ,iv_sale_base_code               IN     VARCHAR2          -- ���㋒�_
  );
END XXCOK024A41C;
/
