CREATE OR REPLACE PACKAGE XXCSO011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO011A01C(spec)
 * Description      : 発注依頼からの要求に従って、物件を各種作業に割当可能かチェックを行い、
 *                    その結果を発注依頼に返します。
 * MD.050           : MD050_CSO_011_A01_作業依頼（発注依頼）時のインストールベースチェック機能
 *
 * Version          : 1.0
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main_for_application メイン処理（発注依頼申請用）
 *  main_for_approval    メイン処理（発注依頼承認用）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   Noriyuki.Yabuki  新規作成
 *
 *****************************************************************************************/
  --
  -- メイン処理（発注依頼申請用）
  PROCEDURE main_for_application(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  );
  --
  -- メイン処理（発注依頼承認用）
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
