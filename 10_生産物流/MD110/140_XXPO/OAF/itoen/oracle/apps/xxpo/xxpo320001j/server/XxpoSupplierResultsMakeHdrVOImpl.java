/*============================================================================
* ファイル名 : XxpoSupplierResultsMakeHdrVOImpl
* 概要説明   : 仕入先出荷実績:登録ヘッダービューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-12 1.0  吉元強樹   　新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * 登録ヘッダービューオブジェクトクラスです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoSupplierResultsMakeHdrVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsMakeHdrVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchParams 検索パラメータ用HashMap
   ****************************************************************************/
  public void initQuery(
    HashMap        searchParams         // 検索キーパラメータ
   )
  {

    // 初期化
    setWhereClauseParams(null);
    // 検索パラメータ(ヘッダーID)
    String serchHeaderId = (String)searchParams.get("searchHeaderId");

    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, serchHeaderId);
  
    // SELECT文実行
    executeQuery();
  }
}