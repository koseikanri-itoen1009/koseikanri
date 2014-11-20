CREATE OR REPLACE PACKAGE xxcso_007002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007002j_pkg(spec)
 * Description      : ���k��������͉�ʂōs��ꂽ���F�˗��ɑ΂��A�����㒷�����F�^�۔F��
 *                    �s���܂��B�����㒷�̏��F������ꂽ�ꍇ�A���k������̒ʒm�Ώێ҂֏�
 *                    �k������̒ʒm���s���܂��B�����㒷�����F���s�����ꍇ�́A���F�˗���
 *                    �s�������[�U�[�֏��F���ʂ𑗕t���܂��B�����㒷���۔F���s�����ꍇ�́A
 *                    ���F�˗����s�������[�U�[�֔۔F���ʂ𑗕t���܂��B
 * MD.050           : MD050_CSO_007_A02_���k������ʒm
 *
 * Version          : 1.0
 *
 * Program List
 * ----------------------- ------------------------------------------------------------
 *  Name                    Description
 * ----------------------- ------------------------------------------------------------
 *  chk_appr_rjct_comment   ���F�˗��ʒm(W-1)
 *  upd_line_notified_flag  ���k�����񗚗𖾍׍X�V(W-2)
 *  get_notify_user         �ʒm�Ҏ擾(W-4)
 *  upd_user_notified_flag  ���k������ʒm�҃��X�g�X�V(W-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-26    1.0   Kazuo.Satomura   �V�K�쐬
 *
 *****************************************************************************************/
  --
  -- ���F�˗��ʒm
  PROCEDURE chk_appr_rjct_comment(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
  -- ���k�����񗚗𖾍׍X�V
  PROCEDURE upd_line_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
  -- ���F�m�F�ʒm�v���Z�X�N��
  PROCEDURE create_process(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
  -- ���k������ʒm�҃��X�g�X�V
  PROCEDURE upd_user_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
END xxcso_007002j_pkg;
/
