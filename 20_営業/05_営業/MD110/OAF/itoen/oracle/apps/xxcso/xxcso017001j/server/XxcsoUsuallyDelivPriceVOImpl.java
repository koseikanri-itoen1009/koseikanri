/*============================================================================
* ファイル名 : XxcsoUsuallyDelivPriceVOImpl
* 概要説明   : 通常店納価格ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS及川領    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 通常店納価格を出力するためのビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUsuallyDelivPriceVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoUsuallyDelivPriceVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param AccountNumber       顧客コード
   * @param InventoryItemId     品目ＩＤ
   *****************************************************************************
   */
  public void initQuery(
    String AccountNumber,
    Number InventoryItemId
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, AccountNumber);
    setWhereClauseParam(index++, InventoryItemId);

    executeQuery();
  }

}