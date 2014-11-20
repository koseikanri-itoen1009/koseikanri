/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateSumVOImpl
* 概要説明   : 対象指定リージョンビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 対象指定リージョンのビュークラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateSumVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param employeeNumber       従業員番号
   * @param fullName             従業員氏名
   * @param routeNo              ルートNo
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String fullName
   ,String routeNo
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
    setWhereClauseParam(1, fullName);
    setWhereClauseParam(2, routeNo);

    executeQuery();
  }
}