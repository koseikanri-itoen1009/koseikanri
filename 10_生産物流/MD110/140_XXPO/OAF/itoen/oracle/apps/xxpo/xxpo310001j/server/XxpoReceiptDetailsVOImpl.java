/*============================================================================
* ファイル名 : XxpoReceiptDetailsVOImpl
* 概要説明   : 発注受入入力:受入明細ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-05 1.0  吉元強樹     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;

import com.sun.java.util.collections.HashMap;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * 受入明細ビューオブジェクトです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoReceiptDetailsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoReceiptDetailsVOImpl()
  {
  }
  
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchParams 検索パラメータ用HashMap
   ****************************************************************************/
  public void initQuery(
    HashMap searchParams // 検索キーパラメータ
   )
  {

    // 初期化
    setWhereClauseParams(null);

    // 検索パラメータ(発注番号)
    String serchHeaderNumber = (String)searchParams.get("headerNumber");
    // 検索パラメータ(発注明細番号)
    String serchLineNumber   = (String)searchParams.get("lineNumber");

    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, serchHeaderNumber);
    setWhereClauseParam(1, serchLineNumber);
  
    // SELECT文実行
    executeQuery();
  }
}