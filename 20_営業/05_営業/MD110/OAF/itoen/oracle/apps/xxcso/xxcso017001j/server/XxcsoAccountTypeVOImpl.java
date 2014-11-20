/*============================================================================
* ファイル名 : XxcsoAccountTypeVOImpl
* 概要説明   : 顧客タイプ検索用ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-29 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * 選択した顧客コードの顧客タイプを検索するためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoAccountTypeVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoAccountTypeVOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param AccountNumber       顧客コード
   *****************************************************************************
   */
  public void initQuery(
    String accountNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, accountNumber);

    executeQuery();
  }

}