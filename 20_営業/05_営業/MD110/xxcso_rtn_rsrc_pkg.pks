CREATE OR REPLACE PACKAGE APPS.xxcso_rtn_rsrc_pkg
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcso_util_common_pkg(SPEC)
 * Description      : ルートNo/担当営業員更新処理関数
 * MD.050/070       :
 * Version          : 1.0
 *
 * Program List
 *  ------------------------- ---- ----- --------------------------------------------------
 *   Name                     Type  Ret   Description
 *  ------------------------- ---- ----- --------------------------------------------------
 *  regist_route_no           P    -     ルートNo登録関数
 *  unregist_route_no         P    -     ルートNo削除関数
 *  regist_resource_no        P    -     担当営業員登録関数
 *  unregist_resource_no      P    -     担当営業員削除関数
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/08    1.0   H.Ogawa          新規作成
 *  2008/12/24    1.0   M.maruyama       ヘッダ修正(Oracle版からSCS版へ)
 *  2009-05-01    1.1   Tomoko.Mori      T1_0897対応
 *
 *****************************************************************************************/
--
   /**********************************************************************************
   * Function Name    : regist_route_no
   * Description      : ルートNo登録関数
   ***********************************************************************************/
  PROCEDURE regist_route_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_route_no                  IN  VARCHAR2         -- ルートNo
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  );
--
   /**********************************************************************************
   * Function Name    : unregist_route_no
   * Description      : ルートNo削除関数
   ***********************************************************************************/
  PROCEDURE unregist_route_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_route_no                  IN  VARCHAR2         -- ルートNo
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  );
--
   /**********************************************************************************
   * Function Name    : regist_resource_no
   * Description      : 担当営業員登録関数
   ***********************************************************************************/
  PROCEDURE regist_resource_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_resource_no               IN  VARCHAR2         -- 担当営業員（従業員コード）
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  );
--
   /**********************************************************************************
   * Function Name    : unregist_resource_no
   * Description      : 担当営業員削除関数
   ***********************************************************************************/
  PROCEDURE unregist_resource_no(
    iv_account_number            IN  VARCHAR2         -- 顧客コード
   ,iv_resource_no               IN  VARCHAR2         -- 担当営業員（従業員コード）
   ,id_start_date                IN  DATE             -- 適用開始日
   ,ov_errbuf                    OUT NOCOPY VARCHAR2  -- システムメッセージ
   ,ov_retcode                   OUT NOCOPY VARCHAR2  -- 処理結果('0':正常, '1':警告, '2':エラー)
   ,ov_errmsg                    OUT NOCOPY VARCHAR2  -- ユーザーメッセージ
  );
--
END xxcso_rtn_rsrc_pkg;
/
