CREATE OR REPLACE PACKAGE XXCMM004A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCMM004A06C(spec)
 * Description      : �����ꗗ�쐬
 * MD.050           : �����ꗗ�쐬 MD050_CMM_004_A06
 * Version          : Draft2C
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
 *  2008/12/11    1.0   N.Nishimura      main�V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf               OUT    VARCHAR2,        --   �G���[���b�Z�[�W #�Œ�#
    retcode              OUT    VARCHAR2,        --   �G���[�R�[�h     #�Œ�#
    iv_calendar_code     IN     VARCHAR2,        --   �W�������Ώ۔N�x
    iv_cost_type         IN     VARCHAR2         --   �c�ƌ����^�C�v
  );
END XXCMM004A06C;
/
