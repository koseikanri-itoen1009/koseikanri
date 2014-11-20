/*============================================================================
* ファイル名 : XxcsoAcctWeeklyPlanFullVOImpl
* 概要説明   : 訪問・売上計画画面　顧客別売上計画日別リージョンビュークラス
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
 * 訪問・売上計画画面　顧客別売上計画日別リージョンビュークラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctWeeklyPlanFullVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctWeeklyPlanFullVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param baseCode        拠点コード
   * @param accountNumber   顧客コード
   * @param planYearMonth   計画年月
   *****************************************************************************
   */
  public void initQuery(
    String baseCode
   ,String accountNumber
   ,String planYearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, baseCode);
    setWhereClauseParam(index++, accountNumber);
    setWhereClauseParam(index++, planYearMonth);

    executeQuery();
  }
}