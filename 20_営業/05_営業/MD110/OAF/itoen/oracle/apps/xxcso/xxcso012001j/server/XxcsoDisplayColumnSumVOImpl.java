/*============================================================================
* ファイル名 : XxcsoDisplayColumnSumVOImpl
* 概要説明   : パーソナライズビュー作成画面／表示列(表示用)ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

/*******************************************************************************
 * 表示列(新規作成)を検索するためのビュークラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDisplayColumnSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDisplayColumnSumVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param viewId        ビューID
   * @param pvDispMode    汎用表示使用モード
   *****************************************************************************
   */
  public void initQuery(
    String viewId
   ,String pvDispMode
  )
  {
    // 初期化
    setWhereClause(null);
    setWhereClauseParams(null);

    // バインドへの値の設定
    int idx = 0;
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, pvDispMode);

    // SQL実行
    executeQuery();
  }

}