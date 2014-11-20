CREATE OR REPLACE PACKAGE xxwsh_common3_pkg
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name           : xxwsh_common3_pkg(SPEC)
 * Description            : 共通関数(SPEC)
 * MD.070(CMD.050)        : なし
 * Version                : 1.0
 *
 * Program List
 *  --------------------   ---- ----- --------------------------------------------------
 *   Name                  Type  Ret   Description
 *  --------------------   ---- ----- --------------------------------------------------
 *  get_wsh_wf_info         P          ワークフロー処理情報取得
 *  wf_whs_start            P          出荷用ワークフロー起動関数
 *
 * Change Record
 * ------------ ----- ---------------- -----------------------------------------------
 *  Date         Ver.  Editor           Description
 * ------------ ----- ---------------- -----------------------------------------------
 *  2008/06/10   1.0   Oracle 野村      新規作成
 *
 *****************************************************************************************/
--
  -- ===============================
  -- グローバル型
  -- ===============================
--
  -- WF関連データ
  TYPE wf_whs_rec IS RECORD(
    wf_class                VARCHAR2(150),
    wf_notification         VARCHAR2(150),
    directory               VARCHAR2(150),
    file_name               VARCHAR2(150),
    file_display_name       VARCHAR2(150),
    wf_name                 VARCHAR2(150),
    wf_owner                VARCHAR2(150),
    user_cd01               VARCHAR2(150),
    user_cd02               VARCHAR2(150),
    user_cd03               VARCHAR2(150),
    user_cd04               VARCHAR2(150),
    user_cd05               VARCHAR2(150),
    user_cd06               VARCHAR2(150),
    user_cd07               VARCHAR2(150),
    user_cd08               VARCHAR2(150),
    user_cd09               VARCHAR2(150),
    user_cd10               VARCHAR2(150)
  );
--
  -- ===============================
  -- プロシージャおよびファンクション
  -- ===============================
--
  -- ワークフロー処理情報取得
  PROCEDURE get_wsh_wf_info(
    iv_wf_ope_div       IN  VARCHAR2,                 -- 処理区分
    iv_wf_class         IN  VARCHAR2,                 -- 対象
    iv_wf_notification  IN  VARCHAR2,                 -- 宛先
    or_wf_whs_rec       OUT NOCOPY wf_whs_rec,        -- ファイル情報
    ov_errbuf           OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode          OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg           OUT NOCOPY VARCHAR2);         -- ユーザー・エラー・メッセージ --# 固定 #
--
  -- 出荷用 ワークフロー起動
  PROCEDURE wf_whs_start(
    ir_wf_whs_rec IN  wf_whs_rec,               -- ワークフロー関連情報
    iv_filename   IN  VARCHAR2,                 -- ファイル名
    ov_errbuf     OUT NOCOPY VARCHAR2,          -- エラー・メッセージ           --# 固定 #
    ov_retcode    OUT NOCOPY VARCHAR2,          -- リターン・コード             --# 固定 #
    ov_errmsg     OUT NOCOPY VARCHAR2           -- ユーザー・エラー・メッセージ --# 固定 #
   );
--
END xxwsh_common3_pkg;
/
