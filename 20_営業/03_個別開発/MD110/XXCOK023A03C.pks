CREATE OR REPLACE PACKAGE XXCOK023A03C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK023A03C(spec)
 * Description      : �^����\�Z�y�щ^������т����_�ʕi�ڕʁi�P�i�ʁj���ʂ�CSV�f�[�^�`���ŗv���o�͂��܂��B
 * MD.050           : �^����\�Z�ꗗ�\�o�� MD050_COK_023_A03
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
 *  2008/11/10    1.0   SCS T.Taniguchi  main�V�K�쐬
 *  2009/03/02    1.1   SCS T.Taniguchi  [��QCOK_069] ���̓p�����[�^�ɂ��A���_�̎擾�͈͂𐧌�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf         OUT  VARCHAR2,   --   �G���[���b�Z�[�W #�Œ�#
    retcode        OUT  VARCHAR2,   --   �G���[�R�[�h     #�Œ�#
    iv_base_code   IN   VARCHAR2,   -- 1.���_�R�[�h
    iv_budget_year IN   VARCHAR2,   -- 2.�\�Z�N�x
    iv_resp_type   IN   VARCHAR2    -- 3.�E�Ӄ^�C�v
  );
END XXCOK023A03C;
/
