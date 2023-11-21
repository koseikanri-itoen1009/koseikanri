CREATE OR REPLACE PACKAGE XXCOK016A05C
AS
/*****************************************************************************************
 * Copyright(c) SCSK Corporation, 2023. All rights reserved.
 *
 * Package Name     : XXCOK016A05C(spec)
 * Description      : FB�f�[�^�t�@�C���쐬�����ō쐬���ꂽFB�f�[�^����ɁA
 *                    �d����s�̐U�蕪���������s���܂��B
 *
 * MD.050           : FB�f�[�^�t�@�C���U�蕪������ MD050_COK_016_A05
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
 *  2023/11/08    1.0   T.Okuyama        [E_�{�ғ�_19540�Ή�] �V�K�쐬
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf             OUT VARCHAR2     -- �G���[���b�Z�[�W
  , retcode            OUT VARCHAR2     -- �G���[�R�[�h
  , in_request_id      IN  NUMBER       -- �p�����[�^�FFB�f�[�^�t�@�C���쐬���̗v��ID
  , iv_internal_bank1  IN  VARCHAR2     -- �p�����[�^�F���s���d����s1
  , in_bank_cnt1       IN  NUMBER       -- �p�����[�^�F�d����s1�ւ̈�����
  , iv_internal_bank2  IN  VARCHAR2     -- �p�����[�^�F���s���d����s2
  , in_bank_cnt2       IN  NUMBER       -- �p�����[�^�F�d����s2�ւ̈�����
  , iv_internal_bank3  IN  VARCHAR2     -- �p�����[�^�F���s���d����s3
  , in_bank_cnt3       IN  NUMBER       -- �p�����[�^�F�d����s3�ւ̈�����
  , iv_internal_bank4  IN  VARCHAR2     -- �p�����[�^�F���s���d����s4
  , in_bank_cnt4       IN  NUMBER       -- �p�����[�^�F�d����s4�ւ̈�����
  , iv_internal_bank5  IN  VARCHAR2     -- �p�����[�^�F���s���d����s5
  , in_bank_cnt5       IN  NUMBER       -- �p�����[�^�F�d����s5�ւ̈�����
  , iv_internal_bank6  IN  VARCHAR2     -- �p�����[�^�F���s���d����s6
  , in_bank_cnt6       IN  NUMBER       -- �p�����[�^�F�d����s6�ւ̈�����
  );
END XXCOK016A05C;
/
