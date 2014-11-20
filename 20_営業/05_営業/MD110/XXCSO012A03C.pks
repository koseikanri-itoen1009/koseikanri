CREATE OR REPLACE PACKAGE APPS.XXCSO012A03C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2011. All rights reserved.
 *
 * Package Name     : XXCSO012A03C(spec)
 * Description      : �t�@�C���A�b�v���[�hIF�Ɏ捞�܂ꂽ�����̔��@�X�V�f�[�^�ɂ�
 *                    �����}�X�^���(IB)���X�V���܂��B
 * MD.050           : �����̔��@�f�[�^�X�V (MD050_CSO_012_A03)
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
 * 2014/09/11     1.0   Taketo Oda       main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf        OUT  NOCOPY  VARCHAR2,         --   �G���[���b�Z�[�W #�Œ�#
    retcode       OUT  NOCOPY  VARCHAR2,         --   �G���[�R�[�h     #�Œ�#
    in_file_id    IN   NUMBER,                   --   �t�@�C��ID
    iv_format     IN   VARCHAR2                  --   �t�H�[�}�b�g�p�^�[��
);
END XXCSO012A03C;
/
