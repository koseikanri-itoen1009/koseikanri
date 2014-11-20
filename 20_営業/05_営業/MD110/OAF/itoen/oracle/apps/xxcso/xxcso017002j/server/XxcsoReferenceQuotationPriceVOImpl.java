/*============================================================================
* ファイル名 : XxcsoReferenceQuotationPriceVOImpl
* 概要説明   : 建値算出ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-14 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/*******************************************************************************
 * 建値の算出をするためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoReferenceQuotationPriceVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoReferenceQuotationPriceVOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param InventoryItemId         品目ID
   * @param AccountNumber           顧客コード
   *****************************************************************************
   */
  public void initQuery(
    String InventoryItemId,
    String AccountNumber
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, InventoryItemId);
    setWhereClauseParam(index++, AccountNumber);

    executeQuery();
  }
}