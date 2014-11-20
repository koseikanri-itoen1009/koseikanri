CREATE OR REPLACE PACKAGE XXCOS011A06C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS011A06C (spec)
 * Description      : �̔����уw�b�_�f�[�^�A�̔����і��׃f�[�^���擾���āA�̔����уf�[�^�t�@�C����
 *                    �쐬����B
 * MD.050           : �̔����уf�[�^�쐬�iMD050_COS_011_A06�j
 * Version          : 1.3
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
 *  2009/01/09    1.0   K.Watanabe      �V�K�쐬
 *  2009/03/10    1.1   K.Kiriu         [COS_157]�����J�n��NULL�l���̏C���A�͂���Z���s���C��
 *  2009/04/15    1.2   K.Kiriu         [T1_0495]JP1�N���̈׃p�����[�^�̒ǉ�
 *  2009/04/28    1.3   K.Kiriu         [T1_0756]���R�[�h���ύX�Ή�
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf            OUT  VARCHAR2,     --   �G���[���b�Z�[�W #�Œ�#
    retcode           OUT  VARCHAR2,     --   �G���[�R�[�h     #�Œ�#
    iv_run_class      IN   VARCHAR2,     --   ���s�敪�F�u0:�V�K�v�u2:�����v
    iv_inv_cust_code  IN   VARCHAR2,     --   ������ڋq�R�[�h
/* 2009/04/15 Mod Start */
--    iv_send_date      IN   VARCHAR2      --   ���M��(YYYYMMDD)
    iv_send_date      IN   VARCHAR2,     --   ���M��(YYYYMMDD)
    iv_sales_exp_ptn  IN   VARCHAR2      --   EDI�̔����я����p�^�[��
/* 2009/04/15 Mod End   */
  );
END XXCOS011A06C;
/
