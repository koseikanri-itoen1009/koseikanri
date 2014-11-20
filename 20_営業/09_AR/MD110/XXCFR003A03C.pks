CREATE OR REPLACE PACKAGE XXCFR003A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFR003A03C(spec)
 * Description      : �������׃f�[�^�쐬
 * MD.050           : MD050_CFR_003_A03_�������׃f�[�^�쐬
 * MD.070           : MD050_CFR_003_A03_�������׃f�[�^�쐬
 * Version          : 1.10
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
 *  2008/12/08    1.00 SCS ���� �א�    ����쐬
 *  2012/11/06    1.10 SCSK ���� ����   [��Q�{�ғ�10090] ��ԃW���u�p�t�H�[�}���X�Ή�(JOB�̕����Ή�)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                  OUT     VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode                 OUT     VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
-- Modify 2012.11.06 Ver1.10 Start
    iv_parallel_type        IN      VARCHAR2,         -- �p���������s�敪
    iv_batch_on_judge_type  IN      VARCHAR2          -- ��Ԏ蓮���f�敪
-- Modify 2012.11.06 Ver1.10 End
  );
END XXCFR003A03C;--(�ύX)
/
