/*============================================================================
* ファイル名 : XxcsoEnableColumnSumVOImpl
* 概要説明   : パーソナライズビュー作成画面／使用可能列ビューオブジェクト
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
 * 使用可能列を検索するためのビュークラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEnableColumnSumVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEnableColumnSumVOImpl()
  {
  }

  /*****************************************************************************
   * ビュー・オブジェクトの初期化
   * @param viewId        ビューID
   * @param pvDispMode    汎用検索表示モード
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
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, pvDispMode);
    setWhereClauseParam(idx++, viewId);
    setWhereClauseParam(idx++, viewId);

    // SQL実行
    executeQuery();
  }

}