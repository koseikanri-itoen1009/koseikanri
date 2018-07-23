CREATE OR REPLACE PACKAGE XXCOK015A03R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOK015A03R(spec)
 * Description      : �x����̌ڋq���⍇�����������ꍇ�A
 *                    ��������ʂ̋��z���󎚂��ꂽ�x���ē�����������܂��B
 * MD.050           : �x���ē�������i���ׁj MD050_COK_015_A03
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
 *  2009/01/13    1.0   K.Yamaguchi      �V�K�쐬
 *  2018/07/06    1.1   K.Nara           [��QE_�{�ғ�_15005] �����Z���^�[�Č��i�x���ē����A�̔��񍐏��ꊇ�o�́j
 *
 *****************************************************************************************/
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                         OUT VARCHAR2        -- �G���[���b�Z�[�W
  , retcode                        OUT VARCHAR2        -- �G���[�R�[�h
  , iv_base_code                   IN  VARCHAR2        -- �⍇����
  , iv_target_ym                   IN  VARCHAR2        -- �ē������s�N��
  , iv_vendor_code                 IN  VARCHAR2        -- �x����
-- Ver.1.1 [��QE_�{�ғ�_15005] SCSK K.Nara ADD START
  , in_request_id                  IN  NUMBER          -- �v��ID
  , in_output_num                  IN  NUMBER          -- �o�͔ԍ�
-- Ver.1.1 [��QE_�{�ғ�_15005] SCSK K.Nara ADD END
  );
END XXCOK015A03R;
/
