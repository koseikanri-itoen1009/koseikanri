/*============================================================================
* ファイル名 : XxpoSupplierResultsDetailsVOImpl
* 概要説明   : 仕入先出荷実績:登録明細ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-12 1.0  吉元強樹   　新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * 登録明細ビューオブジェクトクラスです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsDetailsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsDetailsVOImpl()
  {
  }
  
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchId 検索パラメータID
   ****************************************************************************/
  public void initQuery(
    String  searchId         // 検索パラメータID
  )
  {

    // 初期化
    setWhereClauseParams(null);

    // WHERE句のバインド変数に検索値をセット
    //setWhereClauseParam(0, searchId);
    setWhereClause(" po_header_id IN (" + searchId + ") ");

    // SELECT文実行
    executeQuery();
  }
}
