CREATE OR REPLACE PACKAGE XXCSM004A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM004A03C(spec)
 * Description      : �]�ƈ��}�X�^�Ǝ��i�|�C���g�}�X�^����e�c�ƈ��̎��i�|�C���g���Z�o���A
 *                  : �V�K�l���|�C���g�ڋq�ʗ����e�[�u���ɓo�^���܂��B
 * MD.050           : MD050_CSM_004_A03_�V�K�l���|�C���g�W�v�i���i�|�C���g�W�v�����j
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
 *  2008-12-12    1.0   T.Tsukino        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf           OUT NOCOPY VARCHAR2          --   �G���[���b�Z�[�W #�Œ�#
   ,retcode          OUT NOCOPY VARCHAR2          --   �G���[�R�[�h     #�Œ�#
   ,iv_process_date  IN  VARCHAR2
    );
END XXCSM004A03C;
/
