/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateSumVOImpl
* 概要説明   : 対象指定リージョンビュークラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基  新規作成
* 2010-03-23 1.1  SCS阿部大輔  [E_本稼動_01942]管理元拠点対応
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
   * @param baseCode             拠点コード
   * @param baseName             拠点名
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String fullName
   ,String routeNo
// 2010-03-23 [E_本稼動_01942] Add Start
   ,String baseCode
   ,String baseName
// 2010-03-23 [E_本稼動_01942] Add End
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
    setWhereClauseParam(1, fullName);
    setWhereClauseParam(2, routeNo);
// 2010-03-23 [E_本稼動_01942] Add Start
    setWhereClauseParam(3, baseCode);
    setWhereClauseParam(4, baseName);
// 2010-03-23 [E_本稼動_01942] Add End

    executeQuery();
  }
}