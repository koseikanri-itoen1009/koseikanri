/*============================================================================
* ファイル名 : VendorCode2VOImpl
* 概要説明   : 取引先LOVビューオブジェクト
* バージョン : 1.0
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-05-21 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.lov.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 取引先LOVビューオブジェクトです。
 * @author  ORACLE伊藤ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class VendorCode2VOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public VendorCode2VOImpl()
  {
  }

  /***************************************************************************
   * 初期化処理を行うメソッドです。
   * @param vendorCode 取引先
   ***************************************************************************
   */
  public void initQuery(String vendorCode)
  {
    // WHERE句に取引先を追加
    setWhereClause(null);
    setWhereClause(" vendor_code = :0");
    setWhereClauseParam(0, vendorCode);

    // 検索実行
    executeQuery();
  }
}