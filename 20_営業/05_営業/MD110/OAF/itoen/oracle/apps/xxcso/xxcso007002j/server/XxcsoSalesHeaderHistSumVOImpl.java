/*============================================================================
* ファイル名 : XxcsoSalesHeaderHistSumVOImpl
* 概要説明   : 商談決定情報履歴ヘッダ取得用ビュークラス
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
 * 商談決定情報履歴ヘッダを取得するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesHeaderHistSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesHeaderHistSumVOImpl()
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