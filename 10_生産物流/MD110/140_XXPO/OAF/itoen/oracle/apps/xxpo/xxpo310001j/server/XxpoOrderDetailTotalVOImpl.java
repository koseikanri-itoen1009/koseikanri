/*============================================================================
* ファイル名 : XxpoOrderDetailTotalVOImpl
* 概要説明   : 発注受入詳細:合計算出ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-03 1.0  吉元強樹　   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/***************************************************************************
 * 合計算出ビューオブジェクトです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderDetailTotalVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderDetailTotalVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param headerNumber 発注番号
   ****************************************************************************/
  public void initQuery(
    String headerNumber    // 発注番号
   )
  {

    // 初期化
    setWhereClauseParams(null);

    // WHERE句のバインド変数に検索値をセット
    setWhereClauseParam(0, headerNumber);
  
    // SELECT文実行
    executeQuery();
  }
}