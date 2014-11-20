CREATE OR REPLACE PACKAGE APPS.XXCCP005A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCCP005A01C(spec)
 * Description      : ���V�X�e�������IF�t�@�C���ɂ�����A�w�b�_�E�t�b�^�폜���܂��B
 * MD.050           : MD050_CCP_005_A01_IF�t�@�C���w�b�_�E�t�b�^�폜����
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
 *  2008-xx-xx    1.0   Yutaka.Kuboshima main�V�K�쐬
 *  2009-05-01    1.1   Masayuki.Sano    ��Q�ԍ�T1_0910�Ή�(�X�L�[�}���t��)
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT    VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT    VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    iv_file_name    IN     VARCHAR2,         --   �t�@�C����
    iv_other_system IN     VARCHAR2,         --   ����V�X�e����
    iv_file_dir     IN     VARCHAR2          --   �t�@�C���f�B���N�g��
  );
END XXCCP005A01C;
/
