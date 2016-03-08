CREATE OR REPLACE PACKAGE APPS.XXCSO015A07C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2016. All rights reserved.
 *
 * Package Name     : XXCSO015A07C(spec)
 * Description      : �_��ɂăI�[�i�[�ύX�������������A���̋@�Ǘ��V�X�e����
 *                    �ڋq�ƕ�����A�g���邽�߂ɁACSV�t�@�C�����쐬���܂��B
 * MD.050           : MD050_���̋@-EBS�C���^�t�F�[�X�F�iOUT�j�jEBS���̋@�ύX
 * Version          : 1.0
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                        Description
 * ---------------------------- ----------------------------------------------------------
 *  init                        ��������                       (A-1)
 *  open_csv_file               CSV�t�@�C���I�[�v��            (A-2)
 *  upd_cont_manage             �_��Ǘ��e�[�u���X�V����       (A-5)
 *  create_csv_rec              EBS���̋@�ύX�f�[�^CSV�o��     (A-6)
 *  close_csv_file              CSV�t�@�C���N���[�Y����        (A-7)
 *  submain                     ���C�������v���V�[�W��
 *                                EBS���̋@�ύX�f�[�^���o����  (A-3)
 *                                �Z�[�u�|�C���g���s           (A-4)
 *  main                        �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *                                �I������                     (A-8)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2016-01-06    1.0   Y.Shoji          �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,         -- �G���[���b�Z�[�W #�Œ�#
    retcode       OUT  NOCOPY  VARCHAR2,         -- �G���[�R�[�h     #�Œ�#
    iv_proc_date  IN VARCHAR2,                   -- �Ώۓ�
    iv_proc_time  IN VARCHAR2                    -- �Ώێ���
  );
END XXCSO015A07C;
/
