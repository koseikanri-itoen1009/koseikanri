/*============================================================================
* ファイル名 : XxcsoAcctSalesSummaryVOImpl
* 概要説明   : 訪問・売上計画画面　顧客検索結果表示リージョンビュークラス
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
 * 訪問・売上計画画面　顧客検索結果表示リージョンビュークラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAcctSalesSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAcctSalesSummaryVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param accountNumber   顧客コード
   * @param partyName       顧客名
   * @param partyId         パーティID
   * @param vistTargetDiv   訪問対象区分
   * @param planYear        計画年
   * @param planMonth       計画月
   *****************************************************************************
   */
  public void initQuery(
    String accountNumber
   ,String partyName
   ,String partyId
   ,String vistTargetDiv
   ,String planYear
   ,String planMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, accountNumber);
    setWhereClauseParam(index++, partyName);
    setWhereClauseParam(index++, partyId);
    setWhereClauseParam(index++, vistTargetDiv);
    setWhereClauseParam(index++, planYear);
    setWhereClauseParam(index++, planMonth);

    executeQuery();
  }
}