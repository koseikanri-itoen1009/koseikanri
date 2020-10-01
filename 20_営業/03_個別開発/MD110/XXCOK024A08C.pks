CREATE OR REPLACE PACKAGE APPS.XXCOK024A08C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCOK024A08C (spec)
 * Description      : �̔��T���f�[�^CSV�o��
 * MD.050           : �̔��T���f�[�^CSV�o�� MD050_COS_024_A08
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
 *  2019/09/20    1.0   H.Ishii          main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2     -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2     -- �G���[�R�[�h     #�Œ�#
   ,iv_customer_code                IN     VARCHAR2     -- �ڋq�ԍ�
   ,iv_order_list_date_from         IN     VARCHAR2     -- �o�͓�(FROM)
   ,iv_order_list_date_to           IN     VARCHAR2     -- �o�͓�(TO)
  );
END XXCOK024A08C;
/
