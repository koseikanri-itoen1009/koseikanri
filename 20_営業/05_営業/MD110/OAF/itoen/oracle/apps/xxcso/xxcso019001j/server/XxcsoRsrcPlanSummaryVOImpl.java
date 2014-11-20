/*============================================================================
* ファイル名 : XxcsoRsrcPlanSummaryVOImpl
* 概要説明   : 訪問・売上計画画面　営業員計画情報リージョンビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 訪問・売上計画画面　営業員計画情報リージョンビュークラス
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
   * @param employeeNumber  従業員番号
   * @param fullName        従業員名
   * @param baseCode        拠点コード
   * @param planYearMonth   計画年月
   *****************************************************************************
   */
  public void initQuery(
    String employeeNumber
   ,String fullName
   ,String baseCode
   ,String yearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;

    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, fullName);
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, yearMonth);

    executeQuery();
  }
}