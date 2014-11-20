CREATE OR REPLACE PACKAGE APPS.XXCSO011A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO011A03C (spec)
 * Description      : ���������X�g�쐬
 * MD.050           : ���������X�g�쐬 (MD050_CSO_011A03)
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
 *  2014/05/12    1.0   S.Niki           main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2      --   �G���[���b�Z�[�W #�Œ�#
   ,retcode         OUT    VARCHAR2      --   �G���[�R�[�h     #�Œ�#
   ,iv_base_code    IN     VARCHAR2      -- 1.�����쐬����
   ,iv_created_by   IN     VARCHAR2      -- 2.�����쐬��
   ,iv_vendor_code  IN     VARCHAR2      -- 3.�d����
   ,iv_po_num       IN     VARCHAR2      -- 4.�����ԍ�
   ,iv_date_from    IN     VARCHAR2      -- 5.�����쐬��FROM
   ,iv_date_to      IN     VARCHAR2      -- 6.�����쐬��TO
   ,iv_lease_kbn    IN     VARCHAR2      -- 7.���[�X�敪
  );
END XXCSO011A03C;
/
