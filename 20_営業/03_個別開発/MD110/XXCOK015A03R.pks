CREATE OR REPLACE PACKAGE XXCOK015A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A03R(spec)
 * Description      : �x����̌ڋq���⍇�����������ꍇ�A
 *                    ��������ʂ̋��z���󎚂��ꂽ�x���ē�����������܂��B
 * MD.050           : �x���ē�������i���ׁj MD050_COK_015_A03
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
 *  2009/01/13    1.0   K.Yamaguchi      �V�K�쐬
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
  );
END XXCOK015A03R;
/
