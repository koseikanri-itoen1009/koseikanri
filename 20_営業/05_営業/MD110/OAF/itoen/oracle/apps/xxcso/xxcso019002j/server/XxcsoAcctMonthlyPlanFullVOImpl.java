/*============================================================================
* ファイル名 : XxcsoAcctMonthlyPlanFullVOImpl
* 概要説明   : 売上計画(複数顧客)　顧客別売上計画月別リージョンビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 売上計画(複数顧客)　顧客別売上計画月別リージョンビュークラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctMonthlyPlanFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctMonthlyPlanFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param baseCode          拠点コード
   * @param targetYearMonth   対象年月
   * @param employeeNumber    従業員番号
   *****************************************************************************
   */
  public void initQuery(
    String baseCode
   ,String targetYearMonth
   ,String employeeNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, targetYearMonth);
    setWhereClauseParam(index++, employeeNumber);

    executeQuery();
  }

}