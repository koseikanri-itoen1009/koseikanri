/*============================================================================
* ファイル名 : XxcsoSalesNotifyUserSumVOImpl
* 概要説明   : 商談決定情報通知者リスト取得用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 商談決定情報通知者リストを取得するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotifyUserSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotifyUserSumVOImpl()
  {
  }


  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param headerHistoryId 商談決定情報履歴ヘッダID
   *****************************************************************************
   */
  public void initQuery(
    Number headerHistoryId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, headerHistoryId);

    executeQuery();
  }
}