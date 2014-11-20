CREATE OR REPLACE PACKAGE xxcso_007002j_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_007002j_pkg(spec)
 * Description      : 商談決定情報入力画面で行われた承認依頼に対し、所属上長が承認／否認を
 *                    行います。所属上長の承認が得られた場合、商談決定情報の通知対象者へ商
 *                    談決定情報の通知を行います。所属上長が承認を行った場合は、承認依頼を
 *                    行ったユーザーへ承認結果を送付します。所属上長が否認を行った場合は、
 *                    承認依頼を行ったユーザーへ否認結果を送付します。
 * MD.050           : MD050_CSO_007_A02_商談決定情報通知
 *
 * Version          : 1.0
 *
 * Program List
 * ----------------------- ------------------------------------------------------------
 *  Name                    Description
 * ----------------------- ------------------------------------------------------------
 *  chk_appr_rjct_comment   承認依頼通知(W-1)
 *  upd_line_notified_flag  商談決定情報履歴明細更新(W-2)
 *  get_notify_user         通知者取得(W-4)
 *  upd_user_notified_flag  商談決定情報通知者リスト更新(W-6)
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-26    1.0   Kazuo.Satomura   新規作成
 *
 *****************************************************************************************/
  --
  -- 承認依頼通知
  PROCEDURE chk_appr_rjct_comment(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
  -- 商談決定情報履歴明細更新
  PROCEDURE upd_line_notified_flag(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
  -- 承認確認通知プロセス起動
  PROCEDURE create_process(
     itemtype  IN         VARCHAR2
    ,itemkey   IN         VARCHAR2
    ,actid     IN         NUMBER
    ,funcmode  IN         VARCHAR2
    ,resultout OUT NOCOPY VARCHAR2
  );
  --
  -- 商談決定情報通知者リスト更新
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
