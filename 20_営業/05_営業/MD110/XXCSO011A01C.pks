CREATE OR REPLACE PACKAGE XXCSO011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO011A01C(spec)
 * Description      : �����˗�����̗v���ɏ]���āA�������e���ƂɊ����\���`�F�b�N���s���A
 *                    ���̌��ʂ𔭒��˗��ɕԂ��܂��B
 * MD.050           : MD050_CSO_011_A01_��ƈ˗��i�����˗��j���̃C���X�g�[���x�[�X�`�F�b�N�@�\
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main_for_application ���C�������i�����˗��\���p�j
 *  main_for_approval    ���C�������i�����˗����F�p�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Noriyuki.Yabuki  �V�K�쐬
 *
 *****************************************************************************************/
  --
  -- ���C�������i�����˗��\���p�j
  PROCEDURE main_for_application(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  );
  --
  -- ���C�������i�����˗����F�p�j
  PROCEDURE main_for_approval(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  );
  --
END XXCSO011A01C;
/
