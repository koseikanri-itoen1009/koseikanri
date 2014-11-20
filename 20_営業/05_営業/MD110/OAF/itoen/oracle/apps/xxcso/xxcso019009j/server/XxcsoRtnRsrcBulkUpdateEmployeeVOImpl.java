/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateEmployeeVOImpl
* 概要説明   : 拠点内担当営業員ビュークラス
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
 * 拠点内担当営業員のビュークラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateEmployeeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param employeeNumber       従業員番号
   * @param baseCode             拠点コード
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String baseCode
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    setWhereClauseParam(0, employeeNumber);
    setWhereClauseParam(1, baseCode);
    setWhereClauseParam(2, baseCode);

    executeQuery();
  }
}