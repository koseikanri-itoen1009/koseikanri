/*============================================================================
* ファイル名 : XxcsoPvDefUpdDfltFlgVOImpl
* 概要説明   : パーソナライズビュー作成画面／デフォルトフラグ設定ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * デフォルトフラグを検索／設定するためのビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvDefUpdDfltFlgVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvDefUpdDfltFlgVOImpl()
  {
  }
  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param viewId     ビューID
   *****************************************************************************
   */
  public void initQuery(
    String viewId
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);

    // SQL実行
    executeQuery();
  }

}