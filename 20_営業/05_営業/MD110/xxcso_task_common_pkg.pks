CREATE OR REPLACE PACKAGE APPS.xxcso_task_common_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCSO_TASK_COMMON_PKG(SPEC)
 * Description      : 共通関数(XXCSOタスク）
 * MD.050/070       :
 * Version          : 1.3
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  create_task               P    -     訪問タスク登録関数
 *  update_task               P    -     訪問タスク更新関数
 *  delete_task               P    -     訪問タスク削除関数
 *  update_task2              P    -     訪問タスク更新処理２（ATTRIBUTE15のみ更新）関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/05    1.0   K.Cho            新規作成
 *  2008/12/16    1.0   T.maruyama       訪問タスク削除関数
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *  2009-07-16    1.2   Kazuo.Satomura   0000070対応
 *  2009-10-23    1.3   Daisuke.Abe      障害対応(E_T4_00056)
 *****************************************************************************************/
--
  -- 訪問タスク登録関数
  PROCEDURE create_task(
    in_resource_id           IN  NUMBER,                 -- 営業員コードのリソースID
    in_party_id              IN  NUMBER,                 -- 顧客のパーティID
    iv_party_name            IN  VARCHAR2,               -- 顧客のパーティ名称
    id_visit_date            IN  DATE,                   -- 実績終了日（訪問日時）
    iv_description           IN  VARCHAR2 DEFAULT NULL,  -- 詳細内容
    /* 2009.07.16 K.Satomura 0000070対応 START */
    it_task_status_id        IN  jtf_task_statuses_b.task_status_id%TYPE DEFAULT NULL,-- タスクステータスＩＤ
    /* 2009.07.16 K.Satomura 0000070対応 END */
    iv_attribute1            IN  VARCHAR2 DEFAULT NULL,  -- DFF1
    iv_attribute2            IN  VARCHAR2 DEFAULT NULL,  -- DFF2
    iv_attribute3            IN  VARCHAR2 DEFAULT NULL,  -- DFF3
    iv_attribute4            IN  VARCHAR2 DEFAULT NULL,  -- DFF4
    iv_attribute5            IN  VARCHAR2 DEFAULT NULL,  -- DFF5
    iv_attribute6            IN  VARCHAR2 DEFAULT NULL,  -- DFF6
    iv_attribute7            IN  VARCHAR2 DEFAULT NULL,  -- DFF7
    iv_attribute8            IN  VARCHAR2 DEFAULT NULL,  -- DFF8
    iv_attribute9            IN  VARCHAR2 DEFAULT NULL,  -- DFF9
    iv_attribute10           IN  VARCHAR2 DEFAULT NULL,  -- DFF10
    iv_attribute11           IN  VARCHAR2 DEFAULT NULL,  -- DFF11
    iv_attribute12           IN  VARCHAR2 DEFAULT NULL,  -- DFF12
    iv_attribute13           IN  VARCHAR2 DEFAULT NULL,  -- DFF13
    iv_attribute14           IN  VARCHAR2 DEFAULT NULL,  -- DFF14
    on_task_id               OUT NUMBER,                 -- タスクID
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  );
--
  -- 訪問タスク更新関数
  PROCEDURE update_task(
    in_task_id               IN  NUMBER,                 -- タスクID
    in_resource_id           IN  NUMBER,                 -- 営業員コードのリソースID
    in_party_id              IN  NUMBER,                 -- 顧客のパーティID
    iv_party_name            IN  VARCHAR2,               -- 顧客のパーティ名称
    id_visit_date            IN  DATE,                   -- 実績終了日（訪問日時）
    iv_description           IN  VARCHAR2 DEFAULT NULL,  -- 詳細内容
    in_obj_ver_num           IN  NUMBER,                 -- オブジェクトバージョン番号
    /* 2009.07.16 K.Satomura 0000070対応 START */
    it_task_status_id        IN  jtf_task_statuses_b.task_status_id%TYPE DEFAULT NULL,-- タスクステータスＩＤ
    /* 2009.07.16 K.Satomura 0000070対応 END */
    iv_attribute1            IN  VARCHAR2 DEFAULT NULL,  -- DFF1
    iv_attribute2            IN  VARCHAR2 DEFAULT NULL,  -- DFF2
    iv_attribute3            IN  VARCHAR2 DEFAULT NULL,  -- DFF3
    iv_attribute4            IN  VARCHAR2 DEFAULT NULL,  -- DFF4
    iv_attribute5            IN  VARCHAR2 DEFAULT NULL,  -- DFF5
    iv_attribute6            IN  VARCHAR2 DEFAULT NULL,  -- DFF6
    iv_attribute7            IN  VARCHAR2 DEFAULT NULL,  -- DFF7
    iv_attribute8            IN  VARCHAR2 DEFAULT NULL,  -- DFF8
    iv_attribute9            IN  VARCHAR2 DEFAULT NULL,  -- DFF9
    iv_attribute10           IN  VARCHAR2 DEFAULT NULL,  -- DFF10
    iv_attribute11           IN  VARCHAR2 DEFAULT NULL,  -- DFF11
    iv_attribute12           IN  VARCHAR2 DEFAULT NULL,  -- DFF12
    iv_attribute13           IN  VARCHAR2 DEFAULT NULL,  -- DFF13
    iv_attribute14           IN  VARCHAR2 DEFAULT NULL,  -- DFF14
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  );
--
  -- 訪問タスク削除関数
  PROCEDURE delete_task(
    in_task_id               IN  NUMBER,                 -- タスクID
    in_obj_ver_num           IN  NUMBER,                 -- オブジェクトバージョン番号
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  );
--
/* 2009.10.23 D.Abe E_T4_00056対応 START */
  -- 訪問タスク更新関数2
  PROCEDURE update_task2(
    in_task_id               IN  NUMBER,                 -- タスクID
    in_obj_ver_num           IN  NUMBER,                 -- オブジェクトバージョン番号
    iv_attribute15           IN  VARCHAR2 DEFAULT jtf_task_utl.g_miss_char,  -- DFF15
    ov_errbuf                OUT NOCOPY VARCHAR2,        -- エラー・メッセージ
    ov_retcode               OUT NOCOPY VARCHAR2,        -- 正常:0、警告:1、異常:2
    ov_errmsg                OUT NOCOPY VARCHAR2         -- ユーザー・エラー・メッセージ
  );
--
/* 2009.10.23 D.Abe E_T4_00056対応 END */
END XXCSO_TASK_COMMON_PKG;
/
