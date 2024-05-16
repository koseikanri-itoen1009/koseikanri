CREATE OR REPLACE PACKAGE APPS.XXCFF018A01C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCFF018A01C (spec)
 * Description      : ���p�V�~�����[�V�������ʃ��X�g
 * MD.050           : ���p�V�~�����[�V�������ʃ��X�g (MD050_CFF_018_A01)
 * Version          : 1.1
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
 *  2014-12-18    1.0   K.Kanada         �V�K�쐬  E_�{�ғ�_08122�Ή�
 *  2024-02-09    1.1   Y.Sato           E_�{�ғ�_19496�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                          OUT    VARCHAR2      -- �G���[���b�Z�[�W #�Œ�#
   ,retcode                         OUT    VARCHAR2      -- �G���[�R�[�h     #�Œ�#
   ,iv_whatif_request_id            IN     VARCHAR2      -- 1.WHATIF���N�G�X�gID
   ,iv_period_date                  IN     VARCHAR2      -- 2.�J�n����
   ,iv_num_periods                  IN     VARCHAR2      -- 3.���Ԑ�
-- Ver1.1 Add Start
   ,iv_owner_company                IN     VARCHAR2      -- 4.�{�ЍH��敪
-- Ver1.1 Add end
  );
END XXCFF018A01C;
/
