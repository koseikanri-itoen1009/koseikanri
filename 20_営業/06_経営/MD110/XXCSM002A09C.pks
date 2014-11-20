CREATE OR REPLACE PACKAGE XXCSM002A09C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A09C(spec)
 * Description      : �N�ԏ��i�v��i�c�ƌ����j�`�F�b�N���X�g�o��
 * MD.050           : �N�ԏ��i�v��i�c�ƌ����j�`�F�b�N���X�g�o�� MD050_CSM_002_A09
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
 *  2008-12-11    1.0   K.Yamada         main�V�K�쐬
 *  2012-12-13    1.1   SCSK K.Taniguchi [E_�{�ғ�_09949] �V�������I���\�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT VARCHAR2,          --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT VARCHAR2,          --   �G���[�R�[�h     #�Œ�#
    iv_p_yyyy       IN  VARCHAR2,          -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,          -- 2.���_�R�[�h
--//+UPD START E_�{�ғ�_09949 K.Taniguchi
--    iv_p_level      IN  VARCHAR2           -- 3.�K�w
    iv_p_level      IN  VARCHAR2,          -- 3.�K�w
    iv_p_new_old_cost_class
                    IN  VARCHAR2           -- 4.�V�������敪
--//+UPD END E_�{�ғ�_09949 K.Taniguchi
  );
END XXCSM002A09C;
/
