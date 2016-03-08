/*============================================================================
* ファイル名 : XxcsoContractManagementFullVOImpl
* 概要説明   : 契約管理テーブル情報ビューオブジェクトクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2016-01-06 1.1  SCSK桐生和幸 [E_本稼動_13456]自販機管理システム代替対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 契約管理テーブル情報ビューオブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractManagementFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractManagementFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param contractManagementId 自動販売機設置契約書ID
   *****************************************************************************
   */
  public void initQuery(
    String contractManagementId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, contractManagementId);

    executeQuery();
  }
}