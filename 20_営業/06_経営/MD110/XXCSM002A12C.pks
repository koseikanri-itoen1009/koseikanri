CREATE OR REPLACE PACKAGE XXCSM002A12C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A12C(spec)
 * Description      : ���i�v�惊�X�g(���n��)�o��
 * MD.050           : ���i�v�惊�X�g(���n��)�o�� MD050_CSM_002_A12
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/01/14    1.0   M.Ohtsuki        �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
                errbuf           OUT    NOCOPY VARCHAR2                                             -- �G���[���b�Z�[�W
               ,retcode          OUT    NOCOPY VARCHAR2                                             -- �G���[�R�[�h
               ,iv_taisyo_year   IN            VARCHAR2                                             -- �Ώ۔N�x
               ,iv_kyoten_cd     IN            VARCHAR2                                             -- ���_�R�[�h
               ,iv_cost_kind     IN            VARCHAR2                                             -- �������
               ,iv_kyoten_kaisou IN            VARCHAR2                                             -- �K�w
               );
END XXCSM002A12C;
/
