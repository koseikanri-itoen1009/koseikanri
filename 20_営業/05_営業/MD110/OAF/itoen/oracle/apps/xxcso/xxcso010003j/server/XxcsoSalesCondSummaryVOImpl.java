/*============================================================================
* ファイル名 : XxcsoSalesCondSummaryVOImpl
* 概要説明   : SP専決明細情報(売価別条件)取得ビューオブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * SP専決明細情報(売価別条件)取得ビューオブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesCondSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesCondSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param spDecisionHeaderId SP専決ヘッダーID
   *****************************************************************************
   */
  public void initQuery(
    String spDecisionCustomerId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, spDecisionCustomerId);

    executeQuery();
  }

}