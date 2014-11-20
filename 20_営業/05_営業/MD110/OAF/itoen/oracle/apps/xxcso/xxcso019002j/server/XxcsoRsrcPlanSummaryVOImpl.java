/*============================================================================
* ファイル名 : XxcsoRsrcPlanSummaryVOImpl
* 概要説明   : 売上計画(複数顧客)　営業員計画情報リージョンビュークラス
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
 * 売上計画(複数顧客)　営業員計画情報リージョンビュークラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRsrcPlanSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRsrcPlanSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param baseCode          拠点コード
   * @param employeeNumber    営業員コード
   * @param targetYearMonth   対象年月
   *****************************************************************************
   */
  public void initQuery(
    String baseCode
   ,String employeeNumber
   ,String targetYearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, targetYearMonth);
    setWhereClauseParam(index++, targetYearMonth);

    executeQuery();
  }
}