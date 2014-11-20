/*============================================================================
* ファイル名 : XxcsoUsuallyDelivPriceVOImpl
* 概要説明   : 通常NET価格ビュークラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2011-04-13 1.0  SCS吉元強樹  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 通常NET価格を導出するためのビュークラスです。
 * @author  SCS吉元強樹
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoUsuallNetPriceVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoUsuallNetPriceVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化を行います。
   * @param AccountNumber       顧客コード
   * @param InventoryItemId     品目ＩＤ
   * @param QuoteDiv            見積区分
   * @param UsuallyDelivPrice   通常店納価格
   *****************************************************************************
   */
  public void initQuery(
    String AccountNumber,     // 顧客コード
    Number InventoryItemId,   // 品目ID
    String UsuallyDelivPrice  // 通常店納価格
  )
  {
    setWhereClause(null);
    setWhereClauseParams(null);

    int index = 0;
    setWhereClauseParam(index++, AccountNumber);
    setWhereClauseParam(index++, InventoryItemId);
    setWhereClauseParam(index++, UsuallyDelivPrice);   

    executeQuery();
  }

}