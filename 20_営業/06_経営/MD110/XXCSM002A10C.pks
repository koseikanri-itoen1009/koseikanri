CREATE OR REPLACE PACKAGE XXCSM002A10C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSM002A10C(spec)
 * Description      : ���i�v�惊�X�g�i�݌v�j�o��
 * MD.050           : ���i�v�惊�X�g�i�݌v�j�o�� MD050_CSM_002_A10
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
 *  2009-1-7      1.0   n.izumi          main�V�K�쐬
 *  2012-12-10    1.1   SCSK K.Taniguchi [E_�{�ғ�_09949] �V�������I���\�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf          OUT NOCOPY VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode         OUT NOCOPY VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_p_yyyy       IN  VARCHAR2,          -- 1.�Ώ۔N�x
    iv_p_kyoten_cd  IN  VARCHAR2,          -- 2.���_�R�[�h
    iv_p_cost_kind  IN  VARCHAR2,          -- 3.�������
    iv_p_level      IN  VARCHAR2,          -- 4.�K�w
--//+ADD START E_�{�ғ�_09949 K.Taniguchi
    iv_p_new_old_cost_class
                    IN  VARCHAR2           -- 4.�V�������敪
--//+ADD END E_�{�ғ�_09949 K.Taniguchi
  );
END XXCSM002A10C;
/
