CREATE OR REPLACE PACKAGE APPS.XXCSO011A01C
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO011A01C(spec)
 * Description      : 発注依頼からの要求に従って、物件を各種作業に割当可能かチェックを行い、
 *                    その結果を発注依頼に返します。
 * MD.050           : MD050_CSO_011_A01_作業依頼（発注依頼）時のインストールベースチェック機能
 *
 * Version          : 1.1
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main_for_application メイン処理（発注依頼申請用）
 *  main_for_approval    メイン処理（発注依頼承認用）
 *  main_for_denegation  メイン処理（発注依頼否認用）
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2009-01-21    1.0   N.Yabuki         新規作成
 *  2009-04-16    1.1   N.Yabuki        【ST障害管理398】否認時にIBの作業依頼中フラグをOFFにする処理を追加
 *  2009-05-01    1.2   Tomoko.Mori      T1_0897対応
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
/*20090416_yabuki_ST398 START*/
  -- メイン処理（発注依頼承認用）
  PROCEDURE main_for_denegation(
      itemtype   IN         VARCHAR2
    , itemkey    IN         VARCHAR2
    , actid      IN         VARCHAR2
    , funcmode   IN         VARCHAR2
    , resultout  OUT NOCOPY VARCHAR2
  );
/*20090416_yabuki_ST398 END*/
  --
END XXCSO011A01C;
/
