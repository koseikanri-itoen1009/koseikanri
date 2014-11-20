/*============================================================================
* ファイル名 : XxcsoSalesLineSummaryVOImpl
* 概要説明   : 商談決定情報明細取得用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 商談決定情報明細を取得するためのビュークラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesLineSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesLineSummaryVOImpl()
  {
  }


  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param leadId 商談ID
   *****************************************************************************
   */
  public void initQuery(
    String leadId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, leadId);

    executeQuery();
  }
}