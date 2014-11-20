/*============================================================================
* ファイル名 : XxpoSupplierResultsTotalVOImpl
* 概要説明   : 仕入出荷実績:合計算出ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-18 1.0  吉元強樹　   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * 合計算出ビューオブジェクトです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsTotalVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchId 検索パラメータID
   ****************************************************************************/
  public void initQuery(
    String searchId         // 検索パラメータID
   )
  {
    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, searchId);
  
    // SELECT文実行
    executeQuery();
  }
}