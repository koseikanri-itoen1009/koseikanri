/*============================================================================
* ファイル名 : XxcsoValidateAcctRsrsVOImpl
* 概要説明   : 訪問・売上計画画面　バリデーションチェックビュークラス
*             顧客担当営業員(最新)VIEWの存在チェック
*             顧客マスタVIEWの訪問対象区分、パーティID取得
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS朴邦彦　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 訪問・売上計画画面　バリデーションチェックビュークラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoValidateAcctRsrsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoValidateAcctRsrsVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param accountNumber   顧客コード
   * @param employeeNumber  従業員番号
   * @param planYearMonth   計画年月
   *****************************************************************************
   */
  public void initQuery(
    String accountNumber
   ,String employeeNumber
   ,String planYearMonth
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    
    setWhereClauseParam(index++, employeeNumber);
    setWhereClauseParam(index++, accountNumber);
    setWhereClauseParam(index++, planYearMonth);
    setWhereClauseParam(index++, planYearMonth);
    setWhereClauseParam(index++, planYearMonth);

    executeQuery();
  }
  
}